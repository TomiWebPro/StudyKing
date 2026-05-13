# Test Master Issue: Structural Inconsistencies & Critical Coverage Gaps

## Context

The test suite has significant structural debt and blind spots. Several core services and data-layer components lack any tests, while the test directory itself suffers from duplicate files and inconsistent naming conventions that create confusion and maintenance overhead. The project has begun migrating from a dotted-naming flat structure (`core.utils.color_utils.test.dart`) to a directory-based mirror structure (`core/utils/time_utils_test.dart`) but the migration is incomplete — some files exist in both forms or only in the old form.

---

## Issue A: Duplicate Widget Test Files (Critical Structural Debt)

**Four sets of widget tests exist in two locations with diverging code.** One location is the flat `test/widgets/` directory, the other is the feature-aligned path `test/features/questions/ui/widgets/`. These are not aliases — they contain different test implementations for the same widgets.

| Duplicate Pair | Lines (flat) | Lines (feature-path) |
|---|---|---|
| `question_card_widget_test.dart` | 438 | 427 |
| `canvas_drawing_widget_test.dart` | ~200 | ~200 |
| `math_expression_widget_test.dart` | ~200 | ~200 |
| `single_answer_widget_test.dart` | ~200 | ~200 |

**Impact:** Any change to a widget requires updating both test files, or worse — the tests silently diverge and lose coverage value. Newcomers cannot tell which file is canonical.

**Resolution:** Remove the flat `test/widgets/` copies and keep only the feature-aligned ones under `test/features/questions/ui/widgets/`.

---

## Issue B: Inconsistent Test Naming Convention (Structural Debt)

Tests use a mix of two conventions:

| Convention | Example | Count (approx.) |
|---|---|---|
| Old: dotted filename in flat dir | `core.utils.color_utils.test.dart` | ~50 files |
| New: directory mirror of source | `core/utils/time_utils_test.dart` | ~15 files |

Many source directories have tests in **both** conventions (`core/utils/` has both `core.utils.color_utils.test.dart` and `core/utils/time_utils_test.dart`). This is confusing — a developer looking for the test for `lib/core/utils/color_utils.dart` may look in the wrong place.

**Resolution:** Migrate all remaining dotted-name files to the directory-based convention, matching `lib/` structure. Flat wrappers like `test/core.services.*.test.dart` should become `test/core/services/*_test.dart`.

---

## Issue C: Untested Core Services & Infrastructure (Coverage Gap)

These production files have **zero dedicated unit tests**:

| Source File | Lines | Risk |
|---|---|---|
| `lib/core/services/question_generation_service.dart` | 403 | Contains retry logic, LLM API orchestration, `GenerationResult` error handling |
| `lib/core/data/database_migration.dart` | 120 | Schema migration logic; bugs here corrupt user data |
| `lib/core/data/hive_initializer.dart` | 74 | Box registration and adapter wiring; failure crashes app at startup |
| `lib/core/constants/app_storage_config.dart` | 35 | Filesystem path resolution used across the app |
| `lib/core/data/adapters/*.dart` (6 adapters) | 30-60 each | Hive serialization; wrong read/write corrupts persisted data |
| `lib/features/settings/data/models/user_profile_model.dart` | 97 | Hive model with `fromJson`/`toJson`; no dedicated unit test |
| `lib/features/practice/services/answer_validation_service.dart` | 39 | Caching layer over answer validators; no tests for cache invalidation logic |

---

## Issue D: Existing Tests That Are Too Basic / Missing Edge Cases

Even where tests exist, they often skip important scenarios:

- **`color_utils_test.dart`**: `stringToColor` is only tested with valid 6-char hex codes. Missing: 3-char hex (`#FFF`), hex with alpha (`#FF2196F3`), very long strings, hex values at boundary (`#000000`, `#FFFFFF`). Also tests the `l10n` parameter path only for `getColorLabel` — but the `l10n != null` branch vs `l10n == null` branch coverage is implicit, not explicit.

- **`time_utils_test.dart`**: `formatDate` is tested with today/yesterday/older, but never with future dates (which would produce negative diffs). `isSameDay` handles normal cases but not UTC vs local timezone edge cases.

- **`markscheme_model_test.dart`**: No `toJson`/`fromJson` round-trip tests, no Hive adapter tests, no test for edge case where `acceptableAnswers` is null (it defaults to empty list via constructor but `fromJson` may not).

---

## Acceptance Criteria

1. **Resolve duplicates (Issue A):** Delete the 4 redundant test files under `test/widgets/`. Verify the feature-path counterparts still pass.
2. **Standardize naming (Issue B):** Move remaining dotted-name test files to directory-based paths. Update any import references (if any test runners reference paths directly).
3. **Cover untested services (Issue C):** Create unit tests for each listed file:
   - `test/core/services/question_generation_service_test.dart` — test retry logic, success/failure paths, edge cases for `GenerationResult`
   - `test/core/data/database_migration_test.dart` — test `runMigrations`, `validateSchema`, version tracking
   - `test/core/data/hive_initializer_test.dart` — test adapter registration and box opening (may need `Hive.init` mock)
   - `test/core/constants/app_storage_config_test.dart` — test path resolution (may need temp directory)
   - `test/core/data/adapters/*_test.dart` — round-trip Hive adapter read/write tests for all 6 adapters
   - `test/features/settings/data/models/user_profile_model_test.dart` — constructor, toJson, fromJson, copyWith, Hive adapter
   - `test/features/practice/services/answer_validation_service_test.dart` — cache hit/miss, invalidation on markscheme change
4. **Deepen existing tests (Issue D):** Add edge-case coverage to `color_utils_test.dart`, `time_utils_test.dart`, and `markscheme_model_test.dart` as described above.
