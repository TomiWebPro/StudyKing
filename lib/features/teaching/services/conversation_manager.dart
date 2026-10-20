import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:studyking/core/utils/string_extensions.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_agent/agent_loop.dart';
import 'package:studyking/core/services/voice_service.dart';
import 'package:studyking/core/constants/timeouts.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/data/models/learning_preference_model.dart';
import '../data/models/evaluation_result.dart';
import '../data/models/lesson_plan_model.dart';
import 'conversation_phase.dart';
import 'exercise_evaluator.dart';
import 'prompts/prompts.dart';
import 'syllabus_switch_parser.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';

class ConversationManager {
  final LlmService _llmService;
  final String _modelId;
  final ConversationMemory _memory;
  final String sessionId;
  final ConversationRepository? _persistenceRepo;
  final ExerciseEvaluator _exerciseEvaluator;
  final ConversationPromptSet _prompts;
  final Clock _clock;
  final VoiceService? _voiceService;

  /// Optional AgentLoop that drives live tutoring turns through the
  /// think→act→observe tool-calling loop (Vision Next-Term §3.1). When present,
  /// [sendMessage] / [processImage] route through it so the LLM can invoke
  /// teaching tools (explain_differently, suggest_practice, read_source_content,
  /// review_mistakes, …). When absent (no API key configured), teaching
  /// degrades to a direct chat stream so it still works offline.
  final AgentLoop? _agentLoop;

  bool enableVoiceOutput = false;
  bool reduceMotion = false;

  final String studentId;
  final String topicTitle;
  final String subjectId;
  final String topicId;
  final String? scheduledSessionId;

  /// The syllabus (subject) the student is currently scoped to in the tutor.
  /// `null` means all syllabi are in scope.
  String? get currentSyllabusId => _currentSyllabusId;
  String? get currentSyllabusTitle => _currentSyllabusTitle;

  /// The syllabus goals TutorService injected at lesson start (Vision Next-Term
  /// §3.1: the tutor must know which syllabi are available so the student can
  /// switch mid-lesson). Exposed so behaviour can be asserted in tests.
  List<SyllabusGoal> get availableSyllabi => List.unmodifiable(_availableSyllabi);

  /// Whether live tutoring turns are routed through the AgentLoop tool-calling
  /// infrastructure. Present only when a configured LlmAgent was injected;
  /// absent (null) lets teaching fall back to a direct chat stream so it still
  /// works without an API key.
  bool get usesAgentLoop => _agentLoop != null;
  String? _currentSyllabusId;
  String? _currentSyllabusTitle;
  final List<SyllabusGoal> _availableSyllabi;
  final DateTime sessionStartTime;
  final LearningPreference? learningPreferences;

  /// Optional note built from the student's past lesson-quality feedback,
  /// injected into the tutor system prompt so the tutor can adapt its style.
  String? feedbackContext;

  /// Optional note built from the student's weak topics and recent lesson
  /// history, injected into the tutor system prompt so the tutor adapts to the
  /// learner's actual progress (agent_must_read.md §32-45: adapt to
  /// understanding; §86-96: progress feeds teaching). Null/empty means the
  /// student has no recorded mastery data yet, so nothing is injected.
  String? masteryContext;

  /// Optional note built from the active lesson's pre-built blocks
  /// (examples, exercises, analogies, …) and injected into the tutor system
  /// prompt so the live tutor reads prepared artefacts instead of
  /// synthesising the course from scratch (docs/vision_next_term.md §4.3).
  /// Null/empty means no pre-built lesson is loaded, so nothing is injected.
  String? lessonPlanContext;

  ConversationPhase phase = ConversationPhase.greeting;
  int exerciseCount = 0;
  int correctCount = 0;
  int _consecutiveIncorrect = 0;

  /// Number of consecutive incorrect answers in the current exercise streak.
  /// Exposed so behaviour (confusion detection, §4.1 prep triggers) can be
  /// asserted in tests without reaching into private state.
  int get consecutiveIncorrectCount => _consecutiveIncorrect;

  /// Consecutive free-text confusion signals ("I don't get it", "I'm confused",
  /// ...) expressed by the student during a teaching/feedback turn, independent
  /// of exercise-answer correctness. Combined with [_consecutiveIncorrect] so
  /// the confusion-adaptation directive (prompts.dart:89-92) fires for both
  /// pathways — realising agent_must_read.md §36 ("adapt explanations to student
  /// understanding") for the free-text confused-student journey
  /// (dry-run-test/scenario_confused_student_fractions.md Step 1).
  int _consecutiveConfusionSignals = 0;

