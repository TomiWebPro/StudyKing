import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';

class EngagementNudgeRepository extends Repository<EngagementNudgeModel> {
  static final Logger _logger = const Logger('EngagementNudgeRepository');
  EngagementNudgeRepository() : super(boxName: HiveBoxNames.engagementNudges);

  Future<void> init() async {
    await openBox(HiveBoxNames.engagementNudges);
  }

  Future<Result<void>> create(EngagementNudgeModel nudge) async {
    return super.put(nudge.id, nudge);
  }

  Future<Result<List<EngagementNudgeModel>>> getByStudent(
      String studentId) async {
    return Result.capture(() async {
      final all = filterBy((n) => n.studentId, studentId)
        ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
      return all;
    }, context: 'getByStudent');
  }

  Future<Result<List<EngagementNudgeModel>>> getRecentByStudent(
      String studentId, {int limit = 10}) async {
    try {
      final allResult = await getByStudent(studentId);
      if (allResult.isFailure) {
        return Result.failure(allResult.error);
      }
      return Result.success(allResult.data!.take(limit).toList());
    } catch (e) {
      _logger.w(e.toString(), e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<EngagementNudgeModel>>> getUnactedByStudent(
      String studentId) async {
    return Result.capture(() async {
      final byStudent = filterBy((n) => n.studentId, studentId);
      return byStudent.where((n) => !n.wasActedUpon).toList()
        ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    }, context: 'getUnactedByStudent');
  }

  Future<Result<void>> markActedUpon(String id) async {
    try {
      final nudge = box.get(id);
      if (nudge == null) {
        return Result.success(null);
      }
      final result = await super.put(
          id, nudge.copyWith(wasActedUpon: true, actedUponAt: DateTime.now()));
      if (result.isFailure) {
        _logger.w('Failed to mark nudge $id acted upon', result.error);
      }
      return result;
    } catch (e) {
      _logger.w('markActedUpon failed for nudge $id: $e', e);
      return Result.failure('markActedUpon failed: $e');
    }
  }

  Future<Result<int>> getTodayCount(String studentId) async {
    return Result.capture(() async {
      final today = DateTime.now();
      final startOfDay = today.dateOnly;
      return filterBy((n) => n.studentId, studentId)
          .where((n) => n.sentAt.isAfter(startOfDay))
          .length;
    }, context: 'getTodayCount');
  }

  Future<Result<List<EngagementNudgeModel>>> getByType(
      String studentId, String nudgeType) async {
    return Result.capture(() async {
      final byStudent = filterBy((n) => n.studentId, studentId);
      return byStudent.where((n) => n.nudgeType == nudgeType).toList()
        ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    }, context: 'getByType');
  }

  Future<Result<void>> deleteOld(int daysOld) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: daysOld));
      final old = box.values.where((n) => n.sentAt.isBefore(cutoff)).toList();
      for (final n in old) {
        final result = await super.delete(n.id);
        if (result.isFailure) {
          _logger.w('Failed to delete old nudge ${n.id}', result.error);
          return result;
        }
      }
      return Result.success(null);
    } catch (e) {
      _logger.w('deleteOld failed: $e', e);
      return Result.failure('deleteOld failed: $e');
    }
  }
}
