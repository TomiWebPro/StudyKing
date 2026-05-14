# Refactor: Mitigate God Widgets, Production-Blocking Error Logging, and Feature Structure Inconsistencies

## Context

Several screens in the codebase have grown into monolithic widgets exceeding 600–1000+ lines, violating the Single Responsibility Principle. These screens mix data loading, state management, widget building, navigation, and export logic into single files. Additionally, critical production issues (error logs guarded by `kDebugMode`) and inconsistent feature directory structures reduce maintainability and reliability.

## Affected Files

### God Widgets / SRP Violations

| File | Lines | Issue |
|------|-------|-------|
| `lib/features/practice/presentation/practice_screen.dart` | 1029 | Contains 2 private inner widget classes (`_PracticeModeCard`, `_PracticeModeOption`). Mixes data fetching, navigation, state, and UI. |
| `lib/features/practice/presentation/practice_session_screen.dart` | 718 | Contains 2 export-only helper classes (`PracticeAnswerRecord`, `PracticeSessionResult`). Mixes timer logic, session persistence, answer validation, and UI. |
| `lib/features/dashboard/presentation/dashboard_screen.dart` | 699 | Mixes service init, data loading (6 sources), CSV export, navigation, and 12+ `_build*` widget methods. |
| `lib/features/quickguide/presentation/quick_guide_screen.dart` | 678 | Large single-file screen with embedded data and UI logic. |
| `lib/features/subjects/presentation/subject_detail_view.dart` | 748 | Excessive length for a detail view. |

### Production-Blocking Anti-Pattern

| File | Lines | Issue |
|------|-------|-------|
| `lib/core/errors/handlers.dart` | 224–226 | `_logError` wraps `_logger.e(...)` in `if (kDebugMode)` — production error logs are **silently discarded**, making production debugging impossible. |

### Non-Localized Hardcoded Strings

| File | Lines | Issue |
|------|-------|-------|
| `lib/core/services/answer_validation_service.dart` | 57, 92, 96–97, 131, 133, 135, 186–216, 261–273 | 20+ hardcoded English strings (`'Correct!'`, `'Incorrect.'`, `'No markscheme available'`, step feedback messages) bypass the l10n system. |
| `lib/core/errors/handlers.dart` | 242–294 | Hardcoded English error messages (`'Network request failed'`, `'Invalid API key or credentials'`, etc.) returned via `AppException.message` without localization. |

### Feature Structure Inconsistency

Many features lack conventional subdirectories (`providers/`, `services/`, `data/`, `models/`), leading to business logic leaking into presentation code:

- `lib/features/dashboard/` — only `presentation/`, no `services/`, `providers/`, `data/`, `widgets/`
- `lib/features/lessons/` — only `presentation/`
- `lib/features/planner/` — only `presentation/`
- `lib/features/quickguide/` — only `presentation/`
- `lib/features/llm_tasks/` — only `presentation/`

## Rationale

1. **God widgets** directly hinder onboarding, testing, and future changes. A single 1029-line file cannot be meaningfully unit-tested. Developers must understand the entire file to make any change, increasing merge conflicts and regressions. Each `_build*` method that accesses `setState` or `context` is tightly coupled to the parent widget, preventing reuse.

2. **Error logging behind `kDebugMode`** is a critical reliability issue. Production crashes, API failures, and data inconsistencies become invisible. This single guard makes the entire error handling layer unreliable for diagnosing production issues.

3. **Hardcoded strings** create an internationalization debt that grows with every new feature. Having some strings go through `AppLocalizations` and others bypass it creates an inconsistent user experience for non-English users.

4. **Missing feature directory structure** means there is no natural home for repositories, providers, or widget tests. Components that logically belong to a feature (e.g., a `DashboardMetricCard` widget) instead live in `core/widgets/` or are inlined, eroding the feature-boundary design.

## Acceptance Criteria

### A. God Widget Decomposition
- [ ] `lib/features/practice/presentation/practice_screen.dart` is split into at most 400 lines per file:
  - Extract `_PracticeModeCard` to `lib/features/practice/presentation/widgets/practice_mode_card.dart`
  - Extract `_PracticeModeOption` to `lib/features/practice/presentation/widgets/practice_mode_option.dart`
  - Extract a presenter/service for the data-loading logic
- [ ] `lib/features/dashboard/presentation/dashboard_screen.dart` is split:
  - Extract sections into standalone widgets under `lib/features/dashboard/presentation/widgets/` (e.g., `mastery_progress_card.dart`, `weak_areas_card.dart`, `export_section.dart`)
  - Move all service instantiation out of `initState` (use dependency injection already available via Riverpod)
  - `/lib/features/dashboard/` gains the standard subdirectories (`services/`, `widgets/`, `providers/`)
- [ ] `lib/features/practice/presentation/practice_session_screen.dart` is split:
  - Extract `PracticeAnswerRecord` and `PracticeSessionResult` into a separate `models/` file
  - Extract timer and session persistence logic into a dedicated service/provider

### B. Production Logging Fix
- [ ] `lib/core/errors/handlers.dart:224` — remove `kDebugMode` guard from `_logError`, or demote it to a `kDebugMode` guard on verbose logging only — error-level logs (`_logger.e`) must always fire.

### C. Localization Compliance
- [ ] All hardcoded English strings in `lib/core/services/answer_validation_service.dart` are replaced with `AppLocalizations.of(context)` calls or pass-through `String` parameters
- [ ] All hardcoded error messages in `lib/core/errors/handlers.dart` are routed through the l10n system or defined as constants in a single locale-bundled file

### D. Feature Structure Standardization
- [ ] `lib/features/dashboard/` follows the established convention with `widgets/`, `services/`, `providers/` subdirectories
- [ ] Every feature's barrel file (`feature_name.dart`) exports all public symbols from its subdirectories (not just presentation screens)
