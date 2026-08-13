import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/questions/data/models/drawing_models.dart';

enum RecognitionMode { text, math }

class RecognitionResult {
  final String recognizedText;
  final double confidence;
  final RecognitionMode mode;

  const RecognitionResult({
    required this.recognizedText,
    required this.confidence,
    required this.mode,
  });
}

class HandwritingRecognitionService {
  static final Logger _logger = const Logger('HandwritingRecognitionService');

  final StreamController<RecognitionResult> _recognitionController =
      StreamController<RecognitionResult>.broadcast();

  final StreamController<double> _confidenceController =
      StreamController<double>.broadcast();

  Stream<RecognitionResult> get recognizedText => _recognitionController.stream;
  Stream<double> get confidence => _confidenceController.stream;

  RecognitionResult? _lastResult;
  RecognitionResult? get lastResult => _lastResult;

  RecognitionResult recognizeStrokes(List<Stroke> strokes, RecognitionMode mode) {
    if (strokes.isEmpty) {
      return const RecognitionResult(
        recognizedText: '',
        confidence: 0.0,
        mode: RecognitionMode.text,
      );
    }

    try {
      final result = mode == RecognitionMode.math
          ? _recognizeMath(strokes)
          : _recognizeText(strokes);

      _lastResult = result;
      _recognitionController.add(result);
      _confidenceController.add(result.confidence);
      return result;
    } catch (e) {
      _logger.w('Recognition failed', e);
      return RecognitionResult(
        recognizedText: '',
        confidence: 0.0,
        mode: mode,
      );
    }
  }

  RecognitionResult _recognizeText(List<Stroke> strokes) {
    final buffer = StringBuffer();
    double totalConfidence = 0.0;
    int charCount = 0;

    for (final stroke in strokes) {
      if (stroke.tool == DrawingTool.eraser) continue;
      if (stroke.points.length < 2) continue;

      final char = _recognizeCharacter(stroke);
      if (char != null) {
        buffer.write(char.character);
        totalConfidence += char.confidence;
        charCount++;
      }
    }

    final avgConfidence = charCount > 0 ? totalConfidence / charCount : 0.0;
    return RecognitionResult(
      recognizedText: buffer.toString(),
      confidence: avgConfidence,
      mode: RecognitionMode.text,
    );
  }

  RecognitionResult _recognizeMath(List<Stroke> strokes) {
    final buffer = StringBuffer();
    double totalConfidence = 0.0;
    int tokenCount = 0;

    for (final stroke in strokes) {
      if (stroke.tool == DrawingTool.eraser) continue;
      if (stroke.points.length < 2) continue;

      final token = _recognizeMathToken(stroke);
      if (token != null) {
        buffer.write(token.character);
        totalConfidence += token.confidence;
        tokenCount++;
      }
    }

    final avgConfidence = tokenCount > 0 ? totalConfidence / tokenCount : 0.0;
    return RecognitionResult(
      recognizedText: buffer.toString(),
      confidence: avgConfidence,
      mode: RecognitionMode.math,
    );
  }

  _CharRecognition? _recognizeCharacter(Stroke stroke) {
    if (stroke.points.length < 3) return null;

    final points = stroke.points.map((p) => p.point).toList();
    final boundingBox = _getBoundingBox(points);
    final width = boundingBox.width;
    final height = boundingBox.height;

    if (width < 5 && height < 5) return null;

    final aspectRatio = width / max(height, 1);
    final direction = _getStrokeDirection(points);
    final curvature = _getStrokeCurvature(points);
    final hasVerticalComponent = direction.dy.abs() > 0.3;
    final hasHorizontalComponent = direction.dx.abs() > 0.3;

    if (aspectRatio > 2.5 && hasHorizontalComponent) {
      return _CharRecognition('-', 0.7);
    }

    if (hasVerticalComponent && !hasHorizontalComponent && aspectRatio < 0.5) {
      return _CharRecognition('l', 0.6);
    }

    if (curvature > 0.6) {
      if (aspectRatio > 0.7 && aspectRatio < 1.3) {
        return _CharRecognition('o', 0.65);
      }
      return _CharRecognition('c', 0.6);
    }

    if (hasVerticalComponent && hasHorizontalComponent && curvature < 0.3) {
      if (direction.dy < 0) {
        return _CharRecognition('L', 0.5);
      }
      return _CharRecognition('r', 0.5);
    }

    if (aspectRatio > 0.8 && aspectRatio < 1.2 && hasVerticalComponent) {
      return _CharRecognition('x', 0.55);
    }

    if (hasVerticalComponent && curvature > 0.4) {
      return _CharRecognition('s', 0.5);
    }

    return _CharRecognition('e', 0.4);
  }

