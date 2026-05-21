import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/onboarding/services/onboarding_service.dart';
import 'package:studyking/features/onboarding/services/onboarding_storage.dart';

void main() {
  group('OnboardingService', () {
    late OnboardingService service;

    setUp(() {
      service = OnboardingService(storage: InMemoryOnboardingStorage());
    });

    group('isOnboardingNeeded', () {
      test('returns true when neither flag is set', () async {
        final result = await service.isOnboardingNeeded();
        expect(result.data, isTrue);
      });

      test('returns false when onboarding is completed', () async {
        await service.markCompleted();
        final result = await service.isOnboardingNeeded();
        expect(result.data, isFalse);
      });

      test('returns false when dontShowAgain is set', () async {
        await service.markDontShowAgain();
        final result = await service.isOnboardingNeeded();
        expect(result.data, isFalse);
      });
    });

    group('markCompleted', () {
      test('persists completed flag', () async {
        await service.markCompleted();
        final needed = await service.isOnboardingNeeded();
        expect(needed.data, isFalse);
        final firstLaunch = await service.isFirstLaunch();
        expect(firstLaunch.data, isFalse);
      });
    });

    group('markDontShowAgain', () {
      test('persists dontShowAgain flag', () async {
        await service.markDontShowAgain();
        final result = await service.isOnboardingNeeded();
        expect(result.data, isFalse);
      });
    });

    group('isFirstLaunch', () {
      test('returns true when no flags are set', () async {
        final result = await service.isFirstLaunch();
        expect(result.data, isTrue);
      });

      test('returns false after markCompleted', () async {
        await service.markCompleted();
        final result = await service.isFirstLaunch();
        expect(result.data, isFalse);
      });
    });

    group('InMemory storage', () {
      test('uses InMemoryOnboardingStorage when set', () async {
        final svc = OnboardingService(
          storage: InMemoryOnboardingStorage({
            OnboardingService.onboardingKey: false,
          }),
        );
        final result = await svc.isOnboardingNeeded();
        expect(result.data, isTrue);
      });

      test('storage is isolated between calls', () async {
        final svc = OnboardingService(
          storage: InMemoryOnboardingStorage({
            OnboardingService.onboardingKey: false,
          }),
        );
        await svc.markCompleted();
        final result = await svc.isOnboardingNeeded();
        expect(result.data, isFalse);
      });
    });

    group('error handling', () {
      test('isOnboardingNeeded returns true when storage is empty', () async {
        final svc = OnboardingService(
          storage: InMemoryOnboardingStorage(),
        );
        final result = await svc.isOnboardingNeeded();
        expect(result.data, isTrue);
      });

      test('isFirstLaunch returns true when storage is empty', () async {
        final svc = OnboardingService(
          storage: InMemoryOnboardingStorage(),
        );
        final result = await svc.isFirstLaunch();
        expect(result.data, isTrue);
      });

      test('markCompleted sets key regardless of prior state', () async {
        final svc = OnboardingService(
          storage: InMemoryOnboardingStorage({
            OnboardingService.onboardingKey: false,
          }),
        );
        await svc.markCompleted();
        final result = await svc.isFirstLaunch();
        expect(result.data, isFalse);
      });
    });

    group('error-state: storage throwing', () {
      test('getBool returns true on storage exception (fallback safe)', () async {
        final svc = OnboardingService(
          storage: _ThrowingOnboardingStorage(),
        );
        final result = await svc.isOnboardingNeeded();
        expect(result.data, isTrue);
      });

      test('setBool does not propagate storage exceptions', () async {
        final svc = OnboardingService(
          storage: _ThrowingOnboardingStorage(),
        );
        await svc.markCompleted();
        final result = await svc.isOnboardingNeeded();
        expect(result.data, isTrue);
      });
    });
  });
}

class _ThrowingOnboardingStorage implements OnboardingStorage {
  @override
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    throw Exception('Storage failure');
  }

  @override
  Future<void> setBool(String key, bool value) async {
    throw Exception('Storage failure');
  }
}
