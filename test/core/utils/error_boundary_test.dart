import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/error_boundary.dart';

void main() {
  group('ErrorBoundary', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ErrorBoundary(child: Text('Hello')),
        ),
      ));

      expect(find.text('Hello'), findsOneWidget);
    });
  });

  group('AppErrorWidgetBuilder', () {
    testWidgets('build returns a widget', (tester) async {
      final details = FlutterErrorDetails(
        exception: Exception('test error'),
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppErrorWidgetBuilder.build(details),
        ),
      ));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders error icon, title, message, and retry button', (
      tester,
    ) async {
      final details = FlutterErrorDetails(
        exception: Exception('test error'),
      );
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: AppErrorWidgetBuilder.build(details),
        ),
      ));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.textContaining('Error:'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('tap retry triggers rebuild', (tester) async {
      final details = FlutterErrorDetails(
        exception: Exception('test error'),
      );
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: AppErrorWidgetBuilder.build(details),
        ),
      ));

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('handles null AppLocalizations gracefully', (tester) async {
      final details = FlutterErrorDetails(
        exception: Exception('test error'),
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppErrorWidgetBuilder.build(details),
        ),
      ));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('An unexpected error occurred.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
