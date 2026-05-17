import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/extensions/iterable_extensions.dart';

void main() {
  group('IterableExtension.firstOrNull', () {
    test('returns null for empty list', () {
      expect([].firstOrNull, isNull);
    });

    test('returns first element for non-empty list', () {
      expect([1, 2, 3].firstOrNull, equals(1));
    });

    test('returns first element for single-element list', () {
      expect(['only'].firstOrNull, equals('only'));
    });

    test('works with Set', () {
      expect({10, 20, 30}.firstOrNull, equals(10));
    });

    test('works with filtered Iterable returning match', () {
      expect([true, false].where((e) => e).firstOrNull, isTrue);
    });

    test('returns null when all elements filtered out', () {
      expect([1, 2, 3].where((e) => e > 10).firstOrNull, isNull);
    });

    test('returns null for Iterable.generate with count 0', () {
      expect(Iterable.generate(0).firstOrNull, isNull);
    });

    test('returns first element for Iterable.generate', () {
      expect(Iterable.generate(5, (i) => i * 2).firstOrNull, equals(0));
    });

    test('returns null from take(0)', () {
      expect([1, 2, 3].take(0).firstOrNull, isNull);
    });

    test('returns null element if first element is null', () {
      expect([null, 'a', 'b'].firstOrNull, isNull);
    });

    test('works with Map entries', () {
      final map = {'a': 1, 'b': 2};
      expect(map.entries.firstOrNull?.key, equals('a'));
    });

    test('returns null for empty Map entries', () {
      expect(<String, int>{}.entries.firstOrNull, isNull);
    });

    test('works with Queue', () {
      final queue = Queue<int>()..addAll([100, 200]);
      expect(queue.firstOrNull, equals(100));
    });

    test('returns null for empty Queue', () {
      expect(Queue<int>().firstOrNull, isNull);
    });

    test('works with Runes', () {
      expect('hello'.runes.firstOrNull, equals(104));
    });

    test('preserves type inference with complex generic', () {
      final list = <Map<String, List<int>>>[{'a': [1, 2]}];
      final result = list.firstOrNull;
      expect(result, isA<Map<String, List<int>>>());
    });

    test('does not invoke generator on empty lazy iterable', () {
      bool generatorCalled = false;
      final lazy = Iterable.generate(0, (_) {
        generatorCalled = true;
        return 1;
      });
      expect(lazy.firstOrNull, isNull);
      expect(generatorCalled, isFalse);
    });

    test('works on Iterable with nullable type', () {
      final list = <int?>[null, 1, 2];
      expect(list.firstOrNull, isNull);
    });

    test('returns first from reversed iterable', () {
      expect([1, 2, 3].reversed.firstOrNull, equals(3));
    });
  });
}