  /// Number of consecutive free-text confusion signals in the current streak,
  /// exposed for assertion in tests without reaching into private state. Resets
  /// to zero when the student indicates understanding.
  int get confusionSignalCount => _consecutiveConfusionSignals;

  int _adaptiveReviewExchanges = 0;
  double adaptivePace = 1.0;
  LessonPlan? lessonPlan;
  EvaluationResult? lastEvaluationResult;
  String _lastExerciseQuestion = '';
  bool _pendingExerciseQuestionCapture = false;
  String localeName;
  int totalTokensUsed = 0;

  ConversationManager({
    required LlmService llmService,
    required String modelId,
    required this.sessionId,
    required this.studentId,
    required this.topicTitle,
    required this.subjectId,
    required this.topicId,
    this.scheduledSessionId,
    List<SyllabusGoal> availableSyllabi = const [],
    required ExerciseEvaluator exerciseEvaluator,
    ConversationRepository? persistenceRepo,
    ConversationPromptSet? prompts,
    Clock? clock,
    required this.localeName,
    VoiceService? voiceService,
    this.learningPreferences,
    AgentLoop? agentLoop,
  })  : _llmService = llmService,
        _modelId = modelId,
        _persistenceRepo = persistenceRepo,
        _exerciseEvaluator = exerciseEvaluator,
        _prompts = prompts ?? ConversationPromptSet(localeName: localeName),
        _clock = clock ?? SystemClock(),
        _voiceService = voiceService,
        _agentLoop = agentLoop,
        sessionStartTime = (clock ?? SystemClock()).now(),
        _availableSyllabi = availableSyllabi,
        _memory = ConversationMemory(
          maxTurns: 30,
          sessionId: sessionId,
          repository: persistenceRepo,
          summarizer: (messages) => _summarizeMessages(messages, llmService, modelId),
        ) {
    // Wire the LLM service's token-usage callback so this session's
    // totalTokensUsed reflects actual API-returned counts (input + output)
    // rather than the previous chars/4 heuristic. The callback is invoked
    // from LlmService._recordCompletion on every completed LLM call —
    // streaming and non-streaming — so removing the per-line
    // `totalTokensUsed += content.length ~/ 4` increments below is safe.
    // (Vision Next-Term thesis §0: students must see where tokens go.)
    _llmService.onTokenUsage = (inputTokens, outputTokens, model) {
      totalTokensUsed += inputTokens + outputTokens;
    };
  }

  List<ConversationMessage> get messages => _memory.getHistory();
  String get capturedExerciseQuestion => _lastExerciseQuestion;

  static final Logger _logger = const Logger('ConversationManager');

  static const double _masteryThreshold = 0.7;
  static const double _struggleThreshold = 0.3;
  static const double _paceIncrement = 0.15;
  static const double _maxPace = 1.5;
  static const double _minPace = 0.5;
  static const double _defaultConfidence = 0.5;
  static const double _chunkSizeFast = 10;
  static const int _chunkSizeNormal = 5;
  static const int _chunkSizeSlow = 3;
  static const double _paceFastThreshold = 1.2;
  static const double _paceSlowThreshold = 0.8;

  Future<void> initialize() async {
    phase = ConversationPhase.greeting;
    await _loadPersistedMessages();
  }

  Future<void> _loadPersistedMessages() async {
    if (_persistenceRepo == null) return;
    try {
      await _memory.loadFromRepository();
    } catch (e) {
      _logger.w('Failed to load persisted messages', e);
    }
  }

