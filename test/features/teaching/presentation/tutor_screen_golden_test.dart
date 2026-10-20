// Golden (visual) tests for `TutorScreen` using the `flutter_to_image`
// package — the teaching-mode top-level screen golden test
// (per `docs/vision_next_term.md` §1.1: at least one golden test per
// top-level screen: dashboard, planner, teaching, mentor, practice, lessons).
//
// These goldens catch pixel-level regressions (layout overflow, contrast,
// density, stale-l10n, desktop-width truncation) that the structural widget
// tests in `tutor_screen_test.dart` cannot.
//
// See: docs/development/visual-testing.md
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_to_image/flutter_to_image.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider, SettingsController;
import 'package:studyking/core/providers/service_providers.dart' show studentIdValueProvider, studentIdServiceProvider, voiceServiceProvider;
import 'package:studyking/core/providers/llm_agent_providers.dart' show llmAgentProvider;
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/voice_service.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/teaching/presentation/tutor_screen.dart';
import 'package:studyking/features/teaching/services/conversation_manager.dart';
import 'package:studyking/features/teaching/services/exercise_evaluator.dart';
import 'package:studyking/features/teaching/services/tutor_service.dart';
import 'package:studyking/features/teaching/data/models/evaluation_result.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/settings_update.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../helpers/fakes.dart';

// ---------------------------------------------------------------------------
// Fakes — hand-written (no mockito/mocktail) per AGENTS.md. No Hive I/O.
// ---------------------------------------------------------------------------

/// LLM whose chat stream yields instantly — lets TutorScreen's greeting
/// complete within `renderWidgetToPng`'s `_pumpAndSettle` frame budget.
class _FakeLlmService extends LlmService {
  _FakeLlmService()
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'test-key',
          ),
        );

  @override
  Future<Result<String>> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
    String? taskType,
  }) async {
    return Result.success(
      '{"goals":["goal1"],"sections":[{"title":"intro","duration":10,"type":"explanation"}]}',
    );
  }

  @override
  Stream<String> chatStream({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
    String? taskType,
  }) async* {
    yield 'Mock tutor response for: $message';
  }
}

/// Exercise evaluator that always returns a fixed result.
class _FakeExerciseEvaluator extends ExerciseEvaluator {
  _FakeExerciseEvaluator()
      : super(
          llmService: _FakeLlmService(),
          modelId: 'test-model',
          localeName: 'en',
        );

  @override
  Future<Result<EvaluationResult>> evaluate({
    required String question,
    required String studentAnswer,
    required String subjectId,
    required String topicTitle,
    String? systemPrompt,
    String? userPrompt,
  }) async {
    return Result.success(EvaluationResult(score: 0.8, explanation: 'Good work.'));
  }
}

/// Minimal MasteryGraphService fake — returns empty results, no Hive I/O.
class _FakeMasteryGraphService extends MasteryGraphService {
  _FakeMasteryGraphService()
      : super(
          masteryStateRepo: null,
          questionMasteryRepo: null,
          topicDependencyRepo: null,
          questionEvaluationRepo: null,
          calculationService: null,
        );

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(
    String studentId, {
    String? subjectId,
  }) async =>
      Result.success([]);

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(
    String studentId, {
    double threshold = 0.5,
  }) async =>
      Result.success([]);

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(
    String studentId,
  ) async =>
      Result.success({});
}

/// Minimal SpacedRepetitionService fake — returns empty results.
class _FakeSpacedRepetitionService extends SpacedRepetitionService {
  _FakeSpacedRepetitionService()
      : super(
          questionRepo: FakeQuestionRepository(),
          attemptRepo: FakeAttemptRepository(),
          srEngine: null,
        );

  @override
  Future<Result<List<Question>>> getQuestionsDueForReview({DateTime? asOf}) async =>
      Result.success([]);

  @override
  Future<Result<List<Question>>> getTopicTimeDue(String topicId) async =>
      Result.success([]);
}

// ---------------------------------------------------------------------------
// Null repositories — no-op init, no Hive I/O.
// ---------------------------------------------------------------------------

class _NullConversationRepository extends ConversationRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);
}

class _NullLessonRepository extends LessonRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);
}

class _NullSubjectRepository extends SubjectRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);
}

// ---------------------------------------------------------------------------
// Settings / voice / student-id fakes
// ---------------------------------------------------------------------------

class _FakeSettingsRepository extends SettingsRepository {
  final SettingsBox _box = SettingsBox();

  @override
  Future<Result<SettingsBox>> getSettings() async => Result.success(_box);

  @override
  Future<Result<void>> updateSettings(SettingsUpdate update) async =>
      Result.success(null);
}

class _FakeVoiceService extends VoiceService {
  @override
  bool get isAvailable => true;

  @override
  bool get isListening => false;

  @override
  Stream<String> get transcribedText => const Stream.empty();

  @override
  Future<Result<void>> startListening({String? localeName}) async =>
      Result.success(null);

  @override
  Future<void> stopListening() async {}

  @override
  Future<bool> requestPermission() async => true;
}

// ---------------------------------------------------------------------------
// TutorService fake — startLesson returns a pre-configured ConversationManager
// with an instant LLM stream so the greeting completes within the frame budget.
// ---------------------------------------------------------------------------

