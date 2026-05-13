# Issue: Data Layer Fragmentation — Duplicate Profile Models, Inconsistent File Placement, and Missing Domain Abstractions

## Context

The codebase follows a feature-based architecture but lacks consistent enforcement of its conventions. An audit of `lib/features/settings/data/models/` and neighboring feature directories uncovered fragmentation across the data layer: duplicate Hive types representing the same concept (`ProfileData` vs `UserProfile`), non-uniform directory layouts across features, mutable models mixing business logic with serialization, and deep cross-feature imports from `main.dart` — all of which erode maintainability and increase the risk of data corruption bugs.

## Affected Files

| File | Issue |
|------|-------|
| `lib/features/settings/data/models/settings_box.dart` (L126-195) | Defines `ProfileData` (Hive typeId: 5) — a profile model partially overlapping with `UserProfile` |
| `lib/features/settings/data/models/user_profile_model.dart` (L1-99) | Defines `UserProfile` (Hive typeId: 10) — same domain concept as `ProfileData`, different Hive type, different fields |
| `lib/features/subjects/models/subject_model.dart` | Placed directly in `models/` (no `data/` parent), breaking the `data/models/` convention used by every other feature |
| `lib/core/data/models/mastery_state_model.dart` (L1-322) | 322-line model mixing Hive serialization with mutable business logic (`recordAttempt` contains inline spaced-repetition algorithm) |
| `lib/features/settings/data/models/settings_model.dart` (L106-112) | `UsageRecord.calculateTotalCost` hardcodes LLM token pricing constants that change frequently |
| `lib/features/settings/presentation/settings_screen.dart` (L10-11) | Imports `main.dart` for providers (`apiKeyProvider`, `selectedModelProvider`, `settingsProvider`) |
| `lib/features/settings/presentation/api_config_screen.dart` (L5-6) | Imports `main.dart` for providers |
| `lib/features/settings/presentation/profile_screen.dart` (L5) | Imports `main.dart` for `settingsRepository` and `localeProvider` |
| `lib/features/settings/settings.dart` | Barrel file only exports presentation screens; models/repository are not re-exported, forcing deep relative imports |
| `lib/features/subjects/data/repositories/subject_repository.dart` | `getStudentSubjects` ignores `studentId` param and returns `getAll()` — dead parameter |
| `lib/features/lessons/data/models/` | Empty directory (leftover scaffolding) |
| `lib/features/lessons/services/`, `lib/features/planner/services/`, `lib/features/sessions/services/` | Empty directories |
| `lib/features/settings/data/repositories/settings_repository.dart` | `SettingsRepository` is a singleton DAO with no interface/abstraction; directly exposes Hive `Box` semantics |

## Rationale

1. **Duplicate profile models risk silent data loss.** `ProfileData` (typeId: 5) and `UserProfile` (typeId: 10) are persisted to separate Hive boxes. When the profile screen writes via `ProfileData` but other code reads via `UserProfile`, the two fall out of sync. The `settings_box.g.dart` generated file is never regenerated for `ProfileData` because `settings_box.dart` lacks a `part` directive. This means `ProfileData` serialization is entirely manual while `UserProfile` uses auto-generated serialization — yet both claim to represent user profile data.

2. **Inconsistent directory structure creates cognitive overhead.** `Subject` model lives at `lib/features/subjects/models/subject_model.dart` while every other feature nests models under `data/models/`. The `subjects` feature also lacks a `presentation/` subdirectory for *all* its screen files — `subject_list_view.dart` is in `presentation/` but `subject_management_screen.dart`, `subject_selection_screen.dart`, etc. are also there; this is correct but the `data/models` directory is missing from `subjects`.

3. **Mutable models violate immutability conventions.** `MasteryState` uses `late` mutable fields and mutation methods (`recordAttempt`, `_updateAccuracy`, etc.) on a `HiveObject`, making it impossible to track state changes, complicates testing, and prevents reliable change detection in Riverpod. The `recordAttempt` method is 40 lines of business logic embedded in a model class.

4. **`main.dart` imports from feature code create circular-dependency risk.** Three presentation files in the settings feature import `package:studyking/main.dart`. This couples feature code to the app's root composition root, making it impossible to test features in isolation and creating a build-time circular dependency hazard.

5. **Hardcoded token pricing will silently produce wrong costs.** The `calculateTotalCost` function embeds per-token rates for a specific LLM provider. When prices change (which they do frequently), the displayed usage costs will be silently incorrect with no mechanism to update them without a code deploy.

## Acceptance Criteria

- [ ] Consolidate `ProfileData` and `UserProfile` into a single model class; migrate Hive typeId; update all consumers (profile_screen, settings_repository, etc.)
- [ ] Move `subject_model.dart` into `lib/features/subjects/data/models/subject_model.dart` and update imports/barrel file
- [ ] Extract mutable business logic from `MasteryState` into a dedicated service class (e.g. `MasteryCalculationService`); make `MasteryState` immutable with a single `copyWith` mutation path
- [ ] Remove `main.dart` imports from feature presentation files; inject dependencies via Riverpod providers defined in the feature's own provider files or via constructor injection
- [ ] Extract hardcoded token pricing into a configurable provider or runtime configuration source
- [ ] Either populate or remove the 4 empty scaffolding directories
- [ ] Update the settings barrel file to re-export models and repository so consumers use clean imports
