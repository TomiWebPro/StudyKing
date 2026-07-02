import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/presentation/widgets/file_upload_widget.dart';
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
  group('FileUploadWidget', () {
    group('basic rendering', () {
      testWidgets('renders upload button when no answer provided', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildApp(
            FileUploadWidget(
              currentAnswer: null,
              isSubmitted: false,
              onAnswerChanged: (_) {},
            ),
          ),
        );

        expect(find.text('Upload file'), findsOneWidget);
        expect(find.byIcon(Icons.upload_file), findsOneWidget);
      });

      testWidgets('shows file attached when answer is provided', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildApp(
            FileUploadWidget(
              currentAnswer: 'report.pdf||/tmp/report.pdf',
              isSubmitted: false,
              onAnswerChanged: (_) {},
            ),
          ),
        );

        expect(find.text('File attached'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('renders OutlinedButton', (tester) async {
        await tester.pumpWidget(
          buildApp(
            FileUploadWidget(
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
            FileUploadWidget(
              currentAnswer: 'report.pdf||/tmp/report.pdf',
              isSubmitted: true,
              onAnswerChanged: (_) {},
            ),
          ),
        );

        final button = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'File attached'),
        );
        expect(button.onPressed, isNull);
      });

      testWidgets('button is enabled when not submitted', (tester) async {
        await tester.pumpWidget(
          buildApp(
            FileUploadWidget(
              currentAnswer: null,
              isSubmitted: false,
              onAnswerChanged: (_) {},
            ),
          ),
        );

        final button = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Upload file'),
        );
        expect(button.onPressed, isNotNull);
      });
    });

    group('edge cases', () {
      testWidgets('handles empty answer string', (tester) async {
        await tester.pumpWidget(
          buildApp(
            FileUploadWidget(
              currentAnswer: '',
              isSubmitted: false,
              onAnswerChanged: (_) {},
            ),
          ),
        );

        expect(find.text('Upload file'), findsOneWidget);
      });

      testWidgets('shows file name when file path provided', (tester) async {
        await tester.pumpWidget(
          buildApp(
            FileUploadWidget(
              currentAnswer: 'notes.txt||/tmp/notes.txt',
              isSubmitted: false,
              onAnswerChanged: (_) {},
            ),
          ),
        );

        expect(find.text('notes.txt'), findsOneWidget);
      });

      testWidgets('handles answer with only file name and no path', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildApp(
            FileUploadWidget(
              currentAnswer: 'image.png',
              isSubmitted: false,
              onAnswerChanged: (_) {},
            ),
          ),
        );

        expect(find.text('File attached'), findsOneWidget);
        expect(find.text('image.png'), findsOneWidget);
      });
    });
  });
}
