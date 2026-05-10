// Graph Type Detection and Validation Service
// Analyzes graph type, validates format, and detects from data

import 'dart:convert';
import 'package:dio/dio.dart';

/// Graph type detection result
enum GraphDetectionResult {
  success,
  partial,
  error,
}

/// Graph validation error
class GraphValidationError {
  final String errorType;
  final String errorMessage;
  final int? errorCode;

  GraphValidationError({
    required this.errorType,
    required this.errorMessage,
    this.errorCode,
  });
}

/// Graph type validator
class GraphTypeValidator {
  final Map<String, String> recognizedGraphTypes = {
    'barChart': 'Bar chart visualization',
    'lineGraph': 'Line graph with plotted data',
    'scatterPlot': 'Scatter plot with coordinates',
    'pieChart': 'Pie chart with segments',
    'heatmap': '2D heatmap matrix',
    'sankey': 'Sankey diagram with flows',
    'network': 'Network graph with nodes',
    'timeline': 'Timeline with events',
  };

  bool validateGraphType(String graphType) {
    return recognizedGraphTypes.containsKey(graphType);
  }

  GraphValidationResult validateAndDetect(String inputData) {
    try {
      final detectedType = detectGraphTypeFromContent(inputData);
      final isValid = validateGraphFormat(inputData);
      return GraphValidationResult(
        detectedType: detectedType,
        isValid: isValid,
        message: isValid ? 'Graph valid' : 'Graph format invalid',
      );
    } catch (e) {
      return GraphValidationResult(
        detectedType: 'unknown',
        isValid: false,
        message: e.toString(),
      );
    }
  }

  String detectGraphTypeFromContent(String content) {
    if (content.contains(',') && content.contains(']')) return 'scatterPlot';
    if (content.contains('[')) return 'barChart';
    if (content.contains('}') && content.contains('"heatmap"')) return 'heatmap';
    if (content.contains(',')) return 'lineGraph';
    if (content.contains('}')) return 'pieChart';
    if (content.contains('nodes')) return 'network';
    if (content.contains('start')) return 'sankey';
    return 'unknown';
  }

  bool validateGraphFormat(String content) {
    try {
      final jsonDecoder = jsonDecode(content);
      return jsonDecoder is Map || jsonDecoder is List;
    } catch (e) {
      return false;
    }
  }

  String normalizeGraphType(String graphType) {
    final normalized = graphType.toLowerCase();
    if (recognizedGraphTypes.containsKey(normalized)) return normalized;
    return 'unknown';
  }
}

/// Graph validation result
class GraphValidationResult {
  final String detectedType;
  final bool isValid;
  final String message;

  GraphValidationResult({
    required this.detectedType,
    required this.isValid,
    required this.message,
  });

  factory GraphValidationResult.fromJson(Map<String, dynamic> json) {
    return GraphValidationResult(
      detectedType: json['detectedType'] ?? 'unknown',
      isValid: json['isValid'] ?? false,
      message: json['message'] ?? 'Validation failed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detectedType': detectedType,
      'isValid': isValid,
      'message': message,
    };
  }
}

/// Graph analyzer
class GraphAnalyzer {
  final Dio dio;

  GraphAnalyzer({Dio? dio}) : dio = dio ?? Dio();

  Future<GraphAnalysis> analyzeGraph(String graphData) async {
    try {
      final response = await dio.post(
        '/api/v1/graph/analyze',
        data: {'graphData': graphData},
      );
      return GraphAnalysis.fromJson(response.data);
    } catch (e) {
      return GraphAnalysis.failure(exception: e.toString());
    }
  }

  Future<String> detectGraphTypes(String imageData) async {
    try {
      final response = await dio.post(
        '/api/v1/graph/detect',
        data: {'imageData': imageData},
      );
      return response.data?.toString() ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  String renderGraphFromJSON(Map<String, dynamic> graphJson) {
    return jsonEncode(graphJson);
  }
}

/// Graph analysis result
class GraphAnalysis {
  final String type;
  final String? suggestedType;
  final Map<String, dynamic>? data;
  final String? suggestion;
  final String? error;

  const GraphAnalysis({
    required this.type,
    this.suggestedType,
    this.data,
    this.suggestion,
    this.error,
  });

  static GraphAnalysis failure({String? exception}) {
    return const GraphAnalysis(
      type: 'unknown',
      error: 'Analysis failed',
    );
  }

  factory GraphAnalysis.fromJson(Map<String, dynamic> json) {
    return GraphAnalysis(
      type: json['type']?.toString() ?? 'unknown',
      suggestedType: json['suggestedType'],
      data: json['data'],
      suggestion: json['suggestion'],
      error: json['error'],
    );
  }
}

/// Graph error type
enum GraphErrorType {
  invalidFormat,
  unsupportedType,
  emptyData,
  missingTitle,
}

/// Graph rendering error
class GraphError {
  final GraphErrorType errorType;
  final String? details;

  GraphError(this.details, {this.errorType = GraphErrorType.invalidFormat});

  @override
  String toString() => 'GraphError($errorType): $details';
}
