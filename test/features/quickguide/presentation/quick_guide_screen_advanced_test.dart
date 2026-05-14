import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/quickguide/presentation/quick_guide_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeLlmService extends LlmService {
  bool shouldThrow = false;
  final List<String> chunks = [];
  bool streamConsumed = false;
  Duration chunkDelay = Duration.zero;
  String? capturedSystemPrompt;
  String? capturedModelId;

  _FakeLlmService({String apiKey = 'fake-key-for-testing'})
      : super(
          config: LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: apiKey,
          ),
        );

  @override
  Stream<String> chatStream({
    required String message,
    required String modelId,
    String? systemPrompt,
    ConversationMemory? memory,
    List<Map<String, String>>? history,
  }) async* {
    if (shouldThrow) throw Exception('Simulated LLM error');
    capturedSystemPrompt = systemPrompt;
    capturedModelId = modelId;
    for (final chunk in chunks) {
      await Future<void>.delayed(chunkDelay);
      yield chunk;
    }
    streamConsumed = true;
  }
}

class _TestNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
  }
}

Widget _buildTestApp({
  QuickGuideScreen? screen,
  NavigatorObserver? observer,
  LlmService? llmService,
}) {
  final overrides = <Override>[];
  if (llmService != null) {
    overrides.add(llmServiceProvider.overrideWith((ref) => llmService));
  }
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: observer != null ? [observer] : [],
      routes: {
        '/mentor': (_) => const Scaffold(
              body: Center(child: Text('Mentor Screen')),
            ),
      },
      home: screen ?? const QuickGuideScreen(showModeNavigation: false),
    ),
  );
}

void main() {
  group('QuickGuideScreen - fallback responses via empty API key', () {
    testWidgets('empty API key uses fallback without calling LLM stream',
        (tester) async {
      final llm = _FakeLlmService(apiKey: '');
      await tester.pumpWidget(_buildTestApp(
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
      final llm = _FakeLlmService(apiKey: '');
      await tester.pumpWidget(_buildTestApp(
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
      final llm = _FakeLlmService(apiKey: '');
      await tester.pumpWidget(_buildTestApp(
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
      final llm = _FakeLlmService(apiKey: '');
      await tester.pumpWidget(_buildTestApp(
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
      final llm = _FakeLlmService(apiKey: '');
      await tester.pumpWidget(_buildTestApp(
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
      final llm = _FakeLlmService(apiKey: '');
      await tester.pumpWidget(_buildTestApp(
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
      final llm = _FakeLlmService(apiKey: '');
      await tester.pumpWidget(_buildTestApp(
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

  group('QuickGuideScreen - streaming UI states', () {
    testWidgets('send button re-appears after streaming completes',
        (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('Final response');
      llm.chunkDelay = const Duration(milliseconds: 200);

      await tester.pumpWidget(_buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
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

  group('QuickGuideScreen - custom configuration', () {
    testWidgets('custom system prompt is passed to LLM service',
        (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('Custom prompt response');
      const customPrompt = 'You are a custom test assistant.';

      await tester.pumpWidget(_buildTestApp(
        screen: QuickGuideScreen(
          llmService: llm,
          systemPrompt: customPrompt,
          showModeNavigation: false,
        ),
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
      final llm = _FakeLlmService();
      llm.chunks.add('Model response');
      const customModelId = 'custom/test-model';

      await tester.pumpWidget(_buildTestApp(
        screen: QuickGuideScreen(
          llmService: llm,
          defaultModelId: customModelId,
          showModeNavigation: false,
        ),
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

  group('QuickGuideScreen - multiple messages and conversation', () {
    testWidgets('displays multiple messages in the list', (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('First response');

      await tester.pumpWidget(_buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
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

    testWidgets('clear conversation resets to welcome message',
        (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('Response');

      await tester.pumpWidget(_buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
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
  });

  group('QuickGuideScreen - message content rendering', () {
    testWidgets('student message text appears in chat', (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('Tutor answer');

      await tester.pumpWidget(_buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Student query');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Student query'), findsOneWidget);
      expect(find.text('Tutor answer'), findsOneWidget);
    });

    testWidgets('tutor message text appears in chat', (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('Tutor answer here');

      await tester.pumpWidget(_buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Tutor answer here'), findsOneWidget);
    });
  });

  group('QuickGuideScreen - help dialog', () {
    testWidgets('help dialog contains title and content', (tester) async {
      await tester.pumpWidget(_buildTestApp(
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
  });

  group('QuickGuideScreen - navigation', () {
    testWidgets('AI Tutor navigation card tap pushes route', (tester) async {
      final observer = _TestNavigatorObserver();
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: true),
        observer: observer,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('AI Tutor'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(observer.pushedRoutes, isNotEmpty);
      tester.takeException();
    });

    testWidgets('mode navigation cards are present before interaction',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: true),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Choose a study mode'), findsOneWidget);
      expect(find.text('AI Tutor'), findsOneWidget);
      expect(find.text('Mentor'), findsOneWidget);
    });

  });

  group('QuickGuideScreen - message sending edge cases', () {
    testWidgets('empty text does not add message', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining(
            'Hello! I\'m StudyKing\'s Quick Guide. Ask me anything'),
        findsOneWidget,
      );
    });

    testWidgets('submits via keyboard TextInputAction.send', (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('Keyboard response');

      await tester.pumpWidget(_buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Keyboard message');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Keyboard message'), findsOneWidget);
    });
  });

  group('QuickGuideScreen - constructor defaults', () {
    test('default showModeNavigation is true', () {
      const screen = QuickGuideScreen();
      expect(screen.showModeNavigation, isTrue);
    });

    test('default defaultModelId is openai/gpt-4o-mini', () {
      const screen = QuickGuideScreen();
      expect(screen.defaultModelId, 'openai/gpt-4o-mini');
    });

    test('default systemPrompt is null', () {
      const screen = QuickGuideScreen();
      expect(screen.systemPrompt, isNull);
    });

    test('default llmService is null', () {
      const screen = QuickGuideScreen();
      expect(screen.llmService, isNull);
    });
  });
}
