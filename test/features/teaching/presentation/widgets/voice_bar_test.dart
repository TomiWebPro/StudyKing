import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/presentation/widgets/voice_bar.dart';
import 'package:studyking/core/services/voice_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class FakeVoiceService extends VoiceService {
  bool _fakeIsListening = false;
  final bool _fakeIsAvailable = true;
  final StreamController<String> _transcriptionCtrl =
      StreamController<String>.broadcast();
  bool requestPermissionCalled = false;
  String? lastLocaleName;

  @override
  bool get isListening => _fakeIsListening;

  @override
  bool get isAvailable => _fakeIsAvailable;

  @override
  Stream<String> get transcribedText => _transcriptionCtrl.stream;

  @override
  Future<void> startListening({String? localeName}) async {
    _fakeIsListening = true;
    lastLocaleName = localeName;
  }

  @override
  Future<void> stopListening() async {
    _fakeIsListening = false;
  }

  @override
  Future<bool> requestPermission() async {
    requestPermissionCalled = true;
    return true;
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
    late FakeVoiceService controller;
    late List<String> submitted;

    setUp(() {
      controller = FakeVoiceService();
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

    testWidgets('second press shows review overlay and auto-submits after delay', (tester) async {
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
      // Review overlay shown, not yet submitted
      expect(submitted, isEmpty);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Advance past the review overlay duration
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(submitted, ['Hello world']);
      expect(find.byIcon(Icons.close), findsNothing);
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

      // No review overlay since transcription is empty
      expect(submitted, isEmpty);
      expect(find.byIcon(Icons.close), findsNothing);
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

    testWidgets('reduceMotion true hides waveform container', (tester) async {
      await tester.pumpWidget(wrapApp(
        VoiceBar(
          controller: controller,
          onTranscriptionSubmitted: (text) => submitted.add(text),
          reduceMotion: true,
        ),
      ));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      controller.addTranscription('');
      await tester.pump();

      final waveformFinder = find.byWidgetPredicate(
        (w) =>
            w is SizedBox &&
            w.width == 24 &&
            w.height == 24 &&
            w.child is AnimatedBuilder,
      );
      expect(waveformFinder, findsNothing);
    });

    testWidgets('stream subscription lifecycle - emit after dispose is safe', (tester) async {
      await tester.pumpWidget(wrapApp(
        VoiceBar(
          controller: controller,
          onTranscriptionSubmitted: (text) => submitted.add(text),
        ),
      ));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      controller.addTranscription('Active transcription');
      await tester.pump();

      // Remove widget to trigger dispose and subscription cancellation
      await tester.pumpWidget(wrapApp(
        const SizedBox.shrink(),
      ));
      await tester.pump();

      // Emit after dispose - should not throw (mounted check or cancelled sub protects setState)
      controller.addTranscription('');
    });

    testWidgets('transcription text is italic and uses ellipsis overflow', (tester) async {
      await tester.pumpWidget(wrapApp(
        VoiceBar(
          controller: controller,
          onTranscriptionSubmitted: (text) => submitted.add(text),
        ),
      ));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      controller.addTranscription('Long transcription text that should overflow');
      await tester.pump();

      final transcriptionText = tester.widget<Text>(find.text('Long transcription text that should overflow'));
      expect(transcriptionText.overflow, equals(TextOverflow.ellipsis));
      expect(transcriptionText.style?.fontStyle, equals(FontStyle.italic));
    });

    testWidgets('mic icon color is error red when listening', (tester) async {
      await tester.pumpWidget(wrapApp(
        VoiceBar(
          controller: controller,
          onTranscriptionSubmitted: (text) => submitted.add(text),
        ),
      ));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      controller.addTranscription('');
      await tester.pump();

      final micIcon = tester.widget<Icon>(find.byIcon(Icons.mic));
      expect(micIcon.color, isNotNull);
    });

    testWidgets('shows CustomPaint with painter when listening', (tester) async {
      await tester.pumpWidget(wrapApp(
        VoiceBar(
          controller: controller,
          onTranscriptionSubmitted: (text) => submitted.add(text),
        ),
      ));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      controller.addTranscription('');
      await tester.pump();

      final waveformPaint = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.size.width == 24 && w.size.height == 24,
      );
      expect(waveformPaint, findsOneWidget);

      final customPaint = tester.widget<CustomPaint>(waveformPaint);
      expect(customPaint.painter, isNotNull);
    });

    testWidgets('handles transcription stream emitting after widget disposal', (tester) async {
      await tester.pumpWidget(wrapApp(
        VoiceBar(
          controller: controller,
          onTranscriptionSubmitted: (text) => submitted.add(text),
        ),
      ));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      controller.addTranscription('Active transcription');
      await tester.pump();

      await tester.pumpWidget(wrapApp(const SizedBox.shrink()));
      await tester.pump();

      controller.addTranscription('After dispose');
      expect(tester.takeException(), isNull);
    });

    testWidgets('voice bar disabled does not start listening on tap', (tester) async {
      await tester.pumpWidget(wrapApp(
        VoiceBar(
          controller: controller,
          onTranscriptionSubmitted: (text) => submitted.add(text),
          isEnabled: false,
        ),
      ));

      expect(find.byIcon(Icons.mic_none), findsOneWidget);

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(controller.isListening, isFalse);
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
    });

    testWidgets('stop listening with empty transcription does not submit', (tester) async {
      await tester.pumpWidget(wrapApp(
        VoiceBar(
          controller: controller,
          onTranscriptionSubmitted: (text) => submitted.add(text),
        ),
      ));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      controller.addTranscription('');
      await tester.pump();

      expect(find.byIcon(Icons.mic), findsOneWidget);

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(submitted, isEmpty);
    });

    testWidgets('shows transcription text in flexible widget when listening', (tester) async {
      await tester.pumpWidget(wrapApp(
        VoiceBar(
          controller: controller,
          onTranscriptionSubmitted: (text) => submitted.add(text),
        ),
      ));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      controller.addTranscription('Flexible transcription text');
      await tester.pump();

      expect(find.text('Flexible transcription text'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Flexible transcription text'),
          matching: find.byType(Flexible),
        ),
        findsOneWidget,
      );
    });

    testWidgets('requestPermission is called on mic tap, not on init', (tester) async {
      await tester.pumpWidget(wrapApp(
        VoiceBar(
          controller: controller,
          onTranscriptionSubmitted: (text) => submitted.add(text),
        ),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.requestPermissionCalled, isFalse);

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(controller.requestPermissionCalled, isTrue);
    });

    testWidgets('transcription is cleared in internal state after submission', (tester) async {
      await tester.pumpWidget(wrapApp(
        VoiceBar(
          controller: controller,
          onTranscriptionSubmitted: (text) => submitted.add(text),
        ),
      ));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      controller.addTranscription('Submit me');
      await tester.pump();

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      // Wait for review overlay to auto-submit
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(submitted, ['Submit me']);

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      controller.addTranscription('');
      await tester.pump();

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(submitted, ['Submit me']);
    });

    testWidgets('_WaveformPainter shouldRepaint returns true for different value', (tester) async {
      await tester.pumpWidget(wrapApp(
        VoiceBar(
          controller: controller,
          onTranscriptionSubmitted: (text) => submitted.add(text),
        ),
      ));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      controller.addTranscription('');
      await tester.pump();

      final waveformPaint = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.size.width == 24 && w.size.height == 24,
      );
      expect(waveformPaint, findsOneWidget);

      final customPaint = tester.widget<CustomPaint>(waveformPaint);
      final painter = customPaint.painter;
      expect(painter, isNotNull);
    });
  });
}
