import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/practice/data/adapters.dart';
import 'package:studyking/features/practice/data/adapters/mastery_improvement_adapter.dart';
import 'package:studyking/features/practice/data/adapters/mastery_state_adapter.dart';
import 'package:studyking/features/practice/data/adapters/question_mastery_state_adapter.dart';
import '../../../helpers/hive_test_utils.dart';

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

  group('MasteryStateAdapter', () {
    test('has correct typeId', () {
      expect(MasteryStateAdapter().typeId, 16);
    });

    test('is a TypeAdapter<MasteryState>', () {
      expect(MasteryStateAdapter(), isA<TypeAdapter>());
    });
  });

  group('QuestionMasteryStateAdapter', () {
    test('has correct typeId', () {
      expect(QuestionMasteryStateAdapter().typeId, 18);
    });

    test('is a TypeAdapter<QuestionMasteryState>', () {
      expect(QuestionMasteryStateAdapter(), isA<TypeAdapter>());
    });
  });

  group('MasteryImprovementMetricAdapter', () {
    test('has correct typeId', () {
      expect(MasteryImprovementMetricAdapter().typeId, 31);
    });

    test('is a TypeAdapter<MasteryImprovementMetric>', () {
      expect(MasteryImprovementMetricAdapter(), isA<TypeAdapter>());
    });
  });

  group('adapters integration with real Hive', () {
    late String hivePath;

    setUpAll(() async {
      hivePath = await HiveTestHelper.initHive();
    });

    tearDownAll(() async {
      await HiveTestHelper.cleanHive(hivePath);
    });

    test('can open and read from Hive box after adapter registration', () async {
      registerPracticeAdapters();
      final box = await Hive.openBox<int>('test_adapters_box');
      await box.put('key1', 42);
      expect(box.get('key1'), 42);
      await box.close();
      await Hive.deleteBoxFromDisk('test_adapters_box');
    });
  });
}
