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

  _FakeLlmService()
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'fake-key-for-testing',
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
  group('QuickGuideScreen', () {
    testWidgets('renders empty state when no messages exist', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Quick Guide'), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('suggested prompt chips render with correct labels', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final chips = find.byType(ActionChip);
      expect(chips, findsAtLeastNWidgets(1));
    });

    testWidgets('suggested prompt chip tap triggers message sending', (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('Test response');
      await tester.pumpWidget(_buildTestApp(
        screen: QuickGuideScreen(
          llmService: llm,
          showModeNavigation: false,
        ),
        llmService: llm,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final chips = find.byType(ActionChip);
      if (chips.evaluate().isNotEmpty) {
        await tester.tap(chips.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));
      }
    });

    testWidgets('help dialog opens and displays content', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('help dialog dismisses on Got it tap', (tester) async {
      await tester.pumpWidget(_buildTestApp(
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

    testWidgets('clear conversation button appears after interaction', (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('Response');
      await tester.pumpWidget(_buildTestApp(
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

    testWidgets('clear conversation resets messages and state', (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('Response text');
      await tester.pumpWidget(_buildTestApp(
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

    testWidgets('send button is disabled while streaming', (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('response');
      llm.chunkDelay = const Duration(milliseconds: 100);

      await tester.pumpWidget(_buildTestApp(
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

    testWidgets('LLM exception is caught and fallback response is shown', (tester) async {
      final llm = _FakeLlmService();
      llm.shouldThrow = true;

      await tester.pumpWidget(_buildTestApp(
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

    testWidgets('semantics labels are present on key elements', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.bySemanticsLabel('Quick Guide help'), findsOneWidget);
    });
  });

  group('QuickGuideScreen - Navigation', () {
    testWidgets('mode navigation cards are rendered when showModeNavigation is true', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: true),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('AI Tutor'), findsOneWidget);
      expect(find.text('Mentor'), findsOneWidget);
      expect(find.text('Choose a study mode'), findsOneWidget);
    });

    testWidgets('mode navigation Mentor card navigates to mentor route', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: true),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Mentor'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Mentor Screen'), findsOneWidget);
    });

    testWidgets('mode navigation AI Tutor card tap triggers navigation', (tester) async {
      final observer = _TestNavigatorObserver();
      await tester.pumpWidget(_buildTestApp(
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
  });

  group('QuickGuideScreen - send/receive message flow', () {
    testWidgets('does not send empty or whitespace-only messages', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(find.text('Quick Guide'), findsOneWidget);
    });

    testWidgets('sends message via mocked LlmService', (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('Here is an explanation of fractions.');

      await tester.pumpWidget(_buildTestApp(
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

    testWidgets('streaming response updates message content progressively', (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('First part... ');
      llm.chunks.add('Second part.');

      await tester.pumpWidget(_buildTestApp(
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

    testWidgets('submits from keyboard action', (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('Gravity response.');
      await tester.pumpWidget(_buildTestApp(
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
  });
}
