import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_agent/llm_agent.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/core/services/student_id_service.dart';
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

class ScheduleProposal {
  final String topicTitle;
  final String? topicId;
  final String? subjectId;
  final DateTime proposedTime;
  final int durationMinutes;

  ScheduleProposal({
    required this.topicTitle,
    this.topicId,
    this.subjectId,
    required this.proposedTime,
    this.durationMinutes = 30,
  });
}

class PlanProposal {
  final int days;
  final String? goal;
  final String? subjectId;

  PlanProposal({this.days = 30, this.goal, this.subjectId});
}

class MentorService {
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
  final LlmAgent? _agent;

  ScheduleProposal? _pendingSchedule;
  PlanProposal? _pendingPlan;

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
    required String localeName,
    LlmAgent? agent,
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
        _agent = agent,
        _memory = ConversationMemory(
          maxTurns: 50,
          sessionId: 'mentor_$studentId',
          repository: conversationRepo,
        );

  ConversationMemory get memory => _memory;
  ScheduleProposal? get pendingScheduleProposal => _pendingSchedule;
  PlanProposal? get pendingPlanProposal => _pendingPlan;
  bool get hasApiKey => _llmService.config.apiKey.isNotEmpty;

  void clearPendingSchedule() => _pendingSchedule = null;
  void clearPendingPlan() => _pendingPlan = null;

  Future<void> initialize() async {
    await _memory.loadFromRepository();
    await _nudgeRepo.init();
  }

  Future<bool> hasMeaningfulData() async {
    final result = await Result.capture(() async {
      final subjectsResult = await _database.subjectRepository.getAll();
      final hasSubjects = subjectsResult.data != null && subjectsResult.data!.isNotEmpty;
      final stats = await _progressTracker.getOverallStats(_studentId);
      final attempts = stats['totalAttempts'] as int? ?? 0;
      return attempts > 0 || hasSubjects;
    }, context: 'hasMeaningfulData');
    return result.data ?? true;
  }

  Stream<String> chat(String message) async* {
    _pendingSchedule = null;
    _pendingPlan = null;

    final hasData = await hasMeaningfulData();
    if (!hasData) {
      final l10n = lookupAppLocalizations(Locale(_localeName));
      final msg = l10n.mentorNoSubjects;
      _memory.addAssistantMessage(msg);
      yield msg;
      return;
    }

    _memory.addUserMessage(message);

    if (_agent != null) {
      final context = await _buildContextPrompt();
      final systemPrompt = '${_mentorSystemPrompt()}\n\n$context';
      final history = _memory.getHistory().map((m) => {
        'role': m.role == MessageRole.student ? 'user' : 'assistant',
        'content': m.content,
      }).toList();

      final response = await _agent.chat(
        message: message,
        systemPrompt: systemPrompt,
        feature: 'mentor',
        history: history,
      );

      final content = response.content;
      _memory.addAssistantMessage(content);
      yield content;
      if (response.toolCalls.isNotEmpty) {
        for (final call in response.toolCalls) {
          final toolMsg = '[${call.toolName}] ${call.result ?? 'executed'}';
          _memory.addSystemMessage(toolMsg);
        }
      }
      _checkAndHandlePlanningIntent(message);
      return;
    }

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

    _checkAndHandlePlanningIntent(message);
  }

