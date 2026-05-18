import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/utils/number_format_utils.dart';

void main() {
  group('formatDecimal', () {
    test('en locale uses period decimal separator', () {
      expect(formatDecimal(85.5, 'en', minFractionDigits: 1, maxFractionDigits: 1), '85.5');
    });

    test('es locale uses comma decimal separator', () {
      expect(formatDecimal(85.5, 'es', minFractionDigits: 1, maxFractionDigits: 1), '85,5');
    });

    test('es locale formats zero correctly', () {
      expect(formatDecimal(0.0, 'es', minFractionDigits: 1, maxFractionDigits: 1), '0,0');
    });

    test('supports varying fraction digits', () {
      expect(formatDecimal(0.0025, 'es', minFractionDigits: 4, maxFractionDigits: 4), '0,0025');
    });
  });

  group('formatPercent', () {
    test('en locale uses period decimal separator for percent', () {
      expect(formatPercent(85.5, 'en', minFractionDigits: 1, maxFractionDigits: 1), '85.5%');
    });

    test('es locale uses comma decimal separator for percent', () {
      final result = formatPercent(85.5, 'es', minFractionDigits: 1, maxFractionDigits: 1);
      expect(result.contains('85'), isTrue);
      expect(result.contains(','), isTrue);
    });
  });

  group('formatCompactNumber', () {
    test('en locale formats thousands', () {
      expect(formatCompactNumber(1500, 'en'), '1.5K');
    });

    test('es locale formats thousands', () {
      final result = formatCompactNumber(1500, 'es');
      expect(result.contains('1'), isTrue);
    });

    test('returns plain string for small numbers', () {
      expect(formatCompactNumber(999, 'es'), '999');
    });

    test('en locale formats millions', () {
      expect(formatCompactNumber(1500000, 'en'), '1.5M');
    });

    test('zero returns zero', () {
      expect(formatCompactNumber(0, 'en'), '0');
    });
  });

  group('formatHours', () {
    test('en locale uses period separator', () {
      expect(formatHours(12600, 'en'), '3.5');
    });

    test('es locale uses comma separator', () {
      expect(formatHours(12600, 'es'), '3,5');
    });
  });

  group('formatCurrency', () {
    test('en locale uses period decimal separator', () {
      expect(formatCurrency(0.0025, 'en', minFractionDigits: 4, maxFractionDigits: 4), '\$0.0025');
    });

    test('es locale uses comma decimal separator', () {
      final result = formatCurrency(0.0025, 'es', minFractionDigits: 4, maxFractionDigits: 4);
      expect(result.contains(','), isTrue);
      expect(result.contains('0'), isTrue);
    });
  });
}
