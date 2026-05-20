import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/teaching/data/models/lesson_plan_model.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_agent/llm_agent.dart';
import 'package:studyking/core/utils/study_utils.dart';
import 'package:studyking/core/services/long_term_memory.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/core/services/voice_service.dart';
import 'conversation_manager.dart';
import 'exercise_evaluator.dart';

class TutorService {
  static final Logger _logger = const Logger('TutorService');
  final DatabaseService _database;
  final LlmService _llmService;
  final MasteryGraphService _masteryService;
  final String _modelId;
  final PlanAdherenceOrchestrator _planOrchestrator;
  final ExerciseEvaluator _exerciseEvaluator;
  final Clock _clock;
  final ConversationRepository _conversationRepository;
  final LessonRepository _lessonRepository;
  final VoiceService? _voiceService;
  final LongTermMemory? _longTermMemory;
  LlmAgent? _llmAgent;
  ConversationManager? _currentManager;
  String? _scheduledSessionId;
  String? _currentLessonId;
  List<LessonBlock>? _currentLessonBlocks;
  String _localeName = 'en';

  TutorService({
    required DatabaseService database,
    required LlmService llmService,
    required MasteryGraphService masteryService,
    required String modelId,
    required ExerciseEvaluator exerciseEvaluator,
    required ConversationRepository conversationRepository,
    LessonRepository? lessonRepository,
    PlanAdherenceOrchestrator? planOrchestrator,
    VoiceService? voiceService,
    LlmAgent? llmAgent,
    LongTermMemory? longTermMemory,
    Clock? clock,
  })  : _database = database,
        _llmService = llmService,
        _masteryService = masteryService,
        _modelId = modelId,
        _exerciseEvaluator = exerciseEvaluator,
        _conversationRepository = conversationRepository,
        _lessonRepository = lessonRepository ?? LessonRepository(),
        _planOrchestrator = planOrchestrator ?? PlanAdherenceOrchestrator(),
        _voiceService = voiceService,
        _llmAgent = llmAgent,
        _longTermMemory = longTermMemory,
        _clock = clock ?? SystemClock();

  ConversationManager? get currentManager => _currentManager;

  List<LessonBlock>? get currentLessonBlocks => _currentLessonBlocks;

  set llmAgent(LlmAgent? agent) => _llmAgent = agent;

  int _getDefaultDurationMinutes() {
    try {
      if (!Hive.isBoxOpen(HiveBoxNames.settings)) return 45;
      final box = Hive.box(HiveBoxNames.settings);
      final stored = box.get('defaultTeachingDuration', defaultValue: 45) as int;
      return stored > 0 && stored <= 480 ? stored : 45;
    } catch (e) {
      _logger.w('Failed to read default teaching duration from Hive', e);
      return 45;
    }
  }

