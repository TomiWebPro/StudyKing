import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/features/dashboard/providers/dashboard_data_providers.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';

class _FakePlanAdherenceRepo extends PlanAdherenceRepository {
  final List<PlanAdherenceModel> _records = [];

  void addRecord(PlanAdherenceModel record) => _records.add(record);

  @override
  Future<void> init() async {}

  @override
  Future<List<PlanAdherenceModel>> getByStudent(String studentId) async {
    return _records.where((r) => r.studentId == studentId).toList();
  }

  @override
  Future<List<PlanAdherenceModel>> getWeekly(String studentId) async {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _records
        .where((r) => r.studentId == studentId && r.date.isAfter(weekAgo))
        .toList();
  }

  @override
  Future<double> getAverageAdherence(String studentId) async {
    final records = await getByStudent(studentId);
    if (records.isEmpty) return 0.0;
    return records.fold<double>(0.0, (sum, r) => sum + r.adherenceScore) /
        records.length;
  }
}

class _FakeTopicRepo extends TopicRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Topic>>> getAll() async => Result.success([]);

  @override
  Future<Result<Topic?>> get(String id) async => Result.success(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Dashboard + Planner Integration — adherence data flow', () {
    test(
        'dashboardAdherenceDataProvider and planProgressProvider agree on '
        'adherence from shared PlanAdherenceRepository', () async {
      const studentId = 'test-student';
      final now = DateTime.now();

      final plan = PersonalLearningPlan(
        studentId: studentId,
        generatedAt: now.subtract(const Duration(days: 7)),
        dailyPlans: [
          DailyPlan(
            date: now.subtract(const Duration(days: 6)),
            dayNumber: 1,
            priorityTopics: [],
            reviewQuestionIds: [],
            stretchGoalQuestionIds: [],
            targetQuestions: 10,
            targetMinutes: 30,
          ),
          DailyPlan(
            date: now.subtract(const Duration(days: 5)),
            dayNumber: 2,
            priorityTopics: [],
            reviewQuestionIds: [],
            stretchGoalQuestionIds: [],
            targetQuestions: 15,
            targetMinutes: 45,
          ),
          DailyPlan(
            date: now.subtract(const Duration(days: 4)),
            dayNumber: 3,
            priorityTopics: [],
            reviewQuestionIds: [],
            stretchGoalQuestionIds: [],
            targetQuestions: 10,
            targetMinutes: 30,
          ),
          DailyPlan(
            date: now.subtract(const Duration(days: 3)),
            dayNumber: 4,
            priorityTopics: [],
            reviewQuestionIds: [],
            stretchGoalQuestionIds: [],
            targetQuestions: 10,
            targetMinutes: 30,
          ),
          DailyPlan(
            date: now.subtract(const Duration(days: 2)),
            dayNumber: 5,
            priorityTopics: [],
            reviewQuestionIds: [],
            stretchGoalQuestionIds: [],
            targetQuestions: 15,
            targetMinutes: 45,
          ),
        ],
        summary: PlanSummary(
          totalQuestions: 60,
          totalMinutes: 180,
          newTopics: 3,
          reviewTopics: 2,
          estimatedCoverage: 0.5,
          focusAreas: ['math', 'science'],
        ),
        recommendations: [],
      );

      final planRepo = PlanRepositoryFake();
      planRepo.addPlan(plan);

      final adherenceRepo = _FakePlanAdherenceRepo();
      adherenceRepo.addRecord(PlanAdherenceModel(
        id: 'adh1',
        studentId: studentId,
        date: now.subtract(const Duration(days: 6)),
        actualMinutes: 25,
        plannedMinutes: 30,
        actualQuestions: 8,
        plannedQuestions: 10,
        adherenceScore: 0.85,
      ));
      adherenceRepo.addRecord(PlanAdherenceModel(
        id: 'adh2',
        studentId: studentId,
        date: now.subtract(const Duration(days: 5)),
        actualMinutes: 10,
        plannedMinutes: 45,
        actualQuestions: 3,
        plannedQuestions: 15,
        adherenceScore: 0.20,
      ));
      adherenceRepo.addRecord(PlanAdherenceModel(
        id: 'adh3',
        studentId: studentId,
        date: now.subtract(const Duration(days: 4)),
        actualMinutes: 28,
        plannedMinutes: 30,
        actualQuestions: 9,
        plannedQuestions: 10,
        adherenceScore: 0.90,
      ));
      adherenceRepo.addRecord(PlanAdherenceModel(
        id: 'adh4',
        studentId: studentId,
        date: now.subtract(const Duration(days: 3)),
        actualMinutes: 5,
        plannedMinutes: 30,
        actualQuestions: 2,
        plannedQuestions: 10,
        adherenceScore: 0.15,
      ));
      adherenceRepo.addRecord(PlanAdherenceModel(
        id: 'adh5',
        studentId: studentId,
        date: now.subtract(const Duration(days: 2)),
        actualMinutes: 40,
        plannedMinutes: 45,
        actualQuestions: 12,
        plannedQuestions: 15,
        adherenceScore: 0.88,
      ));

      final plannerService = PlannerService(
        planRepo: planRepo,
        adherenceRepo: adherenceRepo,
        masteryService: MasteryGraphService(),
        topicRepository: _FakeTopicRepo(),
        fixedStudentId: studentId,
      );

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(plannerService),
          engagementAdherenceRepoProvider
              .overrideWithValue(adherenceRepo),
        ],
      );

      final adherenceData =
          await container.read(dashboardAdherenceDataProvider(studentId).future);

      final expectedAvg = (0.85 + 0.20 + 0.90 + 0.15 + 0.88) / 5;
      expect(adherenceData.averageAdherence, closeTo(expectedAvg, 0.01));
      expect(adherenceData.weeklyAdherence, closeTo(expectedAvg, 0.01));
      expect(adherenceData.isEmpty, isFalse);

      // planProgressProvider: 5 non-rest days, 3 completed (adh >= 0.5)
      final planProgress = await container.read(planProgressProvider.future);
      expect(planProgress.totalPlanDays, 5);
      expect(planProgress.completedDays, 3);
      expect(planProgress.cumulativeProgress, closeTo(0.6, 0.01));

      // Today is not in the plan's daily plans, so todayProgress is 0
      expect(planProgress.todayProgress, 0.0);

      // 7 weekly progress entries (6 days ago through today)
      expect(planProgress.weeklyProgress.length, 7);

      container.dispose();
    });

    test('dashboard shows zero adherence when no planner data exists',
        () async {
      const studentId = 'test-student';

      final planRepo = PlanRepositoryFake();
      planRepo.addPlan(PersonalLearningPlan(
        studentId: studentId,
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

      final adherenceRepo = _FakePlanAdherenceRepo();
      final plannerService = PlannerService(
        planRepo: planRepo,
        adherenceRepo: adherenceRepo,
        masteryService: MasteryGraphService(),
        topicRepository: _FakeTopicRepo(),
        fixedStudentId: studentId,
      );

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(plannerService),
          engagementAdherenceRepoProvider
              .overrideWithValue(adherenceRepo),
        ],
      );

      final adherenceData =
          await container.read(dashboardAdherenceDataProvider(studentId).future);
      expect(adherenceData.averageAdherence, 0.0);
      expect(adherenceData.weeklyAdherence, 0.0);
      expect(adherenceData.isEmpty, isTrue);

      final planProgress = await container.read(planProgressProvider.future);
      expect(planProgress.totalPlanDays, 0);
      expect(planProgress.completedDays, 0);
      expect(planProgress.cumulativeProgress, 0.0);

      container.dispose();
    });
  });
}

class PlanRepositoryFake extends PlanRepository {
  final Map<String, PersonalLearningPlan> _storage = {};

  void addPlan(PersonalLearningPlan plan) {
    _storage[plan.studentId] = plan;
  }

  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> savePlan(PersonalLearningPlan plan) async {
    _storage[plan.studentId] = plan;
    return Result.success(null);
  }

  @override
  Future<Result<PersonalLearningPlan?>> loadPlan(String studentId) async {
    return Result.success(_storage[studentId]);
  }

  @override
  Future<Result<bool>> hasPlan(String studentId) async {
    return Result.success(_storage.containsKey(studentId));
  }

  @override
  Future<Result<List<PersonalLearningPlan>>> getAllPlans() async {
    return Result.success(_storage.values.toList());
  }

  @override
  Future<Result<void>> deletePlan(String studentId) async {
    _storage.remove(studentId);
    return Result.success(null);
  }
}
