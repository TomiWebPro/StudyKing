import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Canvas/Drawing Widget for graph drawing and diagram questions
class CanvasDrawingWidget extends StatefulWidget {
  final String? instruction;
  final ValueChanged<Uint8List> onDrawingComplete;
  final String? initialDrawing;

  const CanvasDrawingWidget({
    super.key,
    this.instruction,
    required this.onDrawingComplete,
    this.initialDrawing,
  });

  @override
  State<CanvasDrawingWidget> createState() => _CanvasDrawingWidgetState();
}

class _CanvasDrawingWidgetState extends State<CanvasDrawingWidget> {
  final List<DrawingPoint> _drawings = [];
  bool _isDrawing = false;
  bool _isEmpty = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.instruction != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.instruction!,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        GestureDetector(
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          child: Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                // Grid background
                _buildGrid(context),
                
                // Drawing canvas
                CustomPaint(
                  size: Size.infinite,
                  painter: DrawingPainter(drawings: _drawings),
                ),
                
                // Empty state hint
                if (_isEmpty && !_isDrawing)
                  const Center(
                    child: Text(
                      'Draw here...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),

                // Control buttons
                Positioned(
                  right: 8,
                  top: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIconButton(
                        icon: Icons.undo,
                        onTap: _handleUndo,
                      ),
                      const SizedBox(width: 8),
                      _buildIconButton(
                        icon: Icons.delete_outline,
                        onTap: _handleClear,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isEmpty ? null : _handleSave,
          child: const Text('Save Drawing'),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: GridPainter(),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 10),
            blurRadius: 4,
          ),
        ],
      ),
      child: Icon(icon, size: 20, color: Colors.grey.shade700),
    );
  }

  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _isDrawing = true;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isDrawing) return;

    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.globalToLocal(details.globalPosition);
    
    setState(() {
      _drawings.add(DrawingPoint(
        point: Offset(offset.dx, offset.dy),
        color: Colors.black,
      ));
      _isEmpty = false;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _isDrawing = false;
    });
  }

  void _handleUndo() {
    if (_drawings.isNotEmpty) {
      setState(() {
        _drawings.removeLast();
        if (_drawings.isEmpty) {
          _isEmpty = true;
        }
      });
    }
  }

  void _handleClear() {
    setState(() {
      _drawings.clear();
      _isEmpty = true;
    });
  }

  Future<void> _handleSave() async {
    // Convert canvas to image
    // For simplicity, just emit the drawing data
    widget.onDrawingComplete(_generateDrawingData());
  }

  Uint8List _generateDrawingData() {
    // Convert drawing points to a serializable format
    // In production, would convert to PNG/SVG
    return Uint8List.fromList([1]); // Placeholder
  }
}

class DrawingPoint {
  final Offset point;
  final Color color;

  DrawingPoint({
    required this.point,
    this.color = Colors.black,
  });
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint> drawings;

  DrawingPainter({required this.drawings});

  @override
  void paint(Canvas canvas, Size size) {
    for (final drawing in drawings) {
      canvas.drawCircle(
        drawing.point,
        3,
        Paint()..color = drawing.color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return drawings.length != oldDelegate.drawings.length;
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1.0;

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw vertical lines
    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => false;
}