  Future<String> _buildContextPrompt() async {
    final stats = await _progressTracker.getOverallStats(_studentId);
    final weakTopics = (await _loadWeakTopics()).data ?? [];
    final plan = (await _loadPlan()).data;
    final roadmaps = (await _loadRoadmaps()).data ?? [];
    final pendingActions = (await _loadPendingActions()).data ?? [];
    final upcomingLessons = (await _loadUpcomingLessons()).data ?? [];
    final adherenceDeviation = (await _loadAdherence()).data;
    final todayMinutes = await _getTodayStudyMinutes();
    final dailyCap = await _getDailyCapMinutes();
    final consecutiveDays = await _getConsecutiveStudyDays();
    final daysSinceLastActivity = StudentIdService().getDaysSinceLastActivity();
    final l10n = lookupAppLocalizations(Locale(_localeName));
    final bullet = l10n.mentorBulletPoint;

    final buffer = StringBuffer();
    // Note: Context labels are in invariant English regardless of user locale.
    // This context data is fed to the LLM. The labels are a data-formatting
    // convention, not user-facing text.
    buffer.writeln('Current student context:');
    buffer.writeln('${bullet}Total attempts: ${stats['totalAttempts']}');
    buffer.writeln('${bullet}Correct attempts: ${stats['correctAttempts']}');
    buffer.writeln('${bullet}Accuracy: ${stats['accuracy']}%');
    buffer.writeln('${bullet}Topics studied: ${stats['topicsStudied']}');
    buffer.writeln('${bullet}Weekly activity: ${stats['weeklyActivity']} attempts');
    buffer.writeln('${bullet}Total study time: ${stats['totalStudyTimeHours']} hours');

    if (plan != null) {
      buffer.writeln('${bullet}Plan exists: current phase (day ${_getPlanDay(plan)} of ${plan.dailyPlans.length})');
      if (adherenceDeviation != null) {
        buffer.writeln('${bullet}Plan adherence: ${adherenceDeviation.averageAdherence.toStringAsFixed(1)}%'); // LLM-facing: invariant period format OK
        if (adherenceDeviation.consecutiveLowDays > 0) {
          buffer.writeln('${bullet}Low adherence for ${adherenceDeviation.consecutiveLowDays} consecutive days');
        }
      }
    }

    if (daysSinceLastActivity >= 0) {
      buffer.writeln('${bullet}Days since last activity: $daysSinceLastActivity');
      if (daysSinceLastActivity >= 3) {
        buffer.writeln('IMPORTANT: The student is returning after a $daysSinceLastActivity-day absence. Provide a warm welcome-back and suggest specific catch-up steps.');
      }
    }

    if (roadmaps.isNotEmpty) {
      final activeRoadmaps = roadmaps.where((r) => r.status == 'active').toList();
      if (activeRoadmaps.isNotEmpty) {
        buffer.writeln('${bullet}Active roadmaps: ${activeRoadmaps.length}');
        for (final roadmap in activeRoadmaps.take(2)) {
          final completedMilestones = roadmap.milestones.where((m) => m.isCompleted).length;
          final nearest = roadmap.milestones.where((m) => !m.isCompleted).firstOrNull;
          buffer.writeln('  $bullet"${roadmap.goal}": $completedMilestones/${roadmap.milestones.length} milestones completed');
          if (nearest != null) {
            buffer.writeln('    Next milestone: "${nearest.title}" due ${DateFormat.yMd(_localeName).add_Hm().format(nearest.deadline.toLocal())}');
          }
        }
      }
    }

    if (pendingActions.isNotEmpty) {
      buffer.writeln('${bullet}Pending actions awaiting decision: ${pendingActions.length}');
      for (final action in pendingActions.take(3)) {
        buffer.writeln('  $bullet${action.actionType}: ${action.topicTitle}');
      }
    }

    if (upcomingLessons.isNotEmpty) {
      buffer.writeln('${bullet}Upcoming lessons (next ${upcomingLessons.length > 3 ? 3 : upcomingLessons.length}):');
      for (final lesson in upcomingLessons.take(3)) {
        final title = lesson.tutorMetadata?.topicTitle ?? lesson.topicId ?? l10n.unknown;
        buffer.writeln('  $bullet"$title" at ${DateFormat.yMd(_localeName).add_Hm().format(lesson.startTime.toLocal())} (${lesson.plannedDurationMinutes ?? 30}min)');
      }
    }

    if (weakTopics.isNotEmpty) {
      buffer.writeln('${bullet}Weak topics needing attention:');
      for (final topic in weakTopics.take(5)) {
        buffer.writeln('  $bullet${topic.topicId} (accuracy: ${(topic.accuracy * 100).toStringAsFixed(0)}%)'); // LLM-facing: invariant period format OK
      }
    }

    if (todayMinutes > 0) {
      buffer.writeln("${bullet}Today's study time: $todayMinutes minutes");
      if (dailyCap > 0 && todayMinutes > dailyCap) {
        buffer.writeln('${bullet}WARNING: Daily study cap ($dailyCap min) exceeded by ${todayMinutes - dailyCap} minutes');
      } else if (dailyCap > 0) {
        buffer.writeln('${bullet}Daily cap: $dailyCap minutes (${dailyCap - todayMinutes} min remaining)');
      }
    }

    if (consecutiveDays >= 7) {
      buffer.writeln('${bullet}Congratulations! $consecutiveDays day study streak!');
    } else if (consecutiveDays >= 3) {
      buffer.writeln('$bullet$consecutiveDays consecutive study days - good consistency!');
    }

    final recentResult = await _sessionRepository.getByDate(DateTime.now());
    if (recentResult.isSuccess) {
      final todaySessions = recentResult.data!;
      if (todaySessions.isNotEmpty) {
        buffer.writeln('${bullet}Sessions today: ${todaySessions.length}');
        final lateNight = todaySessions.where((s) => s.startTime.hour >= 22).toList();
        if (lateNight.isNotEmpty) {
          buffer.writeln('${bullet}WARNING: ${lateNight.length} session(s) started after 10 PM (late-night study detected)');
        }
      }
    }

    return buffer.toString();
  }

