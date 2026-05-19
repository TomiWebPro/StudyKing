# Code Refactor Master Issue

**Generated:** 2026-05-19
**Scope:** Entire `lib/` codebase (364 Dart source files)
**Analysis methods:** `flutter analyze`, ripgrep pattern analysis, cross-file import tracing, manual review

---

## BLOCKER — App crashes or user cannot proceed

### B1. Silent error swallowing in `agent_loop.dart`

**File:** `lib/core/services/llm_agent/agent_loop.dart:87-88, 101-102`

Two `catch` blocks silently swallow exceptions without any logging:

```dart
// Line 87-88 — JSON parse failure silently ignored
} catch (e) {
  toolArgs = {};
}

// Line 101-102 — Tool execution failure silently absorbed
} catch (e) {
  toolResult = {'error': e.toString()};
}
```

**Rationale:** The first block means any malformed tool-call JSON from the LLM is silently discarded — the LLM agent gets empty args with no feedback, leading to silent tool-call failures or infinite retry loops. The second at least captures the error string into the result, but with zero local logging, debugging agent loops becomes extremely difficult.

**Acceptance criteria:**
- [ ] Both catch blocks must log the exception using `_logger.w('...')` with a descriptive message
- [ ] The first catch should also consider whether to include the error in the agent's message history so the LLM can self-correct
- [ ] Both blocks must continue to handle the error gracefully (no crash), but must emit a structured warning log

### B2. Missing try/catch on `OnboardingService` completion methods

**Files:**
- `lib/features/onboarding/services/onboarding_service.dart:28` (`markCompleted`)
- `lib/features/onboarding/services/onboarding_service.dart:32` (`markDontShowAgain`)

**Issue:** These methods perform Hive write operations but have no try/catch wrapper. If the Hive box is not open, they will throw an unhandled exception that cascades to the widget tree.

**Acceptance criteria:**
- [ ] `markCompleted()` must wrap the Hive write in try/catch and return `Result<void>` or catch + log gracefully
- [ ] `markDontShowAgain()` must do the same
- [ ] Both methods should have a unit test that verifies graceful handling when the box is closed

---

## MAJOR — Feature is broken, misleading, or structurally unsound

### M1. Cross-feature circular dependency: `practice` ↔ `questions`

**Cycle detected:**
```
features/practice/ ──imports──▶ features/questions/
features/questions/ ──imports──▶ features/practice/
```

**Evidence:**

| Direction | File | What is imported |
|---|---|---|
| practice → questions | `practice/services/spaced_repetition_service.dart` | `questions/data/repositories/question_repository.dart` |
| practice → questions | `practice/presentation/screens/practice_screen.dart` | `questions/providers/question_providers.dart`, `questions/data/repositories/question_repository.dart` |
| practice → questions | `practice/providers/practice_providers.dart` | `questions/providers/question_providers.dart` |
| questions → practice | `questions/presentation/question_bank_screen.dart:15` | `practice/providers/practice_providers.dart` |

**Rationale:** A direct 2-step cycle creates a fragile bidirectional coupling where changes in either feature risk breaking the other. The question bank screen imports `practice_providers` for due-count display, while practice services import question repositories for retrieval. This cycle makes it impossible to extract either feature into a standalone package.

**Acceptance criteria:**
- [ ] Move the shared interface (e.g., `PracticeSummaryProvider` or `DueCount`) into `core/providers/` or define it as an abstract contract in a neutral location
- [ ] `QuestionBankScreen` must depend on an abstract provider interface rather than directly on `practice_providers`
- [ ] `SpacedRepetitionService` must depend on an abstract `QuestionRepositoryInterface` rather than the concrete `QuestionRepository`
- [ ] All imports crossing the cycle must be mediated by core abstractions; verify with `rg` that no `features/practice/` file directly imports from `features/questions/` and vice versa after the refactor

### M2. Cross-feature coupling mesh (12/15 features directly import other features)

