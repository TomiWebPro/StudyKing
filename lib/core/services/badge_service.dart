import 'package:studyking/features/dashboard/data/repositories/badge_repository.dart';
import 'package:studyking/features/dashboard/data/models/badge_model.dart';
import 'package:studyking/core/utils/logger.dart';
import 'notification_service.dart';

class BadgeService {
  final BadgeRepository _repository;
  final Future<Map<String, dynamic>> Function(String)? _getStats;
  final NotificationService _notificationService;

  BadgeService({
    BadgeRepository? repository,
    Future<Map<String, dynamic>> Function(String)? getStats,
    NotificationService? notificationService,
  })  : _repository = repository ?? BadgeRepository(),
        _getStats = getStats,
        _notificationService = notificationService ?? NotificationService();

  Future<List<BadgeModel>> getBadges(String studentId) async {
    await _repository.init();
    final badges = await _repository.getByStudent(studentId);
    return badges;
  }

  Future<List<BadgeModel>> checkAndUnlockBadges(String studentId) async {
    await _repository.init();
    final stats = _getStats != null ? await _getStats(studentId) : <String, dynamic>{};
    final existing = await _repository.getBadgeMap(studentId);
    final newlyUnlocked = <BadgeModel>[];

    for (final definition in BadgeDefinitions.all) {
      if (existing.containsKey(definition.id)) continue;

      if (definition.isSatisfiedBy(stats)) {
        final badge = BadgeModel(
          id: '${definition.id}_$studentId',
          studentId: studentId,
          name: definition.name,
          description: definition.description,
          iconName: definition.iconName,
          category: definition.category,
          criteria: {
            'key': definition.checkKey,
            'value': definition.checkValue,
            'actual': stats[definition.checkKey],
          },
        );

        await _repository.create(badge);
        newlyUnlocked.add(badge);

        try {
          await _notificationService.showBadgeUnlocked(
            id: DateTime.now().millisecondsSinceEpoch,
            badgeName: definition.name,
            badgeDescription: definition.description,
          );
        } catch (e) {
          const Logger('BadgeService').e('Failed to show badge notification', e);
        }
      }
    }

    return newlyUnlocked;
  }

  Future<bool> hasBadge(String studentId, String badgeId) async {
    await _repository.init();
    return _repository.hasBadge(studentId, badgeId);
  }

  Future<int> getBadgeCount(String studentId) async {
    await _repository.init();
    return _repository.getBadgeCount(studentId);
  }

  Future<Map<String, List<BadgeModel>>> getBadgesByCategory(
      String studentId) async {
    final badges = await getBadges(studentId);
    final categorized = <String, List<BadgeModel>>{};
    for (final badge in badges) {
      categorized.putIfAbsent(badge.category, () => []);
      categorized[badge.category]!.add(badge);
    }
    return categorized;
  }

  Future<List<BadgeDefinition>> getLockedBadges(String studentId) async {
    await _repository.init();
    final existing = await _repository.getBadgeMap(studentId);
    return BadgeDefinitions.all
        .where((d) => !existing.containsKey(d.id))
        .toList();
  }

  Future<Map<String, dynamic>> getBadgeStats(String studentId) async {
    final badges = await getBadges(studentId);
    final allDefs = BadgeDefinitions.all;
    return {
      'total': allDefs.length,
      'unlocked': badges.length,
      'locked': allDefs.length - badges.length,
      'completionPercentage':
          allDefs.isEmpty ? 0.0 : badges.length / allDefs.length,
    };
  }
}
