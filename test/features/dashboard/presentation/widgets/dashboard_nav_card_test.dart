import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/presentation/widgets/dashboard_nav_card.dart';

void main() {
  group('DashboardNavCard', () {
    Widget buildApp(DashboardNavCard card) {
      return MaterialApp(
        home: Scaffold(body: card),
      );
    }

    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(buildApp(
        DashboardNavCard(
          icon: Icons.school,
          iconColor: Colors.blue,
          title: 'Study',
          subtitle: 'Track your progress',
          onTap: () {},
        ),
      ));

      expect(find.text('Study'), findsOneWidget);
      expect(find.text('Track your progress'), findsOneWidget);
    });

    testWidgets('renders the provided icon', (tester) async {
      await tester.pumpWidget(buildApp(
        DashboardNavCard(
          icon: Icons.school,
          iconColor: Colors.blue,
          title: 'Subjects',
          subtitle: 'Manage subjects',
          onTap: () {},
        ),
      ));

      expect(find.byIcon(Icons.school), findsOneWidget);
    });

    testWidgets('renders chevron right icon', (tester) async {
      await tester.pumpWidget(buildApp(
        DashboardNavCard(
          icon: Icons.book,
          iconColor: Colors.green,
          title: 'Library',
          subtitle: 'Browse resources',
          onTap: () {},
        ),
      ));

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('triggers onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildApp(
        DashboardNavCard(
          icon: Icons.settings,
          iconColor: Colors.grey,
          title: 'Settings',
          subtitle: 'Configure app',
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.text('Settings'));
      expect(tapped, isTrue);
    });

    testWidgets('is tappable via Semantics', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(buildApp(
        DashboardNavCard(
          icon: Icons.home,
          iconColor: Colors.red,
          title: 'Home',
          subtitle: 'Dashboard',
          onTap: () => tapCount++,
        ),
      ));

      // Tap the card via its Semantics label
      await tester.tap(find.bySemanticsLabel('Home'));
      expect(tapCount, 1);
    });
  });
}
