import 'dart:async';
import 'package:flutter/material.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/features/mentor/services/mentor_keywords.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/string_extensions.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_agent/llm_agent.dart';
import 'package:studyking/core/services/long_term_memory.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/core/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/mentor/data/models/progress_report.dart';
import 'package:studyking/features/mentor/data/models/mentor_action.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'mentor_context_builder.dart';
import 'mentor_wellbeing_service.dart';
import 'mentor_schedule_handler.dart';

class PlanProposal {
  final int days;
  final String? goal;
  final String? subjectId;

  PlanProposal({this.days = 30, this.goal, this.subjectId});
}

class MentorService {
  static final _logger = const Logger('MentorService');

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
  final LongTermMemory? _longTermMemory;

  late final MentorContextBuilder _contextBuilder;
  late final MentorWellbeingService _wellbeingService;
  late final MentorScheduleHandler _scheduleHandler;

  ScheduleProposal? _pendingSchedule;
  PlanProposal? _pendingPlan;
  String? _pendingRescheduleSessionId;

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
    LongTermMemory? longTermMemory,
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
        _longTermMemory = longTermMemory,
        _memory = ConversationMemory(
          maxTurns: 50,
          sessionId: 'mentor_$studentId',
          repository: conversationRepo,
        ) {
    _contextBuilder = MentorContextBuilder(
      progressTracker: _progressTracker,
      masteryService: _masteryService,
      plannerService: _plannerService,
      sessionRepository: _sessionRepository,
      localeName: _localeName,
    );
    _wellbeingService = MentorWellbeingService(
      sessionRepository: _sessionRepository,
      nudgeRepo: _nudgeRepo,
      masteryService: _masteryService,
      localeName: _localeName,
      studentId: _studentId,
    );
    _scheduleHandler = MentorScheduleHandler(
      database: _database,
      plannerService: _plannerService,
      pendingActionRepo: _pendingActionRepo,
      localeName: _localeName,
      memory: _memory,
    );
  }

  ConversationMemory get memory => _memory;
  ScheduleProposal? get pendingScheduleProposal => _pendingSchedule;
  PlanProposal? get pendingPlanProposal => _pendingPlan;
  String? get pendingRescheduleSessionId => _pendingRescheduleSessionId;
  bool get hasApiKey => _llmService.config.apiKey.isNotEmpty;

  void clearPendingSchedule() => _pendingSchedule = null;
  void clearPendingPlan() => _pendingPlan = null;
  void clearPendingReschedule() => _pendingRescheduleSessionId = null;

  Future<void> initialize() async {
    await _memory.loadFromRepository();
    await _nudgeRepo.init();
    try {
      await _longTermMemory?.init();
    } catch (e) {
      _logger.w('LongTermMemory.init failed during MentorService.initialize', e);
    }
  }

  Future<bool> hasMeaningfulData() async {
    final result = await Result.capture(() async {
      final subjectsResult = await _database.subjectRepository.getAll();
      final hasSubjects = subjectsResult.data != null && subjectsResult.data!.isNotEmpty;
      final statsResult = await _progressTracker.getOverallStats(_studentId);
      final stats = statsResult.data ?? <String, dynamic>{};
      final attempts = stats['totalAttempts'] as int? ?? 0;
      return attempts > 0 || hasSubjects;
    }, context: 'hasMeaningfulData');
    return result.data ?? true;
  }

  Stream<String> chat(String message) async* {
    _pendingSchedule = null;
    _pendingPlan = null;
    _pendingRescheduleSessionId = null;

    final hasData = await hasMeaningfulData();
    if (!hasData) {
      final l10n = lookupAppLocalizations(Locale(_localeName));
      final msg = l10n.mentorNoSubjects;
      _memory.addAssistantMessage(msg);
      yield msg;
      return;
    }

    _memory.addUserMessage(message);

    final memoryContext = await _buildLongTermMemoryContext();

    if (_agent != null) {
      final context = await _contextBuilder.buildContextPrompt();
      final systemPrompt = '${_mentorSystemPrompt()}\n\n$context\n\n$memoryContext';
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
      await _storeMentorSessionSummary(content);
      yield content;
      if (response.toolCalls.isNotEmpty) {
        for (final call in response.toolCalls) {
          final toolMsg = '[${call.toolName}] ${call.result ?? 'executed'}';
          _memory.addSystemMessage(toolMsg);
        }
      }
      await _checkAndHandlePlanningIntent(message);
      return;
    }

    final context = await _contextBuilder.buildContextPrompt();
    final fullPrompt = '$context\n\n$memoryContext\n\nStudent: $message';

    final buffer = StringBuffer();
    try {
      await for (final chunk in _llmService.chatStream(
        message: fullPrompt,
        modelId: _modelId,
        memory: _memory,
        systemPrompt: _mentorSystemPrompt(),
      )) {
        buffer.write(chunk);
        yield chunk;
      }
    } catch (e) {
      final partialContent = buffer.toString();
      if (partialContent.isNotEmpty) {
        _memory.addAssistantMessage(partialContent);
      }
      rethrow;
    }

    _memory.addAssistantMessage(buffer.toString());
    await _storeMentorSessionSummary(buffer.toString());

    await _checkAndHandlePlanningIntent(message);
  }

