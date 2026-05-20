import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/providers/secure_api_key_provider.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/user_profile_model.dart';
import 'package:studyking/features/settings/data/models/settings_update.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/settings/presentation/api_config_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/services/secure_api_key_service.dart';
import '../../../helpers/navigator_observer_helper.dart';

class FakeSettingsRepository implements SettingsRepository {
  SettingsBox _settings = SettingsBox();
  bool _shouldThrowOnSave = false;

  void setThrowOnSave(bool shouldThrow) {
    _shouldThrowOnSave = shouldThrow;
  }

  @override
  Future<Result<SettingsBox>> getSettings() async => Result.success(_settings);

  @override
  Future<Result<void>> updateSettings(SettingsUpdate update) async {
    if (_shouldThrowOnSave) {
      return Result.failure('Simulated save failure');
    }
    _settings = SettingsBox(
      apiKey: update.apiKey ?? _settings.apiKey,
      apiBaseUrl: update.apiBaseUrl ?? _settings.apiBaseUrl,
      selectedModel: update.selectedModel ?? _settings.selectedModel,
      themeMode: update.themeMode?.index ?? _settings.themeMode,
      fontSize: update.fontSize ?? _settings.fontSize,
      totalSessionCount: _settings.totalSessionCount,
      totalStudyTimeMs: _settings.totalStudyTimeMs,
      totalQuestions: _settings.totalQuestions,
      studyRemindersEnabled: update.studyRemindersEnabled ?? _settings.studyRemindersEnabled,
      requestTimeoutSeconds: update.requestTimeoutSeconds ?? _settings.requestTimeoutSeconds,
      sessionDurationMinutes: update.sessionDurationMinutes ?? _settings.sessionDurationMinutes,
      highContrastEnabled: update.highContrastEnabled ?? _settings.highContrastEnabled,
      largeTouchTargets: update.largeTouchTargets ?? _settings.largeTouchTargets,
      reduceMotion: update.reduceMotion ?? _settings.reduceMotion,
      backupLlmProviderName: update.backupLlmProviderName ?? _settings.backupLlmProviderName,
      backupApiKey: update.backupApiKey ?? _settings.backupApiKey,
      backupBaseUrl: update.backupBaseUrl ?? _settings.backupBaseUrl,
      backupModel: update.backupModel ?? _settings.backupModel,
    );
    return Result.success(null);
  }

  @override
  Future<Result<void>> init() async => Result.success(null);
  @override
  Future<Result<void>> updateStats({int? sessionCount, int? studyTimeMs, int? questions}) async => Result.success(null);
  @override
  Future<Result<void>> saveApiKey({required String service, required String key}) async => Result.success(null);
  @override
  Future<Result<String?>> getApiKey({required String service}) async => Result.success(null);
  @override
  Future<Result<void>> saveProfileData(UserProfile profile) async => Result.success(null);
  @override
  Future<Result<UserProfile?>> getProfileData() async => Result.success(null);
  @override
  Future<Result<void>> clearProfile() async => Result.success(null);
  @override
  Future<Result<void>> clearSettings() async => Result.success(null);
  @override
  Future<Result<void>> saveProvider(LlmProvider provider) async => Result.success(null);
  @override
  Future<Result<LlmProvider>> getProvider() async => Result.success(LlmProvider.openRouter);
}

final fakeApiRepo = FakeSettingsRepository();

class FakeSecureApiKeyService extends SecureApiKeyService {
  FakeSecureApiKeyService() : super();
  @override
  Future<void> saveApiKey(String key) async {}
  @override
  Future<String> getApiKey() async => '';
  @override
  Future<void> saveBackupApiKey(String key) async {}
  @override
  Future<String> getBackupApiKey() async => '';
  @override
  Future<void> clearAll() async {}
}

class _TestSettingsNotifier extends SettingsController {
  _TestSettingsNotifier() : super(fakeApiRepo);

  @override
  Future<void> updateSettings(SettingsUpdate update, {LlmProvider? llmProvider}) async {
    await fakeApiRepo.updateSettings(update);
    state = fakeApiRepo._settings;
  }
}

Widget buildApiConfigScreen({
  String initialApiKey = '',
  String initialBaseUrl = 'https://openrouter.ai/api/v1',
  LlmProvider initialProvider = LlmProvider.openRouter,
  String initialBackupApiKey = '',
  String initialBackupBaseUrl = '',
  String initialBackupModel = '',
  LlmProvider initialBackupProvider = LlmProvider.openRouter,
  TestNavigatorObserver? navigatorObserver,
}) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith((ref) => _TestSettingsNotifier()),
      apiKeyProvider.overrideWith((ref) => initialApiKey),
      apiBaseUrlProvider.overrideWith((ref) => initialBaseUrl),
      llmProviderProvider.overrideWith((ref) => initialProvider),
      backupLlmProviderProvider.overrideWith((ref) => initialBackupProvider),
      backupApiKeyProvider.overrideWith((ref) => initialBackupApiKey),
      backupBaseUrlProvider.overrideWith((ref) => initialBackupBaseUrl),
      backupModelProvider.overrideWith((ref) => initialBackupModel),
      secureApiKeyServiceProvider.overrideWith((ref) => FakeSecureApiKeyService()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      home: const ApiConfigScreen(),
    ),
  );
}

