import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/utils/answer_comparator.dart';

void main() {
  group('AnswerComparator.areEquivalent', () {
    test('exact match returns true', () {
      expect(AnswerComparator.areEquivalent('hello', 'hello'), isTrue);
    });

    test('whitespace-tolerant match', () {
      expect(AnswerComparator.areEquivalent('  hello  ', 'hello'), isTrue);
      expect(AnswerComparator.areEquivalent('hello', '  hello  '), isTrue);
      expect(AnswerComparator.areEquivalent('  hello world  ', 'hello world'), isTrue);
    });

    test('case-insensitive match', () {
      expect(AnswerComparator.areEquivalent('HELLO', 'hello'), isTrue);
      expect(AnswerComparator.areEquivalent('Hello', 'hELLO'), isTrue);
    });

    test('empty strings', () {
      expect(AnswerComparator.areEquivalent('', ''), isTrue);
      expect(AnswerComparator.areEquivalent('  ', ''), isTrue);
      expect(AnswerComparator.areEquivalent('', '  '), isTrue);
    });

    test('different strings return false', () {
      expect(AnswerComparator.areEquivalent('hello', 'world'), isFalse);
      expect(AnswerComparator.areEquivalent('abc', 'xyz'), isFalse);
    });

    test('null input safety - should handle gracefully', () {
      expect(AnswerComparator.areEquivalent('', ''), isTrue);
    });
  });
}
