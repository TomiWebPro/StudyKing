import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'planner_providers.dart' show plannerServiceProvider, clockProvider;

final _logger = const Logger('AdherenceProviders');

/// Calendar-day difference `a - b` in whole days. Both arguments are
/// local calendar midnights; the computation is done on UTC-normalized
/// dates so a DST transition (a 23h or 25h calendar day) cannot shift
/// the result the way elapsed-time `difference().inDays` does.
int _calendarDayDiff(DateTime a, DateTime b) {
  final utcA = DateTime.utc(a.year, a.month, a.day);
  final utcB = DateTime.utc(b.year, b.month, b.day);
  return utcA.difference(utcB).inDays;
}

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

    // Adherence records are created per finished session, so a day
    // can have several records and inactive days none. Aggregate to
    // one mean adherence value per calendar day before computing
    // any day-based stat (matches the weeklyTrend aggregation below).
    final recordsByDay = <DateTime, List<PlanAdherenceModel>>{};
    for (final record in records) {
      recordsByDay.putIfAbsent(record.date.dateOnly, () => []).add(record);
    }
    final dayScores = <DateTime, double>{};
    for (final entry in recordsByDay.entries) {
      final sum = entry.value
          .fold<double>(0, (sum, r) => sum + r.adherenceScore);
      dayScores[entry.key] = sum / entry.value.length;
    }

    final totalDays = dayScores.length;
    final completedDays =
        dayScores.values.where((score) => score >= 0.5).length;
    final lowAdherenceDays =
        dayScores.values.where((score) => score < 0.3).length;
    final averageAdherence = totalDays > 0
        ? dayScores.values.fold<double>(0, (sum, score) => sum + score) /
            totalDays
        : 0.0;

    final sortedDays = dayScores.keys.toList()..sort();
    final now = ref.watch(clockProvider).now().dateOnly;

    // Walk backwards over distinct days while they are consecutive
    // and good. The first accepted day may be today or yesterday
    // (daysDiff <= 1); each older day must sit exactly one day
    // before the previously accepted one.
    int currentStreak = 0;
    int anchorOffset = 0;
    for (var i = sortedDays.length - 1; i >= 0; i--) {
      final day = sortedDays[i];
      final daysDiff = _calendarDayDiff(now, day);
      if (dayScores[day]! < 0.5 || daysDiff < 0) {
        break;
      }
      if (currentStreak == 0) {
        if (daysDiff > 1) {
          break;
        }
        anchorOffset = daysDiff;
        currentStreak = 1;
      } else if (daysDiff == anchorOffset + currentStreak) {
        currentStreak++;
      } else {
        break;
      }
    }

    // Best streak: longest run of consecutive calendar days with
    // adherence >= 0.5 (a gap day breaks the run).
    int bestStreak = 0;
    int runStreak = 0;
    DateTime? previousDay;
    for (final day in sortedDays) {
      if (dayScores[day]! >= 0.5) {
        if (previousDay != null &&
            _calendarDayDiff(day, previousDay) == 1) {
          runStreak++;
        } else {
          runStreak = 1;
        }
        if (runStreak > bestStreak) {
          bestStreak = runStreak;
        }
      } else {
        runStreak = 0;
      }
      previousDay = day;
    }

    final trend = <double>[];
    for (var i = 6; i >= 0; i--) {
      // Calendar-day step: `Duration(days: i)` is an absolute 24h×i
      // span that lands on 23:00/01:00 across a DST transition and
      // can never equal the calendar midnights adherence records are
      // keyed by.
      final day = DateTime(now.year, now.month, now.day - i);
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
