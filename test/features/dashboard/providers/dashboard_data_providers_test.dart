import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/providers/dashboard_data_providers.dart';
import 'package:studyking/features/dashboard/providers/dashboard_providers.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider;
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart' show topicRepositoryProvider;
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/remaining_workload_estimator.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart'
    show masteryGraphServiceProvider, spacedRepetitionServiceProvider;
import 'package:studyking/features/subjects/providers/subject_repository_provider.dart'
    show subjectRepositoryProvider;
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart' show plannerServiceProvider;
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';

class _FakeMasteryGraphService extends MasteryGraphService {
  final List<MasteryState>? _allMastery;
  final Map<String, dynamic>? _snapshot;
  final bool _failAllMastery;
  final bool _failSnapshot;
  final bool _failInit;

  _FakeMasteryGraphService({
    List<MasteryState>? allMastery,
    Map<String, dynamic>? snapshot,
    bool failAllMastery = false,
    bool failSnapshot = false,
    bool failInit = false,
  })  : _allMastery = allMastery,
        _snapshot = snapshot,
        _failAllMastery = failAllMastery,
        _failSnapshot = failSnapshot,
        _failInit = failInit;

  @override
  Future<Result<void>> init() async {
    if (_failInit) return Result.failure('init failed');
    return Result.success(null);
  }

  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) async {
    if (_failAllMastery) return Result.failure('fail');
    return Result.success(_allMastery ?? []);
  }

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) async {
    if (_failSnapshot) return Result.failure('fail');
    return Result.success(_snapshot ?? {});
  }
}

class _FakeAttemptRepo extends AttemptRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async => Result.success([]);
}

class _FakeProgressTracker extends StudyProgressTracker {
  final Map<String, dynamic>? _overallStats;
  final List<Map<String, dynamic>> _weeklyTrend;
  final List<Map<String, dynamic>> _badges;
  final bool _failGetBadges;

  _FakeProgressTracker({
    Map<String, dynamic>? overallStats,
    List<Map<String, dynamic>> weeklyTrend = const [],
    List<Map<String, dynamic>> badges = const [],
    bool failGetBadges = false,
  })  : _overallStats = overallStats,
        _weeklyTrend = weeklyTrend,
        _badges = badges,
        _failGetBadges = failGetBadges,
        super(attemptRepo: _FakeAttemptRepo(), l10n: lookupAppLocalizations(const Locale('en')));

