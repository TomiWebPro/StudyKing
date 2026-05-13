import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/app_runtime_config.dart';
import 'package:studyking/core/constants/app_build_config.dart';
import 'package:studyking/core/constants/app_features.dart';
import 'package:studyking/core/constants/app_api_config.dart';
import 'package:studyking/core/constants/app_config.dart';
import 'package:studyking/core/constants/security_config.dart';

void main() {
  group('UiConfig', () {
    test('has correct default values', () {
      expect(UiConfig.defaultThemeMode.name, 'system');
      expect(UiConfig.defaultNotificationsEnabled, isTrue);
      expect(UiConfig.notificationReminderLeadTime, const Duration(minutes: 10));
      expect(UiConfig.notificationChannelId, 'study_reminders');
      expect(UiConfig.notificationChannelName, 'Study Reminders');
    });
  });

  group('CacheConfig', () {
    test('has correct values', () {
      expect(CacheConfig.cacheExpiration, const Duration(hours: 24));
      expect(CacheConfig.maxCacheSizeMb, 100);
      expect(CacheConfig.databaseCacheSizeMb, 100);
    });
  });

  group('SecurityConfig', () {
    test('session timeout is 30 minutes', () {
      expect(SecurityConfig.sessionTimeout, const Duration(minutes: 30));
    });

    group('requireAuthentication', () {
      test('requires auth for production', () {
        expect(SecurityConfig.requireAuthentication(AppEnvironment.production), isTrue);
      });

      test('returns true for development by default', () {
        expect(SecurityConfig.requireAuthentication(AppEnvironment.development), isTrue);
      });

      test('returns true for staging by default', () {
        expect(SecurityConfig.requireAuthentication(AppEnvironment.staging), isTrue);
      });
    });

    group('encryptionKeyOrThrow', () {
      test('throws StateError when STUDYKING_ENCRYPTION_KEY is not set', () {
        expect(
          () => SecurityConfig.encryptionKeyOrThrow(),
          throwsA(isA<StateError>()),
        );
      });

      test('error message mentions STUDYKING_ENCRYPTION_KEY', () {
        try {
          SecurityConfig.encryptionKeyOrThrow();
        } catch (e) {
          expect((e as StateError).message, contains('STUDYKING_ENCRYPTION_KEY'));
        }
      });
    });

    group('enforceStartupGuards', () {
      test('completes without error in test environment', () {
        expect(() => SecurityConfig.enforceStartupGuards(), returnsNormally);
      });
    });
  });

  group('AppConfig', () {
    tearDown(() {
      AppConstants.resetForTesting();
    });

    group('direct construction', () {
      test('constructs with explicit parameters', () {
        final secrets = ApiSecrets.fromRuntime(openRouterApiKey: 'test-key');
        final apiConfig = ApiConfig.forEnvironment(AppEnvironment.development);
        final featureFlags = FeatureFlagService();
        final config = AppConfig(
          environment: AppEnvironment.staging,
          apiConfig: apiConfig,
          secrets: secrets,
          featureFlags: featureFlags,
        );
        expect(config.environment, AppEnvironment.staging);
        expect(config.apiConfig, apiConfig);
        expect(config.secrets, secrets);
        expect(config.featureFlags, featureFlags);
      });
    });

    group('bootstrap', () {
      test('bootstrap creates config with development environment by default', () {
        final config = AppConfig.bootstrap();
        expect(config.environment, AppEnvironment.development);
        expect(config.apiConfig, isA<ApiConfig>());
        expect(config.secrets, isA<ApiSecrets>());
        expect(config.featureFlags, isA<FeatureFlagService>());
      });

      test('bootstrap accepts feature overrides', () {
        final config = AppConfig.bootstrap(featureOverrides: {
          AppFeature.analytics: true,
        });
        expect(config.featureFlags.isEnabled(AppFeature.analytics), isTrue);
        expect(config.featureFlags.isEnabled(AppFeature.crashReporting), isFalse);
      });

      test('bootstrap applies empty feature overrides', () {
        final config = AppConfig.bootstrap(featureOverrides: {});
        expect(config.featureFlags.isEnabled(AppFeature.performanceOptimization), isTrue);
      });
    });

    group('runtimeSnapshot', () {
      test('returns expected keys and values', () {
        final config = AppConfig.bootstrap();
        final snapshot = config.runtimeSnapshot();
        expect(snapshot['appName'], 'StudyKing');
        expect(snapshot['version'], isA<String>());
        expect(snapshot['build'], isA<String>());
        expect(snapshot['environment'], 'development');
        expect(snapshot['openRouterBaseUrl'], 'https://openrouter.ai/api/v1');
        expect(snapshot['openRouterTimeoutMs'], 60000);
        expect(snapshot['youtubeTimeoutMs'], 20000);
        expect(snapshot['defaultThemeMode'], 'system');
        expect(snapshot['cacheExpirationHours'], 24);
        expect(snapshot['performanceOptimization'], isTrue);
        expect(snapshot['requireAuthentication'], isTrue);
      });

      test('returns all 11 keys', () {
        final config = AppConfig.bootstrap();
        expect(config.runtimeSnapshot().length, 11);
      });

      test('all values are non-null in default config', () {
        final config = AppConfig.bootstrap();
        final snapshot = config.runtimeSnapshot();
        for (final entry in snapshot.entries) {
          expect(
            entry.value,
            isNotNull,
            reason: 'Key ${entry.key} should not be null',
          );
        }
      });
    });

    group('redactedRuntimeSnapshot', () {
      test('returns non-sensitive keys unchanged', () {
        final config = AppConfig.bootstrap();
        final snapshot = config.redactedRuntimeSnapshot();
        expect(snapshot['appName'], 'StudyKing');
        expect(snapshot['version'], '1.0.0');
        expect(snapshot['environment'], 'development');
      });

      test('is a Map with the same keys as runtimeSnapshot', () {
        final config = AppConfig.bootstrap();
        final runtime = config.runtimeSnapshot();
        final redacted = config.redactedRuntimeSnapshot();
        expect(redacted.keys, unorderedEquals(runtime.keys));
      });

      test('redacted snapshot values match runtime snapshot for non-sensitive keys', () {
        final config = AppConfig.bootstrap();
        final runtime = config.runtimeSnapshot();
        final redacted = config.redactedRuntimeSnapshot();
        expect(redacted['appName'], runtime['appName']);
        expect(redacted['version'], runtime['version']);
        expect(redacted['environment'], runtime['environment']);
        expect(redacted['performanceOptimization'], runtime['performanceOptimization']);
      });

      test('redacted snapshot equals runtime snapshot when no sensitive keys present', () {
        final config = AppConfig.bootstrap();
        final runtime = config.runtimeSnapshot();
        final redacted = config.redactedRuntimeSnapshot();
        expect(runtime, redacted);
      });

      group('redactSensitiveValues', () {
        test('redacts keys matching secret/token/password/key patterns', () {
          final data = <String, Object?>{
            'apiKey': 'super-secret',
            'authToken': 'abc123',
            'userPassword': 'p@ss',
            'clientSecret': 'shhh',
            'safeField': 'visible',
          };
          final redacted = AppConfig.redactSensitiveValues(data);
          expect(redacted['apiKey'], '<redacted>');
          expect(redacted['authToken'], '<redacted>');
          expect(redacted['userPassword'], '<redacted>');
          expect(redacted['clientSecret'], '<redacted>');
          expect(redacted['safeField'], 'visible');
        });

        test('redacts sensitive keys even with null values', () {
          final data = <String, Object?>{
            'apiKey': null,
            'name': 'test',
          };
          final redacted = AppConfig.redactSensitiveValues(data);
          expect(redacted['apiKey'], '<redacted>');
          expect(redacted['name'], 'test');
        });

        test('handles empty map', () {
          expect(AppConfig.redactSensitiveValues({}), isEmpty);
        });

        test('is case insensitive for key matching', () {
          final data = <String, Object?>{
            'APIKEY': 'value1',
            'Api_Secret': 'value2',
            'TOKEN': 'value3',
          };
          final redacted = AppConfig.redactSensitiveValues(data);
          expect(redacted['APIKEY'], '<redacted>');
          expect(redacted['Api_Secret'], '<redacted>');
          expect(redacted['TOKEN'], '<redacted>');
        });
      });
    });

    group('debugLogSnapshot', () {
      test('does not throw', () {
        final config = AppConfig.bootstrap();
        expect(() => config.debugLogSnapshot(), returnsNormally);
      });
    });
  });

  group('AppConstants', () {
    tearDown(() {
      AppConstants.resetForTesting();
    });

    test('initialize creates singleton', () {
      final config = AppConstants.initialize();
      expect(config, isA<AppConfig>());
      expect(AppConstants.instance, same(config));
    });

    test('instance throws if not initialized', () {
      AppConstants.resetForTesting();
      expect(() => AppConstants.instance, throwsA(isA<StateError>()));
    });

    test('injectForTesting sets test config', () {
      final testConfig = AppConfig.bootstrap();
      AppConstants.injectForTesting(testConfig);
      expect(AppConstants.instance, same(testConfig));
    });

    test('resetForTesting clears the instance', () {
      AppConstants.initialize();
      AppConstants.resetForTesting();
      expect(() => AppConstants.instance, throwsA(isA<StateError>()));
    });

    test('initialize returns existing instance on second call', () {
      final first = AppConstants.initialize();
      final second = AppConstants.initialize();
      expect(first, same(second));
    });

    test('injectForTesting overrides existing instance', () {
      AppConstants.initialize();
      final newConfig = AppConfig.bootstrap(featureOverrides: {
        AppFeature.analytics: true,
      });
      AppConstants.injectForTesting(newConfig);
      expect(AppConstants.instance, same(newConfig));
    });
  });
}
