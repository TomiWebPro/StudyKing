import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/services/conversation_phase.dart';

void main() {
  group('ConversationPhase', () {
    test('has all 6 expected values', () {
      expect(ConversationPhase.values.length, equals(6));
      expect(ConversationPhase.values, contains(ConversationPhase.greeting));
      expect(ConversationPhase.values, contains(ConversationPhase.teaching));
      expect(ConversationPhase.values, contains(ConversationPhase.exercise));
      expect(ConversationPhase.values, contains(ConversationPhase.feedback));
      expect(ConversationPhase.values, contains(ConversationPhase.adaptiveReview));
      expect(ConversationPhase.values, contains(ConversationPhase.closing));
    });

    test('values are in correct order (greeting → teaching → exercise → feedback → adaptiveReview → closing)', () {
      expect(ConversationPhase.values[0], equals(ConversationPhase.greeting));
      expect(ConversationPhase.values[1], equals(ConversationPhase.teaching));
      expect(ConversationPhase.values[2], equals(ConversationPhase.exercise));
      expect(ConversationPhase.values[3], equals(ConversationPhase.feedback));
      expect(ConversationPhase.values[4], equals(ConversationPhase.adaptiveReview));
      expect(ConversationPhase.values[5], equals(ConversationPhase.closing));
    });

    test('index values are correct', () {
      expect(ConversationPhase.greeting.index, equals(0));
      expect(ConversationPhase.teaching.index, equals(1));
      expect(ConversationPhase.exercise.index, equals(2));
      expect(ConversationPhase.feedback.index, equals(3));
      expect(ConversationPhase.adaptiveReview.index, equals(4));
      expect(ConversationPhase.closing.index, equals(5));
    });

    test('each enum value has a unique name', () {
      final names = ConversationPhase.values.map((e) => e.name).toSet();
      expect(names.length, equals(ConversationPhase.values.length));
    });

    test('next phase can be determined by index + 1', () {
      expect(ConversationPhase.values[ConversationPhase.greeting.index + 1],
          equals(ConversationPhase.teaching));
      expect(ConversationPhase.values[ConversationPhase.teaching.index + 1],
          equals(ConversationPhase.exercise));
      expect(ConversationPhase.values[ConversationPhase.exercise.index + 1],
          equals(ConversationPhase.feedback));
    });

    test('closing has no next phase (it is the last)', () {
      expect(ConversationPhase.closing.index, equals(ConversationPhase.values.length - 1));
    });

    test('all phases can be serialized to name and back', () {
      for (final phase in ConversationPhase.values) {
        final parsed = ConversationPhase.values.firstWhere(
          (p) => p.name == phase.name,
        );
        expect(parsed, equals(phase));
      }
    });

    test('unknown name string throws StateError', () {
      expect(
        () => ConversationPhase.values.firstWhere(
          (p) => p.name == 'nonexistent',
        ),
        throwsA(isA<StateError>()),
      );
    });

    group('error-state: boundary conditions', () {
      test('accessing out-of-range index throws RangeError', () {
        expect(
          () => ConversationPhase.values[ConversationPhase.values.length],
          throwsA(isA<RangeError>()),
        );
      });

      test('accessing negative index throws RangeError', () {
        expect(
          () => ConversationPhase.values[-1],
          throwsA(isA<RangeError>()),
        );
      });

      test('empty name does not match any phase', () {
        expect(
          ConversationPhase.values.where((p) => p.name.isEmpty),
          isEmpty,
        );
      });
    });
  });
}
