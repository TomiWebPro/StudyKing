import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/widgets/loading_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

void main() {
  group('LoadingScreen', () {
    testWidgets('renders CircularProgressIndicator with default strokeWidth', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: LoadingScreen(),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders message when provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: LoadingScreen(message: 'Please wait...'),
        ),
      ));

      expect(find.text('Please wait...'), findsOneWidget);
    });

    testWidgets('uses semantics label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: LoadingScreen(semanticsLabel: 'Content is loading'),
        ),
      ));

      expect(
        find.bySemanticsLabel('Content is loading'),
        findsOneWidget,
      );
    });

    testWidgets('uses localized loading text as default semantics label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: LoadingScreen(),
        ),
      ));

      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(find.bySemanticsLabel(l10n.loading), findsOneWidget);
    });

    testWidgets('accepts custom strokeWidth and color', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: LoadingScreen(strokeWidth: 5, color: Colors.red),
        ),
      ));

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.strokeWidth, 5);
      expect(indicator.color, Colors.red);
    });
  });
}
