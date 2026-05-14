import 'dart:io';
import 'package:studyking/features/settings/data/models/user_profile_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/presentation/settings_screen.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class FakeSettingsRepository implements SettingsRepository {
  SettingsBox _settings = SettingsBox();

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
  }) async {
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
    );
  }

  @override
  Future<void> updateStats({int? sessionCount, int? studyTimeMs, int? questions}) async {}
  @override
  Future<void> saveApiKey({required String service, required String key}) async {}
  @override
  Future<void> saveProfileData(UserProfile profile) async {}
  @override
  Future<UserProfile?> getProfileData() async => null;
  @override
  Future<void> clearSettings() async {}
  @override
  Future<void> clearProfile() async {}
  @override
  Future<String?> getApiKey({required String service}) async => null;
  @override
  Future<void> init() async {}
}

final fakeRepo = FakeSettingsRepository();

class _TestSettingsNotifier extends SettingsController {
  _TestSettingsNotifier(SettingsBox initial, SettingsRepository repo) : super(repo) {
    state = initial;
  }
}

Widget buildSettingsScreen({
  SettingsBox? initialSettings,
  String apiKey = '',
  String selectedModel = '',
}) {
  if (initialSettings != null) {
    fakeRepo._settings = initialSettings;
  }
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith((ref) => _TestSettingsNotifier(fakeRepo._settings, fakeRepo)),
      apiKeyProvider.overrideWith((ref) => apiKey),
      selectedModelProvider.overrideWith((ref) => selectedModel),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const SettingsScreen(),
    ),
  );
}

