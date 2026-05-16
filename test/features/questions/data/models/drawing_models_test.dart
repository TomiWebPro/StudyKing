import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/data/models/drawing_models.dart';

void main() {
  group('Stroke', () {
    test('creates with required points', () {
      final stroke = Stroke(points: []);
      expect(stroke.points, isEmpty);
    });

    test('creates with default color and stroke width', () {
      final stroke = Stroke(points: []);
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
      final stroke = Stroke(
        points: [DrawingPoint(point: const Offset(10, 20))],
      );
      expect(stroke.points.length, 1);
      expect(stroke.points.first.point.dx, 10);
      expect(stroke.points.first.point.dy, 20);
    });

    test('creates with multiple points', () {
      final stroke = Stroke(
        points: [
          DrawingPoint(point: const Offset(10, 20)),
          DrawingPoint(point: const Offset(30, 40)),
        ],
      );
      expect(stroke.points.length, 2);
    });

    test('creates with both custom color and stroke width', () {
      final stroke = Stroke(
        points: [DrawingPoint(point: Offset.zero)],
        color: Colors.green,
        strokeWidth: 2.0,
      );
      expect(stroke.color, Colors.green);
      expect(stroke.strokeWidth, 2.0);
    });
  });

  group('DrawingPoint', () {
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

    test('creates with zero offset', () {
      final point = DrawingPoint(point: Offset.zero, pressure: 1.0);
      expect(point.point, Offset.zero);
      expect(point.pressure, 1.0);
    });

    test('creates with negative coordinates', () {
      final point = DrawingPoint(point: const Offset(-10, -20));
      expect(point.point.dx, -10);
      expect(point.point.dy, -20);
      expect(point.pressure, isNull);
    });

    test('creates with null pressure', () {
      final point = DrawingPoint(point: const Offset(5, 10));
      expect(point.point.dx, 5);
      expect(point.point.dy, 10);
      expect(point.pressure, isNull);
    });

    test('creates with fractional pressure', () {
      final point = DrawingPoint(point: const Offset(0, 0), pressure: 0.75);
      expect(point.pressure, 0.75);
    });
  });
}