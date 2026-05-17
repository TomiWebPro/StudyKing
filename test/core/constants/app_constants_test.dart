import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';

void main() {
  group('BuildConfig', () {
    test('has meaningful values', () {
      expect(BuildConfig.appName, isNotEmpty);
      expect(BuildConfig.appVersion, isNotEmpty);
    });
  });

  group('ApiConfig', () {
    test('has valid base URL', () {
      expect(ApiConfig.openRouterBaseUrlString, startsWith('http'));
    });
  });

  group('CacheConfig', () {
    test('cache expiration is positive', () {
      expect(CacheConfig.cacheExpiration.inHours, greaterThan(0));
    });
  });

  group('defaultModelForProvider', () {
    test('returns non-empty model for every provider', () {
      for (final provider in LlmProvider.values) {
        expect(defaultModelForProvider(provider), isNotEmpty);
      }
    });
  });
}
