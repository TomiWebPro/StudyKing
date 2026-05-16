import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/practice/data/repositories/question_choice_repository.dart';
import 'package:studyking/features/practice/data/models/answer_model.dart';

class _MockQuestionChoiceRepository extends QuestionChoiceRepository {
  final Map<String, QuestionChoice> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> create(QuestionChoice choice) async {
    _storage[choice.id] = choice;
    return Result.success(null);
  }

  @override
  Future<QuestionChoice?> get(String id) async {
    return _storage[id];
  }

  @override
  Future<Result<List<QuestionChoice>>> getByQuestion(String questionId) async {
    return Result.success(_storage.values.where((a) => a.questionId == questionId).toList());
  }
}

void main() {
  group('QuestionChoiceRepository', () {
    late _MockQuestionChoiceRepository repository;

    setUp(() {
      repository = _MockQuestionChoiceRepository();
    });

    group('create', () {
      test('stores a question choice', () async {
        final choice = QuestionChoice(id: 'a1', questionId: 'q1', text: 'Paris', isCorrect: true);
        await repository.create(choice);
        final stored = await repository.get('a1');
        expect(stored?.text, 'Paris');
      });
    });

    group('get', () {
      test('returns null for non-existent', () async {
        expect(await repository.get('none'), isNull);
      });

      test('returns stored choice', () async {
        final choice = QuestionChoice(id: 'a1', questionId: 'q1', text: 'Paris', isCorrect: true);
        await repository.create(choice);
        expect(await repository.get('a1'), isNotNull);
      });
    });

    group('getByQuestion', () {
      test('returns choices for question', () async {
        await repository.create(QuestionChoice(id: 'a1', questionId: 'q1', text: 'A', isCorrect: true));
        await repository.create(QuestionChoice(id: 'a2', questionId: 'q1', text: 'B', isCorrect: false));
        await repository.create(QuestionChoice(id: 'a3', questionId: 'q2', text: 'C', isCorrect: true));
        final result = await repository.getByQuestion('q1');
        expect(result.isSuccess, isTrue);
        expect(result.data!.length, 2);
      });

      test('returns empty list when no choices for question', () async {
        final result = await repository.getByQuestion('none');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });
  });
}
