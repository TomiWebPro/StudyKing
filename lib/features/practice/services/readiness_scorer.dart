import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/logger.dart';

/// Calendar-day difference `a - b` in whole days. Both
/// arguments are local timestamps; the computation is done
/// on UTC-normalized dates so a DST transition (a 23h or
/// 25h calendar day) cannot shift the result the way
/// elapsed-time `difference().inDays` does.
int _calendarDayDiff(DateTime a, DateTime b) {
  final utcA = DateTime.utc(a.year, a.month, a.day);
  final utcB = DateTime.utc(b.year, b.month, b.day);
  return utcA.difference(utcB).inDays;
}

class ScoredQuestion {
  final Question question;
  final double score;
  final MasteryState? topicMastery;
  final QuestionMasteryState? questionMastery;

  const ScoredQuestion({
    required this.question,
    required this.score,
    this.topicMastery,
    this.questionMastery,
  });
}

/// Per-topic readiness snapshot surfaced to the mentor LLM
/// (Vision Next-Term §3.1 scenario audit). Mirrors the readiness signal
/// [ReadinessScorer] uses internally for difficulty selection so the mentor
/// reasons over the same data the practice-session tool ([CreatePracticeSessionTool])
/// sees when picking question difficulty.
class TopicReadiness {
  final String topicId;
  final String subjectId;
  final double readinessScore;
  final double accuracy;
  final int totalAttempts;

  /// Most-recent per-attempt accuracy (0–1), newest last, used to surface a
  /// short accuracy trend per topic to the mentor.
  final List<double> recentAccuracy;

  const TopicReadiness({
    required this.topicId,
    required this.subjectId,
    required this.readinessScore,
    required this.accuracy,
    required this.totalAttempts,
    this.recentAccuracy = const [],
  });
}

class ReadinessScorer {
  static final Logger _logger = const Logger('ReadinessScorer');
  Map<String, MasteryState> _topicMasteryMap = {};
  Map<String, QuestionMasteryState> _questionMasteryMap = {};

  /// True when mastery maps were injected through the constructor.
  /// Injected maps are authoritative — the mastery service is never
  /// consulted in that case.
  bool _mapsInjected = false;

  final MasteryGraphService? _masteryService;
  final StudentIdService? _studentIdService;

  static const double urgencyWeight = 0.4;
  static const double readinessInverseWeight = 0.3;
  static const double daysSinceLastAttemptWeight = 0.2;
  static const double confidenceGapWeight = 0.1;

  /// Extra scoring weight applied to a question that belongs to the same variant
  /// family as a concept the student recently answered incorrectly. This nudges
  /// the practice session to re-test the *concept* (via a different surface
  /// form) rather than repeating the exact question the student failed.
  static const double wrongVariantBoost = 0.15;

  /// Ids of questions the student recently answered incorrectly. When provided,
  /// the scorer prefers showing a variant of any related concept so the student
  /// re-demonstrates understanding with different values.
  final Set<String>? wrongQuestionIds;

  ReadinessScorer({
    Map<String, MasteryState>? topicMasteryMap,
    Map<String, QuestionMasteryState>? questionMasteryMap,
    MasteryGraphService? masteryService,
    StudentIdService? studentIdService,
    this.wrongQuestionIds,
  })  : _masteryService = masteryService,
        _studentIdService = studentIdService {
    if (topicMasteryMap != null) {
      _topicMasteryMap = topicMasteryMap;
      _mapsInjected = true;
    }
    if (questionMasteryMap != null) {
      _questionMasteryMap = questionMasteryMap;
      _mapsInjected = true;
    }
  }

  bool _loading = false;

  /// Loads the current mastery snapshot from the service. Called on every
  /// [scoreQuestions] invocation so that mastery updates recorded during the
  /// app run (via MasteryGraphService.recordAttempt) are reflected without
  /// requiring an app restart. Constructor-injected maps skip this entirely.
  Future<void> _ensureDataLoaded() async {
    if (_mapsInjected || _loading) return;
    if (_masteryService == null || _studentIdService == null) return;
    _loading = true;

    try {
      await _masteryService.init();
      final studentId = _studentIdService.getStudentId().data ?? '';

      final topicResult = await _masteryService.getAllTopicMastery(studentId);
      if (topicResult.isSuccess && topicResult.data != null) {
        _topicMasteryMap = {
          for (final state in topicResult.data!) state.topicId: state,
        };
      }

      final questionResult =
          await _masteryService.getAllQuestionMastery(studentId);
      if (questionResult.isSuccess && questionResult.data != null) {
        _questionMasteryMap = {
          for (final state in questionResult.data!) state.questionId: state,
        };
      }
    } catch (e) {
      _logger.w('Error loading mastery data', e);
    } finally {
      _loading = false;
    }
  }

