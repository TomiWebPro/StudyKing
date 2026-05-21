import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/questions/data/adapters/question_evaluation_adapter.dart';
import 'package:studyking/features/questions/data/models/question_evaluation_model.dart';
import 'package:studyking/features/practice/data/repositories/question_evaluation_repository.dart';

class _FakeEvaluationBox implements Box<QuestionEvaluation> {
  final Map<String, QuestionEvaluation> _storage = {};
  bool _shouldThrow = false;

  void throwOnNextCall() => _shouldThrow = true;

  @override
  Iterable<QuestionEvaluation> get values {
    _checkThrow();
    return _storage.values;
  }

  @override
  QuestionEvaluation? get(dynamic key, {QuestionEvaluation? defaultValue}) {
    _checkThrow();
    return _storage[key] ?? defaultValue;
  }

  @override
  Future<void> put(dynamic key, QuestionEvaluation value) async {
    _checkThrow();
    _storage[key.toString()] = value;
  }

  void _checkThrow() {
    if (_shouldThrow) {
      _shouldThrow = false;
      throw Exception('simulated box error');
    }
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

void main() {
  group('QuestionEvaluationRepository', () {
    late _FakeEvaluationBox box;
    late QuestionEvaluationRepository repository;

    setUp(() {
      box = _FakeEvaluationBox();
      repository = QuestionEvaluationRepository();
      repository.attachBox(box);
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
      });

      test('returns failure on box error', () async {
        box.throwOnNextCall();
        final result = await repository.getEvaluation('q1');
        expect(result.isFailure, isTrue);
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

      test('returns failure on box error', () async {
        box.throwOnNextCall();
        final evaluation = QuestionEvaluation(
          questionId: 'q1',
          correctAnswer: 'Berlin',
        );
        final result = await repository.saveEvaluation(evaluation);
        expect(result.isFailure, isTrue);
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

      test('returns failure on box error during get', () async {
        box.throwOnNextCall();
        final result = await repository.migrateFromLegacy(
          questionId: 'q1',
          correctAnswer: '42',
        );
        expect(result.isFailure, isTrue);
      });
    });
  });

  group('QuestionEvaluationRepository (init with real Hive)', () {
    late QuestionEvaluationRepository repository;
    late String hivePath;

    setUpAll(() {
      Hive.registerAdapter(QuestionEvaluationAdapter());
      Hive.registerAdapter(EvaluationStepAdapter());
    });

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('qe_repo_test_');
      hivePath = dir.path;
      Hive.init(hivePath);
      repository = QuestionEvaluationRepository();
      await repository.init();
    });

    tearDown(() async {
      await Hive.box<QuestionEvaluation>('question_evaluations').close();
      await Hive.deleteBoxFromDisk('question_evaluations');
    });

    test('init opens box and supports CRUD', () async {
      final evaluation = QuestionEvaluation(questionId: 'q1', correctAnswer: 'Paris');
      await repository.saveEvaluation(evaluation);
      final result = await repository.getEvaluation('q1');
      expect(result.isSuccess, isTrue);
      expect(result.data?.correctAnswer, 'Paris');
    });

    test('migrateFromLegacy works after init', () async {
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

    test('overwrites existing evaluation after init', () async {
      await repository.saveEvaluation(QuestionEvaluation(questionId: 'q1', correctAnswer: 'Berlin'));
      await repository.saveEvaluation(QuestionEvaluation(questionId: 'q1', correctAnswer: 'Munich'));
      final result = await repository.getEvaluation('q1');
      expect(result.data?.correctAnswer, 'Munich');
    });
  });
}
