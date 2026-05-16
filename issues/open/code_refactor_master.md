# Refactor: Standardize Feature Directory Structure & Eliminate Dead Code

## Context

The codebase has drifted from its own conventions for feature directory layout. Features like `llm_tasks`, `questions`, `quickguide`, and `focus_mode` are missing standard subdirectories (`services/`, `data/`, `providers/`) that other features have. Additionally, several files contain dead code, redundant wrappers, or misplaced responsibilities that increase maintenance burden.

## Affected Areas

| Area | File(s) | Issue |
|---|---|---|
| **Incomplete feature layouts** | `lib/features/llm_tasks/`, `lib/features/questions/`, `lib/features/quickguide/`, `lib/features/focus_mode/` | Missing `services/` and/or `data/` directories that stable features (dashboard, subjects, teaching) all follow |
| **Dead code: formatCurrency** | `lib/core/utils/number_format_utils.dart:44-60` | Zero callers in the codebase — likely superseded by locale-aware formatting or never adopted |
| **Single-constant file** | `lib/core/constants/bottom_sheet_constants.dart` | Contains only `bottomSheetShape`; inflates the constants directory with negligible value. Merge into `app_runtime_config.dart` or theme |
| **Redundant localization wrapper** | `lib/core/services/localization_service.dart` (213 lines) | Thin delegation layer over `AppLocalizations` — every new translation string requires a boilerplate method here. Consumers could use `AppLocalizations` directly |
| **Dead code: Result.hasError** | `lib/core/errors/result.dart:12` | `hasError` getter is semantically identical to `isFailure` (both check `error != null`) yet differs from a consumer's perspective; never referenced outside the file |
| **Duplicated error-handling paths** | `lib/core/errors/handlers.dart` | `handleError` (async) and `handleSyncError` (sync) share ~80% identical logic (`_logError` + `_convertToAppException` + `_showErrorUI` / snackbar). Could be unified |
| **Incomplete barrel coverage** | `lib/core/utils/utils.dart` | Only re-exports 2 of 7 util files (`time_utils.dart`, `color_utils.dart`), while `core.dart` does not re-export utils at all. Consumers must import individual paths |
| **Theme depends on service type** | `lib/core/theme/app_theme.dart` | Imports `core/services/llm_task_manager.dart` solely for the `LlmTaskStatus` enum used in `statusColor()`. Violates dependency direction — theme should not depend on a service module |
| **Config mixed with UI widgets** | `lib/core/config/locale_config.dart:33-45` | `buildDropdownItems()` constructs Material `DropdownMenuItem` widgets inside a config enum. Config-layer code should not reference Flutter widgets |
| **Hardcoded model defaults** | `lib/core/providers/app_providers.dart:224-233` | `defaultModelForProvider()` has hardcoded model strings that will become stale as OpenRouter models evolve |

## Rationale

- **Maintainability**: Every new contributor must learn which subdirectories a feature needs. Incomplete structures force ad-hoc placement (e.g. logic dumped in `presentation/`) and make test mirroring (`test/features/*/`) harder.
- **Cognitive load**: Dead code (`formatCurrency`, `hasError`), single-constant files, and redundant wrappers (`LocalizationService`) make the codebase larger than necessary and confuse readers.
- **Dependency hygiene**: `app_theme.dart` importing a service file and `locale_config.dart` returning `DropdownMenuItem`s conflates architectural layers and makes testing/refactoring harder.
- **Consistency**: After this sweep, every feature and every core subdirectory follows a predictable, documented pattern.

## Acceptance Criteria

1. Every feature in `lib/features/*/` has at least the same subdirectory shape as `dashboard` or `subjects`:
   - `data/models/` (if domain models exist)
   - `data/repositories/` (if data persistence exists)
   - `providers/` (if Riverpod state exists)
   - `services/` (if business logic exists)
   - `presentation/` and `presentation/widgets/` (if screens/widgets exist)
2. Files with zero callers across the codebase are removed:
   - `formatCurrency()` in `number_format_utils.dart` (dead export confirmed via `grep -rn` — zero usages)
   - `bottom_sheet_constants.dart` (constant merged into existing config/theme)
3. `localization_service.dart` is collapsed: either inlined at call sites or replaced by direct `AppLocalizations.of(context)` usage.
4. `utils.dart` is either removed (consumers import directly) or expanded to export all 7 utility files.
5. `locale_config.dart` no longer returns Flutter widgets — `buildDropdownItems` moves to a UI helper or the settings screen.
6. `app_theme.dart` decouples from `llm_task_manager.dart`: introduce a standalone status enum or a color mapping function in `core/theme/`.
7. All `toStringAsFixed()` calls in user-facing display paths (not CSV/prompt-only paths) are replaced with locale-aware helpers per AGENTS.md.
8. All tests continue to pass and no regressions are introduced.
