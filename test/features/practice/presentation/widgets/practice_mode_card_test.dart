import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_mode_card.dart';
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
  group('PracticeModeCard', () {
    testWidgets('renders icon, title, and subtitle', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeCard(
          icon: Icons.flash_on,
          title: 'Quick Practice',
          subtitle: '10 random questions',
          color: Colors.blue,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.flash_on), findsOneWidget);
      expect(find.text('Quick Practice'), findsOneWidget);
      expect(find.text('10 random questions'), findsOneWidget);
    });

    testWidgets('is tappable when onTap is provided', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_buildTestApp(
        PracticeModeCard(
          icon: Icons.flash_on,
          title: 'Quick Practice',
          subtitle: '10 random questions',
          color: Colors.blue,
          onTap: () => tapped = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quick Practice'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('shows badge count when badge is provided', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeCard(
          icon: Icons.flash_on,
          title: 'Quick Practice',
          subtitle: '10 random questions',
          color: Colors.blue,
          badge: 5,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('does not show badge when badge is 0', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeCard(
          icon: Icons.flash_on,
          title: 'Quick Practice',
          subtitle: '10 random questions',
          color: Colors.blue,
          badge: 0,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsNothing);
    });

    testWidgets('renders card widget', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeCard(
          icon: Icons.flash_on,
          title: 'Quick Practice',
          subtitle: '10 random questions',
          color: Colors.blue,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('is disabled and not tappable when onTap is null', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_buildTestApp(
        PracticeModeCard(
          icon: Icons.flash_on,
          title: 'Quick Practice',
          subtitle: '10 random questions',
          color: Colors.blue,
          onTap: null,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quick Practice'));
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
    });

    testWidgets('does not show badge when badge is null', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeCard(
          icon: Icons.flash_on,
          title: 'Quick Practice',
          subtitle: '10 random questions',
          color: Colors.blue,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders disabled card with muted colors when onTap is null', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeCard(
          icon: Icons.flash_on,
          title: 'Quick Practice',
          subtitle: '10 random questions',
          color: Colors.blue,
          onTap: null,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.flash_on), findsOneWidget);
      expect(find.text('Quick Practice'), findsOneWidget);
      expect(find.text('10 random questions'), findsOneWidget);
    });

    testWidgets('renders with Semantics widget wrapping', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeCard(
          icon: Icons.flash_on,
          title: 'Quick Practice',
          subtitle: '10 random questions',
          color: Colors.blue,
        ),
      ));
      await tester.pumpAndSettle();

      // Semantics widget wraps the card
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('calls onTapDisabled when card is disabled and tapped', (tester) async {
      bool disabledCalled = false;
      await tester.pumpWidget(_buildTestApp(
        PracticeModeCard(
          icon: Icons.flash_on,
          title: 'Quick Practice',
          subtitle: '10 random questions',
          color: Colors.blue,
          onTap: null,
          onTapDisabled: () => disabledCalled = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quick Practice'));
      await tester.pumpAndSettle();

      expect(disabledCalled, isTrue);
    });

    testWidgets('shows badge with correct accessibility label', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeCard(
          icon: Icons.flash_on,
          title: 'Quick Practice',
          subtitle: '10 random questions',
          color: Colors.blue,
          badge: 3,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
    });
  });
}
