# Improvement Report: `lib/features/sessions/`

**Date:** 2026-05-10 17:45  
**Analyzed by:** Automated code review  
**Scope:** `lib/features/sessions/` (3 files, 1025 lines total)

---

## File-by-File Findings

---

### FILE 1: `lib/features/sessions/presentation/session_history_screen.dart` (356 lines)

| # | Line(s) | Severity | Category | Description | Suggested Fix |
|---|---------|----------|----------|-------------|---------------|
| 1 | 23 | **HIGH** | Bug | `StudySessionRepository` is instantiated directly via `new`. Its `init()` method (which opens the Hive box) is never called. Any call to `_box` will throw a `LateInitializationError` crash. | Call `_sessionRepository.init()` after construction, or inject an already-initialized repository via Riverpod provider. |
| 2 | 24-25 | **HIGH** | Bug | `_loadSessions()` is `async` but not `await`ed in `initState`. `_filterSessions()` runs immediately after on line 25 while `_allSessions` is still an empty list. The initial filter call is entirely wasted. | Move the `_filterSessions()` call inside the `setState` callback in `_loadSessions()` after data is loaded. |
| 3 | 46 | **LOW** | Dead Code | `dateStr` variable is computed on line 46 but never used. The actual filtering uses `_isSameDay()` on line 47. | Remove unused `dateStr` variable. |
| 4 | 97 | **MEDIUM** | Bug | After `_deleteSession`, calling `_loadSessions()` resets `_filteredSessions` to `_allSessions` (line 34), clearing any active date/subject filter without restoring it. | After `_loadSessions()` completes, re-apply the existing filters by calling `_filterSessions()`. |
| 5 | 95-98 | **MEDIUM** | Bug | `_deleteSession` awaits the dialog but does **not** await `_sessionRepository.delete()`. The delete is fire-and-forget. If it fails, the item is already removed from the UI (via `onDismissed`), causing a stale UX. | `await _sessionRepository.delete(session.id)` and wrap in try-catch with user-facing error notification. |
| 6 | 278-281 | **HIGH** | Bug | `onDismissed` is irreversible — swipe-dismiss immediately removes the item from the UI. If `_deleteSession` fails (network/db error), the item is gone from view but still exists in the database, creating invisible inconsistency. | Use `confirmDismiss` instead of `onDismissed` to control removal after the async operation succeeds, or show a SnackBar with Undo action. |
| 7 | 300 | **LOW** | UX | Session titles use `'Session ${index + 1}'` which reflects filtered-array index, not the session's actual chronological or DB identifier. After filtering, this becomes meaningless (e.g., "Session 1" might be the 10th real session). | Use a display number based on total sorted position, or include the session's date/time as the title. |
| 8 | 165 | **LOW** | Naming | Method `_showDateFilter` is misleading — it shows a `showDatePicker`, not a filter dialog. | Rename to `_showDatePicker`. |
| 9 | 180-182 | **MEDIUM** | Incomplete | Subject filter button `onPressed` has a no-op body with a `// Subject filter would go here` comment. Tapping does nothing and gives no user feedback. | Implement subject filtering or disable the button with a "Coming soon" tooltip. |
| 10 | 169, 186 | **LOW** | Code Style | Hardcoded emojis (`'📅'`, `'📚'`) in button labels alongside proper `Icon` widgets. Emojis render inconsistently across platforms and are redundant with the existing icons. | Remove emoji characters; use only the `Icon` widgets. |
| 11 | 116-126 | **LOW** | Fragile | `_formatDate` uses `==` to compare two `DateTime` objects. While both are normalized to midnight, this is a fragile pattern — `==` checks referential/tick equality. A daylight-saving or timezone edge case could break it. | Use `date.year == now.year && date.month == now.month && date.day == now.day` or `isAtSameMomentAs` after normalization. |
| 12 | 342-354 | **MEDIUM** | UX | No loading indicator. While `_loadSessions()` is in flight, the UI shows the empty state "No sessions yet". | Add a `CircularProgressIndicator` shown during loading (track with a `_isLoading` flag). |
| 13 | 251-252 | **LOW** | Bug-Prone | `theme.textTheme.bodyMedium?.color` can be `null` if `bodyMedium` is null, causing a `Color?` to propagate where `Color` is expected. | Fall back to a hardcoded color or use `theme.textTheme.bodyMedium?.color ?? theme.textTheme.bodySmall?.color`. |
| 14 | 75-98 | **MEDIUM** | Memory | `_deleteSession` builds a new `AlertDialog` subtree every invocation. The dialog builder lambda captures `context` which, if the widget is disposed before the dialog closes, can cause a failure. | Handle `mounted` check before `Navigator.pop` and after awaiting the dialog. |
| 15 | 34, 58 | **LOW** | Redundancy | `_filteredSessions = _allSessions` is set in two places: `_loadSessions` (line 34) and `_filterSessions` (line 58). The line 34 assignment is immediately overwritten if any filter is active. | Remove redundant assignment from `_loadSessions` and let `_filterSessions()` handle the initial unfiltered case. |
| 16 | 44, 48 | **LOW** | Efficiency | `_filterSessions()` sorts on every call. For large datasets, repeated filtering (date change, filter clear, etc.) causes unnecessary re-sorts. | Sort once in `_loadSessions` and only filter (without sort) on subsequent calls, or mark dirty state. |
| 17 | 101-113 | **LOW** | Duplication | `_formatTime(Duration)` is identical to the method in `session_tracker_screen.dart:120-132`. | Extract to a shared utility class (e.g., `lib/core/utils/time_utils.dart`). |
| 18 | 63-65 | **LOW** | Duplication | `_isSameDay(DateTime, DateTime)` is duplicated in `session_tracker_screen.dart:78-80`. | Extract to shared utility. |

