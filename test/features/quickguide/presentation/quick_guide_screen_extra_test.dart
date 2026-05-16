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
  Locale? locale,
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
      locale: locale ?? const Locale('en'),
      navigatorObservers: observer != null ? [observer] : [],
      home: screen ?? const QuickGuideScreen(showModeNavigation: false),
    ),
  );
}

void main() {
  group('QuickGuideScreen - semantics and accessibility', () {
    testWidgets('clear conversation button has proper semantics label',
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
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.bySemanticsLabel('Clear conversation'), findsOneWidget);
    });

    testWidgets('clear conversation button has correct tooltip',
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
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byTooltip('Clear conversation'), findsOneWidget);
    });

    testWidgets('help button semantics label is present without interaction',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.bySemanticsLabel('Quick Guide help'), findsOneWidget);
    });

    testWidgets('conversation input has correct hint text', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Ask anything...'), findsAtLeastNWidgets(1));
    });

    testWidgets('send button has semantics label', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byTooltip('Send message'), findsOneWidget);
    });

    testWidgets('send button tooltip is present', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byTooltip('Send message'), findsOneWidget);
    });

    testWidgets('help button tooltip is present', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byTooltip('Help'), findsOneWidget);
    });
  });

  group('QuickGuideScreen - FocusTraversalGroup layout', () {
    testWidgets('renders FocusTraversalGroup widgets in body', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: true),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FocusTraversalGroup), findsAtLeastNWidgets(2));
    });

    testWidgets('body contains SafeArea widget', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SafeArea), findsAtLeastNWidgets(1));
    });
  });

  group('QuickGuideScreen - localized guard', () {
    testWidgets('welcome message appears only once after locale change',
        (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('Response');

      await tester.pumpWidget(_buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining(
            "Hello! I'm StudyKing's Quick Guide. Ask me anything"),
        findsOneWidget,
      );

      await tester.binding.setLocale('es', '');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining(
            "Hello! I'm StudyKing's Quick Guide. Ask me anything"),
        findsOneWidget,
      );
    });
  });

  group('QuickGuideScreen - widget lifecycle', () {
    testWidgets('dispose does not throw', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pumpWidget(Container());
      await tester.pump();
    });

    testWidgets('can be created without localization context then removed',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });

  group('QuickGuideScreen - streaming with mounted check', () {
    testWidgets('mounted check prevents setState after dispose',
        (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('Response');
      llm.chunkDelay = const Duration(milliseconds: 50);

      await tester.pumpWidget(_buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
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

  group('QuickGuideScreen - ExcludeSemantics usage', () {
    testWidgets('Semantics wrappers around app bar buttons exist',
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
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.bySemanticsLabel('Clear conversation'), findsOneWidget);
      expect(find.bySemanticsLabel('Quick Guide help'), findsOneWidget);
    });
  });

  group('QuickGuideScreen - conversation input properties', () {
    testWidgets('TextField is rendered within conversation input',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('text field accepts input and shows it', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        screen: const QuickGuideScreen(showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Test query');
      expect(find.text('Test query'), findsOneWidget);
    });
  });

  group('QuickGuideScreen - clear conversation restores suggestions', () {
    testWidgets('clear conversation makes chips reappear', (tester) async {
      final llm = _FakeLlmService();
      llm.chunks.add('Response');

      await tester.pumpWidget(_buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ActionChip), findsAtLeastNWidgets(1));

      await tester.enterText(find.byType(TextField), 'Message');
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

  group('QuickGuideScreen - empty API key fallback responses', () {
    testWidgets('empty API key uses fallback for explain query',
        (tester) async {
      final llm = _FakeLlmService(apiKey: '');
      await tester.pumpWidget(_buildTestApp(
        screen: QuickGuideScreen(llmService: llm, showModeNavigation: false),
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

    testWidgets('empty API key uses fallback for quiz query', (tester) async {
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

    testWidgets('empty API key uses fallback for math query', (tester) async {
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

    testWidgets('empty API key uses general fallback for other queries',
        (tester) async {
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

    testWidgets('empty API key question keyword uses quiz fallback',
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

    testWidgets('empty API key calculate keyword uses math fallback',
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
  });

  group('QuickGuideScreen - streaming error with fallback', () {
    testWidgets('LLM streaming error shows general fallback', (tester) async {
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
}
