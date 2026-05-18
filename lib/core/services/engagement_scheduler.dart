import 'dart:async';
import 'package:studyking/core/constants/app_constants.dart';
import '../utils/logger.dart';
import '../../l10n/generated/app_localizations.dart';
import '../services/study_progress_tracker.dart';
import '../services/mastery_graph_service.dart';
import '../services/notification_service.dart';
import '../services/plan_adapter.dart';
import '../utils/number_format_utils.dart';
import 'package:studyking/features/planner/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/planner/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/planner/services/planner_service.dart';

class EngagementSchedulerConfig {
  final int checkHour;
  final int checkMinute;
  final String studentId;

  const EngagementSchedulerConfig({
    this.checkHour = 9,
    this.checkMinute = 0,
    this.studentId = 'default',
  });

  Duration get nextCheckDelay {
    final now = DateTime.now();
    final nextCheck = DateTime(now.year, now.month, now.day, checkHour, checkMinute);
    return nextCheck.isAfter(now)
        ? nextCheck.difference(now)
        : nextCheck.add(Timeouts.day).difference(now);
  }
}

class EngagementScheduler {
  final Logger _logger = const Logger('EngagementScheduler');
  final StudyProgressTracker _tracker;
  final MasteryGraphService _masteryService;
  final NotificationService _notificationService;
  final EngagementNudgeRepository _nudgeRepository;
  final PlanAdherenceRepository _adherenceRepository;
  final PlanAdapter? _planAdapter;
  final SessionRepository? _sessionRepository;
  final EngagementSchedulerConfig _config;
  final AppLocalizations? _l10n;
  SettingsBox? _settingsBox;
  final PlannerService? _plannerService;

  Timer? _dailyTimer;
  Timer? _lessonCheckTimer;
  bool _isInitialized = false;
  int _notificationIdCounter = 1000;

  EngagementScheduler({
    required StudyProgressTracker tracker,
    required MasteryGraphService masteryService,
    NotificationService? notificationService,
    EngagementNudgeRepository? nudgeRepository,
    PlanAdherenceRepository? adherenceRepository,
    PlanAdapter? planAdapter,
    SessionRepository? sessionRepository,
    EngagementSchedulerConfig? config,
    AppLocalizations? l10n,
    SettingsBox? settingsBox,
    PlannerService? plannerService,
  })  :         _tracker = tracker,
        _masteryService = masteryService,
        _notificationService = notificationService ?? NotificationService(),
        _nudgeRepository = nudgeRepository ?? EngagementNudgeRepository(),
        _adherenceRepository = adherenceRepository ?? PlanAdherenceRepository(),
        _planAdapter = planAdapter,
        _sessionRepository = sessionRepository,
        _config = config ?? const EngagementSchedulerConfig(),
        _l10n = l10n,
        _settingsBox = settingsBox,
        _plannerService = plannerService;

