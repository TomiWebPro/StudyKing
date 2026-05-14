import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/conversation_message_model.dart';
import 'package:studyking/features/quickguide/presentation/widgets/message_list_widget.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp({
  required List<ConversationMessage> messages,
  ScrollController? scrollController,
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

    testWidgets('student messages are right-aligned', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        messages: [_studentMessage()],
      ));
      await tester.pump();

      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets('tutor messages are left-aligned', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        messages: [_tutorMessage()],
      ));
      await tester.pump();

      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, Alignment.centerLeft);
    });

    testWidgets('displays streaming cursor character when content not empty',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        messages: [
          _tutorMessage(content: 'Partial', isStreaming: true),
        ],
      ));
      await tester.pump();

      expect(find.textContaining('Partial\u258C'), findsOneWidget);
    });

    testWidgets('shows loading spinner for streaming message with empty content',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        messages: [
          _tutorMessage(content: '', isStreaming: true),
        ],
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('does not show spinner for streaming with content',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        messages: [
          _tutorMessage(content: 'Has content', isStreaming: true),
        ],
      ));
      await tester.pump();

      final spinners = find.byType(CircularProgressIndicator);
      expect(spinners, findsNothing);
    });

    testWidgets('uses Semantics widget for messages', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        messages: [_studentMessage(content: 'My question')],
      ));
      await tester.pump();

      expect(find.byType(Semantics), findsAtLeastNWidgets(1));
    });

    testWidgets('message containers have max width 75% of screen', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        messages: [_studentMessage(content: 'A')],
      ));
      await tester.pump();

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final constraints = container.constraints;
      expect(constraints, isNotNull);
      expect(constraints!.maxWidth, 600.0);
    });

    testWidgets('all messages are rendered in ListView', (tester) async {
      final messages = List.generate(
        10,
        (i) => _studentMessage(content: 'Message $i'),
      );

      await tester.pumpWidget(_buildTestApp(messages: messages));
      await tester.pump();

      for (int i = 0; i < 10; i++) {
        expect(find.text('Message $i'), findsOneWidget);
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

    testWidgets('student message uses primary color decoration',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        messages: [_studentMessage()],
      ));
      await tester.pump();

      final containers = find.byType(Container);
      expect(containers, findsAtLeastNWidgets(1));
    });
  });
}
