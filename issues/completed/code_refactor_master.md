# Code Refactoring & Quality Master Issue

**Generated:** 2026-05-17  
**Scope:** Full codebase audit — dead code, circular deps, SRP violations, inconsistent error handling, redundant abstractions, file placement, comments/logging, hardcoded values, repeated patterns.

---

## MAJOR Issues

### M1. Repository base class violates its own `Result` contract

`lib/core/data/repository.dart:4-5` declares "All repositories MUST wrap their public method return types in `Result`", but the base class itself returns raw types (`Future<void>`, `Future<T?>`, `Future<List<T>>`). Every downstream repository inherits this broken contract, meaning callers get raw data with no error channel.

**Affected files:**
- `lib/core/data/repository.dart:18,22,26` — base class `save/get/getAll` return raw types

**Rationale:** Violation of the project's own error handling convention. All repository calls silently swallow errors. Callers must add defensive try-catch (which many don't). This is the root cause of the inconsistent error handling pattern documented in M2.

**Acceptance criteria:**
- [ ] `Repository<T>.save()` returns `Future<Result<void>>`
- [ ] `Repository<T>.get()` returns `Future<Result<T?>>` or `Future<Result<T>>`
- [ ] `Repository<T>.getAll()` returns `Future<Result<List<T>>>`
- [ ] All 30+ downstream repositories update their overrides
- [ ] All callers updated to unwrap `Result` instead of raw try-catch
- [ ] `handlers.dart:214` fallback type changed from `ExceptionType.network` to `ExceptionType.unknown` for unrecognized errors

---

### M2. Pervasive inconsistent error handling — silent failures

The codebase mixes two error handling strategies inconsistently, often in the same file:

| Pattern | Count | Examples |
|---|---|---|
| `Result<T>` with `.isSuccess` / `.isFailure` | ~20% of services | `mastery_graph_service.dart`, `plan_adapter.dart` |
| Raw `try/catch` returning `null` / `[]` / `false` | ~80% of services | `mentor_service.dart:232-285`, `planner_service.dart:284-363`, `engagement_scheduler.dart:109-262` |
| Empty `catch (_) {}` | 3+ locations | `badge_service.dart:59`, `personal_learning_plan_service.dart:108` |
| Mixed in single method | `tutor_service.dart:116-195` | `endLesson()` uses both `isSuccess` checks and raw try-catch |

**Affected files:**
- `lib/features/mentor/services/mentor_service.dart:232-285` — 5 methods returning `[]` / `null` on error
- `lib/features/planner/services/planner_service.dart:284-363` — 8 methods returning `false` on error
- `lib/core/services/engagement_scheduler.dart:89-262` — 5 separate raw try-catch blocks
- `lib/core/services/study_progress_tracker.dart:221-274` — 4 raw try-catch swallowing with Logger
- `lib/core/services/badge_service.dart:59` — empty `catch (_) {}`
- `lib/core/services/plan_adapter.dart:212,262` — `catch (_) { return null; }`

**Rationale:** Silent failures propagate as plausible-looking empty results, making bugs invisible. If `sessionRepo.save()` silently fails in `tutor_service.dart:148`, the session is lost with no user feedback. The Result type was designed to prevent this but is widely ignored.

**Acceptance criteria:**
- [ ] Every `catch` block either returns a `Result.failure` or surfaces the error to the user
- [ ] No empty `catch (_) {}` blocks remain
- [ ] No method returns `null` / `[]` / `false` as the only error path from try-catch without logging the error appropriately (`.e()` not `.w()`)
- [ ] `tutor_service.dart:116-195` (`endLesson()`) refactored to use `Result` consistently
- [ ] `mentor_service.dart:232-285` unified into a single `Result<T>` async try-catch helper

---

### M3. Inverted dependencies — `core/services/` heavily imports `features/`

9 services in `core/services/` import from `features/` packages, creating an inverted dependency flow. The core layer should be feature-agnostic.

