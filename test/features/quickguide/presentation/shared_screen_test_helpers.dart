import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/quickguide/presentation/quick_guide_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class FakeLlmService extends LlmService {
  bool shouldThrow = false;
  final List<String> chunks = [];
  bool streamConsumed = false;
  Duration chunkDelay = Duration.zero;
  String? capturedSystemPrompt;
  String? capturedModelId;

  FakeLlmService({String apiKey = 'fake-key-for-testing'})
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

class TestNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
  }
}

Widget buildTestApp({
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
      routes: {
        '/mentor': (_) => const Scaffold(
              body: Center(child: Text('Mentor Screen')),
            ),
      },
      home: screen ?? const QuickGuideScreen(showModeNavigation: false),
    ),
  );
}

Widget buildTestAppWithProvider({
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