  Future<Result<LessonPlan>> generateLessonPlan({
    required int durationMinutes,
  }) async {
    final entry = _prompts.lessonPlan(
      subjectId: subjectId,
      topicTitle: topicTitle,
      durationMinutes: durationMinutes,
    );

    final result = await _llmService.chat(
      message: entry.userPrompt,
      modelId: _modelId,
      systemPrompt: entry.systemPrompt,
      feature: 'teaching_lesson_plan',
      sessionId: sessionId,
    );

    Future<Result<LessonPlan>> buildDefaultPlan() async {
      final l10n = lookupAppLocalizations(Locale(localeName));
      final plan = LessonPlan.defaultPlan(
        durationMinutes,
        goal: l10n.defaultLessonGoal,
        introTitle: l10n.sectionIntroduction,
        mainTitle: l10n.sectionMainContent,
        practiceTitle: l10n.sectionPractice,
        checkpointStarted: l10n.checkpointStarted,
        checkpointCovered: l10n.checkpointTopicCovered,
        checkpointCompleted: l10n.checkpointPracticeCompleted,
      );
      lessonPlan = plan;
      return Result.success(plan);
    }

    if (result.isFailure) {
      return buildDefaultPlan();
    }
    final response = result.data!;

    final plan = LessonPlan.fromJson(response);
    if (plan != null) {
      lessonPlan = plan;
      return Result.success(plan);
    }
    return buildDefaultPlan();
  }

  Stream<String> sendMessage(String content) async* {
    if (phase == ConversationPhase.greeting) {
      _logTransition(phase, ConversationPhase.teaching, 'initial greeting');
      phase = ConversationPhase.teaching;
    }

    final switchResult = SyllabusSwitchParser.parse(
      content,
      availableTitles: _availableSyllabi.map((g) => g.subjectTitle).toList(),
    );
    if (switchResult.matched) {
      { final memResult = await _memory.addUserMessage(content); if (memResult.isFailure) _logger.w('Failed to persist message: ${memResult.error}'); }
      final l10n = lookupAppLocalizations(Locale(localeName));
      if (switchResult.syllabusTitle == null) {
        _currentSyllabusId = null;
        _currentSyllabusTitle = null;
        { final memResult = await _memory.addAssistantMessage(l10n.tutorSyllabusSwitchedAll); if (memResult.isFailure) _logger.w('Failed to persist message: ${memResult.error}'); }
        yield l10n.tutorSyllabusSwitchedAll;
      } else {
        final goal = _availableSyllabi.firstWhere(
          (g) => g.subjectTitle.normalized == switchResult.syllabusTitle!.normalized,
          orElse: () => SyllabusGoal(subjectId: '', subjectTitle: switchResult.syllabusTitle!),
        );
        _currentSyllabusId = goal.subjectId;
        _currentSyllabusTitle = goal.subjectTitle;
        final ack = l10n.tutorSyllabusSwitched(goal.subjectTitle);
        { final memResult = await _memory.addAssistantMessage(ack); if (memResult.isFailure) _logger.w('Failed to persist message: ${memResult.error}'); }
        yield ack;
      }
      return;
    }

    { final memResult = await _memory.addUserMessage(content); if (memResult.isFailure) _logger.w('Failed to persist message: ${memResult.error}'); }

    if (phase == ConversationPhase.exercise) {
      final result = await _evaluateExerciseResponse(content);
      await _memory.addSystemMessage(
        jsonEncode({
          'type': 'evaluation',
          'score': result.score,
          'explanation': result.explanation,
          if (result.partialCredit != null)
            'partialCredit': result.partialCredit,
          if (result.conceptBreakdown != null)
            'conceptBreakdown': result.conceptBreakdown,
        }),
      );
    } else if (phase == ConversationPhase.feedback) {
      if (_consecutiveIncorrect >= 2) {
        _logTransition(phase, ConversationPhase.adaptiveReview, 'consecutive incorrect >= 2');
        phase = ConversationPhase.adaptiveReview;
      } else {
        _logTransition(phase, ConversationPhase.teaching, 'student answered correctly');
        phase = ConversationPhase.teaching;
      }
    } else if (phase == ConversationPhase.adaptiveReview) {
      _adaptiveReviewExchanges++;
      final lower = content.normalized;
      final continueKeywords = _getContinueKeywords();
      if (continueKeywords.any((k) => lower.contains(k))) {
        _logTransition(phase, ConversationPhase.teaching, 'student indicates understanding');
        phase = ConversationPhase.teaching;
        _adaptiveReviewExchanges = 0;
      } else if (_adaptiveReviewExchanges >= 3) {
        _logTransition(phase, ConversationPhase.teaching, 'max adaptive review exchanges reached');
        phase = ConversationPhase.teaching;
        _adaptiveReviewExchanges = 0;
      }
      _consecutiveIncorrect = 0;
      _consecutiveConfusionSignals = 0;
    }

    // Detect exercise requests BEFORE building the prompt so that:
    // (1) the request turn itself streams under the exercise-phase
    //     prompt, and (2) the capture block below runs with the flag
    //     already set, storing the generated exercise question (not the
    //     follow-up teaching reply) in _lastExerciseQuestion.
    _detectExerciseRequest(content);
    _updateConfusionSignal(content);

    final buffer = StringBuffer();
    var emittedLength = 0;
    final entry = _prompts.tutorMessage(
      subjectId: subjectId,
      topicTitle: topicTitle,
      adaptivePace: adaptivePace,
      phase: phase,
      scheduledSessionId: scheduledSessionId,
      learningPreferences: learningPreferences,
      feedbackContext: feedbackContext,
      confusionCount: max(_consecutiveIncorrect, _consecutiveConfusionSignals),
      masteryContext: masteryContext,
      lessonPlanContext: lessonPlanContext,
    );

    try {
      await for (final chunk in _turnStream(
        userMessage: content,
        systemPrompt: '${entry.systemPrompt}\n\n${entry.userPrompt}',
        // Live tutoring turns must be attributable in the LLM task-manager
        // portal (Vision Next-Term §0 thesis: students steer where tokens go).
        // 'teaching' maps to LlmTaskType.tutor via LlmTaskType.fromFeature.
        feature: 'teaching',
      )) {
        buffer.write(chunk);
        final streamed = buffer.toString();
        if (streamed.length > emittedLength) {
          // Yield only the not-yet-emitted tail so consumers that append
          // chunks (e.g. TutorScreen) render each byte exactly once.
          yield* _buildAdaptiveChunks(streamed.substring(emittedLength));
          emittedLength = streamed.length;
        }
      }
    } catch (e) {
      final partialContent = buffer.toString();
      if (partialContent.isNotEmpty) {
        { final memResult = await _memory.addAssistantMessage(partialContent); if (memResult.isFailure) _logger.w('Failed to persist message: ${memResult.error}'); }
      }
      rethrow;
    }

    final assistantContent = buffer.toString();
    { final memResult = await _memory.addAssistantMessage(assistantContent); if (memResult.isFailure) _logger.w('Failed to persist message: ${memResult.error}'); }

    if (_pendingExerciseQuestionCapture) {
      _lastExerciseQuestion = assistantContent;
      _pendingExerciseQuestionCapture = false;
    }

    if (enableVoiceOutput) {
      _speakResponse(assistantContent);
    }
  }

