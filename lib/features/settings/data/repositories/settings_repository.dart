import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import '../../../../core/constants/app_api_config.dart';
import '../models/settings_box.dart';
import '../models/user_profile_model.dart';

/// Real implementation of settings repository using Hive storage
class SettingsRepository {
  Box? _settingsBox;
  Box? _profileBox;
  static const String _currentProfileKey = 'current_profile';
  static const String _settingsKey = 'settings';

  Box _requireSettingsBox() {
    final box = _settingsBox;
    if (box == null) {
      throw StateError('SettingsRepository not initialized');
    }
    return box;
  }

  Box _requireProfileBox() {
    final box = _profileBox;
    if (box == null) {
      throw StateError('SettingsRepository not initialized');
    }
    return box;
  }

  Future<void> init() async {
    _settingsBox = await Hive.openBox(HiveBoxNames.settings);
    _profileBox = await Hive.openBox(HiveBoxNames.profile);
  }

  /// Save API key with service identifier
  Future<void> saveApiKey({
    required String service,
    required String key,
  }) async {
    final box = _requireSettingsBox();

    // Use service name as a key prefix if needed
    await box.put('apiKey', key);
    if (service != 'default') {
      await box.put('apiKey_$service', key);
    }
  }

  /// Get API key by service
  Future<String?> getApiKey({required String service}) async {
    final box = _requireSettingsBox();
    
    // Check if this is a service-specific key
    if (service == 'default') {
      return box.get('apiKey');
    } else {
      return box.get('apiKey_$service');
    }
  }

  /// Save LLM provider selection
  Future<void> saveProvider(LlmProvider provider) async {
    final box = _requireSettingsBox();
    await box.put('llmProvider', provider.name);
  }

  /// Get LLM provider selection
  Future<LlmProvider> getProvider() async {
    final box = _requireSettingsBox();
    final stored = box.get('llmProvider', defaultValue: 'openRouter') as String;
    return LlmProvider.values.firstWhere(
      (p) => p.name == stored,
      orElse: () => LlmProvider.openRouter,
    );
  }

  /// Save profile data
  Future<void> saveProfileData(UserProfile profile) async {
    final box = _requireProfileBox();
    await box.put(profile.id, profile);
    await box.put(_currentProfileKey, profile.id);
  }

  /// Get profile data
  Future<UserProfile?> getProfileData() async {
    final box = _requireProfileBox();
    final currentId = box.get(_currentProfileKey);
    if (currentId is String) {
      final profile = box.get(currentId);
      if (profile is UserProfile) return profile;
    }

    if (box.keys.isEmpty) {
      return UserProfile(
        id: 'default_profile',
        name: '',
      );
    }

    for (final key in box.keys) {
      final value = box.get(key);
      if (value is UserProfile) {
        await box.put(_currentProfileKey, value.id);
        return value;
      }
    }
    return null;
  }

  /// Get current settings
  Future<SettingsBox> getSettings() async {
    final box = _requireSettingsBox();

    final stored = box.get(_settingsKey);
    if (stored is Map) {
      return SettingsBox.fromJson(stored.cast<String, dynamic>());
    }

    // Migration from legacy per-key storage
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
    return legacy;
  }

  /// Update settings fields
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
    int? breakDurationSeconds,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    bool? firstFocusVisit,
    bool? dailyReminderEnabled,
  }) async {
    final box = _requireSettingsBox();
    final current = await getSettings();

    final updated = current.copyWith(
      apiKey: apiKey,
      apiBaseUrl: apiBaseUrl,
      selectedModel: selectedModel,
      themeModeEnum: themeMode,
      fontSize: fontSize,
      studyRemindersEnabled: studyRemindersEnabled,
      requestTimeoutSeconds: requestTimeoutSeconds,
      sessionDurationMinutes: sessionDurationMinutes,
      highContrastEnabled: highContrastEnabled,
      largeTouchTargets: largeTouchTargets,
      reduceMotion: reduceMotion,
      revisionRemindersEnabled: revisionRemindersEnabled,
      lessonNotificationsEnabled: lessonNotificationsEnabled,
      overworkAlertsEnabled: overworkAlertsEnabled,
      planAdjustmentNotificationsEnabled: planAdjustmentNotificationsEnabled,
      breakDurationSeconds: breakDurationSeconds,
      dailyReminderHour: dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute,
      firstFocusVisit: firstFocusVisit,
      dailyReminderEnabled: dailyReminderEnabled,
    );

    await box.put(_settingsKey, updated.toJson());
  }

  /// Update statistics counters
  Future<void> updateStats({
    int? sessionCount,
    int? studyTimeMs,
    int? questions,
  }) async {
    final current = await getSettings();
    final updated = current.copyWith(
      totalSessionCount: sessionCount,
      totalStudyTimeMs: studyTimeMs,
      totalQuestions: questions,
    );
    final box = _requireSettingsBox();
    await box.put(_settingsKey, updated.toJson());
  }

  /// Clear all settings (use with caution)
  Future<void> clearSettings() async {
    final box = _requireSettingsBox();
    await box.clear();
  }

  /// Clear profile data
  Future<void> clearProfile() async {
    final box = _requireProfileBox();
    await box.clear();
  }

  @override
  String toString() {
    return 'SettingsRepository()';
  }
}
