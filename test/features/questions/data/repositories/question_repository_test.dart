import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/enums.dart';

class _MockQuestionRepository extends QuestionRepository {
  final Map<String, Question> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<Question?> get(String id) async {
    return _storage[id];
  }

  @override
  Future<List<Question>> getAll() async {
    return _storage.values.toList();
  }

  @override
  Future<Result<void>> create(Question question) async {
    _storage[question.id] = question;
    return Result.success(null);
  }

  @override
  Future<Result<List<Question>>> getByTopic(String topicId) async {
    final filtered = _storage.values.where((q) => q.topicId == topicId).toList();
    return Result.success(filtered);
  }

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async {
    final filtered = _storage.values.where((q) => q.subjectId == subjectId).toList();
    return Result.success(filtered);
  }

  @override
  Future<Result<List<Question>>> getBySubjectAndTopic(String subjectId, String topicId) async {
    final filtered = _storage.values
        .where((q) => q.subjectId == subjectId && q.topicId == topicId)
        .toList();
    return Result.success(filtered);
  }

  @override
  Future<Result<List<Question>>> getByType(QuestionType type) async {
    final filtered = _storage.values.where((q) => q.type == type).toList();
    return Result.success(filtered);
  }

  @override
  Future<Result<List<Question>>> getBySubjectAndType(String subjectId, QuestionType type) async {
    final filtered = _storage.values
        .where((q) => q.subjectId == subjectId && q.type == type)
        .toList();
    return Result.success(filtered);
  }

  @override
  Future<void> delete(String id) async {
    _storage.remove(id);
  }

  @override
  Future<Result<List<QuestionWithMarkscheme>>> getQuestionsWithMarkschemes(String subjectId) async {
    final questions = _storage.values.toList();
    final filtered = questions.where((q) => q.markscheme != null).toList();
    if (filtered.isEmpty) {
      return Result.failure('No questions with markscheme found for subject: $subjectId');
    }
    return Result.success(
      filtered.map((q) => QuestionWithMarkscheme(
        question: q,
        markscheme: q.markscheme!,
      )).toList(),
    );
  }

  @override
  Future<Result<void>> updateMarkscheme(String questionId, Markscheme markscheme) async {
    final question = _storage[questionId];
    if (question == null) {
      return Result.failure('Question not found: $questionId');
    }
    final updated = question.copyWith(markscheme: markscheme);
    _storage[questionId] = updated;
    return Result.success(null);
  }
}

Question createTestQuestion({
  String id = 'q-1',
  String text = 'Test question?',
  QuestionType type = QuestionType.singleChoice,
  int difficulty = 1,
  String subjectId = 'subject-1',
  String topicId = 'topic-1',
  Markscheme? markscheme,
}) {
  return Question(
    id: id,
    text: text,
    type: type,
    difficulty: difficulty,
    subjectId: subjectId,
    topicId: topicId,
    markscheme: markscheme,
    createdAt: DateTime(2026, 5, 12),
    updatedAt: DateTime(2026, 5, 12),
  );
}

