import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/widgets/not_found_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../helpers/navigator_observer_helper.dart';

void main() {
  testWidgets('NotFoundScreen displays page not found message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: onGenerateRoute,
        home: const NotFoundScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.search_off), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('NotFoundScreen shows custom message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: onGenerateRoute,
        home: const NotFoundScreen(message: 'Custom error'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Custom error'), findsOneWidget);
  });

  testWidgets('NotFoundScreen dashboard button navigates to /dashboard', (tester) async {
    final observer = TestNavigatorObserver();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.dashboard) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('Dashboard')),
            );
          }
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Unknown')),
          );
        },
        navigatorObservers: [observer],
        home: const NotFoundScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.byType(FilledButton);
    expect(button, findsOneWidget);

    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(observer.pushedRoutes, isNotEmpty);
    expect(
      observer.pushedRoutes.last.settings.name,
      equals(AppRoutes.dashboard),
    );
  });
}
