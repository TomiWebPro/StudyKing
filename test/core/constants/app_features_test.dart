import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/app_features.dart';

void main() {
  group('AppFeature', () {
    test('has all feature values', () {
      expect(AppFeature.values.length, 4);
      expect(AppFeature.analytics, AppFeature.analytics);
      expect(AppFeature.crashReporting, AppFeature.crashReporting);
      expect(AppFeature.betaFeatures, AppFeature.betaFeatures);
      expect(AppFeature.performanceOptimization, AppFeature.performanceOptimization);
    });
  });

  group('FeatureFlagService', () {
    test('uses defaults when no overrides', () {
      final service = FeatureFlagService();
      expect(service.isEnabled(AppFeature.analytics), isFalse);
      expect(service.isEnabled(AppFeature.crashReporting), isFalse);
      expect(service.isEnabled(AppFeature.betaFeatures), isFalse);
      expect(service.isEnabled(AppFeature.performanceOptimization), isTrue);
    });

    test('uses overrides when provided', () {
      final service = FeatureFlagService(overrides: {
        AppFeature.analytics: true,
        AppFeature.betaFeatures: true,
      });
      expect(service.isEnabled(AppFeature.analytics), isTrue);
      expect(service.isEnabled(AppFeature.betaFeatures), isTrue);
      expect(service.isEnabled(AppFeature.performanceOptimization), isTrue);
      expect(service.isEnabled(AppFeature.crashReporting), isFalse);
    });

    test('handles empty overrides map', () {
      final service = FeatureFlagService(overrides: {});
      expect(service.isEnabled(AppFeature.analytics), isFalse);
      expect(service.isEnabled(AppFeature.performanceOptimization), isTrue);
    });

    test('overrides map cannot be modified externally', () {
      final overrides = <AppFeature, bool>{AppFeature.analytics: true};
      final service = FeatureFlagService(overrides: overrides);
      expect(service.isEnabled(AppFeature.analytics), isTrue);
      overrides[AppFeature.analytics] = false;
      expect(service.isEnabled(AppFeature.analytics), isTrue);
    });
  });
}
