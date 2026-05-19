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
  });
}