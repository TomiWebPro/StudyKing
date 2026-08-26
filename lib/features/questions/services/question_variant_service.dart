import 'dart:convert';
import 'dart:math';

import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/id_generator.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/questions/services/question_variant_prompts.dart';

/// Generates and links concept-preserving, value-varying variants of a question.
///
/// Variants are used by adaptive practice / spaced repetition to re-test the
/// same concept with different values, which prevents rote memorisation and
/// strengthens retention. Generation is delegated to an LLM; persisted variants
/// are cross-linked to the source question (and to each other) via
/// [Question.variantIds].
///
/// All public methods return [Result] and never throw.
class QuestionVariantService {
  static final Logger _logger = const Logger('QuestionVariantService');

  final QuestionRepository _questionRepo;
  final LlmService _llmService;
  final String _modelId;
  final String _localeName;
  final Random _random;

  QuestionVariantService({
    required QuestionRepository questionRepo,
    required LlmService llmService,
    required String modelId,
    String localeName = 'en',
    Random? random,
  })  : _questionRepo = questionRepo,
        _llmService = llmService,
        _modelId = modelId,
        _localeName = localeName,
        _random = random ?? Random();

  /// Generates [count] concept-preserving variants of [source] via the LLM.
  ///
  /// Each generated variant is persisted and cross-linked to the source (and to
  /// its sibling variants) through [Question.variantIds]. The source question's
  /// own [Question.variantIds] is updated to include every new variant id.
  ///
  /// Returns the list of newly generated variant [Question]s on success. If the
  /// source already had variants, the new ones are appended (deduplicated).
  Future<Result<List<Question>>> generateVariants(
    Question source, {
    int count = 3,
  }) async {
      if (count <= 0) {
      return Result.failure('Variant count must be positive');
    }
    try {
      if (_modelId.isEmpty) {
        return Result.failure(
          'No model selected. Please choose an AI model in Settings to generate variants.',
        );
      }

      // All members of a generated family share one group id so the readiness
      // scorer and mastery tracker can reason about the concept as a unit.
      final groupId = source.variantGroupId.isNotEmpty
          ? source.variantGroupId
          : IdGenerator.generate('vq');

      final prompt = buildVariantGenerationPrompt(source: source, count: count);

      final llmResult = await _llmService.chat(
        message: prompt,
        modelId: _modelId,
        feature: 'question_variant_generation',
        localeName: _localeName,
      );

      if (llmResult.isFailure) {
        _logger.w('LLM variant generation failed for ${source.id}');
        return Result.failure(llmResult.error ?? 'LLM variant generation failed');
      }

      final parsed = _parseVariantList(llmResult.data!);
      if (parsed.isEmpty) {
        _logger.w('LLM returned no usable variants for ${source.id}');
        return Result.failure('LLM returned no usable variants');
      }

      final generated = <Question>[];
      final siblingIds = [...source.variantIds];

      for (final raw in parsed) {
        final variant = _buildVariant(
          source,
          raw,
          groupId: groupId,
          siblingIds: siblingIds,
        );
        final saveResult = await _questionRepo.create(variant);
        if (saveResult.isFailure) {
          _logger.w('Failed to persist variant ${variant.id}', saveResult.error);
          continue;
        }
        generated.add(variant);
        siblingIds.add(variant.id);
      }

      if (generated.isEmpty) {
        return Result.failure('Failed to persist any generated variants');
      }

      // Ensure the base question is also tagged with the family group id and
      // links back to every generated variant.
      if (source.variantGroupId != groupId || source.variantIds != siblingIds) {
        final updatedSource = source.copyWith(
          variantGroupId: groupId,
          variantIds: siblingIds,
        );
        final sourceSave = await _questionRepo.save(source.id, updatedSource);
        if (sourceSave.isFailure) {
          _logger.w('Failed to update source variantIds for ${source.id}',
              sourceSave.error);
        }
      }

      return Result.success(generated);
    } catch (e) {
      _logger.e('Unexpected error generating variants for ${source.id}', e);
      return Result.failure('QuestionVariantService.generateVariants: $e');
    }
  }

  /// Picks a variant to use as an immediate retry after an incorrect answer.
  ///
  /// Selection is restricted to already-generated variants linked from
  /// [Question.variantIds] (it does not trigger LLM generation). [excludeVariantId]
  /// lets callers avoid re-showing a variant that was just attempted. If no
  /// usable variant exists, the original [question] is returned so callers can
  /// fall back to re-asking the same question.
  Future<Result<Question>> selectVariantForRetry(
    Question question, {
    String? excludeVariantId,
  }) async {
    try {
      final variantIds = question.variantIds
          .where((id) => id != excludeVariantId && id != question.id)
          .toList();

      if (variantIds.isEmpty) {
        return Result.success(question);
      }

      final pickId = variantIds[_random.nextInt(variantIds.length)];
      final getResult = await _questionRepo.get(pickId);
      final variant = getResult.data;
      if (variant == null) {
        _logger.w('Linked variant $pickId not found for ${question.id}');
        return Result.success(question);
      }

      return Result.success(variant);
    } catch (e) {
      _logger.e('Unexpected error selecting retry variant for ${question.id}', e);
      return Result.failure('QuestionVariantService.selectVariantForRetry: $e');
    }
  }

  /// Returns the full variant family (base + generated variants) for [question].
  ///
  /// Useful for the question-bank UI to display variant relationships and for
  /// the mastery/analytics layer to aggregate concept-level statistics.
  Future<Result<List<Question>>> getVariantFamily(Question question) async {
    try {
      if (question.variantGroupId.isNotEmpty) {
        return await _questionRepo.getByVariantGroupId(question.variantGroupId);
      }
      return await _questionRepo.getVariantFamily(question.id);
    } catch (e) {
      _logger.e('Unexpected error loading variant family for ${question.id}', e);
      return Result.failure('QuestionVariantService.getVariantFamily: $e');
    }
  }

  List<Map<String, dynamic>> _parseVariantList(String response) {
    try {
      final arrayMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(response);
      final raw = arrayMatch != null ? arrayMatch.group(0)! : response.trim();
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    } catch (e) {
      _logger.w('Failed to parse variant JSON from LLM response', e);
      return const [];
    }
  }

  Question _buildVariant(
    Question source,
    Map<String, dynamic> raw, {
    required String groupId,
    required List<String> siblingIds,
  }) {
    final now = DateTime.now();
    final id = IdGenerator.generate('qv');
    final options = List<String>.from(raw['options'] as List? ?? const []);
    final correctAnswer = (raw['correctAnswer'] as String? ?? '').toString();
    final text = (raw['text'] as String? ?? source.text).toString();
    final explanation = (raw['explanation'] as String? ?? '').toString();

    final variantIds = <String>[source.id, ...siblingIds]
      ..removeWhere((v) => v == id);

    return Question(
      id: id,
      text: text,
      type: source.type,
      difficulty: source.difficulty,
      subjectId: source.subjectId,
      topicId: source.topicId,
      variantIds: variantIds,
      variantGroupId: groupId,
      sourceIds: source.sourceIds,
      options: options,
      allowedAnswerTypes: source.allowedAnswerTypes,
      markscheme: Markscheme(
        questionId: id,
        correctAnswer: correctAnswer,
        acceptableAnswers: const [],
        explanation: explanation.isNotEmpty ? explanation : null,
      ),
      topic: source.topic,
      tags: source.tags,
      explanation: explanation.isNotEmpty ? explanation : source.explanation,
      createdAt: now,
      updatedAt: now,
    );
  }
}
