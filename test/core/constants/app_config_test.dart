import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/app_api_config.dart';
import 'package:studyking/core/constants/app_build_config.dart';
import 'package:studyking/core/constants/app_config.dart';

void main() {
  group('AppConstants', () {
    setUp(() {
      AppConstants.resetForTesting();
    });

    tearDown(() {
      AppConstants.resetForTesting();
    });

    test('throws StateError when not initialized', () {
      expect(
        () => AppConstants.instance,
        throwsA(isA<StateError>()),
      );
    });

    test('initialize creates config', () {
      final config = AppConstants.initialize();
      expect(config, isA<AppConfig>());
      expect(AppConstants.instance, same(config));
    });

    test('initialize returns same instance on second call', () {
      final first = AppConstants.initialize();
      final second = AppConstants.initialize();
      expect(first, same(second));
    });

    test('resetForTesting clears instance', () {
      AppConstants.initialize();
      AppConstants.resetForTesting();
      expect(
        () => AppConstants.instance,
        throwsA(isA<StateError>()),
      );
    });

    test('injectForTesting allows custom config', () {
      final custom = AppConfig(
        environment: AppEnvironment.development,
        apiConfig: ApiConfig.forEnvironment(AppEnvironment.development),
        secrets: ApiSecrets.fromEnvironment(),
      );
      AppConstants.injectForTesting(custom);
      expect(AppConstants.instance, same(custom));
    });
  });

  group('AppConfig', () {
    test('bootstrap creates config', () {
      final config = AppConfig.bootstrap();
      expect(config, isA<AppConfig>());
    });

    test('runtimeSnapshot returns expected keys', () {
      final config = AppConfig.bootstrap();
      final snapshot = config.runtimeSnapshot();
      expect(snapshot, containsPair('appName', isNotNull));
      expect(snapshot, containsPair('version', isNotNull));
      expect(snapshot, containsPair('build', isNotNull));
      expect(snapshot, containsPair('environment', isNotNull));
    });

    test('redactSensitiveValues replaces sensitive keys', () {
      final data = <String, Object?>{
        'apiKey': 'sk-12345',
        'apiSecret': 'my-secret',
        'token': 'abc',
        'password': 'p@ss',
        'appName': 'StudyKing',
        'version': '1.0.0',
        'timeout': 30000,
        'ApiKey': 'another-key',
      };
      final redacted = AppConfig.redactSensitiveValues(data);
      expect(redacted['apiKey'], equals('<redacted>'));
      expect(redacted['apiSecret'], equals('<redacted>'));
      expect(redacted['token'], equals('<redacted>'));
      expect(redacted['password'], equals('<redacted>'));
      expect(redacted['ApiKey'], equals('<redacted>'));
      expect(redacted['appName'], equals('StudyKing'));
      expect(redacted['version'], equals('1.0.0'));
      expect(redacted['timeout'], equals(30000));
    });

    test('redactSensitiveValues with empty map', () {
      final redacted = AppConfig.redactSensitiveValues({});
      expect(redacted, isEmpty);
    });

    test('redactSensitiveValues with no sensitive keys', () {
      final data = <String, Object?>{
        'appName': 'StudyKing',
        'version': '1.0.0',
      };
      final redacted = AppConfig.redactSensitiveValues(data);
      expect(redacted['appName'], equals('StudyKing'));
      expect(redacted['version'], equals('1.0.0'));
    });
  });
}
