import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/providers/dashboard_data_providers.dart';
import 'package:studyking/features/dashboard/providers/dashboard_layout_providers.dart';
import 'package:studyking/features/dashboard/providers/dashboard_providers.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/planner/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart'
    show masteryGraphServiceProvider;

class _FakeMasteryGraphService extends MasteryGraphService {
  final List<MasteryState>? _allMastery;
  final Map<String, dynamic>? _snapshot;
  final bool _failAllMastery;
  final bool _failSnapshot;
  final bool _failInit;

  _FakeMasteryGraphService({
    List<MasteryState>? allMastery,
    Map<String, dynamic>? snapshot,
    bool failAllMastery = false,
    bool failSnapshot = false,
    bool failInit = false,
  })  : _allMastery = allMastery,
        _snapshot = snapshot,
        _failAllMastery = failAllMastery,
        _failSnapshot = failSnapshot,
        _failInit = failInit;

  @override
  Future<void> init() async {
    if (_failInit) throw Exception('init failed');
  }

  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) async {
    if (_failAllMastery) return Result.failure('fail');
    return Result.success(_allMastery ?? []);
  }

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) async {
    if (_failSnapshot) return Result.failure('fail');
    return Result.success(_snapshot ?? {});
  }
}

class _FakeAttemptRepo extends AttemptRepository {
  @override
  Future<void> init() async {}

  @override
  Future<List<StudentAttempt>> getByStudent(String studentId) async => [];
}

class _FakeProgressTracker extends StudyProgressTracker {
  final Map<String, dynamic>? _overallStats;
  final List<Map<String, dynamic>> _weeklyTrend;
  final List<Map<String, dynamic>> _badges;
  final bool _failGetBadges;

  _FakeProgressTracker({
    Map<String, dynamic>? overallStats,
    List<Map<String, dynamic>> weeklyTrend = const [],
    List<Map<String, dynamic>> badges = const [],
    bool failGetBadges = false,
  })  : _overallStats = overallStats,
        _weeklyTrend = weeklyTrend,
        _badges = badges,
        _failGetBadges = failGetBadges,
        super(attemptRepo: _FakeAttemptRepo());

