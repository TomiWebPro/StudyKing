import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/app_build_config.dart';
import 'package:studyking/core/constants/security_config.dart';

void main() {
  group('SecurityConfig encryption key validation', () {
    test('enforceStartupGuards passes in non-release mode', () {
      expect(() => SecurityConfig.enforceStartupGuards(), returnsNormally);
    });

    test('encryptionKeyOrThrow when key is set returns valid key', () {
      const key = String.fromEnvironment('STUDYKING_ENCRYPTION_KEY');
      if (key.isNotEmpty) {
        final result = SecurityConfig.encryptionKeyOrThrow();
        expect(result, isNotEmpty);
        expect(result.length, greaterThanOrEqualTo(32));
        expect(RegExp(r'[A-Za-z]').hasMatch(result), isTrue);
        expect(RegExp(r'\d').hasMatch(result), isTrue);
      }
    });

    test('encryptionKeyOrThrow when key is empty throws StateError', () {
      const key = String.fromEnvironment('STUDYKING_ENCRYPTION_KEY');
      if (key.isEmpty) {
        expect(
          () => SecurityConfig.encryptionKeyOrThrow(),
          throwsA(isA<StateError>()),
        );
      }
    });

    test('enforceStartupGuards in production environment', () {
      const env = String.fromEnvironment('APP_ENV', defaultValue: 'development');
      if (env == 'production') {
        expect(() => SecurityConfig.enforceStartupGuards(), returnsNormally);
      }
    });
  });

  group('SecurityConfig.requireAuthentication', () {
    test('returns true for production environment', () {
      expect(SecurityConfig.requireAuthentication(AppEnvironment.production), isTrue);
    });

    test('returns true for development environment by default', () {
      expect(SecurityConfig.requireAuthentication(AppEnvironment.development), isTrue);
    });

    test('returns true for staging environment by default', () {
      expect(SecurityConfig.requireAuthentication(AppEnvironment.staging), isTrue);
    });
  });
}
