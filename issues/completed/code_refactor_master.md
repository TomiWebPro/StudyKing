# Refactor: Critical Cleanup — Hive Type Collisions, Dead Code, Misplaced Files & i18n Gaps in `practice` Feature

## Context

The `practice` feature (`lib/features/practice/`) has accumulated multiple architectural issues that degrade maintainability and pose runtime risks. The most severe — Hive `typeId` collisions — will crash the app at startup when the second adapter overwrites the first during registration. Other issues include dead parameters, files in wrong directories, unlocalized UI strings, an over-exposing barrel file, and a bug in question timing analytics.

---

## Issue 1 — Hive typeId Collisions (CRITICAL — Runtime Crash)

Two pairs of models share the same `@HiveType(typeId: ...)`. Hive registers adapters by `typeId`; the second registration silently overwrites the first, causing **data corruption or `TypeError` at runtime** when reading stored objects.

| Collision | typeId | Production Files | `hive_type_ids.dart` Entry |
|---|---|---|---|
| **11** | `SubjectModel` (`core/data/models/subject_model.dart:5`) and `AccessibilityPreferences` (`features/settings/data/models/accessibility_preferences.dart:5`) | `_typeIdSubjectModel = 11` |
| **24** | `StudentAttempt` (`features/practice/data/models/student_attempt_model.dart:5`) and `RoadmapModel` (`features/planner/data/models/roadmap_model.dart:3`) | `_typeIdStudentAttempt = 24` |

Also, `_typeIdMarkschemeLegacy = 25` occupies the same slot as `MilestoneModel` (`roadmap_model.dart:108`, `@HiveType(typeId: 25)`). And typeIds 30/31 have manual adapters (`PlanAdherenceMetricAdapter`, `MasteryImprovementMetricAdapter`) that risk collision with annotated models (`PendingActionModel`, `BadgeModel`).

Additionally, `engagement_nudge_model.dart:3` (`typeId: 32`) and `plan_adherence_model.dart:3` (`typeId: 33`) are not tracked in `hive_type_ids.dart` at all.

**Rationale:** `hive_type_ids.dart` is meant to be the single source of truth but provides false confidence — `_checkUniqueIds()` only validates its own constant list and does not scan `@HiveType` annotations, so it never detects the real collisions.

**Action:** Reassign colliding typeIds, update both `@HiveType` annotations and `hive_type_ids.dart`, and add a CI check (or `build.yaml` hook) that scans all `@HiveType(typeId: ...)` annotations and cross-references them against the central tracker.

**Affected files:**
- `lib/core/data/hive_type_ids.dart`
- `lib/core/data/models/subject_model.dart:5`
- `lib/features/settings/data/models/accessibility_preferences.dart:5`
- `lib/features/practice/data/models/student_attempt_model.dart:5`
- `lib/features/planner/data/models/roadmap_model.dart:3`, `:108`
- `lib/features/planner/data/models/engagement_nudge_model.dart:3`
- `lib/features/planner/data/models/plan_adherence_model.dart:3`
- `lib/features/planner/data/models/pending_action_model.dart:3`
- `lib/features/dashboard/data/models/badge_model.dart:3`

---

## Issue 2 — Misplaced Screen Files (Architecture)

Three screen files sit in `lib/features/practice/presentation/` root instead of `presentation/screens/`:

| Current Location | Correct Location |
|---|---|
| `presentation/practice_screen.dart` | `presentation/screens/practice_screen.dart` |
| `presentation/practice_session_screen.dart` | `presentation/screens/practice_session_screen.dart` |
| `presentation/practice_results_screen.dart` | `presentation/screens/practice_results_screen.dart` |

Meanwhile `exam_session_screen.dart` correctly lives in `presentation/screens/`. This inconsistency forces developers to check two locations. The barrel file (`practice.dart:11-13`) exports the root-level paths, and `practice_screen.dart:25` uses a mixed-depth import path (`presentation/screens/exam_session_screen.dart`) that breaks the principle that screens should only communicate via the router.

**Rationale:** The project's own conventions (see `AGENTS.md`) specify `presentation/screens/` for screen files. Having files in both locations is confusing and error-prone.

**Action:**
1. Move the three files to `presentation/screens/`
2. Update imports in all dependent files (barrel, providers, services)
3. Remove the direct `exam_session_screen.dart` import from `practice_screen.dart` and navigate via the router instead

**Affected files:**
- `lib/features/practice/presentation/practice_screen.dart`
- `lib/features/practice/presentation/practice_session_screen.dart`
- `lib/features/practice/presentation/practice_results_screen.dart`
- `lib/features/practice/presentation/screens/exam_session_screen.dart` (imported from root)
- `lib/features/practice/practice.dart` (barrel exports)
- All files that import these three screens across the codebase

---

## Issue 3 — Dead Unused Parameter in `MasteryRecorder`

