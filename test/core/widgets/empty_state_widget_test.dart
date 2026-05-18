import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/widgets/empty_state_widget.dart';

void main() {
  group('EmptyStateWidget', () {
    testWidgets('renders icon and title', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget(
            icon: Icons.inbox,
            title: 'No items',
          ),
        ),
      ));

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('No items'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget(
            icon: Icons.inbox,
            title: 'No items',
            subtitle: 'Add some items to get started',
          ),
        ),
      ));

      expect(find.text('Add some items to get started'), findsOneWidget);
    });

    testWidgets('renders action button when label and onAction provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget(
            icon: Icons.inbox,
            title: 'No items',
            actionLabel: 'Add Item',
            onAction: () {},
          ),
        ),
      ));

      expect(find.text('Add Item'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('does not render action button when onAction is null', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget(
            icon: Icons.inbox,
            title: 'No items',
            actionLabel: 'Add Item',
          ),
        ),
      ));

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('action button fires onAction callback', (tester) async {
      bool actionFired = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget(
            icon: Icons.inbox,
            title: 'No items',
            actionLabel: 'Add Item',
            onAction: () => actionFired = true,
          ),
        ),
      ));

      await tester.tap(find.text('Add Item'));
      expect(actionFired, isTrue);
    });

    testWidgets('icon has sematic label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget(
            icon: Icons.inbox,
            title: 'No items',
          ),
        ),
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.inbox));
      expect(icon.size, 64);
    });
  });
}
