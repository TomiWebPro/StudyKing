import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/ui/widgets/canvas_drawing_widget.dart';

void main() {
  group('CanvasDrawingWidget', () {
    testWidgets('renders canvas with instruction text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CanvasDrawingWidget(
              instruction: 'Draw a circle',
              onDrawingComplete: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Draw a circle'), findsOneWidget);
      expect(find.text('Draw here...'), findsOneWidget);
    });

    testWidgets('save button is disabled when canvas is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CanvasDrawingWidget(
              instruction: 'Draw something',
              onDrawingComplete: (_) {},
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('draw on canvas enables save button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: CanvasDrawingWidget(
                instruction: 'Draw',
                onDrawingComplete: (_) {},
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(200, 200));
      await gesture.moveBy(const Offset(50, 50));
      await gesture.up();
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('undo button removes last stroke', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: CanvasDrawingWidget(
                onDrawingComplete: (_) {},
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(200, 200));
      await gesture.moveBy(const Offset(50, 50));
      await gesture.up();
      await tester.pump();

      expect(find.text('Draw here...'), findsNothing);

      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();

      expect(find.text('Draw here...'), findsOneWidget);
    });

    testWidgets('clear button removes all strokes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: CanvasDrawingWidget(
                onDrawingComplete: (_) {},
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(200, 200));
      await gesture.moveBy(const Offset(50, 50));
      await gesture.up();
      await tester.pump();

      final gesture2 = await tester.startGesture(const Offset(100, 100));
      await gesture2.moveBy(const Offset(30, 30));
      await gesture2.up();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      expect(find.text('Draw here...'), findsOneWidget);
    });

    testWidgets('handles invalid initialDrawing JSON gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CanvasDrawingWidget(
              onDrawingComplete: (_) {},
              initialDrawing: 'invalid json {{{{',
            ),
          ),
        ),
      );

      expect(find.text('Draw here...'), findsOneWidget);
    });

    testWidgets('handles non-array initialDrawing JSON gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CanvasDrawingWidget(
              onDrawingComplete: (_) {},
              initialDrawing: '{"invalid": "format"}',
            ),
          ),
        ),
      );

      expect(find.text('Draw here...'), findsOneWidget);
    });

    testWidgets('handles empty array initialDrawing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CanvasDrawingWidget(
              onDrawingComplete: (_) {},
              initialDrawing: '[]',
            ),
          ),
        ),
      );

      expect(find.text('Draw here...'), findsOneWidget);
    });

    testWidgets('handles null initialDrawing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CanvasDrawingWidget(
              onDrawingComplete: (_) {},
              initialDrawing: null,
            ),
          ),
        ),
      );

      expect(find.text('Draw here...'), findsOneWidget);
    });

    testWidgets('handles valid initialDrawing JSON with strokes', (tester) async {
      const validJson = '[[{"x": 10, "y": 20}, {"x": 30, "y": 40}]]';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: CanvasDrawingWidget(
                onDrawingComplete: (_) {},
                initialDrawing: validJson,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Draw here...'), findsNothing);
    });

    testWidgets('undo button is present when canvas is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CanvasDrawingWidget(
              onDrawingComplete: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.undo), findsOneWidget);
    });

    testWidgets('clear button is present when canvas is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CanvasDrawingWidget(
              onDrawingComplete: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('works without instruction', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CanvasDrawingWidget(
              onDrawingComplete: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Draw here...'), findsOneWidget);
    });

    testWidgets('multiple strokes can be drawn', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: CanvasDrawingWidget(
                onDrawingComplete: (_) {},
              ),
            ),
          ),
        ),
      );

      final gesture1 = await tester.startGesture(const Offset(100, 100));
      await gesture1.moveBy(const Offset(20, 20));
      await gesture1.up();
      await tester.pump();

      final gesture2 = await tester.startGesture(const Offset(200, 200));
      await gesture2.moveBy(const Offset(30, 30));
      await gesture2.up();
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });
  });
}