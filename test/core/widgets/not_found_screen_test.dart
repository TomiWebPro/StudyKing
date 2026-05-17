import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/widgets/not_found_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

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

  testWidgets('NotFoundScreen has go to dashboard button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: onGenerateRoute,
        home: const NotFoundScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.byType(FilledButton);
    expect(button, findsOneWidget);
  });
}