  Future<void> _speakResponse(String text) async {
    final vs = _voiceService;
    if (enableVoiceOutput && vs != null && text.isNotEmpty) {
      await vs.speak(text, localeName: localeName);
    }
  }

  Stream<String> processImage(String base64Image) async* {
    { final memResult = await _memory.addUserMessage('[Image submitted for analysis]'); if (memResult.isFailure) _logger.w('Failed to persist message: ${memResult.error}'); }

    if (phase == ConversationPhase.greeting) {
      _logTransition(phase, ConversationPhase.teaching, 'image submitted during greeting');
      phase = ConversationPhase.teaching;
    }

    final imageData = 'data:image/jpeg;base64,$base64Image';
    final l10n = lookupAppLocalizations(Locale(localeName));
    final message = l10n.tutorImageAnalysisUserPrompt(imageData);

    final buffer = StringBuffer();
    try {
      // Image analysis is live visual tutoring; attribute its tokens under the
      // tutor task type so the LLM task-manager portal reflects visual-tutoring
      // spend (Vision Next-Term §0 thesis: students steer where tokens go).
      // 'teaching_image_analysis' maps to LlmTaskType.tutor via
      // LlmTaskType.fromFeature('teaching'), instead of leaking into 'unknown'.
      await for (final chunk in _turnStream(
        userMessage: message,
        systemPrompt: l10n.tutorImageAnalysisSystemPrompt,
        feature: 'teaching_image_analysis',
      )) {
        buffer.write(chunk);
        if (buffer.length > 0) {
          yield chunk;
        }
      }
    } catch (e) {
      final partialContent = buffer.toString();
      if (partialContent.isNotEmpty) {
        { final memResult = await _memory.addAssistantMessage(partialContent); if (memResult.isFailure) _logger.w('Failed to persist message: ${memResult.error}'); }
      }
      rethrow;
    }

    final assistantContent = buffer.toString();
    { final memResult = await _memory.addAssistantMessage(assistantContent); if (memResult.isFailure) _logger.w('Failed to persist message: ${memResult.error}'); }
    _speakResponse(assistantContent);
  }

