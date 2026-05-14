import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_session_nav_buttons.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('PracticeSessionNavButtons', () {
    testWidgets('renders previous and next buttons', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeSessionNavButtons(
          onPrevious: () {},
          onNext: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('shows arrow icons', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeSessionNavButtons(
          onPrevious: () {},
          onNext: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('calls onPrevious when previous button tapped', (tester) async {
      bool previousCalled = false;
      await tester.pumpWidget(_buildTestApp(
        PracticeSessionNavButtons(
          onPrevious: () => previousCalled = true,
          onNext: () {},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();

      expect(previousCalled, isTrue);
    });

    testWidgets('calls onNext when next button tapped', (tester) async {
      bool nextCalled = false;
      await tester.pumpWidget(_buildTestApp(
        PracticeSessionNavButtons(
          onPrevious: () {},
          onNext: () => nextCalled = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(nextCalled, isTrue);
    });

    testWidgets('renders inside a Column layout', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeSessionNavButtons(
          onPrevious: () {},
          onNext: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Column), findsOneWidget);
    });
  });
}
