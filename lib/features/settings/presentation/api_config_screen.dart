import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/main.dart'
    show apiBaseUrlProvider, apiKeyProvider, settingsProvider;

class ApiConfigScreen extends ConsumerStatefulWidget {
  const ApiConfigScreen({super.key});

  @override
  ConsumerState<ApiConfigScreen> createState() => _ApiConfigScreenState();
}

class _ApiConfigScreenState extends ConsumerState<ApiConfigScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController();

  bool _isSaving = false;
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
    });
  }

  Future<void> _saveKeys() async {
    if (_apiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API key cannot be empty'),
          backgroundColor: Colors.red,
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
      await ref
          .read(settingsProvider.notifier)
          .updateSettings(apiKey: apiKey, apiBaseUrl: baseUrl);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API keys saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save API configuration. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Configuration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configure API Keys',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Enter your OpenRouter API credentials below. These are used to power the AI features.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildApiSection(
              title: 'OpenRouter API Key',
              controller: _apiKeyController,
              hint: 'sk-or-v1-...',
              description:
                  'Required for LLM content generation. Get your key from https://openrouter.ai/keys',
              obscureText: _obscureApiKey,
            ),
            const SizedBox(height: 24),
            _buildApiSection(
              title: 'API Base URL',
              controller: _baseUrlController,
              hint: 'https://openrouter.ai/api/v1',
              description: 'The endpoint URL for the AI service',
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
                label: const Text('Save API Keys'),
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}
