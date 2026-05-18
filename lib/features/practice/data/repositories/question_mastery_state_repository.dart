import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

class QuestionMasteryStateRepository extends Repository<QuestionMasteryState> {
  final Logger _logger = const Logger('QuestionMasteryStateRepository');

  Future<void> init() async {
    await openBox(HiveBoxNames.questionMasteryStates);
  }

  Future<Result<QuestionMasteryState>> getQuestionMasteryState(
    String studentId,
    String questionId,
  ) async {
    try {
      final key = '${studentId}_$questionId';
      final state = box.get(key);
      if (state != null) {
        return Result.success(state);
      }
      final newState = QuestionMasteryState.initial(
          studentId: studentId, questionId: questionId, now: DateTime.now());
      await box.put(key, newState);
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
      await box.put(key, state);
      return Result.success(null);
    } catch (e) {
      _logger.e('Error updating question mastery state', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<QuestionMasteryState>>> getAllForStudent(
      String studentId) async {
    try {
      final states = filterBy((s) => s.studentId, studentId);
      return Result.success(states);
    } catch (e) {
      _logger.e('Error getting all question mastery states for student', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<QuestionMasteryState>>> getDueQuestions(
    String studentId, {
    DateTime? asOf,
  }) async {
    try {
      final now = asOf ?? DateTime.now();
      final states = box.values
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
      final states = box.values
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
}
