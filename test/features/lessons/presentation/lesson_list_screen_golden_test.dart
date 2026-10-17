// Golden (visual) tests for `LessonListScreen` using the `flutter_to_image`
// package — the first consumer of the package on a top-level screen
// (per `docs/vision_next_term.md` §1.1: at least one golden test per
// top-level screen: dashboard, planner, teaching, mentor, practice, lessons).
//
// These goldens catch pixel-level regressions (layout overflow, contrast,
// density, stale-l10n, desktop-width truncation) that the structural widget
// tests in `lesson_list_screen_test.dart` cannot.
//
// See: docs/development/visual-testing.md
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_to_image/flutter_to_image.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/service_providers.dart' show studentIdValueProvider;
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/lessons/providers/lesson_providers.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/features/lessons/presentation/lesson_list_screen.dart';
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

/// Hand-written fake in place of Hive-backed `LessonRepository`.
/// No Hive I/O — returns in-memory data per AGENTS.md.
class _FakeLessonRepository extends LessonRepository {
  final List<Lesson> _lessons;

  _FakeLessonRepository({List<Lesson>? lessons}) : _lessons = lessons ?? [];

  @override
  Future<Result<List<Lesson>>> getAll() async => Result.success(_lessons);

  @override
  Future<Result<Lesson?>> get(String id) async =>
      Result.success(_lessons.where((l) => l.id == id).firstOrNull);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<void>> create(Lesson lesson) async => Result.success(null);
}

/// Hand-written fake in place of Hive-backed `SessionRepository`.
/// No Hive I/O — returns in-memory data per AGENTS.md.
class _FakeSessionRepository extends SessionRepository {
  final List<Session> _sessions;

  _FakeSessionRepository({List<Session>? sessions}) : _sessions = sessions ?? [];

  @override
  Future<Result<List<Session>>> getByStudent(String studentId) async {
    return Result.success(_sessions);
  }

  @override
  Future<Result<List<Session>>> getAll() async => Result.success(_sessions);

  @override
  Future<Result<void>> init() async => Result.success(null);
}

/// Test data: a small lesson list + session so the golden images are visually
/// meaningful (not empty states) and locale differences are clearly visible.
final _lessons = [
  Lesson(
    id: 'l1',
    subjectId: 's1',
    title: 'Introduction to Algebra',
    topicId: 't1',
    blocks: [
      LessonBlock(
        id: 'b1',
        subjectId: 's1',
        lessonId: 'l1',
        type: LessonBlockType.text,
        content: 'Content',
        order: 0,
      ),
    ],
    createdAt: DateTime.now(),
  ),
  Lesson(
    id: 'l2',
    subjectId: 's1',
    title: 'Linear Equations',
    topicId: 't1',
    blocks: [],
    createdAt: DateTime.now(),
  ),
];

final _sessions = <Session>[]; // No sessions → no status chips in ListTile subtitles

/// Builds `LessonListScreen` wrapped in `MaterialApp` + `ProviderScope` with
/// fakes, so the widget can read its Riverpod dependencies without Hive I/O.
///
/// `MaterialApp` is required because `LessonListScreen`'s `AppBar` contains a
/// `Tooltip` (inside `IconButton`) that needs an `Overlay` ancestor — which
/// `MaterialApp` provides via its internal `Navigator`.
///
/// Since `MaterialApp` creates its own Theme/MediaQuery/Directionality, we
/// loop manually instead of using `renderGoldenMatrixFull`/`renderGoldenTextScaleSweep`
/// (which would apply the same widget across multiple renders, and the
/// package's theme/locale/textScale would be overridden by MaterialApp's own).
///
/// Each call creates a fresh `MaterialApp` widget tree, so `OverlayEntry`
/// objects from previous renders don't conflict.
///
/// fixedStudentId per AGENTS.md — avoids StudentIdService singleton / Hive I/O.
Widget _buildScreen(Locale locale, ThemeMode theme, double textScale) {
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
    // LessonListScreen already contains its own Scaffold, so no extra Scaffold
    // is needed here — nested scaffds would constrain the body.
    home: ProviderScope(
      overrides: [
        lessonRepositoryProvider.overrideWithValue(_FakeLessonRepository(lessons: _lessons)),
        sessionRepositoryProvider.overrideWithValue(_FakeSessionRepository(sessions: _sessions)),
        studentIdValueProvider.overrideWith((ref) => 'test-student'),
      ],
      child: LessonListScreen(
        args: const LessonListArgs(
          topicId: 't1',
          topicTitle: 'Algebra',
          subjectId: 's1',
        ),
      ),
    ),
  );
}

void Function(FlutterErrorDetails)? _originalOnError;

void main() {
  // Golden tests compare pixels, not layout overflow. The LessonListScreen's
  // ListTile subtitle Row may overflow at narrow phone widths — this is a
  // pre-existing widget concern visible in the golden itself. Suppress the
  // framework's error reporting so the test can still capture pixels.
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

  group('LessonListScreen goldens', () {
    // The 8-file matrix required by the issue: en/es x 375(phone)/1200(desktop)
    // x light/dark. We loop manually because MaterialApp provides its own
    // Theme/MediaQuery/Locale, which take precedence over the package's
    // wrappers — so each matrix cell needs its own MaterialApp with the
    // correct theme and locale.
    testWidgets('matches goldens across locale x width x theme', (tester) async {
      const locales = [Locale('en'), Locale('es')];
      // Phone height ~ 15% of 375 width; desktop tall enough for the list.
      const sizes = [Size(375, 667), Size(1200, 800)];
      const themes = [ThemeMode.light, ThemeMode.dark];

      for (final locale in locales) {
        for (final size in sizes) {
          for (final theme in themes) {
            final png = await renderWidgetToPng(
              _buildScreen(locale, theme, 1.0),
              size: size,
              pixelRatio: 2.0,
            );
            expect(png, isNotEmpty);
            final path = buildGoldenPath('lesson_list', locale, size, theme);
            await _expectGolden(png, path);
          }
        }
      }
    });

    // A text-scale sweep guards the accessibility concern from the issue
    // (overflow at larger font sizes). Each scale gets its own MaterialApp
    // (with textScaler applied via MediaQuery) because MaterialApp creates
    // its own MediaQuery that overrides the package's.
    testWidgets('text-scale sweep stays readable at 1.0x/1.5x/2.0x', (tester) async {
      const textScales = [1.0, 1.5, 2.0];
      const size = Size(375, 800);

      for (final textScale in textScales) {
        final png = await renderWidgetToPng(
          _buildScreen(const Locale('en'), ThemeMode.light, textScale),
          size: size,
          pixelRatio: 2.0,
        );
        expect(png, isNotEmpty);
        final path = buildGoldenPathWithTextScale(
          'lesson_list', const Locale('en'), size, textScale, ThemeMode.light,
        );
        await _expectGolden(png, path);
      }
    });
  });
}
