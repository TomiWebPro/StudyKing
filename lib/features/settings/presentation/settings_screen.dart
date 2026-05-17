import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:share_plus/share_plus.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/services/data_backup_service.dart';
import 'package:studyking/core/services/llm/llm_model_service.dart';
import 'package:studyking/core/services/notification_service.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/features/ingestion/data/models/source_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/questions/data/models/question_evaluation_model.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/providers/app_providers.dart'
    show apiKeyProvider, selectedModelProvider, settingsProvider, engagementSchedulerProvider;
import 'package:studyking/core/providers/llm_providers.dart' show llmUsageMeterProvider;

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
            _section(l10n.contentManagement, [
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
              _tile(l10n.aiTaskMonitor, l10n.viewActiveAiTasks, Icons.monitor_heart,
                  () => Navigator.pushNamed(context, AppRoutes.llmTasks)),
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
                  secondary: const Icon(Icons.alarm),
                  title: Text(l10n.dailyReminders),
                  subtitle: Text(l10n.dailyReminderDescription),
                  value: settings.dailyReminderEnabled,
                  onChanged: (value) =>
                      ref.read(settingsProvider.notifier).updateDailyReminderEnabled(value),
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

  Future<void> _showDailyReminderTimePicker(SettingsBox settings) async {
    final l10n = AppLocalizations.of(context)!;
    final initial = TimeOfDay(hour: settings.dailyReminderHour, minute: settings.dailyReminderMinute);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: l10n.dailyReminderTimeHelp,
    );
    if (picked != null) {
      await ref.read(settingsProvider.notifier).updateDailyReminderTime(picked.hour, picked.minute);
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
                    ref.read(settingsProvider.notifier).updateBreakDuration(s);
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

  Future<void> _exportBackup() async {
    final l10n = AppLocalizations.of(context)!;
    final backupService = DataBackupService();
    try {
      final boxData = _collectAllBoxData();
      final result = await backupService.exportAllData(boxData: boxData);
      if (result.isSuccess) {
        final file = File(result.data!);
        await Share.shareXFiles([XFile(file.path)],
            text: 'StudyKing Backup');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.backupExported)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:                     Text(l10n.backupExportFailedWithError(result.error!))),
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

      final backupService = DataBackupService();
      final result = await backupService.restoreData(filePath);
      if (result.isFailure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(l10n.invalidBackupFileWithError(result.error!))),
          );
        }
        return;
      }

      final data = result.data!;
      final totalBoxes = data.length;
      final totalRecords = data.values.fold(0, (int s, l) => s + l.length);

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.importConfirmTitle),
          content: Text(l10n.importPreview(totalBoxes, totalRecords)),
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

      if (confirmed != true) return;

      await _writeBoxData(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.importSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.importFailed}: $e')),
        );
      }
    }
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
        return json;
      case HiveBoxNames.masteryImprovementMetrics:
        return json;
      case HiveBoxNames.conversations:
        return ConversationMessage.fromJson(json);
      case HiveBoxNames.tutorSessions:
        return TutorSession.fromJson(json);
      case HiveBoxNames.topicDependencies:
        return TopicDependency.fromJson(json);
      case HiveBoxNames.lessonBlocks:
        return LessonBlock.fromJson(json);
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

class _ModelItem {
  final String name;
  final String provider;
  final String id;

  const _ModelItem({required this.name, required this.provider, required this.id});
}
