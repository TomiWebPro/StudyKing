import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/mentor/services/mentor_context_builder.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeSessionRepo extends SessionRepository {
  List<Session> _allSessions = [];
  List<Session> _todaySessions = [];
  int _todayDurationMs = 0;

  void setAllSessions(List<Session> sessions) => _allSessions = sessions;
  void setTodaySessions(List<Session> sessions) => _todaySessions = sessions;
  void setTodayDurationMs(int ms) => _todayDurationMs = ms;

  @override
  Future<Result<List<Session>>> getAll() async => Result.success(_allSessions);

  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async => Result.success(_todaySessions);

  @override
  Future<Result<int>> getTodayDurationMs() async => Result.success(_todayDurationMs);
}

class _FakeMasteryGraphService extends MasteryGraphService {
  List<MasteryState> _weakTopics = [];

  void setWeakTopics(List<MasteryState> topics) => _weakTopics = topics;

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async => Result.success(_weakTopics);
}

class _FakePlanAdherenceOrchestrator extends PlanAdherenceOrchestrator {
  AdherenceDeviation? _deviation;

  void setAdherenceDeviation(AdherenceDeviation? d) => _deviation = d;

  @override
  Future<Result<AdherenceDeviation>> checkAdherence(String studentId) async {
    return Result.success(_deviation ?? const AdherenceDeviation());
  }
}

class _FakePlannerService extends PlannerService {
  PersonalLearningPlan? _plan;
  List<RoadmapModel> _roadmaps = [];
  List<PendingActionModel> _pendingActions = [];
  List<Session> _scheduledLessons = [];
  List<Session> _missedLessons = [];

  _FakePlannerService({
    PlanAdherenceOrchestrator? planOrchestrator,
  }) : super(
         fixedStudentId: 'test-student',
         planOrchestrator: planOrchestrator ?? _FakePlanAdherenceOrchestrator(),
       );

  void setPlan(PersonalLearningPlan? plan) => _plan = plan;
  void setRoadmaps(List<RoadmapModel> roadmaps) => _roadmaps = roadmaps;
  void setPendingActions(List<PendingActionModel> actions) => _pendingActions = actions;
  void setScheduledLessons(List<Session> lessons) => _scheduledLessons = lessons;
  void setMissedLessons(List<Session> lessons) => _missedLessons = lessons;

  @override
  Future<Result<PersonalLearningPlan?>> loadExistingPlan() async => Result.success(_plan);

  @override
  Future<Result<List<RoadmapModel>>> loadRoadmaps() async => Result.success(_roadmaps);

  @override
  Future<Result<List<PendingActionModel>>> loadPendingActions() async => Result.success(_pendingActions);

  @override
  Future<Result<List<Session>>> getScheduledLessons() async => Result.success(_scheduledLessons);

  @override
  Future<Result<List<Session>>> getMissedLessons() async => Result.success(_missedLessons);
}

class _FakeProgressTracker extends StudyProgressTracker {
  Map<String, dynamic> _stats = {
    'totalAttempts': 10,
    'correctAttempts': 7,
    'accuracy': 70,
    'avgTimePerQuestion': 30,
    'totalStudyTimeHours': 2.5,
    'weeklyActivity': 5,
    'dailyActivity': 2,
    'topicsStudied': 3,
  };

  _FakeProgressTracker()
      : super(
          attemptRepo: AttemptRepository(),
          l10n: lookupAppLocalizations(const Locale('en')),
        );

  void setStats(Map<String, dynamic> stats) => _stats = stats;

  @override
  Future<Result<Map<String, dynamic>>> getOverallStats(String studentId) async {
    if (_stats.containsKey('throw')) throw Exception('Simulated error');
    return Result.success(_stats);
  }
}

