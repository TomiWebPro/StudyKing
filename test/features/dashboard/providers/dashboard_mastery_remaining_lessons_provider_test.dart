import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/dashboard/providers/dashboard_data_providers.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart'
    show masteryGraphServiceProvider, spacedRepetitionServiceProvider;
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart'
    show topicRepositoryProvider;

class FakeMasteryGraphService extends MasteryGraphService {
  final List<MasteryState> states;
  final List<QuestionMasteryState> dueQuestions;

  FakeMasteryGraphService(this.states, this.dueQuestions)
      : super();

  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) =>
      Future.value(Result.success(states));

  @override
  Future<Result<List<QuestionMasteryState>>> getQuestionsDueForReview(
    String studentId, {
    DateTime? asOf,
  }) =>
      Future.value(Result.success(dueQuestions));
}

class FakeSpacedRepetitionService extends SpacedRepetitionService {
  final List<Question> dueQuestions;

  FakeSpacedRepetitionService(this.dueQuestions)
      : super(
          questionRepo: QuestionRepository(),
          attemptRepo: AttemptRepository(),
        );

  @override
  Future<Result<List<Question>>> getQuestionsDueForReview({DateTime? asOf}) =>
      Future.value(Result.success(dueQuestions));
}

class FakeTopicRepository extends TopicRepository {
  final int topicCount;

  FakeTopicRepository(this.topicCount);

  @override
  Future<Result<List<Topic>>> getAll() => Future.value(Result.success(
        List.generate(
          topicCount,
          (i) => Topic(
            id: 'topic-$i',
            subjectId: 'sub1',
            title: 'Topic $i',
            description: '',
            syllabusText: '',
          ),
        ),
      ));

  @override
  Future<Result<void>> init() => Future.value(Result.success(null));
}

void main() {
  group('dashboardMasteryRemainingLessonsProvider', () {
    test('computes remaining lessons from injected mastery + due signals',
        () async {
      final state = MasteryState(
        studentId: 's1',
        topicId: 't1',
        masteryLevel: MasteryLevel.developing,
        accuracy: 0.5,
        lastAttempt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      final dueQuestion = Question(
        id: 'q1',
        text: 'q',
        type: QuestionType.singleChoice,
        subjectId: 'sub1',
        topicId: 't1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final container = ProviderContainer(overrides: [
        dashboardInitProvider.overrideWith((ref) => Future.value()),
        masteryGraphServiceProvider
            .overrideWith((ref) => FakeMasteryGraphService([state], [])),
        spacedRepetitionServiceProvider
            .overrideWith((ref) => FakeSpacedRepetitionService([dueQuestion])),
        topicRepositoryProvider.overrideWith((ref) => FakeTopicRepository(3)),
      ]);

      final estimate =
          await container.read(dashboardMasteryRemainingLessonsProvider('s1').future);

      // developing base = 8; low accuracy (0.5) adds 2; due question t1 adds
      // ceil(1/5)=1 -> 11 for the covered topic. 1 of 3 topics covered ->
      // 2 uncovered novice topics * 16 = 32. Total = 11 + 32 = 43.
      expect(estimate.lessonsRemaining, 43);
      expect(estimate.masteryProgress, greaterThan(0.0));
      container.dispose();
    });

    test('returns zero lessons when no mastery and no syllabus topics',
        () async {
      final container = ProviderContainer(overrides: [
        dashboardInitProvider.overrideWith((ref) => Future.value()),
        masteryGraphServiceProvider
            .overrideWith((ref) => FakeMasteryGraphService([], [])),
        spacedRepetitionServiceProvider
            .overrideWith((ref) => FakeSpacedRepetitionService([])),
        topicRepositoryProvider.overrideWith((ref) => FakeTopicRepository(0)),
      ]);

      final estimate =
          await container.read(dashboardMasteryRemainingLessonsProvider('s1').future);
      expect(estimate.lessonsRemaining, 0);
      container.dispose();
    });
  });
}