`lib/features/practice/services/mastery_recorder.dart:23` accepts `required MasteryStateRepository masteryStateRepo` in its constructor, but **the parameter is never assigned to a field and never used** anywhere in the class (lines 26-30). The call site at `practice_providers.dart:87` dutifully provides it, creating a misleading API contract.

**Rationale:** This adds unnecessary cognitive overhead for readers who must wonder why the parameter exists. It also creates a false dependency that might mask a real missing dependency.

**Action:** Remove the parameter from the constructor, the call site, and test instantiations.

**Affected files:**
- `lib/features/practice/services/mastery_recorder.dart:23`
- `lib/features/practice/providers/practice_providers.dart:87`
- `test/features/practice/services/mastery_recorder_test.dart:166`
- `test/features/practice/presentation/screens/exam_session_screen_test.dart:39`
- `test/helpers/fakes.dart:69`

---

## Issue 4 — Hardcoded English Strings in `ExamSessionScreen` (i18n Gap)

`lib/features/practice/presentation/screens/exam_session_screen.dart` contains 8+ hardcoded English strings that bypass `AppLocalizations`:

| Line(s) | String |
|---|---|
| 384 | `'Exam Configuration'` |
| 397 | `'Start Exam'` |
| 412 | `'Exam Duration'` |
| 431 | `'Number of Questions'` |
| 464 | `'Incorrect'` |
| 465 | `'Skipped'` |
| 474 | `'Exam was auto-submitted when time ran out.'` |
| 481 | `'Topic Breakdown'` |

**Rationale:** The rest of the codebase consistently uses `AppLocalizations.of(context)!` for user-facing text. These 8 strings are clearly oversights that cause non-English locales to see English text (per `AGENTS.md`).

**Action:** Add new l10n keys in the `.arb` files and replace each hardcoded string with the corresponding `l10n.*` accessor.

**Affected files:**
- `lib/features/practice/presentation/screens/exam_session_screen.dart`
- `lib/l10n/` (arb files need new entries)

---

## Issue 5 — Barrel File Exposes Internal Implementation Details

`lib/features/practice/practice.dart` exports **33 items** including every repository, service, provider, and individual widget. This creates a very wide API surface and makes internal refactoring difficult (any change to an internal class may break external consumers).

**Rationale:** Feature barrel files should expose only the public API — screen classes, the main service interfaces, and the feature-level provider. Internal repositories and individual widgets should not be exported.

**Action:** Trim barrel exports to only public-facing types. Internal repositories and widgets should be imported directly by the files that need them, not re-exported.

**Affected files:**
- `lib/features/practice/practice.dart` (entire file — all 33 export lines)

---

## Issue 6 — Bug: Hardcoded / Averaged `timeSpentMs` in Exam and Practice Sessions

**6a.** `exam_session_screen.dart:173,183` passes `timeSpentMs: 0` or `timeSpentMs: 1` — hardcoded values that make per-question timing analytics meaningless.

**6b.** `practice_session_screen.dart:192-193` divides total session elapsed time by question count and assigns that average to every question, so all questions get the same `timeSpentMs` even though later questions take longer.

**Rationale:** `timeSpentMs` feeds into mastery computation and spaced repetition scheduling. Incorrect values produce unreliable analytics and suboptimal review scheduling.

**Action:** Track per-question start time using `DateTime` markers (record `DateTime.now()` when each question is shown, compute delta on answer), then pass the real duration.

**Affected files:**
- `lib/features/practice/presentation/screens/exam_session_screen.dart:173,183`
- `lib/features/practice/presentation/practice_session_screen.dart:192-193`

---

## Acceptance Criteria

- [ ] **CRITICAL — Hive typeIds**: No `@HiveType(typeId: ...)` collisions remain. `hive_type_ids.dart` tracks all active typeIds. A CI check validates that tracked IDs match all `@HiveType` annotations across the codebase. App starts without adapter registration errors.
- [ ] **Misplaced screens**: `practice_screen.dart`, `practice_session_screen.dart`, and `practice_results_screen.dart` moved to `presentation/screens/`. All imports and barrel exports updated. `practice_screen.dart` navigates to `ExamSessionScreen` via router, not direct `Navigator.push`.
- [ ] **Dead parameter**: `MasteryRecorder` constructor no longer accepts `masteryStateRepo`. All call sites updated.
- [ ] **i18n**: All 8+ hardcoded strings in `exam_session_screen.dart` replaced with `l10n.*` accessors. New `.arb` entries added.
- [ ] **Barrel exports**: `practice.dart` exports only public-facing types (screens, main services, feature provider). Internal repositories and widgets removed from barrel.
- [ ] **Time tracking**: `exam_session_screen.dart` and `practice_session_screen.dart` pass per-question real `timeSpentMs` (not `0`, `1`, or averaged values), using `DateTime` markers.
