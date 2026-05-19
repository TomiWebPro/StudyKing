# Code Refactor Master & Quality Audit

> Generated: 2026-05-19
> Scope: Full codebase exploration across `lib/`, `test/`, configuration, and architecture.

---

## BLOCKER (app crashes or user cannot proceed)

### B1. Memory leak risk — empty `catch (_) {}` swallowing fatal errors

**Context:** Five locations silently catch all exceptions with empty handlers, suppressing crashes that should propagate or at least be logged.

| File | Line | Code |
|---|---|---|
| `lib/main.dart` | 102 | `} catch (_) {}` |
| `lib/features/teaching/services/tutor_service.dart` | 265, 273, 305 | `} catch (_) {}` (3x) |
| `lib/features/sessions/presentation/session_tracker_screen.dart` | 75 | `} catch (_) {}` |
| `lib/features/settings/presentation/settings_screen.dart` | 1593 | `} catch (_) {}` |

**Rationale:** Swallowing exceptions makes failures completely invisible. If the tutor service or session tracker silently drops errors, the user gets no feedback and the app appears broken.

**Acceptance criteria:**
- Replace every empty `catch (_) {}` with either:
  - `catch (e, st) { _logger.e('...', e, st); }` with a descriptive message, or
  - `catch (e) { Result.failure(e.toString()); }` if in a Result-returning context.
- Verify no other empty catch blocks exist via `git grep 'catch\s*(\s*_\s*)'`.

---

## MAJOR (feature broken or misleading)

### M1. i18n violation — `toStringAsFixed()` in user-facing file-size display

**Affected file:** `lib/features/settings/presentation/settings_screen.dart:972,974`

**Context:** The `_formatBytes` helper (line ~970) uses `toStringAsFixed()` to display file sizes. This produces period decimals (`"1.2 MB"`) even for comma-decimal locales (Spanish `es`, French, German). Per AGENTS.md: *"Never use `toStringAsFixed()` for user-facing numeric displays."*

**Rationale:** Spanish-speaking users see `"1.2 MB"` instead of `"1,2 MB"`, breaking the i18n promise.

**Acceptance criteria:**
- Replace `toStringAsFixed()` in `_formatBytes` with `formatDecimal` or a dedicated `formatFileSize` utility from `lib/core/utils/number_format_utils.dart`.
- Unit test the new helper with `localeName: 'es'` to verify comma decimal.
- Confirm all other `toStringAsFixed()` calls are in CSV/LLM-facing contexts (exempt per AGENTS.md).

---

### M2. Mixed error-handling strategy (Result + raw exceptions + string errors)

**Context:** Three coexisting patterns — no enforcement of which to use where.

| Pattern | Prevalence | Example |
|---|---|---|
| `Result.failure('...')` | ~176 calls | `spaced_repetition_service.dart`, `settings_repository.dart` |
| `throw AppException(...)` | `app_api_config.dart:22,38`; `settings_repository.dart:21,29` | |
| Raw `Exception` / `throw` | Various | Ad-hoc string exceptions |

**Affected files:**
- `lib/features/settings/data/repositories/settings_repository.dart` — **same class** mixes `throw AppException` (lines 21, 29) and `return Result.failure(...)` (line 40).
- `lib/core/constants/app_api_config.dart` — throws `AppException` instead of returning `Result.failure`.
- `lib/features/practice/services/spaced_repetition_service.dart` — uses fragile string error codes (`'box_closed'`, `'not_found'`) not centralized anywhere.

**Rationale:** Callers cannot rely on a single error path. Some upper layers expect `Result`, others expect exceptions — leading to unhandled `AppException` crashes when a Result-returning method is refactored to throw.

**Acceptance criteria:**
- Establish a single codebase-wide rule in AGENTS.md: **public repository/service method return types must be `Result<T>`**; `throw` is only allowed in private helpers or config validation at startup.
- Refactor `settings_repository.dart` to consistently return `Result.failure(...)` instead of `throw AppException`.
- Refactor `app_api_config.dart` getters to return `Result<String>` instead of throwing.
- Centralize error-code strings (e.g., `SpacedRepetitionErrorCodes` enum in `lib/core/errors/`).

---

