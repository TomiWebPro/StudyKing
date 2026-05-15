import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/mastery_integration_service.dart';
import 'package:studyking/core/services/adaptive_practice_engine.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/questions/data/models/question_evaluation_model.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';

class MockMasteryGraphRepository extends MasteryGraphRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<MasteryState>> getMasteryState(String studentId, String topicId) async {
    final state = MasteryState.initial(studentId: studentId, topicId: topicId).copyWith(
      accuracy: 0.8,
      currentStreak: 5,
      masteryLevel: MasteryLevel.proficient,
      readinessScore: 0.8,
      reviewUrgency: 0.3,
    );
    return Result.success(state);
  }

  @override
  Future<Result<void>> updateMasteryState(MasteryState state) async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getAllMasteryStates(String studentId) async => Result.success([]);

  @override
  Future<Result<QuestionMasteryState>> getQuestionMasteryState(String studentId, String questionId) async {
    final state = QuestionMasteryState.initial(studentId: studentId, questionId: questionId);
    state.correctCount = 3;
    state.incorrectCount = 1;
    state.confidenceHistory.add(4);
    return Result.success(state);
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
    final states = [
      MasteryState.initial(studentId: studentId, topicId: 'topic1').copyWith(accuracy: 0.4),
    ];
    return Result.success(states);
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
  Future<Result<List<TopicDependency>>> getAllDependencies() async => Result.success([]);

  @override
  Future<Result<TopicDependency>> getTopicDependency(String topicId) async {
    final dep = TopicDependency(topicId: topicId);
    return Result.success(dep);
  }

  @override
  Future<Result<void>> updateTopicDependency(TopicDependency dependency) async => Result.success(null);
}

void main() {
  group('MasteryIntegrationService', () {
    late MasteryIntegrationService service;
    late MockMasteryGraphRepository mockRepo;
    late AdaptivePracticeEngine adaptiveEngine;

    setUp(() {
      mockRepo = MockMasteryGraphRepository();
      final masteryService = MasteryGraphService(repository: mockRepo);
      adaptiveEngine = AdaptivePracticeEngine();
      service = MasteryIntegrationService(
        masteryService: masteryService,
        repository: mockRepo,
        adaptiveEngine: adaptiveEngine,
      );
    });

    group('initialize', () {
      test('initializes successfully', () async {
        await service.initialize();
      });
    });

    group('recordAttemptWithMasteryUpdate', () {
      test('records correct attempt with mastery update', () async {
        final result = await service.recordAttemptWithMasteryUpdate(
          studentId: 'student1',
          topicId: 'topic1',
          questionId: 'q1',
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 5000,
        );
        expect(result.isSuccess, isTrue);
      });

      test('records incorrect attempt with mastery update', () async {
        final result = await service.recordAttemptWithMasteryUpdate(
          studentId: 'student1',
          topicId: 'topic1',
          questionId: 'q1',
          isCorrect: false,
          confidence: 2,
          timeSpentMs: 3000,
        );
        expect(result.isSuccess, isTrue);
      });

      test('handles subtopic id', () async {
        final result = await service.recordAttemptWithMasteryUpdate(
          studentId: 'student1',
          topicId: 'topic1',
          questionId: 'q1',
          isCorrect: true,
          confidence: 5,
          timeSpentMs: 10000,
          subtopicId: 'subtopic1',
        );
        expect(result.isSuccess, isTrue);
      });
    });

    group('getAdaptiveRecommendation', () {
      test('returns recommendation for topic', () async {
        final result = await service.getAdaptiveRecommendation(
          studentId: 'student1',
          topicId: 'topic1',
        );
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!['difficulty'], isA<int>());
        expect(result.data!['masteryLevel'], isA<MasteryLevel>());
        expect(result.data!['readinessScore'], isA<double>());
        expect(result.data!['suggestedFocus'], isA<String>());
      });

      test('returns review focus for low accuracy', () async {
        final result = await service.getAdaptiveRecommendation(
          studentId: 'student1',
          topicId: 'topic1',
        );
        expect(result.isSuccess, isTrue);
        final focus = result.data!['suggestedFocus'] as String;
        expect(['Review fundamentals', 'Review at-risk topics', 'Build consistency', 'Challenge advanced problems', 'Practice and reinforce'], contains(focus));
      });

      test('respects maxQuestions parameter', () async {
        final result = await service.getAdaptiveRecommendation(
          studentId: 'student1',
          topicId: 'topic1',
          maxQuestions: 5,
        );
        expect(result.isSuccess, isTrue);
      });
    });

    group('calculateSpacedRepetitionInterval', () {
      test('calculates interval for question', () async {
        final result = await service.calculateSpacedRepetitionInterval(
          studentId: 'student1',
          questionId: 'q1',
        );
        expect(result.isSuccess, isTrue);
        expect(result.data, isA<double>());
      });
    });

    group('getPrioritizedQuestionIds', () {
      test('returns prioritized question ids', () async {
        final result = await service.getPrioritizedQuestionIds(
          studentId: 'student1',
          availableQuestionIds: ['q1', 'q2', 'q3'],
        );
        expect(result.isSuccess, isTrue);
        expect(result.data, isA<List<String>>());
      });

      test('respects limit parameter', () async {
        final result = await service.getPrioritizedQuestionIds(
          studentId: 'student1',
          availableQuestionIds: ['q1', 'q2', 'q3', 'q4', 'q5'],
          limit: 2,
        );
        expect(result.isSuccess, isTrue);
      });

      test('handles empty available questions', () async {
        final result = await service.getPrioritizedQuestionIds(
          studentId: 'student1',
          availableQuestionIds: [],
        );
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });

    group('getMasterySnapshot', () {
      test('returns mastery snapshot', () async {
        final result = await service.getMasterySnapshot('student1');
        expect(result.isSuccess, isTrue);
      });
    });

    group('getTopicMasteries', () {
      test('returns all topic masteries', () async {
        final result = await service.getTopicMasteries('student1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isA<List<MasteryState>>());
      });
    });

    group('getTopicMastery', () {
      test('returns specific topic mastery', () async {
        final result = await service.getTopicMastery('student1', 'topic1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isA<MasteryState>());
      });
    });

    group('migrateLegacyQuestion', () {
      test('migrates question with all fields', () async {
        final result = await service.migrateLegacyQuestion(
          questionId: 'q1',
          markscheme: 'Step 1: x = 5',
          correctAnswer: '5',
          options: ['A', 'B', 'C', 'D'],
          explanation: 'Solve for x',
        );
        expect(result.isSuccess, isTrue);
      });

      test('migrates question with minimal fields', () async {
        final result = await service.migrateLegacyQuestion(
          questionId: 'q2',
        );
        expect(result.isSuccess, isTrue);
      });
    });

    group('masteryService getter', () {
      test('returns mastery service instance', () {
        expect(service.masteryService, isA<MasteryGraphService>());
      });
    });
  });
}