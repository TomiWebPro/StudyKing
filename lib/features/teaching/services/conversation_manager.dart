import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import '../../../core/services/llm/llm_chat_service.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/number_format_utils.dart';
import '../data/models/evaluation_result.dart';
import '../data/models/lesson_plan_model.dart';
import 'conversation_phase.dart';
export 'conversation_phase.dart';
import 'exercise_evaluator.dart';
import 'prompts/prompts.dart';

class ConversationManager {
  final LlmService _llmService;
  final String _modelId;
  final ConversationMemory _memory;
  final String sessionId;
  final ConversationRepository? _persistenceRepo;
  final ExerciseEvaluator _exerciseEvaluator;
  final ConversationPromptSet _prompts;
  final Clock _clock;

  final String studentId;
  final String topicTitle;
  final String subjectId;
  final String topicId;
  final DateTime sessionStartTime;

  ConversationPhase phase = ConversationPhase.greeting;
  int exerciseCount = 0;
  int correctCount = 0;
  int _consecutiveIncorrect = 0;
  double adaptivePace = 1.0;
  LessonPlan? lessonPlan;
  EvaluationResult? lastEvaluationResult;
  String _lastExerciseQuestion = '';
  bool _pendingExerciseQuestionCapture = false;
  String localeName = 'en';

  ConversationManager({
    required LlmService llmService,
    required String modelId,
    required this.sessionId,
    required this.studentId,
    required this.topicTitle,
    required this.subjectId,
    required this.topicId,
    required ExerciseEvaluator exerciseEvaluator,
    ConversationRepository? persistenceRepo,
    ConversationPromptSet? prompts,
    Clock? clock,
    this.localeName = 'en',
  })  : _llmService = llmService,
        _modelId = modelId,
        _persistenceRepo = persistenceRepo,
        _exerciseEvaluator = exerciseEvaluator,
        _prompts = prompts ?? ConversationPromptSet(localeName: localeName),
        _clock = clock ?? SystemClock(),
        sessionStartTime = (clock ?? SystemClock()).now(),
        _memory = ConversationMemory(
          maxTurns: 30,
          sessionId: sessionId,
          repository: persistenceRepo,
        );

  List<ConversationMessage> get messages => _memory.getHistory();
  String get capturedExerciseQuestion => _lastExerciseQuestion;

  Future<void> initialize() async {
    phase = ConversationPhase.greeting;
    await _loadPersistedMessages();
  }

  static final Logger _logger = const Logger('ConversationManager');

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
    if (result.isFailure) {
      final defaultPlan = LessonPlan.defaultPlan(durationMinutes);
      lessonPlan = defaultPlan;
      return defaultPlan;
    }
    final response = result.data!;