### M3. Secret injection unimplemented — API keys embedded at compile time

**Affected file:** `lib/core/constants/app_api_config.dart:32`

```dart
// TODO: implement runtime secret injection (keystore/native layer) over compile-time embedding.
```

**Context:** The `runtimeApiKey` and `runtimeBaseUrl` fields on `ApiConfig` are never populated. All API keys flow through `--dart-define` at build time, meaning they are plaintext in the binary.

**Rationale:** Security best practice violation. API keys can be extracted from the compiled binary.

**Acceptance criteria:**
- Implement the TODO by integrating a keystore/native secrets layer (e.g., `flutter_secure_storage` or platform channels).
- Fall back to `--dart-define` only when runtime storage is unavailable (dev builds).
- Remove the commented TODO after implementation.
- Unit test: confirm `ApiConfig.runtimeApiKey` returns stored value when available.

---

### M4. Massive build methods violate single-responsibility principle

**Affected files:**

| File | Build method length | Total file |
|---|---|---|
| `lib/features/planner/presentation/planner_screen.dart:428` | ~1046 lines | 1474 |
| `lib/features/mentor/presentation/mentor_screen.dart:532` | ~579 lines | 1118 |
| `lib/features/settings/presentation/settings_screen.dart:125` | ~243 lines (`_buildSettingsBody`) | 1826 |
| `lib/features/teaching/presentation/tutor_screen.dart:537` | ~391 lines | 928 |

**Rationale:** These methods handle layout, state derivation, event handling, and nested widget construction — far beyond "describe what this screen looks like." Each screen is a maintenance hazard: merges conflict constantly, readability is poor, and adding a single setting touch requires navigating 1800 lines.

**Acceptance criteria:**
- Extract every distinct logical section into its own `StatelessWidget` in a `widgets/` subdirectory.
  - `planner_screen.dart`: extract Calendar section, PlanSummary section, Roadmap section, PendingActions section into separate widget files.
  - `settings_screen.dart`: extract each settings category (Appearance, Notifications, Data, About, etc.) into a dedicated widget.
  - `mentor_screen.dart`: extract ChatPanel, StatsPanel, NudgePanel.
  - `tutor_screen.dart`: extract ChatArea, LessonProgress, VoiceBar, ExerciseArea.
- Each extracted widget must be under 150 lines.
- No existing widget test should break after extraction.

---

### M5. `StudentIdService()` direct instantiation in 28+ locations (no DI)

**Context:** `StudentIdService` is instantiated directly via `StudentIdService().getStudentId()` across the codebase instead of being injected via Riverpod or constructor parameter.

**Partial list of offenders:**
- `lib/main.dart:197-198,465`
- `lib/features/teaching/presentation/tutor_screen.dart:92,100`
- `lib/features/sessions/presentation/session_tracker_screen.dart:182`
- `lib/features/sessions/presentation/session_history_screen.dart:157`
- `lib/features/planner/services/planner_service.dart:77`
- `lib/features/mentor/services/mentor_service.dart:202`
- `lib/features/mentor/presentation/mentor_screen.dart:115`
- `lib/features/ingestion/presentation/upload_screen.dart:246,278`
- `lib/core/services/study_progress_tracker.dart:129,260`
- `lib/core/routes/app_router.dart:148,176`
- `lib/core/providers/app_providers.dart:223`

**Rationale:** Tight coupling makes it impossible to stub `StudentIdService` in tests, forcing every test to initialise Hive. AGENTS.md already recommends `fixedStudentId` for testing, yet production code never uses DI.

**Acceptance criteria:**
- Create a Riverpod provider for `StudentIdService` (or inject it as a parameter).
- Refactor all direct `StudentIdService().getStudentId()` calls to use the provider or constructor injection.
- Verify that at least one widget test no longer requires Hive initialization to run.

---

### M6. Cross-feature contamination — core services import feature packages

**Context:** Files in `lib/core/services/` import directly from `lib/features/*/data/repositories/`, creating a circular-ish dependency where core depends on features and features depend on core.

