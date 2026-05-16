import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import '../../../../core/constants/app_api_config.dart';
import '../models/settings_box.dart';
import '../models/user_profile_model.dart';

/// Real implementation of settings repository using Hive storage
class SettingsRepository {
  static final SettingsRepository _instance = SettingsRepository._internal();
  factory SettingsRepository() => _instance;
  SettingsRepository._internal();

  Box? _settingsBox;
  Box? _profileBox;
  static const String _currentProfileKey = 'current_profile';

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
    
    return SettingsBox(
      apiKey: box.get('apiKey', defaultValue: ''),
      apiBaseUrl: box.get('apiBaseUrl', defaultValue: ApiConfig.openRouterBaseUrlString),
      selectedModel: box.get('selectedModel', defaultValue: ''),
      themeMode: box.get('themeMode', defaultValue: 0),
      fontSize: box.get('fontSize', defaultValue: 16.0),
      totalSessionCount: box.get('totalSessionCount', defaultValue: 0),
      totalStudyTimeMs: box.get('totalStudyTimeMs', defaultValue: 0),
      totalQuestions: box.get('totalQuestions', defaultValue: 0),
      studyRemindersEnabled: box.get('studyRemindersEnabled', defaultValue: true),
      requestTimeoutSeconds: box.get('requestTimeoutSeconds', defaultValue: 120),
      sessionDurationMinutes: box.get('sessionDurationMinutes', defaultValue: 30),
      highContrastEnabled: box.get('highContrastEnabled', defaultValue: false),
      largeTouchTargets: box.get('largeTouchTargets', defaultValue: false),
      reduceMotion: box.get('reduceMotion', defaultValue: false),
      revisionRemindersEnabled:
          box.get('revisionRemindersEnabled', defaultValue: true),
      lessonNotificationsEnabled:
          box.get('lessonNotificationsEnabled', defaultValue: true),
      overworkAlertsEnabled:
          box.get('overworkAlertsEnabled', defaultValue: true),
      planAdjustmentNotificationsEnabled:
          box.get('planAdjustmentNotificationsEnabled', defaultValue: true),
    );
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
  }) async {
    final box = _requireSettingsBox();
    final current = await getSettings();

    final updated = SettingsBox(
      apiKey: apiKey ?? current.apiKey,
      apiBaseUrl: apiBaseUrl ?? current.apiBaseUrl,
      selectedModel: selectedModel ?? current.selectedModel,
      themeMode: themeMode?.index ?? current.themeMode,
      fontSize: fontSize ?? current.fontSize,
      totalSessionCount: current.totalSessionCount,
      totalStudyTimeMs: current.totalStudyTimeMs,
      totalQuestions: current.totalQuestions,
      studyRemindersEnabled:
          studyRemindersEnabled ?? current.studyRemindersEnabled,
      requestTimeoutSeconds:
          requestTimeoutSeconds ?? current.requestTimeoutSeconds,
      sessionDurationMinutes:
          sessionDurationMinutes ?? current.sessionDurationMinutes,
      highContrastEnabled:
          highContrastEnabled ?? current.highContrastEnabled,
      largeTouchTargets:
          largeTouchTargets ?? current.largeTouchTargets,
      reduceMotion:
          reduceMotion ?? current.reduceMotion,
      revisionRemindersEnabled:
          revisionRemindersEnabled ?? current.revisionRemindersEnabled,
      lessonNotificationsEnabled:
          lessonNotificationsEnabled ?? current.lessonNotificationsEnabled,
      overworkAlertsEnabled:
          overworkAlertsEnabled ?? current.overworkAlertsEnabled,
      planAdjustmentNotificationsEnabled:
          planAdjustmentNotificationsEnabled ?? current.planAdjustmentNotificationsEnabled,
    );

    await box.put('apiKey', updated.apiKey);
    await box.put('apiBaseUrl', updated.apiBaseUrl);
    await box.put('selectedModel', updated.selectedModel);
    await box.put('themeMode', updated.themeMode);
    await box.put('fontSize', updated.fontSize);
    await box.put('totalSessionCount', updated.totalSessionCount);
    await box.put('totalStudyTimeMs', updated.totalStudyTimeMs);
    await box.put('totalQuestions', updated.totalQuestions);
    await box.put('studyRemindersEnabled', updated.studyRemindersEnabled);
    await box.put('requestTimeoutSeconds', updated.requestTimeoutSeconds);
    await box.put('sessionDurationMinutes', updated.sessionDurationMinutes);
    await box.put('highContrastEnabled', updated.highContrastEnabled);
    await box.put('largeTouchTargets', updated.largeTouchTargets);
    await box.put('reduceMotion', updated.reduceMotion);
    await box.put('revisionRemindersEnabled', updated.revisionRemindersEnabled);
    await box.put('lessonNotificationsEnabled', updated.lessonNotificationsEnabled);
    await box.put('overworkAlertsEnabled', updated.overworkAlertsEnabled);
    await box.put('planAdjustmentNotificationsEnabled', updated.planAdjustmentNotificationsEnabled);
  }

  /// Update statistics counters
  Future<void> updateStats({
    int? sessionCount,
    int? studyTimeMs,
    int? questions,
  }) async {
    final current = await getSettings();
    await updateSettings(
      apiKey: current.apiKey,
      apiBaseUrl: current.apiBaseUrl,
      selectedModel: current.selectedModel,
      themeMode: current.themeModeEnum,
      fontSize: current.fontSize,
      studyRemindersEnabled: current.studyRemindersEnabled,
      requestTimeoutSeconds: current.requestTimeoutSeconds,
      sessionDurationMinutes: current.sessionDurationMinutes,
      highContrastEnabled: current.highContrastEnabled,
      largeTouchTargets: current.largeTouchTargets,
      reduceMotion: current.reduceMotion,
    );
    final box = _requireSettingsBox();
    await box.put('totalSessionCount', sessionCount ?? current.totalSessionCount);
    await box.put('totalStudyTimeMs', studyTimeMs ?? current.totalStudyTimeMs);
    await box.put('totalQuestions', questions ?? current.totalQuestions);
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
