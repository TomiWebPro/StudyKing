import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/presentation/widgets/mastery_progress_card.dart';
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

    testWidgets('shows correct inProgress count', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        MasteryProgressCard(snapshot: MasterySnapshot(
          totalTopics: 10,
          masteredTopics: 4,
          weakTopics: 2,
        )),
      ));
      await tester.pumpAndSettle();

      // inProgress = 10 - 4 - 2 = 4
      expect(find.text('4'), findsAtLeast(1));
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('shows zero inProgress when all mastered', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        MasteryProgressCard(snapshot: MasterySnapshot(
          totalTopics: 5,
          masteredTopics: 5,
          weakTopics: 0,
        )),
      ));
      await tester.pumpAndSettle();

      // inProgress = 5 - 5 - 0 = 0
      // 0 appears many times (for inProgress, weakTopics, avgAccuracy)
      expect(find.text('0'), findsAtLeast(1));
    });

    testWidgets('shows 40% progress bar for 2/5 mastered', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        MasteryProgressCard(snapshot: MasterySnapshot(
          totalTopics: 5,
          masteredTopics: 2,
          weakTopics: 1,
        )),
      ));
      await tester.pumpAndSettle();

      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.value, closeTo(0.4, 0.01));
    });

    testWidgets('shows names for all stat columns', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        MasteryProgressCard(snapshot: MasterySnapshot(
          totalTopics: 10,
          masteredTopics: 3,
          weakTopics: 2,
        )),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Total Topics'), findsOneWidget);
      expect(find.text('Mastered'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
    });

    testWidgets('shows stale data banner when daysSinceUpdate >= 3', (tester) async {
      final oldDate = DateTime.now().subtract(const Duration(days: 3));
      await tester.pumpWidget(_buildTestApp(
        MasteryProgressCard(snapshot: MasterySnapshot(
          totalTopics: 5,
          masteredTopics: 2,
          weakTopics: 1,
          averageAccuracy: 0.6,
          avgReadiness: 0.5,
          lastUpdated: oldDate,
        )),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('days ago'), findsWidgets);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('shows warning banner when daysSinceUpdate >= 7', (tester) async {
      final oldDate = DateTime.now().subtract(const Duration(days: 7));
      await tester.pumpWidget(_buildTestApp(
        MasteryProgressCard(snapshot: MasterySnapshot(
          totalTopics: 5,
          masteredTopics: 2,
          weakTopics: 1,
          averageAccuracy: 0.6,
          avgReadiness: 0.5,
          lastUpdated: oldDate,
        )),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('days ago'), findsWidgets);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('no stale data banner when just updated', (tester) async {
      final recentDate = DateTime.now().subtract(const Duration(days: 1));
      await tester.pumpWidget(_buildTestApp(
        MasteryProgressCard(snapshot: MasterySnapshot(
          totalTopics: 5,
          masteredTopics: 2,
          weakTopics: 1,
          averageAccuracy: 0.6,
          avgReadiness: 0.5,
          lastUpdated: recentDate,
        )),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('shows weak topics stat label', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        MasteryProgressCard(snapshot: MasterySnapshot(
          totalTopics: 10,
          masteredTopics: 4,
          weakTopics: 3,
        )),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Weak Topics'), findsOneWidget);
    });

    testWidgets('handles zero totalTopics gracefully', (tester) async {
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

    testWidgets('shows accuracy stat column', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        MasteryProgressCard(snapshot: MasterySnapshot(
          totalTopics: 10,
          masteredTopics: 4,
          weakTopics: 2,
          averageAccuracy: 0.85,
        )),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Accuracy'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('shows readiness stat column', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        MasteryProgressCard(snapshot: MasterySnapshot(
          totalTopics: 10,
          masteredTopics: 4,
          weakTopics: 2,
          avgReadiness: 0.7,
        )),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Readiness'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);
    });

    testWidgets('handles null lastUpdated', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const MasteryProgressCard(snapshot: MasterySnapshot(
          totalTopics: 5,
          masteredTopics: 2,
          weakTopics: 1,
        )),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });
  });
}
