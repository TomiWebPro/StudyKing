import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/features/practice/presentation/widgets/weak_areas_sheet.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('WeakAreasSheet', () {
    testWidgets('renders subject list', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        WeakAreasSheet(
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
        WeakAreasSheet(
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

    testWidgets('renders select subject title', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        WeakAreasSheet(
          subjects: [
            Subject(id: 's1', name: 'Mathematics'),
          ],
          onSubjectSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Select Subject'), findsOneWidget);
    });

    testWidgets('renders school icon for each subject', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        WeakAreasSheet(
          subjects: [
            Subject(id: 's1', name: 'Mathematics'),
            Subject(id: 's2', name: 'Physics'),
          ],
          onSubjectSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.school), findsNWidgets(2));
    });

    testWidgets('renders list tiles for each subject', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        WeakAreasSheet(
          subjects: [
            Subject(id: 's1', name: 'Mathematics'),
            Subject(id: 's2', name: 'Physics'),
          ],
          onSubjectSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(2));
    });

    testWidgets('renders empty subjects list gracefully', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        WeakAreasSheet(
          subjects: [],
          onSubjectSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Select Subject'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('renders three subjects correctly', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        WeakAreasSheet(
          subjects: [
            Subject(id: 's1', name: 'Mathematics'),
            Subject(id: 's2', name: 'Physics'),
            Subject(id: 's3', name: 'Chemistry'),
          ],
          onSubjectSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(3));
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);
      expect(find.text('Chemistry'), findsOneWidget);
    });

    testWidgets('static show displays bottom sheet', (tester) async {
      Subject? selected;
      await tester.pumpWidget(_buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              WeakAreasSheet.show(
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
