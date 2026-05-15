import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/presentation/widgets/badges_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
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
  });
}
