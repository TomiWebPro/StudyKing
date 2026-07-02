import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/features/dashboard/data/models/badge_model.dart';
import 'package:studyking/core/data/repository.dart';

class BadgeRepository extends Repository<BadgeModel> {
  BadgeRepository() : super(boxName: HiveBoxNames.badges);

  Future<void> init() async {
    await openBox(HiveBoxNames.badges);
  }

  Future<void> create(BadgeModel badge) async {
    await save(badge.id, badge);
  }

  Future<List<BadgeModel>> getByStudent(String studentId) async {
    final byStudent = filterBy((b) => b.studentId, studentId)
      ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
    return byStudent;
  }

  Future<bool> hasBadge(String studentId, String badgeId) async {
    final byStudent = filterBy((b) => b.studentId, studentId);
    return byStudent.any((b) => b.id == badgeId);
  }

  Future<Map<String, BadgeModel>> getBadgeMap(String studentId) async {
    final badges = await getByStudent(studentId);
    return {for (final b in badges) b.id: b};
  }

  Future<int> getBadgeCount(String studentId) async {
    return filterBy((b) => b.studentId, studentId).length;
  }
}
