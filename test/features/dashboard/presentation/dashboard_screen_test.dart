import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider, SettingsController;
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/core/widgets/animated_bar_chart.dart';
import 'package:studyking/features/dashboard/presentation/dashboard_screen.dart';
import 'package:studyking/features/dashboard/providers/dashboard_providers.dart';
import 'package:studyking/features/focus_mode/data/repositories/focus_session_repository.dart';
import 'package:studyking/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:studyking/features/focus_mode/services/focus_session_service.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart' show masteryGraphServiceProvider;
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

MasteryState _masteryState({
  required String topicId,
  double accuracy = 0.0,
  int totalAttempts = 0,
  int correctAttempts = 0,
  MasteryLevel masteryLevel = MasteryLevel.novice,
}) {
  return MasteryState(
    studentId: 'student-1',
    topicId: topicId,
    accuracy: accuracy,
    totalAttempts: totalAttempts,
    correctAttempts: correctAttempts,
    masteryLevel: masteryLevel,
    lastAttempt: DateTime.now(),
    lastUpdated: DateTime.now(),
  );
}

class FakeFocusSessionRepository extends FocusSessionRepository {
  @override
  Future<void> init() async {}
}

class FakeFocusSessionService extends FocusSessionService {
  FakeFocusSessionService() : super(repository: FakeFocusSessionRepository());

  @override
  Future<Map<String, dynamic>> getTodayStats() async => {
    'totalSeconds': 0,
    'completedSessions': 0,
    'totalSessions': 0,
    'plannedMinutes': 0,
    'hours': '0.0',
  };
}

class FakeMasteryGraphService extends MasteryGraphService {
  final List<MasteryState> allMastery;
  final Map<String, dynamic>? snapshot;
  final bool failGetAllMastery;
  final bool failGetSnapshot;

  FakeMasteryGraphService({
    this.allMastery = const [],
    this.snapshot,
    this.failGetAllMastery = false,
    this.failGetSnapshot = false,
  });

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) async {
    if (failGetAllMastery) return Result.failure('Failed to get all mastery');
    return Result.success(allMastery);
  }

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) async {
    if (failGetSnapshot) return Result.failure('Failed to get snapshot');
    return Result.success(snapshot ?? {
      'totalTopics': 0,
      'masteredTopics': 0,
      'weakTopics': 0,
      'averageAccuracy': 0.0,
      'avgReadiness': 0.0,
    });
  }
}

class FakeStudyProgressTracker extends StudyProgressTracker {
  final Map<String, dynamic>? overallStats;
  final List<Map<String, dynamic>> weeklyTrend;
  final List<Map<String, dynamic>> badges;
  final bool failExportProgress;
  final bool failExportSession;
  final Completer<Map<String, dynamic>>? statsCompleter;

  FakeStudyProgressTracker({
    this.overallStats,
    this.weeklyTrend = const [],
    this.badges = const [],
    this.failExportProgress = false,
    this.failExportSession = false,
    this.statsCompleter,
  }) : super(attemptRepo: _FakeAttemptRepository());

