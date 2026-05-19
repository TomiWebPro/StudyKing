import 'dart:async';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm/llm_model_service.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/services/notification_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/dashboard/data/models/badge_model.dart';
import 'package:studyking/features/focus_mode/data/focus_session_model.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/data/models/student_availability_model.dart';
import 'package:studyking/features/planner/data/models/task_model.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/questions/data/models/question_evaluation_model.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/settings_update.dart';
import 'package:studyking/features/settings/data/models/user_profile_model.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/providers/app_providers.dart'
    show apiBaseUrlProvider, apiKeyProvider, llmProviderProvider, selectedModelProvider, settingsProvider, engagementSchedulerProvider;
import 'package:studyking/core/providers/llm_providers.dart' show llmTaskManagerProvider, llmUsageMeterProvider;
import 'package:studyking/features/settings/providers/settings_providers.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:studyking/core/widgets/loading_indicator.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _modelSearchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _modelSearchController.dispose();
    super.dispose();
  }

  Future<void> _performAutoBackup() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      var boxData = _collectAllBoxData();
      // Exclude sensitive data from auto-backup
      boxData.remove(HiveBoxNames.settings);
      final backupService = ref.read(dataBackupServiceProvider);
      final result = await backupService.exportAllData(
        boxData: boxData,
        outputDir: 'persistent',
      );
      if (result.isSuccess) {
        if (!mounted) return;
        final box = Hive.box(HiveBoxNames.settings);
        final filePath = result.data!;
        box.put('lastAutoBackupDate', DateTime.now().toIso8601String());
        box.put('lastAutoBackupPath', filePath);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.backupCompleted),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => Share.shareXFiles(
                [XFile(filePath)],
                text: 'StudyKing Backup — ${DateTime.now().toIso8601String().substring(0, 10)}',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      const Logger('SettingsScreen').e('Auto-backup failed', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final settings = ref.watch(settingsProvider);
      final apiKey = ref.watch(apiKeyProvider);
      final llmProvider = ref.watch(llmProviderProvider);
      final apiBaseUrl = ref.watch(apiBaseUrlProvider);
      return _buildSettingsBody(context, l10n, settings, apiKey, llmProvider, apiBaseUrl);
    } catch (e) {
      return _buildSettingsError(context, l10n, e);
    }
  }

  Widget _buildSettingsBody(BuildContext context, AppLocalizations l10n, SettingsBox settings, String apiKey, LlmProvider llmProvider, String apiBaseUrl) {
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
            _section(l10n.contentManagement, [
              _tile(l10n.uploadMaterial, l10n.uploadMaterialDesc, Icons.cloud_upload,
                  () => Navigator.pushNamed(context, AppRoutes.upload)),
              _tile(l10n.myUploads, l10n.viewMyUploads, Icons.source,
                  () => Navigator.pushNamed(context, AppRoutes.contentLibrary)),
              _tile(l10n.questionBank, l10n.browseAndManageQuestions, Icons.quiz,
                  () => Navigator.pushNamed(context, AppRoutes.questionBank)),
              _FailedUploadsTile(),
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
                    ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(highContrastEnabled: value)),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.touch_app),
                title: Text(l10n.largeTouchTargets),
                subtitle: Text(l10n.largeTouchTargetsDescription),
                value: settings.largeTouchTargets,
                onChanged: (value) =>
                    ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(largeTouchTargets: value)),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.animation),
                title: Text(l10n.reduceMotion),
                subtitle: Text(l10n.reduceMotionDescription),
                value: settings.reduceMotion,
                onChanged: (value) =>
                    ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(reduceMotion: value)),
              ),
            ]),
            _section(l10n.aiConfiguration, [
              _tile(l10n.apiKeys, apiKey.isNotEmpty ? l10n.configured : l10n.notConfigured,
                  Icons.key, () => Navigator.pushNamed(context, AppRoutes.apiConfig)),
              _tile(l10n.aiModel, _getAiModelLabel(settings.selectedModel), Icons.chat,
                  () => _showAiModelSelection(settings.selectedModel, apiKey, llmProvider, apiBaseUrl)),
              _tile(l10n.requestTimeout, l10n.secondsValue(settings.requestTimeoutSeconds),
                  Icons.bolt, () => _showTimeoutDialog(settings.requestTimeoutSeconds)),
              _AiTaskMonitorTile(),
            ]),
            _section(l10n.notificationPreferences, [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active),
                title: Text(l10n.enableNotifications),
                subtitle: Text(l10n.enableNotificationAlerts),
                value: settings.studyRemindersEnabled,
                onChanged: (value) =>
                    ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(studyRemindersEnabled: value)),
              ),
              if (settings.studyRemindersEnabled) ...[
                SwitchListTile(
                  secondary: const Icon(Icons.alarm),
                  title: Text(l10n.dailyReminders),
                  subtitle: Text(l10n.dailyReminderDescription),
                  value: settings.dailyReminderEnabled,
                  onChanged: (value) =>
                      ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(dailyReminderEnabled: value)),
                ),
                if (settings.dailyReminderEnabled)
                  _tile(
                    l10n.reminderTime,
                    DateFormat.jm(l10n.localeName).format(
                      DateTime(0, 0, 0, settings.dailyReminderHour, settings.dailyReminderMinute),
                    ),
                    Icons.access_time,
                    () => _showDailyReminderTimePicker(settings),
                  ),
                SwitchListTile(
                  secondary: const Icon(Icons.repeat),
                  title: Text(l10n.revisionReminders),
                  value: settings.revisionRemindersEnabled,
                  onChanged: (value) =>
                      ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(revisionRemindersEnabled: value)),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.school),
                  title: Text(l10n.notifChannelLessons),
                  value: settings.lessonNotificationsEnabled,
                  onChanged: (value) =>
                      ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(lessonNotificationsEnabled: value)),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.warning_amber),
                  title: Text(l10n.overworkAlerts),
                  value: settings.overworkAlertsEnabled,
                  onChanged: (value) =>
                      ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(overworkAlertsEnabled: value)),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.tune),
                  title: Text(l10n.planAdjustmentNotifications),
                  value: settings.planAdjustmentNotificationsEnabled,
                  onChanged: (value) =>
                      ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(planAdjustmentNotificationsEnabled: value)),
                ),
              ],
              ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(l10n.checkNudgesNow),
                subtitle: Text(l10n.runNudgeChecks),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  final scheduler = ref.read(engagementSchedulerProvider);
                  try {
                    await scheduler.runDailyChecksNow();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.nudgeCheckComplete)),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.nudgeCheckFailed)),
                      );
                    }
                  }
                },
              ),
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
              _tile(l10n.breakDuration,
                  l10n.minutesValue(settings.breakDurationSeconds ~/ 60),
                  Icons.free_breakfast,
                  () => _showBreakDurationDialog(settings.breakDurationSeconds)),
            ]),
            _section(l10n.sessionTracking, [
              _tile(l10n.manualSessionTracker, l10n.manualSessionTrackerDescription, Icons.timer,
                  () => Navigator.pushNamed(context, AppRoutes.sessionTracker)),
              _tile(l10n.sessionHistory, l10n.sessionHistoryDescription, Icons.history,
                  () => Navigator.pushNamed(context, AppRoutes.sessionHistory)),
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
            _section(l10n.tokenUsageSummary, [
              _tile(l10n.totalTokens,
                  l10n.tokensLabel(formatDecimal(ref.watch(llmUsageMeterProvider).getTotalTokens().toDouble(), l10n.localeName, minFractionDigits: 0)),
                  Icons.token, () => _showTokenUsageDetails()),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: Text(l10n.totalCost),
                subtitle: Text(formatCurrency(ref.watch(llmUsageMeterProvider).getTotalCost(), l10n.localeName)),
              ),
            ]),
            _section(l10n.backupAndRestore, [
              _tile(l10n.exportBackup, l10n.exportAllDataDescription,
                  Icons.backup, _exportBackup),
              _tile(l10n.importBackup, l10n.importFromFileDescription,
                  Icons.restore_page, _importBackup),
              _tile(l10n.autoBackup, l10n.autoBackupDescription,
                  Icons.schedule, () => _showAutoBackupDialog()),
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

  Widget _buildSettingsError(BuildContext context, AppLocalizations l10n, Object e) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(l10n.somethingWentWrong, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                l10n.errorOccurred,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.invalidate(settingsProvider),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
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
            ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(themeMode: ThemeMode.light));
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: Text(l10n.dark),
          leading: const Icon(Icons.dark_mode),
          selected: currentMode == ThemeMode.dark,
          onTap: () {
            ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(themeMode: ThemeMode.dark));
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: Text(l10n.system),
          leading: const Icon(Icons.settings_brightness),
          selected: currentMode == ThemeMode.system,
          onTap: () {
            ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(themeMode: ThemeMode.system));
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
                Text(formatDecimal(localSize.round().toDouble(), l10n.localeName, minFractionDigits: 0)),
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
                      ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(fontSize: validSize));
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

  Future<void> _showAiModelSelection(String currentModel, String apiKey, LlmProvider llmProvider, String apiBaseUrl) async {
    final l10n = AppLocalizations.of(context)!;
    if (apiKey.isEmpty && llmProvider != LlmProvider.ollama) {
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
        llmProvider: llmProvider,
        apiBaseUrl: apiBaseUrl,
        onModelSelected: (modelId) {
          ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(selectedModel: modelId));
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
                    .updateSettings(SettingsUpdate(requestTimeoutSeconds: selected.round()));
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
    } catch (e) {
      const Logger('SettingsScreen').e('Failed to get daily cap label', e);
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
    } catch (e) {
      const Logger('SettingsScreen').e('Failed to show daily cap dialog: $e');
    }
  }

  void _showAutoBackupDialog() {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      {'label': l10n.backupIntervalNever, 'value': 0},
      {'label': l10n.backupIntervalDaily, 'value': 1},
      {'label': l10n.backupIntervalWeekly, 'value': 7},
    ];

    try {
      final box = Hive.box(HiveBoxNames.settings);
      final current = box.get('autoBackupIntervalDays', defaultValue: 0) as int;
      final lastBackupStr = box.get('lastAutoBackupDate', defaultValue: '') as String;
      final lastBackupPath = box.get('lastAutoBackupPath', defaultValue: '') as String;

      showModalBottomSheet(
        context: context,
        builder: (ctx) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _performAutoBackup();
                },
                icon: const Icon(Icons.backup, size: 18),
                label: const Text('Back Up Now'),
              ),
            ),
            const Divider(),
            if (lastBackupStr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  '${l10n.lastBackup}: ${DateFormat.yMd(l10n.localeName).format(DateTime.parse(lastBackupStr))}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (lastBackupPath.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Share.shareXFiles([XFile(lastBackupPath)],
                      text: 'StudyKing Backup — ${lastBackupStr.substring(0, 10)}',
                    );
                  },
                  icon: const Icon(Icons.share, size: 16),
                  label: Text('Share last backup', style: Theme.of(context).textTheme.bodySmall),
                ),
              ),
            ...options.map((opt) {
              final days = opt['value'] as int;
              return ListTile(
                title: Text(opt['label'] as String),
                trailing: current == days
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  box.put('autoBackupIntervalDays', days);
                  if (days > 0) {
                    box.put('lastAutoBackupDate', DateTime.now().toIso8601String());
                  }
                  (context as Element).markNeedsBuild();
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      );
    } catch (e) {
      const Logger('SettingsScreen').e('Failed to show auto backup dialog: $e');
    }
  }

  Future<void> _showDailyReminderTimePicker(SettingsBox settings) async {
    final l10n = AppLocalizations.of(context)!;
    final initial = TimeOfDay(hour: settings.dailyReminderHour, minute: settings.dailyReminderMinute);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: l10n.dailyReminderTimeHelp,
    );
    if (picked != null) {
      await ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(dailyReminderHour: picked.hour, dailyReminderMinute: picked.minute));
      final notifService = NotificationService();
      await notifService.init();
      await notifService.showDailyReminder(
        id: 9999,
        title: l10n.dailyReminderNotificationTitle,
        body: l10n.dailyReminderNotificationBody,
        remindAt: picked,
      );
    }
  }

  void _showBreakDurationDialog(int currentSeconds) {
    final l10n = AppLocalizations.of(context)!;
    final options = [60, 120, 180, 300, 420, 600, 900];
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: options
            .map((s) => ListTile(
                  title: Text(l10n.minutesValue(s ~/ 60)),
                  trailing: s == currentSeconds
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(breakDurationSeconds: s));
                    Navigator.pop(context);
                  },
                ))
            .toList(),
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
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(sessionDurationMinutes: m));
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
          ListTile(title: Text(l10n.sessionsLabel), subtitle: Text(formatCompactNumber(settings.totalSessionCount, l10n.localeName))),
          ListTile(title: Text(l10n.questionsLabel), subtitle: Text(formatCompactNumber(settings.totalQuestions, l10n.localeName))),
        ]),
      ),
    );
  }

  Future<void> _exportBackup() async {
    final l10n = AppLocalizations.of(context)!;

    if (!mounted) return;
    final includeSensitive = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.exportBackup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.backupContainsSensitiveData),
            const SizedBox(height: 8),
            Text(
              l10n.sensitiveDataWillBeExcluded,
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, size: 20, color: Theme.of(ctx).colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.sensitiveDataWillBeExcluded,
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: Theme.of(ctx).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your API keys will be readable as plaintext in the backup file. '
                    'Anyone with access to this file can use your API keys.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.excludeSensitiveData),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.exportBackup),
          ),
        ],
      ),
    );

    // null = cancelled, false = full export, true = exclude sensitive
    if (includeSensitive == null || !mounted) return;

    var boxData = _collectAllBoxData();

    // If user chose to exclude sensitive data
    if (includeSensitive == true) {
      // Remove settings box from backup (it contains API key)
      boxData.remove(HiveBoxNames.settings);
    } else {
      // Full export warning for sensitive data
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.exportBackup),
          content: Text(l10n.backupContainsSensitiveData),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.exportBackup),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
      // Re-collect to ensure fresh data after dialog
      boxData = _collectAllBoxData();
    }

    final backupService = ref.read(dataBackupServiceProvider);
    try {
      // Compute backup summary
      int totalRecords = 0;
      for (final records in boxData.values) {
        totalRecords += records.length;
      }
      final boxCount = boxData.length;

      // Show backup summary dialog (M4)
      final boxSummaries = boxData.entries
          .where((e) => e.value.isNotEmpty)
          .map((e) => '${_boxDisplayName(e.key)}: ${l10n.recordCount(e.value.length)}')
          .toList()
        ..sort();
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.exportBackup),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.recordCount(totalRecords)),
              const SizedBox(height: 8),
              Text(
                '$boxCount boxes',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              if (includeSensitive == false) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, size: 16, color: Theme.of(ctx).colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your API keys will be stored in plaintext. Anyone with this file can use your API keys.',
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: Theme.of(ctx).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (boxSummaries.length <= 20)
                ...boxSummaries.take(20).map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Text(s, style: Theme.of(ctx).textTheme.bodySmall),
                ))
              else ...[
                ...boxSummaries.take(19).map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Text(s, style: Theme.of(ctx).textTheme.bodySmall),
                )),
                Text(
                  '... and ${boxSummaries.length - 19} more',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.exportBackup),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;

      final result = await backupService.exportAllData(boxData: boxData);
      if (result.isSuccess) {
        final filePath = result.data!;
        late String sizeStr;
        if (kIsWeb) {
          sizeStr = '0 B';
        } else {
          final fileSize = await File(filePath).length();
          sizeStr = fileSize > 1048576
              ? '${(fileSize / 1048576).toStringAsFixed(1)} MB'
              : fileSize > 1024
                  ? '${(fileSize / 1024).toStringAsFixed(0)} KB'
                  : '$fileSize B';
        }
        final shareText = l10n.exportBackup;
        await Share.shareXFiles(
          [XFile(filePath)],
          text: '$shareText — ${DateTime.now().toIso8601String().substring(0, 10)}'
              ' — ${l10n.recordCount(totalRecords)}, $sizeStr',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.backupExported)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(l10n.backupExportFailedWithError(result.error!))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.backupExportFailedWithError(e.toString()))),
        );
      }
    }
  }

  String _boxDisplayName(String boxName) {
    final l10n = AppLocalizations.of(context)!;
    switch (boxName) {
      case HiveBoxNames.subjects: return l10n.backupBoxSubjects;
      case HiveBoxNames.topics: return l10n.backupBoxTopics;
      case HiveBoxNames.questions: return l10n.backupBoxQuestions;
      case HiveBoxNames.sources: return l10n.backupBoxSources;
      case HiveBoxNames.lessons: return l10n.backupBoxLessons;
      case HiveBoxNames.lessonBlocks: return l10n.backupBoxLessonBlocks;
      case HiveBoxNames.sessionsTyped: return l10n.backupBoxSessionsTyped;
      case HiveBoxNames.sessions: return l10n.backupBoxSessions;
      case HiveBoxNames.masteryStates: return l10n.backupBoxMasteryStates;
      case HiveBoxNames.questionMasteryStates: return l10n.backupBoxQuestionMasteryStates;
      case HiveBoxNames.questionEvaluations: return l10n.backupBoxQuestionEvaluations;
      case HiveBoxNames.learningPlans: return l10n.backupBoxLearningPlans;
      case HiveBoxNames.planAdherence: return l10n.backupBoxPlanAdherence;
      case HiveBoxNames.planAdherenceMetrics: return l10n.backupBoxPlanAdherenceMetrics;
      case HiveBoxNames.masteryImprovementMetrics: return l10n.backupBoxMasteryImprovementMetrics;
      case HiveBoxNames.conversations: return l10n.backupBoxConversations;
      case HiveBoxNames.tutorSessions: return l10n.backupBoxTutorSessions;
      case HiveBoxNames.topicDependencies: return l10n.backupBoxTopicDependencies;
      case HiveBoxNames.settings: return l10n.backupBoxSettings;
      case HiveBoxNames.profile: return l10n.backupBoxProfile;
      case HiveBoxNames.answers: return 'Answers';
      case HiveBoxNames.attempts: return 'Attempts';
      case HiveBoxNames.badges: return 'Badges';
      case HiveBoxNames.engagementNudges: return 'Engagement Nudges';
      case HiveBoxNames.focusSessions: return 'Focus Sessions';
      case HiveBoxNames.pendingActions: return 'Pending Actions';
      case HiveBoxNames.progress: return 'Progress';
      case HiveBoxNames.tasks: return 'Tasks';
      case HiveBoxNames.studentAvailability: return 'Student Availability';
      case HiveBoxNames.roadmaps: return 'Roadmaps';
      case HiveBoxNames.llmTasks: return 'LLM Tasks';
      case HiveBoxNames.llmUsageRecords: return 'LLM Usage Records';
      default: return boxName;
    }
  }

  Future<void> _importBackup() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final pickResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: l10n.selectBackupFile,
      );
      if (pickResult == null || pickResult.files.isEmpty) return;
      final filePath = pickResult.files.single.path;
      if (filePath == null) return;

      final backupService = ref.read(dataBackupServiceProvider);
      final result = await backupService.restoreData(filePath);
      if (result.isFailure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.invalidBackupFileWithError(result.error!))),
          );
        }
        return;
      }

      final data = result.data!;
      if (!mounted) return;

      // Show selective restore dialog
      final selectedBoxes = await _showSelectiveRestoreDialog(l10n, data);
      if (selectedBoxes == null || selectedBoxes.isEmpty || !mounted) return;

      // Filter data to only selected boxes
      final filteredData = <String, List<Map<String, dynamic>>>{};
      for (final box in selectedBoxes) {
        if (data.containsKey(box)) {
          filteredData[box] = data[box]!;
        }
      }

      if (filteredData.isEmpty) return;

      if (!mounted) return;
      final restoreMethod = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.importConfirmTitle),
          content: Text(l10n.selectedBoxesWillBeOverwritten),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'merge'),
              child: Text(l10n.mergeRestore),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'overwrite'),
              child: Text(l10n.overwriteRestore),
            ),
          ],
        ),
      );

      if (restoreMethod == null || !mounted) return;

      // Check for studentId mismatch (M2)
      String? backupStudentId;
      for (final records in filteredData.values) {
        for (final record in records) {
          if (record.containsKey('studentId') && record['studentId'] is String) {
            backupStudentId = record['studentId'] as String;
            break;
          }
        }
        if (backupStudentId != null) break;
      }
      final currentStudentId = StudentIdService().getStudentId();
      final idMismatch = backupStudentId != null && backupStudentId != currentStudentId;

      if (idMismatch) {
        final reconcileStudentId = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.importConfirmTitle),
            content: Text(
              '${l10n.importPreview(1, 1)}\n\n'
              'Student ID mismatch detected. '
              'Current: $currentStudentId\n'
              'Backup: $backupStudentId\n\n'
              'Update student records to match current ID?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.importBackup),
              ),
            ],
          ),
        );
        if (reconcileStudentId != true || !mounted) return;

        // Rewrite all studentId fields to current ID
        for (final records in filteredData.values) {
          for (final record in records) {
            if (record.containsKey('studentId') && record['studentId'] is String) {
              record['studentId'] = currentStudentId;
            }
          }
        }
      }

      if (restoreMethod == 'merge') {
        await _writeBoxDataMerge(filteredData);
      } else {
        await _writeBoxData(filteredData);
      }
      if (mounted) {
        // Invalidate key providers to refresh UI after restore (M3)
        ref.invalidate(settingsProvider);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.importSuccess),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.importPreview(1, 1)),
                const SizedBox(height: 12),
                Text(
                  'Data restored successfully. A restart may be needed for all changes to appear.',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(l10n.close),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.importFailedWithError(e.toString()))),
        );
      }
    }
  }

  Future<Set<String>?> _showSelectiveRestoreDialog(
      AppLocalizations l10n, Map<String, List<Map<String, dynamic>>> data) async {
    final allKeys = data.keys.toList();
    final selected = Set<String>.from(allKeys);

    return showDialog<Set<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInnerState) => AlertDialog(
          title: Text(l10n.selectBoxesToRestore),
          content: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setInnerState(() => selected.addAll(allKeys)),
                      child: Text(l10n.selectAll),
                    ),
                    TextButton(
                      onPressed: () => setInnerState(() => selected.clear()),
                      child: Text(l10n.deselectAll),
                    ),
                  ],
                ),
                const Divider(),
                ...allKeys.map((key) {
                  final records = data[key]!;
                  return CheckboxListTile(
                    title: Text(_boxDisplayName(key)),
                    subtitle: Text(l10n.recordCount(records.length)),
                    value: selected.contains(key),
                    onChanged: (v) {
                      setInnerState(() {
                        if (v == true) {
                          selected.add(key);
                        } else {
                          selected.remove(key);
                        }
                      });
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: selected.isNotEmpty ? () => Navigator.pop(ctx, selected) : null,
              child: Text(l10n.importBackup),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _collectAllBoxData() {
    final data = <String, List<Map<String, dynamic>>>{};
    final boxNames = [
      HiveBoxNames.subjects,
      HiveBoxNames.topics,
      HiveBoxNames.questions,
      HiveBoxNames.answers,
      HiveBoxNames.sources,
      HiveBoxNames.attempts,
      HiveBoxNames.lessons,
      HiveBoxNames.lessonBlocks,
      HiveBoxNames.sessions,
      HiveBoxNames.sessionsTyped,
      HiveBoxNames.progress,
      HiveBoxNames.tasks,
      HiveBoxNames.conversations,
      HiveBoxNames.tutorSessions,
      HiveBoxNames.masteryStates,
      HiveBoxNames.questionMasteryStates,
      HiveBoxNames.questionEvaluations,
      HiveBoxNames.learningPlans,
      HiveBoxNames.planAdherence,
      HiveBoxNames.planAdherenceMetrics,
      HiveBoxNames.masteryImprovementMetrics,
      HiveBoxNames.roadmaps,
      HiveBoxNames.pendingActions,
      HiveBoxNames.engagementNudges,
      HiveBoxNames.badges,
      HiveBoxNames.focusSessions,
      HiveBoxNames.studentAvailability,
      HiveBoxNames.topicDependencies,
      HiveBoxNames.settings,
      HiveBoxNames.profile,
      HiveBoxNames.llmTasks,
      HiveBoxNames.llmUsageRecords,
    ];

    for (final boxName in boxNames) {
      if (!Hive.isBoxOpen(boxName)) continue;
      final box = Hive.box(boxName);
      final records = <Map<String, dynamic>>[];
      for (final value in box.values) {
        final map = _toMap(value);
        if (map != null) records.add(map);
      }
      if (records.isNotEmpty) data[boxName] = records;
    }
    return data;
  }

  Map<String, dynamic>? _toMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    try {
      final obj = value as dynamic;
      return obj.toJson() as Map<String, dynamic>;
    } catch (e) {
      const Logger('SettingsScreen').e('Failed to convert map', e);
      return null;
    }
  }

  Future<void> _writeBoxData(
      Map<String, List<Map<String, dynamic>>> data) async {
    for (final entry in data.entries) {
      final boxName = entry.key;
      final records = entry.value;
      if (!Hive.isBoxOpen(boxName)) continue;
      final box = Hive.box(boxName);
      await box.clear();
      for (final record in records) {
        final obj = _deserializeRecord(boxName, record);
        final key = record['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
        await box.put(key, obj);
      }
    }
  }

  Future<void> _writeBoxDataMerge(
      Map<String, List<Map<String, dynamic>>> data) async {
    for (final entry in data.entries) {
      final boxName = entry.key;
      final records = entry.value;
      if (!Hive.isBoxOpen(boxName)) continue;
      final box = Hive.box(boxName);
      for (final record in records) {
        final key = record['id'] as String?;
        if (key != null && box.containsKey(key)) continue;
        if (key == null) continue;
        final obj = _deserializeRecord(boxName, record);
        await box.put(key, obj);
      }
    }
  }

  dynamic _deserializeRecord(String boxName, Map<String, dynamic> json) {
    switch (boxName) {
      case HiveBoxNames.subjects:
        return Subject.fromJson(json);
      case HiveBoxNames.topics:
        return Topic.fromJson(json);
      case HiveBoxNames.questions:
        return Question.fromJson(json);
      case HiveBoxNames.sources:
        return Source.fromJson(json);
      case HiveBoxNames.lessons:
        return Lesson.fromJson(json);
      case HiveBoxNames.sessionsTyped:
        return Session.fromJson(json);
      case HiveBoxNames.masteryStates:
        return MasteryState.fromJson(json);
      case HiveBoxNames.questionMasteryStates:
        return QuestionMasteryState.fromJson(json);
      case HiveBoxNames.questionEvaluations:
        return QuestionEvaluation.fromJson(json);
      case HiveBoxNames.learningPlans:
        return PersonalLearningPlan.fromJson(json);
      case HiveBoxNames.planAdherence:
        return PlanAdherenceModel.fromJson(json);
      case HiveBoxNames.planAdherenceMetrics:
        // ok: stored as raw Map<String, dynamic> — metric aggregates
        return json;
      case HiveBoxNames.masteryImprovementMetrics:
        // ok: stored as raw Map<String, dynamic> — metric aggregates
        return json;
      case HiveBoxNames.conversations:
        return ConversationMessage.fromJson(json);
      case HiveBoxNames.tutorSessions:
        return TutorSession.fromJson(json);
      case HiveBoxNames.topicDependencies:
        return TopicDependency.fromJson(json);
      case HiveBoxNames.lessonBlocks:
        return LessonBlock.fromJson(json);
      case HiveBoxNames.attempts:
        return StudentAttempt.fromJson(json);
      case HiveBoxNames.badges:
        return BadgeModel.fromJson(json);
      case HiveBoxNames.engagementNudges:
        return EngagementNudgeModel.fromJson(json);
      case HiveBoxNames.focusSessions:
        return FocusSession.fromJson(json);
      case HiveBoxNames.pendingActions:
        return PendingActionModel.fromJson(json);
      case HiveBoxNames.tasks:
        return TaskModel.fromJson(json);
      case HiveBoxNames.settings:
        return SettingsBox.fromJson(json);
      case HiveBoxNames.profile:
        return UserProfile.fromJson(json);
      case HiveBoxNames.studentAvailability:
        return StudentAvailabilityModel.fromJson(json);
      case HiveBoxNames.llmTasks:
        return LlmTask.fromJson(json);
      case HiveBoxNames.llmUsageRecords:
        return LlmUsageRecord.fromJson(json);
      case HiveBoxNames.answers:
        // Answers are stored as raw Map<String, dynamic>
        return json;
      case HiveBoxNames.progress:
        // Progress stats stored as raw Map<String, dynamic>
        return json;
      case HiveBoxNames.sessions:
        // Legacy sessions stored as raw Map<String, dynamic>
        return json;
      default:
        return json;
    }
  }

  void _showTokenUsageDetails() {
    final l10n = AppLocalizations.of(context)!;
    final meter = ref.read(llmUsageMeterProvider);
    final totalTokens = meter.getTotalTokens();
    final totalCost = meter.getTotalCost();
    final avgCost = totalTokens > 0 ? (totalCost / totalTokens * 1000) : 0.0;
    final perFeature = meter.getTotalTokensPerFeature();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tokenUsageSummary),
        content: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.usageSummary(
                formatCurrency(totalCost, l10n.localeName),
                formatDecimal(totalTokens.toDouble(), l10n.localeName, minFractionDigits: 0),
                formatDecimal(avgCost, l10n.localeName, minFractionDigits: 4),
              )),
              const SizedBox(height: 16),
              if (perFeature.isNotEmpty) ...[
                const Divider(),
                ...perFeature.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_featureLabel(e.key)),
                      Text(
                        l10n.tokensLabel(
                          formatDecimal(e.value.toDouble(), l10n.localeName, minFractionDigits: 0),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  String _featureLabel(String feature) {
    final l10n = AppLocalizations.of(context)!;
    switch (feature) {
      case 'ocr_extraction':
      case 'transcription':
      case 'content_classification':
      case 'content_summarization':
      case 'question_generation':
        return l10n.featureLabelIngestion;
      case 'general':
        return l10n.featureLabelGeneral;
      default:
        return feature;
    }
  }

  Future<void> _showSignOutDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOut),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.signOutConfirmation),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Theme.of(ctx).colorScheme.tertiary),
                      const SizedBox(width: 8),
                      Text(
                        'What will be cleared:',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• API key\n• Selected AI model',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: Theme.of(ctx).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Your study data will be preserved.',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Theme.of(ctx).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    ref.read(apiKeyProvider.notifier).state = '';
    ref.read(selectedModelProvider.notifier).state = '';
    ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(apiKey: '', selectedModel: ''));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.signOutComplete)));
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

}

