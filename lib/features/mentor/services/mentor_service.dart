import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/plan_adapter.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/features/planner/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/mentor/data/models/progress_report.dart';
import 'package:studyking/features/mentor/data/models/mentor_action.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class MentorService {
  final Logger _logger = const Logger('MentorService');
  final DatabaseService _database;
  final LlmService _llmService;
  final MasteryGraphService _masteryService;
  final StudyProgressTracker _progressTracker;
  final String _modelId;
  final ConversationMemory _memory;
  final String _studentId;
  final PendingActionRepository _pendingActionRepo;
  final PlannerService _plannerService;
  final EngagementNudgeRepository _nudgeRepo;
  final SessionRepository _sessionRepository;
  final String _localeName;

  MentorService({
    required DatabaseService database,
    required LlmService llmService,
    required MasteryGraphService masteryService,
    required StudyProgressTracker progressTracker,
    required String modelId,
    required String studentId,
    required PlannerService plannerService,
    PendingActionRepository? pendingActionRepo,
    EngagementNudgeRepository? nudgeRepo,
    SessionRepository? sessionRepository,
    ConversationRepository? conversationRepo,
    String localeName = 'en',
  })  : _database = database,
        _llmService = llmService,
        _masteryService = masteryService,
        _progressTracker = progressTracker,
        _modelId = modelId,
        _studentId = studentId,
        _plannerService = plannerService,
        _pendingActionRepo = pendingActionRepo ?? PendingActionRepository(),
        _nudgeRepo = nudgeRepo ?? EngagementNudgeRepository(),
        _sessionRepository = sessionRepository ?? SessionRepository(),
        _localeName = localeName,
        _memory = ConversationMemory(
          maxTurns: 50,
          sessionId: 'mentor_$studentId',
          repository: conversationRepo,
        );

  ConversationMemory get memory => _memory;

  Future<void> initialize() async {
    await _memory.loadFromRepository();
    await _nudgeRepo.init();
  }

  Stream<String> chat(String message) async* {
    _memory.addUserMessage(message);

    final context = await _buildContextPrompt();
    final fullPrompt = '$context\n\nStudent: $message';

    final buffer = StringBuffer();
    await for (final chunk in _llmService.chatStream(
      message: fullPrompt,
      modelId: _modelId,
      memory: _memory,
      systemPrompt: _mentorSystemPrompt(),
    )) {
      buffer.write(chunk);
      yield chunk;
    }

    _memory.addAssistantMessage(buffer.toString());

    final response = buffer.toString();
    await _checkAndHandlePlanningIntent(response, message);
  }

  Future<String> _buildContextPrompt() async {
    final stats = await _progressTracker.getOverallStats(_studentId);
    final weakTopics = await _loadWeakTopics();
    final plan = await _loadPlan();
    final roadmaps = await _loadRoadmaps();
    final pendingActions = await _loadPendingActions();
    final upcomingLessons = await _loadUpcomingLessons();
    final adherenceDeviation = await _loadAdherence();
    final todayMinutes = await _getTodayStudyMinutes();
    final dailyCap = await _getDailyCapMinutes();
    final consecutiveDays = await _getConsecutiveStudyDays();

    final buffer = StringBuffer();
    // Note: Context labels are in invariant English regardless of user locale.
    // This context data is fed to the LLM. The labels are a data-formatting
    // convention, not user-facing text.
    buffer.writeln('Current student context:');
    buffer.writeln('- Total attempts: ${stats['totalAttempts']}');
    buffer.writeln('- Correct attempts: ${stats['correctAttempts']}');
    buffer.writeln('- Accuracy: ${stats['accuracy']}%');
    buffer.writeln('- Topics studied: ${stats['topicsStudied']}');
    buffer.writeln('- Weekly activity: ${stats['weeklyActivity']} attempts');
    buffer.writeln('- Total study time: ${stats['totalStudyTimeHours']} hours');

    if (plan != null) {
      buffer.writeln('- Plan exists: current phase (day ${_getPlanDay(plan)} of ${plan.dailyPlans.length})');
      if (adherenceDeviation != null) {
        buffer.writeln('- Plan adherence: ${adherenceDeviation.averageAdherence.toStringAsFixed(1)}%'); // LLM-facing: invariant period format OK
        if (adherenceDeviation.consecutiveLowDays > 0) {
          buffer.writeln('- Low adherence for ${adherenceDeviation.consecutiveLowDays} consecutive days');
        }
      }
    }

    if (roadmaps.isNotEmpty) {
      final activeRoadmaps = roadmaps.where((r) => r.status == 'active').toList();
      if (activeRoadmaps.isNotEmpty) {
        buffer.writeln('- Active roadmaps: ${activeRoadmaps.length}');
        for (final roadmap in activeRoadmaps.take(2)) {
          final completedMilestones = roadmap.milestones.where((m) => m.isCompleted).length;
          final nearest = roadmap.milestones.where((m) => !m.isCompleted).firstOrNull;
          buffer.writeln('  * "${roadmap.goal}": $completedMilestones/${roadmap.milestones.length} milestones completed');
          if (nearest != null) {
            buffer.writeln('    Next milestone: "${nearest.title}" due ${DateFormat.yMd(_localeName).format(nearest.deadline.toLocal())}');
          }
        }
      }
    }

    if (pendingActions.isNotEmpty) {
      buffer.writeln('- Pending actions awaiting decision: ${pendingActions.length}');
      for (final action in pendingActions.take(3)) {
        buffer.writeln('  * ${action.actionType}: ${action.topicTitle}');
      }
    }

    if (upcomingLessons.isNotEmpty) {
      buffer.writeln('- Upcoming lessons (next ${upcomingLessons.length > 3 ? 3 : upcomingLessons.length}):');
      for (final lesson in upcomingLessons.take(3)) {
        final title = lesson.tutorMetadata?.topicTitle ?? lesson.topicId ?? 'Unknown';
        buffer.writeln('  * "$title" at ${DateFormat('y-MM-dd HH:mm', _localeName).format(lesson.startTime.toLocal())} (${lesson.plannedDurationMinutes ?? 30}min)');
      }
    }

    if (weakTopics.isNotEmpty) {
      buffer.writeln('- Weak topics needing attention:');
      for (final topic in weakTopics.take(5)) {
        buffer.writeln('  * ${topic.topicId} (accuracy: ${(topic.accuracy * 100).toStringAsFixed(0)}%)'); // LLM-facing: invariant period format OK
      }
    }

    if (todayMinutes > 0) {
      buffer.writeln('- Today\'s study time: $todayMinutes minutes');
      if (dailyCap > 0 && todayMinutes > dailyCap) {
        buffer.writeln('- WARNING: Daily study cap ($dailyCap min) exceeded by ${todayMinutes - dailyCap} minutes');
      } else if (dailyCap > 0) {
        buffer.writeln('- Daily cap: $dailyCap minutes (${dailyCap - todayMinutes} min remaining)');
      }
    }

    if (consecutiveDays >= 7) {
      buffer.writeln('- Congratulations! $consecutiveDays day study streak!');
    } else if (consecutiveDays >= 3) {
      buffer.writeln('- $consecutiveDays consecutive study days - good consistency!');
    }

    final recentResult = await _sessionRepository.getByDate(DateTime.now());
    if (recentResult.isSuccess) {
      final todaySessions = recentResult.data!;
      if (todaySessions.isNotEmpty) {
        buffer.writeln('- Sessions today: ${todaySessions.length}');
        final lateNight = todaySessions.where((s) => s.startTime.hour >= 22).toList();
        if (lateNight.isNotEmpty) {
          buffer.writeln('- WARNING: ${lateNight.length} session(s) started after 10 PM (late-night study detected)');
        }
      }
    }

    return buffer.toString();
  }

  String _mentorSystemPrompt() {
    final l10n = lookupAppLocalizations(Locale(_localeName));
    return l10n.mentorSystemPrompt;
  }

  String _extractTopic(String message) {
    final lower = message.toLowerCase();
    final keywords = _localeName == 'es'
        ? ['sobre ', 'para ', 'de ', 'estudiar ', 'aprender ', 'repasar ', 'practicar ', 'acerca de ', 'acerca ']
        : ['about ', 'for ', 'on ', 'study ', 'learn ', 'review ', 'practice '];
    for (final kw in keywords) {
      final idx = lower.indexOf(kw);
      if (idx != -1) {
        final after = message.substring(idx + kw.length).trim();
        final end = after.indexOf(RegExp(r'[.,!?\n]'));
        return end != -1 ? after.substring(0, end).trim() : after;
      }
    }
    final topicKeywords = _localeName == 'es'
        ? ['tema ', 'materia ', 'lección ', 'asignatura ']
        : ['topic ', 'subject ', 'lesson '];
    for (final kw in topicKeywords) {
      final idx = lower.indexOf(kw);
      if (idx != -1) {
        final after = message.substring(idx + kw.length).trim();
        final end = after.indexOf(RegExp(r'[.,!?\n]'));
        return end != -1 ? after.substring(0, end).trim() : after;
      }
    }
    return 'general';
  }

  Future<List<MasteryState>> _loadWeakTopics() async {
    try {
      final result = await _masteryService.getWeakTopics(_studentId);
      return result.isSuccess ? result.data! : [];
    } catch (e) {
      _logger.w('Failed to load weak topics', e);
      return [];
    }
  }

  Future<PersonalLearningPlan?> _loadPlan() async {
    try {
      return await _plannerService.loadExistingPlan();
    } catch (e) {
      _logger.w('Failed to load existing plan', e);
      return null;
    }
  }

  Future<List<RoadmapModel>> _loadRoadmaps() async {
    try {
      return await _plannerService.loadRoadmaps();
    } catch (e) {
      _logger.w('Failed to load roadmaps', e);
      return [];
    }
  }

  Future<List<PendingActionModel>> _loadPendingActions() async {
    try {
      return await _plannerService.loadPendingActions();
    } catch (e) {
      _logger.w('Failed to load pending actions', e);
      return [];
    }
  }

  Future<List<Session>> _loadUpcomingLessons() async {
    try {
      return await _plannerService.getScheduledLessons();
    } catch (e) {
      _logger.w('Failed to load upcoming lessons', e);
      return [];
    }
  }

  Future<AdherenceDeviation?> _loadAdherence() async {
    try {
      return await _plannerService.checkAdherence();
    } catch (e) {
      _logger.w('Failed to load adherence', e);
      return null;
    }
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
    return result.isSuccess ? (result.data! ~/ 60000) : 0;
  }

  Future<int> _getDailyCapMinutes() async {
    try {
      final box = await Hive.openBox('settings');
      return box.get('dailyCapMinutes', defaultValue: 0) as int;
    } catch (e) {
      _logger.w('Failed to get daily cap minutes', e);
      return 0;
    }
  }

  Future<int> _getConsecutiveStudyDays() async {
    try {
      final allResult = await _sessionRepository.getAll();
      if (allResult.isFailure) return 0;
      final all = allResult.data!;
      if (all.isEmpty) return 0;
      final studyDays = all.where((s) => s.completed).map((s) =>
        s.startTime.dateOnly
      ).toSet().toList()..sort((a, b) => b.compareTo(a));
      int consecutive = 0;
      final now = DateTime.now();
      final today = now.dateOnly;
      for (var i = 0; i < studyDays.length; i++) {
        final expected = today.subtract(Duration(days: i));
        if (studyDays[i] == expected) {
          consecutive++;
        } else {
          break;
        }
      }
      return consecutive;
    } catch (e) {
      _logger.w('Failed to get consecutive study days', e);
      return 0;
    }
  }

  Future<void> checkWellbeingAndGenerateNudges() async {
    try {
      final todayMinutes = await _getTodayStudyMinutes();
      final dailyCap = await _getDailyCapMinutes();
      final recentResult = await _sessionRepository.getByDate(DateTime.now());

      if (dailyCap > 0 && todayMinutes > dailyCap) {
        final nudge = EngagementNudgeModel(
          id: 'overwork_${DateTime.now().millisecondsSinceEpoch}_$_studentId',
          studentId: _studentId,
          nudgeType: NudgeType.overwork.name,
          message: lookupAppLocalizations(Locale(_localeName)).nudgeOverworkMinutes(todayMinutes, dailyCap),
          severity: NudgeSeverity.medium.name,
        );
        await _nudgeRepo.create(nudge);
        _memory.addSystemMessage(nudge.message);
      }

      if (recentResult.isSuccess) {
        final lateNight = recentResult.data!.where((s) => s.startTime.hour >= 22).toList();
        if (lateNight.isNotEmpty) {
          final nudge = EngagementNudgeModel(
            id: 'wellbeing_${DateTime.now().millisecondsSinceEpoch}_$_studentId',
            studentId: _studentId,
            nudgeType: NudgeType.overwork.name,
            message: lookupAppLocalizations(Locale(_localeName)).nudgeLateNight(lateNight.length),
            severity: NudgeSeverity.low.name,
          );
          await _nudgeRepo.create(nudge);
        }
      }

      final weakResult = await _masteryService.getAtRiskQuestions(_studentId);
      if (weakResult.isSuccess && weakResult.data!.isNotEmpty) {
        final atRiskCount = weakResult.data!.length;
        if (atRiskCount >= 3) {
          final nudge = EngagementNudgeModel(
            id: 'revision_${DateTime.now().millisecondsSinceEpoch}_$_studentId',
            studentId: _studentId,
            nudgeType: NudgeType.revision.name,
            message: lookupAppLocalizations(Locale(_localeName)).nudgeRevisionNeeded(atRiskCount),
            severity: NudgeSeverity.low.name,
          );
          await _nudgeRepo.create(nudge);
        }
      }

      final consecutiveDays = await _getConsecutiveStudyDays();
      if (consecutiveDays >= 7) {
        _memory.addSystemMessage(
          lookupAppLocalizations(Locale(_localeName)).nudgeStreakDays(consecutiveDays)
        );
      } else if (consecutiveDays == 0) {
        final allResult = await _sessionRepository.getAll();
        if (allResult.isSuccess) {
          final lastStudy = allResult.data!.where((s) => s.completed).fold<DateTime?>(
            null, (prev, s) {
              if (prev == null || s.startTime.isAfter(prev)) return s.startTime;
              return prev;
            });
          if (lastStudy != null && DateTime.now().difference(lastStudy).inHours >= 48) {
            _memory.addSystemMessage(
              lookupAppLocalizations(Locale(_localeName)).nudgeInactive48h
            );
          }
        }
      }

      if (dailyCap > 0) {
        final todayNudges = await _nudgeRepo.getTodayCount(_studentId);
        if (todayNudges >= 5) return;
      }
    } catch (e) {
      _logger.w('Failed to check wellbeing: $e');
    }
  }

  Future<void> _checkAndHandlePlanningIntent(
      String response, String originalMessage) async {
    final lower = originalMessage.toLowerCase();
    final hasScheduleIntent = lower.contains('schedule') ||
        lower.contains('reschedule') ||
        lower.contains('programar') ||
        lower.contains('reprogramar') ||
        lower.contains('agendar') ||
        lower.contains('reagendar') ||
        lower.contains('citar');
    final hasPlanIntent = lower.contains('plan') ||
        lower.contains('roadmap') ||
        lower.contains('planificar') ||
        (_localeName == 'es' && (lower.contains('plan') ||
            lower.contains('hoja de ruta') ||
            lower.contains('planificar')));

    if (!hasScheduleIntent && !hasPlanIntent) return;

    if (hasScheduleIntent) {
      await _handleScheduleIntent(originalMessage);
    } else if (hasPlanIntent) {
      await _handlePlanIntent(originalMessage);
    }
  }

  Future<void> _handleScheduleIntent(String originalMessage) async {
    try {
      final topicTitle = _extractTopic(originalMessage);

      String? topicId;
      String? subjectId;
      if (topicTitle.isNotEmpty && topicTitle != 'general') {
        await _database.topicRepository.init();
        final allTopics = await _database.topicRepository.getAll();
        final match = allTopics.where(
          (t) => t.title.toLowerCase().contains(topicTitle.toLowerCase()),
        ).firstOrNull;
        topicId = match?.id;
        subjectId = match?.subjectId;
      }

      final proposedTime = DateTime.now().add(Timeouts.hour);
      final nextHour = DateTime(
        proposedTime.year,
        proposedTime.month,
        proposedTime.day,
        proposedTime.hour,
        0,
      );

      final hasConflict = await _plannerService.hasSchedulingConflict(
        startTime: nextHour,
        durationMinutes: 30,
      );

      if (hasConflict) {
        final existingLessons = await _plannerService.getScheduledLessons();
        final nextFree = _findNextFreeSlot(existingLessons, 30);
        _memory.addSystemMessage(
          lookupAppLocalizations(Locale(_localeName)).mentorScheduleConflict(
            DateFormat('y-MM-dd HH:mm', _localeName).format(nextHour.toLocal()),
            DateFormat('y-MM-dd HH:mm', _localeName).format(nextFree.toLocal()),
          )
        );
        return;
      }

      final success = await _plannerService.scheduleLesson(
        topicId: topicId ?? '',
        topicTitle: topicTitle,
        subjectId: subjectId ?? '',
        scheduledTime: nextHour,
        durationMinutes: 30,
      );

      if (success) {
        _memory.addSystemMessage(
          lookupAppLocalizations(Locale(_localeName)).mentorScheduleSuccess(
            topicTitle,
            DateFormat('y-MM-dd HH:mm', _localeName).format(nextHour.toLocal()),
          )
        );
      } else {
        _memory.addSystemMessage(
          lookupAppLocalizations(Locale(_localeName)).mentorScheduleFail
        );
      }
    } catch (e) {
      _logger.w('Failed to handle schedule intent: $e');
    }
  }

  DateTime _findNextFreeSlot(List<Session> existingLessons, int durationMinutes) {
    final now = DateTime.now();
    var candidate = DateTime(now.year, now.month, now.day, now.hour + 1, 0);
    final sorted = List<Session>.from(existingLessons)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    for (final lesson in sorted) {
      if (lesson.completed || lesson.endTime != null) continue;
      final plannedDur = lesson.plannedDurationMinutes ?? durationMinutes;
      final end = lesson.startTime.add(Duration(minutes: plannedDur));
      if (candidate.isBefore(lesson.startTime) &&
          lesson.startTime.difference(candidate).inMinutes >= durationMinutes) {
        return candidate;
      }
      if (candidate.isBefore(end)) {
        candidate = end;
      }
    }
    return candidate;
  }

  Future<void> _handlePlanIntent(String originalMessage) async {
    try {
      final daysMatch = RegExp(r'(\d+)\s*days?').firstMatch(originalMessage.toLowerCase());
      final days = daysMatch != null ? int.parse(daysMatch.group(1)!) : 30;

      _memory.addSystemMessage(
        lookupAppLocalizations(Locale(_localeName)).mentorPlanDaysPrompt(days)
      );
    } catch (e) {
      _logger.w('Failed to handle plan intent: $e');
    }
  }

  Future<ProgressReport> getProgressReport() async {
    final stats = await _progressTracker.getOverallStats(_studentId);
    final weakResult = await _masteryService.getWeakTopics(_studentId);
    final recommendations = await _progressTracker.getRecommendations(_studentId);
    final badges = await _progressTracker.getBadges(_studentId);

    int completedLessons = 0;
    try {
      final completed = await _database.tutorSessionRepository.getCompletedSessions(_studentId);
      completedLessons = completed.length;
    } catch (e) {
      _logger.w('Failed to fetch completed lessons count: $e');
    }

    return ProgressReport(
      totalAttempts: stats['totalAttempts'] as int,
      correctAttempts: stats['correctAttempts'] as int,
      accuracy: (stats['accuracy'] as num).toDouble(),
      topicsStudied: stats['topicsStudied'] as int,
      completedLessons: completedLessons,
      weeklyActivity: stats['weeklyActivity'] as int,
      totalStudyTimeHours: (stats['totalStudyTimeHours'] as num?)?.toDouble() ?? 0,
      weakTopics: weakResult.isSuccess ? weakResult.data! : [],
      badges: badges,
      recommendations: recommendations,
    );
  }

  Future<MentorAction> suggestNextAction() async {
    final recommendations = await _progressTracker.getRecommendations(_studentId);
    if (recommendations.isNotEmpty) {
      return MentorAction(
        message: recommendations.first['message'] as String,
        type: recommendations.first['type'] as String,
      );
    }

    final l10n = lookupAppLocalizations(Locale(_localeName));
    final subjects = await _database.subjectRepository.getAll();
    if (subjects.isEmpty) {
      return MentorAction(
        message: l10n.mentorNoSubjects,
        type: 'setup',
      );
    }

    return MentorAction(
      message: l10n.mentorDoingWell,
      type: 'generic',
    );
  }

  Future<void> suggestReschedule(String sessionId) async {
    final session = await _database.tutorSessionRepository.getSession(sessionId);
    if (session == null) return;

    final existingLessons = await _plannerService.getScheduledLessons();
    final nextFree = _findNextFreeSlot(
      existingLessons.where((l) => l.id != sessionId).toList(),
      session.plannedDurationMinutes,
    );

    final hasConflict = await _plannerService.hasSchedulingConflict(
      startTime: nextFree,
      durationMinutes: session.plannedDurationMinutes,
      excludeSessionId: sessionId,
    );

    if (hasConflict) {
      _memory.addSystemMessage(
        lookupAppLocalizations(Locale(_localeName)).mentorRescheduleNoFreeSlot(session.topicTitle),
      );
      return;
    }

    final action = PendingActionModel(
      id: 'resched_${DateTime.now().millisecondsSinceEpoch}',
      studentId: _studentId,
      actionType: PendingActionType.reschedule.name,
      topicTitle: session.topicTitle,
      sessionId: sessionId,
      payload: {
        'topicId': session.topicId,
        'subjectId': session.subjectId,
        'scheduledTime': nextFree.toIso8601String(),
        'durationMinutes': session.plannedDurationMinutes,
        'originalSessionStart': session.startTime.toIso8601String(),
      },
    );
    await _pendingActionRepo.init();
    await _pendingActionRepo.create(action);

    _memory.addSystemMessage(
      lookupAppLocalizations(Locale(_localeName)).mentorReschedulePending(
        session.topicTitle,
        DateFormat('y-MM-dd HH:mm', _localeName).format(nextFree.toLocal()),
      )
    );
  }

  Future<List<EngagementNudgeModel>> getRecentNudges({int limit = 10}) async {
    return _nudgeRepo.getRecentByStudent(_studentId, limit: limit);
  }
}
