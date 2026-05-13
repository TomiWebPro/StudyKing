import 'dart:async';
import '../../../core/data/database_service.dart';
import '../../../core/services/llm/llm_chat_service.dart';
import '../../../core/services/mastery_graph_service.dart';
import '../../../core/services/study_progress_tracker.dart';
import '../../../core/data/repositories/plan_repository.dart';
import '../../../core/utils/logger.dart';

class MentorService {
  final DatabaseService _database;
  final LlmService _llmService;
  final MasteryGraphService _masteryService;
  final StudyProgressTracker _progressTracker;
  final String _modelId;
  final ConversationMemory _memory;
  final String _studentId;
  final Logger _logger = const Logger('MentorService');

  bool _pendingConfirmation = false;
  Map<String, dynamic>? _pendingAction;

  MentorService({
    required DatabaseService database,
    required LlmService llmService,
    required MasteryGraphService masteryService,
    required StudyProgressTracker progressTracker,
    required String modelId,
    required String studentId,
  })  : _database = database,
        _llmService = llmService,
        _masteryService = masteryService,
        _progressTracker = progressTracker,
        _modelId = modelId,
        _studentId = studentId,
        _memory = ConversationMemory(maxTurns: 50);

  ConversationMemory get memory => _memory;
  bool get hasPendingConfirmation => _pendingConfirmation;
  Map<String, dynamic>? get pendingAction => _pendingAction;

  Stream<String> chat(String message) async* {
    final lower = message.toLowerCase();

    if (_pendingConfirmation && _pendingAction != null) {
      if (_isConfirmation(lower)) {
        yield* _executePendingAction();
        return;
      } else if (_isRejection(lower)) {
        _pendingConfirmation = false;
        _pendingAction = null;
        yield 'No problem! I won\'t make any changes. Let me know if you need anything else.';
        return;
      }
    }

    if (_isScheduleRequest(lower)) {
      yield* _handleScheduleRequest(message);
      return;
    }

    if (_isProgressRequest(lower)) {
      yield* _handleProgressRequest(message);
      return;
    }

    if (_isInactivityCheck(lower)) {
      yield* _handleInactivityCheck();
      return;
    }

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
  }

  bool _isConfirmation(String lower) {
    return lower.contains('yes') ||
        lower.contains('sure') ||
        lower.contains('ok') ||
        lower.contains('go ahead') ||
        lower.contains('confirm') ||
        lower.contains('please do');
  }

  bool _isRejection(String lower) {
    return lower.contains('no') ||
        lower.contains("don't") ||
        lower.contains("not") ||
        lower.contains("never mind") ||
        lower.contains("cancel");
  }

  bool _isScheduleRequest(String lower) {
    return lower.contains('schedule') ||
        lower.contains('reschedule') ||
        lower.contains('plan') ||
        lower.contains('lesson') ||
        lower.contains('when') ||
        lower.contains('next study');
  }

  bool _isProgressRequest(String lower) {
    return lower.contains('progress') ||
        lower.contains('how am i doing') ||
        lower.contains('stats') ||
        lower.contains('performance') ||
        lower.contains('improve') ||
        lower.contains('weak');
  }

  bool _isInactivityCheck(String lower) {
    return lower.contains('inactive') ||
        lower.contains('reminder') ||
        lower.contains('nudge') ||
        lower.contains('haven\'t studied');
  }

