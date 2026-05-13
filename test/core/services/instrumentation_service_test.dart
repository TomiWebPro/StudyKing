import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/data/models/topic_dependency_model.dart';
import 'package:studyking/core/data/models/question_evaluation_model.dart';

class MockMasteryGraphRepository implements MasteryGraphRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<MasteryState>> getMasteryState(String studentId, String topicId) async {
      final state = MasteryState.initial(studentId: studentId, topicId: topicId).copyWith(
        accuracy: 0.8,
        readinessScore: 0.8,
        masteryLevel: MasteryLevel.proficient,
      );
    return Result.success(state);
  }

  @override
  Future<Result<void>> updateMasteryState(MasteryState state) async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getAllMasteryStates(String studentId) async => Result.success([]);

  @override
  Future<Result<QuestionMasteryState>> getQuestionMasteryState(String studentId, String questionId) async => Result.success(QuestionMasteryState.initial(studentId: studentId, questionId: questionId));

  @override
  Future<Result<void>> updateQuestionMasteryState(QuestionMasteryState state) async => Result.success(null);

  @override
  Future<Result<List<QuestionMasteryState>>> getDueQuestions(String studentId, {DateTime? asOf}) async => Result.success([]);

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(String studentId, {double threshold = 0.5}) async => Result.success([]);

  @override
  Future<Result<List<MasteryState>>> getTopicsNeedingReview(String studentId) async => Result.success([]);

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async => Result.success([]);

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) async => Result.success({
    'totalTopics': 10,
    'masteredTopics': 5,
  });

  @override
  Future<Result<void>> migrateFromLegacy({required String questionId, String? markscheme, String? correctAnswer, List<String>? options, String? explanation}) async => Result.success(null);

  @override
  Future<Result<QuestionEvaluation>> getEvaluation(String questionId) async => Result.success(QuestionEvaluation(questionId: questionId, correctAnswer: ''));

  @override
  Future<Result<void>> saveEvaluation(dynamic evaluation) async => Result.success(null);

  @override
  Future<Result<List<TopicDependency>>> getAllDependencies() async => Result.success([]);

  @override
  Future<Result<TopicDependency>> getTopicDependency(String topicId) async => Result.success(TopicDependency(topicId: topicId));

  @override
  Future<Result<void>> updateTopicDependency(TopicDependency dependency) async => Result.success(null);
}

