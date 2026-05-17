import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/features/questions/data/models/question_evaluation_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

class QuestionEvaluationRepository extends Repository<QuestionEvaluation> {
  final Logger _logger = const Logger('QuestionEvaluationRepository');

  Future<void> init() async {
    try {
      await openBox(HiveBoxNames.questionEvaluations);
    } catch (e) {
      _logger.e('Error initializing QuestionEvaluationRepository', e);
      rethrow;
    }
  }

  Future<Result<QuestionEvaluation>> getEvaluation(String questionId) async {
    try {
      final evaluation = box.get(questionId);
      if (evaluation != null) {
        return Result.success(evaluation);
      }
      return Result.failure('not_found');
    } catch (e) {
      _logger.e('Error getting evaluation', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> saveEvaluation(QuestionEvaluation evaluation) async {
    try {
      await box.put(evaluation.questionId, evaluation);
      return Result.success(null);
    } catch (e) {
      _logger.e('Error saving evaluation', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> migrateFromLegacy({
    required String questionId,
    String? markscheme,
    String? correctAnswer,
    List<String>? options,
    String? explanation,
  }) async {
    try {
      final existing = box.get(questionId);
      if (existing != null) return Result.success(null);

      final evaluation = QuestionEvaluation.fromLegacy(
        questionId: questionId,
        markscheme: markscheme,
        correctAnswer: correctAnswer,
        options: options,
        explanation: explanation,
      );
      await box.put(questionId, evaluation);
      return Result.success(null);
    } catch (e) {
      _logger.e('Error migrating legacy evaluation', e);
      return Result.failure(e.toString());
    }
  }
}
