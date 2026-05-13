import 'dart:async';
import '../services/study_progress_tracker.dart';
import '../services/mastery_graph_service.dart';
import '../data/repositories/plan_repository.dart';
import '../services/instrumentation_service.dart';

class EngagementScheduler {
  final StudyProgressTracker _tracker;
  final MasteryGraphService _masteryService;
  final PlanRepository _planRepository;

  Timer? _dailyTimer;
  bool _isInitialized = false;

  EngagementScheduler({
    required StudyProgressTracker tracker,
    required MasteryGraphService masteryService,
    PlanRepository? planRepository,
  })  : _tracker = tracker,
        _masteryService = masteryService,
        _planRepository = planRepository ?? PlanRepository();

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    _scheduleDailyCheck();
  }

  void _scheduleDailyCheck() {
    final now = DateTime.now();
    final nextCheck = DateTime(now.year, now.month, now.day, 9, 0);
    final delay = nextCheck.isAfter(now)
        ? nextCheck.difference(now)
        : nextCheck.add(const Duration(days: 1)).difference(now);
    _dailyTimer = Timer(delay, _runDailyChecks);
  }

  Future<void> _runDailyChecks() async {
    _scheduleDailyCheck();
  }

  Future<List<EngagementNudge>> getOverworkNudge(String studentId) async {
    final stats = await _tracker.getOverallStats(studentId);
    final totalHoursStr = stats['totalStudyTimeHours'] as String? ?? '0';
    final totalHours = double.tryParse(totalHoursStr) ?? 0;
    if (totalHours > 4) {
      return [EngagementNudge(
        type: NudgeType.overwork,
        message: 'You have studied ${totalHours.toStringAsFixed(1)} hours today. Consider taking a break!',
        severity: NudgeSeverity.medium,
      )];
    }
    return [];
  }

  Future<List<EngagementNudge>> getRevisionNudges(String studentId) async {
    final nudges = <EngagementNudge>[];
    final weakResult = await _masteryService.getTopicsNeedingReview(studentId);
    if (weakResult.isSuccess) {
      for (final state in weakResult.data!) {
        final daysSince = DateTime.now().difference(state.lastAttempt).inDays;
        if (daysSince >= 3) {
          nudges.add(EngagementNudge(
            type: NudgeType.revision,
            message: 'It has been $daysSince days since you practiced "${state.topicId}". Time for a review!',
            severity: daysSince >= 7 ? NudgeSeverity.high : NudgeSeverity.low,
            topicId: state.topicId,
          ));
        }
      }
    }
    return nudges;
  }

  Future<List<EngagementNudge>> getPlanAdjustmentNudge(String studentId) async {
    final nudges = <EngagementNudge>[];
    try {
      await _planRepository.init();
      final plan = await _planRepository.loadPlan(studentId);
      if (plan != null) {
        final consecutiveLow = _countConsecutiveLowAdherence(plan, studentId);
        if (consecutiveLow >= 3) {
          nudges.add(EngagementNudge(
            type: NudgeType.planAdjustment,
            message: 'You have had $consecutiveLow days of low plan adherence. Would you like to adjust your study plan?',
            severity: NudgeSeverity.medium,
          ));
        }
      }
    } catch (_) {}
    return nudges;
  }

  int _countConsecutiveLowAdherence(dynamic plan, String studentId) {
    try {
      final instrumentation = InstrumentationService()..init();
      final metrics = instrumentation.getAdherenceHistory(studentId);
      final sorted = List<PlanAdherenceMetric>.from(metrics)
        ..sort((a, b) => b.date.compareTo(a.date));
      int count = 0;
      for (final m in sorted) {
        if (m.adherenceScore < 0.5) {
          count++;
        } else {
          break;
        }
      }
      return count;
    } catch (_) {}
    return 0;
  }

  Future<String> getWeeklyDigest(String studentId) async {
    final stats = await _tracker.getOverallStats(studentId);
    final accuracy = stats['accuracy'] as int? ?? 0;
    final totalHours = stats['totalStudyTimeHours'] as String? ?? '0';
    final weeklyActivity = stats['weeklyActivity'] as int? ?? 0;
    final badges = await _tracker.getBadges(studentId);
    final weakResult = await _masteryService.getWeakTopics(studentId);
    final weakCount = weakResult.isSuccess ? weakResult.data!.length : 0;
    return 'Weekly Digest: $weeklyActivity questions answered, $accuracy% accuracy, $totalHours hours studied, $weakCount weak areas, ${badges.length} badges earned.';
  }

  void dispose() {
    _dailyTimer?.cancel();
  }
}

enum NudgeType { overwork, revision, planAdjustment, lessonReminder }
enum NudgeSeverity { low, medium, high }

class EngagementNudge {
  final NudgeType type;
  final String message;
  final NudgeSeverity severity;
  final String? topicId;

  EngagementNudge({
    required this.type,
    required this.message,
    required this.severity,
    this.topicId,
  });
}
