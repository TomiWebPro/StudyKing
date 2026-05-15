import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/practice/data/repositories/answer_repository.dart';
import 'package:studyking/features/practice/data/models/answer_model.dart';

class _MockAnswerRepository extends AnswerRepository {
  final Map<String, Answer> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> create(Answer answer) async {
    _storage[answer.id] = answer;
    return Result.success(null);
  }

  @override
  Future<Answer?> get(String id) async {
    return _storage[id];
  }

  @override
  Future<Result<List<Answer>>> getByQuestion(String questionId) async {
    return Result.success(_storage.values.where((a) => a.questionId == questionId).toList());
  }
}

void main() {
  group('AnswerRepository', () {
    late _MockAnswerRepository repository;

    setUp(() {
      repository = _MockAnswerRepository();
    });

    group('create', () {
      test('stores an answer', () async {
        final answer = Answer(id: 'a1', questionId: 'q1', text: 'Paris', isCorrect: true);
        await repository.create(answer);
        final stored = await repository.get('a1');
        expect(stored?.text, 'Paris');
      });
    });

    group('get', () {
      test('returns null for non-existent', () async {
        expect(await repository.get('none'), isNull);
      });

      test('returns stored answer', () async {
        final answer = Answer(id: 'a1', questionId: 'q1', text: 'Paris', isCorrect: true);
        await repository.create(answer);
        expect(await repository.get('a1'), isNotNull);
      });
    });

    group('getByQuestion', () {
      test('returns answers for question', () async {
        await repository.create(Answer(id: 'a1', questionId: 'q1', text: 'A', isCorrect: true));
        await repository.create(Answer(id: 'a2', questionId: 'q1', text: 'B', isCorrect: false));
        await repository.create(Answer(id: 'a3', questionId: 'q2', text: 'C', isCorrect: true));
        final result = await repository.getByQuestion('q1');
        expect(result.isSuccess, isTrue);
        expect(result.data!.length, 2);
      });

      test('returns empty list when no answers for question', () async {
        final result = await repository.getByQuestion('none');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });
  });
}
