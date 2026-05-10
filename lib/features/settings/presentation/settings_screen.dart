import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/main.dart'
    show apiBaseUrlProvider, apiKeyProvider, selectedModelProvider, settingsProvider;

const String _defaultReferer = 'https://studyking.app';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _modelSearchController = TextEditingController();

  @override
  void dispose() {
    _modelSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final apiKey = ref.watch(apiKeyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _section('User Management', [
            _tile('Current User', 'Manage your profile', Icons.account_circle,
                () => Navigator.pushNamed(context, '/profile')),
          ]),
          _section('Appearance', [
            _tile('Theme', _getThemeLabel(settings.themeModeEnum), Icons.dark_mode,
                () => _showThemeDialog(settings.themeModeEnum)),
            _tile('Font Size', _getFontSizeLabel(settings.fontSize), Icons.text_fields,
                () => _showFontSizeDialog(settings.fontSize)),
          ]),
          _section('AI Configuration', [
            _tile('API Keys', apiKey.isNotEmpty ? 'Configured' : 'Not configured',
                Icons.key, () => Navigator.pushNamed(context, '/api-config')),
            _tile('AI Model', _getAiModelLabel(settings.selectedModel), Icons.chat,
                () => _showAiModelSelection(settings.selectedModel, apiKey)),
            _tile('Request Timeout', '${settings.requestTimeoutSeconds} seconds',
                Icons.bolt, () => _showTimeoutDialog(settings.requestTimeoutSeconds)),
          ]),
          _section('Study Preferences', [
            SwitchListTile(
              secondary: const Icon(Icons.notifications),
              title: const Text('Study Reminders'),
              subtitle: const Text('Enable notification alerts'),
              value: settings.studyRemindersEnabled,
              onChanged: (value) =>
                  ref.read(settingsProvider.notifier).updateStudyReminders(value),
            ),
            _tile('Session Duration', '${settings.sessionDurationMinutes} minutes',
                Icons.timer, () => _showSessionDurationDialog(settings.sessionDurationMinutes)),
          ]),
          _section('Study Analytics', [
            _tile('Total Study Sessions', '${settings.totalSessionCount} sessions',
                Icons.show_chart, () => _showAnalytics(settings)),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Total Study Time'),
              subtitle: Text(formatDuration(
                  Duration(milliseconds: settings.totalStudyTimeMs),
                  showDays: true)),
            ),
          ]),
          _section('About', [
            _tile('About StudyKing', 'Version 0.1.0', Icons.info,
                () => _showAboutDialog(context)),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: _showSignOutDialog,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ...children,
          const Divider(height: 1),
        ],
      );

  Widget _tile(String title, String subtitle, IconData icon, VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      );

  String _getThemeLabel(ThemeMode mode) =>
      mode == ThemeMode.light ? 'Light' : mode == ThemeMode.dark ? 'Dark' : 'System';
  String _getFontSizeLabel(double size) =>
      size < 14 ? 'Small' : size < 17 ? 'Medium' : size < 23 ? 'Large' : 'Extra Large';
  String _getAiModelLabel(String model) {
    if (model.isEmpty) return 'Select a model from API';
    final parts = model.split('/');
    if (parts.length < 2) return model;
    final name = parts.last.replaceAll('-', ' ').replaceAll('_', ' ').trim();
    if (name.isEmpty) return model;
    return name[0].toUpperCase() + name.substring(1);
  }

  void _showThemeDialog(ThemeMode currentMode) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          title: const Text('Light'),
          selected: currentMode == ThemeMode.light,
          onTap: () {
            ref.read(settingsProvider.notifier).updateTheme(ThemeMode.light);
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: const Text('Dark'),
          selected: currentMode == ThemeMode.dark,
          onTap: () {
            ref.read(settingsProvider.notifier).updateTheme(ThemeMode.dark);
            Navigator.pop(context);
          },
        ),
      ]),
    );
  }

  void _showFontSizeDialog(double currentSize) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Font Size'),
        content: StatefulBuilder(builder: (context, setInnerState) {
          double localSize = currentSize;
          return Slider(
            value: localSize,
            min: 10,
            max: 30,
            divisions: 20,
            onChanged: (value) {
              final validSize = value.clamp(10.0, 30.0).toDouble();
              setInnerState(() => localSize = validSize);
              ref.read(settingsProvider.notifier).updateFontSize(validSize);
            },
          );
        }),
      ),
    );
  }

  Future<void> _showAiModelSelection(String currentModel, String apiKey) async {
    if (apiKey.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('API Key Required'),
          content: const Text('Please configure your API key first.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/api-config');
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http
          .get(
            Uri.parse('${ref.read(apiBaseUrlProvider)}/models'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'HTTP-Referer': _defaultReferer,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);

      if (response.statusCode != 200) {
        _showError('Unable to load models right now.');
        return;
      }

      final models = _parseModels(response.body);
      final filtered = models.take(100).toList();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _modelSearchController,
              decoration: const InputDecoration(
                  hintText: 'Search models', prefixIcon: Icon(Icons.search)),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: ListView(
              children: filtered
                  .where((m) => m.name
                      .toLowerCase()
                      .contains(_modelSearchController.text.toLowerCase()))
                  .map((m) => ListTile(
                        title: Text(m.name),
                        subtitle: Text(m.provider),
                        trailing: m.id == currentModel
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                        onTap: () {
                          ref.read(settingsProvider.notifier).updateModel(m.id);
                          ref.read(selectedModelProvider.notifier).state = m.id;
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
          ),
        ]),
      );
    } on TimeoutException {
      if (Navigator.canPop(context)) Navigator.pop(context);
      _showError('Model request timed out. Please try again.');
    } catch (_) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      _showError('Unable to load models. Please try again.');
    }
  }

  List<_AiModel> _parseModels(String responseBody) {
    final decoded = json.decode(responseBody);
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (data is! List) return [];
    return data.whereType<Map>().map((raw) {
      final map = raw.cast<dynamic, dynamic>();
      final id = map['id'] is String ? map['id'] as String : 'unknown-model';
      final name = map['name'] is String
          ? map['name'] as String
          : id.split('/').last.replaceAll('-', ' ');
      String provider = 'Unknown';
      final providers = map['providers'];
      if (providers is Map && providers.isNotEmpty) {
        final first = providers.values.first;
        if (first is Map && first['id'] is String) {
          provider = first['id'] as String;
        }
      }
      return _AiModel(id: id, name: name, provider: provider);
    }).toList();
  }

  void _showTimeoutDialog(int currentTimeout) {
    double selected = currentTimeout.toDouble();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInnerState) => AlertDialog(
          title: const Text('Request Timeout'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${selected.round()} seconds'),
            Slider(
              value: selected,
              min: 30,
              max: 300,
              divisions: 27,
              onChanged: (value) => setInnerState(() => selected = value),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                ref
                    .read(settingsProvider.notifier)
                    .updateRequestTimeout(selected.round());
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSessionDurationDialog(int currentMinutes) {
    final options = [15, 30, 45, 60, 90];
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: options
            .map((m) => ListTile(
                  title: Text('$m minutes'),
                  trailing: m == currentMinutes
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).updateSessionDuration(m);
                    Navigator.pop(context);
                  },
                ))
            .toList(),
      ),
    );
  }

  void _showAnalytics(SettingsBox settings) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: const Text('Sessions'), subtitle: Text('${settings.totalSessionCount}')),
          ListTile(title: const Text('Questions'), subtitle: Text('${settings.totalQuestions}')),
        ]),
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ref.read(apiKeyProvider.notifier).state = '';
              ref.read(selectedModelProvider.notifier).state = '';
              ref.read(settingsProvider.notifier).updateSettings(apiKey: '', selectedModel: '');
              Navigator.pop(context);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AiModel {
  final String id;
  final String name;
  final String provider;

  const _AiModel({required this.id, required this.name, required this.provider});
}

void _showAboutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => const AboutDialog(
      applicationName: 'StudyKing',
      applicationVersion: 'v0.1.0',
      applicationLegalese: '© 2026 StudyKing.',
    ),
  );
}