  String _mentorSystemPrompt() {
    final l10n = lookupAppLocalizations(Locale(_localeName));
    final base = l10n.mentorSystemPrompt;
    final l10nSuffix = lookupAppLocalizations(Locale(_localeName)).mentorSystemPromptScheduling;
    return '$base\n\n$l10nSuffix';
  }

  Future<String> _buildLongTermMemoryContext() async {
    final ltm = _longTermMemory;
    if (ltm == null) return '';
    try {
      await ltm.init();
      return await ltm.buildMemoryContext(_studentId);
    } catch (e) {
      return '';
    }
  }

  Future<void> _storeMentorSessionSummary(String responseContent) async {
    final ltm = _longTermMemory;
    if (ltm == null) return;
    try {
      final sessionId = 'mentor_${DateTime.now().millisecondsSinceEpoch}';
      final messages = ConversationMemory.fromConversationMessages(
        _memory.getHistory(),
      );
      if (messages.length < 2) return;
      await ltm.generateAndStoreSummary(
        llmService: _llmService,
        modelId: _modelId,
        studentId: _studentId,
        sessionId: sessionId,
        conversationMessages: messages,
        topicTitle: 'Mentor Session',
      );
    } catch (e) {
      _logger.w('Failed to store mentor session summary', e);
    }
  }

