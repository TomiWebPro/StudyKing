import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'planner_providers.dart' show plannerServiceProvider;

class PlanProgressData {
  final int plannedMinutesToday;
  final int actualMinutesToday;
  final int plannedQuestionsToday;
  final int actualQuestionsToday;
  final double todayProgress;
  final int totalPlanDays;
  final int completedDays;
  final double cumulativeProgress;
  final List<DailyProgress> weeklyProgress;

  const PlanProgressData({
    this.plannedMinutesToday = 0,
    this.actualMinutesToday = 0,
    this.plannedQuestionsToday = 0,
    this.actualQuestionsToday = 0,
    this.todayProgress = 0.0,
    this.totalPlanDays = 0,
    this.completedDays = 0,
    this.cumulativeProgress = 0.0,
    this.weeklyProgress = const [],
  });
}

class DailyProgress {
  final DateTime date;
  final int plannedMinutes;
  final int actualMinutes;

  const DailyProgress({
    required this.date,
    this.plannedMinutes = 0,
    this.actualMinutes = 0,
  });
}

final planProgressProvider = FutureProvider<PlanProgressData>((ref) async {
  final service = ref.watch(plannerServiceProvider);
  final planResult = await service.loadExistingPlan();
  final plan = planResult.data;
  if (plan == null) return const PlanProgressData();

  final now = DateTime.now();
  final todayStart = now.dateOnly;

  int plannedMinutesToday = 0;
  int plannedQuestionsToday = 0;
  for (final day in plan.dailyPlans) {
    final dDay = day.date.dateOnly;
    if (dDay == todayStart) {
      plannedMinutesToday = day.targetMinutes;
      plannedQuestionsToday = day.targetQuestions;
      break;
    }
  }

  final metricsResult = await service.getAdherenceMetrics();
  final metrics = metricsResult.data ?? <String, int>{};
  final actualMinutesToday = metrics['actualMinutesToday'] as int;
  final actualQuestionsToday = metrics['actualQuestionsToday'] as int;

  final todayProgress = plannedMinutesToday > 0
      ? (actualMinutesToday / plannedMinutesToday).clamp(0.0, 1.5)
      : 0.0;

  final adherenceRecordsResult = await service.getAdherenceRecords();
  final adherenceRecords = adherenceRecordsResult.data ?? [];

  final weeklyProgress = <DailyProgress>[];
  for (var i = 6; i >= 0; i--) {
    final day = todayStart.subtract(Duration(days: i));
    var pMin = 0;
    var aMin = 0;
    for (final dp in plan.dailyPlans) {
      final dDay = dp.date.dateOnly;
      if (dDay == day) {
        pMin = dp.targetMinutes;
        break;
      }
    }
    for (final r in adherenceRecords) {
      final rDay = r.date.dateOnly;
      if (rDay == day) {
        aMin += r.actualMinutes;
      }
    }
    weeklyProgress.add(DailyProgress(
      date: day,
      plannedMinutes: pMin,
      actualMinutes: aMin,
    ));
  }

  final completedDays = plan.dailyPlans.where((d) {
    if (d.isRestDay) return true;
    for (final r in adherenceRecords) {
      final rDay = r.date.dateOnly;
      final dDay = d.date.dateOnly;
      if (rDay == dDay && r.adherenceScore >= 0.5) return true;
    }
    return false;
  }).length;

  final totalPlanDays = plan.dailyPlans.length;
  final cumulativeProgress = totalPlanDays > 0 ? completedDays / totalPlanDays : 0.0;

  return PlanProgressData(
    plannedMinutesToday: plannedMinutesToday,
    actualMinutesToday: actualMinutesToday,
    plannedQuestionsToday: plannedQuestionsToday,
    actualQuestionsToday: actualQuestionsToday,
    todayProgress: todayProgress,
    totalPlanDays: totalPlanDays,
    completedDays: completedDays,
    cumulativeProgress: cumulativeProgress,
    weeklyProgress: weeklyProgress,
  );
});
