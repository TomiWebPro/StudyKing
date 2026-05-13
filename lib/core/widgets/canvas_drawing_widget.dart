import 'package:flutter/material.dart';

class CanvasDrawingWidget extends StatefulWidget {
  final double width;
  final double height;
  final Color? penColor;
  final double penStrokeWidth;
  final void Function(dynamic imageData)? onSaved;

  const CanvasDrawingWidget({
    super.key,
    this.width = double.infinity,
    this.height = 300,
    this.penColor,
    this.penStrokeWidth = 3.0,
    this.onSaved,
  });

  @override
  State<CanvasDrawingWidget> createState() => _CanvasDrawingWidgetState();
}

class _CanvasDrawingWidgetState extends State<CanvasDrawingWidget> {
  final List<_DrawPoint> _points = [];

  @override
  Widget build(BuildContext context) {
    final color = widget.penColor ?? Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(
              onPanStart: (details) {
                final point = _DrawPoint(
                  x: details.localPosition.dx,
                  y: details.localPosition.dy,
                  color: color,
                  strokeWidth: widget.penStrokeWidth,
                );
                _points.add(point);
                setState(() {});
              },
              onPanUpdate: (details) {
                final point = _DrawPoint(
                  x: details.localPosition.dx,
                  y: details.localPosition.dy,
                  color: color,
                  strokeWidth: widget.penStrokeWidth,
                );
                _points.add(point);
                setState(() {});
              },
              onPanEnd: (_) {
                setState(() {});
              },
              child: CustomPaint(
                painter: _CanvasPainter(_points),
                size: Size(widget.width, widget.height),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() => _points.clear());
              },
              icon: const Icon(Icons.delete),
              label: const Text('Clear'),
            ),
            if (widget.onSaved != null)
              TextButton.icon(
                onPressed: () {
                  widget.onSaved!(_points.map((p) => p.toJson()).toList());
                },
                icon: const Icon(Icons.save),
                label: const Text('Save Drawing'),
              ),
          ],
        ),
      ],
    );
  }
}

class _DrawPoint {
  final double x;
  final double y;
  final Color color;
  final double strokeWidth;

  _DrawPoint({
    required this.x,
    required this.y,
    required this.color,
    required this.strokeWidth,
  });

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'color': color.toARGB32(),
    'strokeWidth': strokeWidth,
  };
}

class _CanvasPainter extends CustomPainter {
  final List<_DrawPoint> points;

  _CanvasPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final paint = Paint()
        ..color = current.color
        ..strokeWidth = current.strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(current.x, current.y), Offset(next.x, next.y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}
