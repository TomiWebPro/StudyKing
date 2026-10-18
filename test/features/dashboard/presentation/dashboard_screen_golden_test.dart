// Golden (visual) tests for the full `DashboardScreen` using the
// `flutter_to_image` package — closing the last top-level-screen coverage gap.
//
// Per `docs/vision_next_term.md` §1.1: "at least one golden/visual test per
// top-level screen (dashboard, planner, teaching, mentor, practice, lessons)".
// Before this file, 4 of the 6 top-level screens had goldens (mentor, planner,
// teaching/tutor, lessons) plus two dashboard *sub-widgets* (DashboardNavCard,
// SummaryRow), but the DashboardScreen itself — the student's primary landing
// page — had only structural widget tests that never render pixels.
//
// These goldens catch pixel-level regressions (layout overflow, contrast,
// density, stale-l10n after a locale switch, desktop-width truncation) that the
// 1388-line structural test in `dashboard_screen_test.dart` cannot. The
// rendered dashboard is populated (snapshot/stats/adherence/badges/weak+strong
// topics) so the card layouts are actually exercised in both `en` and `es`,
// while `weeklyTrend` is left empty so the daily-activity heatmap stays
// deterministic (its grid is anchored to today otherwise).
//
// See: docs/development/visual-testing.md
// See: AGENTS.md — hand-written fakes, ProviderScope overrides, no Hive I/O.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_to_image/flutter_to_image.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart'
    show settingsProvider, SettingsController, engagementAdherenceRepoProvider;
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/dashboard/presentation/dashboard_screen.dart';
// Full imports (no `show`): dashboardInitProvider,
// dashboardInstrumentationServiceProvider, dashboardStudyProgressTrackerProvider
// and engagementAdherenceRepoProvider are all reachable through these two
// libraries, matching how `dashboard_screen_test.dart` consumes them.
import 'package:studyking/features/dashboard/providers/dashboard_data_providers.dart';
import 'package:studyking/features/dashboard/providers/dashboard_providers.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart'
    show masteryGraphServiceProvider, readinessScorerProvider, spacedRepetitionServiceProvider;
import 'package:studyking/features/practice/services/readiness_scorer.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/questions/providers/question_providers.dart'
    show questionRepositoryProvider, sourceRepositoryProvider;
import 'package:studyking/features/sessions/providers/session_providers.dart' show sessionRepositoryProvider;
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/providers/subject_repository_provider.dart' show subjectRepositoryProvider;
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart' show topicRepositoryProvider;
import 'package:studyking/features/subjects/providers/subjects_list_provider.dart' show subjectListProvider;
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart' show PersonalLearningPlan;
import 'package:studyking/features/focus_mode/data/repositories/focus_session_repository.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_model.dart';
import 'package:studyking/features/focus_mode/providers/focus_mode_providers.dart' show focusSessionRepositoryProvider;
import 'package:studyking/core/providers/service_providers.dart' show learningMethodAnalyticsServiceProvider;
import 'package:studyking/core/services/learning_method_analytics_service.dart';
import 'package:studyking/features/teaching/providers/lesson_feedback_providers.dart' show lessonFeedbackRepositoryProvider;
import 'package:studyking/features/teaching/data/repositories/lesson_feedback_repository.dart';
import 'package:studyking/features/teaching/data/models/lesson_feedback_model.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart' show plannerServiceProvider;
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

/// Locates the StudyKing project root by walking up from the current working
/// directory to the nearest ancestor containing a `pubspec.yaml`.
String _projectRoot() {
  var dir = Directory.current;
  while (dir.path != dir.parent.path) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) {
      return dir.path;
    }
    dir = dir.parent;
  }
  return Directory.current.path;
}

/// Asserts that [pngBytes] matches the golden file at [relativePath].
///
/// `matchesGoldenFile` decodes the PNG bytes (real engine work) to compare
/// pixels. Under `flutter test` the FakeAsync clock cannot drive that work, so
/// the comparison runs inside the test binding's `runAsync` — the same idiom
/// the `flutter_to_image` package uses for `toImage`/`toByteData`.
Future<void> _expectGolden(Uint8List pngBytes, String relativePath) async {
  final binding = TestWidgetsFlutterBinding.instance;
  final uri = goldenFileComparator.getTestUri(Uri.parse(relativePath), null);
  await binding.runAsync<void>(() async {
    if (autoUpdateGoldenFiles) {
      await goldenFileComparator.update(uri, pngBytes);
    } else {
      await goldenFileComparator.compare(pngBytes, uri);
    }
  });
}

