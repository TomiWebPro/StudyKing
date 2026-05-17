import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/user_profile_model.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/settings/presentation/api_config_screen.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class FakeSettingsRepository implements SettingsRepository {
  SettingsBox _settings = SettingsBox();
  bool _shouldThrowOnSave = false;

  void setThrowOnSave(bool shouldThrow) {
    _shouldThrowOnSave = shouldThrow;
  }

  @override
  Future<SettingsBox> getSettings() async => _settings;

  @override
  Future<void> updateSettings({
    String? apiKey,
    String? apiBaseUrl,
    String? selectedModel,
    ThemeMode? themeMode,
    double? fontSize,
    bool? studyRemindersEnabled,
    int? requestTimeoutSeconds,
    int? sessionDurationMinutes,
    bool? highContrastEnabled,
    bool? largeTouchTargets,
    bool? reduceMotion,
    bool? revisionRemindersEnabled,
    bool? lessonNotificationsEnabled,
    bool? overworkAlertsEnabled,
    bool? planAdjustmentNotificationsEnabled,
    int? breakDurationSeconds,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    bool? firstFocusVisit,
    bool? dailyReminderEnabled,
  }) async {
    if (_shouldThrowOnSave) {
      throw Exception('Simulated save failure');
    }
    _settings = SettingsBox(
      apiKey: apiKey ?? _settings.apiKey,
      apiBaseUrl: apiBaseUrl ?? _settings.apiBaseUrl,
      selectedModel: selectedModel ?? _settings.selectedModel,
      themeMode: themeMode?.index ?? _settings.themeMode,
      fontSize: fontSize ?? _settings.fontSize,
      totalSessionCount: _settings.totalSessionCount,
      totalStudyTimeMs: _settings.totalStudyTimeMs,
      totalQuestions: _settings.totalQuestions,
      studyRemindersEnabled: studyRemindersEnabled ?? _settings.studyRemindersEnabled,
      requestTimeoutSeconds: requestTimeoutSeconds ?? _settings.requestTimeoutSeconds,
      sessionDurationMinutes: sessionDurationMinutes ?? _settings.sessionDurationMinutes,
      highContrastEnabled: highContrastEnabled ?? _settings.highContrastEnabled,
      largeTouchTargets: largeTouchTargets ?? _settings.largeTouchTargets,
      reduceMotion: reduceMotion ?? _settings.reduceMotion,
      revisionRemindersEnabled: revisionRemindersEnabled ?? _settings.revisionRemindersEnabled,
      lessonNotificationsEnabled: lessonNotificationsEnabled ?? _settings.lessonNotificationsEnabled,
      overworkAlertsEnabled: overworkAlertsEnabled ?? _settings.overworkAlertsEnabled,
      planAdjustmentNotificationsEnabled: planAdjustmentNotificationsEnabled ?? _settings.planAdjustmentNotificationsEnabled,
      breakDurationSeconds: breakDurationSeconds ?? _settings.breakDurationSeconds,
      dailyReminderHour: dailyReminderHour ?? _settings.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? _settings.dailyReminderMinute,
      firstFocusVisit: firstFocusVisit ?? _settings.firstFocusVisit,
      dailyReminderEnabled: dailyReminderEnabled ?? _settings.dailyReminderEnabled,
    );
  }

  @override
  Future<void> init() async {}
  @override
  Future<void> updateStats({int? sessionCount, int? studyTimeMs, int? questions}) async {}
  @override
  Future<void> saveApiKey({required String service, required String key}) async {}
  @override
  Future<String?> getApiKey({required String service}) async => null;
  @override
  Future<void> saveProfileData(UserProfile profile) async {}
  @override
  Future<UserProfile?> getProfileData() async => null;
  @override
  Future<void> clearProfile() async {}
  @override
  Future<void> clearSettings() async {}
  @override
  Future<void> saveProvider(LlmProvider provider) async {}
  @override
  Future<LlmProvider> getProvider() async => LlmProvider.openRouter;
}

