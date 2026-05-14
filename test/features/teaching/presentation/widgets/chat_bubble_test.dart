import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/conversation_message_model.dart';
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

    testWidgets('shows exercise type label', (tester) async {
      await tester.pumpWidget(wrapApp(
        ChatBubble(
          message: ConversationMessage(
            id: '5',
            sessionId: 's1',
            role: MessageRole.tutor,
            type: MessageType.exercise,
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
  });
}