---

### FILE 2: `lib/features/sessions/presentation/session_tracker_screen.dart` (413 lines)

| # | Line(s) | Severity | Category | Description | Suggested Fix |
|---|---------|----------|----------|-------------|---------------|
| 1 | 31 | **HIGH** | Bug | `StudySessionRepository` instantiated without calling `init()`. Accessing `_box` will throw `LateInitializationError`. Same root cause as `session_history_screen.dart` #1. | Inject via Riverpod provider or call `init()`. |
| 2 | 32-33 | **HIGH** | Bug | `_loadSessions()` is async but not awaited. `_calculateStats()` runs on the still-empty `_allSessions` list, computing `_totalStudyTime = Duration.zero` and `_currentStreak = 0`. Stats are wrong until `_loadSessions` completes and triggers a rebuild. | Call `_calculateStats()` inside the `setState` of `_loadSessions()` after data arrives. |
| 3 | 54 | **HIGH** | Bug | Streak calculation starts from `yesterday` (`DateTime.now().subtract(const Duration(days: 1))`). **Today's session is never counted.** If the user studied today and the last 5 days, the streak shows 5 instead of 6. | Start from `today` (remove `subtract(const Duration(days: 1))`). |
| 4 | 89-93 | **MEDIUM** | Bug | Timer continues running when the app goes to background. `Timer.periodic` is not paused by `WidgetsBindingObserver`. Elapsed time inflates while the app is minimized. | Register a `WidgetsBindingObserver` and pause/resume the timer on app lifecycle changes. Or compute elapsed time from `DateTime.now().difference(_sessionStartTime)` instead of incrementing a counter. |
| 5 | 103 | **LOW** | Crash Risk | `_sessionStartTime!` is force-unwrapped. If `_endSession()` is somehow called without `_startSession()` having set `_sessionStartTime`, this throws a runtime `NullError`. | Guard with `if (_sessionStartTime == null) return;` or use `!` only after checking. |
| 6 | 105-114 | **MEDIUM** | Bug | `_sessionRepository.create()` is not awaited. If the write fails (Hive box full, disk error), no error is surfaced and the session data is lost silently. | `await _sessionRepository.create(...)` and wrap in try-catch with user-facing SnackBar. |
| 7 | 110-111 | **MEDIUM** | Data Loss | Manually-ended sessions always record `questionsAnswered: 0, correctAnswers: 0`. The session shows "0 questions" in history, providing no value. There is no follow-up dialog to enter stats. | Add a post-session dialog allowing the user to input questions answered / correct, or wire the tracker to the practice screen to receive real data. |
| 8 | 100 | **LOW** | Stale State | `_sessionStartTime` is never cleared after `_endSession`. Holding a stale DateTime reference. | Set `_sessionStartTime = null` after the session ends. |
| 9 | 105 | **LOW** | ID Collision | ID is `DateTime.now().millisecondsSinceEpoch.toString()`. Two sessions started in the same millisecond will collide and overwrite each other. | Use a UUID (e.g., `Uuid().v4()` from the `uuid` package) or a combination of timestamp + random salt. |
| 10 | 113 | **HIGH** | Hardcoded | `studentId: 'anonymous'` is hardcoded. No user identity concept. All sessions are stored under 'anonymous', making multi-user or server-backed scenarios impossible without a migration. | Read from a `UserProvider` or `AuthProvider` via Riverpod. |
| 11 | 116-117 | **MEDIUM** | Bug | `_loadSessions()` is not awaited before `_calculateStats()`. The stats are recalculated before the new session is added to `_allSessions`, so the just-ended session is not reflected in the displayed stats until a rebuild occurs. | `await _loadSessions()` then call `_calculateStats()`. |
| 12 | 120-132 | **LOW** | Duplication | `_formatTime(Duration)` — same method exists in `session_history_screen.dart:101-113`. | Extract to shared utility. |
| 13 | 134-138 | **LOW** | UX | `_formatElapsed` returns `MM:SS` with no hours component. Sessions over 60 minutes display as `90:00`, which is ambiguous. | Format as `HH:MM:SS` or use the same format as `_formatTime`. |
| 14 | 129-131 vs 134-138 | **LOW** | Inconsistency | Two different time formats: `_formatTime` returns `"1h 30m 0s"` while `_formatElapsed` returns `"90:00"`. Users see two different styles for the same concept. | Use a single consistent format throughout. |
| 15 | 89-93 | **LOW** | Efficiency | `Timer.periodic` fires every second and calls `setState` each time, rebuilding the entire widget tree 60+ times per minute during a session. | Consider a less expensive timer update approach or use `AnimatedBuilder` with `Listenable`. |
| 16 | 363-364 | **MEDIUM** | Performance | `_buildRecentSessionsList` creates a sorted copy of `_allSessions` on every build (every `setState`). Sorting O(n log n) on every frame. | Pre-sort `_allSessions` once in `_loadSessions()` or cache the sorted order. |
| 17 | 366 | **LOW** | UX | "Recent Sessions" always shows the last 5. If there are more, there is no affordance to show them beyond the "View All" button. Consider showing a count badge. | Add "5 of N" text or a count badge next to the "View All" button. |
| 18 | 7-8 | **LOW** | Style | Import paths mix relative (`'session_history_screen.dart'`, `'../widgets/session_analytics.dart'`) and package (`'package:studyking/...'`) styles. | Use package-relative imports consistently. |
| 19 | 4 | **LOW** | Dead Import | `flutter_riverpod` is imported and the class extends `ConsumerStatefulWidget`, but `ref` is never used in the build method or anywhere else. The repository is instantiated directly instead of via a provider. | Either switch to `StatefulWidget` or use a Riverpod provider for the repository. |
| 20 | 270-271 | **LOW** | Readability | `_totalStudyTime ~/ _allSessions.length` performs integer division on a `Duration` object (dividing its internal tick count). The resulting `Duration` is correct but it's non-obvious what `~/` on a `Duration` does. | Explicitly compute: `Duration(milliseconds: _totalStudyTime.inMilliseconds ~/ _allSessions.length)`. |
| 21 | 373-394 | **LOW** | Duplication | The session card `ListTile` structure closely mirrors the one in `session_history_screen.dart:288-335`. Could be a shared widget. | Extract a `SessionCard` widget. |

