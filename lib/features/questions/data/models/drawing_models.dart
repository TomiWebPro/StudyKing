import 'package:flutter/material.dart';

class Stroke {
  final List<DrawingPoint> points;
  final Color color;
  final double strokeWidth;

  Stroke({required this.points, this.color = Colors.black, this.strokeWidth = 3});
}

class DrawingPoint {
  final Offset point;
  final double? pressure;

  DrawingPoint({required this.point, this.pressure});
}
