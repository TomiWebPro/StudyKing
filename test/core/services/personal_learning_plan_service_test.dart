import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/personal_learning_plan_service.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/questions/data/models/question_evaluation_model.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';

class MockMasteryGraphRepository extends MasteryGraphRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<MasteryState>> getMasteryState(String studentId, String topicId) async {
    final state = MasteryState.initial(studentId: studentId, topicId: topicId).copyWith(
      accuracy: 0.8,
      currentStreak: 5,
      masteryLevel: MasteryLevel.proficient,
    );
    return Result.success(state);
  }

  @override
  Future<Result<void>> updateMasteryState(MasteryState state) async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getAllMasteryStates(String studentId) async {
    return Result.success([
      MasteryState.initial(studentId: studentId, topicId: 'topic1').copyWith(accuracy: 0.9),
      MasteryState.initial(studentId: studentId, topicId: 'topic2').copyWith(accuracy: 0.7),
    ]);
  }

  @override
  Future<Result<QuestionMasteryState>> getQuestionMasteryState(String studentId, String questionId) async {
    return Result.success(QuestionMasteryState.initial(studentId: studentId, questionId: questionId, now: DateTime.now()));
  }

  @override
  Future<Result<void>> updateQuestionMasteryState(QuestionMasteryState state) async => Result.success(null);

  @override
  Future<Result<List<QuestionMasteryState>>> getDueQuestions(String studentId, {DateTime? asOf}) async => Result.success([]);

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(String studentId, {double threshold = 0.5}) async => Result.success([]);

  @override
  Future<Result<List<MasteryState>>> getTopicsNeedingReview(String studentId) async => Result.success([]);

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return Result.success([
      MasteryState.initial(studentId: studentId, topicId: 'topic1').copyWith(accuracy: 0.4),
    ]);
  }

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) async => Result.success({});

  @override
  Future<Result<void>> migrateFromLegacy({required String questionId, String? markscheme, String? correctAnswer, List<String>? options, String? explanation}) async => Result.success(null);

  @override
  Future<Result<QuestionEvaluation>> getEvaluation(String questionId) async {
    final evaluation = QuestionEvaluation(
      questionId: questionId,
      correctAnswer: 'test',
      acceptableAnswers: ['A', 'B', 'C', 'D'],
      explanation: 'test',
    );
    return Result.success(evaluation);
  }

  @override
  Future<Result<void>> saveEvaluation(QuestionEvaluation evaluation) async => Result.success(null);

  @override
  Future<Result<List<TopicDependency>>> getAllDependencies() async {
    return Result.success([
      TopicDependency(topicId: 'topic1', prerequisites: [], downstreamTopics: ['topic2']),
      TopicDependency(topicId: 'topic2', prerequisites: ['topic1'], downstreamTopics: []),
    ]);
  }

  @override
  Future<Result<TopicDependency>> getTopicDependency(String topicId) async {
    final dep = TopicDependency(topicId: topicId);
    return Result.success(dep);
  }

  @override
  Future<Result<void>> updateTopicDependency(TopicDependency dependency) async => Result.success(null);
}

class MockTopicRepository extends TopicRepository {
  final Map<String, Topic> _topics = {};

