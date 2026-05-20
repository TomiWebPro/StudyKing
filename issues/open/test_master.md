# Test Coverage & Quality Issue (Round 3)

## Severity Legend

| Label | Meaning |
|---|---|
| BLOCKER | App crashes or user cannot proceed |
| MAJOR | Feature is broken or misleading |
| MINOR | Code quality / UX friction |

---

## MAJOR

### M1. 8 source files with zero test coverage

The following source files have no dedicated test file anywhere in the project. Per AGENTS.md mapping conventions, they are completely untested.

| Source file | Lines | Risk if untested |
|---|---|---|
| `lib/core/utils/sr_data_codec.dart` | 35 | **Data corruption risk.** Serializes/deserializes `QuestionSRData` — the spaced repetition state for every question. On deserialization failure, silently returns defaults (repetitions=0, easeFactor=2.5). A regression could silently reset years of SR progress. |
| `lib/core/utils/string_extensions.dart` | 3 | `.normalized` extension (`.trim().toLowerCase()`) used at **15+ call sites** across features (question evaluation, lesson agent, practice screen, question card). If semantics change, answer matching breaks silently. |
| `lib/core/utils/label_helpers.dart` | 71 | Exhaustive switch-to-localized-label mapping for `QuestionType` (9 variants), `SourceType` (8 variants), `ProcessingStatus` (7 variants). Adding a new enum variant without updating this file is a silent UI regression. |
| `lib/core/errors/spaced_repetition_error_codes.dart` | 4 | `SpacedRepetitionErrorCode` enum (2 values). Per AGENTS.md: "Use this enum instead of string literals." No test verifies these are used consistently or that error codes match. |
| `lib/core/widgets/dialog_utils.dart` | 28 | `showConfirmationDialog` — confirm/cancel dialog used across the app. No test verifies rendering, button labels, or `Navigator.pop(false)` fallback. |
| `lib/core/widgets/snackbar_utils.dart` | 34 | `showSuccessSnackBar`, `showErrorSnackBar`, `showInfoSnackBar`. No test verifies correct color scheme per variant. |
| `lib/core/data/data.dart` | 11 | Barrel file re-exporting 11 core data types. No test — lowest priority of this group, but still a mapping gap. |
| `lib/features/subjects/data/curriculum_seed_data.dart` | 544 | 544 lines of seed data. No test verifies data integrity (non-empty titles, no null fields, structure matches repository expectations). |

**Expected test locations:**
| Source | Expected test |
|---|---|
| `lib/core/utils/sr_data_codec.dart` | `test/core/utils/sr_data_codec_test.dart` |
| `lib/core/utils/string_extensions.dart` | `test/core/utils/string_extensions_test.dart` |
| `lib/core/utils/label_helpers.dart` | `test/core/utils/label_helpers_test.dart` |
| `lib/core/errors/spaced_repetition_error_codes.dart` | `test/core/errors/spaced_repetition_error_codes_test.dart` |
| `lib/core/widgets/dialog_utils.dart` | `test/core/widgets/dialog_utils_test.dart` |
| `lib/core/widgets/snackbar_utils.dart` | `test/core/widgets/snackbar_utils_test.dart` |
| `lib/core/data/data.dart` | `test/core/data/data_test.dart` |
| `lib/features/subjects/data/curriculum_seed_data.dart` | `test/features/subjects/data/curriculum_seed_data_test.dart` |

**Acceptance criteria:**
- [ ] `sr_data_codec_test.dart` covers: round-trip encode/decode with realistic `QuestionSRData`, null/empty input returns defaults, malformed JSON returns defaults, partial data preserves known fields and fills defaults for missing fields.
- [ ] `string_extensions_test.dart` covers: `.normalized` trims whitespace, lowercases, handles empty string, handles mixed case with surrounding whitespace, does not throw on special characters.
- [ ] `label_helpers_test.dart` covers: every `QuestionType` variant returns a non-null label, every `SourceType` variant returns a non-null label, every `ProcessingStatus` variant returns a non-null label (these tests fail at compile time if a new variant is added — this is the behavioral assertion).
- [ ] `spaced_repetition_error_codes_test.dart` covers: `SpacedRepetitionErrorCode.values` contains exactly `boxClosed` and `notFound` (fails at compile time if new value added without updating test).
- [ ] `dialog_utils_test.dart` covers: dialog renders title/message, confirm button pops with `true`, cancel button pops with `false`, backdrop dismiss returns `false`.
- [ ] `snackbar_utils_test.dart` covers: each variant (success/error/info) renders with correct background color from `Theme.of(context).colorScheme`.
- [ ] `curriculum_seed_data_test.dart` covers: `curriculumSeedData` is non-empty, every `CurriculumSeedEntry` has non-empty `curriculumName` and non-empty `topics`, every `SeedTopic` has non-empty `title`.