  Future<ConversationManager> startLesson({
    required String studentId,
    required String subjectId,
    required String topicId,
    required String topicTitle,
    int durationMinutes = 0,
    String? scheduledSessionId,
    required String localeName,
  }) async {
    _localeName = localeName;
    _scheduledSessionId = scheduledSessionId;
    final actualDuration = durationMinutes > 0 ? durationMinutes : _getDefaultDurationMinutes();
    final sessionId = 'tutor_${_clock.now().millisecondsSinceEpoch}';

    final session = TutorSession(
      id: sessionId,
      studentId: studentId,
      subjectId: subjectId,
      topicId: topicId,
      topicTitle: topicTitle,
      status: SessionStatus.inProgress,
      startTime: _clock.now(),
      plannedDurationMinutes: actualDuration,
    );
    await _database.tutorSessionRepository.saveSession(session);

    if (scheduledSessionId != null) {
      try {
        final existingResult = await _database.sessionRepository.get(scheduledSessionId);
        if (existingResult.isSuccess && existingResult.data != null) {
          final updatedSession = existingResult.data!.copyWith(
            status: SessionStatus.inProgress,
          );
          await _database.sessionRepository.save(updatedSession.id, updatedSession);
        }
      } catch (e) {
        _logger.w('Failed to update scheduled session to inProgress', e);
      }
    }

    final manager = ConversationManager(
      llmService: _llmService,
      modelId: _modelId,
      sessionId: sessionId,
      studentId: studentId,
      topicTitle: topicTitle,
      subjectId: subjectId,
      topicId: topicId,
      scheduledSessionId: scheduledSessionId,
      exerciseEvaluator: _exerciseEvaluator,
      persistenceRepo: _conversationRepository,
      clock: _clock,
      localeName: localeName,
      voiceService: _voiceService,
    );

    try {
      await manager.initialize();

      final lessonPlan = await manager.generateLessonPlan(
        durationMinutes: actualDuration,
      );

      await _database.tutorSessionRepository.saveSession(
        session.copyWith(lessonPlanJson: lessonPlan.toJsonString()),
      );

      await _lessonRepository.init();
      final lesson = Lesson(
        id: const Uuid().v4(),
        subjectId: subjectId,
        title: topicTitle,
        topicId: topicId,
        blocks: _lessonPlanToBlocks(lessonPlan, subjectId, topicId),
        difficulty: 3,
        generatedBy: GeneratedBy.ai,
        createdAt: _clock.now(),
      );
      await _lessonRepository.create(lesson);
      _currentLessonId = lesson.id;
      _currentLessonBlocks = lesson.blocks;

      _currentManager = manager;
      return manager;
    } catch (e) {
      _logger.w('Lesson initialization failed, rolling back session', e);
      await _database.tutorSessionRepository.saveSession(
        session.copyWith(status: SessionStatus.cancelled),
      );
      if (scheduledSessionId != null) {
        try {
          final existingResult = await _database.sessionRepository.get(scheduledSessionId);
          if (existingResult.isSuccess && existingResult.data != null) {
            final restored = existingResult.data!.copyWith(
              status: SessionStatus.planned,
              completed: false,
            );
            await _database.sessionRepository.save(restored.id, restored);
          }
        } catch (restoreErr) {
          _logger.w('Failed to restore scheduled session after rollback', restoreErr);
        }
      }
      rethrow;
    }
  }

  Future<void> endLesson() async {
    if (_currentManager == null) return;

    final session = _currentManager!.toSession();

    await _saveCurrentSession(session);
    await _recordMasteryAttempt(session);
    await _persistExercisesAsQuestions(session);
    await _recordLessonActivity(session);
    await _saveAsSessionModel(session);
    await _updateScheduledSession(session);
    await _updateLessonRecord(session);
    _enqueueBackgroundTasks(session);
    await _generateAndStoreSessionSummary(session);
    _resetState();
  }

  Future<void> _saveCurrentSession(TutorSession session) async {
    await _database.tutorSessionRepository.saveSession(session);
  }

  Future<void> _recordMasteryAttempt(TutorSession session) async {
    if (session.questionsAsked <= 0) return;
    await _masteryService.recordAttempt(
      studentId: session.studentId,
      topicId: session.topicId,
      questionId: 'tutor_${session.id}',
      isCorrect: session.accuracy > 0.5,
      confidence: session.confidenceRating.clamp(0, 5).round(),
      timeSpentMs: _elapsedMinutes(session) * msPerMinute,
    );
  }

  Future<void> _recordLessonActivity(TutorSession session) async {
    try {
      await _planOrchestrator.recordActivity(
        studentId: session.studentId,
        actualMinutes: _elapsedMinutes(session).clamp(1, 480),
      );
    } catch (e) {
      _logger.w('Failed to record tutor session to plan adapter', e);
    }
  }

