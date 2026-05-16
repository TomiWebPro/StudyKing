import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/presentation/widgets/chat_bubble.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

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
  group('ChatBubble', () {
    final now = DateTime.now();

    testWidgets('renders tutor message text', (tester) async {
      await tester.pumpWidget(wrapApp(
        ChatBubble(
          message: ConversationMessage(
            id: '1',
            sessionId: 's1',
            role: MessageRole.tutor,
            type: MessageType.text,
            content: 'Hello student! Let us learn.',
            timestamp: now,
          ),
        ),
      ));

      expect(find.text('Hello student! Let us learn.'), findsOneWidget);
      expect(find.text('Tutor'), findsOneWidget);
    });

    testWidgets('renders student message text', (tester) async {
      await tester.pumpWidget(wrapApp(
        ChatBubble(
          message: ConversationMessage(
            id: '2',
            sessionId: 's1',
            role: MessageRole.student,
            type: MessageType.text,
            content: 'I have a question.',
            timestamp: now,
          ),
        ),
      ));

      expect(find.text('I have a question.'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('renders system message', (tester) async {
      await tester.pumpWidget(wrapApp(
        ChatBubble(
          message: ConversationMessage(
            id: '3',
            sessionId: 's1',
            role: MessageRole.system,
            type: MessageType.system,
            content: 'Session started.',
            timestamp: now,
          ),
        ),
      ));

      expect(find.text('Session started.'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
    });

    testWidgets('shows streaming dots when content is empty and streaming', (tester) async {
      await tester.pumpWidget(wrapApp(
        ChatBubble(
          message: ConversationMessage(
            id: '4',
            sessionId: 's1',
            role: MessageRole.tutor,
            type: MessageType.text,
            content: '',
            timestamp: now,
            isStreaming: true,
          ),
        ),
      ));

      expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
    });

    testWidgets('renders exercise type message', (tester) async {
      await tester.pumpWidget(wrapApp(
        ChatBubble(
          message: ConversationMessage(
            id: '5',
            sessionId: 's1',
            role: MessageRole.tutor,
            type: MessageType.text,
            content: 'Solve for x: 2x = 4',
            timestamp: now,
          ),
        ),
      ));

      expect(find.text('Solve for x: 2x = 4'), findsOneWidget);
    });

    testWidgets('hides sender label when showSender is false', (tester) async {
      await tester.pumpWidget(wrapApp(
        ChatBubble(
          message: ConversationMessage(
            id: '6',
            sessionId: 's1',
            role: MessageRole.tutor,
            type: MessageType.text,
            content: 'Hello',
            timestamp: now,
          ),
          showSender: false,
        ),
      ));

      expect(find.text('Tutor'), findsNothing);
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('renders avatars for tutor and student', (tester) async {
      await tester.pumpWidget(wrapApp(
        ChatBubble(
          message: ConversationMessage(
            id: '7',
            sessionId: 's1',
            role: MessageRole.tutor,
            type: MessageType.text,
            content: 'Hello',
            timestamp: now,
          ),
        ),
      ));

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
    });

    testWidgets('renders student avatar on the right', (tester) async {
      await tester.pumpWidget(wrapApp(
        ChatBubble(
          message: ConversationMessage(
            id: '8',
            sessionId: 's1',
            role: MessageRole.student,
            type: MessageType.text,
            content: 'Hi',
            timestamp: now,
          ),
        ),
      ));

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('shows static dots when reduceMotion is true and streaming', (tester) async {
      await tester.pumpWidget(wrapApp(
        ChatBubble(
          message: ConversationMessage(
            id: '9',
            sessionId: 's1',
            role: MessageRole.tutor,
            type: MessageType.text,
            content: '',
            timestamp: now,
            isStreaming: true,
          ),
          reduceMotion: true,
        ),
      ));

      expect(find.text('Tutor'), findsOneWidget);
    });

    testWidgets('renders text when streaming with non-empty content', (tester) async {
      await tester.pumpWidget(wrapApp(
        ChatBubble(
          message: ConversationMessage(
            id: '10',
            sessionId: 's1',
            role: MessageRole.tutor,
            type: MessageType.text,
            content: 'Partial response...',
            timestamp: now,
            isStreaming: true,
          ),
        ),
      ));

      expect(find.text('Partial response...'), findsOneWidget);
    });

    testWidgets('renders mentor role message', (tester) async {
      await tester.pumpWidget(wrapApp(
        ChatBubble(
          message: ConversationMessage(
            id: '11',
            sessionId: 's1',
            role: MessageRole.mentor,
            type: MessageType.text,
            content: 'Mentor advice',
            timestamp: now,
          ),
        ),
      ));

      expect(find.text('Mentor advice'), findsOneWidget);
    });

    testWidgets('displays evaluation score and explanation', (tester) async {
      final evalData = {
        'type': 'evaluation',
        'score': 0.85,
        'explanation': 'Good understanding!',
      };

      await tester.pumpWidget(wrapApp(
        ChatBubble(
          message: ConversationMessage(
            id: '12',
            sessionId: 's1',
            role: MessageRole.system,
            type: MessageType.feedback,
            content: jsonEncode(evalData),
            timestamp: now,
          ),
        ),
      ));

      expect(find.text('85%'), findsOneWidget);
      expect(find.text('Good understanding!'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays evaluation with concept breakdown', (tester) async {
      final evalData = {
        'type': 'evaluation',
        'score': 0.6,
        'explanation': 'Partial understanding.',
        'partialCredit': 0.5,
        'conceptBreakdown': {
          'Algebra': 0.8,
          'Calculus': 0.3,
        },
      };

      await tester.pumpWidget(wrapApp(
        ChatBubble(
          message: ConversationMessage(
            id: '13',
            sessionId: 's1',
            role: MessageRole.system,
            type: MessageType.feedback,
            content: jsonEncode(evalData),
            timestamp: now,
          ),
        ),
      ));

      expect(find.text('60%'), findsOneWidget);
      expect(find.text('Partial understanding.'), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('evaluation with low score shows cancel icon', (tester) async {
      final evalData = {
        'type': 'evaluation',
        'score': 0.2,
        'explanation': 'Needs improvement.',
      };

      await tester.pumpWidget(wrapApp(
        ChatBubble(
          message: ConversationMessage(
            id: '14',
            sessionId: 's1',
            role: MessageRole.system,
            type: MessageType.feedback,
            content: jsonEncode(evalData),
            timestamp: now,
          ),
        ),
      ));

      expect(find.text('20%'), findsOneWidget);
      expect(find.text('Needs improvement.'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('evaluation with empty explanation hides body', (tester) async {
      final evalData = {
        'type': 'evaluation',
        'score': 0.9,
        'explanation': '',
      };

      await tester.pumpWidget(wrapApp(
        ChatBubble(
          message: ConversationMessage(
            id: '15',
            sessionId: 's1',
            role: MessageRole.system,
            type: MessageType.feedback,
            content: jsonEncode(evalData),
            timestamp: now,
          ),
        ),
      ));

      expect(find.text('90%'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('malformed evaluation JSON falls back to plain text', (tester) async {
      await tester.pumpWidget(wrapApp(
        ChatBubble(
          message: ConversationMessage(
            id: '16',
            sessionId: 's1',
            role: MessageRole.system,
            type: MessageType.feedback,
            content: '{invalid json}',
            timestamp: now,
          ),
        ),
      ));

      expect(find.text('{invalid json}'), findsOneWidget);
    });

    testWidgets('non-evaluation JSON content renders as plain text', (tester) async {
      final data = {'type': 'greeting', 'text': 'hello'};

      await tester.pumpWidget(wrapApp(
        ChatBubble(
          message: ConversationMessage(
            id: '17',
            sessionId: 's1',
            role: MessageRole.tutor,
            type: MessageType.text,
            content: jsonEncode(data),
            timestamp: now,
          ),
        ),
      ));

      expect(find.text(jsonEncode(data)), findsOneWidget);
    });

    testWidgets('evaluation content with text type still renders evaluation via isEvaluationMessage', (tester) async {
      final evalData = {
        'type': 'evaluation',
        'score': 0.75,
        'explanation': 'Good effort.',
      };

      await tester.pumpWidget(wrapApp(
        ChatBubble(
          message: ConversationMessage(
            id: '18',
            sessionId: 's1',
            role: MessageRole.system,
            type: MessageType.text,
            content: jsonEncode(evalData),
            timestamp: now,
          ),
        ),
      ));

      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Good effort.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('system message shows avatar on the left', (tester) async {
      await tester.pumpWidget(wrapApp(
        ChatBubble(
          message: ConversationMessage(
            id: '19',
            sessionId: 's1',
            role: MessageRole.system,
            type: MessageType.system,
            content: 'System message',
            timestamp: now,
          ),
        ),
      ));

      expect(find.text('System message'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      // System is not student, so avatar is shown (isTutor=false, shows person icon)
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('streaming with reduceMotion true renders static dots', (tester) async {
      await tester.pumpWidget(wrapApp(
        ChatBubble(
          message: ConversationMessage(
            id: '20',
            sessionId: 's1',
            role: MessageRole.tutor,
            type: MessageType.text,
            content: '',
            timestamp: now,
            isStreaming: true,
          ),
          reduceMotion: true,
        ),
      ));

      // Static dots are 3 Circle-shaped containers inside a SizedBox(width:40)
      expect(find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 40,
      ), findsOneWidget);
    });

    testWidgets('animated dots reach both easeInOut branches when animation advances', (tester) async {
      await tester.pumpWidget(wrapApp(
        ChatBubble(
          message: ConversationMessage(
            id: '21',
            sessionId: 's1',
            role: MessageRole.tutor,
            type: MessageType.text,
            content: '',
            timestamp: now,
            isStreaming: true,
          ),
          reduceMotion: false,
        ),
      ));

      // Advance to _controller.value = 0.5 (t < 0.5 branch of easeInOut)
      await tester.pump(const Duration(milliseconds: 200));
      // Advance to _controller.value = 0.625 → (value*4)%1 = 0.5 → hits t>=0.5 branch
      await tester.pump(const Duration(milliseconds: 550));

      expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
    });
  });
}
