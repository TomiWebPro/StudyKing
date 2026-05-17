import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../core/services/llm/llm_chat_service.dart';
import '../../../core/utils/logger.dart';
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
    // Invariant prompt format with JSON template
    return 'Evaluate this student answer for the subject "$subjectId" on topic "$topicTitle".\n'
        '\nQuestion: $question\n'
        '\nStudent Answer: $studentAnswer\n'
        '\nReturn a JSON object with:\n'
        '{\n'
        '  "score": <0.0 to 1.0>,\n'
        '  "explanation": "<detailed feedback explaining what was correct/incorrect>",\n'
        '  "partialCredit": <optional 0.0-1.0 for partially correct parts>,\n'
        '  "conceptBreakdown": {<optional map of concept name to mastery score 0.0-1.0>}\n'
        '}';
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