void main() {
  group('QuestionRepository', () {
    late _MockQuestionRepository repository;

    setUp(() {
      repository = _MockQuestionRepository();
    });

    group('create', () {
      test('stores a question', () async {
        final question = createTestQuestion();
        final result = await repository.create(question);
        expect(result.isSuccess, isTrue);
        final stored = await repository.get('q-1');
        expect(stored, isNotNull);
        expect(stored!.id, 'q-1');
      });
    });

    group('get', () {
      test('returns question by id', () async {
        final question = createTestQuestion();
        await repository.create(question);
        final stored = await repository.get('q-1');
        expect(stored, isNotNull);
        expect(stored!.text, 'Test question?');
      });

      test('returns null for missing question', () async {
        final stored = await repository.get('not-found');
        expect(stored, isNull);
      });
    });

    group('getAll', () {
      test('returns all questions', () async {
        await repository.create(createTestQuestion(id: 'q1'));
        await repository.create(createTestQuestion(id: 'q2'));
        final questions = await repository.getAll();
        expect(questions.length, 2);
      });

      test('returns empty when no questions', () async {
        final questions = await repository.getAll();
        expect(questions, isEmpty);
      });
    });

    group('getByTopic', () {
      test('returns questions for topic', () async {
        await repository.create(createTestQuestion(id: 'q1', topicId: 't1'));
        await repository.create(createTestQuestion(id: 'q2', topicId: 't1'));
        await repository.create(createTestQuestion(id: 'q3', topicId: 't2'));
        final result = await repository.getByTopic('t1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 2);
      });

      test('returns empty for non-existent topic', () async {
        final result = await repository.getByTopic('none');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });

    group('getBySubject', () {
      test('returns questions for subject', () async {
        await repository.create(createTestQuestion(id: 'q1', subjectId: 's1'));
        await repository.create(createTestQuestion(id: 'q2', subjectId: 's1'));
        await repository.create(createTestQuestion(id: 'q3', subjectId: 's2'));
        final result = await repository.getBySubject('s1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 2);
      });

      test('returns empty for non-existent subject', () async {
        final result = await repository.getBySubject('none');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });

    group('getBySubjectAndTopic', () {
      test('returns filtered questions', () async {
        await repository.create(createTestQuestion(id: 'q1', subjectId: 's1', topicId: 't1'));
        await repository.create(createTestQuestion(id: 'q2', subjectId: 's1', topicId: 't2'));
        await repository.create(createTestQuestion(id: 'q3', subjectId: 's2', topicId: 't1'));
        final result = await repository.getBySubjectAndTopic('s1', 't1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 1);
        expect(result.data?.first.id, 'q1');
      });

      test('returns empty when no match', () async {
        final result = await repository.getBySubjectAndTopic('s1', 't1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });

    group('getByType', () {
      test('returns questions of specific type', () async {
        await repository.create(createTestQuestion(id: 'q1', type: QuestionType.singleChoice));
        await repository.create(createTestQuestion(id: 'q2', type: QuestionType.multiChoice));
        await repository.create(createTestQuestion(id: 'q3', type: QuestionType.singleChoice));
        final result = await repository.getByType(QuestionType.singleChoice);
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 2);
      });

      test('returns empty for type with no questions', () async {
        final result = await repository.getByType(QuestionType.essay);
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });

    group('getBySubjectAndType', () {
      test('returns filtered questions by subject and type', () async {
        await repository.create(createTestQuestion(id: 'q1', subjectId: 's1', type: QuestionType.singleChoice));
        await repository.create(createTestQuestion(id: 'q2', subjectId: 's1', type: QuestionType.multiChoice));
        await repository.create(createTestQuestion(id: 'q3', subjectId: 's2', type: QuestionType.singleChoice));
        final result = await repository.getBySubjectAndType('s1', QuestionType.singleChoice);
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 1);
      });

      test('returns empty when no match', () async {
        final result = await repository.getBySubjectAndType('s1', QuestionType.essay);
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });

    group('updateMarkscheme', () {
      test('updates markscheme for existing question', () async {
        final question = createTestQuestion(id: 'q1');
        await repository.create(question);
        final markscheme = Markscheme(correctAnswer: 'Paris');
        final result = await repository.updateMarkscheme('q1', markscheme);
        expect(result.isSuccess, isTrue);
        final stored = await repository.get('q1');
        expect(stored!.markscheme?.correctAnswer, 'Paris');
      });

      test('returns failure for non-existent question', () async {
        final markscheme = Markscheme(correctAnswer: 'Paris');
        final result = await repository.updateMarkscheme('none', markscheme);
        expect(result.isFailure, isTrue);
      });
    });

    group('getQuestionsWithMarkschemes', () {
      test('returns questions with markscheme for subject', () async {
        final ms = Markscheme(correctAnswer: 'Paris');
        await repository.create(createTestQuestion(id: 'q1', subjectId: 's1', markscheme: ms));
        await repository.create(createTestQuestion(id: 'q2', subjectId: 's1', markscheme: ms));
        await repository.create(createTestQuestion(id: 'q3', subjectId: 's1'));
        final result = await repository.getQuestionsWithMarkschemes('s1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 2);
      });

      test('returns failure when no questions with markscheme', () async {
        await repository.create(createTestQuestion(id: 'q1', subjectId: 's1'));
        final result = await repository.getQuestionsWithMarkschemes('s1');
        expect(result.isFailure, isTrue);
      });

      test('returns failure when no questions for subject', () async {
        final result = await repository.getQuestionsWithMarkschemes('empty');
        expect(result.isFailure, isTrue);
      });
    });

    group('delete', () {
      test('removes question', () async {
        await repository.create(createTestQuestion(id: 'q1'));
        await repository.delete('q1');
        final stored = await repository.get('q1');
        expect(stored, isNull);
      });

      test('does not throw for non-existent question', () async {
        await repository.delete('none');
      });
    });
  });
}
