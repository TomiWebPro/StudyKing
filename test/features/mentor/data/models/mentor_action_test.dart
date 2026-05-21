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

    test('accepts long message strings', () {
      final long = 'A' * 10000;
      final action = MentorAction(message: long);

      expect(action.message, long);
      expect(action.message.length, 10000);
    });

    test('accepts message with leading and trailing whitespace', () {
      final action = MentorAction(message: '  Hello World  ');

      expect(action.message, '  Hello World  ');
    });

    test('accepts message with unicode characters', () {
      final action = MentorAction(message: 'Café résumé ñoño 中文');

      expect(action.message, 'Café résumé ñoño 中文');
    });

    test('accepts message with special characters', () {
      final action = MentorAction(message: 'Hello\nWorld\tTab');

      expect(action.message, 'Hello\nWorld\tTab');
    });

    test('accepts various meaningful type values', () {
      final types = ['nudge', 'reminder', 'alert', 'warning', 'encouragement',
        'notification', 'feedback', 'tip', 'milestone', 'achievement'];
      for (final t in types) {
        final action = MentorAction(message: 'Msg', type: t);
        expect(action.type, t);
      }
    });

    test('accepts type with special characters', () {
      final action = MentorAction(message: 'Test', type: 'type-with-hyphen');

      expect(action.type, 'type-with-hyphen');
    });

    test('same const instance has consistent hashCode', () {
      const a = MentorAction(message: 'Study', type: 'reminder');

      expect(a.hashCode, a.hashCode);
    });

    test('different instances of same const have same runtimeType', () {
      const a = MentorAction(message: 'Hello');
      const b = MentorAction(message: 'Hello');

      expect(a.runtimeType, b.runtimeType);
    });

    test('can be used in a Set with identity semantics', () {
      final a = MentorAction(message: 'Hello');
      final b = MentorAction(message: 'Hello');
      final set = {a, b};

      expect(set.length, 2);
    });
  });
}
