import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/dashboard/services/dashboard_data_loader.dart';

class _FakeSessionRepo extends SessionRepository {
  final List<Session>? sessions;
  final bool shouldThrow;

  _FakeSessionRepo({this.sessions, this.shouldThrow = false});

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async {
    if (shouldThrow) throw Exception('Session repo error');
    return Result.success(sessions ?? []);
  }
}

class _FakeMasteryGraphService extends MasteryGraphService {
  final List<MasteryState>? allMastery;
  final Map<String, dynamic>? snapshot;
  final bool failGetAllMastery;
  final bool failGetSnapshot;

  _FakeMasteryGraphService({
    this.allMastery,
    this.snapshot,
    this.failGetAllMastery = false,
    this.failGetSnapshot = false,
  });

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) async {
    if (failGetAllMastery) return Result.failure('Failed');
    return Result.success(allMastery ?? []);
  }

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) async {
    if (failGetSnapshot) return Result.failure('Failed');
    return Result.success(snapshot ?? {
      'totalTopics': 0,
      'masteredTopics': 0,
      'weakTopics': 0,
      'averageAccuracy': 0.0,
      'avgReadiness': 0.0,
    });
  }
}

class _FakeAttemptRepository extends AttemptRepository {
  @override
  Future<void> init() async {}

  @override
  Future<List<StudentAttempt>> getByStudent(String studentId) async {
    return [];
  }
}

class _FakeStudyProgressTracker extends StudyProgressTracker {
  final Map<String, dynamic>? overallStats;

  _FakeStudyProgressTracker({this.overallStats})
      : super(attemptRepo: _FakeAttemptRepository());

