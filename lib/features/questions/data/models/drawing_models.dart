import 'package:flutter/material.dart';

enum DrawingTool { freehand, line, rectangle, circle, plotPoint, eraser }

class Stroke {
  final List<DrawingPoint> points;
  final Color color;
  final double strokeWidth;
  final DrawingTool tool;

  Stroke({
    required this.points,
    this.color = Colors.black,
    this.strokeWidth = 3,
    this.tool = DrawingTool.freehand,
  });
}

class DrawingPoint {
  final Offset point;
  final double? pressure;

  DrawingPoint({required this.point, this.pressure});
}

class UndoableStroke {
  final Stroke stroke;

  const UndoableStroke({required this.stroke});
}
