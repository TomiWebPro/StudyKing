# Critical Test Gaps: 8 Untested Core Models, 6 Missing Feature Tests, and Pervasive Inadequate Coverage

## Context

Despite a large test suite, **structural weaknesses** undermine regression protection. The completed issue `test_master.md` covered `MentorService._checkAndHandlePlanningIntent` and provider boilerplate. This issue addresses **remaining gaps at every layer**: untested foundational models, missing feature‑level test files, dangerously shallow tests, and universal holes across all model tests.

---

## Problem 1: 8 Core Data Models Have Zero Tests

These models underpin the entire app — they are persisted via Hive and consumed by every feature — yet have **no test file whatsoever**. A regression in serialization, field mapping, or default values would go undetected until runtime.

| Source File | Key Classes | Risk |
|---|---|---|
| `lib/core/data/models/badge_model.dart` | `BadgeModel`, `BadgeDefinition`, `BadgeDefinitions`, `CheckOperator` | Badge logic (`isSatisfiedBy`, `getById`) and Hive persistence |
| `lib/core/data/models/engagement_nudge_model.dart` | `EngagementNudgeModel`, `NudgeType`, `NudgeSeverity` | Nudge creation & dedup, enum mappings, `copyWith` (9 fields) |
| `lib/core/data/models/mastery_improvement_metric_model.dart` | `MasteryImprovementMetric`, `MasteryLevel` | JSON serialization, `leveledUp` computed getter |
| `lib/core/data/models/pending_action_model.dart` | `PendingActionModel`, `PendingActionType` | Action type discrimination, string/name consistency, `copyWith` (8 fields) |
| `lib/core/data/models/plan_adherence_metric_model.dart` | `PlanAdherenceMetric` | JSON serialization, adherence score field wiring |
| `lib/core/data/models/plan_adherence_model.dart` | `PlanAdherenceModel` | Hive roundtrip, `copyWith` (10 fields), nullable fields |
| `lib/core/data/models/roadmap_model.dart` | `RoadmapModel`, `MilestoneModel` | Nested JSON with `plannedVsActual` and `milestones`, two Hive type IDs |
| `lib/core/data/models/student_availability_model.dart` | `StudentAvailabilityModel` | `isAvailableOn` date logic, `copyWith` (7 fields), blackout dates, Hive type 35 |

**Acceptance Criteria:**
- Each model above has a corresponding `*_test.dart` in `test/core/data/models/`
- Tests cover: all constructors (required + named), `copyWith` (each field + null semantics), `toJson`/`fromJson` roundtrip (where applicable), `==`/`hashCode`, `toString`, edge cases (null/empty/negative/boundary), and `HiveObject` type IDs

---

## Problem 2: 6 Feature-Level Source Files Missing Tests

Per AGENTS.md convention, every source file must have a matching test. These files are entirely uncovered:

| Source File | Expected Test | Type | Complexity |
|---|---|---|---|
| `lib/features/planner/data/repositories/student_availability_repository.dart` | `test/features/planner/data/repositories/student_availability_repository_test.dart` | Repository | Hive CRUD + date queries |
| `lib/features/planner/presentation/widgets/calendar_view_widget.dart` | `test/features/planner/presentation/widgets/calendar_view_widget_test.dart` | Widget | 175‑line StatefulWidget with calendar grid |
| `lib/features/planner/presentation/widgets/progress_overlay_widget.dart` | `test/features/planner/presentation/widgets/progress_overlay_widget_test.dart` | Widget | 188‑line complex progress UI |
| `lib/features/planner/services/action_executor.dart` | `test/features/planner/services/action_executor_test.dart` | Service | Pending action execution pipeline |
| `lib/features/sessions/services/session_export_service.dart` | `test/features/sessions/services/session_export_service_test.dart` | Service | Data export logic |
| `lib/features/subjects/providers/topic_repository_provider.dart` | `test/features/subjects/providers/topic_repository_provider_test.dart` | Provider | Riverpod provider wiring |

**Acceptance Criteria:**
- All 6 files above have matching `*_test.dart` files following existing conventions (hand‑written fakes, `ProviderScope` with overrides for widgets)
- Repository and service tests cover success paths, error/edge cases, and Hive interaction
- Widget tests verify rendering and user interaction

---

## Problem 3: Existing Tests That Are Dangerously Inadequate

Four existing tests provide **false confidence** — they are either placeholder tests or test mocks instead of real logic:

### 3a. `source_model_test.dart` — 3 assertions, no serialization
Only tests 3 constructor variants. **`toJson`, `fromJson`, `copyWith`, `==`/`hashCode`, `toString`, and all edge cases are missing.**

### 3b. `database_service_test.dart` — Placeholder
Single test: `expect(DatabaseService(), isNotNull)`. **Zero behavior is exercised.**

### 3c. `student_id_service_test.dart` — Singleton + null check only
Tests singleton identity and that one provider is not null. **ID generation, caching, persistence, Hive interaction, and all other providers are untested.**

