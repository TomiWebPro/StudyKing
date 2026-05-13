import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'graph_type_detector.dart' show GraphError;

enum GraphType { line, bar, scatter, pie, heatmap, sankey, network, timeline }

class GraphRenderingEngine extends ChangeNotifier {
  final Dio dio;
  final List<String> renderedGraphs = [];
  GraphType? currentGraphType;

  GraphRenderingEngine({Dio? dio}) : dio = dio ?? Dio();

  void setGraphType(GraphType type) {
    currentGraphType = type;
    notifyListeners();
  }

  Future<void> renderGraph({
    required String data,
    required String title,
    GraphType? type,
    Color? primaryColor,
  }) async {
    throw GraphError('API failure');
  }

  Future<List<String>> renderGraphString({required String content}) async {
    throw Exception('API error');
  }

  Future<String> generatePlotFromChart({required String chartContent}) async {
    throw Exception('API error');
  }

  bool checkGraphType(String type) {
    return ['lineGraph', 'barChart', 'scatterPlot', 'pieChart', 'heatmap'].contains(type);
  }

  GraphType getGraphTypeFromData(String data) {
    if (data.contains('[') && data.contains(',')) return GraphType.scatter;
    if (data.contains(',') && !data.contains('[')) return GraphType.line;
    if (data.contains('[') && !data.contains(',')) return GraphType.bar;
    return GraphType.pie;
  }
}

class PlotConfiguration {
  final String label;
  final GraphType? type;
  final String? dataColor;
  final String? graphType;
  final String? annotation;
  final int? gravity;
  final double? fontScale;

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
    final map = <String, dynamic>{'label': label};
    if (type != null) map['type'] = type!.name;
    if (dataColor != null) map['dataColor'] = dataColor;
    if (graphType != null) map['graphType'] = graphType;
    if (annotation != null) map['annotation'] = annotation;
    if (gravity != null) map['gravity'] = gravity;
    if (fontScale != null) map['fontScale'] = fontScale;
    return map;
  }
}
