import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/onboarding/services/onboarding_storage.dart';

void main() {
  late InMemoryOnboardingStorage storage;

  setUp(() {
    storage = InMemoryOnboardingStorage();
  });

  group('InMemoryOnboardingStorage', () {
    group('getBool', () {
      test('returns defaultValue when key does not exist', () async {
        expect(await storage.getBool('missing'), isFalse);
      });

      test('returns custom defaultValue when key does not exist', () async {
        expect(await storage.getBool('missing', defaultValue: true), isTrue);
      });

      test('returns stored value after setBool', () async {
        await storage.setBool('onboarded', true);
        expect(await storage.getBool('onboarded'), isTrue);
      });

      test('returns false after setting false', () async {
        await storage.setBool('onboarded', true);
        await storage.setBool('onboarded', false);
        expect(await storage.getBool('onboarded'), isFalse);
      });

      test('returns true for multiple keys independently', () async {
        await storage.setBool('a', true);
        await storage.setBool('b', false);
        expect(await storage.getBool('a'), isTrue);
        expect(await storage.getBool('b'), isFalse);
      });
    });

    group('setBool', () {
      test('overwrites existing value', () async {
        await storage.setBool('flag', true);
        await storage.setBool('flag', false);
        expect(await storage.getBool('flag'), isFalse);
      });

      test('does not affect other keys', () async {
        await storage.setBool('x', true);
        await storage.setBool('y', true);
        expect(await storage.getBool('x'), isTrue);
        expect(await storage.getBool('z', defaultValue: false), isFalse);
      });
    });

    group('error handling', () {
      test('getBool with non-boolean stored value returns defaultValue', () async {
        storage.store['corrupt'] = 'not_a_bool';
        expect(await storage.getBool('corrupt'), isFalse);
      });

      test('setBool then getBool roundtrip for false value', () async {
        await storage.setBool('feature_flag', false);
        expect(await storage.getBool('feature_flag'), isFalse);
      });

      test('multiple false values work correctly', () async {
        await storage.setBool('a', false);
        await storage.setBool('b', false);
        expect(await storage.getBool('a'), isFalse);
        expect(await storage.getBool('b'), isFalse);
      });
    });
  });
}
