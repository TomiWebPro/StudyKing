import 'package:flutter_test/flutter_test.dart';

class _InMemoryOnboardingStore {
  static bool onboardingCompleted = false;
  static bool onboardingDontShowAgain = false;

  static void reset() {
    onboardingCompleted = false;
    onboardingDontShowAgain = false;
  }

  static Future<bool> isOnboardingNeeded() async {
    return !onboardingCompleted && !onboardingDontShowAgain;
  }

  static Future<void> markCompleted() async {
    onboardingCompleted = true;
  }

  static Future<void> markDontShowAgain() async {
    onboardingDontShowAgain = true;
  }

  static Future<bool> isFirstLaunch() async {
    return !onboardingCompleted;
  }
}

void main() {
  setUp(() async {
    _InMemoryOnboardingStore.reset();
  });

  group('OnboardingService (in-memory)', () {
    test('isOnboardingNeeded returns true when no values set', () async {
      final needed = await _InMemoryOnboardingStore.isOnboardingNeeded();
      expect(needed, isTrue);
    });

    test('isOnboardingNeeded returns false after markCompleted', () async {
      await _InMemoryOnboardingStore.markCompleted();
      final needed = await _InMemoryOnboardingStore.isOnboardingNeeded();
      expect(needed, isFalse);
    });

    test('isOnboardingNeeded returns false after markDontShowAgain', () async {
      await _InMemoryOnboardingStore.markDontShowAgain();
      final needed = await _InMemoryOnboardingStore.isOnboardingNeeded();
      expect(needed, isFalse);
    });

    test('markCompleted persists the completion flag', () async {
      await _InMemoryOnboardingStore.markCompleted();
      final needed = await _InMemoryOnboardingStore.isOnboardingNeeded();
      expect(needed, isFalse);
    });

    test('markDontShowAgain persists the dont-show flag', () async {
      await _InMemoryOnboardingStore.markDontShowAgain();
      final needed = await _InMemoryOnboardingStore.isOnboardingNeeded();
      expect(needed, isFalse);
    });

    test('isFirstLaunch returns true when onboarding not yet completed', () async {
      final firstLaunch = await _InMemoryOnboardingStore.isFirstLaunch();
      expect(firstLaunch, isTrue);
    });

    test('isFirstLaunch returns false after markCompleted', () async {
      await _InMemoryOnboardingStore.markCompleted();
      final firstLaunch = await _InMemoryOnboardingStore.isFirstLaunch();
      expect(firstLaunch, isFalse);
    });

    test('isOnboardingNeeded respects completed flag independently', () async {
      await _InMemoryOnboardingStore.markCompleted();
      final firstLaunch = await _InMemoryOnboardingStore.isFirstLaunch();
      expect(firstLaunch, isFalse);
    });

    test('isFirstLaunch returns true after markDontShowAgain', () async {
      await _InMemoryOnboardingStore.markDontShowAgain();
      final firstLaunch = await _InMemoryOnboardingStore.isFirstLaunch();
      expect(firstLaunch, isTrue);
    });

    test('isOnboardingNeeded returns true when both flags explicitly false', () async {
      final needed = await _InMemoryOnboardingStore.isOnboardingNeeded();
      expect(needed, isTrue);
    });

    test('isOnboardingNeeded returns false when only completed is true', () async {
      await _InMemoryOnboardingStore.markCompleted();
      final needed = await _InMemoryOnboardingStore.isOnboardingNeeded();
      expect(needed, isFalse);
    });

    test('isOnboardingNeeded returns false when only dontShowAgain is true', () async {
      await _InMemoryOnboardingStore.markDontShowAgain();
      final needed = await _InMemoryOnboardingStore.isOnboardingNeeded();
      expect(needed, isFalse);
    });

    test('isFirstLaunch returns true when only dontShowAgain is set', () async {
      await _InMemoryOnboardingStore.markDontShowAgain();
      final firstLaunch = await _InMemoryOnboardingStore.isFirstLaunch();
      expect(firstLaunch, isTrue);
    });

    test('isOnboardingNeeded returns false when both flags are true', () async {
      await _InMemoryOnboardingStore.markCompleted();
      await _InMemoryOnboardingStore.markDontShowAgain();
      final needed = await _InMemoryOnboardingStore.isOnboardingNeeded();
      expect(needed, isFalse);
    });

    test('isFirstLaunch returns false when completed is set', () async {
      await _InMemoryOnboardingStore.markCompleted();
      final firstLaunch = await _InMemoryOnboardingStore.isFirstLaunch();
      expect(firstLaunch, isFalse);
    });

    test('flags are independent', () async {
      await _InMemoryOnboardingStore.markCompleted();
      expect(_InMemoryOnboardingStore.onboardingCompleted, isTrue);
      expect(_InMemoryOnboardingStore.onboardingDontShowAgain, isFalse);

      _InMemoryOnboardingStore.reset();
      await _InMemoryOnboardingStore.markDontShowAgain();
      expect(_InMemoryOnboardingStore.onboardingCompleted, isFalse);
      expect(_InMemoryOnboardingStore.onboardingDontShowAgain, isTrue);
    });
  });
}
