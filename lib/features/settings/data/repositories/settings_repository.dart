import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import '../../../../core/constants/app_api_config.dart';
import '../models/settings_box.dart';
import '../models/settings_update.dart';
import '../models/user_profile_model.dart';
import 'package:studyking/core/errors/exceptions.dart';

/// Real implementation of settings repository using Hive storage
class SettingsRepository {
  Box? _settingsBox;
  Box? _profileBox;
  static const String _currentProfileKey = 'current_profile';
  static const String _settingsKey = 'settings';

  Box _requireSettingsBox() {
    final box = _settingsBox;
    if (box == null) {
      throw AppException(message: 'SettingsRepository not initialized', type: ExceptionType.database);
    }
    return box;
  }

  Box _requireProfileBox() {
    final box = _profileBox;
    if (box == null) {
      throw AppException(message: 'SettingsRepository not initialized', type: ExceptionType.database);
    }
    return box;
  }

  Future<Result<void>> init() async {
    try {
      _settingsBox = await Hive.openBox(HiveBoxNames.settings);
      _profileBox = await Hive.openBox(HiveBoxNames.profile);
      return Result.success(null);
    } catch (e) {
      return Result.failure('Failed to initialize settings repository: $e');
    }
  }

  Future<Result<void>> saveApiKey({
    required String service,
    required String key,
  }) async {
    try {
      final box = _requireSettingsBox();
      await box.put('apiKey', key);
      if (service != 'default') {
        await box.put('apiKey_$service', key);
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure('Failed to save API key: $e');
    }
  }

  Future<Result<String?>> getApiKey({required String service}) async {
    try {
      final box = _requireSettingsBox();
      if (service == 'default') {
        return Result.success(box.get('apiKey'));
      } else {
        return Result.success(box.get('apiKey_$service'));
      }
    } catch (e) {
      return Result.failure('Failed to get API key: $e');
    }
  }

  Future<Result<void>> saveProvider(LlmProvider provider) async {
    try {
      final box = _requireSettingsBox();
      await box.put('llmProvider', provider.name);
      return Result.success(null);
    } catch (e) {
      return Result.failure('Failed to save provider: $e');
    }
  }

  Future<Result<LlmProvider>> getProvider() async {
    try {
      final box = _requireSettingsBox();
      final stored = box.get('llmProvider', defaultValue: 'openRouter') as String;
      final provider = LlmProvider.values.firstWhere(
        (p) => p.name == stored,
        orElse: () => LlmProvider.openRouter,
      );
      return Result.success(provider);
    } catch (e) {
      return Result.failure('Failed to get provider: $e');
    }
  }

  Future<Result<void>> saveProfileData(UserProfile profile) async {
    try {
      final box = _requireProfileBox();
      await box.put(profile.id, profile);
      await box.put(_currentProfileKey, profile.id);
      return Result.success(null);
    } catch (e) {
      return Result.failure('Failed to save profile: $e');
    }
  }

  Future<Result<UserProfile?>> getProfileData() async {
    try {
      final box = _requireProfileBox();
      final currentId = box.get(_currentProfileKey);
      if (currentId is String) {
        final profile = box.get(currentId);
        if (profile is UserProfile) return Result.success(profile);
      }

      if (box.keys.isEmpty) {
        return Result.success(UserProfile(
          id: 'default_profile',
          name: '',
        ));
      }

      for (final key in box.keys) {
        final value = box.get(key);
        if (value is UserProfile) {
          await box.put(_currentProfileKey, value.id);
          return Result.success(value);
        }
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure('Failed to get profile: $e');
    }
  }

  Future<Result<SettingsBox>> getSettings() async {
    try {
      final box = _requireSettingsBox();

      final stored = box.get(_settingsKey);
      if (stored is Map) {
        return Result.success(SettingsBox.fromJson(stored.cast<String, dynamic>()));
      }

      final legacy = SettingsBox(
        apiKey: box.get('apiKey', defaultValue: ''),
        apiBaseUrl: box.get('apiBaseUrl', defaultValue: ApiConfig.openRouterBaseUrlString),
        selectedModel: box.get('selectedModel', defaultValue: ''),
        themeMode: box.get('themeMode', defaultValue: 0),
        fontSize: box.get('fontSize', defaultValue: SettingsBox.defaultFontSize),
        totalSessionCount: box.get('totalSessionCount', defaultValue: 0),
        totalStudyTimeMs: box.get('totalStudyTimeMs', defaultValue: 0),
        totalQuestions: box.get('totalQuestions', defaultValue: 0),
        studyRemindersEnabled: box.get('studyRemindersEnabled', defaultValue: true),
        requestTimeoutSeconds: box.get('requestTimeoutSeconds', defaultValue: SettingsBox.defaultRequestTimeoutSeconds),
        sessionDurationMinutes: box.get('sessionDurationMinutes', defaultValue: SettingsBox.defaultSessionDurationMinutes),
        highContrastEnabled: box.get('highContrastEnabled', defaultValue: false),
        largeTouchTargets: box.get('largeTouchTargets', defaultValue: false),
        reduceMotion: box.get('reduceMotion', defaultValue: false),
        boldText: box.get('boldText', defaultValue: false),
        revisionRemindersEnabled: box.get('revisionRemindersEnabled', defaultValue: true),
        lessonNotificationsEnabled: box.get('lessonNotificationsEnabled', defaultValue: true),
        overworkAlertsEnabled: box.get('overworkAlertsEnabled', defaultValue: true),
        planAdjustmentNotificationsEnabled:
            box.get('planAdjustmentNotificationsEnabled', defaultValue: true),
        breakDurationSeconds: box.get('breakDurationSeconds', defaultValue: SettingsBox.defaultBreakDurationSeconds),
        dailyReminderHour: box.get('dailyReminderHour', defaultValue: SettingsBox.defaultDailyReminderHour),
        dailyReminderMinute: box.get('dailyReminderMinute', defaultValue: 0),
        firstFocusVisit: box.get('firstFocusVisit', defaultValue: true),
        dailyReminderEnabled: box.get('dailyReminderEnabled', defaultValue: false),
      );
      await box.put(_settingsKey, legacy.toJson());
      return Result.success(legacy);
    } catch (e) {
      return Result.failure('Failed to get settings: $e');
    }
  }

  Future<Result<void>> updateSettings(SettingsUpdate update) async {
    try {
      final box = _requireSettingsBox();
      final currentResult = await getSettings();
      if (currentResult.isFailure) return Result.failure(currentResult.error);

      final updated = currentResult.data!.copyWith(
        apiKey: update.apiKey,
        apiBaseUrl: update.apiBaseUrl,
        selectedModel: update.selectedModel,
        llmProviderName: update.llmProviderName,
        lastConnectionTestMs: update.lastConnectionTestMs,
        lastLlmError: update.lastLlmError,
        themeModeEnum: update.themeMode,
        fontSize: update.fontSize,
        studyRemindersEnabled: update.studyRemindersEnabled,
        requestTimeoutSeconds: update.requestTimeoutSeconds,
        sessionDurationMinutes: update.sessionDurationMinutes,
        highContrastEnabled: update.highContrastEnabled,
        largeTouchTargets: update.largeTouchTargets,
        reduceMotion: update.reduceMotion,
        boldText: update.boldText,
        revisionRemindersEnabled: update.revisionRemindersEnabled,
        lessonNotificationsEnabled: update.lessonNotificationsEnabled,
        overworkAlertsEnabled: update.overworkAlertsEnabled,
        planAdjustmentNotificationsEnabled: update.planAdjustmentNotificationsEnabled,
        breakDurationSeconds: update.breakDurationSeconds,
        dailyReminderHour: update.dailyReminderHour,
        dailyReminderMinute: update.dailyReminderMinute,
        firstFocusVisit: update.firstFocusVisit,
        dailyReminderEnabled: update.dailyReminderEnabled,
      );

      await box.put(_settingsKey, updated.toJson());
      return Result.success(null);
    } catch (e) {
      return Result.failure('Failed to update settings: $e');
    }
  }

  Future<Result<void>> updateStats({
    int? sessionCount,
    int? studyTimeMs,
    int? questions,
  }) async {
    try {
      final currentResult = await getSettings();
      if (currentResult.isFailure) return Result.failure(currentResult.error);

      final updated = currentResult.data!.copyWith(
        totalSessionCount: sessionCount,
        totalStudyTimeMs: studyTimeMs,
        totalQuestions: questions,
      );
      final box = _requireSettingsBox();
      await box.put(_settingsKey, updated.toJson());
      return Result.success(null);
    } catch (e) {
      return Result.failure('Failed to update stats: $e');
    }
  }

  Future<Result<void>> clearSettings() async {
    try {
      final box = _requireSettingsBox();
      await box.clear();
      return Result.success(null);
    } catch (e) {
      return Result.failure('Failed to clear settings: $e');
    }
  }

  Future<Result<void>> clearProfile() async {
    try {
      final box = _requireProfileBox();
      await box.clear();
      return Result.success(null);
    } catch (e) {
      return Result.failure('Failed to clear profile: $e');
    }
  }

  @override
  String toString() {
    return 'SettingsRepository()';
  }
}