**Summary:** 12 of 15 features contain direct imports from other features, creating a tightly coupled dependency web. The most imported features are:

| Feature | Imported By | Outgoing imports (other features) |
|---|---|---|
| `subjects/` | 8 features | 4 features |
| `practice/` | 7 features | 4 features |
| `questions/` | 7 features | 3 features |
| `sessions/` | 6 features | 2 features |
| `settings/` | 1 feature | **8 features (highest fan-out)** |
| `dashboard/` | 1 feature | **7 features (2nd highest fan-out)** |

**Full cross-feature import matrix (all):**

| Feature | Imports From |
|---|---|
| planner | lessons, practice, subjects, questions, sessions |
| practice | questions, sessions, subjects, ingestion |
| teaching | lessons, focus_mode |
| mentor | teaching, planner, sessions, practice, subjects, questions |
| focus_mode | practice, questions, sessions, subjects, settings |
| settings | ALL except onboarding, llm_tasks, quickguide |
| dashboard | practice, sessions, subjects, planner, questions, ingestion, focus_mode |
| ingestion | subjects, questions, lessons |
| subjects | ingestion, sessions, practice, lessons |
| questions | ingestion, subjects, practice |
| sessions | practice, planner, subjects |
| quickguide | teaching |
| lessons | (self-contained) |
| llm_tasks | (self-contained) |
| onboarding | (self-contained) |

**Affected files:** 100+ files across `lib/features/` (see companion matrix from exploration for exact per-file mapping)

**Rationale:** This degree of coupling means:
1. No single feature can be extracted, tested, or maintained in isolation
2. A change in `subjects/` models can ripple through 8 features
3. `settings_screen.dart` (1859 lines) imports 18 models from 7 other features just for its data-clear functionality — a strong Modularity Violation smell
4. `mentor_service.dart` is a God Service importing from 6 other features with 792 lines

**Acceptance criteria (gradual, ordered by impact):**
- [ ] Extract shared domain models used across ≥3 features into `core/data/models/`:
  - `MasteryStateModel` (used by 5+ features) — currently in `features/practice/data/models/`
  - `TopicDependencyModel` (used by 5+ features) — currently in `features/subjects/data/models/`
  - `QuestionEvaluationModel` (used by 3+ features) — currently in `features/questions/data/models/`
  - `LessonModel` / `LessonBlockModel` (used by 5+ features) — currently in `features/lessons/data/models/`
- [ ] Replace cross-feature repository imports with abstract interfaces in core (e.g. `QuestionRepositoryInterface` in `core/data/interfaces/`)
- [ ] Refactor `settings_screen.dart` clear-cache to use a dedicated `CacheWipeService` in core instead of importing 18 models
- [ ] Verify after each extraction: only `core/data/models/` and `core/data/interfaces/` are imported across feature boundaries

### M3. SettingsRepository throws in private helpers (Result convention violation)

**File:** `lib/features/settings/data/repositories/settings_repository.dart:21, 29`

**Issue:** `_requireSettingsBox()` and `_requireProfileBox()` throw `AppException` directly instead of returning `Result<Box>`. While the throws are caught by callers' try/catch blocks, this creates a fragile dependency — any new public method that forgets the try/catch propagates an unhandled exception.

**Acceptance criteria:**
- [ ] Change `_requireSettingsBox()` to return `Result<Box>` (or make it a getter that initializes lazily)
- [ ] Change `_requireProfileBox()` to return `Result<Box>`
- [ ] Remove the try/catch from all 12 public methods that currently rely on throwing as control flow
- [ ] Verify no other file in the codebase calls `settings_repository.dart` methods without try/catch or Result handling

### M4. Public methods returning `void` / bare types instead of `Result<T>`

**Files and methods:**