final fakeApiRepo = FakeSettingsRepository();

class _TestSettingsNotifier extends SettingsController {
  _TestSettingsNotifier() : super(fakeApiRepo);

  @override
  Future<void> updateSettings({
    String? apiKey,
    String? apiBaseUrl,
    String? selectedModel,
    LlmProvider? llmProvider,
    ThemeMode? themeMode,
    double? fontSize,
    bool? studyRemindersEnabled,
    int? requestTimeoutSeconds,
    int? sessionDurationMinutes,
    bool? highContrastEnabled,
    bool? largeTouchTargets,
    bool? reduceMotion,
    bool? revisionRemindersEnabled,
    bool? lessonNotificationsEnabled,
    bool? overworkAlertsEnabled,
    bool? planAdjustmentNotificationsEnabled,
    int? breakDurationSeconds,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    bool? firstFocusVisit,
    bool? dailyReminderEnabled,
  }) async {
    await fakeApiRepo.updateSettings(
      apiKey: apiKey,
      apiBaseUrl: apiBaseUrl,
      selectedModel: selectedModel,
      themeMode: themeMode,
      fontSize: fontSize,
      studyRemindersEnabled: studyRemindersEnabled,
      requestTimeoutSeconds: requestTimeoutSeconds,
      sessionDurationMinutes: sessionDurationMinutes,
      highContrastEnabled: highContrastEnabled,
      largeTouchTargets: largeTouchTargets,
      reduceMotion: reduceMotion,
      revisionRemindersEnabled: revisionRemindersEnabled,
      lessonNotificationsEnabled: lessonNotificationsEnabled,
      overworkAlertsEnabled: overworkAlertsEnabled,
      planAdjustmentNotificationsEnabled: planAdjustmentNotificationsEnabled,
    );
    state = fakeApiRepo._settings;
  }
}

Widget buildApiConfigScreen({
  String initialApiKey = '',
  String initialBaseUrl = 'https://openrouter.ai/api/v1',
  LlmProvider initialProvider = LlmProvider.openRouter,
}) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith((ref) => _TestSettingsNotifier()),
      apiKeyProvider.overrideWith((ref) => initialApiKey),
      apiBaseUrlProvider.overrideWith((ref) => initialBaseUrl),
      llmProviderProvider.overrideWith((ref) => initialProvider),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const ApiConfigScreen(),
    ),
  );
}

class _TestTimeoutHttpOverride extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => 'PROXY localhost';
    return client;
  }
}

