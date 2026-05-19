import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/features/settings/data/models/settings_update.dart';
import 'package:studyking/core/providers/app_providers.dart'
    show apiBaseUrlProvider, apiKeyProvider, llmProviderProvider, selectedModelProvider, settingsProvider;
import 'package:studyking/core/constants/app_api_config.dart';
import 'package:studyking/core/constants/timeouts.dart';

class ApiConfigScreen extends ConsumerStatefulWidget {
  const ApiConfigScreen({super.key});

  @override
  ConsumerState<ApiConfigScreen> createState() => _ApiConfigScreenState();
}

class _ApiConfigScreenState extends ConsumerState<ApiConfigScreen> {
  final Logger _logger = const Logger('ApiConfigScreen');
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController();

  LlmProvider _selectedProvider = LlmProvider.openRouter;
  bool _isSaving = false;
  bool _isTesting = false;
  bool _obscureApiKey = true;

  String _initialApiKey = '';
  String _initialBaseUrl = '';
  LlmProvider _initialProvider = LlmProvider.openRouter;
  bool _hasUnsavedChanges = false;

  static const _knownDefaultUrls = [
    ApiConfig.openRouterBaseUrlString,
    ApiConfig.ollamaDefaultUrl,
    ApiConfig.openAIDefaultUrl,
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentValues();
    _apiKeyController.addListener(_onFieldChanged);
    _baseUrlController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _apiKeyController.removeListener(_onFieldChanged);
    _baseUrlController.removeListener(_onFieldChanged);
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    _updateUnsavedChanges();
  }

  void _updateUnsavedChanges() {
    setState(() {
      _hasUnsavedChanges = _apiKeyController.text != _initialApiKey ||
          _baseUrlController.text != _initialBaseUrl ||
          _selectedProvider != _initialProvider;
    });
  }

  void _loadCurrentValues() {
    final apiKey = ref.read(apiKeyProvider);
    final baseUrl = ref.read(apiBaseUrlProvider);
    final provider = ref.read(llmProviderProvider);
    setState(() {
      _apiKeyController.text = apiKey;
      _baseUrlController.text = baseUrl;
      _selectedProvider = provider;
      _initialApiKey = apiKey;
      _initialBaseUrl = baseUrl;
      _initialProvider = provider;
      _hasUnsavedChanges = false;
    });
  }

  Future<void> _saveKeys() async {
    final l10n = AppLocalizations.of(context)!;
    final errorColor = Theme.of(context).colorScheme.error;
    final successColor = Theme.of(context).colorScheme.primary;
    if (_apiKeyController.text.trim().isEmpty && _selectedProvider != LlmProvider.ollama) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.apiKeyCannotBeEmpty),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final apiKey = _apiKeyController.text.trim();
      final baseUrl = _baseUrlController.text.trim();

      ref.read(apiKeyProvider.notifier).state = apiKey;
      ref.read(apiBaseUrlProvider.notifier).state = baseUrl;
      ref.read(llmProviderProvider.notifier).state = _selectedProvider;
      ref.read(selectedModelProvider.notifier).state = '';
      await ref.read(settingsProvider.notifier).updateSettings(
            SettingsUpdate(
              apiKey: apiKey,
              apiBaseUrl: baseUrl,
              selectedModel: '',
            ),
            llmProvider: _selectedProvider,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.apiKeysSavedSuccessfully),
          backgroundColor: successColor,
        ),
      );

      if (!mounted) return;
      setState(() {
        _initialApiKey = apiKey;
        _initialBaseUrl = baseUrl;
        _initialProvider = _selectedProvider;
        _hasUnsavedChanges = false;
      });
      Navigator.pop(context);
    } catch (e) {
      _logger.w('Failed to save API config', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.unableToSaveApiConfig),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _testConnection() async {
    final l10n = AppLocalizations.of(context)!;
    final errorColor = Theme.of(context).colorScheme.error;
    final successColor = Theme.of(context).colorScheme.primary;
    final apiKey = _apiKeyController.text.trim();
    final baseUrl = _baseUrlController.text.trim();

    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.apiKeyCannotBeEmpty), backgroundColor: errorColor),
      );
      return;
    }

    setState(() => _isTesting = true);

    try {
      final stopwatch = Stopwatch()..start();
      final url = baseUrl.isNotEmpty ? '$baseUrl/models' : '${ApiConfig.openRouterBaseUrlString}/models';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $apiKey'},
      ).timeout(Timeouts.apiCall);
      stopwatch.stop();

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.connectionSuccessful(stopwatch.elapsedMilliseconds)),
            backgroundColor: successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.connectionFailed('HTTP ${response.statusCode}')),
            backgroundColor: errorColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.connectionFailed(e.toString())),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.unsavedChanges),
        content: Text(l10n.unsavedChangesDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(title: Text(l10n.apiConfiguration)),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.screenPadding(context),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.configureApiKeys,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              l10n.configureApiKeysDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _buildApiSection(
              title: l10n.openRouterApiKey,
              controller: _apiKeyController,
              hint: l10n.apiKeyHint,
              description: l10n.apiKeyDescription,
              obscureText: _obscureApiKey,
            ),
            const SizedBox(height: 24),
            _buildProviderSection(),
            const SizedBox(height: 24),
            _buildApiSection(
              title: l10n.apiBaseUrl,
              controller: _baseUrlController,
              hint: l10n.apiBaseUrlHint,
              description: l10n.apiBaseUrlDescription,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveKeys,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(l10n.saveApiKeys),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering),
                label: Text(_isTesting ? l10n.testing : l10n.testConnection),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildApiSection({
    required String title,
    required TextEditingController controller,
    required String hint,
    required String description,
    bool obscureText = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            suffixIcon: obscureText
                ? IconButton(
                    icon: Icon(
                      _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                    ),
                    tooltip: l10n.toggleVisibility,
                    onPressed: () => setState(() {
                      _obscureApiKey = !_obscureApiKey;
                    }),
                  )
                : null,
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildProviderSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.aiModel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<LlmProvider>(
          initialValue: _selectedProvider,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: LlmProvider.values.map((provider) {
            String label;
            switch (provider) {
              case LlmProvider.openRouter:
                label = 'OpenRouter';
                break;
              case LlmProvider.ollama:
                label = 'Ollama';
                break;
              case LlmProvider.openAI:
                label = 'OpenAI';
                break;
            }
            return DropdownMenuItem(
              value: provider,
              child: Text(label),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            ref.read(llmProviderProvider.notifier).state = value;

            setState(() {
              _selectedProvider = value;

              final currentUrl = _baseUrlController.text;
              if (currentUrl.isEmpty || _knownDefaultUrls.contains(currentUrl)) {
                switch (value) {
                  case LlmProvider.openRouter:
                    _baseUrlController.text = ApiConfig.openRouterBaseUrlString;
                    break;
                  case LlmProvider.ollama:
                    _baseUrlController.text = ApiConfig.ollamaDefaultUrl;
                    break;
                  case LlmProvider.openAI:
                    _baseUrlController.text = ApiConfig.openAIDefaultUrl;
                    break;
                }
              }

              ref.read(apiBaseUrlProvider.notifier).state = _baseUrlController.text;
            });
            _updateUnsavedChanges();
          },
        ),
        const SizedBox(height: 4),
        Text(
          l10n.apiBaseUrlDescription,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