---

### M2. Orphaned vacuous test files

Two non-barrel test files contain only a placeholder assertion (`expect(true, isTrue)`) that always passes.

**M2a. `test/features/dashboard/data/models/dashboard_models_test.dart`** (8 lines)
```dart
// TODO: Re-enable when feature classes are available
expect(true, isTrue);
```
The TODO is stale — source files `lib/features/dashboard/data/models/dashboard_models.dart` and `badge_model.dart` both exist with real classes. This file creates a false sense of coverage.

**M2b. `test/core/utils/utils_test.dart`** (8 lines)
```dart
// TODO: Re-enable when feature classes are available
expect(true, isTrue);
```
There is NO corresponding `lib/core/utils/utils.dart` source file. This is a leftover barrel test for a barrel that was deleted. It tests nothing.

**Affected files:**
- `test/features/dashboard/data/models/dashboard_models_test.dart`
- `test/core/utils/utils_test.dart`

**Rationale:** Both files pass on CI while detecting zero regressions. A bug in dashboard models or core utils would be invisible.

**Acceptance criteria:**
- [ ] `dashboard_models_test.dart` is implemented with real tests covering constructor defaults, copyWith, toJson/fromJson round-trip for `DashboardMetrics` and `Badge`, and edge cases (null fields, empty lists).
- [ ] `utils_test.dart` is either deleted (no source to test) or, if it serves as a barrel import check, its purpose is documented and it contains at least one behavioral assertion (e.g., verify a non-const constructor from re-exported utils works).

---

### M3. Voice bar test has placeholder assertion after dispose

In `test/features/teaching/presentation/widgets/voice_bar_test.dart` at line 421:

```dart
testWidgets('handles transcription stream emitting after widget disposal', (tester) async {
  // ... setup, emit while active, dispose widget ...
  controller.addTranscription('After dispose');
  expect(true, isTrue);  // <-- proves nothing
});
```

The test intent (verify no crash after disposal) is correct, but the assertion is vacuous. If `addTranscription` throws, the test fails as an unhandled exception — but that is an implicit assertion, not an explicit one. The test should verify no exception leaked and no stale state propagated.

**Affected file:** `test/features/teaching/presentation/widgets/voice_bar_test.dart:421`

**Acceptance criteria:**
- [ ] Replace `expect(true, isTrue)` with an explicit assertion: either `expect(tester.takeException(), isNull)` to verify no exception, or verify no new transcription callback was fired after disposal.

---

### M4. Misplaced test file: `session_utils_test.dart`

| Source file | Current test location | Correct location |
|---|---|---|
| `lib/features/sessions/presentation/utils/session_utils.dart` | `test/features/sessions/data/repositories/session_utils_test.dart` | `test/features/sessions/presentation/utils/session_utils_test.dart` |

The test file exercises a `presentation/utils/` module but lives under `data/repositories/`, violating the AGENTS.md one-to-one directory mapping. A developer looking for tests of presentation utilities won't find them under data/repositories.

**Affected file:** `test/features/sessions/data/repositories/session_utils_test.dart`

**Acceptance criteria:**
- [ ] File is moved to `test/features/sessions/presentation/utils/session_utils_test.dart`.
- [ ] Old file at `data/repositories/session_utils_test.dart` is deleted.
- [ ] All imports in test files that reference the old path (if any) are updated.

---

## MINOR

### m1. 18 barrel-level placeholder tests (`expect(true, isTrue)`)

18 feature-/data-level barrel tests use `expect(true, isTrue)` as a placeholder. These serve as import-smoke tests (verify imports resolve at runtime) but provide no behavioral regression protection:

| File | Type |
|---|---|
| `test/features/teaching/teaching_test.dart` | Feature barrel |
| `test/features/teaching/data/teaching_data_test.dart` | Data barrel |
| `test/features/sessions/sessions_test.dart` | Feature barrel |
| `test/features/subjects/subjects_test.dart` | Feature barrel |
| `test/features/subjects/data/subjects_data_test.dart` | Data barrel |
| `test/features/settings/settings_test.dart` | Feature barrel |
| `test/features/quickguide/quickguide_test.dart` | Feature barrel |
| `test/features/questions/questions_test.dart` | Feature barrel |
| `test/features/questions/data/questions_data_test.dart` | Data barrel |
| `test/features/practice/practice_test.dart` | Feature barrel |
| `test/features/practice/data/practice_data_test.dart` | Data barrel |
| `test/features/planner/planner_test.dart` | Feature barrel |
| `test/features/planner/data/planner_data_test.dart` | Data barrel |
| `test/features/mentor/mentor_test.dart` | Feature barrel |
| `test/features/ingestion/ingestion_test.dart` | Feature barrel |
| `test/features/llm_tasks/llm_tasks_test.dart` | Feature barrel |
| `test/features/focus_mode/focus_mode_test.dart` | Feature barrel |
| `test/features/dashboard/dashboard_test.dart` | Feature barrel |
| `test/features/features_barrel_test.dart` | Top-level barrel |

