import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/app_runtime_config.dart';
import 'package:studyking/core/constants/app_build_config.dart';
import 'package:studyking/core/constants/app_features.dart';
import 'package:studyking/core/constants/app_api_config.dart';

void main() {
  group('StudyConfig', () {
    test('has correct default values', () {
      expect(StudyConfig.defaultQuestionsPerSession, 10);
      expect(StudyConfig.maxQuestionsPerSession, 50);
      expect(StudyConfig.minScoreForMastery, 80);
      expect(StudyConfig.maxRetryAttempts, 3);
      expect(StudyConfig.defaultStudySessionDuration, const Duration(minutes: 45));
      expect(StudyConfig.defaultBreakDuration, const Duration(minutes: 10));
      expect(StudyConfig.maxDailyStudyHours, 8);
    });
  });

  group('UiConfig', () {
    test('has correct default values', () {
      expect(UiConfig.defaultThemeMode.name, 'system');
      expect(UiConfig.defaultNotificationsEnabled, isTrue);
      expect(UiConfig.notificationReminderLeadTime, const Duration(minutes: 10));
      expect(UiConfig.notificationChannelId, 'study_reminders');
      expect(UiConfig.notificationChannelName, 'Study Reminders');
    });
  });

  group('PdfConfig', () {
    test('has correct constant values', () {
      expect(PdfConfig.maxPdfPagesForSingleLoad, 50);
      expect(PdfConfig.minChunkSizeBytes, 1024);
      expect(PdfConfig.maxChunkSizeBytes, 128 * 1024);
      expect(PdfConfig.defaultChunkSizeBytes, 10 * 1024);
      expect(PdfConfig.minChunkOverlapBytes, 0);
      expect(PdfConfig.maxChunkOverlapBytes, 8 * 1024);
      expect(PdfConfig.defaultChunkOverlapBytes, 500);
    });

    group('adaptiveChunkSize', () {
      test('returns small chunk for small documents', () {
        expect(PdfConfig.adaptiveChunkSize(documentSizeBytes: 100 * 1024), 4 * 1024);
      });

      test('returns medium chunk for medium documents', () {
        expect(PdfConfig.adaptiveChunkSize(documentSizeBytes: 1 * 1024 * 1024), 8 * 1024);
      });

      test('returns large chunk for large documents', () {
        expect(PdfConfig.adaptiveChunkSize(documentSizeBytes: 5 * 1024 * 1024), 12 * 1024);
      });

      test('returns max chunk for very large documents', () {
        expect(PdfConfig.adaptiveChunkSize(documentSizeBytes: 10 * 1024 * 1024), 16 * 1024);
      });

      test('returns min chunk for zero-size document', () {
        expect(PdfConfig.adaptiveChunkSize(documentSizeBytes: 0), 4 * 1024);
      });

      test('returns min chunk for negative size', () {
        expect(PdfConfig.adaptiveChunkSize(documentSizeBytes: -1), 4 * 1024);
      });
    });

    group('validatedChunkSize', () {
      test('clamps to min', () {
        expect(PdfConfig.validatedChunkSize(500), PdfConfig.minChunkSizeBytes);
      });

      test('clamps to max', () {
        expect(PdfConfig.validatedChunkSize(200 * 1024), PdfConfig.maxChunkSizeBytes);
      });

      test('returns value when in range', () {
        expect(PdfConfig.validatedChunkSize(5 * 1024), 5 * 1024);
      });

      test('returns value at exact min boundary', () {
        expect(PdfConfig.validatedChunkSize(PdfConfig.minChunkSizeBytes), PdfConfig.minChunkSizeBytes);
      });

      test('returns value at exact max boundary', () {
        expect(PdfConfig.validatedChunkSize(PdfConfig.maxChunkSizeBytes), PdfConfig.maxChunkSizeBytes);
      });

      test('clamps negative values to min', () {
        expect(PdfConfig.validatedChunkSize(-100), PdfConfig.minChunkSizeBytes);
      });
    });

    group('validatedChunkOverlap', () {
      test('clamps to min', () {
        expect(PdfConfig.validatedChunkOverlap(-1, chunkSize: 4096), 0);
      });

      test('clamps negative large value to min', () {
        expect(PdfConfig.validatedChunkOverlap(-9999, chunkSize: 4096), 0);
      });

      test('clamps to max allowed by chunk size', () {
        final result = PdfConfig.validatedChunkOverlap(2000, chunkSize: 4096);
        expect(result, 4096 ~/ 4);
      });

      test('returns value when in valid range', () {
        expect(PdfConfig.validatedChunkOverlap(500, chunkSize: 8192), 500);
      });

      test('clamps to maxChunkOverlapBytes when chunkSize allows larger', () {
        final result = PdfConfig.validatedChunkOverlap(10000, chunkSize: 64000);
        expect(result, PdfConfig.maxChunkOverlapBytes);
      });

      test('normalizes chunkSize before computing max allowed overlap', () {
        final result = PdfConfig.validatedChunkOverlap(500, chunkSize: -10);
        expect(result, PdfConfig.minChunkSizeBytes ~/ 4);
      });

      test('returns value at exact overlap boundary', () {
        expect(PdfConfig.validatedChunkOverlap(0, chunkSize: 4096), 0);
      });

      test('returns maxAllowedOverlap when bounded equals maxAllowed', () {
        final result = PdfConfig.validatedChunkOverlap(1024, chunkSize: 4096);
        expect(result, 1024);
      });

      test('clamps to maxChunkOverlapBytes when both limits apply', () {
        final result = PdfConfig.validatedChunkOverlap(10000, chunkSize: 64000);
        expect(result, PdfConfig.maxChunkOverlapBytes);
      });
    });

    group('adaptiveChunkSize boundaries', () {
      test('returns small chunk at exactly 256KB', () {
        expect(
          PdfConfig.adaptiveChunkSize(documentSizeBytes: 256 * 1024),
          4 * 1024,
        );
      });

      test('returns medium chunk at exactly 2MB', () {
        expect(
          PdfConfig.adaptiveChunkSize(documentSizeBytes: 2 * 1024 * 1024),
          8 * 1024,
        );
      });

      test('returns large chunk at exactly 8MB', () {
        expect(
          PdfConfig.adaptiveChunkSize(documentSizeBytes: 8 * 1024 * 1024),
          12 * 1024,
        );
      });

      test('returns max chunk just above 8MB', () {
        expect(
          PdfConfig.adaptiveChunkSize(documentSizeBytes: 8 * 1024 * 1024 + 1),
          16 * 1024,
        );
      });

      test('transitions from small to medium at 256KB+1', () {
        expect(
          PdfConfig.adaptiveChunkSize(documentSizeBytes: 256 * 1024 + 1),
          8 * 1024,
        );
      });

      test('transitions from medium to large at 2MB+1', () {
        expect(
          PdfConfig.adaptiveChunkSize(documentSizeBytes: 2 * 1024 * 1024 + 1),
          12 * 1024,
        );
      });
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

  group('ErrorKeys', () {
    test('has correct error key constants', () {
      expect(ErrorKeys.unexpected, 'error.unexpected');
      expect(ErrorKeys.networkConnectionFailed, 'error.network.connection_failed');
      expect(ErrorKeys.authenticationFailed, 'error.auth.failed');
    });
  });

  group('MediaConfig', () {
    test('has correct default', () {
      expect(MediaConfig.defaultImageCompressionQuality, 80);
    });

    group('validatedImageCompressionQuality', () {
      test('clamps to 0 for negative values', () {
        expect(MediaConfig.validatedImageCompressionQuality(-10), 0);
      });

      test('clamps to 100 for values above 100', () {
        expect(MediaConfig.validatedImageCompressionQuality(150), 100);
      });

      test('returns value when in range', () {
        expect(MediaConfig.validatedImageCompressionQuality(75), 75);
        expect(MediaConfig.validatedImageCompressionQuality(0), 0);
        expect(MediaConfig.validatedImageCompressionQuality(100), 100);
      });

      test('returns 50 for mid-range value', () {
        expect(MediaConfig.validatedImageCompressionQuality(50), 50);
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
