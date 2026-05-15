import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/sessions/data/repositories/study_session_repository.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../data/database_service.dart';

final database = DatabaseService(
  topicRepository: TopicRepository(),
  questionRepository: QuestionRepository(),
  attemptRepository: AttemptRepository(),
  lessonRepository: LessonRepository(),
  sessionRepository: StudySessionRepository(),
  subjectRepository: SubjectRepository(),
  conversationRepository: ConversationRepository(),
  tutorSessionRepository: TutorSessionRepository(),
);

final settingsRepository = SettingsRepository();

class SettingsController extends StateNotifier<SettingsBox> {
  final Logger _logger = const Logger('SettingsController');
  final SettingsRepository _repository;
  bool _hasLoadedOnce = false;

  SettingsController(this._repository) : super(SettingsBox());

  Future<void> _loadSettings() async {
    if (_hasLoadedOnce) return;
    try {
      _hasLoadedOnce = true;
      final settings = await _repository.getSettings();
      state = settings;
    } catch (e) {
      _logger.e('Error loading settings', e);
    }
  }

  Future<void> updateSettings({
    String? apiKey,
    String? apiBaseUrl,
    String? selectedModel,
    ThemeMode? themeMode,
    double? fontSize,
    bool? studyRemindersEnabled,
    int? requestTimeoutSeconds,
    int? sessionDurationMinutes,
    bool? highContrastEnabled,
    bool? largeTouchTargets,
    bool? reduceMotion,
    bool? revisionRemindersEnabled,
    bool? lessonNotificationsEnabled,
    bool? overworkAlertsEnabled,
    bool? planAdjustmentNotificationsEnabled,
  }) async {
    try {
      await _repository.updateSettings(
        apiKey: apiKey ?? state.apiKey,
        apiBaseUrl: apiBaseUrl ?? state.apiBaseUrl,
        selectedModel: selectedModel ?? state.selectedModel,
        themeMode: themeMode ?? state.themeModeEnum,
        fontSize: fontSize ?? state.fontSize,
        studyRemindersEnabled:
            studyRemindersEnabled ?? state.studyRemindersEnabled,
        requestTimeoutSeconds:
            requestTimeoutSeconds ?? state.requestTimeoutSeconds,
        sessionDurationMinutes:
            sessionDurationMinutes ?? state.sessionDurationMinutes,
        highContrastEnabled:
            highContrastEnabled ?? state.highContrastEnabled,
        largeTouchTargets:
            largeTouchTargets ?? state.largeTouchTargets,
        reduceMotion:
            reduceMotion ?? state.reduceMotion,
        revisionRemindersEnabled:
            revisionRemindersEnabled ?? state.revisionRemindersEnabled,
        lessonNotificationsEnabled:
            lessonNotificationsEnabled ?? state.lessonNotificationsEnabled,
        overworkAlertsEnabled:
            overworkAlertsEnabled ?? state.overworkAlertsEnabled,
        planAdjustmentNotificationsEnabled:
            planAdjustmentNotificationsEnabled ?? state.planAdjustmentNotificationsEnabled,
      );
      state = await _repository.getSettings();
    } catch (e) {
      _logger.e('Error updating settings', e);
    }
  }

  Future<void> saveApiKey(String key) async {
    try {
      await _repository.saveApiKey(service: 'default', key: key);
      await _loadSettings();
    } catch (e) {
      _logger.e('Error saving API key', e);
    }
  }

  Future<void> updateTheme(ThemeMode mode) async {
    try {
      await _repository.updateSettings(themeMode: mode);
      state = await _repository.getSettings();
    } catch (e) {
      _logger.e('Error updating theme', e);
    }
  }

  Future<void> updateFontSize(double size) async {
    try {
      await _repository.updateSettings(fontSize: size);
      state = await _repository.getSettings();
    } catch (e) {
      _logger.e('Error updating font size', e);
    }
  }

  Future<void> updateModel(String model) async {
    try {
      await _repository.updateSettings(selectedModel: model);
      state = await _repository.getSettings();
    } catch (e) {
      _logger.e('Error updating model', e);
    }
  }

  Future<void> updateStudyReminders(bool enabled) async {
    await updateSettings(studyRemindersEnabled: enabled);
  }

  Future<void> updateRequestTimeout(int timeoutSeconds) async {
    await updateSettings(requestTimeoutSeconds: timeoutSeconds);
  }

  Future<void> updateSessionDuration(int minutes) async {
    await updateSettings(sessionDurationMinutes: minutes);
  }

  Future<void> updateStats({
    int? sessionCount,
    int? studyTimeMs,
    int? questions,
  }) async {
    try {
      await _repository.updateStats(
        sessionCount: sessionCount,
        studyTimeMs: studyTimeMs,
        questions: questions,
      );
      state = await _repository.getSettings();
    } catch (e) {
      _logger.e('Error updating stats', e);
    }
  }

  Future<void> updateHighContrast(bool enabled) async {
    await updateSettings(highContrastEnabled: enabled);
  }

  Future<void> updateLargeTouchTargets(bool enabled) async {
    await updateSettings(largeTouchTargets: enabled);
  }

  Future<void> updateReduceMotion(bool enabled) async {
    await updateSettings(reduceMotion: enabled);
  }

  Future<void> updateRevisionReminders(bool enabled) async {
    await updateSettings(revisionRemindersEnabled: enabled);
  }

  Future<void> updateLessonNotifications(bool enabled) async {
    await updateSettings(lessonNotificationsEnabled: enabled);
  }

  Future<void> updateOverworkAlerts(bool enabled) async {
    await updateSettings(overworkAlertsEnabled: enabled);
  }

  Future<void> updatePlanAdjustmentNotifications(bool enabled) async {
    await updateSettings(planAdjustmentNotificationsEnabled: enabled);
  }
}

final settingsProvider = StateNotifierProvider<SettingsController, SettingsBox>((ref) {
  return SettingsController(settingsRepository);
});

final settingsLoadingProvider = StateProvider<bool>((ref) => false);

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

final fontSizeProvider = StateProvider<double>((ref) => 16.0);

final apiKeyProvider = StateProvider<String>((ref) => '');

final apiBaseUrlProvider = StateProvider<String>((ref) => ApiConfig.openRouterBaseUrlString);

final selectedModelProvider = StateProvider<String>((ref) => '');

final localeProvider = StateProvider<Locale>((ref) {
  try {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    for (final supported in AppLocalizations.supportedLocales) {
      if (supported.languageCode == deviceLocale.languageCode) {
        return supported;
      }
    }
  } catch (_) {}
  return const Locale('en');
});