**Affected files:**
- `lib/core/services/personal_learning_plan_service.dart` — imports 6+ feature repositories (mastery graph, topic, subject, plan, etc.)
- `lib/core/services/mastery_graph_service.dart` — imports `features/practice/data/repositories/mastery_graph_repository.dart`
- `lib/core/services/study_progress_tracker.dart` — imports `features/planner/data/repositories/plan_adherence_repository.dart`
- `lib/core/data/hive_initializer.dart` — imports adapters from ALL features (lines 8-15)

**Rationale:** Architecture violation. Core should be feature-agnostic. When core depends on features, extracting a feature into a separate package becomes impossible, and the dependency graph is a mess.

**Acceptance criteria:**
- Move feature-specific services currently in `core/services/` into their respective feature directories:
  - `mastery_graph_service.dart` → `features/practice/services/`
  - `study_progress_tracker.dart` → `features/dashboard/services/` or `features/practice/services/`
  - `personal_learning_plan_service.dart` → `features/planner/services/`
  - `plan_adherence_orchestrator.dart` → `features/planner/services/`
- Move feature models from `core/data/models/` into their respective features:
  - `session_model.dart` → `features/sessions/data/models/`
  - `subject_model.dart` → `features/subjects/data/models/`
  - `topic_model.dart` → `features/subjects/data/models/`
  - `markscheme_model.dart` → `features/questions/data/models/`
- All existing imports across the codebase must be updated accordingly.
- The `hive_initializer.dart` should use a registry pattern or central adapter list, not per-feature imports.

---

### M7. Barrel files never imported by production code — dead exports

**Affected files:**
- `lib/features/features.dart`
- `lib/features/onboarding/onboarding.dart`
- `lib/features/quickguide/quickguide.dart`
- `lib/features/focus_mode/focus_mode.dart`
- `lib/features/llm_tasks/llm_tasks.dart`
- `lib/features/mentor/mentor.dart`
- `lib/features/ingestion/ingestion.dart`
- `lib/features/sessions/sessions.dart`
- `lib/features/subjects/subjects.dart`
- `lib/features/practice/practice.dart`
- `lib/features/planner/planner.dart`
- `lib/features/dashboard/dashboard.dart`
- `lib/features/lessons/lessons.dart`
- `lib/features/settings/settings.dart`
- `lib/features/teaching/teaching.dart`
- `lib/features/questions/questions.dart`
- `lib/core/utils/utils.dart`

**Rationale:** These barrel files export their feature's public API but nothing in production imports them — only test files reference them sporadically. They are misleading (suggest a public API surface that isn't used) and add unnecessary maintenance.

**Acceptance criteria:**
- Either delete all unreferenced barrel files, or make a single barrel `lib/studyking.dart` that aggregates only what external consumers need (unlikely in a Flutter app).
- Add a lint rule (e.g., `avoid_relative_lib_imports` or a custom `dart_code_metrics` rule) to prevent future barrel bloat.
- Update AGENTS.md to specify: *"Do not create barrel files unless they are imported by production code."*

---

### M8. Dead/inactive files (zero production usage)

**Context:** These files are never imported or referenced by any `lib/` production code. They only exist in test imports or nowhere at all.

| File | Lines | Status |
|---|---|---|
| `lib/core/services/cross_feature_integrator.dart` | 198 | Test-only |
| `lib/core/services/topic_readiness_service.dart` | 133 | Test-only |
| `lib/core/services/pdf_generator/question_pdf_generator.dart` | 157 | Test-only |
| `lib/core/services/llm/llm_embeddings_service.dart` | 79 | Zero references anywhere |
| `lib/core/providers/study_progress_provider.dart` | 27 | Test-only |
| `lib/core/utils/sr_data_codec.dart` | 34 | Test-only |

**Rationale:** Dead code increases maintenance surface, creates false confidence in test coverage (lines are "covered" but feature is dead), and confuses new contributors.

**Acceptance criteria:**
- For each file: either delete it, or move it to a `_deprecated/` directory with a clear comment and link to the tracking issue.
- Write a quick script (or manual check) to confirm no `lib/` imports reference these files.
- Pass: `git grep -l 'cross_feature_integrator' lib/` returns empty.

---

### M9. Dead utility functions — `snackbar_utils.dart` and `dialog_utils.dart` functions never called