  String _extractTopic(String message) {
    final lower = message.normalized;
    final keywords = MentorKeywords.extractKeywordsByLocale[_localeName] ?? MentorKeywords.extractKeywordsByLocale['en']!;
    for (final kw in keywords) {
      final idx = lower.indexOf(kw);
      if (idx != -1) {
        final after = message.substring(idx + kw.length).trim();
        final end = after.indexOf(RegExp(r'[.,!?\n]'));
        return end != -1 ? after.substring(0, end).trim() : after;
      }
    }
    final topicKeywords = MentorKeywords.extractTopicKeywordsByLocale[_localeName] ?? MentorKeywords.extractTopicKeywordsByLocale['en']!;
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

  int _extractDurationMinutes(String message) {
    final lower = message.normalized;
    final enMinPattern = RegExp(r'(\d+)\s*mins?\b');
    final esMinPattern = RegExp(r'(\d+)\s*minutos?\b');
    final enHourPattern = RegExp(r'(\d+(?:\.\d+)?)\s*hours?\b');
    final esHourPattern = RegExp(r'(\d+(?:\.\d+)?)\s*hora?s?\b');

    for (final pattern in [enMinPattern, esMinPattern]) {
      final match = pattern.firstMatch(lower);
      if (match != null) {
        final value = int.parse(match.group(1)!);
        if (value > 0 && value <= 480) return value;
      }
    }

    for (final pattern in [enHourPattern, esHourPattern]) {
      final match = pattern.firstMatch(lower);
      if (match != null) {
        final value = double.parse(match.group(1)!);
        final minutes = (value * 60).round();
        if (minutes > 0 && minutes <= 480) return minutes;
      }
    }

    return 0;
  }

  Future<void> _checkAndHandlePlanningIntent(String originalMessage) async {
    final lower = originalMessage.normalized;
    final scheduleKeywords = MentorKeywords.scheduleKeywordsByLocale[_localeName] ?? MentorKeywords.scheduleKeywordsByLocale['en']!;
    final planKeywords = MentorKeywords.planKeywordsByLocale[_localeName] ?? MentorKeywords.planKeywordsByLocale['en']!;
    final rescheduleKeywords = MentorKeywords.rescheduleKeywordsByLocale[_localeName] ?? MentorKeywords.rescheduleKeywordsByLocale['en']!;
    final hasScheduleIntent = scheduleKeywords.any((kw) => lower.contains(kw));
    final hasPlanIntent = planKeywords.any((kw) => lower.contains(kw));
    final hasRescheduleIntent = rescheduleKeywords.any((kw) => lower.contains(kw));

    if (!hasScheduleIntent && !hasPlanIntent && !hasRescheduleIntent) return;

    if (hasRescheduleIntent) {
      await _handleRescheduleIntent(originalMessage);
    } else if (hasScheduleIntent) {
      final topicTitle = _extractTopic(originalMessage);
      final durationMinutes = _extractDurationMinutes(originalMessage);
      _pendingSchedule = _scheduleHandler.extractScheduleProposal(topicTitle, durationMinutes);
    } else if (hasPlanIntent) {
      _pendingPlan = _extractPlanProposal(originalMessage);
    }
  }

  Future<void> _handleRescheduleIntent(String originalMessage) async {
    final topicTitle = _extractTopic(originalMessage);
    final lessonsResult = await _plannerService.getScheduledLessons();
    final lessons = lessonsResult.data ?? [];
    if (lessons.isEmpty) return;

    Session? targetSession;
    if (topicTitle.isNotEmpty && topicTitle != 'general') {
      final lowerTopic = topicTitle.normalized;
      targetSession = lessons.where(
        (s) => (s.tutorMetadata?.topicTitle?.normalized.contains(lowerTopic) ?? false)
            || (s.topicId?.normalized.contains(lowerTopic) ?? false),
      ).firstOrNull;
    }
    targetSession ??= lessons.first;

    _pendingRescheduleSessionId = targetSession.id;
  }

  PlanProposal _extractPlanProposal(String originalMessage) {
    final lower = originalMessage.normalized;
    final daysMatch = RegExp(r'(\d+)\s*days?').firstMatch(lower);
    final days = daysMatch != null ? int.parse(daysMatch.group(1)!) : 30;
    final goalMatch = RegExp(r'(?:roadmap|hoja de ruta|plan|planificar)\s+(?:for|de|para|to|of|por)\s+(.+?)(?:\.|$|in\s+\d|\s+with\s+)', caseSensitive: false).firstMatch(originalMessage);
    final goal = goalMatch?.group(1)?.trim();
    return PlanProposal(days: days, goal: goal);
  }

  Future<List<String>> checkWellbeingAndGenerateNudges() async {
    final messages = await _wellbeingService.checkWellbeingAndGenerateNudges();
    for (final msg in messages) {
      _memory.addAssistantMessage(msg);
    }
    return messages;
  }

  Future<String> confirmSchedule(ScheduleProposal proposal) async {
    return _scheduleHandler.confirmSchedule(proposal);
  }

  Future<String> suggestReschedule(String sessionId) async {
    return _scheduleHandler.suggestReschedule(sessionId);
  }

  String planDaysMessage(int days) {
    final l10n = lookupAppLocalizations(Locale(_localeName));
    final msg = l10n.mentorPlanDaysPrompt(days);
    return msg;
  }

  Future<ProgressReport> getProgressReport() async {
    final statsResult = await _progressTracker.getOverallStats(_studentId);
    final stats = statsResult.data ?? <String, dynamic>{};
    final weakResult = await _masteryService.getWeakTopics(_studentId);
    final recommendationsResult = await _progressTracker.getRecommendations(_studentId);
    final recommendations = recommendationsResult.data ?? [];
    final badgesResult = await _progressTracker.getBadges(_studentId);
    final badges = badgesResult.data ?? [];

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
    final recommendationsResult = await _progressTracker.getRecommendations(_studentId);
    final recommendations = recommendationsResult.data ?? [];
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

  Future<List<EngagementNudgeModel>> getRecentNudges({int limit = 10}) async {
    final result = await _nudgeRepo.getRecentByStudent(_studentId, limit: limit);
    return result.data ?? [];
  }

  Future<List<Session>> getUpcomingLessons() async {
    final result = await _contextBuilder.loadUpcomingLessons();
    return result.data ?? [];
  }
}
