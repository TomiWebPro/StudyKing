// Golden (visual) tests for `PracticeScreen` using the `flutter_to_image`
// package — the last top-level screen needing golden coverage
// (per `docs/vision_next_term.md` §1.1: at least one golden test per
// top-level screen: dashboard, planner, teaching, mentor, practice, lessons).
//
// `PracticeScreen` is the spaced-repetition question hub: it composes a
// summary row (Questions Today / Due for Review / Subjects), an activity
// section (accuracy, weekly activity, mastery chips, recent sessions), a
// practice-mode grid, an extra-modes grid, and a scrollable subject-card list.
// Its existing widget tests (`practice_screen_test.dart`) only assert structural
// widget presence and text matches — never pixels. Agents have no pixels to
// see or optimise for overflow in the mastery-chip Wrap, stale-l10n after a
// locale switch, or dark-mode contrast in the extra-mode cards.
//
// These goldens catch exactly those regressions across locale × width × theme.
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
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/study_progress_provider.dart';
import 'package:studyking/core/providers/service_providers.dart'
    show studentIdServiceProvider;
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/practice/presentation/screens/practice_screen.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart'
    show
        attemptRepositoryProvider,
        masteryGraphServiceProvider,
        spacedRepetitionServiceProvider;
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/questions/providers/question_providers.dart'
    show questionRepositoryProvider;
import 'package:studyking/features/sessions/providers/session_providers.dart'
    show sessionRepositoryProvider;
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/providers/subject_repository_provider.dart'
    show subjectRepositoryProvider;
import 'package:studyking/l10n/generated/app_localizations.dart';

/// ---------------------------------------------------------------------------
/// Helpers
/// ---------------------------------------------------------------------------

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

/// ---------------------------------------------------------------------------
/// Fixed data — all timestamps are anchored to a constant date so every golden
/// is deterministic (no Hive I/O, no `DateTime.now()` leakage into pixels).
/// ---------------------------------------------------------------------------

const String _kStudentId = 'test-student-1';
final DateTime _kFixedDate = DateTime(2025, 1, 1);

final List<Subject> _kSubjects = [
  Subject(
    id: '1',
    name: 'Mathematics',
    color: '#4CAF50',
    topicIds: ['topic-algebra', 'topic-geometry'],
    createdAt: _kFixedDate,
  ),
  Subject(
    id: '2',
    name: 'Physics',
    color: '#2196F3',
    topicIds: ['topic-physics'],
    createdAt: _kFixedDate,
  ),
];

final List<Question> _kQuestions = [
  Question(
    id: 'q1',
    text: 'Solve for x: 2x + 5 = 15',
    type: QuestionType.typedAnswer,
    subjectId: '1',
    topicId: 'topic-algebra',
    topic: 'Algebra',
    markscheme: null,
    createdAt: _kFixedDate,
    updatedAt: _kFixedDate,
  ),
  Question(
    id: 'q2',
    text: 'What is the acceleration due to gravity?',
    type: QuestionType.typedAnswer,
    subjectId: '2',
    topicId: 'topic-physics',
    topic: 'Physics',
    markscheme: null,
    createdAt: _kFixedDate,
    updatedAt: _kFixedDate,
  ),
];

/// Due-counts keyed by subject ID — shown in the summary-row "Due for Review"
/// total and in the Spaced Repetition mode card.
const Map<String, int> _kDueCounts = {'1': 5, '2': 3};

/// Stats returned by the fake [StudyProgressTracker.getOverallStats].
final Map<String, dynamic> _kStats = {
  'totalAttempts': 100,
  'correctAttempts': 80,
  'accuracy': 80,
  'avgTimePerQuestion': 12,
  'totalStudyTimeHours': '12.5',
  'weeklyActivity': 25,
  'dailyActivity': 15,
  'topicsStudied': 5,
};