| Core Service | Imports from Features |
|---|---|
| `personal_learning_plan_service.dart` | `features/planner` (4 repos, 1 service, 2 models), `features/subjects` (1 repo, 1 model), `features/practice` (1 repo), `features/questions` (1 repo) |
| `mastery_graph_service.dart` | `features/practice` (5 repos, 2 models), `features/questions` (1 model) |
| `study_progress_tracker.dart` | `features/practice` (1 repo, 1 model), `features/sessions` (1 repo) |
| `badge_service.dart` | `features/dashboard` (1 repo, 1 model), `features/practice` (1 repo) |
| `engagement_scheduler.dart` | `features/planner` (2 repos, 1 model), `features/sessions` (1 repo) |
| `instrumentation_service.dart` | `features/practice` (1 repo, 2 models), `features/planner` (1 repo, 1 model) |
| `progress_export_service.dart` | `features/practice` (1 repo, 1 model), `features/sessions` (1 repo) |
| `cross_feature_integrator.dart` | `features/ingestion` (1 repo), `features/sessions` (1 repo) |
| `plan_adapter.dart` | `features/planner` (2 repos, 1 model) |
| `conversation_memory.dart` | `features/teaching` (1 model, 1 repo) |
| `data/database_service.dart` | `features/lessons`, `practice`, `questions`, `sessions`, `subjects`, `teaching` |

**Potential cycle risk:** `core/services/personal_learning_plan_service.dart` → `features/planner/services/syllabus_resolver.dart` → `features/planner/data/repositories/...` ← `core/services/plan_adapter.dart` ← `features/planner/services/planner_service.dart`. Core → Planner → Core is a runtime cycle.

**Rationale:** Core modules should not depend on feature modules. This makes the codebase rigid, hard to test in isolation, and vulnerable to circular dependency issues. It also means any change to a feature repo potentially requires recompiling the entire core layer.

**Acceptance criteria:**
- [ ] Models used across features (e.g. `mastery_state_model.dart`, `personal_learning_plan_model.dart`, `session_repository.dart`) are extracted to `lib/core/data/models/` or `lib/core/data/repositories/`
- [ ] Services that are fundamentally feature-specific (e.g. `plan_adapter.dart`, `conversation_memory.dart`) are moved into the relevant feature directory
- [ ] `core/services/personal_learning_plan_service.dart` refactored to depend on interfaces/abstract classes defined in core, with feature implementations injected via DI
- [ ] `core/services/` no longer contains any `import 'package:studyking/features/...'` statement
- [ ] `core/data/database_service.dart` uses service locator or DI rather than direct feature imports
- [ ] All feature-feature cross-imports documented in M4 are resolved

---

### M4. Feature-to-feature cross-imports

9+ features directly import from other features, creating tight coupling:

| Source Feature | Target Feature(s) |
|---|---|
| `mentor/` | `teaching`, `planner`, `sessions`, `practice` |
| `planner/` | `practice`, `subjects`, `sessions` |
| `ingestion/` | `questions`, `subjects` |
| `practice/` | `ingestion` |
| `settings/` | `ingestion`, `lessons`, `planner`, `practice`, `questions`, `subjects`, `teaching` |
| `sessions/` | `planner` |
| `focus_mode/` | `sessions`, `subjects` |
| `dashboard/` | `focus_mode` |

**Rationale:** Tightly coupled features cannot be developed, tested, or extracted independently. A change in `planner/` can break `mentor/`, `sessions/`, `settings/`, and `core/`.

**Acceptance criteria:**
- [ ] All feature-to-feature imports replaced with dependency on shared core interfaces or a cross-feature integration layer
- [ ] Feature barrel exports (`features/*/*.dart`) do not expose internal implementation details that encourage cross-feature coupling
- [ ] A `lib/features/bridges/` or `lib/core/integration/` directory created for legitimate cross-feature orchestration

---

### M5. `QuestionModel` in `core/data/models/` depends on `features/questions/`

`lib/core/data/models/question_model.dart:3` imports from `features/questions/data/models/markscheme_model.dart`. The `Question` model is shared across 4+ features and lives in core, but depends on a feature-specific model.

**Rationale:** Any change to `markscheme_model.dart` forces recompilation of all consumers of core models. The `Question` model should be self-contained.

