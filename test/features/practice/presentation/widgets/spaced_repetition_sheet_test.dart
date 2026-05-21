import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/features/practice/presentation/widgets/spaced_repetition_sheet.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('SpacedRepetitionSheet', () {
    testWidgets('renders subjects with due counts', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SpacedRepetitionSheet(
          subjectsWithDue: [
            Subject(id: 's1', name: 'Mathematics'),
          ],
          dueCounts: {'s1': 5},
          onSubjectSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('5 due'), findsOneWidget);
    });

    testWidgets('calls onSubjectSelected when subject tapped', (tester) async {
      Subject? selected;
      await tester.pumpWidget(_buildTestApp(
        SpacedRepetitionSheet(
          subjectsWithDue: [
            Subject(id: 's1', name: 'Mathematics'),
          ],
          dueCounts: {'s1': 3},
          onSubjectSelected: (s) => selected = s,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mathematics'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.id, 's1');
    });

    testWidgets('renders empty subjects list gracefully', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SpacedRepetitionSheet(
          subjectsWithDue: [],
          dueCounts: {},
          onSubjectSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Select Subject'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('renders multiple subjects with different due counts', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SpacedRepetitionSheet(
          subjectsWithDue: [
            Subject(id: 's1', name: 'Mathematics'),
            Subject(id: 's2', name: 'Physics'),
            Subject(id: 's3', name: 'Chemistry'),
          ],
          dueCounts: {'s1': 5, 's2': 3, 's3': 0},
          onSubjectSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(3));
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);
      expect(find.text('Chemistry'), findsOneWidget);
      expect(find.text('5 due'), findsOneWidget);
      expect(find.text('3 due'), findsOneWidget);
      expect(find.text('0 due'), findsOneWidget);
    });

    testWidgets('shows due count of 0 for missing subject', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SpacedRepetitionSheet(
          subjectsWithDue: [
            Subject(id: 's1', name: 'Mathematics'),
          ],
          dueCounts: {},
          onSubjectSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('0 due'), findsOneWidget);
    });

    testWidgets('showAllCaughtUp displays bottom sheet with icon and text', (tester) async {
      await tester.pumpWidget(_buildTestApp(const SizedBox.shrink()));
      await tester.pumpAndSettle();

      SpacedRepetitionSheet.showAllCaughtUp(tester.element(find.byType(SizedBox)));

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('All caught up!'), findsOneWidget);
      expect(find.text('No reviews scheduled.'), findsOneWidget);
      expect(find.text('Back to Practice'), findsOneWidget);
    });

    testWidgets('showAllCaughtUp back button pops the sheet', (tester) async {
      await tester.pumpWidget(_buildTestApp(const SizedBox.shrink()));
      await tester.pumpAndSettle();

      SpacedRepetitionSheet.showAllCaughtUp(tester.element(find.byType(SizedBox)));

      await tester.pumpAndSettle();

      await tester.tap(find.text('Back to Practice'));
      await tester.pumpAndSettle();

      expect(find.text('Back to Practice'), findsNothing);
    });

    testWidgets('showSubjectPicker displays bottom sheet with subjects', (tester) async {
      Subject? selected;
      await tester.pumpWidget(_buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              SpacedRepetitionSheet.showSubjectPicker(
                context,
                subjectsWithDue: [
                  Subject(id: 's1', name: 'Mathematics'),
                ],
                dueCounts: {'s1': 3},
                onSubjectSelected: (s) => selected = s,
              );
            },
            child: const Text('Show Picker'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('3 due'), findsOneWidget);

      await tester.tap(find.text('Mathematics'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.id, 's1');
    });
  });
}
