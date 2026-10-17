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

/// Builds the LessonListScreen wrapped in ProviderScope with fakes,
/// so the widget can read its Riverpod dependencies without Hive I/O.
Widget _buildScreen(Locale locale) {
  final now = DateTime.now();
  final lessons = [
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
      createdAt: now,
    ),
    Lesson(
      id: 'l2',
      subjectId: 's1',
      title: 'Linear Equations',
      topicId: 't1',
      blocks: [],
      createdAt: now,
    ),
  ];
  final sessions = [
    Session(
      id: 'sess1',
      studentId: 'test-student',
      subjectId: 's1',
      topicId: 't1',
      type: SessionType.tutoring,
      startTime: now,
      endTime: now.add(const Duration(minutes: 30)),
      completed: true,
      status: SessionStatus.completed,
      lessonIds: ['l1'],
    ),
  ];

  // Wrap in MaterialApp to provide the app-level inherited widgets
  // (Localizations, MediaQuery, ScaffoldMessenger, etc.) that LessonListScreen
  // expects. The flutter_to_image package wraps this with its own Theme/
  // Directionality/MediaQuery, which MaterialApp inherits.
  // The flutter_to_image package wraps the widget with Theme, Directionality,
  // MediaQuery, and an optional Localizations wrapper (all passed via
  // renderGoldenMatrixFull parameters), so LessonListScreen gets everything
  // it needs without a MaterialApp — just the ProviderScope for Riverpod.
  return ProviderScope(
    overrides: [
      lessonRepositoryProvider.overrideWithValue(_FakeLessonRepository(lessons: lessons)),
      sessionRepositoryProvider.overrideWithValue(_FakeSessionRepository(sessions: sessions)),
      // fixedStudentId per AGENTS.md — avoids StudentIdService singleton / Hive I/O.
      studentIdValueProvider.overrideWith((ref) => 'test-student'),
    ],
    child: LessonListScreen(
      args: const LessonListArgs(
        topicId: 't1',
        topicTitle: 'Algebra',
        subjectId: 's1',
      ),
    ),
  );
}

void main() {
  // The package's `buildGoldenPath` produces root-relative paths such as
  // `test/goldens/lesson_list_en_375_light.png`. The default
  // `GoldenFileComparator` roots relative golden keys at the *test file's*
  // directory, so from `test/features/lessons/.../presentation/` that would look
  // in the wrong place. Override it to root lookups at the project root.
  setUp(() {
    final root = _projectRoot();
    goldenFileComparator = LocalFileComparator(
      Uri.file('$root/.goldens_root_placeholder'),
    );
  });

  group('LessonListScreen goldens', () {
    // The 8-file matrix required by the issue: en/es x 375(phone)/1200(desktop)
    // x light/dark.
    testWidgets('matches goldens across locale x width x theme', (tester) async {
      const locales = [Locale('en'), Locale('es')];
      // Phone height ~ 15% of 375 width; desktop tall enough for the list.
      const sizes = [Size(375, 667), Size(1200, 800)];
      const themes = [ThemeMode.light, ThemeMode.dark];

      for (final locale in locales) {
        final matrix = await renderGoldenMatrixFull(
          _buildScreen(locale),
          locales: [locale],
          sizes: sizes,
          themeModes: themes,
          pixelRatio: 2.0,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          pathBuilder: (l, s, t) =>
              buildGoldenPath('lesson_list', l, s, t),
        );

        // 2 sizes x 2 themes = 4 entries per locale
        expect(matrix.length, sizes.length * themes.length);
        for (final entry in matrix.entries) {
          expect(entry.value, isNotEmpty);
          await _expectGolden(entry.value, entry.key);
        }
      }
    });

    // A text-scale sweep exercises the package's `renderGoldenTextScaleSweep`
    // helper and guards the accessibility concern from the issue (overflow at
    // larger font sizes) — LessonListScreen's ListView, AppBar, and chips
    // must remain intact.
    testWidgets('text-scale sweep stays readable at 1.0x/1.5x/2.0x', (tester) async {
      final sweep = await renderGoldenTextScaleSweep(
        _buildScreen(const Locale('en')),
        locale: const Locale('en'),
        size: const Size(375, 800),
        textScales: [1.0, 1.5, 2.0],
        themeMode: ThemeMode.light,
        pixelRatio: 2.0,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        pathBuilder: (locale, size, textScale, theme) =>
            buildGoldenPathWithTextScale('lesson_list', locale, size, textScale, theme),
      );

      expect(sweep.length, 3);
      for (final entry in sweep.entries) {
        expect(entry.value, isNotEmpty);
        await _expectGolden(entry.value, entry.key);
      }
    });
  });
}
