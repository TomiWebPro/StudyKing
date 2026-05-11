import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/ui/widgets/single_answer_widget.dart';

void main() {
  group('SingleAnswerWidget', () {
    const testOptions = ['Option A', 'Option B', 'Option C', 'Option D'];

    Widget buildWidget({
      List<String> options = testOptions,
      String? correctAnswer,
      String? selectedAnswer,
      bool isSubmitted = false,
      bool isFeedbackVisible = true,
      ValueChanged<String?>? onAnswerSelected,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleAnswerWidget(
            options: options,
            correctAnswer: correctAnswer,
            selectedAnswer: selectedAnswer,
            isSubmitted: isSubmitted,
            isFeedbackVisible: isFeedbackVisible,
            onAnswerSelected: onAnswerSelected ?? (_) {},
          ),
        ),
      );
    }

    testWidgets('renders all options', (tester) async {
      await tester.pumpWidget(buildWidget());

      for (final option in testOptions) {
        expect(find.text(option), findsOneWidget);
      }
    });

    testWidgets('renders radio buttons for each option', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(4));
    });

    testWidgets('tapping option calls onAnswerSelected with option text', (tester) async {
      String? selectedOption;
      await tester.pumpWidget(buildWidget(
        onAnswerSelected: (option) => selectedOption = option,
      ));

      await tester.tap(find.text('Option B'));
      await tester.pump();

      expect(selectedOption, 'Option B');
    });

    testWidgets('does not call onAnswerSelected when isSubmitted is true', (tester) async {
      String? selectedOption;
      await tester.pumpWidget(buildWidget(
        isSubmitted: true,
        onAnswerSelected: (option) => selectedOption = option,
      ));

      await tester.tap(find.text('Option C'));
      await tester.pump();

      expect(selectedOption, isNull);
    });

    testWidgets('shows radio button checked for selected answer', (tester) async {
      await tester.pumpWidget(buildWidget(
        selectedAnswer: 'Option B',
      ));

      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(3));
    });

    testWidgets('renders correct answer indicator when submitted with correct answer', (tester) async {
      await tester.pumpWidget(buildWidget(
        correctAnswer: 'Option A',
        selectedAnswer: 'Option A',
        isSubmitted: true,
        isFeedbackVisible: true,
      ));

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Correct!'), findsOneWidget);
    });

    testWidgets('renders incorrect answer indicator when submitted with wrong answer', (tester) async {
      await tester.pumpWidget(buildWidget(
        correctAnswer: 'Option A',
        selectedAnswer: 'Option B',
        isSubmitted: true,
        isFeedbackVisible: true,
      ));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Incorrect'), findsOneWidget);
    });

    testWidgets('does not show feedback when isFeedbackVisible is false', (tester) async {
      await tester.pumpWidget(buildWidget(
        correctAnswer: 'Option A',
        selectedAnswer: 'Option B',
        isSubmitted: true,
        isFeedbackVisible: false,
      ));

      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('shows correct answer highlighted when submitted and correct', (tester) async {
      await tester.pumpWidget(buildWidget(
        correctAnswer: 'Option C',
        selectedAnswer: 'Option C',
        isSubmitted: true,
      ));

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows selected wrong answer highlighted when submitted', (tester) async {
      await tester.pumpWidget(buildWidget(
        correctAnswer: 'Option A',
        selectedAnswer: 'Option B',
        isSubmitted: true,
      ));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('handles empty options list', (tester) async {
      await tester.pumpWidget(buildWidget(options: []));

      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('handles single option', (tester) async {
      await tester.pumpWidget(buildWidget(options: ['Only Option']));

      expect(find.text('Only Option'), findsOneWidget);
    });

    testWidgets('renders without correct answer', (tester) async {
      await tester.pumpWidget(buildWidget(correctAnswer: null));

      expect(find.text('Option A'), findsOneWidget);
    });

    testWidgets('handles option text overflow', (tester) async {
      const longOption = 'This is a very long option text that should be handled properly without overflow issues';
      await tester.pumpWidget(buildWidget(options: [longOption]));

      final textWidget = tester.widget<Text>(find.text(longOption));
      expect(textWidget.softWrap, isTrue);
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(textWidget.maxLines, 3);
    });

    testWidgets('uses InkWell for touch feedback', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byType(InkWell), findsNWidgets(4));
    });

    testWidgets('applies border style correctly', (tester) async {
      await tester.pumpWidget(buildWidget(
        selectedAnswer: 'Option A',
      ));

      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(SingleAnswerWidget),
          matching: find.byType(Container),
        ),
      ).toList();

      expect(containers, isNotEmpty);
    });

    testWidgets('handles rapid taps', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(buildWidget(
        onAnswerSelected: (_) => tapCount++,
      ));

      await tester.tap(find.text('Option A'));
      await tester.pump();
      await tester.tap(find.text('Option B'));
      await tester.pump();
      await tester.tap(find.text('Option C'));
      await tester.pump();

      expect(tapCount, 3);
    });
  });
}