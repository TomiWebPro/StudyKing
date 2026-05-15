import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/questions/data/models/question_evaluation_model.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

class MasteryGraphRepository extends Repository<MasteryState> {
  final Logger _logger = const Logger('MasteryGraphRepository');
  late Box<QuestionMasteryState> _questionMasteryBox;
  late Box<TopicDependency> _dependencyBox;
  late Box<QuestionEvaluation> _evaluationBox;

  MasteryGraphRepository();

  MasteryGraphRepository.test({
    required Box<MasteryState> masteryBox,
    required Box<QuestionMasteryState> questionMasteryBox,
    required Box<TopicDependency> dependencyBox,
    required Box<QuestionEvaluation> evaluationBox,
  })  : _questionMasteryBox = questionMasteryBox,
        _dependencyBox = dependencyBox,
        _evaluationBox = evaluationBox {
    attachBox(masteryBox);
  }

  Future<void> init() async {
    try {
      await openBox(HiveBoxNames.masteryStates);
      _questionMasteryBox =
          await Hive.openBox<QuestionMasteryState>(HiveBoxNames.questionMasteryStates);
      _dependencyBox =
          await Hive.openBox<TopicDependency>(HiveBoxNames.topicDependencies);
      _evaluationBox =
          await Hive.openBox<QuestionEvaluation>(HiveBoxNames.questionEvaluations);
    } catch (e) {
      _logger.e('Error initializing MasteryGraphRepository', e);
      rethrow;
    }
  }

