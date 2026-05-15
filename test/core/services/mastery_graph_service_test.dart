import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/questions/data/models/question_evaluation_model.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';

class MockMasteryGraphRepository extends MasteryGraphRepository {
  final Map<String, MasteryState> _masteryStates = {};
  final Map<String, QuestionMasteryState> _questionMasteryStates = {};
  final Map<String, QuestionEvaluation> _evaluations = {};

  @override
  Future<void> init() async {}

  void addMasteryState(MasteryState state) {
    _masteryStates['${state.studentId}_${state.topicId}'] = state;
  }

  void addQuestionMasteryState(QuestionMasteryState state) {
    _questionMasteryStates['${state.studentId}_${state.questionId}'] = state;
  }

  void addEvaluation(QuestionEvaluation evaluation) {
    _evaluations[evaluation.questionId] = evaluation;
  }

  @override
  Future<Result<MasteryState>> getMasteryState(String studentId, String topicId) async {
    final key = '${studentId}_$topicId';
    if (_masteryStates.containsKey(key)) {
      return Result.success(_masteryStates[key]!);
    }
    final newState = MasteryState.initial(studentId: studentId, topicId: topicId);
    _masteryStates[key] = newState;
    return Result.success(newState);
  }

  @override
  Future<Result<void>> updateMasteryState(MasteryState state) async {
    final key = '${state.studentId}_${state.topicId}';
    _masteryStates[key] = state;
    return Result.success(null);
  }

  @override
  Future<Result<List<MasteryState>>> getAllMasteryStates(String studentId) async {
    final states = _masteryStates.values
        .where((s) => s.studentId == studentId)
        .toList();
    return Result.success(states);
  }

  @override
  Future<Result<QuestionMasteryState>> getQuestionMasteryState(String studentId, String questionId) async {
    final key = '${studentId}_$questionId';
    if (_questionMasteryStates.containsKey(key)) {
      return Result.success(_questionMasteryStates[key]!);
    }
    final newState = QuestionMasteryState.initial(studentId: studentId, questionId: questionId);
    _questionMasteryStates[key] = newState;
    return Result.success(newState);
  }

  @override
  Future<Result<void>> updateQuestionMasteryState(QuestionMasteryState state) async {
    final key = '${state.studentId}_${state.questionId}';
    _questionMasteryStates[key] = state;
    return Result.success(null);
  }

  @override
  Future<Result<List<QuestionMasteryState>>> getDueQuestions(String studentId, {DateTime? asOf}) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(String studentId, {double threshold = 0.5}) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<MasteryState>>> getTopicsNeedingReview(String studentId) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return Result.success([]);
  }

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) async {
    return Result.success({
      'totalTopics': 10,
      'masteredTopics': 5,
    });
  }

  @override
  Future<Result<void>> migrateFromLegacy({
    required String questionId,
    String? markscheme,
    String? correctAnswer,
    List<String>? options,
    String? explanation,
  }) async {
    return Result.success(null);
  }

  @override
  Future<Result<QuestionEvaluation>> getEvaluation(String questionId) async {
    if (_evaluations.containsKey(questionId)) {
      return Result.success(_evaluations[questionId]!);
    }
    final eval = QuestionEvaluation(
      questionId: questionId,
      correctAnswer: '42',
      evaluationType: EvaluationType.exactMatch,
    );
    return Result.success(eval);
  }

  @override
  Future<Result<void>> saveEvaluation(QuestionEvaluation evaluation) async {
    _evaluations[evaluation.questionId] = evaluation;
    return Result.success(null);
  }

  @override
  Future<Result<List<TopicDependency>>> getAllDependencies() async {
    return Result.success([]);
  }

  @override
  Future<Result<TopicDependency>> getTopicDependency(String topicId) async {
    return Result.success(TopicDependency(topicId: topicId));
  }

  @override
  Future<Result<void>> updateTopicDependency(TopicDependency dependency) async {
    return Result.success(null);
  }
}

void main() {
  group('MasteryGraphService', () {
    late MasteryGraphService service;
    late MockMasteryGraphRepository mockRepo;

    setUp(() {
      mockRepo = MockMasteryGraphRepository();
      service = MasteryGraphService(repository: mockRepo);
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
    });
  });
}