  @override
  Future<Result<Map<String, dynamic>>> getOverallStats(String studentId) async {
    return Result.success(_overallStats ?? {
      'totalAttempts': 0,
      'correctAttempts': 0,
      'accuracy': 0,
      'avgTimePerQuestion': 0,
      'totalStudyTimeHours': '0.0',
      'weeklyActivity': 0,
      'dailyActivity': 0,
      'topicsStudied': 0,
    });
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getWeeklyTrend(int weeks,
      {String? studentId}) async {
    return Result.success(_weeklyTrend);
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getBadges(String studentId) async {
    if (_failGetBadges) return Result.failure('Badges error');
    return Result.success(_badges);
  }
}

class _FakeInstrumentationService extends InstrumentationService {
  @override
  Future<Result<void>> init() async => Result.success(null);
}

class _FakeTopicRepo extends TopicRepository {
  final List<Topic> _topics;

  _FakeTopicRepo({List<Topic> topics = const []}) : _topics = topics;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Topic>>> getAll() async => Result.success(_topics);
}

class _FakePlanAdherenceRepo extends PlanAdherenceRepository {
  final double _avgAdherence;
  final List<PlanAdherenceModel> _weeklyRecords;

  _FakePlanAdherenceRepo({
    double avgAdherence = 0.0,
    List<PlanAdherenceModel> weeklyRecords = const [],
  })  : _avgAdherence = avgAdherence,
        _weeklyRecords = weeklyRecords;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<double>> getAverageAdherence(String studentId) async => Result.success(_avgAdherence);

  @override
  Future<Result<List<PlanAdherenceModel>>> getWeekly(String studentId) async =>
      Result.success(_weeklyRecords);
}

class _FakeSessionRepo extends SessionRepository {
  final List<Session> _sessions;
  final bool _throwOnGetByDate;

  _FakeSessionRepo({List<Session> sessions = const [], bool throwOnGetByDate = false})
      : _sessions = sessions,
        _throwOnGetByDate = throwOnGetByDate;

  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async {
    if (_throwOnGetByDate) throw Exception('getByDate error');
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return Result.success(_sessions.where((s) =>
        s.startTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
        s.startTime.isBefore(end)).toList());
  }
}

ProviderContainer _createContainer({
  MasteryGraphService? masteryService,
  StudyProgressTracker? tracker,
  InstrumentationService? instrumentation,
  TopicRepository? topicRepo,
  PlanAdherenceRepository? adherenceRepo,
  SessionRepository? sessionRepo,
  SpacedRepetitionService? srService,
  SubjectRepository? subjectRepo,
  QuestionRepository? questionRepo,
  PlannerService? plannerServiceParam,
}) {
  return ProviderContainer(
    overrides: [
      masteryGraphServiceProvider.overrideWithValue(
        masteryService ?? _FakeMasteryGraphService(),
      ),
      dashboardStudyProgressTrackerProvider.overrideWithValue(
        tracker ?? _FakeProgressTracker(),
      ),
      dashboardInstrumentationServiceProvider.overrideWithValue(
        instrumentation ?? _FakeInstrumentationService(),
      ),
      topicRepositoryProvider.overrideWithValue(
        topicRepo ?? _FakeTopicRepo(),
      ),
      engagementAdherenceRepoProvider.overrideWithValue(
        adherenceRepo ?? _FakePlanAdherenceRepo(),
      ),
      if (sessionRepo != null)
        sessionRepositoryProvider.overrideWithValue(sessionRepo),
      if (srService != null)
        spacedRepetitionServiceProvider.overrideWithValue(srService),
      if (subjectRepo != null)
        subjectRepositoryProvider.overrideWithValue(subjectRepo),
      if (questionRepo != null)
        questionRepositoryProvider.overrideWithValue(questionRepo),
      if (plannerServiceParam != null)
        plannerServiceProvider.overrideWithValue(plannerServiceParam),
    ],
  );
}

class _FakeSpacedRepetitionService extends SpacedRepetitionService {
  final Map<String, int> _dueCounts;

  _FakeSpacedRepetitionService(this._dueCounts)
      : super(
          questionRepo: QuestionRepository(),
          attemptRepo: _FakeAttemptRepo(),
          srEngine: _FakeSpacedRepetitionEngine(),
        );

  @override
  Future<Result<int>> getSubjectDueCount(String subjectId) async {
    return Result.success(_dueCounts[subjectId] ?? 0);
  }
}

class _FakeSubjectRepo extends SubjectRepository {
  final List<Subject> _subjects;

  _FakeSubjectRepo({List<Subject> subjects = const []}) : _subjects = subjects;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Subject>>> getAll() async => Result.success(_subjects);
}

class _FakeSpacedRepetitionEngine extends SpacedRepetitionEngine {
  @override
  SM2Result scheduleReview({
    required String questionId,
    required int grade,
    QuestionSRData? currentData,
    DateTime? now,
  }) {
    return SM2Result(
      nextReview: DateTime.now(),
      updatedData: currentData ?? const QuestionSRData(),
    );
  }
}

class _FakeQuestionRepository extends QuestionRepository {
  final List<Question> _questions;

  _FakeQuestionRepository({List<Question> questions = const []}) : _questions = questions;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Question>>> getAll() async => Result.success(_questions);
}

class _FakePlannerService extends PlannerService {
  final PersonalLearningPlan? _plan;
  final List<Session> _scheduledLessons;
  final bool _loadExistingPlanThrows;

  _FakePlannerService({
    PersonalLearningPlan? plan,
    List<Session> scheduledLessons = const [],
    bool loadExistingPlanThrows = false,
  })  : _plan = plan,
        _scheduledLessons = scheduledLessons,
        _loadExistingPlanThrows = loadExistingPlanThrows,
        super();

  @override
  Future<Result<PersonalLearningPlan?>> loadExistingPlan() async {
    if (_loadExistingPlanThrows) throw Exception('loadExistingPlan error');
    return Result.success(_plan);
  }

  @override
  Future<Result<List<Session>>> getScheduledLessons() async {
    return Result.success(_scheduledLessons);
  }
}

void main() {
  group('dashboardAllMasteryProvider', () {
    test('returns list of MasteryState on success', () async {
      final now = DateTime.now();
      final masteryService = _FakeMasteryGraphService(
        allMastery: [
          MasteryState(studentId: 's1', topicId: 't1', lastAttempt: now, lastUpdated: now),
          MasteryState(studentId: 's1', topicId: 't2', lastAttempt: now, lastUpdated: now),
        ],
      );
      final container = _createContainer(masteryService: masteryService);
      addTearDown(container.dispose);

      final result = await container.read(dashboardAllMasteryProvider('s1').future);
      expect(result.length, 2);
    });

    test('returns empty list when getAllTopicMastery fails', () async {
      final masteryService = _FakeMasteryGraphService(failAllMastery: true);
      final container = _createContainer(masteryService: masteryService);
      addTearDown(container.dispose);

      final result = await container.read(dashboardAllMasteryProvider('s1').future);
      expect(result, isEmpty);
    });
  });

  group('dashboardMasterySnapshotProvider', () {
    test('returns MasterySnapshot on success', () async {
      final masteryService = _FakeMasteryGraphService(
        snapshot: {
          'totalTopics': 5,
          'masteredTopics': 2,
          'weakTopics': 1,
          'averageAccuracy': 0.8,
          'avgReadiness': 0.7,
        },
      );
      final container = _createContainer(masteryService: masteryService);
      addTearDown(container.dispose);

      final result = await container.read(dashboardMasterySnapshotProvider('s1').future);
      expect(result, isA<MasterySnapshot>());
      expect(result!.totalTopics, 5);
      expect(result.masteredTopics, 2);
    });

    test('returns null when getMasterySnapshot fails', () async {
      final masteryService = _FakeMasteryGraphService(failSnapshot: true);
      final container = _createContainer(masteryService: masteryService);
      addTearDown(container.dispose);

      final result = await container.read(dashboardMasterySnapshotProvider('s1').future);
      expect(result, isNull);
    });
  });

  group('dashboardOverallStatsProvider', () {
    test('returns OverallStats from tracker', () async {
      final tracker = _FakeProgressTracker(
        overallStats: {
          'totalAttempts': 100,
          'correctAttempts': 75,
          'accuracy': 75,
          'avgTimePerQuestion': 30,
          'totalStudyTimeHours': '12.5',
          'weeklyActivity': 5,
          'dailyActivity': 1,
          'topicsStudied': 8,
        },
      );
      final container = _createContainer(tracker: tracker);
      addTearDown(container.dispose);

      final result = await container.read(dashboardOverallStatsProvider('s1').future);
      expect(result!.totalAttempts, 100);
      expect(result.accuracy, 75);
      expect(result.topicsStudied, 8);
    });
  });

  group('dashboardWeeklyTrendProvider', () {
    test('returns list of WeeklyTrendEntry from tracker', () async {
      final tracker = _FakeProgressTracker(
        weeklyTrend: [
          {'week': 1, 'month': 1, 'attempts': 10, 'accuracy': 80, 'improvement': 0.1},
          {'week': 2, 'month': 1, 'attempts': 15, 'accuracy': 85, 'improvement': 0.05},
        ],
      );
      final container = _createContainer(tracker: tracker);
      addTearDown(container.dispose);

      final result = await container.read(dashboardWeeklyTrendProvider('s1').future);
      expect(result.length, 2);
      expect(result[0].week, 1);
      expect(result[1].accuracy, 85);
    });
  });

  group('dashboardFocusStatsProvider', () {
    test('returns null when no sessions today', () async {
      final sessionRepo = _FakeSessionRepo(sessions: []);
      final container = _createContainer(sessionRepo: sessionRepo);
      addTearDown(container.dispose);

      final result = await container.read(dashboardFocusStatsProvider('s1').future);
      expect(result, isNull);
    });

    test('returns null when no focus sessions today', () async {
      final now = DateTime.now();
      final sessionRepo = _FakeSessionRepo(sessions: [
        Session(
          id: 's1',
          studentId: 's1',
          type: SessionType.practice,
          startTime: now,
          actualDurationMs: 1800000,
          completed: true,
        ),
      ]);
      final container = _createContainer(sessionRepo: sessionRepo);
      addTearDown(container.dispose);

      final result = await container.read(dashboardFocusStatsProvider('s1').future);
      expect(result, isNull);
    });

    test('returns FocusTodayStats when focus sessions exist', () async {
      final now = DateTime.now();
      final sessionRepo = _FakeSessionRepo(sessions: [
        Session(
          id: 's1',
          studentId: 's1',
          type: SessionType.focus,
          startTime: now,
          actualDurationMs: 1800000,
          completed: true,
          plannedDurationMinutes: 30,
        ),
        Session(
          id: 's2',
          studentId: 's1',
          type: SessionType.focus,
          startTime: now,
          actualDurationMs: 900000,
          completed: false,
          plannedDurationMinutes: 15,
        ),
      ]);
      final container = _createContainer(sessionRepo: sessionRepo);
      addTearDown(container.dispose);

      final result = await container.read(dashboardFocusStatsProvider('s1').future);
      expect(result, isA<FocusTodayStats>());
      expect(result!.completedSessions, 1);
      expect(result.totalSessions, 2);
      expect(result.plannedMinutes, 45);
    });

    test('handles session repository error gracefully', () async {
      final sessionRepo = _FakeSessionRepo(throwOnGetByDate: true);
      final container = _createContainer(sessionRepo: sessionRepo);
      addTearDown(container.dispose);

      final result = await container.read(dashboardFocusStatsProvider('s1').future);
      expect(result, isNull);
    });

    test('computes totalMs and totalSeconds correctly', () async {
      final now = DateTime.now();
      final sessionRepo = _FakeSessionRepo(sessions: [
        Session(
          id: 's1',
          studentId: 's1',
          type: SessionType.focus,
          startTime: now,
          actualDurationMs: 3600000,
          completed: true,
          plannedDurationMinutes: 60,
        ),
      ]);
      final container = _createContainer(sessionRepo: sessionRepo);
      addTearDown(container.dispose);

      final result = await container.read(dashboardFocusStatsProvider('s1').future);
      expect(result!.totalSeconds, 3600);
      expect(result.totalSessions, 1);
      expect(result.completedSessions, 1);
      expect(result.plannedMinutes, 60);
    });
  });

  group('dashboardInitProvider', () {
    test('enters error state when a service init fails', () async {
      final masteryService = _FakeMasteryGraphService(failInit: true);
      final container = _createContainer(masteryService: masteryService);
      addTearDown(container.dispose);

      await expectLater(
        container.read(dashboardInitProvider.future),
        throwsA(isA<Exception>()),
      );
      expect(container.read(dashboardInitProvider).hasError, isTrue);
    });
  });

  group('dashboardWeeklyTrendProvider', () {
    test('returns empty list when no weekly trend data', () async {
      final tracker = _FakeProgressTracker(weeklyTrend: []);
      final container = _createContainer(tracker: tracker);
      addTearDown(container.dispose);

      final result = await container.read(dashboardWeeklyTrendProvider('s1').future);
      expect(result, isEmpty);
    });
  });

  group('dashboardOverallStatsProvider', () {
    test('returns OverallStats with default values when stats are empty', () async {
      final tracker = _FakeProgressTracker(
        overallStats: {
          'totalAttempts': 0,
          'correctAttempts': 0,
          'accuracy': 0,
          'avgTimePerQuestion': 0,
          'totalStudyTimeHours': '0',
          'weeklyActivity': 0,
          'dailyActivity': 0,
          'topicsStudied': 0,
        },
      );
      final container = _createContainer(tracker: tracker);
      addTearDown(container.dispose);

      final result = await container.read(dashboardOverallStatsProvider('s1').future);
      expect(result!.totalAttempts, 0);
      expect(result.accuracy, 0);
      expect(result.topicsStudied, 0);
      expect(result.isEmpty, isTrue);
    });

    test('returns OverallStats with partial stats map', () async {
      final tracker = _FakeProgressTracker(
        overallStats: {
          'totalAttempts': 10,
        },
      );
      final container = _createContainer(tracker: tracker);
      addTearDown(container.dispose);

      final result = await container.read(dashboardOverallStatsProvider('s1').future);
      expect(result!.totalAttempts, 10);
      expect(result.correctAttempts, 0);
      expect(result.accuracy, 0);
      expect(result.totalStudyTimeHours, 0);
    });
  });

  group('dashboardAdherenceDataProvider', () {
    test('returns AdherenceData with correct values', () async {
      final adherenceRepo = _FakePlanAdherenceRepo(
        avgAdherence: 0.85,
        weeklyRecords: [
          PlanAdherenceModel(
            id: 'w1',
            studentId: 's1',
            date: DateTime.now(),
            adherenceScore: 0.9,
          ),
          PlanAdherenceModel(
            id: 'w2',
            studentId: 's1',
            date: DateTime.now(),
            adherenceScore: 0.8,
          ),
          PlanAdherenceModel(
            id: 'w3',
            studentId: 's1',
            date: DateTime.now(),
            adherenceScore: 0.7,
          ),
        ],
      );
      final container = _createContainer(adherenceRepo: adherenceRepo);
      addTearDown(container.dispose);

      final result = await container.read(dashboardAdherenceDataProvider('s1').future);
      expect(result.averageAdherence, 0.85);
      expect(result.weeklyAdherence, closeTo(0.8, 0.001));
    });

    test('weeklyAdherence is 0 when no weekly records', () async {
      final adherenceRepo = _FakePlanAdherenceRepo(
        avgAdherence: 0.5,
        weeklyRecords: [],
      );
      final container = _createContainer(adherenceRepo: adherenceRepo);
      addTearDown(container.dispose);

      final result = await container.read(dashboardAdherenceDataProvider('s1').future);
      expect(result.averageAdherence, 0.5);
      expect(result.weeklyAdherence, 0.0);
    });
  });

  group('dashboardTopicNamesProvider', () {
    test('builds topic name map from topics and mastery data', () async {
      final now = DateTime.now();
      final masteryService = _FakeMasteryGraphService(
        allMastery: [
          MasteryState(studentId: 's1', topicId: 't1', lastAttempt: now, lastUpdated: now),
          MasteryState(studentId: 's1', topicId: 't2', lastAttempt: now, lastUpdated: now),
          MasteryState(studentId: 's1', topicId: 't3', lastAttempt: now, lastUpdated: now),
        ],
      );
      final topicRepo = _FakeTopicRepo(
        topics: [
          Topic(id: 't1', subjectId: 'sub1', title: 'Topic 1', description: '', syllabusText: ''),
          Topic(id: 't2', subjectId: 'sub1', title: 'Topic 2', description: '', syllabusText: ''),
        ],
      );
      final container = _createContainer(
        masteryService: masteryService,
        topicRepo: topicRepo,
      );
      addTearDown(container.dispose);

      final result = await container.read(dashboardTopicNamesProvider('s1').future);
      expect(result['t1'], 'Topic 1');
      expect(result['t2'], 'Topic 2');
      expect(result['t3'], 't3');
    });

    test('handles empty topics and mastery data', () async {
      final masteryService = _FakeMasteryGraphService(
        allMastery: [],
      );
      final topicRepo = _FakeTopicRepo(topics: []);
      final container = _createContainer(
        masteryService: masteryService,
        topicRepo: topicRepo,
      );
      addTearDown(container.dispose);

      final result = await container.read(dashboardTopicNamesProvider('s1').future);
      expect(result, isEmpty);
    });
  });

  group('dashboardBadgesProvider', () {
    test('returns list of BadgeDisplay on success', () async {
      final tracker = _FakeProgressTracker(
        badges: [
          {'name': 'Badge 1', 'description': 'First badge', 'category': 'achievement'},
          {'name': 'Badge 2', 'description': 'Second badge', 'category': 'general'},
        ],
      );
      final container = _createContainer(tracker: tracker);
      addTearDown(container.dispose);

      final result = await container.read(dashboardBadgesProvider('s1').future);
      expect(result.length, 2);
      expect(result[0].name, 'Badge 1');
      expect(result[0].category, 'achievement');
    });

    test('handles empty badges list', () async {
      final tracker = _FakeProgressTracker(badges: []);
      final container = _createContainer(tracker: tracker);
      addTearDown(container.dispose);

      final result = await container.read(dashboardBadgesProvider('s1').future);
      expect(result, isEmpty);
    });

    test('returns empty list on error from tracker', () async {
      final tracker = _FakeProgressTracker(failGetBadges: true);
      final container = _createContainer(tracker: tracker);
      addTearDown(container.dispose);

      final result = await container.read(dashboardBadgesProvider('s1').future);
      expect(result, isEmpty);
    });

    test('handles badge with null fields gracefully', () async {
      final tracker = _FakeProgressTracker(
        badges: [
          {'name': null, 'description': null},
        ],
      );
      final container = _createContainer(tracker: tracker);
      addTearDown(container.dispose);

      final result = await container.read(dashboardBadgesProvider('s1').future);
      expect(result.length, 1);
      expect(result[0].name, '');
      expect(result[0].description, '');
      expect(result[0].category, 'general');
    });
  });

  group('dashboardDueReviewsProvider', () {
    test('returns DueReviewsData with correct totals', () async {
      final subjects = [
        Subject(id: 'subj-1', name: 'Mathematics', code: 'MATH'),
        Subject(id: 'subj-2', name: 'Physics', code: 'PHY'),
      ];
      final srService = _FakeSpacedRepetitionService({
        'subj-1': 5,
        'subj-2': 3,
      });
      final subjectRepo = _FakeSubjectRepo(subjects: subjects);
      final container = _createContainer(
        srService: srService,
        subjectRepo: subjectRepo,
      );
      addTearDown(container.dispose);

      final result = await container.read(dashboardDueReviewsProvider('s1').future);

      expect(result, isA<DueReviewsData>());
      expect(result!.totalDue, 8);
      expect(result.subjectBreakdown.length, 2);
      expect(result.subjectBreakdown[0].subjectName, 'Mathematics');
      expect(result.subjectBreakdown[0].dueCount, 5);
      expect(result.subjectBreakdown[1].subjectName, 'Physics');
      expect(result.subjectBreakdown[1].dueCount, 3);
    });

    test('returns 0 total when no subjects exist', () async {
      final container = _createContainer(
        srService: _FakeSpacedRepetitionService({}),
        subjectRepo: _FakeSubjectRepo(subjects: []),
      );
      addTearDown(container.dispose);

      final result = await container.read(dashboardDueReviewsProvider('s1').future);

      expect(result, isA<DueReviewsData>());
      expect(result!.totalDue, 0);
      expect(result.subjectBreakdown, isEmpty);
    });

    test('handles service errors gracefully returning null', () async {
      final container = _createContainer(
        srService: _FakeSpacedRepetitionService({}),
        subjectRepo: _FakeSubjectRepo(subjects: []),
      );
      addTearDown(container.dispose);

      final result = await container.read(dashboardDueReviewsProvider('s1').future);
      expect(result, isA<DueReviewsData>());
    });

    test('includes subjects with zero due count', () async {
      final subjects = [
        Subject(id: 'subj-1', name: 'English', code: 'ENG'),
      ];
      final srService = _FakeSpacedRepetitionService({'subj-1': 0});
      final subjectRepo = _FakeSubjectRepo(subjects: subjects);
      final container = _createContainer(
        srService: srService,
        subjectRepo: subjectRepo,
      );
      addTearDown(container.dispose);

      final result = await container.read(dashboardDueReviewsProvider('s1').future);

      expect(result!.totalDue, 0);
      expect(result.subjectBreakdown.length, 1);
      expect(result.subjectBreakdown[0].dueCount, 0);
    });
  });

  group('dashboardWorkloadProvider', () {
    test('returns null when question repo has no questions', () async {
      final now = DateTime.now();
      final masteryService = _FakeMasteryGraphService(
        allMastery: [
          MasteryState(studentId: 's1', topicId: 't1', lastAttempt: now, lastUpdated: now),
        ],
      );
      final topicRepo = _FakeTopicRepo(topics: [
        Topic(id: 't1', subjectId: 'subj1', title: 'Topic 1', description: '', syllabusText: ''),
      ]);
      final questionRepo = _FakeQuestionRepository(questions: []);
      final container = _createContainer(
        masteryService: masteryService,
        topicRepo: topicRepo,
        questionRepo: questionRepo,
      );
      addTearDown(container.dispose);

      final result = await container.read(dashboardWorkloadProvider('s1').future);
      expect(result, isA<SubjectWorkload>());
      expect(result!.totalQuestions, 0);
    });

    test('returns workload with question counts', () async {
      final now = DateTime.now();
      final masteryService = _FakeMasteryGraphService(
        allMastery: [
          MasteryState(studentId: 's1', topicId: 't1', lastAttempt: now, lastUpdated: now),
        ],
      );
      final topicRepo = _FakeTopicRepo(topics: [
        Topic(id: 't1', subjectId: 'subj1', title: 'Topic 1', description: '', syllabusText: ''),
      ]);
      final questionRepo = _FakeQuestionRepository(questions: [
        Question(
          id: 'q1', text: 'Q1', type: QuestionType.singleChoice,
          subjectId: 'subj1', topicId: 't1',
          createdAt: now, updatedAt: now,
        ),
        Question(
          id: 'q2', text: 'Q2', type: QuestionType.singleChoice,
          subjectId: 'subj1', topicId: 't1',
          createdAt: now, updatedAt: now,
        ),
      ]);
      final container = _createContainer(
        masteryService: masteryService,
        topicRepo: topicRepo,
        questionRepo: questionRepo,
      );
      addTearDown(container.dispose);

      final result = await container.read(dashboardWorkloadProvider('s1').future);
      expect(result, isA<SubjectWorkload>());
      expect(result!.totalQuestions, 2);
      expect(result.topicWorkloads.length, 1);
    });

    test('returns null on error', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(dashboardWorkloadProvider('s1').future);
      expect(result, isNull);
    });
  });

  group('dashboardSourceCountProvider', () {
    test('returns 0 when Hive is not initialized (error path)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(dashboardSourceCountProvider('s1').future);
      expect(result, 0);
    });
  });

