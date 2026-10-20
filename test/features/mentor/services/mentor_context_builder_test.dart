import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/core/services/system_monitor_service.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/practice/services/readiness_scorer.dart';
import 'package:studyking/features/mentor/services/mentor_context_builder.dart';
import 'package:studyking/features/mentor/services/syllabus_focus_service.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeSessionRepo extends SessionRepository {
  List<Session> _allSessions = [];
  List<Session> _todaySessions = [];
  int _todayDurationMs = 0;
  Map<String, int> _todayDurationBySubject = {};

  void setAllSessions(List<Session> sessions) => _allSessions = sessions;
  void setTodaySessions(List<Session> sessions) => _todaySessions = sessions;
  void setTodayDurationMs(int ms) => _todayDurationMs = ms;
  void setTodayDurationBySubject(Map<String, int> map) =>
      _todayDurationBySubject = Map<String, int>.from(map);

  @override
  Future<Result<List<Session>>> getAll() async => Result.success(_allSessions);

  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async => Result.success(_todaySessions);

  @override
  Future<Result<int>> getTodayDurationMs() async => Result.success(_todayDurationMs);

  @override
  Future<Result<Map<String, int>>> getTodayDurationBySubject() async =>
      Result.success(Map<String, int>.from(_todayDurationBySubject));
}

class _FakeMasteryGraphService extends MasteryGraphService {
  List<MasteryState> _weakTopics = [];
  List<QuestionMasteryState> _atRiskQuestions = [];
  bool _atRiskFailure = false;

  void setWeakTopics(List<MasteryState> topics) => _weakTopics = topics;
  void setAtRiskQuestions(List<QuestionMasteryState> qs) => _atRiskQuestions = qs;
  void setAtRiskFailure(bool v) => _atRiskFailure = v;

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId, {String? subjectId}) async => Result.success(_weakTopics);

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(String studentId, {double threshold = 0.5}) async {
    if (_atRiskFailure) return Result.failure('simulated getAtRiskQuestions failure');
    return Result.success(_atRiskQuestions);
  }
}

class _FakePlanAdherenceOrchestrator extends PlanAdherenceOrchestrator {
  AdherenceDeviation? _deviation;

  void setAdherenceDeviation(AdherenceDeviation? d) => _deviation = d;

  @override
  Future<Result<AdherenceDeviation>> checkAdherence(String studentId) async {
    return Result.success(_deviation ?? const AdherenceDeviation());
  }
}

class _FakeSourceRepo extends SourceRepository {
  List<Source> _sources = [];
  bool _throwOnGetByStudent = false;

  void setSources(List<Source> sources) => _sources = sources;
  void setThrowOnGetByStudent(bool v) => _throwOnGetByStudent = v;

  @override
  Future<Result<List<Source>>> getByStudent(String studentId) async {
    if (_throwOnGetByStudent) throw Exception('Simulated source read failure');
    return Result.success(_sources);
  }
}

/// Hand-written fake [QuestionRepository] for deterministic testing of the
/// per-question mistake context injection (no Hive I/O).
class _FakeQuestionRepository extends QuestionRepository {
  final Map<String, Question> _questions = {};

  void setQuestions(Map<String, Question> qs) => _questions
    ..clear()
    ..addAll(qs);

  @override
  Future<Result<Question?>> get(String key) async => Result.success(_questions[key]);
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

/// Hand-written fake [SystemMonitorService] for deterministic testing of the
/// device-status context injection (Vision Next-Term §4.3).
class _FakeSystemMonitor extends SystemMonitorService {
  @override
  final bool canRunHeavyPrepNow;
  @override
  final int batteryLevel;
  @override
  final bool isCharging;
  @override
  final double cpuLoad;
  @override
  final bool isBatterySaver;
  @override
  final String? networkType;

