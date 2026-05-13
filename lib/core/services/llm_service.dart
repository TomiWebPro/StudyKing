/// Canonical LLM services.
///
/// Responsibilities split by concern:
/// - [LlmService] & [LlmConfiguration] — chat completions, generation tasks
/// - [ModelListingService] & [AiModel] — model listing
/// - [EmbeddingService] — embeddings
library;

export 'llm/llm_chat_service.dart' show LlmService, LlmConfiguration, LlmProvider;
export 'llm/llm_model_service.dart' show ModelListingService, AiModel;
export 'llm/llm_embeddings_service.dart' show EmbeddingService;
