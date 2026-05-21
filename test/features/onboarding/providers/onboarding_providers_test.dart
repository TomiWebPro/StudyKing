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
  group('onboardingServiceProvider', () {
    test('creates an OnboardingService', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      final service = container.read(onboardingServiceProvider);
      expect(service, isA<OnboardingService>());
    });

    test('returns the same instance across reads (singleton)', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      final service1 = container.read(onboardingServiceProvider);
      final service2 = container.read(onboardingServiceProvider);
      expect(identical(service1, service2), isTrue);
    });

    test('injected override is used by providers', () async {
      final storage = InMemoryOnboardingStorage();
      final service = OnboardingService(storage: storage);
      final container = ProviderContainer(
        overrides: [
          onboardingServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(() => container.dispose());
      final readService = container.read(onboardingServiceProvider);
      expect(identical(readService, service), isTrue);
      final result = await container.read(onboardingNeededProvider.future);
      expect(result, isTrue);
    });
  });

  group('onboardingNeededProvider', () {
    late OnboardingService service;

    setUp(() {
      service = OnboardingService(storage: InMemoryOnboardingStorage());
    });

    test('returns true when onboarding is needed', () async {
      final container = ProviderContainer(
        overrides: [
          onboardingServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(() => container.dispose());
      final result = await container.read(onboardingNeededProvider.future);
      expect(result, isTrue);
    });

    test('returns false when onboarding is completed', () async {
      await service.markCompleted();
      final container = ProviderContainer(
        overrides: [
          onboardingServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(() => container.dispose());
      final result = await container.read(onboardingNeededProvider.future);
      expect(result, isFalse);
    });

    test('returns false when dontShowAgain is set', () async {
      await service.markDontShowAgain();
      final container = ProviderContainer(
        overrides: [
          onboardingServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(() => container.dispose());
      final result = await container.read(onboardingNeededProvider.future);
      expect(result, isFalse);
    });

    test('returns false when both completed and dontShowAgain are set', () async {
      await service.markCompleted();
      await service.markDontShowAgain();
      final container = ProviderContainer(
        overrides: [
          onboardingServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(() => container.dispose());
      final result = await container.read(onboardingNeededProvider.future);
      expect(result, isFalse);
    });

    test('returns true when storage throws (safe default)', () async {
      final throwingService = OnboardingService(
        storage: _ThrowingOnboardingStorage(),
      );
      final container = ProviderContainer(
        overrides: [
          onboardingServiceProvider.overrideWithValue(throwingService),
        ],
      );
      addTearDown(() => container.dispose());
      final result = await container.read(onboardingNeededProvider.future);
      expect(result, isTrue);
    });

    test('returns true again after resetOnboarding', () async {
      await service.markCompleted();
      await service.resetOnboarding();
      final container = ProviderContainer(
        overrides: [
          onboardingServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(() => container.dispose());
      final result = await container.read(onboardingNeededProvider.future);
      expect(result, isTrue);
    });
  });

  group('isFirstLaunchProvider', () {
    late OnboardingService service;

    setUp(() {
      service = OnboardingService(storage: InMemoryOnboardingStorage());
    });

    test('returns true when not completed', () async {
      final container = ProviderContainer(
        overrides: [
          onboardingServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(() => container.dispose());
      final result = await container.read(isFirstLaunchProvider.future);
      expect(result, isTrue);
    });

    test('returns false after markCompleted', () async {
      await service.markCompleted();
      final container = ProviderContainer(
        overrides: [
          onboardingServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(() => container.dispose());
      final result = await container.read(isFirstLaunchProvider.future);
      expect(result, isFalse);
    });

    test('returns true when dontShowAgain is set but completed is false', () async {
      await service.markDontShowAgain();
      final container = ProviderContainer(
        overrides: [
          onboardingServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(() => container.dispose());
      final result = await container.read(isFirstLaunchProvider.future);
      expect(result, isTrue);
    });

    test('returns false when dontShowAgain and completed are both set', () async {
      await service.markCompleted();
      await service.markDontShowAgain();
      final container = ProviderContainer(
        overrides: [
          onboardingServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(() => container.dispose());
      final result = await container.read(isFirstLaunchProvider.future);
      expect(result, isFalse);
    });

    test('returns true when storage throws (safe default)', () async {
      final throwingService = OnboardingService(
        storage: _ThrowingOnboardingStorage(),
      );
      final container = ProviderContainer(
        overrides: [
          onboardingServiceProvider.overrideWithValue(throwingService),
        ],
      );
      addTearDown(() => container.dispose());
      final result = await container.read(isFirstLaunchProvider.future);
      expect(result, isTrue);
    });

    test('returns true again after resetOnboarding', () async {
      await service.markCompleted();
      await service.resetOnboarding();
      final container = ProviderContainer(
        overrides: [
          onboardingServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(() => container.dispose());
      final result = await container.read(isFirstLaunchProvider.future);
      expect(result, isTrue);
    });
  });
}
