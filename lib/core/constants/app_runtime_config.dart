import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/logger.dart';

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
    if (documentSizeBytes <= 256 * 1024) {
      return validatedChunkSize(4 * 1024);
    }
    if (documentSizeBytes <= 2 * 1024 * 1024) {
      return validatedChunkSize(8 * 1024);
    }
    if (documentSizeBytes <= 8 * 1024 * 1024) {
      return validatedChunkSize(12 * 1024);
    }
    return validatedChunkSize(16 * 1024);
  }

  static int validatedChunkSize(int value) {
    if (value < minChunkSizeBytes) return minChunkSizeBytes;
    if (value > maxChunkSizeBytes) return maxChunkSizeBytes;
    return value;
  }

  static int validatedChunkOverlap(int value, {required int chunkSize}) {
    final normalizedChunkSize = validatedChunkSize(chunkSize);
    final bounded = value < minChunkOverlapBytes
        ? minChunkOverlapBytes
        : (value > maxChunkOverlapBytes ? maxChunkOverlapBytes : value);
    final maxAllowedOverlap = normalizedChunkSize ~/ 4;
    if (bounded < minChunkOverlapBytes) return minChunkOverlapBytes;
    if (bounded > maxAllowedOverlap) return maxAllowedOverlap;
    return bounded;
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
  static final RegExp _placeholderTokenPattern = RegExp(
    r'(default|changeme|change me|sample|example|placeholder|dummy|test)',
  );

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
    final normalized = _normalizeKeyCandidate(key);
    const defaultLikeValues = <String>{
      'studykingdefaultencryptionkey',
      'changeme',
      'default',
      'placeholder',
      'sample',
      'dummy',
      'test',
    };
    if (defaultLikeValues.contains(normalized) ||
        _placeholderTokenPattern.hasMatch(normalized)) {
      throw StateError('Unsafe placeholder STUDYKING_ENCRYPTION_KEY detected.');
    }
    if (key.length < 32) {
      throw StateError(
        'STUDYKING_ENCRYPTION_KEY is too short. Minimum length is 32 characters.',
      );
    }
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(key);
    final hasDigit = RegExp(r'\d').hasMatch(key);
    if (!hasLetter || !hasDigit) {
      throw StateError(
        'STUDYKING_ENCRYPTION_KEY must include letters and numbers.',
      );
    }
    return key;
  }

  static String _normalizeKeyCandidate(String value) {
    final lower = value.trim().toLowerCase();
    return lower.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  static void enforceStartupGuards() {
    BuildConfig.validateOrThrow();
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
    if (quality < 0) return 0;
    if (quality > 100) return 100;
    return quality;
  }
}

class AppConfig {
  static final Logger _logger = const Logger('AppConfig');

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
    // Keep this payload non-sensitive. debugLogSnapshot() additionally redacts
    // keys matching secret/token/password/key for defensive logging.
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

  Map<String, Object?> redactedRuntimeSnapshot() {
    return redactSensitiveValues(runtimeSnapshot());
  }

  static final RegExp _sensitiveSnapshotKeyPattern = RegExp(
    r'(key|secret|token|password)',
    caseSensitive: false,
  );

  @visibleForTesting
  static Map<String, Object?> redactSensitiveValues(Map<String, Object?> data) {
    final redacted = <String, Object?>{};
    for (final entry in data.entries) {
      if (_sensitiveSnapshotKeyPattern.hasMatch(entry.key)) {
        redacted[entry.key] = '<redacted>';
      } else {
        redacted[entry.key] = entry.value;
      }
    }
    return redacted;
  }

  void debugLogSnapshot() {
    assert(() {
      _logger.i('AppConfig snapshot: ${redactedRuntimeSnapshot()}');
      return true;
    }());
  }
}

class AppConstants {
  AppConstants._();

  static AppConfig? _instance;

  static AppConfig get instance {
    final current = _instance;
    if (current != null) return current;
    throw StateError(
      'AppConstants is not initialized. Call AppConstants.initialize() during app startup.',
    );
  }

  static AppConfig initialize({Map<AppFeature, bool>? featureOverrides}) {
    return _instance ??= AppConfig.bootstrap(featureOverrides: featureOverrides);
  }

  static void resetForTesting() {
    _instance = null;
  }

  static void injectForTesting(AppConfig config) {
    _instance = config;
  }
}
