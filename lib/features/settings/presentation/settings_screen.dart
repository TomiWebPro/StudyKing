import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/services/llm/llm_model_service.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/core/routes/app_router.dart';
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
                  () => Navigator.pushNamed(context, AppRoutes.profile)),
            ]),
            _section(l10n.quickAccess, [
              _tile(l10n.quickGuide, l10n.aiPoweredStudyAssistant, Icons.auto_awesome,
                  () => Navigator.pushNamed(context, AppRoutes.quickGuide)),
            ]),
            _section(l10n.appearance, [
              _tile(l10n.theme, _getThemeLabel(settings.themeModeEnum), Icons.dark_mode,
                  () => _showThemeDialog(settings.themeModeEnum)),
              _tile(l10n.fontSize, _getFontSizeLabel(settings.fontSize), Icons.text_fields,
                  () => _showFontSizeDialog(settings.fontSize)),
            ]),
            _section(l10n.accessibility, [
              SwitchListTile(
                secondary: const Icon(Icons.contrast),
                title: Text(l10n.highContrastMode),
                subtitle: Text(l10n.highContrastDescription),
                value: settings.highContrastEnabled,
                onChanged: (value) =>
                    ref.read(settingsProvider.notifier).updateHighContrast(value),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.touch_app),
                title: Text(l10n.largeTouchTargets),
                subtitle: Text(l10n.largeTouchTargetsDescription),
                value: settings.largeTouchTargets,
                onChanged: (value) =>
                    ref.read(settingsProvider.notifier).updateLargeTouchTargets(value),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.animation),
                title: Text(l10n.reduceMotion),
                subtitle: Text(l10n.reduceMotionDescription),
                value: settings.reduceMotion,
                onChanged: (value) =>
                    ref.read(settingsProvider.notifier).updateReduceMotion(value),
              ),
            ]),
            _section(l10n.aiConfiguration, [
              _tile(l10n.apiKeys, apiKey.isNotEmpty ? l10n.configured : l10n.notConfigured,
                  Icons.key, () => Navigator.pushNamed(context, AppRoutes.apiConfig)),
              _tile(l10n.aiModel, _getAiModelLabel(settings.selectedModel), Icons.chat,
                  () => _showAiModelSelection(settings.selectedModel, apiKey)),
              _tile(l10n.requestTimeout, l10n.secondsValue(settings.requestTimeoutSeconds),
                  Icons.bolt, () => _showTimeoutDialog(settings.requestTimeoutSeconds)),
            ]),
            _section(l10n.notificationPreferences, [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active),
                title: Text(l10n.enableNotifications),
                subtitle: Text(l10n.enableNotificationAlerts),
                value: settings.studyRemindersEnabled,
                onChanged: (value) =>
                    ref.read(settingsProvider.notifier).updateStudyReminders(value),
              ),
              if (settings.studyRemindersEnabled) ...[
                SwitchListTile(
                  secondary: const Icon(Icons.repeat),
                  title: Text(l10n.revisionReminders),
                  value: settings.revisionRemindersEnabled,
                  onChanged: (value) =>
                      ref.read(settingsProvider.notifier).updateRevisionReminders(value),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.school),
                  title: Text(l10n.notifChannelLessons),
                  value: settings.lessonNotificationsEnabled,
                  onChanged: (value) =>
                      ref.read(settingsProvider.notifier).updateLessonNotifications(value),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.warning_amber),
                  title: Text(l10n.overworkAlerts),
                  value: settings.overworkAlertsEnabled,
                  onChanged: (value) =>
                      ref.read(settingsProvider.notifier).updateOverworkAlerts(value),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.tune),
                  title: Text(l10n.planAdjustmentNotifications),
                  value: settings.planAdjustmentNotificationsEnabled,
                  onChanged: (value) =>
                      ref.read(settingsProvider.notifier).updatePlanAdjustmentNotifications(value),
                ),
              ],
            ]),
            _section(l10n.studyPreferences, [
              _tile(l10n.sessionDuration, l10n.minutesValue(settings.sessionDurationMinutes),
                  Icons.timer, () => _showSessionDurationDialog(settings.sessionDurationMinutes)),
            ]),
            _section(l10n.focusMode, [
              _tile(l10n.focusTime, l10n.focusTimerDescription, Icons.timer_outlined,
                  () => Navigator.pushNamed(context, AppRoutes.focusMode)),
              _tile(l10n.dailyStudyCap,
                  _getDailyCapLabel(l10n),
                  Icons.access_time_filled,
                  () => _showDailyCapDialog()),
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
                leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                title: Text(l10n.signOut, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: _showSignOutDialog,
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

  Widget _tile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

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
        ListTile(
          title: Text(l10n.light),
          leading: const Icon(Icons.light_mode),
          selected: currentMode == ThemeMode.light,
          onTap: () {
            ref.read(settingsProvider.notifier).updateTheme(ThemeMode.light);
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: Text(l10n.dark),
          leading: const Icon(Icons.dark_mode),
          selected: currentMode == ThemeMode.dark,
          onTap: () {
            ref.read(settingsProvider.notifier).updateTheme(ThemeMode.dark);
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: Text(l10n.system),
          leading: const Icon(Icons.settings_brightness),
          selected: currentMode == ThemeMode.system,
          onTap: () {
            ref.read(settingsProvider.notifier).updateTheme(ThemeMode.system);
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
                Navigator.pushNamed(context, AppRoutes.apiConfig);
              },
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AiModelLoadingSheet(
        apiKey: apiKey,
        currentModel: currentModel,
        searchController: _modelSearchController,
        onModelSelected: (modelId) {
          ref.read(settingsProvider.notifier).updateModel(modelId);
          ref.read(selectedModelProvider.notifier).state = modelId;
        },
      ),
    );
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

  String _getDailyCapLabel(AppLocalizations l10n) {
    try {
      final box = Hive.box(HiveBoxNames.settings);
      final cap = box.get('dailyCapMinutes', defaultValue: 0) as int;
      return cap > 0 ? l10n.minutesValue(cap) : l10n.noLimit;
    } catch (_) {
      return l10n.noLimit;
    }
  }

  Future<void> _showDailyCapDialog() async {
    try {
      final box = Hive.box(HiveBoxNames.settings);
      final current = box.get('dailyCapMinutes', defaultValue: 0) as int;
      final options = [0, 30, 60, 90, 120, 180, 240];
      final l10n = AppLocalizations.of(context)!;
      showModalBottomSheet(
        context: context,
        builder: (_) => ListView(
          children: options
              .map((m) => ListTile(
                    title: Text(m == 0 ? l10n.noLimit : l10n.minutesValue(m)),
                    trailing: m == current
                        ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () {
                      box.put('dailyCapMinutes', m);
                      (context as Element).markNeedsBuild();
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      );
    } catch (_) {}
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
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
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
        padding: ResponsiveUtils.screenPadding(context),
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

class _AiModelLoadingSheet extends StatefulWidget {
  final String apiKey;
  final String currentModel;
  final TextEditingController searchController;
  final void Function(String modelId) onModelSelected;

  const _AiModelLoadingSheet({
    required this.apiKey,
    required this.currentModel,
    required this.searchController,
    required this.onModelSelected,
  });

  @override
  State<_AiModelLoadingSheet> createState() => _AiModelLoadingSheetState();
}

class _AiModelLoadingSheetState extends State<_AiModelLoadingSheet> {
  List<_ModelItem>? _models;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    try {
      final modelService = ModelListingService(apiKey: widget.apiKey);
      final models = await modelService.fetchAvailableModels().timeout(
        const Duration(seconds: 10),
      );
      if (!mounted) return;
      final items = models.take(100).map((m) => _ModelItem(name: m.name, provider: m.provider, id: m.id)).toList();
      setState(() {
        _models = items;
        _isLoading = false;
      });
    } on TimeoutException {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _error = l10n.modelRequestTimedOut);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _error = l10n.unableToLoadModelsTryAgain);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(48),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 16),
            TextButton(onPressed: _loadModels, child: Text(l10n.retry)),
          ],
        ),
      );
    }

    final filtered = _models!
        .where((m) => m.name.toLowerCase().contains(widget.searchController.text.toLowerCase()))
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: widget.searchController,
            decoration: InputDecoration(
              hintText: l10n.searchModels,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: ListView(
            children: filtered
                .map((m) => ListTile(
                  title: Text(m.name),
                  subtitle: Text(m.provider),
                  trailing: m.id == widget.currentModel
                      ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    widget.onModelSelected(m.id);
                    Navigator.pop(context);
                  },
                ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ModelItem {
  final String name;
  final String provider;
  final String id;

  const _ModelItem({required this.name, required this.provider, required this.id});
}
