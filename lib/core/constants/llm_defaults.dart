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
    case LlmProvider.custom:
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
      '  "score": ${l10n.evalScoreDesc},\n'
      '  "$explanationKey": "${l10n.evalExplanationDesc}",\n'
      '  "$partialCreditKey": ${l10n.evalPartialCreditDesc},\n'
      '  "$conceptBreakdownKey": {${l10n.evalConceptBreakdownDesc}},\n'
      '  "correctAnswer": "${l10n.evalCorrectAnswerDesc}",\n'
      '  "type": "${l10n.evalTypeDesc}",\n'
      '  "options": [${l10n.evalOptionsDesc}]\n'
      '}';
}