| File | Method | Current Return | Should Be |
|---|---|---|---|
| `lib/features/planner/services/personal_learning_plan_service.dart:510` | `recordDailyAdherence()` | `Future<void>` | `Future<Result<void>>` |
| `lib/features/planner/services/personal_learning_plan_service.dart:657` | `extendPlan()` | `Future<void>` | `Future<Result<void>>` |
| `lib/features/planner/services/personal_learning_plan_service.dart:616` | `redistributeMissedWorkload()` | `Future<void>` | `Future<Result<void>>` |
| `lib/features/sessions/services/study_timer_service.dart:97` | `startSession()` | `Future<Session>` | `Future<Result<Session>>` |
| `lib/core/services/study_progress_tracker.dart:34` | `getOverallStats()` | `Future<Map<String, dynamic>>` | `Future<Result<Map<String, dynamic>>>` |

**Rationale:** Per AGENTS.md: "Public repository and service method return types must be `Result<T>`." These methods currently force callers to inspect raw exceptions or risk unhandled crashes when errors occur.

**Acceptance criteria:**
- [ ] `recordDailyAdherence()` returns `Future<Result<void>>`; all callers updated
- [ ] `extendPlan()` returns `Future<Result<void>>`; all callers updated
- [ ] `redistributeMissedWorkload()` returns `Future<Result<void>>`; all callers updated
- [ ] `startSession()` returns `Future<Result<Session>>`; all callers handle binding/unwrapping
- [ ] `getOverallStats()` returns `Future<Result<Map<String, dynamic>>>`; all callers handle binding/unwrapping

### M5. Unused `SpacedRepetitionErrorCode` values

**File:** `lib/core/errors/spaced_repetition_error_codes.dart`

**Issue:** 2 of 4 enum values are never used in production code:

| Value | Status |
|---|---|
| `boxClosed` | Used (lines 105, 213, 231, 261 in `spaced_repetition_service.dart`) |
| `notFound` | Used (lines 125, 194 in `spaced_repetition_service.dart`) |
| `invalidState` | **Never referenced anywhere in `lib/` or `test/`** |
| `storageFailure` | **Never referenced anywhere in `lib/` or `test/`** |

**Acceptance criteria:**
- [ ] Either remove `invalidState` and `storageFailure` (simplest), OR
- [ ] Add code paths in `spaced_repetition_service.dart` that produce these codes for appropriate error scenarios
- [ ] After cleanup, add a test that verifies all enum values are used at least once (use reflection or a simple coverage lint)

### M6. 27 unused barrel files (AGENTS.md convention violation)

**Convention:** "Do not create barrel files unless they are imported by production code."

**Barrel files NOT imported by any production code:**

| File | Lines |
|---|---|
| `lib/core/utils/utils.dart` | ≥1 export |
| `lib/features/features.dart` | ≥1 export |
| `lib/features/onboarding/onboarding.dart` | ≥1 export |
| `lib/features/settings/settings.dart` | ≥1 export |
| `lib/features/planner/planner.dart` | ≥1 export |
| `lib/features/planner/data/planner_data.dart` | ≥1 export |
| `lib/features/mentor/mentor.dart` | ≥1 export |
| `lib/features/ingestion/ingestion.dart` | ≥1 export |
| `lib/features/quickguide/quickguide.dart` | ≥1 export |
| `lib/features/sessions/sessions.dart` | ≥1 export |
| `lib/features/questions/questions.dart` | ≥1 export |
| `lib/features/questions/data/questions_data.dart` | ≥1 export |
| `lib/features/focus_mode/focus_mode.dart` | ≥1 export |
| `lib/features/llm_tasks/llm_tasks.dart` | ≥1 export |
| `lib/features/subjects/subjects.dart` | ≥1 export |
| `lib/features/subjects/data/subjects_data.dart` | ≥1 export |
| `lib/features/teaching/teaching.dart` | ≥1 export |
| `lib/features/teaching/data/teaching_data.dart` | ≥1 export |
| `lib/features/practice/practice.dart` | ≥1 export |
| `lib/features/practice/data/practice_data.dart` | ≥1 export |
| `lib/features/dashboard/dashboard.dart` | ≥1 export |
| `lib/features/lessons/lessons.dart` | ≥1 export |
| `lib/core/data/data.dart` | ≥1 export |
| (plus 4 more nested barrel files not individually listed) | |

