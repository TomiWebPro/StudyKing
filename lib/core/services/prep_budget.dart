import 'package:studyking/core/services/llm_usage_meter.dart';

/// Preparation spend categories that divide the student's preparation token
/// budget (docs/vision_next_term.md §4.2).
///
/// [taskTypeKey] is the exact string written to
/// [LlmUsageRecord.taskType] by preparation work, so a
/// [PrepBudgetService] can read live spend straight off
/// [LlmUsageMeter.getTotalTokensPerTaskType()] without inventing a parallel
/// tracker. The `background` key intentionally matches
/// `LlmTaskType.background`'s recorded name, so background prep shows up in
/// the same aggregate the meter already maintains.
enum PrepCategory {
  /// PDF / textbook / notes ingestion into the knowledge base (§4.1).
  pdfIngestion,

  /// Question-bank expansion: variants, difficulty tagging (§4.1).
  questionVariants,

  /// Lesson pre-generation: blocks, examples, exercises, homework (§4.1).
  lessonPrep,

  /// Embedding + retrieval pipeline tokens (§4.1).
  embeddings,

  /// Catch-all for background/idle preparation work.
  background;

  String get taskTypeKey {
    switch (this) {
      case PrepCategory.pdfIngestion:
        return 'pdf_ingestion';
      case PrepCategory.questionVariants:
        return 'question_variants';
      case PrepCategory.lessonPrep:
        return 'lesson_prep';
      case PrepCategory.embeddings:
        return 'embeddings';
      case PrepCategory.background:
        return 'background';
    }
  }
}

/// Student-steerable preparation budget (docs/vision_next_term.md §4.2).
///
/// Holds per-category token caps plus an enabled switch ("Prepare while I'm
/// away" master toggle). Caps are absolute token amounts; the Settings
/// surface is expected to present them as percentages of a rolling budget
/// and persist student edits. [PrepBudget.defaults] encodes the §4.2 split
/// (PDF→KB 40%, Q-bank 30%, lesson prep 20%, embeddings 10%) normalised to
/// a 500 000-token budget.
class PrepBudget {
  /// When false, no preparation tokens may be spent (master switch off).
  final bool enabled;

  /// Per-category token caps. A category absent from the map has a cap of 0.
  final Map<PrepCategory, int> caps;

  const PrepBudget({
    required this.enabled,
    required this.caps,
  });

  /// Vision-default caps: 40% / 30% / 20% / 10% of a 500k-token budget, plus
  /// a 50k background bucket.
  static const PrepBudget defaults = PrepBudget(
    enabled: true,
    caps: {
      PrepCategory.pdfIngestion: 200000,
      PrepCategory.questionVariants: 150000,
      PrepCategory.lessonPrep: 100000,
      PrepCategory.embeddings: 50000,
      PrepCategory.background: 50000,
    },
  );

  PrepBudget copyWith({bool? enabled, Map<PrepCategory, int>? caps}) {
    return PrepBudget(
      enabled: enabled ?? this.enabled,
      caps: caps ?? Map<PrepCategory, int>.of(this.caps),
    );
  }

  /// Reference total budget used to map absolute caps to percentages in the
  /// Settings surface. The vision §4.2 default split (40/30/20/10) is expressed
  /// as caps over this total, so the student can steer each category as a
  /// percentage of a known whole.
  static const int referenceTotalTokens = 500000;

  /// Percentage of [referenceTotalTokens] allocated to [category] (0–100).
  int percentFor(PrepCategory category) {
    final cap = caps[category] ?? 0;
    return ((cap / referenceTotalTokens) * 100).round();
  }

  /// A copy with the cap for [category] set to the token amount implied by
  /// [percent] of [referenceTotalTokens] (clamped to 0–100).
  PrepBudget withPercent(PrepCategory category, int percent) {
    final clamped = percent.clamp(0, 100);
    final cap = (clamped / 100 * referenceTotalTokens).round();
    return copyWith(caps: {
      for (final c in PrepCategory.values) c: c == category ? cap : (caps[c] ?? 0),
    });
  }

  /// Tokens remaining in [category] for the given per-task-type spend map,
  /// clamped to zero once the cap is exhausted.
  int remainingFor(PrepCategory category, Map<String, int> spentByCategory) {
    final cap = caps[category] ?? 0;
    final spent = spentByCategory[category.taskTypeKey] ?? 0;
    final remaining = cap - spent;
    return remaining > 0 ? remaining : 0;
  }

  /// Whether [tokens] more may be spent in [category] without exceeding its
  /// cap. Denied entirely when the budget is disabled (master switch off).
  bool canSpend(
    PrepCategory category,
    int tokens,
    Map<String, int> spentByCategory,
  ) {
    if (!enabled) return false;
    if (tokens < 0) return false;
    return remainingFor(category, spentByCategory) >= tokens;
  }
}

/// Enforces a [PrepBudget] against live spend recorded in [LlmUsageMeter].
///
/// This is the minimal, testable solidification of vision §4.2/§4.4: it
/// exposes per-category remaining spend and a `canSpend` gate read directly
/// from the meter's per-task-type aggregates, so a student who halves one
/// category's cap never silently starves the others. It does not drive the
/// meter itself — consuming it (recording a pre-run token estimate before a
/// background task spends) is the follow-up wiring step; this layer only
/// consumes what the meter already records.
class PrepBudgetService {
  final LlmUsageMeter _meter;
  final PrepBudget budget;

  PrepBudgetService({
    required LlmUsageMeter meter,
    this.budget = PrepBudget.defaults,
  }) : _meter = meter;

  /// Live tokens spent per category (for §4.2 "live counters: tokens per
  /// category"). Unrecognised task types in the meter are ignored.
  Map<PrepCategory, int> spendingByCategory() {
    final byType = _meter.getTotalTokensPerTaskType();
    final out = <PrepCategory, int>{};
    for (final category in PrepCategory.values) {
      out[category] = byType[category.taskTypeKey] ?? 0;
    }
    return out;
  }

  /// Live est. cost spent per category (for §4.2 "est. cost per category").
  Map<PrepCategory, double> costByCategory() {
    final byType = _meter.getTotalCostPerTaskType();
    final out = <PrepCategory, double>{};
    for (final category in PrepCategory.values) {
      out[category] = byType[category.taskTypeKey] ?? byType['unknown'] ?? 0.0;
    }
    return out;
  }

  /// Tokens remaining in [category] against the live meter.
  int remainingFor(PrepCategory category) =>
      budget.remainingFor(category, _meter.getTotalTokensPerTaskType());

  /// Whether [tokens] more can be spent in [category] without exceeding its
  /// cap (and only when the budget is enabled).
  bool canSpend(PrepCategory category, int tokens) =>
      budget.canSpend(category, tokens, _meter.getTotalTokensPerTaskType());
}