  Future<void> _saveAsSessionModel(TutorSession session) async {
    try {
      final now = _clock.now();
      final elapsedMs = _elapsedMinutes(session) * msPerMinute;
      final sessionToSave = Session(
        id: session.id,
        studentId: session.studentId,
        subjectId: session.subjectId,
        topicId: session.topicId,
        sourceId: session.id,
        type: SessionType.tutoring,
        startTime: session.startTime,
        endTime: session.endTime ?? now,
        actualDurationMs: elapsedMs,
        questionsAnswered: session.questionsAsked,
        correctAnswers: session.questionsCorrect,
        completed: session.status == SessionStatus.completed,
        tutorMetadata: TutorMetadata(
          topicTitle: session.topicTitle,
          lessonPlanJson: session.lessonPlanJson,
          confidenceRating: session.confidenceRating,
          tutorNotes: session.tutorNotes,
          topicsCovered: session.topicsCovered,
          totalMessages: session.totalMessages,
          totalTokensUsed: session.totalTokensUsed,
        ),
      );
      await _database.sessionRepository.save(sessionToSave.id, sessionToSave);
    } catch (e) {
      _logger.w('Failed to save tutor session as Session', e);
    }
  }

  Future<void> _updateScheduledSession(TutorSession session) async {
    if (_scheduledSessionId == null) return;
    try {
      final existingResult = await _database.sessionRepository.get(_scheduledSessionId!);
      if (existingResult.isSuccess && existingResult.data != null) {
        final completedSession = existingResult.data!.copyWith(
          status: SessionStatus.completed,
          completed: true,
          endTime: session.endTime ?? _clock.now(),
          tutorSessionId: session.id,
        );
        await _database.sessionRepository.save(completedSession.id, completedSession);
      }
    } catch (e) {
      _logger.w('Failed to update scheduled session to completed', e);
    }
  }

  Future<void> _updateLessonRecord(TutorSession session) async {
    if (_currentLessonId == null) return;
    try {
      final lessonResult = await _lessonRepository.get(_currentLessonId!);
      if (lessonResult.isSuccess && lessonResult.data != null) {
        final existing = lessonResult.data!;
        final notesBlock = LessonBlock(
          id: const Uuid().v4(),
          subjectId: session.subjectId,
          lessonId: _currentLessonId!,
          type: LessonBlockType.text,
          content: 'Session completed: ${session.topicTitle}\n'
              'Duration: ${_elapsedMinutes(session)} min\n'
              'Questions: ${session.questionsAsked}\n'
              'Correct: ${session.questionsCorrect}\n'
              'Tutor notes: ${session.tutorNotes ?? "N/A"}',
          order: existing.blocks.length,
        );
        final updated = existing.copyWith(
          blocks: [...existing.blocks, notesBlock],
        );
        await _lessonRepository.create(updated);
      }
    } catch (e) {
      _logger.w('Failed to update lesson record after tutor session', e);
    }
  }

  void _enqueueBackgroundTasks(TutorSession session) {
    if (_llmAgent == null) return;
    _enqueueAdherenceCheck(session.studentId);
    _enqueueWeakTopicAnalysis(session.studentId);
    _enqueueNextTopicPrep(session);
  }

  void _enqueueAdherenceCheck(String studentId) {
    _llmAgent!.enqueueBackgroundTask(
      'Post-lesson adherence update',
      () async {
        try {
          await _planOrchestrator.checkAdherence(studentId);
        } catch (e) {
          _logger.w('Post-lesson adherence update failed', e);
        }
      },
    );
  }

  void _enqueueWeakTopicAnalysis(String studentId) {
    _llmAgent!.enqueueBackgroundTask(
      'Post-lesson weak topic reanalysis',
      () async {
        try {
          await _masteryService.getWeakTopics(studentId);
        } catch (e) {
          _logger.w('Post-lesson weak topic reanalysis failed', e);
        }
      },
    );
  }

