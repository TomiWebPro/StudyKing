import 'dart:async';
import '../../../core/data/database_service.dart';
import '../../../core/services/llm/llm_chat_service.dart';
import '../../../core/services/mastery_graph_service.dart';
import '../../../core/services/study_progress_tracker.dart';
import '../../../core/services/instrumentation_service.dart';
import '../../../core/data/repositories/plan_repository.dart';
import '../../../core/utils/logger.dart';
import '../../../l10n/generated/app_localizations.dart';

class MentorService {
  final DatabaseService _database;
  final LlmService _llmService;
  final MasteryGraphService _masteryService;
  final StudyProgressTracker _progressTracker;
  final InstrumentationService _instrumentation;
  final String _modelId;
  final ConversationMemory _memory;
  final String _studentId;
  final AppLocalizations _l10n;
  final Logger _logger = const Logger('MentorService');

  bool _pendingConfirmation = false;
  Map<String, dynamic>? _pendingAction;

  MentorService({
    required DatabaseService database,
    required LlmService llmService,
    required MasteryGraphService masteryService,
    required StudyProgressTracker progressTracker,
    InstrumentationService? instrumentation,
    required String modelId,
    required String studentId,
    required AppLocalizations l10n,
  })  : _database = database,
        _llmService = llmService,
        _masteryService = masteryService,
        _progressTracker = progressTracker,
        _instrumentation = instrumentation ?? InstrumentationService(),
        _modelId = modelId,
        _studentId = studentId,
        _l10n = l10n,
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
        yield _l10n.mentorRejectionResponse;
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
        lower.contains('please do') ||
        lower.contains('sí') ||
        lower.contains('claro') ||
        lower.contains('vale') ||
        lower.contains('confirmar') ||
        lower.contains('adelante');
  }

  bool _isRejection(String lower) {
    return lower.contains('no') ||
        lower.contains("don't") ||
        lower.contains("not") ||
        lower.contains("never mind") ||
        lower.contains("cancel") ||
        lower.contains('no quiero') ||
        lower.contains('cancelar') ||
        lower.contains('ningún cambio') ||
        lower.contains('para nada');
  }

  bool _isScheduleRequest(String lower) {
    return lower.contains('schedule') ||
        lower.contains('reschedule') ||
        lower.contains('plan') ||
        lower.contains('lesson') ||
        lower.contains('when') ||
        lower.contains('next study') ||
        lower.contains('programar') ||
        lower.contains('reprogramar') ||
        lower.contains('planificar') ||
        lower.contains('lección') ||
        lower.contains('cuándo') ||
        lower.contains('próximo estudio');
  }

  bool _isProgressRequest(String lower) {
    return lower.contains('progress') ||
        lower.contains('how am i doing') ||
        lower.contains('stats') ||
        lower.contains('performance') ||
        lower.contains('improve') ||
        lower.contains('weak') ||
        lower.contains('progreso') ||
        lower.contains('cómo voy') ||
        lower.contains('estadísticas') ||
        lower.contains('rendimiento') ||
        lower.contains('mejorar') ||
        lower.contains('débil');
  }

  bool _isInactivityCheck(String lower) {
    return lower.contains('inactive') ||
        lower.contains('reminder') ||
        lower.contains('nudge') ||
        lower.contains('haven\'t studied') ||
        lower.contains('inactivo') ||
        lower.contains('recordatorio') ||
        lower.contains('no he estudiado') ||
        lower.contains('cuánto tiempo');
  }

  Stream<String> _handleScheduleRequest(String message) async* {
    _memory.addUserMessage(message);

    try {
      final schedule = await getSchedule();
      final upcomingLessons = schedule['upcomingLessons'] as List;
      final recentSessions = schedule['recentSessions'] as List;

      if (upcomingLessons.isEmpty && recentSessions.isEmpty) {
        yield _l10n.mentorNoLessonsScheduled;
        return;
      }

      if (upcomingLessons.isNotEmpty) {
        yield _l10n.mentorUpcomingLessonsHeader;
        for (final lesson in upcomingLessons.take(5)) {
          final date = DateTime.tryParse(lesson['plannedDate'] as String? ?? '');
          final dateStr = date != null
              ? '${date.month}/${date.day}'
              : 'unknown date';
          yield _l10n.mentorLessonEntry(
            lesson['topic'] as String,
            dateStr,
            lesson['duration'] as int,
          );
        }
        yield _l10n.mentorReschedulePrompt;
        return;
      }

      if (recentSessions.isNotEmpty) {
        yield _l10n.mentorRecentSessionOnDate(
          recentSessions.first['date'] as String,
        );
      } else {
        yield _l10n.mentorNotStarted;
      }
    } catch (e) {
      _logger.e('Schedule handling error', e);
      yield _l10n.mentorScheduleError;
    }
  }

  Stream<String> _handleProgressRequest(String message) async* {
    _memory.addUserMessage(message);

    try {
      final report = await getProgressReport();
      yield report;
    } catch (e) {
      _logger.e('Progress handling error', e);
      yield _l10n.mentorProgressError;
    }
  }

  Stream<String> _handleInactivityCheck() async* {
    try {
      final sessions = await _database.tutorSessionRepository
          .getStudentSessions(_studentId);

      if (sessions.isEmpty) {
        yield _l10n.mentorNotStartedStudying;
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
          yield _l10n.mentorInactiveDays(daysSince);
        } else {
          final daysAgo = daysSince == 0
              ? _l10n.mentorToday
              : _l10n.mentorDaysAgo(daysSince);
          yield _l10n.mentorGreatJobStayingActive(daysAgo);
        }
      } else {
        yield _l10n.mentorWelcomeStart;
      }
    } catch (e) {
      _logger.e('Inactivity check error', e);
      yield _l10n.mentorActivityCheckError;
    }
  }

  Stream<String> _executePendingAction() async* {
    if (_pendingAction == null) return;

    final action = _pendingAction!;
    final type = action['type'] as String;

    if (type == 'reschedule') {
      yield _l10n.mentorRescheduledConfirmation(action['topic'] as String);
    } else if (type == 'schedule') {
      yield _l10n.mentorNewSessionAdded;
    } else {
      yield _l10n.mentorChangesDone;
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
- Respond in the same language the student uses
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

      // Plan adherence data
      String adherenceInfo = 'No plan adherence data available.';
      try {
        final dashboard = await _instrumentation.getInstrumentationDashboard(_studentId);
        if (dashboard.isSuccess) {
          final data = dashboard.data!;
          final adherence = data['planAdherence'] as Map<String, dynamic>?;
          if (adherence != null) {
            final avg = (adherence['averageAdherence'] as double? ?? 0.0);
            final weekly = (adherence['weeklyAdherenceAvg'] as double? ?? 0.0);
            final lowAdherenceDays = adherence['consecutiveLowDays'] as int? ?? 0;
            adherenceInfo = 'Plan adherence: ${(avg * 100).round()}% overall, ${(weekly * 100).round()}% this week.';
            if (lowAdherenceDays >= 3) {
              adherenceInfo += ' WARNING: Student has had $lowAdherenceDays consecutive days of low adherence — suggest plan adjustment.';
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
      buffer.writeln(_l10n.mentorProgressReportTitle);
      buffer.writeln(_l10n.mentorOverallAccuracy(
        '${stats['accuracy']}',
        '${stats['correctAttempts']}',
        '${stats['totalAttempts']}',
      ));
      buffer.writeln(
          _l10n.mentorTotalStudyTime('${stats['totalStudyTimeHours']}'));
      buffer.writeln(
          _l10n.mentorWeeklyActivity('${stats['weeklyActivity']}'));
      buffer.writeln(_l10n.mentorCompletedLessons(
          '${sessions.where((s) => s.status.toString().contains('completed')).length}'));
      buffer.writeln(
          _l10n.mentorTopicsStudied('${stats['topicsStudied']}'));

      if (weakTopics.isSuccess && weakTopics.data!.isNotEmpty) {
        buffer.writeln(_l10n.mentorAreasNeedingAttention);
        for (final topic in weakTopics.data!.take(3)) {
          buffer.writeln(_l10n.mentorTopicAccuracyEntry(
            topic.topicId,
            (topic.accuracy * 100).round(),
          ));
        }
      }

      if (badges.isNotEmpty) {
        buffer.writeln(_l10n.mentorBadgesEarned);
        for (final badge in badges) {
          buffer.writeln(_l10n.mentorBadgeEntry(
            badge['name'] as String,
            badge['description'] as String,
          ));
        }
      }

      if (recommendations.isNotEmpty) {
        buffer.writeln(_l10n.mentorRecommendations);
        for (final rec in recommendations.take(3)) {
          buffer.writeln(
              _l10n.mentorRecommendationEntry(rec['message'] as String));
        }
      }

      return buffer.toString();
    } catch (e) {
      return _l10n.mentorProgressReportError;
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
      return _l10n.mentorNoSubjects;
    }

    return _l10n.mentorDoingWell;
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
