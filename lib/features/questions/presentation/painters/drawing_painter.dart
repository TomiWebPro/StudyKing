import 'package:flutter/material.dart';
import 'package:studyking/features/questions/data/models/drawing_models.dart';

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;

  DrawingPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path()..moveTo(stroke.points.first.point.dx, stroke.points.first.point.dy);
      for (var i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].point.dx, stroke.points[i].point.dy);
      }
      canvas.drawPath(path, paint);
      if (stroke.points.length == 1) {
        canvas.drawCircle(stroke.points.first.point, stroke.strokeWidth / 2, paint..style = PaintingStyle.fill);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => oldDelegate.strokes != strokes;
}
