import 'dart:convert';
import '../../../core/services/llm/llm_chat_service.dart';
import '../data/models/evaluation_result.dart';

class ExerciseEvaluator {
  final LlmService _llmService;
  final String _modelId;

  ExerciseEvaluator({
    required LlmService llmService,
    required String modelId,
  })  : _llmService = llmService,
        _modelId = modelId;

  static const String _defaultSystemPrompt =
      'You are an expert academic evaluator. Assess the student\'s answer and return a JSON object with: score (0.0-1.0), explanation, partialCredit (optional), conceptBreakdown (optional map of concept->score). Be fair and encouraging. Consider partial credit for partially correct answers.';

  String _buildPrompt({
    required String question,
    required String studentAnswer,
    required String subjectId,
    required String topicTitle,
  }) {
    return '''
Evaluate this student answer for the subject "$subjectId" on topic "$topicTitle".

Question: $question

Student Answer: $studentAnswer

Return a JSON object with:
{
  "score": <0.0 to 1.0>,
  "explanation": "<detailed feedback explaining what was correct/incorrect>",
  "partialCredit": <optional 0.0-1.0 for partially correct parts>,
  "conceptBreakdown": {<optional map of concept name to mastery score 0.0-1.0>}
}
''';
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

    final response = await _llmService.chat(
      message: effectiveUserPrompt,
      modelId: _modelId,
      systemPrompt: effectiveSystemPrompt,
      feature: 'teaching_evaluation',
    );

    if (response.isEmpty) {
      return EvaluationResult(
        score: 0.5,
        explanation: 'Could not evaluate answer.',
      );
    }

    try {
      final json = jsonDecode(response) as Map<String, dynamic>;
      return EvaluationResult.fromJson(json);
    } catch (_) {
      return EvaluationResult(
        score: 0.5,
        explanation: response,
      );
    }
  }
}
