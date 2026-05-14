import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_session_stats_bar.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('PracticeSessionStatsBar', () {
    testWidgets('renders elapsed time', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeSessionStatsBar(
          elapsedTime: '5:30',
          correctAnswers: 3,
          currentIndex: 4,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('5:30'), findsOneWidget);
    });

    testWidgets('renders correct answers count', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeSessionStatsBar(
          elapsedTime: '1:00',
          correctAnswers: 5,
          currentIndex: 7,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('renders score percentage', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeSessionStatsBar(
          elapsedTime: '2:00',
          correctAnswers: 4,
          currentIndex: 7,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('renders 0% score when no questions answered', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeSessionStatsBar(
          elapsedTime: '0:00',
          correctAnswers: 0,
          currentIndex: 0,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('handles null elapsed time', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeSessionStatsBar(
          elapsedTime: null,
          correctAnswers: 0,
          currentIndex: 0,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('0:00'), findsOneWidget);
    });

    testWidgets('renders time, score, and correct icons', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeSessionStatsBar(
          elapsedTime: '1:00',
          correctAnswers: 2,
          currentIndex: 3,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.access_time), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
