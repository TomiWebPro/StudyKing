import 'dart:async';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/data/repositories/pending_action_repository.dart';
import 'package:studyking/core/data/models/pending_action_model.dart';
import 'package:studyking/features/mentor/models/progress_report.dart';
import 'package:studyking/features/mentor/models/mentor_action.dart';

class MentorService {
  final DatabaseService _database;
  final LlmService _llmService;
  final MasteryGraphService _masteryService;
  final StudyProgressTracker _progressTracker;
  final InstrumentationService _instrumentation;
  final String _modelId;
  final ConversationMemory _memory;
  final String _studentId;
  final PendingActionRepository _pendingActionRepo;

  MentorService({
    required DatabaseService database,
    required LlmService llmService,
    required MasteryGraphService masteryService,
    required StudyProgressTracker progressTracker,
    InstrumentationService? instrumentation,
    required String modelId,
    required String studentId,
    PendingActionRepository? pendingActionRepo,
  })  : _database = database,
        _llmService = llmService,
        _masteryService = masteryService,
        _progressTracker = progressTracker,
        _instrumentation = instrumentation ?? InstrumentationService(),
        _modelId = modelId,
        _studentId = studentId,
        _pendingActionRepo = pendingActionRepo ?? PendingActionRepository(),
        _memory = ConversationMemory(maxTurns: 50);

  ConversationMemory get memory => _memory;

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

