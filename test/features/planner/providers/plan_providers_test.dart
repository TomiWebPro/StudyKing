import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/planner/services/planner_service.dart';

class _FakePlannerService extends PlannerService {
  _FakePlannerService() : super(lessonAgentService: null, localeName: 'en');

  @override
  Future<Result<PersonalLearningPlan?>> loadExistingPlan() async {
    return Result.success(null);
  }

  @override
  Future<Result<List<RoadmapModel>>> loadRoadmaps() async {
    return Result.success([]);
  }

  @override
  Future<Result<List<PendingActionModel>>> loadPendingActions() async {
    return Result.success([]);
  }

  @override
  Future<Result<List<Session>>> getScheduledLessons() async {
    return Result.success([]);
  }

  @override
  Future<Result<List<Session>>> getMissedLessons() async {
    return Result.success([]);
  }

  @override
  Future<Result<Map<String, int>>> getAdherenceMetrics() async {
    return Result.success({});
  }

  @override
  Future<Result<List<PlanAdherenceModel>>> getAdherenceRecords() async {
    return Result.success([]);
  }
}

void main() {
  group('PlanProgressData', () {
    test('has correct default values', () {
      final data = PlanProgressData();
      expect(data.plannedMinutesToday, 0);
      expect(data.actualMinutesToday, 0);
      expect(data.plannedQuestionsToday, 0);
      expect(data.actualQuestionsToday, 0);
      expect(data.todayProgress, 0.0);
      expect(data.totalPlanDays, 0);
      expect(data.completedDays, 0);
      expect(data.cumulativeProgress, 0.0);
      expect(data.weeklyProgress, isEmpty);
    });

    test('can be created with custom values', () {
      final data = PlanProgressData(
        plannedMinutesToday: 60,
        actualMinutesToday: 45,
        plannedQuestionsToday: 15,
        actualQuestionsToday: 10,
        todayProgress: 0.75,
        totalPlanDays: 30,
        completedDays: 20,
        cumulativeProgress: 0.67,
        weeklyProgress: [
          DailyProgress(date: DateTime(2026, 1, 1), plannedMinutes: 30, actualMinutes: 25),
        ],
      );
      expect(data.plannedMinutesToday, 60);
      expect(data.actualMinutesToday, 45);
      expect(data.cumulativeProgress, 0.67);
    });

    test('weeklyProgress can hold multiple DailyProgress entries', () {
      final data = PlanProgressData(
        weeklyProgress: [
          DailyProgress(date: DateTime(2026, 1, 1)),
          DailyProgress(date: DateTime(2026, 1, 2)),
          DailyProgress(date: DateTime(2026, 1, 3)),
        ],
      );
      expect(data.weeklyProgress, hasLength(3));
    });
  });

  group('DailyProgress', () {
    test('has correct default values', () {
      final dp = DailyProgress(date: DateTime(2026, 1, 1));
      expect(dp.date, DateTime(2026, 1, 1));
      expect(dp.plannedMinutes, 0);
      expect(dp.actualMinutes, 0);
    });

    test('can be created with custom values', () {
      final dp = DailyProgress(
        date: DateTime(2026, 6, 15),
        plannedMinutes: 60,
        actualMinutes: 45,
      );
      expect(dp.plannedMinutes, 60);
      expect(dp.actualMinutes, 45);
    });

    test('supports different dates', () {
      final dp1 = DailyProgress(date: DateTime(2026, 1, 1));
      final dp2 = DailyProgress(date: DateTime(2026, 6, 15));
      expect(dp1.date.isBefore(dp2.date), true);
    });
  });

  group('planProgressProvider', () {
    test('returns default PlanProgressData when no plan exists', () async {
      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(_FakePlannerService()),
        ],
      );
      addTearDown(container.dispose);

      final progress = await container.read(planProgressProvider.future);
      expect(progress.plannedMinutesToday, 0);
      expect(progress.actualMinutesToday, 0);
      expect(progress.todayProgress, 0.0);
      expect(progress.totalPlanDays, 0);
      expect(progress.completedDays, 0);
      expect(progress.cumulativeProgress, 0.0);
      expect(progress.weeklyProgress, hasLength(7));
    });
  });
}
