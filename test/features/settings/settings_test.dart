import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/settings.dart';

void main() {
  group('settings barrel', () {
    test('exports AccessibilityPreferences', () => expect(AccessibilityPreferences, isNotNull));
    test('exports SettingsBox', () => expect(SettingsBox, isNotNull));
    test('exports LLMSettingsModel', () => expect(LLMSettingsModel, isNotNull));
    test('exports UserProfile', () => expect(UserProfile, isNotNull));
    test('exports SettingsRepository', () => expect(SettingsRepository, isNotNull));
    test('exports ApiConfigScreen', () => expect(ApiConfigScreen, isNotNull));
    test('exports ProfileScreen', () => expect(ProfileScreen, isNotNull));
    test('exports SettingsScreen', () => expect(SettingsScreen, isNotNull));
  });
}
