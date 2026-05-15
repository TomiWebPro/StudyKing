import 'package:studyking/features/dashboard/data/repositories/badge_repository.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import '../data/models/badge_model.dart';
import 'study_progress_tracker.dart';
import 'notification_service.dart';

class BadgeService {
  final BadgeRepository _repository;
  final StudyProgressTracker _tracker;
  final NotificationService _notificationService;

  BadgeService({
    BadgeRepository? repository,
    StudyProgressTracker? tracker,
    NotificationService? notificationService,
  })  : _repository = repository ?? BadgeRepository(),
        _tracker = tracker ?? StudyProgressTracker(attemptRepo: AttemptRepository()),
        _notificationService = notificationService ?? NotificationService();

  Future<List<BadgeModel>> getBadges(String studentId) async {
    await _repository.init();
    final badges = await _repository.getByStudent(studentId);
    return badges;
  }

  Future<List<BadgeModel>> checkAndUnlockBadges(String studentId) async {
    await _repository.init();
    final stats = await _tracker.getOverallStats(studentId);
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
        } catch (_) {}
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
