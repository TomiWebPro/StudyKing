import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/settings_box.dart';

/// Real implementation of settings repository using Hive storage
class SettingsRepository {
  static final SettingsRepository _instance = SettingsRepository._internal();
  factory SettingsRepository() => _instance;
  SettingsRepository._internal();

  Box? _settingsBox;
  Box? _profileBox;

  Future<void> init() async {
    _settingsBox = await Hive.openBox('settings');
    _profileBox = await Hive.openBox('profile');
  }

  /// Save API key with service identifier
  Future<void> saveApiKey({
    required String service,
    required String key,
  }) async {
    if (_settingsBox == null) return;

    final box = _settingsBox!;
    final settings = SettingsBox(
      apiKey: key,
      apiBaseUrl: box.get('apiBaseUrl', defaultValue: 'https://openrouter.ai/api/v1'),
      selectedModel: box.get('selectedModel', defaultValue: ''),
      themeMode: box.get('themeMode', defaultValue: 0),
      fontSize: box.get('fontSize', defaultValue: 16.0),
      totalSessionCount: box.get('totalSessionCount', defaultValue: 0),
      totalStudyTimeMs: box.get('totalStudyTimeMs', defaultValue: 0),
      totalQuestions: box.get('totalQuestions', defaultValue: 0),
    );

    // Use service name as a key prefix if needed
    await box.put('apiKey', key);
    if (service != 'default') {
      await box.put('apiKey_$service', key);
    }
  }

  /// Get API key by service
  Future<String?> getApiKey({required String service}) async {
    if (_settingsBox == null) return null;

    final box = _settingsBox!;
    
    // Check if this is a service-specific key
    if (service == 'default') {
      return box.get('apiKey');
    } else {
      return box.get('apiKey_$service');
    }
  }

  /// Save profile data
  Future<void> saveProfileData(ProfileData profile) async {
    if (_profileBox == null) return;
    await _profileBox!.put(profile.id, profile);
  }

  /// Get profile data
  Future<ProfileData?> getProfileData() async {
    if (_profileBox == null) return null;

    // Get the latest profile or use default
    final box = _profileBox!;
    if (box.keys.isEmpty) {
      return ProfileData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '',
      );
    }
    
    final firstKey = box.keys.first;
    return box.get(firstKey);
  }

  /// Get current settings
  Future<SettingsBox> getSettings() async {
    if (_settingsBox == null) {
      return SettingsBox();
    }

    final box = _settingsBox!;
    
    return SettingsBox(
      apiKey: box.get('apiKey', defaultValue: ''),
      apiBaseUrl: box.get('apiBaseUrl', defaultValue: 'https://openrouter.ai/api/v1'),
      selectedModel: box.get('selectedModel', defaultValue: ''),
      themeMode: box.get('themeMode', defaultValue: 0),
      fontSize: box.get('fontSize', defaultValue: 16.0),
      totalSessionCount: box.get('totalSessionCount', defaultValue: 0),
      totalStudyTimeMs: box.get('totalStudyTimeMs', defaultValue: 0),
      totalQuestions: box.get('totalQuestions', defaultValue: 0),
    );
  }

  /// Update settings fields
  Future<void> updateSettings({
    String? apiKey,
    String? apiBaseUrl,
    String? selectedModel,
    ThemeMode? themeMode,
    double? fontSize,
  }) async {
    if (_settingsBox == null) return;

    final box = _settingsBox!;
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
    );

    // Store updated settings
    await box.clear();
    await box.put(0, updated);
  }

  /// Update statistics counters
  Future<void> updateStats({
    int? sessionCount,
    int? studyTimeMs,
    int? questions,
  }) async {
    if (_settingsBox == null) return;

    final box = _settingsBox!;
    final current = await getSettings();

    final updated = SettingsBox(
      apiKey: current.apiKey,
      apiBaseUrl: current.apiBaseUrl,
      selectedModel: current.selectedModel,
      themeMode: current.themeMode,
      fontSize: current.fontSize,
      totalSessionCount: sessionCount ?? current.totalSessionCount,
      totalStudyTimeMs: studyTimeMs ?? current.totalStudyTimeMs,
      totalQuestions: questions ?? current.totalQuestions,
    );

    await box.clear();
    await box.put(0, updated);
  }

  /// Clear all settings (use with caution)
  Future<void> clearSettings() async {
    await _settingsBox?.clear();
  }

  /// Clear profile data
  Future<void> clearProfile() async {
    await _profileBox?.clear();
  }

  @override
  String toString() {
    return 'SettingsRepository()';
  }
}
