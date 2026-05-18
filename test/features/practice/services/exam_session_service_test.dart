import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/features/practice/services/exam_session_service.dart';

Question _q({
  required String id,
  required String text,
  QuestionType type = QuestionType.singleChoice,
  String markschemeText = 'A',
  String topicId = 'topic-a',
  List<String> options = const [],
  String? explanation,
  int difficulty = 1,
}) {
  final now = DateTime.utc(2024, 1, 1);
  return Question(
    id: id,
    text: text,
    type: type,
    difficulty: difficulty,
    subjectId: 'subject-a',
    topicId: topicId,
    markscheme: Markscheme(
      questionId: id,
      correctAnswer: markschemeText,
      explanation: explanation,
    ),
    options: options,
    createdAt: now,
    updatedAt: now,
    explanation: explanation,
  );
}

void main() {
  group('ExamResult', () {
    group('accuracy', () {
      test('returns 1.0 when all correct', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 2, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q'), isCorrect: true, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q'), isCorrect: true, timeSpentMs: 100),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.accuracy, 1.0);
      });

      test('returns 0.0 when all incorrect', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 2, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q'), isCorrect: false, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q'), isCorrect: false, timeSpentMs: 100),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.accuracy, 0.0);
      });

      test('returns 0.5 when half correct', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 2, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q'), isCorrect: true, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q'), isCorrect: false, timeSpentMs: 100),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.accuracy, 0.5);
      });

      test('excludes skipped from denominator', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 3, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q'), isCorrect: true, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q'), isCorrect: false, timeSpentMs: 0, wasSkipped: true),
            ExamQuestionResult(question: _q(id: 'q3', text: 'Q'), isCorrect: false, timeSpentMs: 100),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.accuracy, 0.5);
      });

      test('returns 0.0 when no non-skipped questions', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 1, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q'), isCorrect: false, timeSpentMs: 0, wasSkipped: true),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.accuracy, 0.0);
      });

      test('returns 0.0 when questionResults is empty', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 0, subjectId: 's'),
          questionResults: [],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.accuracy, 0.0);
      });
    });

    group('topicBreakdown', () {
      test('groups results by topic', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 4, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q', topicId: 't1'), isCorrect: true, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q', topicId: 't1'), isCorrect: false, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q3', text: 'Q', topicId: 't2'), isCorrect: true, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q4', text: 'Q', topicId: 't2'), isCorrect: true, timeSpentMs: 100),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.topicBreakdown['t1'], 0.5);
        expect(result.topicBreakdown['t2'], 1.0);
      });

      test('excludes skipped from topic breakdown', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 2, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q', topicId: 't1'), isCorrect: true, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q', topicId: 't1'), isCorrect: false, timeSpentMs: 0, wasSkipped: true),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.topicBreakdown['t1'], 1.0);
      });

      test('returns empty map for empty results', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 0, subjectId: 's'),
          questionResults: [],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.topicBreakdown, isEmpty);
      });
    });

    group('averageTimePerQuestionMs', () {
      test('calculates average correctly', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 3, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q'), isCorrect: true, timeSpentMs: 10000),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q'), isCorrect: true, timeSpentMs: 20000),
            ExamQuestionResult(question: _q(id: 'q3', text: 'Q'), isCorrect: true, timeSpentMs: 30000),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.averageTimePerQuestionMs, 20000);
      });

      test('returns 0.0 for empty results', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 0, subjectId: 's'),
          questionResults: [],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.averageTimePerQuestionMs, 0.0);
      });
    });

    group('counts', () {
      test('totalCorrect, totalIncorrect, totalSkipped', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 3, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q'), isCorrect: true, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q'), isCorrect: false, timeSpentMs: 0, wasSkipped: true),
            ExamQuestionResult(question: _q(id: 'q3', text: 'Q'), isCorrect: false, timeSpentMs: 100),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.totalCorrect, 1);
        expect(result.totalIncorrect, 1);
        expect(result.totalSkipped, 1);
      });
    });
  });

  group('ExamConfig', () {
    test('creates with required fields', () {
      const config = ExamConfig(
        durationMinutes: 30,
        questionCount: 10,
        subjectId: 's1',
      );
      expect(config.durationMinutes, 30);
      expect(config.questionCount, 10);
      expect(config.subjectId, 's1');
      expect(config.topicIds, isNull);
      expect(config.easyCount, isNull);
    });

    test('creates with all optional fields', () {
      const config = ExamConfig(
        durationMinutes: 45,
        questionCount: 20,
        subjectId: 's1',
        easyCount: 5,
        mediumCount: 10,
        hardCount: 5,
        topicIds: ['t1', 't2'],
      );
      expect(config.easyCount, 5);
      expect(config.mediumCount, 10);
      expect(config.hardCount, 5);
      expect(config.topicIds, ['t1', 't2']);
    });
  });

  group('ExamQuestionResult', () {
    test('creates with required fields', () {
      final q = _q(id: 'q1', text: 'Test');
      final result = ExamQuestionResult(
        question: q,
        isCorrect: true,
        timeSpentMs: 5000,
      );
      expect(result.question, q);
      expect(result.isCorrect, isTrue);
      expect(result.timeSpentMs, 5000);
      expect(result.userAnswer, isNull);
      expect(result.wasSkipped, isFalse);
    });

    test('creates with all fields', () {
      final q = _q(id: 'q1', text: 'Test');
      final result = ExamQuestionResult(
        question: q,
        userAnswer: 'A',
        isCorrect: true,
        timeSpentMs: 5000,
        wasSkipped: false,
      );
      expect(result.userAnswer, 'A');
      expect(result.wasSkipped, isFalse);
    });

    test('creates with skipped flag', () {
      final q = _q(id: 'q1', text: 'Test');
      final result = ExamQuestionResult(
        question: q,
        isCorrect: false,
        timeSpentMs: 0,
        wasSkipped: true,
      );
      expect(result.wasSkipped, isTrue);
    });
  });
}
