import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/mentor/services/tools/search_questions_tool.dart';
import 'test_helpers.dart';

Question _q(String id, String text, String subjectId, String topicId,
    {String? topic}) {
  final now = DateTime.now();
  return Question(
    id: id,
    text: text,
    type: QuestionType.singleChoice,
    subjectId: subjectId,
    topicId: topicId,
    topic: topic,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('SearchQuestionsTool', () {
    late FakeQuestionRepository questionRepo;

    setUp(() => questionRepo = FakeQuestionRepository());

    test('returns all questions when no filters are provided', () async {
      questionRepo.setQuestions([
        _q('q1', 'What is integration?', 's1', 't1'),
        _q('q2', 'Differentiate x squared', 's1', 't2'),
      ]);

      final tool = SearchQuestionsTool(questionRepo: questionRepo);
      final result = await tool.execute({});

      expect(result['count'], equals(2));
      final questions = result['questions'] as List;
      expect(questions.length, equals(2));
      expect(questions[0]['id'], equals('q1'));
      expect(questions[0]['type'], equals('singleChoice'));
      expect(questions[0]['subjectId'], equals('s1'));
    });

    test('filters by subjectId', () async {
      questionRepo.setQuestions([
        _q('q1', 'Integration basics', 's1', 't1'),
        _q('q2', 'Integration advanced', 's2', 't1'),
      ]);

      final tool = SearchQuestionsTool(questionRepo: questionRepo);
      final result = await tool.execute({'subjectId': 's1'});

      expect(result['count'], equals(1));
      final questions = result['questions'] as List;
      expect(questions.first['id'], equals('q1'));
    });

    test('filters by topicId and keyword (normalized)', () async {
      questionRepo.setQuestions([
        _q('q1', 'Integration by parts', 's1', 't1', topic: 'Calculus'),
        _q('q2', 'ALGEBRA fundamentals', 's1', 't2', topic: 'Algebra'),
        _q('q3', 'Integration over surfaces', 's1', 't1', topic: 'Calculus'),
      ]);

      final tool = SearchQuestionsTool(questionRepo: questionRepo);
      final result = await tool.execute({
        'topicId': 't1',
        'keyword': 'INTEGRATION',
      });

      expect(result['count'], equals(2));
      final ids = (result['questions'] as List).map((q) => q['id']).toList();
      expect(ids, containsAll(['q1', 'q3']));
    });

    test('respects the limit argument', () async {
      questionRepo.setQuestions([
        _q('q1', 'a', 's1', 't1'),
        _q('q2', 'b', 's1', 't1'),
        _q('q3', 'c', 's1', 't1'),
      ]);

      final tool = SearchQuestionsTool(questionRepo: questionRepo);
      final result = await tool.execute({'limit': 2});

      expect(result['count'], equals(2));
    });

    test('degrades gracefully with no matching questions', () async {
      questionRepo.setQuestions(const []);

      final tool = SearchQuestionsTool(questionRepo: questionRepo);
      final result = await tool.execute({});

      expect(result['count'], equals(0));
      expect(result['questions'], equals([]));
      expect(result['questions'], isA<List>());
    });
  });
}
