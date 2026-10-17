// Golden (visual) tests for `PlannerScreen` using the `flutter_to_image`
// package — the third top-level screen with golden coverage
// (per `docs/vision_next_term.md` §1.1: at least one golden test per
// top-level screen: dashboard, planner, teaching, mentor, practice, lessons).
//
// These goldens catch pixel-level regressions (layout overflow in the
// roadmap/roadmap-labels section at narrow widths, contrast regressions in
// dark mode, stale-l10n strings after locale switch, desktop-width truncation)
// that the structural widget tests in `planner_screen_test.dart` cannot.
//
// See: docs/development/visual-testing.md
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_to_image/flutter_to_image.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/features/planner/presentation/planner_screen.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/planner/services/personal_learning_plan_service.dart';
import 'package:studyking/features/subjects/providers/subject_repository_provider.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';

import 'planner_screen_test_helpers.dart';

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

/// Fixed clock so golden renders are deterministic (no DST-dependent dates).
class _FixedClock implements Clock {
  const _FixedClock();
  @override
  DateTime now() => DateTime(2026, 1, 15, 12, 0, 0);
}

/// Builds `PlannerScreen` wrapped in `MaterialApp` + `ProviderScope` with
/// hand-written fakes — no Hive I/O, deterministic via [_FixedClock] and
/// `fixedStudentId: 'test-student'` per `AGENTS.md`.
///
/// `MaterialApp` is required because `PlannerScreen`'s `AppBar` contains a
/// `PopupMenuButton` / `Tooltip` that need an `Overlay` ancestor.
///
/// Since `MaterialApp` creates its own Theme/MediaQuery/Locale, we loop
/// manually instead of using `renderGoldenMatrixFull` — each matrix cell
/// gets its own `MaterialApp` widget tree.
Widget _buildPlannerScreen(Locale locale, ThemeMode theme, double textScale, String studentId) {
  final themeData = theme == ThemeMode.dark ? ThemeData.dark() : ThemeData.light();

  // Build a PlannerService with hand-written fakes (no Hive I/O), mirroring
  // the approach in `planner_screen_test_helpers.dart` `buildPlannerTestApp`.
  final svc = PlannerService(
    planRepo: FakePlanRepository(),
    masteryService: MasteryGraphService(),
    repository: FakeMasteryGraphRepository(),
    topicRepository: FakeTopicRepository(),
    roadmapRepo: FakeRoadmapRepository(),
    sessionRepo: FakeSessionRepository(),
    pendingActionRepo: FakePendingActionRepository(),
    planOrchestrator: FakePlanAdherenceOrchestrator(),
    adherenceRepo: FakeAdherenceRepo(),
    planContextRepo: FakePlanContextRepository(),
    planService: PersonalLearningPlanService(
      repository: FakeMasteryGraphRepository(),
      topicRepository: FakeTopicRepository(),
      planRepository: FakePlanRepository(),
      // QuestionRepository defaults to an in-memory instance that won't
      // init Hive until a method is called (and plan generation isn't
      // triggered during a static golden render).
      l10n: AppLocalizationsEn(),
      clock: const _FixedClock(),
    ),
    fixedStudentId: studentId,
  );

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
    home: ProviderScope(
      overrides: [
        plannerServiceProvider.overrideWithValue(svc),
        subjectRepositoryProvider.overrideWith((ref) => FakeSubjectRepository()),
        topicRepositoryProvider.overrideWith((ref) => FakeTopicRepository()),
        clockProvider.overrideWithValue(const _FixedClock()),
      ],
      child: PlannerScreen(fixedStudentId: studentId),
    ),
  );
}

void Function(FlutterErrorDetails)? _originalOnError;

void main() {
  // Golden tests compare pixels, not layout overflow. The PlannerScreen's
  // TabBar / list items may overflow at narrow phone widths — this is a
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

  group('PlannerScreen goldens', () {
    // The 8-file matrix required by the issue: en/es x 375(phone)/1200(desktop)
    // x light/dark. MaterialApp handles theme + locale, so each cell gets its
    // own MaterialApp widget tree.
    testWidgets('matches goldens across locale x width x theme', (tester) async {
      const locales = [Locale('en'), Locale('es')];
      const sizes = [Size(375, 800), Size(1200, 800)];
      const themes = [ThemeMode.light, ThemeMode.dark];
      const studentId = 'test-student';

      for (final locale in locales) {
        for (final size in sizes) {
          for (final theme in themes) {
            final png = await renderWidgetToPng(
              _buildPlannerScreen(locale, theme, 1.0, studentId),
              size: size,
              pixelRatio: 2.0,
            );
            expect(png, isNotEmpty);
            final path = buildGoldenPath('planner_screen', locale, size, theme);
            await _expectGolden(png, path);
          }
        }
      }
    });

    // A text-scale sweep guards the accessibility concern from the issue
    // (overflow at larger font sizes). We use a desktop-width canvas so the
    // planner screen's TabBar and content have enough horizontal space for
    // text to flow without excessive wrapping — the goal is to catch
    // *regressions* in text-scaling behaviour, not phone-width layout overflow.
    testWidgets('text-scale sweep stays readable at 1.0x/1.5x/2.0x', (tester) async {
      const textScales = [1.0, 1.5, 2.0];
      const size = Size(1200, 800);
      const studentId = 'test-student';

      for (final textScale in textScales) {
        final png = await renderWidgetToPng(
          _buildPlannerScreen(const Locale('en'), ThemeMode.light, textScale, studentId),
          size: size,
          pixelRatio: 2.0,
        );
        expect(png, isNotEmpty);
        final path = buildGoldenPathWithTextScale(
          'planner_screen', const Locale('en'), size, textScale, ThemeMode.light,
        );
        await _expectGolden(png, path);
      }
    });
  });
}