**Affected files:**
- `lib/core/widgets/snackbar_utils.dart` — `showSuccessSnackBar` and `showErrorSnackBar` defined but never called in any `lib/` file.
- `lib/core/widgets/dialog_utils.dart` — `showConfirmationDialog` defined but never called.

**Rationale:** These exist in a shared widgets barrel (`lib/core/widgets/widgets.dart`) suggesting they are available utilities, but no production code uses them. New contributors may waste time evaluating them or worse, build on top of untested dead utilities.

**Acceptance criteria:**
- Either delete these files and their barrel exports, or add callsites in appropriate screens.
- If kept, add unit tests covering the functions.

---

### M10. Hardcoded Duration values outside `timeouts.dart` (>20 instances)

**Context:** `lib/core/constants/timeouts.dart` exists as the canonical location for Duration constants, yet values are scattered inline.

**Partial list:**
- `lib/features/settings/presentation/settings_screen.dart:1647` — `Duration(seconds: 10)`
- `lib/features/teaching/presentation/tutor_screen.dart:137,449,863,908,919` — various
- `lib/features/teaching/services/conversation_manager.dart:258` — `Duration(milliseconds: 15)`
- `lib/features/sessions/presentation/session_history_screen.dart:491` — `Duration(hours: 1)`
- `lib/features/practice/presentation/screens/practice_session_screen.dart:691,746,747` — various
- `lib/features/planner/services/planner_service.dart:388,407` — `Duration(hours: 1)` (duplicate)
- `lib/core/services/engagement_scheduler.dart:106` — `Duration(minutes: 5)`
- `lib/core/services/llm_agent/idle_executor.dart:41` — `Duration(seconds: 30)`
- etc.

**Rationale:** Inline durations make it impossible to tune timing globally, and duplicate values (like `Duration(hours: 1)` for "recent session" in 3 places) risk silent drift.

**Acceptance criteria:**
- Audit all inline `Duration(...)` in `lib/` (excluding animation-specific durations in widget build methods).
- Move every repeated or semantically meaningful duration into `lib/core/constants/timeouts.dart` with a descriptive name.
- Replace all inline durations with the constant reference.

---

## MINOR (code quality / UX friction)

### m1. Inconsistent Logger instantiation pattern

**Affected files:** Widespread (30+ files).

**Patterns found:**
```dart
final Logger _logger = const Logger('Name');          // instance variable
static final Logger _logger = const Logger('Name');    // static final
const Logger('SettingsScreen').e('...');               // inline (settings_screen.dart, 8x)
```

**Rationale:** Inline Logger creation (third pattern) allocates a new object on every error call path and makes it impossible to globally configure log filtering by tag.

**Acceptance criteria:**
- Codify in AGENTS.md: *"All Logger instances must be `static final` at class level."*
- Refactor all inline `const Logger(...).e(...)` calls to use a `static final` instance.
- Refactor instance-level `final Logger(...)` to `static final`.

---

### m2. Incorrect log levels — warnings used for errors, errors for warnings

**Affected files:**

`.w()` where `.e()` is appropriate:
- `lib/features/practice/services/spaced_repetition_service.dart` — 8 catch blocks use `.w()` for `Exception` handling (lines 109, 144, 172, 202, 222, 239, 250, 271)
- `lib/core/utils/sr_data_codec.dart:21` — `.w()` for deserialization failure

`.e()` where `.w()` may be more appropriate:
- `lib/features/questions/data/repositories/question_repository.dart` — 8 locations use `.e()` for repository transaction errors (lines 22, 34, 47, 64, 76, 92, 120, 136)

**Rationale:** When developers search logs for `ERROR` level, they miss actual errors logged as warnings. Conversely, routine repository errors at `.e()` flood the error channel and desensitize the team.

**Acceptance criteria:**
- `.e()` should only be used for unexpected exceptions that require immediate investigation.
- `.w()` should be used for caught exceptions in expected error paths (e.g., box not open, item not found).
- Audit every `.w()` and `.e()` call across `lib/` and correct misclassifications.

---

### m3. Duplicate `trim().toLowerCase()` normalization (30+ callsites)

