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

      test('returns empty result with the requested mode for empty strokes',
          () {
        final result = service.recognizeStrokes([], RecognitionMode.math);
        expect(result.recognizedText, isEmpty);
        expect(result.confidence, 0.0);
        expect(result.mode, RecognitionMode.math);
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

    group('unrecognized strokes (no fabricated fallback)', () {
      // Sharp-bend geometry that matches no heuristic rule in either
      // recognition mode. Before the fix, the fallback branches emitted
      // a fabricated 'e' (text) / 'x' (math) at 0.4 confidence, so any
      // real handwriting produced garbage that flowed into answer
      // validation. Unmatched strokes must now report nothing.
      List<Stroke> unmatchedStroke() => [
            Stroke(
              points: [
                DrawingPoint(point: const Offset(0, 0)),
                DrawingPoint(point: const Offset(20, 30)),
                DrawingPoint(point: const Offset(22, 0)),
              ],
            ),
          ];

      test('text mode emits nothing when no rule matches', () {
        final result =
            service.recognizeStrokes(unmatchedStroke(), RecognitionMode.text);
        expect(result.recognizedText, isEmpty);
        expect(result.confidence, 0.0);
        expect(result.mode, RecognitionMode.text);
      });

      test('math mode emits nothing when no rule matches', () {
        final result =
            service.recognizeStrokes(unmatchedStroke(), RecognitionMode.math);
        expect(result.recognizedText, isEmpty);
        expect(result.confidence, 0.0);
        expect(result.mode, RecognitionMode.math);
      });

      test('mixed strokes emit only rule-matched characters', () {
        // The vertical line matches the 'l' rule (0.6); the sharp bend
        // matches nothing and must contribute no character.
        final strokes = [
          Stroke(
            points: [
              DrawingPoint(point: const Offset(0, 0)),
              DrawingPoint(point: const Offset(0, 50)),
              DrawingPoint(point: const Offset(0, 100)),
            ],
          ),
          ...unmatchedStroke(),
        ];
        final result = service.recognizeStrokes(strokes, RecognitionMode.text);
        expect(result.recognizedText, 'l');
        expect(result.confidence, 0.6);
      });

      test('rule-matched characters always carry at least 0.5 confidence',
          () {
        final shapes = <List<Stroke>>[
          // Horizontal line -> '-' at 0.7.
          [
            Stroke(
              points: [
                DrawingPoint(point: const Offset(0, 0)),
                DrawingPoint(point: const Offset(50, 0)),
                DrawingPoint(point: const Offset(100, 0)),
              ],
            ),
          ],
          // Vertical line -> 'l' at 0.6.
          [
            Stroke(
              points: [
                DrawingPoint(point: const Offset(0, 0)),
                DrawingPoint(point: const Offset(0, 50)),
                DrawingPoint(point: const Offset(0, 100)),
              ],
            ),
          ],
          // Shallow diagonal -> 'r' at 0.5.
          [
            Stroke(
              points: [
                DrawingPoint(point: const Offset(0, 0)),
                DrawingPoint(point: const Offset(10, 10)),
                DrawingPoint(point: const Offset(20, 20)),
              ],
            ),
          ],
        ];

        for (final strokes in shapes) {
          final result =
              service.recognizeStrokes(strokes, RecognitionMode.text);
          expect(result.recognizedText, isNotEmpty);
          expect(result.confidence, greaterThanOrEqualTo(0.5));
        }
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

      test('skips a zero-point stroke between mergeable strokes', () {
        final strokes = [
          Stroke(
            points: [
              DrawingPoint(point: const Offset(0, 0)),
              DrawingPoint(point: const Offset(10, 10)),
            ],
          ),
          Stroke(points: []),
          Stroke(
            points: [
              DrawingPoint(point: const Offset(11, 11)),
              DrawingPoint(point: const Offset(20, 20)),
            ],
          ),
        ];
        final combined = service.combineStrokes(strokes);
        // The empty stroke carries no geometry, so the close strokes
        // either side of it still merge into one.
        expect(combined, hasLength(1));
      });

      test('skips a leading zero-point stroke', () {
        final strokes = [
          Stroke(points: []),
          Stroke(
            points: [
              DrawingPoint(point: const Offset(0, 0)),
              DrawingPoint(point: const Offset(10, 10)),
            ],
          ),
        ];
        final combined = service.combineStrokes(strokes);
        expect(combined, hasLength(1));
        expect(combined.first.points, hasLength(2));
      });

      test('returns empty list for all zero-point strokes', () {
        final combined = service.combineStrokes([
          Stroke(points: []),
          Stroke(points: []),
        ]);
        expect(combined, isEmpty);
      });

      test('keeps far-apart strokes separate around a zero-point stroke',
          () {
        final strokes = [
          Stroke(
            points: [
              DrawingPoint(point: const Offset(0, 0)),
              DrawingPoint(point: const Offset(10, 10)),
            ],
          ),
          Stroke(points: []),
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
    });

    group('dispose', () {
      test('can be disposed without error', () {
        expect(() => service.dispose(), returnsNormally);
      });
    });
  });
}
