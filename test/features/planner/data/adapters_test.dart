import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/planner/data/adapters.dart';

void main() {
  group('registerPlannerAdapters', () {
    test('registers all adapters when not already registered', () {
      registerPlannerAdapters();
      expect(Hive.isAdapterRegistered(19), isTrue);
      expect(Hive.isAdapterRegistered(20), isTrue);
      expect(Hive.isAdapterRegistered(21), isTrue);
      expect(Hive.isAdapterRegistered(22), isTrue);
      expect(Hive.isAdapterRegistered(23), isTrue);
      expect(Hive.isAdapterRegistered(30), isTrue);
    });

    test('is idempotent when called multiple times', () {
      expect(() => registerPlannerAdapters(), returnsNormally);
      expect(() => registerPlannerAdapters(), returnsNormally);
      expect(Hive.isAdapterRegistered(19), isTrue);
      expect(Hive.isAdapterRegistered(20), isTrue);
      expect(Hive.isAdapterRegistered(21), isTrue);
      expect(Hive.isAdapterRegistered(22), isTrue);
      expect(Hive.isAdapterRegistered(23), isTrue);
      expect(Hive.isAdapterRegistered(30), isTrue);
    });
  });
}
