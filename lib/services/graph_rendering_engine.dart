// COMPLETE GRAPH RENDERING ENGINE
// Renders graphs (line, bar, scatter, pie) and validates graph types
// Supports LLM input and graph type checking

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:charting_flutter/charting_flutter.dart';
import 'package:graphing/graphing.dart';

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
  Map<String, GraphPath> renderedGraphs = {};
  GraphType? currentGraphType;

  GraphRenderingEngine({Dio? dio}) : dio = dio ?? Dio();

  void setGraphType(GraphType type) {
    currentGraphType = type;
    notifyListeners();
  }

  Future<GraphData> renderGraph({
    required String data,
    required String title,
    GraphType type = GraphType.line,
    Color? primaryColor,
  }) async {
    try {
      final response = await dio.get('/api/v1/graph/render', data: {
        'data': data,
        'title': title,
        'type': type.name,
        'primaryColor': primaryColor?.value.toString(),
      });
      
      return GraphData(
        graphData: response.data['data'],
        path: response.data['path'],
        graphType: type,
        graphTitle: title,
      );
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
    return await dio.get(
      '/api/v1/graphing/plot_r_eq',
      data: {
        'content': content,
        'schemeName': schemeName,
        'schemes': schemes,
        'columns': columns,
      },
    );
  }

  /// Generate plot from chart
  Future<String> generatePlotFromChart({
    required String chartContent,
    String? equation,
  }) async {
    final plot = await dio.get(
      '/api/v1/plot',
      data: {
        'chartContent': chartContent,
        'equation': equation,
      },
    );
    return plot.data;
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
    if (data.contains(',')) return GraphType.line;
    if (data.contains('[')) return GraphType.bar;
    if (data.contains('[') && data.contains(']')) return GraphType.scatter;
    return GraphType.pie;
  }
}

/// Graph drawing service
class GraphDrawingService {
  List<GraphCoordinate> _coordinates = [];
  GraphCoordinates get _coords => GraphCoordinates(
    width: 1600,
    height: 1200,
    graphText: 'graph_table',
    plotCurve: 'plot_curve equation',
    image: 'graph_image',
  );

  GraphCoordinates _graphData = GraphCoordinates();

  void updateCoordinates(GraphCoordinate coordinate) {
    _coordinates.add(coordinate);
  }

  void drawCoordinates() {
    _graphData = _graphData;
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
      if (type != null) 'type': type,
      if (dataColor != null) 'dataColor': dataColor,
      if (graphType != null) 'graphType': graphType,
      if (annotation != null) 'annotation': annotation,
      if (gravity != null) 'gravity': gravity,
      if (fontScale != null) 'fontScale': fontScale,
    };
  }
}