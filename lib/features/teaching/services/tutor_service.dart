import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/services/settings_service.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/teaching/data/repositories/lesson_feedback_repository.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/teaching/data/models/lesson_plan_model.dart';
import 'package:studyking/features/teaching/data/repositories/lesson_recap_repository.dart';
import 'package:studyking/features/teaching/services/lesson_recap_service.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_agent/llm_agent.dart';
import 'package:studyking/core/services/llm_agent/idle_executor.dart'
    show IdleTask, TaskReconstructor;
import 'package:studyking/core/services/prep_budget.dart' show PrepCategory;
import 'package:studyking/features/mentor/services/tools/pre_generate_lesson_tool.dart';
import 'package:studyking/core/utils/study_utils.dart';
import 'package:studyking/core/services/long_term_memory.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/core/services/voice_service.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'conversation_manager.dart';
import 'exercise_evaluator.dart';
import 'feedback_analyzer.dart';
import 'lesson_plan_context_builder.dart';
import 'mastery_context_builder.dart';

class TutorService {
  static final Logger _logger = const Logger('TutorService');

  /// Difficulty stored on questions persisted from tutor exercises.
  /// The exercise carries no intrinsic difficulty metadata, so a neutral
  /// default is used instead of deriving it from the student's score.
  static const int _defaultQuestionDifficulty = 3;
  final DatabaseService _database;
  final LlmService _llmService;
  final MasteryGraphService _masteryService;
  final SpacedRepetitionService _spacedRepetitionService;
  final String _modelId;
  final PlanAdherenceOrchestrator _planOrchestrator;
  final ExerciseEvaluator _exerciseEvaluator;
  final Clock _clock;
  final ConversationRepository _conversationRepository;
  final LessonRepository _lessonRepository;
  final TopicRepository _topicRepository;
  final LessonRecapService _lessonRecapService;
  final VoiceService? _voiceService;
  final LongTermMemory? _longTermMemory;
  final LessonFeedbackRepository _feedbackRepository;
  final PlannerService? _plannerService;
  final PreGenerateLessonTool? _preGenerateLessonTool;
  late final FeedbackAnalyzer _feedbackAnalyzer;
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
    required SpacedRepetitionService spacedRepetitionService,
    required String modelId,
    required ExerciseEvaluator exerciseEvaluator,
    required ConversationRepository conversationRepository,
    LessonRepository? lessonRepository,
    LessonRecapService? lessonRecapService,
    PlanAdherenceOrchestrator? planOrchestrator,
    VoiceService? voiceService,
    LlmAgent? llmAgent,
    LongTermMemory? longTermMemory,
    LessonFeedbackRepository? feedbackRepository,
    PlannerService? plannerService,
    PreGenerateLessonTool? preGenerateLessonTool,
    TopicRepository? topicRepository,
    Clock? clock,
  })  : _database = database,
        _llmService = llmService,
        _masteryService = masteryService,
        _spacedRepetitionService = spacedRepetitionService,
        _modelId = modelId,
        _exerciseEvaluator = exerciseEvaluator,
        _conversationRepository = conversationRepository,
        _lessonRepository = lessonRepository ?? LessonRepository(),
        _lessonRecapService = lessonRecapService ??
            LessonRecapService(
              llmService: llmService,
              modelId: modelId,
              repository: LessonRecapRepository(),
              localeName: 'en',
            ),
        _planOrchestrator = planOrchestrator ?? PlanAdherenceOrchestrator(),
        _voiceService = voiceService,
        _longTermMemory = longTermMemory,
        _feedbackRepository = feedbackRepository ?? LessonFeedbackRepository(),
        _plannerService = plannerService,
        _preGenerateLessonTool = preGenerateLessonTool,
        _topicRepository = topicRepository ?? TopicRepository(),
        _clock = clock ?? SystemClock() {
    _attachLlmAgent(llmAgent);
    _feedbackAnalyzer = FeedbackAnalyzer(_feedbackRepository);
  }

  ConversationManager? get currentManager => _currentManager;

  List<LessonBlock>? get currentLessonBlocks => _currentLessonBlocks;

  LlmAgent? get llmAgent => _llmAgent;

  set llmAgent(LlmAgent? agent) => _attachLlmAgent(agent);

  /// Stores the [LlmAgent] and, when non-null, registers a
  /// [TaskReconstructor] on its [IdleExecutor] so that post-lesson prep tasks
  /// restored from persistence (which arrive with `taskFn == null`) are
  /// re-attached to their executable closures instead of being silently
  /// drained as no-ops (Vision Next-Term §4.1/§4.2 "Prepare while I'm away").
  ///
  /// Called both from the constructor (when [LlmAgent] is injected at
  /// construction time) and from the [llmAgent] setter (when TutorScreen
  /// wires the agent after provider creation). Mirrors the IngestionProvider
  /// pattern at `bulk_ingestion_service.dart:328-349`.
  void _attachLlmAgent(LlmAgent? agent) {
    _llmAgent = agent;
    if (agent != null) {
      _registerPrepTaskReconstructor(agent);
    }
  }

  /// Builds and registers a [TaskReconstructor] on [agent]'s [IdleExecutor]
  /// that re-attaches executable closures for the three post-lesson prep task
  /// kinds encoded in each task's `payload` JSON:
  /// - `adherence_check` → [_planOrchestrator.checkAdherence]
  /// - `weak_topic_reanalysis` → [_masteryService.getWeakTopics]
  /// - `next_topic_lesson_prep` → [generateNextTopicLesson]
  ///
  /// Each task carries a `studentId` (and `subjectId` for lesson_prep) in its
  /// payload, so the reconstructed closure can re-run the same service method
  /// that originally enqueued the task — without the original `TutorSession`,
  /// which cannot survive process termination.
  void _registerPrepTaskReconstructor(LlmAgent agent) {
    agent.idleExecutor.setTaskReconstructor((IdleTask task) {
      final payload = task.payload;
      if (payload == null) return null;

      String? kind;
      String? studentId;
      try {
        final json = jsonDecode(payload) as Map<String, dynamic>;
        kind = json['kind'] as String?;
        studentId = json['studentId'] as String?;
      } catch (e) {
        _logger.w('Failed to parse prep task payload: $payload', e);
        return null;
      }

      if (kind == null || studentId == null) return null;

      final sid = studentId;
      final orchestrator = _planOrchestrator;
      final mastery = _masteryService;

      switch (kind) {
        case 'adherence_check':
          return () async {
            try {
              await orchestrator.checkAdherence(sid);
            } catch (e) {
              _logger.w('Restored adherence check failed', e);
              rethrow;
            }
          };
        case 'weak_topic_reanalysis':
          return () async {
            try {
              await mastery.getWeakTopics(sid);
            } catch (e) {
              _logger.w('Restored weak topic reanalysis failed', e);
              rethrow;
            }
          };
        case 'next_topic_lesson_prep':
          final subjectId = task.subjectId;
          if (subjectId == null) return null;
          final self = this;
          final session = TutorSession(
            id: 'restored_${DateTime.now().millisecondsSinceEpoch}',
            studentId: studentId,
            subjectId: subjectId,
            topicId: '',
            topicTitle: '',
            startTime: _clock.now(),
          );
          return () async {
            final result = await self.generateNextTopicLesson(session);
            final success = result['success'] as bool? ?? false;
            if (!success) {
              throw Exception(
                result['error'] ?? result['message'] ?? 'Lesson prep returned failure',
              );
            }
          };
        default:
          return null;
      }
    });
  }

  int _getDefaultDurationMinutes() {
    try {
      return SettingsService.getTeachingDurationMinutes();
    } catch (e) {
      _logger.w('Failed to read default teaching duration', e);
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

    // Capture the scheduled session so startLesson can check whether a
    // pre-generated lesson is ready to consume (Vision Next-Term §4.3).
    Session? scheduledSession;
    if (scheduledSessionId != null) {
      try {
        final existingResult = await _database.sessionRepository.get(scheduledSessionId);
        if (existingResult.isSuccess && existingResult.data != null) {
          scheduledSession = existingResult.data;
          final updatedSession = scheduledSession!.copyWith(
            status: SessionStatus.inProgress,
          );
          await _database.sessionRepository.save(updatedSession.id, updatedSession);
        }
      } catch (e) {
        _logger.w('Failed to update scheduled session to inProgress', e);
      }
    }

    // Fetch the student's active syllabus goals so the tutor can switch
    // syllabi mid-lesson (agent_must_read.md §100: "Student can dynamically
    // switch syllabi"). Without these, SyllabusSwitchParser has an empty
    // title list and can never match a switch intent.
    final availableSyllabi =
        (await _plannerService?.loadExistingPlan())?.data?.syllabusGoals ?? [];

    final manager = ConversationManager(
      llmService: _llmService,
      modelId: _modelId,
      sessionId: sessionId,
      studentId: studentId,
      topicTitle: topicTitle,
      subjectId: subjectId,
      topicId: topicId,
      scheduledSessionId: scheduledSessionId,
      availableSyllabi: availableSyllabi,
      exerciseEvaluator: _exerciseEvaluator,
      persistenceRepo: _conversationRepository,
      clock: _clock,
      localeName: localeName,
      voiceService: _voiceService,
      // Route live teaching turns through the AgentLoop tool-calling loop so
      // the LLM can invoke teaching tools (explain_differently, suggest_practice,
      // read_source_content, review_mistakes, …) — Vision Next-Term §3.1.
      // Sourced from the LlmAgent TutorScreen already injected via llmAgent;
      // null (no API key) keeps teaching working offline via direct chat.
      agentLoop: _llmAgent?.loop,
    );

    String? lessonPlanError;
    try {
      await manager.initialize();

      final noteResult = await _feedbackAnalyzer.buildTutorContextNote(studentId);
      noteResult.fold(
        (note) {
          if (note.isNotEmpty) manager.feedbackContext = note;
        },
        (error) => _logger.w('Failed to build tutor feedback context', error),
      );

      // Inject the student's weak topics + recent lesson history into the
      // lesson prompt so the tutor adapts to actual progress rather than only
      // the current topic (agent_must_read.md §32-45, §86-96). Both reads
      // return Result and degrade to an empty context when the student has no
      // recorded mastery data yet, so this never blocks lesson start. Awaited
      // so the context is set before the lesson is handed off to the tutor UI.
      await _injectMasteryContext(manager, studentId, subjectId);

      // Vision Next-Term §4.3: live lessons consume pre-built plans, blocks,
      // and knowledge — not raw reasoning from scratch. When the scheduled
      // session already carries a pre-generated lesson (lessonReady +
      // lessonIds, populated by PlannerService.scheduleLesson and
      // PreGenerateLessonTool post-lesson), reuse its stored blocks and skip
      // the live plan-generation LLM call. When no pre-generated lesson is
      // available (lessonReady false, no ids, or lesson missing), fall back
      // to live generation below.
      final preGenerated = scheduledSession != null
          ? await _loadPreGeneratedLesson(scheduledSession)
          : null;

      if (preGenerated != null) {
        // Reuse the pre-built lesson's blocks directly — no fresh LLM call.
        _currentLessonId = preGenerated.id;
        _currentLessonBlocks = preGenerated.blocks;
        _currentManager = manager;
      } else {
        final lessonPlanResult = await manager.generateLessonPlan(
          durationMinutes: actualDuration,
        );
        // generateLessonPlan falls back to a default plan on LLM failure, so
        // a failure here means no plan could be built at all.
        if (lessonPlanResult.isFailure) {
          lessonPlanError =
              lessonPlanResult.error ?? 'Lesson plan generation failed';
        } else {
          final lessonPlan = lessonPlanResult.data!;

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
            // Plan-built lessons are AI-generated and unreviewed until
            // validated (vision_next_term.md §4.3).
            validationStatus: ValidationStatus.pending,
          );
          final createResult = await _lessonRepository.create(lesson);
          if (createResult.isFailure) {
            _logger.w(
              'Failed to persist lesson ${lesson.id}',
              createResult.error,
            );
            lessonPlanError = createResult.error ?? 'Failed to create lesson';
          } else {
            _currentLessonId = lesson.id;
            _currentLessonBlocks = lesson.blocks;

            _currentManager = manager;
          }
        }
      }
      // Vision Next-Term §4.3: inject the active lesson blocks into the tutor
      // prompt so the LLM consumes pre-built artefacts instead of synthesising
      // the course from scratch — a sibling injection to _injectMasteryContext.
      // Both the pre-generated path (preGenerated.blocks) and the live path
      // (lesson.blocks) populate _currentLessonBlocks, so this covers both and
      // lets the tutor cite "the example from my lesson" from pre-built content.
      if (_currentLessonBlocks != null) {
        _injectLessonPlanContext(manager, _currentLessonBlocks!);
      }
    } catch (e) {
      await _rollbackFailedLessonStart(session, scheduledSessionId, e);
      rethrow;
    }
    if (lessonPlanError != null) {
      // No plan could be built or the lesson could not be
      // persisted; roll the session back and propagate the
      // failure to the caller.
      final error = StateError(lessonPlanError);
      await _rollbackFailedLessonStart(session, scheduledSessionId, error);
      return Future.error(error);
    }
    return manager;
  }

  Future<void> _injectMasteryContext(
    ConversationManager manager,
    String studentId,
    String subjectId,
  ) async {
    final weakResult =
        await _masteryService.getWeakTopics(studentId, subjectId: subjectId);
    final historyResult = await getLessonHistory(studentId);
    final context = MasteryContextBuilder().build(
      weakTopics: weakResult.data ?? [],
      recentSessions: historyResult.data ?? [],
    );
    if (context != null && context.isNotEmpty) {
      manager.masteryContext = context;
    }
  }

  /// Builds a bounded "Current lesson plan" note from the active lesson's
  /// pre-built blocks and attaches it to manager.lessonPlanContext so
  /// ConversationPromptSet.tutorMessage serialises it into the tutor system
  /// prompt (Vision Next-Term section 4.3: live lessons consume pre-built
  /// artefacts, not raw reasoning from scratch). Pure, synchronous logic
  /// delegated to LessonPlanContextBuilder; mirrors _injectMasteryContext.
  void _injectLessonPlanContext(
    ConversationManager manager,
    List<LessonBlock> blocks,
  ) {
    final context = LessonPlanContextBuilder().build(blocks: blocks);
    if (context != null && context.isNotEmpty) {
      manager.lessonPlanContext = context;
    }
  }

  /// Rolls back a failed lesson start: marks the tutor session
  /// cancelled and restores a scheduled session to planned so its
  /// slot stays bookable. Shared by the lesson-plan failure path
  /// and the catch block in [startLesson].
  Future<void> _rollbackFailedLessonStart(
    TutorSession session,
    String? scheduledSessionId,
    Object error,
  ) async {
    _logger.w('Lesson initialization failed, rolling back session', error);
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
  }

  Future<void> endLesson() async {
    if (_currentManager == null) return;

    final session = _currentManager!.toSession().copyWith(
      lessonId: _currentLessonId,
    );

    await _saveCurrentSession(session);
    await _recordMasteryAttempt(session);
    await _persistExercisesAsQuestions(session);
    await _markTopicsForPriorityReview(session);
    await _recordLessonActivity(session);
    await _saveAsSessionModel(session);
    await _updateScheduledSession(session);
    await _updateLessonRecord(session);
    _enqueueBackgroundTasks(session);
    await _generateAndStoreSessionSummary(session);
    await _generateAndStoreLessonRecap(session);
    _resetState();
  }

  Future<void> _generateAndStoreLessonRecap(TutorSession session) async {
    final manager = _currentManager;
    if (manager == null) return;
    try {
      await _lessonRecapService.generateAndStoreRecap(
        session: session,
        messages: manager.messages,
        localeName: _localeName,
      );
    } catch (e) {
      _logger.w('Failed to generate lesson recap', e);
    }
  }

  Future<void> _saveCurrentSession(TutorSession session) async {
    await _database.tutorSessionRepository.saveSession(session);
  }

  Future<void> _recordMasteryAttempt(TutorSession session) async {
    if (session.questionsAsked <= 0) return;
    await _masteryService.recordAttempt(
      studentId: session.studentId,
      topicId: session.topicId,
      subjectId: session.subjectId,
      questionId: 'tutor_${session.id}',
      isCorrect: session.accuracy > 0.5,
      confidence: session.confidenceRating.clamp(0, 5).round(),
      timeSpentMs: _elapsedMinutes(session) * msPerMinute,
    );
  }

  Future<void> _markTopicsForPriorityReview(TutorSession session) async {
    try {
      final questionsResult = await _spacedRepetitionService.getTopicTimeDue(session.topicId);
      final questions = questionsResult.data ?? [];
      if (questions.isEmpty) return;
      final now = _clock.now();
      for (final q in questions) {
        final updated = q.copyWith(nextReview: now.subtract(const Duration(hours: 1)));
        await _database.questionRepository.save(q.id, updated);
      }
    } catch (e) {
      _logger.w('Failed to mark topics for priority review', e);
    }
  }

  Future<void> _recordLessonActivity(TutorSession session) async {
    try {
      await _planOrchestrator.recordActivity(
        studentId: session.studentId,
        actualMinutes: _elapsedMinutes(session).clamp(1, 480),
        // Forwarding actualQuestions keeps tutor-session question participation
        // visible to the adherence score, matching the practice path and the
        // vision requirement that all study activities (tutoring, practice,
        // review) feed daily totals.
        actualQuestions: session.questionsAsked,
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
    _llmAgent!.enqueuePrepTask(
      'Post-lesson adherence update',
      () async {
        try {
          await _planOrchestrator.checkAdherence(studentId);
          return {'success': true};
        } catch (e) {
          _logger.w('Post-lesson adherence update failed', e);
          return {'success': false, 'error': e.toString()};
        }
      },
      requiresHeavy: true,
      // Plan adherence update is off-period maintenance — attribute to the
      // generic background prep bucket so the task manager + budget reflect it.
      feature: PrepCategory.background.taskTypeKey,
      taskType: PrepCategory.background.taskTypeKey,
      // Vision Next-Term §4.1: payload carries the task kind + studentId so the
      // TaskReconstructor can rebuild this closure after a restart (closures
      // are not serialised to Hive).
      payload: jsonEncode({'kind': 'adherence_check', 'studentId': studentId}),
    );
  }

  void _enqueueWeakTopicAnalysis(String studentId) {
    _llmAgent!.enqueuePrepTask(
      'Post-lesson weak topic reanalysis',
      () async {
        try {
          await _masteryService.getWeakTopics(studentId);
          return {'success': true};
        } catch (e) {
          _logger.w('Post-lesson weak topic reanalysis failed', e);
          return {'success': false, 'error': e.toString()};
        }
      },
      requiresHeavy: true,
      feature: PrepCategory.background.taskTypeKey,
      taskType: PrepCategory.background.taskTypeKey,
      // Vision Next-Term §4.1: payload carries the task kind + studentId so the
      // TaskReconstructor can rebuild this closure after a restart.
      payload: jsonEncode({'kind': 'weak_topic_reanalysis', 'studentId': studentId}),
    );
  }

  /// Generates a pre-built lesson for the student's next weak topic as an
  /// off-period prep task (Vision Next-Term §4.1: "Lesson pre-generation
  /// ahead of each scheduled lesson").
  ///
  /// When [_preGenerateLessonTool] is wired, this invokes the prep tool so
  /// the lesson receives real structured blocks (slides, examples, exercises,
  /// recap) instead of a one-line placeholder. When the tool is absent, a
  /// minimal placeholder is created so the lesson list is never empty.
  @visibleForTesting
  Future<Map<String, dynamic>> generateNextTopicLesson(TutorSession session) async {
    try {
      final weakResult = await _masteryService.getWeakTopics(session.studentId);
      if (weakResult.isSuccess && weakResult.data!.isNotEmpty) {
        final nextTopic = weakResult.data!.first;
        final subjectId =
            nextTopic.subjectId.isNotEmpty ? nextTopic.subjectId : session.subjectId;

        // Resolve a human-readable topic title from the TopicRepository so
        // pre-generated lessons never surface with an opaque machine ID as
        // their title. Falls back to a labeled form when the topic is absent.
        final topicTitle = await _resolveTopicTitle(nextTopic.topicId, subjectId);

        if (_preGenerateLessonTool != null) {
          final result = await _preGenerateLessonTool.execute({
            'subjectId': subjectId,
            'topicId': nextTopic.topicId,
            'topicTitle': topicTitle,
            'localeName': _localeName,
          });
          return result;
        }

        // Fallback: minimal placeholder when the prep tool is not wired
        // (e.g. no API key). Ensures the lesson list always has content.
        final lesson = Lesson(
          id: const Uuid().v4(),
          subjectId: session.subjectId,
          title: topicTitle,
          topicId: nextTopic.topicId,
          blocks: [
            LessonBlock(
              id: const Uuid().v4(),
              subjectId: session.subjectId,
              lessonId: nextTopic.topicId,
              type: LessonBlockType.text,
              content: 'Pre-generated lesson for $topicTitle. Open to start learning.',
              order: 0,
            ),
          ],
          difficulty: 3,
          generatedBy: GeneratedBy.ai,
          createdAt: _clock.now(),
          // Placeholder lesson (prep tool not wired) is gappy/unreviewed
          // content — flag for validation rather than silently trusted.
          validationStatus: ValidationStatus.pending,
        );
        await _lessonRepository.init();
        await _lessonRepository.create(lesson);
        return {'success': true, 'lessonId': lesson.id};
      }
      return {'success': true};
    } catch (e) {
      _logger.w('Next topic lesson prep failed', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Resolves a human-readable topic title for [topicId] by looking it up in
  /// [_topicRepository]. Returns the topic's `title` when available; otherwise
  /// falls back to a labeled form (`subjectId/topicId`) so pre-generated
  /// lessons never surface with a bare machine identifier as their title.
  ///
  /// The fallback still carries the subject context so a reader can tell which
  /// syllabus the topic belongs to, rather than seeing an opaque ID alone.
  Future<String> _resolveTopicTitle(String topicId, String subjectId) async {
    try {
      final result = await _topicRepository.get(topicId);
      if (result.isSuccess &&
          result.data != null &&
          result.data!.title.isNotEmpty) {
        return result.data!.title;
      }
    } catch (e) {
      _logger.w('Failed to resolve topic title for $topicId', e);
    }
    return '$subjectId/$topicId';
  }

  void _enqueueNextTopicPrep(TutorSession session) {
    if (_llmAgent == null) return;
    _llmAgent!.enqueuePrepTask(
      'Next topic lesson prep',
      () => generateNextTopicLesson(session),
      requiresHeavy: true,
      // Lesson pre-generation is §4.1 prep work — attribute to the lesson_prep
      // budget bucket so the task manager + PrepBudgetService surface the
      // correct category (Vision Next-Term §4.1/§4.2).
      feature: PrepCategory.lessonPrep.taskTypeKey,
      taskType: PrepCategory.lessonPrep.taskTypeKey,
      // Vision §4.2: bind the task to the lesson's subject so the
      // IdleExecutor can skip prep when the student has paused that syllabus.
      subjectId: session.subjectId,
      // Vision Next-Term §4.1: payload carries the task kind + studentId so
      // the TaskReconstructor can rebuild this closure after a restart (the
      // TutorSession cannot survive process termination).
      payload: jsonEncode({
        'kind': 'next_topic_lesson_prep',
        'studentId': session.studentId,
      }),
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

  /// Loads the pre-generated [Lesson] for a scheduled session, when one exists.
  ///
  /// The planner ([PlannerService.scheduleLesson]) and post-lesson prep
  /// ([PreGenerateLessonTool]) store a pre-built lesson ahead of the
  /// scheduled time and record its id on [Session.lessonIds] with
  /// [Session.lessonReady] true. This reads the first available lesson back
  /// from the [LessonRepository] so [startLesson] can reuse its blocks
  /// instead of synthesising a plan from scratch (Vision Next-Term §4.3).
  ///
  /// Returns null when the session is not lesson-ready, has no lesson ids,
  /// or the lesson cannot be found — signalling the caller to fall back to
  /// live generation.
  Future<Lesson?> _loadPreGeneratedLesson(Session scheduledSession) async {
    if (!scheduledSession.lessonReady || scheduledSession.lessonIds.isEmpty) {
      return null;
    }
    try {
      await _lessonRepository.init();
      for (final lessonId in scheduledSession.lessonIds) {
        final result = await _lessonRepository.get(lessonId);
        if (result.isSuccess && result.data != null) {
          return result.data;
        }
      }
      _logger.w(
        'Pre-generated lesson not found for session '
        '${scheduledSession.id} (ids: ${scheduledSession.lessonIds.join(', ')})',
      );
      return null;
    } catch (e) {
      _logger.w(
        'Failed to load pre-generated lesson for session ${scheduledSession.id}',
        e,
      );
      return null;
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
      difficulty: _defaultQuestionDifficulty,
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

  Future<Result<List<TutorSession>>> getLessonHistory(String studentId) async {
    final result =
        await _database.tutorSessionRepository.getStudentSessions(studentId);
    if (result.isFailure) {
      _logger.w('Failed to load lesson history for $studentId', result.error);
      return Result.failure(result.error);
    }
    return Result.success(result.data ?? []);
  }

  Future<Result<List<ConversationMessage>>> getSessionMessages(
      String sessionId) async {
    final result =
        await _database.conversationRepository.getSessionMessages(sessionId);
    if (result.isFailure) {
      _logger.w('Failed to load session messages for $sessionId', result.error);
      return Result.failure(result.error);
    }
    return Result.success(result.data ?? []);
  }

  Future<Result<Map<String, dynamic>>> getStats(String studentId) async {
    final result =
        await _database.tutorSessionRepository.getSessionStats(studentId);
    if (result.isFailure) {
      _logger.w('Failed to load tutor stats for $studentId', result.error);
      return Result.failure(result.error);
    }
    return Result.success(result.data ?? {});
  }

  Future<Result<void>> saveMessage(ConversationMessage message) async {
    final result =
        await _database.conversationRepository.saveMessage(message);
    if (result.isFailure) {
      _logger.w('Failed to save conversation message', result.error);
      return Result.failure(result.error);
    }
    return Result.success(null);
  }

  Future<Result<TutorSession?>> getActiveSession() async {
    final result =
        await _database.tutorSessionRepository.getActiveSessions();
    if (result.isFailure) {
      _logger.w('Failed to load active session', result.error);
      return Result.failure(result.error);
    }
    final sessions = result.data ?? [];
    return Result.success(sessions.isNotEmpty ? sessions.first : null);
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
