import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/practice/data/adapters.dart';

void main() {
  group('registerPracticeAdapters', () {
    test('registers all three adapters when not already registered', () {
      registerPracticeAdapters();
      expect(Hive.isAdapterRegistered(16), isTrue);
      expect(Hive.isAdapterRegistered(18), isTrue);
      expect(Hive.isAdapterRegistered(31), isTrue);
    });

    test('is idempotent when called multiple times', () {
      expect(() => registerPracticeAdapters(), returnsNormally);
      expect(() => registerPracticeAdapters(), returnsNormally);
      expect(Hive.isAdapterRegistered(16), isTrue);
      expect(Hive.isAdapterRegistered(18), isTrue);
      expect(Hive.isAdapterRegistered(31), isTrue);
    });
  });
}
