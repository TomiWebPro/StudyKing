import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'onboarding_storage.dart';

class OnboardingService {
  static final Logger _logger = const Logger('OnboardingService');

  static const String onboardingKey = 'onboarding_completed';
  static const String dontShowAgainKey = 'onboarding_dont_show_again';

  final OnboardingStorage _storage;

  OnboardingService({OnboardingStorage? storage})
      : _storage = storage ?? HiveOnboardingStorage();

  Future<Result<bool>> isOnboardingNeeded() async {
    try {
      final completed = await _storage.getBool(onboardingKey);
      final dontShow = await _storage.getBool(dontShowAgainKey);
      return Result.success(!completed && !dontShow);
    } catch (e) {
      _logger.w('Failed to check onboarding needed: $e');
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> markCompleted() async {
    try {
      await _storage.setBool(onboardingKey, true);
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to mark onboarding completed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> markDontShowAgain() async {
    try {
      await _storage.setBool(dontShowAgainKey, true);
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to mark onboarding dont show again', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> isFirstLaunch() async {
    try {
      final completed = await _storage.getBool(onboardingKey);
      return Result.success(!completed);
    } catch (e) {
      _logger.w('Failed to check first launch: $e');
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> resetOnboarding() async {
    try {
      await _storage.setBool(onboardingKey, false);
      await _storage.setBool(dontShowAgainKey, false);
      _logger.w('Onboarding has been reset');
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to reset onboarding: $e');
      return Result.failure(e.toString());
    }
  }
}
