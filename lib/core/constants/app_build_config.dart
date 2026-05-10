import 'package:flutter/foundation.dart';

enum AppEnvironment { development, staging, production }

class BuildConfig {
  const BuildConfig._();

  static const String appName = 'StudyKing';
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );
  static const String appBuildNumber = String.fromEnvironment(
    'APP_BUILD_NUMBER',
    defaultValue: '1',
  );

  static AppEnvironment get environment {
    const env = String.fromEnvironment('APP_ENV', defaultValue: 'development');
    switch (env.toLowerCase()) {
      case 'production':
      case 'prod':
        return AppEnvironment.production;
      case 'staging':
        return AppEnvironment.staging;
      case 'development':
      case 'dev':
        return AppEnvironment.development;
      default:
        if (kReleaseMode) {
          throw StateError('Unknown APP_ENV value: $env');
        }
        return AppEnvironment.development;
    }
  }

  static void validateOrThrow() {
    final env = environment;
    if (!kReleaseMode) return;
    if (appVersion == '1.0.0') {
      throw StateError('APP_VERSION must be set in release builds.');
    }
    if (appBuildNumber == '1') {
      throw StateError('APP_BUILD_NUMBER must be set in release builds.');
    }
    if (env == AppEnvironment.development) {
      throw StateError('Release mode cannot run with development APP_ENV.');
    }
  }
}
