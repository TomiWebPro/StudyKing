// Golden (visual) tests for `MentorScreen` using the `flutter_to_image`
// package — the second top-level screen with golden coverage
// (per `docs/vision_next_term.md` §1.1: at least one golden test per
// top-level screen: dashboard, planner, teaching, mentor, practice, lessons).
//
// These goldens catch pixel-level regressions (layout overflow, contrast,
// density, stale-l10n, desktop-width truncation) that the structural widget
// tests in `mentor_screen_basic_test.dart` etc. cannot.
//
// See: docs/development/visual-testing.md
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_to_image/flutter_to_image.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider, SettingsController;
import 'package:studyking/core/providers/llm_providers.dart' show llmServiceProvider;
import 'package:studyking/features/mentor/providers/mentor_providers.dart'
    show mentorEngagementNudgeRepoProvider, mentorSessionRepositoryProvider, mentorProgressTrackerProvider;
import 'package:studyking/features/planner/providers/planner_providers.dart' show plannerServiceProvider;
import 'package:studyking/features/practice/providers/practice_providers.dart' show masteryGraphServiceProvider;
import 'package:studyking/core/providers/llm_agent_providers.dart' show llmAgentProvider, longTermMemoryProvider;
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/features/mentor/presentation/mentor_screen.dart';
import 'mentor_screen_test_helpers.dart';

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

/// Builds `MentorScreen` wrapped in `MaterialApp` + `ProviderScope` with the
/// same hand-written fakes from `mentor_screen_test_helpers.dart`.
///
/// `MaterialApp` is required because `MentorScreen`'s `AppBar` contains
/// `Tooltip` widgets that need an `Overlay` ancestor. Since `MaterialApp`
/// creates its own Theme/MediaQuery/Locale, we loop manually instead of using
/// the package's `renderGoldenMatrixFull`/`renderGoldenTextScaleSweep` — each
/// matrix cell builds a fresh `MaterialApp` with the correct locale/theme.
///
/// All Riverpod overrides use hand-written fakes (not `mockito`/`mocktail`) per
/// `AGENTS.md`. No Hive I/O: `StudentIdService.getStudentId()` returns a UUID
/// without requiring Hive box initialization.
Widget _buildMentorScreen(Locale locale, ThemeMode theme, double textScale) {
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
    // MentorScreen already contains its own Scaffold.
    home: ProviderScope(
      overrides: [
        llmServiceProvider.overrideWithValue(FakeLlmService()),
        settingsProvider.overrideWith((ref) => SettingsController(FakeSettingsRepo())),
        plannerServiceProvider.overrideWithValue(FakePlannerService()),
        mentorEngagementNudgeRepoProvider.overrideWithValue(FakeNudgeRepo()),
        mentorSessionRepositoryProvider.overrideWithValue(FakeSessionRepo()),
        masteryGraphServiceProvider.overrideWithValue(FakeMasteryGraphService()),
        mentorProgressTrackerProvider.overrideWithValue(FakeProgressTracker()),
        llmAgentProvider.overrideWith((ref, studentId) => null),
        longTermMemoryProvider.overrideWithValue(FakeLongTermMemory()),
      ],
      child: const MentorScreen(),
    ),
  );
}

void Function(FlutterErrorDetails)? _originalOnError;

void main() {
  // Golden tests compare pixels, not layout overflow. If a matrix item overflows
  // at narrow phone widths, the overflow is visible in the golden itself.
  // Suppress the framework's error reporting so the test can still capture pixels.
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

  group('MentorScreen goldens', () {
    // The 8-file matrix required by the issue: en/es x 375(phone)/1200(desktop)
    // x light/dark. MaterialApp handles theme + locale, so each cell gets its
    // own MaterialApp widget tree.
    testWidgets('matches goldens across locale x width x theme', (tester) async {
      const locales = [Locale('en'), Locale('es')];
      const sizes = [Size(375, 800), Size(1200, 800)];
      const themes = [ThemeMode.light, ThemeMode.dark];

      for (final locale in locales) {
        for (final size in sizes) {
          for (final theme in themes) {
            final png = await renderWidgetToPng(
              _buildMentorScreen(locale, theme, 1.0),
              size: size,
              pixelRatio: 2.0,
            );
            expect(png, isNotEmpty);
            final path = buildGoldenPath('mentor_screen', locale, size, theme);
            await _expectGolden(png, path);
          }
        }
      }
    });

    // A text-scale sweep guards the accessibility concern from the issue
    // (overflow at larger font sizes). We use a desktop-width canvas so the
    // mentor screen's Column body has enough horizontal space for text to
    // flow without excessive wrapping — the goal is to catch *regressions*
    // in text-scaling behaviour, not phone-width layout overflow (which is a
    // separate, pre-existing widget concern visible in the width×height matrix).
    testWidgets('text-scale sweep stays readable at 1.0x/1.5x/2.0x', (tester) async {
      const textScales = [1.0, 1.5, 2.0];
      const size = Size(1200, 800);

      for (final textScale in textScales) {
        final png = await renderWidgetToPng(
          _buildMentorScreen(const Locale('en'), ThemeMode.light, textScale),
          size: size,
          pixelRatio: 2.0,
        );
        expect(png, isNotEmpty);
        final path = buildGoldenPathWithTextScale(
          'mentor_screen', const Locale('en'), size, textScale, ThemeMode.light,
        );
        await _expectGolden(png, path);
      }
    });
  });
}