  void updateSettings(SettingsBox settingsBox) {
    _settingsBox = settingsBox;
  }

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await _notificationService.init();
    await _nudgeRepository.init();
    await _adherenceRepository.init();
    _scheduleDailyCheck();
    _startLessonCheckTimer();
  }

  void _startLessonCheckTimer() {
    _lessonCheckTimer?.cancel();
    _lessonCheckTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await _checkUpcomingLessons();
    });
    _checkUpcomingLessons();
  }

  void _scheduleDailyCheck() {
    _dailyTimer = Timer(_config.nextCheckDelay, _runDailyChecks);
  }

  Future<void> _runDailyChecks() async {
    _scheduleDailyCheck();
    await _sendNudgeNotifications(_config.studentId);
  }

  Future<void> runDailyChecksNow() async {
    await _sendNudgeNotifications(_config.studentId);
    await _checkUpcomingLessons();
  }

  bool _isNotificationEnabled(String nudgeType) {
    final s = _settingsBox;
    if (s == null) return true;
    if (!s.studyRemindersEnabled) return false;
    return switch (nudgeType) {
      'overwork' => s.overworkAlertsEnabled,
      'revision' => s.revisionRemindersEnabled,
      'planAdjustment' => s.planAdjustmentNotificationsEnabled,
      'lessonReminder' => s.lessonNotificationsEnabled,
      _ => true,
    };
  }

  Future<void> _checkUpcomingLessons() async {
    final s = _settingsBox;
    if (s != null && (!s.studyRemindersEnabled || !s.lessonNotificationsEnabled)) return;
    if (_plannerService == null) return;
    try {
      final lessons = await _plannerService.getScheduledLessons();
      final now = DateTime.now();
      for (final lesson in lessons) {
        if (lesson.completed || lesson.endTime != null) continue;
        final diff = lesson.startTime.difference(now);
        if (diff.inMinutes > 0 && diff.inMinutes <= 30) {
          final title = lesson.tutorMetadata?.topicTitle ?? lesson.topicId ?? 'Lesson';
          await _notificationService.showLessonReminder(
            id: _notificationIdCounter++,
            lessonTitle: title,
            startTime: lesson.startTime,
          );
        }
      }
    } catch (e) {
      _logger.w('Failed to check upcoming lessons: $e');
    }
  }

  Future<void> _sendNudgeNotifications(String studentId) async {
    if (!_isNotificationEnabled('overwork')) {
      _logger.d('Overwork nudges disabled by user preferences');
    } else {
      try {
        final overworkNudges = await getOverworkNudge(studentId);
        for (final nudge in overworkNudges) {
          final model = EngagementNudgeModel(
            id: 'overwork_${DateTime.now().millisecondsSinceEpoch}_$studentId',
            studentId: studentId,
            nudgeType: NudgeType.overwork.name,
            message: nudge.message,
            severity: nudge.severity.name,
          );
          await _nudgeRepository.create(model);
          await _notificationService.showOverworkWarning(
            id: _notificationIdCounter++,
            hoursStudied: double.tryParse(
                    nudge.message.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                0,
          );
        }
      } catch (e) {
        _logger.w('Failed to send overwork nudge: $e');
      }
    }

    if (!_isNotificationEnabled('revision')) {
      _logger.d('Revision nudges disabled by user preferences');
    } else {
      try {
        final revisionNudges = await getRevisionNudges(studentId);
        for (final nudge in revisionNudges) {
          final model = EngagementNudgeModel(
            id: 'revision_${DateTime.now().millisecondsSinceEpoch}_$studentId',
            studentId: studentId,
            nudgeType: NudgeType.revision.name,
            message: nudge.message,
            severity: nudge.severity.name,
            topicId: nudge.topicId,
          );
          await _nudgeRepository.create(model);
          if (nudge.topicId != null) {
            final daysMatch = RegExp(r'(\d+)').firstMatch(nudge.message);
            final days = daysMatch != null ? int.parse(daysMatch.group(1)!) : 3;
            await _notificationService.showRevisionNudge(
              id: _notificationIdCounter++,
              topicName: nudge.topicId!,
              daysSinceLastPractice: days,
            );
          }
        }
      } catch (e) {
        _logger.w('Failed to send revision nudge: $e');
      }
    }

    if (!_isNotificationEnabled('planAdjustment')) {
      _logger.d('Plan adjustment nudges disabled by user preferences');
    } else {
      try {
        final planNudges = await getPlanAdjustmentNudge(studentId);
        for (final nudge in planNudges) {
          final model = EngagementNudgeModel(
            id: 'plan_${DateTime.now().millisecondsSinceEpoch}_$studentId',
            studentId: studentId,
            nudgeType: NudgeType.planAdjustment.name,
            message: nudge.message,
            severity: nudge.severity.name,
          );
          await _nudgeRepository.create(model);
          final daysMatch = RegExp(r'(\d+)').firstMatch(nudge.message);
          final days = daysMatch != null ? int.parse(daysMatch.group(1)!) : 3;
          await _notificationService.showPlanAdjustmentSuggestion(
            id: _notificationIdCounter++,
            consecutiveLowDays: days,
          );
        }
      } catch (e) {
        _logger.w('Failed to send plan adjustment nudge: $e');
      }
    }

    if (!_isNotificationEnabled('weakTopics')) {
      _logger.d('Weak topics nudges disabled by user preferences');
    } else {
      try {
        final weakResult = await _masteryService.getWeakTopics(studentId);
        if (weakResult.isSuccess && weakResult.data!.isNotEmpty) {
          await _notificationService.showLowMasteryWarning(
            id: _notificationIdCounter++,
            weakTopics: weakResult.data!.map((s) => s.topicId).toList(),
          );
        }
      } catch (e) {
        _logger.w('Failed to check weak topics for nudge: $e');
      }
    }

    if (_planAdapter != null) {
      try {
        final deviation = await _planAdapter.checkAdherence(studentId);
        if (deviation.isSuccess && deviation.data!.requiresRegeneration) {
          final model = EngagementNudgeModel(
            id: 'adp_reg_${DateTime.now().millisecondsSinceEpoch}_$studentId',
            studentId: studentId,
            nudgeType: NudgeType.autoRegeneration.name,
            message: deviation.data!.message,
            severity: deviation.data!.requiresEscalation
                ? NudgeSeverity.high.name
                : NudgeSeverity.medium.name,
          );
          await _nudgeRepository.create(model);
        }
      } catch (e) {
        _logger.w('Failed to check plan adherence: $e');
      }
    }
  }

  Future<List<EngagementNudge>> getOverworkNudge(String studentId) async {
    double totalHours = 0;
    try {
      final stats = await _tracker.getOverallStats(studentId);
      totalHours = (stats['totalStudyTimeHours'] as num?)?.toDouble() ?? 0;
    } catch (e) {
      _logger.w('Failed to get overall stats for overwork nudge: $e');
    }

    if (_sessionRepository != null) {
      try {
        final todayResult = await _sessionRepository.getByDate(DateTime.now());
        final todaySessions = todayResult.data ?? [];
        final totalMs = todaySessions.fold<int>(0, (sum, s) => sum + s.actualDurationMs);
        final sessionHours = totalMs / 3600000;
        if (sessionHours > totalHours) {
          totalHours = sessionHours;
        }
      } catch (e) {
        _logger.w('Failed to get today sessions for overwork nudge: $e');
      }
    }

    if (totalHours > 4) {
      final localeName = _l10n?.localeName ?? 'en';
      final hoursStr = formatDecimal(totalHours, localeName, minFractionDigits: 1, maxFractionDigits: 1);
      return [EngagementNudge(
        type: NudgeType.overwork,
        message: _l10n?.nudgeOverwork(hoursStr)
            ?? 'You have studied $hoursStr hours today. Consider taking a break!',
        severity: NudgeSeverity.medium,
      )];
    }
    return [];
  }

  Future<List<EngagementNudge>> getRevisionNudges(String studentId) async {
    final nudges = <EngagementNudge>[];
    final weakResult = await _masteryService.getTopicsNeedingReview(studentId);
    if (weakResult.isSuccess) {
      for (final state in weakResult.data!) {
        final daysSince = DateTime.now().difference(state.lastAttempt).inDays;
        if (daysSince >= 3) {
          nudges.add(EngagementNudge(
            type: NudgeType.revision,
            message: _l10n?.nudgeRevision(daysSince, state.topicId)
                ?? 'It has been $daysSince days since you practiced "${state.topicId}". Time for a review!',
            severity: daysSince >= 7 ? NudgeSeverity.high : NudgeSeverity.low,
            topicId: state.topicId,
          ));
        }
      }
    }
    return nudges;
  }

  Future<List<EngagementNudge>> getPlanAdjustmentNudge(String studentId) async {
    final nudges = <EngagementNudge>[];
    try {
      final consecutiveLow = await _adherenceRepository.getConsecutiveLowAdherenceDays(studentId);
      if (consecutiveLow >= 3) {
        nudges.add(EngagementNudge(
          type: NudgeType.planAdjustment,
          message: _l10n?.nudgePlanAdjustment(consecutiveLow)
              ?? 'You have had $consecutiveLow days of low plan adherence. Would you like to adjust your study plan?',
          severity: NudgeSeverity.medium,
        ));
      }
    } catch (e) {
      _logger.w('Failed to get plan adjustment nudge: $e');
    }
    return nudges;
  }

  Future<String> getWeeklyDigest(String studentId) async {
    final stats = await _tracker.getOverallStats(studentId);
    final accuracy = stats['accuracy'] as int? ?? 0;
    final rawHours = (stats['totalStudyTimeHours'] as num?)?.toDouble() ?? 0.0;
    final localeName = _l10n?.localeName ?? 'en';
    final totalHours = formatDecimal(rawHours, localeName, minFractionDigits: 1, maxFractionDigits: 1);
    final weeklyActivity = stats['weeklyActivity'] as int? ?? 0;
    final badges = await _tracker.getBadges(studentId);
    final weakResult = await _masteryService.getWeakTopics(studentId);
    final weakCount = weakResult.isSuccess ? weakResult.data!.length : 0;
    return _l10n?.nudgeWeeklyDigest(
          weeklyActivity,
          accuracy,
          totalHours,
          weakCount,
          badges.length,
        ) ??
        'Weekly Digest: $weeklyActivity questions answered, $accuracy% accuracy, $totalHours hours studied, $weakCount weak areas, ${badges.length} badges earned.';
  }

  Future<List<EngagementNudgeModel>> getNudgeHistory(String studentId) async {
    final result = await _nudgeRepository.getByStudent(studentId);
    return result.data ?? [];
  }

  void dispose() {
    _dailyTimer?.cancel();
    _lessonCheckTimer?.cancel();
  }
}

// NudgeType and NudgeSeverity are imported from engagement_nudge_model.dart

class EngagementNudge {
  final NudgeType type;
  final String message;
  final NudgeSeverity severity;
  final String? topicId;

  EngagementNudge({
    required this.type,
    required this.message,
    required this.severity,
    this.topicId,
  });
}
