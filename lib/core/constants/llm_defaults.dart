import '../services/llm/llm_chat_service.dart' show LlmProvider;
import '../../l10n/generated/app_localizations.dart';

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
  required AppLocalizations l10n,
  required String subjectId,
  required String topicTitle,
  required String question,
  required String studentAnswer,
  String explanationKey = 'explanation',
  String partialCreditKey = 'partialCredit',
  String conceptBreakdownKey = 'conceptBreakdown',
}) {
  final intro = l10n.evaluateStudentAnswerIntro(
    subjectId, topicTitle, question, studentAnswer,
  );
  return '$intro\n'
      '{\n'
      '  "score": <0.0 to 1.0>,\n'
      '  "$explanationKey": "<detailed feedback explaining what was correct/incorrect>",\n'
      '  "$partialCreditKey": <optional 0.0-1.0 for partially correct parts>,\n'
      '  "$conceptBreakdownKey": {<optional map of concept name to mastery score 0.0-1.0>},\n'
      '  "correctAnswer": "<the correct answer to the exercise question>",\n'
      '  "type": "<question type: typedAnswer|singleChoice|multiChoice|essay|mathExpression>",\n'
      '  "options": [<for singleChoice/multiChoice, list of answer options; otherwise empty>]\n'
      '}';
}
