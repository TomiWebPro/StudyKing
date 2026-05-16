# Test Coverage & Quality: `lib/core/` Has 19 Untested Files, Orphaned Tests, and Shallow Coverage Patterns

## Context

A comprehensive audit of all 63 source files in `lib/core/` and all ~307 test files across the project reveals that while `lib/features/` has near-perfect file-level test coverage (191/192 files mapped), the `lib/core/` layer — containing foundational services, data layer, utilities, and providers — has **19 source files with zero test coverage**. Additionally, several existing tests are orphaned, misplaced, or superficially shallow, and error-handler coverage is fragmented across 6 overlapping files totaling ~2,890 lines.

---

## Issue A: 19 Untested Source Files in `lib/core/` (Critical)

### Services (6 files — highest business risk)

| Source | Lines | Key Logic Missing Tests |
|---|---|---|
| `lib/core/services/notification_service.dart` | ~120 | Singleton with `init()`, `showNotification()`, 7 notification-type methods (century, streak, accuracy, etc.), `cancel()`, `cancelAll()` |
| `lib/core/services/localization_service.dart` | ~80 | Wraps all 40+ AppLocalizations getter methods; used across every screen |
| `lib/core/services/conversation_memory.dart` | ~150 | In-memory conversation buffer with automatic persistence to repository, context-length trimming, load/sync from repo |
| `lib/core/services/badge_service.dart` | ~100 | `getBadges()`, `checkAndUnlockBadges()` — business rules for century/streak/accuracy badge unlock logic |
| `lib/core/services/progress_export_service.dart` | 351 | PDF/CSV/JSON export, file I/O, share integration — largest untested file in core |
| `lib/core/services/llm_usage_meter.dart` | ~80 | `LlmUsageMeter` + `LlmUsageRecord` — token tracking across sessions |

### Providers (2 files — state management over Hive)

| Source | Key Logic Missing Tests |
|---|---|
| `lib/core/providers/app_providers.dart` | `SettingsController` (197 lines, 17 public methods) + 10+ Riverpod providers |
| `lib/core/providers/llm_providers.dart` | 4 Riverpod providers for LLM state |

### Data Layer (2 files)

| Source | Key Logic Missing Tests |
|---|---|
| `lib/core/data/repository.dart` | Generic `Repository<T>` base class wrapping Hive CRUD operations |
| `lib/core/data/hive_box_names.dart` | 33 Hive box name constants (trivial but useful for completeness) |

### Config / Constants (4 files)

| Source | Key Logic Missing Tests |
|---|---|
| `lib/core/config/locale_config.dart` | `AppLocale` enum + `resolveLocale()`, `buildDropdownItems()` |
| `lib/core/constants/app_config.dart` | `AppConfig.bootstrap()`, `redactSensitiveValues()`, `AppConstants` singleton |
| `lib/core/constants/token_pricing_config.dart` | `TokenPricingConfig` with `calculateTotalCost()` |
| `lib/core/constants/bottom_sheet_constants.dart` | Single constant (low priority) |

### Utilities (2 files)

| Source | Key Logic Missing Tests |
|---|---|
| `lib/core/utils/logger.dart` | `Logger` class with 4 log levels |
| `lib/core/utils/responsive.dart` | `ResponsiveUtils` (150+ lines), `ScreenBreakpoint` enum, `ResponsiveContext` extension |

### Extensions (1 file)

| Source | Key Logic Missing Tests |
|---|---|
| `lib/core/extensions/iterable_extensions.dart` | `IterableExtension.firstOrNull` |

**Risk**: These 19 files represent the **shared foundation** of the app. Untested foundational code means bugs here cascade silently into all features without detection.

---

## Issue B: Existing Tests That Are Too Shallow or Superficial

### B1 — `mastery_graph_service_test.dart` (332 lines)
Every public method is tested, but **all assertions use only `isSuccess` / `isNotNull` / `isA<List>`** — never validating actual returned values, error propagation, or edge cases. The mock always returns valid data; failure paths are never exercised.

### B2 — `mastery_integration_service_test.dart` (281 lines)
Same shallow pattern as B1. Checks only that methods return success — never verifies specific values, error cases, or boundary conditions.

### B3 — `pdf_ingestion_service_test.dart` (54 lines)
Only tests the guard clause ("returns failure when API key is empty"). The actual PDF text extraction / parsing logic is never tested. Tests exist in form only.

