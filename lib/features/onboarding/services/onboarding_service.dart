import 'onboarding_storage.dart';

class OnboardingService {
  static const String onboardingKey = 'onboarding_completed';
  static const String dontShowAgainKey = 'onboarding_dont_show_again';

  static OnboardingStorage _storage = HiveOnboardingStorage();

  /// Replace the storage backend (used for test injection).
  static void setStorage(OnboardingStorage storage) {
    _storage = storage;
  }

  static Future<bool> isOnboardingNeeded() async {
    final completed = await _storage.getBool(onboardingKey);
    final dontShow = await _storage.getBool(dontShowAgainKey);
    return !completed && !dontShow;
  }

  static Future<void> markCompleted() async {
    await _storage.setBool(onboardingKey, true);
  }

  static Future<void> markDontShowAgain() async {
    await _storage.setBool(dontShowAgainKey, true);
  }

  static Future<bool> isFirstLaunch() async {
    final completed = await _storage.getBool(onboardingKey);
    return !completed;
  }
}