Note: `test/features/lessons/lessons_test.dart` was a similar file but was already deleted (covered in Round 2).

**Acceptance criteria:**
- [ ] Each file is either (a) deleted (barrel imports are implicitly exercised by every other test that imports the barrel), or (b) enhanced with at least one behavioral assertion.
- [ ] At minimum, files with no corresponding source barrel should be deleted.

---

### m2. Residual `studentIdValueProvider.overrideWith` pattern

Three widget tests use `studentIdValueProvider.overrideWith(...)` instead of the `fixedStudentId` constructor parameter. This was flagged in Round 2 (m3) and remains unfixed.

| File | Lines |
|---|---|
| `test/features/lessons/presentation/lesson_list_screen_test.dart` | 76, 311 |
| `test/features/teaching/presentation/tutor_screen_test.dart` | 172 |
| `test/features/focus_mode/presentation/focus_timer_screen_study_hub_test.dart` | 306 |

Per AGENTS.md: "Prefer `fixedStudentId` over `StudentIdService` singleton in widget tests to avoid Hive I/O dependencies."

**Acceptance criteria:**
- [ ] Screens that accept `fixedStudentId` parameter use it directly in tests.
- [ ] Screens that don't accept `fixedStudentId` are left as-is (override is functionally correct but the import should be narrowed to `show studentIdValueProvider` only).

---

### m3. Residual `Hive.init()` in service/provider unit tests

Four tests still initialize real Hive for adapter registration, flagged in Round 2 (m2) but not fixed:

| File | `Hive.init()` occurrences |
|---|---|
| `test/features/planner/services/planner_service_test.dart` | 2 |
| `test/features/planner/providers/planner_providers_test.dart` | 1 |
| `test/features/subjects/providers/topic_repository_provider_test.dart` | 2 |
| `test/features/subjects/providers/subjects_repository_provider_test.dart` | 2 |

**Acceptance criteria:**
- [ ] Each file either replaces `Hive.init()` with a fake to remove real I/O, or documents why it's unavoidable.
- [ ] If `Hive.init()` is kept, it is moved to `setUpAll` and paired with `tearDownAll` cleanup.

---

### m4. Model tests lacking edge-case coverage

| File | Missing coverage |
|---|---|
| `test/features/planner/data/models/task_model_test.dart` | No test for empty string fields, special characters, very long values, missing optional fields in JSON. |
| `test/features/planner/data/models/pending_action_model_test.dart` | No test for null actionable fields, empty lists. |
| `test/features/focus_mode/data/models/focus_session_model_test.dart` | No test for null optional fields, extreme values for duration/accuracy, negative numbers. |

**Acceptance criteria:**
- [ ] Each file adds at least one edge-case test (null field, empty collection, or boundary value).

---

## POSITIVE FINDINGS (no action needed)

| Area | Status |
|---|---|
| **No mockito/mocktail** | 100% hand-written fakes per AGENTS.md. |
| **No mixed unit/widget tests** | Always in separate files. |
| **Error-state coverage** | All provider tests include error-path coverage; `mentor_providers_test.dart`, `planner_providers_test.dart`, and `question_providers_test.dart` include recovery-after-error tests. |
| **NavigatorObserver usage** | Pervasive in screen-level widget tests. |
| **Provider override verification** | Every provider test verifies dependency wiring via `ProviderContainer(overrides: [...])`. |
| **`fixedStudentId` adoption** | 92 references across planner/session widget tests. |
| **Previous issue resolved** | All 5 MAJOR and 3 MINOR items from Round 2 are confirmed fixed (misplaced files moved, missing test files created, text-based nav assertions replaced, error-path tests added, Hive I/O removed from 3 widget tests, `lessons_test.dart` deleted). |
| **Strong model tests** | `chat_message_data_test.dart` (560 lines), `session_model_test.dart` (1235 lines), and `settings_model_test.dart` (566 lines) set the standard with comprehensive edge-case and error-handling coverage. |

---

## Summary

| Severity | Count | Key fix |
|---|---|---|
| MAJOR | 4 groups (11 files) | Create 8 missing test files, implement 2 placeholder test files, fix 1 placeholder assertion, move 1 misplaced test file |
| MINOR | 4 groups (28 files) | Enhance/delete 19 barrel placeholder files, migrate 3 widget tests to `fixedStudentId`, eliminate `Hive.init()` in 4 unit tests, add edge-case coverage to 3 model tests |
