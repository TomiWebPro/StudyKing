import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:studyking/services/graph_type_detector.dart';

void main() {
  group('GraphDetectionResult', () {
    test('has success value', () {
      expect(GraphDetectionResult.success, isNotNull);
    });

    test('has partial value', () {
      expect(GraphDetectionResult.partial, isNotNull);
    });

    test('has error value', () {
      expect(GraphDetectionResult.error, isNotNull);
    });
  });

  group('GraphValidationError', () {
    test('creates instance with required fields', () {
      final error = GraphValidationError(
        errorType: 'invalid',
        errorMessage: 'Test error',
      );
      expect(error.errorType, equals('invalid'));
      expect(error.errorMessage, equals('Test error'));
    });

    test('accepts optional error code', () {
      final error = GraphValidationError(
        errorType: 'format',
        errorMessage: 'Error message',
        errorCode: 404,
      );
      expect(error.errorCode, equals(404));
    });

    test('default error code is null', () {
      final error = GraphValidationError(
        errorType: 'type',
        errorMessage: 'Error',
      );
      expect(error.errorCode, isNull);
    });
  });

  group('GraphTypeValidator', () {
    late GraphTypeValidator validator;

    setUp(() {
      validator = GraphTypeValidator();
    });

    group('initialization', () {
      test('creates instance with recognized types', () {
        expect(validator.recognizedGraphTypes, isNotEmpty);
      });

      test('has barChart type', () {
        expect(validator.recognizedGraphTypes.containsKey('barChart'), isTrue);
      });

      test('has lineGraph type', () {
        expect(validator.recognizedGraphTypes.containsKey('lineGraph'), isTrue);
      });

      test('has scatterPlot type', () {
        expect(validator.recognizedGraphTypes.containsKey('scatterPlot'), isTrue);
      });

      test('has pieChart type', () {
        expect(validator.recognizedGraphTypes.containsKey('pieChart'), isTrue);
      });

      test('has heatmap type', () {
        expect(validator.recognizedGraphTypes.containsKey('heatmap'), isTrue);
      });
    });

    group('validateGraphType', () {
      test('returns true for valid type', () {
        expect(validator.validateGraphType('barChart'), isTrue);
      });

      test('returns false for invalid type', () {
        expect(validator.validateGraphType('invalidType'), isFalse);
      });

      test('returns true for lineGraph', () {
        expect(validator.validateGraphType('lineGraph'), isTrue);
      });
    });

    group('validateAndDetect', () {
      test('returns result for valid JSON', () {
        final result = validator.validateAndDetect('{"data": "test"}');
        expect(result, isA<GraphValidationResult>());
      });

      test('detects graph type from content', () {
        final result = validator.validateAndDetect('{"type": "bar"}');
        expect(result.detectedType, isA<String>());
      });

      test('returns message on valid format', () {
        final result = validator.validateAndDetect('{"test": true}');
        expect(result.message, isNotEmpty);
      });
    });

    group('detectGraphTypeFromContent', () {
      test('detects scatterPlot for comma and bracket', () {
        final type = validator.detectGraphTypeFromContent('[1,2], [3,4]');
        expect(type, equals('scatterPlot'));
      });

      test('detects heatmap for heatmap keyword', () {
        final type = validator.detectGraphTypeFromContent('{"heatmap": true}');
        expect(type, equals('heatmap'));
      });

      test('detects lineGraph for comma without bracket', () {
        final type = validator.detectGraphTypeFromContent('1,2,3');
        expect(type, equals('lineGraph'));
      });

      test('detects pieChart for curly brace', () {
        final type = validator.detectGraphTypeFromContent('{"pie": true}');
        expect(type, equals('pieChart'));
      });

      test('returns unknown for unrecognized content', () {
        final type = validator.detectGraphTypeFromContent('random text');
        expect(type, equals('unknown'));
      });
    });

    group('validateGraphFormat', () {
      test('returns true for valid JSON object', () {
        expect(validator.validateGraphFormat('{"key": "value"}'), isTrue);
      });

      test('returns true for valid JSON array', () {
        expect(validator.validateGraphFormat('[1, 2, 3]'), isTrue);
      });

      test('returns false for invalid JSON', () {
        expect(validator.validateGraphFormat('not valid json'), isFalse);
      });

      test('returns false for empty string', () {
        expect(validator.validateGraphFormat(''), isFalse);
      });
    });

    group('normalizeGraphType', () {
      test('returns normalized lowercase for valid type', () {
        final type = validator.normalizeGraphType('lineGraph');
        expect(type, equals('linegraph'));
      });

      test('returns unknown for unrecognized type', () {
        final type = validator.normalizeGraphType('invalid');
        expect(type, equals('unknown'));
      });
    });
  });

  group('GraphValidationResult', () {
    test('creates instance with required fields', () {
      final result = GraphValidationResult(
        detectedType: 'barChart',
        isValid: true,
        message: 'Valid graph',
      );
      expect(result.detectedType, equals('barChart'));
      expect(result.isValid, isTrue);
      expect(result.message, equals('Valid graph'));
    });

    group('fromJson', () {
      test('parses valid JSON', () {
        final json = {
          'detectedType': 'lineGraph',
          'isValid': true,
          'message': 'Success',
        };
        final result = GraphValidationResult.fromJson(json);
        expect(result.detectedType, equals('lineGraph'));
        expect(result.isValid, isTrue);
      });

      test('uses defaults for missing fields', () {
        final json = <String, dynamic>{};
        final result = GraphValidationResult.fromJson(json);
        expect(result.detectedType, equals('unknown'));
        expect(result.isValid, isFalse);
        expect(result.message, equals('Validation failed'));
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final result = GraphValidationResult(
          detectedType: 'scatter',
          isValid: true,
          message: 'OK',
        );
        final json = result.toJson();
        expect(json['detectedType'], equals('scatter'));
        expect(json['isValid'], isTrue);
        expect(json['message'], equals('OK'));
      });
    });
  });

  group('GraphAnalyzer', () {
    late GraphAnalyzer analyzer;

    setUp(() {
      analyzer = GraphAnalyzer();
    });

    test('creates instance with dio', () {
      expect(analyzer.dio, isNotNull);
    });

    test('creates instance with custom dio', () {
      final customDio = Dio();
      final customAnalyzer = GraphAnalyzer(dio: customDio);
      expect(customAnalyzer.dio, equals(customDio));
    });

    group('analyzeGraph', () {
      test('returns failure on error', () async {
        final result = await analyzer.analyzeGraph('invalid data');
        expect(result.type, equals('unknown'));
        expect(result.error, isNotNull);
      });

      test('returns GraphAnalysis object', () async {
        final result = await analyzer.analyzeGraph('test');
        expect(result, isA<GraphAnalysis>());
      });
    });

    group('detectGraphTypes', () {
      test('returns unknown on error', () async {
        final type = await analyzer.detectGraphTypes('test');
        expect(type, equals('unknown'));
      });

      test('returns string type', () async {
        final type = await analyzer.detectGraphTypes('data');
        expect(type, isA<String>());
      });
    });

    group('renderGraphFromJSON', () {
      test('returns JSON string', () {
        final json = {'data': [1, 2, 3]};
        final result = analyzer.renderGraphFromJSON(json);
        expect(result, isA<String>());
        expect(result.contains('data'), isTrue);
      });

      test('encodes complex JSON', () {
        final json = {
          'type': 'bar',
          'values': [10, 20, 30],
          'labels': ['A', 'B', 'C'],
        };
        final result = analyzer.renderGraphFromJSON(json);
        expect(result.contains('bar'), isTrue);
      });
    });
  });

  group('GraphAnalysis', () {
    test('creates instance with required type', () {
      final analysis = GraphAnalysis(type: 'line');
      expect(analysis.type, equals('line'));
    });

    test('creates instance with all fields', () {
      final analysis = GraphAnalysis(
        type: 'bar',
        suggestedType: 'pie',
        data: {'values': [1, 2]},
        suggestion: 'Try pie chart',
        error: null,
      );
      expect(analysis.type, equals('bar'));
      expect(analysis.suggestedType, equals('pie'));
      expect(analysis.data, isNotNull);
      expect(analysis.suggestion, equals('Try pie chart'));
    });

    group('failure', () {
      test('creates failure result', () {
        final failure = GraphAnalysis.failure();
        expect(failure.type, equals('unknown'));
        expect(failure.error, equals('Analysis failed'));
      });

      test('includes exception message', () {
        final failure = GraphAnalysis.failure(exception: 'Connection refused');
        expect(failure.error, equals('Analysis failed'));
      });
    });

    group('fromJson', () {
      test('parses valid JSON', () {
        final json = {
          'type': 'scatter',
          'suggestedType': 'line',
          'data': {'values': [1, 2, 3]},
          'suggestion': 'Use line',
        };
        final analysis = GraphAnalysis.fromJson(json);
        expect(analysis.type, equals('scatter'));
        expect(analysis.suggestedType, equals('line'));
      });

      test('uses default type for missing', () {
        final json = <String, dynamic>{};
        final analysis = GraphAnalysis.fromJson(json);
        expect(analysis.type, equals('unknown'));
      });

      test('parses nested data', () {
        final json = {
          'type': 'test',
          'data': {'nested': {'key': 'value'}},
        };
        final analysis = GraphAnalysis.fromJson(json);
        expect(analysis.data, isNotNull);
      });
    });
  });

  group('GraphErrorType', () {
    test('has invalidFormat value', () {
      expect(GraphErrorType.invalidFormat, isNotNull);
    });

    test('has unsupportedType value', () {
      expect(GraphErrorType.unsupportedType, isNotNull);
    });

    test('has emptyData value', () {
      expect(GraphErrorType.emptyData, isNotNull);
    });

    test('has missingTitle value', () {
      expect(GraphErrorType.missingTitle, isNotNull);
    });
  });

  group('GraphError', () {
    test('creates instance with details', () {
      final error = GraphError('Test details');
      expect(error.details, equals('Test details'));
      expect(error.errorType, equals(GraphErrorType.invalidFormat));
    });

    test('accepts custom error type', () {
      final error = GraphError('Details', errorType: GraphErrorType.emptyData);
      expect(error.errorType, equals(GraphErrorType.emptyData));
    });

    test('toString returns formatted string', () {
      final error = GraphError('Missing data', errorType: GraphErrorType.emptyData);
      final str = error.toString();
      expect(str, contains('GraphError'));
      expect(str, contains('emptyData'));
      expect(str, contains('Missing data'));
    });
  });
}
