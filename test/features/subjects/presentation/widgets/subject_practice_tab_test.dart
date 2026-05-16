import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/subjects/presentation/widgets/subject_practice_tab.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('SubjectPracticeTab', () {
    testWidgets('renders icon, title, and subtitle', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          SubjectPracticeTab(
            onStartPractice: () {},
            onStartSpacedRepetition: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsAtLeast(1));
      expect(find.text('Practice Mode'), findsAtLeast(1));
      expect(find.text('Practice Modes'), findsOneWidget);
    });

    testWidgets('shows Start Practice button', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          SubjectPracticeTab(
            onStartPractice: () {},
            onStartSpacedRepetition: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Start Practice'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsAtLeast(1));
    });

    testWidgets('shows Practice Mode outlined button', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          SubjectPracticeTab(
            onStartPractice: () {},
            onStartSpacedRepetition: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byIcon(Icons.repeat), findsOneWidget);
    });

    testWidgets('has semantics labels on buttons', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          SubjectPracticeTab(
            onStartPractice: () {},
            onStartSpacedRepetition: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Semantics), findsAtLeastNWidgets(2));
    });

    testWidgets('calls onStartPractice when filled button is tapped', (
      tester,
    ) async {
      bool started = false;
      await tester.pumpWidget(
        _buildTestApp(
          SubjectPracticeTab(
            onStartPractice: () => started = true,
            onStartSpacedRepetition: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(started, isTrue);
    });

    testWidgets(
      'calls onStartSpacedRepetition when outlined button is tapped',
      (tester) async {
        bool started = false;
        await tester.pumpWidget(
          _buildTestApp(
            SubjectPracticeTab(
              onStartPractice: () {},
              onStartSpacedRepetition: () => started = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(OutlinedButton));
        await tester.pumpAndSettle();

        expect(started, isTrue);
      },
    );

    testWidgets('contains both buttons', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          SubjectPracticeTab(
            onStartPractice: () {},
            onStartSpacedRepetition: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('renders inside a Padding widget', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          SubjectPracticeTab(
            onStartPractice: () {},
            onStartSpacedRepetition: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Padding), findsAtLeastNWidgets(1));
    });

    testWidgets('FilledButton contains play_arrow icon', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          SubjectPracticeTab(
            onStartPractice: () {},
            onStartSpacedRepetition: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final playInFilled = find.descendant(
        of: find.byType(FilledButton),
        matching: find.byIcon(Icons.play_arrow),
      );
      expect(playInFilled, findsOneWidget);
    });

    testWidgets('OutlinedButton contains repeat icon', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          SubjectPracticeTab(
            onStartPractice: () {},
            onStartSpacedRepetition: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final repeatInOutlined = find.descendant(
        of: find.byType(OutlinedButton),
        matching: find.byIcon(Icons.repeat),
      );
      expect(repeatInOutlined, findsOneWidget);
    });

    testWidgets('play_arrow icon appears in both large icon and button', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          SubjectPracticeTab(
            onStartPractice: () {},
            onStartSpacedRepetition: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsAtLeastNWidgets(2));
    });

    testWidgets('both callbacks can be triggered multiple times', (
      tester,
    ) async {
      int practiceCalls = 0;
      int spacedCalls = 0;
      await tester.pumpWidget(
        _buildTestApp(
          SubjectPracticeTab(
            onStartPractice: () => practiceCalls++,
            onStartSpacedRepetition: () => spacedCalls++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(practiceCalls, 1);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(practiceCalls, 2);

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      expect(spacedCalls, 1);

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      expect(spacedCalls, 2);
    });
  });
}
