import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/presentation/planner_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp() {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: const PlannerScreen(),
  );
}

void main() {
  group('PlannerScreen', () {
    testWidgets('renders title and form fields', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Study Planner'), findsOneWidget);
      expect(find.text('Create Study Plan'), findsOneWidget);
      expect(find.text('Generate Plan'), findsOneWidget);
    });

    testWidgets('shows three input fields', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets('shows calendar icon on generate button', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('generate button is enabled initially', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows snackbar when fields are empty on generate', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generate Plan'));
      await tester.pumpAndSettle();

      expect(find.text('Please fill in all fields correctly'), findsOneWidget);
    });

    testWidgets('days field uses number keyboard type', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(textFields.length, 3);

      final daysField = textFields[1];
      expect(daysField.keyboardType, TextInputType.number);

      final hoursField = textFields[2];
      expect(hoursField.keyboardType, TextInputType.number);
    });

    testWidgets('no schedule list shown initially', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Your Study Schedule'), findsNothing);
    });
  });
}