  void addTopic(Topic topic) {
    _topics[topic.id] = topic;
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> create(Topic topic) async {
    _topics[topic.id] = topic;
  }

  @override
  Future<Topic?> get(String id) async {
    return _topics[id];
  }

  @override
  Future<List<Topic>> getAll() async => _topics.values.toList();

  @override
  Future<List<Topic>> getBySubject(String subjectId) async => _topics.values.where((t) => t.subjectId == subjectId).toList();

  @override
  Future<List<Topic>> getByParent(String parentId) async => _topics.values.where((t) => t.parentId == parentId).toList();

  @override
  Future<List<Topic>> getRootTopics() async => _topics.values.where((t) => t.parentId == null).toList();

  @override
  Future<void> delete(String id) async {
    _topics.remove(id);
  }

  @override
  Future<void> addParent(Topic topic, String parentId) async {}
}

void main() {
  group('PlanGenerationConfig', () {
    test('creates config with default values', () {
      final config = PlanGenerationConfig();

      expect(config.planDurationDays, equals(7));
      expect(config.targetQuestionsPerDay, equals(15));
      expect(config.targetMinutesPerDay, equals(30.0));
      expect(config.masteryThreshold, equals(0.8));
      expect(config.maxQuestionsPerTopic, equals(10));
      expect(config.includeRestDays, isFalse);
      expect(config.restDayFrequency, equals(7));
    });

    test('creates config with custom values', () {
      final config = PlanGenerationConfig(
        planDurationDays: 14,
        targetQuestionsPerDay: 20,
        targetMinutesPerDay: 45.0,
        masteryThreshold: 0.9,
        maxQuestionsPerTopic: 15,
        includeRestDays: true,
        restDayFrequency: 3,
      );

      expect(config.planDurationDays, equals(14));
      expect(config.targetQuestionsPerDay, equals(20));
      expect(config.targetMinutesPerDay, equals(45.0));
      expect(config.masteryThreshold, equals(0.9));
      expect(config.maxQuestionsPerTopic, equals(15));
      expect(config.includeRestDays, isTrue);
      expect(config.restDayFrequency, equals(3));
    });
  });

  group('PersonalLearningPlanService', () {
    late PersonalLearningPlanService service;
    late MockMasteryGraphRepository mockRepo;
    late MockTopicRepository mockTopicRepo;

    setUp(() {
      mockRepo = MockMasteryGraphRepository();
      mockTopicRepo = MockTopicRepository();
      service = PersonalLearningPlanService(
        masteryService: null,
        repository: mockRepo,
        topicRepository: mockTopicRepo,
        config: PlanGenerationConfig(planDurationDays: 3),
      );
    });

    group('generatePlan', () {
      test('generates plan successfully', () async {
        final result = await service.generatePlan('student1');

        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.studentId, equals('student1'));
        expect(result.data!.dailyPlans.length, equals(3));
        expect(result.data!.planDurationDays, equals(3));
      });

      test('generates plan with correct config', () async {
        final customConfig = PlanGenerationConfig(
          planDurationDays: 5,
          targetQuestionsPerDay: 10,
          targetMinutesPerDay: 20.0,
        );

        final serviceWithConfig = PersonalLearningPlanService(
          repository: mockRepo,
          topicRepository: mockTopicRepo,
          config: customConfig,
        );

        final result = await serviceWithConfig.generatePlan('student1');

        expect(result.isSuccess, isTrue);
        expect(result.data!.planDurationDays, equals(5));
        expect(result.data!.targetQuestionsPerDay, equals(10));
        expect(result.data!.targetMinutesPerDay, equals(20.0));
      });

      test('returns failure when mastery states fail', () async {
        final failingRepo = _FailingMasteryGraphRepository();
        final failingService = PersonalLearningPlanService(
          repository: failingRepo,
          topicRepository: mockTopicRepo,
        );

        final result = await failingService.generatePlan('student1');

        expect(result.isFailure, isTrue);
      });

      test('generates plan with recommendations', () async {
        final result = await service.generatePlan('student1');

        expect(result.isSuccess, isTrue);
        expect(result.data!.recommendations, isNotEmpty);
      });

      test('generates plan with summary', () async {
        final result = await service.generatePlan('student1');

        expect(result.isSuccess, isTrue);
        expect(result.data!.summary, isNotNull);
        expect(result.data!.summary.totalQuestions, greaterThanOrEqualTo(0));
        expect(result.data!.summary.totalMinutes, greaterThanOrEqualTo(0));
      });

      test('includes rest days when configured', () async {
        final configWithRest = PlanGenerationConfig(
          planDurationDays: 7,
          includeRestDays: true,
          restDayFrequency: 3,
        );

        final serviceWithRest = PersonalLearningPlanService(
          repository: mockRepo,
          topicRepository: mockTopicRepo,
          config: configWithRest,
        );

        final result = await serviceWithRest.generatePlan('student1');

        expect(result.isSuccess, isTrue);
        final hasRestDay = result.data!.dailyPlans.any((d) => d.isRestDay);
        expect(hasRestDay, isTrue);
      });
    });

    group('getNextStudyTopics', () {
      test('returns topics with limit', () async {
        final result = await service.getNextStudyTopics('student1', limit: 3);

        expect(result.isSuccess, isTrue);
        expect(result.data!.length, lessThanOrEqualTo(3));
      });

      test('returns topics sorted by priority', () async {
        final result = await service.getNextStudyTopics('student1', limit: 5);

        expect(result.isSuccess, isTrue);
        if (result.data!.length > 1) {
          for (var i = 0; i < result.data!.length - 1; i++) {
            expect(result.data![i].priority, greaterThanOrEqualTo(result.data![i + 1].priority));
          }
        }
      });

      test('returns failure on error', () async {
        final failingRepo = _FailingMasteryGraphRepository();
        final failingService = PersonalLearningPlanService(
          repository: failingRepo,
          topicRepository: mockTopicRepo,
        );

        final result = await failingService.getNextStudyTopics('student1');

        expect(result.isFailure, isTrue);
      });
    });

    group('getAtRiskTopicIds', () {
      test('returns weak topic ids', () async {
        final result = await service.getAtRiskTopicIds('student1');

        expect(result.isSuccess, isTrue);
        expect(result.data, isA<List<String>>());
      });

      test('returns failure on error', () async {
        final failingRepo = _FailingMasteryGraphRepository();
        final failingService = PersonalLearningPlanService(
          repository: failingRepo,
          topicRepository: mockTopicRepo,
        );

        final result = await failingService.getAtRiskTopicIds('student1');

        expect(result.isFailure, isTrue);
      });
    });

    group('getReadyToAdvanceTopicIds', () {
      test('returns ready topic ids', () async {
        final result = await service.getReadyToAdvanceTopicIds('student1');

        expect(result.isSuccess, isTrue);
        expect(result.data, isA<List<String>>());
      });

      test('returns failure on error', () async {
        final failingRepo = _FailingMasteryGraphRepository();
        final failingService = PersonalLearningPlanService(
          repository: failingRepo,
          topicRepository: mockTopicRepo,
        );

        final result = await failingService.getReadyToAdvanceTopicIds('student1');

        expect(result.isFailure, isTrue);
      });
    });
  });
}