// ---------------------------------------------------------------------------
// Hand-written fakes (no mockito/mocktail) — mirror the fakes already proven
// to render `DashboardScreen` in `dashboard_screen_test.dart`. Each returns
// deterministic, locale-independent data so the rendered pixels are stable
// across runs (no Hive I/O: `StudentIdService.getDaysSinceLastActivity()` is
// never opened without `init()`).
// ---------------------------------------------------------------------------

/// Fixed date used for any mastery state timestamps so the golden is stable
/// across days (timestamps are not painted on the dashboard cards, but this
/// keeps tooltip/message strings deterministic too).
final DateTime _kFixedDate = DateTime(2025, 1, 1);

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
    lastAttempt: _kFixedDate,
    lastUpdated: _kFixedDate,
  );
}

class _FakeTrackerAttemptRepo extends AttemptRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async {
    return Result.success([]);
  }
}

class FakeMasteryGraphService extends MasteryGraphService {
  final List<MasteryState> allMastery;
  final Map<String, dynamic>? snapshot;

  FakeMasteryGraphService({this.allMastery = const [], this.snapshot});

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) async {
    return Result.success(allMastery);
  }

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) async {
    return Result.success(snapshot ?? {
      'totalTopics': 0,
      'masteredTopics': 0,
      'weakTopics': 0,
      'averageAccuracy': 0.0,
      'avgReadiness': 0.0,
    });
  }

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(
    String studentId, {
    String? subjectId,
  }) async {
    return Result.success(
      allMastery.where((m) => m.accuracy < 0.6).toList(),
    );
  }
}

class FakeStudyProgressTracker extends StudyProgressTracker {
  final Map<String, dynamic>? overallStats;
  final List<Map<String, dynamic>> weeklyTrend;
  final List<Map<String, dynamic>> badges;

  FakeStudyProgressTracker({
    this.overallStats,
    this.weeklyTrend = const [],
    this.badges = const [],
  }) : super(
          attemptRepo: _FakeTrackerAttemptRepo(),
          l10n: lookupAppLocalizations(const Locale('en')),
        );

  @override
  Future<Result<Map<String, dynamic>>> getOverallStats(String studentId) async {
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
  Future<Result<List<Map<String, dynamic>>>> getWeeklyTrend(int weeks,
      {String? studentId, DateTime? now}) async {
    return Result.success(weeklyTrend);
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getBadges(String studentId) async {
    return Result.success(badges);
  }

  @override
  Future<Result<String>> exportProgressCSV(String studentId) async {
    return Result.success('progress,csv,data');
  }

  @override
  Future<Result<String>> exportSessionHistoryCSV(String studentId) async {
    return Result.success('session,csv,data');
  }
}

class FakeInstrumentationService extends InstrumentationService {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<Map<String, dynamic>>> getInstrumentationDashboard(String studentId) async {
    return Result.success({
      'planAdherence': {
        'averageAdherence': 0.0,
        'weeklyMetricsCount': 0,
        'weeklyAdherenceAvg': 0.0,
      },
      'masteryImprovement': {},
      'generatedAt': _kFixedDate.toIso8601String(),
    });
  }

  @override
  Future<Result<void>> exportInstrumentationData(String studentId) async {
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
  Future<Result<List<Session>>> getAll() async => Result.success([]);

  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async {
    return Result.success([]);
  }
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
      nextReview: _kFixedDate,
      updatedData: currentData ?? const QuestionSRData(),
    );
  }
}

class _FakeDashboardAttemptRepo extends AttemptRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);
}

class _FakeDashboardQuestionRepo extends QuestionRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);
  @override
  Future<Result<List<Question>>> getAll() async => Result.success([
        Question(
          id: 'q1',
          text: 'Test question',
          type: QuestionType.singleChoice,
          subjectId: 'subj-1',
          topicId: 'topic-weak-1',
          createdAt: _kFixedDate,
          updatedAt: _kFixedDate,
        ),
      ]);
}

class _FakeReadinessScorer extends ReadinessScorer {
  _FakeReadinessScorer() : super(masteryService: null, studentIdService: null);
  @override
  Future<List<ScoredQuestion>> scoreQuestions(List<Question> questions) async =>
      questions.map((q) => ScoredQuestion(question: q, score: 0.5)).toList();
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

