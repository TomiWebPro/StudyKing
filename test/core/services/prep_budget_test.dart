import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import 'package:studyking/core/services/prep_budget.dart';

void main() {
  group('PrepCategory', () {
    test('taskTypeKey uses snake_case matching LlmUsageRecord.taskType', () {
      expect(PrepCategory.pdfIngestion.taskTypeKey, 'pdf_ingestion');
      expect(PrepCategory.questionVariants.taskTypeKey, 'question_variants');
      expect(PrepCategory.lessonPrep.taskTypeKey, 'lesson_prep');
      expect(PrepCategory.embeddings.taskTypeKey, 'embeddings');
      expect(PrepCategory.background.taskTypeKey, 'background');
    });

    test('background key matches the name recorded by background prep', () {
      // IdleExecutor backgrounds tasks under feature='background' and the LLM
      // service records taskType 'background', so the cap layer must read it
      // under the same key.
      expect(PrepCategory.background.taskTypeKey, 'background');
    });
  });

  group('PrepBudget', () {
    test('defaults are enabled with the vision §4.2 category split', () {
      const b = PrepBudget.defaults;
      expect(b.enabled, isTrue);
      // 40% / 30% / 20% / 10% of a 500k-token budget.
      expect(b.caps[PrepCategory.pdfIngestion], 200000);
      expect(b.caps[PrepCategory.questionVariants], 150000);
      expect(b.caps[PrepCategory.lessonPrep], 100000);
      expect(b.caps[PrepCategory.embeddings], 50000);
      expect(b.caps[PrepCategory.background], 50000);
    });

    test('remainingFor is the cap minus spend', () {
      const b = PrepBudget.defaults;
      final spent = {'embeddings': 12000};
      expect(b.remainingFor(PrepCategory.embeddings, spent), 50000 - 12000);
    });

    test('remainingFor clamps to zero once the cap is exhausted', () {
      const b = PrepBudget.defaults;
      final spent = {'embeddings': 50000};
      expect(b.remainingFor(PrepCategory.embeddings, spent), equals(0));
    });

    test('remainingFor for one category ignores spend in another', () {
      const b = PrepBudget.defaults;
      final spent = {'pdf_ingestion': 200000};
      expect(b.remainingFor(PrepCategory.questionVariants, spent), 150000);
    });

    test('canSpend allows within cap and denies over cap', () {
      const b = PrepBudget.defaults;
      final spent = {'pdf_ingestion': 190000};
      expect(b.canSpend(PrepCategory.pdfIngestion, 5000, spent), isTrue); // 195k <= 200k
      expect(b.canSpend(PrepCategory.pdfIngestion, 20000, spent), isFalse); // would exceed cap
    });

    test('canSpend ignores negative token requests as non-spend', () {
      const b = PrepBudget.defaults;
      expect(b.canSpend(PrepCategory.background, -1, <String, int>{}), isFalse);
    });

    test('canSpend denies everything when disabled (master switch off)', () {
      const b = PrepBudget.defaults;
      final disabled = b.copyWith(enabled: false);
      final spent = <String, int>{};
      expect(disabled.canSpend(PrepCategory.background, 1, spent), isFalse);
      expect(disabled.canSpend(PrepCategory.embeddings, 100, spent), isFalse);
    });

    test('copyWith replaces only the provided fields', () {
      const b = PrepBudget.defaults;
      final halved = b.copyWith(
        caps: {
          for (final c in PrepCategory.values) c: b.caps[c]!,
          PrepCategory.pdfIngestion: 100000, // halved from 200000
        },
      );
      expect(halved.caps[PrepCategory.pdfIngestion], 100000);
      expect(halved.caps[PrepCategory.questionVariants], 150000); // unchanged
      expect(halved.enabled, isTrue); // unchanged
    });

    // Vision §4.4 acceptance #2: halving one category's cap must not starve
    // the others — that is the whole point of per-category caps.
    test('halving a category cap keeps all other categories within cap', () {
      const b = PrepBudget.defaults;
      final halved = b.copyWith(
        caps: {
          for (final c in PrepCategory.values) c: b.caps[c]!,
          PrepCategory.pdfIngestion: 100000, // halved from 200000
        },
      );
      final spent = <String, int>{};
      // PDF at its (halved) cap now has 0 remaining.
      expect(
        halved.remainingFor(PrepCategory.pdfIngestion, {...spent, 'pdf_ingestion': 100000}),
        equals(0),
      );
      // Other categories are entirely unaffected by the PDF halve.
      expect(halved.remainingFor(PrepCategory.questionVariants, spent), 150000);
      expect(halved.remainingFor(PrepCategory.lessonPrep, spent), 100000);
      expect(halved.remainingFor(PrepCategory.embeddings, spent), 50000);
      // ...and they can still spend up to their full cap.
      expect(halved.canSpend(PrepCategory.questionVariants, 150000, spent), isTrue);
      expect(halved.canSpend(PrepCategory.lessonPrep, 100000, spent), isTrue);
    });
  });

  group('PrepBudgetService', () {
    test('remainingFor reads live spend from the meter by taskType', () {
      final meter = LlmUsageMeter();
      meter.recordUsage(
        id: 'u1',
        feature: 'prep',
        modelId: 'gpt-4',
        inputTokens: 3000,
        outputTokens: 1000,
        taskType: 'embeddings',
      ); // 4000 against a 50000 cap
      final service = PrepBudgetService(meter: meter);
      expect(service.remainingFor(PrepCategory.embeddings), 50000 - 4000);
    });

    test('canSpend denies once a category cap is exceeded', () {
      final meter = LlmUsageMeter();
      meter.recordUsage(
        id: 'u1',
        feature: 'prep',
        modelId: 'gpt-4',
        inputTokens: 200000,
        outputTokens: 0,
        taskType: 'pdf_ingestion',
      ); // exactly at cap
      final service = PrepBudgetService(meter: meter);
      expect(service.canSpend(PrepCategory.pdfIngestion, 1), isFalse);
      expect(service.remainingFor(PrepCategory.pdfIngestion), equals(0));
    });

    test('spendingByCategory maps meter aggregates to recognised categories', () {
      final meter = LlmUsageMeter();
      meter.recordUsage(
        id: 'u1',
        feature: 'prep',
        modelId: 'gpt-4',
        inputTokens: 10000,
        outputTokens: 5000,
        taskType: 'question_variants',
      );
      // An unrecognised task type must not be attributed to any category.
      meter.recordUsage(
        id: 'u2',
        feature: 'prep',
        modelId: 'gpt-4',
        inputTokens: 1000,
        outputTokens: 0,
        taskType: 'unknown_thing',
      );
      final service = PrepBudgetService(meter: meter);
      final spent = service.spendingByCategory();
      expect(spent[PrepCategory.questionVariants], 15000);
      expect(spent[PrepCategory.background], 0);
    });

    test('costByCategory maps meter cost aggregates to recognised categories', () {
      final meter = LlmUsageMeter();
      meter.recordUsage(
        id: 'u1',
        feature: 'prep',
        modelId: 'gpt-4',
        inputTokens: 100000,
        outputTokens: 50000,
        taskType: 'embeddings',
      );
      final service = PrepBudgetService(meter: meter);
      final costs = service.costByCategory();
      expect(costs[PrepCategory.embeddings], greaterThan(0));
      expect(costs[PrepCategory.pdfIngestion], equals(0.0));
    });

    test('custom budget overrides the defaults', () {
      final meter = LlmUsageMeter();
      final custom = PrepBudget(
        enabled: true,
        caps: {PrepCategory.embeddings: 1000},
      );
      final service = PrepBudgetService(meter: meter, budget: custom);
      expect(service.remainingFor(PrepCategory.embeddings), 1000);
    });

    test('disabled service denies all spend', () {
      final meter = LlmUsageMeter();
      final service = PrepBudgetService(
        meter: meter,
        budget: PrepBudget.defaults.copyWith(enabled: false),
      );
      expect(service.canSpend(PrepCategory.background, 10), isFalse);
    });
  });
}
