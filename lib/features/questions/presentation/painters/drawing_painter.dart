import 'package:flutter/material.dart';
import 'package:studyking/features/questions/data/models/drawing_models.dart';

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Color canvasBackgroundColor;

  DrawingPainter({required this.strokes, this.canvasBackgroundColor = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      if (stroke.tool == DrawingTool.eraser) {
        final eraserPaint = Paint()
          ..color = canvasBackgroundColor
          ..strokeWidth = stroke.strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        _drawFreehand(canvas, stroke, eraserPaint);
        continue;
      }
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      switch (stroke.tool) {
        case DrawingTool.freehand:
          _drawFreehand(canvas, stroke, paint);
        case DrawingTool.line:
          _drawLine(canvas, stroke, paint);
        case DrawingTool.rectangle:
          _drawRectangle(canvas, stroke, paint);
        case DrawingTool.circle:
          _drawCircle(canvas, stroke, paint);
        case DrawingTool.plotPoint:
          final p = stroke.points.first.point;
          canvas.drawCircle(p, stroke.strokeWidth, paint..style = PaintingStyle.fill);
        case DrawingTool.eraser:
          break;
      }
    }
  }

  void _drawFreehand(Canvas canvas, Stroke stroke, Paint paint) {
    final path = Path()..moveTo(stroke.points.first.point.dx, stroke.points.first.point.dy);
    for (var i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].point.dx, stroke.points[i].point.dy);
    }
    canvas.drawPath(path, paint);
    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points.first.point, stroke.strokeWidth / 2, paint..style = PaintingStyle.fill);
    }
  }

  void _drawLine(Canvas canvas, Stroke stroke, Paint paint) {
    if (stroke.points.length < 2) return;
    final start = stroke.points.first.point;
    final end = stroke.points.last.point;
    canvas.drawLine(start, end, paint);
  }

  void _drawRectangle(Canvas canvas, Stroke stroke, Paint paint) {
    if (stroke.points.length < 2) return;
    final start = stroke.points.first.point;
    final end = stroke.points.last.point;
    final rect = Rect.fromPoints(start, end);
    canvas.drawRect(rect, paint);
  }

  void _drawCircle(Canvas canvas, Stroke stroke, Paint paint) {
    if (stroke.points.length < 2) return;
    final center = stroke.points.first.point;
    final edge = stroke.points.last.point;
    final radius = (center - edge).distance;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) =>
      oldDelegate.strokes != strokes || oldDelegate.canvasBackgroundColor != canvasBackgroundColor;
}
