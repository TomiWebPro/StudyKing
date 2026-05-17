import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/utils/utils.dart';

void main() {
  group('core/utils barrel exports', () {
    test('ColorUtils.stringToColor converts hex string to Color', () {
      final color = ColorUtils.stringToColor('#2196F3');
      expect(color, isNotNull);
    });

    test('ColorUtils.stringToColor falls back to default for invalid hex', () {
      final color = ColorUtils.stringToColor('not-a-color');
      expect(color, ColorUtils.defaultColor);
    });

    test('SystemClock returns current DateTime', () {
      final clock = SystemClock();
      final now = clock.now();
      expect(now, isA<DateTime>());
    });
  });
}
