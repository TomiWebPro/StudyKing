# Test: Core error module test suite has structural redundancy, convention violations, and untested code paths

## Context

`lib/core/errors/` contains three source files (`exceptions.dart`, `handlers.dart`, `result.dart`) covered by three test files (`test/core/errors/exceptions_test.dart`, `handle_error_ui_test.dart`, `result_and_conversion_test.dart`) totalling ~3070 lines. Despite high nominal coverage, the suite has significant structural problems.

## Issues

### 1. Convention violation: `exceptions_test.dart` mixes unit tests and widget tests

Per `AGENTS.md`: *"Keep unit tests and widget tests in separate files — never mix them in the same file."*

`exceptions_test.dart` contains both:
- Pure unit tests for exception classes (lines 35–438: `toString`, codes, `originalError`, custom overrides)
- Widget tests for `AppErrorHandler` SnackBar rendering (lines 469–788: `handleError`, `handleSyncError`, icon assertions, retry callback tests)

These should be split into two files: one in `test/core/errors/exceptions_test.dart` (pure unit) and a widget test in a separate file.

### 2. `captureContext` helper duplicated across all three test files

The identical `captureContext` helper function appears verbatim in:
- `test/core/errors/exceptions_test.dart` (lines 7–24)
- `test/core/errors/handle_error_ui_test.dart` (lines 7–24)
- `test/core/errors/result_and_conversion_test.dart` (lines 15–32)

A common `test/core/errors/shared_test_helpers.dart` should be extracted and reused.

### 3. Massive overlapping coverage and no clear boundary between test files

Each of the three files tests overlapping aspects of `handlers.dart`:

| File | What it tests from `handlers.dart` | Lines |
|---|---|---|
| `exceptions_test.dart` | `handleError`, `handleSyncError`, `getRetryText` (for 4 exception types) + icons | ~320 widget lines |
| `handle_error_ui_test.dart` | `handleError`, `handleSyncError`, `safely`, `safelySync` icons, retry combos, durations, edge cases | ~1528 lines |
| `result_and_conversion_test.dart` | `_convertToAppException` via `safelySync`/`handleError` (18 conversion patterns) + `getRetryText` (complete) + `toString` | ~753 lines |

A change to `handleSyncError` may require updates in all three files. The test responsibility should be clearly assigned per source file (one test file per source file).

### 4. `_convertToAppException` tested only via UI integration, never as pure logic

The private `_convertToAppException` method (lines 235–298 of `handlers.dart`) contains 18 conversion rules, all tested via `safelySync`/`handleError` which require `BuildContext` + widget pumping. This makes each conversion test slow (~100ms per widget test) and coupled to Flutter.

These are pure string-matching → exception mapping rules that should be tested as fast synchronous unit tests. A refactor to make this method package-private (or extractable) would enable direct unit testing in microseconds rather than milliseconds.

### 5. `_logError` / Logger interaction is never verified

`handlers.dart` method `_logError` calls `_logger.e(...)` (line 231), but no test verifies that logging actually fires. The `AppErrorHandler.handleError` docstring promises *"Log to analytics"* but there is no assertion that the logger was called with the correct context name. If the logger silently fails (e.g., a future refactor changes the Logger API), no test would catch it.

### 6. Missing test for `conversation_phase.dart`

`lib/features/teaching/services/conversation_phase.dart` (an 8-line enum: `greeting`, `teaching`, `exercise`, `feedback`, `adaptiveReview`, `closing`) has no corresponding test file. AGENTS.md requires every `lib/features/*/` source file to have a test file. Although trivial, a basic test verifying:
- All 6 enum values exist
- Values are ordered correctly (since the conversation state machine relies on phase transitions)
should exist at `test/features/teaching/services/conversation_phase_test.dart`.

## Rationale

- **Convention violations** make the test suite harder to navigate and violate project policy.
- **Duplication** means maintainers must update 3 files for a single handler change, increasing the chance of stale tests.
- **Integration-only testing** of `_convertToAppException` makes a pure-logic method ~10× slower to test than necessary.
- **Unverified side effects** (`_logError`) is a common real-world regression vector.
- **Missing enum test** may seem minor, but downstream state machine behavior depends on phase ordering.

## Acceptance Criteria

- [ ] `exceptions_test.dart` is split: unit tests stay, widget tests move to a dedicated widget test file
- [ ] `captureContext` is extracted to `test/core/errors/shared_test_helpers.dart` and imported by error test files
- [ ] Each `lib/core/errors/` source file has exactly one corresponding test file with clear responsibility boundaries
- [ ] `_convertToAppException` is refactored to be testable without `BuildContext` (or extracted to a package-private helper) and has direct synchronous unit tests covering all 18 conversion rules
- [ ] `_logError` interaction is verified (spy/fake logger asserts the correct tag and message are logged)
- [ ] `test/features/teaching/services/conversation_phase_test.dart` exists and covers all 6 enum values and ordering
