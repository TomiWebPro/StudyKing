import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/services/conversation_phase.dart';
import 'package:studyking/features/teaching/services/prompts/prompts.dart';

const _testSubjectId = 'IB Physics';
const _testTopicTitle = 'Newton\'s Laws';
const _testDurationMinutes = 45;
const _testExerciseCount = 10;
const _testCorrectCount = 7;
const _testConfidenceRating = 0.75;

void main() {
  group('ConversationPromptSet', () {
    final promptSet = const ConversationPromptSet();

    test('provides all prompt builders', () {
      expect(promptSet.lessonPlan, isNotNull);
      expect(promptSet.tutorMessage, isNotNull);
      expect(promptSet.summary, isNotNull);
      expect(promptSet.evaluateExercise, isNotNull);
    });

    test('has defaultTemplates', () {
      expect(ConversationPromptSet.defaultTemplates, isA<ConversationPromptSet>());
    });

    test('lessonPlan returns PromptEntry with system and user prompts', () {
      final entry = promptSet.lessonPlan(
        subjectId: _testSubjectId,
        topicTitle: _testTopicTitle,
        durationMinutes: _testDurationMinutes,
      );
      expect(entry, isA<PromptEntry>());
      expect(entry.systemPrompt, isNotEmpty);
      expect(entry.userPrompt, isNotEmpty);
      expect(entry.userPrompt, contains(_testSubjectId));
      expect(entry.userPrompt, contains(_testTopicTitle));
      expect(entry.userPrompt, contains('$_testDurationMinutes minutes'));
    });

    test('tutorMessage returns PromptEntry with phase context', () {
      final entry = promptSet.tutorMessage(
        subjectId: _testSubjectId,
        topicTitle: _testTopicTitle,
        adaptivePace: 1.0,
        phase: ConversationPhase.teaching,
      );
      expect(entry, isA<PromptEntry>());
      expect(entry.systemPrompt, contains(_testSubjectId));
      expect(entry.userPrompt, contains('Teach the concept step by step'));
    });

    test('summary returns PromptEntry with lesson data', () {
      final entry = promptSet.summary(
        topicTitle: _testTopicTitle,
        exerciseCount: _testExerciseCount,
        correctCount: _testCorrectCount,
        confidenceRating: _testConfidenceRating,
        adaptivePace: 1.0,
      );
      expect(entry, isA<PromptEntry>());
      expect(entry.userPrompt, contains(_testTopicTitle));
      expect(entry.userPrompt, contains('$_testExerciseCount exercises'));
      expect(entry.userPrompt, contains('$_testCorrectCount correct'));
    });

    test('evaluateExercise returns PromptEntry', () {
      final entry = promptSet.evaluateExercise(
        question: 'What is 2+2?',
        studentAnswer: '4',
        subjectId: 'math',
        topicTitle: 'Addition',
      );
      expect(entry, isA<PromptEntry>());
      expect(entry.systemPrompt, contains('academic evaluator'));
      expect(entry.userPrompt, contains('What is 2+2?'));
      expect(entry.userPrompt, contains('4'));
    });
  });

  group('PromptTemplates (backward compat)', () {
    test('is a typedef for ConversationPromptSet', () {
      PromptTemplates templates = const ConversationPromptSet();
      expect(templates, isA<ConversationPromptSet>());
    });
  });

  group('lessonPlan prompt', () {
    final promptSet = const ConversationPromptSet();

    test('includes subject ID', () {
      final entry = promptSet.lessonPlan(
        subjectId: _testSubjectId,
        topicTitle: _testTopicTitle,
        durationMinutes: _testDurationMinutes,
      );
      expect(entry.userPrompt, contains(_testSubjectId));
    });

    test('includes topic title', () {
      final entry = promptSet.lessonPlan(
        subjectId: _testSubjectId,
        topicTitle: _testTopicTitle,
        durationMinutes: _testDurationMinutes,
      );
      expect(entry.userPrompt, contains(_testTopicTitle));
    });

    test('includes duration minutes', () {
      final entry = promptSet.lessonPlan(
        subjectId: _testSubjectId,
        topicTitle: _testTopicTitle,
        durationMinutes: _testDurationMinutes,
      );
      expect(entry.userPrompt, contains('$_testDurationMinutes minutes'));
    });

    test('returns valid JSON structure in prompt', () {
      final entry = promptSet.lessonPlan(
        subjectId: _testSubjectId,
        topicTitle: _testTopicTitle,
        durationMinutes: _testDurationMinutes,
      );
      expect(entry.userPrompt, contains('"goals"'));
      expect(entry.userPrompt, contains('"sections"'));
      expect(entry.userPrompt, contains('"checkpoints"'));
      expect(entry.userPrompt, contains('"estimatedDifficulty"'));
    });
  });

  group('tutorMessage prompt', () {
    final promptSet = const ConversationPromptSet();

    group('adaptivePace thresholds', () {
      test('accelerate when pace > 1.2', () {
        final entry = promptSet.tutorMessage(
          subjectId: _testSubjectId,
          topicTitle: _testTopicTitle,
          adaptivePace: 1.5,
          phase: ConversationPhase.teaching,
        );
        expect(entry.userPrompt, contains('Accelerate pace'));
      });

      test('slow down when pace < 0.8', () {
        final entry = promptSet.tutorMessage(
          subjectId: _testSubjectId,
          topicTitle: _testTopicTitle,
          adaptivePace: 0.5,
          phase: ConversationPhase.teaching,
        );
        expect(entry.userPrompt, contains('struggling'));
        expect(entry.userPrompt, contains('Slow down'));
      });
    });

    group('ConversationPhase branches', () {
      test('greeting phase', () {
        final entry = promptSet.tutorMessage(
          subjectId: _testSubjectId,
          topicTitle: _testTopicTitle,
          adaptivePace: 1.0,
          phase: ConversationPhase.greeting,
        );
        expect(entry.userPrompt, contains('Start the lesson warmly'));
      });

      test('teaching phase', () {
        final entry = promptSet.tutorMessage(
          subjectId: _testSubjectId,
          topicTitle: _testTopicTitle,
          adaptivePace: 1.0,
          phase: ConversationPhase.teaching,
        );
        expect(entry.userPrompt, contains('Teach the concept step by step'));
      });
    });
  });

  group('summary prompt', () {
    final promptSet = const ConversationPromptSet();

    test('includes topic title', () {
      final entry = promptSet.summary(
        topicTitle: _testTopicTitle,
        exerciseCount: _testExerciseCount,
        correctCount: _testCorrectCount,
        confidenceRating: _testConfidenceRating,
        adaptivePace: 1.0,
      );
      expect(entry.userPrompt, contains(_testTopicTitle));
    });

    test('includes confidence percentage', () {
      final entry = promptSet.summary(
        topicTitle: _testTopicTitle,
        exerciseCount: _testExerciseCount,
        correctCount: _testCorrectCount,
        confidenceRating: _testConfidenceRating,
        adaptivePace: 1.0,
      );
      expect(entry.userPrompt, contains('75%'));
    });

    test('handles zero confidence', () {
      final entry = promptSet.summary(
        topicTitle: _testTopicTitle,
        exerciseCount: 0,
        correctCount: 0,
        confidenceRating: 0.0,
        adaptivePace: 1.0,
      );
      expect(entry.userPrompt, contains('0%'));
    });

    test('handles full confidence', () {
      final entry = promptSet.summary(
        topicTitle: _testTopicTitle,
        exerciseCount: 1,
        correctCount: 1,
        confidenceRating: 1.0,
        adaptivePace: 1.0,
      );
      expect(entry.userPrompt, contains('100%'));
    });
  });

  group('system prompts', () {
    test('lessonPlan system prompt is a valid string', () {
      expect(lessonPlanSystemPrompt, isNotEmpty);
      expect(lessonPlanSystemPrompt, contains('curriculum designer'));
    });

    test('summarySystemPrompt is a valid string', () {
      expect(summarySystemPrompt, isNotEmpty);
      expect(summarySystemPrompt, contains('lesson notes'));
    });

    test('evaluationSystemPrompt is a valid string', () {
      expect(evaluationSystemPrompt, isNotEmpty);
      expect(evaluationSystemPrompt, contains('academic evaluator'));
    });
  });
}
