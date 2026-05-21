import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/quickguide/presentation/widgets/help_dialog.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
}

void main() {
  group('QuickGuide + Teaching integration', () {
    testWidgets('QuickGuideHelpDialog renders in teaching context', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showQuickGuideHelpDialog(context),
            child: const Text('Show Help'),
          ),
        ),
      ));

      await tester.tap(find.text('Show Help'));
      await tester.pumpAndSettle();

      expect(find.byType(QuickGuideHelpDialog), findsOneWidget);
      expect(find.text('How to Use StudyKing Guide'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
    });

    testWidgets('QuickGuideHelpDialog content is accessible', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showQuickGuideHelpDialog(context),
            child: const Text('Show Help'),
          ),
        ),
      ));

      await tester.tap(find.text('Show Help'));
      await tester.pumpAndSettle();

      final dialog = tester.widget<QuickGuideHelpDialog>(find.byType(QuickGuideHelpDialog));
      expect(dialog, isA<QuickGuideHelpDialog>());
    });

    testWidgets('QuickGuideHelpDialog can be dismissed', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showQuickGuideHelpDialog(context),
            child: const Text('Show Help'),
          ),
        ),
      ));

      await tester.tap(find.text('Show Help'));
      await tester.pumpAndSettle();
      expect(find.byType(QuickGuideHelpDialog), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.byType(QuickGuideHelpDialog), findsNothing);
    });
  });
}
