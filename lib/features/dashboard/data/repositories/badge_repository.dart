import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/dashboard/data/models/badge_model.dart';
import 'package:studyking/core/data/repository.dart';

class BadgeRepository extends Repository<BadgeModel> {
  static final Logger _logger = const Logger('BadgeRepository');

  BadgeRepository() : super(boxName: HiveBoxNames.badges);

  Future<void> init() async {
    await openBox(HiveBoxNames.badges);
  }

  Future<void> create(BadgeModel badge) async {
    await save(badge.id, badge);
  }

  Future<Result<List<BadgeModel>>> getByStudent(String studentId) async {
    try {
      final byStudent = filterBy((b) => b.studentId, studentId)
        ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
      return Result.success(byStudent);
    } catch (e) {
      _logger.w('Failed to getByStudent for $studentId: $e', e);
      return Result.failure('Failed to getByStudent: $e');
    }
  }

  Future<Result<bool>> hasBadge(String studentId, String badgeId) async {
    try {
      final byStudent = filterBy((b) => b.studentId, studentId);
      return Result.success(byStudent.any((b) => b.id == badgeId));
    } catch (e) {
      _logger.w('Failed to hasBadge for $studentId badge $badgeId: $e', e);
      return Result.failure('Failed to hasBadge: $e');
    }
  }

  Future<Result<Map<String, BadgeModel>>> getBadgeMap(String studentId) async {
    try {
      final badgesResult = await getByStudent(studentId);
      if (badgesResult.isFailure) {
        return Result.failure(badgesResult.error);
      }
      final badges = badgesResult.data!;
      return Result.success({for (final b in badges) b.id: b});
    } catch (e) {
      _logger.w('Failed to getBadgeMap for $studentId: $e', e);
      return Result.failure('Failed to getBadgeMap: $e');
    }
  }

  Future<Result<int>> getBadgeCount(String studentId) async {
    try {
      final count = filterBy((b) => b.studentId, studentId).length;
      return Result.success(count);
    } catch (e) {
      _logger.w('Failed to getBadgeCount for $studentId: $e', e);
      return Result.failure('Failed to getBadgeCount: $e');
    }
  }
}
