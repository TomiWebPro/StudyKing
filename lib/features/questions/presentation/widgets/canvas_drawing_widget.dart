import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:studyking/core/utils/responsive.dart';
import '../../../../core/utils/logger.dart';
import 'package:flutter/rendering.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/features/questions/data/models/drawing_models.dart';
import 'package:studyking/features/questions/presentation/painters/drawing_painter.dart';
import 'package:studyking/features/questions/presentation/painters/grid_painter.dart';
import 'package:studyking/core/services/handwriting_recognition_service.dart';

class CanvasDrawingWidget extends StatefulWidget {
  final String? instruction;
  final ValueChanged<Uint8List> onDrawingComplete;
  final ValueChanged<String>? onTextRecognized;
  final CanvasInputMode? inputMode;
  final ValueChanged<CanvasInputMode>? onInputModeChanged;
  final String? initialDrawing;
  final bool largeTouchTargets;
  final bool showTools;
  final bool showColorPicker;
  final bool showStrokeWidth;
  final bool showInputModeSelector;

  const CanvasDrawingWidget({
    super.key,
    this.instruction,
    required this.onDrawingComplete,
    this.onTextRecognized,
    this.inputMode,
    this.onInputModeChanged,
    this.initialDrawing,
    this.largeTouchTargets = false,
    this.showTools = false,
    this.showColorPicker = false,
    this.showStrokeWidth = false,
    this.showInputModeSelector = false,
  });

  @override
  State<CanvasDrawingWidget> createState() => _CanvasDrawingWidgetState();
}

class _CanvasDrawingWidgetState extends State<CanvasDrawingWidget> {
  static final Logger _logger = const Logger('CanvasDrawingWidget');
  final GlobalKey _paintKey = GlobalKey();
  final List<Stroke> _strokes = <Stroke>[];
  final List<List<Stroke>> _undoStack = <List<Stroke>>[];
  final List<List<Stroke>> _redoStack = <List<Stroke>>[];
  bool _isDrawing = false;
  bool _isSaving = false;
  String? _saveMessage;
  String _recognizedText = '';
  double _recognitionConfidence = 0.0;

  DrawingTool _currentTool = DrawingTool.freehand;
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 3.0;
  CanvasInputMode _currentInputMode = CanvasInputMode.draw;

  HandwritingRecognitionService? _recognitionService;