  /// Builds the reply stream for a single live-tutoring turn.
  ///
  /// When an [AgentLoop] is wired, the turn is routed through the think→act→
  /// observe loop so the LLM can invoke any of the tools registered for
  /// teaching mode (Vision Next-Term §3.1 / scenario_confused_student_fractions:
  /// `explain_differently`; §3.1 / scenario_practice_mistake_review:
  /// `review_mistakes`; source grounding via `read_source_content` /
  /// `search_sources`; weak-topic practice via `suggest_practice`). Tool-call
  /// syntax is buffered and stripped by the loop — only human-readable text is
  /// yielded to the caller, and tool results are recorded as system messages in
  /// conversation memory so subsequent turns see them (mirroring the mentor
  /// flow in mentor_service.dart).
  ///
  /// When no agent is configured (e.g. no API key), this falls back to a direct
  /// chat stream so teaching degrades gracefully offline.
  Stream<String> _turnStream({
    required String userMessage,
    required String systemPrompt,
    required String feature,
  }) {
    final agentLoop = _agentLoop;
    if (agentLoop != null) {
      final history = ConversationMemory.fromConversationMessages(
        _memory.getHistory(),
      );
      return agentLoop.runStream(
        userMessage: userMessage,
        studentId: studentId,
        systemPrompt: systemPrompt,
        feature: feature,
        history: history,
        onToolCall: _recordToolCallInMemory,
        sessionId: sessionId,
      );
    }
    return _llmService.chatStream(
      message: userMessage,
      modelId: _modelId,
      memory: _memory,
      systemPrompt: systemPrompt,
      feature: feature,
      sessionId: sessionId,
    );
  }

  /// Records a completed tool call as a system message in conversation memory so
  /// the tutor can reference prior tool results in later turns (mirrors the
  /// mentor `onToolCall` handler in mentor_service.dart).
  Future<void> _recordToolCallInMemory(AgentToolCall call) async {
    final toolMsg = '[${call.toolName}] ${call.result ?? 'executed'}';
    final memResult = await _memory.addSystemMessage(toolMsg);
    if (memResult.isFailure) {
      _logger.w('Failed to persist tool message: ${memResult.error}');
    }
  }

  String get providerName => _llmService.config.provider.name;

  bool get wasThrottleActive => _llmService.wasThrottleActive;

  Stream<String> _buildAdaptiveChunks(String fullContent) async* {
    if (reduceMotion) {
      yield fullContent;
      return;
    }
    final pace = adaptivePace;
    final chunkSize = (pace > _paceFastThreshold) ? _chunkSizeFast : (pace < _paceSlowThreshold ? _chunkSizeSlow : _chunkSizeNormal);
    int i = 0;
    while (i < fullContent.length) {
      final end = (i + chunkSize).clamp(0, fullContent.length).toInt();
      yield fullContent.substring(i, end);
      i = end;
      if (pace < _paceSlowThreshold) {
        await Future.delayed(Timeouts.adaptiveChunkDelay);
      }
    }
  }

  Future<EvaluationResult> _evaluateExerciseResponse(String content) async {
    exerciseCount++;

    EvaluationResult result;
    try {
      final evalResult = await _exerciseEvaluator.evaluate(
        question: _lastExerciseQuestion,
        studentAnswer: content,
        subjectId: subjectId,
        topicTitle: topicTitle,
      );
      if (evalResult.isFailure) {
        _logger.w('Exercise evaluation failed: ${evalResult.error}');
        final l10n = lookupAppLocalizations(Locale(localeName));
        result = EvaluationResult(
          score: 0.5,
          explanation: evalResult.error ?? l10n.couldNotEvaluateAnswer,
        );
      } else {
        result = evalResult.data!;
      }
    } catch (e, st) {
      _logger.w('Exercise evaluation threw unexpected error', e, st);
      final l10n = lookupAppLocalizations(Locale(localeName));
      result = EvaluationResult(
        score: 0.5,
        explanation: l10n.couldNotEvaluateAnswer,
      );
    }

    lastEvaluationResult = result;

    if (result.score >= _masteryThreshold) {
      correctCount++;
      _consecutiveIncorrect = 0;
      _consecutiveConfusionSignals = 0;
      adaptivePace = min(adaptivePace + _paceIncrement, _maxPace);
    } else if (result.score <= _struggleThreshold) {
      _consecutiveIncorrect++;
      adaptivePace = max(adaptivePace - _paceIncrement, _minPace);
    } else {
      _consecutiveIncorrect = 0;
      _consecutiveConfusionSignals = 0;
    }

    if (result.score >= _masteryThreshold && phase == ConversationPhase.adaptiveReview) {
      _logTransition(phase, ConversationPhase.teaching, 'correct in adaptive review');
      phase = ConversationPhase.teaching;
    } else {
      phase = ConversationPhase.feedback;
    }

    return result;
  }

