import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('DashboardHeader', () {
    testWidgets('renders dashboard icon', (tester) async {
      await tester.pumpWidget(_buildTestApp(const DashboardHeader()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.dashboard), findsOneWidget);
    });

    testWidgets('renders study dashboard title text', (tester) async {
      await tester.pumpWidget(_buildTestApp(const DashboardHeader()));
      await tester.pumpAndSettle();

      expect(find.text('Study Dashboard'), findsOneWidget);
    });
  });
}
