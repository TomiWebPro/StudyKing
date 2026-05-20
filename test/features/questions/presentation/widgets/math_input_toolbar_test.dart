import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/presentation/widgets/math_input_toolbar.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget widget) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: widget,
    ),
  );
}

void main() {
  group('MathInputToolbar', () {
    testWidgets('renders all symbol buttons', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(controller: controller),
      ));

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(InkWell), findsNWidgets(17));
    });

    testWidgets('tapping ^ symbol inserts caret at end', (tester) async {
      final controller = TextEditingController(text: 'x');
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(controller: controller),
      ));

      await tester.tap(find.text('xⁿ'));
      await tester.pumpAndSettle();

      expect(controller.text, 'x^');
      expect(controller.selection.baseOffset, 2);
    });

    testWidgets('tapping sqrt symbol at cursor position', (tester) async {
      final controller = TextEditingController(text: 'x+1');
      controller.selection = TextSelection.collapsed(offset: 1);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(controller: controller),
      ));

      await tester.tap(find.text('√'));
      await tester.pumpAndSettle();

      expect(controller.text, 'xsqrt(+1');
      expect(controller.selection.baseOffset, 6);
    });

    testWidgets('tapping pi inserts pi symbol text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(controller: controller),
      ));

      await tester.tap(find.text('π'));
      await tester.pumpAndSettle();

      expect(controller.text, 'pi');
    });

    testWidgets('tapping theta inserts theta text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(controller: controller),
      ));

      await tester.tap(find.text('θ'));
      await tester.pumpAndSettle();

      expect(controller.text, 'theta');
    });

    testWidgets('tapping alpha inserts alpha text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(controller: controller),
      ));

      await tester.tap(find.text('α'));
      await tester.pumpAndSettle();

      expect(controller.text, 'alpha');
    });

    testWidgets('tapping infty inserts infty text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(controller: controller),
      ));

      await tester.tap(find.text('∞'));
      await tester.pumpAndSettle();

      expect(controller.text, 'infty');
    });

    testWidgets('tapping sum inserts sum text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(controller: controller),
      ));

      await tester.tap(find.text('Σ'));
      await tester.pumpAndSettle();

      expect(controller.text, 'sum');
    });

    testWidgets('tapping int inserts int text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(controller: controller),
      ));

      await tester.tap(find.text('∫'));
      await tester.pumpAndSettle();

      expect(controller.text, 'int');
    });

    testWidgets('tapping frac inserts frac template text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(controller: controller),
      ));

      await tester.tap(find.text('a/b'));
      await tester.pumpAndSettle();

      expect(controller.text, 'frac{}{}');
    });

    testWidgets('tapping pm inserts plusminus text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(controller: controller),
      ));

      await tester.tap(find.text('±'));
      await tester.pumpAndSettle();

      expect(controller.text, 'pm');
    });

    testWidgets('tapping times inserts times text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(controller: controller),
      ));

      await tester.tap(find.text('×'));
      await tester.pumpAndSettle();

      expect(controller.text, 'times');
    });

    testWidgets('tapping rightarrow inserts rightarrow text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(controller: controller),
      ));

      await tester.tap(find.text('→'));
      await tester.pumpAndSettle();

      expect(controller.text, 'rightarrow');
    });

    testWidgets('tapping geq inserts geq text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(controller: controller),
      ));

      await tester.tap(find.text('≥'));
      await tester.pumpAndSettle();

      expect(controller.text, 'geq');
    });

    testWidgets('tapping leq inserts leq text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(controller: controller),
      ));

      await tester.tap(find.text('≤'));
      await tester.pumpAndSettle();

      expect(controller.text, 'leq');
    });

    testWidgets('tapping neq inserts neq text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(controller: controller),
      ));

      await tester.tap(find.text('≠'));
      await tester.pumpAndSettle();

      expect(controller.text, 'neq');
    });

    testWidgets('inserts at cursor position when not at end', (tester) async {
      final controller = TextEditingController(text: 'ab');
      controller.selection = TextSelection.collapsed(offset: 1);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(controller: controller),
      ));

      await tester.tap(find.text('xⁿ'));
      await tester.pumpAndSettle();

      expect(controller.text, 'a^b');
      expect(controller.selection.baseOffset, 2);
    });

    testWidgets('multiple taps insert multiple symbols', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(controller: controller),
      ));

      await tester.tap(find.text('π'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('×'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('xⁿ'));
      await tester.pumpAndSettle();

      expect(controller.text, 'pitimes^');
    });

    testWidgets('all symbol buttons have semantics', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(controller: controller),
      ));

      final semantics = find.descendant(
        of: find.byType(MathInputToolbar),
        matching: find.bySemanticsLabel(RegExp(r'.+')),
      );
      expect(semantics, findsNWidgets(17));
    });

    testWidgets('handles empty controller gracefully', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(controller: controller),
      ));

      await tester.tap(find.text('xⁿ'));
      await tester.pumpAndSettle();

      expect(controller.text, '^');
    });

    testWidgets('renders with showPreview true does not crash', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(
          controller: controller,
          showPreview: true,
        ),
      ));

      expect(find.byType(MathInputToolbar), findsOneWidget);
    });

    testWidgets('renders with showPreview false does not crash', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(
          controller: controller,
          showPreview: false,
        ),
      ));

      expect(find.byType(MathInputToolbar), findsOneWidget);
    });

    testWidgets('renders all display labels', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildTestApp(
        MathInputToolbar(controller: controller),
      ));

      final expectedLabels = ['xⁿ', 'xₙ', '√', 'π', 'θ', 'α', 'β', '∞', 'Σ',
        '∫', 'a/b', '±', '×', '→', '≥', '≤', '≠'];

      for (final label in expectedLabels) {
        expect(find.text(label), findsOneWidget);
      }
    });
  });
}
