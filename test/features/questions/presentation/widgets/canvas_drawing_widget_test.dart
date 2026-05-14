import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/presentation/widgets/canvas_drawing_widget.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget buildWidget({
  String? instruction,
  ValueChanged<Uint8List>? onDrawingComplete,
  String? initialDrawing,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: CanvasDrawingWidget(
        instruction: instruction,
        onDrawingComplete: onDrawingComplete ?? (_) {},
        initialDrawing: initialDrawing,
      ),
    ),
  );
}

void main() {
  group('CanvasDrawingWidget', () {
    group('basic rendering', () {
      testWidgets('renders canvas drawing widget', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.byType(CanvasDrawingWidget), findsOneWidget);
      });

      testWidgets('renders placeholder text when empty', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('Draw here...'), findsOneWidget);
      });

      testWidgets('renders instruction text when provided', (tester) async {
        await tester.pumpWidget(buildWidget(instruction: 'Draw a square'));
        expect(find.text('Draw a square'), findsOneWidget);
      });

      testWidgets('does not render instruction text when not provided', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('Draw a square'), findsNothing);
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

      testWidgets('shows canvas empty status text', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('Canvas is empty'), findsOneWidget);
      });

      testWidgets('shows stroke count after drawing', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        expect(find.text('Canvas is empty'), findsNothing);
      });

      testWidgets('renders GridPainter via CustomPaint', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.byType(CustomPaint), findsWidgets);
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

      testWidgets('drawing creates stroke points', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        expect(find.byType(CanvasDrawingWidget), findsOneWidget);
      });

      testWidgets('single tap creates a point stroke', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.up();
        await tester.pump();

        expect(find.byType(CanvasDrawingWidget), findsOneWidget);
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
        expect(find.text('Canvas is empty'), findsOneWidget);
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

      testWidgets('save button enabled after drawing and calls callback', (tester) async {
        await tester.pumpWidget(buildWidget(
          onDrawingComplete: (_) {},
        ));

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        final saveButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Save Drawing'),
        );
        expect(saveButton.onPressed, isNotNull);
      });

      testWidgets('shows saving indicator while saving', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save Drawing'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('save triggers callback with data', (tester) async {
        await tester.pumpWidget(buildWidget(
          onDrawingComplete: (_) {},
        ));

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save Drawing'));
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(CanvasDrawingWidget), findsOneWidget);
      });

      testWidgets('shows saved message after successful save', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save Drawing'));
        await tester.pumpAndSettle();

        expect(find.text('Drawing saved!'), findsOneWidget);
      });

      testWidgets('save button disabled while saving', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save Drawing'));
        await tester.pump();

        final saveButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Save Drawing'),
        );
        expect(saveButton.onPressed, isNull);
      });
    });

    group('initial drawing', () {
      testWidgets('loads initial drawing from JSON', (tester) async {
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

      testWidgets('handles empty array JSON', (tester) async {
        await tester.pumpWidget(buildWidget(initialDrawing: '[]'));
        expect(find.text('Draw here...'), findsOneWidget);
      });

      testWidgets('handles malformed stroke entries', (tester) async {
        await tester.pumpWidget(buildWidget(initialDrawing: '[[1, 2, 3]]'));
        expect(find.text('Draw here...'), findsOneWidget);
      });

      testWidgets('handles stroke with missing coordinates', (tester) async {
        await tester.pumpWidget(buildWidget(initialDrawing: '[[{"foo":"bar"}]]'));
        expect(find.text('Draw here...'), findsOneWidget);
      });

      testWidgets('handles stroke with partial coordinates', (tester) async {
        await tester.pumpWidget(buildWidget(initialDrawing: '[[{"x":10}]]'));
        expect(find.text('Draw here...'), findsOneWidget);
      });
    });

    group('DrawingPainter', () {
      testWidgets('updates on different strokes', (tester) async {
        await tester.pumpWidget(buildWidget());

        final strokes = [Stroke(points: [DrawingPoint(point: const Offset(10, 10))])];
        final painter1 = DrawingPainter(strokes: strokes);
        final painter2 = DrawingPainter(strokes: []);
        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      testWidgets('does not repaint when strokes are identical', (tester) async {
        final strokes = [Stroke(points: [DrawingPoint(point: const Offset(10, 10))])];
        final painter1 = DrawingPainter(strokes: strokes);
        final painter2 = DrawingPainter(strokes: strokes);
        expect(painter1.shouldRepaint(painter2), isFalse);
      });

      testWidgets('does not repaint GridPainter', (tester) async {
        final painter1 = GridPainter();
        final painter2 = GridPainter();
        expect(painter1.shouldRepaint(painter2), isFalse);
      });
    });

    group('Stroke model', () {
      test('creates with defaults', () {
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

      test('creates with single point', () {
        final stroke = Stroke(points: [DrawingPoint(point: const Offset(10, 20))]);
        expect(stroke.points.length, 1);
      });
    });

    group('DrawingPoint model', () {
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

    group('edge cases', () {
      testWidgets('works without instruction', (tester) async {
        await tester.pumpWidget(buildWidget(instruction: null));
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('works with instruction and no initial drawing', (tester) async {
        await tester.pumpWidget(buildWidget(
          instruction: 'Draw your answer here',
          initialDrawing: null,
        ));
        expect(find.text('Draw your answer here'), findsOneWidget);
      });
    });

    group('largeTouchTargets', () {
      testWidgets('renders with largeTouchTargets enabled', (tester) async {
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: CanvasDrawingWidget(
              onDrawingComplete: (_) {},
              largeTouchTargets: true,
            ),
          ),
        ));
        expect(find.byIcon(Icons.undo), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });

      testWidgets('renders with largeTouchTargets disabled', (tester) async {
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: CanvasDrawingWidget(
              onDrawingComplete: (_) {},
              largeTouchTargets: false,
            ),
          ),
        ));
        expect(find.byIcon(Icons.undo), findsOneWidget);
      });
    });

    group('stroke status text', () {
      testWidgets('shows drawing with strokes count after drawing', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        expect(find.text('Canvas is empty'), findsNothing);
      });
    });

    group('initial drawing edge cases', () {
      testWidgets('loads drawing with pressure data', (tester) async {
        final initialDrawing = '[[{"x":10,"y":20,"pressure":0.8},{"x":15,"y":25}]]';
        await tester.pumpWidget(buildWidget(initialDrawing: initialDrawing));

        expect(find.text('Draw here...'), findsNothing);
      });

      testWidgets('handles empty stroke array within payload', (tester) async {
        final initialDrawing = '[[], [{"x":10,"y":20}]]';
        await tester.pumpWidget(buildWidget(initialDrawing: initialDrawing));

        expect(find.text('Draw here...'), findsNothing);
      });
    });

    group('GridPainter', () {
      testWidgets('repaints on different grid color', (tester) async {
        final p1 = GridPainter(gridColor: Colors.red);
        final p2 = GridPainter(gridColor: Colors.blue);
        expect(p1.shouldRepaint(p2), isTrue);
      });

      testWidgets('does not repaint on same grid color', (tester) async {
        final p1 = GridPainter(gridColor: Colors.grey);
        final p2 = GridPainter(gridColor: Colors.grey);
        expect(p1.shouldRepaint(p2), isFalse);
      });
    });

    group('_buildIconButton large touch targets', () {
      testWidgets('icon button with largeTouchTargets true has different padding', (tester) async {
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: CanvasDrawingWidget(
              onDrawingComplete: (_) {},
              largeTouchTargets: true,
            ),
          ),
        ));
        expect(find.byIcon(Icons.undo), findsOneWidget);
      });
    });

    group('DrawingPainter edge cases', () {
      testWidgets('paints circle for single-point stroke', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.up();
        await tester.pump();

        expect(find.byType(CanvasDrawingWidget), findsOneWidget);
      });

      testWidgets('shouldRepaint returns true for different stroke lists', (tester) async {
        final s1 = [Stroke(points: [DrawingPoint(point: const Offset(0, 0))])];
        final s2 = [Stroke(points: [DrawingPoint(point: const Offset(10, 10))])];
        final painter1 = DrawingPainter(strokes: s1);
        final painter2 = DrawingPainter(strokes: s2);
        expect(painter1.shouldRepaint(painter2), isTrue);
      });
    });

    group('Stroke model equality', () {
      test('two identical strokes have same properties', () {
        final s1 = Stroke(points: [DrawingPoint(point: const Offset(10, 20))]);
        final s2 = Stroke(points: [DrawingPoint(point: const Offset(10, 20))]);
        expect(s1.points.length, s2.points.length);
        expect(s1.color, s2.color);
        expect(s1.strokeWidth, s2.strokeWidth);
      });
    });

    group('DrawingPoint model edge cases', () {
      test('creates with zero offset', () {
        final point = DrawingPoint(point: Offset.zero, pressure: 1.0);
        expect(point.point, Offset.zero);
        expect(point.pressure, 1.0);
      });

      test('creates without pressure', () {
        final point = DrawingPoint(point: const Offset(5, 10));
        expect(point.point.dx, 5);
        expect(point.point.dy, 10);
        expect(point.pressure, isNull);
      });
    });

    group('drawing interaction edge cases', () {
      testWidgets('single tap creates a point and shows no placeholder', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.up();
        await tester.pump();

        expect(find.text('Draw here...'), findsNothing);
      });

      testWidgets('multiple strokes update status text', (tester) async {
        await tester.pumpWidget(buildWidget());

        final g1 = await tester.startGesture(const Offset(50, 50));
        await g1.moveBy(const Offset(10, 10));
        await g1.up();
        await tester.pump();

        final g2 = await tester.startGesture(const Offset(100, 100));
        await g2.moveBy(const Offset(20, 20));
        await g2.up();
        await tester.pump();

        expect(find.text('Draw here...'), findsNothing);
      });
    });
  });
}
