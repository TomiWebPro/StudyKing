import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/flashcards/data/models/flashcard_model.dart';
import 'package:studyking/features/flashcards/data/models/study_guide_model.dart';
import 'package:studyking/features/flashcards/data/models/concept_map_model.dart';

void main() {
  group('Flashcard', () {
    test('creates with required fields', () {
      final now = DateTime(2026, 7, 23);
      final card = Flashcard(
        id: 'fc_1',
        sourceId: 'src_1',
        topicId: 'topic_1',
        subjectId: 'sub_1',
        front: 'What is photosynthesis?',
        back: 'The process by which plants convert sunlight into energy.',
        createdAt: now,
        updatedAt: now,
      );

      expect(card.id, 'fc_1');
      expect(card.sourceId, 'src_1');
      expect(card.topicId, 'topic_1');
      expect(card.subjectId, 'sub_1');
      expect(card.front, 'What is photosynthesis?');
      expect(card.back, contains('process'));
      expect(card.tags, isEmpty);
      expect(card.mastery, 0.0);
      expect(card.nextReview, isNull);
      expect(card.srDataJson, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      final now = DateTime(2026, 7, 23);
      final card = Flashcard(
        id: 'fc_1',
        sourceId: 'src_1',
        topicId: 'topic_1',
        subjectId: 'sub_1',
        front: 'Q1',
        back: 'A1',
        tags: ['biology'],
        createdAt: now,
        updatedAt: now,
      );

      final updated = card.copyWith(mastery: 0.8, front: 'Q2');
      expect(updated.id, 'fc_1');
      expect(updated.sourceId, 'src_1');
      expect(updated.front, 'Q2');
      expect(updated.mastery, 0.8);
      expect(updated.tags, ['biology']);
    });

    test('copyWith clearSrData removes srDataJson', () {
      final now = DateTime(2026, 7, 23);
      final card = Flashcard(
        id: 'fc_1',
        sourceId: 'src_1',
        topicId: 'topic_1',
        subjectId: 'sub_1',
        front: 'Q1',
        back: 'A1',
        createdAt: now,
        updatedAt: now,
        srDataJson: '{"r":2,"ef":2.5}',
      );

      final cleared = card.copyWith(clearSrData: true);
      expect(cleared.srDataJson, isNull);
    });

    test('copyWith clearNextReview removes nextReview', () {
      final now = DateTime(2026, 7, 23);
      final card = Flashcard(
        id: 'fc_1',
        sourceId: 'src_1',
        topicId: 'topic_1',
        subjectId: 'sub_1',
        front: 'Q1',
        back: 'A1',
        createdAt: now,
        updatedAt: now,
        nextReview: DateTime(2026, 8, 1),
      );

      final cleared = card.copyWith(clearNextReview: true);
      expect(cleared.nextReview, isNull);
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime(2026, 7, 23, 10, 30);
      final card = Flashcard(
        id: 'fc_1',
        sourceId: 'src_1',
        topicId: 'topic_1',
        subjectId: 'sub_1',
        front: 'What is DNA?',
        back: 'Deoxyribonucleic acid, carries genetic info.',
        tags: ['biology', 'genetics'],
        createdAt: now,
        updatedAt: now,
        mastery: 0.75,
        srDataJson: '{"r":2,"ef":2.5}',
      );

      final json = card.toJson();
      final restored = Flashcard.fromJson(json);

      expect(restored.id, card.id);
      expect(restored.front, card.front);
      expect(restored.back, card.back);
      expect(restored.tags, card.tags);
      expect(restored.mastery, card.mastery);
      expect(restored.srDataJson, card.srDataJson);
      expect(restored.createdAt, card.createdAt);
    });
  });

  group('StudyGuide', () {
    test('creates with required fields', () {
      final now = DateTime(2026, 7, 23);
      final guide = StudyGuide(
        id: 'sg_1',
        sourceId: 'src_1',
        topicId: 'topic_1',
        subjectId: 'sub_1',
        title: 'Study Guide: Biology',
        content: '# Key Concepts\n- Cell division\n- Photosynthesis',
        createdAt: now,
      );

      expect(guide.id, 'sg_1');
      expect(guide.title, contains('Biology'));
      expect(guide.content, contains('Cell division'));
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime(2026, 7, 23);
      final guide = StudyGuide(
        id: 'sg_1',
        sourceId: 'src_1',
        topicId: 'topic_1',
        subjectId: 'sub_1',
        title: 'Study Guide',
        content: 'Content here',
        createdAt: now,
      );

      final json = guide.toJson();
      final restored = StudyGuide.fromJson(json);

      expect(restored.id, guide.id);
      expect(restored.title, guide.title);
      expect(restored.content, guide.content);
    });
  });

  group('ConceptMap', () {
    test('creates with nodes and edges', () {
      final now = DateTime(2026, 7, 23);
      final map = ConceptMap(
        id: 'cm_1',
        sourceId: 'src_1',
        topicId: 'topic_1',
        subjectId: 'sub_1',
        title: 'Concept Map: Biology',
        nodes: [
          ConceptNode(id: 'n1', label: 'Cell', description: 'Basic unit of life'),
          ConceptNode(id: 'n2', label: 'Nucleus', description: 'Contains DNA'),
        ],
        edges: [
          ConceptEdge(fromId: 'n2', toId: 'n1', relationship: 'is part of'),
        ],
        createdAt: now,
      );

      expect(map.nodes.length, 2);
      expect(map.edges.length, 1);
      expect(map.edges[0].relationship, 'is part of');
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime(2026, 7, 23);
      final map = ConceptMap(
        id: 'cm_1',
        sourceId: 'src_1',
        topicId: 'topic_1',
        subjectId: 'sub_1',
        title: 'Concept Map',
        nodes: [
          ConceptNode(id: 'n1', label: 'A'),
          ConceptNode(id: 'n2', label: 'B'),
        ],
        edges: [
          ConceptEdge(fromId: 'n1', toId: 'n2', relationship: 'relates to'),
        ],
        createdAt: now,
      );

      final json = map.toJson();
      final restored = ConceptMap.fromJson(json);

      expect(restored.id, map.id);
      expect(restored.nodes.length, 2);
      expect(restored.edges.length, 1);
      expect(restored.edges[0].fromId, 'n1');
    });
  });
}
