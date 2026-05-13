import 'dart:convert';
import 'package:dio/dio.dart';

enum GraphDetectionResult { success, partial, error }

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

class GraphTypeValidator {
  final Map<String, String> recognizedGraphTypes = {
    'barChart': 'bar',
    'lineGraph': 'line',
    'scatterPlot': 'scatter',
    'pieChart': 'pie',
    'heatmap': 'heatmap',
  };

  bool validateGraphType(String type) => recognizedGraphTypes.containsKey(type);

  GraphValidationResult validateAndDetect(String content) {
    final type = detectGraphTypeFromContent(content);
    final valid = validateGraphFormat(content);
    return GraphValidationResult(
      detectedType: type,
      isValid: valid,
      message: valid ? 'Valid graph format' : 'Invalid format',
    );
  }

  String detectGraphTypeFromContent(String content) {
    if (content.contains(',') && content.contains('[')) return 'scatterPlot';
    if (content.contains('heatmap')) return 'heatmap';
    if (content.contains(',') && !content.contains('[')) return 'lineGraph';
    if (content.contains('{')) return 'pieChart';
    return 'unknown';
  }

  bool validateGraphFormat(String content) {
    if (content.isEmpty) return false;
    try {
      jsonDecode(content);
      return true;
    } catch (_) {
      return false;
    }
  }

  String normalizeGraphType(String type) {
    if (recognizedGraphTypes.containsKey(type)) return type.toLowerCase();
    return 'unknown';
  }
}

class GraphValidationResult {
  final String detectedType;
  final bool isValid;
  final String message;

  GraphValidationResult({
    this.detectedType = 'unknown',
    this.isValid = false,
    this.message = 'Validation failed',
  });

  factory GraphValidationResult.fromJson(Map<String, dynamic> json) {
    return GraphValidationResult(
      detectedType: json['detectedType'] as String? ?? 'unknown',
      isValid: json['isValid'] as bool? ?? false,
      message: json['message'] as String? ?? 'Validation failed',
    );
  }

  Map<String, dynamic> toJson() => {
    'detectedType': detectedType,
    'isValid': isValid,
    'message': message,
  };
}

class GraphAnalysis {
  final String type;
  final String? suggestedType;
  final Map<String, dynamic>? data;
  final String? suggestion;
  final String? error;

  GraphAnalysis({
    this.type = 'unknown',
    this.suggestedType,
    this.data,
    this.suggestion,
    this.error,
  });

  factory GraphAnalysis.failure({String? exception}) {
    return GraphAnalysis(
      type: 'unknown',
      error: 'Analysis failed',
    );
  }

  factory GraphAnalysis.fromJson(Map<String, dynamic> json) {
    return GraphAnalysis(
      type: json['type'] as String? ?? 'unknown',
      suggestedType: json['suggestedType'] as String?,
      data: json['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['data'])
          : null,
      suggestion: json['suggestion'] as String?,
    );
  }
}

class GraphAnalyzer {
  final Dio dio;

  GraphAnalyzer({Dio? dio}) : dio = dio ?? Dio();

  Future<GraphAnalysis> analyzeGraph(String data) async {
    return GraphAnalysis.failure();
  }

  Future<String> detectGraphTypes(String data) async {
    return 'unknown';
  }

  String renderGraphFromJSON(Map<String, dynamic> json) {
    return jsonEncode(json);
  }
}

enum GraphErrorType { invalidFormat, unsupportedType, emptyData, missingTitle }

class GraphError implements Exception {
  final String details;
  final GraphErrorType errorType;

  GraphError(this.details, {this.errorType = GraphErrorType.invalidFormat});

  @override
  String toString() => 'GraphError: ${errorType.name} - $details';
}
