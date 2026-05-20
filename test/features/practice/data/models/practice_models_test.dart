import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/practice/data/models/practice_models.dart';

void main() {
  group('PracticeAnswerRecord', () {
    group('constructor', () {
      test('creates record with correct values', () {
        final record = PracticeAnswerRecord(
          questionId: 'q1',
          questionType: QuestionType.singleChoice,
          isCorrect: true,
          timeSpent: const Duration(seconds: 30),
          userAnswer: 'Paris',
        );

        expect(record.questionId, 'q1');
        expect(record.questionType, QuestionType.singleChoice);
        expect(record.isCorrect, isTrue);
        expect(record.timeSpent, const Duration(seconds: 30));
        expect(record.userAnswer, 'Paris');
      });

      test('creates record with incorrect answer', () {
        final record = PracticeAnswerRecord(
          questionId: 'q2',
          questionType: QuestionType.typedAnswer,
          isCorrect: false,
          timeSpent: const Duration(seconds: 15),
          userAnswer: 'London',
        );

        expect(record.isCorrect, isFalse);
        expect(record.questionId, 'q2');
      });

      test('creates record with multiChoice question type', () {
        final record = PracticeAnswerRecord(
          questionId: 'q3',
          questionType: QuestionType.multiChoice,
          isCorrect: true,
          timeSpent: const Duration(seconds: 20),
          userAnswer: 'A,B,C',
        );

        expect(record.questionType, QuestionType.multiChoice);
        expect(record.userAnswer, 'A,B,C');
      });

      test('creates record with canvas question type', () {
        final record = PracticeAnswerRecord(
          questionId: 'q4',
          questionType: QuestionType.canvas,
          isCorrect: false,
          timeSpent: const Duration(seconds: 120),
          userAnswer: 'drawing_data',
        );

        expect(record.questionType, QuestionType.canvas);
      });

      test('creates record with essay question type', () {
        final record = PracticeAnswerRecord(
          questionId: 'q5',
          questionType: QuestionType.essay,
          isCorrect: true,
          timeSpent: const Duration(minutes: 5),
          userAnswer: 'Long essay response text',
        );

        expect(record.questionType, QuestionType.essay);
      });

      test('creates record with stepByStep question type', () {
        final record = PracticeAnswerRecord(
          questionId: 'q6',
          questionType: QuestionType.stepByStep,
          isCorrect: true,
          timeSpent: const Duration(seconds: 45),
          userAnswer: 'Step 1: ...',
        );

        expect(record.questionType, QuestionType.stepByStep);
      });

      test('creates record with mathExpression question type', () {
        final record = PracticeAnswerRecord(
          questionId: 'q7',
          questionType: QuestionType.mathExpression,
          isCorrect: false,
          timeSpent: const Duration(seconds: 60),
          userAnswer: 'x^2 + y^2 = r^2',
        );

        expect(record.questionType, QuestionType.mathExpression);
      });

      test('creates record with graphDrawing question type', () {
        final record = PracticeAnswerRecord(
          questionId: 'q8',
          questionType: QuestionType.graphDrawing,
          isCorrect: true,
          timeSpent: const Duration(seconds: 90),
          userAnswer: 'graph_coordinates',
        );

        expect(record.questionType, QuestionType.graphDrawing);
      });

      test('creates record with fileUpload question type', () {
        final record = PracticeAnswerRecord(
          questionId: 'q9',
          questionType: QuestionType.fileUpload,
          isCorrect: false,
          timeSpent: const Duration(seconds: 10),
          userAnswer: 'file:///path/to/upload.pdf',
        );

        expect(record.questionType, QuestionType.fileUpload);
      });

      test('creates record with audioRecording question type', () {
        final record = PracticeAnswerRecord(
          questionId: 'q10',
          questionType: QuestionType.audioRecording,
          isCorrect: true,
          timeSpent: const Duration(seconds: 180),
          userAnswer: 'audio_recording_id',
        );

        expect(record.questionType, QuestionType.audioRecording);
      });
    });

    group('timeSpent edge cases', () {
      test('creates record with zero duration', () {
        final record = PracticeAnswerRecord(
          questionId: 'q-zero',
          questionType: QuestionType.singleChoice,
          isCorrect: true,
          timeSpent: Duration.zero,
          userAnswer: 'A',
        );

        expect(record.timeSpent, Duration.zero);
      });

      test('creates record with very large duration', () {
        final record = PracticeAnswerRecord(
          questionId: 'q-long',
          questionType: QuestionType.essay,
          isCorrect: true,
          timeSpent: const Duration(hours: 24),
          userAnswer: 'Extended response',
        );

        expect(record.timeSpent, const Duration(hours: 24));
      });

      test('creates record with microseconds precision', () {
        final record = PracticeAnswerRecord(
          questionId: 'q-precise',
          questionType: QuestionType.typedAnswer,
          isCorrect: true,
          timeSpent: const Duration(milliseconds: 1500),
          userAnswer: 'precise',
        );

        expect(record.timeSpent, const Duration(milliseconds: 1500));
      });
    });

    group('userAnswer edge cases', () {
      test('creates record with empty user answer', () {
        final record = PracticeAnswerRecord(
          questionId: 'q-empty',
          questionType: QuestionType.typedAnswer,
          isCorrect: false,
          timeSpent: const Duration(seconds: 5),
          userAnswer: '',
        );

        expect(record.userAnswer, isEmpty);
      });

      test('creates record with very long user answer', () {
        final longAnswer = 'A' * 10000;
        final record = PracticeAnswerRecord(
          questionId: 'q-long-answer',
          questionType: QuestionType.essay,
          isCorrect: true,
          timeSpent: const Duration(minutes: 10),
          userAnswer: longAnswer,
        );

        expect(record.userAnswer.length, 10000);
        expect(record.userAnswer, longAnswer);
      });

      test('creates record with special characters in answer', () {
        final record = PracticeAnswerRecord(
          questionId: 'q-special',
          questionType: QuestionType.typedAnswer,
          isCorrect: true,
          timeSpent: const Duration(seconds: 30),
          userAnswer: 'Café résumé ñoño 中文 español',
        );

        expect(record.userAnswer, 'Café résumé ñoño 中文 español');
      });
    });

    group('questionId edge cases', () {
      test('creates record with very long question id', () {
        final longId = 'id_${'x' * 500}';
        final record = PracticeAnswerRecord(
          questionId: longId,
          questionType: QuestionType.singleChoice,
          isCorrect: false,
          timeSpent: const Duration(seconds: 10),
          userAnswer: 'Answer',
        );

        expect(record.questionId, longId);
      });

      test('creates record with empty question id', () {
        final record = PracticeAnswerRecord(
          questionId: '',
          questionType: QuestionType.singleChoice,
          isCorrect: true,
          timeSpent: Duration.zero,
          userAnswer: 'Answer',
        );

        expect(record.questionId, isEmpty);
      });
    });

    group('isCorrect edge cases', () {
      test('creates record with isCorrect: true', () {
        final record = PracticeAnswerRecord(
          questionId: 'q-true',
          questionType: QuestionType.singleChoice,
          isCorrect: true,
          timeSpent: Duration.zero,
          userAnswer: 'A',
        );

        expect(record.isCorrect, isTrue);
      });

      test('creates record with isCorrect: false', () {
        final record = PracticeAnswerRecord(
          questionId: 'q-false',
          questionType: QuestionType.singleChoice,
          isCorrect: false,
          timeSpent: Duration.zero,
          userAnswer: 'B',
        );

        expect(record.isCorrect, isFalse);
      });
    });

    group('field combinations', () {
      test('all fields are independent', () {
        final record = PracticeAnswerRecord(
          questionId: 'unique-id',
          questionType: QuestionType.multiChoice,
          isCorrect: false,
          timeSpent: const Duration(seconds: 42),
          userAnswer: 'custom answer',
        );

        expect(record.questionId, 'unique-id');
        expect(record.questionType, QuestionType.multiChoice);
        expect(record.isCorrect, isFalse);
        expect(record.timeSpent, const Duration(seconds: 42));
        expect(record.userAnswer, 'custom answer');
      });

      test('two records with same values are distinct instances', () {
        final record1 = PracticeAnswerRecord(
          questionId: 'q-same',
          questionType: QuestionType.singleChoice,
          isCorrect: true,
          timeSpent: const Duration(seconds: 10),
          userAnswer: 'A',
        );
        final record2 = PracticeAnswerRecord(
          questionId: 'q-same',
          questionType: QuestionType.singleChoice,
          isCorrect: true,
          timeSpent: const Duration(seconds: 10),
          userAnswer: 'A',
        );

        expect(record1, isNot(same(record2)));
        expect(record1.questionId, record2.questionId);
        expect(record1.questionType, record2.questionType);
        expect(record1.isCorrect, record2.isCorrect);
        expect(record1.timeSpent, record2.timeSpent);
        expect(record1.userAnswer, record2.userAnswer);
      });
    });
  });

  group('PracticeSessionResult', () {
    group('constructor', () {
      test('creates result with correct values', () {
        final result = PracticeSessionResult(
          questionsAnswered: 10,
          correctAnswers: 7,
        );

        expect(result.questionsAnswered, 10);
        expect(result.correctAnswers, 7);
      });

      test('creates result with zero values', () {
        final result = PracticeSessionResult(
          questionsAnswered: 0,
          correctAnswers: 0,
        );

        expect(result.questionsAnswered, 0);
        expect(result.correctAnswers, 0);
      });

      test('creates result with perfect score', () {
        final result = PracticeSessionResult(
          questionsAnswered: 10,
          correctAnswers: 10,
        );

        expect(result.questionsAnswered, 10);
        expect(result.correctAnswers, 10);
      });

      test('creates result with correctAnswers exceeding questionsAnswered', () {
        final result = PracticeSessionResult(
          questionsAnswered: 5,
          correctAnswers: 8,
        );

        expect(result.questionsAnswered, 5);
        expect(result.correctAnswers, 8);
      });
    });

    group('numeric edge cases', () {
      test('creates result with large values', () {
        final result = PracticeSessionResult(
          questionsAnswered: 99999,
          correctAnswers: 88888,
        );

        expect(result.questionsAnswered, 99999);
        expect(result.correctAnswers, 88888);
      });

      test('creates result with very large values', () {
        final result = PracticeSessionResult(
          questionsAnswered: 2147483647,
          correctAnswers: 2147483647,
        );

        expect(result.questionsAnswered, 2147483647);
        expect(result.correctAnswers, 2147483647);
      });

      test('creates result with single question answered', () {
        final result = PracticeSessionResult(
          questionsAnswered: 1,
          correctAnswers: 1,
        );

        expect(result.questionsAnswered, 1);
        expect(result.correctAnswers, 1);
      });

      test('creates result with all wrong', () {
        final result = PracticeSessionResult(
          questionsAnswered: 10,
          correctAnswers: 0,
        );

        expect(result.questionsAnswered, 10);
        expect(result.correctAnswers, 0);
      });

      test('creates result with one correct out of many', () {
        final result = PracticeSessionResult(
          questionsAnswered: 100,
          correctAnswers: 1,
        );

        expect(result.questionsAnswered, 100);
        expect(result.correctAnswers, 1);
      });
    });

    group('field combinations', () {
      test('two results with same values are distinct instances', () {
        final result1 = PracticeSessionResult(
          questionsAnswered: 20,
          correctAnswers: 15,
        );
        final result2 = PracticeSessionResult(
          questionsAnswered: 20,
          correctAnswers: 15,
        );

        expect(result1, isNot(same(result2)));
        expect(result1.questionsAnswered, result2.questionsAnswered);
        expect(result1.correctAnswers, result2.correctAnswers);
      });

      test('fields are independent', () {
        final result = PracticeSessionResult(
          questionsAnswered: 50,
          correctAnswers: 30,
        );

        expect(result.questionsAnswered, 50);
        expect(result.correctAnswers, 30);
        expect(result.questionsAnswered, isNot(result.correctAnswers));
      });
    });

    group('topicBreakdown', () {
      test('defaults to empty map when not provided', () {
        final result = PracticeSessionResult(
          questionsAnswered: 10,
          correctAnswers: 7,
        );

        expect(result.topicBreakdown, isEmpty);
      });

      test('accepts custom topic breakdown with multiple entries', () {
        final breakdown = {
          'algebra': 0.85,
          'geometry': 0.72,
          'calculus': 0.91,
        };
        final result = PracticeSessionResult(
          questionsAnswered: 30,
          correctAnswers: 24,
          topicBreakdown: breakdown,
        );

        expect(result.topicBreakdown, hasLength(3));
        expect(result.topicBreakdown['algebra'], 0.85);
        expect(result.topicBreakdown['geometry'], 0.72);
        expect(result.topicBreakdown['calculus'], 0.91);
      });

      test('accepts empty map explicitly', () {
        final result = PracticeSessionResult(
          questionsAnswered: 5,
          correctAnswers: 3,
          topicBreakdown: {},
        );

        expect(result.topicBreakdown, isEmpty);
      });

      test('accepts single entry', () {
        final result = PracticeSessionResult(
          questionsAnswered: 2,
          correctAnswers: 2,
          topicBreakdown: {'trigonometry': 1.0},
        );

        expect(result.topicBreakdown, hasLength(1));
        expect(result.topicBreakdown['trigonometry'], 1.0);
      });

      test('accepts fractional and edge values', () {
        final result = PracticeSessionResult(
          questionsAnswered: 1,
          correctAnswers: 0,
          topicBreakdown: {'physics': 0.0},
        );

        expect(result.topicBreakdown['physics'], 0.0);
      });

      test('stores distinct map per instance', () {
        final result1 = PracticeSessionResult(
          questionsAnswered: 5,
          correctAnswers: 3,
          topicBreakdown: {'topic_a': 0.6},
        );
        final result2 = PracticeSessionResult(
          questionsAnswered: 5,
          correctAnswers: 3,
          topicBreakdown: {'topic_b': 0.8},
        );

        expect(result1.topicBreakdown, hasLength(1));
        expect(result2.topicBreakdown, hasLength(1));
        expect(result1.topicBreakdown.keys, contains('topic_a'));
        expect(result2.topicBreakdown.keys, contains('topic_b'));
      });
    });
  });
}
