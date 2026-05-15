import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';

class EngagementNudgeRepository extends Repository<EngagementNudgeModel> {
  Future<void> init() async {
    await openBox(HiveBoxNames.engagementNudges);
  }

  Future<void> create(EngagementNudgeModel nudge) async {
    await super.save(nudge.id, nudge);
  }

  Future<List<EngagementNudgeModel>> getByStudent(String studentId) async {
    final all = filterBy((n) => n.studentId, studentId)
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return all;
  }

  Future<List<EngagementNudgeModel>> getRecentByStudent(
      String studentId, {int limit = 10}) async {
    final all = await getByStudent(studentId);
    return all.take(limit).toList();
  }

  Future<List<EngagementNudgeModel>> getUnactedByStudent(
      String studentId) async {
    final byStudent = filterBy((n) => n.studentId, studentId);
    return byStudent.where((n) => !n.wasActedUpon).toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  Future<void> markActedUpon(String id) async {
    final nudge = box.get(id);
    if (nudge != null) {
      await super.save(
          id, nudge.copyWith(wasActedUpon: true, actedUponAt: DateTime.now()));
    }
  }

  Future<int> getTodayCount(String studentId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return filterBy((n) => n.studentId, studentId)
        .where((n) => n.sentAt.isAfter(startOfDay))
        .length;
  }

  Future<List<EngagementNudgeModel>> getByType(
      String studentId, String nudgeType) async {
    final byStudent = filterBy((n) => n.studentId, studentId);
    return byStudent.where((n) => n.nudgeType == nudgeType).toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  Future<void> deleteOld(int daysOld) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysOld));
    final old = box.values.where((n) => n.sentAt.isBefore(cutoff)).toList();
    for (final n in old) {
      await super.delete(n.id);
    }
  }
}
