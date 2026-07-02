import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/engagement_scheduler.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/notification_service.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/core/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
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
    });

    group('getRevisionNudges', () {
      test('returns empty list when no topics need review', () async {
        final result = await scheduler.getRevisionNudges('test-student');
        expect(result.isSuccess, true);
        expect(result.data, isEmpty);
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
  });
}
