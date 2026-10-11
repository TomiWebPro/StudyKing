import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/study_utils.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';

/// Per-day adherence aggregate. Adherence records are created per finished
/// session (see `PersonalLearningPlanService.recordDailyAdherence`), so a day
/// can have several records; all metrics must be derived from one entry per
/// calendar day to avoid weighting multi-session days multiple times.
class _DayAdherence {
  final DateTime date;
  final int plannedQuestions;
  final int actualQuestions;
  final int plannedMinutes;
  final int actualMinutes;
  final double adherence;

  const _DayAdherence({
    required this.date,
    required this.plannedQuestions,
    required this.actualQuestions,
    required this.plannedMinutes,
    required this.actualMinutes,
    required this.adherence,
  });
}

class GetAdherenceTrendsTool extends AgentTool {
  final PlanAdherenceOrchestrator _orchestrator;
  final StudentIdService _studentIdService;

  GetAdherenceTrendsTool({
    required PlanAdherenceOrchestrator orchestrator,
    required StudentIdService studentIdService,
  })  : _orchestrator = orchestrator,
        _studentIdService = studentIdService;

  @override
  String get name => 'get_adherence_trends';

  @override
  String get description =>
      'Get detailed adherence data and trends for the study plan over a period of time. '
      'Use this to answer questions like "How am I doing?", "Am I keeping up?", '
      '"Which days did I miss?", or "Is my adherence improving or declining?".';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'days': {
            'type': 'integer',
            'description':
                'Number of past days to analyze (default 14). Use 7 for weekly, 30 for monthly trends.',
          },
        },
        'required': [],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final days = AgentTool.intArg(args, 'days') ?? 14;
    final studentId = _studentIdService.getStudentId().data ?? '';

    final repo = _orchestrator.adherenceRepository;
    await repo.init();

    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    final recordsResult = await repo.getByDateRange(studentId, start, now);
    final records = recordsResult.data ?? [];

    if (records.isEmpty) {
      return {
        'averageAdherence': 0.0,
        'trend': 'insufficient_data',
        'lowAdherenceDays': <String>[],
        'missedDays': 0,
        'totalDays': 0,
        'perDayBreakdown': <Map<String, dynamic>>[],
        'weeklyAdherence': <double>[],
        'recommendation': 'No adherence data available for the past $days days.',
      };
    }

    final dailySummaries = _aggregateByDay(records);

    final avgAdherence = dailySummaries.fold<double>(0.0, (s, d) => s + d.adherence) /
        dailySummaries.length;

    final lowAdherenceDays = dailySummaries
        .where((d) => d.adherence < 0.5)
        .map((d) => _formatDate(d.date))
        .toList();

    final missedDays = dailySummaries.where((d) => d.adherence == 0.0).length;

    final perDayBreakdown = dailySummaries.reversed.map((d) => {
          'date': _formatDate(d.date),
          'plannedMinutes': d.plannedMinutes,
          'actualMinutes': d.actualMinutes,
          'plannedQuestions': d.plannedQuestions,
          'actualQuestions': d.actualQuestions,
          'adherence': double.parse(d.adherence.toStringAsFixed(2)),
        }).toList();

    final weeklyAdherence = _computeWeeklyBuckets(dailySummaries);

    final trend = _computeTrend(dailySummaries);

    final recommendation = _buildRecommendation(trend, avgAdherence, lowAdherenceDays.length, missedDays);

    return {
      'averageAdherence': double.parse(avgAdherence.toStringAsFixed(2)),
      'trend': trend,
      'lowAdherenceDays': lowAdherenceDays,
      'missedDays': missedDays,
      'totalDays': dailySummaries.length,
      'perDayBreakdown': perDayBreakdown,
      'weeklyAdherence': weeklyAdherence,
      'recommendation': recommendation,
    };
  }

  /// Collapses the raw records into one entry per calendar day. Same-day
  /// sessions are summed so a day's adherence reflects the day's total
  /// effort against that day's plan targets (each day counts once).
  static List<_DayAdherence> _aggregateByDay(List<PlanAdherenceModel> records) {
    final byDay = <DateTime, List<PlanAdherenceModel>>{};
    for (final record in records) {
      final day = record.date.dateOnly;
      byDay.putIfAbsent(day, () => []).add(record);
    }

    final days = byDay.entries.map((entry) {
      final dayRecords = entry.value;
      // Plan targets are constant within a day; the latest record
      // carries the day's final snapshot. Actuals are summed across
      // the day's sessions.
      final plannedQuestions = dayRecords.last.plannedQuestions;
      final plannedMinutes = dayRecords.last.plannedMinutes;
      final actualQuestions = dayRecords.fold<int>(
        0,
        (sum, m) => sum + m.actualQuestions,
      );
      final actualMinutes = dayRecords.fold<int>(
        0,
        (sum, m) => sum + m.actualMinutes,
      );
      return _DayAdherence(
        date: entry.key,
        plannedQuestions: plannedQuestions,
        actualQuestions: actualQuestions,
        plannedMinutes: plannedMinutes,
        actualMinutes: actualMinutes,
        adherence: calculateAdherenceScore(
          plannedQuestions: plannedQuestions,
          actualQuestions: actualQuestions,
          plannedMinutes: plannedMinutes,
          actualMinutes: actualMinutes,
        ),
      );
    }).toList();

    days.sort((a, b) => a.date.compareTo(b.date));
    return days;
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Averages one calendar week per bucket (weeks start on Monday,
  /// matching the rest of the app) instead of chunks of 7 records,
  /// so a bucket never straddles two calendar weeks.
  static List<double> _computeWeeklyBuckets(List<_DayAdherence> days) {
    if (days.isEmpty) return [];

    final sorted = [...days]..sort((a, b) => a.date.compareTo(b.date));
    final buckets = <double>[];
    DateTime? currentWeekStart;
    var sum = 0.0;
    var count = 0;

    for (final day in sorted) {
      final weekStart = _startOfWeek(day.date);
      if (currentWeekStart == null) {
        currentWeekStart = weekStart;
      } else if (!weekStart.isAtSameMomentAs(currentWeekStart)) {
        buckets.add(double.parse((sum / count).toStringAsFixed(2)));
        currentWeekStart = weekStart;
        sum = 0.0;
        count = 0;
      }
      sum += day.adherence;
      count++;
    }
    if (count > 0) {
      buckets.add(double.parse((sum / count).toStringAsFixed(2)));
    }
    return buckets;
  }

  static DateTime _startOfWeek(DateTime date) {
    final day = date.dateOnly;
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  static String _computeTrend(List<_DayAdherence> days) {
    if (days.length < 4) return 'insufficient_data';

    final sorted = [...days]..sort((a, b) => a.date.compareTo(b.date));
    final mid = sorted.length ~/ 2;
    final firstHalf = sorted.sublist(0, mid);
    final secondHalf = sorted.sublist(mid);

    final firstAvg =
        firstHalf.fold<double>(0.0, (s, d) => s + d.adherence) /
            firstHalf.length;
    final secondAvg =
        secondHalf.fold<double>(0.0, (s, d) => s + d.adherence) /
            secondHalf.length;

    final diff = secondAvg - firstAvg;
    if (diff > 0.1) return 'improving';
    if (diff < -0.1) return 'declining';
    return 'steady';
  }

  static String _buildRecommendation(
      String trend, double avg, int lowDays, int missedDays) {
    if (trend == 'insufficient_data') {
      return 'Keep studying to build a trend analysis.';
    }
    if (trend == 'declining') {
      if (missedDays > 0) {
        return 'Your adherence has been declining with $missedDays missed day(s). '
            'Consider redistributing missed workload or adjusting your plan.';
      }
      return 'Your adherence trend is declining. Try to maintain consistent study sessions.';
    }
    if (trend == 'improving') {
      return 'Great job! Your adherence is improving. Keep up the consistent effort.';
    }
    if (lowDays >= 3) {
      return 'Your adherence is steady but you have $lowDays low-adherence day(s). '
          'Try to stay above 50% adherence each day.';
    }
    return 'Your adherence is steady. Keep maintaining your current study routine.';
  }
}
