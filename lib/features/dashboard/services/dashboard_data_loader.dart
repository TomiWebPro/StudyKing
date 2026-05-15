import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/features/planner/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';

class DashboardData {
  final List<MasteryState> allMastery;
  final Map<String, dynamic>? snapshot;
  final Map<String, dynamic>? overallStats;
  final List<Map<String, dynamic>> weeklyTrend;
  final List<Map<String, dynamic>> badges;
  final Map<String, dynamic>? focusTodayStats;
  final double averageAdherence;
  final double weeklyAdherence;
  final Map<String, String> topicNameCache;

  DashboardData({
    this.allMastery = const [],
    this.snapshot,
    this.overallStats,
    this.weeklyTrend = const [],
    this.badges = const [],
    this.focusTodayStats,
    this.averageAdherence = 0.0,
    this.weeklyAdherence = 0.0,
    this.topicNameCache = const {},
  });
}

class DashboardDataLoader {
  final MasteryGraphService masteryService;
  final StudyProgressTracker tracker;
  final InstrumentationService instrumentation;
  final TopicRepository topicRepo;
  final SessionRepository sessionRepo;
  final PlanAdherenceRepository adherenceRepo;
  final String studentId;

  DashboardDataLoader({
    required this.masteryService,
    required this.tracker,
    required this.instrumentation,
    required this.topicRepo,
    required this.sessionRepo,
    required this.adherenceRepo,
    required this.studentId,
  });

  Future<DashboardData> load() async {
    await instrumentation.init();
    await topicRepo.init();
    await adherenceRepo.init();

    Map<String, dynamic>? focusTodayStats;
    try {
      final todaySessions = await sessionRepo.getByDate(DateTime.now());
      final focusToday = todaySessions.where((s) => s.type == SessionType.focus).toList();
      if (focusToday.isNotEmpty) {
        final totalMs = focusToday.fold<int>(0, (sum, s) => sum + s.actualDurationMs);
        focusTodayStats = {
          'totalMs': totalMs,
          'totalSeconds': totalMs ~/ 1000,
          'completedSessions': focusToday.where((s) => s.completed).length,
          'totalSessions': focusToday.length,
          'plannedMinutes': focusToday.fold<int>(0, (sum, s) => sum + (s.plannedDurationMinutes ?? 0)),
          'hours': (totalMs / 3600000).toStringAsFixed(1),
        };
      }
    } catch (_) {}

    List<MasteryState> allMastery = [];
    final masteryResult = await masteryService.getAllTopicMastery(studentId);
    if (masteryResult.isSuccess) {
      allMastery = masteryResult.data!;
    }

    Map<String, dynamic>? snapshot;
    final snapshotResult = await masteryService.getMasterySnapshot(studentId);
    if (snapshotResult.isSuccess) {
      snapshot = snapshotResult.data;
    }

    final overallStats = await tracker.getOverallStats(studentId);
    final weeklyTrend = await tracker.getWeeklyTrend(8, studentId: studentId);
    final badges = await tracker.getBadges(studentId);
    final averageAdherence = await adherenceRepo.getAverageAdherence(studentId);
    final weeklyRecords = await adherenceRepo.getWeekly(studentId);
    final weeklyAdherence = weeklyRecords.isEmpty
        ? 0.0
        : weeklyRecords.fold<double>(0.0, (sum, r) => sum + r.adherenceScore) /
            weeklyRecords.length;

    final topicNameCache = <String, String>{};
    for (final state in allMastery) {
      if (!topicNameCache.containsKey(state.topicId)) {
        try {
          final topic = await topicRepo.get(state.topicId);
          topicNameCache[state.topicId] = topic?.title ?? state.topicId;
        } catch (_) {
          topicNameCache[state.topicId] = state.topicId;
        }
      }
    }

    return DashboardData(
      allMastery: allMastery,
      snapshot: snapshot,
      overallStats: overallStats,
      weeklyTrend: weeklyTrend,
      badges: badges,
      focusTodayStats: focusTodayStats,
      averageAdherence: averageAdherence,
      weeklyAdherence: weeklyAdherence,
      topicNameCache: topicNameCache,
    );
  }
}