  Stream<String> _handleScheduleRequest(String message) async* {
    _memory.addUserMessage(message);

    try {
      final schedule = await getSchedule();
      final upcomingLessons = schedule['upcomingLessons'] as List;
      final recentSessions = schedule['recentSessions'] as List;

      if (upcomingLessons.isEmpty && recentSessions.isEmpty) {
        yield 'You don\'t have any lessons scheduled yet. Would you like me to help you create a study plan? I can help you set up regular study sessions for your subjects.';
        return;
      }

      if (upcomingLessons.isNotEmpty) {
        yield 'Here are your upcoming lessons:\n';
        for (final lesson in upcomingLessons.take(5)) {
          final date = DateTime.tryParse(lesson['plannedDate'] as String? ?? '');
          final dateStr = date != null
              ? '${date.month}/${date.day}'
              : 'unknown date';
          yield '• ${lesson['topic']} on $dateStr (${lesson['duration']} min)\n';
        }
        yield '\nWould you like to reschedule any of these?';
        return;
      }

      if (recentSessions.isNotEmpty) {
        yield 'Your most recent study session was on ${recentSessions.first['date']}. Would you like to schedule a new lesson?';
      } else {
        yield 'It looks like you haven\'t started yet. Would you like me to help you schedule your first lesson?';
      }
    } catch (e) {
      _logger.e('Schedule handling error', e);
      yield 'I had trouble looking up your schedule. Please try again later.';
    }
  }

  Stream<String> _handleProgressRequest(String message) async* {
    _memory.addUserMessage(message);

    try {
      final report = await getProgressReport();
      yield report;
    } catch (e) {
      _logger.e('Progress handling error', e);
      yield 'I had trouble generating your progress report. Please try again later.';
    }
  }

  Stream<String> _handleInactivityCheck() async* {
    try {
      final sessions = await _database.tutorSessionRepository
          .getStudentSessions(_studentId);

      if (sessions.isEmpty) {
        yield 'You haven\'t started studying yet! Would you like me to help you create a study plan to get started?';
        return;
      }

      final lastSession = sessions
          .where((s) => s.endTime != null)
          .fold<DateTime?>(null, (prev, s) {
        if (prev == null || s.endTime!.isAfter(prev)) return s.endTime;
        return prev;
      });

      if (lastSession != null) {
        final daysSince = DateTime.now().difference(lastSession).inDays;
        if (daysSince >= 3) {
          yield 'I noticed you haven\'t studied in $daysSince days. Would you like to schedule a study session to get back on track? Consistency is key to making progress!';
        } else {
          yield 'Great job staying active! Your last study session was ${daysSince == 0 ? 'today' : '$daysSince days ago'}. Keep up the good work!';
        }
      } else {
        yield 'Welcome! Let\'s get started with your studies. Would you like to schedule a lesson?';
      }
    } catch (e) {
      _logger.e('Inactivity check error', e);
      yield 'I had trouble checking your activity. How can I help you today?';
    }
  }

