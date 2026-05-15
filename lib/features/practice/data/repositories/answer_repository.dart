import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/features/practice/data/models/answer_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

class AnswerRepository extends Repository<Answer> {
  final Logger _logger = const Logger('AnswerRepository');

  Future<void> init() async {
    await openBox(HiveBoxNames.answers);
  }

  Future<Result<void>> create(Answer answer) async {
    try {
      await save(answer.id, answer);
      return Result.success(null);
    } catch (e) {
      _logger.e('Error creating answer', e);
      return Result.failure('Failed to create answer: ${e.toString()}');
    }
  }

  Future<Result<List<Answer>>> getByQuestion(String questionId) async {
    try {
      return Result.success(filterBy((a) => a.questionId, questionId));
    } catch (e) {
      _logger.e('Error getting answers by question', e);
      return Result.failure('Failed to get answers: ${e.toString()}');
    }
  }
}
