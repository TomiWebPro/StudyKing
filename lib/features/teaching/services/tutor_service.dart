import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../core/data/database_service.dart';
import '../../../core/data/enums.dart';
import '../../../core/data/models/question_model.dart';
import '../../../core/utils/clock.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import '../../../core/services/llm/llm_chat_service.dart';
import '../../../core/services/mastery_graph_service.dart';
import '../../../core/services/plan_adapter.dart';
import 'conversation_manager.dart';
import 'exercise_evaluator.dart';

class TutorService {
  final DatabaseService _database;
  final LlmService _llmService;
  final MasteryGraphService _masteryService;
  final String _modelId;
  final PlanAdapter _planAdapter;
  final ExerciseEvaluator _exerciseEvaluator;
  final Clock _clock;
  ConversationManager? _currentManager;

  TutorService({
    required DatabaseService database,
    required LlmService llmService,
    required MasteryGraphService masteryService,
    required String modelId,
    required ExerciseEvaluator exerciseEvaluator,
    PlanAdapter? planAdapter,
    Clock? clock,
  })  : _database = database,
        _llmService = llmService,
        _masteryService = masteryService,
        _modelId = modelId,
        _exerciseEvaluator = exerciseEvaluator,
        _planAdapter = planAdapter ?? PlanAdapter(),
        _clock = clock ?? SystemClock();

  ConversationManager? get currentManager => _currentManager;

  Future<ConversationManager> startLesson({
    required String studentId,
    required String subjectId,
    required String topicId,
    required String topicTitle,
    int durationMinutes = 45,
  }) async {
    final sessionId = 'tutor_${_clock.now().millisecondsSinceEpoch}';

    final session = TutorSession(
      id: sessionId,
      studentId: studentId,
      subjectId: subjectId,
      topicId: topicId,
      topicTitle: topicTitle,
      status: SessionStatus.inProgress,
      startTime: _clock.now(),
      plannedDurationMinutes: durationMinutes,
    );
    await _database.tutorSessionRepository.saveSession(session);

    final manager = ConversationManager(
      llmService: _llmService,
      modelId: _modelId,
      sessionId: sessionId,
      studentId: studentId,
      topicTitle: topicTitle,
      subjectId: subjectId,
      topicId: topicId,
      exerciseEvaluator: _exerciseEvaluator,
      clock: _clock,
    );

    await manager.initialize();

    final lessonPlan = await manager.generateLessonPlan(
      durationMinutes: durationMinutes,
    );

    await _database.tutorSessionRepository.saveSession(
      session.copyWith(lessonPlanJson: lessonPlan.toJsonString()),
    );

    _currentManager = manager;
    return manager;
  }

  Future<void> endLesson() async {
    if (_currentManager == null) return;

    final session = _currentManager!.toSession();
    final messages = _currentManager!.messages;

    for (final msg in messages) {
      await _database.conversationRepository.saveMessage(msg);
    }

    await _database.tutorSessionRepository.saveSession(session);

    if (session.questionsAsked > 0) {
      await _masteryService.recordAttempt(
        studentId: session.studentId,
        topicId: session.topicId,
        questionId: 'tutor_${session.id}',
        isCorrect: session.accuracy > 0.5,
        confidence: (session.confidenceRating * 20).clamp(0, 5).round(),
        timeSpentMs: _elapsedMinutes(session) * 60000,
      );
    }

    await _persistExercisesAsQuestions(session);

    try {
      await _planAdapter.recordFromTutorSession(
        studentId: session.studentId,
        actualMinutes: _elapsedMinutes(session).clamp(1, 480),
      );
    } catch (_) {}

    _currentManager = null;
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
    final question = Question(
      id: const Uuid().v4(),
      text: 'Tutor exercise: ${session.topicTitle}',
      type: QuestionType.typedAnswer,
      difficulty: (evalResult.score * 5).round().clamp(1, 5),
      subjectId: session.subjectId,
      topicId: session.topicId,
      sourceIds: ['tutor_${session.id}'],
      createdAt: now,
      updatedAt: now,
      explanation: evalResult.explanation,
    );

    await _database.questionRepository.create(question);
  }

  Future<List<TutorSession>> getLessonHistory(String studentId) async {
    return _database.tutorSessionRepository.getStudentSessions(studentId);
  }

  Future<List<ConversationMessage>> getSessionMessages(
      String sessionId) async {
    return _database.conversationRepository.getSessionMessages(sessionId);
  }

  Future<Map<String, dynamic>> getStats(String studentId) async {
    return _database.tutorSessionRepository.getSessionStats(studentId);
  }

  Future<void> saveMessage(ConversationMessage message) async {
    await _database.conversationRepository.saveMessage(message);
  }

  Future<TutorSession?> getActiveSession() async {
    final sessions =
        await _database.tutorSessionRepository.getActiveSessions();
    return sessions.isNotEmpty ? sessions.first : null;
  }
}
