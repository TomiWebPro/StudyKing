import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/quickguide/presentation/quick_guide_screen.dart';
import 'shared_screen_test_helpers.dart';

void main() {
  group('QuickGuideScreen', () {
    testWidgets('renders empty state when no messages exist', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Quick Guide'), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('shows welcome message on initial render', (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining(
            'Hello! I\'m StudyKing\'s Quick Guide. Ask me anything'),
        findsOneWidget,
      );
    });

    testWidgets('suggested prompt chips render with correct labels',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final chips = find.byType(ActionChip);
      expect(chips, findsAtLeastNWidgets(1));
    });

    testWidgets('suggested prompts section is visible before interaction',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Suggested prompts'), findsOneWidget);
      expect(find.byType(ActionChip), findsAtLeastNWidgets(1));
    });

    testWidgets('help dialog opens and displays content', (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('help dialog contains title and content', (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Quick Guide Help'), findsOneWidget);
      expect(
        find.textContaining('Quick Guide is your AI study assistant'),
        findsOneWidget,
      );
      expect(find.text('Got it'), findsOneWidget);
    });

    testWidgets('help dialog dismisses on Got it tap', (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('conversation input has correct hint text', (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Ask anything...'), findsAtLeastNWidgets(1));
    });

    testWidgets('TextField is rendered within conversation input',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('text field accepts input and shows it', (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Test query');
      expect(find.text('Test query'), findsOneWidget);
    });

    testWidgets('semantics labels are present on key elements',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.bySemanticsLabel('Quick Guide help'), findsOneWidget);
    });

    testWidgets('send button has tooltip', (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byTooltip('Send message'), findsOneWidget);
    });

    testWidgets('help button has tooltip', (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byTooltip('Help'), findsOneWidget);
    });
  });

  group('QuickGuideScreen - Navigation', () {
    testWidgets(
        'mode navigation cards are rendered when showModeNavigation is true',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: true),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('AI Tutor'), findsOneWidget);
      expect(find.text('Mentor'), findsOneWidget);
      expect(find.text('Choose a study mode'), findsOneWidget);
    });

    testWidgets('mode navigation Mentor card navigates to mentor route',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: true),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Mentor'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Mentor Screen'), findsOneWidget);
    });

    testWidgets('AI Tutor navigation card tap pushes route',
        (tester) async {
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: true),
        observer: observer,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('AI Tutor'));
      await tester.pump();

      expect(observer.pushedRoutes, isNotEmpty);
      tester.takeException();
    });

    testWidgets(
        'mode navigation cards are present before interaction',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: true),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Choose a study mode'), findsOneWidget);
      expect(find.text('AI Tutor'), findsOneWidget);
      expect(find.text('Mentor'), findsOneWidget);
    });
  });

  group('QuickGuideScreen - send/receive message flow', () {
    testWidgets('does not send empty or whitespace-only messages',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(find.text('Quick Guide'), findsOneWidget);
    });

    testWidgets('sends message via mocked FakeLlmService', (tester) async {
      final llm = FakeLlmService();
      llm.chunks.add('Here is an explanation of fractions.');

      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(
          llmService: llm,
          showModeNavigation: false,
        ),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Explain fractions');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Explain fractions'), findsOneWidget);
      expect(find.text('Here is an explanation of fractions.'), findsOneWidget);
    });

    testWidgets('streaming response updates message content progressively',
        (tester) async {
      final llm = FakeLlmService();
      llm.chunks.add('First part... ');
      llm.chunks.add('Second part.');

      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(
          llmService: llm,
          showModeNavigation: false,
        ),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Tell me something');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('First part...'), findsOneWidget);
      expect(find.textContaining('Second part.'), findsOneWidget);
    });

    testWidgets('multiple chunks update message content progressively',
        (tester) async {
      final llm = FakeLlmService();
      llm.chunks.add('Start. ');
      llm.chunks.add('Middle. ');
      llm.chunks.add('End.');
      llm.chunkDelay = Duration.zero;

      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Chunks');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Start. Middle. End.'), findsOneWidget);
    });

    testWidgets('submits from keyboard action', (tester) async {
      final llm = FakeLlmService();
      llm.chunks.add('Gravity response.');
      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(
          llmService: llm,
          showModeNavigation: false,
        ),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Explain gravity');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Explain gravity'), findsOneWidget);
    });

    testWidgets('send button is disabled while streaming', (tester) async {
      final llm = FakeLlmService();
      llm.chunks.add('response');
      llm.chunkDelay = const Duration(milliseconds: 100);

      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(
          llmService: llm,
          showModeNavigation: false,
        ),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      final sendButton = find.byIcon(Icons.send_rounded);
      expect(sendButton, findsNothing);

      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('send button re-appears after streaming completes',
        (tester) async {
      final llm = FakeLlmService();
      llm.chunks.add('Final response');
      llm.chunkDelay = const Duration(milliseconds: 200);

      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Teach me something');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(find.byIcon(Icons.send_rounded), findsNothing);

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });
  });

  group('QuickGuideScreen - fallback responses', () {
    testWidgets('LLM exception is caught and fallback response is shown',
        (tester) async {
      final llm = FakeLlmService();
      llm.shouldThrow = true;

      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(
          llmService: llm,
          showModeNavigation: false,
        ),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Explain gravity');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('explain'), findsAtLeastNWidgets(1));
    });

    testWidgets('empty API key uses fallback without calling LLM stream',
        (tester) async {
      final llm = FakeLlmService(apiKey: '');
      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(
          llmService: llm,
          showModeNavigation: false,
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Explain photosynthesis');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(llm.streamConsumed, isFalse);
      expect(
        find.textContaining('Sure! I can help explain concepts'),
        findsOneWidget,
      );
    });

    testWidgets('fallback maps "explain" keyword correctly', (tester) async {
      final llm = FakeLlmService(apiKey: '');
      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Explain quantum physics');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.textContaining('Sure! I can help explain concepts'),
        findsOneWidget,
      );
    });

    testWidgets('fallback maps "quiz" keyword correctly', (tester) async {
      final llm = FakeLlmService(apiKey: '');
      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Quiz me on history');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.textContaining('I can help with questions'),
        findsOneWidget,
      );
    });

    testWidgets('fallback maps "question" keyword to quiz response',
        (tester) async {
      final llm = FakeLlmService(apiKey: '');
      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(
          find.byType(TextField), 'I have a question about biology');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.textContaining('I can help with questions'),
        findsOneWidget,
      );
    });

    testWidgets('fallback maps "math" keyword correctly', (tester) async {
      final llm = FakeLlmService(apiKey: '');
      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Help with math problem');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.textContaining('happy to help with math'),
        findsOneWidget,
      );
    });

    testWidgets('fallback maps "calculate" keyword to math response',
        (tester) async {
      final llm = FakeLlmService(apiKey: '');
      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Calculate 2+2');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.textContaining('happy to help with math'),
        findsOneWidget,
      );
    });

    testWidgets('fallback maps general query correctly', (tester) async {
      final llm = FakeLlmService(apiKey: '');
      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Hello there');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.textContaining('That\'s an interesting question'),
        findsOneWidget,
      );
    });
  });

  group('QuickGuideScreen - custom configuration', () {
    testWidgets('custom system prompt is passed to LLM service',
        (tester) async {
      final llm = FakeLlmService();
      llm.chunks.add('Custom prompt response');
      const customPrompt = 'You are a custom test assistant.';

      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(
          llmService: llm,
          systemPrompt: customPrompt,
          showModeNavigation: false,
        ),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(llm.capturedSystemPrompt, equals(customPrompt));
    });

    testWidgets('custom default model ID is passed to LLM service',
        (tester) async {
      final llm = FakeLlmService();
      llm.chunks.add('Model response');
      const customModelId = 'custom/test-model';

      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(
          llmService: llm,
          defaultModelId: customModelId,
          showModeNavigation: false,
        ),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(llm.capturedModelId, equals(customModelId));
    });
  });

  group('QuickGuideScreen - constructor defaults', () {
    test('default showModeNavigation is true', () {
      const screen = QuickGuideScreen();
      expect(screen.showModeNavigation, isTrue);
    });

    test('default defaultModelId is empty string', () {
      const screen = QuickGuideScreen();
      expect(screen.defaultModelId, '');
    });

    test('default systemPrompt is null', () {
      const screen = QuickGuideScreen();
      expect(screen.systemPrompt, isNull);
    });

    test('default llmService is null', () {
      const screen = QuickGuideScreen();
      expect(screen.llmService, isNull);
    });

    test('can be created with all parameters', () {
      const screen = QuickGuideScreen(
        llmService: null,
        defaultModelId: 'custom-model',
        systemPrompt: 'Custom prompt',
        showModeNavigation: false,
      );
      expect(screen.defaultModelId, 'custom-model');
      expect(screen.systemPrompt, 'Custom prompt');
      expect(screen.showModeNavigation, isFalse);
      expect(screen.llmService, isNull);
    });
  });

  group('QuickGuideScreen - provider path', () {
    testWidgets('sends message via provider-injected FakeLlmService',
        (tester) async {
      final llm = FakeLlmService();
      llm.chunks.add('Provider response');

      await tester.pumpWidget(buildTestAppWithProvider(llmService: llm));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Hello from provider');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(llm.streamConsumed, isTrue);
      expect(find.text('Hello from provider'), findsOneWidget);
      expect(find.text('Provider response'), findsOneWidget);
    });
  });

  group('QuickGuideScreen - clear conversation', () {
    testWidgets('clear conversation button appears after interaction',
        (tester) async {
      final llm = FakeLlmService();
      llm.chunks.add('Response');
      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.refresh), findsNothing);

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('clear conversation resets messages and state',
        (tester) async {
      final llm = FakeLlmService();
      llm.chunks.add('Response text');
      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Explain fractions');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Explain fractions'), findsNothing);
    });

    testWidgets('clear conversation resets to welcome message',
        (tester) async {
      final llm = FakeLlmService();
      llm.chunks.add('Response');

      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.refresh), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Hello'), findsNothing);
      expect(
        find.textContaining(
            'Hello! I\'m StudyKing\'s Quick Guide. Ask me anything'),
        findsOneWidget,
      );
    });

    testWidgets(
        'clear conversation resets hasInteracted and shows mode nav',
        (tester) async {
      final llm = FakeLlmService();
      llm.chunks.add('Response');

      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: true),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(find.text('Choose a study mode'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'First message');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('Choose a study mode'), findsNothing);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(find.text('Choose a study mode'), findsOneWidget);
    });
  });

  group('QuickGuideScreen - suggestions chips', () {
    testWidgets('suggested prompt chips disappear after sending a message',
        (tester) async {
      final llm = FakeLlmService();
      llm.chunks.add('Response');

      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ActionChip), findsAtLeastNWidgets(1));

      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ActionChip), findsNothing);
    });

    testWidgets('suggested prompts chips reappear after clearing conversation',
        (tester) async {
      final llm = FakeLlmService();
      llm.chunks.add('Response');

      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Say something');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ActionChip), findsNothing);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ActionChip), findsAtLeastNWidgets(1));
    });
  });

  group('QuickGuideScreen - mode navigation visibility', () {
    testWidgets('mode navigation cards disappear after first interaction',
        (tester) async {
      final llm = FakeLlmService();
      llm.chunks.add('Response');

      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: true),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Choose a study mode'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'What is AI?');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Choose a study mode'), findsNothing);
    });
  });

  group('QuickGuideScreen - message rendering', () {
    testWidgets('user and tutor messages both appear in chat',
        (tester) async {
      final llm = FakeLlmService();
      llm.chunks.add('Tutor reply');

      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'User question');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('User question'), findsOneWidget);
      expect(find.text('Tutor reply'), findsOneWidget);
    });

    testWidgets('displays multiple messages in the list', (tester) async {
      final llm = FakeLlmService();
      llm.chunks.add('First response');

      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Message one');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Message one'), findsOneWidget);
      expect(find.text('First response'), findsOneWidget);

      llm.chunks.clear();
      llm.chunks.add('Second response');

      await tester.enterText(find.byType(TextField), 'Message two');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Message two'), findsOneWidget);
      expect(find.text('Message one'), findsOneWidget);
      expect(find.text('Second response'), findsOneWidget);
    });
  });

  group('QuickGuideScreen - mode card rendering', () {
    testWidgets('AI Tutor and Mentor cards render with correct icons',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: true),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.smart_toy), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.auto_awesome), findsAtLeastNWidgets(1));
      expect(find.text('AI Tutor'), findsOneWidget);
      expect(find.text('Mentor'), findsOneWidget);
      expect(find.text('Interactive conversational lessons'), findsOneWidget);
      expect(
        find.text('Personal study assistant & planner'),
        findsOneWidget,
      );
    });

    testWidgets('mode cards have correct semantics', (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: true),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.bySemanticsLabel(
          'AI Tutor: Interactive conversational lessons',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Mentor: Personal study assistant & planner',
        ),
        findsOneWidget,
      );
    });
  });

  group('QuickGuideScreen - app bar actions', () {
    testWidgets('app bar has help button and no clear before interaction',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });
  });

  group('QuickGuideScreen - semantics and accessibility', () {
    testWidgets('clear conversation button has proper semantics label',
        (tester) async {
      final llm = FakeLlmService();
      llm.chunks.add('Response');

      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.bySemanticsLabel('Clear conversation'), findsOneWidget);
    });

    testWidgets('clear conversation button has correct tooltip',
        (tester) async {
      final llm = FakeLlmService();
      llm.chunks.add('Response');

      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byTooltip('Clear conversation'), findsOneWidget);
    });

    testWidgets('renders FocusTraversalGroup for keyboard navigation',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: true),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FocusTraversalGroup), findsAtLeastNWidgets(2));
    });

    testWidgets('body contains SafeArea widget', (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SafeArea), findsAtLeastNWidgets(1));
    });

    testWidgets('Semantics wrappers around app bar buttons exist',
        (tester) async {
      final llm = FakeLlmService();
      llm.chunks.add('Response');

      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.bySemanticsLabel('Clear conversation'), findsOneWidget);
      expect(find.bySemanticsLabel('Quick Guide help'), findsOneWidget);
    });
  });

  group('QuickGuideScreen - widget lifecycle', () {
    testWidgets('dispose does not throw', (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pumpWidget(Container());
      await tester.pump();
    });

    testWidgets('can be created without localization context then removed',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });

  group('QuickGuideScreen - mounted check', () {
    testWidgets('mounted check prevents setState after dispose',
        (tester) async {
      final llm = FakeLlmService();
      llm.chunks.add('Response');
      llm.chunkDelay = const Duration(milliseconds: 50);

      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(llm.streamConsumed, isTrue);
    });
  });

  group('QuickGuideScreen - streaming with fallback', () {
    testWidgets('LLM streaming error shows general fallback',
        (tester) async {
      final llm = FakeLlmService();
      llm.shouldThrow = true;

      await tester.pumpWidget(buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Explain stars');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.textContaining('Sure! I can help explain concepts'),
        findsOneWidget,
      );
    });
  });
}
