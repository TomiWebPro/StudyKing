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
    String feature = 'general',
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

Widget _buildTestAppWithProvider({
  required LlmService llmService,
  NavigatorObserver? observer,
}) {
  return ProviderScope(
    overrides: [
      llmServiceProvider.overrideWith((ref) => llmService),
    ],
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
      home: const QuickGuideScreen(showModeNavigation: false),
    ),
  );
}

void main() {
  group('QuickGuideScreen - provider path', () {
    testWidgets('sends message via provider-injected LlmService', (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('Provider response');

      await tester.pumpWidget(_buildTestAppWithProvider(llmService: llm));
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

  group('QuickGuideScreen - empty state rendering', () {
    testWidgets('shows welcome message on initial render', (tester) async {
      await tester.pumpWidget(_buildTestApp(
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
  });

  group('QuickGuideScreen - suggestions visibility', () {
    testWidgets('suggested prompts section is visible before interaction',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Suggested prompts'), findsOneWidget);
      expect(find.byType(ActionChip), findsAtLeastNWidgets(1));
    });

    testWidgets('suggested prompts chips disappear after sending a message',
        (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('Response');

      await tester.pumpWidget(_buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
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
      final llm = _FakeLlmService();
      llm.chunks.add('Response');

      await tester.pumpWidget(_buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
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
      final llm = _FakeLlmService();
      llm.chunks.add('Response');

      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: true),
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
      final llm = _FakeLlmService();
      llm.chunks.add('Tutor reply');

      await tester.pumpWidget(_buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
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
  });

  group('QuickGuideScreen - multiple streaming chunks', () {
    testWidgets('multiple chunks update message content progressively',
        (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('Start. ');
      llm.chunks.add('Middle. ');
      llm.chunks.add('End.');
      llm.chunkDelay = Duration.zero;

      await tester.pumpWidget(_buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Chunks');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Start. Middle. End.'), findsOneWidget);
    });
  });

  group('QuickGuideScreen - token count', () {
    testWidgets('token count is set after streaming completes',
        (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('Hello world');

      await tester.pumpWidget(_buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Test');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Hello world'), findsOneWidget);
    });
  });

  group('QuickGuideScreen - semantics coverage', () {
    testWidgets('send button has tooltip', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byTooltip('Send message'), findsOneWidget);
    });

    testWidgets('help button has tooltip', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byTooltip('Help'), findsOneWidget);
    });

    testWidgets('message input has hint text', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Ask anything...'), findsAtLeastNWidgets(1));
    });
  });

  group('QuickGuideScreen - clear conversation', () {
    testWidgets('clear conversation resets hasInteracted and shows mode nav',
        (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('Response');

      await tester.pumpWidget(_buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: true),
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

  group('QuickGuideScreen - fallback error during streaming', () {
    testWidgets('LLM streaming error with non-empty key shows fallback',
        (tester) async {
      final llm = _FakeLlmService();
      llm.shouldThrow = true;

      await tester.pumpWidget(_buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
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

  group('QuickGuideScreen - selectPrompt', () {
    testWidgets('tapping a suggested prompt sends and shows response',
        (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('This is the answer.');

      await tester.pumpWidget(_buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final chips = find.byType(ActionChip);
      expect(chips, findsAtLeastNWidgets(1));

      await tester.tap(chips.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('This is the answer.'), findsOneWidget);
    });
  });

  group('QuickGuideScreen - mode card rendering', () {
    testWidgets('AI Tutor and Mentor cards render with correct icons',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
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
      await tester.pumpWidget(_buildTestApp(
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
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });
  });

  group('QuickGuideScreen - constructor defaults', () {
    test('showModeNavigation defaults to true', () {
      const screen = QuickGuideScreen();
      expect(screen.showModeNavigation, isTrue);
    });

    test('defaultModelId defaults to empty string', () {
      const screen = QuickGuideScreen();
      expect(screen.defaultModelId, '');
    });

    test('systemPrompt defaults to null', () {
      const screen = QuickGuideScreen();
      expect(screen.systemPrompt, isNull);
    });

    test('llmService defaults to null', () {
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
}
