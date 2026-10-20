import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/utils/mermaid_parser.dart';

void main() {
  group('MermaidParser', () {
    late MermaidParser parser;

    setUp(() {
      parser = MermaidParser();
    });

    group('flowchart detection', () {
      test('directive + direction', () {
        final spec = parser.parse('graph LR\nA --> B');
        expect(spec.family, MermaidDiagramFamily.flowchart);
        expect(spec.direction, 'LR');
        expect(spec.edges, hasLength(1));
        expect(spec.edges.first.fromId, 'A');
        expect(spec.edges.first.toId, 'B');
        expect(spec.nodes, hasLength(2));
      });

      test('flowchart shorthand defaults to TD', () {
        final spec = parser.parse('flowchart TD\nA --> B');
        expect(spec.direction, 'TD');
      });

      test('bare edge without directive is inferred as flowchart', () {
        final spec = parser.parse('A --> B\nB --> C');
        expect(spec.family, MermaidDiagramFamily.flowchart);
        expect(spec.nodes.map((n) => n.id), ['A', 'B', 'C']);
        expect(spec.edges, hasLength(2));
      });

      test('extracts node labels from bracket shapes', () {
        final spec = parser.parse('flowchart TD\nA[Start] --> B{End}\nB --> C((done))');
        expect(spec.nodes, hasLength(3));
        final byId = {for (final n in spec.nodes) n.id: n.label};
        expect(byId['A'], 'Start');
        expect(byId['B'], 'End');
        expect(byId['C'], 'done');
      });

      test('extracts pipe edge label', () {
        final spec = parser.parse('A -->|yes| B');
        expect(spec.edges.first.label, 'yes');
      });

      test('extracts colon arrow note as edge label', () {
        final spec = parser.parse('A --> B : confirm');
        expect(spec.edges.first.label, 'confirm');
      });

      test('standalone node definition registers a node', () {
        final spec = parser.parse('flowchart TD\nA[Only]\nB --> A');
        expect(spec.nodes.any((n) => n.id == 'A' && n.label == 'Only'), isTrue);
      });
    });

    group('pie detection', () {
      test('title and equal fractions', () {
        final spec = parser.parse('pie title Pets\n"Dogs" : 50\n"Cats" : 50');
        expect(spec.family, MermaidDiagramFamily.pie);
        expect(spec.title, 'Pets');
        expect(spec.slices, hasLength(2));
        expect(spec.slices.firstWhere((s) => s.label == 'Dogs').fraction,
            closeTo(0.5, 0.001));
        expect(spec.slices.firstWhere((s) => s.label == 'Cats').fraction,
            closeTo(0.5, 0.001));
      });

      test('normalizes unequal values', () {
        final spec = parser.parse('pie\n"A": 30\n"B": 10');
        expect(spec.slices, hasLength(2));
        expect(spec.slices.first.fraction, closeTo(0.75, 0.001));
        expect(spec.slices.last.fraction, closeTo(0.25, 0.001));
      });

      test('bare quoted slices without pie directive are still pie', () {
        final spec = parser.parse('"Dogs" : 50\n"Cats" : 50');
        expect(spec.family, MermaidDiagramFamily.pie);
        expect(spec.slices, hasLength(2));
      });
    });

    group('bar detection', () {
      test('value-series bar chart', () {
        final spec = parser.parse('barChart\nQ1 30\nQ2 45');
        expect(spec.family, MermaidDiagramFamily.bar);
        expect(spec.barData, hasLength(2));
        expect(spec.barData.first.label, 'Q1');
        expect(spec.barData.first.value, 30);
        expect(spec.barData.last.label, 'Q2');
        expect(spec.barData.last.value, 45);
      });

      test('columnChart directive and title', () {
        final spec = parser.parse('columnChart title Revenue\n2023 100\n2024 150');
        expect(spec.family, MermaidDiagramFamily.bar);
        expect(spec.title, 'Revenue');
        expect(spec.barData, hasLength(2));
      });

      test('unquoted label value is bar, not pie', () {
        final spec = parser.parse('Q1 30\nQ2 45');
        expect(spec.family, MermaidDiagramFamily.bar);
      });
    });

    group('table detection', () {
      test('parses headers, separator and rows', () {
        final spec = parser.parse(
            '| H1 | H2 |\n| --- | --- |\n| a | b |\n| c | d |');
        expect(spec.family, MermaidDiagramFamily.table);
        expect(spec.tableHeaders, ['H1', 'H2']);
        expect(spec.tableRows, [
          ['a', 'b'],
          ['c', 'd'],
        ]);
      });
    });

    group('unsupported', () {
      test('empty spec is unsupported', () {
        final spec = parser.parse('');
        expect(spec.family, MermaidDiagramFamily.unsupported);
        expect(spec.hint, 'empty');
      });

      test('blank/comment-only spec is unsupported', () {
        final spec = parser.parse('%% just a comment\n   ');
        expect(spec.family, MermaidDiagramFamily.unsupported);
      });

      test('unknown directive is unsupported with a hint', () {
        final spec = parser.parse('sequenceDiagram\nAlice -> Bob: hi');
        expect(spec.family, MermaidDiagramFamily.unsupported);
        expect(spec.hint, isNotEmpty);
      });
    });
  });
}