**Affected files (partial):**
- `lib/core/services/answer_validation_service.dart:77-78,331-332,360-361,367-368`
- `lib/core/data/models/markscheme_model.dart:54-55,60`
- `lib/features/questions/data/models/question_evaluation_model.dart:136-137,142`
- `lib/features/questions/presentation/widgets/question_card_widget.dart:377,382,387`
- `lib/features/lessons/presentation/widgets/lesson_block_card.dart:312-316`
- `lib/features/lessons/services/lesson_agent_service.dart:122`

**Rationale:** Each callsite implements the exact same string normalization with subtle ordering differences (`.trim().toLowerCase()` vs `.toLowerCase().trim()`). A shared extension method eliminates duplication and guarantees consistent behavior.

**Acceptance criteria:**
- Add a `StringExtension` extension in `lib/core/utils/string_extensions.dart`:
  ```dart
  extension StringExtension on String {
    String get normalized => trim().toLowerCase();
  }
  ```
- Replace all `trim().toLowerCase()` / `toLowerCase().trim()` patterns with `.normalized`.
- Delete the utility file instead of adding if only one normalization strategy is used (collapse into fewer patterns).

---

### m4. Magic numbers in business logic (>15 occurrences)

**Affected files (key examples):**
- `lib/features/teaching/services/conversation_manager.dart:278,281,340,346,350` — 0.15, 1.5, 0.5, 0.5 (adaptive pace adjustments and default exercise ratio, repeated)
- `lib/features/practice/services/spaced_repetition_service.dart:152,163` — 0.5 mastery threshold, 2.5 default ease factor
- `lib/features/planner/providers/planner_providers.dart:79,114,120,240` — 0.5 adherence threshold repeated 4x
- `lib/features/planner/presentation/planner_screen.dart:695-696` — 0.5, 8.0 pace hours clamp
- `lib/features/practice/presentation/screens/practice_screen.dart:215` — `_minAttemptsForWeakAreas = 10`
- `lib/features/lessons/presentation/lesson_list_screen.dart:88` / `lesson_detail_screen.dart:81` — `_defaultDurationMinutes = 45` (duplicate)
- `lib/main.dart:317` / `lib/features/settings/presentation/settings_screen.dart:476` — font size `10.0, 30.0` clamps (duplicate)

**Rationale:** Magic numbers are untestable, undocumented, and duplicated. When the `0.5` mastery threshold changes, it must be updated in every file that duplicates it.

**Acceptance criteria:**
- Extract every semantic number into a named constant at the top of its class or in a shared constants file.
- For values shared across files (e.g., mastery threshold, font-size range), move to `lib/core/constants/`.
- Ensure zero approval of new magic numbers via a lint rule (`no-magic-number` or custom).

---

### m5. Duplicate clarity: `Duration(hours: 1)` repeated for "recent session" filtering

**Affected files:**
- `lib/features/sessions/data/repositories/session_repository.dart:213`
- `lib/features/sessions/presentation/session_history_screen.dart:491`
- `lib/features/planner/services/planner_service.dart:388,407`

**Rationale:** All four instances represent the same concept: *"how recent must a session be to count as 'recent'".* Each defines it independently.

**Acceptance criteria:**
- Add `static const recentSessionWindow = Duration(hours: 1);` to `lib/core/constants/timeouts.dart`.
- Replace all four inline `Duration(hours: 1)` with `Timeouts.recentSessionWindow`.

---

### m6. Assert-with-closure pattern in `app_config.dart`

**Affected file:** `lib/core/constants/app_config.dart:72`

```dart
assert(() {
  // body
  return true;
}());
```

**Rationale:** This pattern runs code inside an `assert` closure, which works in debug mode but silently disappears in release mode. If the closure has side effects or is meant to validate at runtime, it's a bug; if it's truly just for debugging, the body should be trivial.

**Acceptance criteria:**
- Move any validation logic out of the assert closure into a real `if` check that throws an `AppException` with a clear message.
- If the body is genuinely debug-only (e.g., logging), leave it but add a comment explaining why it's assert-guarded.

---

### m7. Duplicate font-size clamp constant

**Affected files:**
- `lib/main.dart:317` — `fontSize.clamp(10.0, 30.0)`
- `lib/features/settings/presentation/settings_screen.dart:476` — `fontSize.clamp(10.0, 30.0)`

