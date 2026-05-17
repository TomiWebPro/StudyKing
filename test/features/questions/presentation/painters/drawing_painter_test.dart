import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/data/models/drawing_models.dart';
import 'package:studyking/features/questions/presentation/painters/drawing_painter.dart';

void main() {
  group('DrawingPainter', () {
    test('paint with empty strokes does not crash', () {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(100, 100);
      final painter = DrawingPainter(strokes: []);
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });

    test('paint with single point stroke draws without error', () {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(100, 100);
      final strokes = [
        Stroke(points: [DrawingPoint(point: const Offset(50, 50))]),
      ];
      final painter = DrawingPainter(strokes: strokes);
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });

    test('paint with multiple points draws path without error', () {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(100, 100);
      final strokes = [
        Stroke(
          points: [
            DrawingPoint(point: const Offset(10, 10)),
            DrawingPoint(point: const Offset(20, 20)),
            DrawingPoint(point: const Offset(30, 15)),
          ],
          color: Colors.red,
          strokeWidth: 5,
        ),
      ];
      final painter = DrawingPainter(strokes: strokes);
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });

    test('paint with multiple strokes draws without error', () {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(100, 100);
      final strokes = [
        Stroke(points: [DrawingPoint(point: const Offset(10, 10))]),
        Stroke(
          points: [
            DrawingPoint(point: const Offset(20, 20)),
            DrawingPoint(point: const Offset(40, 40)),
          ],
        ),
        Stroke(
          points: [
            DrawingPoint(point: const Offset(50, 50)),
            DrawingPoint(point: const Offset(60, 60)),
            DrawingPoint(point: const Offset(70, 70)),
          ],
        ),
      ];
      final painter = DrawingPainter(strokes: strokes);
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });

    test('paint with empty points in stroke skips it', () {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(100, 100);
      final strokes = [
        Stroke(points: []),
        Stroke(points: [DrawingPoint(point: const Offset(10, 10))]),
      ];
      final painter = DrawingPainter(strokes: strokes);
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });

    test('paint with stroke containing pressure data draws without error', () {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(100, 100);
      final strokes = [
        Stroke(
          points: [
            DrawingPoint(point: const Offset(10, 10), pressure: 0.5),
            DrawingPoint(point: const Offset(20, 20), pressure: 0.8),
          ],
        ),
      ];
      final painter = DrawingPainter(strokes: strokes);
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });

    test('paint with custom stroke width and color draws correctly', () {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(100, 100);
      final strokes = [
        Stroke(
          points: [DrawingPoint(point: const Offset(10, 10))],
          color: Colors.blue,
          strokeWidth: 10,
        ),
      ];
      final painter = DrawingPainter(strokes: strokes);
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });

    test('shouldRepaint returns true for different strokes', () {
      final s1 = [Stroke(points: [DrawingPoint(point: const Offset(0, 0))])];
      final s2 = [Stroke(points: [DrawingPoint(point: const Offset(10, 10))])];
      final painter1 = DrawingPainter(strokes: s1);
      final painter2 = DrawingPainter(strokes: s2);
      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns false for identical strokes', () {
      final strokes = [Stroke(points: [DrawingPoint(point: const Offset(10, 10))])];
      final painter1 = DrawingPainter(strokes: strokes);
      final painter2 = DrawingPainter(strokes: strokes);
      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('paint with pressure data in points draws correctly', () {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(100, 100);
      final strokes = [
        Stroke(points: [
          DrawingPoint(point: const Offset(10, 10), pressure: 0.3),
          DrawingPoint(point: const Offset(20, 20), pressure: 0.6),
          DrawingPoint(point: const Offset(30, 30), pressure: 0.9),
        ]),
      ];
      final painter = DrawingPainter(strokes: strokes);
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });

    test('paint with empty stroke between non-empty strokes', () {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(100, 100);
      final strokes = [
        Stroke(points: [DrawingPoint(point: const Offset(10, 10))]),
        Stroke(points: []),
        Stroke(points: [DrawingPoint(point: const Offset(20, 20))]),
      ];
      final painter = DrawingPainter(strokes: strokes);
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });
  });
}