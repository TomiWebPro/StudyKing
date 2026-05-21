import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/quickguide/presentation/widgets/message_list_widget.dart';
import 'package:studyking/features/teaching/presentation/widgets/chat_bubble.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp({
  required List<ConversationMessage> messages,
  ScrollController? scrollController,
  bool reduceMotion = false,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: SizedBox(
        width: 400,
        height: 600,
        child: MessageListWidget(
          messages: messages,
          scrollController: scrollController ?? ScrollController(),
          reduceMotion: reduceMotion,
        ),
      ),
    ),
  );
}

ConversationMessage _studentMessage({
  String content = 'Student message',
  bool isStreaming = false,
}) {
  return ConversationMessage(
    id: 'test-${content.hashCode}',
    sessionId: 'quickguide',
    role: MessageRole.student,
    type: MessageType.text,
    content: content,
    timestamp: DateTime.now(),
    isStreaming: isStreaming,
  );
}

ConversationMessage _tutorMessage({
  String content = 'Tutor message',
  bool isStreaming = false,
}) {
  return ConversationMessage(
    id: 'test-${content.hashCode}',
    sessionId: 'quickguide',
    role: MessageRole.tutor,
    type: MessageType.text,
    content: content,
    timestamp: DateTime.now(),
    isStreaming: isStreaming,
  );
}

void main() {
  group('MessageListWidget', () {
    testWidgets('renders a single student message', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        messages: [_studentMessage(content: 'What is calculus?')],
      ));
      await tester.pump();

      expect(find.text('What is calculus?'), findsOneWidget);
    });

    testWidgets('renders a single tutor message', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        messages: [_tutorMessage(content: 'Calculus is the study of change.')],
      ));
      await tester.pump();

      expect(find.text('Calculus is the study of change.'), findsOneWidget);
    });

    testWidgets('renders multiple messages in order', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        messages: [
          _studentMessage(content: 'First question'),
          _tutorMessage(content: 'First answer'),
          _studentMessage(content: 'Second question'),
          _tutorMessage(content: 'Second answer'),
        ],
      ));
      await tester.pump();

      expect(find.text('First question'), findsOneWidget);
      expect(find.text('First answer'), findsOneWidget);
      expect(find.text('Second question'), findsOneWidget);
      expect(find.text('Second answer'), findsOneWidget);
    });

    testWidgets('all messages are rendered in ListView', (tester) async {
      final messages = List.generate(
        10,
        (i) => _studentMessage(content: 'Message $i'),
      );

      await tester.pumpWidget(_buildTestApp(messages: messages));
      await tester.pump();

      for (int i = 0; i < 10; i++) {
        expect(find.text('Message $i', skipOffstage: false), findsOneWidget);
      }
    });

    testWidgets('uses provided scroll controller', (tester) async {
      final scrollController = ScrollController();

      await tester.pumpWidget(_buildTestApp(
        messages: [_studentMessage()],
        scrollController: scrollController,
      ));
      await tester.pump();

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.controller, scrollController);
    });

    testWidgets('renders ChatBubble widgets for messages', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        messages: [
          _studentMessage(content: 'Hello'),
          _tutorMessage(content: 'Hi there'),
        ],
      ));
      await tester.pump();

      expect(find.byType(ChatBubble), findsNWidgets(2));
    });

    testWidgets('passes reduceMotion to ChatBubble', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        messages: [_studentMessage(content: 'Test')],
        reduceMotion: true,
      ));
      await tester.pump();

      final chatBubble = tester.widget<ChatBubble>(find.byType(ChatBubble));
      expect(chatBubble.reduceMotion, isTrue);
    });

    testWidgets('renders nothing for empty messages list', (tester) async {
      await tester.pumpWidget(_buildTestApp(messages: []));
      await tester.pump();

      expect(find.byType(ChatBubble), findsNothing);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('renders streaming message ChatBubble', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        messages: [
          _tutorMessage(content: 'Typing...', isStreaming: true),
        ],
      ));
      await tester.pump();

      expect(find.byType(ChatBubble), findsOneWidget);
      expect(find.text('Typing...'), findsOneWidget);
    });

    testWidgets('renders mixed streaming and completed messages',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        messages: [
          _studentMessage(content: 'Hello'),
          _tutorMessage(
            content: 'Working on it...',
            isStreaming: true,
          ),
          _tutorMessage(content: 'Here is the full answer.'),
        ],
      ));
      await tester.pump();

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Working on it...'), findsOneWidget);
      expect(find.text('Here is the full answer.'), findsOneWidget);
      expect(find.byType(ChatBubble), findsNWidgets(3));
    });
  });
}
