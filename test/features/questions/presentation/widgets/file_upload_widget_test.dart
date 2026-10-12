import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
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

/// Hand-written fake that keeps the platform pick in flight until the test
/// completes it, so tests can dispose the widget mid-pick.
///
/// Extends (not implements) [FilePickerPlatform] so the platform
/// interface token check passes.
class FakePendingFilePickerPlatform extends FilePickerPlatform {
  final Completer<FilePickerResult?> _pickFiles =
      Completer<FilePickerResult?>();

  void completePick(FilePickerResult? result) => _pickFiles.complete(result);

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
  }) =>
      _pickFiles.future;
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

    group('dispose mid-flight', () {
      testWidgets('skips setState and answer callback when disposed while pick is in flight',
          (tester) async {
        final logs = <String>[];
        final previousDebugPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) {
            logs.add(message);
          }
        };
        final previousPlatform = FilePickerPlatform.instance;
        final fakePicker = FakePendingFilePickerPlatform();
        FilePickerPlatform.instance = fakePicker;
        try {
          String? changedAnswer;
          await tester.pumpWidget(
            buildApp(
              FileUploadWidget(
                currentAnswer: null,
                isSubmitted: false,
                onAnswerChanged: (value) => changedAnswer = value,
              ),
            ),
          );

          await tester.tap(find.widgetWithText(OutlinedButton, 'Upload file'));
          await tester.pump();

          // Dispose the widget while the platform pick is still in flight.
          await tester.pumpWidget(const SizedBox());

          // The pick completes after the widget is gone.
          fakePicker.completePick(
            FilePickerResult(
              <PlatformFile>[
                PlatformFile(name: 'notes.txt', path: '/tmp/notes.txt', size: 42),
              ],
            ),
          );
          await tester.pump();

          expect(changedAnswer, isNull);
          expect(
            logs.where(
              (message) => message.contains('setState() called after dispose'),
            ),
            isEmpty,
          );
        } finally {
          FilePickerPlatform.instance = previousPlatform;
          debugPrint = previousDebugPrint;
        }
      });
    });
  });
}
