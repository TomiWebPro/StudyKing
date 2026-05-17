import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/extensions/string_extensions.dart';

void main() {
  group('StringExtension.isBlank', () {
    test('returns true for empty string', () {
      expect(''.isBlank, isTrue);
    });

    test('returns true for whitespace-only string', () {
      expect('   '.isBlank, isTrue);
    });

    test('returns true for string with tabs and newlines', () {
      expect('\t\n  '.isBlank, isTrue);
    });

    test('returns false for non-empty string', () {
      expect('hello'.isBlank, isFalse);
    });

    test('returns false for string with whitespace and content', () {
      expect('  hello  '.isBlank, isFalse);
    });
  });

  group('StringExtension.isNotBlank', () {
    test('returns false for empty string', () {
      expect(''.isNotBlank, isFalse);
    });

    test('returns false for whitespace-only string', () {
      expect('   '.isNotBlank, isFalse);
    });

    test('returns true for non-empty string', () {
      expect('hello'.isNotBlank, isTrue);
    });

    test('returns true for string with surrounding whitespace', () {
      expect('  hi  '.isNotBlank, isTrue);
    });
  });

  group('StringExtension.trimmedOrNull', () {
    test('returns null for empty string', () {
      expect(''.trimmedOrNull, isNull);
    });

    test('returns null for whitespace-only string', () {
      expect('   '.trimmedOrNull, isNull);
    });

    test('returns trimmed string for string with surrounding whitespace', () {
      expect('  hello  '.trimmedOrNull, equals('hello'));
    });

    test('returns same string for already trimmed string', () {
      expect('hello'.trimmedOrNull, equals('hello'));
    });

    test('preserves inner whitespace', () {
      expect('  hello world  '.trimmedOrNull, equals('hello world'));
    });
  });

  group('StringExtension.capitalize', () {
    test('returns same string for empty string', () {
      expect(''.capitalize(), equals(''));
    });

    test('capitalizes single character', () {
      expect('a'.capitalize(), equals('A'));
    });

    test('capitalizes first letter of a word', () {
      expect('hello'.capitalize(), equals('Hello'));
    });

    test('keeps rest of string unchanged', () {
      expect('hello WORLD'.capitalize(), equals('Hello WORLD'));
    });

    test('does not change already capitalized string', () {
      expect('Hello'.capitalize(), equals('Hello'));
    });

    test('works with single uppercase character', () {
      expect('A'.capitalize(), equals('A'));
    });
  });

  group('StringExtension.truncate', () {
    test('returns same string when shorter than maxLength', () {
      expect('hello'.truncate(10), equals('hello'));
    });

    test('returns same string when equal to maxLength', () {
      expect('hello'.truncate(5), equals('hello'));
    });

    test('truncates and adds default suffix', () {
      expect('hello world'.truncate(5), equals('hello...'));
    });

    test('truncates with custom suffix', () {
      expect('hello world'.truncate(5, suffix: '!'), equals('hello!'));
    });

    test('truncates with empty suffix', () {
      expect('hello world'.truncate(5, suffix: ''), equals('hello'));
    });

    test('works with empty string', () {
      expect(''.truncate(5), equals(''));
    });

    test('works with maxLength of 0', () {
      expect('hello'.truncate(0), equals('...'));
    });
  });

  group('StringExtension.sentenceCase', () {
    test('returns same string for empty string', () {
      expect(''.sentenceCase, equals(''));
    });

    test('capitalizes first letter and lowercases rest', () {
      expect('hello WORLD'.sentenceCase, equals('Hello world'));
    });

    test('works with single character', () {
      expect('a'.sentenceCase, equals('A'));
    });

    test('works with already proper case', () {
      expect('Hello world'.sentenceCase, equals('Hello world'));
    });

    test('works with all uppercase', () {
      expect('HELLO'.sentenceCase, equals('Hello'));
    });
  });

  group('StringExtension.equalsIgnoreCase', () {
    test('returns true for identical strings', () {
      expect('hello'.equalsIgnoreCase('hello'), isTrue);
    });

    test('returns true for same word different case', () {
      expect('Hello'.equalsIgnoreCase('hELLO'), isTrue);
    });

    test('returns true for all uppercase vs all lowercase', () {
      expect('HELLO'.equalsIgnoreCase('hello'), isTrue);
    });

    test('returns false for different strings', () {
      expect('hello'.equalsIgnoreCase('world'), isFalse);
    });

    test('returns true for empty strings', () {
      expect(''.equalsIgnoreCase(''), isTrue);
    });

    test('returns false when comparing with different length', () {
      expect('hello'.equalsIgnoreCase('hell'), isFalse);
    });
  });

  group('StringExtension.nullIfEmpty', () {
    test('returns null for empty string', () {
      expect(''.nullIfEmpty, isNull);
    });

    test('returns same string for non-empty string', () {
      expect('hello'.nullIfEmpty, equals('hello'));
    });

    test('preserves whitespace string', () {
      expect('  '.nullIfEmpty, equals('  '));
    });
  });
}
