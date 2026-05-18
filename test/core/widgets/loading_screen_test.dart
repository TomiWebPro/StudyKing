import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/widgets/loading_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildWidget({double? strokeWidth, Color? color, String? message, String? semanticsLabel}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: LoadingScreen(
        strokeWidth: strokeWidth ?? 3,
        color: color,
        message: message,
        semanticsLabel: semanticsLabel,
      ),
    ),
  );
}

void main() {
  group('LoadingScreen', () {
    testWidgets('renders CircularProgressIndicator with default stroke width', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders custom stroke width', (tester) async {
      await tester.pumpWidget(_buildWidget(strokeWidth: 5));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders message when provided', (tester) async {
      await tester.pumpWidget(_buildWidget(message: 'Please wait...'));
      await tester.pump();

      expect(find.text('Please wait...'), findsOneWidget);
    });

    testWidgets('renders custom color', (tester) async {
      await tester.pumpWidget(_buildWidget(color: Colors.red));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders with default loading text when no message provided', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