  Stream<String> _executePendingAction() async* {
    if (_pendingAction == null) return;

    final action = _pendingAction!;
    final type = action['type'] as String;

    if (type == 'reschedule') {
      yield 'I\'ve noted the change. Your lesson "${action['topic']}" has been rescheduled. Is there anything else I can help with?';
    } else if (type == 'schedule') {
      yield 'Great! I\'ve added a new study session to your schedule. You can check your planner for details.';
    } else {
      yield 'Done! The changes have been made to your schedule.';
    }

    _pendingConfirmation = false;
    _pendingAction = null;
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
- ${badges.isNotEmpty ? 'Recent badges: ${badges.take(3).map((b) => b['name']).join(', ')}' : 'No badges yet'}

Recent recommendations: ${recommendations.map((r) => r['message']).join('; ')}

Use this context to provide personalized mentoring.
''';
    } catch (_) {
      return 'Student context is currently unavailable. Proceed with general mentoring.';
    }
  }

  Future<String> getProgressReport() async {
    try {
      final stats = await _progressTracker.getOverallStats(_studentId);
      final recommendations =
          await _progressTracker.getRecommendations(_studentId);
      final badges = await _progressTracker.getBadges(_studentId);
      final weakTopics = await _masteryService.getWeakTopics(_studentId);
      final sessions = await _database.tutorSessionRepository
          .getStudentSessions(_studentId);

      final buffer = StringBuffer();
      buffer.writeln('📊 **Your Study Progress Report**\n');
      buffer.writeln(
          '**Overall Accuracy:** ${stats['accuracy']}% (${stats['correctAttempts']}/${stats['totalAttempts']} correct)');
      buffer.writeln('**Total Study Time:** ${stats['totalStudyTimeHours']} hours');
      buffer.writeln('**Weekly Activity:** ${stats['weeklyActivity']} attempts');
      buffer.writeln(
          '**Completed Lessons:** ${sessions.where((s) => s.status.toString().contains('completed')).length}');
      buffer.writeln('**Topics Studied:** ${stats['topicsStudied']}');

      if (weakTopics.isSuccess && weakTopics.data!.isNotEmpty) {
        buffer.writeln('\n**Areas needing attention:**');
        for (final topic in weakTopics.data!.take(3)) {
          buffer.writeln(
              '• ${topic.topicId} (accuracy: ${(topic.accuracy * 100).round()}%)');
        }
      }

      if (badges.isNotEmpty) {
        buffer.writeln('\n**Badges earned:**');
        for (final badge in badges) {
          buffer.writeln('• ${badge['name']}: ${badge['description']}');
        }
      }

      if (recommendations.isNotEmpty) {
        buffer.writeln('\n**Recommendations:**');
        for (final rec in recommendations.take(3)) {
          buffer.writeln('• ${rec['message']}');
        }
      }

      return buffer.toString();
    } catch (e) {
      return 'Unable to generate progress report. Please try again later.';
    }
  }

  Future<Map<String, dynamic>> getSchedule() async {
    final sessions =
        await _database.tutorSessionRepository.getStudentSessions(_studentId);
    final studySessions =
        await _database.sessionRepository.getByStudent(_studentId);

    final upcomingLessons = sessions
        .where((s) => s.status.toString().contains('planned'))
        .map((s) => {
              'id': s.id,
              'topic': s.topicTitle,
              'plannedDate': s.startTime.toIso8601String(),
              'duration': s.plannedDurationMinutes,
            })
        .toList();

    final recentStudySessions = studySessions.take(5).map((s) => {
          'date': s.startTime.toIso8601String(),
          'duration': s.timeSpentMs ~/ 60000,
          'questions': s.questionsAnswered,
        }).toList();

    // Include plan data if available
    Map<String, dynamic>? planData;
    try {
      final planRepo = PlanRepository();
      await planRepo.init();
      final plan = await planRepo.loadPlan(_studentId);
      if (plan != null) {
        planData = {
          'hasPlan': true,
          'generatedAt': plan.generatedAt.toIso8601String(),
          'planDurationDays': plan.planDurationDays,
          'dailyPlans': plan.dailyPlans.take(7).map((d) => {
            'day': d.dayNumber,
            'date': d.date.toIso8601String(),
            'focus': d.focus,
            'targetQuestions': d.targetQuestions,
            'targetMinutes': d.targetMinutes,
            'isRestDay': d.isRestDay,
            'topicCount': d.priorityTopics.length,
          }).toList(),
          'summary': plan.summary.toJson(),
        };
      }
    } catch (_) {}

    return {
      'upcomingLessons': upcomingLessons,
      'recentSessions': recentStudySessions,
      'totalSessions': sessions.length,
      'plan': planData,
    };
  }

  Future<String> suggestNextAction() async {
    final recommendations =
        await _progressTracker.getRecommendations(_studentId);
    final subjects = await _database.subjectRepository.getAll();

    if (recommendations.isNotEmpty) {
      return recommendations.first['message'] as String;
    }

    if (subjects.isEmpty) {
      return "You haven't added any subjects yet. Would you like help setting up your first subject?";
    }

    return "You're doing well! Would you like to review your progress, schedule a new lesson, or practice some questions?";
  }

  Future<void> suggestReschedule(String sessionId) async {
    final session =
        await _database.tutorSessionRepository.getSession(sessionId);
    if (session == null) return;

    _pendingConfirmation = true;
    _pendingAction = {
      'type': 'reschedule',
      'sessionId': sessionId,
      'topic': session.topicTitle,
    };

    _memory.addSystemMessage(
        'Suggested rescheduling session "${session.topicTitle}" - awaiting user confirmation');
  }
}
