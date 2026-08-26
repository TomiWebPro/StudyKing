import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/presentation/widgets/syllabus_breakdown_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../../helpers/navigator_observer_helper.dart';

Widget _buildTestApp(Widget child, {TestNavigatorObserver? navigatorObserver}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
    home: Scaffold(body: child),
  );
}

SyllabusBreakdown _breakdown({
  required String subjectId,
  required String subjectTitle,
  double completionPercent = 0.0,
  double accuracy = 0.0,
  int totalTopics = 0,
  int masteredTopics = 0,
  int weakTopics = 0,
  double studyHours = 0.0,
}) {
  return SyllabusBreakdown(
    subjectId: subjectId,
    subjectTitle: subjectTitle,
    completionPercent: completionPercent,
    accuracy: accuracy,
    totalTopics: totalTopics,
    masteredTopics: masteredTopics,
    weakTopics: weakTopics,
    studyHours: studyHours,
  );
}

void main() {
  group('SyllabusBreakdownCard', () {
    testWidgets('renders nothing when breakdowns are empty', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SyllabusBreakdownCard(breakdowns: []),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SyllabusBreakdownCard), findsOneWidget);
      expect(find.text('Progress by syllabus'), findsNothing);
    });

    testWidgets('renders title and one row per syllabus', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SyllabusBreakdownCard(
          breakdowns: [
            _breakdown(subjectId: 's1', subjectTitle: 'Mathematics'),
            _breakdown(subjectId: 's2', subjectTitle: 'Physics'),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Progress by syllabus'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    });

    testWidgets('renders completion percent for each row', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SyllabusBreakdownCard(
          breakdowns: [
            _breakdown(
              subjectId: 's1',
              subjectTitle: 'Mathematics',
              completionPercent: 0.75,
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('75%'), findsWidgets);
    });

    testWidgets('shows accuracy, weak count and study time metrics',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SyllabusBreakdownCard(
          breakdowns: [
            _breakdown(
              subjectId: 's1',
              subjectTitle: 'Mathematics',
              completionPercent: 0.5,
              accuracy: 0.9,
              weakTopics: 3,
              studyHours: 2.5,
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('90%'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('2.5'), findsOneWidget);
    });

    testWidgets('filters to selected syllabus when selectedSubjectId set',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SyllabusBreakdownCard(
          breakdowns: [
            _breakdown(subjectId: 's1', subjectTitle: 'Mathematics'),
            _breakdown(subjectId: 's2', subjectTitle: 'Physics'),
          ],
          selectedSubjectId: 's2',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Mathematics'), findsNothing);
      expect(find.text('Physics'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders nothing when selected syllabus is absent',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SyllabusBreakdownCard(
          breakdowns: [
            _breakdown(subjectId: 's1', subjectTitle: 'Mathematics'),
          ],
          selectedSubjectId: 'missing',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Progress by syllabus'), findsNothing);
      expect(find.text('Mathematics'), findsNothing);
    });

    testWidgets('uses progress color styling on completion text',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SyllabusBreakdownCard(
          breakdowns: [
            _breakdown(
              subjectId: 's1',
              subjectTitle: 'Mathematics',
              completionPercent: 0.8,
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      final textWidgets = tester.widgetList<Text>(find.byType(Text)).toList();
      final completionText = textWidgets.firstWhere((t) => t.data == '80%');
      expect(completionText.style?.fontWeight, FontWeight.bold);
      expect(completionText.style?.color, isNotNull);
    });

    testWidgets('shows syllabus completion metric label', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SyllabusBreakdownCard(
          breakdowns: [
            _breakdown(
              subjectId: 's1',
              subjectTitle: 'Mathematics',
              completionPercent: 0.4,
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Completion'), findsOneWidget);
      expect(find.text('Accuracy'), findsOneWidget);
      expect(find.text('Weak topics'), findsOneWidget);
      expect(find.text('Study Time'), findsOneWidget);
    });
  });
}
