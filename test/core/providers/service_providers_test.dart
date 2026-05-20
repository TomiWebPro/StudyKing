import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/providers/service_providers.dart';
import '../../helpers/fakes.dart';

void main() {
  group('service_providers', () {
    test('voiceServiceProvider creates VoiceService', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      final service = container.read(voiceServiceProvider);
      expect(service, isNotNull);
    });

    test('studentIdServiceProvider creates StudentIdService', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      final service = container.read(studentIdServiceProvider);
      expect(service, isNotNull);
    });

    test('studentIdValueProvider returns empty string before init', () async {
      final fakeIdService = FakeStudentIdService();
      final container = ProviderContainer(
        overrides: [
          studentIdServiceProvider.overrideWithValue(fakeIdService),
        ],
      );
      addTearDown(() => container.dispose());
      final value = container.read(studentIdValueProvider);
      expect(value, '');
    });

    test('same studentIdService instance across reads', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      final a = container.read(studentIdServiceProvider);
      final b = container.read(studentIdServiceProvider);
      expect(identical(a, b), isTrue);
    });
  });
}