**Rationale:** The min/max font sizes are architectural decisions that should be defined once.

**Acceptance criteria:**
- Add `static const double minFontSize = 10.0; static const double maxFontSize = 30.0;` to a shared location (e.g., `app_constants.dart` or a `ui_constants.dart`).
- Replace both clamp callsites.

---

### m8. Null-assert operator `!.` used extensively (235 matches)

**Context:** `git grep '\!.' lib/ | wc -l` yields ~235 matches across the codebase.

**Notable high-concentration files:**
- `lib/features/teaching/presentation/tutor_screen.dart` — `_manager!.`, `prereqResult.data!.`, etc.
- `lib/features/planner/presentation/planner_screen.dart` — `state.plan!.`, `state.data!.`
- `lib/features/practice/presentation/screens/practice_screen.dart` — `prereqResult.data!.`
- `lib/features/settings/data/repositories/settings_repository.dart:185,224` — `currentResult.data!.`

**Rationale:** Every `!.` is a potential runtime null-pointer crash in production. With 235 assertions, a single unexpected null causes an unrecoverable error.

**Acceptance criteria:**
- For every `data!` on a `Result`, replace with `data ?? fallback` or `switch (result) { ok: ..., err: ... }`.
- For every `late` field that is `!`-accessed, verify it's guaranteed initialized or add a null check.
- Track this as a backlog item with target: reduce `!.` count by 80% (from 235 to <50).

---

### m9. Repository init() boilerplate duplication

**Context:** Every repository class (20+) duplicates the same pattern:
```dart
Future<void> init() async {
  box = await Hive.openBox<ModelType>(BoxNames.someBox);
}
```

**Affected files:** All files in `lib/**/repositories/*.dart`.

**Rationale:** The base `Repository` class at `lib/core/data/repository.dart` already provides `save()`, `get()`, `delete()` etc., but `init()` is left to each subclass to implement identically.

**Acceptance criteria:**
- Add a `boxName` parameter to the `Repository` base class constructor and implement a single `init()` that opens the box by name.
- Remove `init()` overrides from all 20+ repos (they become zero-code subclasses).
- Verify no test relies on custom init logic that differs from the base class pattern.

---

### m10. Inline dialogs in `settings_screen.dart` — repeated pattern

**Context:** `lib/features/settings/presentation/settings_screen.dart` contains nearly identical `showDialog` + `ListView` + `ListTile` implementations for theme selection, font size, timeout duration, break duration, and more.

**Rationale:** ~50 lines of dialog boilerplate × 6 settings = ~300 lines of duplicated code that could be a single reusable `SettingsPickerDialog<T>` widget.

**Acceptance criteria:**
- Extract a generic `SettingsPickerDialog<T>` widget parameterized by title, option list, selected value, and `onSelected` callback.
- Replace all 6+ inline dialogs with the shared widget.
- Delete no-longer-needed dialog-building methods.

---

### m11. Changelogs and auto-improve reports committed to repo

**Context:**
- `.changelogs/` directory
- `.auto_improve_reports/` directory
- `changelogs/` directory

**Rationale:** These appear to be machine-generated files committed to version control. They bloat the repository and create noise in diffs.

**Acceptance criteria:**
- Add `.changelogs/`, `.auto_improve_reports/`, `changelogs/` to `.gitignore`.
- Delete the existing tracked files (after verifying nothing references them).

---

### m12. `lib/core/utils/sr_data_codec.dart` — test-only utility shipped in production bundle

**Affected file:** `lib/core/utils/sr_data_codec.dart:34`

**Context:** `SrDataCodec` is only referenced in test files (`test/features/practice/utils/sr_data_codec_test.dart`). It is shipped in the production binary but never called.

**Rationale:** Wasted bytes in the release APK/app bundle. More importantly, it may give the misleading impression that SR data serialization goes through this codec when it actually goes through Hive adapters.

**Acceptance criteria:**
- Move to `test/` directory (e.g., `test/helpers/sr_data_codec.dart`) if it's a test helper, or delete if it's unused entirely.
- Verify `git grep 'SrDataCodec' lib/` returns empty after removal.

---

### m13. `@visibleForTesting` underused — only 9 annotations