---

### FILE 3: `lib/features/sessions/widgets/session_analytics.dart` (256 lines)

| # | Line(s) | Severity | Category | Description | Suggested Fix |
|---|---------|----------|----------|-------------|---------------|
| 1 | 93-96 | **HIGH** | **BUG** | `_getDayName` uses `days[date.weekday % 7]`. In Dart, `DateTime.monday` = 1, `DateTime.sunday` = 7. The formula maps: Monday→1→`days[1]`='Tue', Sunday→7→`days[0]`='Mon'. **Every day label is shifted by one.** The chart shows incorrect day labels for every data point. | Change to `days[date.weekday - 1]`. |
| 2 | 2 | **LOW** | Dead Import | `flutter_riverpod` imported; class extends `ConsumerWidget` and receives `WidgetRef ref` in `build`, but `ref` is never used. No Riverpod providers are consumed. | Either extend `StatelessWidget` or use `ref` to read session data from a provider instead of receiving it as constructor parameters. |
| 3 | 238-241 | **LOW** | Dead Code | `_getBestStreak()` is a trivial wrapper that just returns `currentStreak`. The comment says "would be more complex in production" but this is never developed. It's a useless indirection. | Inline `currentStreak` directly or remove the method and use the field. |
| 4 | 85-87 | **MEDIUM** | Fragile | `s.startTime.toString().startsWith(dayStr)` compares dates by string prefix. `DateTime.toString()` returns locale-dependent format, not guaranteed to be `YYYY-MM-DD...`. This will break on different locales or Dart SDK versions. | Use proper `DateTime` comparison: `s.startTime.year == date.year && s.startTime.month == date.month && s.startTime.day == date.day`. |
| 5 | 94, 115 | **LOW** | Duplication | The `days` list `['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']` is defined twice — once in `_getDayName` (line 94) and once in `_buildDayOfWeekChart` (line 115). | Define as a top-level `const` list. |
| 6 | 78-91 | **MEDIUM** | Misleading | Method name `_getSessionCountByDayOfWeek` suggests day-of-week aggregation, but it iterates the last 7 calendar days (contiguous window). The chart title says "Last 7 Days" but the bar chart displays Mon-Sun labels, which is confusing when the window spans across weeks. | Either: (a) rename title to "Sessions by Day of Week" and aggregate across all data, or (b) change the chart labels to show actual dates (e.g., "Mon 4", "Tue 5") instead of abstract day names. |
| 7 | 139 | **LOW** | Hardcoded Color | `Colors.grey[200]` used for empty-day bars. Won't adapt to dark mode. In dark mode, grey[200] is near-white on a near-white card background, making empty bars invisible. | Use `theme.disabledColor.withOpacity(0.2)` or `theme.dividerColor`. |
| 8 | 100, 148, 158, 220 | **LOW** | Hardcoded Colors | Multiple uses of `Colors.grey[600]`, `Colors.grey[400]` directly. These do not adapt to dark mode. | Use theme colors: `theme.textTheme.bodySmall?.color ?? Colors.grey`. |
| 9 | 244-256 | **LOW** | Style | `MetricCardData` class has all `final` fields and could be `const`-constructible, but lacks a `const` constructor. | Add `const` constructor: `const MetricCardData({...})`. |
| 10 | 116 | **LOW** | Risk | `counts.values.reduce((a, b) => a > b ? a : b)` on line 116 will throw if `counts.values` is empty. The `isEmpty` guard with `: 1` prevents this, but `maxCount` is always at least 1, which could cause division by issues if all counts are truly 0 (bar heights computed as `40 + 0/1*80 = 40`, which is fine). | Safer: `counts.values.isEmpty ? 1 : counts.values.reduce(max)`. |
| 11 | 168-176 | **LOW** | Performance | `GridView.count` with `shrinkWrap: true` and `NeverScrollableScrollPhysics()` inside a `Column` forces the grid to lay out all children during the parent's build. For 4 items this is negligible, but the pattern is risky if extended. | Document as intentional, or use `Wrap` instead. |
| 12 | 129 | **LOW** | Magic Numbers | Bar height formula `40 + (count / maxCount * 80)` uses two magic numbers. The intent is not obvious. | Extract named constants: `const double _minBarHeight = 40; const double _maxBarHeight = 120;` and compute as `_minBarHeight + (count / maxCount) * (_maxBarHeight - _minBarHeight)`. |
| 13 | 1-3 | **LOW** | Cleanup | Imports include `flutter_riverpod` which is unused, but only `flutter/material.dart` and the model are actually needed. | Remove unused import. |

