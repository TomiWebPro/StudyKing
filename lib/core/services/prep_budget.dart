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

  /// Reverse lookup: returns the [PrepCategory] whose [taskTypeKey] matches
  /// [key], or `null` when [key] is not a recognised preparation category.
  /// Used by the LlmTaskManagerScreen filter dropdown to map raw task-type
  /// strings to localized category labels.
  static PrepCategory? fromTaskTypeKey(String key) {
    for (final category in PrepCategory.values) {
      if (category.taskTypeKey == key) return category;
    }
    return null;
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
///
/// Also holds quiet-hours configuration: when [quietHoursStart] and
/// [quietHoursEnd] are both set, the [IdleExecutor] defers heavy prep tasks
/// during the quiet window to prevent disturbing the student at night
/// (vision §4.2: "Prepare while I'm away" master switch + quiet-hours).
class PrepBudget {
  /// When false, no preparation tokens may be spent (master switch off).
  final bool enabled;

  /// Per-category token caps. A category absent from the map has a cap of 0.
  final Map<PrepCategory, int> caps;

  /// Hour of day (0–23) when quiet hours begin, or null when quiet hours
  /// are not configured. When the window wraps midnight (e.g. start 22,
  /// end 8) the check handles the wraparound.
  final int? quietHoursStart;

  /// Hour of day (0–23) when quiet hours end, or null when quiet hours
  /// are not configured.
  final int? quietHoursEnd;

  /// Set of subject IDs for which preparation is disabled.
  /// Empty means all subjects are enabled (default). When a subject's
  /// toggle is switched off in Settings, its ID is added here so the
  /// IdleExecutor can skip prep for that syllabus (vision §4.2:
  /// "per-syllabus opt-in").
  final Set<String> disabledSubjects;

  const PrepBudget({
    required this.enabled,
    required this.caps,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.disabledSubjects = const {},
  });

  /// Vision-default caps: 40% / 30% / 20% / 10% of a 500k-token budget, plus
  /// a 50k background bucket. Quiet hours and per-subject opt-in are null/empty
  /// by default (student must configure them).
  static const PrepBudget defaults = PrepBudget(
    enabled: true,
    caps: {
      PrepCategory.pdfIngestion: 200000,
      PrepCategory.questionVariants: 150000,
      PrepCategory.lessonPrep: 100000,
      PrepCategory.embeddings: 50000,
      PrepCategory.background: 50000,
    },
    quietHoursStart: null,
    quietHoursEnd: null,
    disabledSubjects: {},
  );

  PrepBudget copyWith({
    bool? enabled,
    Map<PrepCategory, int>? caps,
    int? quietHoursStart,
    int? quietHoursEnd,
    Set<String>? disabledSubjects,
  }) {
    return PrepBudget(
      enabled: enabled ?? this.enabled,
      caps: caps ?? Map<PrepCategory, int>.of(this.caps),
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      disabledSubjects: disabledSubjects ?? Set<String>.of(this.disabledSubjects),
    );
  }

  /// Whether [now] falls within the quiet-hours window, meaning heavy prep
  /// tasks should be deferred to avoid disturbing the student.
  ///
  /// Returns false when quiet hours are not configured (either hour is null)
  /// or when start == end (no window). Handles midnight wraparound: a window
  /// like 22:00–08:00 covers hours 22–23 and 0–7.
  bool shouldDeferForQuietHours(DateTime now) {
    final start = quietHoursStart;
    final end = quietHoursEnd;
    if (start == null || end == null) return false;
    if (start == end) return false;
    final hour = now.hour;
    if (start < end) {
      // Same-day window, e.g. 09:00–17:00.
      return hour >= start && hour < end;
    } else {
      // Wraparound window, e.g. 22:00–08:00 → covers 22,23 + 0–7.
      return hour >= start || hour < end;
    }
  }

  /// Whether preparation is enabled for [subjectId]. Returns false when the
  /// subject has been explicitly disabled by the student via the per-subject
  /// prep toggle in Settings. An empty [disabledSubjects] set means all
  /// subjects are enabled (default behaviour).
  bool isPrepEnabledForSubject(String subjectId) {
    if (disabledSubjects.isEmpty) return true;
    return !disabledSubjects.contains(subjectId);
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
  /// Unrecognised / null-taskType records in the meter are ignored — they
  /// are treated as live spend, not attributed to any prep category, exactly
  /// as [spendingByCategory] does for tokens. This keeps the per-category
  /// cost counters consistent with the token counters and prevents the
  /// `unknown`-bucket total from being inflated across every empty category.
  Map<PrepCategory, double> costByCategory() {
    final byType = _meter.getTotalCostPerTaskType();
    final out = <PrepCategory, double>{};
    for (final category in PrepCategory.values) {
      out[category] = byType[category.taskTypeKey] ?? 0.0;
    }
    return out;
  }

  /// Total tokens spent across all preparation categories, read straight
  /// from the meter's per-task-type aggregates. Realises the §4.2 "live
  /// counters: tokens per category" counter as an aggregate; the §4.4
  /// prep-vs-live thesis test compares it against live chat tokens.
  int totalPrepTokens() {
    final byType = _meter.getTotalTokensPerTaskType();
    var total = 0;
    for (final category in PrepCategory.values) {
      total += byType[category.taskTypeKey] ?? 0;
    }
    return total;
  }

  /// Total tokens spent on live (non-preparation) work — the complement of
  /// [totalPrepTokens] against the meter's per-task-type aggregates
  /// (Vision Next-Term §0 thesis: "Students must be able to see where tokens
  /// go"). Sums every task-type bucket that is NOT a [PrepCategory], which is
  /// equivalent to `LlmUsageMeter.getTotalTokens() - totalPrepTokens()` but
  /// reads from the same per-task-type snapshot as [totalPrepTokens], keeping
  /// the two values consistent when tests stub the meter with a fake.
  /// Unclassified / null task types (recorded under `unknown`) are treated as
  /// live, so the two sums always partition the meter's total exactly.
  int totalLiveTokens() {
    final byType = _meter.getTotalTokensPerTaskType();
    final prepKeys = {for (final category in PrepCategory.values) category.taskTypeKey};
    var total = 0;
    for (final entry in byType.entries) {
      if (!prepKeys.contains(entry.key)) {
        total += entry.value;
      }
    }
    return total;
  }

  /// Tokens remaining in [category] against the live meter.
  int remainingFor(PrepCategory category) =>
      budget.remainingFor(category, _meter.getTotalTokensPerTaskType());

  /// Whether [tokens] more can be spent in [category] without exceeding its
  /// cap (and only when the budget is enabled).
  bool canSpend(PrepCategory category, int tokens) =>
      budget.canSpend(category, tokens, _meter.getTotalTokensPerTaskType());

  /// Whether the student has configured quiet hours and [now] falls within
  /// the quiet window. Delegates to [PrepBudget.shouldDeferForQuietHours]
  /// so the [IdleExecutor] can call this single method to decide whether to
  /// defer a task.
  bool shouldDeferForQuietHours(DateTime now) => budget.shouldDeferForQuietHours(now);

  /// Whether preparation is enabled for [subjectId] (per-syllabus opt-in).
  bool isPrepEnabledForSubject(String subjectId) =>
      budget.isPrepEnabledForSubject(subjectId);
}