**Acceptance criteria:**
- [ ] `MarkschemeModel` extracted to `lib/core/data/models/markscheme_model.dart` or inlined into `question_model.dart`
- [ ] `question_model.dart` has zero `features/` imports

---

## MINOR Issues

### m1. Duplicate `IdGenerator`

`lib/utils/id_generator.dart` and `lib/core/utils/id_generator.dart` are identical 12-line classes. Only one should exist.

**Affected files:**
- `lib/utils/id_generator.dart`
- `lib/core/utils/id_generator.dart`

**Acceptance criteria:**
- [ ] Delete `lib/utils/id_generator.dart` and update all callers to use `lib/core/utils/id_generator.dart`

---

### m2. Dead `typedef PromptTemplates` in production code

`lib/features/teaching/services/prompts/prompts.dart:122` defines `typedef PromptTemplates = ConversationPromptSet`. Only the test file references it.

**Affected files:**
- `lib/features/teaching/services/prompts/prompts.dart:122`
- `test/features/teaching/services/prompts/prompts_test.dart:541-549` (test-only usage)

**Acceptance criteria:**
- [ ] Remove the `typedef` from production code, keep only in test if needed, or remove entirely

---

### m3. `toStringAsFixed()` in user-facing display (violates AGENTS.md)

AGENTS.md explicitly forbids `toStringAsFixed()` for user-facing numeric displays. Violations found:

| File | Line | Code |
|---|---|---|
| `lib/features/settings/presentation/settings_screen.dart` | 184 | `ref.watch(llmUsageMeterProvider).getTotalCost().toStringAsFixed(4)` |
| `lib/features/settings/presentation/settings_screen.dart` | 709 | `'\$${totalCost.toStringAsFixed(4)}'` |

**Rationale:** `toStringAsFixed(4)` always uses a period decimal separator, which is incorrect for comma-decimal locales (Spanish, French, German). Should use `formatCurrency()` from `lib/core/utils/number_format_utils.dart`.

**Acceptance criteria:**
- [ ] Replace both `toStringAsFixed(4)` calls with `formatCurrency(totalCost, l10n.localeName)`
- [ ] `formatCurrency` updated if needed to support min/max fraction digits

---

### m4. `NotificationChannelIds` defined but never registered

`lib/core/constants/notification_channel_ids.dart` defines 9 channel IDs, but no matching Android notification channel initialization code is visible. On Android 8+, channels must be registered at app startup or notifications are silently suppressed.

**Affected files:**
- `lib/core/constants/notification_channel_ids.dart`
- `lib/main.dart` (should contain channel registration)

**Acceptance criteria:**
- [ ] All 9 channels registered in `main.dart` or a dedicated `NotificationInitializer`
- [ ] Channel descriptions localized
- [ ] Test: verify `flutterNotificationPlugin.getNotificationChannels()` returns expected channels

---

### m5. Hardcoded API URLs and secrets via compile-time env

`lib/core/constants/app_api_config.dart:56-69` hardcodes 6 API URLs. Secrets use `const String.fromEnvironment()` (compile-time) rather than runtime injection.

**Affected files:**
- `lib/core/constants/app_api_config.dart:56-60` (hardcoded URLs)
- `lib/core/constants/app_api_config.dart:69` (youtube base URL)
- `lib/core/constants/security_config.dart:22` (encryption key via compile-time env)

**Rationale:** Hardcoded URLs prevent runtime configuration (e.g. pointing to a staging server without rebuilding). Compile-time secrets are exposed in binary analysis.

**Acceptance criteria:**
- [ ] API URLs moved to `ApiConfig` constructor params (can be injected from anywhere)
- [ ] Secrets support runtime injection via `ApiSecrets.fromRuntime()` (already exists but not used by the DI graph)
- [ ] `TODO(security)` at line 30-31 either resolved or updated with a tracking issue link

---

### m6. 15+ magic numbers scattered across services