  @override
  Future<Map<String, dynamic>> getOverallStats(String studentId) async {
    return overallStats ?? {
      'accuracy': 0,
      'totalStudyTimeHours': '0.0',
      'weeklyActivity': 0,
      'topicsStudied': 0,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getWeeklyTrend(int weeks, {String? studentId}) async {
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getBadges(String studentId) async {
    return [];
  }
}

class _FakeInstrumentationService extends InstrumentationService {
  @override
  Future<void> init() async {}
}

class _FakeTopicRepository extends TopicRepository {
  final Topic? topic;
  final bool shouldThrow;

  _FakeTopicRepository({this.topic, this.shouldThrow = false});

  @override
  Future<void> init() async {}

  @override
  Future<Topic?> get(String id) async {
    if (shouldThrow) throw Exception('Topic error');
    return topic;
  }
}

class _FakePlanAdherenceRepository extends PlanAdherenceRepository {
  final List<PlanAdherenceModel> records;

  _FakePlanAdherenceRepository({this.records = const []});

  @override
  Future<void> init() async {}

  @override
  Future<double> getAverageAdherence(String studentId) async {
    if (records.isEmpty) return 0.0;
    return records.fold<double>(0.0, (sum, r) => sum + r.adherenceScore) /
        records.length;
  }

  @override
  Future<List<PlanAdherenceModel>> getWeekly(String studentId) async {
    return records;
  }
}

void main() {
  group('DashboardDataLoader', () {
    test('loads data successfully with all services', () async {
      final masteryStates = [
        MasteryState(
          studentId: 's1',
          topicId: 't1',
          accuracy: 0.5,
          totalAttempts: 5,
          correctAttempts: 2,
          masteryLevel: MasteryLevel.developing,
          lastAttempt: DateTime.now(),
          lastUpdated: DateTime.now(),
        ),
      ];

      final loader = DashboardDataLoader(
        masteryService: _FakeMasteryGraphService(
          allMastery: masteryStates,
          snapshot: {
            'totalTopics': 10,
            'masteredTopics': 3,
            'weakTopics': 2,
            'averageAccuracy': 0.6,
            'avgReadiness': 0.5,
          },
        ),
        tracker: _FakeStudyProgressTracker(overallStats: {
          'accuracy': 80,
          'totalStudyTimeHours': '10.5',
          'weeklyActivity': 20,
          'topicsStudied': 5,
        }),
        instrumentation: _FakeInstrumentationService(),
        topicRepo: _FakeTopicRepository(topic: Topic(
          id: 't1',
          subjectId: 'subj-1',
          title: 'Algebra',
          description: '',
          syllabusText: '',
        )),
        sessionRepo: _FakeSessionRepo(sessions: [
          Session(
            id: 'focus-1',
            studentId: 's1',
            startTime: DateTime.now(),
            type: SessionType.focus,
            actualDurationMs: 3600000,
            completed: true,
          ),
        ]),
        adherenceRepo: _FakePlanAdherenceRepository(records: [
          PlanAdherenceModel(
            id: 'a1',
            studentId: 's1',
            date: DateTime.now(),
            adherenceScore: 0.8,
          ),
          PlanAdherenceModel(
            id: 'a2',
            studentId: 's1',
            date: DateTime.now(),
            adherenceScore: 0.6,
          ),
        ]),
        studentId: 's1',
      );

      final data = await loader.load();

      expect(data.allMastery, hasLength(1));
      expect(data.allMastery[0].topicId, 't1');
      expect(data.snapshot!['totalTopics'], 10);
      expect(data.overallStats!['accuracy'], 80);
      expect(data.focusTodayStats!['totalSeconds'], 3600);
      expect(data.averageAdherence, 0.7);
      expect(data.weeklyAdherence, 0.7);
      expect(data.topicNameCache['t1'], 'Algebra');
    });

    test('focus service failure leaves focusTodayStats null', () async {
      final loader = DashboardDataLoader(
        masteryService: _FakeMasteryGraphService(),
        tracker: _FakeStudyProgressTracker(),
        instrumentation: _FakeInstrumentationService(),
        topicRepo: _FakeTopicRepository(),
        sessionRepo: _FakeSessionRepo(shouldThrow: true),
        adherenceRepo: _FakePlanAdherenceRepository(),
        studentId: 's1',
      );

      final data = await loader.load();
      expect(data.focusTodayStats, isNull);
    });

    test('getAllTopicMastery failure leaves allMastery empty', () async {
      final loader = DashboardDataLoader(
        masteryService: _FakeMasteryGraphService(failGetAllMastery: true),
        tracker: _FakeStudyProgressTracker(),
        instrumentation: _FakeInstrumentationService(),
        topicRepo: _FakeTopicRepository(),
        sessionRepo: _FakeSessionRepo(),
        adherenceRepo: _FakePlanAdherenceRepository(),
        studentId: 's1',
      );

      final data = await loader.load();
      expect(data.allMastery, isEmpty);
    });

    test('getMasterySnapshot failure leaves snapshot null', () async {
      final loader = DashboardDataLoader(
        masteryService: _FakeMasteryGraphService(failGetSnapshot: true),
        tracker: _FakeStudyProgressTracker(),
        instrumentation: _FakeInstrumentationService(),
        topicRepo: _FakeTopicRepository(),
        sessionRepo: _FakeSessionRepo(),
        adherenceRepo: _FakePlanAdherenceRepository(),
        studentId: 's1',
      );

      final data = await loader.load();
      expect(data.snapshot, isNull);
    });

    test('handles combined partial failures gracefully', () async {
      final loader = DashboardDataLoader(
        masteryService: _FakeMasteryGraphService(
          failGetAllMastery: true,
          failGetSnapshot: true,
        ),
        tracker: _FakeStudyProgressTracker(),
        instrumentation: _FakeInstrumentationService(),
        topicRepo: _FakeTopicRepository(),
        sessionRepo: _FakeSessionRepo(shouldThrow: true),
        adherenceRepo: _FakePlanAdherenceRepository(),
        studentId: 's1',
      );

      final data = await loader.load();
      expect(data.allMastery, isEmpty);
      expect(data.snapshot, isNull);
      expect(data.focusTodayStats, isNull);
      expect(data.averageAdherence, 0.0);
      expect(data.weeklyAdherence, 0.0);
      expect(data.topicNameCache, isEmpty);
    });

    test('topic repo failure falls back to topicId in name cache', () async {
      final masteryStates = [
        MasteryState(
          studentId: 's1',
          topicId: 't1',
          accuracy: 0.5,
          totalAttempts: 5,
          correctAttempts: 2,
          masteryLevel: MasteryLevel.developing,
          lastAttempt: DateTime.now(),
          lastUpdated: DateTime.now(),
        ),
      ];

      final loader = DashboardDataLoader(
        masteryService: _FakeMasteryGraphService(allMastery: masteryStates),
        tracker: _FakeStudyProgressTracker(),
        instrumentation: _FakeInstrumentationService(),
        topicRepo: _FakeTopicRepository(shouldThrow: true),
        sessionRepo: _FakeSessionRepo(),
        adherenceRepo: _FakePlanAdherenceRepository(),
        studentId: 's1',
      );

      final data = await loader.load();
      expect(data.topicNameCache['t1'], 't1');
    });

    test('weeklyAdherence is 0.0 when no records', () async {
      final loader = DashboardDataLoader(
        masteryService: _FakeMasteryGraphService(),
        tracker: _FakeStudyProgressTracker(),
        instrumentation: _FakeInstrumentationService(),
        topicRepo: _FakeTopicRepository(),
        sessionRepo: _FakeSessionRepo(),
        adherenceRepo: _FakePlanAdherenceRepository(),
        studentId: 's1',
      );

      final data = await loader.load();
      expect(data.weeklyAdherence, 0.0);
    });
  });
}
