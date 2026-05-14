import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/presentation/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/presentation/widgets/mastery_progress_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
    home: Scaffold(body: child),
  );
}

void main() {
  group('MasteryProgressCard', () {
    testWidgets('renders with null snapshot gracefully', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const MasteryProgressCard(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsAtLeast(1));
      expect(find.text('0%'), findsAtLeast(1));
    });

    testWidgets('renders with empty snapshot', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const MasteryProgressCard(snapshot: MasterySnapshot()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsAtLeast(1));
    });

    testWidgets('displays correct topic counts', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        MasteryProgressCard(snapshot: MasterySnapshot(
          totalTopics: 10,
          masteredTopics: 4,
          weakTopics: 2,
          averageAccuracy: 0.75,
          avgReadiness: 0.6,
        )),
      ));
      await tester.pumpAndSettle();

      expect(find.text('10'), findsOneWidget);
      expect(find.text('4'), findsAtLeast(1));
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('displays mastery overview header', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const MasteryProgressCard(snapshot: MasterySnapshot()),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.analytics), findsOneWidget);
    });

    testWidgets('shows linear progress indicator', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        MasteryProgressCard(snapshot: MasterySnapshot(
          totalTopics: 5,
          masteredTopics: 2,
        )),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows 0 mastery when no topics', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const MasteryProgressCard(snapshot: MasterySnapshot(
          totalTopics: 0,
          masteredTopics: 0,
          weakTopics: 0,
        )),
      ));
      await tester.pumpAndSettle();

      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.value, 0.0);
    });

    testWidgets('shows 100% mastery when all topics mastered', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        MasteryProgressCard(snapshot: MasterySnapshot(
          totalTopics: 5,
          masteredTopics: 5,
          weakTopics: 0,
        )),
      ));
      await tester.pumpAndSettle();

      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.value, 1.0);
    });
  });
}