| Value | File | Line |
|---|---|---|
| `durationMinutes = 45` | `tutor_service.dart:56`, `tutor_screen.dart:34` |
| `durationMinutes = 30` | `mentor_service.dart:463,483` |
| `maxTurns = 30` vs `maxTurns = 50` | `conversation_manager.dart:67`, `mentor_service.dart:68` |
| `targetQuestionsPerDay = 15` | `planner_service.dart:108,136` |
| `questionsPerLesson = 8` | `remaining_workload_estimator.dart:50` |
| `masteryThreshold = 0.7`, `atRiskThreshold = 0.5` | `remaining_workload_estimator.dart:48-49` |
| `expectedTimeMs = 60000.0` | `mastery_calculation_service.dart:89` |
| Pricing constants: `0.000005`, `0.000006`, `0.0000024`, divisor `1000000` | `token_pricing_config.dart:8-11` |
| `maxWidth: 1024, maxHeight: 1024, imageQuality: 80` | `tutor_screen.dart:193-196` |
| `listenFor: 60s, pauseFor: 3s` | `voice_controller.dart:95-96` |

**Acceptance criteria:**
- [ ] Each magic number extracted to a named constant with a descriptive name
- [ ] Constants grouped by domain in `lib/core/constants/` or the relevant feature's constants file
- [ ] Inconsistencies resolved (e.g. `durationMinutes` — why 45 vs 30? why `maxTurns` 30 vs 50?)

---

### m7. Redundant `_calculateAdherenceScore` wrappers

Both `personal_learning_plan_service.dart:575-587` and `instrumentation_service.dart:127-139` define a private `_calculateAdherenceScore()` that simply delegates to the standalone `calculateAdherenceScore()` in `study_utils.dart`. These wrappers add zero value.

**Affected files:**
- `lib/core/services/personal_learning_plan_service.dart:575-587`
- `lib/core/services/instrumentation_service.dart:127-139`
- `lib/core/utils/study_utils.dart:22`

**Acceptance criteria:**
- [ ] Remove both wrapper methods
- [ ] Callers invoke `calculateAdherenceScore()` directly

---

### m8. CSV export logic duplicated 3× across services

Three separate implementations of CSV export with the same `StringBuffer.writeln` + comma-separated headers + data rows + mastery level mapping pattern:

- `lib/core/services/study_progress_tracker.dart:280-359`
- `lib/core/services/progress_export_service.dart:61-122`
- `lib/features/sessions/services/session_export_service.dart`

**Acceptance criteria:**
- [ ] Extract shared CSV building utility at `lib/core/utils/csv_exporter.dart`
- [ ] All three callers refactored to use the shared utility
- [ ] Mastery level → string mapping extracted to shared constant/enum extension

---

### m9. Mastery level → string mapping duplicated 3×

Same string mapping logic repeats in:

- `lib/core/services/study_progress_tracker.dart:252-258`
- `lib/core/services/progress_export_service.dart:83-89`
- `lib/features/dashboard/presentation/widgets/workload_card.dart:132-145`

**Acceptance criteria:**
- [ ] Extract `MasteryLevel.displayName(BuildContext)` or similar extension method
- [ ] All callers use the shared method

---

### m10. Complex functions violating SRP

Functions that do too many things and should be decomposed:

| Function | File | Lines | Responsibilities |
|---|---|---|---|
| `PersonalLearningPlanService._buildPlan()` | `personal_learning_plan_service.dart:94-225` | ~130 | Init repos, fetch mastery, fetch deps, identify gaps, fetch topics, build recommendations, resolve syllabus, generate daily plans, link questions, generate summary, construct model, persist — 7+ steps |
| `ContentPipeline.processFullPipeline()` | `content_pipeline.dart:85-226` | ~140 | 5 pipeline stages in one method |
| `TutorService.endLesson()` | `tutor_service.dart:116-195` | ~80 | Save session, record mastery, persist exercises, save Session, update scheduled session — 5 responsibilities |
| `MentorService._buildContextPrompt()` | `mentor_service.dart:103-201` | ~100 | Fetches 10+ data sources, formats into one prompt string |
| `MentorService.checkWellbeingAndGenerateNudges()` | `mentor_service.dart:339-414` | ~75 | 5 wellbeing checks |
| `PersonalLearningPlanService._generateDailyPlans()` | `personal_learning_plan_service.dart:589-709` | ~120 | Nested 4-level deep loop with async calls |
| `EngagementScheduler._sendNudgeNotifications()` | `engagement_scheduler.dart:89-191` | ~100 | 5 separate try-catch blocks each doing repo writes + notifications |
| `PlannerService.createRoadmap()` | `planner_service.dart:147-209` | ~62 | Syllabus resolution + milestone generation + save |
| `MasteryGraphService.recordAttempt()` | `mastery_graph_service.dart:41-86` | ~45 | Topic mastery + question mastery update in one method |
| `ConversationManager.sendMessage()` | `conversation_manager.dart:123-178` | ~55 | Phase transitions + streaming + exercise detection |

