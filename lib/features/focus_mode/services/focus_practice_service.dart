import 'dart:async';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';

class FocusPracticeService {
  final Logger _logger = const Logger('FocusPracticeService');
  final DatabaseService _database;
  final SessionRepository _sessionRepository;
  final AttemptRepository _attemptRepository;

  FocusPracticeService({
    required DatabaseService database,
    required SessionRepository sessionRepository,
    required AttemptRepository attemptRepository,
  })  : _database = database,
        _sessionRepository = sessionRepository,
        _attemptRepository = attemptRepository;

  Future<List<Question>> getDueQuestions({
    required String studentId,
    List<String>? subjectIds,
    int limit = 20,
  }) async {
    final questions = <Question>[];
    try {
      final allResult = await _database.questionRepository.getAll();
      if (allResult.isFailure || allResult.data == null) return [];

      var allQuestions = allResult.data!;
      if (subjectIds != null && subjectIds.isNotEmpty) {
        allQuestions = allQuestions.where((q) => subjectIds.contains(q.subjectId)).toList();
      }

      // Get recent attempts to determine which questions are due for review
      final attemptsResult = await _attemptRepository.getByStudent(studentId);
      final attempts = attemptsResult.data ?? [];
      final attemptedQuestionIds = attempts.map((a) => a.questionId).toSet();

      // Prioritize questions not yet attempted, then questions needing review
      final unattempted = allQuestions.where((q) => !attemptedQuestionIds.contains(q.id)).toList();
      final attempted = allQuestions.where((q) => attemptedQuestionIds.contains(q.id)).toList();

      questions.addAll(unattempted.take(limit));
      if (questions.length < limit) {
        questions.addAll(attempted.take(limit - questions.length));
      }
    } catch (e) {
      _logger.w('Failed to get due questions for focus practice', e);
    }
    return questions.take(limit).toList();
  }

  Future<Session> startPracticeSession({
    required String studentId,
    List<String>? subjectIds,
    int durationMinutes = 25,
  }) async {
    final session = Session(
      id: 'focus_${DateTime.now().millisecondsSinceEpoch}',
      studentId: studentId,
      type: SessionType.focus,
      startTime: DateTime.now(),
      plannedDurationMinutes: durationMinutes,
      subjectId: subjectIds?.firstOrNull,
    );
    await _sessionRepository.save(session.id, session);
    return session;
  }

  Future<void> endPracticeSession(Session session, {int questionsAnswered = 0, int correctAnswers = 0}) async {
    final updated = session.copyWith(
      status: SessionStatus.completed,
      completed: true,
      endTime: DateTime.now(),
      questionsAnswered: questionsAnswered,
      correctAnswers: correctAnswers,
    );
    await _sessionRepository.save(updated.id, updated);
  }
}