class _FailingMasteryGraphRepository extends MasteryGraphRepository {
  @override
  Future<void> init() async => throw Exception('Init failed');

  @override
  Future<Result<MasteryState>> getMasteryState(String studentId, String topicId) async =>
      Result.failure('Failed to get mastery state');

  @override
  Future<Result<void>> updateMasteryState(MasteryState state) async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getAllMasteryStates(String studentId) async =>
      Result.failure('Failed to get all mastery states');

  @override
  Future<Result<QuestionMasteryState>> getQuestionMasteryState(String studentId, String questionId) async =>
      Result.success(QuestionMasteryState.initial(studentId: studentId, questionId: questionId, now: DateTime.now()));

  @override
  Future<Result<void>> updateQuestionMasteryState(QuestionMasteryState state) async => Result.success(null);

  @override
  Future<Result<List<QuestionMasteryState>>> getDueQuestions(String studentId, {DateTime? asOf}) async =>
      Result.success([]);

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(String studentId, {double threshold = 0.5}) async =>
      Result.success([]);

  @override
  Future<Result<List<MasteryState>>> getTopicsNeedingReview(String studentId) async => Result.success([]);

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async => Result.failure('Failed to get weak topics');

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) async => Result.success({});

  @override
  Future<Result<void>> migrateFromLegacy({required String questionId, String? markscheme, String? correctAnswer, List<String>? options, String? explanation}) async =>
      Result.success(null);

  @override
  Future<Result<QuestionEvaluation>> getEvaluation(String questionId) async =>
      Result.failure('Failed to get evaluation');

  @override
  Future<Result<void>> saveEvaluation(QuestionEvaluation evaluation) async => Result.success(null);

  @override
  Future<Result<List<TopicDependency>>> getAllDependencies() async =>
      Result.failure('Failed to get dependencies');

  @override
  Future<Result<TopicDependency>> getTopicDependency(String topicId) async =>
      Result.failure('Failed to get topic dependency');

  @override
  Future<Result<void>> updateTopicDependency(TopicDependency dependency) async => Result.success(null);
}