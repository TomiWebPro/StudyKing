import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/presentation/widgets/syllabus_breakdown_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(SyllabusBreakdownCard card) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: card),
  );
}

SyllabusBreakdown _breakdown({
  required String subjectId,
  required String subjectTitle,
  double completionPercent = 0.0,
  double accuracy = 0.0,
  int weakTopics = 0,
  double studyHours = 0.0,
}) {
  return SyllabusBreakdown(
    subjectId: subjectId,
    subjectTitle: subjectTitle,
    completionPercent: completionPercent,
    accuracy: accuracy,
    weakTopics: weakTopics,
    studyHours: studyHours,
  );
}

void main() {
  group('SyllabusBreakdownCard', () {
    testWidgets('renders breakdown title and subject rows', (tester) async {
      final breakdowns = [
        _breakdown(subjectId: 's1', subjectTitle: 'Mathematics'),
        _breakdown(subjectId: 's2', subjectTitle: 'Physics'),
      ];

      await tester.pumpWidget(
        _buildTestApp(SyllabusBreakdownCard(breakdowns: breakdowns)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Progress by syllabus'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);
    });

    testWidgets('renders completion percent for each syllabus', (tester) async {
      final breakdowns = [
        _breakdown(subjectId: 's1', subjectTitle: 'Math', completionPercent: 0.42),
        _breakdown(subjectId: 's2', subjectTitle: 'Physics', completionPercent: 0.87),
      ];

      await tester.pumpWidget(
        _buildTestApp(SyllabusBreakdownCard(breakdowns: breakdowns)),
      );
      await tester.pumpAndSettle();

      expect(find.text('42%'), findsWidgets);
      expect(find.text('87%'), findsWidgets);
    });

    testWidgets('renders weak topic count and study time metrics',
        (tester) async {
      final breakdowns = [
        _breakdown(
          subjectId: 's1',
          subjectTitle: 'Chemistry',
          weakTopics: 5,
          studyHours: 2.5,
          accuracy: 0.9,
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(SyllabusBreakdownCard(breakdowns: breakdowns)),
      );
      await tester.pumpAndSettle();

      expect(find.text('5'), findsWidgets);
      expect(find.text('Chemistry'), findsOneWidget);
      expect(find.textContaining('h'), findsWidgets);
    });

    testWidgets('filters to selected subject when selectedSubjectId is set',
        (tester) async {
      final breakdowns = [
        _breakdown(subjectId: 's1', subjectTitle: 'Mathematics'),
        _breakdown(subjectId: 's2', subjectTitle: 'Physics'),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          SyllabusBreakdownCard(
            breakdowns: breakdowns,
            selectedSubjectId: 's1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Physics'), findsNothing);
    });

    testWidgets('renders nothing when breakdown list is empty',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(const SyllabusBreakdownCard(breakdowns: [])),
      );
      await tester.pumpAndSettle();

      expect(find.text('Syllabus Breakdown'), findsNothing);
    });

    testWidgets('renders nothing when selected subject is not present',
        (tester) async {
      final breakdowns = [
        _breakdown(subjectId: 's1', subjectTitle: 'Mathematics'),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          SyllabusBreakdownCard(
            breakdowns: breakdowns,
            selectedSubjectId: 'missing',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Syllabus Breakdown'), findsNothing);
      expect(find.text('Mathematics'), findsNothing);
    });
  });
}
