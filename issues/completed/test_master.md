# Test Coverage Audit: 5 Untested Files, 3 Orphaned Tests, and Structural Gaps

## Context

A comprehensive audit of the test directory against `lib/features/` source files reveals several coverage gaps and structural issues. The project has ~213 source files and ~206 test files (excluding `.g.dart`), which is strong overall, but 5 source files have **zero test coverage**, 3 test files are **orphaned** (no source counterpart), and at least one category of tests (provider-level) is systematically **too thin** to catch regressions.

## Issues Identified

### 1. Untested source files (highest risk)

| File | Lines | Risk | Reason |
|---|---|---|---|
| `lib/features/dashboard/providers/dashboard_layout_providers.dart` | 53 | **High** | `DashboardLayoutNotifier` is a `StateNotifier` that opens a Hive box, reads/writes state as JSON-like lists, and exposes `toggleCollapsed()` with mutation + persistence. State management with I/O is easy to break silently. |
| `lib/features/planner/data/adapters/plan_adherence_model_adapter.dart` | 52 | **Medium** | Hive `TypeAdapter` for `PlanAdherenceModel` — binary serialization with 10 fields. A field-order mismatch or type change in the model that isn't reflected in the adapter will cause silent data corruption at runtime. |
| `lib/features/ingestion/data/models/source_chunk.dart` | 31 | **Low** | Pure data class with `toJson`/`fromJson`. Straightforward but uncovered. |
| `lib/features/ingestion/services/extraction_result.dart` | 37 | **Low** | Data class with `toMetaJson`/`chunksToJson`. Straightforward but uncovered. |
| `lib/features/ingestion/providers/ingestion_providers.dart` | 46 | **Medium** | Defines 6 Riverpod providers wiring together services and repositories. A provider change that breaks the dependency graph won't be caught. |

**Affected tests**: None exist — all 5 files need new test files.

**Acceptance criteria**:
- [ ] `dashboard_layout_providers_test.dart` covering: `DashboardLayoutPreferences.copyWith`, `isCollapsed`, `DashboardLayoutNotifier.init` (with mocked Hive box), `toggleCollapsed` (add/remove/persist), and provider creation via `ProviderContainer`.
- [ ] `plan_adherence_model_adapter_test.dart` covering: `typeId == 33`, `read` returns correct fields, `write` produces correct bytes, round-trip fidelity for all 10 fields, null `planId` and `metadata` fields.
- [ ] `source_chunk_test.dart` covering: constructor, `toJson`/`fromJson` round-trip, equality, `hashCode`.
- [ ] `extraction_result_test.dart` covering: `toMetaJson`, `chunksToJson`, default values.
- [ ] `ingestion_providers_test.dart` covering: all 6 providers instantiate correctly, dependency overrides work (smoke tests per `teaching_providers_test.dart` pattern).

### 2. Orphaned / dead test files

| File | Lines | Problem |
|---|---|---|
| `test/features/settings/presentation/simple_list_test.dart` | 32 | Debug-only script that prints to stdout — no assertions, no source file, no value. Dead code. |
| `test/features/settings/data/adapters/settings_box_adapter_test.dart` | 83 | `SettingsBoxAdapter` and `UserProfileAdapter` no longer live in `lib/features/settings/data/adapters/` — they are embedded in their respective model files. The adapter tests are duplicated in `models_test.dart` (lines 200–249). |
| `test/features/settings/data/adapters/user_profile_adapter_test.dart` | 75 | Same as above — orphaned and redundant. |
| `test/features/settings/data/models_test.dart` | 268 | **Partially** orphaned: the Hive adapter sub-tests (lines 200–249) duplicate the same adapter tests in the orphaned adapter test files. The `SettingsBox` and `UserProfile` model tests here also overlap with dedicated per-model test files (`settings_box_test.dart`, `user_profile_model_test.dart`). |

**Affected tests**: 4 files that should be removed or consolidated.

