import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/teaching/presentation/tutor_screen.dart';
import 'package:studyking/features/teaching/services/conversation_manager.dart';
import 'package:studyking/features/teaching/services/exercise_evaluator.dart';
import 'package:studyking/features/teaching/services/tutor_service.dart';
import 'package:studyking/features/teaching/data/models/evaluation_result.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeLlmService extends LlmService {
  _FakeLlmService()
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'test-key',
          ),
        );

  @override
  Future<String> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async {
    return '{"goals":["goal1"],"sections":[{"title":"intro","duration":10,"type":"explanation"}],"checkpoints":["cp1"],"estimatedDifficulty":2}';
  }

  @override
  Stream<String> chatStream({
    required String message,
    required String modelId,
    String? systemPrompt,
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async* {
    yield 'Mock tutor response for: $message';
  }
}

class _FakeExerciseEvaluator extends ExerciseEvaluator {
  _FakeExerciseEvaluator()
      : super(
          llmService: _FakeLlmService(),
          modelId: 'test-model',
        );

  @override
  Future<EvaluationResult> evaluate({
    required String question,
    required String studentAnswer,
    required String subjectId,
    required String topicTitle,
    String? systemPrompt,
    String? userPrompt,
  }) async {
    return EvaluationResult(score: 0.8, explanation: 'Good work.');
  }
}

class _FakeTutorService extends TutorService {
  _FakeTutorService()
      : super(
          database: DatabaseService(
            topicRepository: TopicRepository(),
            questionRepository: QuestionRepository(),
            attemptRepository: AttemptRepository(),
            lessonRepository: LessonRepository(),
            sessionRepository: SessionRepository(),
            subjectRepository: SubjectRepository(),
            conversationRepository: ConversationRepository(),
            tutorSessionRepository: TutorSessionRepository(),
          ),
          llmService: _FakeLlmService(),
          masteryService: MasteryGraphService(),
          modelId: 'test-model',
          exerciseEvaluator: _FakeExerciseEvaluator(),
          conversationRepository: ConversationRepository(),
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
    final manager = ConversationManager(
      llmService: _FakeLlmService(),
      modelId: 'test-model',
      sessionId: 'test-session',
      studentId: studentId,
      topicTitle: topicTitle,
      subjectId: subjectId,
      topicId: topicId,
      exerciseEvaluator: _FakeExerciseEvaluator(),
    );
    await manager.initialize();
    return manager;
  }

  @override
  Future<void> endLesson() async {}
}

Widget _wrapApp(Widget child) {
  return ProviderScope(
    overrides: [
      studentIdValueProvider.overrideWith((ref) => 'test-student-id'),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  group('TutorScreen', () {
    testWidgets('shows loading indicator before initialization', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: 'topic-1',
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
          topicId: 'topic-1',
          topicTitle: 'Algebra Basics',
          subjectId: 'math',
          tutorService: _FakeTutorService(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Algebra Basics'), findsAtLeast(1));
    });

    testWidgets('shows LessonProgressBar after initialization', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          subjectId: 'math',
          durationMinutes: 45,
          tutorService: _FakeTutorService(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders chat messages from manager', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          subjectId: 'math',
          tutorService: _FakeTutorService(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows end lesson button after initialization', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          subjectId: 'math',
          tutorService: _FakeTutorService(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.stop_circle_outlined), findsOneWidget);
    });

    testWidgets('displays ConversationInput widget', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          subjectId: 'math',
          tutorService: _FakeTutorService(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('mic button is present for voice input', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          subjectId: 'math',
          tutorService: _FakeTutorService(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.mic_none), findsOneWidget);
    });

    testWidgets('image picker button shows SnackBar', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          subjectId: 'math',
          tutorService: _FakeTutorService(),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.image_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Coming soon'), findsOneWidget);
    });

    testWidgets('sending a message adds user and tutor messages to chat', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          subjectId: 'math',
          tutorService: _FakeTutorService(),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello tutor');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Hello tutor'), findsOneWidget);
    });

    testWidgets('end lesson button shows confirmation then summary dialog', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          subjectId: 'math',
          tutorService: _FakeTutorService(),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.stop_circle_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('End your lesson? Your progress will be saved.'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'End Lesson'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Lesson Complete'), findsOneWidget);
    });

    testWidgets('shows lesson time ended text when duration expires', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          subjectId: 'math',
          durationMinutes: 45,
          tutorService: _FakeTutorService(),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(minutes: 46));

      expect(
        find.text("Lesson time has ended. Click 'End Lesson' to finish."),
        findsOneWidget,
      );
    });

    testWidgets('shows stats in lesson progress bar after initialization', (tester) async {
      await tester.pumpWidget(_wrapApp(
        TutorScreen(
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          subjectId: 'math',
          durationMinutes: 45,
          tutorService: _FakeTutorService(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('45 min remaining'), findsOneWidget);
    });
  });
}
