import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../core/errors/result.dart';
import '../../../core/data/models/session_model.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/study_utils.dart';
import '../../../core/services/mastery_graph_service.dart';
import '../../../core/services/study_progress_tracker.dart';
import '../../../core/services/plan_adherence_orchestrator.dart';
import '../../../core/data/models/mastery_state_model.dart';
import '../../../core/data/repositories/session_repository.dart';
import '../../../core/data/repositories/plan_adherence_repository.dart';
import '../../../core/data/repositories/topic_repository.dart';
import '../../../core/data/repositories/attempt_repository.dart';
import '../data/models/dashboard_models.dart';

AppLocalizations _dashboardServiceDefaultL10n() {
  const logger = Logger('DashboardService');
  logger.w('l10n fallback to English in DashboardService constructor');
  return lookupAppLocalizations(const Locale('en'));
}

class DashboardService {
  static final Logger _logger = const Logger('DashboardService');
  final MasteryGraphService _masteryService;
  final StudyProgressTracker _progressTracker;
  final PlanAdherenceOrchestrator _planOrchestrator;
  final SessionRepository _sessionRepo;
  final PlanAdherenceRepository _adherenceRepo;
  final TopicRepository _topicRepo;

  DashboardService({
    MasteryGraphService? masteryService,
    StudyProgressTracker? progressTracker,
    PlanAdherenceOrchestrator? planOrchestrator,
    SessionRepository? sessionRepo,
    PlanAdherenceRepository? adherenceRepo,
    TopicRepository? topicRepo,
    AppLocalizations? l10n,
  })  : _masteryService = masteryService ?? MasteryGraphService(),
        _progressTracker = progressTracker ??
            StudyProgressTracker(
              attemptRepo: AttemptRepository(),
              masteryService: MasteryGraphService(),
              sessionRepo: sessionRepo,
              l10n: l10n ?? _dashboardServiceDefaultL10n(),
            ),
        _planOrchestrator = planOrchestrator ?? PlanAdherenceOrchestrator(),
        _sessionRepo = sessionRepo ?? SessionRepository(),
        _adherenceRepo = adherenceRepo ?? PlanAdherenceRepository(),
        _topicRepo = topicRepo ?? TopicRepository();

  Future<Result<void>> init() async {
    try {
      await Future.wait([
        _masteryService.init(),
        _planOrchestrator.adherenceRepository.init(),
        _topicRepo.init(),
        _sessionRepo.init(),
      ]);
      return Result.success(null);
    } catch (e) {
      _logger.w('DashboardService.init failed', e);
      return Result.failure(e.toString());
    }
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

  Future<Result<OverallStats?>> getOverallStats(String studentId) async {
    try {
      final statsResult = await _progressTracker.getOverallStats(studentId);
      final stats = statsResult.data ?? <String, dynamic>{};
      return Result.success(OverallStats.fromMap(stats));
    } catch (e) {
      _logger.w('getOverallStats failed: $e');
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<WeeklyTrendEntry>>> getWeeklyTrend(String studentId) async {
    try {
      final trendResult = await _progressTracker.getWeeklyTrend(8, studentId: studentId);
      final trend = trendResult.data ?? [];
      return Result.success(trend.map((m) => WeeklyTrendEntry.fromMap(m)).toList());
    } catch (e) {
      _logger.w('getWeeklyTrend failed: $e');
      return Result.failure(e.toString());
    }
  }

  Future<Result<FocusTodayStats?>> getFocusStats() async {
    try {
      final todayResult = await _sessionRepo.getByDate(DateTime.now());
      final todaySessions = todayResult.data ?? [];
      final focusToday = todaySessions.where((s) => s.type == SessionType.focus).toList();
      if (focusToday.isEmpty) return Result.success(null);
      final totalSeconds = focusToday.fold<int>(0, (sum, s) => sum + s.actualDurationMs) ~/ msPerSecond;
      return Result.success(FocusTodayStats.fromMap({
        'totalSeconds': totalSeconds,
        'completedSessions': focusToday.where((s) => s.completed).length,
        'totalSessions': focusToday.length,
        'plannedMinutes': focusToday.fold<int>(0, (sum, s) => sum + (s.plannedDurationMinutes ?? 0)),
      }));
    } catch (e) {
      _logger.w('Failed to get focus stats: $e');
      return Result.failure(e.toString());
    }
  }

  Future<Result<AdherenceData>> getAdherenceData(String studentId) async {
    try {
      final avgResult = await _adherenceRepo.getAverageAdherence(studentId);
      final averageAdherence = avgResult.data ?? 0.0;
      final weeklyResult = await _adherenceRepo.getWeekly(studentId);
      final weeklyRecords = weeklyResult.data ?? [];
      final weeklyAdherence = weeklyRecords.isEmpty
          ? 0.0
          : weeklyRecords.fold<double>(0.0, (sum, r) => sum + r.adherenceScore) /
              weeklyRecords.length;
      return Result.success(AdherenceData(
        averageAdherence: averageAdherence,
        weeklyAdherence: weeklyAdherence,
      ));
    } catch (e) {
      _logger.w('getAdherenceData failed: $e');
      return Result.failure(e.toString());
    }
  }

  Future<Result<Map<String, String>>> getTopicNamesMap(String studentId) async {
    try {
      final allMasteryResult = await _masteryService.getAllTopicMastery(studentId);
      final allMastery = allMasteryResult.isSuccess ? allMasteryResult.data! : <MasteryState>[];
      final allTopicsResult = await _topicRepo.getAll();
      final allTopics = allTopicsResult.data ?? [];
      final topicMap = <String, String>{};
      for (final topic in allTopics) {
        topicMap[topic.id] = topic.title;
      }
      for (final state in allMastery) {
        topicMap.putIfAbsent(state.topicId, () => state.topicId);
      }
      return Result.success(topicMap);
    } catch (e) {
      _logger.w('getTopicNamesMap failed: $e');
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<BadgeDisplay>>> getBadges(String studentId) async {
    try {
      final badgesResult = await _progressTracker.getBadges(studentId);
      final badges = badgesResult.data ?? [];
      return Result.success(badges.map((b) {
        return BadgeDisplay(
          name: (b['name'] as String?) ?? '',
          description: (b['description'] as String?) ?? '',
          category: (b['category'] as String?) ?? 'general',
        );
      }).toList());
    } catch (e) {
      _logger.w('Failed to get badges: $e');
      return Result.failure(e.toString());
    }
  }
}