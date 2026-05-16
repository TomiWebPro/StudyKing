import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

/// Legacy wrapper that delegates to [SpacedRepetitionService].
/// New code should depend on [SpacedRepetitionService] directly.
@Deprecated('Use SpacedRepetitionService directly instead')
class SpacedRepetitionRepository {
  final Logger _logger = const Logger('SpacedRepetitionRepository');
  final SpacedRepetitionService _service;
  final QuestionRepository _questionRepo;

  SpacedRepetitionRepository({
    QuestionRepository? questionRepo,
    AttemptRepository? attemptRepo,
    SpacedRepetitionService? service,
  })  : _questionRepo = questionRepo ?? QuestionRepository(),
        _service = service ?? SpacedRepetitionService(
          questionRepo: questionRepo ?? QuestionRepository(),
          attemptRepo: attemptRepo ?? AttemptRepository(),
        );
  Future<void> init() async {
    try {
      await _questionRepo.init();
    } catch (e) {
      _logger.e('Error initializing spaced repetition repository', e);
      rethrow;
    }
  }

  Future<Result<List<Question>>> getQuestionsDueForReview(
      {DateTime? asOf}) async {
    return _service.getQuestionsDue(asOf: asOf);
  }

  Future<Result<void>> updateNextReviewDate(
      String questionId, double masteryLevel) async {
    return _service.updateNextReviewDate(questionId, masteryLevel);
  }

  Future<Result<List<DateTime>>> getQuestionDueTimes(
      String questionId) async {
    return _service.getQuestionDueTimes(questionId);
  }

  Future<Result<List<Question>>> getPracticeQuestions(
      String subjectId) async {
    return _service.getPracticeQuestions(subjectId);
  }

  Future<Result<List<Question>>> getTopicTimeDue(String topicId) async {
    return _service.getTopicTimeDue(topicId);
  }

  Future<Result<void>> removeDueQuestions(String questionId) async {
    return _service.removeDueQuestions(questionId);
  }

  Future<Result<int>> getSubjectDueCount(String subjectId) async {
    return _service.getSubjectDueCount(subjectId);
  }
}