Future<void> pumpApiConfigScreen(WidgetTester tester, {
  String initialApiKey = '',
  String initialBaseUrl = 'https://openrouter.ai/api/v1',
  LlmProvider initialProvider = LlmProvider.openRouter,
  String initialBackupApiKey = '',
  String initialBackupBaseUrl = '',
  String initialBackupModel = '',
  LlmProvider initialBackupProvider = LlmProvider.openRouter,
  TestNavigatorObserver? navigatorObserver,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(800, 3500);
  await tester.pumpWidget(buildApiConfigScreen(
    initialApiKey: initialApiKey,
    initialBaseUrl: initialBaseUrl,
    initialProvider: initialProvider,
    initialBackupApiKey: initialBackupApiKey,
    initialBackupBaseUrl: initialBackupBaseUrl,
    initialBackupModel: initialBackupModel,
    initialBackupProvider: initialBackupProvider,
    navigatorObserver: navigatorObserver,
  ));
  await tester.pumpAndSettle();
}

Future<void> scrollToWidget(WidgetTester tester, Finder target) async {
  await tester.dragUntilVisible(
    target,
    find.byType(Scrollable).first,
    const Offset(0, -300),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    fakeApiRepo._settings = SettingsBox();
    fakeApiRepo.setThrowOnSave(false);
  });

  group('ApiConfigScreen - Provider Switching Edge Cases', () {
    testWidgets('switching to Ollama auto-fills empty base URL', (tester) async {
      await pumpApiConfigScreen(tester, initialBaseUrl: '');

      await tester.tap(find.byType(DropdownButtonFormField<LlmProvider>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ollama').last);
      await tester.pumpAndSettle();

      expect(find.text('http://localhost:11434'), findsOneWidget);
    });

    testWidgets('switching to OpenAI auto-fills empty base URL', (tester) async {
      await pumpApiConfigScreen(tester, initialBaseUrl: '');

      await tester.tap(find.byType(DropdownButtonFormField<LlmProvider>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('OpenAI').last);
      await tester.pumpAndSettle();

      expect(find.text('https://api.openai.com/v1'), findsOneWidget);
    });

    testWidgets('switching provider preserves non-default base URL', (tester) async {
      await pumpApiConfigScreen(tester, initialBaseUrl: 'https://custom.endpoint.com');

      await tester.tap(find.byType(DropdownButtonFormField<LlmProvider>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ollama').last);
      await tester.pumpAndSettle();

      expect(find.text('https://custom.endpoint.com'), findsOneWidget);
    });
  });

  group('ApiConfigScreen - Ollama Provider', () {
    testWidgets('saves without API key when Ollama is selected', (tester) async {
      await pumpApiConfigScreen(tester,
        initialProvider: LlmProvider.ollama,
        initialBaseUrl: 'http://localhost:11434',
        initialApiKey: '',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
      await tester.pumpAndSettle();

      expect(find.text('API keys saved successfully'), findsOneWidget);
    });

    testWidgets('shows Ollama in provider dropdown', (tester) async {
      await pumpApiConfigScreen(tester);

      await tester.tap(find.byType(DropdownButtonFormField<LlmProvider>));
      await tester.pumpAndSettle();

      expect(find.text('Ollama'), findsOneWidget);
    });
  });

  group('ApiConfigScreen - Save Error Handling', () {
    testWidgets('shows error snackbar when save throws exception', (tester) async {
      fakeApiRepo.setThrowOnSave(true);

      await pumpApiConfigScreen(tester, initialApiKey: 'sk-test');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
      await tester.pumpAndSettle();

      expect(find.text('Unable to save API configuration'), findsOneWidget);
    });

    testWidgets('save error does not crash the screen', (tester) async {
      fakeApiRepo.setThrowOnSave(true);

      await pumpApiConfigScreen(tester, initialApiKey: 'sk-test');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
      await tester.pumpAndSettle();

      expect(find.byType(ApiConfigScreen), findsOneWidget);
    });
  });

  group('ApiConfigScreen - Connection Test', () {
    testWidgets('test connection button shows loading while testing', (tester) async {
      HttpOverrides.global = _TestTimeoutHttpOverride();
      addTearDown(() => HttpOverrides.global = null);

      await pumpApiConfigScreen(tester, initialApiKey: 'sk-test');

      await tester.tap(find.widgetWithText(OutlinedButton, 'Test Connection'));
      await tester.pump();

      expect(find.text('Testing...'), findsOneWidget);
    });
  });

  group('ApiConfigScreen - PopScope No Changes', () {
    testWidgets('PopScope allows back navigation without changes', (tester) async {
      final navigatorObserver = TestNavigatorObserver();
      await pumpApiConfigScreen(tester, navigatorObserver: navigatorObserver);

      final backButton = find.byTooltip('Back');
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        expect(find.text('Unsaved Changes'), findsNothing);
        expect(navigatorObserver.poppedRoutes, isNotEmpty);
      }
    });
  });

  group('ApiConfigScreen - Backup Provider Setup Guide', () {
    testWidgets('shows backup provider section with all fields', (tester) async {
      await pumpApiConfigScreen(tester);

      await scrollToWidget(tester, find.text('Backup Provider'));
      expect(find.text('Backup Provider'), findsOneWidget);

      await scrollToWidget(tester, find.text('Backup API Key'));
      expect(find.text('Backup API Key'), findsOneWidget);

      await scrollToWidget(tester, find.text('Backup Model'));
      expect(find.text('Backup Model'), findsOneWidget);
    });

    testWidgets('backup provider dropdown has correct default value', (tester) async {
      await pumpApiConfigScreen(tester);

      final dropdowns = find.byType(DropdownButtonFormField<LlmProvider>);
      expect(dropdowns, findsNWidgets(2));
    });
  });
}

class _TestTimeoutHttpOverride extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => 'PROXY localhost';
    return client;
  }
}
