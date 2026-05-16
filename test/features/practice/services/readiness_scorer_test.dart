import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/practice/services/readiness_scorer.dart';

Question _createQuestion({
  String id = 'q1',
  String topicId = 't1',
  int difficulty = 1,
  String subjectId = 'sub1',
}) {
  return Question(
    id: id,
    text: 'Test question?',
    type: QuestionType.singleChoice,
    difficulty: difficulty,
    subjectId: subjectId,
    topicId: topicId,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('ReadinessScorer', () {
    test('returns empty list for empty input', () {
      final scorer = ReadinessScorer();
      final result = scorer.scoreQuestions([]);
      expect(result, isEmpty);
    });

    test('scores single question', () {
      final questions = [_createQuestion()];
      final scorer = ReadinessScorer();
      final result = scorer.scoreQuestions(questions);

      expect(result, hasLength(1));
      expect(result.first.score, greaterThan(0));
    });

    test('prioritizes questions with high review urgency', () {
      final now = DateTime.now();
      final questions = [
        _createQuestion(id: 'q1', topicId: 't1'),
        _createQuestion(id: 'q2', topicId: 't2'),
      ];

      final topicMasteryMap = <String, MasteryState>{
        't1': MasteryState(
          studentId: 's1',
          topicId: 't1',
          accuracy: 0.9,
          lastAttempt: now,
          lastUpdated: now,
          readinessScore: 0.8,
          reviewUrgency: 0.9,
        ),
        't2': MasteryState(
          studentId: 's1',
          topicId: 't2',
          accuracy: 0.3,
          lastAttempt: now,
          lastUpdated: now,
          readinessScore: 0.2,
          reviewUrgency: 0.3,
        ),
      };

      final scorer = ReadinessScorer(topicMasteryMap: topicMasteryMap);
      final result = scorer.scoreQuestions(questions);

      expect(result, hasLength(2));
      expect(result.first.question.id, 'q1');
      expect(result.first.score, greaterThan(result.last.score));
    });

    test('prioritizes questions with confidence gaps', () {
      final now = DateTime.now();
      final questions = [
        _createQuestion(id: 'q1', topicId: 't1'),
        _createQuestion(id: 'q2', topicId: 't1'),
      ];

      final questionMasteryMap = <String, QuestionMasteryState>{
        'q1': QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          lastAttempt: now,
          masteryLevel: 0.9,
          confidenceHistory: [5, 5, 5],
        ),
        'q2': QuestionMasteryState(
          studentId: 's1',
          questionId: 'q2',
          lastAttempt: now,
          masteryLevel: 0.2,
          confidenceHistory: [1, 1, 1],
        ),
      };

      final scorer = ReadinessScorer(
        questionMasteryMap: questionMasteryMap,
      );
      final result = scorer.scoreQuestions(questions);

      expect(result, hasLength(2));
      expect(result.first.question.id, 'q2');
    });

    test('prioritizes questions not attempted recently', () {
      final now = DateTime.now();
      final questions = [
        _createQuestion(id: 'q1'),
        _createQuestion(id: 'q2'),
      ];

      final questionMasteryMap = <String, QuestionMasteryState>{
        'q1': QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          lastAttempt: now.subtract(const Duration(days: 30)),
          masteryLevel: 0.5,
        ),
        'q2': QuestionMasteryState(
          studentId: 's1',
          questionId: 'q2',
          lastAttempt: now,
          masteryLevel: 0.5,
        ),
      };

      final scorer = ReadinessScorer(
        questionMasteryMap: questionMasteryMap,
      );
      final result = scorer.scoreQuestions(questions);

      expect(result, hasLength(2));
      expect(result.first.question.id, 'q1');
    });

    test('assigns default scores for unknown topics and questions', () {
      final questions = [_createQuestion()];
      final scorer = ReadinessScorer();
      final result = scorer.scoreQuestions(questions);

      expect(result.first.score, greaterThan(0));
    });

    test('sorts by score descending', () {
      final now = DateTime.now();
      final questions = List.generate(5, (i) => _createQuestion(
        id: 'q$i',
        topicId: 't${i % 2}',
      ));

      final topicMasteryMap = <String, MasteryState>{
        't0': MasteryState(
          studentId: 's1',
          topicId: 't0',
          accuracy: 0.9,
          lastAttempt: now,
          lastUpdated: now,
          readinessScore: 0.9,
          reviewUrgency: 0.1,
        ),
        't1': MasteryState(
          studentId: 's1',
          topicId: 't1',
          accuracy: 0.3,
          lastAttempt: now,
          lastUpdated: now,
          readinessScore: 0.2,
          reviewUrgency: 0.9,
        ),
      };

      final scorer = ReadinessScorer(topicMasteryMap: topicMasteryMap);
      final result = scorer.scoreQuestions(questions);

      expect(result, hasLength(5));
      for (var i = 0; i < result.length - 1; i++) {
        expect(result[i].score, greaterThanOrEqualTo(result[i + 1].score));
      }
    });

    test('handles empty mastery maps gracefully', () {
      final questions = [
        _createQuestion(id: 'q1'),
        _createQuestion(id: 'q2'),
        _createQuestion(id: 'q3'),
      ];

      final scorer = ReadinessScorer();
      final result = scorer.scoreQuestions(questions);

      expect(result, hasLength(3));
    });

    test('ScoredQuestion carries mastery data', () {
      final now = DateTime.now();
      final topicMastery = MasteryState(
        studentId: 's1',
        topicId: 't1',
        lastAttempt: now,
        lastUpdated: now,
      );
      final questionMastery = QuestionMasteryState(
        studentId: 's1',
        questionId: 'q1',
        lastAttempt: now,
      );

      final questions = [_createQuestion()];
      final scorer = ReadinessScorer(
        topicMasteryMap: {'t1': topicMastery},
        questionMasteryMap: {'q1': questionMastery},
      );

      final result = scorer.scoreQuestions(questions);
      expect(result.first.topicMastery, isNotNull);
      expect(result.first.questionMastery, isNotNull);
    });
  });
}
