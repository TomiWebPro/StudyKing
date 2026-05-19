import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/voice_service.dart';
import 'package:studyking/features/teaching/teaching.dart';

void main() {
  group('teaching barrel', () {
    test('ConversationMessage can be constructed with properties', () {
      final msg = ConversationMessage(
        id: 'msg1',
        sessionId: 'session1',
        role: MessageRole.tutor,
        type: MessageType.text,
        content: 'Hello student',
        timestamp: DateTime(2024, 1, 1),
        tokenCount: 42,
      );
      expect(msg.role, MessageRole.tutor);
      expect(msg.content, 'Hello student');
      expect(msg.tokenCount, 42);
    });

    test('TutorSession can be constructed and computed properties work', () {
      final session = TutorSession(
        id: 's1',
        studentId: 'stu1',
        subjectId: 'sub1',
        topicId: 't1',
        topicTitle: 'Algebra',
        startTime: DateTime(2024, 1, 1),
        questionsAsked: 10,
        questionsCorrect: 7,
      );
      expect(session.accuracy, 0.7);
      expect(session.topicTitle, 'Algebra');
    });

    test('ConversationRepository can be constructed', () {
      final repo = ConversationRepository();
      expect(repo, isNotNull);
    });

    test('TutorSessionRepository can be constructed', () {
      final repo = TutorSessionRepository();
      expect(repo, isNotNull);
    });

    test('EvaluationResult can be constructed with score and explanation', () {
      final result = EvaluationResult(
        score: 0.85,
        explanation: 'Good understanding shown',
      );
      expect(result.score, 0.85);
      expect(result.explanation, contains('understanding'));
    });

    test('LessonSection can be constructed with properties', () {
      final section = LessonSection(
        title: 'Introduction',
        durationMinutes: 10,
        type: LessonSectionType.explanation,
      );
      expect(section.title, 'Introduction');
      expect(section.type, LessonSectionType.explanation);
    });

    test('LessonPlan defaultPlan creates sections', () {
      final plan = LessonPlan.defaultPlan(30);
      expect(plan.goals, isNotEmpty);
      expect(plan.sections.length, 3);
      expect(plan.totalDurationMinutes, greaterThan(0));
    });

    test('LessonPlan fromJson parses valid JSON', () {
      final plan = LessonPlan.fromJson('''
        {
          "goals": ["Understand algebra"],
          "sections": [
            {"title": "Intro", "duration": 5, "type": "explanation"},
            {"title": "Main", "duration": 20, "type": "exercise"}
          ],
          "checkpoints": ["Start"],
          "estimatedDifficulty": 3
        }
      ''');
      expect(plan, isNotNull);
      expect(plan!.goals.first, 'Understand algebra');
    });

    test('ConversationPhase has expected values', () {
      expect(ConversationPhase.values, containsAll([
        ConversationPhase.greeting,
        ConversationPhase.teaching,
        ConversationPhase.exercise,
        ConversationPhase.feedback,
        ConversationPhase.adaptiveReview,
        ConversationPhase.closing,
      ]));
    });

    test('ConversationManager is a type', () {
      expect(ConversationManager, isA<Type>());
    });

    test('ExerciseEvaluator is a type', () {
      expect(ExerciseEvaluator, isA<Type>());
    });

    test('TutorService is a type', () {
      expect(TutorService, isA<Type>());
    });

    test('ConversationPromptSet can be constructed with locale', () {
      final prompts = ConversationPromptSet(localeName: 'en');
      expect(prompts.version, 1);
      expect(prompts.localeName, 'en');
    });

    test('PromptEntry can be const-constructed', () {
      const entry = PromptEntry(
        systemPrompt: 'You are a tutor',
        userPrompt: 'Teach math',
      );
      expect(entry.systemPrompt, 'You are a tutor');
      expect(entry.userPrompt, 'Teach math');
    });

    test('ChatBubble can be constructed', () {
      final bubble = ChatBubble(
        message: ConversationMessage(
          id: 'm1',
          sessionId: 's1',
          role: MessageRole.tutor,
          type: MessageType.text,
          content: 'Hi',
          timestamp: DateTime(2024, 1, 1),
        ),
      );
      expect(bubble, isA<ChatBubble>());
    });

    test('LessonProgressBar can be constructed', () {
      final bar = LessonProgressBar(
        elapsedMinutes: 10,
        plannedDurationMinutes: 30,
        exerciseCount: 5,
        correctCount: 4,
        topicTitle: 'Algebra',
      );
      expect(bar, isA<LessonProgressBar>());
    });

    test('VoiceBar can be constructed', () {
      final bar = VoiceBar(
        controller: VoiceService(),
        onTranscriptionSubmitted: (_) {},
      );
      expect(bar, isA<VoiceBar>());
    });

    test('TutorScreen can be constructed', () {
      final screen = TutorScreen(
        topicId: 't1',
        topicTitle: 'Algebra',
        subjectId: 's1',
        durationMinutes: 30,
      );
      expect(screen, isA<TutorScreen>());
    });
  });
}
