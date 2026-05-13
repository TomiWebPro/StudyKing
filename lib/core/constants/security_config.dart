import 'package:flutter/foundation.dart';
import 'app_build_config.dart';

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
