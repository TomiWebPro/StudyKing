import 'package:flutter/material.dart';

class UiConfig {
  const UiConfig._();

  static const ThemeMode defaultThemeMode = ThemeMode.system;
  static const bool defaultNotificationsEnabled = true;
  static const Duration notificationReminderLeadTime = Duration(minutes: 10);

  static const double minFontSize = 10.0;
  static const double maxFontSize = 30.0;
}

class CacheConfig {
  const CacheConfig._();

  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSizeMb = 100;
  static const int databaseCacheSizeMb = 100;

  /// Per-feature TTL for LLM response caching.
  static const Duration classificationCacheTtl = Duration(hours: 24);
  static const Duration lessonPlanCacheTtl = Duration(hours: 1);
  static const Duration tutorCacheTtl = Duration(minutes: 5);
  static const Duration defaultCacheTtl = Duration(minutes: 10);
}