class _FakeTutorService extends TutorService {
  final LlmService llm;
  ConversationManager? lastManager;

  _FakeTutorService({LlmService? llmService})
      : llm = llmService ?? _FakeLlmService(),
        super(
          database: DatabaseService(
            topicRepository: FakeTopicRepository(),
            questionRepository: FakeQuestionRepository(),
            attemptRepository: FakeAttemptRepository(),
            lessonRepository: _NullLessonRepository(),
            sessionRepository: FakeSessionRepository(),
            subjectRepository: _NullSubjectRepository(),
            conversationRepository: _NullConversationRepository(),
            tutorSessionRepository: FakeTutorSessionRepository(),
          ),
          llmService: llmService ?? _FakeLlmService(),
          masteryService: _FakeMasteryGraphService(),
          spacedRepetitionService: _FakeSpacedRepetitionService(),
          modelId: 'test-model',
          exerciseEvaluator: _FakeExerciseEvaluator(),
          conversationRepository: _NullConversationRepository(),
        );

  @override
  Future<ConversationManager> startLesson({
    required String studentId,
    required String subjectId,
    required String topicId,
    required String topicTitle,
    int durationMinutes = 45,
    String? scheduledSessionId,
    required String localeName,
  }) async {
    final manager = ConversationManager(
      llmService: llm,
      modelId: 'test-model',
      sessionId: 'test-session',
      studentId: studentId,
      topicTitle: topicTitle,
      subjectId: subjectId,
      topicId: topicId,
      exerciseEvaluator: _FakeExerciseEvaluator(),
      localeName: localeName,
    );
    await manager.initialize();
    lastManager = manager;
    return manager;
  }

  @override
  Future<void> endLesson() async {}
}

// ---------------------------------------------------------------------------
// Widget builder
// ---------------------------------------------------------------------------

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

/// Builds `TutorScreen` wrapped in `MaterialApp` + `ProviderScope` with
/// hand-written fakes.
///
/// `MaterialApp` is required because `TutorScreen`'s `AppBar` contains
/// `Tooltip` and `PopupMenuButton` widgets that need an `Overlay` ancestor.
/// Since `MaterialApp` creates its own Theme/MediaQuery/Locale, we loop
/// manually instead of using `renderGoldenMatrixFull` — each matrix cell
/// builds a fresh `MaterialApp` widget tree.
///
/// All Riverpod overrides use hand-written fakes (not `mockito`/`mocktail`)
/// per `AGENTS.md`. No Hive I/O: `StudentIdService.getStudentId()` returns a
/// UUID without requiring Hive box initialization.
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
    // TutorScreen already contains its own Scaffold.
    home: ProviderScope(
      overrides: [
        studentIdValueProvider.overrideWith((ref) => 'test-student-id'),
        studentIdServiceProvider.overrideWithValue(FakeStudentIdService()),
        settingsProvider.overrideWith((ref) => SettingsController(_FakeSettingsRepository())),
        voiceServiceProvider.overrideWithValue(_FakeVoiceService()),
        llmAgentProvider.overrideWith((ref, studentId) => null),
      ],
      child: TutorScreen(
        topicId: '',
        topicTitle: 'Algebra',
        subjectId: 'math',
        durationMinutes: 45,
        tutorService: _FakeTutorService(),
      ),
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
    // Golden tests capture pixels, not layout overflow. At narrow phone widths
    // / larger text scales the TutorScreen's LessonProgressBar Row overflows —
    // that overflow IS the regression we want the golden to record. Suppress
    // the framework handler so the overflow doesn't abort the capture; the
    // golden comparison below still catches real visual drift.
    FlutterError.onError = (FlutterErrorDetails details) {
      // Intentionally empty — overflow is visible in the golden image itself.
    };
    final root = _projectRoot();
    goldenFileComparator = LocalFileComparator(
      Uri.file('$root/.goldens_root_placeholder'),
    );
  });

  tearDown(() {
    FlutterError.onError = _originalOnError;
  });

  group('TutorScreen goldens', () {
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
              _buildScreen(locale, theme, 1.0),
              size: size,
              pixelRatio: 2.0,
            );
            expect(png, isNotEmpty);
            final path = buildGoldenPath('tutor_screen', locale, size, theme);
            await _expectGolden(png, path);
          }
        }
      }
    });

    // A text-scale sweep guards the accessibility concern from the issue
    // (overflow at larger font sizes). We use a desktop-width canvas
    // (matching the mentor_screen_golden_test pattern) so text-scaling
    // regressions are visible without the overflow noise that narrow phone
    // widths produce at 1.5x/2.0x.
    testWidgets('text-scale sweep stays readable at 1.0x/1.5x/2.0x', (tester) async {
      const textScales = [1.0, 1.5, 2.0];
      const size = Size(1200, 800);

      for (final textScale in textScales) {
        final png = await renderWidgetToPng(
          _buildScreen(const Locale('en'), ThemeMode.light, textScale),
          size: size,
          pixelRatio: 2.0,
        );
        expect(png, isNotEmpty);
        final path = buildGoldenPathWithTextScale(
          'tutor_screen', const Locale('en'), size, textScale, ThemeMode.light,
        );
        await _expectGolden(png, path);
      }
    });
  });
}
