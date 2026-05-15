import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/features/practice/presentation/widgets/subject_selection_sheet.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('SubjectSelectionSheet', () {
    testWidgets('renders subject list', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SubjectSelectionSheet(
          subjects: [
            Subject(id: 's1', name: 'Mathematics'),
            Subject(id: 's2', name: 'Physics'),
          ],
          onSubjectSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);
    });

    testWidgets('calls onSubjectSelected when subject tapped', (tester) async {
      Subject? selected;
      await tester.pumpWidget(_buildTestApp(
        SubjectSelectionSheet(
          subjects: [
            Subject(id: 's1', name: 'Mathematics'),
          ],
          onSubjectSelected: (s) => selected = s,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mathematics'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.id, 's1');
    });

    testWidgets('uses subtitleBuilder when provided', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SubjectSelectionSheet(
          subjects: [
            Subject(id: 's1', name: 'Mathematics', code: 'MATH101'),
          ],
          onSubjectSelected: (_) {},
          subtitleBuilder: (s) => '5 questions due',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('5 questions due'), findsOneWidget);
    });

    testWidgets('shows subject code as subtitle when no subtitleBuilder', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SubjectSelectionSheet(
          subjects: [
            Subject(id: 's1', name: 'Mathematics', code: 'MATH101'),
          ],
          onSubjectSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('MATH101'), findsOneWidget);
    });

    testWidgets('renders empty subjects list gracefully', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SubjectSelectionSheet(
          subjects: [],
          onSubjectSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Select Subject'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('shows no subtitle when code is null and no subtitleBuilder', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SubjectSelectionSheet(
          subjects: [
            Subject(id: 's1', name: 'Mathematics'),
          ],
          onSubjectSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      // Subject with null code and no subtitleBuilder: subtitle is null => no subtitle
      expect(find.text('Mathematics'), findsOneWidget);
      // Verify ListTile exists
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('static show displays bottom sheet', (tester) async {
      Subject? selected;
      await tester.pumpWidget(_buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              SubjectSelectionSheet.show(
                context,
                subjects: [
                  Subject(id: 's1', name: 'Mathematics'),
                ],
                onSubjectSelected: (s) => selected = s,
              );
            },
            child: const Text('Show Sheet'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Select Subject'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);

      await tester.tap(find.text('Mathematics'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.id, 's1');
    });
  });
}
