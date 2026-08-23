import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/flashcards/data/adapters/flashcard_adapters.dart';
import 'package:studyking/features/flashcards/data/models/flashcard_model.dart';
import 'package:studyking/features/flashcards/data/models/concept_map_model.dart';
import 'package:studyking/features/flashcards/data/models/study_guide_model.dart';

late String _hivePath;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('flashcard_adapters_test_');
    _hivePath = dir.path;
    Hive.init(_hivePath);
    Hive.registerAdapter(FlashcardAdapter());
    Hive.registerAdapter(StudyGuideAdapter());
    Hive.registerAdapter(ConceptMapAdapter());
    Hive.registerAdapter(ConceptNodeAdapter());
    Hive.registerAdapter(ConceptEdgeAdapter());
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await Directory(_hivePath).delete(recursive: true);
  });

  group('FlashcardAdapter', () {
    test('typeId is 38', () => expect(FlashcardAdapter().typeId, 38));

    test('write/read round-trip', () async {
      final box = await Hive.openBox<Flashcard>('fc_rt');
      final now = DateTime(2026, 7, 23);
      final card = Flashcard(
        id: 'fc1',
        sourceId: 's1',
        topicId: 't1',
        subjectId: 'sub1',
        front: 'Q?',
        back: 'A',
        tags: ['tag'],
        createdAt: now,
        updatedAt: now,
        nextReview: DateTime(2026, 8, 1),
        mastery: 0.5,
      );
      await box.put('fc1', card);
      final restored = box.get('fc1')!;
      expect(restored.id, 'fc1');
      expect(restored.front, 'Q?');
      expect(restored.tags, ['tag']);
      expect(restored.mastery, 0.5);
      expect(restored.nextReview, DateTime(2026, 8, 1));
      await box.close();
    });
  });

  group('StudyGuideAdapter', () {
    test('typeId is 39', () => expect(StudyGuideAdapter().typeId, 39));

    test('round-trip preserves fields', () async {
      final box = await Hive.openBox<StudyGuide>('sg_rt');
      final now = DateTime(2026, 7, 23);
      final guide = StudyGuide(
        id: 'sg1',
        sourceId: 's1',
        topicId: 't1',
        subjectId: 'sub1',
        title: 'Study Guide: X',
        content: 'content',
        createdAt: now,
      );
      await box.put('sg1', guide);
      final restored = box.get('sg1')!;
      expect(restored.id, 'sg1');
      expect(restored.title, 'Study Guide: X');
      expect(restored.content, 'content');
      await box.close();
    });
  });

  group('ConceptMapAdapter', () {
    test('typeId is 40', () => expect(ConceptMapAdapter().typeId, 40));

    test('write/read round-trip with nodes and edges', () async {
      final box = await Hive.openBox<ConceptMap>('cm_rt');
      final now = DateTime(2026, 7, 23);
      final map = ConceptMap(
        id: 'cm1',
        sourceId: 's1',
        topicId: 't1',
        subjectId: 'sub1',
        title: 'Concept Map: X',
        nodes: [
          ConceptNode(id: 'n1', label: 'A', description: 'desc'),
          ConceptNode(id: 'n2', label: 'B'),
        ],
        edges: [ConceptEdge(fromId: 'n1', toId: 'n2', relationship: 'rel')],
        createdAt: now,
      );
      await box.put('cm1', map);
      final restored = box.get('cm1')!;
      expect(restored.id, 'cm1');
      expect(restored.nodes.length, 2);
      expect(restored.nodes[0].label, 'A');
      expect(restored.edges.length, 1);
      expect(restored.edges[0].relationship, 'rel');
      await box.close();
    });
  });

  group('ConceptNodeAdapter', () {
    test('typeId is 41', () => expect(ConceptNodeAdapter().typeId, 41));

    test('write/read round-trip', () async {
      final box = await Hive.openBox<ConceptNode>('cn_rt');
      final node = ConceptNode(id: 'n1', label: 'A', description: 'd');
      await box.put('n1', node);
      final restored = box.get('n1')!;
      expect(restored.id, 'n1');
      expect(restored.label, 'A');
      expect(restored.description, 'd');
      await box.close();
    });
  });

  group('ConceptEdgeAdapter', () {
    test('typeId is 42', () => expect(ConceptEdgeAdapter().typeId, 42));

    test('write/read round-trip', () async {
      final box = await Hive.openBox<ConceptEdge>('ce_rt');
      final edge = ConceptEdge(fromId: 'n1', toId: 'n2', relationship: 'rel');
      await box.put('ce1', edge);
      final restored = box.get('ce1')!;
      expect(restored.fromId, 'n1');
      expect(restored.toId, 'n2');
      expect(restored.relationship, 'rel');
      await box.close();
    });
  });
}
