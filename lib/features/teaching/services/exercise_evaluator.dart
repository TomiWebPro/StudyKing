import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../core/services/llm/llm_chat_service.dart';
import '../../../core/utils/logger.dart';
import '../../../core/constants/llm_defaults.dart' show evaluationPromptTemplate;
import '../data/models/evaluation_result.dart';

class ExerciseEvaluator {
  static final Logger _logger = const Logger('ExerciseEvaluator');

  final LlmService _llmService;
  final String _modelId;
  final String _localeName;

  ExerciseEvaluator({
    required LlmService llmService,
    required String modelId,
    String localeName = 'en',
  })  : _llmService = llmService,
      _modelId = modelId,
      _localeName = localeName;

  String get _defaultSystemPrompt =>
      lookupAppLocalizations(Locale(_localeName)).evaluatorSystemPrompt;

  String _buildPrompt({
    required String question,
    required String studentAnswer,
    required String subjectId,
    required String topicTitle,
  }) {
    final l10n = lookupAppLocalizations(Locale(_localeName));
    return evaluationPromptTemplate(
      l10n: l10n,
      subjectId: subjectId,
      topicTitle: topicTitle,
      question: question,
      studentAnswer: studentAnswer,
    );
  }

  Future<EvaluationResult> evaluate({
    required String question,
    required String studentAnswer,
    required String subjectId,
    required String topicTitle,
    String? systemPrompt,
    String? userPrompt,
  }) async {
    final effectiveSystemPrompt = systemPrompt ?? _defaultSystemPrompt;
    final effectiveUserPrompt = userPrompt ??
        _buildPrompt(
          question: question,
          studentAnswer: studentAnswer,
          subjectId: subjectId,
          topicTitle: topicTitle,
        );

    final result = await _llmService.chat(
      message: effectiveUserPrompt,
      modelId: _modelId,
      systemPrompt: effectiveSystemPrompt,
      feature: 'teaching_evaluation',
    );
    if (result.isFailure) {
      return EvaluationResult(
        score: 0.5,
        explanation: 'Could not evaluate answer: ${result.error}',
      );
    }
    final response = result.data!;

    if (response.isEmpty) {
      return EvaluationResult(
        score: 0.5,
        explanation: 'Could not evaluate answer.',
      );
    }

    try {
      final json = jsonDecode(response) as Map<String, dynamic>;
      return EvaluationResult.fromJson(json);
    } catch (e) {
      _logger.w('Failed to parse evaluation response', e);
      return EvaluationResult(
        score: 0.5,
        explanation: response,
      );
    }
  }
}
