import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/onboarding/services/onboarding_service.dart';

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService();
});

final onboardingNeededProvider = FutureProvider<bool>((ref) async {
  return OnboardingService.isOnboardingNeeded();
});

final isFirstLaunchProvider = FutureProvider<bool>((ref) async {
  return OnboardingService.isFirstLaunch();
});
