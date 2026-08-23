import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/flashcards/data/models/concept_map_model.dart';

void main() {
  group('ConceptMap model', () {
    test('creates with nodes and edges', () {
      final now = DateTime(2026, 7, 23);
      final map = ConceptMap(
        id: 'cm1',
        sourceId: 's1',
        topicId: 't1',
        subjectId: 'sub1',
        title: 'Concept Map: Biology',
        nodes: [
          ConceptNode(id: 'n1', label: 'Cell', description: 'Basic unit of life'),
          ConceptNode(id: 'n2', label: 'Nucleus', description: 'Contains DNA'),
        ],
        edges: [ConceptEdge(fromId: 'n2', toId: 'n1', relationship: 'is part of')],
        createdAt: now,
      );
      expect(map.nodes.length, 2);
      expect(map.edges.length, 1);
      expect(map.edges[0].relationship, 'is part of');
    });

    test('toJson and fromJson round-trip', () {
      final now = DateTime(2026, 7, 23);
      final map = ConceptMap(
        id: 'cm1',
        sourceId: 's1',
        topicId: 't1',
        subjectId: 'sub1',
        title: 'Concept Map',
        nodes: [
          ConceptNode(id: 'n1', label: 'A'),
          ConceptNode(id: 'n2', label: 'B', description: 'desc'),
        ],
        edges: [ConceptEdge(fromId: 'n1', toId: 'n2', relationship: 'relates to')],
        createdAt: now,
      );
      final json = map.toJson();
      final restored = ConceptMap.fromJson(json);
      expect(restored.id, map.id);
      expect(restored.nodes.length, 2);
      expect(restored.nodes[1].description, 'desc');
      expect(restored.edges.length, 1);
      expect(restored.edges[0].fromId, 'n1');
      expect(restored.edges[0].relationship, 'relates to');
      expect(restored.createdAt, map.createdAt);
    });

    test('fromJson handles missing nodes/edges', () {
      final restored = ConceptMap.fromJson({
        'id': 'cm2',
        'createdAt': DateTime(2026, 7, 23).toIso8601String(),
      });
      expect(restored.id, 'cm2');
      expect(restored.nodes, isEmpty);
      expect(restored.edges, isEmpty);
    });

    test('ConceptNode round-trip', () {
      final node = ConceptNode(id: 'n1', label: 'A', description: 'd');
      final restored = ConceptNode.fromJson(node.toJson());
      expect(restored.id, 'n1');
      expect(restored.label, 'A');
      expect(restored.description, 'd');
    });

    test('ConceptEdge round-trip', () {
      final edge = ConceptEdge(fromId: 'n1', toId: 'n2', relationship: 'rel');
      final restored = ConceptEdge.fromJson(edge.toJson());
      expect(restored.fromId, 'n1');
      expect(restored.toId, 'n2');
      expect(restored.relationship, 'rel');
    });
  });
}
