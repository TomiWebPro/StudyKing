import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/quickguide/presentation/widgets/message_composer_widget.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp({
  required MessageComposerWidget composer,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: composer),
  );
}

void main() {
  group('MessageComposerWidget', () {
    testWidgets('renders text field and send button', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(_buildTestApp(
        composer: MessageComposerWidget(
          controller: controller,
          focusNode: focusNode,
          isStreaming: false,
          onSend: () {},
        ),
      ));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.text('Ask anything...'), findsOneWidget);

      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('hint text shows Type your question here', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(_buildTestApp(
        composer: MessageComposerWidget(
          controller: controller,
          focusNode: focusNode,
          isStreaming: false,
          onSend: () {},
        ),
      ));
      await tester.pump();

      expect(find.text('Ask anything...'), findsOneWidget);

      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('shows CircularProgressIndicator when streaming', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(_buildTestApp(
        composer: MessageComposerWidget(
          controller: controller,
          focusNode: focusNode,
          isStreaming: true,
          onSend: () {},
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.send), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('send button is disabled while streaming', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      await tester.pumpWidget(_buildTestApp(
        composer: MessageComposerWidget(
          controller: controller,
          focusNode: focusNode,
          isStreaming: true,
          onSend: () {},
        ),
      ));
      await tester.pump();

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.onPressed, isNull);

      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('onSend is called when send button is tapped', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      bool sent = false;

      await tester.pumpWidget(_buildTestApp(
        composer: MessageComposerWidget(
          controller: controller,
          focusNode: focusNode,
          isStreaming: false,
          onSend: () => sent = true,
        ),
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send));
      expect(sent, isTrue);

      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('text field accepts input', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(_buildTestApp(
        composer: MessageComposerWidget(
          controller: controller,
          focusNode: focusNode,
          isStreaming: false,
          onSend: () {},
        ),
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Hello');
      expect(controller.text, 'Hello');

      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('text field max lines is 4', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(_buildTestApp(
        composer: MessageComposerWidget(
          controller: controller,
          focusNode: focusNode,
          isStreaming: false,
          onSend: () {},
        ),
      ));
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLines, 4);

      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('text input action is send', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(_buildTestApp(
        composer: MessageComposerWidget(
          controller: controller,
          focusNode: focusNode,
          isStreaming: false,
          onSend: () {},
        ),
      ));
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.textInputAction, TextInputAction.send);

      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('onSubmit calls onSend', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      bool sent = false;

      await tester.pumpWidget(_buildTestApp(
        composer: MessageComposerWidget(
          controller: controller,
          focusNode: focusNode,
          isStreaming: false,
          onSend: () => sent = true,
        ),
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Test');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      expect(sent, isTrue);

      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('has Semantics widget for message input', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(_buildTestApp(
        composer: MessageComposerWidget(
          controller: controller,
          focusNode: focusNode,
          isStreaming: false,
          onSend: () {},
        ),
      ));
      await tester.pump();

      expect(find.byType(Semantics), findsAtLeastNWidgets(1));

      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('send button has semantics and tooltip', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(_buildTestApp(
        composer: MessageComposerWidget(
          controller: controller,
          focusNode: focusNode,
          isStreaming: false,
          onSend: () {},
        ),
      ));
      await tester.pump();

      expect(find.byTooltip('Send message'), findsOneWidget);

      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('send button has filled style', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(_buildTestApp(
        composer: MessageComposerWidget(
          controller: controller,
          focusNode: focusNode,
          isStreaming: false,
          onSend: () {},
        ),
      ));
      await tester.pump();

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button, isA<IconButton>());

      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('switches from send icon to spinner when streaming changes',
        (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(_buildTestApp(
        composer: MessageComposerWidget(
          controller: controller,
          focusNode: focusNode,
          isStreaming: false,
          onSend: () {},
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.send), findsOneWidget);

      await tester.pumpWidget(_buildTestApp(
        composer: MessageComposerWidget(
          controller: controller,
          focusNode: focusNode,
          isStreaming: true,
          onSend: () {},
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.send), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('send button is disabled (null onPressed) when streaming',
        (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      await tester.pumpWidget(_buildTestApp(
        composer: MessageComposerWidget(
          controller: controller,
          focusNode: focusNode,
          isStreaming: true,
          onSend: () {},
        ),
      ));
      await tester.pump();

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.onPressed, isNull);

      controller.dispose();
      focusNode.dispose();
    });
  });
}
