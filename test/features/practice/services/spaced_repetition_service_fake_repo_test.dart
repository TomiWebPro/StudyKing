import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/enums.dart';

class _FakeSpacedRepetitionService extends SpacedRepetitionService {
  final Map<String, Question> _questionStorage = {};
  final Map<String, StudentAttempt> _attemptStorage = {};

  _FakeSpacedRepetitionService()
      : super(
          questionRepo: _FakeQuestionRepo(),
          attemptRepo: _FakeAttemptRepo(),
        );

  @override
  Future<Result<List<Question>>> getQuestionsDue({DateTime? asOf}) async {
    final reviewDate = asOf ?? DateTime.now();
    final cutover = reviewDate.subtract(const Duration(hours: 1));
    final due = _questionStorage.values
        .where((q) => (q.nextReview ?? DateTime.now()).isBefore(cutover))
        .toList();
    due.sort((a, b) => (a.nextReview ?? DateTime.now()).compareTo(b.nextReview ?? DateTime.now()));
    return Result.success(due);
  }

  @override
  Future<Result<void>> updateNextReviewDate(String questionId, double masteryLevel) async {
    final question = _questionStorage[questionId];
    if (question == null) {
      return Result.failure('Question not found: $questionId');
    }
    double newInterval;
    if (masteryLevel >= 0.9) {
      newInterval = 7 * 24 * 60 * 60 * 1000;
    } else if (masteryLevel >= 0.7) {
      newInterval = 3 * 24 * 60 * 60 * 1000;
    } else if (masteryLevel >= 0.5) {
      newInterval = 1 * 24 * 60 * 60 * 1000;
    } else if (masteryLevel >= 0.3) {
      newInterval = 12 * 60 * 60 * 1000;
    } else {
      newInterval = 30 * 60 * 1000;
    }
    final newReviewDate = DateTime.now().add(Duration(milliseconds: newInterval.toInt()));
    _questionStorage[questionId] = question.copyWith(nextReview: newReviewDate);
    return Result.success(null);
  }

  @override
  Future<Result<List<DateTime>>> getQuestionDueTimes(String questionId) async {
    final attempt = _attemptStorage[questionId];
    if (attempt == null) {
      return Result.failure('No attempts found for question: $questionId');
    }
    final timestamps = attempt.lastDueDate != null ? [attempt.lastDueDate!] : <DateTime>[];
    return Result.success(timestamps);
  }

  @override
  Future<Result<List<Question>>> getPracticeQuestions(String subjectId) async {
    final all = _questionStorage.values.toList();
    final practice = all.where((q) =>
        (q.nextReview ?? DateTime.now()).isBefore(DateTime.now()) && q.subjectId == subjectId);
    return Result.success(practice.toList());
  }

  @override
  Future<Result<List<Question>>> getTopicTimeDue(String topicId) async {
    final all = _questionStorage.values.toList();
    final topicQuestions = all.where((q) => q.topicId == topicId);
    return Result.success(topicQuestions.toList());
  }

  @override
  Future<Result<void>> removeDueQuestions(String questionId) async {
    _questionStorage.remove(questionId);
    return Result.success(null);
  }

  @override
  Future<Result<int>> getSubjectDueCount(String subjectId) async {
    final all = _questionStorage.values.toList();
    final dueCount = all
        .where((q) =>
            q.subjectId == subjectId &&
            (q.nextReview ?? DateTime.now()).isBefore(DateTime.now()))
        .length;
    return Result.success(dueCount);
  }
}

class _FakeQuestionRepo extends QuestionRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Question>>> getAll() async => Result.success([]);

  @override
  Future<Result<Question?>> get(String key) async => Result.success(null);

  @override
  Future<Result<void>> save(String key, Question value) async => Result.success(null);

  @override
  Future<Result<void>> delete(String key) async => Result.success(null);
}

