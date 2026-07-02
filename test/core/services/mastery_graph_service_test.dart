import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/repositories/mastery_state_repository.dart';
import 'package:studyking/core/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_evaluation_repository.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/questions/data/models/question_evaluation_model.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';

class FakeMasteryStateRepo extends MasteryStateRepository {
  final Map<String, MasteryState> _masteryStates = {};
  bool failOnGet = false;
  bool failOnUpdate = false;
  String? failureMessage;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<MasteryState>> getMasteryState(String studentId, String topicId) async {
    if (failOnGet) return Result.failure(failureMessage ?? 'getMasteryState failed');
    final key = '${studentId}_$topicId';
    final state = _masteryStates[key];
    if (state != null) return Result.success(state);
    return Result.success(MasteryState.initial(studentId: studentId, topicId: topicId));
  }

  @override
  Future<Result<void>> updateMasteryState(MasteryState state) async {
    if (failOnUpdate) return Result.failure(failureMessage ?? 'updateMasteryState failed');
    _masteryStates['${state.studentId}_${state.topicId}'] = state;
    return Result.success(null);
  }

  void addMasteryState(MasteryState state) {
    _masteryStates['${state.studentId}_${state.topicId}'] = state;
  }
}

class FakeQuestionMasteryStateRepo extends QuestionMasteryStateRepository {
  final Map<String, QuestionMasteryState> _states = {};
  bool failOnGet = false;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<QuestionMasteryState>> getQuestionMasteryState(String studentId, String questionId) async {
    if (failOnGet) return Result.failure('getQuestionMasteryState failed');
    final key = '${studentId}_$questionId';
    if (_states.containsKey(key)) return Result.success(_states[key]!);
    return Result.success(QuestionMasteryState.initial(studentId: studentId, questionId: questionId, now: DateTime.now()));
  }

  @override
  Future<Result<void>> updateQuestionMasteryState(QuestionMasteryState state) async {
    _states['${state.studentId}_${state.questionId}'] = state;
    return Result.success(null);
  }

  void addState(QuestionMasteryState state) {
    _states['${state.studentId}_${state.questionId}'] = state;
  }
}

class FakeQuestionEvaluationRepo extends QuestionEvaluationRepository {
  final Map<String, QuestionEvaluation> _evaluations = {};

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<QuestionEvaluation>> getEvaluation(String questionId) async {
    if (_evaluations.containsKey(questionId)) return Result.success(_evaluations[questionId]!);
    return Result.failure('Not found');
  }

  @override
  Future<Result<void>> saveEvaluation(QuestionEvaluation evaluation) async {
    _evaluations[evaluation.questionId] = evaluation;
    return Result.success(null);
  }
}

