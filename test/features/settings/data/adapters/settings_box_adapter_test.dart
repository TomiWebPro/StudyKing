import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/user_profile_model.dart';

void main() {
  group('SettingsBoxAdapter', () {
    test('typeId is 4', () {
      expect(SettingsBoxAdapter().typeId, 4);
    });

    test('hashCode and equality', () {
      expect(SettingsBoxAdapter().hashCode, 4.hashCode);
      expect(SettingsBoxAdapter() == SettingsBoxAdapter(), isTrue);
      expect(SettingsBoxAdapter().runtimeType == UserProfileAdapter().runtimeType, isFalse);
    });

    test('write/read round-trips full settings', () {
      final adapter = SettingsBoxAdapter();
      final source = SettingsBox(
        apiKey: 'test-key',
        apiBaseUrl: 'https://api.test.com',
        selectedModel: 'gpt-4',
        themeMode: 1,
        fontSize: 18.0,
        totalSessionCount: 15,
        totalStudyTimeMs: 7200000,
        totalQuestions: 300,
        studyRemindersEnabled: false,
        requestTimeoutSeconds: 60,
        sessionDurationMinutes: 45,
        highContrastEnabled: true,
        largeTouchTargets: false,
        reduceMotion: true,
        revisionRemindersEnabled: false,
        lessonNotificationsEnabled: false,
        overworkAlertsEnabled: true,
        planAdjustmentNotificationsEnabled: false,
      );

      final writer = BinaryWriterImpl(TypeRegistryImpl.nullImpl);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), TypeRegistryImpl.nullImpl);
      final restored = adapter.read(reader);

      expect(restored.apiKey, source.apiKey);
      expect(restored.apiBaseUrl, source.apiBaseUrl);
      expect(restored.selectedModel, source.selectedModel);
      expect(restored.themeMode, source.themeMode);
      expect(restored.fontSize, source.fontSize);
      expect(restored.totalSessionCount, source.totalSessionCount);
      expect(restored.totalStudyTimeMs, source.totalStudyTimeMs);
      expect(restored.totalQuestions, source.totalQuestions);
      expect(restored.studyRemindersEnabled, source.studyRemindersEnabled);
      expect(restored.requestTimeoutSeconds, source.requestTimeoutSeconds);
      expect(restored.sessionDurationMinutes, source.sessionDurationMinutes);
      expect(restored.highContrastEnabled, source.highContrastEnabled);
      expect(restored.largeTouchTargets, source.largeTouchTargets);
      expect(restored.reduceMotion, source.reduceMotion);
      expect(restored.revisionRemindersEnabled, source.revisionRemindersEnabled);
      expect(restored.lessonNotificationsEnabled, source.lessonNotificationsEnabled);
      expect(restored.overworkAlertsEnabled, source.overworkAlertsEnabled);
      expect(restored.planAdjustmentNotificationsEnabled, source.planAdjustmentNotificationsEnabled);
    });

    test('write/read with defaults', () {
      final adapter = SettingsBoxAdapter();
      final source = SettingsBox();

      final writer = BinaryWriterImpl(TypeRegistryImpl.nullImpl);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), TypeRegistryImpl.nullImpl);
      final restored = adapter.read(reader);

      expect(restored.apiKey, '');
      expect(restored.apiBaseUrl, 'https://openrouter.ai/api/v1');
      expect(restored.themeMode, 0);
      expect(restored.fontSize, 16.0);
    });
  });
}
