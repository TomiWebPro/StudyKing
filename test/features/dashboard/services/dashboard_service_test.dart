import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/plan_adapter.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/dashboard/services/dashboard_service.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/planner/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';

class _FakeMasteryGraphService extends MasteryGraphService {
  final List<MasteryState> _allMastery;
  final Map<String, dynamic>? _snapshot;
  final bool _failInit;
  final bool _failAllMastery;
  final bool _failSnapshot;

  _FakeMasteryGraphService({
    List<MasteryState> allMastery = const [],
    Map<String, dynamic>? snapshot,
    bool failInit = false,
    bool failAllMastery = false,
    bool failSnapshot = false,
  })  : _allMastery = allMastery,
        _snapshot = snapshot,
        _failInit = failInit,
        _failAllMastery = failAllMastery,
        _failSnapshot = failSnapshot;

  @override
  Future<void> init() async {
    if (_failInit) throw Exception('init failed');
  }

  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) async {
    if (_failAllMastery) return Result.failure('fail');
    return Result.success(_allMastery);
  }

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) async {
    if (_failSnapshot) return Result.failure('fail');
    return Result.success(_snapshot ?? {
      'totalTopics': 0, 'masteredTopics': 0, 'weakTopics': 0,
      'averageAccuracy': 0.0, 'totalAttempts': 0,
      'avgReadiness': 0.0, 'avgReviewUrgency': 0.0,
    });
  }
}

class _FakeAttemptRepo extends AttemptRepository {
  final List<StudentAttempt> _attempts;

  _FakeAttemptRepo({List<StudentAttempt> attempts = const []}) : _attempts = attempts;

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async => Result.success(_attempts);
}

class _FakeProgressTracker extends StudyProgressTracker {
  final Map<String, dynamic> _stats;
  final List<Map<String, dynamic>> _trend;
  final List<Map<String, dynamic>> _badges;
  final bool _failBadges;

  _FakeProgressTracker({
    Map<String, dynamic> stats = const {},
    List<Map<String, dynamic>> trend = const [],
    List<Map<String, dynamic>> badges = const [],
    bool failBadges = false,
  })  : _stats = stats,
        _trend = trend,
        _badges = badges,
        _failBadges = failBadges,
        super(attemptRepo: _FakeAttemptRepo());

  @override
  Future<Map<String, dynamic>> getOverallStats(String studentId) async => _stats;

  @override
  Future<List<Map<String, dynamic>>> getWeeklyTrend(int weeks, {String? studentId}) async => _trend;

  @override
  Future<List<Map<String, dynamic>>> getBadges(String studentId) async {
    if (_failBadges) throw Exception('badges error');
    return _badges;
  }
}

class _FakeSessionRepo extends SessionRepository {
  final List<Session> _sessions;
  final bool _throwOnGetByDate;

  _FakeSessionRepo({List<Session> sessions = const [], bool throwOnGetByDate = false})
      : _sessions = sessions, _throwOnGetByDate = throwOnGetByDate;

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async {
    if (_throwOnGetByDate) throw Exception('getByDate error');
    return Result.success(_sessions);
  }
}

class _FakePlanAdherenceRepo extends PlanAdherenceRepository {
  final double _avgAdherence;
  final List<PlanAdherenceModel> _weekly;

  _FakePlanAdherenceRepo({double avgAdherence = 0.0, List<PlanAdherenceModel> weekly = const []})
      : _avgAdherence = avgAdherence, _weekly = weekly;

  @override
  Future<void> init() async {}

  @override
  Future<double> getAverageAdherence(String studentId) async => _avgAdherence;

  @override
  Future<List<PlanAdherenceModel>> getWeekly(String studentId) async => _weekly;
}

class _FakeTopicRepo extends TopicRepository {
  final List<Topic> _topics;
  final bool _failGetAll;

  _FakeTopicRepo({List<Topic> topics = const [], bool failGetAll = false})
      : _topics = topics, _failGetAll = failGetAll;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Topic>>> getAll() async {
    if (_failGetAll) return Result.failure('fail');
    return Result.success(_topics);
  }
}

