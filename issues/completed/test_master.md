# Test Coverage Gaps & Structural Disorganization

## Context

The codebase has strong overall test coverage (~97% of source files have a matching test), but several areas fall short of the quality and convention standards set by the `subjects` feature — the gold standard reference. Three categories of issues exist: **missing test coverage** for critical service files, **orphan/duplicate test files** that violate the one-source-file convention, and **overly thin provider tests** that only verify creation.

### Category 1: Missing Test Coverage (CRITICAL)

Four source files have zero test coverage:

| Source File | Lines | Risk Level | Reason |
|---|---|---|---|
| `lib/features/ingestion/services/web_scraper.dart` | 96 | **CRITICAL** | Network I/O, HTTP error handling (5xx, 4xx), URL validation, HTML stripping with `<script>`/`<style>` removal, empty content detection. Non-trivial branching logic in `_extractMainText` and `_stripTags`. |
| `lib/features/teaching/services/prompts/prompts.dart` | 133 | **HIGH** | Prompt generation logic with `switch` on `ConversationPhase` (6 branches), `adaptivePace` threshold logic (3 branches), string interpolation with `durationMinutes`, `confidenceRating`. Template strings can silently produce malformed output. |
| `lib/features/ingestion/services/document_extractor.dart` | 29 | **MEDIUM** | `estimateChunkCount` has edge case at `text.isEmpty` (returns 0) and division/`ceil` boundary at `chunkSize` multiples. `extractText` has branching per `SourceType`. |
| `lib/features/teaching/providers/teaching_providers.dart` | 26 | **MEDIUM** | Provides `tutorServiceProvider`, `teachingModelIdProvider`, `promptTemplatesProvider`. Every other feature tests its providers — this is a consistency gap. `teachingModelIdProvider` has fallback logic (use `selectedModelProvider`, then `defaultModelForProvider`). |

### Category 2: Structural Disorganization — Settings Data Models (HIGH)

The `settings/data/models/` directory has 8 source files but its 6 test files include 2 orphans that don't map to a single source, plus significant **test duplication**:

| Test File | Lines | Issue |
|---|---|---|
| `models_test.dart` | 268 | **Duplicate + orphan.** Tests `SettingsBox` (duplicating `settings_box_test.dart`), `UserProfile` (duplicating `user_profile_model_test.dart`), `SettingsBoxAdapter`, and `UserProfileAdapter`. Tests are also mixed: includes a `testWidgets` call (line 252) for a ThemeMode widget check that belongs in a widget test file. |
| `model_edge_cases_test.dart` | 324 | **Orphan.** Tests `SettingsBox.fromJson` type coercion and Hive adapter binary I/O edge cases. Should be split into `settings_box_test.dart`, `accessibility_preferences_test.dart`, and adapter-specific test files. Despite the volume, edge cases for `SettingsAPIKey`, `UsageRecord`, `LLMSettingsModel`, and `DynamicModel` are absent. |

**Duplication overlap**: `settings_box_test.dart` (170 lines) and `models_test.dart` (268 lines) both test `SettingsBox` constructor defaults, JSON round-trip, theme mode, `toString`. `user_profile_model_test.dart` (187 lines) and `models_test.dart` both test `UserProfile` JSON and `copyWith`. This creates maintenance burden — updating model fields requires touching multiple files.

**Additional structural violations**:
- `test/features/settings/presentation/provider_wiring_test.dart` (81 lines) tests `core/providers/llm_providers.dart` and `core/providers/app_providers.dart` — it is literally in the wrong feature directory.
- `test/features/settings/data/repositories/settings_repository_hive_test.dart` (251 lines) is a Hive integration test companion to `settings_repository_test.dart`. While it adds value, it should be merged into the main test file via shared helpers (which already exist: `settings_repository_test_helper.dart`).

### Category 3: Overly Thin Provider Tests (MEDIUM)

Several provider test files only verify creation (that the provider returns the correct type) and do not test any behavioral/logic scenarios:

