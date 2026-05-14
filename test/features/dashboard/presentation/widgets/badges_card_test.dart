import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    testWidgets('renders nothing when badges list is empty', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        BadgesCard(badges: []),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('renders badge chips when badges are present', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        BadgesCard(badges: [
          {'name': 'First Session'},
          {'name': 'Perfect Score'},
        ]),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(Chip), findsNWidgets(2));
      expect(find.text('First Session'), findsOneWidget);
      expect(find.text('Perfect Score'), findsOneWidget);
    });

    testWidgets('renders achievements title and emoji icon', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        BadgesCard(badges: [
          {'name': 'Test Badge'},
        ]),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.emoji_events), findsAtLeast(1));
    });

    testWidgets('handles badge with null name gracefully', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        BadgesCard(badges: [
          {'name': null},
        ]),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(Chip), findsOneWidget);
    });
  });
}
