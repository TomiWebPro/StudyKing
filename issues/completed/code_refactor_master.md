# Inconsistent Code Quality Patterns: Dead Code, Mixed Import Styles, and Inappropriate Log Levels

## Context

While auditing the `sessions` feature per the codebase conventions, several systemic code quality issues were identified that negatively impact maintainability, readability, and production log hygiene. These patterns recur across multiple files and features.

## Findings

### 1. Duplicate Test Files for `SessionExportService` (Dead Code)

Two test files test identical production code:

| File | Lines |
|---|---|
| `test/features/sessions/services/session_export_test.dart` | 305 |
| `test/features/sessions/services/session_export_service_test.dart` | 217 |

Both target `SessionExportService` with overlapping coverage. This creates confusion about which file is canonical, doubles maintenance surface area, and inflates the test suite with redundancy.

### 2. Empty `init()` Method in `SessionRepository`

`lib/features/sessions/data/repositories/session_repository.dart:13`:

```dart
Future<void> init() async {}
```

This empty method is still called by:
- `session_tracker_screen.dart:70` (`_loadSessions -> _sessionRepository.init()`)
- `session_history_screen.dart:40` (`_loadSessions -> _sessionRepository.init()`)

It gives a false sense of initialization logic and introduces unnecessary async overhead in callers.

### 3. Empty `focus_mode/data/` Directory

`lib/features/focus_mode/data/` exists but contains zero files. It is an orphaned directory — either a leftover from refactoring or a never-populated shell. Every other feature's `data/` directory contains at least one subdirectory or barrel file.

### 4. Mixed Import Styles in Session Presentation Files

Both screen files mix `package:` absolute imports with deep relative `../../../../` imports:

**`lib/features/sessions/presentation/session_tracker_screen.dart`**:
- Lines 1–13: `package:studyking/...`
- Lines 15–18: `../../../../core/...`

**`lib/features/sessions/presentation/session_history_screen.dart`**:
- Lines 1–9: `package:studyking/...`
- Line 10: `../../../../core/utils/logger.dart`
- Line 11: `../services/session_export_service.dart`

This inconsistency makes automated refactoring (e.g., moving files) error-prone and reduces readability.

### 5. Inappropriate Use of `.e()` (Error) Log Level in `SessionRepository`

`lib/features/sessions/data/repositories/session_repository.dart` uses `_logger.e(...)` for **every** caught exception (15+ call sites). Examples:

```dart
// Expected/recoverable failures logged as ERROR
_logger.e('Error saving session', e);
_logger.e('Error getting sessions by date', e);
_logger.e('Error getting sessions by type', e);
_logger.e('Error deleting session', e);
```

The `Logger.e()` level is reserved for **unexpected/unrecoverable** errors per `lib/core/utils/logger.dart:46` — it is always logged even in production. Operational failures like "session not found" or "failed to query" should use `_logger.w()` (warn), which is also always visible but signals a recoverable condition rather than a system malfunction.

## Affected Files

| File | Issue |
|---|---|
| `test/features/sessions/services/session_export_test.dart` | Duplicate test file — candidate for deletion |
| `test/features/sessions/services/session_export_service_test.dart` | Duplicate test file — prefer this as canonical |
| `lib/features/sessions/data/repositories/session_repository.dart` | Empty `init()` method (line 13); 15+ `.e()` calls that should be `.w()` |
| `lib/features/sessions/presentation/session_tracker_screen.dart` | Mixed import styles (lines 1–13 vs 15–18); unused `import 'dart:math'` |
| `lib/features/sessions/presentation/session_history_screen.dart` | Mixed import styles (lines 1–9 vs 10–11) |
| `lib/features/focus_mode/data/` | Empty orphaned directory — candidate for removal |

## Rationale

- **Dead code** increases maintenance burden and confuses developers. The duplicate test files and empty `init()` method serve no purpose.
- **Mixed imports** break consistency with the project's `package:` import convention used everywhere else, making code harder to refactor and review.
- **Misused log levels** pollute production error monitoring with expected failures, making it harder to distinguish real system errors from routine operational edge cases.
- **Orphaned empty directories** accumulate over time without detection, cluttering the project structure.

## Acceptance Criteria

- [ ] `session_export_test.dart` is removed (or its unique coverage is merged into `session_export_service_test.dart`), leaving exactly one canonical test file for `SessionExportService`.
- [ ] The empty `init()` method in `SessionRepository` is removed along with all call sites in screens.
- [ ] The empty `lib/features/focus_mode/data/` directory is deleted.
- [ ] All imports in `session_tracker_screen.dart` and `session_history_screen.dart` use the consistent `package:studyking/...` style (relative `../services/` is acceptable for intra-feature imports per convention).
- [ ] All `.e()` calls in `session_repository.dart` are audited and changed to `.w()` for expected/recoverable failures; only truly unexpected errors retain `.e()`.
- [ ] No existing tests break after the refactor.
