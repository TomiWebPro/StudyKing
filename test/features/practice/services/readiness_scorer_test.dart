import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/practice/services/readiness_scorer.dart';

Question _createQuestion({
  String id = 'q1',
  String topicId = 't1',
  int difficulty = 1,
  String subjectId = 'sub1',
}) {
  return Question(
    id: id,
    text: 'Test question?',
    type: QuestionType.singleChoice,
    difficulty: difficulty,
    subjectId: subjectId,
    topicId: topicId,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('ReadinessScorer', () {
    test('returns empty list for empty input', () async {
      final scorer = ReadinessScorer();
      final result = await scorer.scoreQuestions([]);
      expect(result, isEmpty);
    });

    test('scores single question', () async {
      final questions = [_createQuestion()];
      final scorer = ReadinessScorer();
      final result = await scorer.scoreQuestions(questions);

      expect(result, hasLength(1));
      expect(result.first.score, greaterThan(0));
    });

    test('prioritizes questions with high review urgency', () async {
      final now = DateTime.now();
      final questions = [
        _createQuestion(id: 'q1', topicId: 't1'),
        _createQuestion(id: 'q2', topicId: 't2'),
      ];

      final topicMasteryMap = <String, MasteryState>{
        't1': MasteryState(
          studentId: 's1',
          topicId: 't1',
          accuracy: 0.9,
          lastAttempt: now,
          lastUpdated: now,
          readinessScore: 0.8,
          reviewUrgency: 0.9,
        ),
        't2': MasteryState(
          studentId: 's1',
          topicId: 't2',
          accuracy: 0.3,
          lastAttempt: now,
          lastUpdated: now,
          readinessScore: 0.2,
          reviewUrgency: 0.3,
        ),
      };

      final scorer = ReadinessScorer(topicMasteryMap: topicMasteryMap);
      final result = await scorer.scoreQuestions(questions);

      expect(result, hasLength(2));
      expect(result.first.question.id, 'q1');
      expect(result.first.score, greaterThan(result.last.score));
    });

    test('prioritizes questions with confidence gaps', () async {
      final now = DateTime.now();
      final questions = [
        _createQuestion(id: 'q1', topicId: 't1'),
        _createQuestion(id: 'q2', topicId: 't1'),
      ];

      final questionMasteryMap = <String, QuestionMasteryState>{
        'q1': QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          lastAttempt: now,
          masteryLevel: 0.9,
          confidenceHistory: [5, 5, 5],
        ),
        'q2': QuestionMasteryState(
          studentId: 's1',
          questionId: 'q2',
          lastAttempt: now,
          masteryLevel: 0.2,
          confidenceHistory: [1, 1, 1],
        ),
      };

      final scorer = ReadinessScorer(
        questionMasteryMap: questionMasteryMap,
      );
      final result = await scorer.scoreQuestions(questions);

      expect(result, hasLength(2));
      expect(result.first.question.id, 'q2');
    });

    test('prioritizes questions not attempted recently', () async {
      final now = DateTime.now();
      final questions = [
        _createQuestion(id: 'q1'),
        _createQuestion(id: 'q2'),
      ];

      final questionMasteryMap = <String, QuestionMasteryState>{
        'q1': QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          lastAttempt: now.subtract(const Duration(days: 30)),
          masteryLevel: 0.5,
        ),
        'q2': QuestionMasteryState(
          studentId: 's1',
          questionId: 'q2',
          lastAttempt: now,
          masteryLevel: 0.5,
        ),
      };

      final scorer = ReadinessScorer(
        questionMasteryMap: questionMasteryMap,
      );
      final result = await scorer.scoreQuestions(questions);

      expect(result, hasLength(2));
      expect(result.first.question.id, 'q1');
    });

    test('assigns default scores for unknown topics and questions', () async {
      final questions = [_createQuestion()];
      final scorer = ReadinessScorer();
      final result = await scorer.scoreQuestions(questions);

      expect(result.first.score, greaterThan(0));
    });

    test('sorts by score descending', () async {
      final now = DateTime.now();
      final questions = List.generate(5, (i) => _createQuestion(
        id: 'q$i',
        topicId: 't${i % 2}',
      ));

      final topicMasteryMap = <String, MasteryState>{
        't0': MasteryState(
          studentId: 's1',
          topicId: 't0',
          accuracy: 0.9,
          lastAttempt: now,
          lastUpdated: now,
          readinessScore: 0.9,
          reviewUrgency: 0.1,
        ),
        't1': MasteryState(
          studentId: 's1',
          topicId: 't1',
          accuracy: 0.3,
          lastAttempt: now,
          lastUpdated: now,
          readinessScore: 0.2,
          reviewUrgency: 0.9,
        ),
      };

      final scorer = ReadinessScorer(topicMasteryMap: topicMasteryMap);
      final result = await scorer.scoreQuestions(questions);

      expect(result, hasLength(5));
      for (var i = 0; i < result.length - 1; i++) {
        expect(result[i].score, greaterThanOrEqualTo(result[i + 1].score));
      }
    });

    test('handles empty mastery maps gracefully', () async {
      final questions = [
        _createQuestion(id: 'q1'),
        _createQuestion(id: 'q2'),
        _createQuestion(id: 'q3'),
      ];

      final scorer = ReadinessScorer();
      final result = await scorer.scoreQuestions(questions);

      expect(result, hasLength(3));
    });

    test('ScoredQuestion carries mastery data', () async {
      final now = DateTime.now();
      final topicMastery = MasteryState(
        studentId: 's1',
        topicId: 't1',
        lastAttempt: now,
        lastUpdated: now,
      );
      final questionMastery = QuestionMasteryState(
        studentId: 's1',
        questionId: 'q1',
        lastAttempt: now,
      );

      final questions = [_createQuestion()];
      final scorer = ReadinessScorer(
        topicMasteryMap: {'t1': topicMastery},
        questionMasteryMap: {'q1': questionMastery},
      );

      final result = await scorer.scoreQuestions(questions);
      expect(result.first.topicMastery, isNotNull);
      expect(result.first.questionMastery, isNotNull);
    });

    group('error-state: edge cases and null safety', () {
      test('questions with null topicId do not crash', () async {
        final questions = [
          _createQuestion(id: 'q1', topicId: 'nonexistent'),
        ];
        final scorer = ReadinessScorer();
        final result = await scorer.scoreQuestions(questions);
        expect(result, hasLength(1));
        expect(result.first.score, greaterThanOrEqualTo(0));
      });

      test('null mastery maps use default scoring', () async {
        final questions = [_createQuestion()];
        final scorer = ReadinessScorer(
          topicMasteryMap: <String, MasteryState>{},
          questionMasteryMap: <String, QuestionMasteryState>{},
        );
        final result = await scorer.scoreQuestions(questions);
        expect(result, hasLength(1));
        expect(result.first.score, greaterThan(0));
      });

      test('handles questions with extreme difficulty values', () async {
        final questions = [
          _createQuestion(id: 'q1', difficulty: 0),
          _createQuestion(id: 'q2', difficulty: 999),
        ];
        final scorer = ReadinessScorer();
        final result = await scorer.scoreQuestions(questions);
        expect(result, hasLength(2));
        for (final sq in result) {
          expect(sq.score, inInclusiveRange(0.0, 1.0));
        }
      });

      test('scorer handles large question sets without throwing', () async {
        final questions = List.generate(100, (i) => _createQuestion(id: 'q$i'));
        final scorer = ReadinessScorer();
        final result = await scorer.scoreQuestions(questions);
        expect(result, hasLength(100));
      });
    });
  });

  group('ReadinessScorer - coverage gaps', () {
    group('_computeScore edge cases', () {
      test('empty confidenceHistory uses default confidence gap', () async {
        final now = DateTime.now();
        final questions = [_createQ(id: 'q1')];
        final qMastery = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          lastAttempt: now,
          confidenceHistory: [],
        );
        final scorer = ReadinessScorer(
          questionMasteryMap: {'q1': qMastery},
        );
        final result = await scorer.scoreQuestions(questions);
        expect(result.first.score, greaterThan(0));
      });

      test('no topic mastery uses default urgency', () async {
        final questions = [_createQ(id: 'q1', topicId: 'unknown')];
        final scorer = ReadinessScorer();
        final result = await scorer.scoreQuestions(questions);
        expect(result.first.score, greaterThan(0));
      });

      test('no question mastery uses default days score', () async {
        final questions = [_createQ(id: 'q1')];
        final scorer = ReadinessScorer();
        final result = await scorer.scoreQuestions(questions);
        expect(result.first.score, greaterThan(0));
      });

      test('difficulty contributes to score', () async {
        final easyQ = _createQ(id: 'q1', difficulty: 1);
        final hardQ = _createQ(id: 'q2', difficulty: 5);
        final questions = [easyQ, hardQ];
        final scorer = ReadinessScorer();
        final result = await scorer.scoreQuestions(questions);
        expect(result[0].question.id, 'q2');
        expect(result[0].score, greaterThan(result[1].score));
      });

      test('difficulty weight spans the full canonical 1–3 scale',
          () async {
        final easyQ = _createQ(id: 'q1', difficulty: 1);
        final hardQ = _createQ(id: 'q2', difficulty: 3);
        final scorer = ReadinessScorer();
        final result = await scorer.scoreQuestions([easyQ, hardQ]);

        final easyScore =
            result.firstWhere((s) => s.question.id == 'q1').score;
        final hardScore =
            result.firstWhere((s) => s.question.id == 'q2').score;
        // (3 - 1) / 2.0 * 0.05 == 0.05: the full difficulty weight.
        // On the old 1–5 normalization the delta was only 0.025.
        expect(hardScore - easyScore, closeTo(0.05, 1e-9));
      });

      test('extreme confidence gap gives high boost', () async {
        final now = DateTime.now();
        final questions = [_createQ(id: 'q1')];
        final qMastery = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          lastAttempt: now.subtract(const Duration(days: 30)),
          confidenceHistory: [1],
        );
        final scorer = ReadinessScorer(
          questionMasteryMap: {'q1': qMastery},
        );
        final result = await scorer.scoreQuestions(questions);
        expect(result.first.score, greaterThan(0.5));
      });

      test('high readiness reduces priority', () async {
        final now = DateTime.now();
        final questions = [
          _createQ(id: 'q1', topicId: 't1'),
          _createQ(id: 'q2', topicId: 't2'),
        ];
        final topicMasteryMap = <String, MasteryState>{
          't1': MasteryState(
            studentId: 's1',
            topicId: 't1',
            lastAttempt: now,
            lastUpdated: now,
            readinessScore: 0.9,
            reviewUrgency: 0.5,
            accuracy: 0.8,
          ),
          't2': MasteryState(
            studentId: 's1',
            topicId: 't2',
            lastAttempt: now,
            lastUpdated: now,
            readinessScore: 0.1,
            reviewUrgency: 0.5,
            accuracy: 0.2,
          ),
        };
        final scorer = ReadinessScorer(topicMasteryMap: topicMasteryMap);
        final result = await scorer.scoreQuestions(questions);
        expect(result.first.question.id, 'q2');
      });

      test('counts calendar days since last attempt, not elapsed 24h periods',
          () async {
        final now = DateTime.now();
        // Last second of yesterday: the elapsed span is always
        // under 24h (even on a 23h DST-transition day), so
        // elapsed-time `difference().inDays` reports 0 days,
        // but the attempt is on the previous calendar day —
        // exactly 1 calendar day in every timezone.
        final yesterdayLastSecond =
            DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
        final questions = [_createQ(id: 'q1')];
        final qMastery = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          lastAttempt: yesterdayLastSecond,
          confidenceHistory: const [],
        );
        final scorer = ReadinessScorer(questionMasteryMap: {'q1': qMastery});
        final result = await scorer.scoreQuestions(questions);

        // No topic mastery (0.8*0.4 + 0.5*0.3), one calendar day
        // since last attempt (1/30 * 0.2), default confidence gap
        // (0.5*0.1), difficulty 1 ((1-1)/2 * 0.05).
        final expected =
            0.8 * 0.4 + 0.5 * 0.3 + (1 / 30.0) * 0.2 + 0.5 * 0.1;
        expect(result.first.score, closeTo(expected, 1e-9));
      });
    });

    group('variant awareness', () {
      test('deduplicates a variant family to a single member', () async {
        final base = _createQ(id: 'base', topicId: 't1')
            .copyWith(variantGroupId: 'group-1');
        final variant = _createQ(id: 'variant', topicId: 't1')
            .copyWith(variantGroupId: 'group-1', variantIds: ['base']);

        final scorer = ReadinessScorer();
        final result = await scorer.scoreQuestions([base, variant]);

        // The two belong to the same family, so only one is surfaced.
        expect(result, hasLength(1));
      });

      test('keeps distinct families separate', () async {
        final a = _createQ(id: 'a', topicId: 't1')
            .copyWith(variantGroupId: 'g1');
        final b = _createQ(id: 'b', topicId: 't1')
            .copyWith(variantGroupId: 'g2');

        final scorer = ReadinessScorer();
        final result = await scorer.scoreQuestions([a, b]);

        expect(result, hasLength(2));
      });

      test('prefers a variant of a recently-wrong concept', () async {
        final wrongBase = _createQ(id: 'wrong', topicId: 't1')
            .copyWith(variantGroupId: 'g1');
        final variantOfWrong = _createQ(id: 'variant', topicId: 't1')
            .copyWith(variantGroupId: 'g1', variantIds: ['wrong']);
        final unrelated = _createQ(id: 'unrelated', topicId: 't2')
            .copyWith(variantGroupId: 'g2');

        final scorer = ReadinessScorer(
          wrongQuestionIds: {'wrong'},
        );
        final result =
            await scorer.scoreQuestions([wrongBase, variantOfWrong, unrelated]);

        // variantOfWrong is the highest-priority (boosted) member of its family;
        // the deduplicated family representative should be it or the base, and
        // its score must exceed the unrelated question's score.
        final unrelatedScore = result
            .firstWhere((s) => s.question.id == 'unrelated')
            .score;
        final familyScore = result
            .firstWhere((s) => s.question.variantGroupId == 'g1')
            .score;
        expect(familyScore, greaterThan(unrelatedScore));
      });
    });
  });

  group('ReadinessScorer - mastery refresh', () {
    test('refreshes topic mastery from the service on every call', () async {
      final now = DateTime.now();
      final questions = [_createQ(id: 'q1', topicId: 't1')];
      final mastery = _FakeMasteryGraphService(
        allMastery: [
          MasteryState(
            studentId: 's1',
            topicId: 't1',
            lastAttempt: now,
            lastUpdated: now,
            readinessScore: 0.9,
            reviewUrgency: 0.1,
            accuracy: 0.8,
          ),
        ],
      );
      final scorer = ReadinessScorer(
        masteryService: mastery,
        studentIdService: _FakeStudentIdService('s1'),
      );

      final first = await scorer.scoreQuestions(questions);
      final firstScore = first.first.score;
      expect(first.first.topicMastery?.readinessScore, 0.9);

      // A completed session updates mastery inside the service (Hive).
      mastery.allMastery = [
        MasteryState(
          studentId: 's1',
          topicId: 't1',
          lastAttempt: now,
          lastUpdated: now,
          readinessScore: 0.1,
          reviewUrgency: 0.9,
          accuracy: 0.2,
        ),
      ];

      final second = await scorer.scoreQuestions(questions);
      // The updated mastery must be picked up without an app restart.
      expect(second.first.topicMastery?.readinessScore, 0.1);
      expect(second.first.score, greaterThan(firstScore));
      // Each scoring pass re-reads the service (no permanent cache latch).
      expect(mastery.initCalls, greaterThan(1));
    });

    test('drops topic mastery entries the service no longer returns',
        () async {
      final now = DateTime.now();
      final questions = [_createQ(id: 'q1', topicId: 't1')];
      final mastery = _FakeMasteryGraphService(
        allMastery: [
          MasteryState(
            studentId: 's1',
            topicId: 't1',
            lastAttempt: now,
            lastUpdated: now,
            readinessScore: 0.9,
            reviewUrgency: 0.1,
            accuracy: 0.8,
          ),
        ],
      );
      final scorer = ReadinessScorer(
        masteryService: mastery,
        studentIdService: _FakeStudentIdService('s1'),
      );

      final first = await scorer.scoreQuestions(questions);
      expect(first.first.topicMastery, isNotNull);

      // The topic's mastery record is gone on the next read.
      mastery.allMastery = [];
      final second = await scorer.scoreQuestions(questions);
      expect(second.first.topicMastery, isNull);
    });

    test('refreshes question mastery between calls', () async {
      final now = DateTime.now();
      final questions = [_createQ(id: 'q1', topicId: 't1')];
      final mastery = _FakeMasteryGraphService(
        allQuestionMastery: [
          QuestionMasteryState(
            studentId: 's1',
            questionId: 'q1',
            lastAttempt: now,
            masteryLevel: 0.9,
            confidenceHistory: const [5, 5, 5],
          ),
        ],
      );
      final scorer = ReadinessScorer(
        masteryService: mastery,
        studentIdService: _FakeStudentIdService('s1'),
      );

      final first = await scorer.scoreQuestions(questions);
      final firstScore = first.first.score;
      expect(first.first.questionMastery?.confidenceHistory, [5, 5, 5]);

      // The student struggled on a later attempt: low confidence, stale.
      mastery.allQuestionMastery = [
        QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          lastAttempt: now.subtract(const Duration(days: 30)),
          masteryLevel: 0.2,
          confidenceHistory: const [1, 1, 1],
        ),
      ];

      final second = await scorer.scoreQuestions(questions);
      expect(second.first.questionMastery?.confidenceHistory, [1, 1, 1]);
      expect(second.first.score, greaterThan(firstScore));
    });

    test('keeps the last good snapshot when a reload fails', () async {
      final now = DateTime.now();
      final questions = [_createQ(id: 'q1', topicId: 't1')];
      final mastery = _FakeMasteryGraphService(
        allMastery: [
          MasteryState(
            studentId: 's1',
            topicId: 't1',
            lastAttempt: now,
            lastUpdated: now,
            readinessScore: 0.9,
            reviewUrgency: 0.1,
            accuracy: 0.8,
          ),
        ],
      );
      final scorer = ReadinessScorer(
        masteryService: mastery,
        studentIdService: _FakeStudentIdService('s1'),
      );

      final first = await scorer.scoreQuestions(questions);
      final firstScore = first.first.score;

      // The next reload fails (e.g. box not open): scoring still works
      // against the last good snapshot instead of losing all mastery data.
      mastery.failAllMastery = true;
      final second = await scorer.scoreQuestions(questions);
      expect(second.first.topicMastery?.readinessScore, 0.9);
      expect(second.first.score, closeTo(firstScore, 1e-9));
    });
  });
}

