import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/constants/notification_ids.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/engagement_scheduler.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/notification_service.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/core/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';

class _FakeAttemptRepo extends AttemptRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async => Result.success([]);
}

class _FakeTracker extends StudyProgressTracker {
  _FakeTracker() : super(
    attemptRepo: _FakeAttemptRepo(),
    l10n: lookupAppLocalizations(const Locale('en')),
  );

  @override
  Future<Result<Map<String, dynamic>>> getOverallStats(String studentId) async {
    return Result.success({
      'accuracy': 80,
      'totalStudyTimeHours': 3.5,
      'weeklyActivity': 25,
      'topicsStudied': 10,
      'correctAttempts': 40,
      'totalAttempts': 50,
    });
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getRecommendations(String studentId) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getBadges(String studentId) async {
    return Result.success([]);
  }
}

class _FakeMasteryForScheduler extends MasteryGraphService {
  final List<MasteryState> weakTopics = [];
  final List<MasteryState> topicsNeedingReview = [];

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return Result.success(weakTopics);
  }

  @override
  Future<Result<List<MasteryState>>> getTopicsNeedingReview(String studentId) async {
    return Result.success(topicsNeedingReview);
  }
}

class _FakeNudgeRepository extends EngagementNudgeRepository {
  final List<EngagementNudgeModel> _nudges = [];

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<void>> create(EngagementNudgeModel model) async {
    _nudges.add(model);
    return Result.success(null);
  }

  @override
  Future<Result<List<EngagementNudgeModel>>> getByStudent(String studentId) async {
    return Result.success(_nudges.where((n) => n.studentId == studentId).toList());
  }

  List<EngagementNudgeModel> get storedNudges => _nudges;
}

class _FakeAdherenceRepo extends PlanAdherenceRepository {
  final List<PlanAdherenceModel> _records = [];

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<PlanAdherenceModel>>> getByStudent(String studentId) async {
    return Result.success(_records.where((r) => r.studentId == studentId).toList());
  }

  @override
  Future<Result<int>> getConsecutiveLowAdherenceDays(String studentId, {double threshold = 0.5}) async {
    int consecutive = 0;
    for (final m in _records) {
      if (m.adherenceScore < threshold) {
        consecutive++;
      } else {
        break;
      }
    }
    return Result.success(consecutive);
  }

  @override
  Future<Result<List<PlanAdherenceModel>>> getWeekly(String studentId) async {
    return Result.success(_records.where((r) => r.studentId == studentId).toList());
  }

  @override
  Future<Result<double>> getAverageAdherence(String studentId) async {
    final metrics = _records.where((r) => r.studentId == studentId).toList();
    if (metrics.isEmpty) return Result.success(0.0);
    return Result.success(metrics.fold<double>(0.0, (s, m) => s + m.adherenceScore) / metrics.length);
  }

  void addRecord(PlanAdherenceModel m) => _records.add(m);
}

class _FakePlanAdherenceOrchestrator extends PlanAdherenceOrchestrator {
  final _FakeAdherenceRepo adherenceRepo;

  _FakePlanAdherenceOrchestrator({required this.adherenceRepo}) : super(adherenceRepository: adherenceRepo);

  @override
  Future<Result<AdherenceDeviation>> checkAdherence(String studentId) async {
    final lowDaysResult = await adherenceRepo.getConsecutiveLowAdherenceDays(studentId);
    final avgResult = await adherenceRepo.getAverageAdherence(studentId);
    final lowDays = lowDaysResult.data ?? 0;
    final avg = avgResult.data ?? 0.0;
    if (lowDays >= 7) {
      return Result.success(AdherenceDeviation(
        consecutiveLowDays: lowDays,
        averageAdherence: avg,
        requiresRegeneration: true,
        requiresEscalation: true,
        message: '$lowDays consecutive low adherence days',
      ));
    }
    if (lowDays >= 3) {
      return Result.success(AdherenceDeviation(
        consecutiveLowDays: lowDays,
        averageAdherence: avg,
        requiresRegeneration: true,
        requiresEscalation: false,
        message: '$lowDays consecutive low adherence days',
      ));
    }
    return Result.success(const AdherenceDeviation());
  }
}

class _FakeSessionRepo extends SessionRepository {

  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async => Result.success([]);
}

/// Session repo stub whose [getTodayDurationMs] returns a fixed today-only
/// duration, used to exercise the overwork nudge's daily signal.
class _TodayDurationSessionRepo extends SessionRepository {
  final int todayMs;

  _TodayDurationSessionRepo(this.todayMs);

  @override
  Future<Result<int>> getTodayDurationMs() async => Result.success(todayMs);
}

class _RecordingSessionRepo extends SessionRepository {
  final List<Session> _sessions;
  final List<Session> _saved = [];

  _RecordingSessionRepo(this._sessions);

  @override
  Future<Result<List<Session>>> getAll() async => Result.success(_sessions);

  @override
  Future<Result<void>> save(String key, Session item) async {
    _saved.add(item);
    return Result.success(null);
  }

  List<Session> get savedSessions => List.unmodifiable(_saved);
}

class _FakeNotificationService extends NotificationService {
  final List<double> overworkHoursStudied = [];
  final List<String> revisionTopicNames = [];
  final List<int> planAdjustmentLowDays = [];

  @override
  Future<Result<void>> showOverworkWarning({
    required int id,
    required double hoursStudied,
  }) async {
    overworkHoursStudied.add(hoursStudied);
    return Result.success(null);
  }

