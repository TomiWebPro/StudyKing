import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart' show masteryGraphServiceProvider;
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart' show topicRepositoryProvider;

class _FakePlannerService extends PlannerService {
  PersonalLearningPlan? _plan;
  List<PlanAdherenceModel> _adherenceRecords = [];
  List<RoadmapModel> _roadmaps = [];
  bool _throwOnLoadPlan = false;
  bool _throwOnLoadRoadmaps = false;

  _FakePlannerService() : super(fixedStudentId: 'test-student');

  void setPlan(PersonalLearningPlan p) => _plan = p;
  void setAdherenceRecords(List<PlanAdherenceModel> records) => _adherenceRecords = records;
  void setRoadmaps(List<RoadmapModel> roadmaps) => _roadmaps = roadmaps;
  void setThrowOnLoadPlan() => _throwOnLoadPlan = true;
  void setThrowOnLoadRoadmaps() => _throwOnLoadRoadmaps = true;

  @override
  Future<Result<PersonalLearningPlan?>> loadExistingPlan() async {
    if (_throwOnLoadPlan) throw Exception('load plan error');
    return Result.success(_plan);
  }

  @override
  Future<Result<List<PlanAdherenceModel>>> getAdherenceRecords() async {
    return Result.success(_adherenceRecords);
  }

  @override
  Future<Result<List<RoadmapModel>>> loadRoadmaps() async {
    if (_throwOnLoadRoadmaps) throw Exception('load roadmaps error');
    return Result.success(_roadmaps);
  }
}

class _FakeMasteryServiceForCards extends MasteryGraphService {
  final List<MasteryState> _allMastery;
  final bool _failGetAllMastery;
  int getAllMasteryCalls = 0;

  _FakeMasteryServiceForCards({
    List<MasteryState> allMastery = const [],
    bool failGetAllMastery = false,
  })  : _allMastery = allMastery,
        _failGetAllMastery = failGetAllMastery,
        super();

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) async {
    getAllMasteryCalls++;
    if (_failGetAllMastery) return Result.failure('mastery fetch failed');
    return Result.success(_allMastery.where((m) => m.studentId == studentId).toList());
  }
}

class _FakeTopicRepoForCards extends TopicRepository {
  final List<Topic> _topics;
  final bool _failGetAll;
  int getAllCalls = 0;

  _FakeTopicRepoForCards({
    List<Topic> topics = const [],
    bool failGetAll = false,
  })  : _topics = topics,
        _failGetAll = failGetAll;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Topic>>> getAll() async {
    getAllCalls++;
    if (_failGetAll) return Result.failure('topic fetch failed');
    return Result.success(_topics);
  }
}

