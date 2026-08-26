import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

class QuestionRepository extends Repository<Question> {
  QuestionRepository() : super(boxName: HiveBoxNames.questions);
  static final Logger _logger = const Logger('QuestionRepository');

  Future<void> init() async {
    await openBox(HiveBoxNames.questions);
  }

  Future<Result<void>> create(Question question) async {
    try {
      final result = await save(question.id, question);
      if (result.isFailure) return Result.failure(result.error);
      return Result.success(null);
    } catch (e) {
      _logger.w('Error creating question', e);
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
      _logger.w('Error getting questions by topic', e);
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
      _logger.w('Error getting questions by subject', e);
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
      _logger.w('Error getting questions by subject and topic', e);
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
      _logger.w('Error getting questions by type', e);
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
      _logger.w('Error getting questions by subject and type', e);
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
      _logger.w('Error getting questions with markscheme', e);
      return Result.failure(e.toString());
    }
  }

  /// Returns every question that shares the given [variantGroupId], including
  /// the base question and all of its variants. Returns an empty list when the
  /// group id is empty or no questions belong to it.
  Future<Result<List<Question>>> getByVariantGroupId(String groupId) async {
    try {
      if (!box.isOpen) {
        return Result.failure('Question_bank_not_open');
      }
      if (groupId.isEmpty) {
        return Result.success(const []);
      }
      final all = box.values.toList();
      return Result.success(
        all.where((q) => q.variantGroupId == groupId).toList(),
      );
    } catch (e) {
      _logger.w('Error getting questions by variant group', e);
      return Result.failure(e.toString());
    }
  }

  /// Returns the variant family of [questionId]: the question itself plus every
  /// other question that links to it via [Question.variantIds] or shares its
  /// [Question.variantGroupId].
  Future<Result<List<Question>>> getVariantFamily(String questionId) async {
    try {
      if (!box.isOpen) {
        return Result.failure('Question_bank_not_open');
      }
      final baseResult = await get(questionId);
      final base = baseResult.data;
      if (base == null) {
        return Result.failure('Question_not_found: $questionId');
      }

      final all = box.values.toList();
      final family = all.where((q) {
        if (q.id == questionId) return true;
        if (base.variantGroupId.isNotEmpty &&
            q.variantGroupId == base.variantGroupId) {
          return true;
        }
        return q.variantIds.contains(questionId) ||
            base.variantIds.contains(q.id);
      }).toList();

      return Result.success(family);
    } catch (e) {
      _logger.w('Error getting variant family', e);
      return Result.failure(e.toString());
    }
  }

  /// Cross-links a generated [variantId] to its [baseId] so they form a variant
  /// family. Updates the base question's [Question.variantIds], sets the
  /// variant's [Question.variantGroupId] to [groupId], and adds the base id to
  /// the variant's [Question.variantIds]. Both records are persisted.
  Future<Result<void>> linkVariant({
    required String baseId,
    required String variantId,
    required String groupId,
  }) async {
    try {
      if (!box.isOpen) {
        return Result.failure('Question_bank_not_open');
      }
      if (baseId == variantId) {
        return Result.failure('Cannot link a question to itself');
      }
      final base = box.get(baseId);
      if (base == null) {
        return Result.failure('Question_not_found: $baseId');
      }
      final variant = box.get(variantId);
      if (variant == null) {
        return Result.failure('Question_not_found: $variantId');
      }

      final updatedBase = base.copyWith(
        variantIds: [...base.variantIds, variantId],
        variantGroupId: groupId,
      );
      final updatedVariant = variant.copyWith(
        variantGroupId: groupId,
        variantIds: [...variant.variantIds, baseId]
          ..removeWhere((id) => id == variantId),
      );

      final baseSave = await save(updatedBase.id, updatedBase);
      if (baseSave.isFailure) return Result.failure(baseSave.error);
      final variantSave = await save(updatedVariant.id, updatedVariant);
      if (variantSave.isFailure) return Result.failure(variantSave.error);

      return Result.success(null);
    } catch (e) {
      _logger.w('Error linking variant', e);
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
      _logger.w('Error updating markscheme', e);
      return Result.failure(e.toString());
    }
  }
}

class QuestionWithMarkscheme {
  final Question question;
  final Markscheme markscheme;

  QuestionWithMarkscheme({required this.question, required this.markscheme});
}
