import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/user_profile_model.dart';

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

  group('ProfileData', () {
    test('serializes/deserializes full and default values', () {
      final profile = ProfileData(
        id: 'u1',
        name: 'Tomi',
        studentId: 'S123',
        avatarIcon: 'book',
        learningGoal: 'Math',
        preferredStudyTime: 'evening',
        notificationsEnabled: false,
        language: 'fr',
      );

      final json = profile.toJson();
      final restored = ProfileData.fromJson(json);

      expect(restored.id, 'u1');
      expect(restored.name, 'Tomi');
      expect(restored.studentId, 'S123');
      expect(restored.avatarIcon, 'book');
      expect(restored.learningGoal, 'Math');
      expect(restored.preferredStudyTime, 'evening');
      expect(restored.notificationsEnabled, isFalse);
      expect(restored.language, 'fr');

      final withDefaults = ProfileData.fromJson({});
      expect(withDefaults.id, '');
      expect(withDefaults.name, '');
      expect(withDefaults.notificationsEnabled, isTrue);
      expect(withDefaults.language, 'en');
    });

    test('toString contains key fields', () {
      final profile = ProfileData(id: 'u2', name: 'Ana', studentId: 'A-1');
      expect(profile.toString(), 'ProfileData(id: u2, name: Ana, studentId: A-1)');
    });
  });

  group('UserProfile', () {
    test('toJson/fromJson round-trip and defaults', () {
      final profile = UserProfile(
        id: 'p1',
        name: 'Neo',
        studentId: 'ST-1',
        avatarUrl: 'https://img',
        learningGoal: 'Physics',
        preferredStudyTime: 'morning',
        notificationsEnabled: false,
        language: 'es',
        accessibilitySettings: 'large-text',
      );

      final json = profile.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.id, profile.id);
      expect(restored.name, profile.name);
      expect(restored.studentId, profile.studentId);
      expect(restored.avatarUrl, profile.avatarUrl);
      expect(restored.learningGoal, profile.learningGoal);
      expect(restored.preferredStudyTime, profile.preferredStudyTime);
      expect(restored.notificationsEnabled, isFalse);
      expect(restored.language, 'es');
      expect(restored.accessibilitySettings, 'large-text');

      final withDefaults = UserProfile.fromJson({'id': 'p2', 'name': 'Default'});
      expect(withDefaults.notificationsEnabled, isTrue);
      expect(withDefaults.language, 'en');
      expect(withDefaults.accessibilitySettings, 'default');
    });

    test('copyWith preserves unspecified values and overrides provided', () {
      final profile = UserProfile(
        id: 'p1',
        name: 'Neo',
        studentId: 'ST-1',
        avatarUrl: 'https://img',
        learningGoal: 'Physics',
        preferredStudyTime: 'morning',
        notificationsEnabled: true,
        language: 'en',
        accessibilitySettings: 'default',
      );

      final copy = profile.copyWith(
        name: 'Trinity',
        notificationsEnabled: false,
        language: 'de',
      );

      expect(copy.id, 'p1');
      expect(copy.name, 'Trinity');
      expect(copy.studentId, 'ST-1');
      expect(copy.avatarUrl, 'https://img');
      expect(copy.learningGoal, 'Physics');
      expect(copy.preferredStudyTime, 'morning');
      expect(copy.notificationsEnabled, isFalse);
      expect(copy.language, 'de');
      expect(copy.accessibilitySettings, 'default');
    });
  });

  group('Hive adapters', () {
    test('SettingsBoxAdapter writes/reads all fields and equality', () {
      final adapter = SettingsBoxAdapter();
      final source = SettingsBox(
        apiKey: 'secret-key',
        apiBaseUrl: 'https://api.example.com',
        selectedModel: 'model-x',
        themeMode: 2,
        fontSize: 18.5,
        totalSessionCount: 12,
        totalStudyTimeMs: 99000,
        totalQuestions: 42,
      );

      final writer = BinaryWriterImpl(TypeRegistryImpl.nullImpl);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), TypeRegistryImpl.nullImpl);
      final restored = adapter.read(reader);

      expect(restored.toJson(), source.toJson());
      expect(adapter.typeId, 4);
      expect(adapter.hashCode, 4.hashCode);
      expect(adapter == SettingsBoxAdapter(), isTrue);
      expect(adapter, isNot(isA<ProfileDataAdapter>()));
    });

    test('ProfileDataAdapter writes/reads all fields and equality', () {
      final adapter = ProfileDataAdapter();
      final source = ProfileData(
        id: 'u1',
        name: 'Tomi',
        studentId: 'S123',
        avatarIcon: 'book',
        learningGoal: 'Math',
        preferredStudyTime: 'evening',
        notificationsEnabled: false,
        language: 'fr',
      );

      final writer = BinaryWriterImpl(TypeRegistryImpl.nullImpl);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), TypeRegistryImpl.nullImpl);
      final restored = adapter.read(reader);

      expect(restored.toJson(), source.toJson());
      expect(adapter.typeId, 5);
      expect(adapter.hashCode, 5.hashCode);
      expect(adapter == ProfileDataAdapter(), isTrue);
      expect(adapter, isNot(isA<SettingsBoxAdapter>()));
    });
  });

  testWidgets('SettingsBox theme mode is usable in widgets', (tester) async {
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
}
