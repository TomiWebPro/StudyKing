import 'dart:math' as math;
import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final Color gridColor;
  final bool showAxes;
  final Color axisColor;
  final double originX;
  final double originY;
  final double pixelsPerUnit;

  GridPainter({
    this.gridColor = const Color(0xFF9E9E9E),
    this.showAxes = false,
    this.axisColor = Colors.black,
    this.originX = 0,
    this.originY = 0,
    this.pixelsPerUnit = 20,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    if (!showAxes) return;

    final oy = originY > 0 ? originY : size.height / 2;
    final ox = originX > 0 ? originX : size.width / 2;

    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(ox, 0), Offset(ox, size.height), axisPaint);
    canvas.drawLine(Offset(0, oy), Offset(size.width, oy), axisPaint);

    _drawArrow(canvas, Offset(ox, 0), Offset(ox, -10), axisPaint);
    _drawArrow(canvas, Offset(size.width, oy), Offset(size.width + 10, oy), axisPaint);

    final labelStyle = TextStyle(color: axisColor, fontSize: 10);

    const int maxLabel = 10;
    for (int i = 1; i <= maxLabel; i++) {
      final xPos = ox + i * pixelsPerUnit;
      final yPos = oy - i * pixelsPerUnit;
      if (xPos < size.width - 5) {
        _drawTick(canvas, Offset(xPos, oy), Offset(xPos, oy + 4), gridPaint);
        _drawLabel(canvas, Offset(xPos, oy + 6), '$i', labelStyle);
      }
      if (xPos > 5 && ox > 5) {
        final negXPos = ox - i * pixelsPerUnit;
        if (negXPos > 5) {
          _drawTick(canvas, Offset(negXPos, oy), Offset(negXPos, oy + 4), gridPaint);
          _drawLabel(canvas, Offset(negXPos, oy + 6), '-$i', labelStyle);
        }
      }
      if (yPos > 5) {
        _drawTick(canvas, Offset(ox, yPos), Offset(ox - 4, yPos), gridPaint);
        _drawLabel(canvas, Offset(ox - 20, yPos), '$i', labelStyle);
      }
      if (yPos < size.height - 5 && oy < size.height - 5) {
        final negYPos = oy + i * pixelsPerUnit;
        if (negYPos < size.height - 5) {
          _drawTick(canvas, Offset(ox, negYPos), Offset(ox - 4, negYPos), gridPaint);
          _drawLabel(canvas, Offset(ox - 24, negYPos), '-$i', labelStyle);
        }
      }
    }

    _drawLabel(canvas, Offset(size.width - 4, oy - 14), 'x', labelStyle);
    _drawLabel(canvas, Offset(ox + 6, 2), 'y', labelStyle);
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    canvas.drawLine(from, to, paint);
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const arrowSize = 8.0;
    final arrowAngle = math.pi / 6;
    canvas.drawLine(
      to,
      Offset(to.dx - arrowSize * math.cos(angle - arrowAngle), to.dy - arrowSize * math.sin(angle - arrowAngle)),
      paint,
    );
    canvas.drawLine(
      to,
      Offset(to.dx - arrowSize * math.cos(angle + arrowAngle), to.dy - arrowSize * math.sin(angle + arrowAngle)),
      paint,
    );
  }

  void _drawTick(Canvas canvas, Offset from, Offset to, Paint paint) {
    canvas.drawLine(from, to, paint);
  }

  void _drawLabel(Canvas canvas, Offset pos, String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) =>
      oldDelegate.gridColor != gridColor ||
      oldDelegate.showAxes != showAxes ||
      oldDelegate.axisColor != axisColor ||
      oldDelegate.originX != originX ||
      oldDelegate.originY != originY;
}