    final plan = LessonPlan.fromJson(response);
    if (plan != null) {
      lessonPlan = plan;
      return plan;
    }
    final defaultPlan = LessonPlan.defaultPlan(durationMinutes);
    lessonPlan = defaultPlan;
    return defaultPlan;
  }

  Stream<String> sendMessage(String content) async* {
    _memory.addUserMessage(content);

    if (phase == ConversationPhase.greeting) {
      phase = ConversationPhase.teaching;
    } else if (phase == ConversationPhase.exercise) {
      final result = await _evaluateExerciseResponse(content);
      _memory.addSystemMessage(
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
        phase = ConversationPhase.adaptiveReview;
      } else {
        phase = ConversationPhase.teaching;
      }
    }

    final buffer = StringBuffer();
    final entry = _prompts.tutorMessage(
      subjectId: subjectId,
      topicTitle: topicTitle,
      adaptivePace: adaptivePace,
      phase: phase,
    );

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

    final assistantContent = buffer.toString();
    _memory.addAssistantMessage(assistantContent);

    if (_pendingExerciseQuestionCapture) {
      _lastExerciseQuestion = assistantContent;
      _pendingExerciseQuestionCapture = false;
    }

    _detectExerciseRequest(content);
  }

  Stream<String> processImage(String base64Image) async* {
    _memory.addUserMessage('[Image submitted for analysis]');

    if (phase == ConversationPhase.greeting) {
      phase = ConversationPhase.teaching;
    }

    final imageData = 'data:image/jpeg;base64,$base64Image';
    final message = 'The student submitted handwritten work / an image. '
        'Analyze and provide feedback, identifying any errors and suggesting improvements.\n\n'
        '$imageData';

    final buffer = StringBuffer();
    await for (final chunk in _llmService.chatStream(
      message: message,
      modelId: _modelId,
      memory: _memory,
      systemPrompt: 'The student submitted this work. Analyze and provide feedback.',
    )) {
      buffer.write(chunk);
      if (buffer.length > 0) {
        yield chunk;
      }
    }

    final assistantContent = buffer.toString();
    _memory.addAssistantMessage(assistantContent);
  }

  Stream<String> _buildAdaptiveChunks(String fullContent) async* {
    final pace = adaptivePace;
    final chunkSize = (pace > 1.2) ? 10 : (pace < 0.8 ? 3 : 5);
    int i = 0;
    while (i < fullContent.length) {
      final end = (i + chunkSize).clamp(0, fullContent.length);
      yield fullContent.substring(i, end);
      i = end;
      if (pace < 0.8) {
        await Future.delayed(const Duration(milliseconds: 15));
      }
    }
  }

  Future<EvaluationResult> _evaluateExerciseResponse(String content) async {
    exerciseCount++;

    final result = await _exerciseEvaluator.evaluate(
      question: _lastExerciseQuestion,
      studentAnswer: content,
      subjectId: subjectId,
      topicTitle: topicTitle,
    );

    lastEvaluationResult = result;

    if (result.score >= 0.7) {
      correctCount++;
      _consecutiveIncorrect = 0;
      adaptivePace = min(adaptivePace + 0.15, 1.5);
    } else if (result.score <= 0.3) {
      _consecutiveIncorrect++;
      adaptivePace = max(adaptivePace - 0.15, 0.5);
    } else {
      _consecutiveIncorrect = 0;
    }

    phase = ConversationPhase.feedback;

    return result;
  }

  void _detectExerciseRequest(String content) {
    final lower = content.toLowerCase();
    final exerciseKeywords = ['exercise', 'practice', 'quiz'];
    if (exerciseKeywords.any((k) => lower.contains(k))) {
      phase = ConversationPhase.exercise;
      _pendingExerciseQuestionCapture = true;
      return;
    }

    if (phase == ConversationPhase.adaptiveReview) {
      phase = ConversationPhase.teaching;
    }
  }

  void transitionToExercise() {
    phase = ConversationPhase.exercise;
    _pendingExerciseQuestionCapture = true;
  }

  void transitionToClosing() {
    phase = ConversationPhase.closing;
  }

  void recordCorrectAnswer() {
    correctCount++;
    exerciseCount++;
    _consecutiveIncorrect = 0;
    adaptivePace = min(adaptivePace + 0.15, 1.5);
  }

  void recordIncorrectAnswer() {
    exerciseCount++;
    _consecutiveIncorrect++;
    adaptivePace = max(adaptivePace - 0.15, 0.5);
  }

  double get confidenceRating {
    if (exerciseCount == 0) return 0.5;
    final raw = correctCount / exerciseCount;
    return (raw * adaptivePace).clamp(0.0, 1.0);
  }

  Future<String> generateSummary() async {
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
    if (result.isFailure) return '';
    return result.data!;
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
      tutorNotes: 'Adaptive pace: ${formatDecimal(adaptivePace, 'en', minFractionDigits: 1, maxFractionDigits: 1)}x',
      lessonPlanJson: lessonPlan?.toJsonString() ?? '{}',
    );
  }

  void clearMessages() {
    _memory.clear();
  }
}
