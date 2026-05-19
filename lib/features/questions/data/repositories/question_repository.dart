import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

class QuestionRepository extends Repository<Question> {
  final Logger _logger = const Logger('QuestionRepository');

  Future<void> init() async {
    await openBox(HiveBoxNames.questions);
  }

  Future<Result<void>> create(Question question) async {
    try {
      final result = await save(question.id, question);
      if (result.isFailure) return Result.failure(result.error);
      return Result.success(null);
    } catch (e) {
      _logger.e('Error creating question', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Question>>> getByTopic(String topicId) async {
    try {
      if (!box.isOpen) {
        return Result.failure('Question_box_not_open');
      }
      return Result.success(filterBy((q) => q.topicId, topicId));
    } catch (e) {
      _logger.e('Error getting questions by topic', e);
      return Result.failure(
            e.toString());
    }
  }

  Future<Result<List<Question>>> getBySubject(String subjectId) async {
    try {
      if (!box.isOpen) {
        return Result.failure('Question_bank_not_open');
      }
      return Result.success(filterBy((q) => q.subjectId, subjectId));
    } catch (e) {
      _logger.e('Error getting questions by subject', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Question>>> getBySubjectAndTopic(
    String subjectId,
    String topicId,
  ) async {
    try {
      if (!box.isOpen) {
        return Result.failure('Question_bank_not_open');
      }
      final bySubject = filterBy((q) => q.subjectId, subjectId);
      return Result.success(
          bySubject.where((q) => q.topicId == topicId).toList());
    } catch (e) {
      _logger.e('Error getting questions by subject and topic', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Question>>> getByType(QuestionType type) async {
    try {
      if (!box.isOpen) {
        return Result.failure('Question_bank_not_open');
      }
      return Result.success(filterBy((q) => q.type, type));
    } catch (e) {
      _logger.e('Error getting questions by type', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Question>>> getBySubjectAndType(
    String subjectId,
    QuestionType type,
  ) async {
    try {
      if (!box.isOpen) {
        return Result.failure('Question_bank_not_open');
      }
      final bySubject = filterBy((q) => q.subjectId, subjectId);
      return Result.success(bySubject.where((q) => q.type == type).toList());
    } catch (e) {
      _logger.e('Error getting questions by subject and type', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<QuestionWithMarkscheme>>> getQuestionsWithMarkschemes(
      String subjectId) async {
    try {
      if (!box.isOpen) {
        return Result.failure('Question_bank_not_open');
      }
      final questions = box.values.toList();
      final filtered = questions.where((q) => q.markscheme != null).toList();

      if (filtered.isEmpty) {
        return Result.failure(
            'No_markscheme_for_subject: $subjectId');
      }

      return Result.success(
        filtered
            .map((q) => QuestionWithMarkscheme(
                  question: q,
                  markscheme: q.markscheme!,
                ))
            .toList(),
      );
    } catch (e) {
      _logger.e('Error getting questions with markscheme', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> updateMarkscheme(
      String questionId, Markscheme markscheme) async {
    try {
      final question = box.get(questionId);
      if (question == null) {
        return Result.failure('Question_not_found: $questionId');
      }
      final updated = question.copyWith(markscheme: markscheme);
      await box.put(questionId, updated);
      return Result.success(null);
    } catch (e) {
      _logger.e('Error updating markscheme', e);
      return Result.failure(e.toString());
    }
  }
}

class QuestionWithMarkscheme {
  final Question question;
  final Markscheme markscheme;

  QuestionWithMarkscheme({required this.question, required this.markscheme});
}