**Acceptance criteria**:
- [ ] Delete `simple_list_test.dart` — it tests no source code.
- [ ] Delete `settings_box_adapter_test.dart` and `user_profile_adapter_test.dart` — their content is duplicated in `models_test.dart`.
- [ ] Audit `models_test.dart` against `settings_box_test.dart` and `user_profile_model_test.dart` for overlap; remove or deduplicate the overlapping test cases.

### 3. Thin provider-level tests (systematic weakness)

`test/features/teaching/providers/teaching_providers_test.dart` (81 lines) covers 6 providers with 7 tests, but every test is a single-assertion construction check (e.g., `expect(provider.read(...), isA<TutorService>())`). This pattern is repeated in other provider test files across the project. These tests confirm the provider *creates* something but never verify that the created object has the expected dependencies injected, nor that provider logic (e.g., fallbacks, computed values) behaves correctly under edge conditions.

The same thin pattern is observable across provider tests in most features — they verify instantiation but not behavior or dependency wiring.

**Affected patterns**: All `test/features/*/providers/*_test.dart` files that only assert `isA<...>()`.

**Acceptance criteria**:
- [ ] Audit provider tests across all features — flag any that only test construction (`isA<...>()` or `isNotNull`).
- [ ] Add at least one behavioral assertion per provider group. For example:
  - `teachingModelIdProvider`: verify fallback logic when `selectedModel` is empty, when `llmProvider` changes.
  - `tutorServiceProvider`: verify it is the same instance across reads (auto-dispose behavior).
  - `voiceControllerProvider`: verify it is correctly disposed.
- [ ] Document the minimum bar for provider tests in `AGENTS.md`.

### 4. Test file placement inconsistencies

A small number of files break the convention in `AGENTS.md`:

- `test/features/teaching/models/evaluation_result_test.dart` — tests `lib/features/teaching/models/evaluation_result.dart`, which is under `models/` in the source, so this is correct.
- But `test/features/teaching/providers/teaching_providers_test.dart` tests providers that *depend on* services — the test could also validate that wiring is correct, which it currently doesn't.

More generally, the convention table in `AGENTS.md` is incomplete: it doesn't cover `data/adapters/`, `data/teaching_data.dart`-style data files, or `core/`-level files.

**Acceptance criteria**:
- [ ] Extend the `AGENTS.md` convention table to cover all subdirectory patterns found in the codebase (adapters, data files, core utilities).
- [ ] Verify every source file matches the expected test location; fix any mismatches (none found in this audit, but the convention should be explicit to prevent future drift).

## Rationale

- The `DashboardLayoutNotifier` is UI-adjacent state with persistence — exactly the kind of code where a missing `.put()` or a stale Hive key silently breaks the user experience. It's the highest-ROI file to test.
- The `PlanAdherenceModelAdapter` is binary serialization: if the model gains a field and the adapter doesn't, old data is read as garbage. A round-trip test catches this instantly.
- The orphaned tests (`simple_list_test.dart`, duplicate adapter tests) create confusion — a developer adding or changing adapter code doesn't know which test file to update.
- Provider tests that only check creation give a false sense of coverage. A provider whose dependency was accidentally removed (making construction throw) would still be caught, but incorrect wiring (wrong implementation injected) would not.

## Affected Files

**New test files needed (5)**:
- `test/features/dashboard/providers/dashboard_layout_providers_test.dart`
- `test/features/planner/data/adapters/plan_adherence_model_adapter_test.dart`
- `test/features/ingestion/data/models/source_chunk_test.dart`
- `test/features/ingestion/services/extraction_result_test.dart`
- `test/features/ingestion/providers/ingestion_providers_test.dart`

**Files to remove (3)**:
- `test/features/settings/presentation/simple_list_test.dart`
- `test/features/settings/data/adapters/settings_box_adapter_test.dart`
- `test/features/settings/data/adapters/user_profile_adapter_test.dart`

**Files to audit for deduplication (1)**:
- `test/features/settings/data/models_test.dart`

**Files to raise quality bar (all provider tests)**:
- `test/features/*/providers/*_test.dart` — systematically add behavioral assertions beyond `isA<...>()`.

**Documentation**:
- `AGENTS.md` — extend test placement convention table.
