import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/presentation/widgets/chat_bubble.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'mentor_screen_test_helpers.dart';

class SpeakingFakeVoiceService extends FakeVoiceService {
  final List<String> spokenTexts = [];
  String? lastLocaleName;

  SpeakingFakeVoiceService() : super(available: true);

  @override
  Future<void> speak(String text, {String? localeName}) async {
    spokenTexts.add(text);
    lastLocaleName = localeName;
  }

  @override
  Future<void> stopSpeaking() async {
    // no-op for testing
  }
}

void main() {
  group('MentorScreen - Voice Output (TTS)', () {
    testWidgets('voice output toggle button appears in app bar after initialization',
        (tester) async {
      await tester.pumpWidget(
        buildMentorTestApp(voiceService: SpeakingFakeVoiceService()),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.volume_off),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping voice output toggle enables it, showing volume_up icon',
        (tester) async {
      await tester.pumpWidget(
        buildMentorTestApp(voiceService: SpeakingFakeVoiceService()),
      );
      await tester.pumpAndSettle();

      final appBarFinder = find.byType(AppBar);

      // Initially disabled: volume_off in AppBar
      expect(
        find.descendant(of: appBarFinder, matching: find.byIcon(Icons.volume_off)),
        findsOneWidget,
      );

      // Toggle on
      await tester.tap(
        find.descendant(of: appBarFinder, matching: find.byIcon(Icons.volume_off)),
      );
      await tester.pump();

      // Now enabled: volume_up in AppBar
      expect(
        find.descendant(of: appBarFinder, matching: find.byIcon(Icons.volume_up)),
        findsOneWidget,
      );
    });

    testWidgets('mentor response bubble shows speaker icon when voice output enabled',
        (tester) async {
      await tester.pumpWidget(
        buildMentorTestApp(voiceService: SpeakingFakeVoiceService()),
      );
      await tester.pumpAndSettle();

      // Enable voice output via AppBar toggle
      final appBarFinder = find.byType(AppBar);
      await tester.tap(
        find.descendant(of: appBarFinder, matching: find.byIcon(Icons.volume_off)),
      );
      await tester.pump();

      // Send a message and pump to allow rendering
      await tester.enterText(find.byType(TextField), 'Hello mentor');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));

      // Wait for the mentor response and let the async chain complete
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('Mentor response').evaluate().isNotEmpty) break;
      }
      // Additional pumps to let chat() stream fully complete and final setState apply
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // The mentor response ChatBubble should show a speaker icon
      final speakerInBubble = find.descendant(
        of: find.byType(ChatBubble),
        matching: find.byIcon(Icons.volume_up),
      );
      expect(speakerInBubble, findsWidgets);
    });

    testWidgets('tapping speaker icon on mentor bubble invokes VoiceService.speak',
        (tester) async {
      final voiceService = SpeakingFakeVoiceService();
      await tester.pumpWidget(
        buildMentorTestApp(voiceService: voiceService),
      );
      await tester.pumpAndSettle();

      // Enable voice output via AppBar toggle
      final appBarFinder = find.byType(AppBar);
      await tester.tap(
        find.descendant(of: appBarFinder, matching: find.byIcon(Icons.volume_off)),
      );
      await tester.pump();

      // Send a message and wait for completion
      await tester.enterText(find.byType(TextField), 'Hello mentor');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('Mentor response').evaluate().isNotEmpty) break;
      }
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Find ChatBubble widgets and locate mentor bubbles with onSpeak
      final bubbles = tester.widgetList<ChatBubble>(find.byType(ChatBubble));
      final mentorBubblesWithSpeak = bubbles.where(
        (b) => b.message.role == MessageRole.mentor &&
            b.onSpeak != null &&
            b.message.content.isNotEmpty &&
            !b.message.isStreaming,
      );
      expect(mentorBubblesWithSpeak, isNotEmpty,
          reason: 'Mentor ChatBubbles should have onSpeak set when voice output is enabled');

      // Collect the content of bubbles whose onSpeak we will invoke
      final expectedTexts =
          mentorBubblesWithSpeak.map((b) => b.message.content).toSet();

      // Invoke the onSpeak callback directly (as the IconButton.onPressed would)
      for (final bubble in mentorBubblesWithSpeak) {
        bubble.onSpeak!();
      }
      await tester.pump();

      // Verify speak was called with content from a mentor bubble whose onSpeak was invoked
      expect(voiceService.spokenTexts, isNotEmpty);
      expect(voiceService.spokenTexts.any(expectedTexts.contains), isTrue,
          reason: 'spokenTexts should contain content from a mentor bubble '
              'whose onSpeak callback was invoked');
    });

    testWidgets('no speaker icon on mentor bubble when voice output disabled',
        (tester) async {
      await tester.pumpWidget(
        buildMentorTestApp(voiceService: SpeakingFakeVoiceService()),
      );
      await tester.pumpAndSettle();

      // Send a message and wait for completion
      await tester.enterText(find.byType(TextField), 'Hello mentor');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('Mentor response').evaluate().isNotEmpty) break;
      }
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // No speaker icon should be present on any ChatBubble
      final speakerInBubble = find.descendant(
        of: find.byType(ChatBubble),
        matching: find.byIcon(Icons.volume_up),
      );
      expect(speakerInBubble, findsNothing);

      // AppBar should still show volume_off
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.volume_off),
        ),
        findsOneWidget,
      );
    });

    testWidgets('student message bubble has no onSpeak callback', (tester) async {
      final voiceService = SpeakingFakeVoiceService();
      await tester.pumpWidget(
        buildMentorTestApp(voiceService: voiceService),
      );
      await tester.pumpAndSettle();

      // Enable voice output
      final appBarFinder = find.byType(AppBar);
      await tester.tap(
        find.descendant(of: appBarFinder, matching: find.byIcon(Icons.volume_off)),
      );
      await tester.pump();

      // Send a message and wait for completion
      await tester.enterText(find.byType(TextField), 'Hello mentor');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('Mentor response').evaluate().isNotEmpty) break;
      }
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Find ChatBubble widgets
      final bubbles = tester.widgetList<ChatBubble>(find.byType(ChatBubble));
      final studentBubbles = bubbles.where(
        (b) => b.message.role == MessageRole.student,
      );
      expect(studentBubbles, isNotEmpty, reason: 'Student message should be rendered');

      // Student bubbles should NOT have onSpeak set
      for (final bubble in studentBubbles) {
        expect(bubble.onSpeak, isNull,
            reason: 'Student ChatBubble should not have onSpeak callback');
      }

      // Mentor bubbles with non-empty content should have onSpeak set
      final mentorBubbles = bubbles.where(
        (b) => b.message.role == MessageRole.mentor &&
            b.message.content.isNotEmpty &&
            !b.message.isStreaming,
      );
      expect(mentorBubbles, isNotEmpty, reason: 'Mentor messages should be rendered');
      for (final bubble in mentorBubbles) {
        expect(bubble.onSpeak, isNotNull,
            reason: 'Mentor ChatBubble should have onSpeak when voice output is enabled');
      }
    });

    testWidgets('disabling voice output removes onSpeak from mentor bubbles',
        (tester) async {
      await tester.pumpWidget(
        buildMentorTestApp(voiceService: SpeakingFakeVoiceService()),
      );
      await tester.pumpAndSettle();

      // Enable voice output
      final appBarFinder = find.byType(AppBar);
      await tester.tap(
        find.descendant(of: appBarFinder, matching: find.byIcon(Icons.volume_off)),
      );
      await tester.pump();

      // Send a message and wait for completion
      await tester.enterText(find.byType(TextField), 'Hello mentor');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('Mentor response').evaluate().isNotEmpty) break;
      }
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Verify onSpeak is set while enabled
      var bubbles = tester.widgetList<ChatBubble>(find.byType(ChatBubble));
      var mentorBubbles = bubbles.where(
        (b) => b.message.role == MessageRole.mentor &&
            b.message.content.isNotEmpty &&
            !b.message.isStreaming,
      );
      expect(mentorBubbles, isNotEmpty);
      for (final bubble in mentorBubbles) {
        expect(bubble.onSpeak, isNotNull);
      }

      // Disable voice output
      await tester.tap(
        find.descendant(of: appBarFinder, matching: find.byIcon(Icons.volume_up)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify onSpeak is now null
      bubbles = tester.widgetList<ChatBubble>(find.byType(ChatBubble));
      mentorBubbles = bubbles.where(
        (b) => b.message.role == MessageRole.mentor &&
            b.message.content.isNotEmpty &&
            !b.message.isStreaming,
      );
      expect(mentorBubbles, isNotEmpty);
      for (final bubble in mentorBubbles) {
        expect(bubble.onSpeak, isNull,
            reason: 'Mentor ChatBubble should not have onSpeak when voice output is disabled');
      }

      // AppBar should show volume_off again
      expect(
        find.descendant(of: appBarFinder, matching: find.byIcon(Icons.volume_off)),
        findsOneWidget,
      );
    });
  });
}
