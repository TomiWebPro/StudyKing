import 'package:studyking/core/constants/llm_defaults.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/string_extensions.dart';

/// Agent tool that switches the AI provider / model at runtime.
///
/// Vision Next-Term §3.1 (`scenario_longterm_user_accelerates`):
/// > "Student says 'Switch to Ollama instead of OpenRouter.' The mentor calls
/// > `switch_provider` and responds with confirmation."
///
/// The tool validates the provider name and optional arguments, then delegates
/// the actual configuration update to [onSwitch] — a callback that, in production,
/// updates the Riverpod [StateProvider]s (`apiKeyProvider`, `llmProviderProvider`,
/// `apiBaseUrlProvider`, `selectedModelProvider`) and persists to Hive via
/// `SettingsController.updateSettings`. In tests this callback is a simple
/// recording stub.
///
/// Ollama (local) does not require an API key; all other providers require one.
class SwitchProviderTool extends AgentTool {
  static final Logger _logger = const Logger('SwitchProviderTool');

  /// Updates the provider configuration. Returns [Result.success] when the
  /// configuration was applied, or [Result.failure] with a human-readable error.
  final Future<Result<void>> Function({
    required LlmProvider provider,
    required String? apiKey,
    required String? baseUrl,
    required String? model,
  }) onSwitch;

  SwitchProviderTool({
    required this.onSwitch,
  });

  @override
  String get name => 'switch_provider';

  @override
  String get description =>
      'Switch the active AI provider (openRouter, ollama, openAI, custom) '
      'and optionally update the API key, base URL, and model. Use this only '
      'after the student explicitly confirms they want to switch providers. '
      'Ollama is local and does not require an API key; all other providers do. '
      'After switching, the new configuration takes effect for subsequent chats.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'provider': {
            'type': 'string',
            'description':
                'Provider name: openRouter, ollama, openAI, or custom. Required.',
            'enum': LlmProvider.values.map((p) => p.name).toList(),
          },
          'apiKey': {
            'type': 'string',
            'description': 'API key for the new provider. Required for '
                'openRouter, openAI, and custom. Omit for ollama (local).',
          },
          'baseUrl': {
            'type': 'string',
            'description': 'Base URL for custom providers. '
                'Ignored for openRouter and openAI (uses defaults).',
          },
          'model': {
            'type': 'string',
            'description': 'Model ID. If omitted, a sensible default '
                'for the provider is used.',
          },
        },
        'required': ['provider'],
      };

  /// Converts a provider name string to [LlmProvider].
  /// Returns `null` if the name is not a valid provider.
  static LlmProvider? parseProvider(String? name) {
    if (name == null || name.isEmpty) return null;
    final normalized = name.normalized;
    for (final p in LlmProvider.values) {
      if (p.name.toLowerCase() == normalized) return p;
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final providerName = args['provider'] as String? ?? '';
    final provider = parseProvider(providerName);

    if (provider == null) {
      final validNames = LlmProvider.values.map((p) => p.name).join(', ');
      _logger.w('Unknown provider requested: "$providerName" '
          '(valid: $validNames)');
      return {
        'success': false,
        'error':
            'Unknown provider: "$providerName". Valid providers: $validNames',
      };
    }

    final apiKey = args['apiKey'] as String?;
    final baseUrl = args['baseUrl'] as String?;
    final model = args['model'] as String?;

    // Ollama is local and does not require an API key.
    // All other providers require a non-empty API key.
    if (provider != LlmProvider.ollama) {
      if (apiKey == null || apiKey.normalized.isEmpty) {
        _logger.w('Provider switch to $providerName rejected: API key required');
        return {
          'success': false,
          'error': 'API key is required for provider: $providerName',
          'provider': providerName,
        };
      }
    }

    // Determine the effective model: use the provided one, or fall back to
    // the provider's default model.
    final effectiveModel =
        (model != null && model.isNotEmpty) ? model : defaultModelForProvider(provider);

    // Apply the configuration update via the callback.
    final result = await onSwitch(
      provider: provider,
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
    );

    return {
      'success': result.isSuccess,
      'provider': providerName,
      'model': effectiveModel,
      'apiKeySet': apiKey != null && apiKey.isNotEmpty,
      if (result.isSuccess)
        'message': 'Switched to $providerName with model $effectiveModel.'
      else
        'error': result.error ?? 'Unknown error switching provider.',
    };
  }
}
