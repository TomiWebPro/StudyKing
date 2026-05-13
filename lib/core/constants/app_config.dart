import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/logger.dart';
import 'app_api_config.dart';
import 'app_build_config.dart';
import 'app_features.dart';
import 'app_runtime_config.dart';
import 'security_config.dart';

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


