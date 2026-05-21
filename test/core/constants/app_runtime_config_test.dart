import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/app_runtime_config.dart';

void main() {
  group('UiConfig', () {
    test('has expected default values', () {
      expect(UiConfig.defaultThemeMode, ThemeMode.system);
      expect(UiConfig.defaultNotificationsEnabled, isTrue);
      expect(UiConfig.notificationReminderLeadTime, const Duration(minutes: 10));
    });
  });

  group('CacheConfig', () {
    test('cache expiration is 24 hours', () {
      expect(CacheConfig.cacheExpiration, const Duration(hours: 24));
    });

    test('max cache size is positive', () {
      expect(CacheConfig.maxCacheSizeMb, greaterThan(0));
      expect(CacheConfig.databaseCacheSizeMb, greaterThan(0));
    });

    test('database cache matches max cache', () {
      expect(CacheConfig.databaseCacheSizeMb, CacheConfig.maxCacheSizeMb);
    });
  });
}