void main() {
  group('InstrumentationService', () {
    late InstrumentationService service;
    late MockMasteryGraphRepository mockRepo;

    setUp(() {
      mockRepo = MockMasteryGraphRepository();
      service = InstrumentationService(repository: mockRepo);
    });

    group('init', () {
      test('initializes successfully', () async {
        await service.init();
      });
    });

    group('recordPlanAdherence', () {
      test('records plan adherence with all parameters', () {
        service.recordPlanAdherence(
          studentId: 'student1',
          plannedQuestions: 15,
          actualQuestions: 12,
          plannedMinutes: 30,
          actualMinutes: 25,
        );
      });

      test('records plan adherence with custom date', () {
        service.recordPlanAdherence(
          studentId: 'student1',
          plannedQuestions: 15,
          actualQuestions: 15,
          plannedMinutes: 30,
          actualMinutes: 30,
          date: DateTime(2026, 1, 1),
        );
      });

      test('records zero adherence', () {
        service.recordPlanAdherence(
          studentId: 'student1',
          plannedQuestions: 0,
          actualQuestions: 0,
          plannedMinutes: 0,
          actualMinutes: 0,
        );
      });

      test('records overachievement', () {
        service.recordPlanAdherence(
          studentId: 'student1',
          plannedQuestions: 10,
          actualQuestions: 20,
          plannedMinutes: 30,
          actualMinutes: 60,
        );
      });
    });

    group('trackMasteryImprovement', () {
      test('tracks improvement successfully', () async {
        final result = await service.trackMasteryImprovement('student1', 'topic1');
        expect(result.isSuccess, isTrue);
      });
    });

    group('getInstrumentationDashboard', () {
      test('returns dashboard data', () async {
        final result = await service.getInstrumentationDashboard('student1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!['planAdherence'], isA<Map>());
        expect(result.data!['masteryImprovement'], isA<Map>());
        expect(result.data!['generatedAt'], isA<String>());
      });

      test('returns empty weekly metrics', () async {
        final result = await service.getInstrumentationDashboard('student1');
        expect(result.isSuccess, isTrue);
        final weeklyAdherence = result.data!['planAdherence'] as Map;
        expect(weeklyAdherence['weeklyMetricsCount'], equals(0));
        expect(weeklyAdherence['weeklyAdherenceAvg'], equals(0.0));
      });
    });

    group('getAdherenceHistory', () {
      test('returns empty history initially', () {
        final history = service.getAdherenceHistory('student1');
        expect(history, isEmpty);
      });

      test('returns history after recording', () {
        service.recordPlanAdherence(
          studentId: 'student1',
          plannedQuestions: 10,
          actualQuestions: 8,
          plannedMinutes: 30,
          actualMinutes: 25,
        );
        final history = service.getAdherenceHistory('student1');
        expect(history.length, equals(1));
      });
    });

    group('getImprovementHistory', () {
      test('returns empty history initially', () {
        final history = service.getImprovementHistory('student1');
        expect(history, isEmpty);
      });
    });

    group('exportInstrumentationData', () {
      test('exports data successfully', () async {
        service.recordPlanAdherence(
          studentId: 'student1',
          plannedQuestions: 10,
          actualQuestions: 8,
          plannedMinutes: 30,
          actualMinutes: 25,
        );
        final result = await service.exportInstrumentationData('student1');
        expect(result.isSuccess, isTrue);
      });

      test('exports empty data', () async {
        final result = await service.exportInstrumentationData('student1');
        expect(result.isSuccess, isTrue);
      });
    });
  });

  group('PlanAdherenceTracker', () {
    late PlanAdherenceTracker tracker;

    setUp(() {
      tracker = PlanAdherenceTracker();
    });

    group('recordDay', () {
      test('records day with all parameters', () {
        tracker.recordDay(
          studentId: 'student1',
          date: DateTime(2026, 5, 1),
          plannedQuestions: 15,
          actualQuestions: 12,
          plannedMinutes: 30,
          actualMinutes: 25,
        );
      });

      test('records day with metadata', () {
        tracker.recordDay(
          studentId: 'student1',
          date: DateTime(2026, 5, 1),
          plannedQuestions: 15,
          actualQuestions: 12,
          plannedMinutes: 30,
          actualMinutes: 25,
          metadata: {'sessionId': 'sess1'},
        );
      });
    });

    group('getAverageAdherence', () {
      test('returns 0 for empty metrics', () {
        final avg = tracker.getAverageAdherence('student1');
        expect(avg, equals(0.0));
      });

      test('calculates average correctly', () {
        tracker.recordDay(
          studentId: 'student1',
          date: DateTime(2026, 5, 1),
          plannedQuestions: 10,
          actualQuestions: 10,
          plannedMinutes: 30,
          actualMinutes: 30,
        );
        tracker.recordDay(
          studentId: 'student1',
          date: DateTime(2026, 5, 2),
          plannedQuestions: 10,
          actualQuestions: 5,
          plannedMinutes: 30,
          actualMinutes: 15,
        );
        final avg = tracker.getAverageAdherence('student1');
        expect(avg, greaterThan(0.0));
      });

      test('returns 0 for non-existent student', () {
        tracker.recordDay(
          studentId: 'student1',
          date: DateTime(2026, 5, 1),
          plannedQuestions: 10,
          actualQuestions: 10,
          plannedMinutes: 30,
          actualMinutes: 30,
        );
        final avg = tracker.getAverageAdherence('nonexistent');
        expect(avg, equals(0.0));
      });
    });

    group('getWeeklyMetrics', () {
      test('returns weekly metrics', () {
        final now = DateTime.now();
        tracker.recordDay(
          studentId: 'student1',
          date: now,
          plannedQuestions: 10,
          actualQuestions: 10,
          plannedMinutes: 30,
          actualMinutes: 30,
        );
        final metrics = tracker.getWeeklyMetrics('student1');
        expect(metrics.length, equals(1));
      });

      test('excludes old metrics', () {
        final now = DateTime.now();
        final weekAgo = now.subtract(const Duration(days: 10));
        tracker.recordDay(
          studentId: 'student1',
          date: weekAgo,
          plannedQuestions: 10,
          actualQuestions: 10,
          plannedMinutes: 30,
          actualMinutes: 30,
        );
        final metrics = tracker.getWeeklyMetrics('student1');
        expect(metrics, isEmpty);
      });
    });

    group('getAllMetrics', () {
      test('returns all metrics for student', () {
        tracker.recordDay(
          studentId: 'student1',
          date: DateTime(2026, 5, 1),
          plannedQuestions: 10,
          actualQuestions: 10,
          plannedMinutes: 30,
          actualMinutes: 30,
        );
        tracker.recordDay(
          studentId: 'student1',
          date: DateTime(2026, 5, 2),
          plannedQuestions: 10,
          actualQuestions: 8,
          plannedMinutes: 30,
          actualMinutes: 25,
        );
        final metrics = tracker.getAllMetrics('student1');
        expect(metrics.length, equals(2));
      });
    });
  });

  group('MasteryImprovementTracker', () {
    late MasteryImprovementTracker tracker;

    setUp(() {
      tracker = MasteryImprovementTracker();
    });

    group('trackImprovement', () {
      test('tracks improvement with changed accuracy', () {
        var state = MasteryState.initial(studentId: 'student1', topicId: 'topic1');
        state = state.copyWith(accuracy: 0.5);
        tracker.trackImprovement(currentState: state, studentId: 'student1');

        state = state.copyWith(accuracy: 0.7);
        tracker.trackImprovement(currentState: state, studentId: 'student1');

        final improvements = tracker.getImprovements('student1');
        expect(improvements.length, equals(1));
      });

      test('does not track when accuracy unchanged', () {
        var state = MasteryState.initial(studentId: 'student1', topicId: 'topic1');
        state = state.copyWith(accuracy: 0.5);
        tracker.trackImprovement(currentState: state, studentId: 'student1');

        final improvements = tracker.getImprovements('student1');
        expect(improvements, isEmpty);
      });

      test('tracks multiple topics', () {
        var state = MasteryState.initial(studentId: 'student1', topicId: 'topic1');
        state = state.copyWith(accuracy: 0.5);
        tracker.trackImprovement(currentState: state, studentId: 'student1');

        state = MasteryState.initial(studentId: 'student1', topicId: 'topic1');
        state = state.copyWith(accuracy: 0.7);
        tracker.trackImprovement(currentState: state, studentId: 'student1');

        state = MasteryState.initial(studentId: 'student1', topicId: 'topic2');
        state = state.copyWith(accuracy: 0.3);
        tracker.trackImprovement(currentState: state, studentId: 'student1');

        final improvements = tracker.getImprovements('student1');
        expect(improvements.length, equals(2));
      });
    });

    group('getImprovements', () {
      test('returns all improvements for student', () {
        var state1 = MasteryState.initial(studentId: 'student1', topicId: 'topic1');
        state1 = state1.copyWith(accuracy: 0.5);
        tracker.trackImprovement(currentState: state1, studentId: 'student1');

        var state2 = MasteryState.initial(studentId: 'student1', topicId: 'topic1');
        state2 = state2.copyWith(accuracy: 0.7);
        tracker.trackImprovement(currentState: state2, studentId: 'student1');

        final improvements = tracker.getImprovements('student1');
        expect(improvements, isNotEmpty);
      });

      test('returns empty for non-existent student', () {
        final improvements = tracker.getImprovements('nonexistent');
        expect(improvements, isEmpty);
      });
    });

    group('getRecentImprovements', () {
      test('returns recent improvements within days', () {
        var state = MasteryState.initial(studentId: 'student1', topicId: 'topic1');
        state = state.copyWith(accuracy: 0.5);
        tracker.trackImprovement(currentState: state, studentId: 'student1');

        var state2 = MasteryState.initial(studentId: 'student1', topicId: 'topic1');
        state2 = state2.copyWith(accuracy: 0.7);
        tracker.trackImprovement(currentState: state2, studentId: 'student1');

        final improvements = tracker.getRecentImprovements('student1', days: 7);
        expect(improvements.length, equals(2));
      });
    });

    group('getLevelUpCount', () {
      test('returns count of level ups', () {
        var state = MasteryState.initial(studentId: 'student1', topicId: 'topic1');
        state = state.copyWith(accuracy: 0.5);
        state = state.copyWith(masteryLevel: MasteryLevel.novice);
        tracker.trackImprovement(currentState: state, studentId: 'student1');

        state = MasteryState.initial(studentId: 'student1', topicId: 'topic1');
        state = state.copyWith(accuracy: 0.7);
        state = state.copyWith(masteryLevel: MasteryLevel.browsing);
        tracker.trackImprovement(currentState: state, studentId: 'student1');

        final count = tracker.getLevelUpCount('student1');
        expect(count, equals(1));
      });

      test('returns 0 when no level ups', () {
        var state = MasteryState.initial(studentId: 'student1', topicId: 'topic1');
        state = state.copyWith(accuracy: 0.5);
        state = state.copyWith(masteryLevel: MasteryLevel.novice);
        tracker.trackImprovement(currentState: state, studentId: 'student1');

        final count = tracker.getLevelUpCount('student1');
        expect(count, equals(0));
      });
    });

    group('getAverageImprovement', () {
      test('calculates average improvement', () {
        var state = MasteryState.initial(studentId: 'student1', topicId: 'topic1');
        state = state.copyWith(accuracy: 0.5);
        tracker.trackImprovement(currentState: state, studentId: 'student1');

        state = MasteryState.initial(studentId: 'student1', topicId: 'topic1');
        state = state.copyWith(accuracy: 0.7);
        tracker.trackImprovement(currentState: state, studentId: 'student1');

        final avg = tracker.getAverageImprovement('student1');
        expect(avg, greaterThan(0.0));
      });

      test('returns 0 for no improvements', () {
        final avg = tracker.getAverageImprovement('student1');
        expect(avg, equals(0.0));
      });
    });
  });

  group('PlanAdherenceMetric', () {
    test('creates metric with all fields', () {
      final metric = PlanAdherenceMetric(
        date: DateTime(2026, 5, 1),
        studentId: 'student1',
        plannedQuestions: 15,
        actualQuestions: 12,
        plannedMinutes: 30,
        actualMinutes: 25,
        adherenceScore: 0.8,
      );
      expect(metric.studentId, equals('student1'));
      expect(metric.plannedQuestions, equals(15));
      expect(metric.adherenceScore, equals(0.8));
    });

    test('creates metric with metadata', () {
      final metric = PlanAdherenceMetric(
        date: DateTime(2026, 5, 1),
        studentId: 'student1',
        plannedQuestions: 15,
        actualQuestions: 12,
        plannedMinutes: 30,
        actualMinutes: 25,
        adherenceScore: 0.8,
        metadata: {'sessionId': 'sess1'},
      );
      expect(metric.metadata, isNotNull);
      expect(metric.metadata!['sessionId'], equals('sess1'));
    });

    test('toJson returns correct map', () {
      final metric = PlanAdherenceMetric(
        date: DateTime(2026, 5, 1),
        studentId: 'student1',
        plannedQuestions: 15,
        actualQuestions: 12,
        plannedMinutes: 30,
        actualMinutes: 25,
        adherenceScore: 0.8,
      );
      final json = metric.toJson();
      expect(json['studentId'], equals('student1'));
      expect(json['plannedQuestions'], equals(15));
      expect(json['adherenceScore'], equals(0.8));
    });
  });

  group('MasteryImprovementMetric', () {
    test('creates metric with all fields', () {
      final metric = MasteryImprovementMetric(
        date: DateTime(2026, 5, 1),
        studentId: 'student1',
        topicId: 'topic1',
        previousAccuracy: 0.5,
        currentAccuracy: 0.7,
        accuracyDelta: 0.2,
        previousMasteryLevel: 0.5,
        currentMasteryLevel: 0.7,
        previousLevel: MasteryLevel.novice,
        currentLevel: MasteryLevel.browsing,
      );
      expect(metric.studentId, equals('student1'));
      expect(metric.topicId, equals('topic1'));
      expect(metric.accuracyDelta, equals(0.2));
    });

    test('leveledUp returns true when level increased', () {
      final metric = MasteryImprovementMetric(
        date: DateTime(2026, 5, 1),
        studentId: 'student1',
        topicId: 'topic1',
        previousAccuracy: 0.5,
        currentAccuracy: 0.7,
        accuracyDelta: 0.2,
        previousMasteryLevel: 0.5,
        currentMasteryLevel: 0.7,
        previousLevel: MasteryLevel.novice,
        currentLevel: MasteryLevel.browsing,
      );
      expect(metric.leveledUp, isTrue);
    });

    test('leveledUp returns false when level same', () {
      final metric = MasteryImprovementMetric(
        date: DateTime(2026, 5, 1),
        studentId: 'student1',
        topicId: 'topic1',
        previousAccuracy: 0.5,
        currentAccuracy: 0.6,
        accuracyDelta: 0.1,
        previousMasteryLevel: 0.5,
        currentMasteryLevel: 0.6,
        previousLevel: MasteryLevel.novice,
        currentLevel: MasteryLevel.novice,
      );
      expect(metric.leveledUp, isFalse);
    });

    test('toJson returns correct map', () {
      final metric = MasteryImprovementMetric(
        date: DateTime(2026, 5, 1),
        studentId: 'student1',
        topicId: 'topic1',
        previousAccuracy: 0.5,
        currentAccuracy: 0.7,
        accuracyDelta: 0.2,
        previousMasteryLevel: 0.5,
        currentMasteryLevel: 0.7,
        previousLevel: MasteryLevel.novice,
        currentLevel: MasteryLevel.browsing,
      );
      final json = metric.toJson();
      expect(json['studentId'], equals('student1'));
      expect(json['topicId'], equals('topic1'));
      expect(json['leveledUp'], isTrue);
    });
  });
}