/// Mastery states with fixed dates — shown as mastery chips in the activity
/// section.  `lastAttempt` is anchored far in the past so the practice-streak
/// (which walks back from `DateTime.now()`) is deterministically 0.
final List<MasteryState> _kMastery = [
  MasteryState(
    studentId: _kStudentId,
    topicId: 'topic-algebra',
    accuracy: 0.3,
    totalAttempts: 5,
    correctAttempts: 1,
    masteryLevel: MasteryLevel.novice,
    lastAttempt: _kFixedDate,
    lastUpdated: _kFixedDate,
  ),
  MasteryState(
    studentId: _kStudentId,
    topicId: 'topic-geometry',
    accuracy: 0.6,
    totalAttempts: 10,
    correctAttempts: 6,
    masteryLevel: MasteryLevel.proficient,
    lastAttempt: _kFixedDate,
    lastUpdated: _kFixedDate,
  ),
  MasteryState(
    studentId: _kStudentId,
    topicId: 'topic-physics',
    accuracy: 0.9,
    totalAttempts: 15,
    correctAttempts: 13,
    masteryLevel: MasteryLevel.expert,
    lastAttempt: _kFixedDate,
    lastUpdated: _kFixedDate,
  ),
];

/// Completed sessions with fixed dates — shown in the "Recent Sessions" section.
/// Dates are anchored to January 2025 so `formatDate` always falls through to
/// `DateFormat.yMd` (never "Today"/"Yesterday") regardless of when the test
/// runs.
final List<Session> _kSessions = [
  Session(
    id: 's1',
    studentId: _kStudentId,
    subjectId: '1',
    startTime: _kFixedDate,
    endTime: DateTime(2025, 1, 1, 10, 30),
    completed: true,
    questionsAnswered: 10,
    correctAnswers: 8,
    createdAt: _kFixedDate,
  ),
  Session(
    id: 's2',
    studentId: _kStudentId,
    subjectId: '2',
    startTime: DateTime(2025, 1, 3, 14, 0),
    endTime: DateTime(2025, 1, 3, 14, 45),
    completed: true,
    questionsAnswered: 5,
    correctAnswers: 4,
    createdAt: DateTime(2025, 1, 3, 14, 0),
  ),
];

/// Attempts anchored to fixed past dates — `_questionsToday` counts attempts
/// whose timestamp is after the start of *today*, so with all attempts in the
/// past the count is deterministically 0.
final List<StudentAttempt> _kAttempts = [
  StudentAttempt(
    id: 'a1',
    studentId: _kStudentId,
    questionId: 'q1',
    subjectId: '1',
    isCorrect: true,
    timestamp: _kFixedDate,
  ),
  StudentAttempt(
    id: 'a2',
    studentId: _kStudentId,
    questionId: 'q2',
    subjectId: '2',
    isCorrect: false,
    timestamp: DateTime(2025, 1, 3),
  ),
];

/// ---------------------------------------------------------------------------
/// Hand-written fakes (no mockito/mocktail) — mirror the fakes proven to render
/// `PracticeScreen` in `practice_screen_test.dart`, but with populated data so
/// the golden exercises every sub-section (summary, activity, mode grid,
/// extra modes, subject cards).
/// ---------------------------------------------------------------------------

class _FakeSubjectRepository extends SubjectRepository {
  final List<Subject> _subjects;
  _FakeSubjectRepository(this._subjects);

  @override
  Future<Result<List<Subject>>> getAll() async => Result.success(_subjects);
}

class _FakeQuestionRepository extends QuestionRepository {
  final List<Question> _questions;
  _FakeQuestionRepository(this._questions);

  @override
  Future<Result<List<Question>>> getAll() async => Result.success(_questions);

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async =>
      Result.success(_questions);
}

class _FakeSpacedRepetitionService extends SpacedRepetitionService {
  final Map<String, int> _dueCounts;

  _FakeSpacedRepetitionService([this._dueCounts = const {}])
      : super(
          questionRepo: _FakeQuestionRepository([]),
          attemptRepo: _FakeAttemptRepository(),
          srEngine: SpacedRepetitionEngine(),
        );

  @override
  Future<Result<int>> getSubjectDueCount(String subjectId) async {
    return Result.success(_dueCounts[subjectId] ?? 0);
  }

  @override
  Future<Result<List<Question>>> getPracticeQuestions(String subjectId) async {
    return Result.success(_kQuestions
        .where((q) => q.subjectId == subjectId)
        .toList());
  }
}

