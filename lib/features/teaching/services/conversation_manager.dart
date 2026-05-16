import 'dart:async';
import 'dart:math';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import '../../../core/services/llm/llm_chat_service.dart';
import 'conversation_phase.dart';
export 'conversation_phase.dart';
import 'prompts/prompts.dart';

class ConversationManager {
  final LlmService _llmService;
  final String _modelId;
  final ConversationMemory _memory;
  final String sessionId;
  final ConversationRepository? _persistenceRepo;
  final List<String> _correctKeywords;
  final List<String> _incorrectKeywords;
  final List<String> _exerciseKeywords;
  final PromptTemplates _prompts;

  String _studentId = '';
  String _topicTitle = '';
  String _subjectId = '';
  String _topicId = '';
  ConversationPhase _phase = ConversationPhase.greeting;
  int _exerciseCount = 0;
  int _correctCount = 0;
  int _consecutiveIncorrect = 0;
  double _adaptivePace = 1.0;
  DateTime _sessionStartTime = DateTime.now();

  ConversationManager({
    required LlmService llmService,
    required String modelId,
    required this.sessionId,
    required List<String> correctKeywords,
    required List<String> incorrectKeywords,
    required List<String> exerciseKeywords,
    ConversationRepository? persistenceRepo,
    PromptTemplates? prompts,
  })  : _llmService = llmService,
        _modelId = modelId,
        _persistenceRepo = persistenceRepo,
        _correctKeywords = correctKeywords,
        _incorrectKeywords = incorrectKeywords,
        _exerciseKeywords = exerciseKeywords,
        _prompts = prompts ?? PromptTemplates.defaultTemplates,
        _memory = ConversationMemory(
          maxTurns: 30,
          sessionId: sessionId,
          repository: persistenceRepo,
        );

  List<ConversationMessage> get messages => _memory.getHistory();

  ConversationPhase get phase => _phase;
  int get exerciseCount => _exerciseCount;
  int get correctCount => _correctCount;
  double get adaptivePace => _adaptivePace;
  String get studentId => _studentId;

  Future<void> initialize({
    required String studentId,
    required String topicTitle,
    required String subjectId,
    required String topicId,
  }) async {
    _studentId = studentId;
    _topicTitle = topicTitle;
    _subjectId = subjectId;
    _topicId = topicId;
    _phase = ConversationPhase.greeting;
    _sessionStartTime = DateTime.now();
    await _loadPersistedMessages();
  }

  Future<void> _loadPersistedMessages() async {
    if (_persistenceRepo == null) return;
    try {
      await _memory.loadFromRepository();
    } catch (_) {}
  }

  Future<String> generateLessonPlan({
    required String topicTitle,
    required String subjectId,
    required int durationMinutes,
  }) async {
    final prompt = _prompts.buildLessonPlanPrompt(
      subjectId: subjectId,
      topicTitle: topicTitle,
      durationMinutes: durationMinutes,
    );

    final response = await _llmService.chat(
      message: prompt,
      modelId: _modelId,
      systemPrompt: _prompts.lessonPlanSystemPrompt,
    );

    return response;
  }

  Stream<String> sendMessage(String content) async* {
    _memory.addUserMessage(content);

    if (_phase == ConversationPhase.greeting) {
      _phase = ConversationPhase.teaching;
    } else if (_phase == ConversationPhase.exercise) {
      _evaluateExerciseResponse(content);
    } else if (_phase == ConversationPhase.feedback) {
      if (_consecutiveIncorrect >= 2) {
        _phase = ConversationPhase.adaptiveReview;
      } else {
        _phase = ConversationPhase.teaching;
      }
    }

    final buffer = StringBuffer();
    final tutorPrompt = _prompts.buildTutorPrompt(
      subjectId: _subjectId,
      topicTitle: _topicTitle,
      adaptivePace: _adaptivePace,
      phase: _phase,
    );

    await for (final chunk in _llmService.chatStream(
      message: content,
      modelId: _modelId,
      memory: _memory,
      systemPrompt: tutorPrompt,
    )) {
      buffer.write(chunk);
      if (buffer.length > 2) {
        yield* _buildAdaptiveChunks(buffer.toString());
      }
    }

    _memory.addAssistantMessage(buffer.toString());

    _detectExerciseRequest(content);
  }

  Stream<String> _buildAdaptiveChunks(String fullContent) async* {
    final pace = _adaptivePace;
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

  void _evaluateExerciseResponse(String content) {
    _exerciseCount++;
    final lower = content.toLowerCase();

    final isCorrect = _correctKeywords.any((k) => lower.contains(k));
    final isIncorrect = _incorrectKeywords.any((k) => lower.contains(k));

    if (isCorrect && !isIncorrect) {
      _correctCount++;
      _consecutiveIncorrect = 0;
      _adaptivePace = min(_adaptivePace + 0.15, 1.5);
    } else if (isIncorrect) {
      _consecutiveIncorrect++;
      _adaptivePace = max(_adaptivePace - 0.15, 0.5);
    } else {
      _consecutiveIncorrect = 0;
    }

    _phase = ConversationPhase.feedback;
  }

  void _detectExerciseRequest(String content) {
    final lower = content.toLowerCase();
    if (_exerciseKeywords.any((k) => lower.contains(k))) {
      _phase = ConversationPhase.exercise;
      return;
    }

    if (_phase == ConversationPhase.adaptiveReview) {
      _phase = ConversationPhase.teaching;
    }
  }

  void transitionToExercise() {
    _phase = ConversationPhase.exercise;
  }

  void transitionToClosing() {
    _phase = ConversationPhase.closing;
  }

  void recordCorrectAnswer() {
    _correctCount++;
    _exerciseCount++;
    _consecutiveIncorrect = 0;
    _adaptivePace = min(_adaptivePace + 0.15, 1.5);
  }

  void recordIncorrectAnswer() {
    _exerciseCount++;
    _consecutiveIncorrect++;
    _adaptivePace = max(_adaptivePace - 0.15, 0.5);
  }

  double get confidenceRating {
    if (_exerciseCount == 0) return 0.5;
    final raw = _correctCount / _exerciseCount;
    return (raw * _adaptivePace).clamp(0.0, 1.0);
  }

  Future<String> generateSummary() async {
    final prompt = _prompts.buildSummaryPrompt(
      topicTitle: _topicTitle,
      exerciseCount: _exerciseCount,
      correctCount: _correctCount,
      confidenceRating: confidenceRating,
      adaptivePace: _adaptivePace,
    );

    return await _llmService.chat(
      message: prompt,
      modelId: _modelId,
      systemPrompt: _prompts.summarySystemPrompt,
    );
  }

  TutorSession toSession() {
    final msgCount = _memory.getHistory().length;
    return TutorSession(
      id: sessionId,
      studentId: _studentId,
      subjectId: _subjectId,
      topicId: _topicId,
      topicTitle: _topicTitle,
      status: SessionStatus.completed,
      startTime: _sessionStartTime,
      endTime: DateTime.now(),
      questionsAsked: _exerciseCount,
      questionsCorrect: _correctCount,
      confidenceRating: (confidenceRating * 5).round(),
      totalMessages: msgCount,
      topicsCovered: [_topicTitle],
      tutorNotes: 'Adaptive pace: ${_adaptivePace.toStringAsFixed(1)}x',
    );
  }

  void clearMessages() {
    _memory.clear();
  }
}