  static const List<Color> _presetColors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.grey,
  ];

  static const double _thinWidth = 2.0;
  static const double _mediumWidth = 4.0;
  static const double _thickWidth = 7.0;

  CanvasInputMode get _effectiveInputMode => widget.inputMode ?? _currentInputMode;

  @override
  void initState() {
    super.initState();
    _loadInitialDrawing();
    _initRecognitionService();
  }

  void _initRecognitionService() {
    _recognitionService = HandwritingRecognitionService();
    _recognitionService!.recognizedText.listen((result) {
      if (mounted) {
        setState(() {
          _recognizedText = result.recognizedText;
          _recognitionConfidence = result.confidence;
        });
      }
    });
  }

  @override
  void dispose() {
    _recognitionService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEmpty = _strokes.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showInputModeSelector)
          _buildInputModeSelector(l10n),
        if (widget.instruction != null)
          Semantics(
            header: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(widget.instruction!, style: const TextStyle(fontSize: 14)),
            ),
          ),
        if (widget.showTools || widget.showColorPicker || widget.showStrokeWidth)
          _buildToolbar(l10n),
        Semantics(
          container: true,
          label: widget.instruction ?? l10n.drawingCanvas,
          hint: l10n.drawYourAnswer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: RepaintBoundary(
              key: _paintKey,
              child: Container(
                width: double.infinity,
                height: (MediaQuery.sizeOf(context).height * 0.4).clamp(200.0, 500.0),
                decoration: BoxDecoration(
                  border: Border.all(color: _isDrawing ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline, width: _isDrawing ? 2 : 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    RepaintBoundary(child: _buildGrid(context)),
                    CustomPaint(
                      size: Size.infinite,
                      painter: DrawingPainter(
                        strokes: _strokes,
                        canvasBackgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    if (_effectiveInputMode != CanvasInputMode.draw && _recognizedText.isNotEmpty)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _effectiveInputMode == CanvasInputMode.handwriteMath
                                    ? 'LaTeX: $_recognizedText'
                                    : _recognizedText,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontFamily: _effectiveInputMode == CanvasInputMode.handwriteMath ? 'monospace' : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    _recognitionConfidence > 0.6
                                        ? Icons.check_circle
                                        : Icons.help_outline,
                                    size: 12,
                                    color: _recognitionConfidence > 0.6
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(_recognitionConfidence * 100).round()}% confidence',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (isEmpty && !_isDrawing)
                      Semantics(
                        label: l10n.canvasIsEmpty,
                        excludeSemantics: true,
                        child: Center(
                          child: Text(
                            _effectiveInputMode == CanvasInputMode.draw
                                ? l10n.drawHere
                                : 'Write here',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
                          ),
                        ),
                      ),
                    Positioned.directional(
                      textDirection: Directionality.of(context),
                      end: 8,
                      top: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildIconButton(icon: Icons.undo, onTap: _handleUndo, label: l10n.undoLastStroke),
                          const SizedBox(width: 8),
                          _buildIconButton(icon: Icons.redo, onTap: _handleRedo, label: l10n.redoLastStroke),
                          const SizedBox(width: 8),
                          _buildIconButton(icon: Icons.delete_outline, onTap: _handleClear, label: l10n.clearAllDrawings),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _strokes.isEmpty ? l10n.canvasIsEmpty : l10n.drawingWithStrokes(_strokes.length),
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: (isEmpty || _isSaving) ? null : _handleSave,
                child: _isSaving
                    ? ResponsiveUtils.loaderInTouchTarget(size: 16)
                    : Text(_effectiveInputMode == CanvasInputMode.draw
                        ? l10n.saveDrawing
                        : 'Submit Text'),
              ),
            ),
            if (_saveMessage != null) ...[
              const SizedBox(width: 8),
              Expanded(child: Text(_saveMessage!, style: Theme.of(context).textTheme.bodySmall)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildInputModeSelector(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SegmentedButton<CanvasInputMode>(
        segments: const [
          ButtonSegment<CanvasInputMode>(
            value: CanvasInputMode.draw,
            label: Text('Draw'),
            icon: Icon(Icons.brush, size: 16),
          ),
          ButtonSegment<CanvasInputMode>(
            value: CanvasInputMode.handwriteText,
            label: Text('Text'),
            icon: Icon(Icons.text_fields, size: 16),
          ),
          ButtonSegment<CanvasInputMode>(
            value: CanvasInputMode.handwriteMath,
            label: Text('Math'),
            icon: Icon(Icons.functions, size: 16),
          ),
        ],
        selected: {_effectiveInputMode},
        onSelectionChanged: (selected) {
          if (selected.isNotEmpty) {
            final mode = selected.first;
            setState(() {
              _currentInputMode = mode;
              _recognizedText = '';
              _recognitionConfidence = 0.0;
            });
            widget.onInputModeChanged?.call(mode);
          }
        },
      ),
    );
  }

  Widget _buildToolbar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showTools)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToolButton(l10n.toolFreehand, DrawingTool.freehand, Icons.brush),
                  const SizedBox(width: 4),
                  _buildToolButton(l10n.toolLine, DrawingTool.line, Icons.show_chart),
                  const SizedBox(width: 4),
                  _buildToolButton(l10n.toolRectangle, DrawingTool.rectangle, Icons.crop_square),
                  const SizedBox(width: 4),
                  _buildToolButton(l10n.toolCircle, DrawingTool.circle, Icons.circle_outlined),
                  const SizedBox(width: 4),
                  _buildToolButton(l10n.toolPlotPoint, DrawingTool.plotPoint, Icons.gps_fixed),
                  const SizedBox(width: 4),
                  _buildToolButton(l10n.toolEraser, DrawingTool.eraser, Icons.auto_fix_high),
                ],
              ),
            ),
          if (widget.showStrokeWidth) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStrokeWidthButton(_thinWidth, Icons.horizontal_rule),
                const SizedBox(width: 4),
                _buildStrokeWidthButton(_mediumWidth, Icons.remove),
                const SizedBox(width: 4),
                _buildStrokeWidthButton(_thickWidth, Icons.radio_button_unchecked),
              ],
            ),
          ],
          if (widget.showColorPicker) ...[
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _presetColors.map((color) => Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: _buildColorButton(color),
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolButton(String label, DrawingTool tool, IconData icon) {
    final isSelected = _currentTool == tool;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => setState(() => _currentTool = tool),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  Widget _buildStrokeWidthButton(double width, IconData icon) {
    final isSelected = _currentStrokeWidth == width;
    return Semantics(
      button: true,
      child: Material(
        color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => setState(() => _currentStrokeWidth = width),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = _currentColor == color;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () => setState(() => _currentColor = color),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
      child: CustomPaint(
        size: Size.infinite,
        painter: GridPainter(gridColor: Theme.of(context).colorScheme.outlineVariant, textDirection: Directionality.of(context)),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap, String? label}) {
    final effectivePadding = widget.largeTouchTargets
        ? (ResponsiveUtils.minTouchTarget - 20) / 2
        : ResponsiveUtils.minTouchTarget * 0.3;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.all(effectivePadding),
            child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  void _handlePanStart(DragStartDetails details) {
    final box = _paintKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final point = box.globalToLocal(details.globalPosition);
    _saveToUndo();
    setState(() {
      _isDrawing = true;
      final isEraser = _currentTool == DrawingTool.eraser;
      _strokes.add(Stroke(
        points: <DrawingPoint>[DrawingPoint(point: point)],
        color: isEraser ? Colors.white : _currentColor,
        strokeWidth: isEraser ? 20.0 : _currentStrokeWidth,
        tool: _currentTool,
      ));
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isDrawing || _strokes.isEmpty) return;
    final box = _paintKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final point = box.globalToLocal(details.globalPosition);
    setState(() {
      final lastStroke = _strokes.last;
      if (lastStroke.tool == DrawingTool.freehand || lastStroke.tool == DrawingTool.plotPoint || lastStroke.tool == DrawingTool.eraser) {
        lastStroke.points.add(DrawingPoint(point: point));
      } else {
        lastStroke.points.last = DrawingPoint(point: point);
      }
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _isDrawing = false;
      if (_strokes.isNotEmpty && _strokes.last.tool != DrawingTool.freehand && _strokes.last.tool != DrawingTool.plotPoint) {
        if (_strokes.last.points.length < 2) {
          _strokes.removeLast();
        }
      }
    });
    _triggerRecognition();
  }

  void _triggerRecognition() {
    if (_effectiveInputMode == CanvasInputMode.draw) return;
    if (_strokes.isEmpty) return;

    final mode = _effectiveInputMode == CanvasInputMode.handwriteMath
        ? RecognitionMode.math
        : RecognitionMode.text;

    final result = _recognitionService?.recognizeStrokes(_strokes, mode);
    if (result != null && result.recognizedText.isNotEmpty) {
      widget.onTextRecognized?.call(result.recognizedText);
    }
  }

  void _saveToUndo() {
    _undoStack.add(List<Stroke>.from(_strokes.map((s) => Stroke(
      points: List<DrawingPoint>.from(s.points.map((p) => DrawingPoint(point: p.point, pressure: p.pressure))),
      color: s.color,
      strokeWidth: s.strokeWidth,
      tool: s.tool,
    ))));
    _redoStack.clear();
  }

  void _handleUndo() {
    if (_strokes.isEmpty) return;
    _redoStack.add(List<Stroke>.from(_strokes.map((s) => Stroke(
      points: List<DrawingPoint>.from(s.points.map((p) => DrawingPoint(point: p.point, pressure: p.pressure))),
      color: s.color,
      strokeWidth: s.strokeWidth,
      tool: s.tool,
    ))));
    if (_undoStack.isNotEmpty) {
      final restored = _undoStack.removeLast();
      setState(() {
        _strokes
          ..clear()
          ..addAll(restored);
      });
    } else {
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  void _handleRedo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(List<Stroke>.from(_strokes.map((s) => Stroke(
      points: List<DrawingPoint>.from(s.points.map((p) => DrawingPoint(point: p.point, pressure: p.pressure))),
      color: s.color,
      strokeWidth: s.strokeWidth,
      tool: s.tool,
    ))));
    final restored = _redoStack.removeLast();
    setState(() {
      _strokes
        ..clear()
        ..addAll(restored);
    });
  }

  void _handleClear() {
    _saveToUndo();
    setState(() {
      _strokes.clear();
    });
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isSaving = true;
      _saveMessage = null;
    });
    try {
      if (_effectiveInputMode == CanvasInputMode.draw) {
        final data = await _generateDrawingData();
        widget.onDrawingComplete(data);
      } else {
        _triggerRecognition();
        if (_recognizedText.isNotEmpty) {
          widget.onTextRecognized?.call(_recognizedText);
        } else {
          final data = await _generateDrawingData();
          widget.onDrawingComplete(data);
        }
      }
      if (mounted) {
        setState(() {
          _saveMessage = l10n.drawingSaved;
        });
      }
    } catch (e) {
      _logger.w('Failed to save drawing', e);
      if (mounted) {
        setState(() {
          _saveMessage = l10n.failedToSaveDrawing;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<Uint8List> _generateDrawingData() async {
    final boundary = _paintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return Uint8List(0);
    final image = await boundary.toImage(pixelRatio: 2);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List() ?? Uint8List(0);
  }

  void _loadInitialDrawing() {
    final raw = widget.initialDrawing;
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final loadedStrokes = <Stroke>[];
      for (final stroke in decoded) {
        if (stroke is! List) continue;
        final points = <DrawingPoint>[];
        for (final p in stroke) {
          if (p is Map<String, dynamic>) {
            final dx = (p['x'] as num?)?.toDouble();
            final dy = (p['y'] as num?)?.toDouble();
            final pressure = (p['pressure'] as num?)?.toDouble();
            if (dx != null && dy != null) {
              points.add(DrawingPoint(point: Offset(dx, dy), pressure: pressure));
            }
          }
        }
        if (points.isNotEmpty) {
          loadedStrokes.add(Stroke(points: points));
        }
      }
      if (loadedStrokes.isNotEmpty) {
        _strokes.addAll(loadedStrokes);
      }
    } catch (e) {
      _logger.w('Invalid initial drawing payload', e);
    }
  }
}
