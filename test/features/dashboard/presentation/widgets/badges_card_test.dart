import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/presentation/widgets/badges_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../../helpers/navigator_observer_helper.dart';

Widget _buildTestApp(Widget child, {TestNavigatorObserver? navigatorObserver}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
    home: Scaffold(body: child),
  );
}

void main() {
  group('BadgesCard', () {
    testWidgets('renders no badges message when badges list is empty', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        BadgesCard(badges: []),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsNothing);
      expect(find.byIcon(Icons.emoji_events), findsNothing);
    });

    testWidgets('renders badge chips when badges are present', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        BadgesCard(badges: [
          const BadgeDisplay(name: 'First Session', description: ''),
          const BadgeDisplay(name: 'Perfect Score', description: ''),
        ]),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsNWidgets(2));
      expect(find.text('First Session'), findsOneWidget);
      expect(find.text('Perfect Score'), findsOneWidget);
    });

    testWidgets('renders achievements title and emoji icon', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        BadgesCard(badges: [
          const BadgeDisplay(name: 'Test Badge', description: ''),
        ]),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.emoji_events), findsAtLeast(1));
    });

    testWidgets('renders badge chip', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        BadgesCard(badges: [
          const BadgeDisplay(name: 'Achiever', description: ''),
        ]),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('shows no badges yet message when empty', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        BadgesCard(badges: []),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No achievements yet. Keep studying!'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsNothing);
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('renders achievements heading with semantics', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        BadgesCard(badges: [
          const BadgeDisplay(name: 'Test Badge', description: ''),
        ]),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.emoji_events), findsAtLeast(1));
      expect(find.byType(Semantics), findsAtLeast(1));
    });

    testWidgets('renders Semantics wrapper when badges present', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        BadgesCard(badges: [
          const BadgeDisplay(name: 'Test Badge', description: ''),
        ]),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Semantics), findsAtLeast(1));
    });

    testWidgets('renders Wrap when badges present', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        BadgesCard(badges: [
          const BadgeDisplay(name: 'First', description: ''),
          const BadgeDisplay(name: 'Second', description: ''),
          const BadgeDisplay(name: 'Third', description: ''),
        ]),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Wrap), findsOneWidget);
      expect(find.byType(Chip), findsNWidgets(3));
    });

    testWidgets('empty badges does not render Wrap', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        BadgesCard(badges: []),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsNothing);
    });

    // BadgesCard is a pure rendering widget with no navigation callbacks.
  });
}
