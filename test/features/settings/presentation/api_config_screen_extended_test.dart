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

  group('ApiConfigScreen - Backup Provider Section', () {
    testWidgets('renders backup provider section', (tester) async {
      await pumpApiConfigScreen(tester);

      expect(find.text('Backup Provider'), findsOneWidget);
      expect(find.textContaining('Optional secondary AI provider'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders backup API key section', (tester) async {
      await pumpApiConfigScreen(tester);

      expect(find.text('Backup API Key'), findsOneWidget);
    });

    testWidgets('renders backup base URL section', (tester) async {
      await pumpApiConfigScreen(tester);

      expect(find.text('Backup Base URL'), findsOneWidget);
    });

    testWidgets('renders backup model section', (tester) async {
      await pumpApiConfigScreen(tester);

      expect(find.text('Backup Model'), findsOneWidget);
      expect(find.text('e.g., gpt-4o-mini'), findsOneWidget);
    });

    testWidgets('backup provider dropdown shows all options', (tester) async {
      await pumpApiConfigScreen(tester);

      final dropdowns = find.byType(DropdownButtonFormField<LlmProvider>);
      expect(dropdowns, findsNWidgets(2));

      await tester.tap(dropdowns.last);
      await tester.pumpAndSettle();

      expect(find.text('OpenRouter'), findsWidgets);
      expect(find.text('Ollama'), findsWidgets);
      expect(find.text('OpenAI'), findsWidgets);
    });

    testWidgets('selecting Ollama as backup auto-fills empty backup base URL', (tester) async {
      await pumpApiConfigScreen(tester, initialBackupBaseUrl: '');

      final dropdowns = find.byType(DropdownButtonFormField<LlmProvider>);
      await tester.tap(dropdowns.last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ollama').last);
      await tester.pumpAndSettle();

      expect(find.text('http://localhost:11434'), findsWidgets);
    });

    testWidgets('selecting OpenAI as backup auto-fills empty backup base URL', (tester) async {
      await pumpApiConfigScreen(tester, initialBackupBaseUrl: '');

      final dropdowns = find.byType(DropdownButtonFormField<LlmProvider>);
      await tester.tap(dropdowns.last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('OpenAI').last);
      await tester.pumpAndSettle();

      expect(find.text('https://api.openai.com/v1'), findsWidgets);
    });

    testWidgets('backup provider dropdown does not change non-empty backup base URL', (tester) async {
      await pumpApiConfigScreen(tester, initialBackupBaseUrl: 'https://custom.backup.url');

      final dropdowns = find.byType(DropdownButtonFormField<LlmProvider>);
      await tester.tap(dropdowns.last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ollama').last);
      await tester.pumpAndSettle();

      expect(find.text('https://custom.backup.url'), findsOneWidget);
    });

    testWidgets('backup API key field is obscured by default', (tester) async {
      await pumpApiConfigScreen(tester);

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(5));

      final backupApiKeyField = tester.widget<TextField>(textFields.at(2));
      expect(backupApiKeyField.obscureText, isTrue);
    });

    testWidgets('can type in backup API key field', (tester) async {
      await pumpApiConfigScreen(tester);

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(2), 'sk-backup-key');
      await tester.pumpAndSettle();

      expect(find.text('sk-backup-key'), findsOneWidget);
    });

    testWidgets('can type in backup base URL field', (tester) async {
      await pumpApiConfigScreen(tester);

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(3), 'https://backup.api.url');
      await tester.pumpAndSettle();

      expect(find.text('https://backup.api.url'), findsOneWidget);
    });

    testWidgets('can type in backup model field', (tester) async {
      await pumpApiConfigScreen(tester);

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(4), 'gpt-4');
      await tester.pumpAndSettle();

      expect(find.text('gpt-4'), findsOneWidget);
    });

    testWidgets('loads backup provider values from providers', (tester) async {
      await pumpApiConfigScreen(tester,
        initialBackupApiKey: 'sk-backup-existing',
        initialBackupBaseUrl: 'https://backup.url',
        initialBackupModel: 'gpt-4',
      );

      expect(find.text('sk-backup-existing'), findsOneWidget);
      expect(find.text('https://backup.url'), findsOneWidget);
      expect(find.text('gpt-4'), findsOneWidget);
    });
  });

  group('ApiConfigScreen - Setup Guide', () {
    testWidgets('shows provider setup guide icons', (tester) async {
      await pumpApiConfigScreen(tester);

      expect(find.byIcon(Icons.help_outline), findsAtLeastNWidgets(2));
      expect(find.textContaining('How to get started with'), findsAtLeastNWidgets(2));
    });
  });

  group('ApiConfigScreen - Connection Test', () {
    testWidgets('test connection button exists and is enabled with non-empty key', (tester) async {
      await pumpApiConfigScreen(tester, initialApiKey: 'sk-test-key');

      final testButton = find.widgetWithText(OutlinedButton, 'Test Connection');
      expect(testButton, findsOneWidget);

      final button = tester.widget<OutlinedButton>(testButton);
      expect(button.onPressed, isNotNull);
    });
  });

  group('ApiConfigScreen - Unsaved Changes', () {
    testWidgets('shows unsaved changes dialog when back is pressed with changes', (tester) async {
      await pumpApiConfigScreen(tester);

      final apiKeyField = find.byType(TextField).first;
      await tester.enterText(apiKeyField, 'new-api-key');
      await tester.pumpAndSettle();

      final backButton = find.byTooltip('Back');
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        expect(find.text('Unsaved Changes'), findsOneWidget);
        expect(find.text('Discard'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      }
    });

    testWidgets('cancel on unsaved changes keeps user on screen', (tester) async {
      await pumpApiConfigScreen(tester);

      final apiKeyField = find.byType(TextField).first;
      await tester.enterText(apiKeyField, 'new-api-key');
      await tester.pumpAndSettle();

      final backButton = find.byTooltip('Back');
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.byType(ApiConfigScreen), findsOneWidget);
      }
    });

    testWidgets('discard on unsaved changes navigates back', (tester) async {
      final navigatorObserver = TestNavigatorObserver();
      await pumpApiConfigScreen(tester, navigatorObserver: navigatorObserver);

      final apiKeyField = find.byType(TextField).first;
      await tester.enterText(apiKeyField, 'new-api-key');
      await tester.pumpAndSettle();

      final backButton = find.byTooltip('Back');
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Discard'));
        await tester.pumpAndSettle();

        expect(navigatorObserver.poppedRoutes, isNotEmpty);
      }
    });
  });

  group('ApiConfigScreen - Backup Visibility Toggle', () {
    testWidgets('shows two visibility icons for main and backup API keys', (tester) async {
      await pumpApiConfigScreen(tester);

      expect(find.byIcon(Icons.visibility), findsNWidgets(2));
    });

    testWidgets('tapping backup visibility toggle shows visibility_off', (tester) async {
      await pumpApiConfigScreen(tester);

      await scrollToWidget(tester, find.text('Backup API Key'));
      await tester.pumpAndSettle();

      final visibilityIcons = find.byIcon(Icons.visibility);
      expect(visibilityIcons, findsNWidgets(2));

      await tester.ensureVisible(visibilityIcons.last);
      await tester.pumpAndSettle();

      await tester.tap(visibilityIcons.last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byIcon(Icons.visibility_off).last);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off), findsAtLeastNWidgets(1));
    });
  });
}