**Exception (valid):** `core/widgets/widgets.dart` — imported by 15 production files.

**Note:** `core/data/data.dart` is imported by `main.dart` and should be retained.

**Acceptance criteria:**
- [ ] Files that are truly unused (no production imports at all): **Delete the file** (the exports are unused; removing the barrel does not break imports since code imports by direct path)
- [ ] Files that have at least one production import: **Retain** but verify their exports are all consumed
- [ ] Move the `export` lines from deleted barrel files into the relevant feature entry point if one exists
- [ ] Update `AGENTS.md` if a barrel convention exception is needed (e.g. for test convenience)

### M7. 62+ inline `const Logger('Name')` violations (AGENTS.md convention)

**Convention:** "All Logger instances must be `static final` at class level. Inline `const Logger('Name').e(...)` is forbidden."

**Worst offenders:**

| File | Count | Pattern |
|---|---|---|
| `planner/providers/planner_providers.dart` | 24 | Per-method `final logger = const Logger('PlannerNotifier.xxx')` |
| `dashboard/providers/dashboard_data_providers.dart` | 10 | Inline in every catch block |
| `planner/services/planner_service.dart` | 9 | Inline in every catch block |
| `practice/services/spaced_repetition_service.dart` | 8 | All `.e()` (not `.w()`) inline |
| `settings/presentation/settings_screen.dart` | 8 | Mixed `.e()` and `.w()` inline |
| `subjects/presentation/widgets/subject_topics_tab.dart` | 6 | All `.e()` inline |
| `focus_mode/presentation/focus_timer_screen.dart` | 5 | All `.e()` inline |
| `teaching/services/tutor_service.dart` | 10 | All `.e()` inline |
| `dashboard/presentation/widgets/export_section.dart` | 6 | Inline in every catch block |
| `document_extractor.dart` | 4 | Mixed inline |
| `core/services/llm/llm_chat_service.dart` | 3 | Inline in stream error handlers |

**Full list of ~62 locations:** See companion log-level analysis report.

**Acceptance criteria:**
- [ ] Every class in `lib/` that logs must declare `static final Logger _logger = const Logger('ClassName');` as a class-level field
- [ ] Every inline `const Logger('Tag').method(...)` call must be replaced with `_logger.method(...)`
- [ ] Top-level functions (e.g. `_showAboutDialog` in `settings_screen.dart`) may use `final log = const Logger('Tag');` as a local variable but must declare it once per function, not inline per-catch
- [ ] After changes, run `rg 'const Logger\(' lib/` — there should be 0 matches for inline usage (only class-level declarations remain)

### M8. Widespread wrong log level: 178 `.e()` calls that should be `.w()`

**Convention:** "`.e()` should only be used for unexpected exceptions that require immediate investigation. `.w()` should be used for caught exceptions in expected error paths."

**Summary:** 178 of 178 caught-exception `.e()` calls across the codebase should be `.w()`. These are all expected errors (box not open, item not found, API failure, data loading failure) that are handled gracefully.

**Worst offenders (10+ violations):**

| File | `.e()` count | Example error being logged |
|---|---|---|
| `settings/presentation/settings_screen.dart` | 8 | "Failed to load data", backup failures |
| `teaching/services/tutor_service.dart` | 10 | Session update failed, plan adapter failed |
| `practice/services/spaced_repetition_service.dart` | 8 | Box closed, item not found (expected) |
| `dashboard/providers/dashboard_data_providers.dart` | 10 | Stats/badges/trends fetch failed |
| `subjects/presentation/widgets/subject_topics_tab.dart` | 6 | CRUD operation failures |
| `subjects/presentation/subject_detail_screen.dart` | 4 | Loading/editing failures |
| `focus_mode/presentation/focus_timer_screen.dart` | 5 | Initialization failures |
| `practice/presentation/screens/practice_screen.dart` | 4 | Due-count/attempt load failures |
| `sessions/presentation/session_tracker_screen.dart` | 4 | Session/adherence load failures |
| `dashboard/presentation/widgets/export_section.dart` | 6 | Export format failures |

