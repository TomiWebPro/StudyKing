import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

class QuestionMasteryStateRepository {
  final Logger _logger = const Logger('QuestionMasteryStateRepository');
  late Box<QuestionMasteryState> _box;

  Future<void> init() async {
    try {
      _box = await Hive.openBox<QuestionMasteryState>(HiveBoxNames.questionMasteryStates);
    } catch (e) {
      _logger.e('Error initializing QuestionMasteryStateRepository', e);
      rethrow;
    }
  }

  void attachBox(Box<QuestionMasteryState> box) {
    _box = box;
  }

  Future<Result<QuestionMasteryState>> getQuestionMasteryState(
    String studentId,
    String questionId,
  ) async {
    try {
      final key = '${studentId}_$questionId';
      final state = _box.get(key);
      if (state != null) {
        return Result.success(state);
      }
      final newState = QuestionMasteryState.initial(
          studentId: studentId, questionId: questionId);
      await _box.put(key, newState);
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
      await _box.put(key, state);
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
      final states = _box.values
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
      final states = _box.values
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