  @override
  Future<Map<String, dynamic>> getOverallStats(String studentId) async {
    return _overallStats ?? {
      'totalAttempts': 0,
      'correctAttempts': 0,
      'accuracy': 0,
      'avgTimePerQuestion': 0,
      'totalStudyTimeHours': '0.0',
      'weeklyActivity': 0,
      'dailyActivity': 0,
      'topicsStudied': 0,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getWeeklyTrend(int weeks,
      {String? studentId}) async {
    return _weeklyTrend;
  }

  @override
  Future<List<Map<String, dynamic>>> getBadges(String studentId) async {
    if (_failGetBadges) throw Exception('Badges error');
    return _badges;
  }
}

class _FakeInstrumentationService extends InstrumentationService {
  @override
  Future<void> init() async {}
}

class _FakeTopicRepo extends TopicRepository {
  final List<Topic> _topics;

  _FakeTopicRepo({List<Topic> topics = const []}) : _topics = topics;

  @override
  Future<void> init() async {}

  @override
  Future<List<Topic>> getAll() async => _topics;
}

class _FakePlanAdherenceRepo extends PlanAdherenceRepository {
  final double _avgAdherence;
  final List<PlanAdherenceModel> _weeklyRecords;

  _FakePlanAdherenceRepo({
    double avgAdherence = 0.0,
    List<PlanAdherenceModel> weeklyRecords = const [],
  })  : _avgAdherence = avgAdherence,
        _weeklyRecords = weeklyRecords;

  @override
  Future<void> init() async {}

  @override
  Future<double> getAverageAdherence(String studentId) async => _avgAdherence;

  @override
  Future<List<PlanAdherenceModel>> getWeekly(String studentId) async =>
      _weeklyRecords;
}

class _FakeSessionRepo extends SessionRepository {
  final List<Session> _sessions;
  final bool _throwOnGetByDate;

  _FakeSessionRepo({List<Session> sessions = const [], bool throwOnGetByDate = false})
      : _sessions = sessions,
        _throwOnGetByDate = throwOnGetByDate;

  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async {
    if (_throwOnGetByDate) throw Exception('getByDate error');
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return Result.success(_sessions.where((s) =>
        s.startTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
        s.startTime.isBefore(end)).toList());
  }
}

ProviderContainer _createContainer({
  MasteryGraphService? masteryService,
  StudyProgressTracker? tracker,
  InstrumentationService? instrumentation,
  TopicRepository? topicRepo,
  PlanAdherenceRepository? adherenceRepo,
  SessionRepository? sessionRepo,
}) {
  return ProviderContainer(
    overrides: [
      masteryGraphServiceProvider.overrideWithValue(
        masteryService ?? _FakeMasteryGraphService(),
      ),
      dashboardStudyProgressTrackerProvider.overrideWithValue(
        tracker ?? _FakeProgressTracker(),
      ),
      dashboardInstrumentationServiceProvider.overrideWithValue(
        instrumentation ?? _FakeInstrumentationService(),
      ),
      dashboardTopicRepositoryProvider.overrideWithValue(
        topicRepo ?? _FakeTopicRepo(),
      ),
      dashboardAdherenceRepositoryProvider.overrideWithValue(
        adherenceRepo ?? _FakePlanAdherenceRepo(),
      ),
      if (sessionRepo != null)
        sessionRepositoryProvider.overrideWithValue(sessionRepo),
    ],
  );
}

void main() {
  group('DashboardLayoutPreferences', () {
    group('default constructor', () {
      test('creates instance with empty collapsedCards', () {
        final prefs = DashboardLayoutPreferences();
        expect(prefs.collapsedCards, isEmpty);
      });

      test('isCollapsed returns false for any card', () {
        final prefs = DashboardLayoutPreferences();
        expect(prefs.isCollapsed('any-card'), isFalse);
      });
    });

    group('named constructor with values', () {
      test('creates instance with provided collapsed set', () {
        final prefs = DashboardLayoutPreferences(
          collapsedCards: {'card-1', 'card-2'},
        );
        expect(prefs.collapsedCards, {'card-1', 'card-2'});
      });

      test('isCollapsed returns true for cards in the set', () {
        final prefs = DashboardLayoutPreferences(
          collapsedCards: {'card-1'},
        );
        expect(prefs.isCollapsed('card-1'), isTrue);
        expect(prefs.isCollapsed('card-2'), isFalse);
      });
    });

    group('copyWith', () {
      test('returns same instance when no arguments provided', () {
        final prefs = DashboardLayoutPreferences(
          collapsedCards: {'card-1'},
        );
        final copy = prefs.copyWith();
        expect(copy.collapsedCards, {'card-1'});
      });

      test('replaces collapsedCards when provided', () {
        final prefs = DashboardLayoutPreferences(
          collapsedCards: {'card-1'},
        );
        final copy = prefs.copyWith(collapsedCards: {'card-2', 'card-3'});
        expect(copy.collapsedCards, {'card-2', 'card-3'});
      });

      test('does not mutate original instance', () {
        final prefs = DashboardLayoutPreferences(
          collapsedCards: {'card-1'},
        );
        prefs.copyWith(collapsedCards: {'card-2'});
        expect(prefs.collapsedCards, {'card-1'});
      });
    });
  });

  group('DashboardLayoutNotifier', () {
    test('default state has empty collapsedCards', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(dashboardLayoutPreferencesProvider).collapsedCards, isEmpty);
    });

    group('toggleCollapsed', () {
      test('adds card to collapsed set', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.read(dashboardLayoutPreferencesProvider.notifier).toggleCollapsed('test-card');
        expect(container.read(dashboardLayoutPreferencesProvider).isCollapsed('test-card'), isTrue);
      });

      test('removes card from collapsed set on second toggle', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(dashboardLayoutPreferencesProvider.notifier);
        notifier.toggleCollapsed('test-card');
        expect(container.read(dashboardLayoutPreferencesProvider).isCollapsed('test-card'), isTrue);

        notifier.toggleCollapsed('test-card');
        expect(container.read(dashboardLayoutPreferencesProvider).isCollapsed('test-card'), isFalse);
      });

      test('multiple cards independently toggle', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(dashboardLayoutPreferencesProvider.notifier);
        notifier.toggleCollapsed('card-a');
        notifier.toggleCollapsed('card-b');

        expect(container.read(dashboardLayoutPreferencesProvider).isCollapsed('card-a'), isTrue);
        expect(container.read(dashboardLayoutPreferencesProvider).isCollapsed('card-b'), isTrue);

        notifier.toggleCollapsed('card-a');

        expect(container.read(dashboardLayoutPreferencesProvider).isCollapsed('card-a'), isFalse);
        expect(container.read(dashboardLayoutPreferencesProvider).isCollapsed('card-b'), isTrue);
      });

      test('emits new state after toggle', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(dashboardLayoutPreferencesProvider.notifier);
        final states = <DashboardLayoutPreferences>[];
        notifier.addListener((state) => states.add(state), fireImmediately: false);

        notifier.toggleCollapsed('card');
        expect(states.length, 1);
        expect(states[0].isCollapsed('card'), isTrue);
      });

