import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/ui/widgets/single_answer_widget.dart';

void main() {
  group('SingleAnswerWidget', () {
    testWidgets('renders all options', (tester) async {
      const options = ['Option A', 'Option B', 'Option C', 'Option D'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleAnswerWidget(
              options: options,
              correctAnswer: 'Option A',
              isSubmitted: false,
              isFeedbackVisible: false,
              onAnswerSelected: (_) {},
            ),
          ),
        ),
      );

      for (final option in options) {
        expect(find.text(option), findsOneWidget);
      }
    });

    testWidgets('calls onAnswerSelected when option is tapped and not submitted', (tester) async {
      const options = ['Option A', 'Option B', 'Option C', 'Option D'];
      String? selectedOption;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleAnswerWidget(
              options: options,
              correctAnswer: 'Option A',
              isSubmitted: false,
              isFeedbackVisible: false,
              onAnswerSelected: (option) {
                selectedOption = option;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Option B'));
      await tester.pump();

      expect(selectedOption, 'Option B');
    });

    testWidgets('does not call onAnswerSelected after submission', (tester) async {
      const options = ['Option A', 'Option B', 'Option C', 'Option D'];
      String? selectedOption;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleAnswerWidget(
              options: options,
              correctAnswer: 'Option A',
              selectedAnswer: 'Option A',
              isSubmitted: true,
              isFeedbackVisible: false,
              onAnswerSelected: (option) {
                selectedOption = option;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Option B'));
      await tester.pump();

      expect(selectedOption, isNull);
    });

    testWidgets('shows selected state for selected option', (tester) async {
      const options = ['Option A', 'Option B', 'Option C', 'Option D'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleAnswerWidget(
              options: options,
              correctAnswer: 'Option A',
              selectedAnswer: 'Option B',
              isSubmitted: false,
              isFeedbackVisible: false,
              onAnswerSelected: (_) {},
            ),
          ),
        ),
      );

      final radioIcons = tester.widgetList<Icon>(find.byType(Icon));
      final selectedIcon = radioIcons.firstWhere(
        (icon) => icon.icon == Icons.radio_button_checked,
      );
      expect(selectedIcon, isNotNull);
    });

    testWidgets('shows feedback container when isFeedbackVisible is true and submitted', (tester) async {
      const options = ['Option A', 'Option B', 'Option C', 'Option D'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleAnswerWidget(
              options: options,
              correctAnswer: 'Option A',
              selectedAnswer: 'Option A',
              isSubmitted: true,
              isFeedbackVisible: true,
              onAnswerSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Correct!'), findsOneWidget);
      expect(find.text('Selected right option'), findsOneWidget);
    });

    testWidgets('shows Incorrect feedback when wrong answer selected', (tester) async {
      const options = ['Option A', 'Option B', 'Option C', 'Option D'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleAnswerWidget(
              options: options,
              correctAnswer: 'Option A',
              selectedAnswer: 'Option B',
              isSubmitted: true,
              isFeedbackVisible: true,
              onAnswerSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Incorrect'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('shows visual state for correct answer after submission', (tester) async {
      const options = ['Option A', 'Option B', 'Option C', 'Option D'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleAnswerWidget(
              options: options,
              correctAnswer: 'Option A',
              selectedAnswer: 'Option A',
              isSubmitted: true,
              isFeedbackVisible: true,
              onAnswerSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Correct!'), findsOneWidget);
    });

    testWidgets('shows visual state for wrong selected answer after submission', (tester) async {
      const options = ['Option A', 'Option B', 'Option C', 'Option D'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleAnswerWidget(
              options: options,
              correctAnswer: 'Option A',
              selectedAnswer: 'Option B',
              isSubmitted: true,
              isFeedbackVisible: true,
              onAnswerSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Incorrect'), findsOneWidget);
    });

    testWidgets('does not show feedback when isFeedbackVisible is false', (tester) async {
      const options = ['Option A', 'Option B', 'Option C', 'Option D'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleAnswerWidget(
              options: options,
              correctAnswer: 'Option A',
              selectedAnswer: 'Option B',
              isSubmitted: true,
              isFeedbackVisible: false,
              onAnswerSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Correct!'), findsNothing);
      expect(find.text('Incorrect'), findsNothing);
    });

    testWidgets('works without correctAnswer provided', (tester) async {
      const options = ['Option A', 'Option B', 'Option C', 'Option D'];
      String? selectedOption;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleAnswerWidget(
              options: options,
              isSubmitted: false,
              isFeedbackVisible: false,
              onAnswerSelected: (option) {
                selectedOption = option;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Option A'));
      await tester.pump();

      expect(selectedOption, 'Option A');
    });

    testWidgets('handles single option', (tester) async {
      const options = ['Only Option'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleAnswerWidget(
              options: options,
              correctAnswer: 'Only Option',
              isSubmitted: false,
              isFeedbackVisible: false,
              onAnswerSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Only Option'), findsOneWidget);
    });

    testWidgets('handles empty options list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleAnswerWidget(
              options: const [],
              correctAnswer: 'A',
              isSubmitted: false,
              isFeedbackVisible: false,
              onAnswerSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('selection works after deselecting and selecting another option', (tester) async {
      const options = ['A', 'B', 'C'];
      String? lastSelected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleAnswerWidget(
              options: options,
              selectedAnswer: 'A',
              isSubmitted: false,
              isFeedbackVisible: false,
              onAnswerSelected: (option) {
                lastSelected = option;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('B'));
      await tester.pump();

      expect(lastSelected, 'B');

      await tester.tap(find.text('C'));
      await tester.pump();

      expect(lastSelected, 'C');
    });
  });
}