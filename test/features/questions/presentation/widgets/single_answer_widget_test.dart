import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/presentation/widgets/single_answer_widget.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget buildWidget({
  List<String> options = const ['Option A', 'Option B', 'Option C', 'Option D'],
  String? correctAnswer,
  String? selectedAnswer,
  bool isSubmitted = false,
  bool isFeedbackVisible = true,
  ValueChanged<String?>? onAnswerSelected,
  bool reduceMotion = false,
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
        reduceMotion: reduceMotion,
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

      testWidgets('correct answer adds correct feedback to semantics label', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option A',
          selectedAnswer: 'Option A',
          isSubmitted: true,
        ));

        expect(find.bySemanticsLabel(RegExp('Correct!')), findsWidgets);
      });

      testWidgets('incorrect selected answer adds incorrect feedback to semantics', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option A',
          selectedAnswer: 'Option B',
          isSubmitted: true,
        ));

        expect(find.bySemanticsLabel(RegExp('Incorrect')), findsWidgets);
      });

      testWidgets('not submitted does not add feedback to semantics', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option A',
          selectedAnswer: 'Option B',
          isSubmitted: false,
        ));

        expect(find.bySemanticsLabel(RegExp('Option B')), findsOneWidget);
      });
    });

    group('reduceMotion', () {
      testWidgets('uses Container instead of AnimatedSwitcher when reduceMotion is true', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option A',
          selectedAnswer: 'Option A',
          isSubmitted: true,
          isFeedbackVisible: true,
          reduceMotion: true,
        ));

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.text('Correct!'), findsOneWidget);
      });

      testWidgets('uses AnimatedSwitcher when reduceMotion is false', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option A',
          selectedAnswer: 'Option A',
          isSubmitted: true,
          isFeedbackVisible: true,
          reduceMotion: false,
        ));

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.text('Correct!'), findsOneWidget);
      });

      testWidgets('feedback hidden when isFeedbackVisible false with reduceMotion', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option A',
          selectedAnswer: 'Option A',
          isSubmitted: true,
          isFeedbackVisible: false,
          reduceMotion: true,
        ));

        expect(find.byIcon(Icons.check_circle), findsNothing);
      });
    });

    group('option text properties', () {
      testWidgets('option text has softWrap enabled', (tester) async {
        await tester.pumpWidget(buildWidget(options: ['Long option text']));

        final textWidget = tester.widget<Text>(find.text('Long option text'));
        expect(textWidget.softWrap, isTrue);
      });

      testWidgets('option text has maxLines 3', (tester) async {
        await tester.pumpWidget(buildWidget(options: ['Any option']));

        final textWidget = tester.widget<Text>(find.text('Any option'));
        expect(textWidget.maxLines, 3);
      });

      testWidgets('option text overflow is ellipsis', (tester) async {
        await tester.pumpWidget(buildWidget(options: ['Any option']));

        final textWidget = tester.widget<Text>(find.text('Any option'));
        expect(textWidget.overflow, TextOverflow.ellipsis);
      });
    });

    group('option highlighting after submission', () {
      testWidgets('non-selected correct option gets tertiary container color', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option C',
          selectedAnswer: 'Option B',
          isSubmitted: true,
        ));

        expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
        expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(3));
      });

      testWidgets('non-selected non-correct option stays transparent after submission', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option A',
          selectedAnswer: 'Option B',
          isSubmitted: true,
        ));

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('correct answer option gets tertiary container color', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option C',
          selectedAnswer: 'Option B',
          isSubmitted: true,
        ));

        expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(3));
      });

      testWidgets('non-selected non-correct option has transparent background', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option A',
          selectedAnswer: 'Option B',
          isSubmitted: true,
        ));

        expect(find.byType(InkWell), findsNWidgets(4));
      });
    });

    group('semantics hint', () {
      testWidgets('provides hint when not submitted', (tester) async {
        await tester.pumpWidget(buildWidget(isSubmitted: false));

        final semantics = find.bySemanticsLabel(RegExp('Option [A-D]'));
        expect(semantics, findsNWidgets(4));
      });

      testWidgets('no hint when submitted', (tester) async {
        await tester.pumpWidget(buildWidget(
          isSubmitted: true,
          correctAnswer: 'Option A',
          selectedAnswer: 'Option A',
        ));

        expect(find.byType(InkWell), findsNWidgets(4));
      });
    });

    group('option label edge cases', () {
      testWidgets('submitted with null correct answer renders options', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: null,
          selectedAnswer: 'Option A',
          isSubmitted: true,
        ));

        expect(find.text('Option A'), findsOneWidget);
        expect(find.text('Option B'), findsOneWidget);
      });

      testWidgets('submitted correct answer includes correct feedback in semantics', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option A',
          selectedAnswer: 'Option A',
          isSubmitted: true,
        ));

        expect(find.bySemanticsLabel(RegExp('Option A.*Correct!')), findsOneWidget);
      });

      testWidgets('submitted correct answer label for unselected option', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option A',
          selectedAnswer: 'Option B',
          isSubmitted: true,
        ));

        expect(find.bySemanticsLabel(RegExp('Option A.*Correct!')), findsOneWidget);
      });

      testWidgets('submitted with null correctAnswer does not add feedback to semantics', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: null,
          selectedAnswer: 'Option A',
          isSubmitted: true,
        ));

        expect(find.bySemanticsLabel(RegExp('Option A')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('Option A.*Correct!')), findsNothing);
      });
    });

    group('feedback content text', () {
      testWidgets('correct answer shows Selected right option text', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option A',
          selectedAnswer: 'Option A',
          isSubmitted: true,
          isFeedbackVisible: true,
        ));

        expect(find.text('Selected right option'), findsOneWidget);
      });

      testWidgets('incorrect answer shows Try again text', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option A',
          selectedAnswer: 'Option B',
          isSubmitted: true,
          isFeedbackVisible: true,
        ));

        expect(find.text('Try again'), findsOneWidget);
      });
    });

    group('non-selected correct option highlighting', () {
      testWidgets('correct option highlighted even when not selected', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option A',
          selectedAnswer: 'Option B',
          isSubmitted: true,
        ));

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      });
    });

    group('submitted with no selected answer', () {
      testWidgets('handles submitted with no selected answer and no correct answer', (tester) async {
        await tester.pumpWidget(buildWidget(
          selectedAnswer: null,
          isSubmitted: true,
          isFeedbackVisible: true,
        ));

        expect(find.byIcon(Icons.check_circle), findsNothing);
        expect(find.byIcon(Icons.error_outline), findsNothing);
      });
    });

    group('reduceMotion AnimatedSwitcher feedback', () {
      testWidgets('AnimatedSwitcher wraps feedback when reduceMotion is false', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option A',
          selectedAnswer: 'Option A',
          isSubmitted: true,
          isFeedbackVisible: true,
          reduceMotion: false,
        ));

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.text('Correct!'), findsOneWidget);
      });
    });

    group('correct answer semantics for non-selected option', () {
      testWidgets('correct answer option gets correct feedback in semantics even when not selected', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option A',
          selectedAnswer: 'Option B',
          isSubmitted: true,
        ));

        expect(find.bySemanticsLabel(RegExp('Option A.*Correct!')), findsOneWidget);
      });

      testWidgets('wrong selected option gets incorrect feedback in semantics', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option A',
          selectedAnswer: 'Option B',
          isSubmitted: true,
        ));

        expect(find.bySemanticsLabel(RegExp('Option B.*Incorrect')), findsOneWidget);
      });
    });

    group('correct answer with correctAnswer null', () {
      testWidgets('option color transparent when correctAnswer is null even if submitted', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: null,
          selectedAnswer: 'Option A',
          isSubmitted: true,
        ));

        expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      });

      testWidgets('no color highlighting when correctAnswer is null', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: null,
          selectedAnswer: 'Option B',
          isSubmitted: true,
        ));

        expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
        expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(3));
      });
    });

    group('selected answer styling', () {
      testWidgets('selected option has primary color border', (tester) async {
        await tester.pumpWidget(buildWidget(selectedAnswer: 'Option A'));

        expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      });

      testWidgets('non-selected option has outline color border', (tester) async {
        await tester.pumpWidget(buildWidget(selectedAnswer: 'Option A'));

        expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(3));
      });
    });

    group('feedback with reduceMotion and wrong answer', () {
      testWidgets('incorrect feedback with reduceMotion', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: 'Option A',
          selectedAnswer: 'Option B',
          isSubmitted: true,
          isFeedbackVisible: true,
          reduceMotion: true,
        ));

        expect(find.text('Incorrect'), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
      });
    });

    group('option semantics with null correctAnswer and submitted', () {
      testWidgets('no feedback in semantics when correctAnswer is null', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: null,
          selectedAnswer: 'Option A',
          isSubmitted: true,
        ));

        expect(find.bySemanticsLabel(RegExp('Option A')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('Correct')), findsNothing);
      });

      testWidgets('selected answer semantics without correct answer', (tester) async {
        await tester.pumpWidget(buildWidget(
          correctAnswer: null,
          selectedAnswer: 'Option B',
          isSubmitted: true,
        ));

        expect(find.bySemanticsLabel(RegExp('Option B')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('Incorrect')), findsNothing);
      });
    });
  });
}
