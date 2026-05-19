import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final Color gridColor;

  GridPainter({this.gridColor = const Color(0xFF9E9E9E)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = gridColor..strokeWidth = 1.0;
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) =>
      oldDelegate.gridColor != gridColor;
}