  String _mentorSystemPrompt() {
    final l10n = lookupAppLocalizations(Locale(_localeName));
    return l10n.mentorSystemPrompt;
  }

  static const Map<String, List<String>> _extractKeywordsByLocale = {
    'en': ['about ', 'for ', 'on ', 'study ', 'learn ', 'review ', 'practice '],
    'es': ['sobre ', 'para ', 'de ', 'estudiar ', 'aprender ', 'repasar ', 'practicar ', 'acerca de ', 'acerca '],
    'fr': ['à propos de ', 'pour ', 'sur ', 'étudier ', 'apprendre ', 'réviser ', 'pratiquer '],
    'de': ['über ', 'für ', 'zu ', 'studieren ', 'lernen ', 'wiederholen ', 'üben '],
  };

  static const Map<String, List<String>> _extractTopicKeywordsByLocale = {
    'en': ['topic ', 'subject ', 'lesson '],
    'es': ['tema ', 'materia ', 'lección ', 'asignatura '],
    'fr': ['sujet ', 'matière ', 'leçon '],
    'de': ['thema ', 'fach ', 'lektion '],
  };

  String _extractTopic(String message) {
    final lower = message.toLowerCase();
    final keywords = _extractKeywordsByLocale[_localeName] ?? _extractKeywordsByLocale['en']!;
    for (final kw in keywords) {
      final idx = lower.indexOf(kw);
      if (idx != -1) {
        final after = message.substring(idx + kw.length).trim();
        final end = after.indexOf(RegExp(r'[.,!?\n]'));
        return end != -1 ? after.substring(0, end).trim() : after;
      }
    }
    final topicKeywords = _extractTopicKeywordsByLocale[_localeName] ?? _extractTopicKeywordsByLocale['en']!;
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

  Future<Result<List<MasteryState>>> _loadWeakTopics() async {
    return Result.capture(() async {
      final result = await _masteryService.getWeakTopics(_studentId);
      return result.isSuccess ? result.data! : [];
    }, context: '_loadWeakTopics');
  }

  Future<Result<PersonalLearningPlan?>> _loadPlan() async {
    return Result.capture(() => _plannerService.loadExistingPlan(), context: '_loadPlan');
  }

  Future<Result<List<RoadmapModel>>> _loadRoadmaps() async {
    return Result.capture(() => _plannerService.loadRoadmaps(), context: '_loadRoadmaps');
  }

  Future<Result<List<PendingActionModel>>> _loadPendingActions() async {
    return Result.capture(() => _plannerService.loadPendingActions(), context: '_loadPendingActions');
  }

  Future<Result<List<Session>>> _loadUpcomingLessons() async {
    return Result.capture(() => _plannerService.getScheduledLessons(), context: '_loadUpcomingLessons');
  }

  Future<Result<AdherenceDeviation?>> _loadAdherence() async {
    return Result.capture(() => _plannerService.checkAdherence(), context: '_loadAdherence');
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
    final result = Result.captureSync(() {
      if (!Hive.isBoxOpen('settings')) return 0;
      final box = Hive.box('settings');
      return box.get('dailyCapMinutes', defaultValue: 0) as int;
    }, context: '_getDailyCapMinutes');
    return result.data ?? 0;
  }

  Future<int> _getConsecutiveStudyDays() async {
    final result = await Result.capture(() async {
      final allResult = await _sessionRepository.getAll();
      if (allResult.isFailure) return 0;
      final all = allResult.data!;
      if (all.isEmpty) return 0;
      final studyDays = all.where((s) =>
        s.completed || s.actualDurationMs > 0
      ).map((s) =>
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
    }, context: '_getConsecutiveStudyDays');
    return result.data ?? 0;
  }

  Future<List<String>> checkWellbeingAndGenerateNudges() async {
    final result = await Result.capture(() => _checkWellbeingInner(), context: 'checkWellbeingAndGenerateNudges');
    return result.data ?? [];
  }

  Future<List<String>> _checkWellbeingInner() async {
    final messages = <String>[];
    final todayMinutes = await _getTodayStudyMinutes();
    final dailyCap = await _getDailyCapMinutes();
    final recentResult = await _sessionRepository.getByDate(DateTime.now());

    if (dailyCap > 0 && todayMinutes > dailyCap) {
      final msg = lookupAppLocalizations(Locale(_localeName)).nudgeOverworkMinutes(todayMinutes, dailyCap);
      final nudge = EngagementNudgeModel(
        id: 'overwork_${DateTime.now().millisecondsSinceEpoch}_$_studentId',
        studentId: _studentId,
        nudgeType: NudgeType.overwork.name,
        message: msg,
        severity: NudgeSeverity.medium.name,
      );
      await _nudgeRepo.create(nudge);
      messages.add(msg);
    }

    if (recentResult.isSuccess) {
      final lateNight = recentResult.data!.where((s) => s.startTime.hour >= 22).toList();
      if (lateNight.isNotEmpty) {
        final msg = lookupAppLocalizations(Locale(_localeName)).nudgeLateNight(lateNight.length);
        final nudge = EngagementNudgeModel(
          id: 'wellbeing_${DateTime.now().millisecondsSinceEpoch}_$_studentId',
          studentId: _studentId,
          nudgeType: NudgeType.overwork.name,
          message: msg,
          severity: NudgeSeverity.low.name,
        );
        await _nudgeRepo.create(nudge);
        messages.add(msg);
      }
    }

    final weakResult = await _masteryService.getAtRiskQuestions(_studentId);
    if (weakResult.isSuccess && weakResult.data!.isNotEmpty) {
      final atRiskCount = weakResult.data!.length;
      if (atRiskCount >= 3) {
        final msg = lookupAppLocalizations(Locale(_localeName)).nudgeRevisionNeeded(atRiskCount);
        final nudge = EngagementNudgeModel(
          id: 'revision_${DateTime.now().millisecondsSinceEpoch}_$_studentId',
          studentId: _studentId,
          nudgeType: NudgeType.revision.name,
          message: msg,
          severity: NudgeSeverity.low.name,
        );
        await _nudgeRepo.create(nudge);
        messages.add(msg);
      }
    }

    final consecutiveDays = await _getConsecutiveStudyDays();
    if (consecutiveDays >= 7) {
      final msg = lookupAppLocalizations(Locale(_localeName)).nudgeStreakDays(consecutiveDays);
      messages.add(msg);
    } else if (consecutiveDays == 0) {
      final allResult = await _sessionRepository.getAll();
      if (allResult.isSuccess) {
        final lastStudy = allResult.data!.where((s) => s.completed).fold<DateTime?>(
          null, (prev, s) {
            if (prev == null || s.startTime.isAfter(prev)) return s.startTime;
            return prev;
          });
        if (lastStudy != null && DateTime.now().difference(lastStudy).inHours >= 48) {
          final l10nCtx = lookupAppLocalizations(Locale(_localeName));
          final hoursSince = DateTime.now().difference(lastStudy).inHours;
          final daysSince = hoursSince ~/ 24;
          String msg;
          String nudgeType;
          String severity;
          if (daysSince >= 30) {
            msg = l10nCtx.nudgeInactive30d(daysSince);
            nudgeType = NudgeType.overwork.name;
            severity = NudgeSeverity.high.name;
          } else if (daysSince >= 14) {
            msg = l10nCtx.nudgeInactive14d(daysSince);
            nudgeType = NudgeType.overwork.name;
            severity = NudgeSeverity.high.name;
          } else if (daysSince >= 7) {
            msg = l10nCtx.nudgeInactive7d(daysSince);
            nudgeType = NudgeType.planAdjustment.name;
            severity = NudgeSeverity.medium.name;
          } else {
            msg = l10nCtx.nudgeInactive48h;
            nudgeType = NudgeType.planAdjustment.name;
            severity = NudgeSeverity.medium.name;
          }
          final nudge = EngagementNudgeModel(
            id: 'inactive_${DateTime.now().millisecondsSinceEpoch}_$_studentId',
            studentId: _studentId,
            nudgeType: nudgeType,
            message: msg,
            severity: severity,
          );
          await _nudgeRepo.create(nudge);
          messages.add(msg);
        }
      }
    }

    for (final msg in messages) {
      _memory.addAssistantMessage(msg);
    }

    if (dailyCap > 0) {
      final todayNudgesResult = await _nudgeRepo.getTodayCount(_studentId);
      final todayNudges = todayNudgesResult.data ?? 0;
      if (todayNudges >= 5) return messages;
    }
    return messages;
  }

  static const Map<String, List<String>> _scheduleKeywordsByLocale = {
    'en': ['schedule', 'reschedule'],
    'es': ['programar', 'reprogramar', 'agendar', 'reagendar', 'citar'],
  };

  static const Map<String, List<String>> _planKeywordsByLocale = {
    'en': ['plan', 'roadmap', 'milestone'],
    'es': ['plan', 'planificar', 'hoja de ruta', 'hito'],
  };

  void _checkAndHandlePlanningIntent(String originalMessage) {
    final lower = originalMessage.toLowerCase();
    final scheduleKeywords = _scheduleKeywordsByLocale[_localeName] ?? _scheduleKeywordsByLocale['en']!;
    final planKeywords = _planKeywordsByLocale[_localeName] ?? _planKeywordsByLocale['en']!;
    final hasScheduleIntent = scheduleKeywords.any((kw) => lower.contains(kw));
    final hasPlanIntent = planKeywords.any((kw) => lower.contains(kw));

    if (!hasScheduleIntent && !hasPlanIntent) return;

    if (hasScheduleIntent) {
      _pendingSchedule = _extractScheduleProposal(originalMessage);
    } else if (hasPlanIntent) {
      _pendingPlan = _extractPlanProposal(originalMessage);
    }
  }

  ScheduleProposal _extractScheduleProposal(String originalMessage) {
    final topicTitle = _extractTopic(originalMessage);
    final proposedTime = DateTime.now().add(Timeouts.hour);
    final nextHour = DateTime(
      proposedTime.year,
      proposedTime.month,
      proposedTime.day,
      proposedTime.hour,
      0,
    );
    return ScheduleProposal(
      topicTitle: topicTitle,
      proposedTime: nextHour,
      durationMinutes: 30,
    );
  }

  PlanProposal _extractPlanProposal(String originalMessage) {
    final lower = originalMessage.toLowerCase();
    final daysMatch = RegExp(r'(\d+)\s*days?').firstMatch(lower);
    final days = daysMatch != null ? int.parse(daysMatch.group(1)!) : 30;
    final goalMatch = RegExp(r'(?:roadmap|hoja de ruta|plan|planificar)\s+(?:for|de|para|to|of|por)\s+(.+?)(?:\.|$|in\s+\d|\s+with\s+)', caseSensitive: false).firstMatch(originalMessage);
    final goal = goalMatch?.group(1)?.trim();
    return PlanProposal(days: days, goal: goal);
  }

  Future<String> confirmSchedule(ScheduleProposal proposal) async {
    final result = await Result.capture(() => _confirmScheduleInner(proposal), context: 'confirmSchedule');
    if (result.isSuccess) return result.data!;
    final l10n = lookupAppLocalizations(Locale(_localeName));
    final msg = l10n.mentorScheduleFail;
    _memory.addAssistantMessage(msg);
    return msg;
  }

  Future<String> _confirmScheduleInner(ScheduleProposal proposal) async {
    String? topicId;
    String? subjectId;
    if (proposal.topicTitle.isNotEmpty && proposal.topicTitle != 'general') {
      await _database.topicRepository.init();
      final allTopicsResult = await _database.topicRepository.getAll();
      final allTopics = allTopicsResult.data ?? [];
      final match = allTopics.where(
        (t) => t.title.toLowerCase().contains(proposal.topicTitle.toLowerCase()),
      ).firstOrNull;
      topicId = match?.id;
      subjectId = match?.subjectId;
    }

    final hasConflict = await _plannerService.hasSchedulingConflict(
      startTime: proposal.proposedTime,
      durationMinutes: proposal.durationMinutes,
    );

    if (hasConflict) {
      final existingLessons = await _plannerService.getScheduledLessons();
      final nextFree = _findNextFreeSlot(existingLessons, proposal.durationMinutes);
      final l10n = lookupAppLocalizations(Locale(_localeName));
      final msg = l10n.mentorScheduleConflict(
        DateFormat.yMd(_localeName).add_Hm().format(proposal.proposedTime.toLocal()),
        DateFormat.yMd(_localeName).add_Hm().format(nextFree.toLocal()),
      );
      _memory.addAssistantMessage(msg);
      return msg;
    }

    final success = await _plannerService.scheduleLesson(
      topicId: topicId ?? '',
      topicTitle: proposal.topicTitle,
      subjectId: subjectId ?? '',
      scheduledTime: proposal.proposedTime,
      durationMinutes: proposal.durationMinutes,
    );

    String msg;
    final l10n = lookupAppLocalizations(Locale(_localeName));
    if (success) {
      msg = l10n.mentorScheduleSuccess(
        proposal.topicTitle,
        DateFormat.yMd(_localeName).add_Hm().format(proposal.proposedTime.toLocal()),
      );
    } else {
      msg = l10n.mentorScheduleFail;
    }
    _memory.addAssistantMessage(msg);
    return msg;
  }

  String planDaysMessage(int days) {
    final l10n = lookupAppLocalizations(Locale(_localeName));
    final msg = l10n.mentorPlanDaysPrompt(days);
    return msg;
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

  Future<ProgressReport> getProgressReport() async {
    final stats = await _progressTracker.getOverallStats(_studentId);
    final weakResult = await _masteryService.getWeakTopics(_studentId);
    final recommendations = await _progressTracker.getRecommendations(_studentId);
    final badges = await _progressTracker.getBadges(_studentId);

    final completedResult =
        await _database.tutorSessionRepository.getCompletedSessions(_studentId);
    final completedLessons = completedResult.data?.length ?? 0;

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
    final subjectsResult = await _database.subjectRepository.getAll();
    final subjects = subjectsResult.data ?? [];
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
    final sessionResult = await _database.tutorSessionRepository.getSession(sessionId);
    final session = sessionResult.data;
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
        DateFormat.yMd(_localeName).add_Hm().format(nextFree.toLocal()),
      )
    );
  }

  Future<List<EngagementNudgeModel>> getRecentNudges({int limit = 10}) async {
    final result = await _nudgeRepo.getRecentByStudent(_studentId, limit: limit);
    return result.data ?? [];
  }
}