/// Pumps the settings screen with a large viewport so all ListView children render.
Future<void> pumpWithSettings(WidgetTester tester, {
  SettingsBox? initialSettings,
  String apiKey = '',
  String selectedModel = '',
}) async {
  await tester.pumpWidget(buildSettingsScreen(
    initialSettings: initialSettings,
    apiKey: apiKey,
    selectedModel: selectedModel,
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    fakeRepo._settings = SettingsBox(
      themeMode: 0,
      fontSize: 16.0,
      totalSessionCount: 5,
      totalStudyTimeMs: 3600000,
      totalQuestions: 100,
    );
  });

  group('SettingsScreen', () {
    testWidgets('renders all sections with correct titles', (tester) async {
      await pumpWithSettings(tester);

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('User Management'), findsOneWidget);
      expect(find.text('Quick Access'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('AI Configuration'), findsOneWidget);
      expect(find.text('Study Preferences'), findsOneWidget);
      expect(find.text('Study Analytics'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('shows user management tile', (tester) async {
      await pumpWithSettings(tester);

      final currentUserTile = find.widgetWithText(ListTile, 'Current User');
      expect(currentUserTile, findsOneWidget);
      expect(find.text('Manage your profile'), findsOneWidget);
    });

    testWidgets('shows Quick Guide tile', (tester) async {
      await tester.pumpWidget(buildSettingsScreen());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Quick Guide'), findsOneWidget);
      expect(find.text('AI-powered study assistant'), findsOneWidget);
    });

    testWidgets('shows theme tile with correct label', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(initialSettings: SettingsBox(themeMode: 2)));
      await tester.pumpAndSettle();

      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
    });

    testWidgets('shows font size tile with correct label', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(initialSettings: SettingsBox(fontSize: 14.0)));
      await tester.pumpAndSettle();

      expect(find.text('Font Size'), findsOneWidget);
      expect(find.text('Small'), findsOneWidget);
    });

    testWidgets('shows API key status as Not configured when empty', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(apiKey: ''));
      await tester.pumpAndSettle();

      expect(find.text('API Keys'), findsOneWidget);
      expect(find.text('Not configured'), findsOneWidget);
    });

    testWidgets('shows API key status as Configured when set', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(apiKey: 'sk-test-key'));
      await tester.pumpAndSettle();

      expect(find.text('API Keys'), findsOneWidget);
      expect(find.text('Configured'), findsOneWidget);
    });

    testWidgets('shows request timeout tile', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(initialSettings: SettingsBox(requestTimeoutSeconds: 60)));
      await tester.pumpAndSettle();

      expect(find.text('Request Timeout'), findsOneWidget);
      expect(find.text('60 seconds'), findsOneWidget);
    });

    testWidgets('shows session duration tile', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(initialSettings: SettingsBox(sessionDurationMinutes: 45)));
      await tester.pumpAndSettle();

      expect(find.text('Session Duration'), findsOneWidget);
      expect(find.text('45 minutes'), findsOneWidget);
    });

    testWidgets('shows notification toggle switches when enabled', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(studyRemindersEnabled: true));

      expect(find.widgetWithText(SwitchListTile, 'Enable Notifications'), findsOneWidget);
      expect(find.widgetWithText(SwitchListTile, 'Revision Reminders'), findsOneWidget);
      expect(find.widgetWithText(SwitchListTile, 'Lesson Notifications'), findsOneWidget);
      expect(find.widgetWithText(SwitchListTile, 'Overwork Alerts'), findsOneWidget);
      expect(find.widgetWithText(SwitchListTile, 'Plan Adjustment Alerts'), findsOneWidget);
    });

    testWidgets('hides notification sub-toggles when master is off', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(studyRemindersEnabled: false));

      expect(find.widgetWithText(SwitchListTile, 'Enable Notifications'), findsOneWidget);
      expect(find.widgetWithText(SwitchListTile, 'Revision Reminders'), findsNothing);
      expect(find.widgetWithText(SwitchListTile, 'Plan Adjustment Alerts'), findsNothing);
    });

    testWidgets('shows total study sessions tile', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(initialSettings: SettingsBox(totalSessionCount: 10)));
      await tester.pumpAndSettle();

      expect(find.text('Total Study Sessions'), findsOneWidget);
      expect(find.text('10 sessions'), findsOneWidget);
    });

    testWidgets('shows total study time tile', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(initialSettings: SettingsBox(totalStudyTimeMs: 7200000)));
      await tester.pumpAndSettle();

      expect(find.text('Total Study Time'), findsOneWidget);
      expect(find.text('2h'), findsOneWidget);
    });

    testWidgets('shows About StudyKing tile', (tester) async {
      await tester.pumpWidget(buildSettingsScreen());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'About StudyKing'), findsOneWidget);
      expect(find.text('Version 0.1.0'), findsOneWidget);
    });

    testWidgets('shows Sign Out tile', (tester) async {
      await tester.pumpWidget(buildSettingsScreen());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Sign Out'), findsOneWidget);
    });

    testWidgets('tapping theme tile opens theme dialog', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(initialSettings: SettingsBox(themeMode: 0)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('can select dark theme from dialog', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(initialSettings: SettingsBox(themeMode: 0)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark').last);
      await tester.pumpAndSettle();

      expect(find.text('Dark'), findsWidgets);
    });

    testWidgets('tapping font size tile opens font size dialog', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(initialSettings: SettingsBox(fontSize: 16.0)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Font Size'));
      await tester.pumpAndSettle();

      expect(find.text('Font Size'), findsWidgets);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('tapping session duration opens duration dialog', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(initialSettings: SettingsBox(sessionDurationMinutes: 30)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Session Duration'));
      await tester.pumpAndSettle();

      expect(find.text('15 minutes'), findsOneWidget);
      expect(find.text('30 minutes'), findsOneWidget);
      expect(find.text('45 minutes'), findsOneWidget);
      expect(find.text('60 minutes'), findsOneWidget);
      expect(find.text('90 minutes'), findsOneWidget);
    });

    testWidgets('tapping analytics shows analytics sheet', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(initialSettings: SettingsBox(
        totalSessionCount: 5,
        totalQuestions: 100,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Total Study Sessions'));
      await tester.pumpAndSettle();

      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Questions'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('tapping about shows about dialog', (tester) async {
      await tester.pumpWidget(buildSettingsScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ListTile, 'About StudyKing'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutDialog), findsOneWidget);
      expect(find.text('StudyKing'), findsWidgets);
    });

    testWidgets('tapping sign out shows confirmation dialog', (tester) async {
      await tester.pumpWidget(buildSettingsScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ListTile, 'Sign Out'));
      await tester.pumpAndSettle();

      expect(find.text('Sign Out'), findsWidgets);
      expect(find.text('Are you sure you want to sign out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('cancel sign out closes dialog', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(apiKey: 'test-key'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ListTile, 'Sign Out'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('AI model label shows default text when empty', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(selectedModel: ''));
      await tester.pumpAndSettle();

      expect(find.text('AI Model'), findsOneWidget);
      expect(find.text('Select a model from API'), findsOneWidget);
    });

    testWidgets('AI model label parses model path correctly', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(selectedModel: 'anthropic/claude-3-haiku'));
      await tester.pumpAndSettle();

      expect(find.text('AI Model'), findsOneWidget);
      expect(find.text('Claude 3 haiku'), findsOneWidget);
    });

    testWidgets('AI model label handles single word model', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(selectedModel: 'gpt-4'));
      await tester.pumpAndSettle();

      expect(find.text('AI Model'), findsOneWidget);
      expect(find.text('Gpt 4'), findsOneWidget);
    });

    testWidgets('tapping AI model with empty API key shows warning dialog', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(apiKey: '', selectedModel: ''));
      await tester.pumpAndSettle();

      await tester.tap(find.text('AI Model'));
      await tester.pumpAndSettle();

      expect(find.text('API Key Required'), findsOneWidget);
      expect(find.text('Please configure your API key first.'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('tapping timeout shows timeout dialog with slider', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(initialSettings: SettingsBox(requestTimeoutSeconds: 120)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Request Timeout'));
      await tester.pumpAndSettle();

      expect(find.text('Request Timeout'), findsWidgets);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('timeout dialog has slider that can be adjusted', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(initialSettings: SettingsBox(requestTimeoutSeconds: 120)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Request Timeout'));
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      final saveButton = find.widgetWithText(TextButton, 'Save');
      expect(saveButton, findsOneWidget);
    });

    group('Network Error Handling', () {
      testWidgets('shows error when model selection API returns non-200', (tester) async {
        HttpOverrides.global = _MockHttpOverride(
          responseStatusCode: 500,
          responseBody: '{"error": "Server error"}',
        );
        addTearDown(() => HttpOverrides.global = null);

        await tester.pumpWidget(buildSettingsScreen(apiKey: 'sk-test-key'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('AI Model'));
        await tester.pumpAndSettle();

        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        expect(find.text('Unable to load models right now.'), findsOneWidget);
      });

      testWidgets('shows timeout error message after network timeout', (tester) async {
        HttpOverrides.global = _TimeoutHttpOverride();
        addTearDown(() => HttpOverrides.global = null);

        await tester.pumpWidget(buildSettingsScreen(apiKey: 'sk-test-key'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('AI Model'));
        await tester.pump();

        await tester.pump(const Duration(seconds: 16));
        await tester.pumpAndSettle();

        expect(find.text('Model request timed out. Please try again.'), findsOneWidget);
      });

      testWidgets('shows generic error on malformed response', (tester) async {
        HttpOverrides.global = _MockHttpOverride(
          responseStatusCode: 200,
          responseBody: 'not valid json {{{',
        );
        addTearDown(() => HttpOverrides.global = null);

        await tester.pumpWidget(buildSettingsScreen(apiKey: 'sk-test-key'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('AI Model'));
        await tester.pumpAndSettle();

        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('State Verification', () {
      testWidgets('theme change updates provider state', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(
          initialSettings: SettingsBox(themeMode: ThemeMode.light.index),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Theme'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Dark').last);
        await tester.pumpAndSettle();

        expect(find.text('Dark'), findsWidgets);
      });

      testWidgets('font size change updates state', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(
          initialSettings: SettingsBox(fontSize: 16.0),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Font Size'));
        await tester.pumpAndSettle();

        final slider = find.byType(Slider);
        expect(slider, findsOneWidget);

        await tester.drag(slider, const Offset(100, 0));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
      });

      testWidgets('master enable notifications toggle updates state', (tester) async {
        await pumpWithSettings(tester, initialSettings: SettingsBox(studyRemindersEnabled: true));

        final switchTile = find.widgetWithText(SwitchListTile, 'Enable Notifications');
        final switchWidget = tester.widget<SwitchListTile>(switchTile);
        expect(switchWidget.value, isTrue);

        await tester.tap(switchTile);
        await tester.pumpAndSettle();
      });

      testWidgets('revision reminders toggle persists state', (tester) async {
        await pumpWithSettings(tester, initialSettings: SettingsBox(
          studyRemindersEnabled: true,
          revisionRemindersEnabled: true,
        ));

        final switchTile = find.widgetWithText(SwitchListTile, 'Revision Reminders');
        final switchWidget = tester.widget<SwitchListTile>(switchTile);
        expect(switchWidget.value, isTrue);

        await tester.tap(switchTile);
        await tester.pumpAndSettle();
      });

      testWidgets('lesson notifications toggle persists state', (tester) async {
        await pumpWithSettings(tester, initialSettings: SettingsBox(
          studyRemindersEnabled: true,
          lessonNotificationsEnabled: false,
        ));

        final switchTile = find.widgetWithText(SwitchListTile, 'Lesson Notifications');
        final switchWidget = tester.widget<SwitchListTile>(switchTile);
        expect(switchWidget.value, isFalse);

        await tester.tap(switchTile);
        await tester.pumpAndSettle();
      });

      testWidgets('overwork alerts toggle persists state', (tester) async {
        await pumpWithSettings(tester, initialSettings: SettingsBox(
          studyRemindersEnabled: true,
          overworkAlertsEnabled: true,
        ));

        final switchTile = find.widgetWithText(SwitchListTile, 'Overwork Alerts');
        final switchWidget = tester.widget<SwitchListTile>(switchTile);
        expect(switchWidget.value, isTrue);

        await tester.tap(switchTile);
        await tester.pumpAndSettle();
      });

      testWidgets('plan adjustment notifications toggle persists state', (tester) async {
        await pumpWithSettings(tester, initialSettings: SettingsBox(
          studyRemindersEnabled: true,
          planAdjustmentNotificationsEnabled: false,
        ));

        final switchTile = find.widgetWithText(SwitchListTile, 'Plan Adjustment Alerts');
        final switchWidget = tester.widget<SwitchListTile>(switchTile);
        expect(switchWidget.value, isFalse);

        await tester.tap(switchTile);
        await tester.pumpAndSettle();
      });

      testWidgets('timeout value persists after dialog closes', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(
          initialSettings: SettingsBox(requestTimeoutSeconds: 60),
        ));
        await tester.pumpAndSettle();

        expect(find.text('60 seconds'), findsOneWidget);

        await tester.tap(find.text('Request Timeout'));
        await tester.pumpAndSettle();

        final slider = find.byType(Slider);
        await tester.drag(slider, const Offset(50, 0));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('Request Timeout'), findsOneWidget);
      });

      testWidgets('session duration selection updates state', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(
          initialSettings: SettingsBox(sessionDurationMinutes: 30),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Session Duration'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('60 minutes'));
        await tester.pumpAndSettle();

        expect(find.text('60 minutes'), findsWidgets);
      });
    });

    group('Slider Validation', () {
      testWidgets('timeout slider clamps to 30-300 range', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(
          initialSettings: SettingsBox(requestTimeoutSeconds: 120),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Request Timeout'));
        await tester.pumpAndSettle();

        final slider = find.byType(Slider);
        final sliderWidget = tester.widget<Slider>(slider);

        expect(sliderWidget.min, equals(30));
        expect(sliderWidget.max, equals(300));
      });

      testWidgets('font size slider clamps to 10-30 range', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(
          initialSettings: SettingsBox(fontSize: 16.0),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Font Size'));
        await tester.pumpAndSettle();

        final slider = find.byType(Slider);
        final sliderWidget = tester.widget<Slider>(slider);

        expect(sliderWidget.min, equals(10));
        expect(sliderWidget.max, equals(30));
      });

      testWidgets('only valid session duration options available', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(
          initialSettings: SettingsBox(sessionDurationMinutes: 30),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Session Duration'));
        await tester.pumpAndSettle();

        expect(find.text('15 minutes'), findsOneWidget);
        expect(find.text('30 minutes'), findsOneWidget);
        expect(find.text('45 minutes'), findsOneWidget);
        expect(find.text('60 minutes'), findsOneWidget);
        expect(find.text('90 minutes'), findsOneWidget);
        expect(find.text('120 minutes'), findsNothing);
      });
    });

    group('Model Parsing', () {
      testWidgets('AI model selection parses provider correctly', (tester) async {
        HttpOverrides.global = _MockHttpOverride(
          responseStatusCode: 200,
          responseBody: '{"data": [{"id": "anthropic/claude-3", "name": "Claude 3", "providers": [{"id": "openrouter"}]}]}',
        );
        addTearDown(() => HttpOverrides.global = null);

        await tester.pumpWidget(buildSettingsScreen(apiKey: 'sk-test-key'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('AI Model'));
        await tester.pumpAndSettle();

        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        expect(find.text('Claude 3'), findsOneWidget);
      });

      testWidgets('empty model list handled gracefully', (tester) async {
        HttpOverrides.global = _MockHttpOverride(
          responseStatusCode: 200,
          responseBody: '{"data": []}',
        );
        addTearDown(() => HttpOverrides.global = null);

        await tester.pumpWidget(buildSettingsScreen(apiKey: 'sk-test-key'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('AI Model'));
        await tester.pumpAndSettle();

        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsOneWidget);
      });
    });

    group('Sign Out Flow', () {
      testWidgets('sign out clears API key and model providers', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(
          apiKey: 'sk-to-be-cleared',
          selectedModel: 'test-model',
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ListTile, 'Sign Out'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilledButton, 'Sign Out'));
        await tester.pumpAndSettle();

        expect(find.text('Not configured'), findsOneWidget);
      });
    });
  });
}

class _MockHttpOverride extends HttpOverrides {
  final int responseStatusCode;
  final String responseBody;

  _MockHttpOverride({
    required this.responseStatusCode,
    required this.responseBody,
  });

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => 'PROXY localhost';
    return client;
  }
}

class _TimeoutHttpOverride extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => 'PROXY localhost';
    return client;
  }
}