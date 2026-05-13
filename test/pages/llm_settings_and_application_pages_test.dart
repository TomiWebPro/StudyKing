import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:studyking/core/data/models/llm_config.dart';
import 'package:studyking/pages/settings/llm_applcation_page.dart';
import 'package:studyking/pages/settings/llm_settings_screen.dart';
import 'package:studyking/providers/llm_engine_provider.dart';

void main() {
  group('LLMSettingsScreen', () {
    late LLMAIEngineProvider engine;

    setUp(() {
      engine = LLMAIEngineProvider();
    });

    testWidgets('renders sections and no usage state', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(
            home: LLMSettingsScreen(engineProvider: engine),
          ),
        ),
      );

      expect(find.text('LLM Settings'), findsOneWidget);
      expect(find.text('Connection Settings'), findsOneWidget);
      expect(find.text('Model Selection'), findsOneWidget);
      expect(find.text('Usage Statistics'), findsOneWidget);
      expect(find.text('No usage data yet. Make a request to see statistics.'), findsOneWidget);
    });

    testWidgets('selecting a model shows selection snackbar', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(
            home: LLMSettingsScreen(engineProvider: engine),
          ),
        ),
      );

      await tester.tap(find.text('Anthropic Claude 3.5 Sonnet').first);
      await tester.pump();

      expect(find.text('Anthropic Claude 3.5 Sonnet selected'), findsOneWidget);
      expect(engine.selectedModel?.modelName, equals('anthropic/claude-3.5-sonnet'));
    });

    testWidgets('action buttons clear usage and reset configuration', (tester) async {
      engine.addUsageRecord(
        LLMUsageRecord(
          timestamp: DateTime.now(),
          provider: 'openrouter',
          model: 'anthropic/claude-3.5-sonnet',
          inputTokens: 10,
          outputTokens: 15,
          totalCost: 0.2,
        ),
      );
      engine.setSelectedModel(AvailableModels.openrouterModels.first);

      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(
            home: LLMSettingsScreen(engineProvider: engine),
          ),
        ),
      );

      expect(find.textContaining('Requests: 1'), findsOneWidget);

      await tester.ensureVisible(find.text('Clear Usage History'));
      await tester.tap(find.text('Clear Usage History'));
      await tester.pump();
      expect(find.text('No usage data yet. Make a request to see statistics.'), findsOneWidget);

      await tester.ensureVisible(find.text('Reset Configuration'));
      await tester.tap(find.text('Reset Configuration'));
      await tester.pump();
      expect(engine.selectedModel, isNull);
      expect(engine.apiKeyConfigured, isFalse);
    });
  });

  group('LLMApplcationPage and related widgets', () {
    late LLMAIEngineProvider engine;

    setUp(() {
      engine = LLMAIEngineProvider();
    });

    testWidgets('shows empty model prompt when no model selected', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(
            routes: {
              '/llm-settings': (_) => LLMSettingsScreen(engineProvider: engine),
            },
            home: LLMApplcationPage(engineProvider: engine),
          ),
        ),
      );

      expect(find.text('LLM Chat'), findsOneWidget);
      expect(find.text('Select a model to start'), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('open file action shows coming soon snackbar', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(home: LLMApplcationPage(engineProvider: engine)),
        ),
      );

      await tester.tap(find.byIcon(Icons.folder_open));
      await tester.pump();

      expect(find.text('File open feature coming soon'), findsOneWidget);
    });

    testWidgets('navigates to settings page from app bar', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(
            routes: {
              '/llm-settings': (_) => LLMSettingsScreen(engineProvider: engine),
            },
            home: LLMApplcationPage(engineProvider: engine),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.text('LLM Settings'), findsOneWidget);
    });

    testWidgets('chat area sends and clears text input', (tester) async {
      String? captured;

      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(
            home: Scaffold(
              body: ChatArea(
                engine: engine,
                controller: TextEditingController(),
                onSend: (message, _, __) {
                  captured = message;
                },
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'hello model');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(captured, equals('hello model'));
      expect(find.text('hello model'), findsNothing);
    });

    testWidgets('ChatBubble renders loading and normal states', (tester) async {
      final loadingMessage = ChatMessage(
        type: MessageType.assistant,
        content: 'loading',
        isLoading: true,
      );
      final normalMessage = ChatMessage(
        type: MessageType.user,
        content: 'done',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ChatBubble(message: loadingMessage, isUser: false),
                ChatBubble(message: normalMessage, isUser: true),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('done'), findsOneWidget);
    });

    test('ChatMessage and ModelSelectorWidget constants are usable', () {
      final message = ChatMessage(
        type: MessageType.user,
        content: 'message',
        data: const {'ok': true},
      );

      expect(message.type, equals(MessageType.user));
      expect(message.content, equals('message'));
      expect(ModelSelectorWidget.availableModels, isNotEmpty);
      expect(
        ModelSelectorWidget.availableModels,
        equals(AvailableModels.openrouterModels),
      );
    });
  });
}
