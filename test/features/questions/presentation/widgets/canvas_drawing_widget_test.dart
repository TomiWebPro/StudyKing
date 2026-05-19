import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/data/models/drawing_models.dart';
import 'package:studyking/features/questions/presentation/painters/drawing_painter.dart';
import 'package:studyking/features/questions/presentation/painters/grid_painter.dart';

void main() {
  group('Stroke model', () {
    test('creates with defaults', () {
      final stroke = Stroke(points: []);
      expect(stroke.points, isEmpty);
      expect(stroke.color, Colors.black);
      expect(stroke.strokeWidth, 3);
    });

    test('creates with custom color', () {
      final stroke = Stroke(points: [], color: Colors.red);
      expect(stroke.color, Colors.red);
    });

    test('creates with custom stroke width', () {
      final stroke = Stroke(points: [], strokeWidth: 5.0);
      expect(stroke.strokeWidth, 5.0);
    });

    test('creates with single point', () {
      final stroke = Stroke(points: [DrawingPoint(point: const Offset(10, 20))]);
      expect(stroke.points.length, 1);
    });
  });

  group('DrawingPoint model', () {
    test('creates with required point', () {
      final point = DrawingPoint(point: const Offset(10, 20));
      expect(point.point, const Offset(10, 20));
      expect(point.pressure, isNull);
    });

    test('creates with pressure', () {
      final point = DrawingPoint(point: const Offset(10, 20), pressure: 0.5);
      expect(point.point, const Offset(10, 20));
      expect(point.pressure, 0.5);
    });
  });

  group('DrawingPainter shouldRepaint', () {
    test('does not repaint when strokes are identical', () {
      final strokes = [Stroke(points: [DrawingPoint(point: const Offset(10, 10))])];
      final painter1 = DrawingPainter(strokes: strokes);
      final painter2 = DrawingPainter(strokes: strokes);
      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('does not repaint GridPainter', () {
      final painter1 = GridPainter();
      final painter2 = GridPainter();
      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('shouldRepaint returns true for different stroke lists', () {
      final s1 = [Stroke(points: [DrawingPoint(point: const Offset(0, 0))])];
      final s2 = [Stroke(points: [DrawingPoint(point: const Offset(10, 10))])];
      final painter1 = DrawingPainter(strokes: s1);
      final painter2 = DrawingPainter(strokes: s2);
      expect(painter1.shouldRepaint(painter2), isTrue);
    });
  });

  group('GridPainter', () {
    test('repaints on different grid color', () {
      final p1 = GridPainter(gridColor: Colors.red);
      final p2 = GridPainter(gridColor: Colors.blue);
      expect(p1.shouldRepaint(p2), isTrue);
    });

    test('does not repaint on same grid color', () {
      final p1 = GridPainter(gridColor: Colors.grey);
      final p2 = GridPainter(gridColor: Colors.grey);
      expect(p1.shouldRepaint(p2), isFalse);
    });
  });

  group('Stroke model equality', () {
    test('two identical strokes have same properties', () {
      final s1 = Stroke(points: [DrawingPoint(point: const Offset(10, 20))]);
      final s2 = Stroke(points: [DrawingPoint(point: const Offset(10, 20))]);
      expect(s1.points.length, s2.points.length);
      expect(s1.color, s2.color);
      expect(s1.strokeWidth, s2.strokeWidth);
    });
  });

  group('DrawingPoint model edge cases', () {
    test('creates with zero offset', () {
      final point = DrawingPoint(point: Offset.zero, pressure: 1.0);
      expect(point.point, Offset.zero);
      expect(point.pressure, 1.0);
    });

    test('creates without pressure', () {
      final point = DrawingPoint(point: const Offset(5, 10));
      expect(point.point.dx, 5);
      expect(point.point.dy, 10);
      expect(point.pressure, isNull);
    });
  });
}
