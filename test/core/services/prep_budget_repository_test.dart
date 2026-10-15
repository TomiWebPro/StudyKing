import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/core/services/prep_budget_repository.dart';

void main() {
  group('PrepBudgetRepository', () {
    late PrepBudgetRepository repo;

    setUp(() async {
      await Hive.openBox(HiveBoxNames.settings);
      await Hive.box(HiveBoxNames.settings).clear();
      repo = PrepBudgetRepository();
    });

    test('init opens the settings box', () async {
      final result = await repo.init();
      expect(result.isSuccess, isTrue);
    });

    test('load returns defaults when no keys persisted', () async {
      await repo.init();
      final result = repo.load();
      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.enabled, isTrue);
      expect(result.data!.caps[PrepCategory.pdfIngestion], 200000);
      expect(result.data!.caps[PrepCategory.questionVariants], 150000);
      expect(result.data!.caps[PrepCategory.lessonPrep], 100000);
      expect(result.data!.caps[PrepCategory.embeddings], 50000);
      expect(result.data!.caps[PrepCategory.background], 50000);
    });

    test('save then load round-trips the budget', () async {
      await repo.init();
      final budget = PrepBudget.defaults.copyWith(enabled: false, caps: {
        for (final c in PrepCategory.values) c: 100000,
      });
      final saveResult = await repo.save(budget);
      expect(saveResult.isSuccess, isTrue);

      final repo2 = PrepBudgetRepository();
      await repo2.init();
      final loadResult = repo2.load();
      expect(loadResult.isSuccess, isTrue);
      expect(loadResult.data, isNotNull);
      expect(loadResult.data!.enabled, isFalse);
      expect(loadResult.data!.caps[PrepCategory.pdfIngestion], 100000);
    });

    test('save stores enabled flag and caps as raw keys', () async {
      await repo.init();
      final budget = PrepBudget(
        enabled: false,
        caps: {PrepCategory.background: 25000},
      );
      final result = await repo.save(budget);
      expect(result.isSuccess, isTrue);

      final box = Hive.box(HiveBoxNames.settings);
      expect(box.get('prepBudgetEnabled'), isFalse);
      final caps = box.get('prepBudgetCaps') as Map?;
      expect(caps, isNotNull);
      expect(caps!['pdf_ingestion'] is int || caps['pdf_ingestion'] is num, isTrue);
    });

    test('load fills missing categories from defaults', () async {
      await repo.init();
      final box = Hive.box(HiveBoxNames.settings);
      await box.put('prepBudgetEnabled', true);
      // Only persist one category; others must fall back to defaults.
      await box.put('prepBudgetCaps', {'embeddings': 75000});

      final result = repo.load();
      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.enabled, isTrue);
      expect(result.data!.caps[PrepCategory.embeddings], 75000);
      // Missing categories fall back to defaults.
      expect(result.data!.caps[PrepCategory.pdfIngestion], 200000);
      expect(result.data!.caps[PrepCategory.background], 50000);
    });

    test('load returns defaults when box is not open', () {
      final repo2 = PrepBudgetRepository();
      // No init call, so _box is null.
      final result = repo2.load();
      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.enabled, isTrue);
      expect(result.data!.caps[PrepCategory.pdfIngestion], 200000);
    });

    test('save fails when box is not open', () async {
      final repo2 = PrepBudgetRepository();
      // No init call, so _box is null.
      final result = await repo2.save(PrepBudget.defaults);
      expect(result.isFailure, isTrue);
    });
  });
}
