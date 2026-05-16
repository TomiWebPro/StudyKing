import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/presentation/widgets/voice_bar.dart';
import 'package:studyking/features/teaching/services/voice_controller.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class FakeVoiceController extends VoiceController {
  bool _fakeIsListening = false;
  final bool _fakeIsAvailable = true;
  final StreamController<String> _transcriptionCtrl =
      StreamController<String>.broadcast();

  @override
  bool get isListening => _fakeIsListening;

  @override
  bool get isAvailable => _fakeIsAvailable;

  @override
  Stream<String> get transcribedText => _transcriptionCtrl.stream;

  @override
  Future<void> startListening() async {
    _fakeIsListening = true;
  }

  @override
  Future<void> stopListening() async {
    _fakeIsListening = false;
  }

  void addTranscription(String text) {
    _transcriptionCtrl.add(text);
  }

  @override
  void dispose() {
    _transcriptionCtrl.close();
    super.dispose();
  }
}

Widget wrapApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  group('VoiceBar', () {
    late FakeVoiceController controller;
    late List<String> submitted;

    setUp(() {
      controller = FakeVoiceController();
      submitted = [];
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('shows mic_none icon when not listening', (tester) async {
      await tester.pumpWidget(wrapApp(
        VoiceBar(
          controller: controller,
          onTranscriptionSubmitted: (text) => submitted.add(text),
        ),
      ));

      expect(find.byIcon(Icons.mic_none), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);
    });

    testWidgets('press toggles listening state on controller', (tester) async {
      await tester.pumpWidget(wrapApp(
        VoiceBar(
          controller: controller,
          onTranscriptionSubmitted: (text) => submitted.add(text),
        ),
      ));

      expect(controller.isListening, isFalse);

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(controller.isListening, isTrue);
    });

    testWidgets('second press stops and submits transcription', (tester) async {
      await tester.pumpWidget(wrapApp(
        VoiceBar(
          controller: controller,
          onTranscriptionSubmitted: (text) => submitted.add(text),
        ),
      ));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      controller.addTranscription('Hello world');
      await tester.pump();

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(controller.isListening, isFalse);
      expect(submitted, ['Hello world']);
    });

    testWidgets('does not submit empty transcription on stop', (tester) async {
      await tester.pumpWidget(wrapApp(
        VoiceBar(
          controller: controller,
          onTranscriptionSubmitted: (text) => submitted.add(text),
        ),
      ));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(submitted, isEmpty);
    });

    testWidgets('shows transcription text when listening', (tester) async {
      await tester.pumpWidget(wrapApp(
        VoiceBar(
          controller: controller,
          onTranscriptionSubmitted: (text) => submitted.add(text),
        ),
      ));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      controller.addTranscription('Testing 123');
      await tester.pump();

      expect(find.text('Testing 123'), findsOneWidget);
    });

    testWidgets('shows waveform AnimatedBuilder when listening', (tester) async {
      await tester.pumpWidget(wrapApp(
        VoiceBar(
          controller: controller,
          onTranscriptionSubmitted: (text) => submitted.add(text),
        ),
      ));

      // Use the AnimatedBuilder wrapping CustomPaint as the waveform indicator
      final waveformFinder = find.byWidgetPredicate(
        (w) =>
            w is SizedBox &&
            w.width == 24 &&
            w.height == 24 &&
            w.child is AnimatedBuilder,
      );

      expect(waveformFinder, findsNothing);

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      // Trigger setState via transcription
      controller.addTranscription('');
      await tester.pump();

      expect(waveformFinder, findsOneWidget);
    });

    testWidgets('disabled state does not toggle on tap', (tester) async {
      await tester.pumpWidget(wrapApp(
        VoiceBar(
          controller: controller,
          onTranscriptionSubmitted: (text) => submitted.add(text),
          isEnabled: false,
        ),
      ));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(controller.isListening, isFalse);
    });

    testWidgets('updates transcription text when stream emits', (tester) async {
      await tester.pumpWidget(wrapApp(
        VoiceBar(
          controller: controller,
          onTranscriptionSubmitted: (text) => submitted.add(text),
        ),
      ));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      controller.addTranscription('First');
      await tester.pump();
      expect(find.text('First'), findsOneWidget);

      controller.addTranscription('Second');
      await tester.pump();
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('First'), findsNothing);
    });

    testWidgets('hides waveform AnimatedBuilder when not listening', (tester) async {
      await tester.pumpWidget(wrapApp(
        VoiceBar(
          controller: controller,
          onTranscriptionSubmitted: (text) => submitted.add(text),
        ),
      ));

      final waveformFinder = find.byWidgetPredicate(
        (w) =>
            w is SizedBox &&
            w.width == 24 &&
            w.height == 24 &&
            w.child is AnimatedBuilder,
      );

      expect(waveformFinder, findsNothing);

      await tester.tap(find.byType(IconButton));
      await tester.pump();
      controller.addTranscription('');
      await tester.pump();

      expect(waveformFinder, findsOneWidget);

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      // Emit transcription to trigger setState for rebuild
      controller.addTranscription('');
      await tester.pump();

      expect(waveformFinder, findsNothing);
    });

    testWidgets('shows mic icon when listening after transcription triggers setState', (tester) async {
      await tester.pumpWidget(wrapApp(
        VoiceBar(
          controller: controller,
          onTranscriptionSubmitted: (text) => submitted.add(text),
        ),
      ));

      expect(find.byIcon(Icons.mic_none), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      // _toggleListening doesn't call setState, so emit transcription to trigger rebuild
      controller.addTranscription('');
      await tester.pump();

      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.mic_none), findsNothing);
    });
  });
}
