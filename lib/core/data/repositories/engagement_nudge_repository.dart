import 'package:hive_flutter/hive_flutter.dart';
import '../models/engagement_nudge_model.dart';

class EngagementNudgeRepository {
  late Box<EngagementNudgeModel> _box;

  Future<void> init() async {
    _box = await Hive.openBox<EngagementNudgeModel>('engagement_nudges');
  }

  Future<void> save(EngagementNudgeModel nudge) async {
    await _box.put(nudge.id, nudge);
  }

  Future<List<EngagementNudgeModel>> getByStudent(String studentId) async {
    return _box.values
        .where((n) => n.studentId == studentId)
        .toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  Future<List<EngagementNudgeModel>> getRecentByStudent(
      String studentId, {int limit = 10}) async {
    final all = await getByStudent(studentId);
    return all.take(limit).toList();
  }

  Future<List<EngagementNudgeModel>> getUnactedByStudent(
      String studentId) async {
    return _box.values
        .where((n) => n.studentId == studentId && !n.wasActedUpon)
        .toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  Future<void> markActedUpon(String id) async {
    final nudge = _box.get(id);
    if (nudge != null) {
      await _box.put(
          id, nudge.copyWith(wasActedUpon: true, actedUponAt: DateTime.now()));
    }
  }

  Future<int> getTodayCount(String studentId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return _box.values
        .where((n) =>
            n.studentId == studentId && n.sentAt.isAfter(startOfDay))
        .length;
  }

  Future<List<EngagementNudgeModel>> getByType(
      String studentId, String nudgeType) async {
    return _box.values
        .where((n) => n.studentId == studentId && n.nudgeType == nudgeType)
        .toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  Future<void> deleteOld(int daysOld) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysOld));
    final old = _box.values.where((n) => n.sentAt.isBefore(cutoff)).toList();
    for (final n in old) {
      await _box.delete(n.id);
    }
  }
}
