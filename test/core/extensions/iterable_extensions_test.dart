import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/extensions/iterable_extensions.dart';

void main() {
  group('IterableExtension.firstOrNull', () {
    test('returns null for empty iterable', () {
      final result = [].firstOrNull;
      expect(result, isNull);
    });

    test('returns first element for non-empty list', () {
      final result = [1, 2, 3].firstOrNull;
      expect(result, equals(1));
    });

    test('returns first element for single-element list', () {
      final result = ['only'].firstOrNull;
      expect(result, equals('only'));
    });

    test('works with Set', () {
      final result = {10, 20, 30}.firstOrNull;
      expect(result, equals(10));
    });

    test('works with Iterable', () {
      final result = [true, false].where((e) => e).firstOrNull;
      expect(result, isTrue);
    });

    test('returns null when all elements filtered out', () {
      final result = [1, 2, 3].where((e) => e > 10).firstOrNull;
      expect(result, isNull);
    });
  });
}
