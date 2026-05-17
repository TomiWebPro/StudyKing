import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/onboarding/presentation/onboarding_dialog.dart';

void main() {
  group('Onboarding barrel', () {
    test('OnboardingService is accessible', () {
      expect(OnboardingService, isNotNull);
    });

    test('OnboardingDialog is accessible', () {
      expect(OnboardingDialog, isNotNull);
    });

    test('ApiKeyBanner is accessible', () {
      expect(ApiKeyBanner, isNotNull);
    });

    test('LocalDataNotice is accessible', () {
      expect(LocalDataNotice, isNotNull);
    });
  });
}