  void _enqueueNextTopicPrep(TutorSession session) {
    _llmAgent!.enqueueBackgroundTask(
      'Next topic lesson prep',
      () async {
        try {
          final weakResult = await _masteryService.getWeakTopics(session.studentId);
          if (weakResult.isSuccess && weakResult.data!.isNotEmpty) {
            final nextTopic = weakResult.data!.first;
            final lesson = Lesson(
              id: const Uuid().v4(),
              subjectId: session.subjectId,
              title: nextTopic.topicId,
              topicId: nextTopic.topicId,
              blocks: [
                LessonBlock(
                  id: const Uuid().v4(),
                  subjectId: session.subjectId,
                  lessonId: nextTopic.topicId,
                  type: LessonBlockType.text,
                  content: 'Pre-generated lesson for ${nextTopic.topicId}. Open to start learning.',
                  order: 0,
                ),
              ],
              difficulty: 3,
              generatedBy: GeneratedBy.ai,
              createdAt: _clock.now(),
            );
            await _lessonRepository.init();
            await _lessonRepository.create(lesson);
          }
        } catch (e) {
          _logger.w('Next topic lesson prep failed', e);
        }
      },
    );
  }

  void _resetState() {
    _currentManager = null;
    _scheduledSessionId = null;
    _currentLessonId = null;
    _currentLessonBlocks = null;
  }

  Future<void> _generateAndStoreSessionSummary(TutorSession session) async {
    final ltm = _longTermMemory;
    final manager = _currentManager;
    if (ltm == null || manager == null) return;
    try {
      final messages = ConversationMemory.fromConversationMessages(
        manager.messages,
      );
      if (messages.length < 2) return;
      await ltm.generateAndStoreSummary(
        llmService: _llmService,
        modelId: _modelId,
        studentId: session.studentId,
        sessionId: session.id,
        conversationMessages: messages,
        topicTitle: session.topicTitle,
        exerciseCount: session.questionsAsked,
        correctCount: session.questionsCorrect,
        confidenceRating: session.confidenceRating / 5.0,
      );
    } catch (e) {
      _logger.w('Failed to generate session summary', e);
    }
  }

  List<LessonBlock> _lessonPlanToBlocks(LessonPlan lessonPlan, String subjectId, String topicId) {
    try {
      final planJson = lessonPlan.toJsonString();
      if (planJson.isEmpty) return _fallbackBlocks(subjectId, topicId);
      return _parseBlocks(planJson, subjectId, topicId);
    } catch (e) {
      _logger.w('Failed to convert lesson plan to blocks', e);
      return _fallbackBlocks(subjectId, topicId);
    }
  }

  List<LessonBlock> _parseBlocks(String json, String subjectId, String topicId) {
    try {
      final data = jsonDecode(json);
      if (data is List) {
        return data.asMap().entries.map((entry) {
          final map = entry.value as Map<String, dynamic>;
          return _blockFromJson(map, entry.key, subjectId, topicId);
        }).toList();
      }
      if (data is Map && data.containsKey('blocks')) {
        final blocks = data['blocks'] as List;
        return blocks.asMap().entries.map((entry) {
          final map = entry.value as Map<String, dynamic>;
          return _blockFromJson(map, entry.key, subjectId, topicId);
        }).toList();
      }
    } catch (e) {
      _logger.w('Failed to parse lesson plan JSON', e);
    }
    return _fallbackBlocks(subjectId, topicId);
  }

