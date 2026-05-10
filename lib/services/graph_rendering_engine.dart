// COMPLETE GRAPH RENDERING ENGINE
// Renders graphs (line, bar, scatter, pie) and validates graph types
// Supports LLM input and graph type checking

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'graph_type_detector.dart';

/// Graph visualization configuration
enum GraphType {
  line,
  bar,
  scatter,
  pie,
  heatmap,
  sankey,
  network,
  timeline,
}

/// Graph rendering service
class GraphRenderingEngine extends ChangeNotifier {
  final Dio dio;
  Map<String, Map<String, dynamic>> renderedGraphs = {};
  GraphType? currentGraphType;

  GraphRenderingEngine({Dio? dio}) : dio = dio ?? Dio();

  void setGraphType(GraphType type) {
    currentGraphType = type;
    notifyListeners();
  }

  Future<Map<String, dynamic>> renderGraph({
    required String data,
    required String title,
    GraphType type = GraphType.line,
    Color? primaryColor,
  }) async {
    try {
      final response = await dio.post('/api/v1/graph/render', data: {
        'data': data,
        'title': title,
        'type': type.name,
        'primaryColor': primaryColor?.toARGB32().toString(),
      });

      return response.data is Map ? response.data as Map<String, dynamic> : <String, dynamic>{};
    } catch (e) {
      throw GraphError('Graph rendering failed: $e');
    }
  }

  Future<List<String>> renderGraphString({
    required String content,
    String? schemeName,
    Iterable<Color>? schemes,
    int? columns,
  }) async {
    final response = await dio.post(
      '/api/v1/graphing/plot_r_eq',
      data: {
        'content': content,
        'schemeName': schemeName,
        'schemes': schemes,
        'columns': columns,
      },
    );
    if (response.data is List) {
      return List<String>.from(response.data as List);
    }
    return [];
  }

  /// Generate plot from chart
  Future<String> generatePlotFromChart({
    required String chartContent,
    String? equation,
  }) async {
    final response = await dio.post(
      '/api/v1/plot',
      data: {
        'chartContent': chartContent,
        'equation': equation,
      },
    );
    return response.data?.toString() ?? '';
  }

  /// Check graph type validation
  bool checkGraphType(String graphType) {
    final validTypes = [
      'lineGraph',
      'barChart',
      'scatterPlot',
      'pieChart',
      'heatmap',
    ];
    return validTypes.contains(graphType);
  }

  /// Get graph type from data
  GraphType getGraphTypeFromData(String data) {
    if (data.contains('[') && data.contains(']')) return GraphType.scatter;
    if (data.contains(',')) return GraphType.line;
    if (data.contains('[')) return GraphType.bar;
    return GraphType.pie;
  }
}

/// Plot configuration
class PlotConfiguration {
  final String label;
  GraphType? type;
  String? dataColor;
  String? graphType;
  String? annotation;
  int? gravity;
  double? fontScale;

  PlotConfiguration({
    required this.label,
    this.type,
    this.dataColor,
    this.graphType,
    this.annotation,
    this.gravity,
    this.fontScale,
  });

  PlotConfiguration copyWith({
    String? label,
    GraphType? type,
    String? dataColor,
    String? graphType,
    String? annotation,
    int? gravity,
    double? fontScale,
  }) {
    return PlotConfiguration(
      label: label ?? this.label,
      type: type ?? this.type,
      dataColor: dataColor ?? this.dataColor,
      graphType: graphType ?? this.graphType,
      annotation: annotation ?? this.annotation,
      gravity: gravity ?? this.gravity,
      fontScale: fontScale ?? this.fontScale,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      if (type != null) 'type': type!.name,
      if (dataColor != null) 'dataColor': dataColor,
      if (graphType != null) 'graphType': graphType,
      if (annotation != null) 'annotation': annotation,
      if (gravity != null) 'gravity': gravity,
      if (fontScale != null) 'fontScale': fontScale,
    };
  }
}
