import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final apiKey = ref.watch(apiKeyProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _section(l10n.userManagement, [
            _tile(l10n.currentUser, l10n.manageYourProfile, Icons.account_circle,
                () => Navigator.pushNamed(context, '/profile')),
          ]),
          _section(l10n.quickAccess, [
            _tile(l10n.quickGuide, l10n.aiPoweredStudyAssistant, Icons.auto_awesome,
                () => Navigator.pushNamed(context, '/quick-guide')),
          ]),
          _section(l10n.appearance, [
            _tile(l10n.theme, _getThemeLabel(settings.themeModeEnum), Icons.dark_mode,
                () => _showThemeDialog(settings.themeModeEnum)),
            _tile(l10n.fontSize, _getFontSizeLabel(settings.fontSize), Icons.text_fields,
                () => _showFontSizeDialog(settings.fontSize)),
          ]),
          _section(l10n.aiConfiguration, [
            _tile(l10n.apiKeys, apiKey.isNotEmpty ? l10n.configured : l10n.notConfigured,
                Icons.key, () => Navigator.pushNamed(context, '/api-config')),
            _tile(l10n.aiModel, _getAiModelLabel(settings.selectedModel), Icons.chat,
                () => _showAiModelSelection(settings.selectedModel, apiKey)),
            _tile(l10n.requestTimeout, l10n.secondsValue(settings.requestTimeoutSeconds),
                Icons.bolt, () => _showTimeoutDialog(settings.requestTimeoutSeconds)),
          ]),
          _section(l10n.studyPreferences, [
            SwitchListTile(
              secondary: const Icon(Icons.notifications),
              title: Text(l10n.studyReminders),
              subtitle: Text(l10n.enableNotificationAlerts),
              value: settings.studyRemindersEnabled,
              onChanged: (value) =>
                  ref.read(settingsProvider.notifier).updateStudyReminders(value),
            ),
            _tile(l10n.sessionDuration, l10n.minutesValue(settings.sessionDurationMinutes),
                Icons.timer, () => _showSessionDurationDialog(settings.sessionDurationMinutes)),
          ]),
          _section(l10n.studyAnalytics, [
            _tile(l10n.totalStudySessions, l10n.sessionsCount(settings.totalSessionCount),
                Icons.show_chart, () => _showAnalytics(settings)),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(l10n.totalStudyTime),
              subtitle: Text(formatDuration(
                  Duration(milliseconds: settings.totalStudyTimeMs),
                  showDays: true)),
            ),
          ]),
          _section(l10n.aboutSection, [
            _tile(l10n.aboutStudyKing, l10n.versionInfo, Icons.info,
                () => _showAboutDialog(context)),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(l10n.signOut, style: const TextStyle(color: Colors.red)),
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

  String _getThemeLabel(ThemeMode mode) {
    final l10n = AppLocalizations.of(context)!;
    return mode == ThemeMode.light ? l10n.light : mode == ThemeMode.dark ? l10n.dark : l10n.system;
  }
  String _getFontSizeLabel(double size) {
    final l10n = AppLocalizations.of(context)!;
    return size < 14 ? l10n.small : size < 17 ? l10n.medium : size < 23 ? l10n.large : l10n.extraLarge;
  }
  String _getAiModelLabel(String model) {
    final l10n = AppLocalizations.of(context)!;
    if (model.isEmpty) return l10n.selectModelFromApi;
    final parts = model.split('/');
    if (parts.length < 2) return model;
    final name = parts.last.replaceAll('-', ' ').replaceAll('_', ' ').trim();
    if (name.isEmpty) return model;
    return name[0].toUpperCase() + name.substring(1);
  }

  void _showThemeDialog(ThemeMode currentMode) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          title: Text(l10n.light),
          selected: currentMode == ThemeMode.light,
          onTap: () {
            ref.read(settingsProvider.notifier).updateTheme(ThemeMode.light);
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: Text(l10n.dark),
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.fontSize),
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
    final l10n = AppLocalizations.of(context)!;
    if (apiKey.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(l10n.apiKeyRequired),
          content: Text(l10n.pleaseConfigureApiKey),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/api-config');
              },
              child: Text(l10n.ok),
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
        _showError(l10n.unableToLoadModels);
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
              decoration: InputDecoration(
                  hintText: l10n.searchModels, prefixIcon: const Icon(Icons.search)),
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
      _showError(l10n.modelRequestTimedOut);
    } catch (_) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      _showError(l10n.unableToLoadModelsTryAgain);
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
    final l10n = AppLocalizations.of(context)!;
    double selected = currentTimeout.toDouble();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInnerState) => AlertDialog(
          title: Text(l10n.requestTimeout),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(l10n.secondsValue(selected.round())),
            Slider(
              value: selected,
              min: 30,
              max: 300,
              divisions: 27,
              onChanged: (value) => setInnerState(() => selected = value),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () {
                ref
                    .read(settingsProvider.notifier)
                    .updateRequestTimeout(selected.round());
                Navigator.pop(ctx);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showSessionDurationDialog(int currentMinutes) {
    final l10n = AppLocalizations.of(context)!;
    final options = [15, 30, 45, 60, 90];
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: options
            .map((m) => ListTile(
                  title: Text(l10n.minutesValue(m)),
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
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: Text(l10n.sessionsLabel), subtitle: Text('${settings.totalSessionCount}')),
          ListTile(title: Text(l10n.questionsLabel), subtitle: Text('${settings.totalQuestions}')),
        ]),
      ),
    );
  }

  void _showSignOutDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.signOutConfirmation),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              ref.read(apiKeyProvider.notifier).state = '';
              ref.read(selectedModelProvider.notifier).state = '';
              ref.read(settingsProvider.notifier).updateSettings(apiKey: '', selectedModel: '');
              Navigator.pop(context);
            },
            child: Text(l10n.signOut),
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
