import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/utils/id_generator.dart';

void main() {
  tearDown(() {
    IdGenerator.reset();
  });

  group('IdGenerator', () {
    test('generate produces id with correct prefix', () {
      final id = IdGenerator.generate('user');
      expect(id, startsWith('user_'));
    });

    test('generate produces id with underscore separators', () {
      final id = IdGenerator.generate('topic');
      final parts = id.split('_');
      expect(parts.length, greaterThanOrEqualTo(3));
      expect(parts[0], 'topic');
    });

    test('increments counter for sequential calls', () {
      final id1 = IdGenerator.generate('q');
      final id2 = IdGenerator.generate('q');
      expect(id1, isNot(equals(id2)));
    });

    test('reset clears counter so ids are unique from base', () {
      final id1 = IdGenerator.generate('x');
      IdGenerator.reset();
      final id2 = IdGenerator.generate('x');
      expect(id1, isNot(equals(id2)));
    });

    test('different prefixes generate independently', () {
      final id1 = IdGenerator.generate('a');
      final id2 = IdGenerator.generate('b');
      expect(id1, startsWith('a_'));
      expect(id2, startsWith('b_'));
    });

    test('generate works with empty prefix', () {
      final id = IdGenerator.generate('');
      expect(id, startsWith('_'));
    });

    test('generate does not throw with any string prefix', () {
      expect(() => IdGenerator.generate('test-prefix-123'), returnsNormally);
    });
  });
}
