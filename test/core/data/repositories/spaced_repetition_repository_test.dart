import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/enums.dart';

class _MockSpacedRepetitionRepository extends SpacedRepetitionRepository {
  final Map<String, Question> _questionStorage = {};

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Question>>> getQuestionsDueForReview({DateTime? asOf}) async {
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

void main() {
  group('SpacedRepetitionQueries', () {
    group('getQuestionsDueForReview', () {
      test('returns empty list when no questions due', () {
        // This tests the query logic directly
        expect(SpacedRepetitionQueries.questionsToBoxSafe(null), isEmpty);
        expect(SpacedRepetitionQueries.questionsToBoxSafe([]), isEmpty);
      });
    });

    group('questionsToBoxSafe', () {
      test('returns empty list for null input', () {
        expect(SpacedRepetitionQueries.questionsToBoxSafe(null), isEmpty);
      });

      test('returns same list for non-null input', () {
        final questions = <Question>[];
        expect(SpacedRepetitionQueries.questionsToBoxSafe(questions), same(questions));
      });
    });
  });

  group('SpacedRepetitionRepository', () {
    late _MockSpacedRepetitionRepository repository;

    setUp(() {
      repository = _MockSpacedRepetitionRepository();
    });

    group('getQuestionsDueForReview', () {
      test('returns due questions', () async {
        repository._questionStorage['q1'] = createSRQuestion(id: 'q1', nextReview: DateTime(2020, 1, 1));
        repository._questionStorage['q2'] = createSRQuestion(id: 'q2', nextReview: DateTime(2099, 1, 1));
        final result = await repository.getQuestionsDueForReview();
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 1);
      });
    });

    group('updateNextReviewDate', () {
      test('updates review interval for high mastery', () async {
        repository._questionStorage['q1'] = createSRQuestion(id: 'q1');
        final result = await repository.updateNextReviewDate('q1', 0.95);
        expect(result.isSuccess, isTrue);
        final updated = repository._questionStorage['q1'];
        expect(updated?.nextReview, isNotNull);
        expect(updated?.nextReview!.isAfter(DateTime.now()), isTrue);
      });

      test('returns failure for non-existent question', () async {
        final result = await repository.updateNextReviewDate('none', 0.5);
        expect(result.isFailure, isTrue);
      });
    });

    group('getPracticeQuestions', () {
      test('returns practice questions for subject', () async {
        repository._questionStorage['q1'] = createSRQuestion(id: 'q1', subjectId: 'sub1', nextReview: DateTime(2020, 1, 1));
        repository._questionStorage['q2'] = createSRQuestion(id: 'q2', subjectId: 'sub2', nextReview: DateTime(2020, 1, 1));
        final result = await repository.getPracticeQuestions('sub1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 1);
      });
    });

    group('getTopicTimeDue', () {
      test('returns questions for topic', () async {
        repository._questionStorage['q1'] = createSRQuestion(id: 'q1', topicId: 't1');
        repository._questionStorage['q2'] = createSRQuestion(id: 'q2', topicId: 't2');
        final result = await repository.getTopicTimeDue('t1');
        expect(result.data?.length, 1);
      });
    });

    group('getSubjectDueCount', () {
      test('returns due count for subject', () async {
        repository._questionStorage['q1'] = createSRQuestion(id: 'q1', subjectId: 'sub1', nextReview: DateTime(2020, 1, 1));
        repository._questionStorage['q2'] = createSRQuestion(id: 'q2', subjectId: 'sub1', nextReview: DateTime(2099, 1, 1));
        final result = await repository.getSubjectDueCount('sub1');
        expect(result.isSuccess, isTrue);
        expect(result.data, 1);
      });
    });

    group('removeDueQuestions', () {
      test('removes question', () async {
        repository._questionStorage['q1'] = createSRQuestion(id: 'q1');
        await repository.removeDueQuestions('q1');
        expect(repository._questionStorage.containsKey('q1'), isFalse);
      });
    });
  });
}
