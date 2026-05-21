import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/utils/string_extensions.dart';

void main() {
  group('StringExtension.normalized', () {
    test('trims whitespace', () {
      expect('  hello  '.normalized, 'hello');
    });

    test('lowercases', () {
      expect('HELLO'.normalized, 'hello');
    });

    test('handles empty string', () {
      expect(''.normalized, '');
    });

    test('handles mixed case with surrounding whitespace', () {
      expect('  Hello World  '.normalized, 'hello world');
    });

    test('does not throw on special characters', () {
      expect('  Café 123!  '.normalized, 'café 123!');
    });

    test('handles newlines and tabs', () {
      expect('\n\tHello\n\t'.normalized, 'hello');
    });

    test('handles string with only whitespace', () {
      expect('   '.normalized, '');
    });
  });
}
