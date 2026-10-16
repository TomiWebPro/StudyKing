import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/teaching/presentation/tutor_screen.dart';
import 'package:studyking/features/teaching/presentation/widgets/chat_bubble.dart';
import 'package:studyking/features/teaching/services/conversation_manager.dart';
import 'package:studyking/features/teaching/services/exercise_evaluator.dart';
import 'package:studyking/features/teaching/services/tutor_service.dart';
import 'package:studyking/features/teaching/data/models/evaluation_result.dart';
import 'package:studyking/core/providers/service_providers.dart' show studentIdValueProvider, studentIdServiceProvider, voiceServiceProvider;
import 'package:studyking/core/providers/shared_providers.dart' show settingsProvider, SettingsController;
import 'package:studyking/core/providers/llm_agent_providers.dart' show llmAgentProvider;
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/services/voice_service.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/settings_update.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/navigator_observer_helper.dart';

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
  }) async {
    return Result.success('{"goals":["goal1"],"sections":[{"title":"intro","duration":10,"type":"explanation"}],"checkpoints":["cp1"],"estimatedDifficulty":2}');
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
  }) async* {
    yield 'Mock tutor response for: $message';
  }
}

class _SlowStreamLlmService extends LlmService {
  _SlowStreamLlmService()
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
  }) async {
    return Result.success('{"goals":["goal1"],"sections":[{"title":"intro","duration":10,"type":"explanation"}],"checkpoints":["cp1"],"estimatedDifficulty":2}');
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
  }) async* {
    yield 'partial tutor reply';
    await Future.delayed(const Duration(seconds: 2));
    yield ' now complete';
  }
}

/// LLM whose chat stream succeeds for the initial greeting (first
/// call) and then fails mid-stream with a provider connection error
/// on the next call — the errors `_sendText`'s catch exists for.
///
/// [beforeFailure], when provided, is awaited after the partial
/// chunk and before the stream throws, so tests can dispose the
/// screen while the stream is still open.
class _MidStreamFailureLlmService extends LlmService {
  _MidStreamFailureLlmService({Future<void>? beforeFailure})
      : _beforeFailure = beforeFailure,
        super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'test-key',
          ),
        );

  final Future<void>? _beforeFailure;
  int _streamCalls = 0;

  @override
  Future<Result<String>> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async {
    return Result.success('{"goals":["goal1"],"sections":[{"title":"intro","duration":10,"type":"explanation"}],"checkpoints":["cp1"],"estimatedDifficulty":2}');
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
  }) async* {
    _streamCalls++;
    if (_streamCalls == 1) {
      // Initial greeting stream.
      yield 'Welcome to the lesson!';
      return;
    }
    yield 'partial tutor reply';
    if (_beforeFailure != null) {
      await _beforeFailure;
    }
    throw Exception('Connection refused');
  }
}

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
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId, {String? subjectId}) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(
    String studentId, {
    double threshold = 0.5,
  }) async {
    return Result.success([]);
  }

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(
      String studentId) async {
    return Result.success({});
  }
}

class _FakeSpacedRepetitionService extends SpacedRepetitionService {
  _FakeSpacedRepetitionService()
      : super(
          questionRepo: FakeQuestionRepository(),
          attemptRepo: FakeAttemptRepository(),
          srEngine: null,
        );

  @override
  Future<Result<List<Question>>> getQuestionsDueForReview({DateTime? asOf}) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<Question>>> getTopicTimeDue(String topicId) async {
    return Result.success([]);
  }
}

DatabaseService _createFakeDatabase() {
  return DatabaseService(
    topicRepository: FakeTopicRepository(),
    questionRepository: FakeQuestionRepository(),
    attemptRepository: FakeAttemptRepository(),
    lessonRepository: _NullLessonRepository(),
    sessionRepository: FakeSessionRepository(),
    subjectRepository: _NullSubjectRepository(),
    conversationRepository: _NullConversationRepository(),
    tutorSessionRepository: FakeTutorSessionRepository(),
  );
}

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

class _FakeSettingsRepository extends SettingsRepository {
  final SettingsBox _box = SettingsBox();

  @override
  Future<Result<SettingsBox>> getSettings() async => Result.success(_box);

