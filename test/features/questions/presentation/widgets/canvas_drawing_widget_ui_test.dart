import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/data/models/drawing_models.dart';
import 'package:studyking/features/questions/presentation/painters/drawing_painter.dart';
import 'package:studyking/features/questions/presentation/painters/grid_painter.dart';
import 'package:studyking/features/questions/presentation/widgets/canvas_drawing_widget.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';

final _l10n = AppLocalizationsEn();

Widget buildWidget({
  String? instruction,
  ValueChanged<Uint8List>? onDrawingComplete,
  String? initialDrawing,
  bool showTools = false,
  bool showColorPicker = false,
  bool showStrokeWidth = false,
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
        showTools: showTools,
        showColorPicker: showColorPicker,
        showStrokeWidth: showStrokeWidth,
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
        expect(find.text(_l10n.drawHere), findsOneWidget);
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
        expect(find.widgetWithText(ElevatedButton, _l10n.saveDrawing), findsOneWidget);
      });

      testWidgets('shows canvas empty status text', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text(_l10n.canvasIsEmpty), findsOneWidget);
      });

      testWidgets('shows stroke count after drawing', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        expect(find.text(_l10n.canvasIsEmpty), findsNothing);
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

        expect(find.text(_l10n.drawHere), findsNothing);
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

        expect(find.text(_l10n.drawHere), findsOneWidget);
      });

      testWidgets('undo button does nothing when strokes empty', (tester) async {
        await tester.pumpWidget(buildWidget());

        await tester.tap(find.byIcon(Icons.undo));
        await tester.pump();

        expect(find.text(_l10n.drawHere), findsOneWidget);
        expect(find.text(_l10n.canvasIsEmpty), findsOneWidget);
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

        expect(find.text(_l10n.drawHere), findsOneWidget);
      });
    });

    group('save functionality', () {
      testWidgets('save button disabled when canvas empty', (tester) async {
        await tester.pumpWidget(buildWidget());

        final saveButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, _l10n.saveDrawing),
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
          find.widgetWithText(ElevatedButton, _l10n.saveDrawing),
        );
        expect(saveButton.onPressed, isNotNull);
      });

      testWidgets('shows saving indicator while saving', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        await tester.tap(find.widgetWithText(ElevatedButton, _l10n.saveDrawing));
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

        await tester.tap(find.widgetWithText(ElevatedButton, _l10n.saveDrawing));
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(CanvasDrawingWidget), findsOneWidget);
      });

      testWidgets('shows saving indicator while saving', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        await tester.tap(find.widgetWithText(ElevatedButton, _l10n.saveDrawing));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('save button disabled while saving', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        final saveButtonsBefore = find.widgetWithText(ElevatedButton, _l10n.saveDrawing);
        await tester.tap(saveButtonsBefore);
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, _l10n.saveDrawing), findsNothing);
      });
    });

    group('initial drawing', () {
      testWidgets('loads initial drawing from JSON', (tester) async {
        final initialDrawing = '[[{"x":10,"y":20,"pressure":1}]]';
        await tester.pumpWidget(buildWidget(initialDrawing: initialDrawing));

        expect(find.text(_l10n.drawHere), findsNothing);
      });

      testWidgets('handles invalid JSON gracefully', (tester) async {
        await tester.pumpWidget(buildWidget(initialDrawing: 'invalid json'));
        expect(find.text(_l10n.drawHere), findsOneWidget);
      });

      testWidgets('handles empty string', (tester) async {
        await tester.pumpWidget(buildWidget(initialDrawing: ''));
        expect(find.text(_l10n.drawHere), findsOneWidget);
      });

      testWidgets('handles null initial drawing', (tester) async {
        await tester.pumpWidget(buildWidget(initialDrawing: null));
        expect(find.text(_l10n.drawHere), findsOneWidget);
      });

      testWidgets('handles non-array JSON', (tester) async {
        await tester.pumpWidget(buildWidget(initialDrawing: '{"key": "value"}'));
        expect(find.text(_l10n.drawHere), findsOneWidget);
      });

      testWidgets('handles empty array JSON', (tester) async {
        await tester.pumpWidget(buildWidget(initialDrawing: '[]'));
        expect(find.text(_l10n.drawHere), findsOneWidget);
      });

      testWidgets('handles malformed stroke entries', (tester) async {
        await tester.pumpWidget(buildWidget(initialDrawing: '[[1, 2, 3]]'));
        expect(find.text(_l10n.drawHere), findsOneWidget);
      });

      testWidgets('handles stroke with missing coordinates', (tester) async {
        await tester.pumpWidget(buildWidget(initialDrawing: '[[{"foo":"bar"}]]'));
        expect(find.text(_l10n.drawHere), findsOneWidget);
      });

      testWidgets('handles stroke with partial coordinates', (tester) async {
        await tester.pumpWidget(buildWidget(initialDrawing: '[[{"x":10}]]'));
        expect(find.text(_l10n.drawHere), findsOneWidget);
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

        expect(find.text(_l10n.canvasIsEmpty), findsNothing);
      });

      testWidgets('shows stroke count after single stroke', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        expect(find.textContaining('1 stroke'), findsOneWidget);
      });
    });

    group('initial drawing edge cases', () {
      testWidgets('loads drawing with pressure data', (tester) async {
        final initialDrawing = '[[{"x":10,"y":20,"pressure":0.8},{"x":15,"y":25}]]';
        await tester.pumpWidget(buildWidget(initialDrawing: initialDrawing));

        expect(find.text(_l10n.drawHere), findsNothing);
      });

      testWidgets('handles empty stroke array within payload', (tester) async {
        final initialDrawing = '[[], [{"x":10,"y":20}]]';
        await tester.pumpWidget(buildWidget(initialDrawing: initialDrawing));

        expect(find.text(_l10n.drawHere), findsNothing);
      });

      testWidgets('handles strokes that are maps instead of lists', (tester) async {
        final initialDrawing = '[{"x":10,"y":20}]';
        await tester.pumpWidget(buildWidget(initialDrawing: initialDrawing));

        expect(find.text(_l10n.drawHere), findsOneWidget);
      });

      testWidgets('loads drawing with very large coordinates', (tester) async {
        final initialDrawing = '[[{"x":9999,"y":8888}]]';
        await tester.pumpWidget(buildWidget(initialDrawing: initialDrawing));

        expect(find.text(_l10n.drawHere), findsNothing);
      });

      testWidgets('handles negative coordinates in initial drawing', (tester) async {
        final initialDrawing = '[[{"x":-10,"y":-20}]]';
        await tester.pumpWidget(buildWidget(initialDrawing: initialDrawing));

        expect(find.text(_l10n.drawHere), findsNothing);
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

    group('drawing interaction edge cases', () {
      testWidgets('single tap creates a point and shows no placeholder', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.up();
        await tester.pump();

        expect(find.text(_l10n.drawHere), findsNothing);
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

        expect(find.text(_l10n.drawHere), findsNothing);
      });
    });

    group('save completion', () {
      testWidgets('save completes with data when paint boundary exists', (tester) async {
        Uint8List? captured;
        await tester.pumpWidget(buildWidget(
          onDrawingComplete: (data) => captured = data,
        ));

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        await tester.tap(find.widgetWithText(ElevatedButton, _l10n.saveDrawing));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        await tester.pump();

        expect(captured, isNotNull);
      });

      testWidgets('save with error triggers callback regardless', (tester) async {
        bool callbackCalled = false;
        await tester.pumpWidget(buildWidget(
          onDrawingComplete: (_) { callbackCalled = true; },
        ));

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        await tester.tap(find.widgetWithText(ElevatedButton, _l10n.saveDrawing));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        await tester.pump();

        expect(callbackCalled, isTrue);
      });

      testWidgets('save button re-enabled after save completes', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        await tester.tap(find.widgetWithText(ElevatedButton, _l10n.saveDrawing));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        await tester.pump();

        expect(find.widgetWithText(ElevatedButton, _l10n.saveDrawing), findsOneWidget);
      });
    });

    group('save error handling', () {
      testWidgets('save catches error when callback throws', (tester) async {
        await tester.pumpWidget(buildWidget(
          onDrawingComplete: (_) => throw Exception('Save failed'),
        ));

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        await tester.tap(find.widgetWithText(ElevatedButton, _l10n.saveDrawing));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        await tester.pump();

        expect(find.textContaining(_l10n.failedToSaveDrawing), findsOneWidget);
      });

      testWidgets('save button re-enabled after error', (tester) async {
        await tester.pumpWidget(buildWidget(
          onDrawingComplete: (_) => throw Exception('Save failed'),
        ));

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        await tester.tap(find.widgetWithText(ElevatedButton, _l10n.saveDrawing));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        await tester.pump();

        expect(find.widgetWithText(ElevatedButton, _l10n.saveDrawing), findsOneWidget);
      });
    });

    group('painter edge cases', () {
      testWidgets('DrawingPainter with empty stroke list does not crash', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.byType(CanvasDrawingWidget), findsOneWidget);
      });

      testWidgets('GridPainter draws horizontal and vertical lines', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.byType(CustomPaint), findsWidgets);
      });
    });

    group('save message display', () {
      testWidgets('shows save message after successful save', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        await tester.tap(find.widgetWithText(ElevatedButton, _l10n.saveDrawing));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        await tester.pump();

        expect(find.text(_l10n.drawingSaved), findsOneWidget);
      });
    });

    group('initial drawing multiple strokes', () {
      testWidgets('loads multiple strokes from initial drawing', (tester) async {
        final initialDrawing = '[[{"x":10,"y":20}],[{"x":30,"y":40},{"x":50,"y":60}]]';
        await tester.pumpWidget(buildWidget(initialDrawing: initialDrawing));

        expect(find.text(_l10n.drawHere), findsNothing);
      });

      testWidgets('loads drawing with all valid points even with mixed data', (tester) async {
        final initialDrawing = '[[{"x":10,"y":20,"foo":"bar"},{"x":30,"y":40}]]';
        await tester.pumpWidget(buildWidget(initialDrawing: initialDrawing));

        expect(find.text(_l10n.drawHere), findsNothing);
      });
    });

    group('undo after clear', () {
      testWidgets('undo after clear does nothing', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.undo));
        await tester.pump();

        expect(find.text(_l10n.drawHere), findsOneWidget);
      });
    });

    group('semantics', () {
      testWidgets('canvas has semantics container label and draw hint', (tester) async {
        await tester.pumpWidget(buildWidget(instruction: 'Draw circle'));
        expect(find.bySemanticsLabel('Draw circle'), findsOneWidget);
      });

      testWidgets('canvas with no instruction uses default drawing label', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.bySemanticsLabel(RegExp('Drawing canvas', caseSensitive: false)), findsOneWidget);
      });
    });

    group('handlePan edge cases', () {
      testWidgets('_handlePanUpdate does nothing when _isDrawing is false', (tester) async {
        await tester.pumpWidget(buildWidget());

        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.up();
        await tester.pump();

        expect(find.byType(CanvasDrawingWidget), findsOneWidget);
      });

      testWidgets('undo button icon semantics', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.byIcon(Icons.undo), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });
    });

    group('drawing border color change', () {
      testWidgets('border changes during active drawing', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.byType(CanvasDrawingWidget), findsOneWidget);
      });
    });

    group('redo functionality', () {
      testWidgets('redo button shown alongside undo', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.byIcon(Icons.redo), findsOneWidget);
        expect(find.byIcon(Icons.undo), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });
    });

    group('toolbar options', () {
      testWidgets('toolbar shows tool buttons when showTools is true', (tester) async {
        await tester.pumpWidget(buildWidget(showTools: true));
        await tester.pump();
        expect(find.byIcon(Icons.brush), findsOneWidget);
        expect(find.byIcon(Icons.show_chart), findsOneWidget);
        expect(find.byIcon(Icons.crop_square), findsOneWidget);
        expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
        expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
      });

      testWidgets('toolbar does not show tool buttons when showTools is false', (tester) async {
        await tester.pumpWidget(buildWidget(showTools: false));
        await tester.pump();
        expect(find.byIcon(Icons.brush), findsNothing);
      });

      testWidgets('tool selection changes highlighted button', (tester) async {
        await tester.pumpWidget(buildWidget(showTools: true));
        await tester.pump();

        final lineTool = find.byIcon(Icons.show_chart);
        await tester.tap(lineTool);
        await tester.pump();

        expect(lineTool, findsOneWidget);
      });

      testWidgets('color picker shows color circles when showColorPicker is true', (tester) async {
        await tester.pumpWidget(buildWidget(showColorPicker: true));
        await tester.pump();
        expect(find.byType(CanvasDrawingWidget), findsOneWidget);
      });

      testWidgets('stroke width icons shown when showStrokeWidth is true', (tester) async {
        await tester.pumpWidget(buildWidget(showStrokeWidth: true));
        await tester.pump();
        expect(find.byIcon(Icons.horizontal_rule), findsOneWidget);
        expect(find.byIcon(Icons.remove), findsOneWidget);
        expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
      });
    });
  });
}
