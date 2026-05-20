import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/widgets/splash_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildApp({String? message}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: SplashScreen(message: message),
  );
}

void main() {
  testWidgets('SplashScreen renders app name and icon', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();

    expect(find.byIcon(Icons.school), findsOneWidget);
    expect(find.text('StudyKing'), findsOneWidget);
    expect(find.text('AI-Native Learning Companion'), findsOneWidget);
  });

  testWidgets('SplashScreen shows loading indicator', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('SplashScreen shows optional message', (tester) async {
    await tester.pumpWidget(_buildApp(message: 'Initializing...'));
    await tester.pump();

    expect(find.text('Initializing...'), findsOneWidget);
  });

  testWidgets('SplashScreen hides message when not provided', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();

    expect(find.text('Initializing...'), findsNothing);
  });
}
