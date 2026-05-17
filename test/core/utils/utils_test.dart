import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/utils/utils.dart';

void main() {
  group('core/utils barrel exports', () {
    test('exports Clock', () {
      expect(Clock, isA<Type>());
    });

    test('exports ColorUtils', () {
      expect(ColorUtils, isA<Type>());
    });
  });
}
