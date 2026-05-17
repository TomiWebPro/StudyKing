import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/onboarding/services/onboarding_service.dart';

void main() {
  group('OnboardingService', () {
    setUp(() {
      OnboardingService.setTestStorage({});
    });

    tearDown(() {
      OnboardingService.setTestStorage(null);
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

    group('Hive-backed caching', () {
      test('uses testStorage when set instead of Hive', () async {
        OnboardingService.setTestStorage({'onboarding_completed': false});
        expect(await OnboardingService.isOnboardingNeeded(), isTrue);
      });

      test('testStorage is isolated between calls', () async {
        OnboardingService.setTestStorage({'onboarding_completed': false});
        await OnboardingService.markCompleted();
        expect(await OnboardingService.isOnboardingNeeded(), isFalse);
      });
    });
  });
}
