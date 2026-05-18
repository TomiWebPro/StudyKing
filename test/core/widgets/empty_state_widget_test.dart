import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/widgets/empty_state_widget.dart';

void main() {
  group('EmptyStateWidget', () {
    testWidgets('renders icon and title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.book,
              title: 'No items found',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.book), findsOneWidget);
      expect(find.text('No items found'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.info,
              title: 'Empty',
              subtitle: 'Add some content to get started',
            ),
          ),
        ),
      );

      expect(find.text('Empty'), findsOneWidget);
      expect(find.text('Add some content to get started'), findsOneWidget);
    });

    testWidgets('renders action button when label and callback provided', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.add,
              title: 'No data',
              actionLabel: 'Add Item',
              onAction: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Add Item'), findsOneWidget);
      await tester.tap(find.text('Add Item'));
      expect(tapped, isTrue);
    });

    testWidgets('does not render action button when onAction is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.search,
              title: 'No results',
              actionLabel: 'Retry',
            ),
          ),
        ),
      );

      expect(find.text('No results'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });
  });
}
