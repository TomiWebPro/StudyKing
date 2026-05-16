import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/errors/result.dart';

class _FakeQuestionBox implements Box<Question> {
  final Map<String, Question> _storage = {};

  @override
  Iterable<Question> get values => _storage.values;

  @override
  Question? get(dynamic key, {Question? defaultValue}) =>
      _storage[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, Question value) async {
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
  String get name => 'questions';

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

class _FakeClosedBox implements Box<Question> {
  @override
  Iterable<Question> get values => [];

  @override
  bool get isOpen => false;

  @override
  String get name => 'questions';

  @override
  bool get isNotEmpty => false;

  @override
  bool get isEmpty => true;

  @override
  int get length => 0;

  @override
  Question? get(dynamic key, {Question? defaultValue}) => null;

  @override
  bool containsKey(dynamic key) => false;

  @override
  Future<void> put(dynamic key, Question value) async {}

  @override
  Future<void> delete(dynamic key) async {}

  @override
  Future<int> clear() async => 0;

  @override
  Stream<BoxEvent> watch({dynamic key}) => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQuestionRepository extends QuestionRepository {
  final Box<Question> fakeBox;

  _FakeQuestionRepository(this.fakeBox);

  @override
  Future<void> init() async {}

  @override
  Box<Question> get box => fakeBox;

  @override
  Future<Question?> get(String id) async {
    return fakeBox.get(id);
  }

  @override
  Future<void> save(String key, Question item) async {
    await fakeBox.put(key, item);
  }

  @override
  Future<void> delete(String key) async {
    await fakeBox.delete(key);
  }

  @override
  Future<Result<void>> create(Question question) async {
    await fakeBox.put(question.id, question);
    return Result.success(null);
  }
}

class _FakeAttemptRepository extends AttemptRepository {
  final Map<String, StudentAttempt> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<StudentAttempt?> get(String id) async {
    return _storage[id];
  }
}

Question _createQuestion({
  String id = 'q1',
  String subjectId = 'sub1',
  String topicId = 't1',
  DateTime? nextReview,
}) {
  return Question(
    id: id,
    text: 'Sample question?',
    type: QuestionType.singleChoice,
    subjectId: subjectId,
    topicId: topicId,
    createdAt: DateTime(2026, 5, 12),
    updatedAt: DateTime(2026, 5, 12),
    nextReview: nextReview,
  );
}

void main() {
  group('SpacedRepetitionQueries', () {
    group('getQuestionsDueForReview', () {
      test('returns questions due before cutoff', () {
        final box = _FakeQuestionBox();
        box.put('q1', _createQuestion(
          id: 'q1', nextReview: DateTime(2020, 1, 1)));
        box.put('q2', _createQuestion(
          id: 'q2', nextReview: DateTime(2099, 1, 1)));

        final due = SpacedRepetitionQueries.getQuestionsDueForReview(
          box, asOf: DateTime(2026, 5, 12));
        expect(due.length, 1);
        expect(due.first.id, 'q1');
      });

      test('returns empty when none due', () {
        final box = _FakeQuestionBox();
        box.put('q1', _createQuestion(
          id: 'q1', nextReview: DateTime(2099, 1, 1)));

        final due = SpacedRepetitionQueries.getQuestionsDueForReview(
          box, asOf: DateTime(2026, 5, 12));
        expect(due, isEmpty);
      });

      test('sorts by nextReview ascending', () {
        final box = _FakeQuestionBox();
        box.put('q1', _createQuestion(
          id: 'q1', nextReview: DateTime(2020, 6, 1)));
        box.put('q2', _createQuestion(
          id: 'q2', nextReview: DateTime(2020, 1, 1)));

        final due = SpacedRepetitionQueries.getQuestionsDueForReview(
          box, asOf: DateTime(2026, 5, 12));
        expect(due[0].id, 'q2');
        expect(due[1].id, 'q1');
      });
    });

    group('getQuestionsDueAfter', () {
      test('returns questions due after date', () {
        final box = _FakeQuestionBox();
        box.put('q1', _createQuestion(
          id: 'q1', nextReview: DateTime(2020, 1, 1)));
        box.put('q2', _createQuestion(
          id: 'q2', nextReview: DateTime(2023, 6, 1)));

        final due = SpacedRepetitionQueries.getQuestionsDueAfter(
          box, DateTime(2023, 1, 1));
        expect(due.length, 1);
        expect(due.first.id, 'q1');
      });

      test('returns empty when no questions due', () {
        final box = _FakeQuestionBox();
        box.put('q1', _createQuestion(
          id: 'q1', nextReview: DateTime(2026, 6, 1)));

        final due = SpacedRepetitionQueries.getQuestionsDueAfter(
          box, DateTime(2026, 5, 12));
        expect(due, isEmpty);
      });
    });

    group('isQuestionDueForReview', () {
      test('returns true for past due question', () {
        final q = _createQuestion(nextReview: DateTime(2020, 1, 1));
        expect(SpacedRepetitionQueries.isQuestionDueForReview(q), isTrue);
      });

      test('returns false for future review question', () {
        final q = _createQuestion(nextReview: DateTime(2099, 1, 1));
        expect(
          SpacedRepetitionQueries.isQuestionDueForReview(
            q, asOf: DateTime(2026, 5, 12)),
          isFalse,
        );
      });

      test('returns false when nextReview is null', () {
        final q = _createQuestion();
        expect(
          SpacedRepetitionQueries.isQuestionDueForReview(q),
          isFalse,
        );
      });
    });

    group('mapQuestionsToStatus', () {
      test('returns correct status map', () {
        final box = _FakeQuestionBox();
        box.put('q1', _createQuestion(
          id: 'q1', nextReview: DateTime(2020, 1, 1)));
        box.put('q2', _createQuestion(
          id: 'q2', nextReview: DateTime(2099, 1, 1)));

        final status = SpacedRepetitionQueries.mapQuestionsToStatus(
          box, asOf: DateTime(2026, 5, 12));
        expect(status['q1'], 'due');
        expect(status['q2'], 'not-due');
      });

      test('returns empty map for empty box', () {
        final box = _FakeQuestionBox();
        final status = SpacedRepetitionQueries.mapQuestionsToStatus(box);
        expect(status, isEmpty);
      });
    });
  });

  group('SpacedRepetitionService', () {
    late _FakeQuestionBox questionBox;
    late _FakeAttemptRepository attemptRepo;
    late _FakeQuestionRepository questionRepo;
    late SpacedRepetitionService service;

    setUp(() {
      questionBox = _FakeQuestionBox();
      attemptRepo = _FakeAttemptRepository();
      questionRepo = _FakeQuestionRepository(questionBox);
      service = SpacedRepetitionService(
        questionRepo: questionRepo,
        attemptRepo: attemptRepo,
      );
    });

    group('getQuestionsDueForReview', () {
      test('returns due questions sorted', () {
        questionBox.put('q1', _createQuestion(
          id: 'q1', nextReview: DateTime(2020, 6, 1)));
        questionBox.put('q2', _createQuestion(
          id: 'q2', nextReview: DateTime(2020, 1, 1)));

        final due = service.getQuestionsDueForReview(asOf: DateTime(2026, 5, 12));
        expect(due.length, 2);
        expect(due[0].id, 'q2');
        expect(due[1].id, 'q1');
      });

      test('returns empty when none due', () {
        questionBox.put('q1', _createQuestion(
          id: 'q1', nextReview: DateTime(2099, 1, 1)));

        final due = service.getQuestionsDueForReview(asOf: DateTime(2026, 5, 12));
        expect(due, isEmpty);
      });
    });

    group('isQuestionDueForReview', () {
      test('returns true for past due question', () {
        final q = _createQuestion(nextReview: DateTime(2020, 1, 1));
        expect(service.isQuestionDueForReview(q), isTrue);
      });

      test('returns false for future review question', () {
        final q = _createQuestion(nextReview: DateTime(2099, 1, 1));
        expect(service.isQuestionDueForReview(q, asOf: DateTime(2026, 5, 12)), isFalse);
      });
    });

    group('getQuestionsDue', () {
      test('returns due questions successfully', () async {
        questionBox.put('q1', _createQuestion(
          id: 'q1', nextReview: DateTime(2020, 1, 1)));

        final result = await service.getQuestionsDue(asOf: DateTime(2026, 5, 12));
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 1);
      });

      test('returns failure when box is not open', () async {
        final closedRepo = _FakeQuestionRepository(_FakeClosedBox());
        final s = SpacedRepetitionService(
          questionRepo: closedRepo,
          attemptRepo: attemptRepo,
        );

        final result = await s.getQuestionsDue();
        expect(result.isFailure, isTrue);
        expect(result.error, contains('not open'));
      });

      test('returns empty when no questions due', () async {
        questionBox.put('q1', _createQuestion(
          id: 'q1', nextReview: DateTime(2099, 1, 1)));

        final result = await service.getQuestionsDue(asOf: DateTime(2026, 5, 12));
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });

    group('updateNextReviewDate', () {
      test('uses SM-2 engine: first review gets 1-day interval', () async {
        questionBox.put('q1', _createQuestion(id: 'q1'));
        final before = DateTime.now();

        final result = await service.updateNextReviewDate('q1', 0.95);
        expect(result.isSuccess, isTrue);

        final updated = questionBox.get('q1');
        expect(updated?.nextReview, isNotNull);
        final diff = updated!.nextReview!.difference(before).inMilliseconds;
        expect(diff, greaterThanOrEqualTo(24 * 60 * 60 * 1000 - 1000));
        expect(diff, lessThan(25 * 60 * 60 * 1000));
      });

      test('SM-2 interval grows with successive correct reviews', () async {
        questionBox.put('q1', _createQuestion(id: 'q1'));

        await service.updateNextReviewDate('q1', 0.95);
        final firstReview = questionBox.get('q1')!.nextReview!;
        final firstDiff = firstReview.difference(DateTime.now()).inMilliseconds;
        expect(firstDiff, greaterThanOrEqualTo(24 * 60 * 60 * 1000 - 1000));

        await service.updateNextReviewDate('q1', 0.95);
        final secondReview = questionBox.get('q1')!.nextReview!;
        final secondDiff = secondReview.difference(firstReview).inMilliseconds;
        expect(secondDiff, greaterThanOrEqualTo(5 * 24 * 60 * 60 * 1000 - 1000));
      });

      test('stores serialized SR data on question', () async {
        questionBox.put('q1', _createQuestion(id: 'q1'));

        await service.updateNextReviewDate('q1', 0.95);
        final updated = questionBox.get('q1')!;
        expect(updated.srDataJson, isNotNull);
        expect(updated.srDataJson, contains('"r"'));
      });

      test('returns failure for non-existent question', () async {
        final result = await service.updateNextReviewDate('none', 0.5);
        expect(result.isFailure, isTrue);
        expect(result.error, contains('not found'));
      });
    });

    group('getQuestionDueTimes', () {
      test('returns due times from attempt', () async {
        attemptRepo._storage['q1'] = StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          timestamp: DateTime.now(),
          lastDueDate: DateTime(2020, 1, 1),
        );

        final result = await service.getQuestionDueTimes('q1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 1);
        expect(result.data![0], DateTime(2020, 1, 1));
      });

      test('returns empty list when attempt has no due date', () async {
        attemptRepo._storage['q1'] = StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          timestamp: DateTime.now(),
        );

        final result = await service.getQuestionDueTimes('q1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('returns failure when no attempt found', () async {
        final result = await service.getQuestionDueTimes('none');
        expect(result.isFailure, isTrue);
        expect(result.error, contains('No attempts'));
      });
    });

    group('getPracticeQuestions', () {
      test('returns practice questions for subject', () async {
        questionBox.put('q1', _createQuestion(
          id: 'q1', subjectId: 'sub1', nextReview: DateTime(2020, 1, 1)));
        questionBox.put('q2', _createQuestion(
          id: 'q2', subjectId: 'sub2', nextReview: DateTime(2020, 1, 1)));

        final result = await service.getPracticeQuestions('sub1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 1);
      });

      test('returns empty when no practice questions for subject', () async {
        final result = await service.getPracticeQuestions('empty');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('returns failure when box not open', () async {
        final closedRepo = _FakeQuestionRepository(_FakeClosedBox());
        final s = SpacedRepetitionService(
          questionRepo: closedRepo,
          attemptRepo: attemptRepo,
        );

        final result = await s.getPracticeQuestions('sub1');
        expect(result.isFailure, isTrue);
        expect(result.error, contains('not open'));
      });
    });

    group('getTopicTimeDue', () {
      test('returns questions for topic', () async {
        questionBox.put('q1', _createQuestion(
          id: 'q1', topicId: 't1'));
        questionBox.put('q2', _createQuestion(
          id: 'q2', topicId: 't2'));

        final result = await service.getTopicTimeDue('t1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 1);
      });

      test('returns empty for topic with no questions', () async {
        final result = await service.getTopicTimeDue('none');
        expect(result.data, isEmpty);
      });

      test('returns failure when box not open', () async {
        final closedRepo = _FakeQuestionRepository(_FakeClosedBox());
        final s = SpacedRepetitionService(
          questionRepo: closedRepo,
          attemptRepo: attemptRepo,
        );

        final result = await s.getTopicTimeDue('t1');
        expect(result.isFailure, isTrue);
        expect(result.error, contains('not open'));
      });
    });

    group('removeDueQuestions', () {
      test('removes question from repository', () async {
        questionBox.put('q1', _createQuestion(id: 'q1'));

        final result = await service.removeDueQuestions('q1');
        expect(result.isSuccess, isTrue);
        expect(questionBox.get('q1'), isNull);
      });

      test('does not throw for non-existent question', () async {
        final result = await service.removeDueQuestions('none');
        expect(result.isSuccess, isTrue);
      });
    });

    group('getSubjectDueCount', () {
      test('returns count of due questions for subject', () async {
        questionBox.put('q1', _createQuestion(
          id: 'q1', subjectId: 'sub1', nextReview: DateTime(2020, 1, 1)));
        questionBox.put('q2', _createQuestion(
          id: 'q2', subjectId: 'sub1', nextReview: DateTime(2099, 1, 1)));

        final result = await service.getSubjectDueCount('sub1');
        expect(result.isSuccess, isTrue);
        expect(result.data, 1);
      });

      test('returns zero when no due questions', () async {
        questionBox.put('q1', _createQuestion(
          id: 'q1', subjectId: 'sub1', nextReview: DateTime(2099, 1, 1)));

        final result = await service.getSubjectDueCount('sub1');
        expect(result.data, 0);
      });

      test('returns failure when box not open', () async {
        final closedRepo = _FakeQuestionRepository(_FakeClosedBox());
        final s = SpacedRepetitionService(
          questionRepo: closedRepo,
          attemptRepo: attemptRepo,
        );

        final result = await s.getSubjectDueCount('sub1');
        expect(result.isFailure, isTrue);
        expect(result.error, contains('not open'));
      });
    });
  });
}