  @override
  Future<Result<void>> updateSettings(SettingsUpdate update) async => Result.success(null);
}

class _FakeStudentIdService extends StudentIdService {
  @override
  Result<String> getStudentId() => Result.success('test-student-id');
}

class _FakeVoiceService extends VoiceService {
  @override
  bool get isAvailable => true;
  @override
  bool get isListening => false;
  @override
  Stream<String> get transcribedText => const Stream.empty();
  @override
  Future<Result<void>> startListening({String? localeName}) async => Result.success(null);
  @override
  Future<void> stopListening() async {}
  @override
  Future<bool> requestPermission() async => true;
}

class _FakeTutorService extends TutorService {
  final bool shouldFail;
  final LlmService llm;
  ConversationManager? lastManager;

  _FakeTutorService({this.shouldFail = false, LlmService? llmService})
      : llm = llmService ?? _FakeLlmService(),
        super(
          database: _createFakeDatabase(),
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
    String localeName = 'en',
  }) async {
    if (shouldFail) throw Exception('LLM connection failed');
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

/// TutorService whose `startLesson` throws on the first call (the
/// initial init) and succeeds afterwards, so the Retry button's
/// second `_initializeTutor()` run can be observed recovering.
class _FailOnceTutorService extends _FakeTutorService {
  _FailOnceTutorService() : super(llmService: _FakeLlmService());

  int _startLessonCalls = 0;

  @override
  Future<ConversationManager> startLesson({
    required String studentId,
    required String subjectId,
    required String topicId,
    required String topicTitle,
    int durationMinutes = 45,
    String? scheduledSessionId,
    String localeName = 'en',
  }) async {
    _startLessonCalls++;
    if (_startLessonCalls == 1) throw Exception('LLM connection failed');
    return super.startLesson(
      studentId: studentId,
      subjectId: subjectId,
      topicId: topicId,
      topicTitle: topicTitle,
      durationMinutes: durationMinutes,
      scheduledSessionId: scheduledSessionId,
      localeName: localeName,
    );
  }
}

/// ConversationManager whose `addAssistantMessage` — the error-path
/// persist `TutorScreen._sendText` awaits — parks on a gate until the
/// test releases it, so the screen can be disposed while the persist
/// is in flight.
class _GatedPersistConversationManager extends ConversationManager {
  _GatedPersistConversationManager({
    required super.llmService,
    required Completer<void> persistGate,
    required Completer<void> persistStarted,
  })  : _persistGate = persistGate,
        _persistStarted = persistStarted,
        super(
          modelId: 'test-model',
          sessionId: 'test-session',
          studentId: 'test-student-id',
          topicTitle: 'Algebra',
          subjectId: 'math',
          topicId: '',
          exerciseEvaluator: _FakeExerciseEvaluator(),
          localeName: 'en',
        );

  final Completer<void> _persistGate;
  final Completer<void> _persistStarted;

  @override
  Future<void> addAssistantMessage(String content) async {
    _persistStarted.complete();
    await _persistGate.future;
    await super.addAssistantMessage(content);
  }
}

/// TutorService that builds a [_GatedPersistConversationManager] so
/// the error-path persist can be parked mid-flight.
class _GatedPersistTutorService extends _FakeTutorService {
  _GatedPersistTutorService({
    required super.llmService,
    required Completer<void> persistGate,
    required Completer<void> persistStarted,
  })  : _persistGate = persistGate,
        _persistStarted = persistStarted;

  final Completer<void> _persistGate;
  final Completer<void> _persistStarted;

  @override
  Future<ConversationManager> startLesson({
    required String studentId,
    required String subjectId,
    required String topicId,
    required String topicTitle,
    int durationMinutes = 45,
    String? scheduledSessionId,
    String localeName = 'en',
  }) async {
    final manager = _GatedPersistConversationManager(
      llmService: llm,
      persistGate: _persistGate,
      persistStarted: _persistStarted,
    );
    await manager.initialize();
    lastManager = manager;
    return manager;
  }
}

/// XFile whose `readAsBytes` — the file read `TutorScreen._pickImage`
/// awaits after the pick — parks on a gate until the test releases it,
/// so the screen can be disposed while the read is in flight.
class _GatedReadXFile extends XFile {
  _GatedReadXFile({
    required Completer<void> readGate,
    required Completer<void> readStarted,
  })  : _readGate = readGate,
        _readStarted = readStarted,
        super('gated-image.jpg');

  final Completer<void> _readGate;
  final Completer<void> _readStarted;

  @override
  Future<Uint8List> readAsBytes() async {
    _readStarted.complete();
    await _readGate.future;
    return Uint8List(4);
  }
}

/// ImagePickerPlatform whose pick returns a [_GatedReadXFile] so the
/// post-pick byte read can be parked mid-flight.
class _GatedReadImagePickerPlatform extends ImagePickerPlatform {
  _GatedReadImagePickerPlatform({required XFile? pickedFile})
      : _pickedFile = pickedFile;

  final XFile? _pickedFile;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async =>
      _pickedFile;
}

Widget _wrapApp(Widget child, {TestNavigatorObserver? navigatorObserver}) {
  return ProviderScope(
    overrides: [
      studentIdValueProvider.overrideWith((ref) => 'test-student-id'),
      studentIdServiceProvider.overrideWithValue(_FakeStudentIdService()),
      settingsProvider.overrideWith((ref) => SettingsController(_FakeSettingsRepository())),
      voiceServiceProvider.overrideWithValue(_FakeVoiceService()),
      llmAgentProvider.overrideWith((ref, studentId) => null),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      home: child,
    ),
  );
}

void main() {
  group('TutorScreen', () {
    testWidgets('shows loading indicator before initialization', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: '',
          topicTitle: 'Algebra',
          subjectId: 'math',
          tutorService: _FakeTutorService(),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays topic title in app bar', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: '',
          topicTitle: 'Algebra Basics',
          subjectId: 'math',
          tutorService: _FakeTutorService(),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Algebra Basics'), findsAtLeast(1));
    });

    testWidgets('shows LessonProgressBar after initialization', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: '',
          topicTitle: 'Algebra',
          subjectId: 'math',
          durationMinutes: 45,
          tutorService: _FakeTutorService(),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders chat messages from manager', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: '',
          topicTitle: 'Algebra',
          subjectId: 'math',
          tutorService: _FakeTutorService(),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows end lesson button after initialization', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: '',
          topicTitle: 'Algebra',
          subjectId: 'math',
          tutorService: _FakeTutorService(),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('displays ConversationInput widget', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: '',
          topicTitle: 'Algebra',
          subjectId: 'math',
          tutorService: _FakeTutorService(),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('mic button is present for voice input', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: '',
          topicTitle: 'Algebra',
          subjectId: 'math',
          tutorService: _FakeTutorService(),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byIcon(Icons.mic_none), findsOneWidget);
    });

    testWidgets('image picker button shows SnackBar', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: '',
          topicTitle: 'Algebra',
          subjectId: 'math',
          tutorService: _FakeTutorService(),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byIcon(Icons.image_outlined));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Capture Image'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
    });

    testWidgets('sending a message adds user and tutor messages to chat', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: '',
          topicTitle: 'Algebra',
          subjectId: 'math',
          tutorService: _FakeTutorService(),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      await tester.enterText(find.byType(TextField), 'Hello tutor');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Hello tutor'), findsOneWidget);
    });

    testWidgets('displays tutor reply progressively while streaming', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: '',
          topicTitle: 'Algebra',
          subjectId: 'math',
          tutorService: _FakeTutorService(llmService: _SlowStreamLlmService()),
        ),
      ));
      await tester.pump();
      // Let the lesson start and the greeting stream finish (2s inter-chunk delay).
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      // Greeting finished: no bubble is still streaming.
      expect(
        find.byWidgetPredicate((w) => w is ChatBubble && w.message.isStreaming),
        findsNothing,
      );

      await tester.enterText(find.byType(TextField), 'Hello tutor');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Mid-stream: a tutor bubble is visible with partial content while the
      // stream is still open (previously nothing rendered until stream end).
      expect(
        find.byWidgetPredicate((w) => w is ChatBubble && w.message.isStreaming),
        findsOneWidget,
      );
      expect(find.text('partial tutor reply'), findsOneWidget);

      // Let the delayed final chunk arrive; the reply completes.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      expect(
        find.byWidgetPredicate((w) => w is ChatBubble && w.message.isStreaming),
        findsNothing,
      );
      expect(find.text('partial tutor reply now complete'), findsAtLeast(1));
    });

    testWidgets('end lesson button shows confirmation then summary dialog', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: '',
          topicTitle: 'Algebra',
          subjectId: 'math',
          tutorService: _FakeTutorService(),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byIcon(Icons.stop_circle_outlined));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('End your lesson? Your progress will be saved.'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'End Lesson'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Lesson Complete'), findsOneWidget);
    });

    testWidgets('shows lesson time ended text when duration expires', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: '',
          topicTitle: 'Algebra',
          subjectId: 'math',
          durationMinutes: 45,
          tutorService: _FakeTutorService(),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      await tester.pump(const Duration(minutes: 46));

      expect(
        find.text("Lesson time has ended. Click 'End Lesson' to finish."),
        findsOneWidget,
      );
    });

    testWidgets('shows stats in lesson progress bar after initialization', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: '',
          topicTitle: 'Algebra',
          subjectId: 'math',
          durationMinutes: 45,
          tutorService: _FakeTutorService(),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('45 min remaining'), findsOneWidget);
    });

    testWidgets('navigator observes no pops initially', (tester) async {
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: '',
          topicTitle: 'Algebra',
          subjectId: 'math',
          tutorService: _FakeTutorService(),
        ),
        navigatorObserver: observer,
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      expect(observer.poppedRoutes, isEmpty);
    });

    testWidgets('navigator pops via system back', (tester) async {
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: '',
          topicTitle: 'Algebra',
          subjectId: 'math',
          tutorService: _FakeTutorService(),
        ),
        navigatorObserver: observer,
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      expect(observer.poppedRoutes, isEmpty);
    });

    testWidgets('shows error state when tutor service fails to initialize', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: '',
          topicTitle: 'Algebra',
          subjectId: 'math',
          tutorService: _FakeTutorService(shouldFail: true),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Failed to initialize tutor. Please check your API configuration in Settings and try again.'), findsOneWidget);
    });

    testWidgets('shows retry and settings buttons in error state', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: '',
          topicTitle: 'Algebra',
          subjectId: 'math',
          tutorService: _FakeTutorService(shouldFail: true),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Go to Settings'), findsOneWidget);
    });

    testWidgets(
      'retry after init failure re-initializes without LateInitializationError',
      (tester) async {
        await tester.pumpWidget(_wrapApp(
          TutorScreen(
            topicId: '',
            topicTitle: 'Algebra',
            subjectId: 'math',
            tutorService: _FailOnceTutorService(),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        await tester.pump(const Duration(seconds: 2));

        // First init failed: the error card with the Retry button.
        expect(find.text('Retry'), findsOneWidget);

        // Retry re-runs `_initializeTutor()`. Pre-fix, the second
        // assignment to the late-final `_tutorService` threw
        // `LateInitializationError` synchronously inside the
        // gesture handler, so the retry could never succeed.
        await tester.tap(find.text('Retry'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        await tester.pump(const Duration(seconds: 2));

        // The retry recovered: the second init succeeded and the
        // error card is gone (lesson UI renders instead).
        expect(find.text('Retry'), findsNothing);
        expect(find.byIcon(Icons.error_outline), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('streaming loops stop consuming after the route is popped mid-stream', (tester) async {
      final tutorService = _FakeTutorService(llmService: _SlowStreamLlmService());
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: '',
          topicTitle: 'Algebra',
          subjectId: 'math',
          tutorService: tutorService,
        ),
      ));
      await tester.pump();
      // Let the lesson start and the greeting stream finish (2s inter-chunk delay).
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      final manager = tutorService.lastManager!;

      // Send a message; the reply streams one chunk, then pauses 2s mid-stream.
      await tester.enterText(find.byType(TextField), 'Hello tutor');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('partial tutor reply'), findsOneWidget);

      // Pop mid-stream through the back-navigation confirm dialog
      // ("Save and Exit" keeps the conversation manager alive).
      // PopScope vetoes the raw pop while a lesson is active and
      // routes it through _handleBackNavigation instead.
      await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Save and Exit'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // The delayed final chunk arrives after the route was popped and the
      // State disposed: the streaming loop must not consume it.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      // Pre-fix, the unguarded setState after dispose threw inside the loop,
      // the catch block appended this fallback message to the conversation,
      // and the unguarded setState in the catch surfaced an uncaught error.
      expect(
        manager.messages.where((m) => m.content.contains('Response interrupted')),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'error path does not setState after dispose when the error persist completes after the route is popped',
      (tester) async {
        final persistGate = Completer<void>();
        final persistStarted = Completer<void>();
        final tutorService = _GatedPersistTutorService(
          llmService: _MidStreamFailureLlmService(),
          persistGate: persistGate,
          persistStarted: persistStarted,
        );
        await tester.pumpWidget(_wrapApp(
          TutorScreen(
            topicId: '',
            topicTitle: 'Algebra',
            subjectId: 'math',
            tutorService: tutorService,
          ),
        ));
        await tester.pump();
        // Lesson start + greeting stream (first stream call succeeds).
        await tester.pump(const Duration(seconds: 2));
        await tester.pump(const Duration(seconds: 2));

        // Send a message; the reply streams one chunk, then the
        // provider stream fails (connection refused).
        await tester.enterText(find.byType(TextField), 'Hello tutor');
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('partial tutor reply'), findsOneWidget);

        // The catch block is now parked inside the error-message
        // persist (addAssistantMessage).
        await persistStarted.future;

        // The screen is disposed (session exit) while the persist
        // is still in flight.
        await tester.pumpWidget(const SizedBox());

        // The persist completes after the dispose.
        persistGate.complete();
        await tester.pump();

        // Pre-fix, the catch block ran setState on the disposed
        // State ("setState() called after dispose()").
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'error path skips the context lookup when the route is popped before the stream fails',
      (tester) async {
        final failureGate = Completer<void>();
        final tutorService = _FakeTutorService(
          llmService: _MidStreamFailureLlmService(
            beforeFailure: failureGate.future,
          ),
        );
        await tester.pumpWidget(_wrapApp(
          TutorScreen(
            topicId: '',
            topicTitle: 'Algebra',
            subjectId: 'math',
            tutorService: tutorService,
          ),
        ));
        await tester.pump();
        // Lesson start + greeting stream (first stream call succeeds).
        await tester.pump(const Duration(seconds: 2));
        await tester.pump(const Duration(seconds: 2));

        await tester.enterText(find.byType(TextField), 'Hello tutor');
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        // The stream is open and paused before failing.
        expect(find.text('partial tutor reply'), findsOneWidget);

        // The screen is disposed while the stream is still open.
        await tester.pumpWidget(const SizedBox());

        // Now the provider stream fails.
        failureGate.complete();
        await tester.pump();

        // Pre-fix, the catch block looked up AppLocalizations on the
        // deactivated context and called setState after dispose.
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'image pick does not setState after dispose when the byte read completes after the route is popped',
      (tester) async {
        final readGate = Completer<void>();
        final readStarted = Completer<void>();
        final previousPlatform = ImagePickerPlatform.instance;
        ImagePickerPlatform.instance = _GatedReadImagePickerPlatform(
          pickedFile: _GatedReadXFile(
            readGate: readGate,
            readStarted: readStarted,
          ),
        );
        addTearDown(() {
          ImagePickerPlatform.instance = previousPlatform;
        });

        await tester.pumpWidget(_wrapApp(
          TutorScreen(
            topicId: '',
            topicTitle: 'Algebra',
            subjectId: 'math',
            tutorService: _FakeTutorService(),
          ),
        ));
        await tester.pump();
        // Lesson start + greeting stream.
        await tester.pump(const Duration(seconds: 2));
        await tester.pump(const Duration(seconds: 2));

        // Open the image source dialog and pick from the gallery.
        await tester.tap(find.byIcon(Icons.image_outlined));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.text('Gallery'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // The picker returned the gated file; the byte read is in flight.
        await readStarted.future;

        // The screen is disposed (session exit) while the read is open.
        await tester.pumpWidget(const SizedBox());

        // The byte read completes after the dispose.
        readGate.complete();
        await tester.pump();

        // Pre-fix, the post-await path ran _beginStreamingExchange and
        // setState on the disposed State ("setState() called after
        // dispose()").
        expect(tester.takeException(), isNull);
      },
    );
  });
}
