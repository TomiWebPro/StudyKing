import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

class MasteryStateRepository extends Repository<MasteryState> {
  final Logger _logger = const Logger('MasteryStateRepository');

  Future<void> init() async {
    await openBox(HiveBoxNames.masteryStates);
  }

  Future<Result<MasteryState>> getMasteryState(
    String studentId,
    String topicId,
  ) async {
    try {
      final key = '${studentId}_$topicId';
      final stateResult = await get(key);
      final state = stateResult.data;
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
      final statesResult = await getAllMasteryStates(studentId);
      if (statesResult.isFailure) return Result.failure(statesResult.error);

      final topicStates = statesResult.data!;
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
