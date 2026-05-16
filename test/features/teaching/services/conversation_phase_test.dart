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
  });
}