**Context:** Many internal methods are tested directly without `@visibleForTesting` annotation (e.g., `settings_repository` private helpers, `_buildSettingsBody`).

**Rationale:** Without `@visibleForTesting`, the analyzer permits importing private members from test code only via hacks (part files, etc.), or tests test the public API only. The low count suggests either: (a) testing is primarily end-to-end, or (b) internal methods are tested through public methods, which is fine, but the lack of annotation makes it hard to distinguish.

**Acceptance criteria:**
- Audit 10 largest files. For every private method that has a dedicated unit test, add `@visibleForTesting`.
- Add a lint rule or CI check warning when tests import private members without `@visibleForTesting`.

---

## DEPENDENCY / ARCHITECTURE CHART

```
                    ┌──────────────────────────┐
                    │    lib/core/              │
                    │  services/ constants/     │
                    │  errors/ utils/ widgets/  │
                    └────┬──────┬──────┬───────┘
                         │      │      │
          ┌──────────────┘      │      └──────────────┐
          ▼                     ▼                     ▼
┌───────────────────┐  ┌───────────────────┐  ┌───────────────────┐
│ Features/planner  │  │ Features/practice │  │ Features/settings  │
│  ┌────────────┐   │  │  ┌────────────┐   │  │  ┌────────────┐   │
│  │ services/  │───┼──┼─►│ data/      │   │  │  │ services/  │   │
│  │ planners/  │   │  │  │ repos/     │   │  │  │ repos/     │   │
│  └────────────┘   │  │  └────────────┘   │  │  └────────────┘   │
└───────────────────┘  └───────────────────┘  └───────────────────┘
         │                      │                      │
         │         VIOLATION    │                      │
         └──────────────────────┼──────────────────────┘
                                │
                                ▼
              ┌──────────────────────────────┐
              │  lib/core/services/          │◄──── imports feature repos!
              │  personal_learning_plan      │
              │  mastery_graph_service       │
              │  study_progress_tracker      │
              └──────────────────────────────┘
```

**Problem:** `core/services/` importing downwards into `features/` — violation of layered architecture.

---

## SUMMARY PRIORITY TABLE

| ID | Severity | Issue | Effort | Risk if unfixed |
|---|---|---|---|---|
| **B1** | BLOCKER | Empty catch blocks swallowing errors | Small | Undiagnosed crashes |
| **M1** | MAJOR | `toStringAsFixed()` i18n violation | Small | Broken UX for Spanish users |
| **M2** | MAJOR | Mixed error handling | Medium | Unhandled exceptions |
| **M3** | MAJOR | API keys in binary | Medium | Security leak |
| **M4** | MAJOR | Massive build methods | Large | Maintenance nightmare |
| **M5** | MAJOR | StudentIdService direct instantiation | Medium | Testing friction |
| **M6** | MAJOR | Cross-feature contamination | Large | Architecture rot |
| **M7** | MAJOR | Dead barrel files | Small | Misleading API surface |
| **M8** | MAJOR | Dead/inactive files | Small | Wasted maintenance |
| **M9** | MAJOR | Dead utility functions | Small | Dead code confusion |
| **M10** | MAJOR | Hardcoded Durations | Medium | Tuning impossible |
| **m1** | MINOR | Logger inconsistency | Small | Log filtering issues |
| **m2** | MINOR | Wrong log levels | Small | Log noise |
| **m3** | MINOR | Duplicate string normalization | Small | Tech debt |
| **m4** | MINOR | Magic numbers | Small | Readability |
| **m5** | MINOR | Duplicate Duration hours:1 | Small | Drift risk |
| **m6** | MINOR | Assert closure pattern | Small | Silent failures |
| **m7** | MINOR | Font clamp duplicated | Tiny | Consistency |
| **m8** | MINOR | 235 `!.` operators | Large | Crash risk |
| **m9** | MINOR | Repository init boilerplate | Medium | Boilerplate |
| **m10** | MINOR | Inline settings dialogs | Medium | Code duplication |
| **m11** | MINOR | Changelogs committed | Small | Repo bloat |
| **m12** | MINOR | Test utility in production | Tiny | Bundle size |
| **m13** | MINOR | `@visibleForTesting` underused | Small | Test hygiene |
