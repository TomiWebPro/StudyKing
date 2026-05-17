import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/utils/id_generator.dart';

void main() {
  group('IdGenerator', () {
    setUp(() {
      IdGenerator.reset();
    });

    group('generate', () {
      test('produces unique IDs on successive calls', () {
        final id1 = IdGenerator.generate('q');
        final id2 = IdGenerator.generate('q');
        expect(id1, isNot(id2));
      });

      test('IDs include the prefix', () {
        final id = IdGenerator.generate('topic');
        expect(id, startsWith('topic_'));
      });

      test('IDs contain a timestamp component', () {
        final id = IdGenerator.generate('q');
        final parts = id.split('_');
        expect(parts.length, greaterThanOrEqualTo(3));
      });

      test('increments counter on each call', () {
        final id1 = IdGenerator.generate('q');
        final id2 = IdGenerator.generate('q');
        final parts1 = id1.split('_');
        final parts2 = id2.split('_');
        final counter1 = int.parse(parts1.last);
        final counter2 = int.parse(parts2.last);
        expect(counter2, counter1 + 1);
      });
    });

    group('reset', () {
      test('clears internal counter so a new generate starts from 1', () {
        IdGenerator.generate('q');
        IdGenerator.generate('q');
        IdGenerator.reset();
        final id = IdGenerator.generate('q');
        final parts = id.split('_');
        final counter = int.parse(parts.last);
        expect(counter, 1);
      });
    });
  });
}
