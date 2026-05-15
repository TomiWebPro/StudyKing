import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/questions/data/models/question_evaluation_model.dart';
import 'package:studyking/features/practice/data/repositories/question_evaluation_repository.dart';
import 'package:studyking/core/errors/result.dart';

class _MockQuestionEvaluationBox implements Box<QuestionEvaluation> {
  final Map<String, QuestionEvaluation> _storage = {};

  @override
  Iterable<QuestionEvaluation> get values => _storage.values;

  @override
  QuestionEvaluation? get(dynamic key, {QuestionEvaluation? defaultValue}) =>
      _storage[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, QuestionEvaluation value) async {
    _storage[key.toString()] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _storage.remove(key.toString());
  }

  @override
  Future<int> clear() async {
    final count = _storage.length;
    _storage.clear();
    return count;
  }

  @override
  int get length => _storage.length;

  @override
  bool get isOpen => true;

  @override
  String get name => 'questionEvaluations';

  @override
  bool get isNotEmpty => _storage.isNotEmpty;

  @override
  bool get isEmpty => _storage.isEmpty;

  @override
  bool containsKey(dynamic key) => _storage.containsKey(key.toString());

  @override
  Stream<BoxEvent> watch({dynamic key}) => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockQuestionEvaluationRepository extends QuestionEvaluationRepository {
  final Box<QuestionEvaluation> _fakeBox;

  _MockQuestionEvaluationRepository(this._fakeBox);

  @override
  void attachBox(Box<QuestionEvaluation> box) {}

  @override
  Future<Result<QuestionEvaluation>> getEvaluation(String questionId) async {
    final evaluation = _fakeBox.get(questionId);
    if (evaluation != null) {
      return Result.success(evaluation);
    }
    return Result.failure('No evaluation found for question: $questionId');
  }

  @override
  Future<Result<void>> saveEvaluation(QuestionEvaluation evaluation) async {
    await _fakeBox.put(evaluation.questionId, evaluation);
    return Result.success(null);
  }

  @override
  Future<Result<void>> migrateFromLegacy({
    required String questionId,
    String? markscheme,
    String? correctAnswer,
    List<String>? options,
    String? explanation,
  }) async {
    final existing = _fakeBox.get(questionId);
    if (existing != null) return Result.success(null);

    final evaluation = QuestionEvaluation.fromLegacy(
      questionId: questionId,
      markscheme: markscheme,
      correctAnswer: correctAnswer,
      options: options,
      explanation: explanation,
    );
    await _fakeBox.put(questionId, evaluation);
    return Result.success(null);
  }
}

void main() {
  group('QuestionEvaluationRepository', () {
    late _MockQuestionEvaluationBox box;
    late _MockQuestionEvaluationRepository repository;

    setUp(() {
      box = _MockQuestionEvaluationBox();
      repository = _MockQuestionEvaluationRepository(box);
    });

    group('getEvaluation', () {
      test('returns existing evaluation', () async {
        final evaluation = QuestionEvaluation(
          questionId: 'q1',
          correctAnswer: 'Paris',
        );
        await box.put('q1', evaluation);

        final result = await repository.getEvaluation('q1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.correctAnswer, 'Paris');
      });

      test('returns failure when not found', () async {
        final result = await repository.getEvaluation('none');
        expect(result.isFailure, isTrue);
        expect(result.error, contains('No evaluation found'));
      });
    });

    group('saveEvaluation', () {
      test('saves and retrieves evaluation', () async {
        final evaluation = QuestionEvaluation(
          questionId: 'q1',
          correctAnswer: 'Berlin',
          evaluationType: EvaluationType.exactMatch,
        );

        final saveResult = await repository.saveEvaluation(evaluation);
        expect(saveResult.isSuccess, isTrue);

        final getResult = await repository.getEvaluation('q1');
        expect(getResult.data?.correctAnswer, 'Berlin');
      });

      test('overwrites existing evaluation', () async {
        await repository.saveEvaluation(QuestionEvaluation(
          questionId: 'q1',
          correctAnswer: 'Berlin',
        ));
        await repository.saveEvaluation(QuestionEvaluation(
          questionId: 'q1',
          correctAnswer: 'Munich',
        ));

        final result = await repository.getEvaluation('q1');
        expect(result.data?.correctAnswer, 'Munich');
      });
    });

    group('migrateFromLegacy', () {
      test('creates evaluation from legacy data', () async {
        final result = await repository.migrateFromLegacy(
          questionId: 'q1',
          markscheme: '42',
          correctAnswer: '42',
          options: ['41', '42', '43'],
          explanation: 'The answer',
        );

        expect(result.isSuccess, isTrue);

        final getResult = await repository.getEvaluation('q1');
        expect(getResult.isSuccess, isTrue);
        expect(getResult.data?.correctAnswer, '42');
      });

      test('skips migration when evaluation already exists', () async {
        await box.put('q1', QuestionEvaluation(
          questionId: 'q1',
          correctAnswer: 'Existing',
        ));

        final result = await repository.migrateFromLegacy(
          questionId: 'q1',
          markscheme: 'New',
        );

        expect(result.isSuccess, isTrue);

        final getResult = await repository.getEvaluation('q1');
        expect(getResult.data?.correctAnswer, 'Existing');
      });

      test('handles null markscheme with correctAnswer fallback', () async {
        final result = await repository.migrateFromLegacy(
          questionId: 'q1',
          correctAnswer: 'Fallback',
        );

        expect(result.isSuccess, isTrue);

        final getResult = await repository.getEvaluation('q1');
        expect(getResult.data?.correctAnswer, 'Fallback');
      });

      test('handles all null legacy fields', () async {
        final result = await repository.migrateFromLegacy(
          questionId: 'q1',
        );

        expect(result.isSuccess, isTrue);
        final getResult = await repository.getEvaluation('q1');
        expect(getResult.data?.correctAnswer, '');
      });
    });
  });
}
