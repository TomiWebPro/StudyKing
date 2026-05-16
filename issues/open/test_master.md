# Mastery/Spaced-Repetition Engine: Untested Algorithmic Branch Thresholds

## Context

The core mastery engine spans two files — `MasteryCalculationService`
and `QuestionMasteryState` — that collectively contain **15+ branching
threshold conditions** controlling when students are deemed
"expert"/"proficient"/etc., how intervals grow with mastery, and how
urgency escalates with time. A companion service (`SpacedRepetitionService`)
duplicates similar interval-threshold logic.

Despite 100% file-to-test mapping across the practice feature, **none of
these thresholds are tested at their boundaries**. All tests exercise the
logic indirectly through `recordAttempt()` and verify only coarse
high-level outcomes, missing regressions at every critical cutpoint.

---

## Specific Gaps

### Gap 1: `MasteryCalculationService` — exact `_updateMasteryLevel` level is never asserted

- `lib/core/services/mastery_calculation_service.dart:102–113`
- Five branches: expert (acc≥0.9 + streak≥5 + attempts≥10), proficient
  (acc≥0.8 + attempts≥5), developing (acc≥0.6 + attempts≥3), browsing
  (attempts≥1), novice (fallback).
- The sole test (`test/core/services/mastery_calculation_service_test.dart:184`)
  only checks `greaterThan(MasteryLevel.novice.index)` — it never asserts
  which exact level is reached, nor does it verify each threshold.

### Gap 2: `MasteryCalculationService` — five private algorithmic methods never tested in isolation

| Method | Lines | Branches | Test coverage |
|--------|-------|----------|--------------|
| `_updateReviewUrgency` | 147–164 | 5 day-based branches | None (only via `recordAttempt`) |
| `_updateForgettingRisk` | 96–99 | Retention-decay formula | None |
| `_updateSpeedTrend` | 88–94 | Clamped ratio | None |
| `_updateConfidenceTrend` | 83–85 | Normalized average | None |
| `_updateReadinessScore` | 126–144 | Weighted 4-term sum | None |

Each method encodes real pedagogical logic; none has a standalone unit
test with controlled inputs and verified outputs.

### Gap 3: `QuestionMasteryState._getIntervalMultiplier` — five thresholds, only one verified

- `lib/features/practice/data/models/question_mastery_state_model.dart:217–224`
- Six intervals: 7 d (≥0.9), 3 d (≥0.8), 2 d (≥0.7), 1 d (≥0.5),
  12 h (≥0.3), 30 min (<0.3).
- Tests only verify that `recordAttempt` returns a non-null
  `nextReview.isAfter(now)` — never the exact interval length.

### Gap 4: `SpacedRepetitionService.updateNextReviewDate` — four interval thresholds are not verified

- `lib/features/practice/services/spaced_repetition_service.dart:109–120`
- In `test/features/practice/services/spaced_repetition_service_test.dart`,
  only the 7-day threshold (`mastery ≥ 0.9`) asserts the computed
  interval. The 3-day, 1-day, 12-hour, and 30-minute tests only check
  `isSuccess` — a regression in any of these intervals would silently
  pass.

### Gap 5: `_recencyScore` (both classes) — hour/day boundaries uncovered

- `QuestionMasteryState._recencyScore` (lines 179–189): five hour-based
  thresholds (1 h, 24 h, 48 h, 168 h, >168 h).
- `MasteryCalculationService._recencyScore` (lines 116–124): six
  day-based thresholds (0 d, ≤1 d, ≤3 d, ≤7 d, ≤14 d, >14 d).
- Neither has a test that pins each boundary value.

### Gap 6: `practice_models_test.dart` — 18× bloat for zero business logic

- `lib/features/practice/data/models/practice_models.dart`: **24 lines**,
  two value classes with no methods (pure data holders).
- `test/features/practice/data/models/practice_models_test.dart`: **432
  lines**, 27 constructor-only tests that verify trivial getters, plus
  tests like "two instances with same values are distinct" (no `==`
  override, always true by identity) and "fields are independent"
  (always true by construction). This should be ~40 lines of focused
  serialization/deserialization coverage.

