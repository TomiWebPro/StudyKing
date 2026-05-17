import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/presentation/widgets/due_reviews_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(DueReviewsCard card) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: card),
  );
}

void main() {
  group('DueReviewsCard', () {
    testWidgets('shows total due count', (tester) async {
      final data = DueReviewsData(
        totalDue: 12,
        subjectBreakdown: [
          SubjectDueCount(subjectId: 's1', subjectName: 'Math', dueCount: 7),
          SubjectDueCount(subjectId: 's2', subjectName: 'Physics', dueCount: 5),
        ],
      );

      await tester.pumpWidget(_buildTestApp(DueReviewsCard(data: data)));
      await tester.pumpAndSettle();

      expect(find.text(' due for review'), findsOneWidget);
    });

    testWidgets('shows subject breakdown', (tester) async {
      final data = DueReviewsData(
        totalDue: 7,
        subjectBreakdown: [
          SubjectDueCount(subjectId: 's1', subjectName: 'Mathematics', dueCount: 5),
          SubjectDueCount(subjectId: 's2', subjectName: 'Physics', dueCount: 2),
        ],
      );

      await tester.pumpWidget(_buildTestApp(DueReviewsCard(data: data)));
      await tester.pumpAndSettle();

      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);
    });

    testWidgets('limits breakdown to 5 subjects', (tester) async {
      final subjects = List.generate(
        7,
        (i) => SubjectDueCount(
          subjectId: 's$i',
          subjectName: 'Subject $i',
          dueCount: i + 1,
        ),
      );
      final data = DueReviewsData(totalDue: 28, subjectBreakdown: subjects);

      await tester.pumpWidget(_buildTestApp(DueReviewsCard(data: data)));
      await tester.pumpAndSettle();

      expect(find.text('Subject 0'), findsOneWidget);
      expect(find.text('Subject 4'), findsOneWidget);
      expect(find.text('Subject 5'), findsNothing);
      expect(find.text('Subject 6'), findsNothing);
    });

    testWidgets('excludes subjects with zero due count', (tester) async {
      final data = DueReviewsData(
        totalDue: 3,
        subjectBreakdown: [
          SubjectDueCount(subjectId: 's1', subjectName: 'Math', dueCount: 3),
          SubjectDueCount(subjectId: 's2', subjectName: 'Physics', dueCount: 0),
        ],
      );

      await tester.pumpWidget(_buildTestApp(DueReviewsCard(data: data)));
      await tester.pumpAndSettle();

      expect(find.text('Math'), findsOneWidget);
      expect(find.text('Physics'), findsNothing);
    });

    testWidgets('shows empty breakdown when no subjects have due', (tester) async {
      final data = DueReviewsData(
        totalDue: 0,
        subjectBreakdown: [
          SubjectDueCount(subjectId: 's1', subjectName: 'Math', dueCount: 0),
        ],
      );

      await tester.pumpWidget(_buildTestApp(DueReviewsCard(data: data)));
      await tester.pumpAndSettle();

      expect(find.text('Math'), findsNothing);
    });
  });
}
