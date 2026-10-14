import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/planner/services/planner_service.dart';

class _FakePlannerService extends PlannerService {
  PersonalLearningPlan? _plan;
  List<PlanAdherenceModel> _adherenceRecords = [];
  Map<String, int> _metrics = {};

  _FakePlannerService() : super(lessonAgentService: null, localeName: 'en');

  void setPlan(PersonalLearningPlan p) => _plan = p;
  void setAdherenceRecords(List<PlanAdherenceModel> records) =>
      _adherenceRecords = records;
  void setMetrics(Map<String, int> m) => _metrics = m;

  @override
  Future<Result<PersonalLearningPlan?>> loadExistingPlan() async {
    return Result.success(_plan);
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
    return Result.success(_metrics);
  }

  @override
  Future<Result<List<PlanAdherenceModel>>> getAdherenceRecords() async {
    return Result.success(_adherenceRecords);
  }
}

class _FixedClock implements Clock {
  final DateTime _now;
  _FixedClock(this._now);

  @override
  DateTime now() => _now;
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
      expect(progress.weeklyProgress, isEmpty);
    });

    test('weeklyProgress carries planned and actual minutes across a spring-forward transition',
        () async {
      // Europe/Berlin springs forward on 2026-03-29, so that
      // calendar day is only 23h long. Elapsed-time arithmetic
      // (`todayStart.subtract(Duration(days: i))`) spans an
      // absolute 24h×i and lands on 23:00 of the previous
      // calendar day for every i whose span contains the
      // transition, so it never equals the calendar midnights
      // plan days and adherence records are keyed by: the six
      // days before "today" were emitted with zero minutes.
      final service = _FakePlannerService();
      service.setPlan(PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: DateTime(2026, 3, 30, 12, 0),
        dailyPlans: [
          for (var i = 0; i < 7; i++)
            DailyPlan(
              date: DateTime(2026, 3, 24 + i, 10, 0),
              dayNumber: i + 1,
              priorityTopics: [],
              reviewQuestionIds: [],
              stretchGoalQuestionIds: [],
              targetQuestions: 15,
              targetMinutes: 60,
              focus: 'Study',
            ),
        ],
        summary: PlanSummary(
          totalQuestions: 105,
          totalMinutes: 420,
          newTopics: 7,
          reviewTopics: 0,
          estimatedCoverage: 0.5,
          focusAreas: [],
        ),
        recommendations: [],
      ));
      // Sessions recorded on every day of the previous week
      // (Mar 23-29), with distinct minute counts so a day that
      // fails to match its record cannot borrow another day's.
      service.setAdherenceRecords([
        for (final day in [23, 24, 25, 26, 27, 28, 29])
          PlanAdherenceModel(
            id: 'a$day',
            studentId: 'test-student',
            date: DateTime(2026, 3, day, 10, 0),
            plannedMinutes: 60,
            actualMinutes: day,
            adherenceScore: 0.9,
          ),
      ]);
      service.setMetrics({'actualMinutesToday': 30, 'actualQuestionsToday': 5});

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
          clockProvider.overrideWithValue(_FixedClock(DateTime(2026, 3, 30, 12, 0))),
        ],
      );
      addTearDown(container.dispose);

      final progress = await container.read(planProgressProvider.future);
      expect(progress.weeklyProgress, hasLength(7));
      // Mar 24-29: each day carries the plan's target minutes
      // and that day's own recorded actual minutes.
      for (var i = 0; i < 6; i++) {
        final entry = progress.weeklyProgress[i];
        expect(entry.plannedMinutes, 60, reason: 'Mar ${24 + i}');
        expect(entry.actualMinutes, 24 + i, reason: 'Mar ${24 + i}');
      }
      // Today (Mar 30) carries the plan target; no session
      // recorded yet, so actual minutes are zero.
      expect(progress.weeklyProgress[6].plannedMinutes, 60);
      expect(progress.weeklyProgress[6].actualMinutes, 0);
      // Every emitted day key is a calendar midnight.
      for (final entry in progress.weeklyProgress) {
        expect(entry.date.hour, 0);
        expect(entry.date.minute, 0);
      }
    });

    test('weeklyProgress carries planned and actual minutes across a fall-back transition',
        () async {
      // Europe/Berlin falls back on 2026-10-25, so that calendar
      // day is 25h long and a 24h×i span lands on 01:00 of the
      // target calendar day, matching no plan day or adherence
      // record: the six days before "today" were zeroed.
      final service = _FakePlannerService();
      service.setPlan(PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: DateTime(2026, 10, 26, 12, 0),
        dailyPlans: [
          for (var i = 0; i < 7; i++)
            DailyPlan(
              date: DateTime(2026, 10, 20 + i, 10, 0),
              dayNumber: i + 1,
              priorityTopics: [],
              reviewQuestionIds: [],
              stretchGoalQuestionIds: [],
              targetQuestions: 15,
              targetMinutes: 45,
              focus: 'Study',
            ),
        ],
        summary: PlanSummary(
          totalQuestions: 105,
          totalMinutes: 315,
          newTopics: 7,
          reviewTopics: 0,
          estimatedCoverage: 0.5,
          focusAreas: [],
        ),
        recommendations: [],
      ));
      service.setAdherenceRecords([
        for (final day in [20, 21, 22, 23, 24, 25])
          PlanAdherenceModel(
            id: 'b$day',
            studentId: 'test-student',
            date: DateTime(2026, 10, day, 10, 0),
            plannedMinutes: 45,
            actualMinutes: day,
            adherenceScore: 0.9,
          ),
      ]);
      service.setMetrics({'actualMinutesToday': 20, 'actualQuestionsToday': 5});

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
          clockProvider.overrideWithValue(_FixedClock(DateTime(2026, 10, 26, 12, 0))),
        ],
      );
      addTearDown(container.dispose);

      final progress = await container.read(planProgressProvider.future);
      expect(progress.weeklyProgress, hasLength(7));
      // Oct 20-25: each day carries the plan's target minutes
      // and that day's own recorded actual minutes.
      for (var i = 0; i < 6; i++) {
        final entry = progress.weeklyProgress[i];
        expect(entry.plannedMinutes, 45, reason: 'Oct ${20 + i}');
        expect(entry.actualMinutes, 20 + i, reason: 'Oct ${20 + i}');
      }
      // Today (Oct 26) carries the plan target; no session
      // recorded yet, so actual minutes are zero.
      expect(progress.weeklyProgress[6].plannedMinutes, 45);
      expect(progress.weeklyProgress[6].actualMinutes, 0);
      for (final entry in progress.weeklyProgress) {
        expect(entry.date.hour, 0);
        expect(entry.date.minute, 0);
      }
    });
  });
}
