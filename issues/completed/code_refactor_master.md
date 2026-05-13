# Architecture Fragmentation & Service Duplication

## Context

The codebase has grown organically with at least two architectural paradigms coexisting:
- An older **flat / top-level** layout (`lib/models/`, `lib/services/`, `lib/pages/`)
- A newer **feature-first** layout (`lib/features/{subjects,settings,questions,practice,...}/`)

This has produced duplicate services, model classes, and UI screens that perform nearly identical work but live in separate locations — leading to hardcoded configuration being scattered across the codebase, dead code, excessive debug logging, and confusion about where new code should be placed.

---

## Affected Areas

### 1. Dual Model Locations (Confusion + Duplication Risk)

| Location | Purpose |
|---|---|
| `lib/core/data/models/` (14 models) | Core domain models |
| `lib/models/` (5 files) | Mixed: LLM config, settings, dynamic lesson types |

`lib/models/` is neither purely feature-specific nor purely core — `llm_config.dart` (285 lines), `settings_model.dart` (206 lines), and `dynamic_lesson_types.dart` overlap with functionality that belongs in `lib/features/settings/` or `lib/core/data/models/` respectively.

**Action:** Migrate `lib/models/` files into appropriate feature or core locations.

### 2. Triple LLM Service Implementation

Three separate LLM HTTP clients exist, each with slightly different responsibility but significant overlap:

| File | Lines | HTTP lib | Responsibility |
|---|---|---|---|
| `lib/core/services/llm_service.dart` | 526 | `http` | Full OpenRouter + Ollama client |
| `lib/services/llm_api_service.dart` | 219 | `dio` | OpenRouter client with pricing |
| `lib/core/services/ai_model_service.dart` | ~80 | `http` | OpenRouter model listing |

**All three hardcode the OpenRouter base URL** instead of consuming the constant defined in `lib/core/constants/app_api_config.dart:24`.

`llm_service.dart` also mixes chat completion, embedding, and model listing responsibilities (526 lines) — violating the Single Responsibility Principle.

**Action:** Consolidate into one LLM service in `lib/core/services/`. Split by responsibility (chat, embedding, model listing) instead of by HTTP library.

### 3. Hardcoded OpenRouter URL (9+ Locations)

The URL `https://openrouter.ai/api/v1` is defined once in `app_api_config.dart` but hardcoded again in:

- `lib/main.dart:49` — raw string in LLM config creation
- `lib/features/settings/data/models/settings_box.dart:43,85`
- `lib/features/settings/data/repositories/settings_repository.dart:101`
- `lib/core/services/llm_service.dart:39,234`
- `lib/services/llm_api_service.dart:12`
- `lib/core/services/ai_model_service.dart:7`
- `lib/services/pdf_ingestion_service.dart:95`

**Action:** All consumers should reference `ApiConfig.openRouterBaseUrl` from the singleton `AppConstants.instance`.

### 4. Placeholder / Inconsistent Referer Header

Different files send different `HTTP-Referer` headers:

| File | Value |
|---|---|
| `lib/services/llm_api_service.dart` | `'https://yourapp.com'` (placeholder) |
| `lib/core/services/ai_model_service.dart` | `'https://studyking.app'` (hardcoded) |
| `lib/core/services/llm_service.dart` | missing entirely |

**Action:** Derive the Referer from a single configurable source (e.g., `BuildConfig.appName` or an env var).

### 5. Inappropriate Logging (81 debugPrint Calls Across 23 Files)

`debugPrint` is used for errors, warnings, info, and debug messages with no log-level distinction. Notable hotspots:

| File | Count | Issue |
|---|---|---|
| `lib/core/data/repositories/mastery_graph_repository.dart` | 17 | Most could be `debugPrint` or removed |
| `lib/core/data/repositories/question_repository.dart` | 10 | Mixed: valid debugging + noise |
| `lib/core/data/hive_initializer.dart:42` | 1 | `'Hive initialized successfully'` — low-value log in production |
| `lib/main.dart` | 11 | Startup logs, some redundant |

There is no `Logger` abstraction, no log levels (info/warn/error/debug), and no way to control verbosity per environment.

**Action:** Introduce a lightweight logger (e.g., `package:logging` or a thin wrapper) with levels, and replace all `debugPrint` calls.

### 6. Dead Code & Placeholder Files

| File | Lines | Status |
|---|---|---|
| `lib/core/services/question_generation_service.dart` | **Potentially shadowed** by `lib/services/question_engine.dart` and `lib/services/question_engine_dynamic.dart` |
| `lib/services/question_engine.dart:216-222` | Comment says `// TODO: Remove if unused - development test helper` |
| `lib/pdf_ingestion_placeholder.dart` | Entire file is a placeholder |
| `lib/pages/settings/llm_applcation_page.dart` | Typo in filename ("applcation") + `// TODO: P3-2 Implement file open dialog` at line 158 |
| `lib/services/batch_processor_service.dart:184` | `// TODO: Implement actual context window fetching` |

**Action:** Audit and remove dead code. Rename typo file.

### 7. Outdated / Orphaned Pages

`lib/pages/` contains screens that duplicate feature-based screens:

| Old Location | Duplicate In |
|---|---|
| `lib/pages/graph_rendering_page.dart` (505 lines) | (no clear feature home — orphaned) |
| `lib/pages/lesson_scheduling_page.dart` | `lib/features/lessons/presentation/` |
| `lib/pages/pdf_ingestion_page.dart` | `lib/features/...` (likely) |
| `lib/pages/settings/llm_settings_screen.dart` | `lib/features/settings/presentation/` |

**Action:** Migrate `lib/pages/` content into appropriate feature directories and remove the old layout.

---

## Rationale

- **Developer Onboarding:** A new contributor cannot tell from the directory structure where to add a screen, service, or model. This slows down every future change.
- **Bug Risk:** The Hive typeId collision (both `_typeIdSettingsBox` and `_typeIdSourceModel` at `4` in `hive_type_ids.dart:7-8`) — though technically a bug — is a symptom of poor architectural boundaries. Without consolidation, similar collisions will recur.
- **Maintenance Overhead:** Every URL change requires touching 9+ files. Every LLM API change requires updating 3 services. This is unsustainable.
- **Testing Difficulty:** Duplicate services make it unclear which implementation is "canonical," so tests either cover the wrong one or none at all.
- **Production Risk:** Placeholder URLs (`yourapp.com`) could ship to production if missed during code review.

---

## Acceptance Criteria

- [ ] `lib/models/` is migrated into either `lib/core/data/models/` or appropriate `lib/features/*/models/`
- [ ] A single canonical LLM service exists in `lib/core/services/` (the other two are removed)
  - Responsibilities are split into separate classes (chat, embedding, model listing) within the same service directory
- [ ] The OpenRouter base URL is referenced from `ApiConfig.openRouterBaseUrl` in all consumers — zero hardcoded URL strings remain
- [ ] `HTTP-Referer` header is derived from a single configurable source
- [ ] A lightweight logger (with levels: debug, info, warn, error) replaces all `debugPrint` calls — legacy `debugPrint` count is 0
- [ ] Placeholder files (`pdf_ingestion_placeholder.dart`, dead helpers, TODO-commented code) are removed
- [ ] `lib/pages/` content is migrated into `lib/features/*/presentation/` and `lib/pages/` directory is removed
- [ ] The typo file `llm_applcation_page.dart` is renamed to `llm_application_page.dart`
- [ ] All existing tests pass and no regressions in the consolidated services