  LessonBlock _blockFromJson(Map<String, dynamic> map, int index, String subjectId, String topicId) {
    final typeStr = map['type'] as String? ?? 'text';
    final type = LessonBlockType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => LessonBlockType.text,
    );
    return LessonBlock(
      id: const Uuid().v4(),
      subjectId: subjectId,
      lessonId: topicId,
      type: type,
      content: map['content'] as String? ?? '',
      order: index,
    );
  }

  List<LessonBlock> _fallbackBlocks(String subjectId, String topicId) {
    final l10n = lookupAppLocalizations(Locale(_localeName));
    return [
      LessonBlock(
        id: const Uuid().v4(),
        subjectId: subjectId,
        lessonId: topicId,
        type: LessonBlockType.text,
        content: l10n.lessonPlanFallbackTitle,
        order: 0,
      ),
    ];
  }

  int _elapsedMinutes(TutorSession session) {
    final end = session.endTime ?? _clock.now();
    return end.difference(session.startTime).inMinutes;
  }

  Future<void> _persistExercisesAsQuestions(TutorSession session) async {
    final manager = _currentManager;
    if (manager == null || manager.exerciseCount == 0) return;

    final evalResult = manager.lastEvaluationResult;
    if (evalResult == null) return;

    final now = _clock.now();
    final questionText = manager.capturedExerciseQuestion.isNotEmpty
        ? manager.capturedExerciseQuestion
        : _findExerciseQuestionFromMessages(manager, session.topicTitle);
    final qId = const Uuid().v4();
    final questionType = _parseTutorQuestionType(evalResult.exerciseType);
    final options = evalResult.options ?? <String>[];

    final question = Question(
      id: qId,
      text: questionText,
      type: questionType,
      difficulty: (evalResult.score * 5).round().clamp(1, 5),
      subjectId: session.subjectId,
      topicId: session.topicId,
      sourceIds: ['tutor_${session.id}'],
      createdAt: now,
      updatedAt: now,
      options: options,
      markscheme: evalResult.correctAnswer != null
          ? Markscheme(
              questionId: qId,
              correctAnswer: evalResult.correctAnswer!,
              explanation: evalResult.explanation,
              acceptableAnswers: [evalResult.correctAnswer!],
            )
          : null,
      explanation: evalResult.explanation,
    );

    await _database.questionRepository.create(question);
  }

  String _findExerciseQuestionFromMessages(
      ConversationManager manager, String topicTitle) {
    try {
      final messages = manager.messages;
      for (var i = messages.length - 1; i >= 0; i--) {
        final msg = messages[i];
        if (msg.role == MessageRole.tutor && msg.content.isNotEmpty) {
          return msg.content;
        }
      }
    } catch (e) {
      _logger.w('Failed to find exercise question in messages', e);
    }
    return 'Tutor exercise: $topicTitle';
  }

  QuestionType _parseTutorQuestionType(String? typeStr) {
    if (typeStr == null) return QuestionType.typedAnswer;
    for (final t in QuestionType.values) {
      if (t.name == typeStr) return t;
    }
    return QuestionType.typedAnswer;
  }

  Future<List<TutorSession>> getLessonHistory(String studentId) async {
    final result =
        await _database.tutorSessionRepository.getStudentSessions(studentId);
    return result.data ?? [];
  }

  Future<List<ConversationMessage>> getSessionMessages(
      String sessionId) async {
    final result =
        await _database.conversationRepository.getSessionMessages(sessionId);
    return result.data ?? [];
  }

  Future<Map<String, dynamic>> getStats(String studentId) async {
    final result =
        await _database.tutorSessionRepository.getSessionStats(studentId);
    return result.data ?? {};
  }

  Future<void> saveMessage(ConversationMessage message) async {
    await _database.conversationRepository.saveMessage(message);
  }

  Future<TutorSession?> getActiveSession() async {
    final result =
        await _database.tutorSessionRepository.getActiveSessions();
    final sessions = result.data ?? [];
    return sessions.isNotEmpty ? sessions.first : null;
  }

  Future<void> cancelActiveSession() async {
    if (_currentManager == null) return;
    final session = _currentManager!.toSession();
    final cancelled = session.copyWith(
      status: SessionStatus.cancelled,
    );
    await _database.tutorSessionRepository.saveSession(cancelled);

    if (_scheduledSessionId != null) {
      try {
        final existingResult = await _database.sessionRepository.get(_scheduledSessionId!);
        if (existingResult.isSuccess && existingResult.data != null) {
          final restored = existingResult.data!.copyWith(
            status: SessionStatus.planned,
            completed: false,
          );
          await _database.sessionRepository.save(restored.id, restored);
        }
      } catch (e) {
        _logger.w('Failed to restore scheduled session after discard', e);
      }
    }

    _currentManager = null;
    _scheduledSessionId = null;
    _currentLessonId = null;
    _currentLessonBlocks = null;
  }
}
