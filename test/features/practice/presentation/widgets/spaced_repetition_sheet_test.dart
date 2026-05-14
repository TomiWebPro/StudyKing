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
  });
}