---

## Cross-Cutting Issues (Affecting Multiple Files)

| # | Severity | Category | Description | Suggested Fix |
|---|----------|----------|-------------|---------------|
| C1 | **CRITICAL** | Runtime Crash | `StudySessionRepository.init()` is **never called** by any of the 3 files. The repository's `_box` is `late` and initialized in `init()`. All repository operations (`getAll`, `create`, `delete`) will throw `LateInitializationError`. This makes the entire sessions feature non-functional. | Call `init()` during app startup (e.g., in `main.dart`) or inject an initialized repository. |
| C2 | **HIGH** | Architecture | No dependency injection. Every file creates `StudySessionRepository()` with `new`. This prevents mocking in tests, couples UI to data layer, and duplicates initialization logic. | Create a Riverpod provider for `StudySessionRepository` and use `ref.watch`/`ref.read` in all files. |
| C3 | **HIGH** | Missing Tests | Zero test files exist for the sessions feature (`test/**` contains nothing for sessions). 100% untested. | Add unit tests for the repository wrapper and widget tests for screens. |
| C4 | **MEDIUM** | Error Handling | All repository calls use basic try-catch with only `debugPrint`. Users never see error messages. Operations fail silently — data loss is invisible. | Surface errors to users via SnackBars, and log to a proper error reporting service. |
| C5 | **MEDIUM** | Duplication | `_formatTime(Duration)` — identical implementation in 2 files. `_formatDate(DateTime)` — very similar in 2 files. `_isSameDay(DateTime, DateTime)` — identical in 2 files. | Extract to a shared utility (`lib/core/utils/time_utils.dart`). |
| C6 | **MEDIUM** | Duplication | Session card/ListTile widget structure is nearly identical in `session_history_screen.dart` and `session_tracker_screen.dart`. | Extract a shared `SessionCard` widget to `lib/features/sessions/widgets/`. |
| C7 | **LOW** | State Mgmt | `session_tracker_screen.dart` is a `ConsumerStatefulWidget` but never uses `ref`. `session_analytics.dart` is a `ConsumerWidget` but never uses `ref`. The Riverpod dependency is imported but unused in both. | Either remove Riverpod from these files or properly use it for state management. |
| C8 | **LOW** | Consistency | `session_tracker_screen.dart` uses `import` with relative paths (`'session_history_screen.dart'`). `session_history_screen.dart` uses package-absolute paths (`'package:studyking/...'`). | Standardize on one convention (prefer package-absolute). |
| C9 | **MEDIUM** | UX | No loading indicators in any screen. When data is being fetched from Hive, the UI shows empty state momentarily, causing a flash. | Add `_isLoading` boolean and show `CircularProgressIndicator` during async operations. |
| C10 | **MEDIUM** | UX | Session deletion has no Undo. Once swiped, the session is deleted permanently with no recovery mechanism. | Show a SnackBar with an "Undo" action that re-creates the deleted session. |

