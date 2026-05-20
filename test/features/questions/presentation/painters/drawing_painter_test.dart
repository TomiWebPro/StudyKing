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

    test('shouldRepaint returns true for larger strokes list', () {
      final s1 = [Stroke(points: [DrawingPoint(point: const Offset(0, 0))])];
      final s2 = [
        Stroke(points: [DrawingPoint(point: const Offset(0, 0))]),
        Stroke(points: [DrawingPoint(point: const Offset(10, 10))]),
      ];
      final painter1 = DrawingPainter(strokes: s1);
      final painter2 = DrawingPainter(strokes: s2);
      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns true for smaller strokes list', () {
      final s1 = [
        Stroke(points: [DrawingPoint(point: const Offset(0, 0))]),
        Stroke(points: [DrawingPoint(point: const Offset(10, 10))]),
      ];
      final s2 = [Stroke(points: [DrawingPoint(point: const Offset(0, 0))])];
      final painter1 = DrawingPainter(strokes: s1);
      final painter2 = DrawingPainter(strokes: s2);
      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns false for self', () {
      final strokes = [Stroke(points: [DrawingPoint(point: const Offset(10, 10))])];
      final painter = DrawingPainter(strokes: strokes);
      expect(painter.shouldRepaint(painter), isFalse);
    });

    test('paint with negative coordinates does not crash', () {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(100, 100);
      final strokes = [
        Stroke(
          points: [
            DrawingPoint(point: const Offset(-50, -50)),
            DrawingPoint(point: const Offset(-10, -10)),
          ],
        ),
        Stroke(points: [DrawingPoint(point: const Offset(-30, -30))]),
      ];
      final painter = DrawingPainter(strokes: strokes);
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });

    test('paint with very large coordinates does not crash', () {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(100, 100);
      final strokes = [
        Stroke(
          points: [
            DrawingPoint(point: const Offset(10000, 10000)),
            DrawingPoint(point: const Offset(20000, 20000)),
          ],
        ),
      ];
      final painter = DrawingPainter(strokes: strokes);
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });

    test('paint with strokeWidth zero does not crash', () {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(100, 100);
      final strokes = [
        Stroke(
          points: [
            DrawingPoint(point: const Offset(10, 10)),
            DrawingPoint(point: const Offset(20, 20)),
          ],
          strokeWidth: 0,
        ),
      ];
      final painter = DrawingPainter(strokes: strokes);
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });

    test('paint with many points in stroke does not crash', () {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(100, 100);
      final points = List.generate(
        500,
        (i) => DrawingPoint(
          point: Offset((i % 100).toDouble(), (i ~/ 100).toDouble()),
        ),
      );
      final strokes = [Stroke(points: points)];
      final painter = DrawingPainter(strokes: strokes);
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });
  });

  group('DrawingPainter - pixel verification', () {
    test('paint with multi-point stroke produces non-transparent pixels', () async {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(100, 100);
      final strokes = [
        Stroke(
          points: [
            DrawingPoint(point: const Offset(10, 10)),
            DrawingPoint(point: const Offset(90, 90)),
          ],
          color: Colors.black,
          strokeWidth: 10,
        ),
      ];
      final painter = DrawingPainter(strokes: strokes);
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(100, 100);
      final byteData = await image.toByteData();
      expect(byteData, isNotNull);
      final pixels = byteData!.buffer.asUint32List();
      expect(pixels.length, 100 * 100);
      final pixel = pixels[50 * 100 + 50];
      final alpha = (pixel >> 24) & 0xFF;
      expect(alpha, greaterThan(0));
    });

    test('paint with single-point stroke produces non-transparent pixels', () async {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(100, 100);
      final strokes = [
        Stroke(
          points: [DrawingPoint(point: const Offset(50, 50))],
          color: Colors.black,
          strokeWidth: 10,
        ),
      ];
      final painter = DrawingPainter(strokes: strokes);
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(100, 100);
      final byteData = await image.toByteData();
      expect(byteData, isNotNull);
      final pixels = byteData!.buffer.asUint32List();
      final pixel = pixels[50 * 100 + 50];
      final alpha = (pixel >> 24) & 0xFF;
      expect(alpha, greaterThan(0));
    });

    test('paint with empty strokes produces transparent image', () async {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(100, 100);
      final painter = DrawingPainter(strokes: []);
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(100, 100);
      final byteData = await image.toByteData();
      expect(byteData, isNotNull);
      final pixels = byteData!.buffer.asUint32List();
      final pixel = pixels[50 * 100 + 50];
      final alpha = (pixel >> 24) & 0xFF;
      expect(alpha, 0);
    });

    test('paint with multiple strokes produces pixels at expected positions', () async {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(100, 100);
      final strokes = [
        Stroke(
          points: [DrawingPoint(point: const Offset(20, 20))],
          color: Colors.black,
          strokeWidth: 6,
        ),
        Stroke(
          points: [
            DrawingPoint(point: const Offset(40, 40)),
            DrawingPoint(point: const Offset(80, 80)),
          ],
          color: Colors.black,
          strokeWidth: 6,
        ),
      ];
      final painter = DrawingPainter(strokes: strokes);
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(100, 100);
      final byteData = await image.toByteData();
      expect(byteData, isNotNull);
      final pixels = byteData!.buffer.asUint32List();
      final pixelAtCircle = pixels[20 * 100 + 20];
      expect((pixelAtCircle >> 24) & 0xFF, greaterThan(0));
      final pixelOnPath = pixels[60 * 100 + 60];
      expect((pixelOnPath >> 24) & 0xFF, greaterThan(0));
    });
  });
}