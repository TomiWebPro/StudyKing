import 'dart:async';
import '../services/study_progress_tracker.dart';
import '../services/mastery_graph_service.dart';
import '../services/notification_service.dart';
import '../services/plan_adapter.dart';
import '../data/repositories/plan_adherence_repository.dart';
import '../data/repositories/engagement_nudge_repository.dart';
import '../data/models/engagement_nudge_model.dart';
import '../../features/focus_mode/services/focus_session_service.dart';

class EngagementSchedulerConfig {
  final int checkHour;
  final int checkMinute;
  final List<String> studentIds;

  const EngagementSchedulerConfig({
    this.checkHour = 9,
    this.checkMinute = 0,
    this.studentIds = const ['default'],
  });

  Duration get nextCheckDelay {
    final now = DateTime.now();
    final nextCheck = DateTime(now.year, now.month, now.day, checkHour, checkMinute);
    return nextCheck.isAfter(now)
        ? nextCheck.difference(now)
        : nextCheck.add(const Duration(days: 1)).difference(now);
  }
}

class EngagementScheduler {
  final StudyProgressTracker _tracker;
  final MasteryGraphService _masteryService;
  final NotificationService _notificationService;
  final EngagementNudgeRepository _nudgeRepository;
  final PlanAdherenceRepository _adherenceRepository;
  final PlanAdapter? _planAdapter;
  final FocusSessionService? _focusSessionService;
  final EngagementSchedulerConfig _config;

  Timer? _dailyTimer;
  bool _isInitialized = false;
  int _notificationIdCounter = 1000;

  EngagementScheduler({
    required StudyProgressTracker tracker,
    required MasteryGraphService masteryService,
    NotificationService? notificationService,
    EngagementNudgeRepository? nudgeRepository,
    PlanAdherenceRepository? adherenceRepository,
    PlanAdapter? planAdapter,
    FocusSessionService? focusSessionService,
    EngagementSchedulerConfig? config,
  })  :         _tracker = tracker,
        _masteryService = masteryService,
        _notificationService = notificationService ?? NotificationService(),
        _nudgeRepository = nudgeRepository ?? EngagementNudgeRepository(),
        _adherenceRepository = adherenceRepository ?? PlanAdherenceRepository(),
        _planAdapter = planAdapter,
        _focusSessionService = focusSessionService,
        _config = config ?? const EngagementSchedulerConfig();

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await _notificationService.init();
    await _nudgeRepository.init();
    await _adherenceRepository.init();
    _scheduleDailyCheck();
  }

  void _scheduleDailyCheck() {
    _dailyTimer = Timer(_config.nextCheckDelay, _runDailyChecks);
  }

  Future<void> _runDailyChecks() async {
    _scheduleDailyCheck();
    for (final studentId in _config.studentIds) {
      await _sendNudgeNotifications(studentId);
    }
  }

  Future<void> _sendNudgeNotifications(String studentId) async {
    try {
      final overworkNudges = await getOverworkNudge(studentId);
      for (final nudge in overworkNudges) {
        final model = EngagementNudgeModel(
          id: 'overwork_${DateTime.now().millisecondsSinceEpoch}_$studentId',
          studentId: studentId,
          nudgeType: NudgeType.overwork.name,
          message: nudge.message,
          severity: nudge.severity.name,
        );
        await _nudgeRepository.save(model);
        await _notificationService.showOverworkWarning(
          id: _notificationIdCounter++,
          hoursStudied: double.tryParse(
                  nudge.message.replaceAll(RegExp(r'[^0-9.]'), '')) ??
              0,
        );
      }
    } catch (_) {}

    try {
      final revisionNudges = await getRevisionNudges(studentId);
      for (final nudge in revisionNudges) {
        final model = EngagementNudgeModel(
          id: 'revision_${DateTime.now().millisecondsSinceEpoch}_$studentId',
          studentId: studentId,
          nudgeType: NudgeType.revision.name,
          message: nudge.message,
          severity: nudge.severity.name,
          topicId: nudge.topicId,
        );
        await _nudgeRepository.save(model);
        if (nudge.topicId != null) {
          final daysMatch = RegExp(r'(\d+)').firstMatch(nudge.message);
          final days = daysMatch != null ? int.parse(daysMatch.group(1)!) : 3;
          await _notificationService.showRevisionNudge(
            id: _notificationIdCounter++,
            topicName: nudge.topicId!,
            daysSinceLastPractice: days,
          );
        }
      }
    } catch (_) {}

    try {
      final planNudges = await getPlanAdjustmentNudge(studentId);
      for (final nudge in planNudges) {
        final model = EngagementNudgeModel(
          id: 'plan_${DateTime.now().millisecondsSinceEpoch}_$studentId',
          studentId: studentId,
          nudgeType: NudgeType.planAdjustment.name,
          message: nudge.message,
          severity: nudge.severity.name,
        );
        await _nudgeRepository.save(model);
        final daysMatch = RegExp(r'(\d+)').firstMatch(nudge.message);
        final days = daysMatch != null ? int.parse(daysMatch.group(1)!) : 3;
        await _notificationService.showPlanAdjustmentSuggestion(
          id: _notificationIdCounter++,
          consecutiveLowDays: days,
        );
      }
    } catch (_) {}

    try {
      final weakResult = await _masteryService.getWeakTopics(studentId);
      if (weakResult.isSuccess && weakResult.data!.isNotEmpty) {
        await _notificationService.showLowMasteryWarning(
          id: _notificationIdCounter++,
          weakTopics: weakResult.data!.map((s) => s.topicId).toList(),
        );
      }
    } catch (_) {}

    if (_planAdapter != null) {
      try {
        final deviation = await _planAdapter.checkAdherence(studentId);
        if (deviation.isSuccess && deviation.data!.requiresRegeneration) {
          final model = EngagementNudgeModel(
            id: 'adp_reg_${DateTime.now().millisecondsSinceEpoch}_$studentId',
            studentId: studentId,
            nudgeType: NudgeType.autoRegeneration.name,
            message: deviation.data!.message,
            severity: deviation.data!.requiresEscalation
                ? NudgeSeverity.high.name
                : NudgeSeverity.medium.name,
          );
          await _nudgeRepository.save(model);
        }
      } catch (_) {}
    }
  }

  Future<List<EngagementNudge>> getOverworkNudge(String studentId) async {
    double totalHours = 0;
    try {
      final stats = await _tracker.getOverallStats(studentId);
      totalHours = double.tryParse(stats['totalStudyTimeHours'] as String? ?? '0') ?? 0;
    } catch (_) {}

    if (_focusSessionService != null) {
      try {
        final focusSeconds = await _focusSessionService.getTodayFocusSeconds();
        final focusHours = focusSeconds / 3600;
        if (focusHours > totalHours) {
          totalHours = focusHours;
        }
      } catch (_) {}
    }

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
      final consecutiveLow = await _adherenceRepository.getConsecutiveLowAdherenceDays(studentId);
      if (consecutiveLow >= 3) {
        nudges.add(EngagementNudge(
          type: NudgeType.planAdjustment,
          message: 'You have had $consecutiveLow days of low plan adherence. Would you like to adjust your study plan?',
          severity: NudgeSeverity.medium,
        ));
      }
    } catch (_) {}
    return nudges;
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

  Future<List<EngagementNudgeModel>> getNudgeHistory(String studentId) async {
    return _nudgeRepository.getByStudent(studentId);
  }

  void dispose() {
    _dailyTimer?.cancel();
  }
}

enum NudgeType { overwork, revision, planAdjustment, lessonReminder, autoRegeneration }
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
