import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/features/practice/data/models/answer_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

/// Stores predefined correct answer choices for questions.
/// This is distinct from [StudentAttempt] which tracks student-submitted responses.
class QuestionChoiceRepository extends Repository<QuestionChoice> {
  final Logger _logger = const Logger('QuestionChoiceRepository');

  Future<void> init() async {
    await openBox(HiveBoxNames.answers);
  }

  Future<Result<void>> create(QuestionChoice choice) async {
    try {
      await save(choice.id, choice);
      return Result.success(null);
    } catch (e) {
      _logger.e('Error creating question choice', e);
      return Result.failure('Failed to create question choice: ${e.toString()}');
    }
  }

  Future<Result<List<QuestionChoice>>> getByQuestion(String questionId) async {
    try {
      return Result.success(filterBy((a) => a.questionId, questionId));
    } catch (e) {
      _logger.e('Error getting choices by question', e);
      return Result.failure('Failed to get choices: ${e.toString()}');
    }
  }
}