### B4 — `hive_type_ids_test.dart` (13 lines)
Single test that calls `validateHiveTypeIds()` and asserts no exception. Tests nothing meaningful about the type ID registry.

### B5 — `database_service_test.dart` (163 lines)
Only tests `HiveDatabaseService.init()` — verifies all repositories are registered. Never tests actual database operations (CRUD, migration rollback, error recovery).

---

## Issue C: Orphaned, Misplaced, and Fragmented Tests

### C1 — Orphaned: `test/core/services/evaluation_adapter_service_test.dart`
This file contains a single placeholder assertion (`expect(true, isTrue)`). The source class `EvaluationAdapterService` does not exist anywhere in `lib/`. This test is dead code — either remove it or replace it with a real test if the source was accidentally deleted.

### C2 — Misplaced: `test/core/routes/main_screen_test.dart`
Tests `MainScreen` which is defined in `lib/main.dart`, not in `lib/core/routes/`. Per the project's own convention, this test should live at `test/main_screen_test.dart` (root test level).

### C3 — Fragmented: Error handler tests split across 6 files

| File | Lines |
|---|---|
| `test/core/errors/handlers_test.dart` | 909 |
| `test/core/errors/handlers_coverage_test.dart` | 279 |
| `test/core/errors/handlers_missing_exception_types_test.dart` | 301 |
| `test/core/errors/handlers_duration_and_edge_cases_test.dart` | 430 |
| `test/core/errors/app_error_handler_comprehensive_test.dart` | 734 |
| `test/core/errors/error_conversion_edge_cases_test.dart` | 237 |
| **Total** | **~2,890** |

These 6 files largely overlap, with some adding coverage for specific exception types (SyllabusException, PlanGenerationException, etc.) that were missing from the main test. They should be **consolidated into 2-3 focused files** — one for `Result<T>` and error conversion, one for `handleError`/`handleSyncError` UI behavior, and optionally one for edge-case exception types. The fragmentation makes it hard to know where to add new exception tests and creates maintenance debt.

---

## Issue D: Naming Convention Violation (Minor)

`test/features/dashboard/dashboard_barrel_test.dart` uses a `_barrel` suffix that no other feature follows. Rename to `dashboard_test.dart` for consistency with `focus_mode_test.dart`, `lessons_test.dart`, `mentor_test.dart`, etc.

---

## Rationale

- **`lib/core/` is the shared foundation.** Every feature depends on it. Untested core code is the highest-leverage testing debt in the project.
- **Shallow tests create false confidence.** A test that passes but never asserts meaningful values or exercises failure paths is worse than no test — it wastes CI time and gives a false sense of coverage.
- **Fragmented test files increase maintenance cost.** When a new exception type is added, developers must hunt through 6 files to find where to add coverage.
- **Orphaned tests signal code rot.** A test for a deleted class means the test suite is not being pruned, and coverage metrics are inflated.

---

## Acceptance Criteria

- [ ] **AC1**: Tests added for all 19 untested `lib/core/` files, prioritized:
  - Priority P0 (must-have): `notification_service.dart`, `localization_service.dart`, `conversation_memory.dart`, `badge_service.dart`, `progress_export_service.dart`, `llm_usage_meter.dart`, `app_providers.dart` (SettingsController)
  - Priority P1 (should-have): `repository.dart`, `llm_providers.dart`, `logger.dart`, `responsive.dart`, `locale_config.dart`
  - Priority P2 (nice-to-have): `app_config.dart`, `token_pricing_config.dart`, `iterable_extensions.dart`, `hive_box_names.dart`, `bottom_sheet_constants.dart`
- [ ] **AC2**: Deepen `mastery_graph_service_test.dart` and `mastery_integration_service_test.dart` to assert specific returned values and exercise error/failure paths (not just `isSuccess` / `isNotNull`)
- [ ] **AC3**: Expand `pdf_ingestion_service_test.dart` beyond the API-key guard to test actual ingestion logic (or document why it cannot be unit-tested)
- [ ] **AC4**: Either remove or replace `test/core/services/evaluation_adapter_service_test.dart`
- [ ] **AC5**: Move `test/core/routes/main_screen_test.dart` to `test/main_screen_test.dart`
- [ ] **AC6**: Consolidate the 6 error-handler test files into at most 3 focused files, ensuring no coverage regression
- [ ] **AC7**: Rename `test/features/dashboard/dashboard_barrel_test.dart` to `dashboard_test.dart`
