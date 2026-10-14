import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/constants/notification_ids.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import '../utils/logger.dart';
import '../utils/clock.dart';
import '../errors/result.dart';
import '../../l10n/generated/app_localizations.dart';
import '../services/study_progress_tracker.dart';
import '../services/mastery_graph_service.dart';
import '../services/notification_service.dart';
import '../services/plan_adherence_orchestrator.dart';
import '../services/settings_service.dart';
import '../utils/number_format_utils.dart';
import 'package:studyking/features/mentor/services/mentor_service.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/core/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/core/data/models/session_model.dart';

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

/// Calendar-day difference `a - b` in whole days. Both arguments
/// are local timestamps; the computation is done on UTC-normalized
/// dates so a DST transition (a 23h or 25h calendar day) cannot
/// shift the result the way elapsed-time `difference().inDays` does.
int _calendarDayDiff(DateTime a, DateTime b) {
  final utcA = DateTime.utc(a.year, a.month, a.day);
  final utcB = DateTime.utc(b.year, b.month, b.day);
  return utcA.difference(utcB).inDays;
}

class EngagementScheduler {
  static final Logger _logger = const Logger('EngagementScheduler');

  final StudyProgressTracker _tracker;
  final MasteryGraphService _masteryService;
  final NotificationService _notificationService;
  final EngagementNudgeRepository _nudgeRepository;
  final PlanAdherenceRepository _adherenceRepository;
  final PlanAdherenceOrchestrator? _planOrchestrator;
  final SessionRepository? _sessionRepository;
  final EngagementSchedulerConfig _config;
  AppLocalizations _l10n;
  SettingsBox? _settingsBox;
  final   PlannerService? _plannerService;
  final MentorService? _mentorService;
  final Clock _clock;

  Timer? _dailyTimer;
  Timer? _lessonCheckTimer;
  bool _isInitialized = false;
  int _notificationIdCounter = 1000;
  /// Lesson ids that already had an upcoming-lesson reminder shown for
  /// the current 30-minute window. The 5-minute lesson check
  /// re-evaluates the same window on every tick, so without this set
  /// each tick would stack another notification for the same lesson.
  /// Entries are cleared once the lesson starts or completes.
  final Set<String> _notifiedLessonKeys = {};
  ({bool enabled, int hour, int minute})? _lastAppliedDailyReminder;

  EngagementScheduler({
    required StudyProgressTracker tracker,
    required MasteryGraphService masteryService,
    NotificationService? notificationService,
    EngagementNudgeRepository? nudgeRepository,
    PlanAdherenceRepository? adherenceRepository,
    PlanAdherenceOrchestrator? planOrchestrator,
    SessionRepository? sessionRepository,
    EngagementSchedulerConfig? config,
    required AppLocalizations l10n,
    SettingsBox? settingsBox,
    PlannerService? plannerService,
    MentorService? mentorService,
    Clock? clock,
  })  :         _tracker = tracker,
        _masteryService = masteryService,
        _notificationService = notificationService ?? NotificationService(),
        _nudgeRepository = nudgeRepository ?? EngagementNudgeRepository(),
        _adherenceRepository = adherenceRepository ?? PlanAdherenceRepository(),
        _planOrchestrator = planOrchestrator,
        _sessionRepository = sessionRepository,
        _config = config ?? const EngagementSchedulerConfig(),
        _l10n = l10n,
        _settingsBox = settingsBox,
        _plannerService = plannerService,
        _mentorService = mentorService,
        _clock = clock ?? SystemClock();

  Future<Result<void>> updateSettings(SettingsBox settingsBox) async {
    _settingsBox = settingsBox;
    await _syncDailyReminderSchedule();
    return Result.success(null);
  }

