import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/data/models/drawing_models.dart';

void main() {
  group('GraphDrawingWidget - model integration', () {
    test('stroke with plotPoint tool has correct tool type', () {
      final stroke = Stroke(
        points: [DrawingPoint(point: const Offset(50, 50))],
        tool: DrawingTool.plotPoint,
      );
      expect(stroke.tool, DrawingTool.plotPoint);
      expect(stroke.points.length, 1);
    });

    test('stroke with line tool has correct tool type', () {
      final stroke = Stroke(
        points: [
          DrawingPoint(point: const Offset(10, 10)),
          DrawingPoint(point: const Offset(90, 90)),
        ],
        tool: DrawingTool.line,
      );
      expect(stroke.tool, DrawingTool.line);
      expect(stroke.points.length, 2);
    });

    test('stroke with freehand tool has correct tool type', () {
      final stroke = Stroke(
        points: [
          DrawingPoint(point: const Offset(10, 10)),
          DrawingPoint(point: const Offset(20, 20)),
          DrawingPoint(point: const Offset(30, 30)),
        ],
        tool: DrawingTool.freehand,
      );
      expect(stroke.tool, DrawingTool.freehand);
      expect(stroke.points.length, 3);
    });

    test('stroke with custom color and width works', () {
      final stroke = Stroke(
        points: [DrawingPoint(point: const Offset(10, 10))],
        color: Colors.red,
        strokeWidth: 5.0,
        tool: DrawingTool.plotPoint,
      );
      expect(stroke.color, Colors.red);
      expect(stroke.strokeWidth, 5.0);
      expect(stroke.tool, DrawingTool.plotPoint);
    });
  });
}
