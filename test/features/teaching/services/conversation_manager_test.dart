import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/features/teaching/models/evaluation_result.dart';
import 'package:studyking/features/teaching/services/conversation_manager.dart';
import 'package:studyking/features/teaching/services/exercise_evaluator.dart';

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

class FakeExerciseEvaluator extends ExerciseEvaluator {
  FakeExerciseEvaluator()
      : super(
          llmService: FakeLlmService(),
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
    final lower = studentAnswer.toLowerCase();
    if (lower.contains('correct') || lower.contains('right') || lower.contains('yes')) {
      return EvaluationResult(score: 0.9, explanation: 'Correct answer.');
    } else if (lower.contains('wrong') || lower.contains('incorrect') || lower.contains('no')) {
      return EvaluationResult(score: 0.2, explanation: 'Incorrect answer.');
    }
    return EvaluationResult(score: 0.5, explanation: 'Partial answer.');
  }
}

class FixedClock extends Clock {
  final DateTime fixedTime;
  FixedClock(this.fixedTime);

  @override
  DateTime now() => fixedTime;
}

void main() {
  group('ConversationManager', () {
    late FakeLlmService llmService;
    late FakeExerciseEvaluator exerciseEvaluator;
    late ConversationManager manager;

    setUp(() {
      llmService = FakeLlmService();
      exerciseEvaluator = FakeExerciseEvaluator();
      manager = ConversationManager(
        llmService: llmService,
        modelId: 'test-model',
        sessionId: 'test-session',
        studentId: 'student-123',
        topicTitle: 'Algebra Basics',
        subjectId: 'math',
        topicId: 'topic-1',
        exerciseEvaluator: exerciseEvaluator,
      );
    });

    group('initial state', () {
      test('starts with default values', () {
        expect(manager.messages, isEmpty);
        expect(manager.phase, equals(ConversationPhase.greeting));
        expect(manager.exerciseCount, equals(0));
        expect(manager.correctCount, equals(0));
        expect(manager.adaptivePace, equals(1.0));
        expect(manager.studentId, equals('student-123'));
        expect(manager.sessionId, equals('test-session'));
        expect(manager.subjectId, equals('math'));
        expect(manager.topicId, equals('topic-1'));
        expect(manager.topicTitle, equals('Algebra Basics'));
      });
    });

    group('initialize', () {
      test('sets phase to greeting', () async {
        manager.phase = ConversationPhase.teaching;
        await manager.initialize();
        expect(manager.phase, equals(ConversationPhase.greeting));
      });
    });

    group('generateLessonPlan', () {
      test('returns LessonPlan from LLM service', () async {
        final plan = await manager.generateLessonPlan(
          durationMinutes: 45,
        );

        expect(plan.goals, isNotEmpty);
        expect(plan.sections, isNotEmpty);
        expect(plan.totalDurationMinutes, greaterThan(0));
        expect(manager.lessonPlan, isNotNull);
      });

      test('falls back to default plan on malformed JSON', () async {
        llmService.chatResponse = 'invalid json';
        final plan = await manager.generateLessonPlan(
          durationMinutes: 30,
        );

        expect(plan.goals, isNotEmpty);
        expect(plan.totalDurationMinutes, equals(30));
      });
    });

    group('sendMessage', () {
      setUp(() async {
        await manager.initialize();
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

      test('yields stream chunks to the caller', () async {
        final chunks = await manager.sendMessage('Hello').toList();

        expect(chunks.isNotEmpty, isTrue);
      });
    });

    group('exercise evaluation', () {
      setUp(() async {
        await manager.initialize();
      });

      test('evaluates correct response in exercise phase', () async {
        await manager.sendMessage('Hello').toList();
        manager.phase = ConversationPhase.exercise;

        await manager.sendMessage('correct').toList();

        expect(manager.exerciseCount, equals(1));
        expect(manager.correctCount, equals(1));
        expect(manager.adaptivePace, greaterThan(1.0));
        expect(manager.lastEvaluationResult, isNotNull);
        expect(manager.lastEvaluationResult!.score, greaterThanOrEqualTo(0.7));
      });

      test('evaluates incorrect response in exercise phase', () async {
        await manager.sendMessage('Hello').toList();
        manager.phase = ConversationPhase.exercise;

        await manager.sendMessage('wrong').toList();

        expect(manager.exerciseCount, equals(1));
        expect(manager.correctCount, equals(0));
        expect(manager.adaptivePace, lessThan(1.0));
        expect(manager.lastEvaluationResult!.score, lessThanOrEqualTo(0.3));
      });

      test('evaluates neutral response as neither correct nor incorrect', () async {
        await manager.sendMessage('Hello').toList();
        manager.phase = ConversationPhase.exercise;

        await manager.sendMessage('maybe').toList();

        expect(manager.exerciseCount, equals(1));
        expect(manager.correctCount, equals(0));
        expect(manager.adaptivePace, equals(1.0));
        expect(manager.lastEvaluationResult!.score, equals(0.5));
      });

      test('transitions to feedback after exercise evaluation', () async {
        await manager.sendMessage('Hello').toList();
        manager.phase = ConversationPhase.exercise;

        await manager.sendMessage('correct').toList();

        expect(manager.phase, equals(ConversationPhase.feedback));
      });

      test('adaptive pace caps at 1.5 maximum', () async {
        await manager.sendMessage('Hello').toList();

        for (int i = 0; i < 10; i++) {
          manager.phase = ConversationPhase.exercise;
          await manager.sendMessage('correct').toList();
          manager.phase = ConversationPhase.feedback;
          await manager.sendMessage('next').toList();
        }

        expect(manager.adaptivePace, lessThanOrEqualTo(1.5));
      });

      test('adaptive pace floors at 0.5 minimum', () async {
        await manager.sendMessage('Hello').toList();

        for (int i = 0; i < 10; i++) {
          manager.phase = ConversationPhase.exercise;
          await manager.sendMessage('wrong').toList();
          manager.phase = ConversationPhase.feedback;
          await manager.sendMessage('continue').toList();
        }

        expect(manager.adaptivePace, greaterThanOrEqualTo(0.5));
      });
    });

    group('phase transitions', () {
      setUp(() async {
        await manager.initialize();
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
      setUp(() async {
        await manager.initialize();
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
      setUp(() async {
        await manager.initialize();
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
      setUp(() async {
        await manager.initialize();
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
        await manager.initialize();

        final summary = await manager.generateSummary();

        expect(summary, equals('Lesson summary mock'));
      });
    });

    group('toSession', () {
      test('creates a TutorSession with manager state', () async {
        await manager.initialize();

        await manager.sendMessage('Hello').toList();
        manager.recordCorrectAnswer();
        manager.recordCorrectAnswer();
        manager.recordIncorrectAnswer();

        final session = manager.toSession();

        expect(session.id, equals('test-session'));
        expect(session.studentId, equals('student-123'));
        expect(session.subjectId, equals('math'));
        expect(session.topicId, equals('topic-1'));
        expect(session.topicTitle, equals('Algebra Basics'));
        expect(session.status, equals(SessionStatus.completed));
        expect(session.questionsAsked, equals(3));
        expect(session.questionsCorrect, equals(2));
        expect(session.topicsCovered, contains('Algebra Basics'));
      });

      test('session contains adaptive pace in tutor notes', () async {
        await manager.initialize();

        await manager.sendMessage('Hello').toList();
        manager.recordCorrectAnswer();

        final session = manager.toSession();
        expect(session.tutorNotes, contains('Adaptive pace'));
      });

      test('session uses clock for endTime', () async {
        await manager.initialize();

        final session = manager.toSession();
        expect(session.endTime, isNotNull);
        expect(session.endTime!.isAfter(session.startTime) || session.endTime == session.startTime, isTrue);
      });

      test('session includes lesson plan JSON', () async {
        await manager.generateLessonPlan(durationMinutes: 45);
        await manager.initialize();

        final session = manager.toSession();
        expect(session.lessonPlanJson, contains('goals'));
      });
    });

    group('clearMessages', () {
      test('removes all messages', () async {
        await manager.initialize();

        await manager.sendMessage('Hello').toList();
        expect(manager.messages.length, equals(2));

        manager.clearMessages();
        expect(manager.messages, isEmpty);
      });
    });

    group('clock injection', () {
      test('uses injected clock for sessionStartTime', () {
        final fixedNow = DateTime(2024, 1, 15, 10, 30);
        final fixedClock = FixedClock(fixedNow);

        final m = ConversationManager(
          llmService: llmService,
          modelId: 'test-model',
          sessionId: 'clock-test',
          studentId: 's1',
          topicTitle: 'Test',
          subjectId: 'test',
          topicId: 't1',
          exerciseEvaluator: exerciseEvaluator,
          clock: fixedClock,
        );

        expect(m.sessionStartTime, equals(fixedNow));
      });
    });
  });
}