  /// Keeps the OS daily-reminder alarm in sync with the persisted
  /// settings: registers the alarm at the persisted time-of-day when
  /// daily reminders are enabled and cancels it when they are disabled.
  ///
  /// Settings flow through [updateSettings] both at app startup
  /// (re-registering the alarm after a reboot cleared it) and on every
  /// settings change (so flipping the toggle on or off takes effect
  /// immediately). The last-applied reminder spec is tracked so
  /// unrelated settings updates do not re-register the alarm.
  Future<void> _syncDailyReminderSchedule() async {
    final settings = _settingsBox;
    if (settings == null) return;
    final spec = (
      enabled: settings.dailyReminderEnabled,
      hour: settings.dailyReminderHour,
      minute: settings.dailyReminderMinute,
    );
    if (spec == _lastAppliedDailyReminder) return;
    _lastAppliedDailyReminder = spec;
    try {
      _notificationService.setAppLocalizations(_l10n);
      final initResult = await _notificationService.init();
      if (initResult.isFailure) {
        _logger.w('NotificationService init failed: ${initResult.error}');
        return;
      }
      if (spec.enabled) {
        final scheduleResult = await _notificationService.showDailyReminder(
          id: NotificationIds.dailyReminder,
          title: _l10n.dailyReminderNotificationTitle,
          body: _l10n.dailyReminderNotificationBody,
          remindAt: TimeOfDay(hour: spec.hour, minute: spec.minute),
          payload: 'daily_reminder',
        );
        if (scheduleResult.isFailure) {
          _logger.w(
            'Failed to schedule daily reminder: ${scheduleResult.error}',
          );
        }
      } else {
        final cancelResult = await _notificationService.cancelNotification(
          NotificationIds.dailyReminder,
        );
        if (cancelResult.isFailure) {
          _logger.w(
            'Failed to cancel daily reminder: ${cancelResult.error}',
          );
        }
      }
    } catch (e) {
      _logger.w('Failed to sync daily reminder schedule', e);
    }
  }

  Future<Result<void>> updateLocalization(AppLocalizations l10n) async {
    _l10n = l10n;
    _notificationService.setAppLocalizations(l10n);
    _planOrchestrator?.updateLocalization(l10n);
    return Result.success(null);
  }

  Future<Result<void>> init() async {
    try {
      if (_isInitialized) return Result.success(null);
      _isInitialized = true;
      final notifResult = await _notificationService.init();
      if (notifResult.isFailure) {
        _logger.w('NotificationService init failed: ${notifResult.error}');
      }
      await _nudgeRepository.init();
      await _adherenceRepository.init();
      await _backfillMissedChecks();
      await _autoFinalizeStaleSessions();
      _scheduleDailyCheck();
      _startLessonCheckTimer();
      return Result.success(null);
    } catch (e) {
      _logger.w('EngagementScheduler.init failed: $e');
      return Result.failure(e.toString());
    }
  }

  Future<void> _backfillMissedChecks() async {
    try {
      final schedulerBoxKey = 'scheduler_last_run';
      Box? schedulerBox;
      if (Hive.isBoxOpen(HiveBoxNames.settings)) {
        schedulerBox = Hive.box(HiveBoxNames.settings);
      } else {
        schedulerBox = await Hive.openBox(HiveBoxNames.settings);
      }
      final lastRunStr = schedulerBox.get(schedulerBoxKey) as String?;
      final lastRun = lastRunStr != null ? DateTime.tryParse(lastRunStr) : null;
      final now = _clock.now();

      if (lastRun != null) {
        // Calendar-day count: elapsed-time `difference().inDays`
        // truncates a 23h/25h DST day and would undercount the
        // days the user was away, delaying the welcome-back nudge.
        final missedDays = _calendarDayDiff(now, lastRun);
        if (missedDays >= 2) {
          final createResult = await _nudgeRepository.create(EngagementNudgeModel(
            id: 'missed_backfill_${now.millisecondsSinceEpoch}_${_config.studentId}',
            studentId: _config.studentId,
            nudgeType: NudgeType.planAdjustment.name,
            message: _l10n.welcomeBackDays(missedDays),
            severity: missedDays >= 7 ? NudgeSeverity.high.name : NudgeSeverity.medium.name,
          ));
          if (createResult.isFailure) {
            _logger.w('Failed to persist welcome-back nudge', createResult.error);
          }
        }
      }

      await schedulerBox.put(schedulerBoxKey, now.toIso8601String());
    } catch (e) {
      _logger.w('Failed to backfill missed scheduler checks: $e');
    }
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
    await _sendMentorNudges();
  }

  Future<void> _sendMentorNudges() async {
    final mentorService = _mentorService;
    if (mentorService == null) return;
    if (!_isNotificationEnabled('mentor')) return;
    final frequencyDays = _getMentorCheckinFrequency();
    if (frequencyDays == 0) return;
    try {
      final result = await mentorService.checkWellbeingAndGenerateNudges();
      final nudges = result.data ?? [];
      if (nudges.isNotEmpty) {
        final notifResult = await _notificationService.showMentorMessage(
          id: _notificationIdCounter++,
          title: _l10n.mentorCheckIn,
          body: nudges.first.length > 120
              ? '${nudges.first.substring(0, 120)}...'
              : nudges.first,
        );
        if (notifResult.isFailure) {
          _logger.w('Failed to show mentor nudge notification: ${notifResult.error}');
        }
      }
    } catch (e) {
      _logger.w('Failed to send mentor nudges: $e');
    }
  }

