import 'package:hive_flutter/hive_flutter.dart';
import '../models/badge_model.dart';

class BadgeRepository {
  late Box<BadgeModel> _box;

  Future<void> init() async {
    _box = await Hive.openBox<BadgeModel>('badges');
  }

  Future<void> save(BadgeModel badge) async {
    await _box.put(badge.id, badge);
  }

  Future<BadgeModel?> get(String id) async {
    return _box.get(id);
  }

  Future<List<BadgeModel>> getByStudent(String studentId) async {
    return _box.values
        .where((b) => b.studentId == studentId)
        .toList()
      ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
  }

  Future<bool> hasBadge(String studentId, String badgeId) async {
    return _box.values.any(
        (b) => b.studentId == studentId && b.id == badgeId);
  }

  Future<Map<String, BadgeModel>> getBadgeMap(String studentId) async {
    final badges = await getByStudent(studentId);
    return {for (final b in badges) b.id: b};
  }

  Future<int> getBadgeCount(String studentId) async {
    return _box.values
        .where((b) => b.studentId == studentId)
        .length;
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<List<BadgeModel>> getAll() async {
    return _box.values.toList();
  }
}