| Test File | Lines | What's Missing |
|---|---|---|
| `test/features/subjects/providers/topic_repository_provider_test.dart` | 23 | Only checks `TopicRepository` type and singleton identity. No overrides, no error injection, no interaction with dependent providers. |
| `test/features/dashboard/providers/dashboard_providers_test.dart` | 65 | Only checks creation of 5 providers. No tests for override propagation, error states, or provider family parameterization. |
| `test/features/practice/providers/practice_providers_test.dart` | 74 | Only checks creation of 6 providers. No tests for `practiceDataServiceProvider` depending on both `spacedRepetitionServiceProvider` and `sessionRepositoryProvider`. |
| `test/features/sessions/providers/session_providers_test.dart` | 48 | Only checks creation of 2 providers. No tests for provider interactions or state changes. |
| `test/features/mentor/providers/mentor_providers_test.dart` | 46 | Only checks creation of 1 provider. |

Compare to the gold standard: `test/features/lessons/providers/lesson_providers_test.dart` (437 lines) tests error propagation, all provider family scenarios, and override behavior.

## Affected Files

### Missing tests (need NEW test files):
- `lib/features/ingestion/services/web_scraper.dart` → `test/features/ingestion/services/web_scraper_test.dart`
- `lib/features/ingestion/services/document_extractor.dart` → `test/features/ingestion/services/document_extractor_test.dart`
- `lib/features/teaching/services/prompts/prompts.dart` → `test/features/teaching/services/prompts/prompts_test.dart`
- `lib/features/teaching/providers/teaching_providers.dart` → `test/features/teaching/providers/teaching_providers_test.dart`

### Structural rework needed (settings):
- `test/features/settings/data/models/models_test.dart` — delete once duplicated scenarios are consolidated into dedicated test files
- `test/features/settings/data/models/model_edge_cases_test.dart` — absorb into `settings_box_test.dart`, `accessibility_preferences_test.dart`, and new adapter test files
- `test/features/settings/presentation/provider_wiring_test.dart` — move to `test/core/providers/` (or delete and absorb into a new core provider test)
- `test/features/settings/data/repositories/settings_repository_hive_test.dart` — merge into `settings_repository_test.dart`
- New file: `test/features/settings/data/models/llm_models_edge_cases_test.dart` — currently no test covers `DynamicModel.getBestPrice` with empty vs single vs multiple prices, `calculateCost` with zero tokens, or `OpenRouterRequest.toJson` serialization defaults for temperature/maxTokens/topP.

### Expand existing tests:
- `test/features/subjects/providers/topic_repository_provider_test.dart` — add error handling, override tests
- `test/features/dashboard/providers/dashboard_providers_test.dart` — add override propagation and interaction tests
- `test/features/practice/providers/practice_providers_test.dart` — add dependency wiring tests between services
- `test/features/subjects/data/repositories/progress_repository_test.dart` — add edge cases: zero-time `recordAttempt`, negative `timeSpentMs`, division by zero in `averageTimeMs` calculation on first attempt, concurrent `recordAttempt` calls

## Rationale

1. **`web_scraper.dart`** involves real network I/O and has 5+ distinct failure paths (invalid URL, HTTP 4xx/5xx, empty body, unparseable HTML, exception during fetch). Without tests, regressions in error handling will go undetected. The `_extractMainText` method has a state machine for script/style tag removal that is non-trivial.

2. **`prompts/prompts.dart`** is the teaching feature's prompt generation engine. A malformed prompt string (e.g., mismatched braces, missing interpolations) silently produces bad LLM output, wasting tokens and confusing students. The `_defaultTutorPrompt` function has a `switch` on `ConversationPhase` with 7 branches and a `switch` on `adaptivePace` with 3 branches — each should be tested independently.

3. **Settings model tests** have the worst structural health in the project. `models_test.dart` duplicates `settings_box_test.dart` and `user_profile_model_test.dart` for no reason — these were likely created before the convention solidified and never cleaned up. The `model_edge_cases_test.dart` file is well-written but placed in the wrong files. Fixing this reduces maintenance surface and aligns with AGENTS.md.