  static const Map<String, List<String>> _continueKeywordsByLocale = {
    'en': ['understand', 'got it', 'i see', 'continue', 'next', 'ok', 'yes'],
    'es': ['entiendo', 'entendido', 'ya veo', 'siguiente', 'continúa', 'ok', 'sí', 'si'],
  };

  static const Map<String, List<String>> _exerciseKeywordsByLocale = {
    'en': ['exercise', 'practice', 'quiz'],
    'es': ['ejercicio', 'práctica', 'práct', 'examen', 'quiz'],
  };

  /// Free-text confusion signals (e.g. "I don't get it", "I'm confused") that
  /// a student may express directly during a teaching/feedback turn, rather than
  /// through a wrong exercise answer. Detected via [.normalized] (lowercase,
  /// trimmed) so casing/formatting differences do not matter.
  ///
  /// agent_must_read.md §36: the tutor must adapt explanations to the student's
  /// understanding; detecting these signals escalates the same confusion
  /// directive (prompts.dart:89-92) that consecutive incorrect exercise answers
  /// trigger, so the confused-student free-text journey is handled, not left
  /// to the LLM noticing the complaint in history.
  static const Map<String, List<String>> _confusionKeywordsByLocale = {
    'en': [
      "don't get",
      "dont get",
      "don't understand",
      "dont understand",
      "don't get it",
      "still don't",
      "still dont",
      "i'm confused",
      'im confused',
      'i am confused',
      'confused',
      'hard to understand',
      'not making sense',
      "can't follow",
    ],
    'es': [
      'no entiendo',
      'no comprendo',
      'estoy confundido',
      'estoy confundida',
      'todavía no entiendo',
      'todavia no entiendo',
      'confundido',
      'no me queda claro',
    ],
  };

  List<String> _getContinueKeywords() {
    if (!_continueKeywordsByLocale.containsKey(localeName)) {
      _logger.w('No continue keywords for locale $localeName, falling back to en');
    }
    return _continueKeywordsByLocale[localeName] ?? _continueKeywordsByLocale['en']!;
  }

  void _detectExerciseRequest(String content) {
    final lower = content.normalized;
    if (!_exerciseKeywordsByLocale.containsKey(localeName)) {
      _logger.w('No exercise keywords for locale $localeName, falling back to en');
    }
    final exerciseKeywords = _exerciseKeywordsByLocale[localeName] ?? _exerciseKeywordsByLocale['en']!;
    if (exerciseKeywords.any((k) => lower.contains(k))) {
      _logTransition(phase, ConversationPhase.exercise, 'keyword detected in student message');
      phase = ConversationPhase.exercise;
      _pendingExerciseQuestionCapture = true;
    }
  }

  List<String> _getConfusionKeywords() {
    if (!_confusionKeywordsByLocale.containsKey(localeName)) {
      _logger.w('No confusion keywords for locale $localeName, falling back to en');
    }
    return _confusionKeywordsByLocale[localeName] ?? _confusionKeywordsByLocale['en']!;
  }

  /// Tracks free-text confusion signals expressed during a teaching/feedback
  /// turn (agent_must_read.md §36). Increments [_consecutiveConfusionSignals]
  /// when the student expresses confusion ("I don't get it", "I'm confused",
  /// …) and resets it when the student indicates understanding, so the
  /// confusion-adaptation directive (prompts.dart:89) fires for repeated
  /// free-text confusion as well as for consecutive incorrect exercise answers.
  void _updateConfusionSignal(String content) {
    // Exercise-answer correctness governs confusion during the exercise phase;
    // free-text signals are only counted outside it to avoid double-counting.
    if (phase == ConversationPhase.exercise) return;
    final lower = content.normalized;
    if (_getConfusionKeywords().any((k) => lower.contains(k))) {
      _consecutiveConfusionSignals++;
      _logger.i('Free-text confusion signal detected (${_consecutiveConfusionSignals}th)');
    } else if (_getContinueKeywords().any((k) => lower.contains(k))) {
      _consecutiveConfusionSignals = 0;
    }
  }

