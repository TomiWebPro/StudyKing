import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';

class OnboardingService {
  static const String _onboardingKey = 'onboarding_completed';
  static const String _dontShowAgainKey = 'onboarding_dont_show_again';

  /// Test-only: when set, all operations use this map instead of Hive.
  static Map<String, dynamic>? _testStorage;

  /// Inject a test storage map. Set to null to restore Hive-backed behavior.
  static void setTestStorage(Map<String, dynamic>? storage) {
    _testStorage = storage;
  }

  static Future<bool> isOnboardingNeeded() async {
    if (_testStorage != null) {
      final completed = _testStorage![_onboardingKey] as bool? ?? false;
      final dontShow = _testStorage![_dontShowAgainKey] as bool? ?? false;
      return !completed && !dontShow;
    }
    final box = await Hive.openBox(HiveBoxNames.settings);
    final completed = box.get(_onboardingKey, defaultValue: false) as bool;
    final dontShow = box.get(_dontShowAgainKey, defaultValue: false) as bool;
    return !completed && !dontShow;
  }

  static Future<void> markCompleted() async {
    if (_testStorage != null) {
      _testStorage![_onboardingKey] = true;
      return;
    }
    final box = await Hive.openBox(HiveBoxNames.settings);
    await box.put(_onboardingKey, true);
  }

  static Future<void> markDontShowAgain() async {
    if (_testStorage != null) {
      _testStorage![_dontShowAgainKey] = true;
      return;
    }
    final box = await Hive.openBox(HiveBoxNames.settings);
    await box.put(_dontShowAgainKey, true);
  }

  static Future<bool> isFirstLaunch() async {
    if (_testStorage != null) {
      return !(_testStorage![_onboardingKey] as bool? ?? false);
    }
    final box = await Hive.openBox(HiveBoxNames.settings);
    return !(box.get(_onboardingKey, defaultValue: false) as bool);
  }
}
