import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/presentation/widgets/mastery_remaining_lessons_card.dart';
import 'package:studyking/features/planner/services/mastery_remaining_lessons_estimator.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(RemainingLessonsEstimate estimate) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: MasteryRemainingLessonsCard(estimate: estimate),
    ),
  );
}

void main() {
  testWidgets('renders title and localized remaining-lessons message',
      (tester) async {
    await tester.pumpWidget(_buildTestApp(
      const RemainingLessonsEstimate(8, 0.5),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Lessons to Mastery'), findsOneWidget);
    expect(find.text('8 lessons left to reach mastery'), findsOneWidget);
  });

  testWidgets('zero remaining lessons shows the no-lessons message',
      (tester) async {
    await tester.pumpWidget(_buildTestApp(
      const RemainingLessonsEstimate(0, 1.0),
    ));
    await tester.pumpAndSettle();

    expect(find.text('No lessons left to reach mastery'), findsOneWidget);
  });
}
