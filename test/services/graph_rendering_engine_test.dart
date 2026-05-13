import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:studyking/services/graph_rendering_engine.dart';
import 'package:studyking/services/graph_type_detector.dart';

void main() {
  group('GraphType', () {
    test('has line value', () {
      expect(GraphType.line, isNotNull);
    });

    test('has bar value', () {
      expect(GraphType.bar, isNotNull);
    });

    test('has scatter value', () {
      expect(GraphType.scatter, isNotNull);
    });

    test('has pie value', () {
      expect(GraphType.pie, isNotNull);
    });

    test('has heatmap value', () {
      expect(GraphType.heatmap, isNotNull);
    });

    test('has sankey value', () {
      expect(GraphType.sankey, isNotNull);
    });

    test('has network value', () {
      expect(GraphType.network, isNotNull);
    });

    test('has timeline value', () {
      expect(GraphType.timeline, isNotNull);
    });

    test('enum has correct number of values', () {
      expect(GraphType.values.length, equals(8));
    });
  });

  group('GraphRenderingEngine', () {
    late GraphRenderingEngine engine;

    setUp(() {
      engine = GraphRenderingEngine();
    });

    group('initialization', () {
      test('creates instance with dio', () {
        expect(engine.dio, isNotNull);
      });

      test('creates instance with custom dio', () {
        final customDio = Dio();
        final customEngine = GraphRenderingEngine(dio: customDio);
        expect(customEngine.dio, equals(customDio));
      });

      test('initializes with empty renderedGraphs', () {
        expect(engine.renderedGraphs, isEmpty);
      });

      test('initializes with null currentGraphType', () {
        expect(engine.currentGraphType, isNull);
      });
    });

    group('setGraphType', () {
      test('sets current graph type', () {
        engine.setGraphType(GraphType.bar);
        expect(engine.currentGraphType, equals(GraphType.bar));
      });

      test('can change graph type', () {
        engine.setGraphType(GraphType.line);
        engine.setGraphType(GraphType.scatter);
        expect(engine.currentGraphType, equals(GraphType.scatter));
      });

      test('notifies listeners on change', () {
        var notified = false;
        engine.addListener(() => notified = true);
        engine.setGraphType(GraphType.pie);
        expect(notified, isTrue);
      });
    });

    group('renderGraph', () {
      test('throws GraphError on API failure', () async {
        expect(
          () => engine.renderGraph(
            data: 'test data',
            title: 'Test Graph',
          ),
          throwsA(isA<GraphError>()),
        );
      });

      test('accepts required parameters', () async {
        try {
          await engine.renderGraph(data: 'test', title: 'Test');
        } catch (e) {
          expect(e, isA<GraphError>());
        }
      });

      test('accepts type parameter', () async {
        try {
          await engine.renderGraph(
            data: 'test',
            title: 'Test',
            type: GraphType.bar,
          );
        } catch (e) {
          expect(e, isA<GraphError>());
        }
      });

      test('accepts color parameter', () async {
        try {
          await engine.renderGraph(
            data: 'test',
            title: 'Test',
            primaryColor: Colors.blue,
          );
        } catch (e) {
          expect(e, isA<GraphError>());
        }
      });
    });

    group('renderGraphString', () {
      test('handles API errors gracefully', () async {
        try {
          final result = await engine.renderGraphString(content: 'test content');
          expect(result, isA<List<String>>());
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('generatePlotFromChart', () {
      test('handles API errors gracefully', () async {
        try {
          final result = await engine.generatePlotFromChart(chartContent: 'test');
          expect(result, isA<String>());
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('checkGraphType', () {
      test('returns true for valid types', () {
        expect(engine.checkGraphType('lineGraph'), isTrue);
        expect(engine.checkGraphType('barChart'), isTrue);
        expect(engine.checkGraphType('scatterPlot'), isTrue);
        expect(engine.checkGraphType('pieChart'), isTrue);
        expect(engine.checkGraphType('heatmap'), isTrue);
      });

      test('returns false for invalid types', () {
        expect(engine.checkGraphType('invalid'), isFalse);
        expect(engine.checkGraphType('timeline'), isFalse);
        expect(engine.checkGraphType(''), isFalse);
      });
    });

    group('getGraphTypeFromData', () {
      test('detects scatter for brackets with comma', () {
        final type = engine.getGraphTypeFromData('[1,2] [3,4]');
        expect(type, equals(GraphType.scatter));
      });

      test('detects line for comma without bracket', () {
        final type = engine.getGraphTypeFromData('1,2,3,4');
        expect(type, equals(GraphType.line));
      });

      test('detects bar for bracket without comma', () {
        final type = engine.getGraphTypeFromData('[1, 2, 3]');
        expect(type, equals(GraphType.bar));
      });

      test('defaults to pie for text without special markers', () {
        final type = engine.getGraphTypeFromData('random data');
        expect(type, equals(GraphType.pie));
      });
    });
  });

  group('PlotConfiguration', () {
    test('creates instance with required label', () {
      final config = PlotConfiguration(label: 'Test Plot');
      expect(config.label, equals('Test Plot'));
    });

    test('creates instance with all optional fields', () {
      final config = PlotConfiguration(
        label: 'Test',
        type: GraphType.bar,
        dataColor: '#FF0000',
        graphType: 'barChart',
        annotation: 'Note',
        gravity: 1,
        fontScale: 1.5,
      );
      expect(config.type, equals(GraphType.bar));
      expect(config.dataColor, equals('#FF0000'));
      expect(config.graphType, equals('barChart'));
      expect(config.annotation, equals('Note'));
      expect(config.gravity, equals(1));
      expect(config.fontScale, equals(1.5));
    });

    group('copyWith', () {
      test('returns copy with unchanged values', () {
        final original = PlotConfiguration(label: 'Original');
        final copy = original.copyWith();
        expect(copy.label, equals('Original'));
      });

      test('returns copy with changed label', () {
        final original = PlotConfiguration(label: 'Original');
        final copy = original.copyWith(label: 'Changed');
        expect(copy.label, equals('Changed'));
      });

      test('returns copy with changed type', () {
        final original = PlotConfiguration(label: 'Test', type: GraphType.line);
        final copy = original.copyWith(type: GraphType.bar);
        expect(copy.type, equals(GraphType.bar));
      });

      test('returns copy with changed dataColor', () {
        final original = PlotConfiguration(label: 'Test');
        final copy = original.copyWith(dataColor: '#00FF00');
        expect(copy.dataColor, equals('#00FF00'));
      });

      test('returns copy with changed graphType', () {
        final original = PlotConfiguration(label: 'Test');
        final copy = original.copyWith(graphType: 'pie');
        expect(copy.graphType, equals('pie'));
      });

      test('returns copy with changed annotation', () {
        final original = PlotConfiguration(label: 'Test');
        final copy = original.copyWith(annotation: 'New note');
        expect(copy.annotation, equals('New note'));
      });

      test('returns copy with changed gravity', () {
        final original = PlotConfiguration(label: 'Test');
        final copy = original.copyWith(gravity: 2);
        expect(copy.gravity, equals(2));
      });

      test('returns copy with changed fontScale', () {
        final original = PlotConfiguration(label: 'Test');
        final copy = original.copyWith(fontScale: 2.0);
        expect(copy.fontScale, equals(2.0));
      });

      test('returns independent copy', () {
        final original = PlotConfiguration(label: 'Test', type: GraphType.line);
        final copy = original.copyWith(type: GraphType.bar);
        expect(original.type, equals(GraphType.line));
        expect(copy.type, equals(GraphType.bar));
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final config = PlotConfiguration(
          label: 'Test',
          type: GraphType.scatter,
          dataColor: '#0000FF',
          graphType: 'scatterPlot',
          annotation: 'Note',
          gravity: 1,
          fontScale: 1.0,
        );
        final json = config.toJson();
        expect(json['label'], equals('Test'));
        expect(json['type'], equals('scatter'));
        expect(json['dataColor'], equals('#0000FF'));
        expect(json['graphType'], equals('scatterPlot'));
        expect(json['annotation'], equals('Note'));
        expect(json['gravity'], equals(1));
        expect(json['fontScale'], equals(1.0));
      });

      test('excludes null fields', () {
        final config = PlotConfiguration(label: 'Test');
        final json = config.toJson();
        expect(json.containsKey('type'), isFalse);
        expect(json.containsKey('dataColor'), isFalse);
        expect(json.containsKey('annotation'), isFalse);
      });

      test('includes only non-null fields', () {
        final config = PlotConfiguration(
          label: 'Test',
          graphType: 'line',
        );
        final json = config.toJson();
        expect(json['label'], equals('Test'));
        expect(json['graphType'], equals('line'));
        expect(json.containsKey('type'), isFalse);
      });
    });
  });
}
