import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/services/conversation_phase.dart';
import 'package:studyking/features/teaching/services/prompts/prompts.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

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

    test('defaultTemplates is const and equal to default constructor', () {
      const defaultSet = ConversationPromptSet();
      expect(identical(ConversationPromptSet.defaultTemplates, defaultSet), isTrue);
    });

    test('accepts custom version', () {
      const customSet = ConversationPromptSet(version: 3);
      const defaultSet = ConversationPromptSet();
      // version is not exposed publicly, but constructor accepts it
      expect(customSet, isA<ConversationPromptSet>());
      expect(defaultSet, isA<ConversationPromptSet>());
    });

    group('lessonPlan', () {
      test('returns PromptEntry with system and user prompts', () {
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

      test('works with minimal values', () {
        final entry = promptSet.lessonPlan(
          subjectId: 'Math',
          topicTitle: 'A',
          durationMinutes: 1,
        );
        expect(entry.userPrompt, contains('Math'));
        expect(entry.userPrompt, contains('1 minutes'));
      });

      test('works with long topic titles', () {
        final longTitle = 'A very long topic title that exceeds normal boundaries ' * 10;
        final entry = promptSet.lessonPlan(
          subjectId: _testSubjectId,
          topicTitle: longTitle,
          durationMinutes: _testDurationMinutes,
        );
        expect(entry.userPrompt, contains(longTitle));
      });

      test('system prompt is curriculum designer', () {
        final entry = promptSet.lessonPlan(
          subjectId: _testSubjectId,
          topicTitle: _testTopicTitle,
          durationMinutes: _testDurationMinutes,
        );
        expect(entry.systemPrompt, contains('curriculum designer'));
        expect(entry.systemPrompt, contains('JSON'));
      });
    });

    group('tutorMessage', () {
      test('returns PromptEntry with phase context', () {
        final entry = promptSet.tutorMessage(
          subjectId: _testSubjectId,
          topicTitle: _testTopicTitle,
          adaptivePace: 1.0,
          phase: ConversationPhase.teaching,
        );
        expect(entry, isA<PromptEntry>());
        expect(entry.systemPrompt, contains(_testSubjectId));
        expect(entry.systemPrompt, contains(_testTopicTitle));
        expect(entry.userPrompt, contains('Teach the concept step by step'));
      });

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

        test('steady pace when pace is exactly 1.0', () {
          final entry = promptSet.tutorMessage(
            subjectId: _testSubjectId,
            topicTitle: _testTopicTitle,
            adaptivePace: 1.0,
            phase: ConversationPhase.teaching,
          );
          expect(entry.userPrompt, contains('Maintain a steady teaching pace'));
        });

        test('steady pace when pace is at boundary 0.8', () {
          final entry = promptSet.tutorMessage(
            subjectId: _testSubjectId,
            topicTitle: _testTopicTitle,
            adaptivePace: 0.8,
            phase: ConversationPhase.teaching,
          );
          expect(entry.userPrompt, contains('Maintain a steady teaching pace'));
        });

        test('steady pace when pace is at boundary 1.2', () {
          final entry = promptSet.tutorMessage(
            subjectId: _testSubjectId,
            topicTitle: _testTopicTitle,
            adaptivePace: 1.2,
            phase: ConversationPhase.teaching,
          );
          expect(entry.userPrompt, contains('Maintain a steady teaching pace'));
        });

        test('accelerate when pace is just above 1.2', () {
          final entry = promptSet.tutorMessage(
            subjectId: _testSubjectId,
            topicTitle: _testTopicTitle,
            adaptivePace: 1.2000001,
            phase: ConversationPhase.teaching,
          );
          expect(entry.userPrompt, contains('Accelerate pace'));
        });

        test('slow down when pace is just below 0.8', () {
          final entry = promptSet.tutorMessage(
            subjectId: _testSubjectId,
            topicTitle: _testTopicTitle,
            adaptivePace: 0.7999999,
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

        test('exercise phase', () {
          final entry = promptSet.tutorMessage(
            subjectId: _testSubjectId,
            topicTitle: _testTopicTitle,
            adaptivePace: 1.0,
            phase: ConversationPhase.exercise,
          );
          expect(entry.userPrompt, contains('Give the student a practice question'));
        });

        test('feedback phase', () {
          final entry = promptSet.tutorMessage(
            subjectId: _testSubjectId,
            topicTitle: _testTopicTitle,
            adaptivePace: 1.0,
            phase: ConversationPhase.feedback,
          );
          expect(entry.userPrompt, contains('Provide constructive feedback'));
        });

        test('adaptiveReview phase', () {
          final entry = promptSet.tutorMessage(
            subjectId: _testSubjectId,
            topicTitle: _testTopicTitle,
            adaptivePace: 1.0,
            phase: ConversationPhase.adaptiveReview,
          );
          expect(entry.userPrompt, contains('student needs extra help'));
          expect(entry.userPrompt, contains('Re-explain the concept'));
        });

        test('closing phase', () {
          final entry = promptSet.tutorMessage(
            subjectId: _testSubjectId,
            topicTitle: _testTopicTitle,
            adaptivePace: 1.0,
            phase: ConversationPhase.closing,
          );
          expect(entry.userPrompt, contains('Wrap up the lesson'));
          expect(entry.userPrompt, contains('Summarize key points'));
        });
      });

      test('system prompt includes subject and topic', () {
        final entry = promptSet.tutorMessage(
          subjectId: 'IB Chemistry',
          topicTitle: 'Atomic Structure',
          adaptivePace: 1.0,
          phase: ConversationPhase.teaching,
        );
        expect(entry.systemPrompt, contains('IB Chemistry'));
        expect(entry.systemPrompt, contains('Atomic Structure'));
        expect(entry.systemPrompt, contains('AI tutor'));
      });
    });

    group('summary', () {
      test('returns PromptEntry with lesson data', () {
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

      test('handles fractional confidence rounding', () {
        final entry = promptSet.summary(
          topicTitle: _testTopicTitle,
          exerciseCount: 0,
          correctCount: 0,
          confidenceRating: 0.33333,
          adaptivePace: 1.0,
        );
        expect(entry.userPrompt, contains('33%'));
      });

      test('handles low confidence near zero', () {
        final entry = promptSet.summary(
          topicTitle: _testTopicTitle,
          exerciseCount: 0,
          correctCount: 0,
          confidenceRating: 0.001,
          adaptivePace: 1.0,
        );
        expect(entry.userPrompt, contains('0%'));
      });

      test('includes adaptive pace with one decimal', () {
        final entry = promptSet.summary(
          topicTitle: _testTopicTitle,
          exerciseCount: _testExerciseCount,
          correctCount: _testCorrectCount,
          confidenceRating: _testConfidenceRating,
          adaptivePace: 1.5,
        );
        expect(entry.userPrompt, contains('1.5x'));
      });

      test('includes adaptive pace with zero decimal', () {
        final entry = promptSet.summary(
          topicTitle: _testTopicTitle,
          exerciseCount: _testExerciseCount,
          correctCount: _testCorrectCount,
          confidenceRating: _testConfidenceRating,
          adaptivePace: 0.75,
        );
        expect(entry.userPrompt, contains('0.8x'));
      });

      test('includes adaptive pace for exact integer', () {
        final entry = promptSet.summary(
          topicTitle: _testTopicTitle,
          exerciseCount: _testExerciseCount,
          correctCount: _testCorrectCount,
          confidenceRating: _testConfidenceRating,
          adaptivePace: 2.0,
        );
        expect(entry.userPrompt, contains('2.0x'));
      });

      test('handles zero exercise count gracefully', () {
        final entry = promptSet.summary(
          topicTitle: _testTopicTitle,
          exerciseCount: 0,
          correctCount: 0,
          confidenceRating: 0.0,
          adaptivePace: 1.0,
        );
        expect(entry.userPrompt, contains('0 exercises'));
        expect(entry.userPrompt, contains('0 correct'));
      });

      test('handles correctCount exceeding exerciseCount', () {
        final entry = promptSet.summary(
          topicTitle: _testTopicTitle,
          exerciseCount: 5,
          correctCount: 10,
          confidenceRating: 1.0,
          adaptivePace: 1.0,
        );
        expect(entry.userPrompt, contains('5 exercises'));
        expect(entry.userPrompt, contains('10 correct'));
      });

      test('system prompt is summary', () {
        final entry = promptSet.summary(
          topicTitle: _testTopicTitle,
          exerciseCount: _testExerciseCount,
          correctCount: _testCorrectCount,
          confidenceRating: _testConfidenceRating,
          adaptivePace: 1.0,
        );
        expect(entry.systemPrompt, contains('lesson notes'));
      });
    });

    group('evaluateExercise', () {
      test('returns PromptEntry', () {
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

      test('includes subject ID and topic title in prompt', () {
        final entry = promptSet.evaluateExercise(
          question: 'What is F=ma?',
          studentAnswer: 'Force equals mass times acceleration',
          subjectId: _testSubjectId,
          topicTitle: _testTopicTitle,
        );
        expect(entry.userPrompt, contains(_testSubjectId));
        expect(entry.userPrompt, contains(_testTopicTitle));
      });

      test('includes JSON structure for evaluation', () {
        final entry = promptSet.evaluateExercise(
          question: 'Test question',
          studentAnswer: 'Test answer',
          subjectId: 'Math',
          topicTitle: 'Test',
        );
        expect(entry.userPrompt, contains('"score"'));
        expect(entry.userPrompt, contains('"explanation"'));
        expect(entry.userPrompt, contains('"partialCredit"'));
        expect(entry.userPrompt, contains('"conceptBreakdown"'));
      });

      test('works with empty answer', () {
        final entry = promptSet.evaluateExercise(
          question: 'What is 2+2?',
          studentAnswer: '',
          subjectId: 'Math',
          topicTitle: 'Addition',
        );
        expect(entry.userPrompt, contains('What is 2+2?'));
        expect(entry.userPrompt, contains('Student Answer:'));
      });

      test('works with empty question', () {
        final entry = promptSet.evaluateExercise(
          question: '',
          studentAnswer: '4',
          subjectId: 'Math',
          topicTitle: 'Addition',
        );
        expect(entry.userPrompt, contains('4'));
        expect(entry.userPrompt, contains('Question:'));
      });

      test('system prompt is evaluation', () {
        final entry = promptSet.evaluateExercise(
          question: 'Q?',
          studentAnswer: 'A',
          subjectId: 'S',
          topicTitle: 'T',
        );
        expect(entry.systemPrompt, contains('academic evaluator'));
        expect(entry.systemPrompt, contains('JSON'));
      });
    });
  });

  group('PromptEntry', () {
    test('stores systemPrompt and userPrompt', () {
      const entry = PromptEntry(
        systemPrompt: 'sys',
        userPrompt: 'user',
      );
      expect(entry.systemPrompt, 'sys');
      expect(entry.userPrompt, 'user');
    });

    test('accepts empty strings', () {
      const entry = PromptEntry(
        systemPrompt: '',
        userPrompt: '',
      );
      expect(entry.systemPrompt, '');
      expect(entry.userPrompt, '');
    });

    test('accepts long strings', () {
      final longString = 'A' * 10000;
      final entry = PromptEntry(
        systemPrompt: longString,
        userPrompt: longString,
      );
      expect(entry.systemPrompt.length, 10000);
      expect(entry.userPrompt.length, 10000);
    });
  });

  group('ConversationPromptSet', () {
    test('can be constructed with default params', () {
      const templates = ConversationPromptSet();
      expect(templates, isA<ConversationPromptSet>());
    });

    test('can be used as a valid instance', () {
      void takesConversationPromptSet(ConversationPromptSet set) {}
      const templates = ConversationPromptSet();
      expect(() => takesConversationPromptSet(templates), returnsNormally);
    });
  });

  group('system prompts', () {
    test('lessonPlan system prompt is a valid string', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(l10n.lessonPlanSystemPrompt, isNotEmpty);
      expect(l10n.lessonPlanSystemPrompt, contains('curriculum designer'));
      expect(l10n.lessonPlanSystemPrompt, contains('JSON'));
    });

    test('summarySystemPrompt is a valid string', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(l10n.summarySystemPrompt, isNotEmpty);
      expect(l10n.summarySystemPrompt, contains('lesson notes'));
    });

    test('evaluationSystemPrompt is a valid string', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(l10n.evaluationSystemPrompt, isNotEmpty);
      expect(l10n.evaluationSystemPrompt, contains('academic evaluator'));
      expect(l10n.evaluationSystemPrompt, contains('JSON'));
    });
  });
}
