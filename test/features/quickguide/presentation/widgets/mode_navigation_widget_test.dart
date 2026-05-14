import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/quickguide/presentation/widgets/mode_navigation_widget.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _TestNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
  }
}

Widget _buildTestApp({
  NavigatorObserver? observer,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    navigatorObservers: observer != null ? [observer] : [],
    routes: {
      '/tutor': (_) => const Scaffold(
            body: Center(child: Text('Tutor Screen')),
          ),
      '/mentor': (_) => const Scaffold(
            body: Center(child: Text('Mentor Screen')),
          ),
    },
    home: const Scaffold(
      body: SingleChildScrollView(
        child: ModeNavigationWidget(),
      ),
    ),
  );
}

void main() {
  group('ModeNavigationWidget', () {
    testWidgets('renders title and both mode cards', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Choose a study mode'), findsOneWidget);
      expect(find.text('AI Tutor'), findsOneWidget);
      expect(find.text('Mentor'), findsOneWidget);
    });

    testWidgets('renders subtitle text for both cards', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Interactive conversational lessons'),
        findsOneWidget,
      );
      expect(
        find.text('Personal study assistant & planner'),
        findsOneWidget,
      );
    });

    testWidgets('renders correct icons for both cards', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('AI Tutor card tap pushes /tutor route', (tester) async {
      final observer = _TestNavigatorObserver();
      await tester.pumpWidget(_buildTestApp(observer: observer));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('AI Tutor'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(observer.pushedRoutes.length, 2);
      final routeName = observer.pushedRoutes.last.settings.name;
      expect(routeName, '/tutor');
    });

    testWidgets('Mentor card tap navigates to /mentor route', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Mentor'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Mentor Screen'), findsOneWidget);
    });

    testWidgets('has correct semantics for AI Tutor card', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.bySemanticsLabel(
          'AI Tutor: Interactive conversational lessons',
        ),
        findsOneWidget,
      );
    });

    testWidgets('has correct semantics for Mentor card', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.bySemanticsLabel(
          'Mentor: Personal study assistant & planner',
        ),
        findsOneWidget,
      );
    });

    testWidgets('cards have InkWell for tap interaction', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(InkWell), findsAtLeastNWidgets(2));
    });

    testWidgets('cards have Card widget with elevation 0', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final cards = find.byType(Card);
      expect(cards, findsAtLeastNWidgets(2));
      for (final card in cards.evaluate()) {
        final cardWidget = card.widget as Card;
        expect(cardWidget.elevation, 0.0);
      }
    });
  });
}
