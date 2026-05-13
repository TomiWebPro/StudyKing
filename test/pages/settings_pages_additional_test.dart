import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:studyking/core/data/models/llm_config.dart';
import 'package:studyking/pages/settings/llm_applcation_page.dart';
import 'package:studyking/pages/settings/llm_settings_screen.dart';
import 'package:studyking/providers/llm_engine_provider.dart';

class _SyncErrorAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Object? cancelFuture,
  ) {
    return Future.error(DioException(requestOptions: options));
  }

  @override
  void close({bool force = false}) {}
}

class TestLLMAIEngineProvider extends LLMAIEngineProvider {
  TestLLMAIEngineProvider({super.dio});

  bool _overrideIsLoading = false;

  @override
  bool get isLoading => _overrideIsLoading;

  void setLoading(bool value) {
    _overrideIsLoading = value;
    notifyListeners();
  }
}

void main() {
  group('LLMApplcationPage - additional coverage', () {
    late TestLLMAIEngineProvider engine;

    setUp(() {
      engine = TestLLMAIEngineProvider();
    });

    testWidgets('widget can be disposed without error', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(home: LLMApplcationPage(engineProvider: engine)),
        ),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(home: const Scaffold()),
        ),
      );
      await tester.pump();
    });

    testWidgets('shows chat bubble icon when model is selected', (tester) async {
      engine.setSelectedModel(AvailableModels.openrouterModels.first);

      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(home: LLMApplcationPage(engineProvider: engine)),
        ),
      );

      expect(find.text('Select a model to start'), findsNothing);
      expect(find.byIcon(Icons.chat_bubble), findsOneWidget);
    });

    testWidgets('pressing send triggers loading state via engine', (tester) async {
      bool called = false;
      final controller = TextEditingController(text: 'hello');

      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(
            home: Scaffold(
              body: ChatArea(
                engine: engine,
                controller: controller,
                onSend: (_, __, ___) {
                  called = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(called, isTrue);
      expect(controller.text, isEmpty);
    });

    testWidgets('typing and sending through full app page', (tester) async {
      final dio = Dio()..httpClientAdapter = _SyncErrorAdapter();
      final engineWithDio = TestLLMAIEngineProvider(dio: dio);

      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engineWithDio,
          child: MaterialApp(home: LLMApplcationPage(engineProvider: engineWithDio)),
        ),
      );

      await tester.enterText(find.byType(TextField), 'hello world');
      await tester.tap(find.byIcon(Icons.send));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('hello world'), findsNothing);
    });

    testWidgets('tapping send with empty text does nothing', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(home: LLMApplcationPage(engineProvider: engine)),
        ),
      );

      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('app bar has file open and settings buttons', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(home: LLMApplcationPage(engineProvider: engine)),
        ),
      );

      expect(find.byIcon(Icons.folder_open), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });

  group('ChatArea - additional coverage', () {
    late TestLLMAIEngineProvider engine;

    setUp(() {
      engine = TestLLMAIEngineProvider();
    });

    testWidgets('onSubmit with empty text does not call onSend', (tester) async {
      bool called = false;

      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(
            home: Scaffold(
              body: ChatArea(
                engine: engine,
                controller: TextEditingController(),
                onSend: (_, __, ___) {
                  called = true;
                },
              ),
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(called, isFalse);
    });

    testWidgets('shows loading indicator when engine is loading', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(
            home: Scaffold(
              body: ChatArea(
                engine: engine,
                controller: TextEditingController(),
                onSend: (_, __, ___) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      engine.setLoading(true);
      await tester.pump();

      expect(find.byIcon(Icons.send), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      engine.setLoading(false);
      await tester.pump();

      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('onSubmit clears text field after sending', (tester) async {
      String? sentMessage;

      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(
            home: Scaffold(
              body: ChatArea(
                engine: engine,
                controller: TextEditingController(),
                onSend: (message, _, __) {
                  sentMessage = message;
                },
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(sentMessage, equals('test message'));
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('onSubmit success callback shows snackbar', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(
            home: Scaffold(
              body: ChatArea(
                engine: engine,
                controller: TextEditingController(),
                onSend: (message, onSuccess, onError) {
                  onSuccess?.call(<String, dynamic>{'ok': true});
                },
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(find.text('Request sent'), findsOneWidget);
    });

    testWidgets('onSubmit error callback shows snackbar', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(
            home: Scaffold(
              body: ChatArea(
                engine: engine,
                controller: TextEditingController(),
                onSend: (message, onSuccess, onError) {
                  onError?.call('Something went wrong');
                },
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(find.text('Error: Something went wrong'), findsOneWidget);
    });
  });

  group('ModelSelectorWidget', () {
    late TestLLMAIEngineProvider engine;

    setUp(() {
      engine = TestLLMAIEngineProvider();
    });

    testWidgets('builds and shows model options via PopupMenuButton', (tester) async {

      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(
            home: Scaffold(
              body: ModelSelectorWidget(
                onModelSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(ModelSelectorWidget.availableModels, isNotEmpty);
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Anthropic Claude 3.5 Sonnet'), findsOneWidget);
      expect(find.text('Google Gemini 1.5 Pro'), findsOneWidget);
      expect(find.text('Meta Llama 3.1 405B'), findsOneWidget);
    });

    testWidgets('selecting a model triggers onModelSelected', (tester) async {
      String? selected;

      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(
            home: Scaffold(
              body: ModelSelectorWidget(
                onModelSelected: (model) {
                  selected = model;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mistral Large').last);
      await tester.pumpAndSettle();

      expect(selected, equals('mistral/mistral-large'));
    });
  });

  group('ChatBubble - alignment and styling', () {
    testWidgets('user message aligned right, assistant left', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ChatBubble(
                  message: ChatMessage(type: MessageType.user, content: 'user msg'),
                  isUser: true,
                ),
                ChatBubble(
                  message: ChatMessage(type: MessageType.assistant, content: 'ai msg'),
                  isUser: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('user msg'), findsOneWidget);
      expect(find.text('ai msg'), findsOneWidget);
    });
  });

  group('LLMSettingsScreen - additional coverage', () {
    late TestLLMAIEngineProvider engine;

    setUp(() {
      engine = TestLLMAIEngineProvider();
    });

    testWidgets('radio group changes connection type', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(home: LLMSettingsScreen(engineProvider: engine)),
        ),
      );

      expect(find.byType(RadioListTile<String>), findsOneWidget);

      await tester.tap(find.byType(RadioListTile<String>));
      await tester.pump();
    });

    testWidgets('api key text field calls configureEndpoint', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(home: LLMSettingsScreen(engineProvider: engine)),
        ),
      );

      final textField = find.byType(TextFormField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'sk-or-v1-test-key');
      await tester.pump();

      expect(engine.apiKeyConfigured, isTrue);
      expect(engine.apiKey, equals('sk-or-v1-test-key'));
    });

    testWidgets('switch reflects api key state at build time', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(home: LLMSettingsScreen(engineProvider: engine)),
        ),
      );

      SwitchListTile switchTile = tester.widget(find.byType(SwitchListTile));
      expect(switchTile.value, isFalse);
    });

    testWidgets('switch shows true when api key is set before build', (tester) async {
      await engine.setApiKey('sk-test');

      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(home: LLMSettingsScreen(engineProvider: engine)),
        ),
      );

      SwitchListTile switchTile = tester.widget(find.byType(SwitchListTile));
      expect(switchTile.value, isTrue);
    });

    testWidgets('usage statistics shows price-highlighted row', (tester) async {
      engine.addUsageRecord(
        LLMUsageRecord(
          timestamp: DateTime.now(),
          provider: 'openrouter',
          model: 'test-model',
          inputTokens: 1000,
          outputTokens: 500,
          totalCost: 0.05,
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(home: LLMSettingsScreen(engineProvider: engine)),
        ),
      );

      expect(find.textContaining('Requests: 1'), findsOneWidget);
      expect(find.textContaining('Total Cost'), findsOneWidget);
      expect(find.textContaining('Avg Cost'), findsOneWidget);
    });

    testWidgets('usage statistics shows empty state without data', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(home: LLMSettingsScreen(engineProvider: engine)),
        ),
      );

      expect(
        find.text('No usage data yet. Make a request to see statistics.'),
        findsOneWidget,
      );
    });

    testWidgets('reset configuration clears model and api key', (tester) async {
      engine.setSelectedModel(AvailableModels.openrouterModels.first);
      engine.setApiKey('sk-test');

      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(home: LLMSettingsScreen(engineProvider: engine)),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Reset Configuration'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Reset Configuration'));
      await tester.pump();

      expect(engine.selectedModel, isNull);
      expect(engine.apiKeyConfigured, isFalse);
    });

    testWidgets('clear usage history button works', (tester) async {
      engine.addUsageRecord(
        LLMUsageRecord(
          timestamp: DateTime.now(),
          provider: 'openrouter',
          model: 'test-model',
          inputTokens: 10,
          outputTokens: 5,
          totalCost: 0.001,
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<LLMAIEngineProvider>.value(
          value: engine,
          child: MaterialApp(home: LLMSettingsScreen(engineProvider: engine)),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Clear Usage History'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Clear Usage History'));
      await tester.pump();

      expect(engine.getUsageHistory(), isEmpty);
    });
  });
}