MentorContextBuilder _createBuilder({
  StudyProgressTracker? progressTracker,
  MasteryGraphService? masteryService,
  PlannerService? plannerService,
  SessionRepository? sessionRepository,
  String localeName = 'en',
}) {
  return MentorContextBuilder(
    progressTracker: progressTracker ?? _FakeProgressTracker(),
    masteryService: masteryService ?? _FakeMasteryGraphService(),
    plannerService: plannerService ?? _FakePlannerService(),
    sessionRepository: sessionRepository ?? _FakeSessionRepo(),
    localeName: localeName,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('MentorContextBuilder', () {
    group('buildContextPrompt', () {
      test('includes stats and accuracy in output', () async {
        final builder = _createBuilder();
        final result = await builder.buildContextPrompt();
        expect(result, contains('Total attempts: 10'));
        expect(result, contains('Correct attempts: 7'));
        expect(result, contains('Accuracy: 70'));
        expect(result, contains('Topics studied: 3'));
        expect(result, contains('Weekly activity: 5'));
        expect(result, contains('Total study time: 2.5'));
      });

      test('includes weak topics when present', () async {
        final mastery = _FakeMasteryGraphService();
        mastery.setWeakTopics([
          MasteryState(
            studentId: 'test-student',
            topicId: 'topic_weak',
            accuracy: 0.3,
            lastAttempt: DateTime.now(),
            lastUpdated: DateTime.now(),
          ),
        ]);
        final builder = _createBuilder(masteryService: mastery);
        final result = await builder.buildContextPrompt();
        expect(result, contains('Weak topics'));
        expect(result, contains('topic_weak'));
      });

      test('includes plan info when plan exists', () async {
        final planner = _FakePlannerService(
          planOrchestrator: _FakePlanAdherenceOrchestrator(),
        );
        planner.setPlan(PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: List.generate(7, (i) => DailyPlan(
            date: DateTime.now().add(Duration(days: i)),
            dayNumber: i + 1,
            priorityTopics: [],
            reviewQuestionIds: [],
            stretchGoalQuestionIds: [],
            targetQuestions: 10,
            targetMinutes: 30,
          )),
          summary: PlanSummary(
            totalQuestions: 30,
            totalMinutes: 90,
            newTopics: 2,
            reviewTopics: 1,
            estimatedCoverage: 0.7,
            focusAreas: ['Algebra'],
          ),
          recommendations: [],
          planDurationDays: 7,
        ));

        final builder = _createBuilder(plannerService: planner);
        final result = await builder.buildContextPrompt();
        expect(result, contains('Plan exists'));
        expect(result, contains('day 1 of 7'));
      });

      test('includes upcoming lessons', () async {
        final planner = _FakePlannerService();
        planner.setScheduledLessons([
          Session(
            id: 's1',
            studentId: 'test-student',
            startTime: DateTime.now().add(const Duration(hours: 2)),
            plannedDurationMinutes: 30,
            tutorMetadata: const TutorMetadata(topicTitle: 'Algebra'),
          ),
        ]);

        final builder = _createBuilder(plannerService: planner);
        final result = await builder.buildContextPrompt();
        expect(result, contains('Upcoming'));
        expect(result, contains('Algebra'));
      });

      test('handles empty states gracefully', () async {
        final sessionRepo = _FakeSessionRepo();
        sessionRepo.setAllSessions([]);
        sessionRepo.setTodayDurationMs(0);

        final mastery = _FakeMasteryGraphService();
        mastery.setWeakTopics([]);

        final builder = _createBuilder(
          sessionRepository: sessionRepo,
          masteryService: mastery,
        );
        final result = await builder.buildContextPrompt();
        expect(result, isNotEmpty);
        expect(result, contains('Current student context'));
        expect(result, contains('Total attempts: 10'));
      });

      test('propagates provider errors when tracker throws', () async {
        final failingTracker = _FakeProgressTracker();
        failingTracker.setStats({'throw': true});

        final builder = _createBuilder(progressTracker: failingTracker);
        expect(() => builder.buildContextPrompt(), throwsA(isA<Exception>()));
      });

      test('includes plan adherence when deviation exists', () async {
        final orchestrator = _FakePlanAdherenceOrchestrator();
        orchestrator.setAdherenceDeviation(const AdherenceDeviation(
          consecutiveLowDays: 2,
          averageAdherence: 0.65,
        ));

        final planner = _FakePlannerService(planOrchestrator: orchestrator);
        planner.setPlan(PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [
            DailyPlan(
              date: DateTime.now(),
              dayNumber: 1,
              priorityTopics: [],
              reviewQuestionIds: [],
              stretchGoalQuestionIds: [],
              targetQuestions: 10,
              targetMinutes: 30,
            ),
          ],
          summary: PlanSummary(
            totalQuestions: 30,
            totalMinutes: 90,
            newTopics: 2,
            reviewTopics: 1,
            estimatedCoverage: 0.7,
            focusAreas: ['Math'],
          ),
          recommendations: [],
        ));

        final builder = _createBuilder(plannerService: planner);
        final result = await builder.buildContextPrompt();
        expect(result, contains('Plan adherence'));
      });

      test('includes active roadmaps when present', () async {
        final planner = _FakePlannerService();
        planner.setRoadmaps([
          RoadmapModel(
            id: 'rm-1',
            studentId: 'test-student',
            goal: 'Learn Algebra',
            createdAt: DateTime.now(),
            status: 'active',
            milestones: [
              MilestoneModel(
                id: 'm1',
                title: 'Basics',
                deadline: DateTime.now().add(const Duration(days: 7)),
                isCompleted: true,
              ),
              MilestoneModel(
                id: 'm2',
                title: 'Advanced',
                deadline: DateTime.now().add(const Duration(days: 14)),
                isCompleted: false,
              ),
            ],
          ),
        ]);

        final builder = _createBuilder(plannerService: planner);
        final result = await builder.buildContextPrompt();
        expect(result, contains('Active roadmaps'));
        expect(result, contains('Learn Algebra'));
      });

      test('includes pending actions when present', () async {
        final planner = _FakePlannerService();
        planner.setPendingActions([
          PendingActionModel(
            id: 'pa-1',
            studentId: 'test-student',
            actionType: 'reschedule',
            topicTitle: 'Algebra review',
          ),
        ]);

        final builder = _createBuilder(plannerService: planner);
        final result = await builder.buildContextPrompt();
        expect(result, contains('Pending actions'));
        expect(result, contains('Algebra review'));
      });
    });

    group('missed lessons', () {
      test('includes missed lessons when present', () async {
        final planner = _FakePlannerService();
        planner.setMissedLessons([
          Session(id: 's1', studentId: 'test-student', startTime: DateTime.now().subtract(const Duration(days: 1)), tutorMetadata: const TutorMetadata(topicTitle: 'Algebra')),
          Session(id: 's2', studentId: 'test-student', startTime: DateTime.now().subtract(const Duration(days: 1)), tutorMetadata: const TutorMetadata(topicTitle: 'Geometry')),
        ]);
        final builder = _createBuilder(plannerService: planner);
        final result = await builder.buildContextPrompt();
        expect(result, contains('Missed lessons'));
        expect(result, contains('Algebra'));
        expect(result, contains('Geometry'));
      });

      test('limits missed lessons display to 3', () async {
        final planner = _FakePlannerService();
        planner.setMissedLessons(List.generate(5, (i) => Session(
          id: 's$i', studentId: 'test-student',
          startTime: DateTime.now().subtract(const Duration(days: 1)),
          tutorMetadata: TutorMetadata(topicTitle: 'Topic $i'),
        )));
        final builder = _createBuilder(plannerService: planner);
        final result = await builder.buildContextPrompt();
        expect(result, contains('Missed lessons: 5'));
        expect(result.contains('Topic 3'), isFalse);
      });

      test('uses topicId fallback when tutorMetadata is null', () async {
        final planner = _FakePlannerService();
        planner.setMissedLessons([
          Session(id: 's1', studentId: 'test-student', topicId: 'algebra-101',
            startTime: DateTime.now().subtract(const Duration(days: 1))),
        ]);
        final builder = _createBuilder(plannerService: planner);
        final result = await builder.buildContextPrompt();
        expect(result, contains('algebra-101'));
      });
    });

    group('study time today', () {
      test('includes study time when todayMinutes > 0', () async {
        final sessionRepo = _FakeSessionRepo();
        sessionRepo.setTodayDurationMs(1800000);

        final builder = _createBuilder(sessionRepository: sessionRepo);
        final result = await builder.buildContextPrompt();
        expect(result, contains("Today's study time: 30 minutes"));
      });
    });

    group('streak messages', () {
      test('shows streak congratulations for 7+ consecutive days', () async {
        final sessionRepo = _FakeSessionRepo();
        final now = DateTime.now();
        sessionRepo.setAllSessions(List.generate(7, (i) => Session(
          id: 's$i', studentId: 'test-student',
          startTime: now.subtract(Duration(days: i)),
          completed: true,
        )));
        sessionRepo.setTodayDurationMs(0);

        final builder = _createBuilder(sessionRepository: sessionRepo);
        final result = await builder.buildContextPrompt();
        expect(result, contains('day study streak'));
      });

      test('shows good consistency for 3-6 consecutive days', () async {
        final sessionRepo = _FakeSessionRepo();
        final now = DateTime.now();
        sessionRepo.setAllSessions(List.generate(3, (i) => Session(
          id: 's$i', studentId: 'test-student',
          startTime: now.subtract(Duration(days: i)),
          completed: true,
        )));

        final builder = _createBuilder(sessionRepository: sessionRepo);
        final result = await builder.buildContextPrompt();
        expect(result, contains('consecutive study days'));
      });

      test('does not show streak for fewer than 3 consecutive days', () async {
        final sessionRepo = _FakeSessionRepo();
        sessionRepo.setAllSessions([
          Session(id: 's1', studentId: 'test-student', startTime: DateTime.now(), completed: true),
        ]);

        final builder = _createBuilder(sessionRepository: sessionRepo);
        final result = await builder.buildContextPrompt();
        expect(result, isNot(contains('day study streak')));
        expect(result, isNot(contains('consecutive study days')));
      });
    });

    group('late-night sessions', () {
      test('warns about late-night sessions', () async {
        final sessionRepo = _FakeSessionRepo();
        final now = DateTime.now();
        sessionRepo.setTodaySessions([
          Session(id: 's1', studentId: 'test-student',
            startTime: DateTime(now.year, now.month, now.day, 23, 0)),
        ]);

        final builder = _createBuilder(sessionRepository: sessionRepo);
        final result = await builder.buildContextPrompt();
        expect(result, contains('after 10 PM'));
      });

      test('does not warn for daytime sessions', () async {
        final sessionRepo = _FakeSessionRepo();
        final now = DateTime.now();
        sessionRepo.setTodaySessions([
          Session(id: 's1', studentId: 'test-student',
            startTime: DateTime(now.year, now.month, now.day, 14, 0)),
        ]);

        final builder = _createBuilder(sessionRepository: sessionRepo);
        final result = await builder.buildContextPrompt();
        expect(result, isNot(contains('WARNING')));
      });
    });

    group('sessions today', () {
      test('shows sessions today count when sessions exist', () async {
        final sessionRepo = _FakeSessionRepo();
        final now = DateTime.now();
        sessionRepo.setTodaySessions([
          Session(id: 's1', studentId: 'test-student', startTime: now),
          Session(id: 's2', studentId: 'test-student', startTime: now),
        ]);

        final builder = _createBuilder(sessionRepository: sessionRepo);
        final result = await builder.buildContextPrompt();
        expect(result, contains('Sessions today: 2'));
      });
    });

    group('plan adherence with low consecutive days', () {
      test('shows low adherence warning when consecutiveLowDays > 0', () async {
        final orchestrator = _FakePlanAdherenceOrchestrator();
        orchestrator.setAdherenceDeviation(const AdherenceDeviation(
          consecutiveLowDays: 3,
          averageAdherence: 0.50,
        ));

        final planner = _FakePlannerService(planOrchestrator: orchestrator);
        planner.setPlan(PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [
            DailyPlan(date: DateTime.now(), dayNumber: 5,
              priorityTopics: [], reviewQuestionIds: [], stretchGoalQuestionIds: [],
              targetQuestions: 10, targetMinutes: 30),
          ],
          summary: PlanSummary(totalQuestions: 30, totalMinutes: 90, newTopics: 2,
            reviewTopics: 1, estimatedCoverage: 0.7, focusAreas: ['Math']),
          recommendations: [],
        ));

        final builder = _createBuilder(plannerService: planner);
        final result = await builder.buildContextPrompt();
        expect(result, contains('Low adherence for 3 consecutive days'));
      });
    });

    group('loadUpcomingLessons', () {
      test('delegates to plannerService.getScheduledLessons', () async {
        final planner = _FakePlannerService();
        planner.setScheduledLessons([
          Session(
            id: 's1',
            studentId: 'test-student',
            startTime: DateTime.now().add(const Duration(hours: 2)),
            tutorMetadata: const TutorMetadata(topicTitle: 'Test Topic'),
          ),
        ]);

        final builder = _createBuilder(plannerService: planner);
        final result = await builder.loadUpcomingLessons();
        expect(result.isSuccess, isTrue);
        expect(result.data!.length, equals(1));
        expect(result.data!.first.id, equals('s1'));
      });

      test('returns empty list when no lessons scheduled', () async {
        final planner = _FakePlannerService();
        final builder = _createBuilder(plannerService: planner);
        final result = await builder.loadUpcomingLessons();
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });
  });
}