4. **Thin provider tests** create a false sense of security. A test that only checks `container.read(provider) isA<Foo>()` passes even if the provider is completely miswired, as long as the type is correct. The `lessons/providers/lesson_providers_test.dart` shows what proper provider tests look like — testing override propagation, error states, and parameterization.

5. **`progress_repository_test.dart`** (93 lines) is the thinnest repository test in the subjects area. The `averageTimeMs` calculation has an integer arithmetic edge case on the first record: `(averageTimeMs * 0 + timeSpentMs) / 1` happens to work, but if `questionsAnswered` starts at 0 instead of 1, a division-by-zero crash occurs. This should be explicitly tested.

## Acceptance Criteria

1. **New test files exist for**:
   - `web_scraper_test.dart` covering: URL validation (no scheme, bad URL), all HTTP status code paths (200, 4xx, 5xx), empty body, HTML with script/style tags, HTML without content lines >20 chars, exception during fetch, `dispose` closes client.
   - `document_extractor_test.dart` covering: each `SourceType` branch in `extractText`, `estimateChunkCount` with empty string, exact chunk boundary, partial chunk, single character.
   - `prompts/prompts_test.dart` covering: each `ConversationPhase` in `_defaultTutorPrompt`, each `adaptivePace` threshold (<0.8, >1.2, in-between), all interpolation parameters rendered correctly in `_defaultLessonPlanPrompt`, `_defaultSummaryPrompt`, `_defaultTutorPrompt`.
   - `teaching_providers_test.dart` covering: `teachingModelIdProvider` fallback chain, `tutorServiceProvider` creation with proper dependencies, `promptTemplatesProvider` returns default templates.

2. **Settings model test files are reorganized**:
   - `models_test.dart` and `model_edge_cases_test.dart` are removed.
   - Their unique test scenarios (not duplicated in dedicated test files) are absorbed into `settings_box_test.dart`, `accessibility_preferences_test.dart`, `user_profile_model_test.dart`, `llm_models_test.dart`, and `settings_model_test.dart`.
   - The Hive adapter tests from `models_test.dart` are moved to a new `test/features/settings/data/adapters/settings_box_adapter_test.dart` and `test/features/settings/data/adapters/user_profile_adapter_test.dart`, following the convention used by `subjects/data/adapters/topic_dependency_adapter_test.dart` (658 lines, excellent coverage).
   - `model_edge_cases_test.dart`'s `SettingsBox.fromJson` type coercion tests go into `settings_box_test.dart`; its Hive binary I/O edge cases go into the new adapter test files.
   - `provider_wiring_test.dart` is moved to `test/core/providers/llm_providers_test.dart` or the test scenarios are integrated into the existing `test/core/providers/` area.
   - `settings_repository_hive_test.dart` is merged into `settings_repository_test.dart` using the existing `settings_repository_test_helper.dart` (which already provides `sharedSettingsRepositoryTests`), removing the need for a separate Hive integration file.

3. **Thin provider tests are expanded**:
   - `topic_repository_provider_test.dart` gains at minimum: override test (inject fake box, verify reads work), error propagation test (verify provider throws on closed box).
   - `dashboard_providers_test.dart` gains at minimum: override propagation test for at least 2 providers, error state test.
   - `practice_providers_test.dart` gains at minimum: dependency wiring test verifying `practiceDataServiceProvider` depends on both `spacedRepetitionServiceProvider` and `sessionRepositoryProvider`.

4. **`progress_repository_test.dart` gains edge case coverage**:
   - `recordAttempt` with `timeSpentMs: 0` and `timeSpentMs: -1` (boundary/negative values).
   - `averageTimeMs` calculation verified on first, second, and third sequential attempts.
   - Concurrent `recordAttempt` calls (two `await` in parallel via `Future.wait`) do not corrupt `questionsAnswered` or `averageTimeMs`.