---

## Architecture-Level Suggestions

| # | Severity | Description | Suggested Fix |
|---|----------|-------------|---------------|
| A1 | MEDIUM | `StudySessionRepository` mixes data-access logic with simple CRUD. The `getTotalStudyTimeForSubject` method even has a `timeSpentMs ??= 0` null-coalescing assignment that mutates the model in-place during a read operation (repository line 50). | Separate read-only queries from commands. Remove mutation during reads. |
| A2 | MEDIUM | There are **two repository classes** for the same entity: `StudySessionRepository` and `SessionRepository` (in `lib/core/data/repositories/session_repository.dart`). Both operate on the same Hive box but have different methods. This is confusing and violates DRY. | Consolidate into a single `SessionRepository`. |
| A3 | LOW | The sessions feature has no BLoC / notifier / provider layer. All state management is done via `setState` in the widgets. Sessions data is loaded fresh on every screen mount. | Add a `SessionListNotifier` (Riverpod `StateNotifier`) that caches sessions and provides reactive updates across screens. |

---

## Summary Sorted by Severity

| Severity | Count | Key Issues |
|----------|-------|------------|
| CRITICAL | 1 | `StudySessionRepository.init()` never called → entire feature crashes at runtime |
| HIGH | 9 | Streak bug (misses today), date-label bug in analytics chart, async not awaited in initState, hardcoded studentId, missing `confirmDismiss`, no DI, no tests |
| MEDIUM | 14 | Silent failures, duplicate code, no loading indicators, stale filters after delete, fragile string-based date comparison, timer not paused on background, no undo |
| LOW | 23 | Dead code, minor naming, magic numbers, hardcoded colors, dead imports, inconsistent formatting, redundant allocations |

**Total issues identified: 47**

---

*Report generated automatically on 2026-05-10 at 17:45 UTC.*