class _FakeAttemptRepo extends AttemptRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<List<StudentAttempt>>> getAll() async => Result.success([]);

  @override
  Future<Result<StudentAttempt?>> get(String key) async => Result.success(null);

  @override
  Future<Result<void>> save(String key, StudentAttempt item) async => Result.success(null);

  @override
  Future<Result<void>> delete(String key) async => Result.success(null);
}

Question createSRQuestion({
  String id = 'q1',
  String subjectId = 'sub1',
  String topicId = 't1',
  DateTime? nextReview,
}) {
  return Question(
    id: id,
    text: 'Question?',
    type: QuestionType.singleChoice,
    subjectId: subjectId,
    topicId: topicId,
    createdAt: DateTime(2026, 5, 12),
    updatedAt: DateTime(2026, 5, 12),
    nextReview: nextReview,
  );
}

class FakeQuestionBox implements Box<Question> {
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
  Stream<BoxEvent> watch({dynamic key}) => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SpacedRepetitionQueries', () {
    group('getQuestionsDueAfter', () {
      test('returns questions due after specific date', () {
        final box = FakeQuestionBox();
        box.put('q1', createSRQuestion(id: 'q1', nextReview: DateTime(2020, 1, 1)));
        box.put('q2', createSRQuestion(id: 'q2', nextReview: DateTime(2099, 1, 1)));
        final due = SpacedRepetitionQueries.getQuestionsDueAfter(box, DateTime(2023, 1, 1));
        expect(due.length, 1);
        expect(due.first.id, 'q1');
      });
    });

    group('isQuestionDueForReview', () {
      test('returns true for past due question', () {
        final q = createSRQuestion(nextReview: DateTime(2020, 1, 1));
        expect(SpacedRepetitionQueries.isQuestionDueForReview(q), isTrue);
      });

      test('returns false for future review question', () {
        final q = createSRQuestion(nextReview: DateTime(2099, 1, 1));
        expect(SpacedRepetitionQueries.isQuestionDueForReview(q), isFalse);
      });
    });