### 3d. `plan_repository_test.dart` — Tests a mock, not the real class
Uses `_MockPlanRepository` with in-memory map that bypasses all real Hive logic. `init()` is never called. The test suite is self‑referential — it tests `MockPlanRepository`'s in‑memory map, not `PlanRepository`.

**Acceptance Criteria:**
- `source_model_test.dart`: Add `toJson`/`fromJson` roundtrip, `copyWith` each field, `==`/`hashCode`, `toString`, edge cases (null `title`/`type`, invalid `type` string in JSON)
- `database_service_test.dart`: Add real integration tests or replace with a meaningful contract test
- `student_id_service_test.dart`: Test `getStudentId()` (first‑call generation vs. cached), `setStudentId()` persistence, all 3 providers resolve correctly
- `plan_repository_test.dart`: Test the real `PlanRepository` backed by a temp Hive box, covering `init`, `savePlan`, `loadPlan`, `deletePlan`, `hasPlan`, `getAllPlans`; remove self‑referential mock test

---

## Problem 4: Universal Gaps Across ALL Model Tests

Every model test file (`test/core/data/models/*_test.dart`) is missing the same three categories:

| Gap | Example Files Affected | Impact |
|---|---|---|
| **`==` operator / `hashCode`** | All 20 existing model tests | Identity vs. equality bugs go undetected. Many models use `HiveObject` identity equality — never verified. |
| **`toString`** | 18 of 20 model tests | Debug output silently changes; no test catches it. |
| **Error handling** (malformed JSON, missing non‑nullable fields, wrong types, DateTime parsing failures) | All 20 existing model tests | Every `fromJson` has `??` fallbacks and error recovery that are never exercised. A regression that silently returns broken defaults instead of throwing would be invisible. |

**Acceptance Criteria:**
- Every `*_model_test.dart` adds at least one test for `==`/`hashCode` (or documents intentional identity‑based equality)
- Every `*_model_test.dart` adds at least one `toString` assertion
- Every test for a model with `fromJson` adds at least one malformed/null/missing‑field JSON edge case

---

## Problem 5: `hive_initializer_test.dart` Incomplete

The source `lib/core/data/hive_initializer.dart` registers **5 additional boxes** (`conversations`, `tutorSessions`, `planAdherenceMetrics`, `masteryImprovementMetrics`, `focusSessions`) and **4 additional adapter type IDs** (27, 28, 30, 31) that the test never verifies.

**Acceptance Criteria:**
- Test asserts all 5 missing boxes are opened
- Test asserts all 4 missing adapter type IDs are registered
- Test asserts the `tearDown` list includes all opened boxes

---

## Affected Files

| File | Issue |
|---|---|
| `lib/core/data/models/badge_model.dart` | No test file |
| `lib/core/data/models/engagement_nudge_model.dart` | No test file |
| `lib/core/data/models/mastery_improvement_metric_model.dart` | No test file |
| `lib/core/data/models/pending_action_model.dart` | No test file |
| `lib/core/data/models/plan_adherence_metric_model.dart` | No test file |
| `lib/core/data/models/plan_adherence_model.dart` | No test file |
| `lib/core/data/models/roadmap_model.dart` | No test file |
| `lib/core/data/models/student_availability_model.dart` | No test file |
| `test/core/data/models/source_model_test.dart` | Missing `toJson`/`fromJson`/`copyWith`/`==`/`hashCode`/`toString`/edge cases |
| `test/core/data/database_service_test.dart` | Placeholder — one `isNotNull` assertion |
| `test/core/services/student_id_service_test.dart` | Only singleton + null check, no logic tests |
| `test/features/planner/data/repositories/plan_repository_test.dart` | Tests mock, not real `PlanRepository` |
| `test/core/data/hive_initializer_test.dart` | Missing 5 boxes and 4 adapter ID checks |
| `lib/features/planner/data/repositories/student_availability_repository.dart` | No test file |
| `lib/features/planner/presentation/widgets/calendar_view_widget.dart` | No test file |
| `lib/features/planner/presentation/widgets/progress_overlay_widget.dart` | No test file |
| `lib/features/planner/services/action_executor.dart` | No test file |
| `lib/features/sessions/services/session_export_service.dart` | No test file |
| `lib/features/subjects/providers/topic_repository_provider.dart` | No test file |
| All `test/core/data/models/*_test.dart` (20 files) | Missing `==`/`hashCode`/`toString`/error‑handling tests |

---

## Rationale

1. **Core models are the foundation** — 8 untested `HiveObject` subclasses create risk of silent data corruption. A wrong `copyWith` default, a missing `toJson` field, or a broken `fromJson` null‑handling path would corrupt persisted data before anyone notices.
2. **Placeholder and mock‑test tests inflate the suite** — They pass CI but catch zero real bugs. The `plan_repository_test.dart` pattern (test a mock != test the real class) is especially dangerous because it provides the illusion of coverage.
3. **Universal gaps compound** — No model test checks `==`/`hashCode` or `toString`. Every model test lacks `fromJson` error‑handling coverage. Fixing these once across all models is far cheaper than fixing each individually.
4. **Hive initializer incompleteness** is a ticking clock — if a new box name changes or an adapter ID collides, no test will catch it.
