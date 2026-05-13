# Test Coverage & Structural Gaps: Practice Feature

## Context

The Practice feature (`lib/features/practice/`) is a core user-facing workflow spanning subject selection, spaced repetition, weak-area targeting, per-question practice sessions, and learning-plan dashboards. Despite its centrality, the test suite suffers from **fragmented placement, overlapping coverage, missing critical flows, and dead/misplaced test scaffolding**.

---

## Affected Files & Issues

### 1. Practice Session Screen: Misplaced & Duplicated Tests

| File | Problem |
|---|---|
| `test/features/practice/practice_test.dart` | Tests practice session behavior (187 lines) |
| `test/widgets/practice_session_screen_test.dart` | Tests the same `PracticeSessionScreen` with question-type branches, submission lifecycle, and edge cases (462 lines) |
| `test/features/practice/presentation/practice_screen_test.dart` | Tests the parent `PracticeScreen` (201 lines) |

**Rationale:**
- `practice_test.dart` and `practice_session_screen_test.dart` test **the same widget** (`PracticeSessionScreen`) with nearly identical helper classes (`_FakeQuestionRepository`, `_question()`, `_sessionApp()`). This duplication wastes maintenance effort and confuses coverage analysis.
- There is **no `practice_session_screen_test.dart`** in `test/features/practice/presentation/` — the logical home. The session screen test is orphaned under `test/widgets/`.

**Acceptance Criteria:**
- [ ] Merge `test/widgets/practice_session_screen_test.dart` and `test/features/practice/practice_test.dart` into a single `test/features/practice/presentation/practice_session_screen_test.dart`.
- [ ] Deduplicate shared helper classes (`_FakeQuestionRepository`, `_question`, `_sessionApp`) into a shared test utility.
- [ ] Delete the old files after merge.

---

### 2. Empty / Orphaned Service Directory

| Path | State |
|---|---|
| `lib/features/practice/services/` | **Empty directory** |
| `test/features/practice/services/answer_validation_service_test.dart` | Exists, but tests `lib/core/services/answer_validation_service.dart`, **not** a practice-service |

**Rationale:**
- The test at `test/features/practice/services/answer_validation_service_test.dart` is misleadingly placed. It tests the *core* `AnswerValidationService`, yet lives under `features/practice/services`.
- A separate `AnswerValidationService` class exists at `lib/features/questions/services/answer_validator.dart:35`, shadowing the same name from `lib/core/services/`. The feature-layer one is a thin static wrapper with zero dedicated tests for its own export API.

**Acceptance Criteria:**
- [ ] Relocate `test/features/practice/services/answer_validation_service_test.dart` to `test/core/services/answer_validation_service_test.dart` (where it logically belongs — the file already exists there, so merge or remove).
- [ ] Add dedicated tests for the feature-layer `AnswerValidationService` (`lib/features/questions/services/answer_validator.dart`) covering:
  - `validateWithMarkschemeInstance` (instance method)
  - `validateMCQAnswerWithMarkscheme` (static) for both single and multi choice
  - `validateMathExpressionWithMarkscheme` with normalized expressions
  - `validateCanvasDrawingWithMarkscheme` with real drawing data structures

---

### 3. Missing Test Scenarios for `PracticeSessionScreen`

**Location:** `lib/features/practice/presentation/practice_session_screen.dart`

The following critical flows have **no test coverage**:

| Scenario | Why Needed |
|---|---|
| Session auto-save on completion (`_sessionAutoSaved` guard, `StudySessionRepository.create` invocation) | 18% of the state machine; could silently lose data |
| Restart session flow (`_restartSession` → timer restart, state reset) | Only exit from results screen |
| Spaced repetition mode (`isSpacedRepetition: true` → `_updateNextReview` invoked) | Dedicated code path, no assertion it fires |
| Navigation: Previous button shown and functional | Conditional widget in `_buildNavigationButtons` |
| `_showNoQuestionsDialog` displayed on load failure | Error-resilience path |
| Loading spinner shown while questions empty, then resolves | UI feedback loop |
| Empty questions by subject (no questions for given `subjectId`) | `_showNoQuestionsDialog` vs empty array handling |
| Question types: `graphDrawing`, `fileUpload`, `audioRecording` map to fallback | The `default` branch in `_buildQuestionWidget` |
| Timer display updates | State-dependent `_elapsedTimeFormatted` |

**Acceptance Criteria:**
- [ ] Add widget tests for each scenario listed above.
- [ ] Verify timer ticks, session auto-save, spaced-repetition call, restart flow, and error dialogs.

---

### 4. `PracticeScreen`: Untestable Dependency & Missing Interaction Tests

**Location:** `lib/features/practice/presentation/practice_screen.dart`

- **`_startWeakAreasPractice`** (line 727) creates a **new** `MasteryGraphService` inline with `init()`, defeating mocking. This locks the method out of unit/widget testing unless DI is introduced.
- No test verifies that tapping a `_PracticeModeCard` with `onTap == null` does nothing (disabled state).
- No test for the `_showTopicSelector` flow (topic-from-questions extraction, bottom sheet, navigation).
- No test for the `_showSpacedRepetitionSubjectSelector` "all caught up" state vs. "subjects with due counts" state.

**Acceptance Criteria:**
- [ ] Inject `MasteryGraphService` as a provider parameter so `_startWeakAreasPractice` can be tested with a fake.
- [ ] Add widget tests for disabled mode-card taps, topic-selector flow, and SR subject-selector branching.

---

### 5. Hardcoded Localized Strings in Tests

Across affected test files, UI string assertions use raw English literals (e.g., `'Correct!'`, `'No study plan for today'`, `'Practice Complete!'`, `'100%'`). These will break silently when locale data changes.

**Affected:** All four practice test files.

**Acceptance Criteria:**
- [ ] Refactor assertions to reference `AppLocalizations` or test-local string constants so they survive l10n changes.

---

### 6. `LearningPlanDashboard` — Missing Failure & Partial-Data Tests

**Location:** `test/features/practice/presentation/learning_plan_dashboard_test.dart`

- **No test** for when `generatePlan` returns a failure (error state rendering).
- **No test** for partial service failures (e.g., `generatePlan` succeeds, `getWeakTopics` fails).
- **No test** for `_loadData` `setState` being called only when widget is mounted.
- **No test** for the urgency indicator rendering (`_buildUrgencyIndicator` color logic).

**Acceptance Criteria:**
- [ ] Add tests for failure paths and mixed success/failure scenarios.

---

## Summary

| Category | Count |
|---|---|
| Redundant test files to consolidate | 2 |
| Misplaced test files to relocate | 2 |
| High-priority missing test scenarios | 10 |
| Structural issues (empty dirs, dead scaffolding) | 2 |
| String-hardening needed | All 4 practice test files |
