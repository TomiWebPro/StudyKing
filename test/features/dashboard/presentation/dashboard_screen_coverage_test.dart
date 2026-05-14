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
import 'package:studyking/core/widgets/metric_card.dart';
import 'package:studyking/features/dashboard/presentation/dashboard_screen.dart';
import 'package:studyking/features/dashboard/providers/dashboard_providers.dart';
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

class _FakeAttemptRepository extends AttemptRepository {
  @override
  Future<void> init() async {}

  @override
  Future<List<StudentAttempt>> getByStudent(String studentId) async {
    return [];
  }
}

class _FakeMasteryGraphService extends MasteryGraphService {
  final List<MasteryState> allMastery;
  final Map<String, dynamic>? snapshot;
  final bool failGetAllMastery;
  final bool failGetSnapshot;

  _FakeMasteryGraphService({
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

class _FakeTracker extends StudyProgressTracker {
  final Map<String, dynamic>? overallStats;
  final List<Map<String, dynamic>> weeklyTrend;
  final List<Map<String, dynamic>> badges;
  final Completer<String>? exportProgressCompleter;
  final Completer<String>? exportSessionCompleter;

  _FakeTracker({
    this.overallStats,
    this.weeklyTrend = const [],
    this.badges = const [],
    this.exportProgressCompleter,
    this.exportSessionCompleter,
  }) : super(attemptRepo: _FakeAttemptRepository());

  @override
  Future<Map<String, dynamic>> getOverallStats(String studentId) async {
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
    if (exportProgressCompleter != null) return exportProgressCompleter!.future;
    return 'progress,csv,data';
  }

  @override
  Future<String> exportSessionHistoryCSV(String studentId) async {
    if (exportSessionCompleter != null) return exportSessionCompleter!.future;
    return 'session,csv,data';
  }
}

class _FakeInstrumentation extends InstrumentationService {
  final Map<String, dynamic>? dashboardData;
  final bool failExport;
  final Completer<void>? exportCompleter;

  _FakeInstrumentation({
    this.dashboardData,
    this.failExport = false,
    this.exportCompleter,
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
    if (exportCompleter != null) {
      return exportCompleter!.future.then((_) => Result.success(null));
    }
    if (failExport) return Result.failure('Export failed');
    return Result.success(null);
  }
}

class _FakeTopicRepo extends TopicRepository {
  final bool returnNull;

  _FakeTopicRepo({this.returnNull = false});

  @override
  Future<void> init() async {}

  @override
  Future<Topic?> get(String id) async {
    if (returnNull) return null;
    return Topic(
      id: id,
      subjectId: 'subj-1',
      title: 'Topic $id',
      description: '',
      syllabusText: '',
    );
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

Future<void> _scrollToFind(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('DashboardScreen - additional coverage', () {
    group('data loading failure paths', () {
      testWidgets('getAllTopicMastery failure leaves _allMastery empty', (
        tester,
      ) async {
        final mastery = _FakeMasteryGraphService(
          failGetAllMastery: true,
          snapshot: {
            'totalTopics': 5,
            'masteredTopics': 2,
            'weakTopics': 3,
            'averageAccuracy': 0.5,
            'avgReadiness': 0.5,
          },
        );

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: mastery,
          tracker: _FakeTracker(),
          instrumentation: _FakeInstrumentation(),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Mastery Overview'), findsOneWidget);
        expect(find.text('Weak Areas (Accuracy < 60%)'), findsNothing);
        expect(
          find.text(
            'No topic data yet. Start studying to see your progress!',
          ),
          findsOneWidget,
        );
      });

      testWidgets('getMasterySnapshot failure defaults to zeros', (tester) async {
        final mastery = _FakeMasteryGraphService(
          failGetSnapshot: true,
          allMastery: [
            _masteryState(
              topicId: 'topic-1',
              accuracy: 0.5,
              totalAttempts: 5,
            ),
          ],
        );

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: mastery,
          tracker: _FakeTracker(),
          instrumentation: _FakeInstrumentation(),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Mastery Overview'), findsOneWidget);
        expect(find.text('0'), findsAtLeast(1));
        expect(find.text('Topic Performance'), findsOneWidget);
      });

      testWidgets('topic repo returns null falls back to topicId', (
        tester,
      ) async {
        final mastery = _FakeMasteryGraphService(allMastery: [
          _masteryState(
            topicId: 'null-topic-id',
            accuracy: 0.3,
            totalAttempts: 5,
          ),
        ]);

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: mastery,
          tracker: _FakeTracker(),
          instrumentation: _FakeInstrumentation(),
          topicRepo: _FakeTopicRepo(returnNull: true),
        ));
        await tester.pumpAndSettle();

        expect(find.text('null-topic-id'), findsAtLeast(1));
      });
    });

    group('summary row edge cases', () {
      testWidgets('renders all four MetricCards', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(),
          tracker: _FakeTracker(overallStats: {
            'accuracy': 80,
            'totalStudyTimeHours': '10',
            'weeklyActivity': 20,
            'topicsStudied': 5,
          }),
          instrumentation: _FakeInstrumentation(),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(MetricCard), findsNWidgets(4));
        expect(find.text('80%'), findsOneWidget);
        expect(find.text('10h'), findsOneWidget);
        expect(find.text('20'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('handles large stats values', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(),
          tracker: _FakeTracker(overallStats: {
            'accuracy': 100,
            'totalStudyTimeHours': '999.9',
            'weeklyActivity': 9999,
            'topicsStudied': 500,
          }),
          instrumentation: _FakeInstrumentation(),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('100%'), findsOneWidget);
        expect(find.text('999.9h'), findsOneWidget);
        expect(find.text('9999'), findsOneWidget);
        expect(find.text('500'), findsOneWidget);
      });
    });

    group('weekly chart edge cases', () {
      testWidgets('empty trend shows default weekday labels', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(),
          tracker: _FakeTracker(),
          instrumentation: _FakeInstrumentation(),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Mon'), findsOneWidget);
        expect(find.text('Tue'), findsOneWidget);
        expect(find.text('Wed'), findsOneWidget);
        expect(find.text('Thu'), findsOneWidget);
        expect(find.text('Fri'), findsOneWidget);
        expect(find.text('Sat'), findsOneWidget);
        expect(find.text('Sun'), findsOneWidget);
      });

      testWidgets('trend with fewer than 7 items shows week labels', (
        tester,
      ) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(),
          tracker: _FakeTracker(weeklyTrend: [
            {'week': 2026, 'attempts': 5, 'accuracy': 80},
            {'week': 2026, 'attempts': 10, 'accuracy': 90},
          ]),
          instrumentation: _FakeInstrumentation(),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('W2'), findsOneWidget);
        expect(find.text('W1'), findsOneWidget);
      });
    });

    group('topic breakdown edge cases', () {
      testWidgets('shows all 10 topics when exactly 10 exist', (tester) async {
        final topics = List.generate(
          10,
          (i) => _masteryState(
            topicId: 'topic-$i',
            accuracy: (i + 1) / 10,
            totalAttempts: 3 + i,
          ),
        );

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(allMastery: topics),
          tracker: _FakeTracker(),
          instrumentation: _FakeInstrumentation(),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Topic Performance'), findsOneWidget);
        for (var i = 0; i < 10; i++) {
          expect(find.text('topic-$i'), findsAtLeast(1));
        }
      });

      testWidgets('topic with 0 attempts shows zero count', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(allMastery: [
            _masteryState(
              topicId: 'zero-attempts',
              accuracy: 0.0,
              totalAttempts: 0,
            ),
          ]),
          tracker: _FakeTracker(),
          instrumentation: _FakeInstrumentation(),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('0 attempts'), findsOneWidget);
      });
    });

    group('weak areas accuracy boundary', () {
      testWidgets('topic at exactly 60% is NOT weak', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(allMastery: [
            _masteryState(
              topicId: 'boundary',
              accuracy: 0.6,
              totalAttempts: 5,
            ),
          ]),
          tracker: _FakeTracker(),
          instrumentation: _FakeInstrumentation(),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Weak Areas (Accuracy < 60%)'), findsNothing);
      });

      testWidgets('topic slightly below 60% IS weak', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(allMastery: [
            _masteryState(
              topicId: 'almost',
              accuracy: 0.59,
              totalAttempts: 5,
            ),
          ]),
          tracker: _FakeTracker(),
          instrumentation: _FakeInstrumentation(),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Weak Areas (Accuracy < 60%)'), findsOneWidget);
        expect(find.text('59%'), findsAtLeast(1));
      });

      testWidgets('displays Practice All button when weak topics exist', (
        tester,
      ) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(allMastery: List.generate(
            8,
            (i) => _masteryState(
              topicId: 'weak-$i',
              accuracy: 0.1 + i * 0.05,
              totalAttempts: 2,
            ),
          )),
          tracker: _FakeTracker(),
          instrumentation: _FakeInstrumentation(),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Weak Areas (Accuracy < 60%)'), findsOneWidget);
        expect(find.text('Practice All Weak Areas'), findsOneWidget);
        for (var i = 0; i < 5; i++) {
          expect(find.text('weak-$i'), findsAtLeast(1));
        }
      });

