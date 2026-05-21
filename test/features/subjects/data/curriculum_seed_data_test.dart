import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/subjects/data/curriculum_seed_data.dart';

void main() {
  group('curriculumSeedData', () {
    test('is non-empty', () {
      expect(curriculumSeedData, isNotEmpty);
    });

    test('every CurriculumSeedEntry has non-empty curriculumName and topics', () {
      for (final entry in curriculumSeedData) {
        expect(entry.curriculumName, isNotEmpty,
          reason: 'curriculumName should not be empty');
        expect(entry.topics, isNotEmpty,
          reason: 'topics should not be empty for ${entry.curriculumName}');
      }
    });

    test('every SeedTopic has non-empty title', () {
      void checkTopic(SeedTopic topic) {
        expect(topic.title, isNotEmpty,
          reason: 'SeedTopic title should not be empty');
        for (final subtopic in topic.subtopics) {
          checkTopic(subtopic);
        }
      }

      for (final entry in curriculumSeedData) {
        for (final topic in entry.topics) {
          checkTopic(topic);
        }
      }
    });

    test('every entry has unique curriculumName', () {
      final names = curriculumSeedData.map((e) => e.curriculumName).toSet();
      expect(names.length, curriculumSeedData.length);
    });

    test('every SeedTopic has non-negative sortOrder', () {
      void checkTopic(SeedTopic topic) {
        expect(topic.sortOrder, greaterThanOrEqualTo(0),
          reason: 'sortOrder should be >= 0 for ${topic.title}');
        for (final subtopic in topic.subtopics) {
          checkTopic(subtopic);
        }
      }

      for (final entry in curriculumSeedData) {
        for (final topic in entry.topics) {
          checkTopic(topic);
        }
      }
    });

    test('every SeedTopic with subtopics has subtopics with non-empty titles', () {
      for (final entry in curriculumSeedData) {
        for (final topic in entry.topics) {
          for (final subtopic in topic.subtopics) {
            expect(subtopic.title, isNotEmpty,
              reason: 'Sub-topic under ${topic.title} should have non-empty title');
          }
        }
      }
    });

    test('all known curriculum entries are present', () {
      final names = curriculumSeedData.map((e) => e.curriculumName).toSet();
      expect(names, contains('IB Chemistry'));
      expect(names, contains('IB Biology'));
      expect(names, contains('IB Physics'));
      expect(names, contains('IB Mathematics: Analysis & Approaches'));
      expect(names, contains('A-Level Chemistry'));
      expect(names, contains('A-Level Biology'));
      expect(names, contains('AP Chemistry'));
    });
  });

  group('findSeedEntry', () {
    test('returns matching entry for exact name', () {
      final entry = findSeedEntry('IB Chemistry');
      expect(entry, isNotNull);
      expect(entry!.curriculumName, 'IB Chemistry');
    });

    test('returns matching entry for case-insensitive name', () {
      final entry = findSeedEntry('ib chemistry');
      expect(entry, isNotNull);
      expect(entry!.curriculumName, 'IB Chemistry');
    });

    test('returns matching entry for mixed case', () {
      final entry = findSeedEntry('Ib ChEmIsTrY');
      expect(entry, isNotNull);
      expect(entry!.curriculumName, 'IB Chemistry');
    });

    test('returns matching entry with leading/trailing whitespace', () {
      final entry = findSeedEntry('  IB Chemistry  ');
      expect(entry, isNotNull);
      expect(entry!.curriculumName, 'IB Chemistry');
    });

    test('returns matching entry for A-Level curriculum', () {
      final entry = findSeedEntry('A-Level Biology');
      expect(entry, isNotNull);
      expect(entry!.curriculumName, 'A-Level Biology');
    });

    test('returns matching entry for AP curriculum', () {
      final entry = findSeedEntry('AP Chemistry');
      expect(entry, isNotNull);
      expect(entry!.curriculumName, 'AP Chemistry');
    });

    test('returns matching entry for IB Mathematics', () {
      final entry = findSeedEntry('IB Mathematics: Analysis & Approaches');
      expect(entry, isNotNull);
      expect(entry!.curriculumName, 'IB Mathematics: Analysis & Approaches');
    });

    test('returns matching entry for IB Physics', () {
      final entry = findSeedEntry('IB Physics');
      expect(entry, isNotNull);
      expect(entry!.curriculumName, 'IB Physics');
    });

    test('returns null for unknown name', () {
      expect(findSeedEntry('Non-existent'), isNull);
    });

    test('returns null for empty string', () {
      expect(findSeedEntry(''), isNull);
    });

    test('returns null for whitespace-only string', () {
      expect(findSeedEntry('   '), isNull);
    });

    test('returns null for partial name', () {
      expect(findSeedEntry('IB'), isNull);
    });

    test('returns null for partial name with space', () {
      expect(findSeedEntry('IB '), isNull);
    });

    test('returns null for name like but not matching', () {
      expect(findSeedEntry('IB Chemistry HL'), isNull);
    });

    test('returns null for name with extra text', () {
      expect(findSeedEntry('IB Chemistry 101'), isNull);
    });

    test('returns entry with correct topics', () {
      final entry = findSeedEntry('IB Chemistry');
      expect(entry, isNotNull);
      expect(entry!.topics, isNotEmpty);
      expect(entry.topics.first.title, 'Stoichiometric Relationships');
      expect(entry.topics.first.subtopics, isNotEmpty);
    });
  });
}
