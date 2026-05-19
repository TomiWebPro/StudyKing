import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/onboarding/services/onboarding_service.dart';
import 'package:studyking/features/onboarding/services/onboarding_storage.dart';

void main() {
  group('OnboardingService isOnboardingNeeded', () {
    setUp(() {
      OnboardingService.setStorage(InMemoryOnboardingStorage());
    });

    tearDown(() {
      OnboardingService.setStorage(HiveOnboardingStorage());
    });

    test('returns true when no flags are set', () async {
      expect(await OnboardingService.isOnboardingNeeded(), isTrue);
    });
  });
}
