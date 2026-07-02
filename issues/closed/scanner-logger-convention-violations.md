# [Scanner] Logger convention violations

**Source:** automatic scanner
**Severity:** minor

## Finding

The project convention (AGENTS.md) specifies:
- "All Logger instances must be `static final` at class level."
- "Inline `const Logger('Name').e(...)` is forbidden."
- "`.e()` should only be used for unexpected exceptions. `.w()` should be used for caught exceptions in expected error paths."

Two files use non-static-final logger declarations and one `.e()` call should be `.w()`.

## Locations

### Non-static-final Logger declarations

1. **`lib/features/subjects/providers/subjects_repository_provider.dart:18`**
   ```dart
   final logger = const Logger('SubjectsRepositoryNotifier');
   ```
   Created as a **local variable inside a method body** (catch block), not as `static final` at class level. While the file is small (23 lines), this deviates from the convention.

2. **`lib/features/dashboard/services/dashboard_service.dart:18`**
   ```dart
   const logger = Logger('DashboardService');
   ```
   Created inside a **standalone function** `_dashboardServiceDefaultL10n()`, not as `static final`. The class itself (line 24) properly declares `static final Logger _logger`.

### `.e()` call that should be `.w()`

3. **`lib/features/mentor/presentation/mentor_screen.dart:1432`**
   ```dart
   _logger.e('Failed to pop navigator in error handler', e);
   ```
   This is inside a nested catch block handling a `Navigator.pop()` failure during error recovery. Navigator pop failures are **expected** (can fail when no route context exists), so `.w()` is more appropriate per convention.

### Also noted (informational, not violations per se)

~10 files in the codebase use **file-level (top-level)** `final _logger = const Logger('...')` declarations instead of `static final` inside a class. These appear primarily in Riverpod provider files which consist of standalone functions rather than classes. While technically a deviation from the strict "class-level" rule, this pattern is widely used in the Riverpod ecosystem and may be acceptable. Affected files include:

- `lib/core/providers/study_progress_provider.dart:10`
- `lib/core/providers/shared_providers.dart:131`
- `lib/core/providers/app_providers.dart:37`
- `lib/features/dashboard/providers/dashboard_data_providers.dart:23`
- `lib/features/dashboard/providers/dashboard_providers.dart:13`
- `lib/features/mentor/providers/mentor_providers.dart:18`
- `lib/features/planner/providers/syllabus_providers.dart:7`
- `lib/features/planner/providers/adherence_providers.dart:7`
- `lib/features/subjects/providers/subjects_list_provider.dart:7`
- `lib/main.dart:59`

Consider updating the convention to explicitly allow top-level loggers for Riverpod provider files, or refactor these to follow the strict `static final` class-level pattern.

## Recommendation

1. In `subjects_repository_provider.dart`, move `logger` to a top-level `final _logger = const Logger(...)` declaration.
2. In `dashboard_service.dart`, remove the standalone function's `const logger` — the class-level `_logger` can be used instead.
3. In `mentor_screen.dart:1432`, change `.e()` to `.w()` since navigator pop failures during error recovery are expected.
4. Update AGENTS.md to clarify the rule for file-level loggers in provider files, or refactor them.
