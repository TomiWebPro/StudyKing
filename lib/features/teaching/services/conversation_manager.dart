import 'dart:async';
import 'dart:math';
import '../../../core/data/models/conversation_message_model.dart';
import '../../../core/data/models/tutor_session_model.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import '../../../core/services/llm/llm_chat_service.dart';

enum ConversationPhase {
  greeting,
  teaching,
  exercise,
  feedback,
  adaptiveReview,
  closing,
}

class ConversationManager {
  final LlmService _llmService;
  final String _modelId;
  final ConversationMemory _memory;
  final String sessionId;
  final ConversationRepository? _persistenceRepo;

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
    ConversationRepository? persistenceRepo,
  })  : _llmService = llmService,
        _modelId = modelId,
        _persistenceRepo = persistenceRepo,
        _memory = ConversationMemory(
          maxTurns: 30,
          sessionId: sessionId,
          repository: persistenceRepo,
        );

  List<ConversationMessage> get messages {
    final history = _memory.getHistory();
    final result = <ConversationMessage>[];
    for (int i = 0; i < history.length; i++) {
      final msg = history[i];
      final role = msg['role'] == 'assistant'
          ? MessageRole.tutor
          : msg['role'] == 'system'
              ? MessageRole.system
              : MessageRole.student;
      result.add(ConversationMessage(
        id: '${sessionId}_msg_$i',
        sessionId: sessionId,
        role: role,
        type: MessageType.text,
        content: msg['content'] ?? '',
        timestamp: _sessionStartTime.add(Duration(seconds: i)),
      ));
    }
    return result;
  }

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
    final prompt = '''
You are a knowledgeable AI tutor for $subjectId. Create a structured lesson plan for the topic "$topicTitle".

The lesson should be $durationMinutes minutes long.

Return a JSON object with:
{
  "goals": ["goal1", "goal2", "goal3"],
  "sections": [
    {"title": "section title", "duration": 10, "type": "explanation|exercise|review"},
    ...
  ],
  "checkpoints": ["checkpoint1", "checkpoint2"],
  "estimatedDifficulty": 1-5
}
''';

    final response = await _llmService.chat(
      message: prompt,
      modelId: _modelId,
      systemPrompt:
          'You are a curriculum designer creating lesson plans. Respond only with valid JSON.',
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
    final tutorPrompt = _buildTutorPrompt();

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

  String _buildTutorPrompt() {
    final paceContext = switch (_adaptivePace) {
      > 1.2 => 'The student is doing well. Accelerate pace.',
      < 0.8 => 'The student seems to be struggling. Slow down, simplify explanations, and provide more examples.',
      _ => 'Maintain a steady teaching pace.',
    };

    final timeContext = switch (_phase) {
      ConversationPhase.greeting => 'Start the lesson warmly.',
      ConversationPhase.teaching => 'Teach the concept step by step. Engage the student with questions.',
      ConversationPhase.exercise => 'Give the student a practice question to assess understanding.',
      ConversationPhase.feedback => 'Provide constructive feedback on their answer.',
      ConversationPhase.adaptiveReview => 'The student needs extra help. Re-explain the concept more simply. Use different examples.',
      ConversationPhase.closing => 'Wrap up the lesson. Summarize key points.',
    };

    return '''
You are an AI tutor for $_subjectId teaching "$_topicTitle".

Guidelines:
- $timeContext
- $paceContext
- Explain concepts step by step
- Adapt to the student's level
- Encourage the student always
- If they answer correctly, accelerate; if struggling, simplify
- Keep track of the lesson hour - be mindful of time
- Ask questions to check understanding
- Never give away answers directly - guide the student
- Insert inline exercises naturally into the conversation
- Celebrate correct answers with specific praise
- For wrong answers, explain why and guide toward the correct reasoning

Be conversational, warm, and educational.
''';
  }

  void _evaluateExerciseResponse(String content) {
    _exerciseCount++;
    final lower = content.toLowerCase();
    final correctKeywords = [
      'correct', 'right', 'yes', 'got it', 'understood', 'i see',
      'that makes sense', 'true', 'exactly',
    ];
    final incorrectKeywords = [
      'wrong', 'incorrect', 'not sure', 'confused', "don't know",
      "don't understand", 'no', 'mistake', 'error',
    ];

    final isCorrect = correctKeywords.any((k) => lower.contains(k));
    final isIncorrect = incorrectKeywords.any((k) => lower.contains(k));

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
    final exerciseKeywords = [
      'exercise', 'practice', 'question', 'quiz', 'problem',
      'test me', 'challenge', 'example',
    ];
    if (exerciseKeywords.any((k) => lower.contains(k))) {
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
    final prompt = '''
Summarize what was covered in this lesson about "$_topicTitle".
Include:
1. Key concepts explained
2. Questions answered ($_exerciseCount exercises, $_correctCount correct)
3. Student's apparent understanding level (confidence: ${(confidenceRating * 100).round()}%)
4. Adaptive pace used (${_adaptivePace.toStringAsFixed(1)}x)
5. Recommendations for next lesson

Keep it concise and constructive.
''';

    return await _llmService.chat(
      message: prompt,
      modelId: _modelId,
      systemPrompt: 'You are a tutor writing lesson notes.',
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