  Future<Result<MasteryState>> getMasteryState(
    String studentId,
    String topicId,
  ) async {
    try {
      final key = '${studentId}_$topicId';
      final state = await get(key);
      if (state != null) {
        return Result.success(state);
      }
      final newState =
          MasteryState.initial(studentId: studentId, topicId: topicId);
      await save(key, newState);
      return Result.success(newState);
    } catch (e) {
      _logger.e('Error getting mastery state', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> updateMasteryState(MasteryState state) async {
    try {
      final key = '${state.studentId}_${state.topicId}';
      await save(key, state);
      return Result.success(null);
    } catch (e) {
      _logger.e('Error updating mastery state', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<MasteryState>>> getAllMasteryStates(
      String studentId) async {
    try {
      final states = filterBy((s) => s.studentId, studentId);
      return Result.success(states);
    } catch (e) {
      _logger.e('Error getting all mastery states', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<QuestionMasteryState>> getQuestionMasteryState(
    String studentId,
    String questionId,
  ) async {
    try {
      final key = '${studentId}_$questionId';
      final state = _questionMasteryBox.get(key);
      if (state != null) {
        return Result.success(state);
      }
      final newState = QuestionMasteryState.initial(
          studentId: studentId, questionId: questionId);
      await _questionMasteryBox.put(key, newState);
      return Result.success(newState);
    } catch (e) {
      _logger.e('Error getting question mastery state', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> updateQuestionMasteryState(
      QuestionMasteryState state) async {
    try {
      final key = '${state.studentId}_${state.questionId}';
      await _questionMasteryBox.put(key, state);
      return Result.success(null);
    } catch (e) {
      _logger.e('Error updating question mastery state', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<QuestionMasteryState>>> getDueQuestions(
    String studentId, {
    DateTime? asOf,
  }) async {
    try {
      final now = asOf ?? DateTime.now();
      final states = _questionMasteryBox.values
          .where((s) =>
              s.studentId == studentId &&
              s.nextReview != null &&
              s.nextReview!.isBefore(now))
          .toList();
      states.sort((a, b) =>
          (a.nextReview ?? DateTime.now())
              .compareTo(b.nextReview ?? DateTime.now()));
      return Result.success(states);
    } catch (e) {
      _logger.e('Error getting due questions', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(
    String studentId, {
    double threshold = 0.5,
  }) async {
    try {
      final states = _questionMasteryBox.values
          .where((s) =>
              s.studentId == studentId && s.masteryLevel < threshold)
          .toList();
      states.sort((a, b) => a.masteryLevel.compareTo(b.masteryLevel));
      return Result.success(states);
    } catch (e) {
      _logger.e('Error getting at-risk questions', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<TopicDependency>> getTopicDependency(String topicId) async {
    try {
      final dep = _dependencyBox.get(topicId);
      if (dep != null) {
        return Result.success(dep);
      }
      final newDep = TopicDependency(topicId: topicId);
      await _dependencyBox.put(topicId, newDep);
      return Result.success(newDep);
    } catch (e) {
      _logger.e('Error getting topic dependency', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> updateTopicDependency(
      TopicDependency dependency) async {
    try {
      await _dependencyBox.put(dependency.topicId, dependency);
      return Result.success(null);
    } catch (e) {
      _logger.e('Error updating topic dependency', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<TopicDependency>>> getAllDependencies() async {
    try {
      return Result.success(_dependencyBox.values.toList());
    } catch (e) {
      _logger.e('Error getting all dependencies', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<QuestionEvaluation>> getEvaluation(String questionId) async {
    try {
      final evaluation = _evaluationBox.get(questionId);
      if (evaluation != null) {
        return Result.success(evaluation);
      }
      return Result.failure('No evaluation found for question: $questionId');
    } catch (e) {
      _logger.e('Error getting evaluation', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> saveEvaluation(QuestionEvaluation evaluation) async {
    try {
      await _evaluationBox.put(evaluation.questionId, evaluation);
      return Result.success(null);
    } catch (e) {
      _logger.e('Error saving evaluation', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> migrateFromLegacy({
    required String questionId,
    String? markscheme,
    String? correctAnswer,
    List<String>? options,
    String? explanation,
  }) async {
    try {
      final existing = _evaluationBox.get(questionId);
      if (existing != null) return Result.success(null);

      final evaluation = QuestionEvaluation.fromLegacy(
        questionId: questionId,
        markscheme: markscheme,
        correctAnswer: correctAnswer,
        options: options,
        explanation: explanation,
      );
      await _evaluationBox.put(questionId, evaluation);
      return Result.success(null);
    } catch (e) {
      _logger.e('Error migrating legacy evaluation', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<MasteryState>>> getTopicsNeedingReview(
      String studentId) async {
    try {
      final states = filterBy((s) => s.studentId, studentId)
          .where((s) => s.reviewUrgency > 0.5)
          .toList();
      states.sort((a, b) => b.reviewUrgency.compareTo(a.reviewUrgency));
      return Result.success(states);
    } catch (e) {
      _logger.e('Error getting topics needing review', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    try {
      final states = filterBy((s) => s.studentId, studentId)
          .where((s) => s.accuracy < 0.7)
          .toList();
      states.sort((a, b) => a.accuracy.compareTo(b.accuracy));
      return Result.success(states);
    } catch (e) {
      _logger.e('Error getting weak topics', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<Map<String, dynamic>>> getMasterySnapshot(
      String studentId) async {
    try {
      final states = await getAllMasteryStates(studentId);
      if (states.isFailure) return Result.failure(states.error);

      final topicStates = states.data!;
      final avgAccuracy = topicStates.isEmpty
          ? 0.0
          : topicStates.map((s) => s.accuracy).reduce((a, b) => a + b) /
              topicStates.length;

      final masteredTopics =
          topicStates.where((s) => s.masteryLevel.index >= 3).length;
      final weakTopics =
          topicStates.where((s) => s.accuracy < 0.6).length;
      final totalAttempts =
          topicStates.fold<int>(0, (sum, s) => sum + s.totalAttempts);

      return Result.success({
        'totalTopics': topicStates.length,
        'masteredTopics': masteredTopics,
        'weakTopics': weakTopics,
        'averageAccuracy': avgAccuracy,
        'totalAttempts': totalAttempts,
        'avgReadiness': topicStates.isEmpty
            ? 0.0
            : topicStates
                    .map((s) => s.readinessScore)
                    .reduce((a, b) => a + b) /
                topicStates.length,
        'avgReviewUrgency': topicStates.isEmpty
            ? 0.0
            : topicStates
                    .map((s) => s.reviewUrgency)
                    .reduce((a, b) => a + b) /
                topicStates.length,
      });
    } catch (e) {
      _logger.e('Error getting mastery snapshot', e);
      return Result.failure(e.toString());
    }
  }
}
