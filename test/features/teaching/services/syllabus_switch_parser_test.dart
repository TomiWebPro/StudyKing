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
  });
}
