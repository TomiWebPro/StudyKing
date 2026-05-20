import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:studyking/core/utils/date_utils.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });
  group('localizedDateTime', () {
    test('formats date correctly for en locale', () {
      final dt = DateTime(2024, 3, 15, 14, 30);
      final result = localizedDateTime(dt, 'en');
      expect(result, contains('3/15/2024'));
      expect(result, contains('14:30'));
    });

    test('formats date correctly for es locale', () {
      final dt = DateTime(2024, 3, 15, 14, 30);
      final result = localizedDateTime(dt, 'es');
      expect(result, contains('15/3/2024'));
      expect(result, contains('14:30'));
    });

    test('handles leap year dates', () {
      final dt = DateTime(2024, 2, 29, 10, 0);
      final result = localizedDateTime(dt, 'en');
      expect(result, isNotEmpty);
      expect(result, contains('2024'));
    });

    test('returns non-empty string', () {
      final dt = DateTime(2023, 1, 1);
      final result = localizedDateTime(dt, 'en');
      expect(result, isNotEmpty);
    });
  });
}
