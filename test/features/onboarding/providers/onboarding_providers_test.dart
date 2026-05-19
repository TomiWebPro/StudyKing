import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/onboarding/providers/onboarding_providers.dart';
import 'package:studyking/features/onboarding/services/onboarding_service.dart';
import 'package:studyking/features/onboarding/services/onboarding_storage.dart';

class _ThrowingOnboardingStorage extends OnboardingStorage {
  @override
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    throw Exception('Storage failure');
  }

  @override
  Future<void> setBool(String key, bool value) async {
    throw Exception('Storage failure');
  }
}

void main() {
  group('onboardingNeededProvider', () {
    setUp(() {
      OnboardingService.setStorage(InMemoryOnboardingStorage());
    });

    tearDown(() {
      OnboardingService.setStorage(HiveOnboardingStorage());
    });

    test('returns true when onboarding is needed', () async {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      final result = await container.read(onboardingNeededProvider.future);
      expect(result, isTrue);
    });

    test('returns false when onboarding is completed', () async {
      await OnboardingService.markCompleted();
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      final result = await container.read(onboardingNeededProvider.future);
      expect(result, isFalse);
    });

    test('returns true when storage throws (safe default)', () async {
      OnboardingService.setStorage(_ThrowingOnboardingStorage());
      addTearDown(() => OnboardingService.setStorage(HiveOnboardingStorage()));

      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      final result = await container.read(onboardingNeededProvider.future);
      expect(result, isTrue);
    });
  });

  group('isFirstLaunchProvider', () {
    setUp(() {
      OnboardingService.setStorage(InMemoryOnboardingStorage());
    });

    tearDown(() {
      OnboardingService.setStorage(HiveOnboardingStorage());
    });

    test('returns true when not completed', () async {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      final result = await container.read(isFirstLaunchProvider.future);
      expect(result, isTrue);
    });

    test('returns false after markCompleted', () async {
      await OnboardingService.markCompleted();
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      final result = await container.read(isFirstLaunchProvider.future);
      expect(result, isFalse);
    });

    test('returns true when storage throws (safe default)', () async {
      OnboardingService.setStorage(_ThrowingOnboardingStorage());
      addTearDown(() => OnboardingService.setStorage(HiveOnboardingStorage()));

      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      final result = await container.read(isFirstLaunchProvider.future);
      expect(result, isTrue);
    });
  });
}
