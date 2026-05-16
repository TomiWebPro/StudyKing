# Test Quality & Coverage Gaps

## Context

The codebase achieves ~98% structural test coverage (matching source-to-test file pairs). However, **depth and behavioral quality** vary significantly. Four source files have **zero** test coverage, seven core test files contain only trivial assertions (violating the AGENTS.md provider/ behavioral bar), and one test directory is orphaned. The subjects feature (`lib/features/subjects/presentation`) demonstrates the standard we should hold everywhere — its tests cover behavioral flows, error states, edge cases, and navigation — but other areas fall short.

---

## Issue 1: Untested Source Files (4 files)

The following source files have **no corresponding test file**:

| Source | Expected Test Location |
|---|---|
| `lib/features/questions/data/models/drawing_models.dart` (`Stroke`, `DrawingPoint`) | `test/features/questions/data/models/drawing_models_test.dart` |
| `lib/features/questions/presentation/painters/drawing_painter.dart` (`DrawingPainter`) | `test/features/questions/presentation/painters/drawing_painter_test.dart` |
| `lib/features/questions/presentation/painters/grid_painter.dart` (`GridPainter`) | `test/features/questions/presentation/painters/grid_painter_test.dart` |
| `lib/features/mentor/data/models/chat_message_data.dart` | `test/features/mentor/data/models/chat_message_data_test.dart` |

**Rationale:** These are non-trivial classes with serialization (`Stroke`, `DrawingPoint`), custom painting logic (`DrawingPainter.paint` with multi-stroke pathing and single-point fallback), grid-line math (`GridPainter.paint`), and data-model semantics (`ChatMessageData`). Leaving them untested creates blind spots for regressions in math-input and mentor-chat features.

---

## Issue 2: Overly Basic Test Files (7 files)

These files contain **only** construction checks (`isA<Type>()`, `isNotNull`) or plain default-value assertions with **no** behavioral assertions as required by AGENTS.md:

| Test File | Current Scope | Missing Behavioral Assertions |
|---|---|---|
| `test/core/providers/app_providers_test.dart` | 7 `container.read(...)` checks for default values (`isFalse`, `equals(16.0)`, `isEmpty`) | Override wiring, fallback logic, singleton identity, error handling |
| `test/core/constants/app_constants_test.dart` | 11 barrel-export type checks (`isA<Type>()`, `isA<Function>()`) | No actual value/integration tests |
| `test/core/constants/app_runtime_config_test.dart` | Border radius value check + 5 default-value checks | No behavioral logic, no `UiConfig` method testing |
| `test/core/constants/llm_defaults_test.dart` | 3 return-value checks for `defaultModelForProvider()` | No edge-case providers, no empty/fallback paths |
| `test/core/data/enums_test.dart` | Enum value counts + `.index` checks | No serialization, no fromIndex/fromString parsing |
| `test/core/data/hive_type_ids_test.dart` | Single "does not throw" check | No conflict detection, no duplicate-ID scenarios |
| `test/core/data/hive_box_names_test.dart` | 27 string-literal equality checks | No integration with actual box open logic |

**Rationale:** AGENTS.md mandates that every provider test file include **at least one behavioral assertion** (override wiring, fallback logic, singleton verification, or error-state handling). `test/core/providers/app_providers_test.dart` fails this bar outright. The other 6 files have no behavioral testing at all — they are brittle documentation, not tests.

---

## Issue 3: Orphaned Test Directory

`test/features/settings/data/adapters/` exists but is **empty**. There is no corresponding `lib/features/settings/data/adapters/` directory.

**Action:** Either populate the directory with adapter tests if adapters are planned for settings, or remove the empty directory to avoid confusion.

---

## Issue 4: Missing Test Scenarios in Subject Tests

While the subject presentation tests are **strong** overall, notable gaps exist:

| Screen | Missing Scenario |
|---|---|
| `subject_detail_screen_test.dart` | No test for when `sessionRepository` throws during History tab interaction. The screen accepts an optional `sessionRepository` param that is used in the History tab, but error propagation is untested. |
| `subject_detail_screen_test.dart` | No test for the "more options" bottom sheet when routes `upload` / `dashboard` are **not** registered (navigation edge case that could crash). |
| `subject_list_screen_test.dart` | Loading state (centered `CircularProgressIndicator`) is never asserted. The screen has two loading layers (provider async + `FutureBuilder`) but only error/data states are tested. |

---

## Acceptance Criteria

1. **Drawing models & painters** (`drawing_models_test.dart`, `drawing_painter_test.dart`, `grid_painter_test.dart`):
   - `Stroke` and `DrawingPoint` cover construction, default values (color=black, strokeWidth=3, pressure=null), and equality.
   - `DrawingPainter` verifies `shouldRepaint` returns true/false for different/same strokes, and `paint` handles empty stroke lists gracefully (no crash).
   - `GridPainter` verifies `shouldRepaint` for same/different colors, and `paint` produces expected line count for a given canvas size.
   - Directory `test/features/questions/presentation/painters/` is created.

2. **Chat message data model** (`chat_message_data_test.dart`):
   - Covers construction, JSON serialization roundtrip, missing/null fields, and role enum values.

3. **Core providers** (`app_providers_test.dart`):
   - At least one behavioral assertion per AGENTS.md: override wiring (e.g., inject a fake value and verify it reads back), singleton identity, or error fallback.

4. **Core constants** (`app_constants_test.dart`, `app_runtime_config_test.dart`, `llm_defaults_test.dart`):
   - Replace barrel-export type checks with at least one meaningful behavioral assertion per group, or remove the file if the exports are trivial (convention: barrel-only files don't need tests).

5. **Core data enums, hive type IDs, box names**:
   - `enums_test.dart`: Add fromIndex/fromString parsing or serialization tests.
   - `hive_type_ids_test.dart`: Add duplicate-ID conflict detection test.
   - `hive_box_names_test.dart`: Remove or replace with integration-oriented test.

6. **Orphaned directory**: Remove `test/features/settings/data/adapters/` or populate it with meaningful tests.

7. **Subject screen gaps**: Add tests for (a) sessionRepository throw in detail screen History tab, (b) unregistered route edge case in bottom sheet, (c) loading state in list screen.
