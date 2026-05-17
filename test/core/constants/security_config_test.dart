import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/app_build_config.dart';
import 'package:studyking/core/constants/security_config.dart';

void main() {
  group('SecurityConfig', () {
    test('sessionTimeout is 30 minutes', () {
      expect(SecurityConfig.sessionTimeout, const Duration(minutes: 30));
    });

    test('enforceStartupGuards validates build config', () {
      expect(
        () => SecurityConfig.enforceStartupGuards(),
        returnsNormally,
      );
    });

    test('requireAuthentication returns true for production', () {
      expect(
        SecurityConfig.requireAuthentication(AppEnvironment.production),
        isTrue,
      );
    });

    test('encryptionKeyOrThrow throws for empty key', () {
      expect(
        () => SecurityConfig.encryptionKeyOrThrow(),
        throwsA(isA<StateError>()),
      );
    });
  });
}
