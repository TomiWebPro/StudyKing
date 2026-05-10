import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_api_config.dart';
import 'app_build_config.dart';
import 'app_features.dart';

class StudyConfig {
  const StudyConfig._();

  static const int defaultQuestionsPerSession = 10;
  static const int maxQuestionsPerSession = 50;
  static const int minScoreForMastery = 80;
  static const int maxRetryAttempts = 3;
  static const Duration defaultStudySessionDuration = Duration(minutes: 45);
  static const Duration defaultBreakDuration = Duration(minutes: 10);
  static const int maxDailyStudyHours = 8;
}

class UiConfig {
  const UiConfig._();

  static const ThemeMode defaultThemeMode = ThemeMode.system;
  static const bool defaultNotificationsEnabled = true;
  static const Duration notificationReminderLeadTime = Duration(minutes: 10);
  static const String notificationChannelId = 'study_reminders';
  static const String notificationChannelName = 'Study Reminders';
}

class PdfConfig {
  const PdfConfig._();

  static const int maxPdfPagesForSingleLoad = 50;
  static const int minChunkSizeBytes = 1024;
  static const int maxChunkSizeBytes = 128 * 1024;
  static const int defaultChunkSizeBytes = 10 * 1024;
  static const int minChunkOverlapBytes = 0;
  static const int maxChunkOverlapBytes = 8 * 1024;
  static const int defaultChunkOverlapBytes = 500;

  static int adaptiveChunkSize({required int documentSizeBytes}) {
    if (documentSizeBytes <= 256 * 1024) return 4 * 1024;
    if (documentSizeBytes <= 2 * 1024 * 1024) return 8 * 1024;
    if (documentSizeBytes <= 8 * 1024 * 1024) return 12 * 1024;
    return 16 * 1024;
  }

  static int validatedChunkSize(int value) {
    return value.clamp(minChunkSizeBytes, maxChunkSizeBytes);
  }

  static int validatedChunkOverlap(int value, {required int chunkSize}) {
    final bounded = value.clamp(minChunkOverlapBytes, maxChunkOverlapBytes);
    return bounded.clamp(minChunkOverlapBytes, chunkSize ~/ 4);
  }
}

class ErrorKeys {
  const ErrorKeys._();

  static const String unexpected = 'error.unexpected';
  static const String networkConnectionFailed = 'error.network.connection_failed';
  static const String authenticationFailed = 'error.auth.failed';
}

class CacheConfig {
  const CacheConfig._();

  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSizeMb = 100;
  static const int databaseCacheSizeMb = 100;
}

class SecurityConfig {
  const SecurityConfig._();

  static const Duration sessionTimeout = Duration(minutes: 30);

  static bool requireAuthentication(AppEnvironment environment) {
    const nonProdOverride = bool.fromEnvironment(
      'ALLOW_UNAUTHENTICATED_MODE',
      defaultValue: false,
    );
    if (environment == AppEnvironment.production) return true;
    return !nonProdOverride;
  }

  static String encryptionKeyOrThrow() {
    final key = const String.fromEnvironment('STUDYKING_ENCRYPTION_KEY');
    if (key.isEmpty) {
      throw StateError(
        'Missing STUDYKING_ENCRYPTION_KEY. Use platform keystore-backed provisioning.',
      );
    }
    const defaultLikeValues = <String>{
      'studyking_default_encryption_key',
      'change-me',
      'default',
    };
    if (defaultLikeValues.contains(key.toLowerCase())) {
      throw StateError('Unsafe placeholder STUDYKING_ENCRYPTION_KEY detected.');
    }
    return key;
  }

  static void enforceStartupGuards() {
    final env = BuildConfig.environment;
    if (env == AppEnvironment.production || kReleaseMode) {
      encryptionKeyOrThrow();
      if (!requireAuthentication(env)) {
        throw StateError('Authentication must be enabled in production.');
      }
    }
  }
}

class MediaConfig {
  const MediaConfig._();

  static const int defaultImageCompressionQuality = 80;

  static int validatedImageCompressionQuality(int quality) {
    return quality.clamp(0, 100);
  }
}

class AppConfig {
  AppConfig({
    required this.environment,
    required this.apiConfig,
    required this.secrets,
    required this.featureFlags,
  });

  final AppEnvironment environment;
  final ApiConfig apiConfig;
  final ApiSecrets secrets;
  final FeatureFlagService featureFlags;

  factory AppConfig.bootstrap({Map<AppFeature, bool>? featureOverrides}) {
    final env = BuildConfig.environment;
    SecurityConfig.enforceStartupGuards();
    return AppConfig(
      environment: env,
      apiConfig: ApiConfig.forEnvironment(env),
      secrets: ApiSecrets.fromEnvironment(),
      featureFlags: FeatureFlagService(overrides: featureOverrides),
    );
  }

  Map<String, Object?> runtimeSnapshot() {
    return {
      'appName': BuildConfig.appName,
      'version': BuildConfig.appVersion,
      'build': BuildConfig.appBuildNumber,
      'environment': environment.name,
      'openRouterBaseUrl': apiConfig.openRouterBaseUrl.toString(),
      'openRouterTimeoutMs': apiConfig.openRouterRequestTimeout.inMilliseconds,
      'youtubeTimeoutMs': apiConfig.youtubeRequestTimeout.inMilliseconds,
      'defaultThemeMode': UiConfig.defaultThemeMode.name,
      'cacheExpirationHours': CacheConfig.cacheExpiration.inHours,
      'performanceOptimization': featureFlags.isEnabled(AppFeature.performanceOptimization),
      'requireAuthentication': SecurityConfig.requireAuthentication(environment),
    };
  }

  void debugLogSnapshot() {
    assert(() {
      debugPrint('AppConfig snapshot: ${runtimeSnapshot()}');
      return true;
    }());
  }
}

class AppConstants {
  AppConstants._();

  static AppConfig? _instance;

  static AppConfig get instance =>
      _instance ??= AppConfig.bootstrap(featureOverrides: const {});
}
