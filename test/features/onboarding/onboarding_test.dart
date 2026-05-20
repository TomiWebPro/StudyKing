import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/onboarding/services/onboarding_service.dart';
import 'package:studyking/features/onboarding/services/onboarding_storage.dart';

void main() {
  group('OnboardingService isOnboardingNeeded', () {
    late OnboardingService service;

    setUp(() {
      service = OnboardingService(storage: InMemoryOnboardingStorage());
    });

    test('returns true when no flags are set', () async {
      final result = await service.isOnboardingNeeded();
      expect(result.data, isTrue);
    });
  });
}