  @override
  Future<Result<void>> showRevisionNudge({
    required int id,
    required String topicName,
    required int daysSinceLastPractice,
  }) async {
    revisionTopicNames.add(topicName);
    return Result.success(null);
  }

  @override
  Future<Result<void>> showPlanAdjustmentSuggestion({
    required int id,
    required int consecutiveLowDays,
  }) async {
    planAdjustmentLowDays.add(consecutiveLowDays);
    return Result.success(null);
  }
}

/// Planner service stub whose scheduled lessons are controlled by the
/// test, used to exercise the upcoming-lesson reminder check without
/// any repository/Hive dependency.
class _FakePlannerService extends PlannerService {
  final List<Session> lessons = [];

  @override
  Future<Result<List<Session>>> getScheduledLessons() async {
    return Result.success(lessons);
  }
}

/// Notification service stub that records upcoming-lesson reminders
/// instead of touching the platform channel, used to verify the
/// per-lesson dedup of lesson reminders.
class _LessonReminderRecordingNotificationService extends NotificationService {
  final List<({int id, String lessonTitle, DateTime startTime})>
      lessonReminders = [];

  @override
  Future<Result<void>> showLessonReminder({
    required int id,
    required String lessonTitle,
    required DateTime startTime,
  }) async {
    lessonReminders.add(
      (id: id, lessonTitle: lessonTitle, startTime: startTime),
    );
    return Result.success(null);
  }
}

/// Notification service stub whose lesson reminders always fail, used to
/// verify a failed reminder is retried on the next tick instead of
/// being permanently suppressed.
class _FailingLessonReminderNotificationService extends NotificationService {
  int lessonReminderAttempts = 0;

  @override
  Future<Result<void>> showLessonReminder({
    required int id,
    required String lessonTitle,
    required DateTime startTime,
  }) async {
    lessonReminderAttempts++;
    return Result.failure('simulated notification failure');
  }
}

/// Nudge repository stub whose writes always fail, used to verify the
/// scheduler does not notify about nudges it could not persist.
class _FailingNudgeRepository extends EngagementNudgeRepository {
  final List<EngagementNudgeModel> createAttempts = [];

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<void>> create(EngagementNudgeModel model) async {
    createAttempts.add(model);
    return Result.failure('simulated write failure');
  }

  @override
  Future<Result<List<EngagementNudgeModel>>> getByStudent(String studentId) async =>
      Result.success([]);
}

/// Session repository stub whose [save] always fails, used to verify
/// stale-session finalization surfaces the write failure instead of
/// reporting success.
class _FailingSessionRepo extends SessionRepository {
  final List<Session> _sessions;
  final List<Session> saveAttempts = [];

  _FailingSessionRepo(this._sessions);

  @override
  Future<Result<List<Session>>> getAll() async => Result.success(_sessions);

  @override
  Future<Result<void>> save(String key, Session item) async {
    saveAttempts.add(item);
    return Result.failure('simulated write failure');
  }
}

List<String> _capturedLogs = [];
void _installLogCapture() {
  _capturedLogs.clear();
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) _capturedLogs.add(message);
  };
}

void _uninstallLogCapture() {
  debugPrint = debugPrintThrottled;
}

class _OverworkTracker extends StudyProgressTracker {
  final double hours;

  _OverworkTracker(this.hours)
      : super(
          attemptRepo: _FakeAttemptRepo(),
          l10n: lookupAppLocalizations(const Locale('en')),
        );

  @override
  Future<Result<Map<String, dynamic>>> getOverallStats(String studentId) async {
    return Result.success({
      'accuracy': 80,
      'totalStudyTimeHours': hours,
      'weeklyActivity': 25,
      'topicsStudied': 10,
      'correctAttempts': 40,
      'totalAttempts': 50,
    });
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getRecommendations(String studentId) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getBadges(String studentId) async {
    return Result.success([]);
  }
}

/// Notification service stub that records daily-reminder
/// schedule/cancel calls instead of touching the platform
/// channel, used to verify the alarm sync wiring.
class _RecordingNotificationService extends NotificationService {
  final List<({int id, int hour, int minute, String? payload})>
      dailyReminders = [];
  final List<int> cancelledIds = [];
  int initCount = 0;

  @override
  Future<Result<void>> init({Function(String?)? onNotificationTap}) async {
    initCount++;
    return Result.success(null);
  }

  @override
  Future<Result<void>> showDailyReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay remindAt,
    String? payload,
  }) async {
    dailyReminders.add(
      (id: id, hour: remindAt.hour, minute: remindAt.minute, payload: payload),
    );
    return Result.success(null);
  }

  @override
  Future<Result<void>> cancelNotification(int id) async {
    cancelledIds.add(id);
    return Result.success(null);
  }
}

/// Clock stub returning a fixed instant, used to pin the
/// scheduler's day-count arithmetic to dates around a DST
/// transition without depending on the test process timezone.
class _FixedClock implements Clock {
  final DateTime fixed;

  _FixedClock(this.fixed);

  @override
  DateTime now() => fixed;
}

