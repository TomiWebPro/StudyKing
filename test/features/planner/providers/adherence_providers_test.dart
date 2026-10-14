import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/core/utils/time_utils.dart';
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

class _FixedClock implements Clock {
  final DateTime _now;
  _FixedClock(this._now);

  @override
  DateTime now() => _now;
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
      expect(data.weeklyTrend, isEmpty);
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

    test('bestStreak is not inflated by the current streak', () async {
      final now = DateTime.now();
      final service = _FakePlannerService();
      // 4-day historical best (today-8..today-5), a low-adherence day
      // (today-4), then a 4-day current streak (today-3..today).
      service.setAdherenceRecords([
        PlanAdherenceModel(id: 'a1', studentId: 'test-student', date: now.subtract(const Duration(days: 8)), adherenceScore: 0.8),
        PlanAdherenceModel(id: 'a2', studentId: 'test-student', date: now.subtract(const Duration(days: 7)), adherenceScore: 0.8),
        PlanAdherenceModel(id: 'a3', studentId: 'test-student', date: now.subtract(const Duration(days: 6)), adherenceScore: 0.8),
        PlanAdherenceModel(id: 'a4', studentId: 'test-student', date: now.subtract(const Duration(days: 5)), adherenceScore: 0.8),
        PlanAdherenceModel(id: 'a5', studentId: 'test-student', date: now.subtract(const Duration(days: 4)), adherenceScore: 0.2),
        PlanAdherenceModel(id: 'a6', studentId: 'test-student', date: now.subtract(const Duration(days: 3)), adherenceScore: 0.9),
        PlanAdherenceModel(id: 'a7', studentId: 'test-student', date: now.subtract(const Duration(days: 2)), adherenceScore: 0.9),
        PlanAdherenceModel(id: 'a8', studentId: 'test-student', date: now.subtract(const Duration(days: 1)), adherenceScore: 0.9),
        PlanAdherenceModel(id: 'a9', studentId: 'test-student', date: now, adherenceScore: 0.9),
      ]);

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(adherenceSummaryProvider('test-student').future);
      expect(data.currentStreak, 4);
      expect(data.bestStreak, 4);
    });

    test('currentStreak counts consecutive days ending yesterday', () async {
      final now = DateTime.now().dateOnly;
      final service = _FakePlannerService();
      // 5 consecutive good days, no session recorded today yet.
      service.setAdherenceRecords([
        for (var i = 5; i >= 1; i--)
          PlanAdherenceModel(
            id: 'a$i',
            studentId: 'test-student',
            date: now.subtract(Duration(days: i)),
            adherenceScore: 0.9,
          ),
      ]);

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(adherenceSummaryProvider('test-student').future);
      expect(data.currentStreak, 5);
    });

    test('currentStreak counts a day once across several same-day records', () async {
      final now = DateTime.now().dateOnly;
      final service = _FakePlannerService();
      // Good yesterday, two sessions (two records) today.
      service.setAdherenceRecords([
        PlanAdherenceModel(id: 'a1', studentId: 'test-student',
            date: now.subtract(const Duration(days: 1)), adherenceScore: 0.9),
        PlanAdherenceModel(id: 'a2', studentId: 'test-student',
            date: now, adherenceScore: 0.9),
        PlanAdherenceModel(id: 'a3', studentId: 'test-student',
            date: now, adherenceScore: 0.8),
      ]);

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(adherenceSummaryProvider('test-student').future);
      expect(data.currentStreak, 2);
      expect(data.totalDays, 2);
    });

    test('bestStreak counts days, not records', () async {
      final now = DateTime.now().dateOnly;
      final service = _FakePlannerService();
      // Two good sessions on a single day.
      service.setAdherenceRecords([
        PlanAdherenceModel(id: 'a1', studentId: 'test-student',
            date: now, adherenceScore: 0.9),
        PlanAdherenceModel(id: 'a2', studentId: 'test-student',
            date: now, adherenceScore: 0.9),
      ]);

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(adherenceSummaryProvider('test-student').future);
      expect(data.bestStreak, 1);
      expect(data.totalDays, 1);
    });

    test('bestStreak breaks on gap days', () async {
      final now = DateTime.now().dateOnly;
      final service = _FakePlannerService();
      // Good day, inactive day, good day: best streak is 1 day.
      service.setAdherenceRecords([
        PlanAdherenceModel(id: 'a1', studentId: 'test-student',
            date: now.subtract(const Duration(days: 2)), adherenceScore: 0.9),
        PlanAdherenceModel(id: 'a2', studentId: 'test-student',
            date: now, adherenceScore: 0.9),
      ]);

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(adherenceSummaryProvider('test-student').future);
      expect(data.bestStreak, 1);
      expect(data.currentStreak, 1);
    });

