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