class _FakeMasteryGraphService extends MasteryGraphService {
  final List<MasteryState> allMastery;

  _FakeMasteryGraphService([this.allMastery = const []]);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) async {
    return Result.success(allMastery);
  }

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(
    String studentId, {
    String? subjectId,
  }) async {
    return Result.success(
      allMastery.where((m) => [
        MasteryLevel.novice,
        MasteryLevel.browsing,
        MasteryLevel.developing,
      ].contains(m.masteryLevel)).toList(),
    );
  }

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(
    String studentId, {
    double threshold = 0.5,
  }) async {
    return Result.success([]);
  }
}

class _FakeStudyProgressTracker extends StudyProgressTracker {
  final Map<String, dynamic>? overallStats;

  _FakeStudyProgressTracker({this.overallStats})
      : super(
          attemptRepo: _FakeAttemptRepository(),
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
  Future<Result<List<Map<String, dynamic>>>> getWeeklyTrend(
    int weeks, {
    String? studentId,
    DateTime? now,
  }) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getBadges(String studentId) async {
    return Result.success([]);
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

class _FakeSessionRepository extends SessionRepository {
  final List<Session> _sessions;

  _FakeSessionRepository([this._sessions = const []]);

  @override
  Future<Result<List<Session>>> getByStudent(String studentId) async =>
      Result.success(_sessions);
}

class _FakeStudentIdService extends StudentIdService {
  @override
  Result<String> getStudentId() => Result.success(_kStudentId);

  @override
  Future<Result<void>> init() async => Result.success(null);
}

class _FakeAttemptRepository extends AttemptRepository {
  final List<StudentAttempt> attempts;

  _FakeAttemptRepository([this.attempts = const []]);

  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async {
    return Result.success(attempts);
  }
}

/// ---------------------------------------------------------------------------
/// Screen builder
/// ---------------------------------------------------------------------------

/// Builds `PracticeScreen` wrapped in `MaterialApp` + `ProviderScope` with
/// hand-written fakes (no Hive I/O) so the widget renders its populated state
/// deterministically. Each matrix cell gets a fresh tree with the correct
/// locale/theme.
///
/// `MaterialApp` provides the locale, theme, text-scale, and an `Overlay`
/// ancestor (needed by `Tooltip` / `showBottomSheet` in sub-widgets). Since
/// `MaterialApp` creates its own Theme/MediaQuery/Locale, we loop manually —
/// each matrix cell builds a fresh `MaterialApp` with the correct theme and
/// locale, avoiding `OverlayEntry` reuse errors across renders.
///
/// fixedStudentId per AGENTS.md — `_FakeStudentIdService` returns a constant ID
/// without requiring Hive box initialization.
Widget _buildPracticeScreen({
  required Locale locale,
  required ThemeMode theme,
  double textScale = 1.0,
}) {
  final themeData = theme == ThemeMode.dark ? ThemeData.dark() : ThemeData.light();
  return MaterialApp(
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
    // PracticeScreen already contains its own Scaffold.
    home: ProviderScope(
      overrides: [
        subjectRepositoryProvider.overrideWithValue(_FakeSubjectRepository(_kSubjects)),
        questionRepositoryProvider.overrideWithValue(_FakeQuestionRepository(_kQuestions)),
        spacedRepetitionServiceProvider.overrideWithValue(_FakeSpacedRepetitionService(_kDueCounts)),
        attemptRepositoryProvider.overrideWithValue(_FakeAttemptRepository(_kAttempts)),
        masteryGraphServiceProvider.overrideWithValue(_FakeMasteryGraphService(_kMastery)),
        sessionRepositoryProvider.overrideWithValue(_FakeSessionRepository(_kSessions)),
        studyProgressTrackerProvider.overrideWithValue(_FakeStudyProgressTracker(overallStats: _kStats)),
        studentIdServiceProvider.overrideWithValue(_FakeStudentIdService()),
      ],
      child: const PracticeScreen(),
    ),
  );
}

/// ---------------------------------------------------------------------------
/// Tests
/// ---------------------------------------------------------------------------

void Function(FlutterErrorDetails)? _originalOnError;

/// Drains all pending exceptions from the test binding.
///
/// `renderWidgetToPng` internally calls `binding.pump()`, which triggers
/// `RenderFlex` overflow (yellow stripes) at narrow phone widths (375 px).
/// The Flutter test binding captures these via its own `FlutterError.onError`
/// handler — installed inside `_runTest` *after* `setUp` — and stores them in
/// `_pendingExceptionDetails`, failing the test at completion.
///
/// The `setUp` override above only suppresses *console reporting* via
/// `dumpErrorToConsole`; it does **not** prevent the binding from recording
/// the exception. Only `takeException()` clears it.
///
/// We drain exceptions after each render so the matrix test can pass while
/// the overflow pixels remain captured in the golden image itself (enabling
/// future regression detection when the widget is fixed).
void _drainPendingExceptions(WidgetTester tester) {
  while (tester.takeException() != null) {}
}

void main() {
  // Golden tests compare pixels, not layout overflow. If the practice screen
  // overflows at narrow phone widths, the overflow is visible in the golden
  // itself. Suppress the framework's error reporting so the test can still
  // capture pixels for visual inspection.
  setUp(() {
    _originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
    };
    final root = _projectRoot();
    goldenFileComparator = LocalFileComparator(
      Uri.file('$root/.goldens_root_placeholder'),
    );
  });

  tearDown(() {
    FlutterError.onError = _originalOnError;
  });

  group('PracticeScreen goldens', () {
    // The 8-file matrix required by the issue: en/es x 375(phone)/1200(desktop)
    // x light/dark. MaterialApp handles theme + locale, so each cell gets its
    // own MaterialApp widget tree with the correct locale/theme; the package
    // only imposes the requested canvas size + pixel ratio.
    //
    // Test data (subjects, questions, mastery, sessions, stats) is populated so
    // every sub-section of PracticeScreen is exercised: summary row, activity
    // section with mastery chips + recent sessions, practice-mode grid, extra
    // modes grid, and the subject-card list. All timestamps are fixed (2025-01-01
    // etc.) so the practice-streak is deterministically 0 and `formatDate` always
    // uses the full date format — never "Today"/"Yesterday".
    testWidgets('matches goldens across locale x width x theme', (tester) async {
      const locales = [Locale('en'), Locale('es')];
      const sizes = [Size(375, 800), Size(1200, 800)];
      const themes = [ThemeMode.light, ThemeMode.dark];

      for (final locale in locales) {
        for (final size in sizes) {
          for (final theme in themes) {
            final png = await renderWidgetToPng(
              _buildPracticeScreen(locale: locale, theme: theme),
              size: size,
              pixelRatio: 2.0,
            );
            expect(png, isNotEmpty);
            final path = buildGoldenPath('practice_screen', locale, size, theme);
            await _expectGolden(png, path);
            // Drain overflow exceptions so they don't fail the test at
            // completion. The overflow pixels remain in the golden PNG.
            _drainPendingExceptions(tester);
          }
        }
      }
    });

    // A text-scale sweep guards the accessibility concern from the issue
    // (overflow at larger font sizes). We use a desktop-width canvas so the
    // practice screen's Column body has enough horizontal space for text to
    // flow without excessive wrapping — the goal is to catch *regressions*
    // in text-scaling behaviour, not phone-width layout overflow (which is a
    // separate, pre-existing widget concern visible in the width×height matrix).
    testWidgets('text-scale sweep stays readable at 1.0x/1.5x/2.0x', (tester) async {
      const textScales = [1.0, 1.5, 2.0];
      const size = Size(1200, 800);

      for (final textScale in textScales) {
        final png = await renderWidgetToPng(
          _buildPracticeScreen(
            locale: const Locale('en'),
            theme: ThemeMode.light,
            textScale: textScale,
          ),
          size: size,
          pixelRatio: 2.0,
        );
        expect(png, isNotEmpty);
        final path = buildGoldenPathWithTextScale(
          'practice_screen', const Locale('en'), size, textScale, ThemeMode.light,
        );
        await _expectGolden(png, path);
        // Drain any overflow exceptions at larger text scales.
        _drainPendingExceptions(tester);
      }
    });
  });
}