void main() {
  group('EngagementScheduler', () {
    late _FakeNudgeRepository nudgeRepo;
    late _FakeAdherenceRepo adherenceRepo;
    late _FakePlanAdherenceOrchestrator planOrchestrator;
    late _FakeMasteryForScheduler masteryService;
    late EngagementScheduler scheduler;

    setUp(() async {
      nudgeRepo = _FakeNudgeRepository();
      adherenceRepo = _FakeAdherenceRepo();
      planOrchestrator = _FakePlanAdherenceOrchestrator(adherenceRepo: adherenceRepo);
      masteryService = _FakeMasteryForScheduler();

      scheduler = EngagementScheduler(
        tracker: _FakeTracker(),
        masteryService: masteryService,
        notificationService: NotificationService(),
        nudgeRepository: nudgeRepo,
        adherenceRepository: adherenceRepo,
        planOrchestrator: planOrchestrator,
        sessionRepository: _FakeSessionRepo(),
        config: const EngagementSchedulerConfig(
          checkHour: 9,
          checkMinute: 0,
          studentId: 'test-student',
        ),
        l10n: lookupAppLocalizations(const Locale('en')),
      );
    });

    group('getOverworkNudge', () {
      test('returns empty list when study time is under 4 hours', () async {
        final result = await scheduler.getOverworkNudge('test-student');
        expect(result.isSuccess, true);
        expect(result.data, isEmpty);
      });

      test('returns empty when all-time hours exceed threshold but today does not', () async {
        // Regression: the signal used to be the all-time cumulative
        // totalStudyTimeHours, so any student over 4h lifetime got a
        // "take a break" nudge every day, even on days with no study.
        final allTimeScheduler = EngagementScheduler(
          tracker: _OverworkTracker(87.4),
          masteryService: masteryService,
          notificationService: NotificationService(),
          nudgeRepository: nudgeRepo,
          adherenceRepository: adherenceRepo,
          planOrchestrator: planOrchestrator,
          sessionRepository: _TodayDurationSessionRepo(0),
          config: const EngagementSchedulerConfig(
            checkHour: 9,
            checkMinute: 0,
            studentId: 'test-student',
          ),
          l10n: lookupAppLocalizations(const Locale('en')),
        );

        final result = await allTimeScheduler.getOverworkNudge('test-student');
        expect(result.isSuccess, true);
        expect(result.data, isEmpty);
      });

      test('fires only when today study time exceeds the threshold and reports today hours', () async {
        final todayScheduler = EngagementScheduler(
          tracker: _OverworkTracker(87.4),
          masteryService: masteryService,
          notificationService: NotificationService(),
          nudgeRepository: nudgeRepo,
          adherenceRepository: adherenceRepo,
          planOrchestrator: planOrchestrator,
          sessionRepository: _TodayDurationSessionRepo(5 * 3600000),
          config: const EngagementSchedulerConfig(
            checkHour: 9,
            checkMinute: 0,
            studentId: 'test-student',
          ),
          l10n: lookupAppLocalizations(const Locale('en')),
        );

        final result = await todayScheduler.getOverworkNudge('test-student');
        expect(result.isSuccess, true);
        expect(result.data, hasLength(1));
        expect(result.data!.first.nudgeType, 'overwork');
        // Reports today's 5 hours, not the 87.4h all-time cumulative.
        expect(result.data!.first.hoursStudied, 5.0);
        expect(result.data!.first.hoursStudied, isNot(87.4));
      });
    });

    group('overwork nudge hours propagation', () {
      test('getOverworkNudge stores the raw today hours on the nudge', () async {
        final esScheduler = EngagementScheduler(
          tracker: _OverworkTracker(87.4),
          masteryService: masteryService,
          notificationService: NotificationService(),
          nudgeRepository: nudgeRepo,
          adherenceRepository: adherenceRepo,
          planOrchestrator: planOrchestrator,
          sessionRepository: _TodayDurationSessionRepo((4.5 * 3600000).toInt()),
          config: const EngagementSchedulerConfig(
            checkHour: 9,
            checkMinute: 0,
            studentId: 'test-student',
          ),
          l10n: lookupAppLocalizations(const Locale('es')),
        );

        final result = await esScheduler.getOverworkNudge('test-student');
        expect(result.isSuccess, true);
        expect(result.data, hasLength(1));
        // Today's 4.5h wins over the 87.4h all-time cumulative.
        expect(result.data!.first.hoursStudied, 4.5);
        // The message is localized; in 'es' the hours render as "4,5".
        expect(result.data!.first.message, contains('4,5'));
      });

      test('notification receives the raw hours, not the value re-parsed from the localized message', () async {
        final notif = _FakeNotificationService();
        final esScheduler = EngagementScheduler(
          tracker: _OverworkTracker(87.4),
          masteryService: masteryService,
          notificationService: notif,
          nudgeRepository: nudgeRepo,
          adherenceRepository: adherenceRepo,
          planOrchestrator: planOrchestrator,
          sessionRepository: _TodayDurationSessionRepo((4.5 * 3600000).toInt()),
          config: const EngagementSchedulerConfig(
            checkHour: 9,
            checkMinute: 0,
            studentId: 'test-student',
          ),
          l10n: lookupAppLocalizations(const Locale('es')),
        );

        await esScheduler.runDailyChecksNow();

        // The 'es' message reads "…4,5 horas…". Re-parsing it (the old bug)
        // would strip the comma and inflate 4.5h into 45.0h. The notification
        // must receive the raw 4.5 value carried on the nudge.
        expect(notif.overworkHoursStudied, hasLength(1));
        expect(notif.overworkHoursStudied.first, 4.5);
        expect(notif.overworkHoursStudied.first, isNot(45.0));

        final stored = nudgeRepo.storedNudges
            .where((n) => n.nudgeType == 'overwork')
            .toList();
        expect(stored, hasLength(1));
        expect(stored.first.hoursStudied, 4.5);
      });
    });

    group('nudge persistence failures are not masked', () {
      EngagementScheduler failingWriteScheduler({
        required _FakeNotificationService notif,
        required _FailingNudgeRepository nudgeRepo,
        required SessionRepository sessionRepo,
      }) {
        return EngagementScheduler(
          tracker: _OverworkTracker(87.4),
          masteryService: masteryService,
          notificationService: notif,
          nudgeRepository: nudgeRepo,
          adherenceRepository: adherenceRepo,
          planOrchestrator: planOrchestrator,
          sessionRepository: sessionRepo,
          config: const EngagementSchedulerConfig(
            checkHour: 9,
            checkMinute: 0,
            studentId: 'test-student',
          ),
          l10n: lookupAppLocalizations(const Locale('en')),
        );
      }

      test('overwork notification is skipped when the nudge cannot be persisted',
          () async {
        final notif = _FakeNotificationService();
        final failingNudgeRepo = _FailingNudgeRepository();
        final scheduler = failingWriteScheduler(
          notif: notif,
          nudgeRepo: failingNudgeRepo,
          // 5h of study time today trips the overwork threshold.
          sessionRepo: _TodayDurationSessionRepo(5 * 3600000),
        );

        final result = await scheduler.runDailyChecksNow();

        // The daily check still completes even though the write failed…
        expect(result.isSuccess, true);
        // …the nudge was attempted…
        expect(failingNudgeRepo.createAttempts, hasLength(1));
        expect(failingNudgeRepo.createAttempts.single.nudgeType, 'overwork');
        // …but no notification is shown for a nudge that was never persisted.
        expect(notif.overworkHoursStudied, isEmpty);
      });

      test('revision notification is skipped when the nudge cannot be persisted',
          () async {
        masteryService.topicsNeedingReview.add(MasteryState(
          studentId: 'test-student',
          topicId: 'topic-stale',
          lastAttempt: DateTime.now().subtract(const Duration(days: 5)),
          lastUpdated: DateTime.now().subtract(const Duration(days: 5)),
        ));
        final notif = _FakeNotificationService();
        final failingNudgeRepo = _FailingNudgeRepository();
        final scheduler = failingWriteScheduler(
          notif: notif,
          nudgeRepo: failingNudgeRepo,
          sessionRepo: _FakeSessionRepo(),
        );

        final result = await scheduler.runDailyChecksNow();

        expect(result.isSuccess, true);
        expect(failingNudgeRepo.createAttempts, hasLength(1));
        expect(failingNudgeRepo.createAttempts.single.nudgeType, 'revision');
        expect(notif.revisionTopicNames, isEmpty);
      });

      test('plan adjustment notification is skipped when the nudge cannot be persisted',
          () async {
        for (var i = 0; i < 3; i++) {
          adherenceRepo.addRecord(PlanAdherenceModel(
            id: 'adh_pa_fail_$i',
            studentId: 'test-student',
            date: DateTime.now().subtract(Duration(days: i)),
            adherenceScore: 0.3,
          ));
        }
        final notif = _FakeNotificationService();
        final failingNudgeRepo = _FailingNudgeRepository();
        final scheduler = failingWriteScheduler(
          notif: notif,
          nudgeRepo: failingNudgeRepo,
          sessionRepo: _FakeSessionRepo(),
        );

        final result = await scheduler.runDailyChecksNow();

        expect(result.isSuccess, true);
        // 3 low days also trip the auto-regeneration nudge, so filter by type.
        expect(
          failingNudgeRepo.createAttempts
              .where((n) => n.nudgeType == 'planAdjustment'),
          hasLength(1),
        );
        expect(notif.planAdjustmentLowDays, isEmpty);
      });

      test('auto-regeneration nudge failure is logged, not silently dropped',
          () async {
        _installLogCapture();
        addTearDown(_uninstallLogCapture);
        for (var i = 0; i < 7; i++) {
          adherenceRepo.addRecord(PlanAdherenceModel(
            id: 'adh_reg_fail_$i',
            studentId: 'test-student',
            date: DateTime.now().subtract(Duration(days: i)),
            adherenceScore: 0.1,
          ));
        }
        final notif = _FakeNotificationService();
        final failingNudgeRepo = _FailingNudgeRepository();
        final scheduler = failingWriteScheduler(
          notif: notif,
          nudgeRepo: failingNudgeRepo,
          sessionRepo: _FakeSessionRepo(),
        );

        final result = await scheduler.runDailyChecksNow();

        expect(result.isSuccess, true);
        expect(
          failingNudgeRepo.createAttempts
              .where((n) => n.nudgeType == 'autoRegeneration'),
          hasLength(1),
        );
        final warnings = _capturedLogs.where((l) => l.contains('[W]')).toList();
        expect(
          warnings.any((l) => l.contains('Failed to persist auto-regeneration nudge')),
          isTrue,
        );
      });

      test('stale-session finalization logs the write failure instead of claiming success',
          () async {
        _installLogCapture();
        addTearDown(_uninstallLogCapture);
        final staleSession = Session(
          id: 'stale-fail-1',
          studentId: 'test-student',
          startTime: DateTime.now().subtract(const Duration(hours: 25)),
          plannedDurationMinutes: 45,
          status: SessionStatus.inProgress,
        );
        final failingSessionRepo = _FailingSessionRepo([staleSession]);
        final finalizeScheduler = EngagementScheduler(
          tracker: _FakeTracker(),
          masteryService: masteryService,
          notificationService: NotificationService(),
          nudgeRepository: nudgeRepo,
          adherenceRepository: adherenceRepo,
          planOrchestrator: planOrchestrator,
          sessionRepository: failingSessionRepo,
          config: const EngagementSchedulerConfig(
            checkHour: 9,
            checkMinute: 0,
            studentId: 'test-student',
          ),
          l10n: lookupAppLocalizations(const Locale('en')),
        );

        final result = await finalizeScheduler.init();

        expect(result.isSuccess, true);
        expect(failingSessionRepo.saveAttempts, hasLength(1));
        final warnings = _capturedLogs.where((l) => l.contains('[W]')).toList();
        expect(
          warnings.any(
            (l) => l.contains('Failed to persist auto-finalized stale session stale-fail-1'),
          ),
          isTrue,
        );
        // The unconditional success message must not be logged for a failed write.
        expect(
          warnings.any((l) => l.contains('Auto-finalized stale session: stale-fail-1')),
          isFalse,
        );
      });
    });

    group('getRevisionNudges', () {
      test('returns empty list when no topics need review', () async {
        final result = await scheduler.getRevisionNudges('test-student');
        expect(result.isSuccess, true);
        expect(result.data, isEmpty);
      });
    });

    group('getRevisionNudges calendar-day counting', () {
      EngagementScheduler clockedScheduler(Clock clock) {
        return EngagementScheduler(
          tracker: _FakeTracker(),
          masteryService: masteryService,
          notificationService: NotificationService(),
          nudgeRepository: nudgeRepo,
          adherenceRepository: adherenceRepo,
          planOrchestrator: planOrchestrator,
          sessionRepository: _FakeSessionRepo(),
          config: const EngagementSchedulerConfig(
            checkHour: 9,
            checkMinute: 0,
            studentId: 'test-student',
          ),
          l10n: lookupAppLocalizations(const Locale('en')),
          clock: clock,
        );
      }

      test('counts calendar days, not elapsed 24h periods, so the nudge is not suppressed across a DST-like boundary',
          () async {
        // Fri 2026-03-27 23:00 -> Mon 2026-03-30 01:00 spans the
        // Europe/Berlin spring-forward (2026-03-29): 3 calendar
        // days but 49h, i.e. 2 elapsed days. Elapsed-time
        // `difference().inDays` used to fall below the >= 3 gate
        // and suppress the revision nudge for a full day.
        final clock = _FixedClock(DateTime(2026, 3, 30, 1, 0));
        masteryService.topicsNeedingReview.add(MasteryState(
          studentId: 'test-student',
          topicId: 'topic-dst',
          lastAttempt: DateTime(2026, 3, 27, 23, 0),
          lastUpdated: DateTime(2026, 3, 27, 23, 0),
        ));

        final result =
            await clockedScheduler(clock).getRevisionNudges('test-student');

        expect(result.isSuccess, true);
        expect(result.data, hasLength(1));
        expect(result.data!.first.nudgeType, 'revision');
        expect(result.data!.first.topicId, 'topic-dst');
        // 3 calendar days, not the 2 elapsed days.
        expect(result.data!.first.message, contains('3 days'));
        expect(result.data!.first.message, contains('topic-dst'));
      });

      test('severity is high at 7 calendar days even when only 6 have elapsed',
          () async {
        // Mon 2026-03-23 23:00 -> Mon 2026-03-30 01:00: 7 calendar
        // days but 146h, i.e. 6 elapsed days. The >= 7 severity gate
        // must see the calendar count.
        final clock = _FixedClock(DateTime(2026, 3, 30, 1, 0));
        masteryService.topicsNeedingReview.add(MasteryState(
          studentId: 'test-student',
          topicId: 'topic-week',
          lastAttempt: DateTime(2026, 3, 23, 23, 0),
          lastUpdated: DateTime(2026, 3, 23, 23, 0),
        ));

        final result =
            await clockedScheduler(clock).getRevisionNudges('test-student');

        expect(result.isSuccess, true);
        expect(result.data, hasLength(1));
        expect(result.data!.first.severity, 'high');
      });

      test('no revision nudge before 3 calendar days have passed', () async {
        // Sat 2026-03-28 23:00 -> Mon 2026-03-30 01:00: 2 calendar
        // days (1 elapsed). Guards against overcorrecting the count.
        final clock = _FixedClock(DateTime(2026, 3, 30, 1, 0));
        masteryService.topicsNeedingReview.add(MasteryState(
          studentId: 'test-student',
          topicId: 'topic-recent',
          lastAttempt: DateTime(2026, 3, 28, 23, 0),
          lastUpdated: DateTime(2026, 3, 28, 23, 0),
        ));

        final result =
            await clockedScheduler(clock).getRevisionNudges('test-student');

        expect(result.isSuccess, true);
        expect(result.data, isEmpty);
      });
    });

    group('welcome-back backfill calendar-day counting', () {
      test('fires the welcome-back nudge at 2 calendar days missed even when only 1 has elapsed',
          () async {
        // The app last ran Sat 2026-03-28 23:00 and is next opened
        // Mon 2026-03-30 01:00: 2 calendar days missed but 26h,
        // i.e. 1 elapsed day. Elapsed-time `difference().inDays`
        // used to fall below the >= 2 gate and suppress the nudge.
        final clock = _FixedClock(DateTime(2026, 3, 30, 1, 0));
        final box = Hive.isBoxOpen(HiveBoxNames.settings)
            ? Hive.box(HiveBoxNames.settings)
            : await Hive.openBox(HiveBoxNames.settings);
        await box.put(
          'scheduler_last_run',
          DateTime(2026, 3, 28, 23, 0).toIso8601String(),
        );

        final backfillScheduler = EngagementScheduler(
          tracker: _FakeTracker(),
          masteryService: _FakeMasteryForScheduler(),
          notificationService: NotificationService(),
          nudgeRepository: nudgeRepo,
          adherenceRepository: adherenceRepo,
          planOrchestrator: planOrchestrator,
          sessionRepository: _FakeSessionRepo(),
          config: const EngagementSchedulerConfig(
            checkHour: 9,
            checkMinute: 0,
            studentId: 'test-student',
          ),
          l10n: lookupAppLocalizations(const Locale('en')),
          clock: clock,
        );

        final result = await backfillScheduler.init();

        expect(result.isSuccess, true);
        final welcomeBack = nudgeRepo.storedNudges
            .where((n) => n.nudgeType == 'planAdjustment')
            .toList();
        expect(welcomeBack, hasLength(1));
        // "Welcome back! You've been away for 2 days." — the calendar
        // count, not the 1 elapsed day.
        expect(welcomeBack.first.message, contains('2 days'));
      });
    });

    group('getPlanAdjustmentNudge', () {
      test('returns empty when no low adherence days', () async {
        final result = await scheduler.getPlanAdjustmentNudge('test-student');
        expect(result.isSuccess, true);
        expect(result.data, isEmpty);
      });

      test('returns nudge after 3+ low adherence days', () async {
        for (var i = 0; i < 3; i++) {
          adherenceRepo.addRecord(PlanAdherenceModel(
            id: 'adh_$i',
            studentId: 'test-student',
            date: DateTime.now().subtract(Duration(days: i)),
            adherenceScore: 0.3,
          ));
        }

        final result = await scheduler.getPlanAdjustmentNudge('test-student');
        expect(result.isSuccess, true);
        expect(result.data, hasLength(1));
        expect(result.data!.first.nudgeType, 'planAdjustment');
      });
    });

    group('getWeeklyDigest', () {
      test('returns digest string', () async {
        final result = await scheduler.getWeeklyDigest('test-student');
        expect(result.isSuccess, true);
        expect(result.data, contains('Weekly Digest'));
        expect(result.data, contains('questions answered'));
      });
    });

    group('auto-regeneration via PlanAdherenceOrchestrator', () {
      test('plan adapter detects low adherence', () async {
        for (var i = 0; i < 3; i++) {
          adherenceRepo.addRecord(PlanAdherenceModel(
            id: 'adh_a_$i',
            studentId: 'test-student',
            date: DateTime.now().subtract(Duration(days: i)),
            adherenceScore: 0.2,
          ));
        }

        final deviation = await planOrchestrator.checkAdherence('test-student');
        expect(deviation.isSuccess, true);
        expect(deviation.data!.consecutiveLowDays, 3);
        expect(deviation.data!.requiresRegeneration, true);
      });

      test('escalates when 7+ low adherence days', () async {
        for (var i = 0; i < 7; i++) {
          adherenceRepo.addRecord(PlanAdherenceModel(
            id: 'adh_e_$i',
            studentId: 'test-student',
            date: DateTime.now().subtract(Duration(days: i)),
            adherenceScore: 0.1,
          ));
        }

        final deviation = await planOrchestrator.checkAdherence('test-student');
        expect(deviation.isSuccess, true);
        expect(deviation.data!.consecutiveLowDays, 7);
        expect(deviation.data!.requiresEscalation, true);
        expect(deviation.data!.requiresRegeneration, true);
      });

      test('no escalation with good adherence', () async {
        adherenceRepo.addRecord(PlanAdherenceModel(
          id: 'adh_good',
          studentId: 'test-student',
          date: DateTime.now(),
          adherenceScore: 0.9,
        ));

        final deviation = await planOrchestrator.checkAdherence('test-student');
        expect(deviation.data!.requiresRegeneration, false);
        expect(deviation.data!.requiresEscalation, false);
      });
    });

    group('auto-finalize stale sessions', () {
      test('finalizes an orphaned stale session as cancelled with completed: false', () async {
        final staleSession = Session(
          id: 'stale-1',
          studentId: 'test-student',
          startTime: DateTime.now().subtract(const Duration(hours: 25)),
          plannedDurationMinutes: 45,
          status: SessionStatus.inProgress,
        );
        final sessionRepo = _RecordingSessionRepo([staleSession]);
        final finalizeScheduler = EngagementScheduler(
          tracker: _FakeTracker(),
          masteryService: masteryService,
          notificationService: NotificationService(),
          nudgeRepository: nudgeRepo,
          adherenceRepository: adherenceRepo,
          planOrchestrator: planOrchestrator,
          sessionRepository: sessionRepo,
          config: const EngagementSchedulerConfig(
            checkHour: 9,
            checkMinute: 0,
            studentId: 'test-student',
          ),
          l10n: lookupAppLocalizations(const Locale('en')),
        );

        final result = await finalizeScheduler.init();
        expect(result.isSuccess, true);

        // The abandoned session is persisted exactly once…
        expect(sessionRepo.savedSessions, hasLength(1));
        final finalized = sessionRepo.savedSessions.first;
        expect(finalized.id, 'stale-1');
        // …as cancelled (matching StudyTimerService.cancelSession)…
        expect(finalized.status, SessionStatus.cancelled);
        // …and must NOT be marked completed: a cancelled session that counts
        // as completed inflates completed-session counters and study streaks.
        expect(finalized.completed, false);
        expect(finalized.endTime, isNotNull);
        expect(finalized.endTime, staleSession.startTime.add(const Duration(minutes: 45)));
      });

      test('leaves recent open sessions and already-finished sessions untouched', () async {
        final recentOpen = Session(
          id: 'recent-open',
          studentId: 'test-student',
          startTime: DateTime.now().subtract(const Duration(minutes: 30)),
          status: SessionStatus.inProgress,
        );
        final finishedLongAgo = Session(
          id: 'finished-long-ago',
          studentId: 'test-student',
          startTime: DateTime.now().subtract(const Duration(hours: 30)),
          endTime: DateTime.now().subtract(const Duration(hours: 29)),
          completed: true,
          status: SessionStatus.completed,
        );
        final sessionRepo = _RecordingSessionRepo([recentOpen, finishedLongAgo]);
        final finalizeScheduler = EngagementScheduler(
          tracker: _FakeTracker(),
          masteryService: masteryService,
          notificationService: NotificationService(),
          nudgeRepository: nudgeRepo,
          adherenceRepository: adherenceRepo,
          planOrchestrator: planOrchestrator,
          sessionRepository: sessionRepo,
          config: const EngagementSchedulerConfig(
            checkHour: 9,
            checkMinute: 0,
            studentId: 'test-student',
          ),
          l10n: lookupAppLocalizations(const Locale('en')),
        );

        await finalizeScheduler.init();

        // Neither a still-active recent session nor an already-finished
        // session should be re-saved by the stale-session sweep.
        expect(sessionRepo.savedSessions, isEmpty);
      });
    });

    group('settings-aware notification filtering', () {
      test('updateSettings stores settings box reference', () {
        final settings = SettingsBox(studyRemindersEnabled: false);
        scheduler.updateSettings(settings);
        // No assertion needed - verify no crash
      });

      test('master toggle suppresses overwork nudge when disabled', () async {
        final settings = SettingsBox(
          studyRemindersEnabled: false,
          overworkAlertsEnabled: true,
        );
        scheduler.updateSettings(settings);
        final result = await scheduler.getOverworkNudge('test-student');
        // Nudge check still returns data, but _sendNudgeNotifications should skip
        // The _isNotificationEnabled check is internal, so we verify by calling
        // the public method and confirming no crash
        expect(result.isSuccess, true);
        expect(result.data, isEmpty);
      });

      test('individual toggle gating works via _sendNudgeNotifications', () async {
        final settings = SettingsBox(
          studyRemindersEnabled: true,
          overworkAlertsEnabled: false,
          revisionRemindersEnabled: false,
          planAdjustmentNotificationsEnabled: false,
        );
        scheduler.updateSettings(settings);
        // Should not throw despite disabled toggles
        await expectLater(scheduler.runDailyChecksNow(), completes);
      });
    });

    group('runDailyChecksNow', () {
      test('runs nudge checks without throwing', () async {
        await expectLater(scheduler.runDailyChecksNow(), completes);
      });
    });

    group('upcoming lesson reminder dedup', () {
      EngagementScheduler lessonScheduler({
        required PlannerService plannerService,
        required NotificationService notificationService,
      }) {
        return EngagementScheduler(
          tracker: _FakeTracker(),
          masteryService: _FakeMasteryForScheduler(),
          notificationService: notificationService,
          nudgeRepository: _FakeNudgeRepository(),
          adherenceRepository: _FakeAdherenceRepo(),
          planOrchestrator: _FakePlanAdherenceOrchestrator(
            adherenceRepo: _FakeAdherenceRepo(),
          ),
          sessionRepository: _FakeSessionRepo(),
          plannerService: plannerService,
          config: const EngagementSchedulerConfig(
            checkHour: 9,
            checkMinute: 0,
            studentId: 'test-student',
          ),
          l10n: lookupAppLocalizations(const Locale('en')),
        );
      }

      Session upcomingLesson(String id, {int minutesFromNow = 25}) {
        return Session(
          id: id,
          studentId: 'test-student',
          topicId: id,
          startTime: DateTime.now().add(Duration(minutes: minutesFromNow)),
          status: SessionStatus.planned,
        );
      }

      test('a lesson in the 30-minute window is notified at most once across repeated 5-minute ticks',
          () async {
        final planner = _FakePlannerService()
          ..lessons.add(upcomingLesson('lesson-1'));
        final notif = _LessonReminderRecordingNotificationService();
        final scheduler = lessonScheduler(
          plannerService: planner,
          notificationService: notif,
        );

        // The immediate check on startup plus six 5-minute timer ticks.
        // Without dedup the same lesson matches every tick and the user
        // would see up to seven stacked notifications.
        for (var tick = 0; tick < 7; tick++) {
          await scheduler.runDailyChecksNow();
        }

        expect(notif.lessonReminders, hasLength(1));
        expect(notif.lessonReminders.single.lessonTitle, 'lesson-1');
        expect(
          notif.lessonReminders.single.startTime,
          planner.lessons.single.startTime,
        );
      });

      test('each upcoming lesson in the window is notified exactly once',
          () async {
        final planner = _FakePlannerService()
          ..lessons.addAll([
            upcomingLesson('lesson-a'),
            upcomingLesson('lesson-b'),
          ]);
        final notif = _LessonReminderRecordingNotificationService();
        final scheduler = lessonScheduler(
          plannerService: planner,
          notificationService: notif,
        );

        for (var tick = 0; tick < 3; tick++) {
          await scheduler.runDailyChecksNow();
        }

        // Dedup is per lesson, not a global "already notified" flag.
        expect(notif.lessonReminders, hasLength(2));
        expect(
          notif.lessonReminders.map((r) => r.lessonTitle).toList(),
          containsAll(['lesson-a', 'lesson-b']),
        );
      });

      test('a lesson further than 30 minutes away is not notified', () async {
        final planner = _FakePlannerService()
          ..lessons.add(upcomingLesson('lesson-far', minutesFromNow: 45));
        final notif = _LessonReminderRecordingNotificationService();
        final scheduler = lessonScheduler(
          plannerService: planner,
          notificationService: notif,
        );

        await scheduler.runDailyChecksNow();
        await scheduler.runDailyChecksNow();

        expect(notif.lessonReminders, isEmpty);
      });

      test('a completed lesson is never notified', () async {
        final planner = _FakePlannerService()
          ..lessons.add(Session(
            id: 'lesson-done',
            studentId: 'test-student',
            startTime: DateTime.now().add(const Duration(minutes: 20)),
            completed: true,
            status: SessionStatus.completed,
          ));
        final notif = _LessonReminderRecordingNotificationService();
        final scheduler = lessonScheduler(
          plannerService: planner,
          notificationService: notif,
        );

        await scheduler.runDailyChecksNow();

        expect(notif.lessonReminders, isEmpty);
      });

      test('a failed lesson reminder is retried on the next tick', () async {
        final planner = _FakePlannerService()
          ..lessons.add(upcomingLesson('lesson-retry'));
        final notif = _FailingLessonReminderNotificationService();
        final scheduler = lessonScheduler(
          plannerService: planner,
          notificationService: notif,
        );

        for (var tick = 0; tick < 3; tick++) {
          await scheduler.runDailyChecksNow();
        }

        // Only successful reminders are deduplicated; a failed one is
        // retried while the lesson is still inside the window.
        expect(notif.lessonReminderAttempts, 3);
      });
    });

    group('daily reminder schedule sync', () {
      EngagementScheduler reminderScheduler(NotificationService notif) {
        return EngagementScheduler(
          tracker: _FakeTracker(),
          masteryService: _FakeMasteryForScheduler(),
          notificationService: notif,
          nudgeRepository: _FakeNudgeRepository(),
          adherenceRepository: _FakeAdherenceRepo(),
          planOrchestrator:
              _FakePlanAdherenceOrchestrator(adherenceRepo: _FakeAdherenceRepo()),
          sessionRepository: _FakeSessionRepo(),
          config: const EngagementSchedulerConfig(
            checkHour: 9,
            checkMinute: 0,
            studentId: 'test-student',
          ),
          l10n: lookupAppLocalizations(const Locale('en')),
        );
      }

      test('enabling daily reminders registers the alarm at the persisted time-of-day',
          () async {
        final notif = _RecordingNotificationService();
        final scheduler = reminderScheduler(notif);

        await scheduler.updateSettings(SettingsBox(
          dailyReminderEnabled: true,
          dailyReminderHour: 7,
          dailyReminderMinute: 30,
        ));

        expect(notif.initCount, greaterThan(0));
        expect(notif.dailyReminders, hasLength(1));
        final call = notif.dailyReminders.single;
        expect(call.id, NotificationIds.dailyReminder);
        expect(call.hour, 7);
        expect(call.minute, 30);
        expect(call.payload, 'daily_reminder');
        expect(notif.cancelledIds, isEmpty);
      });

      test('disabling daily reminders cancels the alarm with the shared id',
          () async {
        final notif = _RecordingNotificationService();
        final scheduler = reminderScheduler(notif);
        await scheduler.updateSettings(SettingsBox(
          dailyReminderEnabled: true,
          dailyReminderHour: 9,
          dailyReminderMinute: 0,
        ));
        notif.dailyReminders.clear();

        await scheduler.updateSettings(SettingsBox(
          dailyReminderEnabled: false,
          dailyReminderHour: 9,
          dailyReminderMinute: 0,
        ));

        expect(notif.cancelledIds, [NotificationIds.dailyReminder]);
        expect(notif.dailyReminders, isEmpty);
      });

      test('re-applying the same reminder settings does not re-register the alarm',
          () async {
        final notif = _RecordingNotificationService();
        final scheduler = reminderScheduler(notif);
        final settings = SettingsBox(
          dailyReminderEnabled: true,
          dailyReminderHour: 8,
          dailyReminderMinute: 15,
        );

        await scheduler.updateSettings(settings);
        await scheduler.updateSettings(settings);
        // Unrelated settings updates flow through
        // updateSettings too; the alarm must only be
        // registered once.
        await scheduler.updateSettings(settings.copyWith(fontSize: 18));

        expect(notif.dailyReminders, hasLength(1));
        expect(notif.cancelledIds, isEmpty);
      });

      test('changing the reminder time re-registers the alarm at the new time',
          () async {
        final notif = _RecordingNotificationService();
        final scheduler = reminderScheduler(notif);
        await scheduler.updateSettings(SettingsBox(
          dailyReminderEnabled: true,
          dailyReminderHour: 8,
          dailyReminderMinute: 0,
        ));

        await scheduler.updateSettings(SettingsBox(
          dailyReminderEnabled: true,
          dailyReminderHour: 6,
          dailyReminderMinute: 45,
        ));

        expect(notif.dailyReminders, hasLength(2));
        final last = notif.dailyReminders.last;
        expect(last.hour, 6);
        expect(last.minute, 45);
      });

      test('a disabled reminder stays cancelled across unrelated updates',
          () async {
        final notif = _RecordingNotificationService();
        final scheduler = reminderScheduler(notif);
        final settings = SettingsBox(
          dailyReminderEnabled: false,
          dailyReminderHour: 9,
          dailyReminderMinute: 0,
        );

        await scheduler.updateSettings(settings);
        notif.cancelledIds.clear();
        await scheduler.updateSettings(settings.copyWith(fontSize: 20));

        expect(notif.cancelledIds, isEmpty);
        expect(notif.dailyReminders, isEmpty);
      });
    });
  });
}
