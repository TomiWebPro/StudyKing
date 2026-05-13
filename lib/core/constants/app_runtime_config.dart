import 'package:flutter/material.dart';

class UiConfig {
  const UiConfig._();

  static const ThemeMode defaultThemeMode = ThemeMode.system;
  static const bool defaultNotificationsEnabled = true;
  static const Duration notificationReminderLeadTime = Duration(minutes: 10);
  static const String notificationChannelId = 'study_reminders';
  static const String notificationChannelName = 'Study Reminders';
}

class CacheConfig {
  const CacheConfig._();

  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSizeMb = 100;
  static const int databaseCacheSizeMb = 100;
}
