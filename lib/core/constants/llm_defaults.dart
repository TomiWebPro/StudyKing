import '../services/llm/llm_chat_service.dart' show LlmProvider;

String defaultModelForProvider(LlmProvider provider) {
  switch (provider) {
    case LlmProvider.openRouter:
      return 'gemini-2.0-flash';
    case LlmProvider.ollama:
      return 'llama3';
    case LlmProvider.openAI:
      return 'gpt-4o-mini';
  }
}

String evaluationPromptTemplate({
  required String subjectId,
  required String topicTitle,
  required String question,
  required String studentAnswer,
  String explanationKey = 'explanation',
  String partialCreditKey = 'partialCredit',
  String conceptBreakdownKey = 'conceptBreakdown',
}) {
  return 'Evaluate this student answer for the subject "$subjectId" on topic "$topicTitle".\n'
      '\nQuestion: $question\n'
      '\nStudent Answer: $studentAnswer\n'
      '\nReturn a JSON object with:\n'
      '{\n'
      '  "score": <0.0 to 1.0>,\n'
      '  "$explanationKey": "<detailed feedback explaining what was correct/incorrect>",\n'
      '  "$partialCreditKey": <optional 0.0-1.0 for partially correct parts>,\n'
      '  "$conceptBreakdownKey": {<optional map of concept name to mastery score 0.0-1.0>}\n'
      '}';
}
