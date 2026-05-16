import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:studyking/features/settings/data/models/accessibility_preferences.dart';
import 'package:studyking/features/settings/data/models/user_profile_model.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';

void main() {
  group('UserProfileAdapter', () {
    test('typeId is 10', () {
      expect(UserProfileAdapter().typeId, 10);
    });

    test('hashCode and equality', () {
      expect(UserProfileAdapter().hashCode, 10.hashCode);
      expect(UserProfileAdapter() == UserProfileAdapter(), isTrue);
      expect(UserProfileAdapter().runtimeType == SettingsBoxAdapter().runtimeType, isFalse);
    });

    test('write/read round-trips full user profile', () {
      final adapter = UserProfileAdapter();
      final source = UserProfile(
        id: 'adapter-test',
        name: 'Adapter User',
        studentId: 'ST-001',
        avatarIcon: 'https://example.com/avatar.png',
        learningGoal: 'Learn Testing',
        preferredStudyTime: 'Anytime',
        notificationsEnabled: false,
        language: 'es',
        accessibilityPrefs: AccessibilityPreferences(boldText: true),
      );

      final registry = TypeRegistryImpl()
        ..registerAdapter(AccessibilityPreferencesAdapter());
      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, source.id);
      expect(restored.name, source.name);
      expect(restored.studentId, source.studentId);
      expect(restored.avatarIcon, source.avatarIcon);
      expect(restored.learningGoal, source.learningGoal);
      expect(restored.preferredStudyTime, source.preferredStudyTime);
      expect(restored.notificationsEnabled, source.notificationsEnabled);
      expect(restored.language, source.language);
      expect(restored.accessibilityPrefs?.toJson(), source.accessibilityPrefs?.toJson());
    });

    test('write/read with minimal fields', () {
      final adapter = UserProfileAdapter();
      final source = UserProfile(id: 'min', name: 'Minimal');

      final registry = TypeRegistryImpl()
        ..registerAdapter(AccessibilityPreferencesAdapter());
      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, 'min');
      expect(restored.name, 'Minimal');
      expect(restored.studentId, isNull);
      expect(restored.avatarIcon, isNull);
      expect(restored.learningGoal, isNull);
      expect(restored.preferredStudyTime, isNull);
      expect(restored.notificationsEnabled, isTrue);
      expect(restored.language, 'en');
      expect(restored.accessibilityPrefs, isNull);
    });
  });
}