**Example of correct usage (model to follow):**
- `features/questions/data/repositories/question_repository.dart` — all 8 caught exceptions correctly use `.w()`
- `features/planner/services/planner_service.dart` — all caught exceptions use `.w()`
- `core/services/engagement_scheduler.dart` — all caught exceptions use `.w()`

**Acceptance criteria:**
- [ ] All 178 `.e()` calls in caught-exception blocks must be changed to `.w()`
- [ ] Exception: `.e()` may remain for `catch` blocks that indicate a truly unexpected/impossible state (e.g., a code path that "can't happen")
- [ ] Verify with `rg '\.e\(' lib/` that remaining `.e()` calls are only on unexpected, non-handled exceptions
- [ ] Add a lint rule (e.g. custom lint or code review check) enforcing `.w()` for caught exceptions going forward

### M9. Empty directory: `lib/features/practice/utils/`

**File:** `lib/features/practice/utils/` — directory exists but contains zero files.

**Acceptance criteria:**
- [ ] Remove the empty directory, OR add a `.gitkeep` with an explanation comment

---

## MINOR — Code quality / UX friction / maintainability

### m1. Raw magic numbers `60000` and `1000` should use defined constants

**Constants defined but unused:** `lib/core/utils/study_utils.dart` defines `msPerMinute = 60000` and `msPerSecond = 1000`, but they are never used — raw literals appear everywhere:

**`60000` appears 14 times:**
| File | Lines |
|---|---|
| `session_export_service.dart` | 44, 170, 180 |
| `study_timer_service.dart` | 76, 86, 93, 184 |
| `session_tracker_screen.dart` | 231 |
| `focus_timer_screen.dart` | 98, 873 |
| `tutor_service.dart` | 169, 186 |
| `mentor_service.dart` | 392 |
| `study_progress_tracker.dart` | 120 |

**`1000` appears 16 times:**
| File | Lines |
|---|---|
| `study_timer_service.dart` | 32, 56, 144 |
| `session_export_service.dart` | 181 |
| `session_repository.dart` | 182 |
| `focus_timer_screen.dart` | 208 |
| `session_summary_card.dart` | 29 |
| `dashboard_data_providers.dart` | 80 |
| `dashboard_service.dart` | 82 |
| `study_progress_tracker.dart` | 84, 326, 351 |
| `progress_export_service.dart` | 91 |
| `settings_screen.dart` | 1474 |
| `settings_model.dart` | 183 |
| `session_migration_service.dart` | 70 |

**Acceptance criteria:**
- [ ] Import `msPerMinute` from `study_utils.dart` in all 14 locations and replace `60000`
- [ ] Import `msPerSecond` from `study_utils.dart` in all 16 locations and replace `1000`
- [ ] Verify no raw `60000` or `1000` remains for time conversions (search with `rg '\b60000\b'` and `rg '\b1000\b'`)

### m2. Dead production code: `AppFontSize` class

**File:** `lib/core/constants/app_radius.dart:29-39`

`class AppFontSize` with 7 static const values (xs through display) is defined but imported by zero production files.

**Acceptance criteria:**
- [ ] Either remove `AppFontSize` entirely, OR move it to a separate `app_font_size.dart` if it is intended for future use (with appropriate justification comment)

### m3. Dead production code: `QuestionPdfGenerator`

**File:** `lib/core/services/pdf_generator/question_pdf_generator.dart` (157 lines)

Only imported by a single test file (`test/core/services/question_pdf_generator_test.dart`). Not wired into any production flow.