void _showAboutDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  String version = l10n.aboutVersion;
  try {
    final info = await getPackageInfo();
    if (info.version.isNotEmpty) {
      version = '${info.version}+${info.buildNumber}';
    }
  } catch (_) {}
  if (!context.mounted) return;
  showDialog(
    context: context,
    builder: (_) => AboutDialog(
      applicationName: l10n.aboutApplicationName,
      applicationVersion: version,
      applicationLegalese: l10n.aboutLegalese,
    ),
  );
}

Future<PackageInfo> getPackageInfo() => PackageInfo.fromPlatform();

class _AiModelLoadingSheet extends StatefulWidget {
  final String apiKey;
  final String currentModel;
  final TextEditingController searchController;
  final LlmProvider llmProvider;
  final String apiBaseUrl;
  final void Function(String modelId) onModelSelected;

  const _AiModelLoadingSheet({
    required this.apiKey,
    required this.currentModel,
    required this.searchController,
    required this.llmProvider,
    this.apiBaseUrl = '',
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
      final modelService = ModelListingService(
        apiKey: widget.apiKey,
        baseUrl: widget.apiBaseUrl,
        provider: widget.llmProvider,
      );
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
        child: const LoadingIndicator(),
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

class _FailedUploadsTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FailedUploadsTile> createState() => _FailedUploadsTileState();
}

class _FailedUploadsTileState extends ConsumerState<_FailedUploadsTile> {
  int _failedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadFailedCount();
  }

  Future<void> _loadFailedCount() async {
    try {
      final repo = SourceRepository();
      await repo.init();
      final failed = await repo.getFailed();
      if (mounted) setState(() => _failedCount = failed.length);
    } catch (e) {
      const Logger('SettingsScreen').e('Failed to load failed count', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: _failedCount > 0
          ? Badge(
              label: Text('$_failedCount'),
              child: const Icon(Icons.error_outline),
            )
          : const Icon(Icons.error_outline),
      title: Text(l10n.failedUploads),
      subtitle: Text(_failedCount > 0
          ? l10n.sourceCountFailed(_failedCount)
          : l10n.noFailedUploads),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => Navigator.pushNamed(context, AppRoutes.contentLibrary),
    );
  }
}

class _AiTaskMonitorTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AiTaskMonitorTile> createState() => _AiTaskMonitorTileState();
}

class _AiTaskMonitorTileState extends ConsumerState<_AiTaskMonitorTile> {
  int _activeCount = 0;
  int _failedCount = 0;

  @override
  void initState() {
    super.initState();
    _updateCounts();
  }

  void _updateCounts() {
    final taskManager = ref.read(llmTaskManagerProvider);
    _activeCount = taskManager.activeTasks.length;
    _failedCount = taskManager.tasks.where((t) => t.status == LlmTaskStatus.failed).length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = _activeCount + _failedCount;

    return ListTile(
      leading: total > 0
          ? Badge(
              label: Text('$total'),
              child: const Icon(Icons.monitor_heart),
            )
          : const Icon(Icons.monitor_heart),
      title: Text(l10n.aiTaskMonitor),
      subtitle: Text(_activeCount > 0 || _failedCount > 0
          ? l10n.viewActiveAiTasks
          : l10n.viewActiveAiTasks),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => Navigator.pushNamed(context, AppRoutes.llmTasks),
    );
  }
}

class _ModelItem {
  final String name;
  final String provider;
  final String id;

  const _ModelItem({required this.name, required this.provider, required this.id});
}
