import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_feedback_widget.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('PracticeFeedbackWidget', () {
    testWidgets('shows correct feedback', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PracticeFeedbackWidget(isCorrect: true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Correct!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows incorrect feedback', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PracticeFeedbackWidget(isCorrect: false),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows explanation when provided', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PracticeFeedbackWidget(
          isCorrect: true,
          explanation: 'Paris is the capital of France.',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Paris is the capital of France.'), findsOneWidget);
    });

    testWidgets('handles empty explanation', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PracticeFeedbackWidget(
          isCorrect: true,
          explanation: '',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Correct!'), findsOneWidget);
    });

    testWidgets('handles null explanation', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PracticeFeedbackWidget(isCorrect: true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Correct!'), findsOneWidget);
    });
  });
}
