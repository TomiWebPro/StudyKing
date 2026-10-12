import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
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

/// Hand-written fake that keeps permission/start/stop in flight until the
/// test completes them, so tests can dispose the widget mid-call.
///
/// Extends (not implements) [RecordPlatform] so the platform
/// interface token check passes.
class FakePendingRecordPlatform extends RecordPlatform {
  final Completer<bool> _hasPermission = Completer<bool>();
  final Completer<void> _start = Completer<void>();
  final Completer<String?> _stop = Completer<String?>();

  void completeHasPermission(bool granted) => _hasPermission.complete(granted);

  void completeStart() => _start.complete();

  void completeStop(String? path) => _stop.complete(path);

  @override
  Future<void> create(String recorderId) async {}

  @override
  Future<bool> hasPermission(
    String recorderId, {
    bool request = true,
  }) =>
      _hasPermission.future;

  @override
  Future<void> start(
    String recorderId,
    RecordConfig config, {
    required String path,
  }) =>
      _start.future;

  @override
  Future<String?> stop(String recorderId) => _stop.future;

  @override
  Stream<RecordState> onStateChanged(String recorderId) =>
      Stream<RecordState>.empty();

  @override
  Future<bool> isRecording(String recorderId) async => false;

  @override
  Future<Amplitude> getAmplitude(String recorderId) async =>
      Amplitude(current: 0, max: 0);

  @override
  Future<Stream<Uint8List>> startStream(
    String recorderId,
    RecordConfig config,
  ) async =>
      Stream<Uint8List>.empty();

  @override
  Future<void> pause(String recorderId) async {}

  @override
  Future<void> resume(String recorderId) async {}

  @override
  Future<bool> isPaused(String recorderId) async => false;

  @override
  Future<bool> isEncoderSupported(String recorderId, AudioEncoder encoder) async =>
      true;

  @override
  Future<List<InputDevice>> listInputDevices(String recorderId) async =>
      <InputDevice>[];

  @override
  Future<void> cancel(String recorderId) async {}

  @override
  Future<void> dispose(String recorderId) async {}
}

void main() {
  setUp(() {
    // The record plugin guards every platform call with a single global
    // semaphore shared by all AudioRecorder instances. Tests that only
    // render this widget still fire the recorder's create() call on the
    // real method channel, which never completes in the test environment
    // and would hold that semaphore forever, stalling any later test
    // that exercises recording. Mock the channel so those calls complete
    // and the semaphore drains between tests.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.record/messages'),
      (MethodCall call) async => null,
    );
  });

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

    group('dispose mid-flight', () {
      testWidgets('skips setState when disposed while requesting mic permission',
          (tester) async {
        final logs = <String>[];
        final previousDebugPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) {
            logs.add(message);
          }
        };
        final previousPlatform = RecordPlatform.instance;
        final fakeRecord = FakePendingRecordPlatform();
        RecordPlatform.instance = fakeRecord;
        try {
          String? changedAnswer;
          await tester.pumpWidget(
            buildApp(
              AudioRecordingWidget(
                currentAnswer: null,
                isSubmitted: false,
                onAnswerChanged: (value) => changedAnswer = value,
              ),
            ),
          );

          await tester.tap(find.widgetWithText(OutlinedButton, 'Start recording'));
          await tester.pump();

          // Dispose the widget while the permission request is in flight.
          await tester.pumpWidget(const SizedBox());

          // Permission is granted and recording starts after the widget is gone.
          fakeRecord.completeHasPermission(true);
          await tester.pump();
          fakeRecord.completeStart();
          await tester.pump();

          expect(changedAnswer, isNull);
          expect(
            logs.where(
              (message) => message.contains('setState() called after dispose'),
            ),
            isEmpty,
          );
        } finally {
          RecordPlatform.instance = previousPlatform;
          debugPrint = previousDebugPrint;
        }
      });

      testWidgets('skips setState when disposed while stopping a recording',
          (tester) async {
        final logs = <String>[];
        final previousDebugPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) {
            logs.add(message);
          }
        };
        final previousPlatform = RecordPlatform.instance;
        final fakeRecord = FakePendingRecordPlatform();
        RecordPlatform.instance = fakeRecord;
        try {
          String? changedAnswer;
          await tester.pumpWidget(
            buildApp(
              AudioRecordingWidget(
                currentAnswer: null,
                isSubmitted: false,
                onAnswerChanged: (value) => changedAnswer = value,
              ),
            ),
          );

          // Start a recording first so the toggle stops it.
          await tester.tap(find.widgetWithText(OutlinedButton, 'Start recording'));
          await tester.pump();
          fakeRecord.completeHasPermission(true);
          await tester.pump();
          fakeRecord.completeStart();
          await tester.pumpAndSettle();

          await tester.tap(find.widgetWithText(OutlinedButton, 'Stop recording'));
          await tester.pump();

          // Dispose the widget while the stop call is in flight.
          await tester.pumpWidget(const SizedBox());

          // The stop completes with a path after the widget is gone.
          fakeRecord.completeStop('/tmp/recording_after_dispose.m4a');
          await tester.pump();

          expect(changedAnswer, isNull);
          expect(
            logs.where(
              (message) => message.contains('setState() called after dispose'),
            ),
            isEmpty,
          );
        } finally {
          RecordPlatform.instance = previousPlatform;
          debugPrint = previousDebugPrint;
        }
      });
    });
  });
}
