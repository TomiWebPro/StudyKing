import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/app_build_config.dart';
import 'package:studyking/core/constants/app_runtime_config.dart';
import 'package:studyking/core/constants/app_api_config.dart';

void main() {
  group('BuildConfig in production', () {
    test('environment returns production with APP_ENV=production', () {
      expect(BuildConfig.environment, AppEnvironment.production);
    });

    test('validateOrThrow passes in non-release mode', () {
      expect(() => BuildConfig.validateOrThrow(), returnsNormally);
    });
  });

  group('SecurityConfig in production', () {
    test('requireAuthentication returns true for production', () {
      expect(SecurityConfig.requireAuthentication(AppEnvironment.production), isTrue);
    });

    test('enforceStartupGuards throws because encryption key is missing', () {
      expect(
        () => SecurityConfig.enforceStartupGuards(),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('ApiSecrets in production', () {
    test('fromRuntime with empty openRouterApiKey throws', () {
      expect(
        () => ApiSecrets.fromRuntime(openRouterApiKey: ''),
        throwsA(isA<StateError>()),
      );
    });

    test('fromEnvironment throws because OPENROUTER_API_KEY is empty', () {
      expect(
        () => ApiSecrets.fromEnvironment(),
        throwsA(isA<StateError>()),
      );
    });
  });
}