    test('averageAdherence weights each day once', () async {
      final now = DateTime.now().dateOnly;
      final service = _FakePlannerService();
      // Day 1: one record (0.9). Day 2: two records averaging 0.3.
      // Day-weighted mean: (0.9 + 0.3) / 2 = 0.6.
      service.setAdherenceRecords([
        PlanAdherenceModel(id: 'a1', studentId: 'test-student',
            date: now.subtract(const Duration(days: 1)), adherenceScore: 0.9),
        PlanAdherenceModel(id: 'a2', studentId: 'test-student',
            date: now, adherenceScore: 0.3),
        PlanAdherenceModel(id: 'a3', studentId: 'test-student',
            date: now, adherenceScore: 0.3),
      ]);

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(adherenceSummaryProvider('test-student').future);
      expect(data.totalDays, 2);
      expect(data.averageAdherence, closeTo(0.6, 0.0001));
    });

    test('currentStreak and bestStreak survive a spring-forward transition',
        () async {
      // Europe/Berlin springs forward on 2026-03-29, so that
      // calendar day is only 23h long. Elapsed-time arithmetic
      // between the calendar midnights loses an hour and
      // truncates the day difference by one: the streak walk
      // broke after today and the best-streak run test failed
      // across the transition day.
      final service = _FakePlannerService();
      service.setAdherenceRecords([
        for (final day in [28, 29, 30, 31])
          PlanAdherenceModel(
            id: 'a$day',
            studentId: 'test-student',
            date: DateTime(2026, 3, day, 10, 0),
            adherenceScore: 0.9,
          ),
      ]);

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
          clockProvider.overrideWithValue(_FixedClock(DateTime(2026, 3, 31, 12, 0))),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(adherenceSummaryProvider('test-student').future);
      expect(data.currentStreak, 4);
      expect(data.bestStreak, 4);
    });

    test('currentStreak ending yesterday survives a spring-forward transition',
        () async {
      // Good streak on Mar 28-30 spanning the 2026-03-29
      // spring-forward, no session recorded today (Mar 31).
      // The first accepted day is yesterday (one calendar day
      // back), which elapsed-time arithmetic miscounts as zero
      // days back and breaks the walk.
      final service = _FakePlannerService();
      service.setAdherenceRecords([
        for (final day in [28, 29, 30])
          PlanAdherenceModel(
            id: 'a$day',
            studentId: 'test-student',
            date: DateTime(2026, 3, day, 10, 0),
            adherenceScore: 0.9,
          ),
      ]);

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
          clockProvider.overrideWithValue(_FixedClock(DateTime(2026, 3, 31, 12, 0))),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(adherenceSummaryProvider('test-student').future);
      expect(data.currentStreak, 3);
    });

    test('weeklyTrend shows every day across a spring-forward transition',
        () async {
      // `now.subtract(Duration(days: i))` spans an absolute
      // 24h×i, which lands on 23:00 of the target calendar day
      // for every i whose span contains the 2026-03-29 transition
      // and therefore matches no adherence record.
      final service = _FakePlannerService();
      service.setAdherenceRecords([
        for (final day in [25, 26, 27, 28, 29, 30, 31])
          PlanAdherenceModel(
            id: 'a$day',
            studentId: 'test-student',
            date: DateTime(2026, 3, day, 10, 0),
            adherenceScore: 0.9,
          ),
      ]);

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
          clockProvider.overrideWithValue(_FixedClock(DateTime(2026, 3, 31, 12, 0))),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(adherenceSummaryProvider('test-student').future);
      expect(data.weeklyTrend, hasLength(7));
      for (final score in data.weeklyTrend) {
        expect(score, closeTo(0.9, 0.0001));
      }
    });

    test('weeklyTrend shows every day across a fall-back transition',
        () async {
      // Europe/Berlin falls back on 2026-10-25, so that calendar
      // day is 25h long and a 24h×i span lands on 01:00 of the
      // target calendar day, matching no adherence record.
      final service = _FakePlannerService();
      service.setAdherenceRecords([
        for (final day in [20, 21, 22, 23, 24, 25, 26])
          PlanAdherenceModel(
            id: 'b$day',
            studentId: 'test-student',
            date: DateTime(2026, 10, day, 10, 0),
            adherenceScore: 0.8,
          ),
      ]);

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
          clockProvider.overrideWithValue(_FixedClock(DateTime(2026, 10, 26, 12, 0))),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(adherenceSummaryProvider('test-student').future);
      expect(data.weeklyTrend, hasLength(7));
      for (final score in data.weeklyTrend) {
        expect(score, closeTo(0.8, 0.0001));
      }
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
