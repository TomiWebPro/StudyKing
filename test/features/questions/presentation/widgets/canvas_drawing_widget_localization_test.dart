import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/data/models/drawing_models.dart';
import 'package:studyking/features/questions/presentation/widgets/canvas_drawing_widget.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';
import 'package:studyking/l10n/generated/app_localizations_es.dart';

Widget buildLocalizedCanvasWidget({
  required Locale locale,
  CanvasInputMode? inputMode,
  ValueChanged<Uint8List>? onDrawingComplete,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Scaffold(
      body: CanvasDrawingWidget(
        onDrawingComplete: onDrawingComplete ?? (_) {},
        inputMode: inputMode,
      ),
    ),
  );
}

Future<void> drawDiagonalStroke(WidgetTester tester) async {
  final gesture = await tester.startGesture(const Offset(100, 100));
  await gesture.moveBy(const Offset(20, 20));
  await gesture.moveBy(const Offset(20, 20));
  await gesture.moveBy(const Offset(10, 10));
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  const enLocale = Locale('en');
  const esLocale = Locale('es');
  final enL10n = AppLocalizationsEn();
  final esL10n = AppLocalizationsEs();

  group('CanvasDrawingWidget localization', () {
    testWidgets('draw mode placeholder is localized in es', (tester) async {
      await tester.pumpWidget(buildLocalizedCanvasWidget(locale: esLocale));
      await tester.pumpAndSettle();

      expect(find.text(esL10n.drawHere), findsOneWidget);
      expect(find.text('Draw here...'), findsNothing);
    });

    testWidgets('handwriting mode placeholder is localized in es', (tester) async {
      await tester.pumpWidget(
        buildLocalizedCanvasWidget(
          locale: esLocale,
          inputMode: CanvasInputMode.handwriteMath,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(esL10n.writeHere), findsOneWidget);
      expect(find.text('Write here'), findsNothing);
    });

    testWidgets('handwriting mode placeholder is localized in en', (tester) async {
      await tester.pumpWidget(
        buildLocalizedCanvasWidget(
          locale: enLocale,
          inputMode: CanvasInputMode.handwriteText,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(enL10n.writeHere), findsOneWidget);
    });

    testWidgets('recognition confidence label is localized in es', (tester) async {
      await tester.pumpWidget(
        buildLocalizedCanvasWidget(
          locale: esLocale,
          inputMode: CanvasInputMode.handwriteMath,
        ),
      );
      await tester.pumpAndSettle();

      await drawDiagonalStroke(tester);

      // A straight diagonal stroke is heuristically recognized as '=' with
      // 0.5 confidence, so the badge must read "50% Confianza".
      expect(find.text('50% ${esL10n.confidence}'), findsOneWidget);
      expect(find.text('50% confidence'), findsNothing);
    });

    testWidgets('recognition confidence label is localized in en', (tester) async {
      await tester.pumpWidget(
        buildLocalizedCanvasWidget(
          locale: enLocale,
          inputMode: CanvasInputMode.handwriteMath,
        ),
      );
      await tester.pumpAndSettle();

      await drawDiagonalStroke(tester);

      expect(find.text('50% ${enL10n.confidence}'), findsOneWidget);
    });

    testWidgets('submit text button label is localized in es', (tester) async {
      await tester.pumpWidget(
        buildLocalizedCanvasWidget(
          locale: esLocale,
          inputMode: CanvasInputMode.handwriteText,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(esL10n.submitText), findsOneWidget);
      expect(find.text('Submit Text'), findsNothing);
    });

    testWidgets('submit text button label is localized in en', (tester) async {
      await tester.pumpWidget(
        buildLocalizedCanvasWidget(
          locale: enLocale,
          inputMode: CanvasInputMode.handwriteText,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(enL10n.submitText), findsOneWidget);
    });

    testWidgets('save drawing button label stays localized in es draw mode',
        (tester) async {
      await tester.pumpWidget(
        buildLocalizedCanvasWidget(
          locale: esLocale,
          inputMode: CanvasInputMode.draw,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(esL10n.saveDrawing), findsOneWidget);
      expect(find.text(esL10n.submitText), findsNothing);
    });
  });
}
