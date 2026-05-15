import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/widgets/conversation_input.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  group('ConversationInput', () {
    testWidgets('renders text field with controller and hint', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(wrapApp(
        ConversationInput(
          controller: controller,
          hintText: 'Type a message...',
          sendTooltip: 'Send',
          onSend: () {},
        ),
      ));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Type a message...'), findsOneWidget);
    });

    testWidgets('calls onSend when send button is pressed', (tester) async {
      final controller = TextEditingController();
      bool sent = false;

      await tester.pumpWidget(wrapApp(
        ConversationInput(
          controller: controller,
          hintText: 'Message',
          sendTooltip: 'Send',
          onSend: () => sent = true,
        ),
      ));

      await tester.tap(find.byIcon(Icons.send_rounded));
      expect(sent, isTrue);
    });

    testWidgets('calls onSend when text is submitted', (tester) async {
      final controller = TextEditingController();
      bool sent = false;

      await tester.pumpWidget(wrapApp(
        ConversationInput(
          controller: controller,
          hintText: 'Message',
          sendTooltip: 'Send',
          onSend: () => sent = true,
        ),
      ));

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      expect(sent, isTrue);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(wrapApp(
        ConversationInput(
          controller: controller,
          hintText: 'Message',
          sendTooltip: 'Send',
          isLoading: true,
          onSend: () {},
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsNothing);
    });

    testWidgets('disables send button when isLoading is true', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(wrapApp(
        ConversationInput(
          controller: controller,
          hintText: 'Message',
          sendTooltip: 'Send',
          isLoading: true,
          onSend: () {},
        ),
      ));

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('disables text field when isEnabled is false', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(wrapApp(
        ConversationInput(
          controller: controller,
          hintText: 'Message',
          sendTooltip: 'Send',
          isEnabled: false,
          onSend: () {},
        ),
      ));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('disables send button when isEnabled is false', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(wrapApp(
        ConversationInput(
          controller: controller,
          hintText: 'Message',
          sendTooltip: 'Send',
          isEnabled: false,
          onSend: () {},
        ),
      ));

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('shows leading widget when provided', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(wrapApp(
        ConversationInput(
          controller: controller,
          hintText: 'Message',
          sendTooltip: 'Send',
          onSend: () {},
          leading: const Icon(Icons.attach_file),
        ),
      ));

      expect(find.byIcon(Icons.attach_file), findsOneWidget);
    });

    testWidgets('shows trailing widgets when provided instead of send button', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(wrapApp(
        ConversationInput(
          controller: controller,
          hintText: 'Message',
          sendTooltip: 'Send',
          onSend: () {},
          trailing: [
            IconButton(
              icon: const Icon(Icons.mic),
              onPressed: () {},
            ),
          ],
        ),
      ));

      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsNothing);
    });

    testWidgets('shows send button when trailing is null', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(wrapApp(
        ConversationInput(
          controller: controller,
          hintText: 'Message',
          sendTooltip: 'Send',
          onSend: () {},
        ),
      ));

      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('send button has semantics with custom tooltip', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(wrapApp(
        ConversationInput(
          controller: controller,
          hintText: 'Message',
          sendTooltip: 'Send message',
          onSend: () {},
        ),
      ));

      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
      expect(find.byTooltip('Send message'), findsOneWidget);
    });

    testWidgets('send button shows provided tooltip', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(wrapApp(
        ConversationInput(
          controller: controller,
          hintText: 'Message',
          sendTooltip: 'Send',
          onSend: () {},
        ),
      ));

      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
      expect(find.byTooltip('Send'), findsOneWidget);
    });

    testWidgets('accepts custom focusNode', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(wrapApp(
        ConversationInput(
          controller: controller,
          focusNode: focusNode,
          hintText: 'Message',
          sendTooltip: 'Send',
          onSend: () {},
        ),
      ));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode, equals(focusNode));

      focusNode.dispose();
    });

    testWidgets('text field is disabled when isLoading (even if isEnabled is true)', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(wrapApp(
        ConversationInput(
          controller: controller,
          hintText: 'Message',
          sendTooltip: 'Send',
          isLoading: true,
          isEnabled: true,
          onSend: () {},
        ),
      ));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('applies bottom padding from MediaQuery', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.only(bottom: 20),
            ),
            child: Scaffold(
              body: ConversationInput(
                controller: controller,
                hintText: 'Message',
                sendTooltip: 'Send',
                onSend: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ConversationInput), findsOneWidget);
    });
  });
}
