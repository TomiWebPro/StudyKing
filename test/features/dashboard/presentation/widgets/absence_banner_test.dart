import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/dashboard/presentation/widgets/absence_banner.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../../helpers/navigator_observer_helper.dart';

Widget _buildTestApp({
  required int daysSinceLastActivity,
  NavigatorObserver? observer,
  RouteFactory? onGenerateRoute,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    navigatorObservers: observer != null ? [observer] : [],
    onGenerateRoute: onGenerateRoute,
    home: Scaffold(
      body: AbsenceBanner(daysSinceLastActivity: daysSinceLastActivity),
    ),
  );
}

void main() {
  group('AbsenceBanner', () {
    testWidgets('renders absence detected title', (tester) async {
      await tester.pumpWidget(_buildTestApp(daysSinceLastActivity: 3));
      await tester.pumpAndSettle();

      expect(find.text('Absence Detected'), findsOneWidget);
    });

    testWidgets('shows study planner button', (tester) async {
      await tester.pumpWidget(_buildTestApp(daysSinceLastActivity: 1));
      await tester.pumpAndSettle();

      expect(find.text('Study Planner'), findsOneWidget);
    });

    testWidgets('shows info icon for short absence', (tester) async {
      await tester.pumpWidget(_buildTestApp(daysSinceLastActivity: 3));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('shows warning icon for long absence', (tester) async {
      await tester.pumpWidget(_buildTestApp(daysSinceLastActivity: 7));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('warning icon for 14+ days absence', (tester) async {
      await tester.pumpWidget(_buildTestApp(daysSinceLastActivity: 14));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('shows days message for 3 days', (tester) async {
      await tester.pumpWidget(_buildTestApp(daysSinceLastActivity: 3));
      await tester.pumpAndSettle();

      expect(find.textContaining('3'), findsOneWidget);
    });

    testWidgets('navigates to planner on button tap', (tester) async {
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(_buildTestApp(
        daysSinceLastActivity: 3,
        observer: observer,
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.planner) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('Planner Page')),
            );
          }
          return null;
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Study Planner'));
      await tester.pumpAndSettle();

      expect(observer.pushedRoutes, isNotEmpty);
      expect(
        observer.pushedRoutes.last.settings.name,
        equals(AppRoutes.planner),
      );
    });
  });
}
