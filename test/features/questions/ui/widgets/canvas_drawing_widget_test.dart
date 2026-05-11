import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/ui/widgets/canvas_drawing_widget.dart';

void main() {
  group('CanvasDrawingWidget', () {
    Widget buildWidget({
      String? instruction,
      ValueChanged<Uint8List>? onDrawingComplete,
      String? initialDrawing,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: CanvasDrawingWidget(
            instruction: instruction,
            onDrawingComplete: onDrawingComplete ?? (_) {},
            initialDrawing: initialDrawing,
          ),
        ),
      );
    }

    group('basic rendering', () {
      testWidgets('renders canvas area', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.byType(CanvasDrawingWidget), findsOneWidget);
      });

      testWidgets('renders placeholder text when empty', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.text('Draw here...'), findsOneWidget);
      });

      testWidgets('renders instruction text when provided', (tester) async {
        await tester.pumpWidget(buildWidget(
          instruction: 'Draw a square',
        ));

        expect(find.text('Draw a square'), findsOneWidget);
      });

      testWidgets('renders undo button', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.byIcon(Icons.undo), findsOneWidget);
      });

      testWidgets('renders clear button', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });

      testWidgets('renders save button', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.widgetWithText(ElevatedButton, 'Save Drawing'), findsOneWidget);
      });
    });

    group('drawing interaction', () {
      testWidgets('hides placeholder after drawing starts', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        expect(find.text('Draw here...'), findsNothing);
      });
    });

    group('undo functionality', () {
      testWidgets('undo button removes last stroke', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        await tester.tap(find.byIcon(Icons.undo));
        await tester.pump();

        expect(find.text('Draw here...'), findsOneWidget);
      });

      testWidgets('undo button does nothing when strokes empty', (tester) async {
        await tester.pumpWidget(buildWidget());

        await tester.tap(find.byIcon(Icons.undo));
        await tester.pump();

        expect(find.text('Draw here...'), findsOneWidget);
      });
    });

    group('clear functionality', () {
      testWidgets('clear button removes all strokes', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pump();

        expect(find.text('Draw here...'), findsOneWidget);
      });
    });

    group('save functionality', () {
      testWidgets('save button disabled when canvas empty', (tester) async {
        await tester.pumpWidget(buildWidget());

        final saveButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Save Drawing'),
        );
        expect(saveButton.onPressed, isNull);
      });

      testWidgets('save button enabled after drawing', (tester) async {
        bool dataReceived = false;
        await tester.pumpWidget(buildWidget(
          onDrawingComplete: (data) {
            dataReceived = data.isNotEmpty;
          },
        ));

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        final saveButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Save Drawing'),
        );
        expect(saveButton.onPressed, isNotNull);
        expect(dataReceived, isTrue);
      });
    });

    group('initial drawing', () {
      testWidgets('loads initial drawing from JSON string', (tester) async {
        final initialDrawing = '[[{"x":10,"y":20,"pressure":1}]]';
        await tester.pumpWidget(buildWidget(initialDrawing: initialDrawing));

        expect(find.text('Draw here...'), findsNothing);
      });

      testWidgets('handles invalid JSON gracefully', (tester) async {
        await tester.pumpWidget(buildWidget(initialDrawing: 'invalid json'));

        expect(find.text('Draw here...'), findsOneWidget);
      });

      testWidgets('handles empty string', (tester) async {
        await tester.pumpWidget(buildWidget(initialDrawing: ''));

        expect(find.text('Draw here...'), findsOneWidget);
      });

      testWidgets('handles null initial drawing', (tester) async {
        await tester.pumpWidget(buildWidget(initialDrawing: null));

        expect(find.text('Draw here...'), findsOneWidget);
      });

      testWidgets('handles non-array JSON', (tester) async {
        await tester.pumpWidget(buildWidget(initialDrawing: '{"key": "value"}'));

        expect(find.text('Draw here...'), findsOneWidget);
      });

      testWidgets('handles empty array', (tester) async {
        await tester.pumpWidget(buildWidget(initialDrawing: '[]'));

        expect(find.text('Draw here...'), findsOneWidget);
      });
    });

    group('GridPainter', () {
      testWidgets('grid is visible', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.byType(CustomPaint), findsWidgets);
      });
    });

    group('DrawingPainter', () {
      testWidgets('renders when strokes change', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        expect(find.byType(CanvasDrawingWidget), findsOneWidget);
      });

      testWidgets('handles single point stroke', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.up();
        await tester.pump();

        expect(find.byType(CanvasDrawingWidget), findsOneWidget);
      });
    });

    group('edge cases', () {
      testWidgets('handles widget without instruction', (tester) async {
        await tester.pumpWidget(buildWidget(instruction: null));

        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('renders with instruction and no initial drawing', (tester) async {
        await tester.pumpWidget(buildWidget(
          instruction: 'Draw your answer here',
          initialDrawing: null,
        ));

        expect(find.text('Draw your answer here'), findsOneWidget);
      });
    });
  });

  group('Stroke', () {
    test('creates with required fields', () {
      final stroke = Stroke(points: []);

      expect(stroke.points, isEmpty);
      expect(stroke.color, Colors.black);
      expect(stroke.strokeWidth, 3);
    });

    test('creates with custom color', () {
      final stroke = Stroke(points: [], color: Colors.red);

      expect(stroke.color, Colors.red);
    });

    test('creates with custom stroke width', () {
      final stroke = Stroke(points: [], strokeWidth: 5.0);

      expect(stroke.strokeWidth, 5.0);
    });
  });

  group('DrawingPoint', () {
    test('creates with required point', () {
      final point = DrawingPoint(point: const Offset(10, 20));

      expect(point.point, const Offset(10, 20));
      expect(point.pressure, isNull);
    });

    test('creates with pressure', () {
      final point = DrawingPoint(point: const Offset(10, 20), pressure: 0.5);

      expect(point.point, const Offset(10, 20));
      expect(point.pressure, 0.5);
    });
  });
}