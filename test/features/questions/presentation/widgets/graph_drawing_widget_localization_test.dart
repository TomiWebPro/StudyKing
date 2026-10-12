import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/presentation/widgets/graph_drawing_widget.dart';
import '../../../../helpers/locale_switch_harness.dart';

Future<void> drawDiagonalStroke(WidgetTester tester) async {
  final gesture = await tester.startGesture(const Offset(100, 100));
  await gesture.moveBy(const Offset(20, 20));
  await gesture.moveBy(const Offset(20, 20));
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  group('GraphDrawingWidget - locale switch', () {
    testWidgets('save message follows locale switch', (tester) async {
      final harnessKey = GlobalKey<LocaleSwitchHarnessState>();
      await tester.pumpWidget(LocaleSwitchHarness(
        key: harnessKey,
        child: Scaffold(
          body: GraphDrawingWidget(onDrawingComplete: (_) {}),
        ),
      ));
      await tester.pumpAndSettle();

      await drawDiagonalStroke(tester);

      final saveButton = find.widgetWithText(ElevatedButton, 'Save Drawing');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();

      // RepaintBoundary.toImage rasterizes on the real event
      // loop, so the save flow runs outside the fake clock.
      await tester.runAsync(() async {
        await tester.tap(saveButton);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await Future.delayed(const Duration(milliseconds: 500));
        await tester.pump();
      });
      await tester.pump();

      expect(find.text('Drawing saved.'), findsOneWidget);

      harnessKey.currentState!.switchLocale(const Locale('es'));
      await tester.pumpAndSettle();

      expect(find.text('Dibujo guardado.'), findsOneWidget);
      expect(find.text('Drawing saved.'), findsNothing);
    });

    testWidgets('save failure message follows locale switch',
        (tester) async {
      final harnessKey = GlobalKey<LocaleSwitchHarnessState>();
      await tester.pumpWidget(LocaleSwitchHarness(
        key: harnessKey,
        child: Scaffold(
          // A throwing callback runs inside _handleSave's try
          // block, driving the failedToSaveDrawing path.
          body: GraphDrawingWidget(
            onDrawingComplete: (_) {
              throw Exception('save failed');
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await drawDiagonalStroke(tester);

      final saveButton = find.widgetWithText(ElevatedButton, 'Save Drawing');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(saveButton);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await Future.delayed(const Duration(milliseconds: 500));
        await tester.pump();
      });
      await tester.pump();

      expect(find.text('Failed to save drawing. Retry.'), findsOneWidget);

      harnessKey.currentState!.switchLocale(const Locale('es'));
      await tester.pumpAndSettle();

      expect(find.text('Error al guardar el dibujo. Reintente.'), findsOneWidget);
      expect(find.text('Failed to save drawing. Retry.'), findsNothing);
    });
  });
}
