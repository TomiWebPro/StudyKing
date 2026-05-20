import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/spaced_repetition_error_codes.dart';

void main() {
  group('SpacedRepetitionErrorCode enum', () {
    test('has expected values', () {
      expect(SpacedRepetitionErrorCode.values.length, 2);
      expect(SpacedRepetitionErrorCode.values, containsAll([
        SpacedRepetitionErrorCode.boxClosed,
        SpacedRepetitionErrorCode.notFound,
      ]));
    });

    test('boxClosed has correct name', () {
      expect(SpacedRepetitionErrorCode.boxClosed.name, equals('boxClosed'));
    });

    test('notFound has correct name', () {
      expect(SpacedRepetitionErrorCode.notFound.name, equals('notFound'));
    });
  });

  group('SpacedRepetitionErrorCode usage', () {
    test('can be used in switch statements', () {
      for (final code in SpacedRepetitionErrorCode.values) {
        final description = switch (code) {
          SpacedRepetitionErrorCode.boxClosed => 'box is closed',
          SpacedRepetitionErrorCode.notFound => 'item not found',
        };
        expect(description, isNotEmpty);
      }
    });

    test('index values are sequential', () {
      expect(SpacedRepetitionErrorCode.boxClosed.index, equals(0));
      expect(SpacedRepetitionErrorCode.notFound.index, equals(1));
    });
  });
}
