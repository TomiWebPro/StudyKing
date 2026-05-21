import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/data/models/drawing_models.dart';
import 'package:studyking/features/questions/presentation/painters/drawing_painter.dart';

const _painterKey = Key('drawing_painter_custom_paint');

Widget buildDrawingPainterWidget({
  List<Stroke> strokes = const [],
  double width = 200,
  double height = 200,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          key: _painterKey,
          painter: DrawingPainter(strokes: strokes),
          size: Size(width, height),
        ),
      ),
    ),
  );
}

void main() {
  group('DrawingPainter widget', () {
    testWidgets('renders CustomPaint with empty strokes', (tester) async {
      await tester.pumpWidget(buildDrawingPainterWidget());
      expect(find.byKey(_painterKey), findsOneWidget);
    });

    testWidgets('renders CustomPaint with single point stroke', (tester) async {
      final strokes = [
        Stroke(points: [DrawingPoint(point: const Offset(50, 50))]),
      ];
      await tester.pumpWidget(
        buildDrawingPainterWidget(strokes: strokes),
      );
      expect(find.byKey(_painterKey), findsOneWidget);
    });

    testWidgets('renders CustomPaint with multi-point stroke', (tester) async {
      final strokes = [
        Stroke(
          points: [
            DrawingPoint(point: const Offset(20, 20)),
            DrawingPoint(point: const Offset(40, 40)),
            DrawingPoint(point: const Offset(60, 40)),
          ],
          color: Colors.blue,
          strokeWidth: 5,
        ),
      ];
      await tester.pumpWidget(
        buildDrawingPainterWidget(strokes: strokes),
      );
      expect(find.byKey(_painterKey), findsOneWidget);
    });

    testWidgets('renders CustomPaint with multiple strokes', (tester) async {
      final strokes = [
        Stroke(points: [DrawingPoint(point: const Offset(20, 20))]),
        Stroke(
          points: [
            DrawingPoint(point: const Offset(40, 40)),
            DrawingPoint(point: const Offset(80, 80)),
          ],
        ),
      ];
      await tester.pumpWidget(
        buildDrawingPainterWidget(strokes: strokes),
      );
      expect(find.byKey(_painterKey), findsOneWidget);
    });

    testWidgets('renders with zero size without crashing', (tester) async {
      await tester.pumpWidget(
        buildDrawingPainterWidget(width: 0, height: 0),
      );
      expect(find.byKey(_painterKey), findsOneWidget);
    });

    testWidgets('renders with very large size without crashing', (tester) async {
      await tester.pumpWidget(
        buildDrawingPainterWidget(width: 3000, height: 3000),
      );
      expect(find.byKey(_painterKey), findsOneWidget);
    });

    testWidgets('re-renders when strokes change', (tester) async {
      await tester.pumpWidget(buildDrawingPainterWidget(strokes: []));
      expect(find.byKey(_painterKey), findsOneWidget);

      final strokes = [
        Stroke(points: [DrawingPoint(point: const Offset(50, 50))]),
      ];
      await tester.pumpWidget(
        buildDrawingPainterWidget(strokes: strokes),
      );
      expect(find.byKey(_painterKey), findsOneWidget);
    });

    testWidgets('renders with pressure data', (tester) async {
      final strokes = [
        Stroke(
          points: [
            DrawingPoint(point: const Offset(10, 10), pressure: 0.3),
            DrawingPoint(point: const Offset(20, 20), pressure: 0.7),
          ],
        ),
      ];
      await tester.pumpWidget(
        buildDrawingPainterWidget(strokes: strokes),
      );
      expect(find.byKey(_painterKey), findsOneWidget);
    });

    testWidgets('renders with empty stroke in list', (tester) async {
      final strokes = [
        Stroke(points: []),
        Stroke(points: [DrawingPoint(point: const Offset(50, 50))]),
        Stroke(points: []),
      ];
      await tester.pumpWidget(
        buildDrawingPainterWidget(strokes: strokes),
      );
      expect(find.byKey(_painterKey), findsOneWidget);
    });
  });
}
