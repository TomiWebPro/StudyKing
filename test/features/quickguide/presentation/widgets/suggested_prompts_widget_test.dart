import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/quickguide/presentation/widgets/suggested_prompts_widget.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp({
  required SuggestedPromptsWidget widget,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: widget),
  );
}

void main() {
  group('SuggestedPromptsWidget', () {
    final prompts = ['Explain photosynthesis', 'Quiz me on history', 'Help with math problems'];

    testWidgets('renders section title', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        widget: SuggestedPromptsWidget(
          prompts: prompts,
          onSelectPrompt: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.text('Suggested prompts'), findsOneWidget);
    });

    testWidgets('renders all prompt chips', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        widget: SuggestedPromptsWidget(
          prompts: prompts,
          onSelectPrompt: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.byType(ActionChip), findsNWidgets(3));

      for (final prompt in prompts) {
        expect(find.text(prompt), findsOneWidget);
      }
    });

    testWidgets('calls onSelectPrompt with correct prompt when chip is tapped',
        (tester) async {
      String? selected;
      await tester.pumpWidget(_buildTestApp(
        widget: SuggestedPromptsWidget(
          prompts: prompts,
          onSelectPrompt: (p) => selected = p,
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('Explain photosynthesis'));
      expect(selected, 'Explain photosynthesis');
    });

    testWidgets('different chips call onSelectPrompt with different values',
        (tester) async {
      final selected = <String>[];
      await tester.pumpWidget(_buildTestApp(
        widget: SuggestedPromptsWidget(
          prompts: prompts,
          onSelectPrompt: (p) => selected.add(p),
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('Quiz me on history'));
      await tester.tap(find.text('Help with math problems'));

      expect(selected, ['Quiz me on history', 'Help with math problems']);
    });

    testWidgets('handles empty prompts list', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        widget: SuggestedPromptsWidget(
          prompts: [],
          onSelectPrompt: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.byType(ActionChip), findsNothing);
      expect(find.text('Suggested prompts'), findsOneWidget);
    });

    testWidgets('renders single prompt', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        widget: SuggestedPromptsWidget(
          prompts: ['Single prompt'],
          onSelectPrompt: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.byType(ActionChip), findsOneWidget);
      expect(find.text('Single prompt'), findsOneWidget);
    });

    testWidgets('chips have semantics labels', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        widget: SuggestedPromptsWidget(
          prompts: ['Explain photosynthesis'],
          onSelectPrompt: (_) {},
        ),
      ));
      await tester.pump();

      expect(
        find.bySemanticsLabel('Send prompt: Explain photosynthesis'),
        findsOneWidget,
      );
    });

    testWidgets('chips use ActionChip widget', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        widget: SuggestedPromptsWidget(
          prompts: prompts,
          onSelectPrompt: (_) {},
        ),
      ));
      await tester.pump();

      final chips = find.byType(ActionChip);
      expect(chips, findsNWidgets(3));
    });

    testWidgets('chips do not have border side', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        widget: SuggestedPromptsWidget(
          prompts: ['Test'],
          onSelectPrompt: (_) {},
        ),
      ));
      await tester.pump();

      final chip = tester.widget<ActionChip>(find.byType(ActionChip));
      expect(chip.side, BorderSide.none);
    });

    testWidgets('has FocusTraversalGroup for keyboard navigation',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        widget: SuggestedPromptsWidget(
          prompts: prompts,
          onSelectPrompt: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.byType(FocusTraversalGroup), findsAtLeastNWidgets(1));
    });

    testWidgets('chips are laid out in a Wrap widget', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        widget: SuggestedPromptsWidget(
          prompts: prompts,
          onSelectPrompt: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('chip background color is secondaryContainer', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        widget: SuggestedPromptsWidget(
          prompts: ['Test'],
          onSelectPrompt: (_) {},
        ),
      ));
      await tester.pump();

      final chip = tester.widget<ActionChip>(find.byType(ActionChip));
      expect(chip.backgroundColor, isNotNull);
    });
  });
}
