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

    test('findSeedEntry returns matching entry', () {
      final entry = findSeedEntry('IB Chemistry');
      expect(entry, isNotNull);
      expect(entry!.curriculumName, 'IB Chemistry');
    });

    test('findSeedEntry returns null for unknown name', () {
      expect(findSeedEntry('Non-existent'), isNull);
    });
  });
}