      final action = PendingActionModel(
        id: 'action_${DateTime.now().millisecondsSinceEpoch}',
        studentId: _studentId,
        actionType: lower.contains('reschedule')
            ? PendingActionType.reschedule.name
            : PendingActionType.schedule.name,
        topicTitle: _extractTopic(originalMessage),
        payload: {'originalMessage': originalMessage},
      );
      await _pendingActionRepo.save(action);
    } catch (_) {}
  }

  String _extractTopic(String message) {
    final words = message.split(' ');
    if (words.length > 3) {
      return words.sublist(0, 3).join(' ');
    }
    return message;
  }

  String _mentorSystemPrompt() {
    return '''
You are StudyKing Mentor, a persistent AI academic mentor.

Your role:
- Help with scheduling and rescheduling lessons
- Plan long-term study goals
- Create or modify study roadmaps
- Provide motivation and encouragement
- Help with accountability
- Discuss workload and wellbeing
- Help decide what to study next
- Receive student feedback about lessons
- Adjust study pacing
- Help create new study plans

Guidelines:
- Be supportive and encouraging
- Ask about the student's wellbeing
- NEVER alter schedules without asking for confirmation first
- Always ask "Would you like me to..." before making changes
- If the student agrees, respond with confirmation before acting
- Be aware of the student's subjects, pending lessons, and weak areas
- If you detect no study activity for 3+ days, suggest a gentle nudge
- Keep responses concise and actionable
- Celebrate milestones and progress
- Ask one question at a time
- Use warm, friendly language
- Respond in the same language the student uses
- If the student asks about scheduling or planning, acknowledge their intent
- Do not use keyword matching to detect intent - use natural language understanding
''';
  }

  Future<String> _buildContextPrompt() async {
    try {
      final stats = await _progressTracker.getOverallStats(_studentId);
      final recommendations =
          await _progressTracker.getRecommendations(_studentId);
      final badges = await _progressTracker.getBadges(_studentId);
      final sessions = await _database.tutorSessionRepository
          .getStudentSessions(_studentId);
      final completedSessions =
          sessions.where((s) => s.status.toString().contains('completed')).length;
      final subjects = await _database.subjectRepository.getAll();

      final recentSession = sessions.isNotEmpty ? sessions.first : null;
      final daysSinceLastStudy = recentSession != null
          ? DateTime.now().difference(recentSession.startTime).inDays
          : -1;

      String adherenceInfo = 'No plan adherence data available.';
      try {
        final dashboard =
            await _instrumentation.getInstrumentationDashboard(_studentId);
        if (dashboard.isSuccess) {
          final data = dashboard.data!;
          final adherence = data['planAdherence'] as Map<String, dynamic>?;
          if (adherence != null) {
            final avg = (adherence['averageAdherence'] as double? ?? 0.0);
            final weekly = (adherence['weeklyAdherenceAvg'] as double? ?? 0.0);
            final lowAdherenceDays =
                adherence['consecutiveLowDays'] as int? ?? 0;
            adherenceInfo =
                'Plan adherence: ${(avg * 100).round()}% overall, ${(weekly * 100).round()}% this week.';
            if (lowAdherenceDays >= 3) {
              adherenceInfo +=
                  ' WARNING: Student has had $lowAdherenceDays consecutive days of low adherence - suggest plan adjustment.';
            }
          }
        }
      } catch (_) {}

      return '''
Current context for the student:
- Subjects: ${subjects.map((s) => s.name).join(', ')}
- Total study accuracy: ${stats['accuracy']}%
- Total study time: ${stats['totalStudyTimeHours']} hours
- Weekly activity: ${stats['weeklyActivity']} attempts
- Badges earned: ${badges.length}
- Completed lessons: $completedSessions
- Days since last study session: $daysSinceLastStudy
- ${daysSinceLastStudy >= 3 ? 'Note: Student has been inactive for 3+ days - consider suggesting a gentle return to study' : ''}
- $adherenceInfo
- ${badges.isNotEmpty ? 'Recent badges: ${badges.take(3).map((b) => b['name']).join(', ')}' : 'No badges yet'}

Recent recommendations: ${recommendations.map((r) => r['message']).join('; ')}

Use this context to provide personalized mentoring.
''';
    } catch (_) {
      return 'Student context is currently unavailable. Proceed with general mentoring.';
    }
  }

  Future<ProgressReport> getProgressReport() async {
    try {
      final stats = await _progressTracker.getOverallStats(_studentId);
      final recommendations =
          await _progressTracker.getRecommendations(_studentId);
      final badges = await _progressTracker.getBadges(_studentId);
      final weakTopics = await _masteryService.getWeakTopics(_studentId);
      final sessions = await _database.tutorSessionRepository
          .getStudentSessions(_studentId);

      return ProgressReport(
        totalAttempts: (stats['totalAttempts'] as num?)?.toInt() ?? 0,
        correctAttempts: (stats['correctAttempts'] as num?)?.toInt() ?? 0,
        accuracy: (stats['accuracy'] as num?)?.toDouble() ?? 0.0,
        totalStudyTimeHours: '${stats['totalStudyTimeHours']}',
        weeklyActivity: (stats['weeklyActivity'] as num?)?.toInt() ?? 0,
        topicsStudied: (stats['topicsStudied'] as num?)?.toInt() ?? 0,
        completedLessons: sessions
            .where((s) => s.status.toString().contains('completed'))
            .length,
        weakTopics: weakTopics.isSuccess ? weakTopics.data! : [],
        badges: badges,
        recommendations: recommendations,
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<MentorAction> suggestNextAction() async {
    final recommendations =
        await _progressTracker.getRecommendations(_studentId);
    final subjects = await _database.subjectRepository.getAll();

    if (recommendations.isNotEmpty) {
      return MentorAction(
        message: recommendations.first['message'] as String,
        type: 'recommendation',
      );
    }

    if (subjects.isEmpty) {
      return const MentorAction(
        message: "You haven't added any subjects yet. Would you like help setting up your first subject?",
        type: 'setup',
      );
    }

    return const MentorAction(
      message: "You're doing well! Would you like to review your progress, schedule a new lesson, or practice some questions?",
      type: 'generic',
    );
  }

  Future<void> suggestReschedule(String sessionId) async {
    final session =
        await _database.tutorSessionRepository.getSession(sessionId);
    if (session == null) return;

    try {
      await _pendingActionRepo.init();
      await _pendingActionRepo.save(PendingActionModel(
        id: 'resched_${DateTime.now().millisecondsSinceEpoch}',
        studentId: _studentId,
        actionType: PendingActionType.reschedule.name,
        topicTitle: session.topicTitle,
        sessionId: sessionId,
      ));
    } catch (_) {}

    _memory.addSystemMessage(
        'Suggested rescheduling session "${session.topicTitle}" - pending confirmation stored in repository');
  }
}