  void transitionToTeaching() {
    _logTransition(phase, ConversationPhase.teaching, 'explicit transitionToTeaching()');
    phase = ConversationPhase.teaching;
  }

  void transitionToExercise() {
    _logTransition(phase, ConversationPhase.exercise, 'explicit transitionToExercise()');
    phase = ConversationPhase.exercise;
    _pendingExerciseQuestionCapture = true;
  }

  void transitionToClosing() {
    _logTransition(phase, ConversationPhase.closing, 'explicit transitionToClosing()');
    phase = ConversationPhase.closing;
  }

  void recordCorrectAnswer() {
    correctCount++;
    exerciseCount++;
    _consecutiveIncorrect = 0;
    _consecutiveConfusionSignals = 0;
    adaptivePace = min(adaptivePace + _paceIncrement, _maxPace);
  }

  void recordIncorrectAnswer() {
    exerciseCount++;
    _consecutiveIncorrect++;
    adaptivePace = max(adaptivePace - _paceIncrement, _minPace);
  }

  double get confidenceRating {
    if (exerciseCount == 0) return _defaultConfidence;
    final raw = correctCount / exerciseCount;
    return (raw * adaptivePace).clamp(0.0, 1.0);
  }

  Future<Result<String>> generateSummary() async {
    try {
      final entry = _prompts.summary(
        topicTitle: topicTitle,
        exerciseCount: exerciseCount,
        correctCount: correctCount,
        confidenceRating: confidenceRating,
        adaptivePace: adaptivePace,
      );

      final result = await _llmService.chat(
        message: entry.userPrompt,
        modelId: _modelId,
        systemPrompt: entry.systemPrompt,
        feature: 'teaching_summary',
        sessionId: sessionId,
      );
      if (result.isFailure) {
        _logger.w('Failed to generate summary: ${result.error}');
        return Result.failure(result.error ?? 'Failed to generate summary');
      }
      final summary = result.data!;
      return Result.success(summary);
    } catch (e, stack) {
      _logger.w('Failed to generate summary', e, stack);
      return Result.failure(e.toString());
    }
  }

  TutorSession toSession() {
    final msgCount = _memory.getHistory().length;
    return TutorSession(
      id: sessionId,
      studentId: studentId,
      subjectId: subjectId,
      topicId: topicId,
      topicTitle: topicTitle,
      status: SessionStatus.completed,
      startTime: sessionStartTime,
      endTime: _clock.now(),
      questionsAsked: exerciseCount,
      questionsCorrect: correctCount,
      confidenceRating: (confidenceRating * 5).round(),
      totalMessages: msgCount,
      topicsCovered: [topicTitle],
      // LLM-facing: invariant English format OK per AGENTS.md
      tutorNotes: 'Adaptive pace: ${formatDecimal(adaptivePace, 'en', minFractionDigits: 1, maxFractionDigits: 1)}x',
      lessonPlanJson: lessonPlan?.toJsonString() ?? '{}',
      totalTokensUsed: totalTokensUsed,
    );
  }

  void _logTransition(ConversationPhase from, ConversationPhase to, String reason) {
    _logger.i('Phase transition: ${from.name} → ${to.name} ($reason)');
  }

  void clearMessages() {
    _memory.clear();
  }

  Future<void> addAssistantMessage(String content) async {
    { final memResult = await _memory.addAssistantMessage(content); if (memResult.isFailure) _logger.w('Failed to persist message: ${memResult.error}'); }
  }

  static Future<String?> _summarizeMessages(
    List<ConversationMessage> messages,
    LlmService llmService,
    String modelId,
  ) async {
    final convMaps = ConversationMemory.fromConversationMessages(messages);
    if (convMaps.isEmpty) return null;

    final messagesStr = convMaps
        .map((m) => '[${m['role']}]: ${m['content']}')
        .join('\n');

    final result = await llmService.chat(
      message: 'Summarise the key points from this conversation. '
          'Be concise: list topics, questions, and decisions made.\n\n'
          '$messagesStr',
      modelId: modelId,
      systemPrompt: 'You compress conversation history into a short summary '
          'that preserves context for an AI tutor. Output 1-3 sentences.',
      feature: 'conversation_memory_compression',
    );

    if (result.isFailure) return null;
    return result.data;
  }
}
