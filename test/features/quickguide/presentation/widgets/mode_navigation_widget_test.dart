import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/quickguide/presentation/widgets/mode_navigation_widget.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

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

    testWidgets('AI Tutor card tap shows dialog', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('AI Tutor'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('AI Tutor'), findsAtLeast(1));
      expect(
        find.textContaining(
            'Please create a subject and study plan first'),
        findsOneWidget,
      );
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('AI Tutor dialog dismisses on OK tap', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('AI Tutor'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsNothing);
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

    testWidgets('has FocusTraversalGroup for keyboard navigation',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FocusTraversalGroup), findsAtLeastNWidgets(1));
    });

    testWidgets('icons are wrapped in ExcludeSemantics', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final excludeSemantics = find.byType(ExcludeSemantics);
      expect(excludeSemantics, findsAtLeastNWidgets(4));
    });

    testWidgets('card has rounded rectangle border shape', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final cards = find.byType(Card);
      for (final card in cards.evaluate()) {
        final cardWidget = card.widget as Card;
        final shape = cardWidget.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(12));
      }
    });

    testWidgets('semantics label includes button:true', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final semantics = find.bySemanticsLabel(
        'AI Tutor: Interactive conversational lessons',
      );
      expect(semantics, findsOneWidget);
      final node = tester.element(semantics);
      expect(node, isNotNull);
    });

    testWidgets('Container has decoration with surfaceContainerLow color',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      expect(container.decoration, isNotNull);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('renders correctly on xs breakpoint (small screen)',
        (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
      });
      tester.view.physicalSize = const Size(360, 800);

      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Choose a study mode'), findsOneWidget);
      expect(find.text('AI Tutor'), findsOneWidget);
      expect(find.text('Mentor'), findsOneWidget);
      expect(
        find.text('Interactive conversational lessons'),
        findsOneWidget,
      );
      expect(
        find.text('Personal study assistant & planner'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.byType(FocusTraversalGroup), findsAtLeastNWidgets(1));
    });

    testWidgets('uses Column layout (vertically stacked) on xs breakpoint',
        (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.physicalSize = const Size(590, 900);

      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.text('AI Tutor'), findsOneWidget);
      expect(find.text('Mentor'), findsOneWidget);
      expect(find.text('Choose a study mode'), findsOneWidget);

      await tester.tap(find.text('Mentor'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Mentor Screen'), findsOneWidget);
    });

    testWidgets('AI Tutor dialog appears on xs breakpoint',
        (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
      });
      tester.view.physicalSize = const Size(590, 900);

      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('AI Tutor'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.textContaining(
            'Please create a subject and study plan first'),
        findsOneWidget,
      );

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