  int _getMentorCheckinFrequency() {
    try {
      return SettingsService.getMentorCheckinFrequency();
    } catch (e) {
      _logger.w('Failed to get mentor checkin frequency: $e');
      return 1;
    }
  }

  Future<Result<void>> runDailyChecksNow() async {
    try {
      await _sendNudgeNotifications(_config.studentId);
      await _checkUpcomingLessons();
      return Result.success(null);
    } catch (e) {
      _logger.w('runDailyChecksNow failed: $e');
      return Result.failure(e.toString());
    }
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
      final lessonsResult = await _plannerService.getScheduledLessons();
      final lessons = lessonsResult.data ?? [];
      final now = DateTime.now();
      for (final lesson in lessons) {
        final lessonKey = lesson.id;
        if (lesson.completed || lesson.endTime != null) {
          // The lesson is over; stop tracking it so a lesson that is
          // rescheduled into a future window can be reminded about again.
          _notifiedLessonKeys.remove(lessonKey);
          continue;
        }
        final diff = lesson.startTime.difference(now);
        if (diff.inMinutes <= 0) {
          // The reminder window has passed; drop the key so the
          // tracked set does not grow without bound.
          _notifiedLessonKeys.remove(lessonKey);
          continue;
        }
        if (diff.inMinutes > 30) continue;
        // Each lesson is reminded about at most once per window:
        // every 5-minute tick matches the same lesson for up to 30
        // minutes, so re-notifying would stack duplicates.
        if (_notifiedLessonKeys.contains(lessonKey)) continue;
        final title = lesson.tutorMetadata?.topicTitle ?? lesson.topicId ?? 'Lesson';
        final notifResult = await _notificationService.showLessonReminder(
          id: _notificationIdCounter++,
          lessonTitle: title,
          startTime: lesson.startTime,
        );
        if (notifResult.isSuccess) {
          _notifiedLessonKeys.add(lessonKey);
        } else {
          // Leave the key untracked so a failed reminder is retried
          // on the next tick while the lesson is still upcoming.
          _logger.w('Failed to show lesson reminder notification: ${notifResult.error}');
        }
      }
    } catch (e) {
      _logger.w('Failed to check upcoming lessons: $e');
    }
  }

  Future<void> _sendNudgeNotifications(String studentId) async {
    await _sendOverworkNudges(studentId);
    await _sendRevisionNudges(studentId);
    await _sendPlanAdjustmentNudges(studentId);
    await _sendWeakTopicNudges(studentId);
    await _sendAdherenceNudges(studentId);
  }

  Future<void> _sendOverworkNudges(String studentId) async {
    if (!_isNotificationEnabled('overwork')) {
      _logger.d('Overwork nudges disabled by user preferences');
      return;
    }
    try {
      final nudgesResult = await getOverworkNudge(studentId);
      final nudges = nudgesResult.data ?? [];
      for (final nudge in nudges) {
        final createResult = await _nudgeRepository.create(nudge);
        if (createResult.isFailure) {
          _logger.w('Failed to persist overwork nudge', createResult.error);
          continue;
        }
        final notifResult = await _notificationService.showOverworkWarning(
          id: _notificationIdCounter++,
          hoursStudied: nudge.hoursStudied ?? 0.0,
        );
        if (notifResult.isFailure) {
          _logger.w('Failed to show overwork warning notification: ${notifResult.error}');
        }
      }
    } catch (e) {
      _logger.w('Failed to send overwork nudge: $e');
    }
  }

  Future<void> _sendRevisionNudges(String studentId) async {
    if (!_isNotificationEnabled('revision')) {
      _logger.d('Revision nudges disabled by user preferences');
      return;
    }
    try {
      final nudgesResult = await getRevisionNudges(studentId);
      final nudges = nudgesResult.data ?? [];
      for (final nudge in nudges) {
        final createResult = await _nudgeRepository.create(nudge);
        if (createResult.isFailure) {
          _logger.w('Failed to persist revision nudge', createResult.error);
          continue;
        }
        if (nudge.topicId != null) {
          final days = _extractInt(nudge.message) ?? 3;
          final notifResult = await _notificationService.showRevisionNudge(
            id: _notificationIdCounter++,
            topicName: nudge.topicId!,
            daysSinceLastPractice: days,
          );
          if (notifResult.isFailure) {
            _logger.w('Failed to show revision nudge notification: ${notifResult.error}');
          }
        }
      }
    } catch (e) {
      _logger.w('Failed to send revision nudge: $e');
    }
  }

  Future<void> _sendPlanAdjustmentNudges(String studentId) async {
    if (!_isNotificationEnabled('planAdjustment')) {
      _logger.d('Plan adjustment nudges disabled by user preferences');
      return;
    }
    try {
      final nudgesResult = await getPlanAdjustmentNudge(studentId);
      final nudges = nudgesResult.data ?? [];
      for (final nudge in nudges) {
        final createResult = await _nudgeRepository.create(nudge);
        if (createResult.isFailure) {
          _logger.w('Failed to persist plan adjustment nudge', createResult.error);
          continue;
        }
        final days = _extractInt(nudge.message) ?? 3;
        final notifResult = await _notificationService.showPlanAdjustmentSuggestion(
          id: _notificationIdCounter++,
          consecutiveLowDays: days,
        );
        if (notifResult.isFailure) {
          _logger.w('Failed to show plan adjustment notification: ${notifResult.error}');
        }
      }
    } catch (e) {
      _logger.w('Failed to send plan adjustment nudge: $e');
    }
  }

  Future<void> _sendWeakTopicNudges(String studentId) async {
    if (!_isNotificationEnabled('weakTopics')) {
      _logger.d('Weak topics nudges disabled by user preferences');
      return;
    }
    try {
      final weakResult = await _masteryService.getWeakTopics(studentId);
      if (weakResult.isSuccess && weakResult.data!.isNotEmpty) {
        final notifResult = await _notificationService.showLowMasteryWarning(
          id: _notificationIdCounter++,
          weakTopics: weakResult.data!.map((s) => s.topicId).toList(),
        );
        if (notifResult.isFailure) {
          _logger.w('Failed to show low mastery warning notification: ${notifResult.error}');
        }
      }
    } catch (e) {
      _logger.w('Failed to check weak topics for nudge: $e');
    }
  }

  Future<void> _sendAdherenceNudges(String studentId) async {
    final orchestrator = _planOrchestrator;
    if (orchestrator == null) return;
    try {
      final deviation = await orchestrator.checkAdherence(studentId);
      if (deviation.isSuccess && deviation.data!.requiresRegeneration) {
        final createResult = await _nudgeRepository.create(EngagementNudgeModel(
          id: 'adp_reg_${DateTime.now().millisecondsSinceEpoch}_$studentId',
          studentId: studentId,
          nudgeType: NudgeType.autoRegeneration.name,
          message: deviation.data!.message,
          severity: deviation.data!.requiresEscalation
              ? NudgeSeverity.high.name
              : NudgeSeverity.medium.name,
        ));
        if (createResult.isFailure) {
          _logger.w('Failed to persist auto-regeneration nudge', createResult.error);
        }
      }
    } catch (e) {
      _logger.w('Failed to check plan adherence: $e');
    }
  }

  Future<void> _autoFinalizeStaleSessions() async {
    final sessionRepo = _sessionRepository;
    if (sessionRepo == null) return;
    try {
      final allResult = await sessionRepo.getAll();
      if (allResult.isFailure) return;
      final sessions = allResult.data ?? [];
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(hours: 24));
      for (final session in sessions) {
        if (session.endTime == null && !session.completed && session.startTime.isBefore(cutoff)) {
          final finalized = session.copyWith(
            status: SessionStatus.cancelled,
            endTime: session.startTime.add(
              Duration(minutes: session.plannedDurationMinutes ?? 30),
            ),
            completed: false,
          );
          final saveResult = await _sessionRepository!.save(finalized.id, finalized);
          if (saveResult.isFailure) {
            _logger.w(
              'Failed to persist auto-finalized stale session ${session.id}',
              saveResult.error,
            );
            continue;
          }
          _logger.w('Auto-finalized stale session: ${session.id}');
        }
      }
    } catch (e) {
      _logger.w('Failed to auto-finalize stale sessions: $e');
    }
  }

  int? _extractInt(String message) {
    final match = RegExp(r'(\d+)').firstMatch(message);
    return match != null ? int.parse(match.group(1)!) : null;
  }

  Future<Result<List<EngagementNudgeModel>>> getOverworkNudge(String studentId) async {
    try {
      // The overwork signal must be TODAY's study time only. The all-time
      // cumulative total in getOverallStats would make the daily check fire
      // every day for any student over the threshold lifetime hours, and would
      // report the lifetime total as "hours studied today".
      double todayHours = 0;
      final sessionRepo = _sessionRepository;
      if (sessionRepo != null) {
        final todayMsResult = await sessionRepo.getTodayDurationMs();
        if (todayMsResult.isSuccess) {
          todayHours = (todayMsResult.data ?? 0) / 3600000;
        } else {
          _logger.w('Failed to get today study duration for overwork nudge: ${todayMsResult.error}');
        }
      }

      if (todayHours > Timeouts.overworkThresholdHours) {
        final localeName = _l10n.localeName;
        final hoursStr = formatDecimal(todayHours, localeName, minFractionDigits: 1, maxFractionDigits: 1);
        return Result.success([EngagementNudgeModel(
          id: 'overwork_${DateTime.now().millisecondsSinceEpoch}_$studentId',
          studentId: studentId,
          nudgeType: NudgeType.overwork.name,
          message: _l10n.nudgeOverwork(hoursStr),
          severity: NudgeSeverity.medium.name,
          hoursStudied: todayHours,
        )]);
      }
      return Result.success([]);
    } catch (e) {
      _logger.w('getOverworkNudge failed: $e');
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<EngagementNudgeModel>>> getRevisionNudges(String studentId) async {
    try {
      final nudges = <EngagementNudgeModel>[];
      final now = _clock.now();
      final weakResult = await _masteryService.getTopicsNeedingReview(studentId);
      if (weakResult.isSuccess) {
        for (final state in weakResult.data!) {
          // Calendar-day count: elapsed-time `difference().inDays`
          // truncates a 23h/25h DST day, so a 3-calendar-day gap
          // can compute as 2 days and suppress the revision nudge.
          final daysSince = _calendarDayDiff(now, state.lastAttempt);
          if (daysSince >= 3) {
            nudges.add(EngagementNudgeModel(
              id: 'revision_${DateTime.now().millisecondsSinceEpoch}_$studentId',
              studentId: studentId,
              nudgeType: NudgeType.revision.name,
              message: _l10n.nudgeRevision(daysSince, state.topicId),
              severity: daysSince >= 7 ? NudgeSeverity.high.name : NudgeSeverity.low.name,
              topicId: state.topicId,
            ));
          }
        }
      }
      return Result.success(nudges);
    } catch (e) {
      _logger.w('getRevisionNudges failed: $e');
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<EngagementNudgeModel>>> getPlanAdjustmentNudge(String studentId) async {
    try {
      final nudges = <EngagementNudgeModel>[];
      final consecutiveLowResult = await _adherenceRepository.getConsecutiveLowAdherenceDays(studentId);
      final consecutiveLow = consecutiveLowResult.data ?? 0;
      if (consecutiveLow >= 3) {
        nudges.add(EngagementNudgeModel(
          id: 'plan_${DateTime.now().millisecondsSinceEpoch}_$studentId',
          studentId: studentId,
          nudgeType: NudgeType.planAdjustment.name,
          message: _l10n.nudgePlanAdjustment(consecutiveLow),
          severity: NudgeSeverity.medium.name,
        ));
      }
      return Result.success(nudges);
    } catch (e) {
      _logger.w('getPlanAdjustmentNudge failed: $e');
      return Result.failure(e.toString());
    }
  }

  Future<Result<String>> getWeeklyDigest(String studentId) async {
    try {
      final statsResult = await _tracker.getOverallStats(studentId);
      final stats = statsResult.data ?? <String, dynamic>{};
      final accuracy = stats['accuracy'] as int? ?? 0;
      final rawHours = (stats['totalStudyTimeHours'] as num?)?.toDouble() ?? 0.0;
      final localeName = _l10n.localeName;
      final totalHours = formatDecimal(rawHours, localeName, minFractionDigits: 1, maxFractionDigits: 1);
      final weeklyActivity = stats['weeklyActivity'] as int? ?? 0;
      final badgesResult = await _tracker.getBadges(studentId);
      final badges = badgesResult.data ?? [];
      final weakResult = await _masteryService.getWeakTopics(studentId);
      final weakCount = weakResult.isSuccess ? weakResult.data!.length : 0;
      return Result.success(_l10n.nudgeWeeklyDigest(
        weeklyActivity,
        accuracy,
        totalHours,
        weakCount,
        badges.length,
      ));
    } catch (e) {
      _logger.w('getWeeklyDigest failed: $e');
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<EngagementNudgeModel>>> getNudgeHistory(String studentId) async {
    return _nudgeRepository.getByStudent(studentId);
  }

  void dispose() {
    _dailyTimer?.cancel();
    _lessonCheckTimer?.cancel();
  }
}

// NudgeType and NudgeSeverity are imported from engagement_nudge_model.dart
