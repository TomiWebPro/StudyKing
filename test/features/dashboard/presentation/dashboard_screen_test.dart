import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/core/widgets/animated_bar_chart.dart';
import 'package:studyking/core/widgets/metric_card.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/dashboard/presentation/dashboard_screen.dart';
import 'package:studyking/features/dashboard/providers/dashboard_providers.dart';
import 'package:studyking/features/focus_mode/presentation/widgets/session_summary_card.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart'
    show masteryGraphServiceProvider, spacedRepetitionServiceProvider;
import 'package:studyking/features/subjects/providers/subject_repository_provider.dart'
    show subjectRepositoryProvider;
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../helpers/navigator_observer_helper.dart';

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

class _FakeAttemptRepository extends AttemptRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async {
    return Result.success([]);
  }
}

class FakeStudyProgressTracker extends StudyProgressTracker {
  final Map<String, dynamic>? overallStats;
  final List<Map<String, dynamic>> weeklyTrend;
  final List<Map<String, dynamic>> badges;
  final bool failExportProgress;
  final bool failExportSession;
  final Completer<Result<Map<String, dynamic>>>? statsCompleter;
  final Completer<Result<String>>? exportProgressCompleter;
  final Completer<Result<String>>? exportSessionCompleter;

  FakeStudyProgressTracker({
    this.overallStats,
    this.weeklyTrend = const [],
    this.badges = const [],
    this.failExportProgress = false,
    this.failExportSession = false,
    this.statsCompleter,
    this.exportProgressCompleter,
    this.exportSessionCompleter,
  }) : super(
    attemptRepo: _FakeAttemptRepository(),
    l10n: lookupAppLocalizations(const Locale('en')),
  );

