import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/spaced_repetition_error_codes.dart';

void main() {
  group('SpacedRepetitionErrorCode', () {
    test('values contains exactly boxClosed and notFound', () {
      expect(SpacedRepetitionErrorCode.values, [
        SpacedRepetitionErrorCode.boxClosed,
        SpacedRepetitionErrorCode.notFound,
      ]);
    });

    test('boxClosed has correct name', () {
      expect(SpacedRepetitionErrorCode.boxClosed.name, 'boxClosed');
    });

    test('notFound has correct name', () {
      expect(SpacedRepetitionErrorCode.notFound.name, 'notFound');
    });

    test('index values are correct', () {
      expect(SpacedRepetitionErrorCode.boxClosed.index, 0);
      expect(SpacedRepetitionErrorCode.notFound.index, 1);
    });
  });
}