**Acceptance criteria:**
- [ ] Each complex function is ≤ 30 lines of logic (excluding blank lines, braces, and comments)
- [ ] Each distinct responsibility extracted into a named private method with a single purpose
- [ ] No method has more than 2 levels of nesting (excluding trivial `if` guards)

---

### m11. `FakePlannerService` and `FakeMasteryGraphService` use `dynamic` return types

`test/helpers/fakes.dart:397,400,406,420,422` — `FakePlannerService` methods return `dynamic` or `List<dynamic>`. `FakeMasteryGraphService` lines 431, 437 return `Future<List<dynamic>>`.

**Rationale:** Using `dynamic` bypasses type safety in tests. If the real service changes its return type, the fake won't catch mismatches at compile time.

**Acceptance criteria:**
- [ ] All fake methods return properly typed values matching their real counterparts
- [ ] Tests using these fakes still compile and pass

---

### m12. `export 'conversation_phase.dart'` inside non-barrel file

`lib/features/teaching/services/conversation_manager.dart:15` has `export 'conversation_phase.dart'`. This is atypical — barrel exports belong in barrel files (like `conversation_manager.dart`'s containing folder's barrel). The same file imports from both relative (`../../../core/`) and absolute (`package:studyking/...`) paths — inconsistent import style.

**Affected files:**
- `lib/features/teaching/services/conversation_manager.dart:15`

**Acceptance criteria:**
- [ ] Remove `export` from non-barrel file
- [ ] Add `conversation_phase.dart` to the appropriate barrel export
- [ ] Normalize all imports to use `package:` references consistently

---

### m13. `lookupAppLocalizations()` called repeatedly with `const Locale('en')`

`lookupAppLocalizations(const Locale('en'))` is called in 7+ files to get English localizations. This bypasses the user's actual locale.

**Affected files:** `exercise_evaluator.dart`, `mentor_service.dart`, `prompts.dart`, `content_pipeline.dart`, `time_utils.dart`, `llm_chat_service.dart`, `engagement_scheduler.dart`

**Rationale:** These calls always get English regardless of user setting. While LLM-facing strings can safely default to English, the pattern should be explicit (e.g. `AppLocalizationsEn()`) or injected rather than using `lookupAppLocalizations` which is meant for runtime locale resolution.

**Acceptance criteria:**
- [ ] All LLM-facing English string lookups use `AppLocalizationsEn()` directly (no `lookupAppLocalizations`)
- [ ] Any user-facing strings use the properly injected locale

---

### m14. `handlers.dart` has unused import

`lib/core/errors/handlers.dart:4` imports `app_localizations_en.dart` but the class is unused — `_defaultL10n` is the only reference and it constructs `AppLocalizationsEn()` from the generated package, not the import.

**Affected files:**
- `lib/core/errors/handlers.dart:4`

**Acceptance criteria:**
- [ ] Remove the unused import

---

### Summary Statistics

| Category | Count |
|---|---|
| BLOCKER | 0 |
| MAJOR | 5 (M1–M5) |
| MINOR | 14 (m1–m14) |
| **Total** | **19 findings** |

**Overall approach:**
1. Fix MAJOR items first — they represent architectural debt and silent data loss risks
2. Within MAJOR, start with M1 (Repository contract) since fixing it unblocks M2 (error handling consistency)
3. M3 and M4 (inverted deps + feature coupling) require architectural decision on shared model placement
4. M5 is a quick fix that removes a dependency edge
5. MINOR items can be parallelized across the team
