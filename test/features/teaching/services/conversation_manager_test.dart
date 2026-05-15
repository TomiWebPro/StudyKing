import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/conversation_message_model.dart';
import 'package:studyking/core/data/models/tutor_session_model.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/teaching/services/conversation_manager.dart';

class FakeLlmService extends LlmService {
  FakeLlmService()
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: '',
          ),
        );

  String chatResponse = '{"goals":["goal1"],"sections":[{"title":"intro","duration":10,"type":"explanation"}],"checkpoints":["cp1"],"estimatedDifficulty":2}';
  String streamResponse = 'Mock tutor response';
  String summaryResponse = 'Lesson summary mock';

  @override
  Future<String> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async {
    if (message.contains('Summarize what was covered')) {
      return summaryResponse;
    }
    return chatResponse;
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
    yield streamResponse;
  }
}

void main() {
  group('ConversationManager', () {
    late FakeLlmService llmService;
    late ConversationManager manager;

    setUp(() {
      llmService = FakeLlmService();
      manager = ConversationManager(
        llmService: llmService,
        modelId: 'test-model',
        sessionId: 'test-session',
      );
    });

    group('initial state', () {
      test('starts with default values', () {
        expect(manager.messages, isEmpty);
        expect(manager.phase, equals(ConversationPhase.greeting));
        expect(manager.exerciseCount, equals(0));
        expect(manager.correctCount, equals(0));
        expect(manager.adaptivePace, equals(1.0));
        expect(manager.studentId, equals('anonymous'));
        expect(manager.sessionId, equals('test-session'));
      });

      test('initialize sets properties correctly', () {
        manager.initialize(
          studentId: 'student-123',
          topicTitle: 'Algebra Basics',
          subjectId: 'math',
          topicId: 'topic-1',
        );

        expect(manager.studentId, equals('student-123'));
        expect(manager.phase, equals(ConversationPhase.greeting));
      });
    });

    group('generateLessonPlan', () {
      test('returns lesson plan JSON from LLM service', () async {
        manager.initialize(
          studentId: 's1',
          topicTitle: 'Algebra',
          subjectId: 'math',
          topicId: 't1',
        );

        final plan = await manager.generateLessonPlan(
          topicTitle: 'Algebra',
          subjectId: 'math',
          durationMinutes: 45,
        );

        expect(plan, contains('goals'));
        expect(plan, contains('sections'));
        expect(plan, contains('checkpoints'));
      });
    });

    group('sendMessage', () {
      setUp(() {
        manager.initialize(
          studentId: 's1',
          topicTitle: 'Math',
          subjectId: 'math',
          topicId: 't1',
        );
      });

      test('adds user and tutor messages to the list', () async {
        await manager.sendMessage('Hello').toList();

        expect(manager.messages.length, equals(2));
        expect(manager.messages[0].role, equals(MessageRole.student));
        expect(manager.messages[0].content, equals('Hello'));
        expect(manager.messages[1].role, equals(MessageRole.tutor));
        expect(manager.messages[1].content, contains('Mock tutor response'));
      });

      test('transitions from greeting to teaching phase on first message', () async {
        expect(manager.phase, equals(ConversationPhase.greeting));

        await manager.sendMessage('I am ready to learn').toList();

        expect(manager.phase, equals(ConversationPhase.teaching));
      });

      test('marks streaming message and then marks as complete', () async {
        await manager.sendMessage('Hello').toList();

        final lastMsg = manager.messages.last;
        expect(lastMsg.isStreaming, isFalse);
        expect(lastMsg.tokenCount, greaterThan(0));
      });

      test('yields stream chunks to the caller', () async {
        final chunks = await manager.sendMessage('Hello').toList();

        expect(chunks.isNotEmpty, isTrue);
      });
    });

    group('exercise detection', () {
      setUp(() {
        manager.initialize(
          studentId: 's1',
          topicTitle: 'Math',
          subjectId: 'math',
          topicId: 't1',
        );
      });

      test('detects exercise keyword in user message', () async {
        await manager.sendMessage('Hello').toList();
        expect(manager.phase, equals(ConversationPhase.teaching));

        await manager.sendMessage('Give me an exercise please').toList();

        expect(manager.phase, equals(ConversationPhase.exercise));
      });

      test('detects practice keyword', () async {
        await manager.sendMessage('Hello').toList();

        await manager.sendMessage('I want to practice').toList();

        expect(manager.phase, equals(ConversationPhase.exercise));
      });

      test('detects quiz keyword', () async {
        await manager.sendMessage('Hello').toList();

        await manager.sendMessage('Quiz me').toList();

        expect(manager.phase, equals(ConversationPhase.exercise));
      });

      test('does not trigger exercise for normal messages', () async {
        await manager.sendMessage('Hello').toList();

        await manager.sendMessage("Let's continue learning").toList();

        expect(manager.phase, equals(ConversationPhase.teaching));
      });
    });

    group('exercise evaluation', () {
      setUp(() {
        manager.initialize(
          studentId: 's1',
          topicTitle: 'Math',
          subjectId: 'math',
          topicId: 't1',
        );
      });

      test('evaluates correct response in exercise phase', () async {
        await manager.sendMessage('Hello').toList();
        await manager.sendMessage('exercise').toList();

        await manager.sendMessage('correct').toList();

        expect(manager.exerciseCount, equals(1));
        expect(manager.correctCount, equals(1));
        expect(manager.adaptivePace, greaterThan(1.0));
      });

      test('evaluates right keyword as correct', () async {
        await manager.sendMessage('Hello').toList();
        await manager.sendMessage('exercise').toList();

        await manager.sendMessage('right').toList();

        expect(manager.correctCount, equals(1));
      });

      test('evaluates yes keyword as correct', () async {
        await manager.sendMessage('Hello').toList();
        await manager.sendMessage('exercise').toList();

        await manager.sendMessage('yes').toList();

        expect(manager.correctCount, equals(1));
      });

      test('evaluates incorrect response in exercise phase', () async {
        await manager.sendMessage('Hello').toList();
        await manager.sendMessage('exercise').toList();

        await manager.sendMessage('wrong').toList();

        expect(manager.exerciseCount, equals(1));
        expect(manager.correctCount, equals(0));
        expect(manager.adaptivePace, lessThan(1.0));
      });

      test('evaluates "I don\'t know" as incorrect', () async {
        await manager.sendMessage('Hello').toList();
        await manager.sendMessage('exercise').toList();

        await manager.sendMessage("I don't know").toList();

        expect(manager.correctCount, equals(0));
      });

      test('evaluates neutral response as neither correct nor incorrect', () async {
        await manager.sendMessage('Hello').toList();
        await manager.sendMessage('exercise').toList();

        await manager.sendMessage('maybe').toList();

        expect(manager.exerciseCount, equals(1));
        expect(manager.correctCount, equals(0));
        expect(manager.adaptivePace, equals(1.0));
      });

      test('transitions to feedback after exercise evaluation', () async {
        await manager.sendMessage('Hello').toList();
        await manager.sendMessage('exercise').toList();

        await manager.sendMessage('correct').toList();

        expect(manager.phase, equals(ConversationPhase.feedback));
      });

      test('adaptive pace caps at 1.5 maximum', () async {
        await manager.sendMessage('Hello').toList();
        await manager.sendMessage('exercise').toList();

        for (int i = 0; i < 10; i++) {
          await manager.sendMessage('correct').toList();
          await manager.sendMessage('next').toList();
        }

        expect(manager.adaptivePace, lessThanOrEqualTo(1.5));
      });

      test('adaptive pace floors at 0.5 minimum', () async {
        await manager.sendMessage('Hello').toList();
        await manager.sendMessage('exercise').toList();

        for (int i = 0; i < 10; i++) {
          await manager.sendMessage('wrong').toList();
          await manager.sendMessage('continue').toList();
        }

        expect(manager.adaptivePace, greaterThanOrEqualTo(0.5));
      });

      test('two consecutive incorrect sets consecutiveIncorrect to 2', () async {
        await manager.sendMessage('Hello').toList();
        await manager.sendMessage('exercise').toList();
        await manager.sendMessage('wrong').toList();
        await manager.sendMessage('practice').toList();
        await manager.sendMessage('no').toList();
        expect(manager.phase, equals(ConversationPhase.feedback));

        await manager.sendMessage('continue learning').toList();
        expect(manager.phase, equals(ConversationPhase.teaching));
      });

      test('sendMessage from feedback with consecutiveIncorrect >= 2 transitions through adaptiveReview before detectExerciseRequest', () async {
        await manager.sendMessage('Hello').toList();
        await manager.sendMessage('exercise').toList();
        await manager.sendMessage('wrong').toList();
        await manager.sendMessage('practice').toList();
        await manager.sendMessage('no').toList();

        await manager.sendMessage('exercise please').toList();
        expect(manager.phase, equals(ConversationPhase.exercise));
      });
    });

    group('phase transitions', () {
      setUp(() {
        manager.initialize(
          studentId: 's1',
          topicTitle: 'Math',
          subjectId: 'math',
          topicId: 't1',
        );
      });

      test('transitionToExercise sets phase to exercise', () {
        manager.transitionToExercise();
        expect(manager.phase, equals(ConversationPhase.exercise));
      });

      test('transitionToClosing sets phase to closing', () {
        manager.transitionToClosing();
        expect(manager.phase, equals(ConversationPhase.closing));
      });
    });

    group('recordCorrectAnswer', () {
      setUp(() {
        manager.initialize(
          studentId: 's1',
          topicTitle: 'Math',
          subjectId: 'math',
          topicId: 't1',
        );
      });

      test('increments correct count and exercise count', () {
        manager.recordCorrectAnswer();
        expect(manager.correctCount, equals(1));
        expect(manager.exerciseCount, equals(1));
      });

      test('increases adaptive pace', () {
        final before = manager.adaptivePace;
        manager.recordCorrectAnswer();
        expect(manager.adaptivePace, greaterThan(before));
      });
    });

    group('recordIncorrectAnswer', () {
      setUp(() {
        manager.initialize(
          studentId: 's1',
          topicTitle: 'Math',
          subjectId: 'math',
          topicId: 't1',
        );
      });

      test('increments exercise count but not correct count', () {
        manager.recordIncorrectAnswer();
        expect(manager.exerciseCount, equals(1));
        expect(manager.correctCount, equals(0));
      });

      test('decreases adaptive pace', () {
        final before = manager.adaptivePace;
        manager.recordIncorrectAnswer();
        expect(manager.adaptivePace, lessThan(before));
      });
    });

    group('confidenceRating', () {
      setUp(() {
        manager.initialize(
          studentId: 's1',
          topicTitle: 'Math',
          subjectId: 'math',
          topicId: 't1',
        );
      });

      test('returns 0.5 when no exercises have been done', () {
        expect(manager.confidenceRating, equals(0.5));
      });

      test('increases with more correct answers', () {
        manager.recordCorrectAnswer();
        expect(manager.confidenceRating, greaterThan(0.5));
      });

      test('decreases with incorrect answers', () {
        manager.recordCorrectAnswer();
        final afterCorrect = manager.confidenceRating;
        manager.recordIncorrectAnswer();
        expect(manager.confidenceRating, lessThan(afterCorrect));
      });

      test('stays within 0.0 to 1.0 range', () {
        for (int i = 0; i < 20; i++) {
          manager.recordCorrectAnswer();
        }
        expect(manager.confidenceRating, greaterThanOrEqualTo(0.0));
        expect(manager.confidenceRating, lessThanOrEqualTo(1.0));

        for (int i = 0; i < 20; i++) {
          manager.recordIncorrectAnswer();
        }
        expect(manager.confidenceRating, greaterThanOrEqualTo(0.0));
        expect(manager.confidenceRating, lessThanOrEqualTo(1.0));
      });
    });

    group('generateSummary', () {
      test('returns summary from LLM service', () async {
        manager.initialize(
          studentId: 's1',
          topicTitle: 'Math',
          subjectId: 'math',
          topicId: 't1',
        );

        final summary = await manager.generateSummary();

        expect(summary, equals('Lesson summary mock'));
      });
    });

    group('toSession', () {
      test('creates a TutorSession with manager state', () async {
        manager.initialize(
          studentId: 's1',
          topicTitle: 'Algebra',
          subjectId: 'math',
          topicId: 't1',
        );

        await manager.sendMessage('Hello').toList();
        manager.recordCorrectAnswer();
        manager.recordCorrectAnswer();
        manager.recordIncorrectAnswer();

        final session = manager.toSession();

        expect(session.id, equals('test-session'));
        expect(session.studentId, equals('s1'));
        expect(session.subjectId, equals('math'));
        expect(session.topicId, equals('t1'));
        expect(session.topicTitle, equals('Algebra'));
        expect(session.status, equals(SessionStatus.completed));
        expect(session.questionsAsked, equals(3));
        expect(session.questionsCorrect, equals(2));
        expect(session.topicsCovered, contains('Algebra'));
      });

      test('session contains adaptive pace in tutor notes', () async {
        manager.initialize(
          studentId: 's1',
          topicTitle: 'Math',
          subjectId: 'math',
          topicId: 't1',
        );

        await manager.sendMessage('Hello').toList();
        manager.recordCorrectAnswer();

        final session = manager.toSession();
        expect(session.tutorNotes, contains('Adaptive pace'));
      });
    });

    group('clearMessages', () {
      test('removes all messages', () async {
        manager.initialize(
          studentId: 's1',
          topicTitle: 'Math',
          subjectId: 'math',
          topicId: 't1',
        );

        await manager.sendMessage('Hello').toList();
        expect(manager.messages.length, equals(2));

        manager.clearMessages();
        expect(manager.messages, isEmpty);
      });
    });


  });
}