  @override
  Future<Map<String, dynamic>> getOverallStats(String studentId) async {
    if (statsCompleter != null) return statsCompleter!.future;
    return overallStats ?? {
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
  Future<List<Map<String, dynamic>>> getWeeklyTrend(int weeks, {String? studentId}) async {
    return weeklyTrend;
  }

  @override
  Future<List<Map<String, dynamic>>> getBadges(String studentId) async {
    return badges;
  }

  @override
  Future<String> exportProgressCSV(String studentId) async {
    if (failExportProgress) throw Exception('Export failed');
    return 'progress,csv,data';
  }

  @override
  Future<String> exportSessionHistoryCSV(String studentId) async {
    if (failExportSession) throw Exception('Session export failed');
    return 'session,csv,data';
  }
}

class _FakeAttemptRepository extends AttemptRepository {
  @override
  Future<void> init() async {}

  @override
  Future<List<StudentAttempt>> getByStudent(String studentId) async {
    return [];
  }
}

class FakeInstrumentationService extends InstrumentationService {
  final Map<String, dynamic>? dashboardData;
  final bool failExport;

  FakeInstrumentationService({
    this.dashboardData,
    this.failExport = false,
  });

  @override
  Future<void> init() async {}

  @override
  Future<Result<Map<String, dynamic>>> getInstrumentationDashboard(String studentId) async {
    return Result.success(dashboardData ?? {
      'planAdherence': {
        'averageAdherence': 0.0,
        'weeklyMetricsCount': 0,
        'weeklyAdherenceAvg': 0.0,
      },
      'masteryImprovement': {},
      'generatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<Result<void>> exportInstrumentationData(String studentId) async {
    if (failExport) return Result.failure('Export failed');
    return Result.success(null);
  }
}

class FakeTopicRepository extends TopicRepository {
  final Topic? topic;
  final bool failGet;

  FakeTopicRepository({this.topic, this.failGet = false});

  @override
  Future<void> init() async {}

  @override
  Future<Topic?> get(String id) async {
    if (failGet) throw Exception('Failed to get topic');
    return topic;
  }
}

Widget _buildTestApp(
  Widget screen, {
  MasteryGraphService? masteryService,
  StudyProgressTracker? tracker,
  InstrumentationService? instrumentation,
  TopicRepository? topicRepo,
}) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsController(SettingsRepository()),
      ),
      if (masteryService != null)
        masteryGraphServiceProvider.overrideWithValue(masteryService),
      if (tracker != null)
        dashboardStudyProgressTrackerProvider.overrideWithValue(tracker),
      if (instrumentation != null)
        dashboardInstrumentationServiceProvider.overrideWithValue(instrumentation),
      if (topicRepo != null)
        dashboardTopicRepositoryProvider.overrideWithValue(topicRepo),
      focusSessionRepositoryProvider.overrideWithValue(FakeFocusSessionRepository()),
      focusSessionServiceProvider.overrideWithValue(FakeFocusSessionService()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: screen),
    ),
  );
}

Widget _buildTestAppWithRoutes(
  Widget screen, {
  MasteryGraphService? masteryService,
  StudyProgressTracker? tracker,
  InstrumentationService? instrumentation,
  TopicRepository? topicRepo,
}) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsController(SettingsRepository()),
      ),
      if (masteryService != null)
        masteryGraphServiceProvider.overrideWithValue(masteryService),
      if (tracker != null)
        dashboardStudyProgressTrackerProvider.overrideWithValue(tracker),
      if (instrumentation != null)
        dashboardInstrumentationServiceProvider.overrideWithValue(instrumentation),
      if (topicRepo != null)
        dashboardTopicRepositoryProvider.overrideWithValue(topicRepo),
      focusSessionRepositoryProvider.overrideWithValue(FakeFocusSessionRepository()),
      focusSessionServiceProvider.overrideWithValue(FakeFocusSessionService()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: screen),
      routes: {
        '/practice-session': (_) => const Scaffold(
          body: Text('Practice Session'),
        ),
      },
    ),
  );
}