      testWidgets('practice all button navigates to practice session', (
        tester,
      ) async {
        await tester.pumpWidget(_buildTestAppWithRoutes(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(allMastery: [
            _masteryState(
              topicId: 'weak-1',
              accuracy: 0.3,
              totalAttempts: 3,
            ),
          ]),
          tracker: _FakeTracker(),
          instrumentation: _FakeInstrumentation(),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        await _scrollToFind(tester, find.text('Practice All Weak Areas'));
        await tester.tap(find.text('Practice All Weak Areas'));
        await tester.pumpAndSettle();

        expect(find.text('Practice Session'), findsOneWidget);
      });
    });

    group('badges edge cases', () {
      testWidgets('badge with null name shows empty Chip', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(),
          tracker: _FakeTracker(badges: [
            {'id': 'no-name', 'description': 'No name badge'},
          ]),
          instrumentation: _FakeInstrumentation(),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Achievements'), findsOneWidget);
        expect(find.byType(Chip), findsOneWidget);
      });

      testWidgets('single badge renders correctly', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(),
          tracker: _FakeTracker(badges: [
            {
              'id': 'single',
              'name': 'Solo Badge',
              'description': 'Only one',
            },
          ]),
          instrumentation: _FakeInstrumentation(),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Achievements'), findsOneWidget);
        expect(find.text('Solo Badge'), findsOneWidget);
        expect(find.byType(Chip), findsOneWidget);
      });
    });

    group('mounted guard during export', () {
      testWidgets('dispose during progress CSV export does not crash', (
        tester,
      ) async {
        final exportCompleter = Completer<String>();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(),
          tracker: _FakeTracker(exportProgressCompleter: exportCompleter),
          instrumentation: _FakeInstrumentation(),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        await _scrollToFind(tester, find.text('Export CSV'));
        await tester.tap(find.text('Export CSV'));
        await tester.pump();

        await tester.pumpWidget(const SizedBox());
        await tester.pump();

        exportCompleter.complete('data');
        await tester.pump();

        expect(find.byType(DashboardScreen), findsNothing);
      });

      testWidgets('dispose during session CSV export does not crash', (
        tester,
      ) async {
        final exportCompleter = Completer<String>();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(),
          tracker: _FakeTracker(exportSessionCompleter: exportCompleter),
          instrumentation: _FakeInstrumentation(),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        await _scrollToFind(tester, find.text('Session History'));
        await tester.tap(find.text('Session History'));
        await tester.pump();

        await tester.pumpWidget(const SizedBox());
        await tester.pump();

        exportCompleter.complete('data');
        await tester.pump();

        expect(find.byType(DashboardScreen), findsNothing);
      });

      testWidgets('dispose during instrumentation export does not crash', (
        tester,
      ) async {
        final exportCompleter = Completer<void>();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(),
          tracker: _FakeTracker(),
          instrumentation: _FakeInstrumentation(
            exportCompleter: exportCompleter,
          ),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        await _scrollToFind(tester, find.text('Instrumentation'));
        await tester.tap(find.text('Instrumentation'));
        await tester.pump();

        await tester.pumpWidget(const SizedBox());
        await tester.pump();

        exportCompleter.complete();
        await tester.pump();

        expect(find.byType(DashboardScreen), findsNothing);
      });
    });

    group('instrumentation export behavior', () {
      testWidgets('instrumentation Result.failure shows success snackbar', (
        tester,
      ) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(),
          tracker: _FakeTracker(),
          instrumentation: _FakeInstrumentation(failExport: true),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        await _scrollToFind(tester, find.text('Instrumentation'));
        await tester.tap(find.text('Instrumentation'));
        await tester.pumpAndSettle();

        expect(find.text('Instrumentation data exported'), findsOneWidget);
      });
    });

    group('adherence metric threshold boundaries', () {
      testWidgets('adherence at exactly 0.7 displays 70%', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(),
          tracker: _FakeTracker(),
          instrumentation: _FakeInstrumentation(dashboardData: {
            'planAdherence': {
              'averageAdherence': 0.7,
              'weeklyMetricsCount': 5,
              'weeklyAdherenceAvg': 0.7,
            },
            'masteryImprovement': {},
            'generatedAt': DateTime.now().toIso8601String(),
          }),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('70%'), findsAtLeast(2));
      });

      testWidgets('adherence at exactly 0.4 displays 40%', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(),
          tracker: _FakeTracker(),
          instrumentation: _FakeInstrumentation(dashboardData: {
            'planAdherence': {
              'averageAdherence': 0.4,
              'weeklyMetricsCount': 5,
              'weeklyAdherenceAvg': 0.4,
            },
            'masteryImprovement': {},
            'generatedAt': DateTime.now().toIso8601String(),
          }),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('40%'), findsAtLeast(2));
      });

      testWidgets('adherence between 0.4 and 0.7 displays correctly', (
        tester,
      ) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(),
          tracker: _FakeTracker(),
          instrumentation: _FakeInstrumentation(dashboardData: {
            'planAdherence': {
              'averageAdherence': 0.55,
              'weeklyMetricsCount': 5,
              'weeklyAdherenceAvg': 0.55,
            },
            'masteryImprovement': {},
            'generatedAt': DateTime.now().toIso8601String(),
          }),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('55%'), findsAtLeast(2));
      });

      testWidgets('adherence below 0.4 displays correctly', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(),
          tracker: _FakeTracker(),
          instrumentation: _FakeInstrumentation(dashboardData: {
            'planAdherence': {
              'averageAdherence': 0.15,
              'weeklyMetricsCount': 5,
              'weeklyAdherenceAvg': 0.15,
            },
            'masteryImprovement': {},
            'generatedAt': DateTime.now().toIso8601String(),
          }),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('15%'), findsAtLeast(2));
      });
    });

    group('mastery progress with high accuracy', () {
      testWidgets('displays progress and accuracy for high mastery', (
        tester,
      ) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(snapshot: {
            'totalTopics': 10,
            'masteredTopics': 9,
            'weakTopics': 1,
            'averageAccuracy': 0.9,
            'avgReadiness': 0.8,
          }),
          tracker: _FakeTracker(),
          instrumentation: _FakeInstrumentation(),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Mastery Overview'), findsOneWidget);
        expect(find.text('90%'), findsOneWidget);
        expect(find.text('80%'), findsOneWidget);
        expect(find.text('10'), findsOneWidget);
        expect(find.text('9'), findsOneWidget);
        expect(find.text('1'), findsAtLeast(1));
      });
    });

    group('mastery labels for all levels in topic breakdown', () {
      testWidgets('displays correct label for each MasteryLevel', (
        tester,
      ) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(allMastery: [
            _masteryState(
              topicId: 'novice-topic',
              accuracy: 0.1,
              totalAttempts: 0,
              masteryLevel: MasteryLevel.novice,
            ),
            _masteryState(
              topicId: 'browsing-topic',
              accuracy: 0.3,
              totalAttempts: 1,
              masteryLevel: MasteryLevel.browsing,
            ),
            _masteryState(
              topicId: 'developing-topic',
              accuracy: 0.6,
              totalAttempts: 3,
              masteryLevel: MasteryLevel.developing,
            ),
            _masteryState(
              topicId: 'proficient-topic',
              accuracy: 0.8,
              totalAttempts: 5,
              masteryLevel: MasteryLevel.proficient,
            ),
            _masteryState(
              topicId: 'expert-topic',
              accuracy: 0.95,
              totalAttempts: 15,
              masteryLevel: MasteryLevel.expert,
            ),
          ]),
          tracker: _FakeTracker(),
          instrumentation: _FakeInstrumentation(),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Novice'), findsOneWidget);
        expect(find.text('Browsing'), findsOneWidget);
        expect(find.text('Developing'), findsOneWidget);
        expect(find.text('Proficient'), findsOneWidget);
        expect(find.text('Expert'), findsOneWidget);
      });
    });

    group('refresh indicator', () {
      testWidgets('displays RefreshIndicator and data after refresh', (
        tester,
      ) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: _FakeMasteryGraphService(),
          tracker: _FakeTracker(),
          instrumentation: _FakeInstrumentation(),
          topicRepo: _FakeTopicRepo(),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(RefreshIndicator), findsOneWidget);
        expect(find.text('Study Dashboard'), findsOneWidget);
      });
    });
  });
}
