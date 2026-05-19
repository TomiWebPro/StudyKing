import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/onboarding/data/models/onboarding_state.dart';

void main() {
  group('OnboardingState', () {
    test('default constructor sets both flags to false', () {
      final state = const OnboardingState();
      expect(state.completed, isFalse);
      expect(state.dontShowAgain, isFalse);
    });

    test('isNeeded returns true when both flags are false', () {
      const state = OnboardingState();
      expect(state.isNeeded, isTrue);
    });

    test('isNeeded returns false when completed is true', () {
      const state = OnboardingState(completed: true);
      expect(state.isNeeded, isFalse);
    });

    test('isNeeded returns false when dontShowAgain is true', () {
      const state = OnboardingState(dontShowAgain: true);
      expect(state.isNeeded, isFalse);
    });

    test('isFirstLaunch returns true when not completed', () {
      const state = OnboardingState();
      expect(state.isFirstLaunch, isTrue);
    });

    test('isFirstLaunch returns false when completed', () {
      const state = OnboardingState(completed: true);
      expect(state.isFirstLaunch, isFalse);
    });

    test('copyWith updates completed flag', () {
      const state = OnboardingState();
      final updated = state.copyWith(completed: true);
      expect(updated.completed, isTrue);
      expect(updated.dontShowAgain, isFalse);
    });

    test('copyWith updates dontShowAgain flag', () {
      const state = OnboardingState();
      final updated = state.copyWith(dontShowAgain: true);
      expect(updated.completed, isFalse);
      expect(updated.dontShowAgain, isTrue);
    });

    test('toJson serializes correctly', () {
      const state = OnboardingState(completed: true, dontShowAgain: false);
      final json = state.toJson();
      expect(json['completed'], isTrue);
      expect(json['dontShowAgain'], isFalse);
    });

    test('fromJson deserializes correctly', () {
      final state = OnboardingState.fromJson({
        'completed': true,
        'dontShowAgain': false,
      });
      expect(state.completed, isTrue);
      expect(state.dontShowAgain, isFalse);
    });

    test('fromJson defaults to false when keys are missing', () {
      final state = OnboardingState.fromJson({});
      expect(state.completed, isFalse);
      expect(state.dontShowAgain, isFalse);
    });

    test('round-trip toJson/fromJson preserves state', () {
      const original = OnboardingState(completed: true, dontShowAgain: true);
      final json = original.toJson();
      final restored = OnboardingState.fromJson(json);
      expect(restored.completed, original.completed);
      expect(restored.dontShowAgain, original.dontShowAgain);
    });
  });
}