  group('dashboardSyllabusProgressProvider', () {
    test('returns empty list when plan is null', () async {
      final plannerService = _FakePlannerService(plan: null);
      final container = _createContainer(plannerServiceParam: plannerService);
      addTearDown(container.dispose);

      final result = await container.read(dashboardSyllabusProgressProvider('s1').future);
      expect(result, isEmpty);
    });

    test('returns syllabus goals from plan', () async {
      final plan = PersonalLearningPlan(
        studentId: 's1',
        generatedAt: DateTime.now(),
        dailyPlans: [],
        summary: PlanSummary(totalQuestions: 0, totalMinutes: 0, newTopics: 0, reviewTopics: 0, estimatedCoverage: 0, focusAreas: []),
        recommendations: [],
        metadata: {
          'syllabus_goals': [
            {'subjectId': 'subj1', 'subjectTitle': 'Math'},
            {'subjectId': 'subj2', 'subjectTitle': 'Science'},
          ],
        },
      );
      final plannerService = _FakePlannerService(plan: plan);
      final container = _createContainer(plannerServiceParam: plannerService);
      addTearDown(container.dispose);

      final result = await container.read(dashboardSyllabusProgressProvider('s1').future);
      expect(result.length, 2);
      expect(result[0].subjectId, 'subj1');
      expect(result[0].subjectTitle, 'Math');
      expect(result[1].subjectId, 'subj2');
    });

    test('returns empty list when planner service throws', () async {
      final plannerService = _FakePlannerService(loadExistingPlanThrows: true);
      final container = _createContainer(plannerServiceParam: plannerService);
      addTearDown(container.dispose);

      final result = await container.read(dashboardSyllabusProgressProvider('s1').future);
      expect(result, isEmpty);
    });
  });

  group('dashboardChecklistProgressProvider', () {
    test('returns default ChecklistProgress when Hive is not initialized', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(dashboardChecklistProgressProvider('s1').future);
      expect(result, isA<ChecklistProgress>());
      expect(result.isEmpty, isTrue);
    });
  });
}
