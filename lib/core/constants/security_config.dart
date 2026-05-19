import 'package:flutter/foundation.dart';
import 'app_build_config.dart';
import 'package:studyking/core/errors/exceptions.dart';
import 'package:studyking/core/utils/string_extensions.dart';

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
      throw AppException(message: 'Missing STUDYKING_ENCRYPTION_KEY. Use platform keystore-backed provisioning.', type: ExceptionType.validation);
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
      throw AppException(message: 'Unsafe placeholder STUDYKING_ENCRYPTION_KEY detected.', type: ExceptionType.validation);
    }
    if (key.length < 32) {
      throw AppException(message: 'STUDYKING_ENCRYPTION_KEY is too short. Minimum length is 32 characters.', type: ExceptionType.validation);
    }
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(key);
    final hasDigit = RegExp(r'\d').hasMatch(key);
    if (!hasLetter || !hasDigit) {
      throw AppException(message: 'STUDYKING_ENCRYPTION_KEY must include letters and numbers.', type: ExceptionType.validation);
    }
    return key;
  }

  static String _normalizeKeyCandidate(String value) {
    final lower = value.normalized;
    return lower.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  static void enforceStartupGuards() {
    BuildConfig.validateOrThrow();
    final env = BuildConfig.environment;
    if (env == AppEnvironment.production || kReleaseMode) {
      encryptionKeyOrThrow();
      if (!requireAuthentication(env)) {
        throw AppException(message: 'Authentication must be enabled in production.', type: ExceptionType.validation);
      }
    }
  }
}
