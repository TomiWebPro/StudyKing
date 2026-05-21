import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/utils/clock.dart';

class _TestClock extends Clock {
  final DateTime fixed;
  _TestClock(this.fixed);

  @override
  DateTime now() => fixed;
}

void main() {
  group('Clock', () {
    test('can be subclassed', () {
      final fixed = DateTime(2026, 5, 16, 12, 0, 0);
      final clock = _TestClock(fixed);
      expect(clock.now(), equals(fixed));
    });

    test('different subclass instances return different times', () {
      final t1 = DateTime(2026, 1, 1);
      final t2 = DateTime(2026, 12, 31);
      final clock1 = _TestClock(t1);
      final clock2 = _TestClock(t2);
      expect(clock1.now(), isNot(equals(clock2.now())));
    });
  });

  group('SystemClock', () {
    test('now() returns a DateTime close to real time', () {
      final clock = SystemClock();
      final before = DateTime.now();
      final result = clock.now();
      final after = DateTime.now();
      expect(result.isAfter(before) || result.isAtSameMomentAs(before), isTrue);
      expect(result.isBefore(after) || result.isAtSameMomentAs(after), isTrue);
    });

    test('now() returns a DateTime instance', () {
      final clock = SystemClock();
      expect(clock.now(), isA<DateTime>());
    });
  });
}