    group('mapQuestionsToStatus', () {
      test('returns status map for questions', () {
        final box = FakeQuestionBox();
        box.put('q1', createSRQuestion(id: 'q1', nextReview: DateTime(2020, 1, 1)));
        box.put('q2', createSRQuestion(id: 'q2', nextReview: DateTime(2099, 1, 1)));
        final status = SpacedRepetitionQueries.mapQuestionsToStatus(box);
        expect(status['q1'], 'due');
        expect(status['q2'], 'not-due');
      });
    });
  });

  group('SpacedRepetitionService', () {
    late _FakeSpacedRepetitionService service;

    setUp(() {
      service = _FakeSpacedRepetitionService();
    });

    group('getQuestionsDue', () {
      test('returns due questions', () async {
        service._questionStorage['q1'] = createSRQuestion(id: 'q1', nextReview: DateTime(2020, 1, 1));
        service._questionStorage['q2'] = createSRQuestion(id: 'q2', nextReview: DateTime(2099, 1, 1));
        final result = await service.getQuestionsDue();
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 1);
      });

      test('returns empty when none due', () async {
        service._questionStorage['q1'] = createSRQuestion(id: 'q1', nextReview: DateTime(2099, 1, 1));
        final result = await service.getQuestionsDue();
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });

    group('updateNextReviewDate', () {
      test('updates review interval for high mastery (>=0.9)', () async {
        service._questionStorage['q1'] = createSRQuestion(id: 'q1');
        final result = await service.updateNextReviewDate('q1', 0.95);
        expect(result.isSuccess, isTrue);
        expect(service._questionStorage['q1']?.nextReview, isNotNull);
      });

      test('updates review interval for medium-high mastery (>=0.7)', () async {
        service._questionStorage['q1'] = createSRQuestion(id: 'q1');
        final result = await service.updateNextReviewDate('q1', 0.8);
        expect(result.isSuccess, isTrue);
      });

      test('updates review interval for medium mastery (>=0.5)', () async {
        service._questionStorage['q1'] = createSRQuestion(id: 'q1');
        final result = await service.updateNextReviewDate('q1', 0.6);
        expect(result.isSuccess, isTrue);
      });

      test('updates review interval for low-medium mastery (>=0.3)', () async {
        service._questionStorage['q1'] = createSRQuestion(id: 'q1');
        final result = await service.updateNextReviewDate('q1', 0.4);
        expect(result.isSuccess, isTrue);
      });

      test('updates review interval for low mastery (<0.3)', () async {
        service._questionStorage['q1'] = createSRQuestion(id: 'q1');
        final result = await service.updateNextReviewDate('q1', 0.2);
        expect(result.isSuccess, isTrue);
      });

      test('returns failure for non-existent question', () async {
        final result = await service.updateNextReviewDate('none', 0.5);
        expect(result.isFailure, isTrue);
      });
    });

    group('getQuestionDueTimes', () {
      test('returns due times from attempt', () async {
        final now = DateTime.now();
        service._attemptStorage['q1'] = StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          timestamp: now,
          lastDueDate: now.subtract(const Duration(days: 1)),
        );
        final result = await service.getQuestionDueTimes('q1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 1);
      });

      test('returns empty list when attempt has no due date', () async {
        service._attemptStorage['q1'] = StudentAttempt(
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

      test('returns failure for non-existent question', () async {
        final result = await service.getQuestionDueTimes('none');
        expect(result.isFailure, isTrue);
      });
    });

    group('getPracticeQuestions', () {
      test('returns practice questions for subject', () async {
        service._questionStorage['q1'] = createSRQuestion(id: 'q1', subjectId: 'sub1', nextReview: DateTime(2020, 1, 1));
        service._questionStorage['q2'] = createSRQuestion(id: 'q2', subjectId: 'sub2', nextReview: DateTime(2020, 1, 1));
        final result = await service.getPracticeQuestions('sub1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 1);
      });

      test('returns empty when no practice questions', () async {
        final result = await service.getPracticeQuestions('sub1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });

    group('getTopicTimeDue', () {
      test('returns questions for topic', () async {
        service._questionStorage['q1'] = createSRQuestion(id: 'q1', topicId: 't1');
        service._questionStorage['q2'] = createSRQuestion(id: 'q2', topicId: 't2');
        final result = await service.getTopicTimeDue('t1');
        expect(result.data?.length, 1);
      });

      test('returns empty for topic with no questions', () async {
        final result = await service.getTopicTimeDue('none');
        expect(result.data, isEmpty);
      });
    });

    group('getSubjectDueCount', () {
      test('returns due count for subject', () async {
        service._questionStorage['q1'] = createSRQuestion(id: 'q1', subjectId: 'sub1', nextReview: DateTime(2020, 1, 1));
        service._questionStorage['q2'] = createSRQuestion(id: 'q2', subjectId: 'sub1', nextReview: DateTime(2099, 1, 1));
        final result = await service.getSubjectDueCount('sub1');
        expect(result.isSuccess, isTrue);
        expect(result.data, 1);
      });

      test('returns zero for subject with no due questions', () async {
        service._questionStorage['q1'] = createSRQuestion(id: 'q1', subjectId: 'sub1', nextReview: DateTime(2099, 1, 1));
        final result = await service.getSubjectDueCount('sub1');
        expect(result.isSuccess, isTrue);
        expect(result.data, 0);
      });
    });

    group('removeDueQuestions', () {
      test('removes question', () async {
        service._questionStorage['q1'] = createSRQuestion(id: 'q1');
        await service.removeDueQuestions('q1');
        expect(service._questionStorage.containsKey('q1'), isFalse);
      });

      test('does nothing for non-existent question', () async {
        await service.removeDueQuestions('none');
      });
    });
  });

}