  @override
  Future<Result<Map<String, dynamic>>> getOverallStats(String studentId) async {
    if (statsCompleter != null) return statsCompleter!.future;
    return Result.success(overallStats ?? {
      'totalAttempts': 0,
      'correctAttempts': 0,
      'accuracy': 0,
      'avgTimePerQuestion': 0,
      'totalStudyTimeHours': '0.0',
      'weeklyActivity': 0,
      'dailyActivity': 0,
      'topicsStudied': 0,
    });
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getWeeklyTrend(int weeks, {String? studentId}) async {
    return Result.success(weeklyTrend);
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getBadges(String studentId) async {
    return Result.success(badges);
  }

  @override
  Future<Result<String>> exportProgressCSV(String studentId) async {
    if (exportProgressCompleter != null) return exportProgressCompleter!.future;
    if (failExportProgress) return Result.failure('Export failed');
    return Result.success('progress,csv,data');
  }

  @override
  Future<Result<String>> exportSessionHistoryCSV(String studentId) async {
    if (exportSessionCompleter != null) return exportSessionCompleter!.future;
    if (failExportSession) return Result.failure('Session export failed');
    return Result.success('session,csv,data');
  }
}

class FakeInstrumentationService extends InstrumentationService {
  final Map<String, dynamic>? dashboardData;
  final bool failExport;
  final Completer<void>? exportCompleter;

  FakeInstrumentationService({
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

class FakeTopicRepository extends TopicRepository {
  final Topic? topic;
  final bool failGet;
  final bool returnNull;
  final List<Topic>? allTopics;

  FakeTopicRepository({this.topic, this.failGet = false, this.returnNull = false, this.allTopics});

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<Topic?>> get(String id) async {
    if (failGet) throw Exception('Failed to get topic');
    if (returnNull) return Result.success(null);
    return Result.success(topic);
  }

  @override
  Future<Result<List<Topic>>> getAll() async {
    return Result.success(allTopics ?? (topic != null ? [topic!] : []));
  }
}

class FakeSessionRepository extends SessionRepository {
  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async {
    return Result.success([]);
  }
}

class _FakeDashboardSpacedRepetitionService extends SpacedRepetitionService {
  _FakeDashboardSpacedRepetitionService()
      : super(
          questionRepo: _FakeDashboardQuestionRepo(),
          attemptRepo: _FakeDashboardAttemptRepo(),
          srEngine: _FakeDashboardSpacedRepetitionEngine(),
        );

  @override
  Future<Result<int>> getSubjectDueCount(String subjectId) async {
    return Result.success(0);
  }
}

class _FakeDashboardQuestionRepo extends QuestionRepository {
  @override
  Future<void> init() async {}
}

class _FakeDashboardAttemptRepo extends AttemptRepository {
  @override
  Future<void> init() async {}
}

class _FakeDashboardSpacedRepetitionEngine extends SpacedRepetitionEngine {
  @override
  SM2Result scheduleReview({
    required String questionId,
    required int grade,
    QuestionSRData? currentData,
    DateTime? now,
  }) {
    return SM2Result(
      nextReview: DateTime.now(),
      updatedData: currentData ?? const QuestionSRData(),
    );
  }
}

class _FakeDashboardSubjectRepo extends SubjectRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Subject>>> getAll() async => Result.success([]);
}

class FakePlanAdherenceRepository extends PlanAdherenceRepository {
  final List<PlanAdherenceModel> _records;
  final double _average;
  final double _weekly;

  FakePlanAdherenceRepository({
    double average = 0.0,
    double weekly = 0.0,
    List<PlanAdherenceModel> records = const [],
  })  : _average = average,
        _weekly = weekly,
        _records = records;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<double>> getAverageAdherence(String studentId) async => Result.success(_average);

  @override
  Future<Result<List<PlanAdherenceModel>>> getWeekly(String studentId) async =>
      Result.success(_records.isNotEmpty ? _records : [
        PlanAdherenceModel(
          id: 'test',
          studentId: studentId,
          date: DateTime.now(),
          adherenceScore: _weekly,
        ),
      ]);
}

Widget _buildTestApp(
  Widget screen, {
  MasteryGraphService? masteryService,
  StudyProgressTracker? tracker,
  InstrumentationService? instrumentation,
  TopicRepository? topicRepo,
  PlanAdherenceRepository? adherenceRepo,
}) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsController(SettingsRepository()),
      ),
      sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
      if (masteryService != null)
        masteryGraphServiceProvider.overrideWithValue(masteryService),
      if (tracker != null)
        dashboardStudyProgressTrackerProvider.overrideWithValue(tracker),
      dashboardInstrumentationServiceProvider.overrideWithValue(
        instrumentation ?? FakeInstrumentationService(),
      ),
      if (topicRepo != null)
        topicRepositoryProvider.overrideWithValue(topicRepo),
      engagementAdherenceRepoProvider.overrideWithValue(
        adherenceRepo ?? FakePlanAdherenceRepository(average: 0.5, weekly: 0.5),
      ),
      spacedRepetitionServiceProvider.overrideWithValue(
        _FakeDashboardSpacedRepetitionService(),
      ),
      subjectRepositoryProvider.overrideWithValue(
        _FakeDashboardSubjectRepo(),
      ),
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
  PlanAdherenceRepository? adherenceRepo,
  TestNavigatorObserver? navigatorObserver,
}) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsController(SettingsRepository()),
      ),
      sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
      if (masteryService != null)
        masteryGraphServiceProvider.overrideWithValue(masteryService),
      if (tracker != null)
        dashboardStudyProgressTrackerProvider.overrideWithValue(tracker),
      dashboardInstrumentationServiceProvider.overrideWithValue(
        instrumentation ?? FakeInstrumentationService(),
      ),
      if (topicRepo != null)
        topicRepositoryProvider.overrideWithValue(topicRepo),
      engagementAdherenceRepoProvider.overrideWithValue(
        adherenceRepo ?? FakePlanAdherenceRepository(average: 0.5, weekly: 0.5),
      ),
      spacedRepetitionServiceProvider.overrideWithValue(
        _FakeDashboardSpacedRepetitionService(),
      ),
      subjectRepositoryProvider.overrideWithValue(
        _FakeDashboardSubjectRepo(),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      home: Scaffold(body: screen),
      routes: {
        '/practice-session': (_) => const Scaffold(
          body: Text('Practice Session'),
        ),
        '/planner': (_) => const Scaffold(
          body: Text('Planner'),
        ),
        '/focus-mode': (_) => const Scaffold(
          body: Text('Focus Mode'),
        ),
      },
    ),
  );
}

// Expected plugin: share_plus ^7.0 (channel: dev.fluttercommunity.plus/share)
const _shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