---

## Affected Files

| Source | Test |
|--------|------|
| `lib/core/services/mastery_calculation_service.dart` | `test/core/services/mastery_calculation_service_test.dart` |
| `lib/features/practice/data/models/question_mastery_state_model.dart` | `test/features/practice/data/models/question_mastery_state_model_test.dart` |
| `lib/features/practice/services/spaced_repetition_service.dart` | `test/features/practice/services/spaced_repetition_service_test.dart` |
| `lib/features/practice/data/models/practice_models.dart` | `test/features/practice/data/models/practice_models_test.dart` |

---

## Rationale

These thresholds determine real student-facing behavior:

- A student at 0.89 mastery gets a 12-hour interval; at 0.90 they get
  7 days. This boundary is **not** pinned by any test.
- A student whose last attempt was 167 hours ago receives a recency
  score of 0.5; at 168 hours it drops to 0.3. Neither value is verified.
- The `MasteryCalculationService._updateMasteryLevel` formula directly
  controls which badge/level a student sees in the UI. If a refactor
  shifts the `accuracy ≥ 0.9` condition to `accuracy > 0.9`, a student
  with exactly 0.9 accuracy would silently drop from "expert" to
  "proficient" with no test catching it.

---

## Acceptance Criteria

1. **`_updateMasteryLevel`** — test reports exact `MasteryLevel` for
   every branch: expert (acc=0.9, streak=5, attempts=10), proficient
   (acc=0.8, streak=3, attempts=5; and acc=0.7 to verify it does NOT
   reach expert), developing (acc=0.6, attempts=3), browsing (acc=0.0,
   attempts=1), novice (attempts=0).

2. **`_updateReviewUrgency`** — test verifies exact urgency at each
   day-based branch (0 d → 0.1, ≤1 d, ≤3 d with forgettingRisk=0 → 0.5,
   ≤7 d, >7 d) with controlled `forgettingRisk` inputs.

3. **`_updateForgettingRisk`**, **`_updateSpeedTrend`**,
   **`_updateConfidenceTrend`**, **`_updateReadinessScore`** — each gets
   ≥2 tests with hard-coded inputs and deterministic expected outputs.

4. **`_getIntervalMultiplier`** — test verifies exact hour interval for
   each threshold: 0.9→168 h, 0.8→72 h, 0.7→48 h, 0.65→24 h, 0.5→24 h,
   0.3→12 h, 0.0→0.25 h. Also verifies edge behavior (e.g. 0.89 gap,
   0.90 gap).

5. **`_recencyScore`** — test (in both classes) verifies score at each
   boundary: QuestionMasteryState at 0 h, 1 h, 24 h, 48 h, 168 h, 200 h;
   MasteryCalculationService at 0 d, 1 d, 3 d, 7 d, 14 d, 30 d.

6. **`SpacedRepetitionService.updateNextReviewDate`** — extend the four
   shallow interval tests to assert the actual computed interval (as the
   7-day test already does), verifying exact duration for mastery=0.8,
   0.6, 0.4, and 0.2.

7. **`practice_models_test.dart`** — trim to ≤50 lines: remove redundant
   per-type constructor tests (test one representative `QuestionType`),
   remove identity/non-equality tests, keep JSON round-trip and null/
   missing-field deserialization.

---

## Implementation Notes

- The private methods in `MasteryCalculationService` and
  `QuestionMasteryState` are `static` or instance methods — make them
  package-visible (or extract to testable pure functions) if they are
  not already reachable. `MasteryCalculationService` methods are
  instance-private; they can be tested by constructing the service and
  calling `recordAttempt` with precise inputs tuned to each threshold.
- Prefer hand-written fakes per project convention (no mockito/mocktail).
- Use `DateTime` pinning (not `DateTime.now()`) to ensure deterministic
  results across recency/urgency tests.
