import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/presentation/widgets/audio_recording_widget.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget buildApp(Widget widget) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: widget),
  );
}

void main() {
  group('AudioRecordingWidget', () {
    group('basic rendering', () {
      testWidgets('renders start recording button when no answer provided', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildApp(
            AudioRecordingWidget(
              currentAnswer: null,
              isSubmitted: false,
              onAnswerChanged: (_) {},
            ),
          ),
        );

        expect(find.text('Start recording'), findsOneWidget);
        expect(find.byIcon(Icons.mic_none), findsOneWidget);
      });

      testWidgets('shows recording complete when answer is provided', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildApp(
            AudioRecordingWidget(
              currentAnswer: '/tmp/recording.m4a',
              isSubmitted: false,
              onAnswerChanged: (_) {},
            ),
          ),
        );

        expect(find.text('Recording complete'), findsOneWidget);
        expect(find.byIcon(Icons.mic), findsOneWidget);
      });

      testWidgets('renders OutlinedButton', (tester) async {
        await tester.pumpWidget(
          buildApp(
            AudioRecordingWidget(
              currentAnswer: null,
              isSubmitted: false,
              onAnswerChanged: (_) {},
            ),
          ),
        );

        expect(find.byType(OutlinedButton), findsOneWidget);
      });
    });

    group('submitted state', () {
      testWidgets('disables button when isSubmitted is true', (tester) async {
        await tester.pumpWidget(
          buildApp(
            AudioRecordingWidget(
              currentAnswer: '/tmp/recording.m4a',
              isSubmitted: true,
              onAnswerChanged: (_) {},
            ),
          ),
        );

        final button = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Recording complete'),
        );
        expect(button.onPressed, isNull);
      });

      testWidgets('button is enabled when not submitted', (tester) async {
        await tester.pumpWidget(
          buildApp(
            AudioRecordingWidget(
              currentAnswer: null,
              isSubmitted: false,
              onAnswerChanged: (_) {},
            ),
          ),
        );

        final button = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Start recording'),
        );
        expect(button.onPressed, isNotNull);
      });
    });

    group('edge cases', () {
      testWidgets('handles empty answer string', (tester) async {
        await tester.pumpWidget(
          buildApp(
            AudioRecordingWidget(
              currentAnswer: '',
              isSubmitted: false,
              onAnswerChanged: (_) {},
            ),
          ),
        );

        expect(find.text('Start recording'), findsOneWidget);
      });

      testWidgets('shows filename when recording provided', (tester) async {
        await tester.pumpWidget(
          buildApp(
            AudioRecordingWidget(
              currentAnswer: '/tmp/recording_12345.m4a',
              isSubmitted: false,
              onAnswerChanged: (_) {},
            ),
          ),
        );

        expect(find.text('recording_12345.m4a'), findsOneWidget);
      });
    });
  });
}
