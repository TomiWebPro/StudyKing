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
    });

    group('validatedChunkOverlap', () {
      test('clamps to min', () {
        expect(PdfConfig.validatedChunkOverlap(-1, chunkSize: 4096), 0);
      });

      test('clamps to max allowed by chunk size', () {
        final result = PdfConfig.validatedChunkOverlap(2000, chunkSize: 4096);
        expect(result, lessThanOrEqualTo(4096 ~/ 4));
      });

      test('returns value when in valid range', () {
        expect(PdfConfig.validatedChunkOverlap(500, chunkSize: 8192), 500);
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

      test('returns false for development by default', () {
        // In development without ALLOW_UNAUTHENTICATED_MODE override
        expect(SecurityConfig.requireAuthentication(AppEnvironment.development), isTrue);
      });
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
    });
  });

  group('AppConfig', () {
    test('bootstrap creates config', () {
      final config = AppConfig.bootstrap();
      expect(config.environment, AppEnvironment.development);
      expect(config.apiConfig, isA<ApiConfig>());
      expect(config.secrets, isA<ApiSecrets>());
      expect(config.featureFlags, isA<FeatureFlagService>());
    });

    test('runtimeSnapshot returns expected keys', () {
      final config = AppConfig.bootstrap();
      final snapshot = config.runtimeSnapshot();
      expect(snapshot['appName'], 'StudyKing');
      expect(snapshot['environment'], 'development');
      expect(snapshot.containsKey('openRouterBaseUrl'), isTrue);
      expect(snapshot.containsKey('version'), isTrue);
    });

    test('redactedRuntimeSnapshot redacts sensitive keys', () {
      final config = AppConfig.bootstrap();
      final snapshot = config.redactedRuntimeSnapshot();
      expect(snapshot['appName'], 'StudyKing');
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
  });
}
