import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/onboarding/onboarding.dart';

void main() {
  group('Onboarding barrel', () {
    setUp(() {
      OnboardingService.setTestStorage({});
    });

    tearDown(() {
      OnboardingService.setTestStorage(null);
    });

    test('OnboardingService returns true for isOnboardingNeeded initially', () async {
      expect(await OnboardingService.isOnboardingNeeded(), isTrue);
    });

    test('OnboardingDialog is accessible', () {
      expect(OnboardingDialog, isA<Type>());
    });

    test('ApiKeyBanner is accessible', () {
      expect(ApiKeyBanner, isA<Type>());
    });

    test('LocalDataNotice is accessible', () {
      expect(LocalDataNotice, isA<Type>());
    });
  });
}
