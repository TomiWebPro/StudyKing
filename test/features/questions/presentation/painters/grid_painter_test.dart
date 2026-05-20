import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/presentation/painters/grid_painter.dart';

void main() {
  group('GridPainter', () {
    test('paint draws without error', () {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(100, 100);
      final painter = GridPainter();
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });

    test('paint with custom grid color draws without error', () {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(50, 50);
      final painter = GridPainter(gridColor: Colors.blue);
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });

    test('paint with zero size handles without error', () {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size.zero;
      final painter = GridPainter();
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });

    test('paint with very small size draws at least one line', () {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(5, 5);
      final painter = GridPainter();
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });

    test('paint with non-square size draws without error', () {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(200, 300);
      final painter = GridPainter();
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });

    test('shouldRepaint returns true for different color', () {
      final p1 = GridPainter(gridColor: Colors.red);
      final p2 = GridPainter(gridColor: Colors.blue);
      expect(p1.shouldRepaint(p2), isTrue);
    });

    test('shouldRepaint returns false for same color', () {
      final p1 = GridPainter(gridColor: Colors.grey);
      final p2 = GridPainter(gridColor: Colors.grey);
      expect(p1.shouldRepaint(p2), isFalse);
    });

    test('uses default grid color when not specified', () {
      final painter = GridPainter();
      expect(painter.gridColor, const Color(0xFF9E9E9E));
    });

    test('paint with large size does not crash', () {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(2000, 2000);
      final painter = GridPainter();
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });

    test('paint with size exactly at line interval draws boundary line', () {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(20, 20);
      final painter = GridPainter();
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });

    test('paint with height smaller than interval still draws at y=0', () {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(100, 5);
      final painter = GridPainter();
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });

    test('paint with width smaller than interval still draws at x=0', () {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(5, 100);
      final painter = GridPainter();
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });

    test('shouldRepaint returns true for different default vs custom color', () {
      final p1 = GridPainter();
      final p2 = GridPainter(gridColor: Colors.red);
      expect(p1.shouldRepaint(p2), isTrue);
    });

    test('shouldRepaint returns false for self', () {
      final painter = GridPainter();
      expect(painter.shouldRepaint(painter), isFalse);
    });
  });

  group('GridPainter - pixel verification', () {
    test('paint with 100x100 size produces non-transparent pixels on grid lines', () async {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(100, 100);
      final painter = GridPainter(gridColor: Colors.black);
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(100, 100);
      final byteData = await image.toByteData();
      expect(byteData, isNotNull);
      final pixels = byteData!.buffer.asUint32List();
      final pixelAtIntersection = pixels[0 * 100 + 0];
      expect((pixelAtIntersection >> 24) & 0xFF, greaterThan(0));
      final pixelOnHorizontalLine = pixels[20 * 100 + 50];
      expect((pixelOnHorizontalLine >> 24) & 0xFF, greaterThan(0));
      final pixelOnVerticalLine = pixels[50 * 100 + 20];
      expect((pixelOnVerticalLine >> 24) & 0xFF, greaterThan(0));
      final pixelBetweenLines = pixels[10 * 100 + 10];
      expect((pixelBetweenLines >> 24) & 0xFF, 0);
    });

    test('paint with zero size produces transparent image', () async {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size.zero;
      final painter = GridPainter();
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(1, 1);
      final byteData = await image.toByteData();
      expect(byteData, isNotNull);
      final pixels = byteData!.buffer.asUint32List();
      expect(pixels.length, 1);
      final alpha = (pixels[0] >> 24) & 0xFF;
      expect(alpha, 0);
    });

    test('paint with custom color draws visible lines', () async {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(100, 100);
      final painter = GridPainter(gridColor: Colors.red);
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(100, 100);
      final byteData = await image.toByteData();
      expect(byteData, isNotNull);
      final pixels = byteData!.buffer.asUint32List();
      final pixelOnLine = pixels[20 * 100 + 50];
      expect((pixelOnLine >> 24) & 0xFF, greaterThan(0));
      final pixelBetweenLines = pixels[10 * 100 + 10];
      expect((pixelBetweenLines >> 24) & 0xFF, 0);
    });

    test('paint with 40x60 size draws lines at correct spacing', () async {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(40, 60);
      final painter = GridPainter(gridColor: Colors.black);
      painter.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(40, 60);
      final byteData = await image.toByteData();
      expect(byteData, isNotNull);
      final pixels = byteData!.buffer.asUint32List();
      // On line at y=20: pixel (5, 20) should be non-transparent
      expect(((pixels[20 * 40 + 5] >> 24) & 0xFF), greaterThan(0));
      // On line at y=40: pixel (5, 40) should be non-transparent
      expect(((pixels[40 * 40 + 5] >> 24) & 0xFF), greaterThan(0));
      // Between lines at y=30, x=30: pixel (30, 30) should be transparent
      expect(((pixels[30 * 40 + 30] >> 24) & 0xFF), 0);
    });
  });
}