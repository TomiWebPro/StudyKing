import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/services/syllabus_switch_parser.dart';

void main() {
  group('SyllabusSwitchParser', () {
    const available = ['Math', 'Science', 'English Literature'];

    test('matches explicit /syllabus command with a known title', () {
      final result = SyllabusSwitchParser.parse(
        '/syllabus Math',
        availableTitles: available,
      );
      expect(result.matched, isTrue);
      expect(result.syllabusTitle, 'Math');
    });

    test('matches /switchsyllabus command variant', () {
      final result = SyllabusSwitchParser.parse(
        '/switchsyllabus Science',
        availableTitles: available,
      );
      expect(result.matched, isTrue);
      expect(result.syllabusTitle, 'Science');
    });

    test('clears selection for /syllabus all', () {
      final result = SyllabusSwitchParser.parse(
        '/syllabus all',
        availableTitles: available,
      );
      expect(result.matched, isTrue);
      expect(result.syllabusTitle, isNull);
    });

    test('clears selection for bare /syllabus command', () {
      final result = SyllabusSwitchParser.parse(
        '/syllabus',
        availableTitles: available,
      );
      expect(result.matched, isTrue);
      expect(result.syllabusTitle, isNull);
    });

    test('does not match /syllabus with unknown title', () {
      final result = SyllabusSwitchParser.parse(
        '/syllabus Physics',
        availableTitles: available,
      );
      expect(result.matched, isFalse);
    });

    test('matches natural language "switch to X syllabus"', () {
      final result = SyllabusSwitchParser.parse(
        'Can we switch to Science syllabus?',
        availableTitles: available,
      );
      expect(result.matched, isTrue);
      expect(result.syllabusTitle, 'Science');
    });

    test('matches natural language "change syllabus to X"', () {
      final result = SyllabusSwitchParser.parse(
        'change syllabus to Math',
        availableTitles: available,
      );
      expect(result.matched, isTrue);
      expect(result.syllabusTitle, 'Math');
    });

    test('matches natural language "use X syllabus"', () {
      final result = SyllabusSwitchParser.parse(
        'use English Literature syllabus',
        availableTitles: available,
      );
      expect(result.matched, isTrue);
      expect(result.syllabusTitle, 'English Literature');
    });

    test('does not match an unrelated message', () {
      final result = SyllabusSwitchParser.parse(
        'What is photosynthesis?',
        availableTitles: available,
      );
      expect(result.matched, isFalse);
    });

    test('does not match switch keyword without a known syllabus title', () {
      final result = SyllabusSwitchParser.parse(
        'switch syllabus to Biology',
        availableTitles: available,
      );
      expect(result.matched, isFalse);
    });

    test('is case-insensitive', () {
      final result = SyllabusSwitchParser.parse(
        '/SYLLABUS math',
        availableTitles: available,
      );
      expect(result.matched, isTrue);
      expect(result.syllabusTitle, 'Math');
    });

    test('matches structured phrasing "to <title>"', () {
      final result = SyllabusSwitchParser.parse(
        'to Math',
        availableTitles: available,
      );
      expect(result.matched, isTrue);
      expect(result.syllabusTitle, 'Math');
    });

    test('matches structured phrasing "with <title>"', () {
      final result = SyllabusSwitchParser.parse(
        'with Science',
        availableTitles: available,
      );
      expect(result.matched, isTrue);
      expect(result.syllabusTitle, 'Science');
    });

    test('matches structured phrasing "<title> syllabus"', () {
      final result = SyllabusSwitchParser.parse(
        'Math syllabus',
        availableTitles: available,
      );
      expect(result.matched, isTrue);
      expect(result.syllabusTitle, 'Math');
    });

    test('matches structured phrasing "<title> please"', () {
      final result = SyllabusSwitchParser.parse(
        'Science please',
        availableTitles: available,
      );
      expect(result.matched, isTrue);
      expect(result.syllabusTitle, 'Science');
    });

    test('matches title containing regex-special characters', () {
      const special = ['Math 101 (Honors)'];

      final asSyllabus = SyllabusSwitchParser.parse(
        'Math 101 (Honors) syllabus',
        availableTitles: special,
      );
      expect(asSyllabus.matched, isTrue);
      expect(asSyllabus.syllabusTitle, 'Math 101 (Honors)');

      final asPlease = SyllabusSwitchParser.parse(
        'Math 101 (Honors) please',
        availableTitles: special,
      );
      expect(asPlease.matched, isTrue);
      expect(asPlease.syllabusTitle, 'Math 101 (Honors)');
    });

    test('structured phrasing does not match a longer title-like word', () {
      final result = SyllabusSwitchParser.parse(
        'with Mathew',
        availableTitles: available,
      );
      expect(result.matched, isFalse);
    });

    test('does not match a title mention without switch intent', () {
      final result = SyllabusSwitchParser.parse(
        'I like Math',
        availableTitles: available,
      );
      expect(result.matched, isFalse);
    });

    test('does not false-positive on "because" containing "use"', () {
      final result = SyllabusSwitchParser.parse(
        'I enjoy Math because it is fun',
        availableTitles: available,
      );
      expect(result.matched, isFalse);
    });

    test('does not false-positive on "reopened" containing "open"', () {
      final result = SyllabusSwitchParser.parse(
        'I reopened my Science notes',
        availableTitles: available,
      );
      expect(result.matched, isFalse);
    });

    test('does not false-positive on "exchange" containing "change"', () {
      final result = SyllabusSwitchParser.parse(
        'let us exchange Math notes',
        availableTitles: available,
      );
      expect(result.matched, isFalse);
    });

    test('does not match a title embedded in a longer word', () {
      const titles = ['Art'];
      final result = SyllabusSwitchParser.parse(
        'open the parts of speech worksheets',
        availableTitles: titles,
      );
      expect(result.matched, isFalse);
    });

    test('prefers the longest matching title', () {
      const titles = ['Math', 'Math Advanced'];
      final result = SyllabusSwitchParser.parse(
        'switch to Math Advanced',
        availableTitles: titles,
      );
      expect(result.matched, isTrue);
      expect(result.syllabusTitle, 'Math Advanced');
    });

    test('matches whole-word switch verb', () {
      final result = SyllabusSwitchParser.parse(
        'I will use Math from now on',
        availableTitles: available,
      );
      expect(result.matched, isTrue);
      expect(result.syllabusTitle, 'Math');
    });

    test('matches "go to" phrasing with a known title', () {
      final result = SyllabusSwitchParser.parse(
        'go to Science',
        availableTitles: available,
      );
      expect(result.matched, isTrue);
      expect(result.syllabusTitle, 'Science');
    });
  });
}
