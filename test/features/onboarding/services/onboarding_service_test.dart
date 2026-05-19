import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/onboarding/services/onboarding_service.dart';
import 'package:studyking/features/onboarding/services/onboarding_storage.dart';

void main() {
  group('OnboardingService', () {
    setUp(() {
      OnboardingService.setStorage(InMemoryOnboardingStorage());
    });

    tearDown(() {
      OnboardingService.setStorage(HiveOnboardingStorage());
    });

    group('isOnboardingNeeded', () {
      test('returns true when neither flag is set', () async {
        expect(await OnboardingService.isOnboardingNeeded(), isTrue);
      });

      test('returns false when onboarding is completed', () async {
        await OnboardingService.markCompleted();
        expect(await OnboardingService.isOnboardingNeeded(), isFalse);
      });

      test('returns false when dontShowAgain is set', () async {
        await OnboardingService.markDontShowAgain();
        expect(await OnboardingService.isOnboardingNeeded(), isFalse);
      });
    });

    group('markCompleted', () {
      test('persists completed flag', () async {
        await OnboardingService.markCompleted();
        expect(await OnboardingService.isOnboardingNeeded(), isFalse);
        expect(await OnboardingService.isFirstLaunch(), isFalse);
      });
    });

    group('markDontShowAgain', () {
      test('persists dontShowAgain flag', () async {
        await OnboardingService.markDontShowAgain();
        expect(await OnboardingService.isOnboardingNeeded(), isFalse);
      });
    });

    group('isFirstLaunch', () {
      test('returns true when no flags are set', () async {
        expect(await OnboardingService.isFirstLaunch(), isTrue);
      });

      test('returns false after markCompleted', () async {
        await OnboardingService.markCompleted();
        expect(await OnboardingService.isFirstLaunch(), isFalse);
      });
    });

    group('InMemory storage', () {
      test('uses InMemoryOnboardingStorage when set', () async {
        OnboardingService.setStorage(InMemoryOnboardingStorage({
          OnboardingService.onboardingKey: false,
        }));
        expect(await OnboardingService.isOnboardingNeeded(), isTrue);
      });

      test('storage is isolated between calls', () async {
        OnboardingService.setStorage(InMemoryOnboardingStorage({
          OnboardingService.onboardingKey: false,
        }));
        await OnboardingService.markCompleted();
        expect(await OnboardingService.isOnboardingNeeded(), isFalse);
      });
    });

    group('error handling', () {
      test('isOnboardingNeeded returns true when storage is empty', () async {
        OnboardingService.setStorage(InMemoryOnboardingStorage());
        expect(await OnboardingService.isOnboardingNeeded(), isTrue);
      });

      test('isFirstLaunch returns true when storage is empty', () async {
        OnboardingService.setStorage(InMemoryOnboardingStorage());
        expect(await OnboardingService.isFirstLaunch(), isTrue);
      });

      test('markCompleted sets key regardless of prior state', () async {
        OnboardingService.setStorage(InMemoryOnboardingStorage({
          OnboardingService.onboardingKey: false,
        }));
        await OnboardingService.markCompleted();
        expect(await OnboardingService.isFirstLaunch(), isFalse);
      });
    });

    group('error-state: storage throwing', () {
      test('getBool returns true on storage exception (fallback safe)', () async {
        OnboardingService.setStorage(_ThrowingOnboardingStorage());
        final result = await OnboardingService.isOnboardingNeeded();
        expect(result, isTrue);
      });

      test('setBool does not propagate storage exceptions', () async {
        OnboardingService.setStorage(_ThrowingOnboardingStorage());
        await OnboardingService.markCompleted();
        final result = await OnboardingService.isOnboardingNeeded();
        expect(result, isTrue);
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