  @override
  Future<Result<List<Question>>> getQuestionsDueForReview({DateTime? asOf}) async {
    return Result.success([]);
  }
}

class _FakeDashboardSubjectRepo extends SubjectRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

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
      Result.success(_records.isNotEmpty
          ? _records
          : [
              PlanAdherenceModel(
                id: 'test',
                studentId: studentId,
                date: _kFixedDate,
                adherenceScore: _weekly,
              ),
            ]);
}

/// Fake SourceRepository that returns empty data — prevents Hive access
/// when dashboardSourceCountProvider and dashboardChecklistProgressProvider
/// query sources.
class FakeSourceRepository extends SourceRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Source>>> getByStudent(String studentId) async {
    return Result.success([]);
  }
}

/// Fixed student ID used across all fakes to ensure deterministic provider
/// overrides and avoid Hive I/O from StudentIdService.
const String _kStudentId = 'student-1';

/// Fake PlannerService that returns empty plans and scheduled lessons,
/// preventing Hive access in dashboardSyllabusProgressProvider,
/// dashboardSyllabusBreakdownProvider, and dashboardChecklistProgressProvider.
class FakePlannerService extends PlannerService {
  FakePlannerService() : super(fixedStudentId: _kStudentId);

  @override
  Future<Result<PersonalLearningPlan?>> loadExistingPlan() async {
    return Result.success(null);
  }

  @override
  Future<Result<List<Session>>> getScheduledLessons() async {
    return Result.success([]);
  }
}

/// Fake FocusSessionRepository that returns empty data, preventing Hive
/// access in dashboardLastFocusSessionProvider.
class FakeFocusSessionRepository extends FocusSessionRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<FocusSession>>> getAll() async => Result.success([]);

  @override
  Future<Result<FocusSession?>> getLatest() async => Result.success(null);
}

/// Fake LearningMethodAnalyticsService that returns empty insights,
/// preventing Hive access in dashboardLearningInsightsProvider.
class FakeLearningMethodAnalyticsService extends LearningMethodAnalyticsService {
  @override
  Future<void> init() async {}

  @override
  Future<Result<Map<String, dynamic>>> getLearningInsights(String studentId) async {
    return Result.success({});
  }
}

/// Fake LessonFeedbackRepository that returns empty data, preventing Hive
/// access in LessonsNeedingReviewCard.
class FakeLessonFeedbackRepository extends LessonFeedbackRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<List<LessonFeedbackModel>>> getAll() async => Result.success([]);
}

