import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/features/planner/presentation/widgets/multi_syllabus_input.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget buildApp(Widget widget) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: widget),
  );
}

List<Subject> _createSubjects() {
  return [
    Subject(id: 's1', name: 'Physics'),
    Subject(id: 's2', name: 'Chemistry'),
    Subject(id: 's3', name: 'Biology'),
  ];
}

void main() {
  group('MultiSyllabusInput', () {
    testWidgets('renders with a single entry by default', (tester) async {
      await tester.pumpWidget(buildApp(
        MultiSyllabusInput(
          entries: [SyllableEntry()],
          allSubjects: _createSubjects(),
          onAddEntry: () {},
          onRemoveEntry: (_) {},
          onSubjectChanged: (_, __) {},
        ),
      ));

      expect(find.text('Course/Subject 1'), findsOneWidget);
    });

    testWidgets('shows add button', (tester) async {
      await tester.pumpWidget(buildApp(
        MultiSyllabusInput(
          entries: [SyllableEntry()],
          allSubjects: _createSubjects(),
          onAddEntry: () {},
          onRemoveEntry: (_) {},
          onSubjectChanged: (_, __) {},
        ),
      ));

      expect(find.text('Add Course/Subject'), findsOneWidget);
    });

    testWidgets('shows days and hours fields per entry', (tester) async {
      await tester.pumpWidget(buildApp(
        MultiSyllabusInput(
          entries: [SyllableEntry()],
          allSubjects: _createSubjects(),
          onAddEntry: () {},
          onRemoveEntry: (_) {},
          onSubjectChanged: (_, __) {},
        ),
      ));

      expect(find.text('Days'), findsOneWidget);
      expect(find.text('Hours/Day'), findsOneWidget);
    });

    testWidgets('shows remove button per entry', (tester) async {
      await tester.pumpWidget(buildApp(
        MultiSyllabusInput(
          entries: [SyllableEntry()],
          allSubjects: _createSubjects(),
          onAddEntry: () {},
          onRemoveEntry: (_) {},
          onSubjectChanged: (_, __) {},
        ),
      ));

      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
    });

    testWidgets('triggers onAddEntry when add button tapped', (tester) async {
      bool addTapped = false;
      await tester.pumpWidget(buildApp(
        MultiSyllabusInput(
          entries: [SyllableEntry()],
          allSubjects: _createSubjects(),
          onAddEntry: () => addTapped = true,
          onRemoveEntry: (_) {},
          onSubjectChanged: (_, __) {},
        ),
      ));

      await tester.tap(find.text('Add Course/Subject'));
      expect(addTapped, isTrue);
    });

    testWidgets('triggers onRemoveEntry when remove button tapped', (tester) async {
      int removeIndex = -1;
      await tester.pumpWidget(buildApp(
        MultiSyllabusInput(
          entries: [SyllableEntry(), SyllableEntry()],
          allSubjects: _createSubjects(),
          onAddEntry: () {},
          onRemoveEntry: (index) => removeIndex = index,
          onSubjectChanged: (_, __) {},
        ),
      ));

      // Tap the first remove button
      await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
      expect(removeIndex, 0);
    });
  });
}
