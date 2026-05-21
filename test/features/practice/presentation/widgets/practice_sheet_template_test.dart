import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_sheet_template.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('PracticeSheetTemplate', () {
    testWidgets('renders title and children', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PracticeSheetTemplate(
          title: 'Select Topic',
          children: [
            Text('Algebra'),
            Text('Geometry'),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Select Topic'), findsOneWidget);
      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('Geometry'), findsOneWidget);
    });

    testWidgets('renders title with bold styling', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PracticeSheetTemplate(
          title: 'Test Title',
          children: [],
        ),
      ));
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text('Test Title'));
      expect(text.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('renders with SafeArea padding', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PracticeSheetTemplate(
          title: 'Padded',
          children: [Text('Content')],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Padded'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('renders SafeArea wrapper', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PracticeSheetTemplate(
          title: 'Safe',
          children: [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('renders with default zero padding', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PracticeSheetTemplate(
          title: 'Default Pad',
          children: [Text('Item')],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Default Pad'), findsOneWidget);
      expect(find.text('Item'), findsOneWidget);
    });

    testWidgets('static show displays bottom sheet', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              PracticeSheetTemplate.show(
                context,
                title: 'Bottom Sheet',
                children: [const Text('Sheet Content')],
              );
            },
            child: const Text('Show Sheet'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Bottom Sheet'), findsOneWidget);
      expect(find.text('Sheet Content'), findsOneWidget);
    });

    testWidgets('static show renders multiple children', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              PracticeSheetTemplate.show(
                context,
                title: 'Multiple Items',
                children: const [
                  Text('Item 1'),
                  Text('Item 2'),
                  Text('Item 3'),
                ],
              );
            },
            child: const Text('Open'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Multiple Items'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('renders Column with min main axis size', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PracticeSheetTemplate(
          title: 'Column Test',
          children: [Text('Content')],
        ),
      ));
      await tester.pumpAndSettle();

      final column = tester.widget<Column>(find.byType(Column).first);
      expect(column.mainAxisSize, MainAxisSize.min);
    });
  });
}
