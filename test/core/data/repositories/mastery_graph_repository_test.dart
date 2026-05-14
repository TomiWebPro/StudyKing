import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/data/models/topic_dependency_model.dart';
import 'package:studyking/core/data/models/question_evaluation_model.dart';

class MockMasteryBox implements Box<MasteryState> {
  final Map<String, MasteryState> _storage = {};
  final bool _isOpen = true;

  @override
  Iterable<MasteryState> get values => _storage.values;

  @override
  MasteryState? get(dynamic key, {MasteryState? defaultValue}) =>
      _storage[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, MasteryState value) async {
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
  bool get isOpen => _isOpen;

  @override
  String get name => 'mastery_states';

  @override
  int get length => _storage.length;

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

class MockQuestionMasteryBox implements Box<QuestionMasteryState> {
  final Map<String, QuestionMasteryState> _storage = {};
  final bool _isOpen = true;

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
  bool get isOpen => _isOpen;

  @override
  String get name => 'question_mastery_states';

  @override
  int get length => _storage.length;

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

class MockDependencyBox implements Box<TopicDependency> {
  final Map<String, TopicDependency> _storage = {};
  final bool _isOpen = true;

  @override
  Iterable<TopicDependency> get values => _storage.values;

  @override
  TopicDependency? get(dynamic key, {TopicDependency? defaultValue}) =>
      _storage[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, TopicDependency value) async {
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
  bool get isOpen => _isOpen;

  @override
  String get name => 'topic_dependencies';

  @override
  int get length => _storage.length;

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

class MockEvalBox implements Box<QuestionEvaluation> {
  final Map<String, QuestionEvaluation> _storage = {};
  final bool _isOpen = true;

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
  bool get isOpen => _isOpen;

  @override
  String get name => 'question_evaluations';

  @override
  int get length => _storage.length;

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
  group('MasteryGraphRepository', () {
    late MockMasteryBox masteryBox;
    late MockQuestionMasteryBox questionMasteryBox;
    late MockDependencyBox dependencyBox;
    late MockEvalBox evalBox;
    late MasteryGraphRepository repository;

    setUp(() {
      masteryBox = MockMasteryBox();
      questionMasteryBox = MockQuestionMasteryBox();
      dependencyBox = MockDependencyBox();
      evalBox = MockEvalBox();
      repository = MasteryGraphRepository.test(
        masteryBox: masteryBox,
        questionMasteryBox: questionMasteryBox,
        dependencyBox: dependencyBox,
        evaluationBox: evalBox,
      );
    });

    group('getMasteryState', () {
      test('creates new state when not found', () async {
        final result = await repository.getMasteryState('s1', 't1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.studentId, 's1');
        expect(result.data?.topicId, 't1');
        expect(result.data?.totalAttempts, 0);
      });

      test('returns existing state', () async {
        final state = MasteryState.initial(studentId: 's1', topicId: 't1').copyWith(totalAttempts: 1);
        await repository.updateMasteryState(state);
        final result = await repository.getMasteryState('s1', 't1');
        expect(result.data?.totalAttempts, 1);
      });
    });

    group('updateMasteryState', () {
      test('updates existing state', () async {
        final state = MasteryState.initial(studentId: 's1', topicId: 't1');
        final result = await repository.updateMasteryState(state);
        expect(result.isSuccess, isTrue);
      });
    });

    group('getAllMasteryStates', () {
      test('returns states for student', () async {
        final s1 = MasteryState.initial(studentId: 's1', topicId: 't1');
        final s2 = MasteryState.initial(studentId: 's1', topicId: 't2');
        final s3 = MasteryState.initial(studentId: 's2', topicId: 't1');
        await repository.updateMasteryState(s1);
        await repository.updateMasteryState(s2);
        await repository.updateMasteryState(s3);
        final result = await repository.getAllMasteryStates('s1');
        expect(result.data?.length, 2);
      });

      test('returns empty for student with no states', () async {
        final result = await repository.getAllMasteryStates('none');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });

    group('getQuestionMasteryState', () {
      test('creates new when not found', () async {
        final result = await repository.getQuestionMasteryState('s1', 'q1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.studentId, 's1');
      });

      test('returns existing', () async {
        final state = QuestionMasteryState.initial(studentId: 's1', questionId: 'q1');
        await repository.updateQuestionMasteryState(state);
        final result = await repository.getQuestionMasteryState('s1', 'q1');
        expect(result.data?.questionId, 'q1');
      });
    });

    group('getDueQuestions', () {
      test('returns sorted due questions', () async {
        final future = QuestionMasteryState(studentId: 's1', questionId: 'q1', lastAttempt: DateTime.now(), nextReview: DateTime(2099, 1, 1));
        final past = QuestionMasteryState(studentId: 's1', questionId: 'q2', lastAttempt: DateTime.now(), nextReview: DateTime(2020, 1, 1));
        await repository.updateQuestionMasteryState(future);
        await repository.updateQuestionMasteryState(past);
        final result = await repository.getDueQuestions('s1');
        expect(result.data?.length, 1);
        expect(result.data?.first.questionId, 'q2');
      });

      test('accepts custom asOf date', () async {
        final past = QuestionMasteryState(studentId: 's1', questionId: 'q1', lastAttempt: DateTime.now(), nextReview: DateTime(2020, 1, 1));
        final recent = QuestionMasteryState(studentId: 's1', questionId: 'q2', lastAttempt: DateTime.now(), nextReview: DateTime(2025, 6, 1));
        await repository.updateQuestionMasteryState(past);
        await repository.updateQuestionMasteryState(recent);
        final result = await repository.getDueQuestions('s1', asOf: DateTime(2023, 1, 1));
        expect(result.data?.length, 1);
        expect(result.data?.first.questionId, 'q1');
      });

      test('returns empty when no due questions', () async {
        final future = QuestionMasteryState(studentId: 's1', questionId: 'q1', lastAttempt: DateTime.now(), nextReview: DateTime(2099, 1, 1));
        await repository.updateQuestionMasteryState(future);
        final result = await repository.getDueQuestions('s1');
        expect(result.data, isEmpty);
      });
    });

    group('getAtRiskQuestions', () {
      test('returns questions below threshold', () async {
        final low = QuestionMasteryState(studentId: 's1', questionId: 'q1', lastAttempt: DateTime.now(), masteryLevel: 0.3);
        final high = QuestionMasteryState(studentId: 's1', questionId: 'q2', lastAttempt: DateTime.now(), masteryLevel: 0.8);
        await repository.updateQuestionMasteryState(low);
        await repository.updateQuestionMasteryState(high);
        final result = await repository.getAtRiskQuestions('s1');
        expect(result.data?.length, 1);
        expect(result.data?.first.questionId, 'q1');
      });

      test('accepts custom threshold', () async {
        final medium = QuestionMasteryState(studentId: 's1', questionId: 'q1', lastAttempt: DateTime.now(), masteryLevel: 0.6);
        final high = QuestionMasteryState(studentId: 's1', questionId: 'q2', lastAttempt: DateTime.now(), masteryLevel: 0.9);
        await repository.updateQuestionMasteryState(medium);
        await repository.updateQuestionMasteryState(high);
        final result = await repository.getAtRiskQuestions('s1', threshold: 0.7);
        expect(result.data?.length, 1);
        expect(result.data?.first.questionId, 'q1');
      });

      test('returns empty when none at risk', () async {
        final high = QuestionMasteryState(studentId: 's1', questionId: 'q1', lastAttempt: DateTime.now(), masteryLevel: 0.9);
        await repository.updateQuestionMasteryState(high);
        final result = await repository.getAtRiskQuestions('s1');
        expect(result.data, isEmpty);
      });
    });

    group('getTopicDependency', () {
      test('creates new when not found', () async {
        final result = await repository.getTopicDependency('t1');
        expect(result.data?.topicId, 't1');
      });

      test('returns existing', () async {
          await repository.updateTopicDependency(TopicDependency(topicId: 't1', prerequisites: ['t0']));
        final result = await repository.getTopicDependency('t1');
        expect(result.data?.prerequisites, ['t0']);
      });
    });

    group('updateTopicDependency', () {
      test('updates topic dependency', () async {
        final dep = TopicDependency(topicId: 't1', prerequisites: ['t0']);
        final result = await repository.updateTopicDependency(dep);
        expect(result.isSuccess, isTrue);
        final stored = await repository.getTopicDependency('t1');
        expect(stored.data?.prerequisites, ['t0']);
      });
    });

    group('getAllDependencies', () {
      test('returns all', () async {
        await repository.updateTopicDependency(TopicDependency(topicId: 't1'));
        await repository.updateTopicDependency(TopicDependency(topicId: 't2'));
        final result = await repository.getAllDependencies();
        expect(result.data?.length, 2);
      });

      test('returns empty when none', () async {
        final result = await repository.getAllDependencies();
        expect(result.data, isEmpty);
      });
    });

    group('getEvaluation', () {
      test('returns failure when not found', () async {
        final result = await repository.getEvaluation('none');
        expect(result.isFailure, isTrue);
      });

      test('returns existing evaluation', () async {
        final eval = QuestionEvaluation(questionId: 'q1', correctAnswer: 'Paris');
        await repository.saveEvaluation(eval);
        final result = await repository.getEvaluation('q1');
        expect(result.data?.correctAnswer, 'Paris');
      });
    });

    group('saveEvaluation', () {
      test('saves evaluation', () async {
        final eval = QuestionEvaluation(questionId: 'q1', correctAnswer: 'Paris');
        final result = await repository.saveEvaluation(eval);
        expect(result.isSuccess, isTrue);
        final stored = await repository.getEvaluation('q1');
        expect(stored.data?.correctAnswer, 'Paris');
      });
    });

    group('migrateFromLegacy', () {
      test('creates evaluation from legacy data', () async {
        final result = await repository.migrateFromLegacy(
          questionId: 'q1',
          markscheme: 'Paris',
          correctAnswer: 'London',
          options: ['A', 'B'],
          explanation: 'Capital of France',
        );
        expect(result.isSuccess, isTrue);
        final stored = await repository.getEvaluation('q1');
        expect(stored.data?.correctAnswer, 'Paris');
        expect(stored.data?.acceptableAnswers, ['A', 'B']);
        expect(stored.data?.explanation, 'Capital of France');
      });

      test('skips if evaluation already exists', () async {
        await repository.saveEvaluation(QuestionEvaluation(questionId: 'q1', correctAnswer: 'Existing'));
        final result = await repository.migrateFromLegacy(
          questionId: 'q1',
          markscheme: 'New',
        );
        expect(result.isSuccess, isTrue);
        final stored = await repository.getEvaluation('q1');
        expect(stored.data?.correctAnswer, 'Existing');
      });
    });

    group('getTopicsNeedingReview', () {
      test('returns topics with high review urgency', () async {
        final now = DateTime.now();
        final urgent = MasteryState(studentId: 's1', topicId: 't1', lastAttempt: now, lastUpdated: now, reviewUrgency: 0.8);
        final notUrgent = MasteryState(studentId: 's1', topicId: 't2', lastAttempt: now, lastUpdated: now, reviewUrgency: 0.3);
        await repository.updateMasteryState(urgent);
        await repository.updateMasteryState(notUrgent);
        final result = await repository.getTopicsNeedingReview('s1');
        expect(result.data?.length, 1);
        expect(result.data?.first.topicId, 't1');
      });

      test('returns empty when no topics need review', () async {
        final now = DateTime.now();
        final low = MasteryState(studentId: 's1', topicId: 't1', lastAttempt: now, lastUpdated: now, reviewUrgency: 0.3);
        await repository.updateMasteryState(low);
        final result = await repository.getTopicsNeedingReview('s1');
        expect(result.data, isEmpty);
      });
    });

    group('getWeakTopics', () {
      test('returns topics with low accuracy', () async {
        final now = DateTime.now();
        final weak = MasteryState(studentId: 's1', topicId: 't1', lastAttempt: now, lastUpdated: now, accuracy: 0.5);
        final strong = MasteryState(studentId: 's1', topicId: 't2', lastAttempt: now, lastUpdated: now, accuracy: 0.9);
        await repository.updateMasteryState(weak);
        await repository.updateMasteryState(strong);
        final result = await repository.getWeakTopics('s1');
        expect(result.data?.length, 1);
        expect(result.data?.first.topicId, 't1');
      });

      test('returns empty when no weak topics', () async {
        final now = DateTime.now();
        final strong = MasteryState(studentId: 's1', topicId: 't1', lastAttempt: now, lastUpdated: now, accuracy: 0.9);
        await repository.updateMasteryState(strong);
        final result = await repository.getWeakTopics('s1');
        expect(result.data, isEmpty);
      });
    });

    group('getMasterySnapshot', () {
      test('returns snapshot for student', () async {
        final now = DateTime.now();
        await repository.updateMasteryState(MasteryState(studentId: 's1', topicId: 't1', lastAttempt: now, lastUpdated: now, accuracy: 0.8, masteryLevel: MasteryLevel.proficient, totalAttempts: 10));
        await repository.updateMasteryState(MasteryState(studentId: 's1', topicId: 't2', lastAttempt: now, lastUpdated: now, accuracy: 0.5, masteryLevel: MasteryLevel.developing, totalAttempts: 5));
        final result = await repository.getMasterySnapshot('s1');
        expect(result.isSuccess, isTrue);
        expect(result.data?['totalTopics'], 2);
        expect(result.data?['totalAttempts'], 15);
      });

      test('returns zeros for student with no states', () async {
        final result = await repository.getMasterySnapshot('empty');
        expect(result.isSuccess, isTrue);
        expect(result.data?['totalTopics'], 0);
        expect(result.data?['totalAttempts'], 0);
        expect(result.data?['averageAccuracy'], 0.0);
        expect(result.data?['avgReadiness'], 0.0);
      });
    });
  });
}
