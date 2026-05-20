import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
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

    testWidgets('renders export icon button', (tester) async {
      await tester.pumpWidget(_buildTestApp(const DashboardHeader()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
    });

    testWidgets('renders backup icon button', (tester) async {
      await tester.pumpWidget(_buildTestApp(const DashboardHeader()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.backup_outlined), findsOneWidget);
    });

    testWidgets('renders help icon button', (tester) async {
      await tester.pumpWidget(_buildTestApp(const DashboardHeader()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('onExportTap callback is called when export button tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_buildTestApp(
        DashboardHeader(onExportTap: () => tapped = true),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.file_download_outlined));
      expect(tapped, isTrue);
    });

    testWidgets('renders all icon buttons as tappable', (tester) async {
      await tester.pumpWidget(_buildTestApp(const DashboardHeader()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
      expect(find.byIcon(Icons.backup_outlined), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });
  });
}
