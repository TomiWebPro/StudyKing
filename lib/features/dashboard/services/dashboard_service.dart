import '../../../core/errors/result.dart';
import '../../../core/data/models/session_model.dart';
import '../../../core/services/mastery_graph_service.dart';
import '../../../core/services/study_progress_tracker.dart';
import '../../../core/services/plan_adapter.dart';
import '../../../features/practice/data/models/mastery_state_model.dart';
import '../../../features/sessions/data/repositories/session_repository.dart';
import '../../../features/planner/data/repositories/plan_adherence_repository.dart';
import '../../../features/subjects/data/repositories/topic_repository.dart';
import '../../../features/practice/data/repositories/attempt_repository.dart';
import '../data/models/dashboard_models.dart';

class DashboardService {
  final MasteryGraphService _masteryService;
  final StudyProgressTracker _progressTracker;
  final PlanAdapter _planAdapter;
  final SessionRepository _sessionRepo;
  final PlanAdherenceRepository _adherenceRepo;
  final TopicRepository _topicRepo;

  DashboardService({
    MasteryGraphService? masteryService,
    StudyProgressTracker? progressTracker,
    PlanAdapter? planAdapter,
    SessionRepository? sessionRepo,
    PlanAdherenceRepository? adherenceRepo,
    TopicRepository? topicRepo,
  })  : _masteryService = masteryService ?? MasteryGraphService(),
        _progressTracker = progressTracker ??
            StudyProgressTracker(
              attemptRepo: AttemptRepository(),
              masteryService: MasteryGraphService(),
              sessionRepo: sessionRepo,
            ),
        _planAdapter = planAdapter ?? PlanAdapter(),
        _sessionRepo = sessionRepo ?? SessionRepository(),
        _adherenceRepo = adherenceRepo ?? PlanAdherenceRepository(),
        _topicRepo = topicRepo ?? TopicRepository();

  Future<void> init() async {
    await Future.wait([
      _masteryService.init(),
      _planAdapter.adherenceRepository.init(),
      _topicRepo.init(),
      _sessionRepo.init(),
    ]);
  }

  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) async {
    return _masteryService.getAllTopicMastery(studentId);
  }

  Future<Result<MasterySnapshot?>> getMasterySnapshot(String studentId) async {
    final result = await _masteryService.getMasterySnapshot(studentId);
    if (result.isSuccess && result.data != null) {
      return Result.success(MasterySnapshot.fromMap(result.data!));
    }
    return Result.success(null);
  }

  Future<OverallStats?> getOverallStats(String studentId) async {
    final stats = await _progressTracker.getOverallStats(studentId);
    return OverallStats.fromMap(stats);
  }

  Future<List<WeeklyTrendEntry>> getWeeklyTrend(String studentId) async {
    final trend = await _progressTracker.getWeeklyTrend(8, studentId: studentId);
    return trend.map((m) => WeeklyTrendEntry.fromMap(m)).toList();
  }

  Future<FocusTodayStats?> getFocusStats() async {
    try {
      final todayResult = await _sessionRepo.getByDate(DateTime.now());
      final todaySessions = todayResult.data ?? [];
      final focusToday = todaySessions.where((s) => s.type == SessionType.focus).toList();
      if (focusToday.isEmpty) return null;
      final totalSeconds = focusToday.fold<int>(0, (sum, s) => sum + s.actualDurationMs) ~/ 1000;
      return FocusTodayStats.fromMap({
        'totalSeconds': totalSeconds,
        'completedSessions': focusToday.where((s) => s.completed).length,
        'totalSessions': focusToday.length,
        'plannedMinutes': focusToday.fold<int>(0, (sum, s) => sum + (s.plannedDurationMinutes ?? 0)),
      });
    } catch (_) {
      return null;
    }
  }

  Future<AdherenceData> getAdherenceData(String studentId) async {
    final averageAdherence = await _adherenceRepo.getAverageAdherence(studentId);
    final weeklyRecords = await _adherenceRepo.getWeekly(studentId);
    final weeklyAdherence = weeklyRecords.isEmpty
        ? 0.0
        : weeklyRecords.fold<double>(0.0, (sum, r) => sum + r.adherenceScore) /
            weeklyRecords.length;
    return AdherenceData(
      averageAdherence: averageAdherence,
      weeklyAdherence: weeklyAdherence,
    );
  }

  Future<Map<String, String>> getTopicNamesMap(String studentId) async {
    final allMasteryResult = await _masteryService.getAllTopicMastery(studentId);
    final allMastery = allMasteryResult.isSuccess ? allMasteryResult.data! : <MasteryState>[];
    final allTopics = await _topicRepo.getAll();
    final topicMap = <String, String>{};
    for (final topic in allTopics) {
      topicMap[topic.id] = topic.title;
    }
    for (final state in allMastery) {
      topicMap.putIfAbsent(state.topicId, () => state.topicId);
    }
    return topicMap;
  }

  Future<List<BadgeDisplay>> getBadges(String studentId) async {
    try {
      final badges = await _progressTracker.getBadges(studentId);
      return badges.map((b) {
        return BadgeDisplay(
          name: (b['name'] as String?) ?? '',
          description: (b['description'] as String?) ?? '',
          category: (b['category'] as String?) ?? 'general',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}