import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'planner_providers.dart' show plannerServiceProvider;

final _logger = const Logger('AdherenceProviders');

class AdherenceSummaryData {
  final double averageAdherence;
  final int totalDays;
  final int completedDays;
  final int lowAdherenceDays;
  final int currentStreak;
  final int bestStreak;
  final List<double> weeklyTrend;

  const AdherenceSummaryData({
    this.averageAdherence = 0.0,
    this.totalDays = 0,
    this.completedDays = 0,
    this.lowAdherenceDays = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.weeklyTrend = const [],
  });
}

final adherenceSummaryProvider =
    FutureProvider.family<AdherenceSummaryData, String>((ref, studentId) async {
  final service = ref.watch(plannerServiceProvider);
  try {
    final recordsResult = await service.getAdherenceRecords();
    final records = recordsResult.data ?? [];
    if (records.isEmpty) {
      return const AdherenceSummaryData();
    }

    final totalDays = records.length;
    final completedDays = records.where((r) => r.adherenceScore >= 0.5).length;
    final lowAdherenceDays =
        records.where((r) => r.adherenceScore < 0.3).length;
    final averageAdherence = totalDays > 0
        ? records.fold<double>(0, (sum, r) => sum + r.adherenceScore) /
            totalDays
        : 0.0;

    final sortedByDate = List<PlanAdherenceModel>.from(records)
      ..sort((a, b) => a.date.compareTo(b.date));

    int currentStreak = 0;
    int bestStreak = 0;
    int tempStreak = 0;
    final now = DateTime.now().dateOnly;

    for (final record in sortedByDate.reversed) {
      if (record.adherenceScore >= 0.5) {
        final daysDiff = now.difference(record.date.dateOnly).inDays;
        if (currentStreak == 0 && daysDiff <= 1) {
          currentStreak++;
          tempStreak = currentStreak;
        } else if (daysDiff == currentStreak) {
          currentStreak++;
          tempStreak = currentStreak;
        } else {
          break;
        }
      } else {
        break;
      }
    }

    for (final record in sortedByDate) {
      if (record.adherenceScore >= 0.5) {
        tempStreak++;
        if (tempStreak > bestStreak) {
          bestStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
    }

    final trend = <double>[];
    for (var i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayRecords = records.where(
        (r) => r.date.dateOnly == day,
      );
      if (dayRecords.isNotEmpty) {
        final sum = dayRecords.fold<double>(
          0,
          (sum, r) => sum + r.adherenceScore,
        );
        trend.add(sum / dayRecords.length);
      } else {
        trend.add(0.0);
      }
    }

    return AdherenceSummaryData(
      averageAdherence: averageAdherence,
      totalDays: totalDays,
      completedDays: completedDays,
      lowAdherenceDays: lowAdherenceDays,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      weeklyTrend: trend,
    );
  } catch (e) {
    _logger.w('Failed to compute adherence summary', e);
    return const AdherenceSummaryData();
  }
});

class TodayAdherenceData {
  final int actualMinutes;
  final int actualQuestions;
  final int plannedMinutes;
  final int plannedQuestions;
  final double progress;

  const TodayAdherenceData({
    this.actualMinutes = 0,
    this.actualQuestions = 0,
    this.plannedMinutes = 0,
    this.plannedQuestions = 0,
    this.progress = 0.0,
  });
}

final todayAdherenceProvider =
    FutureProvider.family<TodayAdherenceData, String>((ref, studentId) async {
  final service = ref.watch(plannerServiceProvider);
  try {
    final metricsResult = await service.getAdherenceMetrics();
    final metrics = metricsResult.data ?? {};
    final actualMinutes = metrics['actualMinutesToday'] ?? 0;
    final actualQuestions = metrics['actualQuestionsToday'] ?? 0;

    final planResult = await service.loadExistingPlan();
    final plan = planResult.data;
    if (plan == null) {
      return TodayAdherenceData(
        actualMinutes: actualMinutes,
        actualQuestions: actualQuestions,
      );
    }

    final now = DateTime.now().dateOnly;
    int plannedMinutes = 0;
    int plannedQuestions = 0;
    for (final day in plan.dailyPlans) {
      if (day.date.dateOnly == now) {
        plannedMinutes = day.targetMinutes;
        plannedQuestions = day.targetQuestions;
        break;
      }
    }

    final progress = plannedMinutes > 0
        ? (actualMinutes / plannedMinutes).clamp(0.0, 1.5)
        : 0.0;

    return TodayAdherenceData(
      actualMinutes: actualMinutes,
      actualQuestions: actualQuestions,
      plannedMinutes: plannedMinutes,
      plannedQuestions: plannedQuestions,
      progress: progress,
    );
  } catch (e) {
    _logger.w('Failed to load today adherence', e);
    return const TodayAdherenceData();
  }
});
