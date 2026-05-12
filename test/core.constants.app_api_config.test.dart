import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/app_api_config.dart';
import 'package:studyking/core/constants/app_build_config.dart';

void main() {
  group('ApiSecrets', () {
    test('creates with all keys', () {
      final secrets = const ApiSecrets(
        openRouterApiKey: 'test-key',
        googleApiKey: 'google-key',
        whisperApiKey: 'whisper-key',
      );
      expect(secrets.openRouterApiKey, 'test-key');
      expect(secrets.googleApiKey, 'google-key');
      expect(secrets.whisperApiKey, 'whisper-key');
    });

    test('creates with nullable keys', () {
      final secrets = const ApiSecrets(
        openRouterApiKey: 'test-key',
        googleApiKey: null,
        whisperApiKey: null,
      );
      expect(secrets.googleApiKey, isNull);
      expect(secrets.whisperApiKey, isNull);
    });

    group('fromRuntime', () {
      test('creates secrets from runtime values', () {
        final secrets = ApiSecrets.fromRuntime(
          openRouterApiKey: 'runtime-key',
          googleApiKey: 'google-key',
        );
        expect(secrets.openRouterApiKey, 'runtime-key');
        expect(secrets.googleApiKey, 'google-key');
      });

      test('sets optional keys to null when not provided', () {
        final secrets = ApiSecrets.fromRuntime(
          openRouterApiKey: 'runtime-key',
        );
        expect(secrets.googleApiKey, isNull);
        expect(secrets.whisperApiKey, isNull);
      });

      test('throws in production with empty key', () {
        expect(
          () => ApiSecrets.fromRuntime(openRouterApiKey: ''),
          isNot(throwsA(anything)),
        );
      });
    });

    group('fromEnvironment', () {
      test('creates secrets from environment with defaults in test mode', () {
        final secrets = ApiSecrets.fromEnvironment();
        expect(secrets.openRouterApiKey, isEmpty);
        expect(secrets.googleApiKey, isNull);
        expect(secrets.whisperApiKey, isNull);
      });
    });
  });

  group('ApiConfig', () {
    group('forEnvironment', () {
      test('creates config for production', () {
        final config = ApiConfig.forEnvironment(AppEnvironment.production);
        expect(config.openRouterRequestTimeout, const Duration(seconds: 45));
        expect(config.youtubeRequestTimeout, const Duration(seconds: 30));
        expect(config.openRouterBaseUrl.toString(), 'https://openrouter.ai/api/v1');
      });

      test('creates config for staging', () {
        final config = ApiConfig.forEnvironment(AppEnvironment.staging);
        expect(config.openRouterRequestTimeout, const Duration(seconds: 90));
        expect(config.youtubeRequestTimeout, const Duration(seconds: 30));
      });

      test('creates config for development', () {
        final config = ApiConfig.forEnvironment(AppEnvironment.development);
        expect(config.openRouterRequestTimeout, const Duration(seconds: 60));
        expect(config.youtubeRequestTimeout, const Duration(seconds: 20));
      });
    });
  });
}
