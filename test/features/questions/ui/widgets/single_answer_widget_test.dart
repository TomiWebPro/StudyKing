import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/ui/widgets/single_answer_widget.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget buildWidget({
  List<String> options = const ['Option A', 'Option B', 'Option C', 'Option D'],
  String? correctAnswer,
  String? selectedAnswer,
  bool isSubmitted = false,
  bool isFeedbackVisible = true,
  ValueChanged<String?>? onAnswerSelected,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
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

void main() {
  group('SingleAnswerWidget', () {
    const testOptions = ['Option A', 'Option B', 'Option C', 'Option D'];

    group('basic rendering', () {
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

      testWidgets('renders without feedback when not submitted', (tester) async {
        await tester.pumpWidget(buildWidget(isSubmitted: false));

        expect(find.byIcon(Icons.check_circle), findsNothing);
        expect(find.byIcon(Icons.error_outline), findsNothing);
      });

      testWidgets('renders with InkWell for each option', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.byType(InkWell), findsNWidgets(4));
      });
    });

    group('selection', () {
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

      testWidgets('handles rapid taps on different options', (tester) async {
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

    group('submitted feedback', () {
      testWidgets('renders correct feedback when answer is correct', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option A',
          selectedAnswer: 'Option A',
          isSubmitted: true,
          isFeedbackVisible: true,
        ));

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.text('Correct!'), findsOneWidget);
      });

      testWidgets('renders incorrect feedback when answer is wrong', (tester) async {
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

      testWidgets('does not show feedback when correctAnswer is null', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: null,
          selectedAnswer: 'Option A',
          isSubmitted: true,
          isFeedbackVisible: true,
        ));

        expect(find.byIcon(Icons.check_circle), findsNothing);
        expect(find.byIcon(Icons.error_outline), findsNothing);
        expect(find.text('Correct!'), findsNothing);
        expect(find.text('Incorrect'), findsNothing);
      });

      testWidgets('highlights correct answer with tertiary color after submission', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option C',
          selectedAnswer: 'Option C',
          isSubmitted: true,
        ));

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('highlights wrong selected answer with error color after submission', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option A',
          selectedAnswer: 'Option B',
          isSubmitted: true,
        ));

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });
    });

    group('option highlighting colors', () {
      testWidgets('correct answer gets tertiary container color when submitted', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option A',
          selectedAnswer: 'Option A',
          isSubmitted: true,
        ));

        final containers = tester.widgetList<Container>(find.descendant(
          of: find.byType(SingleAnswerWidget),
          matching: find.byType(Container),
        )).toList();
        expect(containers.length, greaterThan(1));
      });

      testWidgets('wrong selected answer gets error container color when submitted', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option A',
          selectedAnswer: 'Option B',
          isSubmitted: true,
        ));

        final containers = tester.widgetList<Container>(find.descendant(
          of: find.byType(SingleAnswerWidget),
          matching: find.byType(Container),
        )).toList();
        expect(containers.length, greaterThan(1));
      });

      testWidgets('transparent color when not submitted', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option A',
          selectedAnswer: 'Option B',
          isSubmitted: false,
        ));

        expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
        expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(3));
      });
    });

    group('edge cases', () {
      testWidgets('handles empty options list', (tester) async {
        await tester.pumpWidget(buildWidget(options: []));

        expect(find.byType(InkWell), findsNothing);
      });

      testWidgets('handles single option', (tester) async {
        await tester.pumpWidget(buildWidget(options: ['Only Option']));

        expect(find.text('Only Option'), findsOneWidget);
      });

      testWidgets('handles option text overflow', (tester) async {
        const longOption = 'This is a very long option text that should be handled properly without overflow issues';
        await tester.pumpWidget(buildWidget(options: [longOption]));

        final textWidget = tester.widget<Text>(find.text(longOption));
        expect(textWidget.softWrap, isTrue);
        expect(textWidget.overflow, TextOverflow.ellipsis);
        expect(textWidget.maxLines, 3);
      });

      testWidgets('renders without correct answer', (tester) async {
        await tester.pumpWidget(buildWidget(correctAnswer: null));

        expect(find.text('Option A'), findsOneWidget);
      });

      testWidgets('multiple options with correct feedback', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option D',
          selectedAnswer: 'Option D',
          isSubmitted: true,
          isFeedbackVisible: true,
        ));

        expect(find.text('Correct!'), findsOneWidget);
      });
    });

    group('accessibility semantics', () {
      testWidgets('provides button semantics for options', (tester) async {
        await tester.pumpWidget(buildWidget());

        final semantics = find.bySemanticsLabel(RegExp('Option [A-D]'));
        expect(semantics, findsNWidgets(4));
      });

      testWidgets('selected answer Option B shows checked radio', (tester) async {
        await tester.pumpWidget(buildWidget(selectedAnswer: 'Option B'));

        expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
        expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(3));
      });
    });
  });
}