      test('empty collapsed set works after toggle and untoggle', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(dashboardLayoutPreferencesProvider.notifier);
        notifier.toggleCollapsed('card');
        notifier.toggleCollapsed('card');
        expect(container.read(dashboardLayoutPreferencesProvider).collapsedCards, isEmpty);
      });
    });

    group('init', () {
      late Directory hiveDir;

      setUp(() {
        hiveDir = Directory.systemTemp.createTempSync('layout_init_test_');
        Hive.init(hiveDir.path);
      });

      tearDown(() async {
        await Hive.deleteBoxFromDisk('dashboard_layout_prefs');
        hiveDir.deleteSync(recursive: true);
      });

      test('loads saved collapsed cards from Hive', () async {
        final box = await Hive.openBox('dashboard_layout_prefs');
        await box.put('collapsedCards', ['card-1', 'card-2']);
        await box.close();

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(dashboardLayoutPreferencesProvider.notifier);
        await notifier.init();

        expect(
          container.read(dashboardLayoutPreferencesProvider).collapsedCards,
          {'card-1', 'card-2'},
        );
      });

      test('keeps empty set when no saved data', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(dashboardLayoutPreferencesProvider.notifier);
        await notifier.init();

        expect(
          container.read(dashboardLayoutPreferencesProvider).collapsedCards,
          isEmpty,
        );
      });
    });
  });

  group('dashboardLayoutPreferencesProvider', () {
    test('resolves DashboardLayoutNotifier', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(dashboardLayoutPreferencesProvider.notifier);
      expect(notifier, isA<DashboardLayoutNotifier>());
    });

    test('returns DashboardLayoutPreferences', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final prefs = container.read(dashboardLayoutPreferencesProvider);
      expect(prefs, isA<DashboardLayoutPreferences>());
    });

    test('default state has empty collapsed set', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final prefs = container.read(dashboardLayoutPreferencesProvider);
      expect(prefs.collapsedCards, isEmpty);
    });

    test('can toggle through provider notifier', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(dashboardLayoutPreferencesProvider.notifier).toggleCollapsed('card-1');
      final prefs = container.read(dashboardLayoutPreferencesProvider);
      expect(prefs.isCollapsed('card-1'), isTrue);
    });

    test('toggle and untoggle through provider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(dashboardLayoutPreferencesProvider.notifier);
      notifier.toggleCollapsed('card-1');
      expect(container.read(dashboardLayoutPreferencesProvider).isCollapsed('card-1'), isTrue);

      notifier.toggleCollapsed('card-1');
      expect(container.read(dashboardLayoutPreferencesProvider).isCollapsed('card-1'), isFalse);
    });
  });

  group('dashboardAllMasteryProvider', () {
    test('returns list of MasteryState on success', () async {
      final now = DateTime.now();
      final masteryService = _FakeMasteryGraphService(
        allMastery: [
          MasteryState(studentId: 's1', topicId: 't1', lastAttempt: now, lastUpdated: now),
          MasteryState(studentId: 's1', topicId: 't2', lastAttempt: now, lastUpdated: now),
        ],
      );
      final container = _createContainer(masteryService: masteryService);
      addTearDown(container.dispose);

      final result = await container.read(dashboardAllMasteryProvider('s1').future);
      expect(result.length, 2);
    });

    test('returns empty list when getAllTopicMastery fails', () async {
      final masteryService = _FakeMasteryGraphService(failAllMastery: true);
      final container = _createContainer(masteryService: masteryService);
      addTearDown(container.dispose);

      final result = await container.read(dashboardAllMasteryProvider('s1').future);
      expect(result, isEmpty);
    });
  });

  group('dashboardMasterySnapshotProvider', () {
    test('returns MasterySnapshot on success', () async {
      final masteryService = _FakeMasteryGraphService(
        snapshot: {
          'totalTopics': 5,
          'masteredTopics': 2,
          'weakTopics': 1,
          'averageAccuracy': 0.8,
          'avgReadiness': 0.7,
        },
      );
      final container = _createContainer(masteryService: masteryService);
      addTearDown(container.dispose);

      final result = await container.read(dashboardMasterySnapshotProvider('s1').future);
      expect(result, isA<MasterySnapshot>());
      expect(result!.totalTopics, 5);
      expect(result.masteredTopics, 2);
    });

    test('returns null when getMasterySnapshot fails', () async {
      final masteryService = _FakeMasteryGraphService(failSnapshot: true);
      final container = _createContainer(masteryService: masteryService);
      addTearDown(container.dispose);

      final result = await container.read(dashboardMasterySnapshotProvider('s1').future);
      expect(result, isNull);
    });
  });

  group('dashboardOverallStatsProvider', () {
    test('returns OverallStats from tracker', () async {
      final tracker = _FakeProgressTracker(
        overallStats: {
          'totalAttempts': 100,
          'correctAttempts': 75,
          'accuracy': 75,
          'avgTimePerQuestion': 30,
          'totalStudyTimeHours': '12.5',
          'weeklyActivity': 5,
          'dailyActivity': 1,
          'topicsStudied': 8,
        },
      );
      final container = _createContainer(tracker: tracker);
      addTearDown(container.dispose);

      final result = await container.read(dashboardOverallStatsProvider('s1').future);
      expect(result!.totalAttempts, 100);
      expect(result.accuracy, 75);
      expect(result.topicsStudied, 8);
    });
  });

  group('dashboardWeeklyTrendProvider', () {
    test('returns list of WeeklyTrendEntry from tracker', () async {
      final tracker = _FakeProgressTracker(
        weeklyTrend: [
          {'week': 1, 'month': 1, 'attempts': 10, 'accuracy': 80, 'improvement': 0.1},
          {'week': 2, 'month': 1, 'attempts': 15, 'accuracy': 85, 'improvement': 0.05},
        ],
      );
      final container = _createContainer(tracker: tracker);
      addTearDown(container.dispose);

      final result = await container.read(dashboardWeeklyTrendProvider('s1').future);
      expect(result.length, 2);
      expect(result[0].week, 1);
      expect(result[1].accuracy, 85);
    });
  });

  group('dashboardFocusStatsProvider', () {
    test('returns null when no sessions today', () async {
      final sessionRepo = _FakeSessionRepo(sessions: []);
      final container = _createContainer(sessionRepo: sessionRepo);
      addTearDown(container.dispose);

      final result = await container.read(dashboardFocusStatsProvider('s1').future);
      expect(result, isNull);
    });

    test('returns null when no focus sessions today', () async {
      final now = DateTime.now();
      final sessionRepo = _FakeSessionRepo(sessions: [
        Session(
          id: 's1',
          studentId: 's1',
          type: SessionType.practice,
          startTime: now,
          actualDurationMs: 1800000,
          completed: true,
        ),
      ]);
      final container = _createContainer(sessionRepo: sessionRepo);
      addTearDown(container.dispose);

      final result = await container.read(dashboardFocusStatsProvider('s1').future);
      expect(result, isNull);
    });

    test('returns FocusTodayStats when focus sessions exist', () async {
      final now = DateTime.now();
      final sessionRepo = _FakeSessionRepo(sessions: [
        Session(
          id: 's1',
          studentId: 's1',
          type: SessionType.focus,
          startTime: now,
          actualDurationMs: 1800000,
          completed: true,
          plannedDurationMinutes: 30,
        ),
        Session(
          id: 's2',
          studentId: 's1',
          type: SessionType.focus,
          startTime: now,
          actualDurationMs: 900000,
          completed: false,
          plannedDurationMinutes: 15,
        ),
      ]);
      final container = _createContainer(sessionRepo: sessionRepo);
      addTearDown(container.dispose);

      final result = await container.read(dashboardFocusStatsProvider('s1').future);
      expect(result, isA<FocusTodayStats>());
      expect(result!.completedSessions, 1);
      expect(result.totalSessions, 2);
      expect(result.plannedMinutes, 45);
    });

    test('handles session repository error gracefully', () async {
      final sessionRepo = _FakeSessionRepo(throwOnGetByDate: true);
      final container = _createContainer(sessionRepo: sessionRepo);
      addTearDown(container.dispose);

      final result = await container.read(dashboardFocusStatsProvider('s1').future);
      expect(result, isNull);
    });

    test('computes totalMs and totalSeconds correctly', () async {
      final now = DateTime.now();
      final sessionRepo = _FakeSessionRepo(sessions: [
        Session(
          id: 's1',
          studentId: 's1',
          type: SessionType.focus,
          startTime: now,
          actualDurationMs: 3600000,
          completed: true,
          plannedDurationMinutes: 60,
        ),
      ]);
      final container = _createContainer(sessionRepo: sessionRepo);
      addTearDown(container.dispose);

      final result = await container.read(dashboardFocusStatsProvider('s1').future);
      expect(result!.totalSeconds, 3600);
      expect(result.totalSessions, 1);
      expect(result.completedSessions, 1);
      expect(result.plannedMinutes, 60);
    });
  });

  group('dashboardInitProvider', () {
    test('enters error state when a service init fails', () async {
      final masteryService = _FakeMasteryGraphService(failInit: true);
      final container = _createContainer(masteryService: masteryService);
      addTearDown(container.dispose);

      await expectLater(
        container.read(dashboardInitProvider.future),
        throwsA(isA<Exception>()),
      );
      expect(container.read(dashboardInitProvider).hasError, isTrue);
    });
  });

  group('dashboardWeeklyTrendProvider', () {
    test('returns empty list when no weekly trend data', () async {
      final tracker = _FakeProgressTracker(weeklyTrend: []);
      final container = _createContainer(tracker: tracker);
      addTearDown(container.dispose);

      final result = await container.read(dashboardWeeklyTrendProvider('s1').future);
      expect(result, isEmpty);
    });
  });

  group('dashboardOverallStatsProvider', () {
    test('returns OverallStats with default values when stats are empty', () async {
      final tracker = _FakeProgressTracker(
        overallStats: {
          'totalAttempts': 0,
          'correctAttempts': 0,
          'accuracy': 0,
          'avgTimePerQuestion': 0,
          'totalStudyTimeHours': '0',
          'weeklyActivity': 0,
          'dailyActivity': 0,
          'topicsStudied': 0,
        },
      );
      final container = _createContainer(tracker: tracker);
      addTearDown(container.dispose);

      final result = await container.read(dashboardOverallStatsProvider('s1').future);
      expect(result!.totalAttempts, 0);
      expect(result.accuracy, 0);
      expect(result.topicsStudied, 0);
      expect(result.isEmpty, isTrue);
    });

    test('returns OverallStats with partial stats map', () async {
      final tracker = _FakeProgressTracker(
        overallStats: {
          'totalAttempts': 10,
        },
      );
      final container = _createContainer(tracker: tracker);
      addTearDown(container.dispose);

      final result = await container.read(dashboardOverallStatsProvider('s1').future);
      expect(result!.totalAttempts, 10);
      expect(result.correctAttempts, 0);
      expect(result.accuracy, 0);
      expect(result.totalStudyTimeHours, 0);
    });
  });

  group('dashboardAdherenceDataProvider', () {
    test('returns AdherenceData with correct values', () async {
      final adherenceRepo = _FakePlanAdherenceRepo(
        avgAdherence: 0.85,
        weeklyRecords: [
          PlanAdherenceModel(
            id: 'w1',
            studentId: 's1',
            date: DateTime.now(),
            adherenceScore: 0.9,
          ),
          PlanAdherenceModel(
            id: 'w2',
            studentId: 's1',
            date: DateTime.now(),
            adherenceScore: 0.8,
          ),
          PlanAdherenceModel(
            id: 'w3',
            studentId: 's1',
            date: DateTime.now(),
            adherenceScore: 0.7,
          ),
        ],
      );
      final container = _createContainer(adherenceRepo: adherenceRepo);
      addTearDown(container.dispose);

      final result = await container.read(dashboardAdherenceDataProvider('s1').future);
      expect(result.averageAdherence, 0.85);
      expect(result.weeklyAdherence, closeTo(0.8, 0.001));
    });

    test('weeklyAdherence is 0 when no weekly records', () async {
      final adherenceRepo = _FakePlanAdherenceRepo(
        avgAdherence: 0.5,
        weeklyRecords: [],
      );
      final container = _createContainer(adherenceRepo: adherenceRepo);
      addTearDown(container.dispose);

      final result = await container.read(dashboardAdherenceDataProvider('s1').future);
      expect(result.averageAdherence, 0.5);
      expect(result.weeklyAdherence, 0.0);
    });
  });

  group('dashboardTopicNamesProvider', () {
    test('builds topic name map from topics and mastery data', () async {
      final now = DateTime.now();
      final masteryService = _FakeMasteryGraphService(
        allMastery: [
          MasteryState(studentId: 's1', topicId: 't1', lastAttempt: now, lastUpdated: now),
          MasteryState(studentId: 's1', topicId: 't2', lastAttempt: now, lastUpdated: now),
          MasteryState(studentId: 's1', topicId: 't3', lastAttempt: now, lastUpdated: now),
        ],
      );
      final topicRepo = _FakeTopicRepo(
        topics: [
          Topic(id: 't1', subjectId: 'sub1', title: 'Topic 1', description: '', syllabusText: ''),
          Topic(id: 't2', subjectId: 'sub1', title: 'Topic 2', description: '', syllabusText: ''),
        ],
      );
      final container = _createContainer(
        masteryService: masteryService,
        topicRepo: topicRepo,
      );
      addTearDown(container.dispose);

      final result = await container.read(dashboardTopicNamesProvider('s1').future);
      expect(result['t1'], 'Topic 1');
      expect(result['t2'], 'Topic 2');
      expect(result['t3'], 't3');
    });

    test('handles empty topics and mastery data', () async {
      final masteryService = _FakeMasteryGraphService(
        allMastery: [],
      );
      final topicRepo = _FakeTopicRepo(topics: []);
      final container = _createContainer(
        masteryService: masteryService,
        topicRepo: topicRepo,
      );
      addTearDown(container.dispose);

      final result = await container.read(dashboardTopicNamesProvider('s1').future);
      expect(result, isEmpty);
    });
  });

  group('dashboardBadgesProvider', () {
    test('returns list of BadgeDisplay on success', () async {
      final tracker = _FakeProgressTracker(
        badges: [
          {'name': 'Badge 1', 'description': 'First badge', 'category': 'achievement'},
          {'name': 'Badge 2', 'description': 'Second badge', 'category': 'general'},
        ],
      );
      final container = _createContainer(tracker: tracker);
      addTearDown(container.dispose);

      final result = await container.read(dashboardBadgesProvider('s1').future);
      expect(result.length, 2);
      expect(result[0].name, 'Badge 1');
      expect(result[0].category, 'achievement');
    });

    test('handles empty badges list', () async {
      final tracker = _FakeProgressTracker(badges: []);
      final container = _createContainer(tracker: tracker);
      addTearDown(container.dispose);

      final result = await container.read(dashboardBadgesProvider('s1').future);
      expect(result, isEmpty);
    });

    test('returns empty list on error from tracker', () async {
      final tracker = _FakeProgressTracker(failGetBadges: true);
      final container = _createContainer(tracker: tracker);
      addTearDown(container.dispose);

      final result = await container.read(dashboardBadgesProvider('s1').future);
      expect(result, isEmpty);
    });

    test('handles badge with null fields gracefully', () async {
      final tracker = _FakeProgressTracker(
        badges: [
          {'name': null, 'description': null},
        ],
      );
      final container = _createContainer(tracker: tracker);
      addTearDown(container.dispose);

      final result = await container.read(dashboardBadgesProvider('s1').future);
      expect(result.length, 1);
      expect(result[0].name, '');
      expect(result[0].description, '');
      expect(result[0].category, 'general');
    });
  });
}
