import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/mentor/services/tools/search_questions_tool.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';

Question _createQuestion({
  String id = 'q-1',
  String text = 'What is 2+2?',
  QuestionType type = QuestionType.singleChoice,
  int difficulty = 1,
  String topicId = 'topic-1',
  String subjectId = 'subj-1',
  String? topic,
}) {
  return Question(
    id: id,
    text: text,
    type: type,
    difficulty: difficulty,
    subjectId: subjectId,
    topicId: topicId,
    topic: topic,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

class FakeQuestionRepository extends QuestionRepository {
  List<Question> _questions = [];

  void setQuestions(List<Question> questions) => _questions = questions;

  @override
  Future<Result<List<Question>>> getAll() async => Result.success(_questions);

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async {
    return Result.success(
      _questions.where((q) => q.subjectId == subjectId).toList(),
    );
  }

  @override
  Future<void> init() async {}
}

void main() {
  group('SearchQuestionsTool', () {
    late FakeQuestionRepository fakeRepo;
    late SearchQuestionsTool tool;

    setUp(() {
      fakeRepo = FakeQuestionRepository();
      tool = SearchQuestionsTool(questionRepo: fakeRepo);
    });

    test('name returns search_questions', () {
      expect(tool.name, 'search_questions');
    });

    test('description is not empty', () {
      expect(tool.description, isNotEmpty);
    });

    test('parameters has correct JSON schema shape', () {
      final params = tool.parameters;
      expect(params['type'], 'object');
      final properties = params['properties'] as Map<String, dynamic>;
      expect(properties.keys, containsAll(['subjectId', 'topicId', 'keyword', 'limit']));
      expect(properties['subjectId']['type'], 'string');
      expect(properties['topicId']['type'], 'string');
      expect(properties['keyword']['type'], 'string');
      expect(properties['limit']['type'], 'integer');
      expect(properties['limit']['default'], 10);
      expect(params['required'], []);
    });

    test('execute searches by subjectId when provided', () async {
      fakeRepo.setQuestions([
        _createQuestion(id: 'q-1', subjectId: 'subj-1'),
        _createQuestion(id: 'q-2', subjectId: 'subj-1'),
        _createQuestion(id: 'q-3', subjectId: 'subj-2'),
      ]);

      final result = await tool.execute({'subjectId': 'subj-1'});

      expect(result['count'], 2);
      expect((result['questions'] as List).map((q) => q['id']), containsAll(['q-1', 'q-2']));
    });

    test('execute falls back to getAll when no subjectId', () async {
      fakeRepo.setQuestions([
        _createQuestion(id: 'q-1', subjectId: 'subj-1'),
        _createQuestion(id: 'q-2', subjectId: 'subj-2'),
      ]);

      final result = await tool.execute({});

      expect(result['count'], 2);
    });

    test('execute filters by topicId', () async {
      fakeRepo.setQuestions([
        _createQuestion(id: 'q-1', topicId: 'topic-1'),
        _createQuestion(id: 'q-2', topicId: 'topic-1'),
        _createQuestion(id: 'q-3', topicId: 'topic-2'),
      ]);

      final result = await tool.execute({'topicId': 'topic-1'});

      expect(result['count'], 2);
      expect((result['questions'] as List).map((q) => q['id']), containsAll(['q-1', 'q-2']));
    });

    test('execute filters by keyword in question text', () async {
      fakeRepo.setQuestions([
        _createQuestion(id: 'q-1', text: 'What is photosynthesis?'),
        _createQuestion(id: 'q-2', text: 'Solve for x in algebra'),
        _createQuestion(id: 'q-3', text: 'Define photosynthesis process'),
      ]);

      final result = await tool.execute({'keyword': 'photosynthesis'});

      expect(result['count'], 2);
      expect((result['questions'] as List).map((q) => q['id']), containsAll(['q-1', 'q-3']));
    });

    test('execute filters by keyword in topic name', () async {
      fakeRepo.setQuestions([
        _createQuestion(id: 'q-1', text: 'Question 1', topic: 'Algebra'),
        _createQuestion(id: 'q-2', text: 'Question 2', topic: 'Geometry'),
      ]);

      final result = await tool.execute({'keyword': 'algebra'});

      expect(result['count'], 1);
      expect(result['questions'][0]['id'], 'q-1');
    });

    test('execute keyword search is case-insensitive', () async {
      fakeRepo.setQuestions([
        _createQuestion(id: 'q-1', text: 'ALGEBRA equations'),
        _createQuestion(id: 'q-2', text: 'algebraic expressions'),
      ]);

      final result = await tool.execute({'keyword': 'Algebra'});

      expect(result['count'], 2);
    });

    test('execute respects limit parameter', () async {
      fakeRepo.setQuestions([
        _createQuestion(id: 'q-1'),
        _createQuestion(id: 'q-2'),
        _createQuestion(id: 'q-3'),
        _createQuestion(id: 'q-4'),
        _createQuestion(id: 'q-5'),
      ]);

      final result = await tool.execute({'limit': 3});

      expect(result['count'], 3);
      expect((result['questions'] as List).length, 3);
    });

    test('execute defaults limit to 10', () async {
      fakeRepo.setQuestions(
        List.generate(15, (i) => _createQuestion(id: 'q-$i')),
      );

      final result = await tool.execute({});

      expect(result['count'], 10);
    });

    test('execute returns question fields correctly', () async {
      fakeRepo.setQuestions([
        _createQuestion(
          id: 'q-1',
          text: 'Sample question',
          type: QuestionType.multiChoice,
          difficulty: 3,
          topicId: 'topic-1',
          subjectId: 'subj-1',
        ),
      ]);

      final result = await tool.execute({'limit': 10});

      expect(result['count'], 1);
      final question = (result['questions'] as List).first;
      expect(question['id'], 'q-1');
      expect(question['text'], 'Sample question');
      expect(question['type'], 'multiChoice');
      expect(question['difficulty'], 3);
      expect(question['topicId'], 'topic-1');
      expect(question['subjectId'], 'subj-1');
    });

    test('execute returns empty list when no questions exist', () async {
      fakeRepo.setQuestions([]);

      final result = await tool.execute({});

      expect(result['count'], 0);
      expect(result['questions'], []);
    });

    test('execute combines subjectId, topicId, and keyword filters', () async {
      fakeRepo.setQuestions([
        _createQuestion(id: 'q-1', subjectId: 'subj-1', topicId: 'topic-1', text: 'Algebra basics'),
        _createQuestion(id: 'q-2', subjectId: 'subj-1', topicId: 'topic-1', text: 'Advanced algebra'),
        _createQuestion(id: 'q-3', subjectId: 'subj-1', topicId: 'topic-2', text: 'Algebra review'),
        _createQuestion(id: 'q-4', subjectId: 'subj-2', topicId: 'topic-1', text: 'Algebra intro'),
      ]);

      final result = await tool.execute({
        'subjectId': 'subj-1',
        'topicId': 'topic-1',
        'keyword': 'advanced',
      });

      expect(result['count'], 1);
      expect(result['questions'][0]['id'], 'q-2');
    });
  });
}
