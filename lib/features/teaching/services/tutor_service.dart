import 'dart:async';
import '../../../core/data/database_service.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import '../../../core/services/llm/llm_chat_service.dart';
import '../../../core/services/mastery_graph_service.dart';
import '../../../core/services/plan_adapter.dart';
import 'conversation_manager.dart';

class TutorService {
  final DatabaseService _database;
  final LlmService _llmService;
  final MasteryGraphService _masteryService;
  final String _modelId;
  final PlanAdapter _planAdapter;
  ConversationManager? _currentManager;

  TutorService({
    required DatabaseService database,
    required LlmService llmService,
    required MasteryGraphService masteryService,
    required String modelId,
    PlanAdapter? planAdapter,
  })  : _database = database,
        _llmService = llmService,
        _masteryService = masteryService,
        _modelId = modelId,
        _planAdapter = planAdapter ?? PlanAdapter();

  ConversationManager? get currentManager => _currentManager;

  Future<ConversationManager> startLesson({
    required String studentId,
    required String subjectId,
    required String topicId,
    required String topicTitle,
    required List<String> correctKeywords,
    required List<String> incorrectKeywords,
    required List<String> exerciseKeywords,
    int durationMinutes = 45,
  }) async {
    final sessionId = 'tutor_${DateTime.now().millisecondsSinceEpoch}';

    final session = TutorSession(
      id: sessionId,
      studentId: studentId,
      subjectId: subjectId,
      topicId: topicId,
      topicTitle: topicTitle,
      status: SessionStatus.inProgress,
      startTime: DateTime.now(),
      plannedDurationMinutes: durationMinutes,
    );
    await _database.tutorSessionRepository.saveSession(session);

    final manager = ConversationManager(
      llmService: _llmService,
      modelId: _modelId,
      sessionId: sessionId,
      correctKeywords: correctKeywords,
      incorrectKeywords: incorrectKeywords,
      exerciseKeywords: exerciseKeywords,
    );

    manager.initialize(
      studentId: studentId,
      topicTitle: topicTitle,
      subjectId: subjectId,
      topicId: topicId,
    );

    final lessonPlan = await manager.generateLessonPlan(
      topicTitle: topicTitle,
      subjectId: subjectId,
      durationMinutes: durationMinutes,
    );

    await _database.tutorSessionRepository.saveSession(
      session.copyWith(lessonPlanJson: lessonPlan),
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
        timeSpentMs: session.elapsedMinutes * 60000,
      );
    }

    try {
      await _planAdapter.recordFromTutorSession(
        studentId: session.studentId,
        actualMinutes: session.elapsedMinutes.clamp(1, 480),
      );
    } catch (_) {}

    _currentManager = null;
  }

  Future<List<TutorSession>> getLessonHistory(String studentId) async {
    return _database.tutorSessionRepository.getStudentSessions(studentId);
  }

  Future<List<ConversationMessage>> getSessionMessages(String sessionId) async {
    return _database.conversationRepository.getSessionMessages(sessionId);
  }

  Future<Map<String, dynamic>> getStats(String studentId) async {
    return _database.tutorSessionRepository.getSessionStats(studentId);
  }

  Future<void> saveMessage(ConversationMessage message) async {
    await _database.conversationRepository.saveMessage(message);
  }

  Future<TutorSession?> getActiveSession() async {
    final sessions = await _database.tutorSessionRepository.getActiveSessions();
    return sessions.isNotEmpty ? sessions.first : null;
  }
}