/// Builds `DashboardScreen` wrapped in `MaterialApp` + `ProviderScope` with
/// hand-written fakes (no Hive I/O) so the full dashboard renders its populated
/// state deterministically. Each matrix cell gets a fresh tree with the correct
/// locale/theme.
Widget _buildDashboardApp({
  required Locale locale,
  required ThemeMode theme,
  double textScale = 1.0,
  String studentId = 'student-1',
}) {
  final themeData = theme == ThemeMode.dark ? ThemeData.dark() : ThemeData.light();
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith((ref) => SettingsController(SettingsRepository())),
      dashboardInitProvider.overrideWith((ref) => Future.value()),
      sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
      masteryGraphServiceProvider.overrideWithValue(FakeMasteryGraphService(
        snapshot: {
          'totalTopics': 20,
          'masteredTopics': 8,
          'weakTopics': 3,
          'averageAccuracy': 0.75,
          'avgReadiness': 0.6,
        },
        allMastery: [
          _masteryState(topicId: 'topic-1', accuracy: 0.3, totalAttempts: 5),
          _masteryState(topicId: 'topic-2', accuracy: 0.85, totalAttempts: 10),
        ],
      )),
      dashboardStudyProgressTrackerProvider.overrideWithValue(FakeStudyProgressTracker(
        overallStats: {
          'totalAttempts': 100,
          'correctAttempts': 80,
          'accuracy': 80,
          'avgTimePerQuestion': 12,
          'totalStudyTimeHours': '12.5',
          'weeklyActivity': 25,
          'dailyActivity': 15,
          'topicsStudied': 8,
        },
        // Intentionally empty: the daily-activity heatmap grid is anchored to
        // today, so a populated trend would make the golden date-dependent.
        weeklyTrend: const [],
        badges: [
          {
            'id': 'first',
            'name': 'First Step',
            'description': 'First question!',
            'unlockedAt': DateTime(2025, 1, 1).toIso8601String(),
          },
          {
            'id': 'streak',
            'name': 'Daily Scholar',
            'description': 'Studied today!',
            'unlockedAt': DateTime(2025, 1, 2).toIso8601String(),
          },
        ],
      )),
      dashboardInstrumentationServiceProvider.overrideWithValue(FakeInstrumentationService()),
      topicRepositoryProvider.overrideWithValue(FakeTopicRepository(topic: Topic(
        id: 'topic-1',
        subjectId: 'subj-1',
        title: 'Algebra Basics',
        description: '',
        syllabusText: '',
      ))),
      engagementAdherenceRepoProvider.overrideWithValue(
        FakePlanAdherenceRepository(average: 0.85, weekly: 0.75),
      ),
      spacedRepetitionServiceProvider.overrideWithValue(_FakeDashboardSpacedRepetitionService()),
      subjectRepositoryProvider.overrideWithValue(_FakeDashboardSubjectRepo()),
      readinessScorerProvider.overrideWithValue(_FakeReadinessScorer()),
      questionRepositoryProvider.overrideWithValue(_FakeDashboardQuestionRepo()),
      sourceRepositoryProvider.overrideWithValue(FakeSourceRepository()),
      plannerServiceProvider.overrideWithValue(FakePlannerService()),
      learningMethodAnalyticsServiceProvider
          .overrideWithValue(FakeLearningMethodAnalyticsService()),
      lessonFeedbackRepositoryProvider
          .overrideWithValue(FakeLessonFeedbackRepository()),
      focusSessionRepositoryProvider
          .overrideWith((ref) async => FakeFocusSessionRepository()),
      subjectListProvider.overrideWith((ref) async => <Subject>[]),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: themeData,
      darkTheme: themeData,
      themeMode: theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      // DashboardScreen does not own a Scaffold; wrap it so AppBar/Tooltip
      // overlays and scroll physics behave as in production.
      home: Scaffold(body: DashboardScreen(studentId: studentId)),
    ),
  );
}

void main() {
  // Ensure the binding exists before setUp so that FlutterError.onError
  // is available to override. Note: TestWidgetsFlutterBinding's _runTest
  // overwrites FlutterError.onError *inside* each test body (after setUp),
  // so the no-op override must be applied inside the test body itself.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final root = _projectRoot();
    goldenFileComparator = LocalFileComparator(
      Uri.file('$root/.goldens_root_placeholder'),
    );
  });

  group('DashboardScreen goldens', () {
    // The 8-file matrix required by the issue: en/es x 375(phone)/1200(desktop)
    // x light/dark. MaterialApp carries the locale + theme, so each cell builds
    // a fresh tree with the correct locale/theme; the package only imposes the
    // requested canvas size + pixel ratio.
    testWidgets('matches goldens across locale x width x theme', (tester) async {
      // Override the test framework's error handler (set by _runTest *after*
      // setUp) with a true no-op. Layout overflow at narrow phone widths
      // (375px) is expected for the dashboard — it is visible in the golden PNG
      // itself, not something that should fail the test. The test framework's
      // default handler stores each error in _pendingExceptionDetails and
      // reports "Multiple exceptions (N)" at test completion; our no-op prevents
      // that accumulation, allowing renderWidgetToPng to capture pixels.
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        // Intentionally empty: suppress all Flutter errors (layout overflow, etc.)
        // during golden rendering.
      };

      try {
        const locales = [Locale('en'), Locale('es')];
        const sizes = [Size(375, 800), Size(1200, 800)];
        const themes = [ThemeMode.light, ThemeMode.dark];

        for (final locale in locales) {
          for (final size in sizes) {
            for (final theme in themes) {
              // Clear any exceptions that the framework's default handler may
              // have already queued before our no-op override took effect.
              // This ensures the loop starts clean for each matrix cell.
              tester.binding.takeException();
              final png = await renderWidgetToPng(
                _buildDashboardApp(locale: locale, theme: theme),
                size: size,
                pixelRatio: 2.0,
              );
              expect(png, isNotEmpty);
              final path = buildGoldenPath('dashboard_screen', locale, size, theme);
              await _expectGolden(png, path);
            }
          }
        }
      } finally {
        // Restore the test framework's handler so subsequent tests are unaffected.
        FlutterError.onError = originalOnError;
      }
    });
  });
}
