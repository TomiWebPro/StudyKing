import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/conversation_repository.dart';
import 'package:studyking/core/data/repositories/lesson_repository.dart';
import 'package:studyking/core/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/study_session_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/data/repositories/tutor_session_repository.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/data/repositories/subject_repository.dart';
import 'package:studyking/features/teaching/presentation/tutor_screen.dart';
import 'package:studyking/features/teaching/services/conversation_manager.dart';
import 'package:studyking/features/teaching/services/tutor_service.dart';
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
  }) async* {
    yield 'Mock tutor response for: $message';
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
            sessionRepository: StudySessionRepository(),
            subjectRepository: SubjectRepository(),
            conversationRepository: ConversationRepository(),
            tutorSessionRepository: TutorSessionRepository(),
          ),
          llmService: _FakeLlmService(),
          masteryService: MasteryGraphService(),
          modelId: 'test-model',
        );

  @override
  Future<ConversationManager> startLesson({
    required String studentId,
    required String subjectId,
    required String topicId,
    required String topicTitle,
    int durationMinutes = 45,
  }) async {
    final manager = ConversationManager(
      llmService: _FakeLlmService(),
      modelId: 'test-model',
      sessionId: 'test-session',
    );
    manager.initialize(
      studentId: studentId,
      topicTitle: topicTitle,
      subjectId: subjectId,
      topicId: topicId,
    );
    return manager;
  }

  @override
  Future<void> endLesson() async {}
}

Widget _wrapApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
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
  });
}
