import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/widgets/loading_indicator.dart';

void main() {
  group('LoadingIndicator', () {
    testWidgets('renders CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LoadingIndicator(),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders message when provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LoadingIndicator(message: 'Loading...'),
        ),
      ));

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('does not render text when message is null', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LoadingIndicator(),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Only the CircularProgressIndicator is rendered, no Text widget
      expect(find.byType(Text), findsNothing);
    });
  });
}