void main() {
  group('syllabusProgressProvider', () {
    test('returns default data when no plan exists', () async {
      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(_FakePlannerService()),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(syllabusProgressProvider('test-student').future);
      expect(data.totalTopics, 0);
      expect(data.completedTopics, 0);
      expect(data.completionPercentage, 0.0);
      expect(data.focusAreas, isEmpty);
    });

    test('returns correct data when plan exists', () async {
      final now = DateTime.now();
      final plan = PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: now,
        dailyPlans: [
          DailyPlan(
            date: now,
            dayNumber: 1,
            priorityTopics: [
              PlannedTopic(topicId: 'topic-1', topicTitle: 'Kinematics', priority: 0.9, reason: 'test', readinessScore: 0.5, reviewUrgency: 0.3, estimatedQuestions: 5, estimatedMinutes: 30, reasons: [], subjectId: 'sub-1'),
              PlannedTopic(topicId: 'topic-2', topicTitle: 'Vectors', priority: 0.7, reason: 'test', readinessScore: 0.5, reviewUrgency: 0.3, estimatedQuestions: 5, estimatedMinutes: 30, reasons: [], subjectId: 'sub-1'),
            ],
            reviewQuestionIds: [],
            stretchGoalQuestionIds: [],
            targetQuestions: 10,
            targetMinutes: 60,
            focus: 'Study',
          ),
        ],
        summary: PlanSummary(
          totalQuestions: 10, totalMinutes: 60, newTopics: 2, reviewTopics: 0, estimatedCoverage: 0.5, focusAreas: ['topic-1'],
        ),
        recommendations: [
          PlanRecommendation(topicId: 'topic-1', reason: 'Weak', recommendationType: 'weakness', priority: 0.9, explanations: [], prerequisiteReason: null, weaknessReason: null, reviewReason: null),
        ],
      );

      final service = _FakePlannerService();
      service.setPlan(plan);
      service.setAdherenceRecords([
        PlanAdherenceModel(
          id: 'adh-1', studentId: 'test-student', date: now,
          plannedMinutes: 60, actualMinutes: 45,
          plannedQuestions: 10, actualQuestions: 8,
          adherenceScore: 0.75,
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(syllabusProgressProvider('test-student').future);
      expect(data.totalTopics, 2);
      expect(data.completedTopics, 2);
      expect(data.completionPercentage, 1.0);
      expect(data.focusAreas, hasLength(1));
      expect(data.focusAreas.first, 'topic-1');
    });

    test('handles exception gracefully', () async {
      final service = _FakePlannerService();
      service.setThrowOnLoadPlan();

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(syllabusProgressProvider('test-student').future);
      expect(data.totalTopics, 0);
      expect(data.completedTopics, 0);
    });
  });

  group('roadmapListProvider', () {
    test('returns empty list when no roadmaps exist', () async {
      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(_FakePlannerService()),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(roadmapListProvider('test-student').future);
      expect(data.roadmaps, isEmpty);
      expect(data.isLoading, false);
    });

    test('returns roadmaps when they exist', () async {
      final service = _FakePlannerService();
      service.setRoadmaps([
        RoadmapModel(id: 'rm-1', studentId: 'test-student', goal: 'Learn Physics', createdAt: DateTime.now()),
        RoadmapModel(id: 'rm-2', studentId: 'test-student', goal: 'Master Math', createdAt: DateTime.now()),
      ]);

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(roadmapListProvider('test-student').future);
      expect(data.roadmaps, hasLength(2));
      expect(data.roadmaps.first.goal, 'Learn Physics');
      expect(data.isLoading, false);
    });

    test('handles exception gracefully', () async {
      final service = _FakePlannerService();
      service.setThrowOnLoadRoadmaps();

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(roadmapListProvider('test-student').future);
      expect(data.roadmaps, isEmpty);
      expect(data.isLoading, false);
    });
  });

  group('syllabusProgressForCardsProvider', () {
    final now = DateTime(2026, 5, 12);

    createPlanWithGoals(List<SyllabusGoal> goals) {
      return PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: now,
        dailyPlans: [],
        summary: PlanSummary(
          totalQuestions: 0,
          totalMinutes: 0,
          newTopics: 0,
          reviewTopics: 0,
          estimatedCoverage: 0.0,
          focusAreas: [],
        ),
        recommendations: [],
        metadata: {'syllabus_goals': goals.map((g) => g.toJson()).toList()},
      );
    }

    test('scopes mastery states and totalTopics per subject in a single fetch', () async {
      final mathTopics = [
        Topic(id: 'math-t1', subjectId: 'math-101', title: 'Algebra', description: '', syllabusText: ''),
        Topic(id: 'math-t2', subjectId: 'math-101', title: 'Geometry', description: '', syllabusText: ''),
      ];
      final physicsTopics = [
        Topic(id: 'phys-t1', subjectId: 'phys-101', title: 'Mechanics', description: '', syllabusText: ''),
        Topic(id: 'phys-t2', subjectId: 'phys-101', title: 'Optics', description: '', syllabusText: ''),
      ];
      final masteryStates = [
        MasteryState(studentId: 'test-student', topicId: 'math-t1', masteryLevel: MasteryLevel.proficient, lastAttempt: now, lastUpdated: now),
        MasteryState(studentId: 'test-student', topicId: 'phys-t1', masteryLevel: MasteryLevel.expert, lastAttempt: now, lastUpdated: now),
        // A physics mastery from a different student must stay scoped
        MasteryState(studentId: 'other-student', topicId: 'phys-t1', masteryLevel: MasteryLevel.proficient, lastAttempt: now, lastUpdated: now),
      ];

      final plan = createPlanWithGoals([
        const SyllabusGoal(subjectId: 'math-101', subjectTitle: 'Mathematics'),
        const SyllabusGoal(subjectId: 'phys-101', subjectTitle: 'Physics'),
      ]);

      final service = _FakePlannerService()..setPlan(plan);

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
          masteryGraphServiceProvider.overrideWithValue(
            _FakeMasteryServiceForCards(allMastery: masteryStates),
          ),
          topicRepositoryProvider.overrideWithValue(
            _FakeTopicRepoForCards(topics: [...mathTopics, ...physicsTopics]),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Behavioral assertion: exactly one mastery fetch + one topics fetch serve ALL subjects.
      final result = await container.read(syllabusProgressForCardsProvider('test-student').future);

      // Two subjects must be served by exactly ONE mastery fetch and ONE topics fetch.
      // Before this fix, each card called getAllMasteryStates per subject (N calls).
      final masteryService = container.read(masteryGraphServiceProvider) as _FakeMasteryServiceForCards;
      final topicRepo = container.read(topicRepositoryProvider) as _FakeTopicRepoForCards;
      expect(masteryService.getAllMasteryCalls, 1);
      expect(topicRepo.getAllCalls, 1);

      // Math scope contains only math-t1 (proficient).
      final mathScope = result['math-101'];
      expect(mathScope, isNotNull);
      expect(mathScope!.totalTopics, 2);
      expect(mathScope.masteryStates, hasLength(1));
      expect(mathScope.masteryStates.first.topicId, 'math-t1');

      // Physics scope contains only phys-t1 (expert), NOT the other-student state.
      final physicsScope = result['phys-101'];
      expect(physicsScope, isNotNull);
      expect(physicsScope!.totalTopics, 2);
      expect(physicsScope.masteryStates, hasLength(1));
      expect(physicsScope.masteryStates.first.topicId, 'phys-t1');
    });

    test('returns empty map when no plan exists', () async {
      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(_FakePlannerService()),
          masteryGraphServiceProvider.overrideWithValue(_FakeMasteryServiceForCards()),
          topicRepositoryProvider.overrideWithValue(_FakeTopicRepoForCards()),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(syllabusProgressForCardsProvider('test-student').future);
      expect(result, isEmpty);
    });

    test('returns scoped mastery with empty topics when topic fetch fails', () async {
      final masteryStates = [
        MasteryState(studentId: 'test-student', topicId: 'math-t1', masteryLevel: MasteryLevel.proficient, lastAttempt: now, lastUpdated: now),
      ];
      final plan = createPlanWithGoals([
        const SyllabusGoal(subjectId: 'math-101', subjectTitle: 'Mathematics'),
      ]);

      final service = _FakePlannerService()..setPlan(plan);

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
          masteryGraphServiceProvider.overrideWithValue(
            _FakeMasteryServiceForCards(allMastery: masteryStates),
          ),
          topicRepositoryProvider.overrideWithValue(
            _FakeTopicRepoForCards(topics: [], failGetAll: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(syllabusProgressForCardsProvider('test-student').future);
      expect(result, hasLength(1));
      final scope = result['math-101'];
      expect(scope!.masteryStates, isEmpty); // No topicIds known → all scoped out
      expect(scope.totalTopics, 0);
    });
  });
}
