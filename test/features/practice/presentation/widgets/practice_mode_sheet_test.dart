import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_mode_option.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_mode_sheet.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('PracticeModeSheet', () {
    testWidgets('shows auto select when single subject', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeSheet(
          subjects: [
            Subject(id: 's1', name: 'Mathematics'),
          ],
          onSubjectSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Auto Select'), findsOneWidget);
      expect(find.text('AI picks optimal questions'), findsOneWidget);
    });

    testWidgets('shows subject choices when multiple subjects', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeSheet(
          subjects: [
            Subject(id: 's1', name: 'Mathematics'),
            Subject(id: 's2', name: 'Physics'),
          ],
          onSubjectSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Choose Subject'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);
    });

    testWidgets('calls onSubjectSelected with auto pick for single subject', (tester) async {
      Subject? selected;
      await tester.pumpWidget(_buildTestApp(
        PracticeModeSheet(
          subjects: [
            Subject(id: 's1', name: 'Mathematics'),
          ],
          onSubjectSelected: (s) => selected = s,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Auto Select'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.id, 's1');
    });

    testWidgets('shows subject code for subjects with code', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeSheet(
          subjects: [
            Subject(id: 's1', name: 'Mathematics', code: 'MATH101'),
            Subject(id: 's2', name: 'Physics', code: 'PHY201'),
          ],
          onSubjectSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('MATH101'), findsOneWidget);
      expect(find.text('PHY201'), findsOneWidget);
    });

    testWidgets('shows no code message when subject has no code', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeSheet(
          subjects: [
            Subject(id: 's1', name: 'Mathematics'),
            Subject(id: 's2', name: 'Physics'),
          ],
          onSubjectSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No code'), findsNWidgets(2));
    });

    testWidgets('calls onSubjectSelected when tapping a subject in multi mode', (tester) async {
      Subject? selected;
      await tester.pumpWidget(_buildTestApp(
        PracticeModeSheet(
          subjects: [
            Subject(id: 's1', name: 'Mathematics'),
            Subject(id: 's2', name: 'Physics'),
          ],
          onSubjectSelected: (s) => selected = s,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Physics'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.id, 's2');
    });

    testWidgets('renders empty subjects list gracefully', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeSheet(
          subjects: [],
          onSubjectSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Practice Mode'), findsOneWidget);
      expect(find.byType(PracticeModeOption), findsNothing);
    });

    testWidgets('static show displays bottom sheet', (tester) async {
      Subject? selected;
      await tester.pumpWidget(_buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              PracticeModeSheet.show(
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

      expect(find.text('Auto Select'), findsOneWidget);

      await tester.tap(find.text('Auto Select'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.id, 's1');
    });
  });
}
