import 'package:studyking/features/dashboard/data/repositories/badge_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/dashboard/data/models/badge_model.dart';
import 'package:studyking/core/utils/logger.dart';
import 'notification_service.dart';

class BadgeService {
  static final Logger _logger = const Logger('BadgeService');
  final BadgeRepository _repository;
  final Future<Result<Map<String, dynamic>>> Function(String)? _getStats;
  final NotificationService _notificationService;

  BadgeService({
    BadgeRepository? repository,
    Future<Result<Map<String, dynamic>>> Function(String)? getStats,
    NotificationService? notificationService,
  })  : _repository = repository ?? BadgeRepository(),
        _getStats = getStats,
        _notificationService = notificationService ?? NotificationService();

  Future<Result<List<BadgeModel>>> getBadges(String studentId) async {
    try {
      await _repository.init();
      final result = await _repository.getByStudent(studentId);
      if (result.isFailure) {
        _logger.w('getBadges failed for $studentId: ${result.error}');
        return Result.failure(result.error);
      }
      return Result.success(result.data!);
    } catch (e) {
      _logger.w('getBadges failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<BadgeModel>>> checkAndUnlockBadges(String studentId) async {
    try {
      await _repository.init();
      final statsResult = _getStats != null ? await _getStats(studentId) : null;
      if (statsResult != null && statsResult.isFailure) {
        _logger.w('getStats failed for $studentId: ${statsResult.error}');
      }
      final stats = statsResult != null && statsResult.isSuccess
          ? statsResult.data ?? <String, dynamic>{}
          : <String, dynamic>{};
      final existingResult = await _repository.getBadgeMap(studentId);
      if (existingResult.isFailure) {
        _logger.w('getBadgeMap failed for $studentId: ${existingResult.error}');
        return Result.failure(existingResult.error);
      }
      final existing = existingResult.data!;
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
            _logger.w('Failed to show badge notification', e);
          }
        }
      }

      return Result.success(newlyUnlocked);
    } catch (e) {
      _logger.w('checkAndUnlockBadges failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> hasBadge(String studentId, String badgeId) async {
    try {
      await _repository.init();
      final result = await _repository.hasBadge(studentId, badgeId);
      if (result.isFailure) {
        _logger.w('hasBadge failed for $studentId badge $badgeId: ${result.error}');
        return Result.failure(result.error);
      }
      return Result.success(result.data!);
    } catch (e) {
      _logger.w('hasBadge failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<int>> getBadgeCount(String studentId) async {
    try {
      await _repository.init();
      final result = await _repository.getBadgeCount(studentId);
      if (result.isFailure) {
        _logger.w('getBadgeCount failed for $studentId: ${result.error}');
        return Result.failure(result.error);
      }
      return Result.success(result.data!);
    } catch (e) {
      _logger.w('getBadgeCount failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<Map<String, List<BadgeModel>>>> getBadgesByCategory(
      String studentId) async {
    try {
      final badgesResult = await getBadges(studentId);
      if (badgesResult.isFailure) return Result.failure(badgesResult.error);
      final badges = badgesResult.data!;
      final categorized = <String, List<BadgeModel>>{};
      for (final badge in badges) {
        categorized.putIfAbsent(badge.category, () => []);
        categorized[badge.category]!.add(badge);
      }
      return Result.success(categorized);
    } catch (e) {
      _logger.w('getBadgesByCategory failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<BadgeDefinition>>> getLockedBadges(String studentId) async {
    try {
      await _repository.init();
      final existingResult = await _repository.getBadgeMap(studentId);
      if (existingResult.isFailure) {
        _logger.w('getLockedBadges failed for $studentId: ${existingResult.error}');
        return Result.failure(existingResult.error);
      }
      final existing = existingResult.data!;
      return Result.success(BadgeDefinitions.all
          .where((d) => !existing.containsKey(d.id))
          .toList());
    } catch (e) {
      _logger.w('getLockedBadges failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<Map<String, dynamic>>> getBadgeStats(String studentId) async {
    try {
      final badgesResult = await getBadges(studentId);
      if (badgesResult.isFailure) return Result.failure(badgesResult.error);
      final badges = badgesResult.data!;
      final allDefs = BadgeDefinitions.all;
      return Result.success({
        'total': allDefs.length,
        'unlocked': badges.length,
        'locked': allDefs.length - badges.length,
        'completionPercentage':
            allDefs.isEmpty ? 0.0 : badges.length / allDefs.length,
      });
    } catch (e) {
      _logger.w('getBadgeStats failed', e);
      return Result.failure(e.toString());
    }
  }
}
