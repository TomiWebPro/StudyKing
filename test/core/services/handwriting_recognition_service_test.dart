import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/handwriting_recognition_service.dart';
import 'package:studyking/features/questions/data/models/drawing_models.dart';

void main() {
  group('HandwritingRecognitionService', () {
    late HandwritingRecognitionService service;

    setUp(() {
      service = HandwritingRecognitionService();
    });

    tearDown(() {
      service.dispose();
    });

    group('recognizeStrokes', () {
      test('returns empty result for empty strokes', () {
        final result = service.recognizeStrokes([], RecognitionMode.text);
        expect(result.recognizedText, isEmpty);
        expect(result.confidence, 0.0);
      });

      test('returns empty result for eraser-only strokes', () {
        final strokes = [
          Stroke(
            points: [
              DrawingPoint(point: const Offset(0, 0)),
              DrawingPoint(point: const Offset(10, 10)),
            ],
            tool: DrawingTool.eraser,
          ),
        ];
        final result = service.recognizeStrokes(strokes, RecognitionMode.text);
        expect(result.recognizedText, isEmpty);
      });

      test('returns text recognition for text mode', () {
        final strokes = [
          Stroke(
            points: [
              DrawingPoint(point: const Offset(0, 0)),
              DrawingPoint(point: const Offset(0, 50)),
              DrawingPoint(point: const Offset(0, 100)),
            ],
          ),
        ];
        final result = service.recognizeStrokes(strokes, RecognitionMode.text);
        expect(result.recognizedText, isNotEmpty);
        expect(result.mode, RecognitionMode.text);
        expect(result.confidence, greaterThan(0));
      });

      test('returns math recognition for math mode', () {
        final strokes = [
          Stroke(
            points: [
              DrawingPoint(point: const Offset(0, 0)),
              DrawingPoint(point: const Offset(50, 0)),
              DrawingPoint(point: const Offset(100, 0)),
            ],
          ),
        ];
        final result = service.recognizeStrokes(strokes, RecognitionMode.math);
        expect(result.mode, RecognitionMode.math);
        expect(result.confidence, greaterThanOrEqualTo(0));
      });

      test('streams recognition result', () async {
        final strokes = [
          Stroke(
            points: [
              DrawingPoint(point: const Offset(0, 0)),
              DrawingPoint(point: const Offset(10, 10)),
            ],
          ),
        ];

        final results = <RecognitionResult>[];
        service.recognizedText.listen(results.add);

        service.recognizeStrokes(strokes, RecognitionMode.text);

        await Future<void>.delayed(Duration.zero);
        expect(results, hasLength(1));
      });

      test('streams confidence value', () async {
        final strokes = [
          Stroke(
            points: [
              DrawingPoint(point: const Offset(0, 0)),
              DrawingPoint(point: const Offset(10, 10)),
              DrawingPoint(point: const Offset(20, 20)),
            ],
          ),
        ];

        final confidences = <double>[];
        service.confidence.listen(confidences.add);

        service.recognizeStrokes(strokes, RecognitionMode.text);

        await Future<void>.delayed(Duration.zero);
        expect(confidences, hasLength(1));
      });

      test('caches last result', () {
        final strokes = [
          Stroke(
            points: [
              DrawingPoint(point: const Offset(0, 0)),
              DrawingPoint(point: const Offset(10, 10)),
            ],
          ),
        ];

        expect(service.lastResult, isNull);
        service.recognizeStrokes(strokes, RecognitionMode.text);
        expect(service.lastResult, isNotNull);
      });
    });

    group('combineStrokes', () {
      test('returns empty list for empty strokes', () {
        expect(service.combineStrokes([]), isEmpty);
      });

      test('returns same strokes when single stroke', () {
        final strokes = [
          Stroke(
            points: [
              DrawingPoint(point: const Offset(0, 0)),
              DrawingPoint(point: const Offset(10, 10)),
            ],
          ),
        ];
        final combined = service.combineStrokes(strokes);
        expect(combined, hasLength(1));
      });

      test('combines close strokes into one', () {
        final strokes = [
          Stroke(
            points: [
              DrawingPoint(point: const Offset(0, 0)),
              DrawingPoint(point: const Offset(10, 10)),
            ],
          ),
          Stroke(
            points: [
              DrawingPoint(point: const Offset(11, 11)),
              DrawingPoint(point: const Offset(20, 20)),
            ],
          ),
        ];
        final combined = service.combineStrokes(strokes);
        expect(combined, hasLength(1));
      });

      test('keeps separate strokes far apart', () {
        final strokes = [
          Stroke(
            points: [
              DrawingPoint(point: const Offset(0, 0)),
              DrawingPoint(point: const Offset(10, 10)),
            ],
          ),
          Stroke(
            points: [
              DrawingPoint(point: const Offset(200, 200)),
              DrawingPoint(point: const Offset(210, 210)),
            ],
          ),
        ];
        final combined = service.combineStrokes(strokes);
        expect(combined, hasLength(2));
      });

      test('handles eraser strokes correctly', () {
        final strokes = [
          Stroke(
            points: [
              DrawingPoint(point: const Offset(0, 0)),
              DrawingPoint(point: const Offset(10, 10)),
            ],
          ),
          Stroke(
            points: [
              DrawingPoint(point: const Offset(11, 11)),
              DrawingPoint(point: const Offset(20, 20)),
            ],
            tool: DrawingTool.eraser,
          ),
        ];
        final combined = service.combineStrokes(strokes);
        expect(combined, hasLength(2));
      });
    });

    group('dispose', () {
      test('can be disposed without error', () {
        expect(() => service.dispose(), returnsNormally);
      });
    });
  });
}
