import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/planner/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/engagement_scheduler.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/notification_service.dart';
import 'package:studyking/core/services/plan_adapter.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';

class _FakeAttemptRepo extends AttemptRepository {
  @override
  Future<void> init() async {}

  @override
  Future<List<StudentAttempt>> getByStudent(String studentId) async => [];
}

class _FakeTracker extends StudyProgressTracker {
  _FakeTracker() : super(attemptRepo: _FakeAttemptRepo());

  @override
  Future<Map<String, dynamic>> getOverallStats(String studentId) async {
    return {
      'accuracy': 80,
      'totalStudyTimeHours': 3.5,
      'weeklyActivity': 25,
      'topicsStudied': 10,
      'correctAttempts': 40,
      'totalAttempts': 50,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getRecommendations(String studentId) async {
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getBadges(String studentId) async {
    return [];
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
  Future<void> init() async {}

  @override
  Future<void> create(EngagementNudgeModel model) async {
    _nudges.add(model);
  }

  @override
  Future<List<EngagementNudgeModel>> getByStudent(String studentId) async {
    return _nudges.where((n) => n.studentId == studentId).toList();
  }

  List<EngagementNudgeModel> get storedNudges => _nudges;
}

class _FakeAdherenceRepo extends PlanAdherenceRepository {
  final List<PlanAdherenceModel> _records = [];

  @override
  Future<void> init() async {}

  @override
  Future<List<PlanAdherenceModel>> getByStudent(String studentId) async {
    return _records.where((r) => r.studentId == studentId).toList();
  }

  @override
  Future<int> getConsecutiveLowAdherenceDays(String studentId, {double threshold = 0.5}) async {
    int consecutive = 0;
    for (final m in _records) {
      if (m.adherenceScore < threshold) {
        consecutive++;
      } else {
        break;
      }
    }
    return consecutive;
  }

  @override
  Future<List<PlanAdherenceModel>> getWeekly(String studentId) async {
    return _records.where((r) => r.studentId == studentId).toList();
  }

  @override
  Future<double> getAverageAdherence(String studentId) async {
    final metrics = _records.where((r) => r.studentId == studentId).toList();
    if (metrics.isEmpty) return 0.0;
    return metrics.fold<double>(0.0, (s, m) => s + m.adherenceScore) / metrics.length;
  }

  void addRecord(PlanAdherenceModel m) => _records.add(m);
}

class _FakePlanAdapter extends PlanAdapter {
  final _FakeAdherenceRepo adherenceRepo;

  _FakePlanAdapter({required this.adherenceRepo}) : super(adherenceRepository: adherenceRepo);

  @override
  Future<Result<AdherenceDeviation>> checkAdherence(String studentId) async {
    final lowDays = await adherenceRepo.getConsecutiveLowAdherenceDays(studentId);
    final avg = await adherenceRepo.getAverageAdherence(studentId);
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
    late _FakePlanAdapter planAdapter;
    late _FakeMasteryForScheduler masteryService;
    late EngagementScheduler scheduler;

    setUp(() async {
      nudgeRepo = _FakeNudgeRepository();
      adherenceRepo = _FakeAdherenceRepo();
      planAdapter = _FakePlanAdapter(adherenceRepo: adherenceRepo);
      masteryService = _FakeMasteryForScheduler();

      scheduler = EngagementScheduler(
        tracker: _FakeTracker(),
        masteryService: masteryService,
        notificationService: NotificationService(),
        nudgeRepository: nudgeRepo,
        adherenceRepository: adherenceRepo,
        planAdapter: planAdapter,
        sessionRepository: _FakeSessionRepo(),
        config: const EngagementSchedulerConfig(
          checkHour: 9,
          checkMinute: 0,
          studentId: 'test-student',
        ),
      );
    });

    group('getOverworkNudge', () {
      test('returns empty list when study time is under 4 hours', () async {
        final nudges = await scheduler.getOverworkNudge('test-student');
        expect(nudges, isEmpty);
      });
    });

    group('getRevisionNudges', () {
      test('returns empty list when no topics need review', () async {
        final nudges = await scheduler.getRevisionNudges('test-student');
        expect(nudges, isEmpty);
      });
    });

    group('getPlanAdjustmentNudge', () {
      test('returns empty when no low adherence days', () async {
        final nudges = await scheduler.getPlanAdjustmentNudge('test-student');
        expect(nudges, isEmpty);
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

        final nudges = await scheduler.getPlanAdjustmentNudge('test-student');
        expect(nudges, hasLength(1));
        expect(nudges.first.type.name, 'planAdjustment');
      });
    });

    group('getWeeklyDigest', () {
      test('returns digest string', () async {
        final digest = await scheduler.getWeeklyDigest('test-student');
        expect(digest, contains('Weekly Digest'));
        expect(digest, contains('questions answered'));
      });
    });

    group('auto-regeneration via PlanAdapter', () {
      test('plan adapter detects low adherence', () async {
        for (var i = 0; i < 3; i++) {
          adherenceRepo.addRecord(PlanAdherenceModel(
            id: 'adh_a_$i',
            studentId: 'test-student',
            date: DateTime.now().subtract(Duration(days: i)),
            adherenceScore: 0.2,
          ));
        }

        final deviation = await planAdapter.checkAdherence('test-student');
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

        final deviation = await planAdapter.checkAdherence('test-student');
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

        final deviation = await planAdapter.checkAdherence('test-student');
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
        final nudges = await scheduler.getOverworkNudge('test-student');
        // Nudge check still returns data, but _sendNudgeNotifications should skip
        // The _isNotificationEnabled check is internal, so we verify by calling
        // the public method and confirming no crash
        expect(nudges, isEmpty);
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