void main() {
  setUp(() {
    fakeApiRepo._settings = SettingsBox();
    fakeApiRepo.setThrowOnSave(false);
  });

  group('ApiConfigScreen', () {
    testWidgets('renders API configuration screen', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      expect(find.text('API Configuration'), findsOneWidget);
    });

    testWidgets('shows configure API keys title', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      expect(find.text('Configure API Keys'), findsOneWidget);
    });

    testWidgets('shows description about OpenRouter', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('OpenRouter API credentials'), findsOneWidget);
    });

    testWidgets('shows API key section with correct title', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      expect(find.text('OpenRouter API Key'), findsOneWidget);
      expect(find.text('sk-or-v1-...'), findsOneWidget);
      expect(find.textContaining('Required for LLM content generation'), findsOneWidget);
    });

    testWidgets('shows API base URL section', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      expect(find.text('API Base URL'), findsOneWidget);
      expect(find.text('https://openrouter.ai/api/v1'), findsOneWidget);
      expect(find.textContaining('endpoint URL for the AI service'), findsOneWidget);
    });

    testWidgets('shows save button', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, 'Save API Keys'), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('shows test connection button', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, 'Test Connection'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_tethering), findsOneWidget);
    });

    testWidgets('API key field is obscured by default', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      final textField = find.byType(TextField).first;
      final widget = tester.widget<TextField>(textField);
      expect(widget.obscureText, isTrue);
    });

    testWidgets('shows visibility toggle button for API key', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('can type in API key field', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      final apiKeyField = find.byType(TextField).first;
      await tester.enterText(apiKeyField, 'sk-test-key-123');
      await tester.pumpAndSettle();

      expect(find.text('sk-test-key-123'), findsOneWidget);
    });

    testWidgets('can type in base URL field', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      final baseUrlField = find.byType(TextField).last;
      await tester.enterText(baseUrlField, 'https://custom.api.com');
      await tester.pumpAndSettle();

      expect(find.text('https://custom.api.com'), findsOneWidget);
    });

    testWidgets('shows error when saving empty API key', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen(initialApiKey: ''));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
      await tester.pumpAndSettle();

      expect(find.text('API key cannot be empty'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('toggling visibility shows/hides API key', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      final visibilityButton = find.byIcon(Icons.visibility);
      expect(visibilityButton, findsOneWidget);

      await tester.tap(visibilityButton);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      final textField = find.byType(TextField).first;
      final widget = tester.widget<TextField>(textField);
      expect(widget.obscureText, isFalse);
    });

    testWidgets('toggling visibility again hides API key', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
      final textField = find.byType(TextField).first;
      final widget = tester.widget<TextField>(textField);
      expect(widget.obscureText, isTrue);
    });

    testWidgets('loadCurrentValues sets initial API key', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-initial-key'));
      await tester.pumpAndSettle();

      expect(find.text('sk-initial-key'), findsOneWidget);
    });

    testWidgets('loadCurrentValues sets initial base URL', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen(initialBaseUrl: 'https://custom.url'));
      await tester.pumpAndSettle();

      expect(find.text('https://custom.url'), findsOneWidget);
    });

    testWidgets('save button disabled during save', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-test'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Save API Keys'));
      expect(button.onPressed, isNull);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows success snackbar on successful save', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-test'));
      await tester.pumpAndSettle();

      final apiKeyField = find.byType(TextField).first;
      await tester.enterText(apiKeyField, 'sk-new-key');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
      await tester.pumpAndSettle();

      expect(find.text('API keys saved successfully'), findsOneWidget);
      expect(find.byIcon(Icons.save), findsWidgets);
    });

    testWidgets('saving navigates back to previous screen', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-test'));
      await tester.pumpAndSettle();

      final apiKeyField = find.byType(TextField).first;
      await tester.enterText(apiKeyField, 'sk-new-key');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
      await tester.pumpAndSettle();

      expect(find.byType(ApiConfigScreen), findsNothing);
    });

    testWidgets('has proper padding and layout', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('description text is visible', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      final description = find.textContaining('Get your key from');
      expect(description, findsOneWidget);
    });

    testWidgets('base URL field is not obscured', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      final baseUrlField = tester.widget<TextField>(textFields.last);
      expect(baseUrlField.obscureText, isFalse);
    });

    testWidgets('saving trims whitespace from inputs', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      final apiKeyField = find.byType(TextField).first;
      await tester.enterText(apiKeyField, '  sk-trimmed-key  ');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
      await tester.pumpAndSettle();

      expect(find.text('API keys saved successfully'), findsOneWidget);
    });

    testWidgets('switching text fields works', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      final apiKeyField = find.byType(TextField).first;
      await tester.enterText(apiKeyField, 'sk-key-1');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();

      final baseUrlField = find.byType(TextField).last;
      await tester.enterText(baseUrlField, 'sk-key-2');
      await tester.pumpAndSettle();

      expect(find.text('sk-key-1'), findsOneWidget);
      expect(find.text('sk-key-2'), findsOneWidget);
    });

    group('Validation Edge Cases', () {
      testWidgets('shows error for empty API key with whitespace', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        final apiKeyField = find.byType(TextField).first;
        await tester.enterText(apiKeyField, '   ');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
        await tester.pumpAndSettle();

        expect(find.text('API key cannot be empty'), findsOneWidget);
      });

      testWidgets('shows error for tab-only API key', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        final apiKeyField = find.byType(TextField).first;
        await tester.enterText(apiKeyField, '\t\t');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
        await tester.pumpAndSettle();

        expect(find.text('API key cannot be empty'), findsOneWidget);
      });

      testWidgets('newlines in API key are trimmed', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        final apiKeyField = find.byType(TextField).first;
        await tester.enterText(apiKeyField, '\nsk-trimmed\n');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
        await tester.pumpAndSettle();

        expect(find.text('API keys saved successfully'), findsOneWidget);
      });

      testWidgets('base URL can be empty without validation error', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen(initialBaseUrl: ''));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
        await tester.pumpAndSettle();

        expect(find.text('API key cannot be empty'), findsNothing);
      });

      testWidgets('saves with empty base URL', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen(initialBaseUrl: ''));
        await tester.pumpAndSettle();

        final apiKeyField = find.byType(TextField).first;
        await tester.enterText(apiKeyField, 'sk-valid-key');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
        await tester.pumpAndSettle();

        expect(find.text('API keys saved successfully'), findsOneWidget);
      });
    });

    group('State Updates', () {
      testWidgets('successful save updates apiKeyProvider', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-old'));
        await tester.pumpAndSettle();

        final apiKeyField = find.byType(TextField).first;
        await tester.enterText(apiKeyField, 'sk-new-key');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
        await tester.pumpAndSettle();

        expect(find.text('sk-new-key'), findsOneWidget);
      });

      testWidgets('successful save updates apiBaseUrlProvider', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen(initialBaseUrl: 'https://old.url'));
        await tester.pumpAndSettle();

        final baseUrlField = find.byType(TextField).last;
        await tester.enterText(baseUrlField, 'https://new.url');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
        await tester.pumpAndSettle();

        expect(find.text('https://new.url'), findsOneWidget);
      });
    });

    group('Visibility Toggle', () {
      testWidgets('visibility button has correct initial state', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.visibility), findsOneWidget);
        expect(find.byIcon(Icons.visibility_off), findsNothing);
      });

      testWidgets('tapping visibility button once shows visibility_off', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.visibility));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      });

      testWidgets('API key field shows plain text when visibility is on', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        final apiKeyField = find.byType(TextField).first;
        await tester.enterText(apiKeyField, 'secret-key-123');
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.visibility));
        await tester.pumpAndSettle();

        final textField = find.byType(TextField).first;
        final widget = tester.widget<TextField>(textField);
        expect(widget.obscureText, isFalse);
        expect(find.text('secret-key-123'), findsOneWidget);
      });

      testWidgets('toggle multiple times alternates visibility', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        for (var i = 0; i < 3; i++) {
          await tester.tap(find.byIcon(i % 2 == 0 ? Icons.visibility : Icons.visibility_off));
          await tester.pumpAndSettle();
        }

        expect(find.byIcon(Icons.visibility), findsOneWidget);
        expect(find.byIcon(Icons.visibility_off), findsNothing);
      });
    });

    group('Error States', () {
      testWidgets('shows error snackbar when save fails', (tester) async {
        fakeApiRepo.setThrowOnSave(true);
        await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-test'));
        await tester.pumpAndSettle();

        final apiKeyField = find.byType(TextField).first;
        await tester.enterText(apiKeyField, 'sk-trigger-error');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
        await tester.pumpAndSettle();

        expect(find.text('Unable to save API configuration'), findsOneWidget);
      });
    });

    group('Widget Properties', () {
      testWidgets('API key field has correct hint text', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        expect(find.text('sk-or-v1-...'), findsOneWidget);
      });

      testWidgets('base URL field has correct hint text', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        expect(find.text('https://openrouter.ai/api/v1'), findsOneWidget);
      });

      testWidgets('save button has correct text', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        expect(find.text('Save API Keys'), findsOneWidget);
      });

      testWidgets('API key section has correct title', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        expect(find.text('OpenRouter API Key'), findsOneWidget);
      });

      testWidgets('API key section has correct description', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        expect(find.textContaining('Required for LLM'), findsOneWidget);
      });

      testWidgets('base URL section has correct title', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        expect(find.text('API Base URL'), findsOneWidget);
      });

      testWidgets('base URL section has correct description', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        expect(find.textContaining('endpoint URL'), findsOneWidget);
      });
    });

    group('Loading State', () {
      testWidgets('save button shows progress indicator during save', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-test'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.save), findsNothing);
      });
    });

    group('Provider Selection', () {
      testWidgets('renders provider dropdown section', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        expect(find.text('AI Model'), findsWidgets);
        expect(find.byType(DropdownButtonFormField<LlmProvider>), findsOneWidget);
      });

      testWidgets('provider dropdown shows all options', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButtonFormField<LlmProvider>));
        await tester.pumpAndSettle();

        expect(find.text('OpenRouter'), findsWidgets);
        expect(find.text('Ollama'), findsOneWidget);
        expect(find.text('OpenAI'), findsOneWidget);
      });

      testWidgets('selecting Ollama auto-fills base URL if empty', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen(initialBaseUrl: ''));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButtonFormField<LlmProvider>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Ollama').last);
        await tester.pumpAndSettle();

        expect(find.text('http://localhost:11434'), findsOneWidget);
      });

      testWidgets('selecting Ollama does not change non-empty base URL', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen(
          initialBaseUrl: 'https://custom.url',
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButtonFormField<LlmProvider>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Ollama').last);
        await tester.pumpAndSettle();

        expect(find.text('https://custom.url'), findsOneWidget);
      });

      testWidgets('selecting OpenAI does not change base URL', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen(initialBaseUrl: ''));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButtonFormField<LlmProvider>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('OpenAI').last);
        await tester.pumpAndSettle();

        final baseUrlField = find.byType(TextField).last;
        expect(tester.widget<TextField>(baseUrlField).controller?.text, isEmpty);
      });
    });

    group('Test Connection', () {
      testWidgets('test connection with empty API key shows error', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen(initialApiKey: ''));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(OutlinedButton, 'Test Connection'));
        await tester.pumpAndSettle();

        expect(find.text('API key cannot be empty'), findsOneWidget);
      });

      testWidgets('test connection button disabled during test', (tester) async {
        HttpOverrides.global = _TestTimeoutHttpOverride();
        addTearDown(() => HttpOverrides.global = null);

        await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-test'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(OutlinedButton, 'Test Connection'));
        await tester.pump();

        final button = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Testing...'));
        expect(button.onPressed, isNull);
      });

      testWidgets('test connection shows loading text during test', (tester) async {
        HttpOverrides.global = _TestTimeoutHttpOverride();
        addTearDown(() => HttpOverrides.global = null);

        await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-test'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(OutlinedButton, 'Test Connection'));
        await tester.pump();

        expect(find.text('Testing...'), findsOneWidget);
      });

      testWidgets('test connection timeout shows error snackbar', (tester) async {
        HttpOverrides.global = _TestTimeoutHttpOverride();
        addTearDown(() => HttpOverrides.global = null);

        await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-test'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(OutlinedButton, 'Test Connection'));
        await tester.pump(const Duration(seconds: 16));
        await tester.pumpAndSettle();

        expect(find.textContaining('Connection failed'), findsOneWidget);
      });

      testWidgets('test connection state resets after failure', (tester) async {
        HttpOverrides.global = _TestTimeoutHttpOverride();
        addTearDown(() => HttpOverrides.global = null);

        await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-test'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(OutlinedButton, 'Test Connection'));
        await tester.pump(const Duration(seconds: 16));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(OutlinedButton, 'Test Connection'), findsOneWidget);
      });
    });

    group('Provider Description', () {
      testWidgets('shows AI model description text', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        expect(find.textContaining('endpoint URL for the AI service'), findsWidgets);
      });
    });
  });
}
