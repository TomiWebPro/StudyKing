import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/teaching/data/adapters.dart';

void main() {
  group('registerTeachingAdapters', () {
    test('registers both adapters when not already registered', () {
      registerTeachingAdapters();
      expect(Hive.isAdapterRegistered(27), isTrue);
      expect(Hive.isAdapterRegistered(28), isTrue);
    });

    test('is idempotent when called multiple times', () {
      expect(() => registerTeachingAdapters(), returnsNormally);
      expect(() => registerTeachingAdapters(), returnsNormally);
      expect(Hive.isAdapterRegistered(27), isTrue);
      expect(Hive.isAdapterRegistered(28), isTrue);
    });
  });
}
