import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/quickguide/presentation/quick_guide_screen.dart';

void main() {
  Future<void> pumpQuickGuide(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: QuickGuideScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('QuickGuideScreen', () {
    testWidgets('renders initial UI and welcome message', (WidgetTester tester) async {
      await pumpQuickGuide(tester);

      expect(find.text('Quick Guide'), findsOneWidget);
      expect(find.text('Ask anything...'), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(
        find.text('Hello! I\'m StudyKing\'s Quick Guide. Ask me anything about your studies!'),
        findsOneWidget,
      );
    });

    testWidgets('does not send empty or whitespace-only messages', (WidgetTester tester) async {
      await pumpQuickGuide(tester);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(find.text('StudyKing is thinking...'), findsNothing);
      expect(
        find.text('Hello! I\'m StudyKing\'s Quick Guide. Ask me anything about your studies!'),
        findsOneWidget,
      );
    });

    testWidgets('sends message and returns explain-specific response', (WidgetTester tester) async {
      await pumpQuickGuide(tester);

      await tester.enterText(find.byType(TextField), 'Can you explain fractions?');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(find.text('Can you explain fractions?'), findsOneWidget);
      expect(find.text('StudyKing is thinking...'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('StudyKing is thinking...'), findsNothing);
      expect(
        find.text('Sure! I can help explain concepts. What topic would you like me to explain?'),
        findsOneWidget,
      );
      expect(find.text('Ask anything...'), findsOneWidget);
    });

    testWidgets('returns question-specific response when prompt contains question', (
      WidgetTester tester,
    ) async {
      await pumpQuickGuide(tester);

      await tester.enterText(find.byType(TextField), 'I have a QUESTION about biology');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('I have a QUESTION about biology'), findsOneWidget);
      expect(
        find.text('I can help with questions! Ask away and I\'ll do my best.'),
        findsOneWidget,
      );
    });

    testWidgets('returns fallback response for other prompts', (WidgetTester tester) async {
      await pumpQuickGuide(tester);

      await tester.enterText(find.byType(TextField), 'Tell me something');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Tell me something'), findsOneWidget);
      expect(
        find.text('That\'s an interesting question! Let me help you understand it better.'),
        findsOneWidget,
      );
    });

    testWidgets('submits from keyboard action', (WidgetTester tester) async {
      await pumpQuickGuide(tester);

      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Please explain gravity');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.text('Please explain gravity'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(
        find.text('Sure! I can help explain concepts. What topic would you like me to explain?'),
        findsOneWidget,
      );
    });
  });
}
