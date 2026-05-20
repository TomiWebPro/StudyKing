import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/planner/services/planner_service.dart';

class _FakePlannerService extends PlannerService {
  PersonalLearningPlan? _plan;
  List<PlanAdherenceModel> _adherenceRecords = [];
  Map<String, int> _metrics = {};
  bool _throwOnAdherence = false;
  bool _throwOnPlan = false;
  bool _throwOnMetrics = false;

  _FakePlannerService() : super(fixedStudentId: 'test-student');

  void setPlan(PersonalLearningPlan p) => _plan = p;
  void setAdherenceRecords(List<PlanAdherenceModel> records) => _adherenceRecords = records;
  void setMetrics(Map<String, int> m) => _metrics = m;
  void setThrowOnAdherence() => _throwOnAdherence = true;
  void setThrowOnPlan() => _throwOnPlan = true;
  void setThrowOnMetrics() => _throwOnMetrics = true;

  @override
  Future<Result<PersonalLearningPlan?>> loadExistingPlan() async {
    if (_throwOnPlan) throw Exception('load plan error');
    return Result.success(_plan);
  }

  @override
  Future<Result<List<PlanAdherenceModel>>> getAdherenceRecords() async {
    if (_throwOnAdherence) throw Exception('adherence error');
    return Result.success(_adherenceRecords);
  }

  @override
  Future<Result<Map<String, int>>> getAdherenceMetrics() async {
    if (_throwOnMetrics) throw Exception('metrics error');
    return Result.success(_metrics);
  }
}

void main() {
  group('adherenceSummaryProvider', () {
    test('returns default data when no records exist', () async {
      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(_FakePlannerService()),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(adherenceSummaryProvider('test-student').future);
      expect(data.averageAdherence, 0.0);
      expect(data.totalDays, 0);
      expect(data.completedDays, 0);
      expect(data.lowAdherenceDays, 0);
      expect(data.currentStreak, 0);
      expect(data.bestStreak, 0);
      expect(data.weeklyTrend, hasLength(7));
    });

    test('computes adherence summary correctly', () async {
      final now = DateTime.now();
      final service = _FakePlannerService();
      service.setAdherenceRecords([
        PlanAdherenceModel(id: 'a1', studentId: 'test-student', date: now.subtract(const Duration(days: 2)), plannedMinutes: 60, actualMinutes: 45, adherenceScore: 0.75),
        PlanAdherenceModel(id: 'a2', studentId: 'test-student', date: now.subtract(const Duration(days: 1)), plannedMinutes: 60, actualMinutes: 50, adherenceScore: 0.83),
        PlanAdherenceModel(id: 'a3', studentId: 'test-student', date: now, plannedMinutes: 60, actualMinutes: 30, adherenceScore: 0.5),
      ]);

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(adherenceSummaryProvider('test-student').future);
      expect(data.totalDays, 3);
      expect(data.completedDays, 3);
      expect(data.lowAdherenceDays, 0);
      expect(data.averageAdherence, closeTo(0.693, 0.01));
    });

    test('identifies low adherence days', () async {
      final now = DateTime.now();
      final service = _FakePlannerService();
      service.setAdherenceRecords([
        PlanAdherenceModel(id: 'a1', studentId: 'test-student', date: now.subtract(const Duration(days: 2)), plannedMinutes: 60, actualMinutes: 10, adherenceScore: 0.17),
        PlanAdherenceModel(id: 'a2', studentId: 'test-student', date: now.subtract(const Duration(days: 1)), plannedMinutes: 60, actualMinutes: 50, adherenceScore: 0.83),
        PlanAdherenceModel(id: 'a3', studentId: 'test-student', date: now, plannedMinutes: 60, actualMinutes: 5, adherenceScore: 0.08),
      ]);

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(adherenceSummaryProvider('test-student').future);
      expect(data.lowAdherenceDays, 2);
      expect(data.completedDays, 1);
    });

    test('handles exceptions gracefully', () async {
      final service = _FakePlannerService();
      service.setThrowOnAdherence();

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(adherenceSummaryProvider('test-student').future);
      expect(data.averageAdherence, 0.0);
      expect(data.totalDays, 0);
    });
  });

  group('todayAdherenceProvider', () {
    test('returns default data when no plan or records exist', () async {
      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(_FakePlannerService()),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(todayAdherenceProvider('test-student').future);
      expect(data.actualMinutes, 0);
      expect(data.actualQuestions, 0);
      expect(data.plannedMinutes, 0);
      expect(data.plannedQuestions, 0);
      expect(data.progress, 0.0);
    });

    test('computes today adherence from metrics and plan', () async {
      final now = DateTime.now();
      final plan = PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: now,
        dailyPlans: [
          DailyPlan(
            date: now, dayNumber: 1,
            priorityTopics: [],
            reviewQuestionIds: [], stretchGoalQuestionIds: [],
            targetQuestions: 15, targetMinutes: 60, focus: 'Study',
          ),
        ],
        summary: PlanSummary(totalQuestions: 15, totalMinutes: 60, newTopics: 1, reviewTopics: 0, estimatedCoverage: 0.5, focusAreas: []),
        recommendations: [],
      );

      final service = _FakePlannerService();
      service.setPlan(plan);
      service.setMetrics({'actualMinutesToday': 45, 'actualQuestionsToday': 10});

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(todayAdherenceProvider('test-student').future);
      expect(data.actualMinutes, 45);
      expect(data.actualQuestions, 10);
      expect(data.plannedMinutes, 60);
      expect(data.plannedQuestions, 15);
      expect(data.progress, closeTo(0.75, 0.01));
    });

    test('returns actual-only data when no plan exists', () async {
      final service = _FakePlannerService();
      service.setMetrics({'actualMinutesToday': 30, 'actualQuestionsToday': 5});

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(todayAdherenceProvider('test-student').future);
      expect(data.actualMinutes, 30);
      expect(data.actualQuestions, 5);
      expect(data.plannedMinutes, 0);
      expect(data.plannedQuestions, 0);
    });

    test('handles exceptions gracefully', () async {
      final service = _FakePlannerService();
      service.setThrowOnMetrics();

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(todayAdherenceProvider('test-student').future);
      expect(data.actualMinutes, 0);
      expect(data.actualQuestions, 0);
    });
  });
}