void main() {
  group('MasteryGraphService', () {
    late MasteryGraphService service;
    late FakeMasteryStateRepo mockMasteryStateRepo;
    late FakeQuestionMasteryStateRepo mockQuestionMasteryRepo;
    late FakeQuestionEvaluationRepo mockEvalRepo;

    setUp(() {
      mockMasteryStateRepo = FakeMasteryStateRepo();
      mockQuestionMasteryRepo = FakeQuestionMasteryStateRepo();
      mockEvalRepo = FakeQuestionEvaluationRepo();
      service = MasteryGraphService(
        masteryStateRepo: mockMasteryStateRepo,
        questionMasteryRepo: mockQuestionMasteryRepo,
        questionEvaluationRepo: mockEvalRepo,
      );
    });

    group('init', () {
      test('initializes successfully', () async {
        await service.init();
      });
    });

    group('recordAttempt', () {
      test('records attempt successfully', () async {
        final result = await service.recordAttempt(
          studentId: 'student1',
          topicId: 'topic1',
          questionId: 'q1',
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 5000,
        );
        expect(result.isSuccess, isTrue);
      });

      test('records incorrect attempt', () async {
        final result = await service.recordAttempt(
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
        final result = await service.recordAttempt(
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

    group('getTopicMastery', () {
      test('returns topic mastery state', () async {
        final result = await service.getTopicMastery('student1', 'topic1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.topicId, equals('topic1'));
        expect(result.data!.studentId, equals('student1'));
      });
    });

    group('getQuestionMastery', () {
      test('returns question mastery state', () async {
        final result = await service.getQuestionMastery('student1', 'q1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.questionId, equals('q1'));
      });
    });

    group('getAllTopicMastery', () {
      test('returns all topic mastery states for student', () async {
        final result = await service.getAllTopicMastery('student1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isA<List>());
      });
    });

    group('getQuestionsDueForReview', () {
      test('returns questions due for review', () async {
        final result = await service.getQuestionsDueForReview('student1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isA<List>());
      });

      test('respects asOf parameter', () async {
        final asOf = DateTime.now();
        final result = await service.getQuestionsDueForReview('student1', asOf: asOf);
        expect(result.isSuccess, isTrue);
      });
    });

    group('getAtRiskQuestions', () {
      test('returns at risk questions with default threshold', () async {
        final result = await service.getAtRiskQuestions('student1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isA<List>());
      });

      test('respects custom threshold', () async {
        final result = await service.getAtRiskQuestions('student1', threshold: 0.3);
        expect(result.isSuccess, isTrue);
      });
    });

    group('getTopicsNeedingReview', () {
      test('returns topics needing review', () async {
        final result = await service.getTopicsNeedingReview('student1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isA<List>());
      });
    });

    group('getWeakTopics', () {
      test('returns weak topics', () async {
        final result = await service.getWeakTopics('student1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isA<List>());
      });
    });

    group('getMasterySnapshot', () {
      test('returns mastery snapshot', () async {
        final result = await service.getMasterySnapshot('student1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!['totalTopics'], equals(10));
        expect(result.data!['masteredTopics'], equals(5));
      });
    });

    group('saveEvaluation', () {
      test('saves evaluation successfully', () async {
        final evaluation = QuestionEvaluation(
          questionId: 'q1',
          correctAnswer: '42',
          evaluationType: EvaluationType.exactMatch,
        );

        final result = await service.saveEvaluation(evaluation);
        expect(result.isSuccess, isTrue);
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

    group('getReadinessScore', () {
      test('returns readiness score for topic', () async {
        final result = await service.getReadinessScore('student1', 'topic1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isA<double>());
      });
    });

    group('getReviewUrgency', () {
      test('returns review urgency for topic', () async {
        final result = await service.getReviewUrgency('student1', 'topic1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isA<double>());
      });

      test('returns failure when repo fails', () async {
        mockMasteryStateRepo.failOnGet = true;
        final result = await service.getReviewUrgency('student1', 'topic1');
        expect(result.isFailure, isTrue);
      });
    });

    group('error propagation', () {
      test('recordAttempt returns failure when getMasteryState fails', () async {
        mockMasteryStateRepo.failOnGet = true;
        final result = await service.recordAttempt(
          studentId: 's1',
          topicId: 't1',
          questionId: 'q1',
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 5000,
        );
        expect(result.isFailure, isTrue);
      });

      test('recordAttempt returns failure when updateMasteryState fails', () async {
        mockMasteryStateRepo.failOnUpdate = true;
        final result = await service.recordAttempt(
          studentId: 's1',
          topicId: 't1',
          questionId: 'q1',
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 5000,
        );
        expect(result.isFailure, isTrue);
      });

      test('getReadinessScore returns failure when repo fails', () async {
        mockMasteryStateRepo.failOnGet = true;
        final result = await service.getReadinessScore('s1', 't1');
        expect(result.isFailure, isTrue);
      });
    });

    group('value assertions', () {
      test('getTopicMastery returns initial state with expected values', () async {
        final result = await service.getTopicMastery('s1', 't1');
        expect(result.isSuccess, isTrue);
        final state = result.data!;
        expect(state.accuracy, equals(0.0));
        expect(state.totalAttempts, equals(0));
        expect(state.correctAttempts, equals(0));
        expect(state.masteryLevel, equals(MasteryLevel.novice));
      });

      test('getTopicMastery returns pre-set state values', () async {
        mockMasteryStateRepo.addMasteryState(
          MasteryState.initial(studentId: 's1', topicId: 't1').copyWith(
            accuracy: 0.85,
            totalAttempts: 20,
            correctAttempts: 17,
            currentStreak: 8,
            masteryLevel: MasteryLevel.proficient,
          ),
        );
        final result = await service.getTopicMastery('s1', 't1');
        expect(result.isSuccess, isTrue);
        final state = result.data!;
        expect(state.accuracy, equals(0.85));
        expect(state.totalAttempts, equals(20));
        expect(state.correctAttempts, equals(17));
        expect(state.currentStreak, equals(8));
        expect(state.masteryLevel, equals(MasteryLevel.proficient));
      });

      test('getAllTopicMastery returns correct count', () async {
        mockMasteryStateRepo.addMasteryState(
          MasteryState.initial(studentId: 's1', topicId: 't1'),
        );
        mockMasteryStateRepo.addMasteryState(
          MasteryState.initial(studentId: 's1', topicId: 't2'),
        );
        final result = await service.getAllTopicMastery('s1');
        expect(result.isSuccess, isTrue);
        expect(result.data!.length, equals(2));
      });

      test('recordAttempt updates accuracy after correct attempt', () async {
        await service.recordAttempt(
          studentId: 's1',
          topicId: 't1',
          questionId: 'q1',
          isCorrect: true,
          confidence: 5,
          timeSpentMs: 10000,
        );
        final result = await service.getTopicMastery('s1', 't1');
        expect(result.isSuccess, isTrue);
        expect(result.data!.accuracy, greaterThan(0.0));
        expect(result.data!.totalAttempts, equals(1));
        expect(result.data!.correctAttempts, equals(1));
      });

      test('recordAttempt updates accuracy after incorrect attempt', () async {
        await service.recordAttempt(
          studentId: 's1',
          topicId: 't1',
          questionId: 'q1',
          isCorrect: false,
          confidence: 2,
          timeSpentMs: 5000,
        );
        final result = await service.getTopicMastery('s1', 't1');
        expect(result.isSuccess, isTrue);
        expect(result.data!.accuracy, equals(0.0));
        expect(result.data!.totalAttempts, equals(1));
        expect(result.data!.correctAttempts, equals(0));
      });

      test('getReadinessScore returns correct value', () async {
        mockMasteryStateRepo.addMasteryState(
          MasteryState.initial(studentId: 's1', topicId: 't1').copyWith(
            accuracy: 0.9,
            currentStreak: 10,
          ),
        );
        final result = await service.getReadinessScore('s1', 't1');
        expect(result.isSuccess, isTrue);
        expect(result.data!, greaterThan(0.0));
      });

      test('getReviewUrgency returns correct value', () async {
        mockMasteryStateRepo.addMasteryState(
          MasteryState.initial(studentId: 's1', topicId: 't1').copyWith(
            reviewUrgency: 0.8,
          ),
        );
        final result = await service.getReviewUrgency('s1', 't1');
        expect(result.isSuccess, isTrue);
        expect(result.data!, equals(0.8));
      });

      test('getMasterySnapshot returns specific values', () async {
        final result = await service.getMasterySnapshot('s1');
        expect(result.isSuccess, isTrue);
        expect(result.data!['totalTopics'], equals(10));
        expect(result.data!['masteredTopics'], equals(5));
      });
    });
  });
}