**Acceptance criteria:**
- [ ] Either (a) wire it into the app's export functionality (e.g., add a "Generate PDF question bank" button), OR
- [ ] Remove the class and its test (dead code), OR
- [ ] Move to a `staging/` directory with a ticket reference for future integration

### m4. `settings_model.dart` hardcodes `'en'` locale for currency display

**File:** `lib/features/settings/data/models/settings_model.dart:117`

```dart
formatCurrency(totalCost, 'en', ...)
```

Hardcodes `'en'` locale inside a model class. The locale should be passed in from the presentation layer via `AppLocalizations.of(context)!.localeName`.

**Acceptance criteria:**
- [ ] `SettingsModel.formatCurrency` (or equivalent method) accepts `localeName` as a parameter
- [ ] All callers pass `l10n.localeName` from the presentation layer
- [ ] No hardcoded locale strings in any model class

### m5. `mentor_screen.dart` uses `.normalized` on localized display string

**File:** `lib/features/mentor/presentation/mentor_screen.dart:914`

```dart
l10n.mentorCompletedLessons('').split(':').first.normalized
```

The `.normalized` extension lowercases the string, which may strip semantically meaningful casing from the localized display.

**Acceptance criteria:**
- [ ] Review whether `.normalized` is semantically correct here (is this used for display or for matching?)
- [ ] If for display, remove `.normalized` and use the localized string as-is
- [ ] Add a comment if `.normalized` is intentionally used (e.g., for comparison/sorting)

### m6. Redundant `MasteryGraphRepository` facade advises against its own use

**File:** `lib/features/practice/data/repositories/mastery_graph_repository.dart:14-15`

```dart
/// Facade that delegates to four individual repositories.
/// New code should depend on the specific repositories directly.
```

A class whose own doc comment tells new code not to use it.

**Acceptance criteria:**
- [ ] Either remove the facade entirely and update all existing consumers to depend on the individual repositories, OR
- [ ] Update the comment to reflect its actual purpose (e.g., facade for backward compatibility with a planned removal date)

### m7. 20 repository subclasses with identical boilerplate (code generation opportunity)

**File:** `lib/core/data/repository.dart` defines base `Repository<T>` with 4 methods (put, get, getAll, delete).

Every one of the 20 concrete repository subclasses overrides all 4 methods with near-identical try/catch/`Result.failure` boilerplate. Example pattern repeated ~80 times across the codebase:

```dart
Future<Result<T>> get(String key) async {
  try {
    final box = await Hive.openBox<T>(boxName);
    final item = box.get(key);
    return Result.success(item);
  } catch (e) {
    return Result.failure('Failed to get $key: $e');
  }
}
```

**Affected files (20 repos, ~80 catch blocks):**
- `question_repository.dart`, `subject_repository.dart`, `topic_repository.dart`, `session_repository.dart`, `lesson_repository.dart`, `mastery_state_repository.dart`, `attempt_repository.dart`, `mastery_graph_repository.dart`, `question_mastery_state_repository.dart`, `question_evaluation_repository.dart`, `topic_dependency_repository.dart`, `source_repository.dart`, `plan_repository.dart`, `roadmap_repository.dart`, `pending_action_repository.dart`, `plan_adherence_repository.dart`, `engagement_nudge_repository.dart`, `student_availability_repository.dart`, `tutor_session_repository.dart`, `conversation_repository.dart`, `badge_repository.dart`, `settings_repository.dart`

**Acceptance criteria:**
- [ ] Evaluate a mixin-based approach: define `BoxRepositoryMixin` in `core/data/` that provides default put/get/getAll/delete implementations with Result wrapping
- [ ] Each repository uses the mixin and only overrides methods for custom business logic
- [ ] Target: eliminate >50% of the repetitive try/catch boilerplate
- [ ] Alternative: consider `Repository<T>.auto(T Function())` pattern that wraps arbitrary operations in Result

### m8. 6+ monolithic build methods exceeding 200 lines

**Files with overly large build/widget methods:**

