import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/practice/data/adapters/question_mastery_state_adapter.dart';
import 'package:studyking/features/practice/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/errors/result.dart';

class _MockQuestionMasteryStateBox implements Box<QuestionMasteryState> {
  final Map<String, QuestionMasteryState> _storage = {};

  @override
  Iterable<QuestionMasteryState> get values => _storage.values;

  @override
  QuestionMasteryState? get(dynamic key, {QuestionMasteryState? defaultValue}) =>
      _storage[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, QuestionMasteryState value) async {
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
  String get name => 'questionMasteryStates';

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

class _MockQuestionMasteryStateRepository extends QuestionMasteryStateRepository {
  final Box<QuestionMasteryState> _fakeBox;

  _MockQuestionMasteryStateRepository(this._fakeBox);

  @override
  void attachBox(Box<QuestionMasteryState> box) {}

  @override
  Future<Result<QuestionMasteryState>> getQuestionMasteryState(
    String studentId,
    String questionId,
  ) async {
    final key = '${studentId}_$questionId';
    final state = _fakeBox.get(key);
    if (state != null) {
      return Result.success(state);
    }
    final newState = QuestionMasteryState.initial(now: DateTime.now(),
        studentId: studentId, questionId: questionId);
    await _fakeBox.put(key, newState);
    return Result.success(newState);
  }

  @override
  Future<Result<void>> updateQuestionMasteryState(
      QuestionMasteryState state) async {
    final key = '${state.studentId}_${state.questionId}';
    await _fakeBox.put(key, state);
    return Result.success(null);
  }

  @override
  Future<Result<List<QuestionMasteryState>>> getDueQuestions(
    String studentId, {
    DateTime? asOf,
  }) async {
    final now = asOf ?? DateTime.now();
    final states = _fakeBox.values
        .where((s) =>
            s.studentId == studentId &&
            s.nextReview != null &&
            s.nextReview!.isBefore(now))
        .toList();
    states.sort((a, b) =>
        (a.nextReview ?? DateTime.now())
            .compareTo(b.nextReview ?? DateTime.now()));
    return Result.success(states);
  }

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(
    String studentId, {
    double threshold = 0.5,
  }) async {
    final states = _fakeBox.values
        .where((s) =>
            s.studentId == studentId && s.masteryLevel < threshold)
        .toList();
    states.sort((a, b) => a.masteryLevel.compareTo(b.masteryLevel));
    return Result.success(states);
  }
}

QuestionMasteryState _createQS({
  String studentId = 's1',
  String questionId = 'q1',
  DateTime? nextReview,
  double masteryLevel = 0.5,
}) {
  return QuestionMasteryState(
    studentId: studentId,
    questionId: questionId,
    lastAttempt: DateTime(2026, 5, 12),
    nextReview: nextReview,
    masteryLevel: masteryLevel,
  );
}

void main() {
  group('QuestionMasteryStateRepository', () {
    late _MockQuestionMasteryStateBox box;
    late _MockQuestionMasteryStateRepository repository;

    setUp(() {
      box = _MockQuestionMasteryStateBox();
      repository = _MockQuestionMasteryStateRepository(box);
    });

    group('getQuestionMasteryState', () {
      test('returns existing state when found', () async {
        final state = _createQS();
        await box.put('s1_q1', state);

        final result = await repository.getQuestionMasteryState('s1', 'q1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.questionId, 'q1');
      });

      test('creates initial state when not found', () async {
        final result = await repository.getQuestionMasteryState('s1', 'q1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.studentId, 's1');
        expect(result.data?.questionId, 'q1');
        expect(result.data?.correctCount, 0);
      });

      test('returns distinct states for different pairs', () async {
        final result1 = await repository.getQuestionMasteryState('s1', 'q1');
        final result2 = await repository.getQuestionMasteryState('s2', 'q2');

        expect(result1.data?.studentId, 's1');
        expect(result1.data?.questionId, 'q1');
        expect(result2.data?.studentId, 's2');
        expect(result2.data?.questionId, 'q2');
      });
    });

    group('updateQuestionMasteryState', () {
      test('saves and retrieves updated state', () async {
        final state = _createQS(masteryLevel: 0.8);
        await repository.updateQuestionMasteryState(state);

        final result = await repository.getQuestionMasteryState('s1', 'q1');
        expect(result.data?.masteryLevel, 0.8);
      });

      test('overwrites existing state', () async {
        final state1 = _createQS(masteryLevel: 0.3);
        await repository.updateQuestionMasteryState(state1);

        final state2 = _createQS(masteryLevel: 0.9);
        await repository.updateQuestionMasteryState(state2);

        final result = await repository.getQuestionMasteryState('s1', 'q1');
        expect(result.data?.masteryLevel, 0.9);
      });
    });

    group('getDueQuestions', () {
      test('returns questions with past nextReview', () async {
        await box.put('s1_q1', _createQS(
          questionId: 'q1', nextReview: DateTime(2020, 1, 1)));
        await box.put('s1_q2', _createQS(
          questionId: 'q2', nextReview: DateTime(2099, 1, 1)));

        final result = await repository.getDueQuestions('s1',
            asOf: DateTime(2026, 5, 12));
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 1);
        expect(result.data![0].questionId, 'q1');
      });

      test('returns empty when none due', () async {
        await box.put('s1_q1', _createQS(
          questionId: 'q1', nextReview: DateTime(2099, 1, 1)));

        final result = await repository.getDueQuestions('s1',
            asOf: DateTime(2026, 5, 12));
        expect(result.data, isEmpty);
      });

      test('excludes other students questions', () async {
        await box.put('s1_q1', _createQS(
          questionId: 'q1', nextReview: DateTime(2020, 1, 1)));
        await box.put('s2_q2', _createQS(
          studentId: 's2', questionId: 'q2',
          nextReview: DateTime(2020, 1, 1)));

        final result = await repository.getDueQuestions('s1',
            asOf: DateTime(2026, 5, 12));
        expect(result.data?.length, 1);
      });

      test('sorts due questions by nextReview ascending', () async {
        await box.put('s1_q1', _createQS(
          questionId: 'q1', nextReview: DateTime(2020, 6, 1)));
        await box.put('s1_q2', _createQS(
          questionId: 'q2', nextReview: DateTime(2020, 1, 1)));

        final result = await repository.getDueQuestions('s1',
            asOf: DateTime(2026, 5, 12));
        expect(result.data![0].questionId, 'q2');
        expect(result.data![1].questionId, 'q1');
      });
    });

    group('getAtRiskQuestions', () {
      test('returns questions below mastery threshold', () async {
        await box.put('s1_q1', _createQS(questionId: 'q1', masteryLevel: 0.3));
        await box.put('s1_q2', _createQS(questionId: 'q2', masteryLevel: 0.7));
        await box.put('s1_q3', _createQS(questionId: 'q3', masteryLevel: 0.4));

        final result = await repository.getAtRiskQuestions('s1');
        expect(result.data?.length, 2);
      });

      test('returns empty when all above threshold', () async {
        await box.put('s1_q1', _createQS(questionId: 'q1', masteryLevel: 0.7));
        await box.put('s1_q2', _createQS(questionId: 'q2', masteryLevel: 0.9));

        final result = await repository.getAtRiskQuestions('s1');
        expect(result.data, isEmpty);
      });

      test('sorts by masteryLevel ascending', () async {
        await box.put('s1_q1', _createQS(questionId: 'q1', masteryLevel: 0.4));
        await box.put('s1_q2', _createQS(questionId: 'q2', masteryLevel: 0.1));
        await box.put('s1_q3', _createQS(questionId: 'q3', masteryLevel: 0.3));

        final result = await repository.getAtRiskQuestions('s1');
        expect(result.data![0].masteryLevel, 0.1);
        expect(result.data![1].masteryLevel, 0.3);
        expect(result.data![2].masteryLevel, 0.4);
      });

      test('uses custom threshold', () async {
        await box.put('s1_q1', _createQS(questionId: 'q1', masteryLevel: 0.6));
        await box.put('s1_q2', _createQS(questionId: 'q2', masteryLevel: 0.8));

        final result = await repository.getAtRiskQuestions('s1', threshold: 0.7);
        expect(result.data?.length, 1);
        expect(result.data![0].questionId, 'q1');
      });
    });
  });

  group('QuestionMasteryStateRepository (init with real Hive)', () {
    late QuestionMasteryStateRepository repository;
    late String hivePath;

    setUpAll(() {
      Hive.registerAdapter(QuestionMasteryStateAdapter());
    });

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('qms_repo_test_');
      hivePath = dir.path;
      Hive.init(hivePath);
      repository = QuestionMasteryStateRepository();
      await repository.init();
    });

    tearDown(() async {
      await Hive.box<QuestionMasteryState>('question_mastery_states').close();
      await Hive.deleteBoxFromDisk('question_mastery_states');
    });

    test('init opens box and supports CRUD', () async {
      final state = QuestionMasteryState.initial(studentId: 's1', questionId: 'q1', now: DateTime.now());
      await repository.updateQuestionMasteryState(state);
      final result = await repository.getQuestionMasteryState('s1', 'q1');
      expect(result.isSuccess, isTrue);
      expect(result.data?.questionId, 'q1');
    });

    test('getDueQuestions works after init', () async {
      await repository.updateQuestionMasteryState(QuestionMasteryState.initial(studentId: 's1', questionId: 'q1', now: DateTime(2020, 1, 1)));
      await repository.updateQuestionMasteryState(QuestionMasteryState.initial(studentId: 's1', questionId: 'q2', now: DateTime.now()));
      final result = await repository.getDueQuestions('s1', asOf: DateTime(2026, 5, 12));
      expect(result.data?.length, 1);
      expect(result.data![0].questionId, 'q1');
    });

    test('getAtRiskQuestions works after init', () async {
      await repository.updateQuestionMasteryState(_createQS(questionId: 'q1', masteryLevel: 0.3));
      await repository.updateQuestionMasteryState(_createQS(questionId: 'q2', masteryLevel: 0.8));
      final result = await repository.getAtRiskQuestions('s1');
      expect(result.data?.length, 1);
      expect(result.data![0].questionId, 'q1');
    });
  });
}