void main() {
  group('DashboardService', () {
    group('construction', () {
      test('can be constructed with all optional dependencies', () {
        expect(() => DashboardService(), returnsNormally);
      });

      test('accepts injected dependencies', () {
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(),
          progressTracker: _FakeProgressTracker(),
          sessionRepo: _FakeSessionRepo(),
          adherenceRepo: _FakePlanAdherenceRepo(),
          topicRepo: _FakeTopicRepo(),
        );
        expect(service, isNotNull);
      });
    });

    group('init', () {
      test('completes successfully with injected fakes', () async {
        final mastery = _FakeMasteryGraphService();
        final sessionRepo = _FakeSessionRepo();
        final adherenceRepo = _FakePlanAdherenceRepo();
        final topicRepo = _FakeTopicRepo();
        final planAdapter = PlanAdapter(
          adherenceRepository: adherenceRepo,
          planRepository: null,
          planService: null,
          masteryService: null,
          l10n: null,
        );
        final service = DashboardService(
          masteryService: mastery,
          planAdapter: planAdapter,
          sessionRepo: sessionRepo,
          adherenceRepo: adherenceRepo,
          topicRepo: topicRepo,
        );
        await expectLater(service.init(), completes);
      });
    });

    group('getAllTopicMastery', () {
      test('returns empty list when no mastery states', () async {
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(),
        );
        final result = await service.getAllTopicMastery('student1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('returns list of MasteryState', () async {
        final now = DateTime.now();
        final states = [
          MasteryState(studentId: 's1', topicId: 't1', lastAttempt: now, lastUpdated: now),
          MasteryState(studentId: 's1', topicId: 't2', lastAttempt: now, lastUpdated: now),
        ];
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(allMastery: states),
        );
        final result = await service.getAllTopicMastery('s1');
        expect(result.isSuccess, isTrue);
        expect(result.data!.length, 2);
      });

      test('returns failed result when mastery service fails', () async {
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(failAllMastery: true),
        );
        final result = await service.getAllTopicMastery('s1');
        expect(result.isFailure, isTrue);
      });
    });

    group('getMasterySnapshot', () {
      test('returns snapshot data from mastery service', () async {
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(snapshot: {
            'totalTopics': 10, 'masteredTopics': 5, 'weakTopics': 2,
            'averageAccuracy': 0.75, 'totalAttempts': 100,
            'avgReadiness': 0.8, 'avgReviewUrgency': 0.3,
          }),
        );
        final result = await service.getMasterySnapshot('s1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.totalTopics, 10);
        expect(result.data!.masteredTopics, 5);
        expect(result.data!.averageAccuracy, 0.75);
      });

      test('returns null when mastery service returns failure', () async {
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(failSnapshot: true),
        );
        final result = await service.getMasterySnapshot('s1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
      });

      test('uses default values when snapshot map is empty', () async {
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(),
        );
        final result = await service.getMasterySnapshot('s1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.isEmpty, isTrue);
      });
    });

    group('getOverallStats', () {
      test('returns OverallStats from progress tracker', () async {
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(),
          progressTracker: _FakeProgressTracker(stats: {
            'totalAttempts': 50, 'correctAttempts': 35, 'accuracy': 70,
            'avgTimePerQuestion': 25, 'totalStudyTimeHours': '15.5',
            'weeklyActivity': 7, 'dailyActivity': 2, 'topicsStudied': 6,
          }),
        );
        final stats = await service.getOverallStats('s1');
        expect(stats, isNotNull);
        expect(stats!.totalAttempts, 50);
        expect(stats.correctAttempts, 35);
        expect(stats.accuracy, 70);
        expect(stats.totalStudyTimeHours, 15.5);
        expect(stats.weeklyActivity, 7);
        expect(stats.topicsStudied, 6);
      });

      test('returns OverallStats with default values when stats are empty', () async {
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(),
          progressTracker: _FakeProgressTracker(),
        );
        final stats = await service.getOverallStats('s1');
        expect(stats, isNotNull);
        expect(stats!.isEmpty, isTrue);
      });
    });

    group('getWeeklyTrend', () {
      test('returns empty list when no trend data', () async {
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(),
          progressTracker: _FakeProgressTracker(),
        );
        final trend = await service.getWeeklyTrend('s1');
        expect(trend, isEmpty);
      });

      test('returns list of WeeklyTrendEntry', () async {
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(),
          progressTracker: _FakeProgressTracker(trend: [
            {'week': 1, 'month': 1, 'attempts': 10, 'accuracy': 80, 'improvement': 0.1},
            {'week': 2, 'month': 1, 'attempts': 15, 'accuracy': 85, 'improvement': 0.05},
          ]),
        );
        final trend = await service.getWeeklyTrend('s1');
        expect(trend.length, 2);
        expect(trend[0].week, 1);
        expect(trend[0].attempts, 10);
        expect(trend[1].accuracy, 85);
      });
    });

    group('getFocusStats', () {
      test('returns null when no sessions exist', () async {
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(),
          sessionRepo: _FakeSessionRepo(),
        );
        final stats = await service.getFocusStats();
        expect(stats, isNull);
      });

      test('returns null when no focus sessions', () async {
        final now = DateTime.now();
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(),
          sessionRepo: _FakeSessionRepo(sessions: [
            Session(id: 's1', studentId: 's1', type: SessionType.practice,
                startTime: now, actualDurationMs: 1800000, completed: true),
          ]),
        );
        final stats = await service.getFocusStats();
        expect(stats, isNull);
      });

      test('returns FocusTodayStats when focus sessions exist', () async {
        final now = DateTime.now();
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(),
          sessionRepo: _FakeSessionRepo(sessions: [
            Session(id: 's1', studentId: 's1', type: SessionType.focus,
                startTime: now, actualDurationMs: 3600000, completed: true,
                plannedDurationMinutes: 60),
            Session(id: 's2', studentId: 's1', type: SessionType.focus,
                startTime: now, actualDurationMs: 1800000, completed: false,
                plannedDurationMinutes: 30),
          ]),
        );
        final stats = await service.getFocusStats();
        expect(stats, isNotNull);
        expect(stats!.totalSeconds, 5400);
        expect(stats.completedSessions, 1);
        expect(stats.totalSessions, 2);
        expect(stats.plannedMinutes, 90);
        expect(stats.hours, closeTo(1.5, 0.01));
      });

      test('returns null when session repo throws', () async {
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(),
          sessionRepo: _FakeSessionRepo(throwOnGetByDate: true),
        );
        final stats = await service.getFocusStats();
        expect(stats, isNull);
      });
    });

    group('getAdherenceData', () {
      test('returns AdherenceData with correct values', () async {
        final now = DateTime.now();
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(),
          adherenceRepo: _FakePlanAdherenceRepo(
            avgAdherence: 0.85,
            weekly: [
              PlanAdherenceModel(id: 'w1', studentId: 's1', date: now, adherenceScore: 0.9),
              PlanAdherenceModel(id: 'w2', studentId: 's1', date: now, adherenceScore: 0.7),
            ],
          ),
        );
        final data = await service.getAdherenceData('s1');
        expect(data.averageAdherence, 0.85);
        expect(data.weeklyAdherence, closeTo(0.8, 0.001));
      });

      test('weeklyAdherence is 0 when no weekly records', () async {
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(),
          adherenceRepo: _FakePlanAdherenceRepo(avgAdherence: 0.5, weekly: []),
        );
        final data = await service.getAdherenceData('s1');
        expect(data.averageAdherence, 0.5);
        expect(data.weeklyAdherence, 0.0);
      });

      test('isEmpty is true when both adherences are 0', () async {
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(),
          adherenceRepo: _FakePlanAdherenceRepo(),
        );
        final data = await service.getAdherenceData('s1');
        expect(data.isEmpty, isTrue);
      });
    });

    group('getTopicNamesMap', () {
      test('builds map from topics and mastery data', () async {
        final now = DateTime.now();
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(allMastery: [
            MasteryState(studentId: 's1', topicId: 't1', lastAttempt: now, lastUpdated: now),
            MasteryState(studentId: 's1', topicId: 't_missing', lastAttempt: now, lastUpdated: now),
          ]),
          topicRepo: _FakeTopicRepo(topics: [
            Topic(id: 't1', subjectId: 'sub1', title: 'Topic One', description: '', syllabusText: ''),
            Topic(id: 't2', subjectId: 'sub1', title: 'Topic Two', description: '', syllabusText: ''),
          ]),
        );
        final map = await service.getTopicNamesMap('s1');
        expect(map['t1'], 'Topic One');
        expect(map['t2'], 'Topic Two');
        expect(map['t_missing'], 't_missing');
      });

      test('handles empty topics and mastery data', () async {
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(),
          topicRepo: _FakeTopicRepo(),
        );
        final map = await service.getTopicNamesMap('s1');
        expect(map, isEmpty);
      });

      test('handles failed getAllTopicMastery gracefully', () async {
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(failAllMastery: true),
          topicRepo: _FakeTopicRepo(topics: [
            Topic(id: 't1', subjectId: 'sub1', title: 'Topic One', description: '', syllabusText: ''),
          ]),
        );
        final map = await service.getTopicNamesMap('s1');
        expect(map['t1'], 'Topic One');
      });

      test('handles topic repo failure gracefully', () async {
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(),
          topicRepo: _FakeTopicRepo(failGetAll: true),
        );
        final map = await service.getTopicNamesMap('s1');
        expect(map, isEmpty);
      });
    });

    group('getBadges', () {
      test('returns list of BadgeDisplay on success', () async {
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(),
          progressTracker: _FakeProgressTracker(badges: [
            {'name': 'Badge 1', 'description': 'First badge', 'category': 'achievement'},
            {'name': 'Badge 2', 'description': 'Second badge', 'category': 'general'},
          ]),
        );
        final badges = await service.getBadges('s1');
        expect(badges.length, 2);
        expect(badges[0].name, 'Badge 1');
        expect(badges[0].category, 'achievement');
        expect(badges[1].name, 'Badge 2');
        expect(badges[1].category, 'general');
      });

      test('returns empty list when tracker throws', () async {
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(),
          progressTracker: _FakeProgressTracker(failBadges: true),
        );
        final badges = await service.getBadges('s1');
        expect(badges, isEmpty);
      });

      test('handles empty badges list', () async {
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(),
          progressTracker: _FakeProgressTracker(),
        );
        final badges = await service.getBadges('s1');
        expect(badges, isEmpty);
      });

      test('handles badge with null fields gracefully', () async {
        final service = DashboardService(
          masteryService: _FakeMasteryGraphService(),
          progressTracker: _FakeProgressTracker(badges: [
            {'name': null, 'description': null},
          ]),
        );
        final badges = await service.getBadges('s1');
        expect(badges.length, 1);
        expect(badges[0].name, '');
        expect(badges[0].description, '');
        expect(badges[0].category, 'general');
      });
    });
  });
}