  Future<List<ScoredQuestion>> scoreQuestions(List<Question> questions) async {
    await _ensureDataLoaded();
    if (questions.isEmpty) return [];

    final idToQuestion = {for (final q in questions) q.id: q};
    final wrongSet = wrongQuestionIds ?? const <String>{};

    final scored = questions.map((q) {
      final topicMastery = _topicMasteryMap[q.topicId];
      final questionMastery = _questionMasteryMap[q.id];

      final relatedToWrong =
          wrongSet.isNotEmpty && _isRelatedToWrong(q, idToQuestion, wrongSet);

      final score = _computeScore(
        question: q,
        topicMastery: topicMastery,
        questionMastery: questionMastery,
        relatedToWrong: relatedToWrong,
      );

      return ScoredQuestion(
        question: q,
        score: score,
        topicMastery: topicMastery,
        questionMastery: questionMastery,
      );
    }).toList();

    // Variant deduplication: a variant family shares a non-empty group id. To
    // avoid showing near-duplicate surface forms in a single session, collapse
    // each family to its highest-scored member (the most urgent variant).
    final deduped = _deduplicateByVariantGroup(scored);

    deduped.sort((a, b) => b.score.compareTo(a.score));
    return deduped;
  }

  /// Returns per-topic readiness scores for the current student — the SAME
  /// readiness signal ([MasteryState.readinessScore]) this scorer uses in
  /// [_computeScore] for difficulty selection. Sorted by readiness ascending
  /// so the least-ready (most at-risk) topics surface first.
  ///
  /// Used by [MentorContextBuilder] to inject readiness context into the mentor
  /// system prompt (Vision Next-Term §3.1): the mentor must see the readiness
  /// state that drives practice difficulty rather than only raw weak-topic
  /// accuracy. Each entry also carries [TopicReadiness.recentAccuracy] so the
  /// mentor can observe short accuracy trends per topic.
  Future<List<TopicReadiness>> topicReadiness() async {
    await _ensureDataLoaded();
    final topics = [
      for (final entry in _topicMasteryMap.entries)
        TopicReadiness(
          topicId: entry.key,
          subjectId: entry.value.subjectId,
          readinessScore: entry.value.readinessScore,
          accuracy: entry.value.accuracy,
          totalAttempts: entry.value.totalAttempts,
          recentAccuracy: entry.value.recentAccuracy,
        ),
    ];
    // Least-ready first — the mentor cares most about what the student is
    // not ready for, matching the practice tool's urgency-first ordering.
    topics.sort((a, b) => a.readinessScore.compareTo(b.readinessScore));
    return topics;
  }

  /// True when [question] belongs to the same variant family as any question the
  /// student recently got wrong.
  bool _isRelatedToWrong(
    Question question,
    Map<String, Question> idToQuestion,
    Set<String> wrongSet,
  ) {
    if (wrongSet.contains(question.id)) return true;

    if (question.variantGroupId.isNotEmpty) {
      for (final wrongId in wrongSet) {
        final wrong = idToQuestion[wrongId];
        if (wrong != null && wrong.variantGroupId == question.variantGroupId) {
          return true;
        }
      }
    }

    if (question.variantIds.any((id) => wrongSet.contains(id))) return true;

    // A wrong question may itself be a variant of [question]'s base.
    for (final wrongId in wrongSet) {
      final wrong = idToQuestion[wrongId];
      if (wrong != null && wrong.variantIds.contains(question.id)) {
        return true;
      }
    }

    return false;
  }

  /// Collapses variant families to a single representative (highest score).
  List<ScoredQuestion> _deduplicateByVariantGroup(List<ScoredQuestion> scored) {
    final byGroup = <String, ScoredQuestion>{};
    final standalone = <ScoredQuestion>[];

    for (final sq in scored) {
      final groupId = sq.question.variantGroupId;
      if (groupId.isEmpty) {
        standalone.add(sq);
        continue;
      }
      final current = byGroup[groupId];
      if (current == null || sq.score > current.score) {
        byGroup[groupId] = sq;
      }
    }

    return [...standalone, ...byGroup.values];
  }

  double _computeScore({
    required Question question,
    MasteryState? topicMastery,
    QuestionMasteryState? questionMastery,
    bool relatedToWrong = false,
  }) {
    final now = DateTime.now();
    double score = 0.0;

    if (topicMastery != null) {
      score += topicMastery.reviewUrgency * urgencyWeight;
      score += (1.0 - topicMastery.readinessScore) * readinessInverseWeight;
    } else {
      score += 0.8 * urgencyWeight;
      score += 0.5 * readinessInverseWeight;
    }

    if (questionMastery != null) {
      // Calendar-day count, not elapsed 24h periods: a
      // question attempted late yesterday is one day stale
      // even when the elapsed span is under 24h (always the
      // case on a 23h DST-transition day).
      final daysSinceLastAttempt =
          _calendarDayDiff(now, questionMastery.lastAttempt).toDouble();
      final daysNorm = (daysSinceLastAttempt / 30.0).clamp(0.0, 1.0);
      score += daysNorm * daysSinceLastAttemptWeight;

      if (questionMastery.confidenceHistory.isNotEmpty) {
        final avgConfidence = questionMastery.confidenceHistory
                .reduce((a, b) => a + b) /
            questionMastery.confidenceHistory.length;
        final confidenceGap = (5.0 - avgConfidence) / 5.0;
        score += confidenceGap * confidenceGapWeight;
      } else {
        score += 0.5 * confidenceGapWeight;
      }
    } else {
      score += 0.7 * daysSinceLastAttemptWeight;
      score += 0.5 * confidenceGapWeight;
    }

    // Difficulty uses the canonical 1–3 scale; normalize to 0–1.
    final difficultyNorm = (question.difficulty - 1) / 2.0;
    score += difficultyNorm * 0.05;

    if (relatedToWrong) {
      score += wrongVariantBoost;
    }

    return score.clamp(0.0, 1.0);
  }
}