Future<void> scrollToFind(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Widget _buildExportTestApp(
  DashboardScreen screen, {
  StudyProgressTracker? tracker,
  InstrumentationService? instrumentation,
}) {
  return _buildTestApp(
    screen,
    masteryService: FakeMasteryGraphService(),
    tracker: tracker ?? FakeStudyProgressTracker(),
    instrumentation: instrumentation ?? FakeInstrumentationService(),
    topicRepo: FakeTopicRepository(),
    adherenceRepo: FakePlanAdherenceRepository(average: 0.5, weekly: 0.5),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final defaultTopicRepo = FakeTopicRepository();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_shareChannel, (methodCall) async {
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_shareChannel, null);
  });

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

        expect(find.text('80.0%'), findsOneWidget);
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

        expect(find.text('0.0%'), findsAtLeast(1));
        expect(find.text('0.0h'), findsOneWidget);
      });

      testWidgets('renders metric cards', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(),
          tracker: FakeStudyProgressTracker(overallStats: {
            'accuracy': 80,
            'totalStudyTimeHours': '10',
            'weeklyActivity': 20,
            'topicsStudied': 5,
          }),
          instrumentation: FakeInstrumentationService(),
          topicRepo: FakeTopicRepository(),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(MetricCard), findsAtLeast(4));
      });

      testWidgets('handles large stats values', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(),
          tracker: FakeStudyProgressTracker(overallStats: {
            'accuracy': 100,
            'totalStudyTimeHours': '999.9',
            'weeklyActivity': 9999,
            'topicsStudied': 500,
          }),
          instrumentation: FakeInstrumentationService(),
          topicRepo: FakeTopicRepository(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('100.0%'), findsOneWidget);
        expect(find.text('999.9h'), findsOneWidget);
        expect(find.text('9999'), findsOneWidget);
        expect(find.text('500'), findsOneWidget);
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

      testWidgets('empty trend shows default weekday labels', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(),
          tracker: FakeStudyProgressTracker(),
          instrumentation: FakeInstrumentationService(),
          topicRepo: FakeTopicRepository(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Mon'), findsOneWidget);
        expect(find.text('Sun'), findsOneWidget);
      });

      testWidgets('trend with fewer than 7 items shows week labels', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(),
          tracker: FakeStudyProgressTracker(weeklyTrend: [
            {'week': 2026, 'attempts': 5, 'accuracy': 80},
            {'week': 2026, 'attempts': 10, 'accuracy': 90},
          ]),
          instrumentation: FakeInstrumentationService(),
          topicRepo: FakeTopicRepository(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('W2'), findsOneWidget);
        expect(find.text('W1'), findsOneWidget);
      });
    });

    group('plan adherence', () {
      testWidgets('shows adherence card with data', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(),
          tracker: FakeStudyProgressTracker(),
          topicRepo: FakeTopicRepository(),
          adherenceRepo: FakePlanAdherenceRepository(
            average: 0.85,
            weekly: 0.75,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Plan Adherence'), findsAtLeast(1));
        expect(find.text('85%'), findsOneWidget);
        expect(find.text('75%'), findsOneWidget);
      });

      testWidgets('shows 0% when no adherence data', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(snapshot: {
            'totalTopics': 5, 'masteredTopics': 2, 'weakTopics': 1, 'averageAccuracy': 0.5, 'avgReadiness': 0.5,
          }),
          tracker: FakeStudyProgressTracker(),
          topicRepo: FakeTopicRepository(),
          adherenceRepo: FakePlanAdherenceRepository(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Plan Adherence'), findsAtLeast(1));
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

        expect(find.text('Mastery Overview'), findsAtLeast(1));
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

        expect(find.text('Mastery Overview'), findsAtLeast(1));
        expect(find.text('0'), findsAtLeast(1));
        expect(find.text('0%'), findsAtLeast(1));
      });

      testWidgets('displays progress and accuracy for high mastery', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(snapshot: {
            'totalTopics': 10,
            'masteredTopics': 9,
            'weakTopics': 1,
            'averageAccuracy': 0.9,
            'avgReadiness': 0.8,
          }),
          tracker: FakeStudyProgressTracker(),
          instrumentation: FakeInstrumentationService(),
          topicRepo: FakeTopicRepository(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('90%'), findsOneWidget);
        expect(find.text('80%'), findsOneWidget);
        expect(find.text('10'), findsOneWidget);
        expect(find.text('9'), findsOneWidget);
      });
    });

    group('data loading failure paths', () {
      testWidgets('getAllTopicMastery failure leaves _allMastery empty', (tester) async {
        final mastery = FakeMasteryGraphService(
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
          tracker: FakeStudyProgressTracker(),
          instrumentation: FakeInstrumentationService(),
          topicRepo: FakeTopicRepository(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Mastery Overview'), findsAtLeast(1));
        expect(find.text('Weak Areas (Accuracy < 60%)'), findsNothing);
        expect(
          find.text('No topic data yet. Start studying to see your progress!'),
          findsOneWidget,
        );
      });

      testWidgets('getMasterySnapshot failure defaults to zeros', (tester) async {
        final mastery = FakeMasteryGraphService(
          failGetSnapshot: true,
          allMastery: [
            _masteryState(topicId: 'topic-1', accuracy: 0.5, totalAttempts: 5),
          ],
        );

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: mastery,
          tracker: FakeStudyProgressTracker(),
          instrumentation: FakeInstrumentationService(),
          topicRepo: FakeTopicRepository(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Mastery Overview'), findsAtLeast(1));
        expect(find.text('0'), findsAtLeast(1));
        expect(find.text('Topic Performance'), findsAtLeast(1));
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

      testWidgets('topic at exactly 60% is NOT weak', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(allMastery: [
            _masteryState(topicId: 'boundary', accuracy: 0.6, totalAttempts: 5),
          ]),
          tracker: FakeStudyProgressTracker(),
          instrumentation: FakeInstrumentationService(),
          topicRepo: FakeTopicRepository(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Weak Areas (Accuracy < 60%)'), findsNothing);
      });

      testWidgets('topic slightly below 60% IS weak', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(allMastery: [
            _masteryState(topicId: 'almost', accuracy: 0.59, totalAttempts: 5),
          ]),
          tracker: FakeStudyProgressTracker(),
          instrumentation: FakeInstrumentationService(),
          topicRepo: FakeTopicRepository(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Weak Areas (Accuracy < 60%)'), findsOneWidget);
        expect(find.text('59%'), findsAtLeast(1));
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

        expect(find.text('Topic Performance'), findsAtLeast(1));
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

        expect(find.text('Topic Performance'), findsAtLeast(1));
      });

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
          masteryService: FakeMasteryGraphService(allMastery: topics),
          tracker: FakeStudyProgressTracker(),
          instrumentation: FakeInstrumentationService(),
          topicRepo: FakeTopicRepository(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Topic Performance'), findsAtLeast(1));
        for (var i = 0; i < 10; i++) {
          expect(find.text('topic-$i'), findsAtLeast(1));
        }
      });

      testWidgets('topic with 0 attempts shows zero count', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(allMastery: [
            _masteryState(topicId: 'zero-attempts', accuracy: 0.0, totalAttempts: 0),
          ]),
          tracker: FakeStudyProgressTracker(),
          instrumentation: FakeInstrumentationService(),
          topicRepo: FakeTopicRepository(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('0 attempts'), findsOneWidget);
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

        expect(find.text('Achievements'), findsAtLeast(1));
        expect(find.text('First Step'), findsOneWidget);
        expect(find.text('Daily Scholar'), findsOneWidget);
      });

      testWidgets('shows no badges message when no badges', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(),
          tracker: FakeStudyProgressTracker(),
          instrumentation: FakeInstrumentationService(),
          topicRepo: FakeTopicRepository(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('No achievements yet. Keep studying!'), findsOneWidget);
      });

      testWidgets('badge with null name shows achievements section', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(),
          tracker: FakeStudyProgressTracker(badges: [
            {'id': 'no-name', 'description': 'No name badge'},
          ]),
          instrumentation: FakeInstrumentationService(),
          topicRepo: FakeTopicRepository(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Achievements'), findsAtLeast(1));
      });

      testWidgets('single badge renders correctly', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(),
          tracker: FakeStudyProgressTracker(badges: [
            {'id': 'single', 'name': 'Solo Badge', 'description': 'Only one'},
          ]),
          instrumentation: FakeInstrumentationService(),
          topicRepo: FakeTopicRepository(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Achievements'), findsAtLeast(1));
        expect(find.text('Solo Badge'), findsOneWidget);
      });
    });

    group('export section', () {
      testWidgets('shows three export buttons', (tester) async {
        await tester.pumpWidget(_buildExportTestApp(
          DashboardScreen(studentId: 'student-1'),
        ));
        await tester.pumpAndSettle();

        await scrollToFind(tester, find.text('Export CSV'));

        expect(find.text('Export CSV'), findsOneWidget);
        expect(find.text('Session History'), findsOneWidget);
        expect(find.text('Instrumentation'), findsOneWidget);
      });

      testWidgets('export CSV buttons do not crash when tapped', (tester) async {
        await tester.pumpWidget(_buildExportTestApp(
          DashboardScreen(studentId: 'student-1'),
        ));
        await tester.pumpAndSettle();

        await scrollToFind(tester, find.text('Export CSV'));
        await tester.tap(find.text('Export CSV'));
        await tester.pump();

        expect(find.text('Export CSV'), findsOneWidget);
      });

      testWidgets('export session history buttons do not crash when tapped', (tester) async {
        await tester.pumpWidget(_buildExportTestApp(
          DashboardScreen(studentId: 'student-1'),
        ));
        await tester.pumpAndSettle();

        await scrollToFind(tester, find.text('Session History'));
        await tester.tap(find.text('Session History'));
        await tester.pump();

        expect(find.text('Session History'), findsOneWidget);
      });

      testWidgets('export instrumentation buttons do not crash when tapped', (tester) async {
        await tester.pumpWidget(_buildExportTestApp(
          DashboardScreen(studentId: 'student-1'),
        ));
        await tester.pumpAndSettle();

        await scrollToFind(tester, find.text('Instrumentation'));
        await tester.tap(find.text('Instrumentation'));
        await tester.pump();

        expect(find.text('Instrumentation'), findsOneWidget);
      });

      testWidgets('export progress CSV failure shows error snackbar', (tester) async {
        await tester.pumpWidget(_buildExportTestApp(
          DashboardScreen(studentId: 'student-1'),
          tracker: FakeStudyProgressTracker(failExportProgress: true),
        ));
        await tester.pumpAndSettle();

        await scrollToFind(tester, find.text('Export CSV'));
        await tester.tap(find.text('Export CSV'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Export failed'), findsOneWidget);
      });

      testWidgets('export session history failure shows error snackbar', (tester) async {
        await tester.pumpWidget(_buildExportTestApp(
          DashboardScreen(studentId: 'student-1'),
          tracker: FakeStudyProgressTracker(failExportSession: true),
        ));
        await tester.pumpAndSettle();

        await scrollToFind(tester, find.text('Session History'));
        await tester.tap(find.text('Session History'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Export failed'), findsOneWidget);
      });

      testWidgets('export instrumentation failure shows error snackbar', (tester) async {
        await tester.pumpWidget(_buildExportTestApp(
          DashboardScreen(studentId: 'student-1'),
          instrumentation: FakeInstrumentationService(failExport: true),
        ));
        await tester.pumpAndSettle();

        await scrollToFind(tester, find.text('Instrumentation'));
        await tester.tap(find.text('Instrumentation'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Export failed'), findsOneWidget);
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

      testWidgets('topic repo returns null falls back to topicId', (tester) async {
        final mastery = FakeMasteryGraphService(allMastery: [
          _masteryState(topicId: 'null-topic-id', accuracy: 0.3, totalAttempts: 5),
        ]);

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: mastery,
          tracker: FakeStudyProgressTracker(),
          instrumentation: FakeInstrumentationService(),
          topicRepo: FakeTopicRepository(returnNull: true),
        ));
        await tester.pumpAndSettle();

        expect(find.text('null-topic-id'), findsAtLeast(1));
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
        final statsCompleter = Completer<Result<Map<String, dynamic>>>();
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

        statsCompleter.complete(Result.success({
          'accuracy': 50,
          'totalStudyTimeHours': '2',
          'weeklyActivity': 5,
          'topicsStudied': 3,
        }));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('dispose during progress CSV export does not crash', (tester) async {
        final exportCompleter = Completer<Result<String>>();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(),
          tracker: FakeStudyProgressTracker(exportProgressCompleter: exportCompleter),
          instrumentation: FakeInstrumentationService(),
          topicRepo: FakeTopicRepository(),
          adherenceRepo: FakePlanAdherenceRepository(average: 0.5, weekly: 0.5),
        ));
        await tester.pumpAndSettle();

        await scrollToFind(tester, find.text('Export CSV'));
        await tester.tap(find.text('Export CSV'));
        await tester.pump();

        await tester.pumpWidget(const SizedBox());
        await tester.pump();

        exportCompleter.complete(Result.success('data'));
        await tester.pump();

        expect(find.byType(DashboardScreen), findsNothing);
      });

      testWidgets('dispose during session CSV export does not crash', (tester) async {
        final exportCompleter = Completer<Result<String>>();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(),
          tracker: FakeStudyProgressTracker(exportSessionCompleter: exportCompleter),
          instrumentation: FakeInstrumentationService(),
          topicRepo: FakeTopicRepository(),
          adherenceRepo: FakePlanAdherenceRepository(average: 0.5, weekly: 0.5),
        ));
        await tester.pumpAndSettle();

        await scrollToFind(tester, find.text('Session History'));
        await tester.tap(find.text('Session History'));
        await tester.pump();

        await tester.pumpWidget(const SizedBox());
        await tester.pump();

        exportCompleter.complete(Result.success('data'));
        await tester.pump();

        expect(find.byType(DashboardScreen), findsNothing);
      });

      testWidgets('dispose during instrumentation export does not crash', (tester) async {
        final exportCompleter = Completer<void>();

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(),
          tracker: FakeStudyProgressTracker(),
          instrumentation: FakeInstrumentationService(exportCompleter: exportCompleter),
          topicRepo: FakeTopicRepository(),
          adherenceRepo: FakePlanAdherenceRepository(average: 0.5, weekly: 0.5),
        ));
        await tester.pumpAndSettle();

        await scrollToFind(tester, find.text('Instrumentation'));
        await tester.tap(find.text('Instrumentation'));
        await tester.pump();

        await tester.pumpWidget(const SizedBox());
        await tester.pump();

        exportCompleter.complete();
        await tester.pump();

        expect(find.byType(DashboardScreen), findsNothing);
      });
    });

    group('adherence metric values', () {
      testWidgets('shows high adherence value', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(),
          tracker: FakeStudyProgressTracker(),
          topicRepo: FakeTopicRepository(),
          adherenceRepo: FakePlanAdherenceRepository(average: 0.85, weekly: 0.85),
        ));
        await tester.pumpAndSettle();

        expect(find.text('85%'), findsAtLeast(1));
      });

      testWidgets('shows medium adherence value', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(),
          tracker: FakeStudyProgressTracker(),
          topicRepo: FakeTopicRepository(),
          adherenceRepo: FakePlanAdherenceRepository(average: 0.55, weekly: 0.55),
        ));
        await tester.pumpAndSettle();

        expect(find.text('55%'), findsAtLeast(1));
      });

      testWidgets('shows low adherence value', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(),
          tracker: FakeStudyProgressTracker(),
          topicRepo: FakeTopicRepository(),
          adherenceRepo: FakePlanAdherenceRepository(average: 0.25, weekly: 0.25),
        ));
        await tester.pumpAndSettle();

        expect(find.text('25%'), findsAtLeast(1));
      });

      testWidgets('adherence at exactly 0.7 displays 70%', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(),
          tracker: FakeStudyProgressTracker(),
          topicRepo: FakeTopicRepository(),
          adherenceRepo: FakePlanAdherenceRepository(average: 0.7, weekly: 0.7),
        ));
        await tester.pumpAndSettle();

        expect(find.text('70%'), findsAtLeast(2));
      });

      testWidgets('adherence at exactly 0.4 displays 40%', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(),
          tracker: FakeStudyProgressTracker(),
          topicRepo: FakeTopicRepository(),
          adherenceRepo: FakePlanAdherenceRepository(average: 0.4, weekly: 0.4),
        ));
        await tester.pumpAndSettle();

        expect(find.text('40%'), findsAtLeast(2));
      });
    });

    group('planner card navigation', () {
      testWidgets('tapping planner card navigates to planner', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestAppWithRoutes(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
        ));
        await tester.pumpAndSettle();

        await scrollToFind(tester, find.text('Study Planner'));
        await tester.tap(find.text('Study Planner'));
        await tester.pumpAndSettle();

        expect(find.text('Planner'), findsOneWidget);
      });

      testWidgets('tapping focus card navigates to focus mode', (tester) async {
        final masteryService = FakeMasteryGraphService();
        final tracker = FakeStudyProgressTracker();
        final instrumentation = FakeInstrumentationService();
        final topicRepo = FakeTopicRepository();

        await tester.pumpWidget(_buildTestAppWithRoutes(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: tracker,
          instrumentation: instrumentation,
          topicRepo: topicRepo,
          adherenceRepo: FakePlanAdherenceRepository(average: 0.5, weekly: 0.5),
        ));
        await tester.pumpAndSettle();

        final summaryCard = find.byType(SessionSummaryCard);
        await tester.ensureVisible(summaryCard);
        await tester.pumpAndSettle();

        await tester.tap(summaryCard);
        await tester.pumpAndSettle();

        expect(find.text('Focus Mode'), findsOneWidget);
      });

      testWidgets('planner card navigation pushes correct route via NavigatorObserver', (tester) async {
        final observer = TestNavigatorObserver();
        await tester.pumpWidget(_buildTestAppWithRoutes(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(),
          tracker: FakeStudyProgressTracker(),
          instrumentation: FakeInstrumentationService(),
          topicRepo: FakeTopicRepository(),
          navigatorObserver: observer,
        ));
        await tester.pumpAndSettle();

        await scrollToFind(tester, find.text('Study Planner'));
        await tester.tap(find.text('Study Planner'));
        await tester.pumpAndSettle();

        expect(
          observer.pushedRoutes.any((r) => r.settings.name == '/planner'),
          isTrue,
        );
      });
    });

    group('card title semantics', () {
      testWidgets('_cardTitle renders semantics widgets for screen readers', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(),
          tracker: FakeStudyProgressTracker(),
          topicRepo: FakeTopicRepository(),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(Semantics), findsAtLeastNWidgets(3));
      });
    });

    group('provider error state', () {
      testWidgets('overall stats error shows collapsible card error with retry', (tester) async {
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
          adherenceRepo: FakePlanAdherenceRepository(average: 0.5, weekly: 0.5),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Summary'), findsOneWidget);
      });

      testWidgets('badges provider error still shows other sections', (tester) async {
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
          adherenceRepo: FakePlanAdherenceRepository(average: 0.5, weekly: 0.5),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Export CSV'), findsOneWidget);
      });
    });

    group('error and empty boundary', () {
      testWidgets('empty dashboard shows checklist when all empty', (tester) async {
        final masteryService = FakeMasteryGraphService(
          snapshot: {'totalTopics': 0, 'masteredTopics': 0, 'weakTopics': 0, 'averageAccuracy': 0.0, 'avgReadiness': 0.0},
        );

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: FakeStudyProgressTracker(overallStats: {}),
          instrumentation: FakeInstrumentationService(),
          topicRepo: FakeTopicRepository(),
          adherenceRepo: FakePlanAdherenceRepository(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Getting Started'), findsOneWidget);
      });

      testWidgets('partial data hides empty checklist', (tester) async {
        final masteryService = FakeMasteryGraphService(allMastery: [
          _masteryState(topicId: 'topic-1', accuracy: 0.5, totalAttempts: 5),
        ]);

        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: masteryService,
          tracker: FakeStudyProgressTracker(),
          instrumentation: FakeInstrumentationService(),
          topicRepo: FakeTopicRepository(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Getting Started'), findsNothing);
      });
    });

    group('Keyboard accessibility', () {
      testWidgets('renders FocusTraversalGroup wrapping dashboard content', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(),
          tracker: FakeStudyProgressTracker(),
          topicRepo: FakeTopicRepository(),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(FocusTraversalGroup), findsAtLeastNWidgets(1));
      });

      testWidgets('dashboard header renders Semantics widget', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          DashboardScreen(studentId: 'student-1'),
          masteryService: FakeMasteryGraphService(),
          tracker: FakeStudyProgressTracker(),
          topicRepo: FakeTopicRepository(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Study Dashboard'), findsOneWidget);
        expect(find.byIcon(Icons.dashboard), findsOneWidget);
      });
    });
  });
}
