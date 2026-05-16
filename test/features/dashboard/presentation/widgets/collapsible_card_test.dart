import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/presentation/widgets/collapsible_card.dart';
import 'package:studyking/features/dashboard/providers/dashboard_data_providers.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return ProviderScope(
    overrides: [
      dashboardLayoutPreferencesProvider.overrideWith(
        (ref) => DashboardLayoutNotifier(),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('CollapsibleCard', () {
    testWidgets('renders title and body when no asyncValue', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        CollapsibleCard(
          cardId: 'test',
          title: const Text('Test Title'),
          body: const Text('Test Body'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Body'), findsOneWidget);
    });

    testWidgets('shows body when asyncValue is data', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        CollapsibleCard(
          cardId: 'test',
          title: const Text('Title'),
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
        CollapsibleCard(
          cardId: 'test',
          title: const Text('Title'),
          body: const Text('Body'),
          asyncValue: const AsyncValue<dynamic>.loading(),
        ),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows custom loading skeleton', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        CollapsibleCard(
          cardId: 'test',
          title: const Text('Title'),
          body: const Text('Body'),
          asyncValue: const AsyncValue<dynamic>.loading(),
          loadingSkeleton: const SizedBox(
            height: 50,
            child: Center(child: Text('Loading...')),
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('shows error widget when asyncValue has error', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        CollapsibleCard(
          cardId: 'test',
          title: const Text('Title'),
          body: const Text('Body'),
          asyncValue: AsyncValue<dynamic>.error('error', StackTrace.empty),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry is provided', (tester) async {
      bool retried = false;
      await tester.pumpWidget(_buildTestApp(
        CollapsibleCard(
          cardId: 'test',
          title: const Text('Title'),
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
        CollapsibleCard(
          cardId: 'test',
          title: const Text('Title'),
          body: const Text('Body'),
          asyncValue: AsyncValue<dynamic>.error('error', StackTrace.empty),
          errorWidget: const Text('Custom Error'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Custom Error'), findsOneWidget);
      expect(find.text('Something went wrong'), findsNothing);
    });

    testWidgets('toggles collapse state on tap', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        CollapsibleCard(
          cardId: 'toggle-test',
          title: const Text('Toggle Title'),
          body: const Text('Toggle Body'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Toggle Body'), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);

      await tester.tap(find.text('Toggle Title'));
      await tester.pumpAndSettle();

      expect(find.text('Toggle Body'), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('expand after collapse shows body again', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        CollapsibleCard(
          cardId: 'expand-test',
          title: const Text('Title'),
          body: const Text('Hidden Body'),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Title'));
      await tester.pumpAndSettle();

      expect(find.text('Hidden Body'), findsNothing);

      await tester.tap(find.text('Title'));
      await tester.pumpAndSettle();

      expect(find.text('Hidden Body'), findsOneWidget);
    });

    testWidgets('renders with expand icon when collapsed', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        CollapsibleCard(
          cardId: 'collapsed-card',
          title: const Text('Title'),
          body: const Text('Body'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.expand_less), findsOneWidget);

      await tester.tap(find.text('Title'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('toggle remains tappable after removing headingLevel', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        CollapsibleCard(
          cardId: 'tap-test',
          title: const Text('Toggle Header'),
          body: const Text('Collapsible Body'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Collapsible Body'), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);

      await tester.tap(find.text('Toggle Header'));
      await tester.pumpAndSettle();

      expect(find.text('Collapsible Body'), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });
  });
}
