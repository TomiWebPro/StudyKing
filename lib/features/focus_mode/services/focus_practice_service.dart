import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_type.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';

class FocusPracticeService {
  static final Logger _logger = const Logger('FocusPracticeService');
  final SpacedRepetitionService _srService;
  final MasteryGraphService _masteryGraphService;
  final SessionRepository _sessionRepository;
  final QuestionRepository _questionRepository;

  FocusPracticeService({
    required SpacedRepetitionService srService,
    required MasteryGraphService masteryGraphService,
    required SessionRepository sessionRepository,
    required QuestionRepository questionRepository,
  })  : _srService = srService,
        _masteryGraphService = masteryGraphService,
        _sessionRepository = sessionRepository,
        _questionRepository = questionRepository;

  Future<List<Question>> getDueQuestions({
    required String studentId,
    List<String>? subjectIds,
    int limit = 20,
  }) async {
    try {
      final dueResult = await _srService.getQuestionsDueForReview();
      if (dueResult.isFailure || dueResult.data == null) return [];

      var dueQuestions = dueResult.data!;

      if (subjectIds != null && subjectIds.isNotEmpty) {
        dueQuestions = dueQuestions.where((q) => subjectIds.contains(q.subjectId)).toList();
      }

      final weakResult = await _masteryGraphService.getWeakTopics(studentId);
      if (weakResult.isSuccess && weakResult.data != null && weakResult.data!.isNotEmpty) {
        final weakTopicIds = weakResult.data!.map((s) => s.topicId).toSet();
        final weakQuestions = dueQuestions.where((q) => weakTopicIds.contains(q.topicId)).toList();
        final otherQuestions = dueQuestions.where((q) => !weakTopicIds.contains(q.topicId)).toList();
        weakQuestions.shuffle();
        otherQuestions.shuffle();
        dueQuestions = [...weakQuestions, ...otherQuestions];
      } else {
        dueQuestions.shuffle();
      }

      return dueQuestions.take(limit).toList();
    } catch (e) {
      _logger.w('Failed to get due questions for focus practice', e);
      return [];
    }
  }

  Future<List<Question>> getWeakAreaQuestions({
    required String studentId,
    List<String>? subjectIds,
    int limit = 20,
  }) async {
    try {
      final weakResult = await _masteryGraphService.getWeakTopics(studentId);
      if (weakResult.isFailure || weakResult.data == null || weakResult.data!.isEmpty) {
        return [];
      }

      final weakTopicIds = weakResult.data!.map((s) => s.topicId).toSet();
      final allResult = await _questionRepository.getAll();
      final allQuestions = allResult.data ?? [];

      var filtered = allQuestions.where((q) => weakTopicIds.contains(q.topicId)).toList();
      if (subjectIds != null && subjectIds.isNotEmpty) {
        filtered = filtered.where((q) => subjectIds.contains(q.subjectId)).toList();
      }

      filtered.shuffle();
      return filtered.take(limit).toList();
    } catch (e) {
      _logger.w('Failed to get weak area questions for focus practice', e);
      return [];
    }
  }

  Future<List<Question>> getQuestionsForSessionType({
    required FocusSessionType sessionType,
    required String studentId,
    List<String>? subjectIds,
    int limit = 20,
  }) async {
    switch (sessionType) {
      case FocusSessionType.quickPractice:
        final allResult = await _questionRepository.getAll();
        var all = allResult.data ?? [];
        if (subjectIds != null && subjectIds.isNotEmpty) {
          all = all.where((q) => subjectIds.contains(q.subjectId)).toList();
        }
        all.shuffle();
        return all.take(limit).toList();
      case FocusSessionType.weakAreaAttack:
        return getWeakAreaQuestions(
          studentId: studentId,
          subjectIds: subjectIds,
          limit: limit,
        );
      case FocusSessionType.spacedRepetition:
      case FocusSessionType.freeFocus:
        return getDueQuestions(
          studentId: studentId,
          subjectIds: subjectIds,
          limit: limit,
        );
    }
  }

  Future<Result<Session>> startPracticeSession({
    required String studentId,
    List<String>? subjectIds,
    int durationMinutes = 25,
  }) async {
    try {
      final session = Session(
        id: 'focus_${DateTime.now().millisecondsSinceEpoch}',
        studentId: studentId,
        type: SessionType.focus,
        startTime: DateTime.now(),
        plannedDurationMinutes: durationMinutes,
        subjectId: subjectIds?.firstOrNull,
      );
      await _sessionRepository.save(session.id, session);
      return Result.success(session);
    } catch (e) {
      _logger.w('Failed to start practice session', e);
      return Result.failure('FocusPracticeService.startPracticeSession: $e');
    }
  }

  Future<Result<void>> endPracticeSession(Session session, {int questionsAnswered = 0, int correctAnswers = 0}) async {
    try {
      final updated = session.copyWith(
        status: SessionStatus.completed,
        completed: true,
        endTime: DateTime.now(),
        questionsAnswered: questionsAnswered,
        correctAnswers: correctAnswers,
      );
      final saveResult = await _sessionRepository.save(updated.id, updated);
      if (saveResult.isFailure) {
        _logger.w('Failed to save ended practice session: ${saveResult.error}');
        return Result.failure(saveResult.error);
      }
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to end practice session', e);
      return Result.failure('FocusPracticeService.endPracticeSession: $e');
    }
  }
}