  const _FakeSystemMonitor({
    this.canRunHeavyPrepNow = true,
    this.batteryLevel = -1,
    this.isCharging = false,
    this.cpuLoad = -1,
    this.isBatterySaver = false,
    this.networkType,
  });
}

MentorContextBuilder _createBuilder({
  StudyProgressTracker? progressTracker,
  MasteryGraphService? masteryService,
  PlannerService? plannerService,
  SessionRepository? sessionRepository,
  SourceRepository? sourceRepository,
  QuestionRepository? questionRepository,
  String localeName = 'en',
  SystemMonitorService? systemMonitor,
  SyllabusFocusService? focusService,
  LlmConfiguration? llmConfig,
  ReadinessScorer? readinessScorer,
}) {
  return MentorContextBuilder(
    progressTracker: progressTracker ?? _FakeProgressTracker(),
    masteryService: masteryService ?? _FakeMasteryGraphService(),
    plannerService: plannerService ?? _FakePlannerService(),
    sessionRepository: sessionRepository ?? _FakeSessionRepo(),
    sourceRepository: sourceRepository,
    questionRepository: questionRepository,
    localeName: localeName,
    systemMonitor: systemMonitor,
    focusService: focusService,
    llmConfig: llmConfig,
    readinessScorer: readinessScorer,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('MentorContextBuilder', () {
    PersonalLearningPlan planWithGoals(List<Map<String, dynamic>> goals) =>
        PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [],
          summary: PlanSummary(
            totalQuestions: 0,
            totalMinutes: 0,
            newTopics: 0,
            reviewTopics: 0,
            estimatedCoverage: 0,
            focusAreas: [],
          ),
          recommendations: [],
          metadata: {'syllabus_goals': goals},
        );

    group('buildContextPrompt', () {
      test('includes stats and accuracy in output', () async {
        final builder = _createBuilder();
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Total attempts: 10'));
        expect(result.data, contains('Correct attempts: 7'));
        expect(result.data, contains('Accuracy: 70'));
        expect(result.data, contains('Topics studied: 3'));
        expect(result.data, contains('Weekly activity: 5'));
        expect(result.data, contains('Total study time: 2.5'));
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
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Weak topics'));
        expect(result.data, contains('topic_weak'));
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
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Plan exists'));
        expect(result.data, contains('day 1 of 7'));
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
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Upcoming'));
        expect(result.data, contains('Algebra'));
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
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotEmpty);
        expect(result.data, contains('Current student context'));
        expect(result.data, contains('Total attempts: 10'));
      });

      test('returns failure Result when tracker throws', () async {
        final failingTracker = _FakeProgressTracker();
        failingTracker.setStats({'throw': true});

        final builder = _createBuilder(progressTracker: failingTracker);
        final result = await builder.buildContextPrompt();
        expect(result.isFailure, isTrue);
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
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Plan adherence'));
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
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Active roadmaps'));
        expect(result.data, contains('Learn Algebra'));
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
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Pending actions'));
        expect(result.data, contains('Algebra review'));
      });

      test('injects missing-materials directive when no sources uploaded', () async {
        final sourceRepo = _FakeSourceRepo();
        sourceRepo.setSources([]);

        final builder = _createBuilder(sourceRepository: sourceRepo);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('no uploaded study materials'));
      });

      test('does not inject missing-materials directive when sources exist', () async {
        final sourceRepo = _FakeSourceRepo();
        sourceRepo.setSources([
          Source(
            id: 'src-1',
            title: 'IB Chemistry Syllabus',
            type: SourceType.syllabus,
            studentId: 'test-student',
          ),
        ]);

        final builder = _createBuilder(sourceRepository: sourceRepo);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, isNot(contains('no uploaded study materials')));
      });

      test('does not inject directive when sourceRepository is null', () async {
        final builder = _createBuilder(sourceRepository: null);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, isNot(contains('no uploaded study materials')));
      });
    });

    group('source inventory', () {
      test('includes per-syllabus source titles when sources exist', () async {
        final planner = _FakePlannerService();
        planner.setPlan(planWithGoals([
          {'subjectId': 'math-1', 'subjectTitle': 'Math'},
          {'subjectId': 'sci-1', 'subjectTitle': 'Science'},
        ]));
        final sourceRepo = _FakeSourceRepo();
        sourceRepo.setSources([
          Source(id: 's1', title: 'Bonding Notes', type: SourceType.syllabus, studentId: 'test-student', subjectId: 'math-1'),
          Source(id: 's2', title: 'Equations.pdf', type: SourceType.pdf, studentId: 'test-student', subjectId: 'math-1'),
          Source(id: 's3', title: 'Lab Handbook', type: SourceType.pdf, studentId: 'test-student', subjectId: 'sci-1'),
        ]);

        final builder = _createBuilder(plannerService: planner, sourceRepository: sourceRepo);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Uploaded study materials (3)'));
        expect(result.data, contains('Math: 2'));
        expect(result.data, contains('Bonding Notes'));
        expect(result.data, contains('Equations.pdf'));
        expect(result.data, contains('Science: 1'));
        expect(result.data, contains('Lab Handbook'));
        expect(result.data, isNot(contains('no uploaded study materials')));
      });

      test('caps titles per subject with an overflow count', () async {
        final planner = _FakePlannerService();
        planner.setPlan(planWithGoals([
          {'subjectId': 'math-1', 'subjectTitle': 'Math'},
        ]));
        final sourceRepo = _FakeSourceRepo();
        sourceRepo.setSources(List.generate(5, (i) => Source(
          id: 's$i', title: 'Topic Source $i', type: SourceType.pdf,
          studentId: 'test-student', subjectId: 'math-1',
        )));

        final builder = _createBuilder(plannerService: planner, sourceRepository: sourceRepo);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Math: 5'));
        expect(result.data, contains('+2 more'));
        expect(result.data, contains('Topic Source 0'));
        expect(result.data, contains('Topic Source 2'));
        // Titles beyond the per-subject cap are folded into the overflow count.
        expect(result.data!.contains('Topic Source 3'), isFalse);
        expect(result.data!.contains('Topic Source 4'), isFalse);
      });

      test('surfaces unattributed materials when subjectId is empty', () async {
        final sourceRepo = _FakeSourceRepo();
        sourceRepo.setSources([
          Source(id: 's1', title: 'Misc Notes', type: SourceType.document, studentId: 'test-student'),
        ]);

        final builder = _createBuilder(sourceRepository: sourceRepo);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Uploaded study materials (1)'));
        expect(result.data, contains('Unattributed materials: 1'));
        expect(result.data, isNot(contains('no uploaded study materials')));
      });

      test('falls back to subjectId when no syllabus goal matches', () async {
        final planner = _FakePlannerService();
        planner.setPlan(planWithGoals([
          {'subjectId': 'math-1', 'subjectTitle': 'Math'},
        ]));
        final sourceRepo = _FakeSourceRepo();
        sourceRepo.setSources([
          Source(id: 's1', title: 'Unknown Source', type: SourceType.pdf, studentId: 'test-student', subjectId: 'orph-1'),
        ]);

        final builder = _createBuilder(plannerService: planner, sourceRepository: sourceRepo);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('orph-1: 1'));
        expect(result.data, contains('Unknown Source'));
      });

      test('updates inventory when more sources are added', () async {
        final planner = _FakePlannerService();
        planner.setPlan(planWithGoals([
          {'subjectId': 'math-1', 'subjectTitle': 'Math'},
        ]));
        final sourceRepo = _FakeSourceRepo();
        sourceRepo.setSources([
          Source(id: 's1', title: 'First Note', type: SourceType.document, studentId: 'test-student', subjectId: 'math-1'),
        ]);

        final builder = _createBuilder(plannerService: planner, sourceRepository: sourceRepo);
        var result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('First Note'));
        expect(result.data, contains('Math: 1'));

        // Simulate off-period ingestion adding a second source to the same syllabus.
        sourceRepo.setSources([
          Source(id: 's1', title: 'First Note', type: SourceType.document, studentId: 'test-student', subjectId: 'math-1'),
          Source(id: 's2', title: 'Second Note', type: SourceType.document, studentId: 'test-student', subjectId: 'math-1'),
        ]);
        result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Second Note'));
        expect(result.data, contains('Math: 2'));
      });

       test('injects classification confidence summary when sources have topicConfidence', () async {
        final planner = _FakePlannerService();
        planner.setPlan(planWithGoals([
          {'subjectId': 'math-1', 'subjectTitle': 'Math'},
        ]));
        final sourceRepo = _FakeSourceRepo();
        sourceRepo.setSources([
          Source(
            id: 's1',
            title: 'Algebra Notes',
            type: SourceType.pdf,
            studentId: 'test-student',
            subjectId: 'math-1',
            topicId: 'topic-1',
            topicConfidence: '0.85',
          ),
          Source(
            id: 's2',
            title: 'Geometry Guide',
            type: SourceType.pdf,
            studentId: 'test-student',
            subjectId: 'math-1',
            topicId: 'topic-2',
            topicConfidence: '0.70',
          ),
        ]);

        final builder = _createBuilder(plannerService: planner, sourceRepository: sourceRepo);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Source-topic classification confidence'));
        expect(result.data, contains('2 sources classified'));
        expect(result.data, contains('avg 77%'));
      });

       test('omits confidence summary when no sources have topicConfidence', () async {
        final sourceRepo = _FakeSourceRepo();
        sourceRepo.setSources([
          Source(
            id: 's1',
            title: 'Untopiced Note',
            type: SourceType.pdf,
            studentId: 'test-student',
          ),
        ]);

        final builder = _createBuilder(sourceRepository: sourceRepo);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, isNot(contains('Source-topic classification confidence')));
      });
    });

    group('source content excerpts', () {
      test('injects relevant chunk excerpts from active syllabus topics',
          () async {
        final planner = _FakePlannerService();
        planner.setPlan(planWithGoals([
          {'subjectId': 'chem-1', 'subjectTitle': 'Organic Chemistry'},
        ]));
        planner.setScheduledLessons([
          Session(
            id: 's1',
            studentId: 'test-student',
            subjectId: 'chem-1',
            startTime: DateTime.now().add(const Duration(hours: 2)),
            tutorMetadata: const TutorMetadata(topicTitle: 'Aldol Condensation'),
          ),
        ]);

        final sourceRepo = _FakeSourceRepo();
        final chunksJson = jsonEncode([
          {
            'chunkIndex': 0,
            'pageStart': 102,
            'pageEnd': 105,
            'text': 'Aldol condensation is a carbon-carbon bond-forming reaction between enolates and carbonyl compounds.',
            'heading': 'Aldol Condensation',
          },
          {
            'chunkIndex': 1,
            'pageStart': 200,
            'pageEnd': 203,
            'text': 'SN2 reactions proceed through a backside attack mechanism.',
            'heading': 'SN2',
          },
        ]);
        sourceRepo.setSources([
          Source(
            id: 'chem-textbook',
            title: 'Organic Chemistry Textbook',
            type: SourceType.pdf,
            studentId: 'test-student',
            subjectId: 'chem-1',
            chunks: chunksJson,
          ),
        ]);

        final builder = _createBuilder(
          plannerService: planner,
          sourceRepository: sourceRepo,
        );
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        // The search for 'Aldol Condensation' should match chunk 0.
        expect(result.data, contains('Relevant source excerpts'));
        expect(result.data, contains('Organic Chemistry Textbook'));
        expect(result.data, contains('Aldol Condensation'));
        expect(result.data, contains('p.102-105'));
        expect(result.data, contains('Aldol condensation is a carbon-carbon'));
      });

      test('also searches by syllabus subject title when no upcoming lessons',
          () async {
        final planner = _FakePlannerService();
        planner.setPlan(planWithGoals([
          {'subjectId': 'chem-1', 'subjectTitle': 'Organic Chemistry'},
        ]));

        final sourceRepo = _FakeSourceRepo();
        sourceRepo.setSources([
          Source(
            id: 'chem-textbook',
            title: 'Organic Chemistry Textbook',
            type: SourceType.pdf,
            studentId: 'test-student',
            subjectId: 'chem-1',
            chunks: jsonEncode([
              {
                'chunkIndex': 0,
                'pageStart': 10,
                'pageEnd': 12,
                'text': 'Organic Chemistry covers aldehydes and ketones.',
                'heading': 'Intro',
              },
            ]),
          ),
        ]);

        final builder = _createBuilder(
          plannerService: planner,
          sourceRepository: sourceRepo,
        );
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Relevant source excerpts'));
        expect(result.data, contains('Organic Chemistry covers aldehydes'));
      });

      test('omits excerpts block when no matching content found', () async {
        final planner = _FakePlannerService();
        planner.setPlan(planWithGoals([
          {'subjectId': 'chem-1', 'subjectTitle': 'Organic Chemistry'},
        ]));
        planner.setScheduledLessons([
          Session(
            id: 's1',
            studentId: 'test-student',
            subjectId: 'chem-1',
            startTime: DateTime.now().add(const Duration(hours: 2)),
            tutorMetadata: const TutorMetadata(topicTitle: 'Aldol Condensation'),
          ),
        ]);

        final sourceRepo = _FakeSourceRepo();
        sourceRepo.setSources([
          Source(
            id: 'chem-textbook',
            title: 'Organic Chemistry Textbook',
            type: SourceType.pdf,
            studentId: 'test-student',
            subjectId: 'chem-1',
            chunks: jsonEncode([
              {'chunkIndex': 0, 'text': 'SN2 reactions proceed through backside attack.'},
            ]),
          ),
        ]);

        final builder = _createBuilder(
          plannerService: planner,
          sourceRepository: sourceRepo,
        );
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, isNot(contains('Relevant source excerpts')));
      });

      test('omits excerpts block when sourceRepository is null', () async {
        final planner = _FakePlannerService();
        planner.setPlan(planWithGoals([
          {'subjectId': 'chem-1', 'subjectTitle': 'Organic Chemistry'},
        ]));

        final builder = _createBuilder(
          plannerService: planner,
          sourceRepository: null,
        );
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, isNot(contains('Relevant source excerpts')));
      });

      test('caps the number of injected excerpts at 3', () async {
        final planner = _FakePlannerService();
        planner.setPlan(planWithGoals([
          {'subjectId': 'chem-1', 'subjectTitle': 'Organic Chemistry'},
        ]));
        planner.setScheduledLessons([
          Session(
            id: 's1',
            studentId: 'test-student',
            subjectId: 'chem-1',
            startTime: DateTime.now().add(const Duration(hours: 2)),
            tutorMetadata: const TutorMetadata(topicTitle: 'Aldol'),
          ),
        ]);

        final sourceRepo = _FakeSourceRepo();
        // 5 chunks all matching 'aldol' → only 3 injected.
        sourceRepo.setSources([
          Source(
            id: 's1',
            title: 'Source 1',
            type: SourceType.pdf,
            studentId: 'test-student',
            subjectId: 'chem-1',
            chunks: jsonEncode(List.generate(5, (i) => {
                  'chunkIndex': i,
                  'pageStart': i + 1,
                  'pageEnd': i + 1,
                  'text': 'Aldol condensation discussion $i',
                })),
          ),
        ]);

        final builder = _createBuilder(
          plannerService: planner,
          sourceRepository: sourceRepo,
        );
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        // Only 3 excerpts should appear; the 4th and 5th should be omitted.
        expect(result.data, contains('Aldol condensation discussion 0'));
        expect(result.data, contains('Aldol condensation discussion 2'));
        expect(result.data, isNot(contains('Aldol condensation discussion 3')));
        expect(result.data, isNot(contains('Aldol condensation discussion 4')));
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
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Missed lessons'));
        expect(result.data, contains('Algebra'));
        expect(result.data, contains('Geometry'));
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
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Missed lessons: 5'));
        expect(result.data!.contains('Topic 3'), isFalse);
      });

      test('uses topicId fallback when tutorMetadata is null', () async {
        final planner = _FakePlannerService();
        planner.setMissedLessons([
          Session(id: 's1', studentId: 'test-student', topicId: 'algebra-101',
            startTime: DateTime.now().subtract(const Duration(days: 1))),
        ]);
        final builder = _createBuilder(plannerService: planner);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('algebra-101'));
      });
    });

    group('study time today', () {
      test('includes study time when todayMinutes > 0', () async {
        final sessionRepo = _FakeSessionRepo();
        sessionRepo.setTodayDurationMs(1800000);

        final builder = _createBuilder(sessionRepository: sessionRepo);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains("Today's study time: 30 minutes"));
      });
    });

    group('per-subject study time today', () {
      test('includes per-subject breakdown when sessions span multiple subjects',
          () async {
        final sessionRepo = _FakeSessionRepo();
        // Global total is 90 min (set for the existing global block); per-subject
        // breakdown shows the split across syllabi.
        sessionRepo.setTodayDurationMs(5400000);
        sessionRepo.setTodayDurationBySubject({
          'subj1': 3600000, // 60 min
          'subj2': 1800000, // 30 min
        });

        final planner = _FakePlannerService();
        planner.setPlan(PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [],
          summary: PlanSummary(
            totalQuestions: 0,
            totalMinutes: 0,
            newTopics: 0,
            reviewTopics: 0,
            estimatedCoverage: 0,
            focusAreas: [],
          ),
          recommendations: [],
          metadata: {
            'syllabus_goals': [
              {'subjectId': 'subj1', 'subjectTitle': 'Math'},
              {'subjectId': 'subj2', 'subjectTitle': 'Science'},
            ],
          },
        ));

        final builder = _createBuilder(
          plannerService: planner,
          sessionRepository: sessionRepo,
        );
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Per-subject study time today'));
        expect(result.data, contains('Math: 60 minutes'));
        expect(result.data, contains('Science: 30 minutes'));
        // Math (60 min) should appear before Science (30 min) — sorted desc.
        expect(
          result.data!.indexOf('Math: 60 minutes'),
          lessThan(result.data!.indexOf('Science: 30 minutes')),
        );
      });

      test('falls back to subjectId when no syllabus goal matches', () async {
        final sessionRepo = _FakeSessionRepo();
        sessionRepo.setTodayDurationMs(1800000);
        sessionRepo.setTodayDurationBySubject({
          'unknown-subj': 1800000, // 30 min
        });

        final builder = _createBuilder(sessionRepository: sessionRepo);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Per-subject study time today'));
        expect(result.data, contains('unknown-subj: 30 minutes'));
      });

      test('omits per-subject block when no subjects have study time', () async {
        final sessionRepo = _FakeSessionRepo();
        sessionRepo.setTodayDurationMs(0);
        sessionRepo.setTodayDurationBySubject({});

        final builder = _createBuilder(sessionRepository: sessionRepo);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, isNot(contains('Per-subject study time today')));
      });
    });

    group('streak messages', () {
      test('shows streak congratulations for 7+ consecutive days when studied today', () async {
        final sessionRepo = _FakeSessionRepo();
        final now = DateTime.now();
        sessionRepo.setAllSessions(List.generate(7, (i) => Session(
          id: 's$i', studentId: 'test-student',
          startTime: now.subtract(Duration(days: i)),
          completed: true,
        )));
        // Student studied today — streak is safe, show milestone message
        sessionRepo.setTodayDurationMs(1800000); // 30 min

        final builder = _createBuilder(sessionRepository: sessionRepo);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('day study streak'));
        // No at-risk warning when student has studied today
        expect(result.data, isNot(contains('streak is at risk')));
      });

      test('shows good consistency for 3-6 consecutive days when studied today', () async {
        final sessionRepo = _FakeSessionRepo();
        final now = DateTime.now();
        sessionRepo.setAllSessions(List.generate(3, (i) => Session(
          id: 's$i', studentId: 'test-student',
          startTime: now.subtract(Duration(days: i)),
          completed: true,
        )));
        // Student studied today — streak is safe
        sessionRepo.setTodayDurationMs(1800000); // 30 min

        final builder = _createBuilder(sessionRepository: sessionRepo);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('consecutive study days'));
      });

      test('does not show streak milestone for fewer than 3 consecutive days when studied today', () async {
        final sessionRepo = _FakeSessionRepo();
        sessionRepo.setAllSessions([
          Session(id: 's1', studentId: 'test-student', startTime: DateTime.now(), completed: true),
        ]);
        // Student studied today — no at-risk, no milestone (only 1 day)
        sessionRepo.setTodayDurationMs(1800000);

        final builder = _createBuilder(sessionRepository: sessionRepo);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, isNot(contains('day study streak')));
        expect(result.data, isNot(contains('consecutive study days')));
        expect(result.data, isNot(contains('streak is at risk')));
      });

      test('shows streak-at-risk warning when streak exists but no study session today', () async {
        // Reproduces scenario_overworked_student.md Step 2 (PARTIAL → now
        // addressed): streak tracking now injects an at-risk directive into
        // the mentor context when the student has a streak but hasn't studied
        // today, enabling proactive nudge guidance.
        final sessionRepo = _FakeSessionRepo();
        final now = DateTime.now();
        sessionRepo.setAllSessions(List.generate(5, (i) => Session(
          id: 's$i', studentId: 'test-student',
          startTime: now.subtract(Duration(days: i)),
          completed: true,
        )));
        // No study session today — streak is at risk
        sessionRepo.setTodayDurationMs(0);

        final builder = _createBuilder(sessionRepository: sessionRepo);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('streak is at risk'));
        expect(result.data, contains('5'));
        // Should NOT show the positive streak message (milestone) since
        // the student hasn't studied today
        expect(result.data, isNot(contains('good consistency')));
        expect(result.data, isNot(contains('day study streak')));
      });

      test('does not show streak-at-risk when streak exists and student studied today', () async {
        final sessionRepo = _FakeSessionRepo();
        final now = DateTime.now();
        sessionRepo.setAllSessions(List.generate(2, (i) => Session(
          id: 's$i', studentId: 'test-student',
          startTime: now.subtract(Duration(days: i)),
          completed: true,
        )));
        // Student studied today — streak is safe
        sessionRepo.setTodayDurationMs(1200000); // 20 min

        final builder = _createBuilder(sessionRepository: sessionRepo);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        // No at-risk warning
        expect(result.data, isNot(contains('streak is at risk')));
      });

      test('does not show streak-at-risk when no streak exists', () async {
        final sessionRepo = _FakeSessionRepo();
        sessionRepo.setAllSessions([]);
        sessionRepo.setTodayDurationMs(0);

        final builder = _createBuilder(sessionRepository: sessionRepo);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, isNot(contains('streak is at risk')));
      });
    });

    group('device status', () {
      test('includes a device-status line when a system monitor is provided', () async {
        final monitor = _FakeSystemMonitor(
          canRunHeavyPrepNow: false,
          batteryLevel: 15,
          isCharging: false,
          cpuLoad: 0.85,
          isBatterySaver: true,
          networkType: 'cellular',
        );
        final builder = _createBuilder(systemMonitor: monitor);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Device status'));
        expect(result.data, contains('battery 15%'));
        expect(result.data, contains('CPU 85%'));
        expect(result.data, contains('battery-saver on'));
        expect(result.data, contains('cellular'));
        expect(result.data, contains('heavy prep deferred'));
      });

      test('reports heavy prep available when the system is healthy', () async {
        final monitor = _FakeSystemMonitor(
          canRunHeavyPrepNow: true,
          batteryLevel: 80,
          isCharging: true,
          cpuLoad: 0.3,
          networkType: 'wifi',
        );
        final builder = _createBuilder(systemMonitor: monitor);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Device status'));
        expect(result.data, contains('plugged in'));
        expect(result.data, contains('heavy prep available'));
        expect(result.data, isNot(contains('heavy prep deferred')));
      });

      test('omits the device-status line when no system monitor is available', () async {
        final builder = _createBuilder(); // systemMonitor defaults to null
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, isNot(contains('Device status')));
      });
    });

    group('LLM provider status', () {
      test('injects active provider and backup when configured', () async {
        final config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'sk-test',
          backupProvider: LlmProvider.ollama,
          backupApiKey: 'sk-backup',
        );
        final builder = _createBuilder(llmConfig: config);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('LLM provider: OpenRouter'));
        expect(result.data, contains('Backup: Ollama configured'));
      });

      test('reports no backup when hasBackup is false', () async {
        final config = LlmConfiguration(
          provider: LlmProvider.openAI,
          apiKey: 'sk-test',
        );
        final builder = _createBuilder(llmConfig: config);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('LLM provider: OpenAI'));
        expect(result.data, contains('Backup: not configured'));
      });

      test('omits provider status when llmConfig is null', () async {
        final builder = _createBuilder(); // llmConfig defaults to null
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, isNot(contains('LLM provider:')));
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
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('after 10 PM'));
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
        expect(result.isSuccess, isTrue);
        expect(result.data, isNot(contains('WARNING')));
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
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Sessions today: 2'));
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
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Low adherence for 3 consecutive days'));
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

    group('syllabus context', () {
      PersonalLearningPlan planWithGoals() => PersonalLearningPlan(
            studentId: 'test-student',
            generatedAt: DateTime.now(),
            dailyPlans: [],
            summary: PlanSummary(
              totalQuestions: 0,
              totalMinutes: 0,
              newTopics: 0,
              reviewTopics: 0,
              estimatedCoverage: 0,
              focusAreas: [],
            ),
            recommendations: [],
            metadata: {
              'syllabus_goals': [
                {'subjectId': 'subj1', 'subjectTitle': 'Math'},
                {'subjectId': 'subj2', 'subjectTitle': 'Science'},
              ],
            },
          );

      test('loadSyllabusGoals returns goals from the plan', () async {
        final planner = _FakePlannerService();
        planner.setPlan(planWithGoals());
        final builder = _createBuilder(plannerService: planner);
        final result = await builder.loadSyllabusGoals();
        expect(result.isSuccess, isTrue);
        expect(result.data!.length, 2);
        expect(result.data!.first.subjectTitle, 'Math');
      });

      test('includes syllabus goals in the built context', () async {
        final planner = _FakePlannerService();
        planner.setPlan(planWithGoals());
        final builder = _createBuilder(plannerService: planner);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Syllabus goals'));
        expect(result.data, contains('Math'));
        expect(result.data, contains('Science'));
        expect(builder.currentSyllabusContext, contains('Math'));
        // currentSyllabusContext must be injected into the buffer output,
        // not just available as a getter (Vision §3.1 context audit).
        expect(result.data, contains(builder.currentSyllabusContext));
      });

      test('identifies current syllabus from upcoming lesson subject', () async {
        final planner = _FakePlannerService();
        planner.setPlan(planWithGoals());
        planner.setScheduledLessons([
          Session(
            id: 's-1',
            studentId: 'test-student',
            subjectId: 'subj2', // Science has an upcoming lesson
            startTime: DateTime.now().add(const Duration(days: 1)),
          ),
        ]);
        final builder = _createBuilder(plannerService: planner);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        // currentSyllabusContext should identify Science as the active syllabus
        expect(builder.currentSyllabusContext, contains('Science'));
        expect(builder.currentSyllabusContext, contains('Active syllabus'));
        // And it must appear in the built prompt buffer
        expect(result.data, contains(builder.currentSyllabusContext));
      });

      test('auto-identifies single syllabus as current', () async {
        final planner = _FakePlannerService();
        planner.setPlan(PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [],
          summary: PlanSummary(
            totalQuestions: 0,
            totalMinutes: 0,
            newTopics: 0,
            reviewTopics: 0,
            estimatedCoverage: 0,
            focusAreas: [],
          ),
          recommendations: [],
          metadata: {
            'syllabus_goals': [
              {'subjectId': 'subj1', 'subjectTitle': 'Math'},
            ],
          },
        ));
        final builder = _createBuilder(plannerService: planner);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(builder.currentSyllabusContext, contains('Math'));
        expect(builder.currentSyllabusContext, contains('Active syllabus'));
        expect(result.data, contains(builder.currentSyllabusContext));
      });

      test('omits syllabus context when plan has no goals', () async {
        final planner = _FakePlannerService();
        planner.setPlan(PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [],
          summary: PlanSummary(
            totalQuestions: 0,
            totalMinutes: 0,
            newTopics: 0,
            reviewTopics: 0,
            estimatedCoverage: 0,
            focusAreas: [],
          ),
          recommendations: [],
        ));
        final builder = _createBuilder(plannerService: planner);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, isNot(contains('Syllabus goals')));
        expect(builder.currentSyllabusContext, isEmpty);
      });

      test('honors explicit syllabus focus over implicit upcoming-lesson resolution', () async {
        final focusService = SyllabusFocusService();
        final planner = _FakePlannerService();
        planner.setPlan(planWithGoals());
        // Implicit resolution would pick Math (subj1) because it has the
        // upcoming lesson — but the explicit focus on Science (subj2) wins.
        planner.setScheduledLessons([
          Session(
            id: 's-1',
            studentId: 'test-student',
            subjectId: 'subj1',
            startTime: DateTime.now().add(const Duration(days: 1)),
          ),
        ]);

        final builder = _createBuilder(
          plannerService: planner,
          focusService: focusService,
        );

        // Without focus: implicit resolution picks Math (upcoming lesson).
        var result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(builder.currentSyllabusContext, contains('Math'));
        expect(builder.currentSyllabusContext, contains('Active syllabus'));

        // Set explicit focus to Science.
        focusService.setFocus('subj2', subjectTitle: 'Science');

        // With focus: explicit override wins — Science, not Math.
        result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(builder.currentSyllabusContext, contains('Science'));
        expect(builder.currentSyllabusContext, isNot(contains('Math')));
      });

      test('clearing focus reverts to implicit resolution', () async {
        final focusService = SyllabusFocusService();
        final planner = _FakePlannerService();
        planner.setPlan(planWithGoals());
        planner.setScheduledLessons([
          Session(
            id: 's-1',
            studentId: 'test-student',
            subjectId: 'subj1',
            startTime: DateTime.now().add(const Duration(days: 1)),
          ),
        ]);

        final builder = _createBuilder(
          plannerService: planner,
          focusService: focusService,
        );

        focusService.setFocus('subj2', subjectTitle: 'Science');
        await builder.buildContextPrompt();
        expect(builder.currentSyllabusContext, contains('Science'));

        focusService.clearFocus();
        await builder.buildContextPrompt();
        expect(builder.currentSyllabusContext, contains('Math'));
      });
    });

    group('recent mistakes', () {
      test('injects per-question accuracy snapshot with concept labels and variant counts', () async {
        final now = DateTime.now();
        final mastery = _FakeMasteryGraphService();
        mastery.setAtRiskQuestions([
          QuestionMasteryState(
            studentId: 'test-student',
            questionId: 'q-aldol',
            correctCount: 2,
            incorrectCount: 3,
            lastIncorrect: now,
            lastAttempt: now,
          ),
        ]);
        final questionRepo = _FakeQuestionRepository();
        questionRepo.setQuestions({
          'q-aldol': Question(
            id: 'q-aldol',
            text: 'What is the product of the aldol condensation?',
            type: QuestionType.singleChoice,
            subjectId: 'chem-1',
            topicId: 'aldol',
            topic: 'aldol condensation',
            variantIds: ['v1', 'v2'],
            createdAt: now,
            updatedAt: now,
          ),
        });

        final builder = _createBuilder(
          masteryService: mastery,
          questionRepository: questionRepo,
        );
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Recent mistakes'));
        expect(result.data, contains('q-aldol'));
        expect(result.data, contains('aldol condensation'));
        expect(result.data, contains('40% accuracy'));
        expect(result.data, contains('2/5 correct'));
        expect(result.data, contains('3 wrong'));
        expect(result.data, contains('2 variant'));
      });

      test('falls back to questionId when concept label cannot be resolved', () async {
        final now = DateTime.now();
        final mastery = _FakeMasteryGraphService();
        mastery.setAtRiskQuestions([
          QuestionMasteryState(
            studentId: 'test-student',
            questionId: 'q-7',
            correctCount: 1,
            incorrectCount: 1,
            lastIncorrect: now,
            lastAttempt: now,
          ),
        ]);
        // Empty repo -> question cannot be resolved, no concept label, no
        // variant count emitted, but the per-question accuracy line still shows.
        final questionRepo = _FakeQuestionRepository();
        final builder = _createBuilder(
          masteryService: mastery,
          questionRepository: questionRepo,
        );
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('q-7: 50% accuracy'));
        expect(result.data, isNot(contains('variant')));
      });

      test('omits the recent mistakes block when no at-risk questions', () async {
        final builder = _createBuilder(); // default fakes: empty at-risk
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, isNot(contains('Recent mistakes')));
      });

      test('degrades gracefully when the mastery service fails', () async {
        final mastery = _FakeMasteryGraphService();
        mastery.setAtRiskFailure(true);
        final builder = _createBuilder(masteryService: mastery);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, isNot(contains('Recent mistakes')));
      });

      test('caps the number of per-question mistake lines', () async {
        final now = DateTime.now();
        final mastery = _FakeMasteryGraphService();
        mastery.setAtRiskQuestions(List.generate(8, (i) => QuestionMasteryState(
          studentId: 'test-student',
          questionId: 'q-$i',
          correctCount: 1,
          incorrectCount: 4,
          lastIncorrect: now,
          lastAttempt: now,
        )));
        final builder = _createBuilder(masteryService: mastery);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        // Only the first 5 at-risk questions are surfaced (see _maxRecentMistakes).
        expect(result.data, contains('q-0'));
        expect(result.data, isNot(contains('q-6')));
        expect(result.data, isNot(contains('q-7')));
      });
    });

    group('readiness scores', () {
      test('injects per-topic readiness scores matching CreatePracticeSessionTool signal', () async {
        final now = DateTime.now();
        final mastery = MasteryState(
          studentId: 'test-student',
          topicId: 'topic_alpha',
          subjectId: 'subj1',
          accuracy: 0.6,
          totalAttempts: 10,
          readinessScore: 0.45,
          recentAccuracy: [0.7, 0.6, 0.5],
          lastAttempt: now,
          lastUpdated: now,
        );
        // Inject the mastery maps directly so the scorer does not hit the
        // MasteryGraphService / Hive — same pattern CreatePracticeSessionTool
        // tests use for deterministic readiness data.
        final scorer = ReadinessScorer(
          topicMasteryMap: {'topic_alpha': mastery},
        );

        final builder = _createBuilder(readinessScorer: scorer);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        // Readiness block header present.
        expect(result.data, contains('Readiness to practice'));
        // Topic id and its readiness score (0.45 → 45%) surface.
        expect(result.data, contains('topic_alpha'));
        expect(result.data, contains('45%'));
        // Recent accuracy trend (per-topic past-session accuracy) is injected.
        expect(result.data, contains('recent:'));
        expect(result.data, contains('70%'));
      });

      test('omits readiness block when no scorer is wired', () async {
        final builder = _createBuilder(); // no readinessScorer
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        expect(result.data, isNot(contains('Readiness to practice')));
      });

      test('caps the number of per-topic readiness lines', () async {
        final now = DateTime.now();
        final scorer = ReadinessScorer(
          topicMasteryMap: {
            for (int i = 0; i < 10; i++)
              'topic_$i': MasteryState(
                studentId: 'test-student',
                topicId: 'topic_$i',
                subjectId: 'subj1',
                accuracy: 0.5,
                totalAttempts: 5,
                readinessScore: 0.3 + (i * 0.05),
                lastAttempt: now,
                lastUpdated: now,
              ),
          },
        );
        final builder = _createBuilder(readinessScorer: scorer);
        final result = await builder.buildContextPrompt();
        expect(result.isSuccess, isTrue);
        // Only _maxReadinessTopics (5) topic lines are injected.
        expect(result.data, contains('topic_0'));
        expect(result.data, isNot(contains('topic_9')));
        expect(result.data, isNot(contains('topic_8')));
      });
    });
  });
}
