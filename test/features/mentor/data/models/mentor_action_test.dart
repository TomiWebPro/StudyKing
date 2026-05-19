import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/mentor/data/models/mentor_action.dart';

void main() {
  group('MentorAction', () {
    test('can be created with required message and default type', () {
      final action = MentorAction(message: 'Hello');

      expect(action.message, 'Hello');
      expect(action.type, 'generic');
    });

    test('can be created with custom type', () {
      final action = MentorAction(message: 'Study time!', type: 'reminder');

      expect(action.message, 'Study time!');
      expect(action.type, 'reminder');
    });

    test('supports value equality', () {
      final a = MentorAction(message: 'Test', type: 'alert');
      final b = MentorAction(message: 'Test', type: 'alert');

      expect(a.message, b.message);
      expect(a.type, b.type);
    });

    test('different messages are not equal', () {
      final a = MentorAction(message: 'Hello');
      final b = MentorAction(message: 'World');

      expect(a, isNot(equals(b)));
    });

    test('different types are not equal', () {
      final a = MentorAction(message: 'Test', type: 'reminder');
      final b = MentorAction(message: 'Test', type: 'alert');

      expect(a, isNot(equals(b)));
    });

    test('can be const', () {
      const action = MentorAction(message: 'Const test', type: 'nudge');

      expect(action.message, 'Const test');
      expect(action.type, 'nudge');
    });

    test('accepts empty message string', () {
      final action = MentorAction(message: '');

      expect(action.message, isEmpty);
      expect(action.type, 'generic');
    });

    test('accepts empty type string', () {
      final action = MentorAction(message: 'Hello', type: '');

      expect(action.message, 'Hello');
      expect(action.type, isEmpty);
    });

    test('default type with explicitly passed generic', () {
      final withDefault = MentorAction(message: 'Hi');
      final withExplicit = MentorAction(message: 'Hi', type: 'generic');

      expect(withDefault.type, withExplicit.type);
    });

    test('identical runtimeType for const instances', () {
      const a = MentorAction(message: 'Same');
      const b = MentorAction(message: 'Same');

      expect(a.runtimeType, b.runtimeType);
    });
  });
}