| File | Size | Method |
|---|---|---|
| `lib/features/mentor/presentation/mentor_screen.dart` | 1165 lines total | `build()` ~555 lines |
| `lib/features/planner/presentation/planner_screen.dart` | 1477 lines total | `build()` ~270 lines |
| `lib/features/settings/presentation/settings_screen.dart` | 1859 lines total | `_buildSettingsBody()` ~212 lines |
| `lib/features/focus_mode/presentation/focus_timer_screen.dart` | 1092 lines total | `build()` large |
| `lib/features/teaching/presentation/tutor_screen.dart` | 985 lines total | `build()` large |
| `lib/features/practice/presentation/screens/practice_screen.dart` | 864 lines total | `build()` large |

**Acceptance criteria (per file):**
- [ ] Extract sections of the build method into separate `Widget` classes or `StatelessWidget` methods
- [ ] Each extracted widget must have a single responsibility (e.g., `_buildStatsSection`, `_buildActionButtons`)
- [ ] Target: no build method exceeds 100 lines
- [ ] Each extracted widget must have its own test (widget test or unit test as appropriate)
- [ ] After extraction, verify the screen file is <500 lines total (ideally <400)

### m9. `spaced_repetition_service.dart` comment marks `SpacedRepetitionQueries` as temporary

**File:** `lib/features/practice/services/spaced_repetition_service.dart:21`

```dart
// Remove after migrating test helpers to use SpacedRepetitionService methods.
```

This comment references `SpacedRepetitionQueries` as a temporary helper that should be removed, but the class is still in production code.

**Acceptance criteria:**
- [ ] Audit usage of `SpacedRepetitionQueries` in both production and test code
- [ ] If all usages have been migrated, remove the class and the comment
- [ ] If not yet migrated, update the comment with a concrete target date or ticket reference

### m10. Non-`static final` Logger declarations (convention violation)

**Convention:** "All Logger instances must be `static final` at class level."

~35 files declare `final Logger _logger` (instance-level) instead of `static final Logger _logger`. Including:

| File | Line | Declaration |
|---|---|---|
| `core/data/database_service.dart` | 13 | `final Logger _logger` |
| `core/data/extraction/pdf_extractor.dart` | 19 | `final Logger _logger` |
| `core/services/cross_feature_integrator.dart` | 34 | `final Logger _logger` |
| `core/services/engagement_scheduler.dart` | 40 | `final Logger _logger` |
| `features/practice/services/spaced_repetition_service.dart` | 67 | `final Logger _logger` |
| ... and ~30 more | | |

**Acceptance criteria:**
- [ ] Change all `final Logger _logger` to `static final Logger _logger` in all service/repository/utility classes
- [ ] Presentation widgets/screens are lower priority but should follow suit
- [ ] Run `rg '^\s+final Logger _logger' lib/` to verify zero remaining instance-level Logger declarations

### m11. Inconsistent error string format in `Result.failure()` calls

**Files use at least 3 different error string styles:**

| Style | Example | Files |
|---|---|---|
| Enum code name | `Result.failure(SpacedRepetitionErrorCode.boxClosed.name)` | `spaced_repetition_service.dart` |
| Code-like identifier | `Result.failure('Question_bank_not_open')` | `question_repository.dart` |
| Descriptive prose | `Result.failure('Failed to get item: $e')` | Most repositories |
| Raw exception | `Result.failure(e.toString())` | Common pattern |

**Acceptance criteria:**
- [ ] Decide on a single standard (recommended: `'ClassName.methodName: description'` for consistency with log format)
- [ ] Apply the standard across all `Result.failure()` calls
- [ ] Update the AGENTS.md convention to document the chosen standard
- [ ] Verify with `rg 'Result\.failure\(' lib/` that all ~120 calls follow the new standard

### m12. `'Bearer '` string literal duplicated 9 times

