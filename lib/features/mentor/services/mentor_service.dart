import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
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
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/mentor/data/models/progress_report.dart';
import 'package:studyking/features/mentor/data/models/mentor_action.dart';

class MentorService {
  final Logger _logger = const Logger('MentorService');
  static const String _mentorSystemPromptText = 'You are a knowledgeable and encouraging AI mentor for a student. '
      'Your role is to guide their learning journey, provide motivation, '
      'and help them develop effective study habits. '
      'Keep responses concise, supportive, and actionable.';
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

    Result<List<MasteryState>> weakResult;
    try {
      weakResult = await _masteryService.getWeakTopics(_studentId);
    } catch (_) {
      weakResult = Result.success([]);
    }

    PersonalLearningPlan? plan;
    try {
      plan = await _plannerService.loadExistingPlan();
    } catch (_) {}

    List<RoadmapModel> roadmaps;
    try {
      roadmaps = await _plannerService.loadRoadmaps();
    } catch (_) {
      roadmaps = [];
    }

    List<PendingActionModel> pendingActions;
    try {
      pendingActions = await _plannerService.loadPendingActions();
    } catch (_) {
      pendingActions = [];
    }

    List<Session> upcomingLessons;
    try {
      upcomingLessons = await _plannerService.getScheduledLessons();
    } catch (_) {
      upcomingLessons = [];
    }

    AdherenceDeviation? adherenceDeviation;
    try {
      adherenceDeviation = await _plannerService.checkAdherence();
    } catch (_) {}

    final weakTopics = weakResult.isSuccess ? weakResult.data! : <MasteryState>[];
    final todayMinutes = await _getTodayStudyMinutes();
    final dailyCap = await _getDailyCapMinutes();
    final consecutiveDays = await _getConsecutiveStudyDays();

    final buffer = StringBuffer();
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
        buffer.writeln('- Plan adherence: ${adherenceDeviation.averageAdherence.toStringAsFixed(1)}%');
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
            buffer.writeln('    Next milestone: "${nearest.title}" due ${nearest.deadline.toLocal().toString().substring(0, 10)}');
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
        buffer.writeln('  * "$title" at ${lesson.startTime.toLocal().toString().substring(0, 16)} (${lesson.plannedDurationMinutes ?? 30}min)');
      }
    }

    if (weakTopics.isNotEmpty) {
      buffer.writeln('- Weak topics needing attention:');
      for (final topic in weakTopics.take(5)) {
        buffer.writeln('  * ${topic.topicId} (accuracy: ${(topic.accuracy * 100).toStringAsFixed(0)}%)');
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
    return _mentorSystemPromptText;
  }

  String _extractTopic(String message) {
    final lower = message.toLowerCase();
    final keywords = ['about ', 'for ', 'on ', 'study ', 'learn ', 'review ', 'practice '];
    for (final kw in keywords) {
      final idx = lower.indexOf(kw);
      if (idx != -1) {
        final after = message.substring(idx + kw.length).trim();
        final end = after.indexOf(RegExp(r'[.,!?\n]'));
        return end != -1 ? after.substring(0, end).trim() : after;
      }
    }
    final topicKeywords = ['topic ', 'subject ', 'lesson '];
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

  int _getPlanDay(PersonalLearningPlan plan) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final day in plan.dailyPlans) {
      final dDay = DateTime(day.date.year, day.date.month, day.date.day);
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
    } catch (_) {
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
        DateTime(s.startTime.year, s.startTime.month, s.startTime.day)
      ).toSet().toList()..sort((a, b) => b.compareTo(a));
      int consecutive = 0;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      for (var i = 0; i < studyDays.length; i++) {
        final expected = today.subtract(Duration(days: i));
        if (studyDays[i] == expected) {
          consecutive++;
        } else {
          break;
        }
      }
      return consecutive;
    } catch (_) {
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
          message: 'You have studied $todayMinutes minutes today, which exceeds your daily cap of $dailyCap minutes. Consider taking a break!',
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
            message: 'I noticed you had ${lateNight.length} late-night study session(s). Remember that rest is important for effective learning!',
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
            message: 'You have $atRiskCount question(s) approaching their review date. Time for a revision session!',
            severity: NudgeSeverity.low.name,
          );
          await _nudgeRepo.create(nudge);
        }
      }

      final consecutiveDays = await _getConsecutiveStudyDays();
      if (consecutiveDays >= 7) {
        _memory.addSystemMessage(
          'Congratulations on your $consecutiveDays-day study streak! Keep up the amazing consistency!'
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
              'It has been over 48 hours since your last study session. Is everything okay? Would you like to schedule a short review?'
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
        lower.contains('reprogramar');
    final hasPlanIntent = lower.contains('plan') ||
        lower.contains('roadmap') ||
        lower.contains('planificar');

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

      final proposedTime = DateTime.now().add(const Duration(hours: 1));
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
          'The proposed time ($nextHour) conflicts with an existing lesson. '
          'Suggested free slot: ${nextFree.toLocal().toString().substring(0, 16)}. '
          'Shall I book it there?'
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
          'Lesson on "$topicTitle" scheduled for ${nextHour.toLocal().toString().substring(0, 16)} (30 min). '
          'You can review or reschedule anytime.'
        );
      } else {
        _memory.addSystemMessage(
          'I was unable to schedule the lesson. Please try again or check your planner.'
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
        'I can help create a study plan. Would you like me to set up a $days-day learning roadmap? '
        'Please confirm and provide the subject or goal you\'d like to focus on.'
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

    final subjects = await _database.subjectRepository.getAll();
    if (subjects.isEmpty) {
      return const MentorAction(
        message: "You haven't added any subjects yet. Start by setting up your subjects!",
        type: 'setup',
      );
    }

    return const MentorAction(
      message: "You're doing well! Keep up the good work and consider reviewing your recent topics.",
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
        'Unable to find a free slot for rescheduling "${session.topicTitle}". '
        'Please check your availability in the planner.'
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
      'Suggested rescheduling "${session.topicTitle}" to ${nextFree.toLocal().toString().substring(0, 16)} '
      '- pending confirmation stored in repository.'
    );
  }

  Future<List<EngagementNudgeModel>> getRecentNudges({int limit = 10}) async {
    return _nudgeRepo.getRecentByStudent(_studentId, limit: limit);
  }
}