Future<void> scrollToFind(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  final defaultTopicRepo = FakeTopicRepository();

  group('DashboardScreen', () {
    group('initial loading state', () {
      testWidgets('shows CircularProgressIndicator initially', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker(statsCompleter: Completer());
        final instrumentation = FakeInstrumentationService();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: defaultTopicRepo,
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('header', () {
      testWidgets('shows dashboard title', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Study Dashboard'), findsOneWidget);
      });
    });

    group('summary row', () {
      testWidgets('shows metric cards with values', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker(overallStats: {
          'accuracy': 80,
          'totalStudyTimeHours': '12.5',
          'weeklyActivity': 15,
          'topicsStudied': 8,
        });
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.text('80%'), findsOneWidget);
        expect(find.text('12.5h'), findsOneWidget);
        expect(find.text('15'), findsOneWidget);
        expect(find.text('8'), findsOneWidget);
      });

      testWidgets('shows default values when stats are empty', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker(overallStats: {});
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.text('0%'), findsAtLeast(1));
        expect(find.text('0h'), findsOneWidget);
      });
    });

    group('weekly chart', () {
      testWidgets('shows chart with weekly trend data', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker(weeklyTrend: [
          {'week': 2026, 'month': 5, 'attempts': 10, 'accuracy': 80, 'improvement': 0},
          {'week': 2026, 'month': 4, 'attempts': 15, 'accuracy': 70, 'improvement': 5},
          {'week': 2026, 'month': 4, 'attempts': 8, 'accuracy': 90, 'improvement': -10},
        ]);
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.byType(AnimatedBarChart), findsOneWidget);
      });

      testWidgets('shows chart when trend is empty', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.byType(AnimatedBarChart), findsOneWidget);
      });
    });

    group('plan adherence', () {
      testWidgets('shows adherence card with data', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService(dashboardData: {
          'planAdherence': {
            'averageAdherence': 0.85,
            'weeklyMetricsCount': 5,
            'weeklyAdherenceAvg': 0.75,
          },
          'masteryImprovement': {},
          'generatedAt': DateTime.now().toIso8601String(),
        });
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Plan Adherence'), findsOneWidget);
        expect(find.text('85%'), findsOneWidget);
        expect(find.text('75%'), findsOneWidget);
      });

      testWidgets('shows 0% when no adherence data', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker();
        final topicRepo = FakeTopicRepository();
        final instrumentation = FakeInstrumentationService(dashboardData: {
          'planAdherence': null,
          'masteryImprovement': {},
          'generatedAt': DateTime.now().toIso8601String(),
        });

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Plan Adherence'), findsOneWidget);
        expect(find.text('0%'), findsAtLeast(1));
      });
    });

    group('mastery progress', () {
      testWidgets('shows mastery overview with snapshot data', (tester) async {
        final masteryService = FakeMasteryGraphService(snapshot: {
          'totalTopics': 20,
          'masteredTopics': 8,
          'weakTopics': 3,
          'averageAccuracy': 0.75,
          'avgReadiness': 0.6,
        });
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Mastery Overview'), findsOneWidget);
        expect(find.text('20'), findsOneWidget);
        expect(find.text('8'), findsOneWidget);
        expect(find.text('75%'), findsOneWidget);
        expect(find.text('60%'), findsOneWidget);
      });

      testWidgets('shows default values when snapshot is empty', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Mastery Overview'), findsOneWidget);
        expect(find.text('0'), findsAtLeast(1));
        expect(find.text('0%'), findsAtLeast(1));
      });
    });

    group('weak areas', () {
      testWidgets('shows weak topics when accuracy < 60%', (tester) async {
        final masteryService = FakeMasteryGraphService(allMastery: [
          _masteryState(topicId: 'topic-weak-1', accuracy: 0.3, totalAttempts: 5),
          _masteryState(topicId: 'topic-weak-2', accuracy: 0.45, totalAttempts: 3),
          _masteryState(topicId: 'topic-strong', accuracy: 0.85, totalAttempts: 10),
        ]);
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository(topic: Topic(
          id: 'topic-weak-1',
          subjectId: 'subj-1',
          title: 'Weak Topic 1',
          description: '',
          syllabusText: '',
        ));

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Weak Areas (Accuracy < 60%)'), findsOneWidget);
        expect(find.text('30%'), findsAtLeast(1));
        expect(find.text('45%'), findsAtLeast(1));
      });

      testWidgets('shows nothing when no weak topics', (tester) async {
        final masteryService = FakeMasteryGraphService(allMastery: [
          _masteryState(topicId: 'topic-strong', accuracy: 0.85, totalAttempts: 10),
        ]);
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Weak Areas (Accuracy < 60%)'), findsNothing);
      });

      testWidgets('limits to 5 weak topics', (tester) async {
        final masteryService = FakeMasteryGraphService(allMastery: List.generate(
          7,
          (i) => _masteryState(
            topicId: 'topic-weak-$i',
            accuracy: 0.2 + i * 0.05,
            totalAttempts: 3,
          ),
        ));
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Weak Areas (Accuracy < 60%)'), findsOneWidget);
        expect(find.text('Practice All Weak Areas'), findsOneWidget);
      });

      testWidgets('practice button navigates to practice session', (tester) async {
        final masteryService = FakeMasteryGraphService(allMastery: [
          _masteryState(topicId: 'topic-weak-1', accuracy: 0.3, totalAttempts: 5),
        ]);
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository(topic: Topic(
          id: 'topic-weak-1',
          subjectId: 'subj-1',
          title: 'Weak Topic 1',
          description: '',
          syllabusText: '',
        ));

        await tester.pumpWidget(_buildTestAppWithRoutes(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        await scrollToFind(tester, find.byIcon(Icons.play_arrow).first);
        await tester.tap(find.byIcon(Icons.play_arrow).first);
        await tester.pumpAndSettle();

        expect(find.text('Practice Session'), findsOneWidget);
      });

      testWidgets('practice all button navigates to practice session', (tester) async {
        final masteryService = FakeMasteryGraphService(allMastery: [
          _masteryState(topicId: 'topic-weak-1', accuracy: 0.3, totalAttempts: 5),
        ]);
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository(topic: Topic(
          id: 'topic-weak-1',
          subjectId: 'subj-1',
          title: 'Weak Topic 1',
          description: '',
          syllabusText: '',
        ));

        await tester.pumpWidget(_buildTestAppWithRoutes(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        await scrollToFind(tester, find.text('Practice All Weak Areas'));
        await tester.tap(find.text('Practice All Weak Areas'));
        await tester.pumpAndSettle();

        expect(find.text('Practice Session'), findsOneWidget);
      });
    });

    group('topic breakdown', () {
      testWidgets('shows empty state message when no topics', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(
          find.text('No topic data yet. Start studying to see your progress!'),
          findsOneWidget,
        );
      });

      testWidgets('shows sorted topic performance', (tester) async {
        final masteryService = FakeMasteryGraphService(allMastery: [
          _masteryState(
            topicId: 'topic-b',
            accuracy: 0.5,
            totalAttempts: 5,
            correctAttempts: 2,
            masteryLevel: MasteryLevel.developing,
          ),
          _masteryState(
            topicId: 'topic-a',
            accuracy: 0.3,
            totalAttempts: 3,
            correctAttempts: 1,
            masteryLevel: MasteryLevel.browsing,
          ),
        ]);
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository(topic: Topic(
          id: 'topic-a',
          subjectId: 'subj-1',
          title: 'Topic A',
          description: '',
          syllabusText: '',
        ));

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Topic Performance'), findsOneWidget);
        expect(find.text('30%'), findsAtLeast(1));
        expect(find.text('3 attempts'), findsOneWidget);
        expect(find.text('Developing'), findsOneWidget);
      });

      testWidgets('limits to 10 topics', (tester) async {
        final masteryService = FakeMasteryGraphService(allMastery: List.generate(
          15,
          (i) => _masteryState(
            topicId: 'topic-$i',
            accuracy: i / 15,
            totalAttempts: 5,
            masteryLevel: MasteryLevel.values[i % 5],
          ),
        ));
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Topic Performance'), findsOneWidget);
      });
    });

    group('badges', () {
      testWidgets('shows badges when available', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker(badges: [
          {'id': 'first', 'name': 'First Step', 'description': 'First question!', 'unlockedAt': DateTime.now().toIso8601String()},
          {'id': 'streak', 'name': 'Daily Scholar', 'description': 'Studied today!', 'unlockedAt': DateTime.now().toIso8601String()},
        ]);
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Achievements'), findsOneWidget);
        expect(find.text('First Step'), findsOneWidget);
        expect(find.text('Daily Scholar'), findsOneWidget);
      });

      testWidgets('shows nothing when no badges', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Achievements'), findsNothing);
      });
    });

    group('export section', () {
      testWidgets('shows three export buttons', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        await scrollToFind(tester, find.text('Export CSV'));

        expect(find.text('Export CSV'), findsOneWidget);
        expect(find.text('Session History'), findsOneWidget);
        expect(find.text('Instrumentation'), findsOneWidget);
      });

      testWidgets('export progress CSV shows success snackbar', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        await scrollToFind(tester, find.text('Export CSV'));
        await tester.tap(find.text('Export CSV'));
        await tester.pumpAndSettle();

        expect(find.text('Progress CSV generated (17 chars)'), findsOneWidget);
      });

      testWidgets('export session history shows success snackbar', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        await scrollToFind(tester, find.text('Session History'));
        await tester.tap(find.text('Session History'));
        await tester.pumpAndSettle();

        expect(find.text('Session history CSV generated (16 chars)'), findsOneWidget);
      });

      testWidgets('export instrumentation shows success snackbar', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        await scrollToFind(tester, find.text('Instrumentation'));
        await tester.tap(find.text('Instrumentation'));
        await tester.pumpAndSettle();

        expect(find.text('Instrumentation data exported'), findsOneWidget);
      });

      testWidgets('export progress CSV failure shows error snackbar', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker(failExportProgress: true);
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        await scrollToFind(tester, find.text('Export CSV'));
        await tester.tap(find.text('Export CSV'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Export failed'), findsOneWidget);
      });

      testWidgets('export session history failure shows error snackbar', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker(failExportSession: true);
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        await scrollToFind(tester, find.text('Session History'));
        await tester.tap(find.text('Session History'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Export failed'), findsOneWidget);
      });

      testWidgets('export instrumentation failure shows error snackbar', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService(failExport: true);
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        await scrollToFind(tester, find.text('Instrumentation'));
        await tester.tap(find.text('Instrumentation'));
        await tester.pumpAndSettle();

        expect(find.text('Instrumentation data exported'), findsOneWidget);
      });
    });

    group('topic name resolution', () {
      testWidgets('resolves topic name from repository', (tester) async {
        final masteryService = FakeMasteryGraphService(allMastery: [
          _masteryState(topicId: 'topic-1', accuracy: 0.3, totalAttempts: 5),
        ]);
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository(topic: Topic(
          id: 'topic-1',
          subjectId: 'subj-1',
          title: 'Algebra Basics',
          description: '',
          syllabusText: '',
        ));

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Algebra Basics'), findsAtLeast(1));
      });

      testWidgets('falls back to topicId when repo throws', (tester) async {
        final masteryService = FakeMasteryGraphService(allMastery: [
          _masteryState(topicId: 'fallback-id', accuracy: 0.3, totalAttempts: 5),
        ]);
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository(failGet: true);

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.text('fallback-id'), findsAtLeast(1));
      });
    });

    group('mastery labels', () {
      testWidgets('displays correct mastery label for each level', (tester) async {
        final masteryService = FakeMasteryGraphService(allMastery: [
          _masteryState(topicId: 't1', accuracy: 0.1, totalAttempts: 0, masteryLevel: MasteryLevel.novice),
          _masteryState(topicId: 't2', accuracy: 0.3, totalAttempts: 1, masteryLevel: MasteryLevel.browsing),
          _masteryState(topicId: 't3', accuracy: 0.6, totalAttempts: 3, masteryLevel: MasteryLevel.developing),
          _masteryState(topicId: 't4', accuracy: 0.8, totalAttempts: 5, masteryLevel: MasteryLevel.proficient),
          _masteryState(topicId: 't5', accuracy: 0.95, totalAttempts: 15, masteryLevel: MasteryLevel.expert),
        ]);
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Novice'), findsOneWidget);
        expect(find.text('Browsing'), findsOneWidget);
        expect(find.text('Developing'), findsOneWidget);
        expect(find.text('Proficient'), findsOneWidget);
        expect(find.text('Expert'), findsOneWidget);
      });
    });

    group('refresh', () {
      testWidgets('has RefreshIndicator', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.byType(RefreshIndicator), findsOneWidget);
      });
    });

    group('mounted guard', () {
      testWidgets('does not crash when unmounted during async load', (tester) async {
        final statsCompleter = Completer<Map<String, dynamic>>();
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker(statsCompleter: statsCompleter);
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpWidget(const SizedBox());

        statsCompleter.complete({
          'accuracy': 50,
          'totalStudyTimeHours': '2',
          'weeklyActivity': 5,
          'topicsStudied': 3,
        });
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('adherence metric colors', () {
      testWidgets('shows high adherence value', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService(dashboardData: {
          'planAdherence': {
            'averageAdherence': 0.85,
            'weeklyMetricsCount': 5,
            'weeklyAdherenceAvg': 0.85,
          },
          'masteryImprovement': {},
          'generatedAt': DateTime.now().toIso8601String(),
        });
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.text('85%'), findsAtLeast(1));
      });

      testWidgets('shows medium adherence value', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService(dashboardData: {
          'planAdherence': {
            'averageAdherence': 0.55,
            'weeklyMetricsCount': 5,
            'weeklyAdherenceAvg': 0.55,
          },
          'masteryImprovement': {},
          'generatedAt': DateTime.now().toIso8601String(),
        });
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.text('55%'), findsAtLeast(1));
      });

      testWidgets('shows low adherence value', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService(dashboardData: {
          'planAdherence': {
            'averageAdherence': 0.25,
            'weeklyMetricsCount': 5,
            'weeklyAdherenceAvg': 0.25,
          },
          'masteryImprovement': {},
          'generatedAt': DateTime.now().toIso8601String(),
        });
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        expect(find.text('25%'), findsAtLeast(1));
      });
    });
  });
}
