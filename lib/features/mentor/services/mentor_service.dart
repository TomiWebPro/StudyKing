import 'dart:async';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/core/data/models/pending_action_model.dart';
import 'package:studyking/features/mentor/data/models/progress_report.dart';
import 'package:studyking/features/mentor/data/models/mentor_action.dart';

class MentorService {
  final DatabaseService _database;
  final LlmService _llmService;
  final MasteryGraphService _masteryService;
  final StudyProgressTracker _progressTracker;
  final String _modelId;
  final ConversationMemory _memory;
  final String _studentId;
  final PendingActionRepository _pendingActionRepo;

  MentorService({
    required DatabaseService database,
    required LlmService llmService,
    required MasteryGraphService masteryService,
    required StudyProgressTracker progressTracker,
    required String modelId,
    required String studentId,
    PendingActionRepository? pendingActionRepo,
    ConversationRepository? conversationRepo,
  })  : _database = database,
        _llmService = llmService,
        _masteryService = masteryService,
        _progressTracker = progressTracker,
        _modelId = modelId,
        _studentId = studentId,
        _pendingActionRepo = pendingActionRepo ?? PendingActionRepository(),
        _memory = ConversationMemory(
          maxTurns: 50,
          sessionId: 'mentor_$studentId',
          repository: conversationRepo,
        );

  ConversationMemory get memory => _memory;

  Future<void> initialize() async {
    await _memory.loadFromRepository();
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

    final response = buffer.toString().toLowerCase();
    await _checkAndHandlePlanningIntent(response, message);
  }

  Future<void> _checkAndHandlePlanningIntent(
      String response, String originalMessage) async {
    final lower = originalMessage.toLowerCase();
    final hasPlanIntent = lower.contains('schedule') ||
        lower.contains('reschedule') ||
        lower.contains('plan') ||
        lower.contains('roadmap') ||
        lower.contains('programar') ||
        lower.contains('reprogramar') ||
        lower.contains('planificar');

    if (!hasPlanIntent) return;

    try {
      await _pendingActionRepo.init();
      final existing = await _pendingActionRepo.getPending(_studentId);
      if (existing.isNotEmpty) return;

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

      final scheduledTime = DateTime.now().add(const Duration(hours: 1));
      final nextHour = DateTime(
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        scheduledTime.hour,
        0,
      );

      final payload = <String, dynamic>{
        'originalMessage': originalMessage,
        if (topicId != null) 'topicId': topicId,
        if (subjectId != null) 'subjectId': subjectId,
        'scheduledTime': nextHour.toIso8601String(),
        'durationMinutes': 30,
      };

      final action = PendingActionModel(
        id: 'action_${DateTime.now().millisecondsSinceEpoch}',
        studentId: _studentId,
        actionType: lower.contains('reschedule')
            ? PendingActionType.reschedule.name
            : PendingActionType.schedule.name,
        topicTitle: topicTitle,
        payload: payload,
      );
      await _pendingActionRepo.create(action);
    } catch (_) {}
  }

  Future<String> _buildContextPrompt() async {
    final stats = await _progressTracker.getOverallStats(_studentId);
    return '''
Current student context:
- Total attempts: ${stats['totalAttempts']}
- Correct attempts: ${stats['correctAttempts']}
- Accuracy: ${stats['accuracy']}%
- Topics studied: ${stats['topicsStudied']}
- Weekly activity: ${stats['weeklyActivity']} attempts
- Total study time: ${stats['totalStudyTimeHours']} hours
''';
  }

  String _mentorSystemPrompt() {
    return 'You are a knowledgeable and encouraging AI mentor for a student. '
        'Your role is to guide their learning journey, provide motivation, '
        'and help them develop effective study habits. '
        'Keep responses concise, supportive, and actionable.';
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

  Future<ProgressReport> getProgressReport() async {
    final stats = await _progressTracker.getOverallStats(_studentId);
    final weakResult = await _masteryService.getWeakTopics(_studentId);
    final recommendations = await _progressTracker.getRecommendations(_studentId);
    final badges = await _progressTracker.getBadges(_studentId);

    return ProgressReport(
      totalAttempts: stats['totalAttempts'] as int,
      correctAttempts: stats['correctAttempts'] as int,
      accuracy: (stats['accuracy'] as num).toDouble(),
      topicsStudied: stats['topicsStudied'] as int,
      completedLessons: 0,
      weeklyActivity: stats['weeklyActivity'] as int,
      totalStudyTimeHours: stats['totalStudyTimeHours'] as String,
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

    final nextSlot = DateTime.now().add(const Duration(hours: 1));
    final nextHour = DateTime(
      nextSlot.year,
      nextSlot.month,
      nextSlot.day,
      nextSlot.hour,
      0,
    );

    final action = PendingActionModel(
      id: 'resched_${DateTime.now().millisecondsSinceEpoch}',
      studentId: _studentId,
      actionType: PendingActionType.reschedule.name,
      topicTitle: session.topicTitle,
      sessionId: sessionId,
      payload: {
        'topicId': session.topicId,
        'subjectId': session.subjectId,
        'scheduledTime': nextHour.toIso8601String(),
        'durationMinutes': session.plannedDurationMinutes,
        'originalSessionStart': session.startTime.toIso8601String(),
      },
    );
    await _pendingActionRepo.init();
    await _pendingActionRepo.create(action);

    _memory.addSystemMessage(
      'Suggested rescheduling session "${session.topicTitle}" - pending confirmation stored in repository',
    );
  }
}