  _CharRecognition? _recognizeMathToken(Stroke stroke) {
    if (stroke.points.length < 3) return null;

    final points = stroke.points.map((p) => p.point).toList();
    final boundingBox = _getBoundingBox(points);
    final width = boundingBox.width;
    final height = boundingBox.height;

    if (width < 5 && height < 5) return null;

    final aspectRatio = width / max(height, 1);
    final direction = _getStrokeDirection(points);
    final curvature = _getStrokeCurvature(points);
    final hasVerticalComponent = direction.dy.abs() > 0.3;
    final hasHorizontalComponent = direction.dx.abs() > 0.3;

    if (aspectRatio > 2.5 && hasHorizontalComponent) {
      return _CharRecognition('−', 0.7);
    }

    if (hasVerticalComponent && hasHorizontalComponent && curvature < 0.2) {
      if (direction.dx > 0 && direction.dy < 0) {
        return _CharRecognition('+', 0.65);
      }
    }

    if (curvature > 0.7 && aspectRatio > 0.7 && aspectRatio < 1.3) {
      return _CharRecognition('0', 0.6);
    }

    if (curvature > 0.7 && aspectRatio < 0.7) {
      return _CharRecognition('6', 0.5);
    }

    if (hasVerticalComponent && curvature > 0.5) {
      return _CharRecognition('2', 0.5);
    }

    if (hasVerticalComponent && !hasHorizontalComponent && aspectRatio < 0.3) {
      return _CharRecognition('1', 0.55);
    }

    if (hasHorizontalComponent && curvature < 0.3) {
      return _CharRecognition('=', 0.5);
    }

    return _CharRecognition('x', 0.4);
  }

  List<Stroke> combineStrokes(List<Stroke> strokes) {
    if (strokes.isEmpty) return [];

    final combined = <Stroke>[];
    Stroke? current;

    for (final stroke in strokes) {
      if (stroke.tool == DrawingTool.eraser) {
        if (current != null) {
          combined.add(current);
          current = null;
        }
        combined.add(stroke);
        continue;
      }

      if (current == null) {
        current = Stroke(
          points: List<DrawingPoint>.from(stroke.points),
          color: stroke.color,
          strokeWidth: stroke.strokeWidth,
          tool: stroke.tool,
        );
      } else {
        final lastPoint = current.points.last.point;
        final firstPoint = stroke.points.first.point;
        final distance = (lastPoint - firstPoint).distance;

        if (distance < 50) {
          current = Stroke(
            points: List<DrawingPoint>.from(current.points)..addAll(stroke.points),
            color: current.color,
            strokeWidth: current.strokeWidth,
            tool: current.tool,
          );
        } else {
          combined.add(current);
          current = Stroke(
            points: List<DrawingPoint>.from(stroke.points),
            color: stroke.color,
            strokeWidth: stroke.strokeWidth,
            tool: stroke.tool,
          );
        }
      }
    }

    if (current != null) {
      combined.add(current);
    }

    return combined;
  }

  Rect _getBoundingBox(List<Offset> points) {
    if (points.isEmpty) return Rect.zero;

    double minX = points.first.dx;
    double maxX = points.first.dx;
    double minY = points.first.dy;
    double maxY = points.first.dy;

    for (final point in points) {
      minX = min(minX, point.dx);
      maxX = max(maxX, point.dx);
      minY = min(minY, point.dy);
      maxY = max(maxY, point.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Offset _getStrokeDirection(List<Offset> points) {
    if (points.length < 2) return Offset.zero;

    final first = points.first;
    final last = points.last;
    final dx = last.dx - first.dx;
    final dy = last.dy - first.dy;
    final length = sqrt(dx * dx + dy * dy);

    if (length < 1) return Offset.zero;
    return Offset(dx / length, dy / length);
  }

  double _getStrokeCurvature(List<Offset> points) {
    if (points.length < 3) return 0.0;

    final first = points.first;
    final last = points.last;
    final mid = points[points.length ~/ 2];

    final midToFirst = (mid - first).distance;
    final midToLast = (mid - last).distance;
    final firstToLast = (first - last).distance;

    if (firstToLast < 1) return 0.0;

    final deviation = (midToFirst + midToLast) / 2;
    final ratio = deviation / firstToLast;

    return (ratio - 1.0).clamp(0.0, 1.0);
  }

  void dispose() {
    _recognitionController.close();
    _confidenceController.close();
  }
}

class _CharRecognition {
  final String character;
  final double confidence;

  const _CharRecognition(this.character, this.confidence);
}