**Appears in:**
- `lib/core/services/llm/llm_chat_service.dart` (lines 390, 432, 625, 666)
- `lib/core/services/llm/llm_model_service.dart` (lines 145, 179)
- `lib/core/services/llm/llm_embeddings_service.dart` (lines 41, 49)
- `lib/features/settings/presentation/api_config_screen.dart` (line 177)

**Acceptance criteria:**
- [ ] Define a `static const String bearerAuth = 'Bearer '` in a central location (e.g., `core/constants/app_api_config.dart`)
- [ ] Replace all 9 occurrences with the named constant

### m13. Hardcoded API URLs not environment-configurable

**File:** `lib/core/constants/app_api_config.dart:57-70`

The following URLs are hardcoded:
- OpenRouter base URL, Ollama URL, OpenAI URL
- YouTube transcript API URL
- YouTube Data API v3 URL
- User-Agent string

These cannot be overridden for staging/test environments or self-hosted alternatives.

**Acceptance criteria:**
- [ ] Add `--dart-define` environment variables for each URL (e.g., `OPENROUTER_BASE_URL`, `OLLAMA_BASE_URL`, etc.)
- [ ] Fall back to the current hardcoded values when the env var is not set
- [ ] Update `.env.example` with the new variables
- [ ] Verify all 4 LLM services read from the config rather than raw literals

### m14. Missing lint: no `rethrow` within `Result<T>` return-type context

**Files using `rethrow` in methods that don't return `Result<T>`:**
- `core/services/llm/llm_chat_service.dart` — stream methods (OK — streams can't return Result)
- `features/mentor/services/mentor_service.dart:191` — `chat()` rethrows inside a stream
- `features/teaching/services/conversation_manager.dart:213` — `sendMessage()` rethrows inside a stream

These are acceptable because stream methods inherently can't use `Result<T>`. However, this inconsistency means stream consumers must handle both patterns.

**Acceptance criteria (investigative, not prescriptive):**
- [ ] Document in AGENTS.md how stream-based methods should communicate errors (e.g., `Result<T>` for non-stream, `Exception` via stream for stream)
- [ ] Add a `StreamResult<T>` type or convention if widely applicable (optional, for future consideration)

---

## Files exceeding complexity thresholds (for prioritization)

| File | Lines | Primary Concern |
|---|---|---|
| `features/settings/presentation/settings_screen.dart` | 1859 | God screen: imports from 7 features, 12 catch blocks, 8 `.e()` violations |
| `features/planner/presentation/planner_screen.dart` | 1477 | God screen: build() ~270 lines, 25+ catch blocks in providers |
| `features/mentor/presentation/mentor_screen.dart` | 1165 | build() ~555 lines, imports from 4 features |
| `features/focus_mode/presentation/focus_timer_screen.dart` | 1092 | God screen: 10 catch blocks, 5 inline Logger violations |
| `features/planner/services/personal_learning_plan_service.dart` | 1018 | God service: 3 methods return void instead of Result |
| `features/teaching/presentation/tutor_screen.dart` | 985 | Large build method, inline Logger violations |
| `features/mentor/services/mentor_service.dart` | 792 | God service: imports from 6 features, 792 lines |
| `core/services/llm/llm_chat_service.dart` | 748 | Heavy service with 4 stream implementations |

---

## Summary of counts

| Severity | Count | Key items |
|---|---|---|
| **BLOCKER** | 2 | Silent error swallowing, missing try/catch in onboarding |
| **MAJOR** | 9 | Circular dep, coupling mesh, Result violations, inline Logger (62×), wrong log levels (178×), unused barrels (27×), unused enum values, empty dir |
| **MINOR** | 14 | Magic numbers (30×), dead code classes, hardcoded locale, facade advising against itself, boilerplate repos, monolithic builds, inconsistent error strings, hardcoded URLs, etc. |
| **Total** | **25** | |

**Note:** `dart analyze lib/` (3.4s) reports **0 issues** as of 2026-05-19 — the codebase is syntactically clean despite the structural issues above.
