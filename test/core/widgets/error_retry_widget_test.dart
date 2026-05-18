import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/widgets/error_retry_widget.dart';

void main() {
  group('ErrorRetryWidget', () {
    testWidgets('renders error icon and message', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ErrorRetryWidget(message: 'Something went wrong'),
        ),
      ));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('renders retry button with default label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ErrorRetryWidget(
            message: 'Something went wrong',
            onRetry: () {},
          ),
        ),
      ));

      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('renders retry button with custom label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ErrorRetryWidget(
            message: 'Something went wrong',
            retryLabel: 'Try Again',
            onRetry: () {},
          ),
        ),
      ));

      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('does not render retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ErrorRetryWidget(message: 'Something went wrong'),
        ),
      ));

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('retry button fires onRetry callback', (tester) async {
      bool retried = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ErrorRetryWidget(
            message: 'Something went wrong',
            onRetry: () => retried = true,
          ),
        ),
      ));

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });
}
