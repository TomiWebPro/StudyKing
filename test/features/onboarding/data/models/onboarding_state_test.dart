import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/onboarding/data/models/onboarding_state.dart';

void main() {
  group('OnboardingState', () {
    group('constructor', () {
      test('default constructor sets both flags to false', () {
        final state = const OnboardingState();
        expect(state.completed, isFalse);
        expect(state.dontShowAgain, isFalse);
      });

      test('constructor sets completed to true', () {
        const state = OnboardingState(completed: true);
        expect(state.completed, isTrue);
        expect(state.dontShowAgain, isFalse);
      });

      test('constructor sets dontShowAgain to true', () {
        const state = OnboardingState(dontShowAgain: true);
        expect(state.completed, isFalse);
        expect(state.dontShowAgain, isTrue);
      });

      test('constructor sets both flags to true', () {
        const state = OnboardingState(completed: true, dontShowAgain: true);
        expect(state.completed, isTrue);
        expect(state.dontShowAgain, isTrue);
      });
    });

    group('isNeeded', () {
      test('returns true when both flags are false', () {
        const state = OnboardingState();
        expect(state.isNeeded, isTrue);
      });

      test('returns false when completed is true', () {
        const state = OnboardingState(completed: true);
        expect(state.isNeeded, isFalse);
      });

      test('returns false when dontShowAgain is true', () {
        const state = OnboardingState(dontShowAgain: true);
        expect(state.isNeeded, isFalse);
      });

      test('returns false when both flags are true', () {
        const state = OnboardingState(completed: true, dontShowAgain: true);
        expect(state.isNeeded, isFalse);
      });
    });

    group('isFirstLaunch', () {
      test('returns true when not completed', () {
        const state = OnboardingState();
        expect(state.isFirstLaunch, isTrue);
      });

      test('returns false when completed is true', () {
        const state = OnboardingState(completed: true);
        expect(state.isFirstLaunch, isFalse);
      });

      test('returns false when completed and dontShowAgain are true', () {
        const state = OnboardingState(completed: true, dontShowAgain: true);
        expect(state.isFirstLaunch, isFalse);
      });
    });

    group('copyWith', () {
      test('returns same values when no arguments given', () {
        const state = OnboardingState(completed: true, dontShowAgain: true);
        final updated = state.copyWith();
        expect(updated.completed, isTrue);
        expect(updated.dontShowAgain, isTrue);
      });

      test('updates completed flag', () {
        const state = OnboardingState();
        final updated = state.copyWith(completed: true);
        expect(updated.completed, isTrue);
        expect(updated.dontShowAgain, isFalse);
      });

      test('updates dontShowAgain flag', () {
        const state = OnboardingState();
        final updated = state.copyWith(dontShowAgain: true);
        expect(updated.completed, isFalse);
        expect(updated.dontShowAgain, isTrue);
      });

      test('updates both flags', () {
        const state = OnboardingState();
        final updated = state.copyWith(completed: true, dontShowAgain: true);
        expect(updated.completed, isTrue);
        expect(updated.dontShowAgain, isTrue);
      });

      test('preserves completed when dontShowAgain is updated', () {
        const state = OnboardingState(completed: true);
        final updated = state.copyWith(dontShowAgain: true);
        expect(updated.completed, isTrue);
        expect(updated.dontShowAgain, isTrue);
      });

      test('preserves dontShowAgain when completed is updated', () {
        const state = OnboardingState(dontShowAgain: true);
        final updated = state.copyWith(completed: true);
        expect(updated.completed, isTrue);
        expect(updated.dontShowAgain, isTrue);
      });
    });

    group('toJson', () {
      test('serializes default state', () {
        const state = OnboardingState();
        final json = state.toJson();
        expect(json['completed'], isFalse);
        expect(json['dontShowAgain'], isFalse);
      });

      test('serializes completed state', () {
        const state = OnboardingState(completed: true);
        final json = state.toJson();
        expect(json['completed'], isTrue);
        expect(json['dontShowAgain'], isFalse);
      });

      test('serializes dontShowAgain state', () {
        const state = OnboardingState(dontShowAgain: true);
        final json = state.toJson();
        expect(json['completed'], isFalse);
        expect(json['dontShowAgain'], isTrue);
      });

      test('serializes both flags true', () {
        const state = OnboardingState(completed: true, dontShowAgain: true);
        final json = state.toJson();
        expect(json['completed'], isTrue);
        expect(json['dontShowAgain'], isTrue);
      });
    });

    group('fromJson', () {
      test('deserializes completed state', () {
        final state = OnboardingState.fromJson({
          'completed': true,
          'dontShowAgain': false,
        });
        expect(state.completed, isTrue);
        expect(state.dontShowAgain, isFalse);
      });

      test('deserializes dontShowAgain state', () {
        final state = OnboardingState.fromJson({
          'completed': false,
          'dontShowAgain': true,
        });
        expect(state.completed, isFalse);
        expect(state.dontShowAgain, isTrue);
      });

      test('deserializes both flags true', () {
        final state = OnboardingState.fromJson({
          'completed': true,
          'dontShowAgain': true,
        });
        expect(state.completed, isTrue);
        expect(state.dontShowAgain, isTrue);
      });

      test('defaults to false when keys are missing', () {
        final state = OnboardingState.fromJson({});
        expect(state.completed, isFalse);
        expect(state.dontShowAgain, isFalse);
      });

      test('defaults to false when values are null', () {
        final state = OnboardingState.fromJson({
          'completed': null,
          'dontShowAgain': null,
        });
        expect(state.completed, isFalse);
        expect(state.dontShowAgain, isFalse);
      });

      test('defaults to false when only one key is present', () {
        final state = OnboardingState.fromJson({'completed': true});
        expect(state.completed, isTrue);
        expect(state.dontShowAgain, isFalse);
      });

      test('handles unknown keys gracefully', () {
        final state = OnboardingState.fromJson({
          'completed': true,
          'dontShowAgain': false,
          'unknownKey': 'value',
        });
        expect(state.completed, isTrue);
        expect(state.dontShowAgain, isFalse);
      });
    });

    group('serialization round-trip', () {
      test('default state round-trips correctly', () {
        const original = OnboardingState();
        final json = original.toJson();
        final restored = OnboardingState.fromJson(json);
        expect(restored.completed, original.completed);
        expect(restored.dontShowAgain, original.dontShowAgain);
      });

      test('completed state round-trips correctly', () {
        const original = OnboardingState(completed: true);
        final json = original.toJson();
        final restored = OnboardingState.fromJson(json);
        expect(restored.completed, original.completed);
        expect(restored.dontShowAgain, original.dontShowAgain);
      });

      test('both flags state round-trips correctly', () {
        const original = OnboardingState(completed: true, dontShowAgain: true);
        final json = original.toJson();
        final restored = OnboardingState.fromJson(json);
        expect(restored.completed, original.completed);
        expect(restored.dontShowAgain, original.dontShowAgain);
      });
    });
  });
}
