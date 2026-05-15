import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/adaptive_practice_engine.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/subjects/data/models/topic_progress_model.dart';
import 'package:studyking/core/data/enums.dart';

void main() {
  group('AdaptivePracticeEngine', () {
    late AdaptivePracticeEngine engine;

    setUp(() {
      engine = AdaptivePracticeEngine();
    });

    group('calculateReviewInterval', () {
      test('returns 1.0 for zero attempts', () {
        final interval = engine.calculateReviewInterval(
          correctCount: 0,
          incorrectCount: 0,
          averageConfidence: 3.0,
        );
        expect(interval, equals(1.0));
      });

      test('returns low interval for low accuracy', () {
        final interval = engine.calculateReviewInterval(
          correctCount: 1,
          incorrectCount: 9,
          averageConfidence: 1.0,
        );
        expect(interval, lessThan(2.0));
      });

      test('returns high interval for high accuracy', () {
        final interval = engine.calculateReviewInterval(
          correctCount: 9,
          incorrectCount: 1,
          averageConfidence: 5.0,
        );
        expect(interval, greaterThan(3.0));
      });

      test('handles only correct attempts', () {
        final interval = engine.calculateReviewInterval(
          correctCount: 10,
          incorrectCount: 0,
          averageConfidence: 5.0,
        );
        expect(interval, greaterThan(1.0));
      });

      test('handles only incorrect attempts', () {
        final interval = engine.calculateReviewInterval(
          correctCount: 0,
          incorrectCount: 10,
          averageConfidence: 1.0,
        );
        expect(interval, greaterThanOrEqualTo(1.0));
      });
    });

    group('updateQuestionState', () {
      test('creates new state for first attempt', () {
        engine.updateQuestionState(
          questionId: 'q1',
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 5000,
        );
      });

      test('updates existing state for subsequent attempts', () {
        engine.updateQuestionState(
          questionId: 'q1',
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 5000,
        );
        engine.updateQuestionState(
          questionId: 'q1',
          isCorrect: false,
          confidence: 2,
          timeSpentMs: 3000,
        );
      });

      test('increments streak on correct answer', () {
        engine.updateQuestionState(
          questionId: 'q1',
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 5000,
        );
        engine.updateQuestionState(
          questionId: 'q1',
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 5000,
        );
      });

      test('resets streak on incorrect answer', () {
        engine.updateQuestionState(
          questionId: 'q1',
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 5000,
        );
        engine.updateQuestionState(
          questionId: 'q1',
          isCorrect: false,
          confidence: 2,
          timeSpentMs: 3000,
        );
      });
    });

    group('getRecommendedDifficulty', () {
      test('returns 0 for struggling students', () {
        final difficulty = engine.getRecommendedDifficulty(
          topicId: 'topic1',
          currentAccuracy: 0.5,
          currentStreak: 2,
        );
        expect(difficulty, equals(0));
      });

      test('returns 2 for high performing students', () {
        final difficulty = engine.getRecommendedDifficulty(
          topicId: 'topic1',
          currentAccuracy: 0.95,
          currentStreak: 10,
        );
        expect(difficulty, equals(2));
      });

      test('returns 1 for average students', () {
        final difficulty = engine.getRecommendedDifficulty(
          topicId: 'topic1',
          currentAccuracy: 0.7,
          currentStreak: 3,
        );
        expect(difficulty, equals(1));
      });
    });

    group('generateQuestionVariants', () {
      test('generates correct number of variants', () {
        final variants = engine.generateQuestionVariants('q1', 3);
        expect(variants.length, equals(3));
      });

      test('generates unique variant ids', () {
        final variants = engine.generateQuestionVariants('q1', 3);
        expect(variants.toSet().length, equals(3));
      });

      test('generates zero variants', () {
        final variants = engine.generateQuestionVariants('q1', 0);
        expect(variants, isEmpty);
      });
    });

    group('getTopicRecommendations', () {
      test('returns fundamentals focus for low accuracy', () {
        final progress = TopicProgress(
          topicId: 'topic1',
          questionsAnswered: 10,
          correctAnswers: 4,
          lastUpdated: DateTime.now(),
        );

        final recommendations = engine.getTopicRecommendations('topic1', progress);

        expect(recommendations['focus'], equals('fundamentals'));
      });

      test('returns practice focus for medium accuracy', () {
        final progress = TopicProgress(
          topicId: 'topic1',
          questionsAnswered: 10,
          correctAnswers: 7,
          lastUpdated: DateTime.now(),
        );

        final recommendations = engine.getTopicRecommendations('topic1', progress);

        expect(recommendations['focus'], equals('practice'));
      });

      test('returns mastery focus for high accuracy', () {
        final progress = TopicProgress(
          topicId: 'topic1',
          questionsAnswered: 10,
          correctAnswers: 9,
          lastUpdated: DateTime.now(),
        );

        final recommendations = engine.getTopicRecommendations('topic1', progress);

        expect(recommendations['focus'], equals('mastery'));
      });

      test('includes timeToReview in recommendations', () {
        final progress = TopicProgress(
          topicId: 'topic1',
          questionsAnswered: 10,
          correctAnswers: 7,
          lastUpdated: DateTime.now(),
        );

        final recommendations = engine.getTopicRecommendations('topic1', progress);

        expect(recommendations['timeToReview'], isA<int>());
      });
    });

    group('getNextPracticeQuestions', () {
      test('returns questions up to maxQuestions limit', () async {
        final questions = List.generate(20, (i) => Question(
          id: 'q$i',
          text: 'Question $i',
          type: QuestionType.singleChoice,
          difficulty: 1,
          subjectId: 'math',
          topicId: i % 2 == 0 ? 'topic1' : 'topic2',
          variantIds: [],
          sourceIds: [],
          allowedAnswerTypes: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        final topicProgress = {
          'topic1': TopicProgress(topicId: 'topic1', questionsAnswered: 10, correctAnswers: 8, lastUpdated: DateTime.now()),
          'topic2': TopicProgress(topicId: 'topic2', questionsAnswered: 5, correctAnswers: 2, lastUpdated: DateTime.now()),
        };

        final result = await engine.getNextPracticeQuestions(
          availableQuestions: questions,
          topicProgress: topicProgress,
          maxQuestions: 5,
        );

        expect(result.length, lessThanOrEqualTo(5));
      });

      test('handles empty available questions', () async {
        final topicProgress = {
          'topic1': TopicProgress(topicId: 'topic1', questionsAnswered: 10, correctAnswers: 8, lastUpdated: DateTime.now()),
        };

        final result = await engine.getNextPracticeQuestions(
          availableQuestions: [],
          topicProgress: topicProgress,
          maxQuestions: 5,
        );

        expect(result, isEmpty);
      });

      test('handles empty topic progress', () async {
        final questions = [
          Question(id: 'q1', text: 'Q1', type: QuestionType.singleChoice, difficulty: 1, subjectId: 'math', topicId: 'topic1', variantIds: [], sourceIds: [], allowedAnswerTypes: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        ];

        final result = await engine.getNextPracticeQuestions(
          availableQuestions: questions,
          topicProgress: {},
          maxQuestions: 5,
        );

        expect(result.length, greaterThan(0));
      });
    });
  });
}