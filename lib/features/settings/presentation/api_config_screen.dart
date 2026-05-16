import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/providers/app_providers.dart'
    show apiBaseUrlProvider, apiKeyProvider, llmProviderProvider, settingsProvider;

class ApiConfigScreen extends ConsumerStatefulWidget {
  const ApiConfigScreen({super.key});

  @override
  ConsumerState<ApiConfigScreen> createState() => _ApiConfigScreenState();
}

class _ApiConfigScreenState extends ConsumerState<ApiConfigScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController();

  LlmProvider _selectedProvider = LlmProvider.openRouter;
  bool _isSaving = false;
  bool _isTesting = false;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentValues();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  void _loadCurrentValues() {
    setState(() {
      _apiKeyController.text = ref.read(apiKeyProvider);
      _baseUrlController.text = ref.read(apiBaseUrlProvider);
      _selectedProvider = ref.read(llmProviderProvider);
    });
  }

  Future<void> _saveKeys() async {
    final l10n = AppLocalizations.of(context)!;
    final errorColor = Theme.of(context).colorScheme.error;
    final successColor = Theme.of(context).colorScheme.primary;
    if (_apiKeyController.text.trim().isEmpty) {
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
      await ref.read(settingsProvider.notifier).updateSettings(
            apiKey: apiKey,
            apiBaseUrl: baseUrl,
            llmProvider: _selectedProvider,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.apiKeysSavedSuccessfully),
          backgroundColor: successColor,
        ),
      );
      Navigator.pop(context);
    } catch (_) {
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
      final url = baseUrl.isNotEmpty ? '$baseUrl/models' : 'https://openrouter.ai/api/v1/models';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $apiKey'},
      ).timeout(const Duration(seconds: 15));
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.apiConfiguration)),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.screenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.configureApiKeys,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildApiSection({
    required String title,
    required TextEditingController controller,
    required String hint,
    required String description,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
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
        Text(
          l10n.aiModel,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
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
            setState(() {
              _selectedProvider = value;
              if (value == LlmProvider.ollama && _baseUrlController.text.isEmpty) {
                _baseUrlController.text = 'http://localhost:11434';
              }
            });
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
