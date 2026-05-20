import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/onboarding/services/onboarding_service.dart';

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService();
});

final onboardingNeededProvider = FutureProvider<bool>((ref) async {
  final result = await ref.read(onboardingServiceProvider).isOnboardingNeeded();
  return result.data ?? true;
});

final isFirstLaunchProvider = FutureProvider<bool>((ref) async {
  final result = await ref.read(onboardingServiceProvider).isFirstLaunch();
  return result.data ?? true;
});
