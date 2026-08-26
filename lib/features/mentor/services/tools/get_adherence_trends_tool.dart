import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/core/services/student_id_service.dart';

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
    final days = (args['days'] as num?)?.toInt() ?? 14;
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

    final avgAdherence = records.fold<double>(0.0, (s, m) => s + m.adherenceScore) /
        records.length;

    final lowAdherenceDays = records
        .where((m) => m.adherenceScore < 0.5)
        .map((m) => _formatDate(m.date))
        .toList();

    final missedDays = records.where((m) => m.adherenceScore == 0.0).length;

    final perDayBreakdown = records.reversed.map((m) => {
          'date': _formatDate(m.date),
          'plannedMinutes': m.plannedMinutes,
          'actualMinutes': m.actualMinutes,
          'plannedQuestions': m.plannedQuestions,
          'actualQuestions': m.actualQuestions,
          'adherence': m.adherenceScore,
        }).toList();

    final weeklyAdherence = _computeWeeklyBuckets(records);

    final trend = _computeTrend(records);

    final recommendation = _buildRecommendation(trend, avgAdherence, lowAdherenceDays.length, missedDays);

    return {
      'averageAdherence': double.parse(avgAdherence.toStringAsFixed(2)),
      'trend': trend,
      'lowAdherenceDays': lowAdherenceDays,
      'missedDays': missedDays,
      'totalDays': records.length,
      'perDayBreakdown': perDayBreakdown,
      'weeklyAdherence': weeklyAdherence,
      'recommendation': recommendation,
    };
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static List<double> _computeWeeklyBuckets(List<dynamic> records) {
    if (records.isEmpty) return [];

    final sorted = [...records]..sort((a, b) => a.date.compareTo(b.date));
    final buckets = <double>[];
    const bucketSize = 7;

    for (var i = 0; i < sorted.length; i += bucketSize) {
      final end = (i + bucketSize).clamp(0, sorted.length);
      final chunk = sorted.sublist(i, end);
      final avg = chunk.fold<double>(0.0, (s, m) => s + m.adherenceScore) /
          chunk.length;
      buckets.add(double.parse(avg.toStringAsFixed(2)));
    }
    return buckets;
  }

  static String _computeTrend(List<dynamic> records) {
    if (records.length < 4) return 'insufficient_data';

    final sorted = [...records]..sort((a, b) => a.date.compareTo(b.date));
    final mid = sorted.length ~/ 2;
    final firstHalf = sorted.sublist(0, mid);
    final secondHalf = sorted.sublist(mid);

    final firstAvg =
        firstHalf.fold<double>(0.0, (s, m) => s + m.adherenceScore) /
            firstHalf.length;
    final secondAvg =
        secondHalf.fold<double>(0.0, (s, m) => s + m.adherenceScore) /
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
