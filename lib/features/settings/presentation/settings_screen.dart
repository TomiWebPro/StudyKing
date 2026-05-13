import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/services/llm/llm_model_service.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/providers/app_providers.dart'
    show apiKeyProvider, selectedModelProvider, settingsProvider;

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
      body: FocusTraversalGroup(
        child: ListView(
          padding: ResponsiveUtils.listPadding(context),
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
            _section(l10n.accessibility, [
              Semantics(
                label: l10n.highContrastMode,
                child: SwitchListTile(
                  secondary: const Icon(Icons.contrast),
                  title: Text(l10n.highContrastMode),
                  subtitle: Text(l10n.highContrastDescription),
                  value: settings.highContrastEnabled,
                  onChanged: (value) =>
                      ref.read(settingsProvider.notifier).updateHighContrast(value),
                ),
              ),
              Semantics(
                label: l10n.largeTouchTargets,
                child: SwitchListTile(
                  secondary: const Icon(Icons.touch_app),
                  title: Text(l10n.largeTouchTargets),
                  subtitle: Text(l10n.largeTouchTargetsDescription),
                  value: settings.largeTouchTargets,
                  onChanged: (value) =>
                      ref.read(settingsProvider.notifier).updateLargeTouchTargets(value),
                ),
              ),
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
              Semantics(
                label: l10n.studyReminders,
                child: SwitchListTile(
                  secondary: const Icon(Icons.notifications),
                  title: Text(l10n.studyReminders),
                  subtitle: Text(l10n.enableNotificationAlerts),
                  value: settings.studyRemindersEnabled,
                  onChanged: (value) =>
                      ref.read(settingsProvider.notifier).updateStudyReminders(value),
                ),
              ),
              _tile(l10n.sessionDuration, l10n.minutesValue(settings.sessionDurationMinutes),
                  Icons.timer, () => _showSessionDurationDialog(settings.sessionDurationMinutes)),
            ]),
            _section(l10n.studyAnalytics, [
              _tile(l10n.totalStudySessions, l10n.sessionsCount(settings.totalSessionCount),
                  Icons.show_chart, () => _showAnalytics(settings)),
              Semantics(
                label: l10n.totalStudyTime,
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(l10n.totalStudyTime),
                  subtitle: Text(formatDuration(
                      Duration(milliseconds: settings.totalStudyTimeMs),
                      showDays: true)),
                ),
              ),
            ]),
            _section(l10n.aboutSection, [
              _tile(l10n.aboutStudyKing, l10n.versionInfo, Icons.info,
                  () => _showAboutDialog(context)),
              Semantics(
                label: l10n.signOut,
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(l10n.signOut, style: const TextStyle(color: Colors.red)),
                  onTap: _showSignOutDialog,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: ResponsiveUtils.verticalSpacing(context) * 1.5,
              bottom: ResponsiveUtils.verticalSpacing(context),
            ),
            child: Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
          ),
          ...children,
          const Divider(height: 1),
        ],
      );

  Widget _tile(String title, String subtitle, IconData icon, VoidCallback onTap) =>
      Semantics(
        label: title,
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: onTap,
        ),
      );

  String _getThemeLabel(ThemeMode mode) {
    final l10n = AppLocalizations.of(context)!;
    return mode == ThemeMode.light ? l10n.light : mode == ThemeMode.dark ? l10n.dark : l10n.system;
  }
  String _getFontSizeLabel(double size) {
    final l10n = AppLocalizations.of(context)!;
    return size < 14 ? l10n.small : size < 17 ? l10n.fontSizeMedium : size < 23 ? l10n.large : l10n.extraLarge;
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
        Semantics(
          label: l10n.light,
          selected: currentMode == ThemeMode.light,
          child: ListTile(
            title: Text(l10n.light),
            leading: const Icon(Icons.light_mode),
            selected: currentMode == ThemeMode.light,
            onTap: () {
              ref.read(settingsProvider.notifier).updateTheme(ThemeMode.light);
              Navigator.pop(context);
            },
          ),
        ),
        Semantics(
          label: l10n.dark,
          selected: currentMode == ThemeMode.dark,
          child: ListTile(
            title: Text(l10n.dark),
            leading: const Icon(Icons.dark_mode),
            selected: currentMode == ThemeMode.dark,
            onTap: () {
              ref.read(settingsProvider.notifier).updateTheme(ThemeMode.dark);
              Navigator.pop(context);
            },
          ),
        ),
        Semantics(
          label: l10n.system,
          selected: currentMode == ThemeMode.system,
          child: ListTile(
            title: Text(l10n.system),
            leading: const Icon(Icons.settings_brightness),
            selected: currentMode == ThemeMode.system,
            onTap: () {
              ref.read(settingsProvider.notifier).updateTheme(ThemeMode.system);
              Navigator.pop(context);
            },
          ),
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
        content: FocusTraversalGroup(
          child: StatefulBuilder(builder: (context, setInnerState) {
            double localSize = currentSize;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${localSize.round()}'),
                const SizedBox(height: 8),
                Semantics(
                  label: l10n.fontSize,
                  slider: true,
                  value: localSize.round().toString(),
                  child: Slider(
                    value: localSize,
                    min: 10,
                    max: 30,
                    divisions: 20,
                    onChanged: (value) {
                      final validSize = value.clamp(10.0, 30.0).toDouble();
                      setInnerState(() => localSize = validSize);
                      ref.read(settingsProvider.notifier).updateFontSize(validSize);
                    },
                  ),
                ),
              ],
            );
          }),
        ),
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
      final modelService = ModelListingService(apiKey: apiKey);
      final models = await modelService.fetchAvailableModels();
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);

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
                  .map((m) => Semantics(
                        label: m.name,
                        child: ListTile(
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
                        ),
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
            Semantics(
              label: l10n.requestTimeout,
              slider: true,
              value: selected.round().toString(),
              child: Slider(
                value: selected,
                min: 30,
                max: 300,
                divisions: 27,
                onChanged: (value) => setInnerState(() => selected = value),
              ),
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
            .map((m) => Semantics(
                  label: l10n.minutesValue(m),
                  child: ListTile(
                    title: Text(l10n.minutesValue(m)),
                    trailing: m == currentMinutes
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      ref.read(settingsProvider.notifier).updateSessionDuration(m);
                      Navigator.pop(context);
                    },
                  ),
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
        padding: ResponsiveUtils.screenPadding(context),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Semantics(
            label: l10n.sessionsLabel,
            child: ListTile(title: Text(l10n.sessionsLabel), subtitle: Text('${settings.totalSessionCount}')),
          ),
          Semantics(
            label: l10n.questionsLabel,
            child: ListTile(title: Text(l10n.questionsLabel), subtitle: Text('${settings.totalQuestions}')),
          ),
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

void _showAboutDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (_) => AboutDialog(
      applicationName: l10n.aboutApplicationName,
      applicationVersion: l10n.aboutVersion,
      applicationLegalese: l10n.aboutLegalese,
    ),
  );
}
