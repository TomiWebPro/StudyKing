import 'package:flutter/material.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/core/services/settings_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/core/utils/date_utils.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/utils/study_utils.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class MentorContextBuilder {

  final StudyProgressTracker _progressTracker;
  final MasteryGraphService _masteryService;
  final PlannerService _plannerService;
  final SessionRepository _sessionRepository;
  final String _localeName;

  MentorContextBuilder({
    required StudyProgressTracker progressTracker,
    required MasteryGraphService masteryService,
    required PlannerService plannerService,
    required SessionRepository sessionRepository,
    required String localeName,
  })  : _progressTracker = progressTracker,
        _masteryService = masteryService,
        _plannerService = plannerService,
        _sessionRepository = sessionRepository,
        _localeName = localeName;

  Future<String> buildContextPrompt() async {
    final statsResult = await _progressTracker.getOverallStats(_plannerService.studentId);
    final stats = statsResult.data ?? <String, dynamic>{};
    final weakTopics = (await _loadWeakTopics()).data ?? [];
    final plan = (await _loadPlan()).data;
    final roadmaps = (await _loadRoadmaps()).data ?? [];
    final pendingActions = (await _loadPendingActions()).data ?? [];
    final upcomingLessons = (await loadUpcomingLessons()).data ?? [];
    final missedLessons = (await _loadMissedLessons()).data ?? [];
    final adherenceDeviation = (await _loadAdherence()).data;
    final todayMinutes = await _getTodayStudyMinutes();
    final dailyCap = SettingsService.getDailyCapMinutes();
    final consecutiveDays = await _getConsecutiveStudyDays();
    final daysSinceLastActivity = StudentIdService().getDaysSinceLastActivity();
    final l10n = lookupAppLocalizations(Locale(_localeName));
    final bullet = l10n.mentorBulletPoint;

    final buffer = StringBuffer();
    buffer.writeln(l10n.mentorContextHeader);
    buffer.writeln('$bullet${l10n.mentorContextTotalAttempts(stats['totalAttempts'] as int? ?? 0)}');
    buffer.writeln('$bullet${l10n.mentorContextCorrectAttempts(stats['correctAttempts'] as int? ?? 0)}');
    buffer.writeln('$bullet${l10n.mentorContextAccuracy('${stats['accuracy']}')}');
    buffer.writeln('$bullet${l10n.mentorContextTopicsStudied(stats['topicsStudied'] as int? ?? 0)}');
    buffer.writeln('$bullet${l10n.mentorContextWeeklyActivity(stats['weeklyActivity'] as int? ?? 0)}');
    buffer.writeln('$bullet${l10n.mentorContextTotalStudyTime('${stats['totalStudyTimeHours']}')}');

    if (plan != null) {
      buffer.writeln('$bullet${l10n.mentorContextPlanPhase(_getPlanDay(plan), plan.dailyPlans.length)}');
      if (adherenceDeviation != null) {
        buffer.writeln('$bullet${l10n.mentorContextPlanAdherence(formatDecimal(adherenceDeviation.averageAdherence, _localeName, minFractionDigits: 1, maxFractionDigits: 1))}');
        if (adherenceDeviation.consecutiveLowDays > 0) {
          buffer.writeln('$bullet${l10n.mentorContextLowAdherence(adherenceDeviation.consecutiveLowDays)}');
        }
      }
    }

    if (daysSinceLastActivity >= 0) {
      buffer.writeln('$bullet${l10n.mentorContextDaysSinceActivity(daysSinceLastActivity)}');
      if (daysSinceLastActivity >= 3) {
        buffer.writeln(l10n.mentorContextWelcomeBack(daysSinceLastActivity));
      }
    }

    if (missedLessons.isNotEmpty) {
      buffer.writeln('$bullet Missed lessons: ${missedLessons.length}');
      for (final lesson in missedLessons.take(3)) {
        final title = lesson.tutorMetadata?.topicTitle ?? lesson.topicId ?? l10n.unknown;
        buffer.writeln('  $bullet$title');
      }
    }

    if (plan != null && daysSinceLastActivity >= 3) {
      final metadata = plan.metadata ?? {};
      final lastRedistribution = metadata['lastRedistributionDate'] as String?;
      if (lastRedistribution != null) {
        buffer.writeln('$bullet Redistribution was applied for the absence.');
        final remainingDays = plan.dailyPlans.where((d) =>
          d.date.dateOnly.isAfter(DateTime.now().dateOnly) && !d.isRestDay
        ).length;
        final extraPerDay = (plan.targetMinutesPerDay * 0.5).ceil();
        if (remainingDays > 0) {
          buffer.writeln('$bullet Extra minutes per day: ${extraPerDay.toInt()} min over $remainingDays remaining days');
        }
      }
    }

    if (roadmaps.isNotEmpty) {
      final activeRoadmaps = roadmaps.where((r) => r.status == 'active').toList();
      if (activeRoadmaps.isNotEmpty) {
        buffer.writeln('$bullet${l10n.mentorContextActiveRoadmaps(activeRoadmaps.length)}');
        for (final roadmap in activeRoadmaps.take(2)) {
          final completedMilestones = roadmap.milestones.where((m) => m.isCompleted).length;
          final nearest = roadmap.milestones.where((m) => !m.isCompleted).firstOrNull;
          buffer.writeln('  $bullet${l10n.mentorContextRoadmapProgress(roadmap.goal, completedMilestones, roadmap.milestones.length)}');
          if (nearest != null) {
            buffer.writeln('    ${l10n.mentorContextNextMilestone(nearest.title, localizedDateTime(nearest.deadline, _localeName))}');
          }
        }
      }
    }

    if (pendingActions.isNotEmpty) {
      buffer.writeln('$bullet${l10n.mentorContextPendingActions(pendingActions.length)}');
      for (final action in pendingActions.take(3)) {
        buffer.writeln('  $bullet${l10n.mentorContextPendingActionItem(action.actionType, action.topicTitle)}');
      }
    }

    if (upcomingLessons.isNotEmpty) {
      final shownCount = upcomingLessons.length > 3 ? 3 : upcomingLessons.length;
      buffer.writeln('$bullet${l10n.mentorContextUpcomingLessons(shownCount)}');
      for (final lesson in upcomingLessons.take(3)) {
        final title = lesson.tutorMetadata?.topicTitle ?? lesson.topicId ?? l10n.unknown;
        buffer.writeln('  $bullet${l10n.mentorContextLessonItem(title, localizedDateTime(lesson.startTime, _localeName), lesson.plannedDurationMinutes ?? 30)}');
      }
    }

    if (weakTopics.isNotEmpty) {
      buffer.writeln('$bullet${l10n.mentorContextWeakTopics}');
      for (final topic in weakTopics.take(5)) {
        buffer.writeln('  $bullet${l10n.mentorContextWeakTopicItem(topic.topicId, formatPercent(topic.accuracy * 100, _localeName, minFractionDigits: 0))}');
      }
    }

    if (todayMinutes > 0) {
      buffer.writeln('$bullet${l10n.mentorContextStudyTimeToday(todayMinutes)}');
      if (dailyCap > 0 && todayMinutes > dailyCap) {
        buffer.writeln('$bullet${l10n.mentorContextCapExceeded(dailyCap, todayMinutes - dailyCap)}');
      } else if (dailyCap > 0) {
        buffer.writeln('$bullet${l10n.mentorContextCapRemaining(dailyCap, dailyCap - todayMinutes)}');
      }
    }

    if (consecutiveDays >= 7) {
      buffer.writeln('$bullet${l10n.mentorContextStreak(consecutiveDays)}');
    } else if (consecutiveDays >= 3) {
      buffer.writeln('$bullet${l10n.mentorContextStreakGood(consecutiveDays)}');
    }

    final recentResult = await _sessionRepository.getByDate(DateTime.now());
    if (recentResult.isSuccess) {
      final todaySessions = recentResult.data!;
      if (todaySessions.isNotEmpty) {
        buffer.writeln('$bullet${l10n.mentorContextSessionsToday(todaySessions.length)}');
        final lateNight = todaySessions.where((s) => s.startTime.hour >= lateNightHour).toList();
        if (lateNight.isNotEmpty) {
          buffer.writeln('$bullet${l10n.mentorContextLateNightWarning(lateNight.length)}');
        }
      }
    }

    return buffer.toString();
  }

  Future<Result<List<Session>>> loadUpcomingLessons() async {
    return _plannerService.getScheduledLessons();
  }

  Future<Result<List<MasteryState>>> _loadWeakTopics() async {
    return Result.capture(() async {
      final result = await _masteryService.getWeakTopics(_plannerService.studentId);
      return result.isSuccess ? result.data! : [];
    }, context: '_loadWeakTopics');
  }

  Future<Result<PersonalLearningPlan?>> _loadPlan() async {
    return _plannerService.loadExistingPlan();
  }

  Future<Result<List<RoadmapModel>>> _loadRoadmaps() async {
    return _plannerService.loadRoadmaps();
  }

  Future<Result<List<PendingActionModel>>> _loadPendingActions() async {
    return _plannerService.loadPendingActions();
  }

  Future<Result<AdherenceDeviation?>> _loadAdherence() async {
    return _plannerService.planOrchestrator.checkAdherence(_plannerService.studentId);
  }

  Future<Result<List<Session>>> _loadMissedLessons() async {
    return _plannerService.getMissedLessons();
  }

  int _getPlanDay(PersonalLearningPlan plan) {
    final now = DateTime.now();
    final today = now.dateOnly;
    for (final day in plan.dailyPlans) {
      final dDay = day.date.dateOnly;
      if (dDay == today) return day.dayNumber;
    }
    return 0;
  }

  Future<int> _getTodayStudyMinutes() async {
    final result = await _sessionRepository.getTodayDurationMs();
    return result.isSuccess ? (result.data! ~/ msPerMinute) : 0;
  }

  Future<int> _getConsecutiveStudyDays() async {
    return _sessionRepository.getConsecutiveStudyDays();
  }
}
