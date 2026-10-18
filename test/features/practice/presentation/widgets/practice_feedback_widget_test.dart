import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_feedback_widget.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

void main() {
  group('PracticeFeedbackWidget', () {
    testWidgets('renders correct feedback with explanation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: PracticeFeedbackWidget(
              isCorrect: true,
              explanation: 'The capital of France is Paris.',
            ),
          ),
        ),
      );

      expect(find.text('Correct!'), findsOneWidget);
      expect(find.text('The capital of France is Paris.'), findsOneWidget);
    });

    testWidgets('renders incorrect feedback without explanation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: PracticeFeedbackWidget(
              isCorrect: false,
              explanation: null,
            ),
          ),
        ),
      );

      expect(find.text('Incorrect'), findsOneWidget);
    });

    testWidgets('renders correct feedback without explanation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: PracticeFeedbackWidget(
              isCorrect: true,
              explanation: null,
            ),
          ),
        ),
      );

      expect(find.text('Correct!'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
    });
  });
}
