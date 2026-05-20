import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/presentation/widgets/confidence_selector.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('ConfidenceSelector', () {
    group('getConfidenceColor', () {
      test('returns error for rating 1', () {
        const cs = ColorScheme.light();
        expect(ConfidenceSelector.getConfidenceColor(1, cs), cs.error);
      });

      test('returns tertiary for rating 2', () {
        const cs = ColorScheme.light();
        expect(ConfidenceSelector.getConfidenceColor(2, cs), cs.tertiary);
      });

      test('returns tertiary for rating 3', () {
        const cs = ColorScheme.light();
        expect(ConfidenceSelector.getConfidenceColor(3, cs), cs.tertiary);
      });

      test('returns primary for rating 4', () {
        const cs = ColorScheme.light();
        expect(ConfidenceSelector.getConfidenceColor(4, cs), cs.primary);
      });

      test('returns primary for rating 5', () {
        const cs = ColorScheme.light();
        expect(ConfidenceSelector.getConfidenceColor(5, cs), cs.primary);
      });

      test('returns onSurfaceVariant for default', () {
        const cs = ColorScheme.light();
        expect(ConfidenceSelector.getConfidenceColor(0, cs), cs.onSurfaceVariant);
      });
    });

    group('widget', () {
      Widget buildSelector({int value = 3, void Function(int)? onChanged}) {
        return _buildTestApp(
          ConfidenceSelector(value: value, onChanged: onChanged ?? (_) {}),
        );
      }

      testWidgets('renders title text', (tester) async {
        await tester.pumpWidget(buildSelector());
        await tester.pumpAndSettle();

        expect(find.text('How confident are you?'), findsOneWidget);
      });

      testWidgets('renders five rating buttons 1 through 5', (tester) async {
        await tester.pumpWidget(buildSelector());
        await tester.pumpAndSettle();

        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('shows label for the selected value 1', (tester) async {
        await tester.pumpWidget(buildSelector(value: 1));
        await tester.pumpAndSettle();

        expect(find.text('Not confident at all'), findsOneWidget);
      });

      testWidgets('shows label for the selected value 2', (tester) async {
        await tester.pumpWidget(buildSelector(value: 2));
        await tester.pumpAndSettle();

        expect(find.text('Slightly confident'), findsOneWidget);
      });

      testWidgets('shows label for the selected value 3', (tester) async {
        await tester.pumpWidget(buildSelector(value: 3));
        await tester.pumpAndSettle();

        expect(find.text('Moderately confident'), findsOneWidget);
      });

      testWidgets('shows label for the selected value 4', (tester) async {
        await tester.pumpWidget(buildSelector(value: 4));
        await tester.pumpAndSettle();

        expect(find.text('Quite confident'), findsOneWidget);
      });

      testWidgets('shows label for the selected value 5', (tester) async {
        await tester.pumpWidget(buildSelector(value: 5));
        await tester.pumpAndSettle();

        expect(find.text('Very confident'), findsOneWidget);
      });

      testWidgets('calls onChanged when a rating is tapped', (tester) async {
        int? captured;
        await tester.pumpWidget(_buildTestApp(
          ConfidenceSelector(
            value: 1,
            onChanged: (v) => captured = v,
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('4'));
        await tester.pumpAndSettle();

        expect(captured, 4);
      });

      testWidgets('highlights selected rating with bold text', (tester) async {
        await tester.pumpWidget(buildSelector(value: 3));
        await tester.pumpAndSettle();

        final text3 = tester.widget<Text>(find.text('3'));
        expect(text3.style?.fontWeight, FontWeight.bold);
      });

      testWidgets('does not bold non-selected ratings', (tester) async {
        await tester.pumpWidget(buildSelector(value: 3));
        await tester.pumpAndSettle();

        final text1 = tester.widget<Text>(find.text('1'));
        expect(text1.style?.fontWeight, FontWeight.normal);
      });

      testWidgets('renders Wrap layout for rating buttons', (tester) async {
        await tester.pumpWidget(buildSelector());
        await tester.pumpAndSettle();

        expect(find.byType(Wrap), findsOneWidget);
      });

      testWidgets('renders Semantics for accessibility', (tester) async {
        await tester.pumpWidget(buildSelector());
        await tester.pumpAndSettle();

        expect(find.byType(Semantics), findsWidgets);
      });

      testWidgets('renders AnimatedContainer for each rating', (tester) async {
        await tester.pumpWidget(buildSelector());
        await tester.pumpAndSettle();

        expect(find.byType(AnimatedContainer), findsNWidgets(5));
      });

      testWidgets('calls onChanged with correct rating when tapping each button', (tester) async {
        for (final expected in [1, 2, 3, 4, 5]) {
          int? captured;
          await tester.pumpWidget(_buildTestApp(
            ConfidenceSelector(
              value: 1,
              onChanged: (v) => captured = v,
            ),
          ));
          await tester.pumpAndSettle();

          await tester.tap(find.text('$expected'));
          await tester.pumpAndSettle();

          expect(captured, expected);
        }
      });
    });
  });
}
