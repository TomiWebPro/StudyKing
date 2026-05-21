import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/features/practice/presentation/widgets/subject_practice_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('SubjectPracticeCard', () {
    testWidgets('renders subject name', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SubjectPracticeCard(
          subject: Subject(id: 's1', name: 'Mathematics', code: 'MATH101'),
          onTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Mathematics'), findsOneWidget);
    });

    testWidgets('renders subject code', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SubjectPracticeCard(
          subject: Subject(id: 's1', name: 'Mathematics', code: 'MATH101'),
          onTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('MATH101'), findsOneWidget);
    });

    testWidgets('renders play circle icon', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SubjectPracticeCard(
          subject: Subject(id: 's1', name: 'Mathematics'),
          onTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_circle), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_buildTestApp(
        SubjectPracticeCard(
          subject: Subject(id: 's1', name: 'Mathematics'),
          onTap: () => tapped = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mathematics'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('renders card layout', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SubjectPracticeCard(
          subject: Subject(id: 's1', name: 'Physics'),
          onTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
      expect(find.byIcon(Icons.school), findsOneWidget);
    });

    testWidgets('renders practice available text for subject without code', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SubjectPracticeCard(
          subject: Subject(id: 's1', name: 'Mathematics'),
          onTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Practice available'), findsOneWidget);
      expect(find.byIcon(Icons.quiz), findsOneWidget);
    });

    testWidgets('renders subject with code showing code', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SubjectPracticeCard(
          subject: Subject(id: 's1', name: 'Mathematics', code: 'MATH101'),
          onTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('MATH101'), findsOneWidget);
      expect(find.text('Practice available'), findsOneWidget);
    });

    testWidgets('renders InkWell tap target', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SubjectPracticeCard(
          subject: Subject(id: 's1', name: 'Mathematics'),
          onTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
