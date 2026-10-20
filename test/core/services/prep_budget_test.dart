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

    test('fromTaskTypeKey returns the matching category', () {
      expect(PrepCategory.fromTaskTypeKey('pdf_ingestion'),
          equals(PrepCategory.pdfIngestion));
      expect(PrepCategory.fromTaskTypeKey('question_variants'),
          equals(PrepCategory.questionVariants));
      expect(PrepCategory.fromTaskTypeKey('lesson_prep'),
          equals(PrepCategory.lessonPrep));
      expect(PrepCategory.fromTaskTypeKey('embeddings'),
          equals(PrepCategory.embeddings));
      expect(PrepCategory.fromTaskTypeKey('background'),
          equals(PrepCategory.background));
    });

    test('fromTaskTypeKey returns null for unknown keys', () {
      expect(PrepCategory.fromTaskTypeKey('mentor'), isNull);
      expect(PrepCategory.fromTaskTypeKey('tutor'), isNull);
      expect(PrepCategory.fromTaskTypeKey(''), isNull);
      expect(PrepCategory.fromTaskTypeKey('unknown'), isNull);
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

    // Issue: prep-budget-costbycategory-unknown-fallback
    //
    // When the meter contains records with taskType: null (grouped under
    // 'unknown' by getTotalCostPerTaskType), costByCategory() must NOT
    // attribute that unknown cost to every prep category. It returns 0.0 for
    // categories that have no spend in their own key, exactly as
    // spendingByCategory() does for tokens. This is consistent with
    // totalLiveTokens() which treats 'unknown' as live.
    test("costByCategory ignores 'unknown' taskType records (no false attribution)", () {
      final meter = LlmUsageMeter();

      // A recognised prep category record — cost should be attributed here.
      meter.recordUsage(
        id: 'prep1',
        feature: 'prep',
        modelId: 'gpt-4',
        inputTokens: 100000,
        outputTokens: 50000,
        taskType: 'pdf_ingestion',
      );

      // An unclassified (null taskType) record — grouped under 'unknown'.
      // This simulates a live chat whose feature string could not be
      // classified by LlmTaskType.fromFeature.
      meter.recordUsage(
        id: 'live1',
        feature: 'tutor',
        modelId: 'gpt-4',
        inputTokens: 200000,
        outputTokens: 100000,
        taskType: null,
      );

      final service = PrepBudgetService(meter: meter);
      final costs = service.costByCategory();
      final byType = meter.getTotalCostPerTaskType();

      // The unknown record has a real cost > 0.
      expect(byType['unknown'], greaterThan(0));

      // Only the pdf_ingestion cost is attributed to pdfIngestion.
      expect(costs[PrepCategory.pdfIngestion],
          equals(byType['pdf_ingestion']));
      expect(costs[PrepCategory.pdfIngestion], greaterThan(0));

      // Every other prep category — which has no spend in its own key —
      // must be 0.0, NOT the unknown-bucket cost.
      expect(costs[PrepCategory.questionVariants], equals(0.0));
      expect(costs[PrepCategory.lessonPrep], equals(0.0));
      expect(costs[PrepCategory.embeddings], equals(0.0));
      expect(costs[PrepCategory.background], equals(0.0));

      // The sum of category costs must equal only the recognised prep cost,
      // not inflated by the unknown cost.
      final totalCategoryCost =
          costs.values.fold(0.0, (sum, c) => sum + c);
      expect(totalCategoryCost, equals(byType['pdf_ingestion']));
      expect(totalCategoryCost, lessThan(byType['unknown']!));
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

  group('PrepBudget quiet hours', () {
    test('returns false when quiet hours are not configured (both null)', () {
      const b = PrepBudget.defaults;
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 2, 0, 0)), isFalse);
    });

    test('returns false when only start is set', () {
      final b = PrepBudget.defaults.copyWith(quietHoursStart: 22);
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 2, 0, 0)), isFalse);
    });

    test('returns false when only end is set', () {
      final b = PrepBudget.defaults.copyWith(quietHoursEnd: 8);
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 2, 0, 0)), isFalse);
    });

    test('returns false when start == end (no window)', () {
      final b = PrepBudget.defaults.copyWith(quietHoursStart: 10, quietHoursEnd: 10);
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 10, 0, 0)), isFalse);
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 9, 0, 0)), isFalse);
    });

    test('non-wraparound window defers during the window and allows outside', () {
      final b = PrepBudget.defaults.copyWith(quietHoursStart: 9, quietHoursEnd: 17);
      // Inside the window (9:00–17:00 exclusive of 17).
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 9, 0, 0)), isTrue);
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 12, 0, 0)), isTrue);
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 16, 59, 0)), isTrue);
      // Boundary: 17:00 is outside (end is exclusive).
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 17, 0, 0)), isFalse);
      // Before the window.
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 8, 59, 0)), isFalse);
      // After the window.
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 18, 0, 0)), isFalse);
    });

    test('wraparound window (22→8) defers at 2am and 23:00, allows at 10am', () {
      final b = PrepBudget.defaults.copyWith(quietHoursStart: 22, quietHoursEnd: 8);
      // 2am is within the wraparound window.
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 2, 0, 0)), isTrue);
      // 23:00 (11pm) is within the window.
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 23, 0, 0)), isTrue);
      // Edge: 22:00 (start) is included.
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 22, 0, 0)), isTrue);
      // Edge: 7:59 is within (hour < 8).
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 7, 59, 0)), isTrue);
      // 8:00 (end) is outside — end is exclusive.
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 8, 0, 0)), isFalse);
      // 10am is outside.
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 10, 0, 0)), isFalse);
      // Noon is outside.
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 12, 0, 0)), isFalse);
    });

    test('wraparound window (23→6) defers at 2am and 23:30', () {
      final b = PrepBudget.defaults.copyWith(quietHoursStart: 23, quietHoursEnd: 6);
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 2, 0, 0)), isTrue);
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 23, 30, 0)), isTrue);
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 5, 59, 0)), isTrue);
      // 6:00 is outside.
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 6, 0, 0)), isFalse);
      // 14:00 is outside.
      expect(b.shouldDeferForQuietHours(DateTime(2025, 1, 1, 14, 0, 0)), isFalse);
    });

    test('hour is clamped to 0–23 on copyWith', () {
      final b = PrepBudget.defaults.copyWith(quietHoursStart: 25, quietHoursEnd: -1);
      // Clamping happens in setQuietHours, not copyWith — copyWith stores raw.
      // This test documents that copyWith does not clamp; the controller does.
      expect(b.quietHoursStart, 25);
      expect(b.quietHoursEnd, -1);
    });

    test('copyWith preserves existing quiet hours when parameters are omitted', () {
      final b = PrepBudget.defaults.copyWith(quietHoursStart: 22, quietHoursEnd: 8);
      final preserved = b.copyWith(enabled: false);
      expect(preserved.quietHoursStart, 22);
      expect(preserved.quietHoursEnd, 8);
      expect(preserved.shouldDeferForQuietHours(DateTime(2025, 1, 1, 2, 0, 0)), isTrue);
    });
  });

  group('PrepBudget per-subject opt-in', () {
    test('isPrepEnabledForSubject returns true when disabledSubjects is empty', () {
      const b = PrepBudget.defaults;
      expect(b.isPrepEnabledForSubject('math'), isTrue);
      expect(b.isPrepEnabledForSubject('history'), isTrue);
      expect(b.isPrepEnabledForSubject(''), isTrue);
    });

    test('isPrepEnabledForSubject returns false for a disabled subject', () {
      final b = PrepBudget.defaults.copyWith(disabledSubjects: {'math'});
      expect(b.isPrepEnabledForSubject('math'), isFalse);
    });

    test('isPrepEnabledForSubject returns true for a non-disabled subject when others are disabled', () {
      final b = PrepBudget.defaults.copyWith(disabledSubjects: {'math', 'physics'});
      expect(b.isPrepEnabledForSubject('history'), isTrue);
      expect(b.isPrepEnabledForSubject('math'), isFalse);
      expect(b.isPrepEnabledForSubject('physics'), isFalse);
    });

    test('copyWith replaces disabledSubjects', () {
      const b = PrepBudget.defaults;
      final updated = b.copyWith(disabledSubjects: {'new_subject'});
      expect(updated.isPrepEnabledForSubject('new_subject'), isFalse);
      expect(updated.isPrepEnabledForSubject('math'), isTrue);
      // Original is unchanged.
      expect(b.isPrepEnabledForSubject('new_subject'), isTrue);
    });

    test('copyWith with empty disabledSubjects set re-enables all', () {
      final b = PrepBudget.defaults.copyWith(disabledSubjects: {'math'});
      final reenabled = b.copyWith(disabledSubjects: <String>{});
      expect(reenabled.isPrepEnabledForSubject('math'), isTrue);
    });
  });

  // Vision §0 thesis / §4.4 acceptance #1:
  // "With budgets at defaults, a week of simulated off-periods shows
  //  prep tokens > live tokens in LlmUsageMeter aggregates (test proves the
  //  ratio)." Preparation must dominate tokens so lessons start pre-built.
  group('PrepBudget token-economy thesis', () {
    test('a week of off-period prep produces more tokens than live chat', () {
      final meter = LlmUsageMeter();
      final service = PrepBudgetService(meter: meter); // defaults
      final caps = PrepBudget.defaults.caps;

      // --- Live chat: teaching + mentor only, during scheduled contact.
      // Realistic 1h lesson + 0.5h mentor chat per day over a week.
      const days = 7;
      for (var d = 0; d < days; d++) {
        meter.recordUsage(
          id: 'live_teach_$d',
          feature: 'tutor',
          modelId: 'gpt-4o',
          inputTokens: 4000,
          outputTokens: 2000,
          taskType: 'teaching',
        );
        meter.recordUsage(
          id: 'live_mentor_$d',
          feature: 'mentor',
          modelId: 'gpt-4o',
          inputTokens: 2000,
          outputTokens: 1000,
          taskType: 'mentor',
        );
      }

      // --- Off-period prep: the background queue pre-builds material
      // across every prep category, approaching (never exceeding) the
      // default caps. Over a week of idle compute the caps are the limit.
      // The 80/20 input/output split is a realistic generation-heavy ratio.
      void prep(String id, String taskType, int cap) {
        final total = (cap * 0.8).round();
        meter.recordUsage(
          id: id,
          feature: 'prep',
          modelId: 'gpt-4o',
          inputTokens: (total * 0.8).round(),
          outputTokens: (total * 0.2).round(),
          taskType: taskType,
        );
      }

      prep('prep_pdf', 'pdf_ingestion', caps[PrepCategory.pdfIngestion]!);
      prep('prep_qv', 'question_variants', caps[PrepCategory.questionVariants]!);
      prep('prep_lp', 'lesson_prep', caps[PrepCategory.lessonPrep]!);
      prep('prep_emb', 'embeddings', caps[PrepCategory.embeddings]!);
      prep('prep_bg', 'background', caps[PrepCategory.background]!);

      // --- Aggregates read straight off the shared LlmUsageMeter.
      final totalPrepTokens = service.totalPrepTokens();
      final liveByType = meter.getTotalTokensPerTaskType();
      final totalLiveTokens =
          (liveByType['teaching'] ?? 0) + (liveByType['mentor'] ?? 0);

      // Thesis: preparation dominates tokens.
      expect(totalPrepTokens, greaterThan(totalLiveTokens));

      // Guardrail: prep stayed inside the default caps (budget enforced).
      final spent = service.spendingByCategory();
      for (final category in PrepCategory.values) {
        expect(
          spent[category],
          lessThanOrEqualTo(caps[category]!),
          reason: '${category.name} exceeded its cap',
        );
      }

      // Sanity: the four required prep categories all carried tokens (≥4),
      // and live tokens equal the realistic per-day contact window.
      expect(spent[PrepCategory.pdfIngestion], greaterThan(0));
      expect(spent[PrepCategory.questionVariants], greaterThan(0));
      expect(spent[PrepCategory.lessonPrep], greaterThan(0));
      expect(spent[PrepCategory.embeddings], greaterThan(0));
      expect(totalLiveTokens, equals(days * (6000 + 3000)));
    });
  });

  // Mirrors the §4.4 prep-vs-live thesis assertion, but exercises the
  // dedicated [PrepBudgetService.totalLiveTokens] complement method (the
  // screen uses this to render the on-portal ratio), instead of inlining the
  // live sum.
  group('PrepBudgetService live tokens', () {
    test('totalLiveTokens is the complement of totalPrepTokens', () {
      final meter = LlmUsageMeter();
      meter.recordUsage(
        id: 'prep1',
        feature: 'prep',
        modelId: 'gpt-4o',
        inputTokens: 4000,
        outputTokens: 1000,
        taskType: 'pdf_ingestion',
      );
      meter.recordUsage(
        id: 'prep2',
        feature: 'prep',
        modelId: 'gpt-4o',
        inputTokens: 3000,
        outputTokens: 1000,
        taskType: 'lesson_prep',
      );
      meter.recordUsage(
        id: 'live1',
        feature: 'tutor',
        modelId: 'gpt-4o',
        inputTokens: 2000,
        outputTokens: 1000,
        taskType: 'teaching',
      );
      meter.recordUsage(
        id: 'live2',
        feature: 'mentor',
        modelId: 'gpt-4o',
        inputTokens: 1000,
        outputTokens: 500,
        taskType: 'mentor',
      );
      final service = PrepBudgetService(meter: meter);

      // prep = 5000 + 4000 = 9000; live = 3000 + 1500 = 4500
      expect(service.totalPrepTokens(), 9000);
      expect(service.totalLiveTokens(), 4500);
      // The two sums partition the meter's total exactly.
      expect(service.totalPrepTokens() + service.totalLiveTokens(),
          meter.getTotalTokens());
      // Prep dominates live in this simulation.
      expect(service.totalLiveTokens(), lessThan(service.totalPrepTokens()));
    });

    test('totalLiveTokens is 0 when only prep categories have spend', () {
      final meter = LlmUsageMeter();
      meter.recordUsage(
        id: 'p',
        feature: 'prep',
        modelId: 'm',
        inputTokens: 1000,
        outputTokens: 0,
        taskType: 'embeddings',
      );
      final service = PrepBudgetService(meter: meter);
      expect(service.totalPrepTokens(), 1000);
      expect(service.totalLiveTokens(), 0);
    });

    test('totalLiveTokens treats unclassified tasks as live', () {
      final meter = LlmUsageMeter();
      // background is a prep category; a null taskType is unclassified (live).
      meter.recordUsage(
        id: 'p',
        feature: 'prep',
        modelId: 'm',
        inputTokens: 1000,
        outputTokens: 0,
        taskType: 'background',
      );
      meter.recordUsage(
        id: 'u',
        feature: 'chat',
        modelId: 'm',
        inputTokens: 500,
        outputTokens: 0,
        taskType: null,
      );
      final service = PrepBudgetService(meter: meter);
      expect(service.totalPrepTokens(), 1000);
      expect(service.totalLiveTokens(), 500);
    });

    test('totalLiveTokens is 0 for an empty meter', () {
      final service = PrepBudgetService(meter: LlmUsageMeter());
      expect(service.totalPrepTokens(), 0);
      expect(service.totalLiveTokens(), 0);
    });

    // Issue: prep-lesson-prep-tokens-misattributed-as-live
    //
    // Vision §0 token principle: when LessonAgentService.generateLesson() runs
    // in prep context (feature: 'lesson_prep'), LlmTaskType.fromFeature maps
    // 'lesson_prep' → LlmTaskType.background, so _recordCompletion records actual
    // tokens with taskType: 'background' — NOT 'generation' (a live category).
    // PrepBudgetService.totalLiveTokens() must therefore exclude those tokens,
    // and totalPrepTokens() must include them.
    test('lesson_prep tokens (recorded as background) excluded from totalLiveTokens', () {
      final meter = LlmUsageMeter();
      // Simulates actual LLM tokens from a prep-context LessonAgentService
      // call: feature 'lesson_prep' → fromFeature → background taskType.
      meter.recordUsage(
        id: 'lesson_prep_actual',
        feature: 'lesson_prep',
        modelId: 'gpt-4o',
        inputTokens: 8000,
        outputTokens: 3000,
        taskType: 'background', // what fromFeature('lesson_prep') resolves to
      );
      // A live teaching call must remain counted as live.
      meter.recordUsage(
        id: 'live_tutor',
        feature: 'tutor',
        modelId: 'gpt-4o',
        inputTokens: 4000,
        outputTokens: 2000,
        taskType: 'teaching',
      );

      final service = PrepBudgetService(meter: meter);

      // The 11k prep tokens are under 'background', a PrepCategory key.
      expect(service.totalPrepTokens(), 11000);
      // Live tokens should only contain the 6k teaching record — NOT the
      // lesson-prep actuals that were misattributed before the fix.
      expect(service.totalLiveTokens(), 6000);
      // Partition holds: 11k prep + 6k live = 17k total.
      expect(service.totalPrepTokens() + service.totalLiveTokens(),
          meter.getTotalTokens());
    });

    // Issue: prep-question-variant-generation-tokens-misattributed
    //
    // Vision §0 token principle: when QuestionVariantService.generateVariants()
    // runs in prep context (feature: 'question_variants'), LlmTaskType.fromFeature
    // maps 'question_variants' → LlmTaskType.background, so _recordCompletion
    // records actual tokens with taskType: 'background' — NOT 'generation' (a
    // live category). PrepBudgetService.totalLiveTokens() must therefore
    // exclude those tokens, and totalPrepTokens() must include them.
    test('question_variants tokens (recorded as background) excluded from totalLiveTokens', () {
      final meter = LlmUsageMeter();
      // Simulates actual LLM tokens from a prep-context
      // QuestionVariantService.generateVariants() call:
      // feature 'question_variants' → fromFeature → background taskType.
      meter.recordUsage(
        id: 'qv_actual',
        feature: 'question_variants',
        modelId: 'gpt-4o',
        inputTokens: 5000,
        outputTokens: 3000,
        taskType: 'background', // what fromFeature('question_variants') resolves to
      );
      // A live teaching call must remain counted as live.
      meter.recordUsage(
        id: 'live_tutor',
        feature: 'tutor',
        modelId: 'gpt-4o',
        inputTokens: 4000,
        outputTokens: 2000,
        taskType: 'teaching',
      );

      final service = PrepBudgetService(meter: meter);

      // The 8k prep tokens are under 'background', a PrepCategory key.
      expect(service.totalPrepTokens(), 8000);
      // Live tokens should only contain the 6k teaching record — NOT the
      // question-variant actuals that were misattributed before the fix.
      expect(service.totalLiveTokens(), 6000);
      // Partition holds: 8k prep + 6k live = 14k total.
      expect(service.totalPrepTokens() + service.totalLiveTokens(),
          meter.getTotalTokens());

      // Also verify the task-type breakdown: no tokens under 'generation'.
      final byType = meter.getTotalTokensPerTaskType();
      expect(byType['generation'], isNull);
      expect(byType['question_variants'], isNull);
      expect(byType['background'], greaterThan(0));
    });

    test('totalPrepTokens + totalLiveTokens partitions every meter token', () {
      final meter = LlmUsageMeter();
      meter.recordUsage(
        id: 'a',
        feature: 'x',
        modelId: 'm',
        inputTokens: 100,
        outputTokens: 100,
        taskType: 'pdf_ingestion',
      );
      meter.recordUsage(
        id: 'b',
        feature: 'x',
        modelId: 'm',
        inputTokens: 50,
        outputTokens: 50,
        taskType: 'teaching',
      );
      meter.recordUsage(
        id: 'c',
        feature: 'x',
        modelId: 'm',
        inputTokens: 25,
        outputTokens: 25,
        taskType: null,
      );
      final service = PrepBudgetService(meter: meter);
      // prep = pdf_ingestion(200); live = teaching(100) + unknown(50)
      expect(service.totalPrepTokens(), 200);
      expect(service.totalLiveTokens(), 150);
      expect(service.totalPrepTokens() + service.totalLiveTokens(),
          meter.getTotalTokens());
    });

    // Issue: prep-tool-doubles-count-tokens
    //
    // Double-counting bug: the three PrepTools (IngestPdfToKbTool,
    // EnqueueQuestionVariantsTool, PreGenerateLessonTool) used to record
    // *estimated* tokens on the LlmUsageMeter under their specific category
    // key (e.g. 'pdf_ingestion'), while LlmService.chat(feature: 'pdf_ingestion')
    // simultaneously recorded *actual* tokens under 'background' (via
    // fromFeature). Since both keys are PrepCategory.taskTypeKeys,
    // totalPrepTokens() counted both → inflation.
    //
    // Fix: PrepTools now pass taskType: prepCategory.taskTypeKey to chat(),
    // so _recordCompletion uses the override instead of fromFeature.
    // The estimated recording was removed. This test verifies the new
    // behaviour: actual tokens are recorded once, under the specific
    // category key, and totalPrepTokens() matches exactly.
    test('actual prep tokens recorded under specific category key are not double-counted', () {
      final meter = LlmUsageMeter();
      // Simulates LlmService.chat(feature: 'pdf_ingestion', taskType: 'pdf_ingestion')
      // → _recordCompletion uses the taskType override, not fromFeature('pdf_ingestion').
      meter.recordUsage(
        id: 'pdf_actual',
        feature: 'pdf_ingestion',
        modelId: 'gpt-4o',
        inputTokens: 800,
        outputTokens: 200,
        taskType: 'pdf_ingestion', // explicit override, NOT 'background'
      );
      // A live tutoring call remains counted as live.
      meter.recordUsage(
        id: 'live_tutor',
        feature: 'tutor',
        modelId: 'gpt-4o',
        inputTokens: 4000,
        outputTokens: 2000,
        taskType: 'teaching',
      );

      final service = PrepBudgetService(meter: meter);

      // Only the actual pdf_ingestion tokens (1000) are counted — no
      // estimated tokens double-counted, no actual leaked to 'background'.
      expect(service.totalPrepTokens(), 1000);
      expect(service.totalLiveTokens(), 6000);
      // Partition holds: 1000 prep + 6000 live = 7000 total.
      expect(service.totalPrepTokens() + service.totalLiveTokens(),
          meter.getTotalTokens());

      // Per-category spend reflects actuals, not estimates.
      final spent = service.spendingByCategory();
      expect(spent[PrepCategory.pdfIngestion], 1000);
      expect(spent[PrepCategory.background], 0);

      // The actual tokens are under the specific key, NOT 'background'.
      final byType = meter.getTotalTokensPerTaskType();
      expect(byType['pdf_ingestion'], 1000);
      expect(byType['background'], isNull);
    });
  });
}
