import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    if (_apiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.apiKeyCannotBeEmpty),
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
        SnackBar(
          content: Text(l10n.apiKeysSavedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.unableToSaveApiConfig),
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.apiConfiguration)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.configureApiKeys,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              l10n.configureApiKeysDescription,
              style: const TextStyle(fontSize: 14),
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
