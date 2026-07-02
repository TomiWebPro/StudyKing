import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/presentation/widgets/collapsible_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('DashboardCard', () {
    testWidgets('renders body when no asyncValue', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const DashboardCard(
          body: Text('Test Body'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Test Body'), findsOneWidget);
    });

    testWidgets('shows body when asyncValue is data', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        DashboardCard(
          body: const Text('Data Body'),
          asyncValue: const AsyncValue.data('loaded'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Data Body'), findsOneWidget);
    });

    testWidgets('shows loading indicator when asyncValue is loading',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const DashboardCard(
          body: Text('Body'),
          asyncValue: AsyncValue<dynamic>.loading(),
        ),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Body should NOT be visible while loading
      expect(find.text('Body'), findsNothing);
    });

    testWidgets('shows custom loading skeleton', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const DashboardCard(
          body: Text('Body'),
          asyncValue: AsyncValue<dynamic>.loading(),
          loadingSkeleton: SizedBox(
            height: 50,
            child: Center(child: Text('Loading...')),
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('Loading...'), findsOneWidget);
      expect(find.text('Body'), findsNothing);
    });

    testWidgets('shows error widget when asyncValue has error', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        DashboardCard(
          body: const Text('Body'),
          asyncValue: AsyncValue<dynamic>.error('error', StackTrace.empty),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      // Body should NOT be visible on error
      expect(find.text('Body'), findsNothing);
    });

    testWidgets('shows retry button when onRetry is provided', (tester) async {
      bool retried = false;
      await tester.pumpWidget(_buildTestApp(
        DashboardCard(
          body: const Text('Body'),
          asyncValue: AsyncValue<dynamic>.error('error', StackTrace.empty),
          onRetry: () => retried = true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('shows custom error widget', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const DashboardCard(
          body: Text('Body'),
          asyncValue: AsyncValue<dynamic>.error('error', StackTrace.empty),
          errorWidget: Text('Custom Error'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Custom Error'), findsOneWidget);
      expect(find.text('Something went wrong'), findsNothing);
      // Body should NOT be visible when custom error is shown
      expect(find.text('Body'), findsNothing);
    });

    testWidgets('renders inside a Card widget', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const DashboardCard(
          body: Text('Card Content'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Card Content'), findsOneWidget);
    });
  });
}
