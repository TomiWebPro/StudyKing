import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/onboarding/services/onboarding_service.dart';

void main() {
  late Map<String, dynamic> storage;

  setUp(() {
    storage = <String, dynamic>{};
    OnboardingService.setTestStorage(storage);
  });

  tearDown(() {
    OnboardingService.setTestStorage(null);
  });

  group('OnboardingService', () {
    test('isOnboardingNeeded returns true when no values set', () async {
      final needed = await OnboardingService.isOnboardingNeeded();
      expect(needed, isTrue);
    });

    test('isOnboardingNeeded returns false after markCompleted', () async {
      await OnboardingService.markCompleted();
      final needed = await OnboardingService.isOnboardingNeeded();
      expect(needed, isFalse);
    });

    test('isOnboardingNeeded returns false after markDontShowAgain', () async {
      await OnboardingService.markDontShowAgain();
      final needed = await OnboardingService.isOnboardingNeeded();
      expect(needed, isFalse);
    });

    test('markCompleted persists the completion flag', () async {
      await OnboardingService.markCompleted();
      expect(storage['onboarding_completed'], isTrue);
    });

    test('markDontShowAgain persists the dont-show flag', () async {
      await OnboardingService.markDontShowAgain();
      expect(storage['onboarding_dont_show_again'], isTrue);
    });

    test('isFirstLaunch returns true when onboarding not yet completed', () async {
      final firstLaunch = await OnboardingService.isFirstLaunch();
      expect(firstLaunch, isTrue);
    });

    test('isFirstLaunch returns false after markCompleted', () async {
      await OnboardingService.markCompleted();
      final firstLaunch = await OnboardingService.isFirstLaunch();
      expect(firstLaunch, isFalse);
    });

    test('isFirstLaunch returns true after markDontShowAgain', () async {
      await OnboardingService.markDontShowAgain();
      final firstLaunch = await OnboardingService.isFirstLaunch();
      expect(firstLaunch, isTrue);
    });

    test('isOnboardingNeeded returns false when both flags are true', () async {
      await OnboardingService.markCompleted();
      await OnboardingService.markDontShowAgain();
      final needed = await OnboardingService.isOnboardingNeeded();
      expect(needed, isFalse);
    });

    test('flags are independent', () async {
      await OnboardingService.markCompleted();
      expect(storage['onboarding_completed'], isTrue);
      expect(storage['onboarding_dont_show_again'], isNull);

      storage.clear();
      await OnboardingService.markDontShowAgain();
      expect(storage['onboarding_completed'], isNull);
      expect(storage['onboarding_dont_show_again'], isTrue);
    });

    test('handles storage errors gracefully', () async {
      OnboardingService.setTestStorage(null);
      await expectLater(
        OnboardingService.markCompleted(),
        throwsException,
      );
    });

    test('recovers after storage error', () async {
      OnboardingService.setTestStorage(null);
      await expectLater(
        OnboardingService.markCompleted(),
        throwsException,
      );

      final recovered = <String, dynamic>{};
      OnboardingService.setTestStorage(recovered);
      await OnboardingService.markCompleted();
      expect(recovered['onboarding_completed'], isTrue);
    });
  });
}
