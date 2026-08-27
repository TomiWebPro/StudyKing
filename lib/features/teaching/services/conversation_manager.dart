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
  String? _currentSyllabusId;
  String? _currentSyllabusTitle;
  final List<SyllabusGoal> _availableSyllabi;
  final DateTime sessionStartTime;
  final LearningPreference? learningPreferences;

  /// Optional note built from the student's past lesson-quality feedback,
  /// injected into the tutor system prompt so the tutor can adapt its style.
  String? feedbackContext;

  ConversationPhase phase = ConversationPhase.greeting;
  int exerciseCount = 0;
  int correctCount = 0;
  int _consecutiveIncorrect = 0;
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
  })  : _llmService = llmService,
        _modelId = modelId,
        _persistenceRepo = persistenceRepo,
        _exerciseEvaluator = exerciseEvaluator,
        _prompts = prompts ?? ConversationPromptSet(localeName: localeName),
        _clock = clock ?? SystemClock(),
        _voiceService = voiceService,
        sessionStartTime = (clock ?? SystemClock()).now(),
        _availableSyllabi = availableSyllabi,
        _memory = ConversationMemory(
          maxTurns: 30,
          sessionId: sessionId,
          repository: persistenceRepo,
          summarizer: (messages) => _summarizeMessages(messages, llmService, modelId),
        );

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

  Future<LessonPlan> generateLessonPlan({
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
    );

    Future<LessonPlan> buildDefaultPlan() async {
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
      return plan;
    }

    if (result.isFailure) {
      return buildDefaultPlan();
    }
    final response = result.data!;
    totalTokensUsed += response.length ~/ 4;

    final plan = LessonPlan.fromJson(response);
    if (plan != null) {
      lessonPlan = plan;
      return plan;
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
    }

    final buffer = StringBuffer();
    final entry = _prompts.tutorMessage(
      subjectId: subjectId,
      topicTitle: topicTitle,
      adaptivePace: adaptivePace,
      phase: phase,
      scheduledSessionId: scheduledSessionId,
      learningPreferences: learningPreferences,
      feedbackContext: feedbackContext,
    );

    try {
      await for (final chunk in _llmService.chatStream(
        message: content,
        modelId: _modelId,
        memory: _memory,
        systemPrompt: '${entry.systemPrompt}\n\n${entry.userPrompt}',
      )) {
        buffer.write(chunk);
        if (buffer.length > 0) {
          yield* _buildAdaptiveChunks(buffer.toString());
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
    totalTokensUsed += assistantContent.length ~/ 4;
    { final memResult = await _memory.addAssistantMessage(assistantContent); if (memResult.isFailure) _logger.w('Failed to persist message: ${memResult.error}'); }

    if (_pendingExerciseQuestionCapture) {
      _lastExerciseQuestion = assistantContent;
      _pendingExerciseQuestionCapture = false;
    }

    if (enableVoiceOutput) {
      _speakResponse(assistantContent);
    }

    _detectExerciseRequest(content);
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
      await for (final chunk in _llmService.chatStream(
        message: message,
        modelId: _modelId,
        memory: _memory,
        systemPrompt: l10n.tutorImageAnalysisSystemPrompt,
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
    totalTokensUsed += assistantContent.length ~/ 4;
    { final memResult = await _memory.addAssistantMessage(assistantContent); if (memResult.isFailure) _logger.w('Failed to persist message: ${memResult.error}'); }
    _speakResponse(assistantContent);
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
      adaptivePace = min(adaptivePace + _paceIncrement, _maxPace);
    } else if (result.score <= _struggleThreshold) {
      _consecutiveIncorrect++;
      adaptivePace = max(adaptivePace - _paceIncrement, _minPace);
    } else {
      _consecutiveIncorrect = 0;
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
      );
      if (result.isFailure) {
        _logger.w('Failed to generate summary: ${result.error}');
        return Result.failure(result.error ?? 'Failed to generate summary');
      }
      final summary = result.data!;
      totalTokensUsed += summary.length ~/ 4;
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