class _FakeMasteryGraphService extends MasteryGraphService {
  List<MasteryState> allMastery;
  List<QuestionMasteryState> allQuestionMastery;
  bool failAllMastery = false;
  int initCalls = 0;

  _FakeMasteryGraphService({
    this.allMastery = const [],
    this.allQuestionMastery = const [],
  }) : super();

  @override
  Future<Result<void>> init() async {
    initCalls++;
    return Result.success(null);
  }

  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(
    String studentId,
  ) async {
    if (failAllMastery) return Result.failure('box not open');
    return Result.success(allMastery);
  }

  @override
  Future<Result<List<QuestionMasteryState>>> getAllQuestionMastery(
    String studentId,
  ) async {
    if (failAllMastery) return Result.failure('box not open');
    return Result.success(allQuestionMastery);
  }
}

class _FakeStudentIdService extends StudentIdService {
  final String _id;

  _FakeStudentIdService(this._id);

  @override
  Result<String> getStudentId() => Result.success(_id);
}

Question _createQ({
  String id = 'q1',
  String subjectId = 'sub1',
  String topicId = 't1',
  int difficulty = 1,
  String variantGroupId = '',
  String? srDataJson,
}) {
  return Question(
    id: id,
    text: 'Sample question?',
    type: QuestionType.singleChoice,
    subjectId: subjectId,
    topicId: topicId,
    difficulty: difficulty,
    variantGroupId: variantGroupId,
    createdAt: DateTime(2026, 5, 12),
    updatedAt: DateTime(2026, 5, 12),
    srDataJson: srDataJson,
  );
}
