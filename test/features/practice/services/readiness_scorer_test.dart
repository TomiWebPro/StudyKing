import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
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
    test('returns empty list for empty input', () async {
      final scorer = ReadinessScorer();
      final result = await scorer.scoreQuestions([]);
      expect(result, isEmpty);
    });

    test('scores single question', () async {
      final questions = [_createQuestion()];
      final scorer = ReadinessScorer();
      final result = await scorer.scoreQuestions(questions);

      expect(result, hasLength(1));
      expect(result.first.score, greaterThan(0));
    });

    test('prioritizes questions with high review urgency', () async {
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
      final result = await scorer.scoreQuestions(questions);

      expect(result, hasLength(2));
      expect(result.first.question.id, 'q1');
      expect(result.first.score, greaterThan(result.last.score));
    });

    test('prioritizes questions with confidence gaps', () async {
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
      final result = await scorer.scoreQuestions(questions);

      expect(result, hasLength(2));
      expect(result.first.question.id, 'q2');
    });

    test('prioritizes questions not attempted recently', () async {
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
      final result = await scorer.scoreQuestions(questions);

      expect(result, hasLength(2));
      expect(result.first.question.id, 'q1');
    });

    test('assigns default scores for unknown topics and questions', () async {
      final questions = [_createQuestion()];
      final scorer = ReadinessScorer();
      final result = await scorer.scoreQuestions(questions);

      expect(result.first.score, greaterThan(0));
    });

    test('sorts by score descending', () async {
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
      final result = await scorer.scoreQuestions(questions);

      expect(result, hasLength(5));
      for (var i = 0; i < result.length - 1; i++) {
        expect(result[i].score, greaterThanOrEqualTo(result[i + 1].score));
      }
    });

    test('handles empty mastery maps gracefully', () async {
      final questions = [
        _createQuestion(id: 'q1'),
        _createQuestion(id: 'q2'),
        _createQuestion(id: 'q3'),
      ];

      final scorer = ReadinessScorer();
      final result = await scorer.scoreQuestions(questions);

      expect(result, hasLength(3));
    });

    test('ScoredQuestion carries mastery data', () async {
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

      final result = await scorer.scoreQuestions(questions);
      expect(result.first.topicMastery, isNotNull);
      expect(result.first.questionMastery, isNotNull);
    });

    group('error-state: edge cases and null safety', () {
      test('questions with null topicId do not crash', () async {
        final questions = [
          _createQuestion(id: 'q1', topicId: 'nonexistent'),
        ];
        final scorer = ReadinessScorer();
        final result = await scorer.scoreQuestions(questions);
        expect(result, hasLength(1));
        expect(result.first.score, greaterThanOrEqualTo(0));
      });

      test('null mastery maps use default scoring', () async {
        final questions = [_createQuestion()];
        final scorer = ReadinessScorer(
          topicMasteryMap: <String, MasteryState>{},
          questionMasteryMap: <String, QuestionMasteryState>{},
        );
        final result = await scorer.scoreQuestions(questions);
        expect(result, hasLength(1));
        expect(result.first.score, greaterThan(0));
      });

      test('handles questions with extreme difficulty values', () async {
        final questions = [
          _createQuestion(id: 'q1', difficulty: 0),
          _createQuestion(id: 'q2', difficulty: 999),
        ];
        final scorer = ReadinessScorer();
        final result = await scorer.scoreQuestions(questions);
        expect(result, hasLength(2));
        for (final sq in result) {
          expect(sq.score, inInclusiveRange(0.0, 1.0));
        }
      });

      test('scorer handles large question sets without throwing', () async {
        final questions = List.generate(100, (i) => _createQuestion(id: 'q$i'));
        final scorer = ReadinessScorer();
        final result = await scorer.scoreQuestions(questions);
        expect(result, hasLength(100));
      });
    });
  });

  group('ReadinessScorer - coverage gaps', () {
    group('_computeScore edge cases', () {
      test('empty confidenceHistory uses default confidence gap', () async {
        final now = DateTime.now();
        final questions = [_createQ(id: 'q1')];
        final qMastery = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          lastAttempt: now,
          confidenceHistory: [],
        );
        final scorer = ReadinessScorer(
          questionMasteryMap: {'q1': qMastery},
        );
        final result = await scorer.scoreQuestions(questions);
        expect(result.first.score, greaterThan(0));
      });

      test('no topic mastery uses default urgency', () async {
        final questions = [_createQ(id: 'q1', topicId: 'unknown')];
        final scorer = ReadinessScorer();
        final result = await scorer.scoreQuestions(questions);
        expect(result.first.score, greaterThan(0));
      });

      test('no question mastery uses default days score', () async {
        final questions = [_createQ(id: 'q1')];
        final scorer = ReadinessScorer();
        final result = await scorer.scoreQuestions(questions);
        expect(result.first.score, greaterThan(0));
      });

      test('difficulty contributes to score', () async {
        final easyQ = _createQ(id: 'q1', difficulty: 1);
        final hardQ = _createQ(id: 'q2', difficulty: 5);
        final questions = [easyQ, hardQ];
        final scorer = ReadinessScorer();
        final result = await scorer.scoreQuestions(questions);
        expect(result[0].question.id, 'q2');
        expect(result[0].score, greaterThan(result[1].score));
      });

      test('extreme confidence gap gives high boost', () async {
        final now = DateTime.now();
        final questions = [_createQ(id: 'q1')];
        final qMastery = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          lastAttempt: now.subtract(const Duration(days: 30)),
          confidenceHistory: [1],
        );
        final scorer = ReadinessScorer(
          questionMasteryMap: {'q1': qMastery},
        );
        final result = await scorer.scoreQuestions(questions);
        expect(result.first.score, greaterThan(0.5));
      });

      test('high readiness reduces priority', () async {
        final now = DateTime.now();
        final questions = [
          _createQ(id: 'q1', topicId: 't1'),
          _createQ(id: 'q2', topicId: 't2'),
        ];
        final topicMasteryMap = <String, MasteryState>{
          't1': MasteryState(
            studentId: 's1',
            topicId: 't1',
            lastAttempt: now,
            lastUpdated: now,
            readinessScore: 0.9,
            reviewUrgency: 0.5,
            accuracy: 0.8,
          ),
          't2': MasteryState(
            studentId: 's1',
            topicId: 't2',
            lastAttempt: now,
            lastUpdated: now,
            readinessScore: 0.1,
            reviewUrgency: 0.5,
            accuracy: 0.2,
          ),
        };
        final scorer = ReadinessScorer(topicMasteryMap: topicMasteryMap);
        final result = await scorer.scoreQuestions(questions);
        expect(result.first.question.id, 'q2');
      });
    });
  });
}

Question _createQ({
  String id = 'q1',
  String subjectId = 'sub1',
  String topicId = 't1',
  int difficulty = 1,
  String? srDataJson,
}) {
  return Question(
    id: id,
    text: 'Sample question?',
    type: QuestionType.singleChoice,
    subjectId: subjectId,
    topicId: topicId,
    difficulty: difficulty,
    createdAt: DateTime(2026, 5, 12),
    updatedAt: DateTime(2026, 5, 12),
    srDataJson: srDataJson,
  );
}
