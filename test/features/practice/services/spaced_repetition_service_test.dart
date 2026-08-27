import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';

/// In-memory [Box] implementation that backs the fake repositories.
class _FakeBox<T> implements Box<T> {
  final Map<dynamic, T> _storage = {};

  @override
  Iterable<T> get values => _storage.values;

  @override
  T? get(dynamic key, {T? defaultValue}) => _storage[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, T value) async {
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

  Map<dynamic, T> get debugMap => _storage;

  @override
  int get length => _storage.length;

  @override
  bool get isOpen => true;

  @override
  String get name => 'fakeBox';

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

class FakeQuestionRepository extends QuestionRepository {
  final _FakeBox<Question> _box = _FakeBox<Question>();

  @override
  Future<Result<Question?>> get(String key) async {
    return Result.success(_box.get(key));
  }

  @override
  Future<Result<void>> save(String key, Question item) async {
    await _box.put(key, item);
    return Result.success(null);
  }

  @override
  Future<Result<void>> delete(String key) async {
    await _box.delete(key);
    return Result.success(null);
  }

  @override
  Box<Question> get box => _box;

  Map<dynamic, Question> get _storage => _box._storage;
}

class FakeAttemptRepository extends AttemptRepository {
  final _FakeBox<StudentAttempt> _box = _FakeBox<StudentAttempt>();

  @override
  Future<Result<void>> create(StudentAttempt attempt) async {
    await _box.put(attempt.id, attempt);
    return Result.success(null);
  }

  @override
  Future<Result<StudentAttempt?>> get(String key) async {
    return Result.success(_box.get(key));
  }

  Map<dynamic, StudentAttempt> get _storage => _box._storage;
}

/// Spy engine that records whether the service delegated to it.
class _SpyEngine extends SpacedRepetitionEngine {
  bool scheduleCalled = false;
  String? lastQuestionId;
  int? lastGrade;

  @override
  SM2Result scheduleReview({
    required String questionId,
    required int grade,
    QuestionSRData? currentData,
    DateTime? now,
  }) {
    scheduleCalled = true;
    lastQuestionId = questionId;
    lastGrade = grade;
    return super.scheduleReview(
      questionId: questionId,
      grade: grade,
      currentData: currentData,
      now: now,
    );
  }
}

Question _makeQuestion(String id, {DateTime? nextReview, String? srDataJson}) {
  final now = DateTime(2026, 1, 1);
  return Question(
    id: id,
    text: 'What is 2+2?',
    type: QuestionType.typedAnswer,
    subjectId: 'math',
    topicId: 'arithmetic',
    createdAt: now,
    updatedAt: now,
    nextReview: nextReview,
    srDataJson: srDataJson,
  );
}

void main() {
  group('SpacedRepetitionService.updateNextReviewDate', () {
    late FakeQuestionRepository questionRepo;
    late FakeAttemptRepository attemptRepo;
    late _SpyEngine spyEngine;
    late SpacedRepetitionService service;

    setUp(() {
      questionRepo = FakeQuestionRepository();
      attemptRepo = FakeAttemptRepository();
      spyEngine = _SpyEngine();
      service = SpacedRepetitionService(
        questionRepo: questionRepo,
        attemptRepo: attemptRepo,
        srEngine: spyEngine,
      );
    });

    test('delegates scheduling to the engine and persists the new state',
        () async {
      questionRepo._storage['q1'] = _makeQuestion('q1');

      final result = await service.updateNextReviewDate('q1', 0.95);

      expect(result.isSuccess, isTrue);
      expect(spyEngine.scheduleCalled, isTrue);
      expect(spyEngine.lastQuestionId, 'q1');
      expect(spyEngine.lastGrade, 5);

      final updated = questionRepo._storage['q1']!;
      expect(updated.nextReview, isNotNull);
      expect(updated.nextReview!.isAfter(DateTime(2026, 1, 1)), isTrue);
      expect(updated.srDataJson, isNotNull);
      expect(updated.srDataJson!.isNotEmpty, isTrue);
    });

    test('returns a failure when the question does not exist', () async {
      final result = await service.updateNextReviewDate('missing', 0.9);
      expect(result.isFailure, isTrue);
      expect(result.error, contains('notFound'));
    });
  });

  group('SpacedRepetitionService.isQuestionDueForReview', () {
    late FakeQuestionRepository questionRepo;
    late SpacedRepetitionService service;

    setUp(() {
      questionRepo = FakeQuestionRepository();
      service = SpacedRepetitionService(
        questionRepo: questionRepo,
        attemptRepo: FakeAttemptRepository(),
      );
    });

    test('an overdue question is due', () async {
      questionRepo._storage['q1'] =
          _makeQuestion('q1', nextReview: DateTime(2020, 1, 1));
      final result = await service.isQuestionDueForReview(
          questionRepo._storage['q1']!,
          asOf: DateTime(2026, 1, 1));
      expect(result.data, isTrue);
    });

    test('a future question is not due', () async {
      questionRepo._storage['q1'] =
          _makeQuestion('q1', nextReview: DateTime(2099, 1, 1));
      final result = await service.isQuestionDueForReview(
          questionRepo._storage['q1']!,
          asOf: DateTime(2026, 1, 1));
      expect(result.data, isFalse);
    });
  });

  group('SpacedRepetitionService.getQuestionsDueForReview', () {
    late FakeQuestionRepository questionRepo;
    late SpacedRepetitionService service;

    setUp(() {
      questionRepo = FakeQuestionRepository();
      service = SpacedRepetitionService(
        questionRepo: questionRepo,
        attemptRepo: FakeAttemptRepository(),
      );
    });

    test('returns only questions whose nextReview is before the cutoff',
        () async {
      questionRepo._storage['due'] =
          _makeQuestion('due', nextReview: DateTime(2020, 1, 1));
      questionRepo._storage['future'] =
          _makeQuestion('future', nextReview: DateTime(2099, 1, 1));

      final result = await service.getQuestionsDueForReview(
          asOf: DateTime(2026, 1, 1));
      expect(result.isSuccess, isTrue);
      expect(result.data!.map((q) => q.id), ['due']);
    });
  });

  group('SpacedRepetitionService.removeDueQuestions', () {
    late FakeQuestionRepository questionRepo;
    late SpacedRepetitionService service;

    setUp(() {
      questionRepo = FakeQuestionRepository();
      service = SpacedRepetitionService(
        questionRepo: questionRepo,
        attemptRepo: FakeAttemptRepository(),
      );
    });

    test('deletes the question from the repository', () async {
      questionRepo._storage['q1'] = _makeQuestion('q1');
      final result = await service.removeDueQuestions('q1');
      expect(result.isSuccess, isTrue);
      expect(questionRepo._storage.containsKey('q1'), isFalse);
    });
  });

  group('SpacedRepetitionService.getQuestionDueTimes', () {
    late FakeQuestionRepository questionRepo;
    late FakeAttemptRepository attemptRepo;
    late SpacedRepetitionService service;

    setUp(() {
      questionRepo = FakeQuestionRepository();
      attemptRepo = FakeAttemptRepository();
      service = SpacedRepetitionService(
        questionRepo: questionRepo,
        attemptRepo: attemptRepo,
      );
    });

    test('returns the attempt due time when the attempt exists', () async {
      attemptRepo._storage['q1'] = StudentAttempt(
        id: 'a1',
        studentId: 's1',
        questionId: 'q1',
        subjectId: 'math',
        timestamp: DateTime(2026, 1, 1),
        lastDueDate: DateTime(2026, 1, 2),
      );
      final result = await service.getQuestionDueTimes('q1');
      expect(result.isSuccess, isTrue);
      expect(result.data!, [DateTime(2026, 1, 2)]);
    });

    test('returns a failure when no attempt exists', () async {
      final result = await service.getQuestionDueTimes('q1');
      expect(result.isFailure, isTrue);
    });
  });

  group('SpacedRepetitionService.getQuestionsDue', () {
    late FakeQuestionRepository questionRepo;
    late SpacedRepetitionService service;

    setUp(() {
      questionRepo = FakeQuestionRepository();
      service = SpacedRepetitionService(
        questionRepo: questionRepo,
        attemptRepo: FakeAttemptRepository(),
      );
    });

    test('propagates failure when inner getQuestionsDueForReview fails', () async {
      final failingService = _FailingSpacedRepetitionService(
        questionRepo: questionRepo,
        attemptRepo: FakeAttemptRepository(),
      );
      final result = await failingService.getQuestionsDue();
      expect(result.isFailure, isTrue);
    });

    test('returns empty success when inner succeeds with empty list', () async {
      final result = await service.getQuestionsDue(asOf: DateTime(2026, 1, 1));
      expect(result.isSuccess, isTrue);
      expect(result.data, isEmpty);
    });

    test('returns due questions when inner succeeds with data', () async {
      questionRepo._storage['due'] = _makeQuestion('due', nextReview: DateTime(2020, 1, 1));
      questionRepo._storage['future'] = _makeQuestion('future', nextReview: DateTime(2099, 1, 1));
      final result = await service.getQuestionsDue(asOf: DateTime(2026, 1, 1));
      expect(result.isSuccess, isTrue);
      expect(result.data!.map((q) => q.id), contains('due'));
    });
  });
}

class _FailingSpacedRepetitionService extends SpacedRepetitionService {
  _FailingSpacedRepetitionService({
    required super.questionRepo,
    required super.attemptRepo,
  });

  @override
  Future<Result<List<Question>>> getQuestionsDueForReview({DateTime? asOf}) async {
    return Result.failure('inner failure');
  }
}
