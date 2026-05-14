import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';

void main() {
  group('SettingsBox', () {
    test('uses constructor defaults', () {
      final settings = SettingsBox();

      expect(settings.apiKey, '');
      expect(settings.apiBaseUrl, 'https://openrouter.ai/api/v1');
      expect(settings.selectedModel, '');
      expect(settings.themeMode, 0);
      expect(settings.fontSize, 16.0);
      expect(settings.totalSessionCount, 0);
      expect(settings.totalStudyTimeMs, 0);
      expect(settings.totalQuestions, 0);
      expect(settings.themeModeEnum, ThemeMode.system);
    });

    test('maps theme mode safely including fallback', () {
      final settings = SettingsBox(themeMode: 1);
      expect(settings.themeModeEnum, ThemeMode.light);

      settings.setThemeMode(ThemeMode.dark);
      expect(settings.themeMode, ThemeMode.dark.index);
      expect(settings.themeModeEnum, ThemeMode.dark);

      settings.themeMode = 99;
      expect(settings.themeModeEnum, ThemeMode.light);
    });

    test('serializes and deserializes json with values', () {
      final settings = SettingsBox(
        apiKey: 'secret-key',
        apiBaseUrl: 'https://api.example.com',
        selectedModel: 'model-x',
        themeMode: 2,
        fontSize: 18.5,
        totalSessionCount: 12,
        totalStudyTimeMs: 99000,
        totalQuestions: 42,
      );

      final json = settings.toJson();
      final restored = SettingsBox.fromJson(json);

      expect(restored.apiKey, settings.apiKey);
      expect(restored.apiBaseUrl, settings.apiBaseUrl);
      expect(restored.selectedModel, settings.selectedModel);
      expect(restored.themeMode, settings.themeMode);
      expect(restored.fontSize, settings.fontSize);
      expect(restored.totalSessionCount, settings.totalSessionCount);
      expect(restored.totalStudyTimeMs, settings.totalStudyTimeMs);
      expect(restored.totalQuestions, settings.totalQuestions);
      expect(restored.revisionRemindersEnabled, settings.revisionRemindersEnabled);
      expect(restored.lessonNotificationsEnabled, settings.lessonNotificationsEnabled);
      expect(restored.overworkAlertsEnabled, settings.overworkAlertsEnabled);
      expect(restored.planAdjustmentNotificationsEnabled, settings.planAdjustmentNotificationsEnabled);
    });

    test('serializes and deserializes notification preference fields', () {
      final settings = SettingsBox(
        revisionRemindersEnabled: false,
        lessonNotificationsEnabled: false,
        overworkAlertsEnabled: true,
        planAdjustmentNotificationsEnabled: false,
      );

      final json = settings.toJson();
      final restored = SettingsBox.fromJson(json);

      expect(restored.revisionRemindersEnabled, isFalse);
      expect(restored.lessonNotificationsEnabled, isFalse);
      expect(restored.overworkAlertsEnabled, isTrue);
      expect(restored.planAdjustmentNotificationsEnabled, isFalse);
    });

    test('fromJson applies defaults for missing/null values', () {
      final restored = SettingsBox.fromJson({
        'apiKey': null,
        'apiBaseUrl': null,
        'selectedModel': null,
        'themeMode': null,
        'fontSize': null,
        'totalSessionCount': null,
        'totalStudyTimeMs': null,
        'totalQuestions': null,
      });

      expect(restored.apiKey, '');
      expect(restored.apiBaseUrl, 'https://openrouter.ai/api/v1');
      expect(restored.selectedModel, '');
      expect(restored.themeMode, 0);
      expect(restored.fontSize, 16.0);
      expect(restored.totalSessionCount, 0);
      expect(restored.totalStudyTimeMs, 0);
      expect(restored.totalQuestions, 0);
    });

    test('toString masks api key and includes readable values', () {
      final hidden = SettingsBox(apiKey: '', themeMode: 1, fontSize: 15.6);
      final shown = SettingsBox(apiKey: 'abcdefgh12345678', themeMode: 2, fontSize: 21.2);

      expect(hidden.toString(), contains('(hidden)'));
      expect(hidden.toString(), contains('ThemeMode.light'));
      expect(hidden.toString(), contains('16px'));

      expect(shown.toString(), contains('(hidden)'));
      expect(shown.toString(), contains('ThemeMode.dark'));
      expect(shown.toString(), contains('21px'));
    });
  });

  group('SettingsBox constructor fields', () {
    test('sets studyRemindersEnabled from constructor', () {
      final settings = SettingsBox(studyRemindersEnabled: false);
      expect(settings.studyRemindersEnabled, isFalse);
    });

    test('sets reduceMotion from constructor', () {
      final settings = SettingsBox(reduceMotion: true);
      expect(settings.reduceMotion, isTrue);
    });

    test('sets largeTouchTargets from constructor', () {
      final settings = SettingsBox(largeTouchTargets: true);
      expect(settings.largeTouchTargets, isTrue);
    });

    test('sets revisionRemindersEnabled from constructor', () {
      final settings = SettingsBox(revisionRemindersEnabled: false);
      expect(settings.revisionRemindersEnabled, isFalse);
    });

    test('sets lessonNotificationsEnabled from constructor', () {
      final settings = SettingsBox(lessonNotificationsEnabled: false);
      expect(settings.lessonNotificationsEnabled, isFalse);
    });

    test('sets overworkAlertsEnabled from constructor', () {
      final settings = SettingsBox(overworkAlertsEnabled: false);
      expect(settings.overworkAlertsEnabled, isFalse);
    });

    test('sets planAdjustmentNotificationsEnabled from constructor', () {
      final settings = SettingsBox(planAdjustmentNotificationsEnabled: false);
      expect(settings.planAdjustmentNotificationsEnabled, isFalse);
    });
  });

  group('SettingsBox widget usage', () {
    testWidgets('theme mode is usable in widgets', (tester) async {
      final settings = SettingsBox(themeMode: ThemeMode.dark.index);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: settings.themeModeEnum,
          home: const Scaffold(body: Text('Settings')),
        ),
      );

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
