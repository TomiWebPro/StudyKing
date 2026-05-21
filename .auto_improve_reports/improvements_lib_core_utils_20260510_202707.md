# Improvement Report: `lib/core/utils/`  
**Date:** 2026-05-10  
**Scope:** `lib/core/utils/time_utils.dart` (the sole file in this directory)

---

## Summary

| Severity | Count |
|----------|-------|
| Bug      | 3     |
| Code Duplication | 3 (across 4 files) |
| Enhancement | 5 |
| Code Style / Maintainability | 5 |
| Performance | 0 |
| **Total** | **16** |

---

## 1. Bug: "Yesterday" incorrectly matches "Tomorrow"

| Field | Value |
|-------|-------|
| **File** | `lib/core/utils/time_utils.dart` |
| **Line** | 22 |
| **Severity** | **Bug** |

### Description
`formatDate` uses `.abs()` on the difference:
```dart
sessionDate.difference(today).abs() == const Duration(days: 1)
```
This makes the comparison **symmetric**. If `date` is tomorrow, `difference` returns `Duration(days: 1)`, `.abs()` also returns `Duration(days: 1)`, and the function returns `"Yesterday"` — which is incorrect.

### Fix
Remove `.abs()` and check explicitly that the date is in the past:
```dart
final diff = today.difference(sessionDate);
if (diff == const Duration(days: 1)) {
  return 'Yesterday';
}
```

---

## 2. Bug: Negative durations produce malformed output

| Field | Value |
|-------|-------|
| **File** | `lib/core/utils/time_utils.dart` |
| **Lines** | 2–11 |
| **Severity** | **Bug** |

### Description
Dart's `remainder` preserves the sign of the dividend, so `(-61).remainder(60)` returns `-1`. When a negative `Duration` is passed — e.g. `Duration(inMinutes: -61)` — the output becomes `"-1h -1m 0s"` instead of a sensible value or an empty string. No guards exist.

### Fix
Clamp negative durations or take their absolute value:
```dart
String formatDuration(Duration duration) {
  if (duration.isNegative) return formatDuration(-duration);
  // ...
}
```

---

## 3. Bug: Timezone-agnostic comparisons in `formatDate` / `isSameDay`

| Field | Value |
|-------|-------|
| **File** | `lib/core/utils/time_utils.dart` |
| **Lines** | 14–31 |
| **Severity** | **Bug** / **Enhancement** |

### Description
- `formatDate` calls `DateTime.now()` (local time) but receives a `DateTime` argument that may be in **UTC** (common for timestamps from a backend).
- `isSameDay` compares two `DateTime` objects without normalising to the same timezone.

Example: a UTC `DateTime(2026, 5, 10, 23, 0, 0)` represents May 11 in a timezone with a positive offset, but would be compared as May 10.

### Fix
Normalise both sides to UTC (or local) before comparison, or document that callers must pass timezone-consistent values. Use `DateTime.utc` constructors or `.toLocal()` / `.toUtc()`.

---

## 4. Code Duplication: `_formatDuration` exists in 4 places with different implementations

| Field | Value |
|-------|-------|
| **Files** | `lib/core/utils/time_utils.dart:1` · `lib/features/subjects/presentation/subject_detail_view.dart:718` · `lib/features/sessions/widgets/session_analytics.dart:197` · `lib/features/settings/presentation/settings_screen.dart:227` |
| **Lines** | 4 distinct implementations |
| **Severity** | **Code Duplication** |

### Description
The same logic (formatting a time span as a human-readable string) is implemented **four separate times** with subtle behavioural differences:

| Variant | Hours | Minutes | Seconds | Days |
|---------|-------|---------|---------|------|
| `time_utils.dart` | `1h 2m 3s` | `2m 3s` | `3s` | — |
| `subject_detail_view.dart` | `1h ` | `2m ` | `3s` | — |
| `session_analytics.dart` | `1h 2m` | `2m 3s` | `3s` | — |
| `settings_screen.dart` | `2 hr 3 min` | `3 min 4 sec` | `4 sec` | `1 day, 2 hr 3 min` |

This means **different screens in the same app show durations in different formats**, causing inconsistency and confusion.

### Fix
Delete the 3 private duplicates and have every consumer import and use the canonical `formatDuration` from `time_utils.dart`. If the settings screen needs days support, add a `bool showDays = false` parameter (or create a separate `formatDurationVerbose`).

---

## 5. Code Duplication: `_formatDate` in `subject_detail_view.dart`

| Field | Value |
|-------|-------|
| **File** | `lib/features/subjects/presentation/subject_detail_view.dart` |
| **Lines** | 714–716 |
| **Severity** | **Code Duplication** |

### Description
The private `_formatDate` in `subject_detail_view.dart` outputs `DD/MM/YYYY HH:MM` while the canonical `formatDate` in `time_utils.dart` outputs relative labels (`Today`, `Yesterday`) or `DD/MM/YYYY`. The private version should be replaced with the canonical one (or the canonical one should offer an optional time-inclusion flag).

### Fix
Either inline `formatDate` with a time-formatting addition or extend the canonical `formatDate` with parameters. Remove the private copy.

---

## 6. Missed reuse: `formatDate` does not call `isSameDay`

| Field | Value |
|-------|-------|
| **File** | `lib/core/utils/time_utils.dart` |
| **Lines** | 18–20 |
| **Severity** | **Enhancement / Maintainability** |

### Description
The same-day check in `formatDate` (lines 18–20) duplicates the logic already extracted into `isSameDay` (line 29):
```dart
if (sessionDate.year == today.year &&
    sessionDate.month == today.month &&
    sessionDate.day == today.day) {
```

### Fix
```dart
if (isSameDay(sessionDate, today)) return 'Today';
```

---

## 7. No barrel export for `lib/core/utils`

| Field | Value |
|-------|-------|
| **File** | `lib/core/utils/` (directory) |
| **Severity** | **Code Style / Maintainability** |

### Description
There is no barrel file (`utils.dart`) that re-exports the contents. Each consumer must import the exact path:
```dart
import 'package:studyking/core/utils/time_utils.dart';
```

### Fix
Create `lib/core/utils/utils.dart`:
```dart
export 'time_utils.dart';
```
Then consumers import `package:studyking/core/utils/utils.dart`.

---

## 8. `intl` dependency available but unused

| Field | Value |
|-------|-------|
| **File** | `pubspec.yaml:36` · `lib/core/utils/time_utils.dart` |
| **Severity** | **Enhancement** |

### Description
The project already depends on `intl: ^0.18.0` (used for date formatting), but `time_utils.dart` implements date and duration formatting manually. This reinvents the wheel and introduces bugs (see items #1, #3).

### Fix
Replace manual formatting with `intl`:
- `DateFormat.yMd().format(date)` / `DateFormat.yMMMd().format(date)` for dates
- `DateFormat('HH:mm').format(date)` for time components
- Relative formatting can leverage `intl`'s `RelativeDateTime` (available in newer versions of `intl`), or manual logic with proper locale support.

---

## 9. No documentation comments on any function

| Field | Value |
|-------|-------|
| **File** | `lib/core/utils/time_utils.dart` |
| **Lines** | 1, 14, 29 |
| **Severity** | **Code Style / Maintainability** |

### Description
None of the three top-level functions (`formatDuration`, `formatDate`, `isSameDay`) have Dartdoc comments explaining:
- Expected input ranges / edge cases (negative durations, null, timezone)
- Return value format
- Example usage

### Fix
Add `///` doc comments:
```dart
/// Formats a [Duration] as a human-readable string (e.g. "1h 2m 3s").
/// Negative durations are returned as their absolute value.
String formatDuration(Duration duration) { ... }
```

---

## 10. `isSameDay` could be an extension on `DateTime`

| Field | Value |
|-------|-------|
| **File** | `lib/core/utils/time_utils.dart` |
| **Lines** | 29–31 |
| **Severity** | **Enhancement** |

### Description
`isSameDay` is a top-level function, which results in verbose call-site syntax:
```dart
isSameDay(s.startTime, _selectedDate!)
```
An extension method would read more naturally:
```dart
s.startTime.isSameDay(_selectedDate!)
```

### Fix
```dart
extension DateTimeX on DateTime {
  bool isSameDay(DateTime other) =>
    year == other.year && month == other.month && day == other.day;
}
```

---

## 11. `formatDuration` does not handle durations ≥ 24 hours

| Field | Value |
|-------|-------|
| **File** | `lib/core/utils/time_utils.dart` |
| **Lines** | 1–12 |
| **Severity** | **Enhancement** |

### Description
A duration of 25 hours is displayed as `"25h 0m 0s"`. For study tracking it may be preferable to show `"1d 1h 0m 0s"` or similar. The `settings_screen.dart` duplicate already implements this with a `days` component.

### Fix
```dart
String formatDuration(Duration duration, {bool showDays = false}) {
  if (showDays) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    // ...
  }
  // ...
}
```

---

## 12. `formatDuration` hides seconds when `hours > 0` but minutes are always shown

| Field | Value |
|-------|-------|
| **File** | `lib/core/utils/time_utils.dart` |
| **Line** | 6 |
| **Severity** | **Enhancement** |

### Description
When `hours > 0`, seconds are shown (`1h 2m 3s`). When `hours == 0 && minutes > 0`, seconds are shown (`2m 3s`). When only seconds, it shows `3s`. This is **inconsistent**: the hours branch includes seconds opportunistically but the design choice is not obvious. Consider always showing all components or providing a configurable granularity.

---

## 13. `formatDate` does not handle `null` / nullable `DateTime`

| Field | Value |
|-------|-------|
| **File** | `lib/core/utils/time_utils.dart` |
| **Line** | 14 |
| **Severity** | **Enhancement** |

### Description
Callers sometimes fallback to `DateTime.now()` when the real value is null:
```dart
formatDate(session.startTime ?? DateTime.now())
```
The function itself is typed as `DateTime` (non-nullable), so it already prevents passing null. However, there is no `DateTime?` convenience overload that returns a fallback string (`"Unknown"`).

---

## 14. `formatDate` shows `DD/MM/YYYY` format without locale awareness

| Field | Value |
|-------|-------|
| **File** | `lib/core/utils/time_utils.dart` |
| **Line** | 25 |
| **Severity** | **Enhancement** |

### Description
The hard-coded format `'${date.day}/${date.month}/${date.year}'` uses DD/MM/YYYY, which is not the standard in all locales (e.g. US uses MM/DD/YYYY, many Asian locales use YYYY/MM/DD). The `intl` package (already a dependency) provides locale-aware formatting.

### Fix
```dart
import 'package:intl/intl.dart';
return DateFormat.yMd().format(date);
```

---

## 15. Unused `vector_math` import or outdated dependencies

| Field | Value |
|-------|-------|
| **File** | `pubspec.yaml:13` |
| **Severity** | **Low / Maintainability** |

### Description
While not in `time_utils.dart`, the `vector_math: ^2.2.0` dependency is listed at the top of `pubspec.yaml` without appearing in any Dart import across the project (it's an implicit Flutter dependency). Having it listed explicitly as a first-party dependency may cause confusion.

*(Minor — not critical to fix.)*

---

## 16. Only 2 of 5 util consumers actually import `time_utils.dart`

| File | Uses canon `time_utils.dart`? |
|------|------------------------------|
| `session_history_screen.dart` | ✅ Yes |
| `session_tracker_screen.dart` | ✅ Yes |
| `subject_detail_view.dart` | ❌ No (private `_formatDuration`/`_formatDate`) |
| `session_analytics.dart` | ❌ No (private `_formatDuration`) |
| `settings_screen.dart` | ❌ No (private `_formatDuration(int ms)`) |

### Description
Three files have private duplicates instead of importing the canonical functions. This prevents the codebase from benefiting from central bug fixes and creates inconsistent UI behaviour.

### Fix
As described in items #4 and #5: remove private copies and use `package:studyking/core/utils/time_utils.dart`.

---

## Priority Action Items

| Priority | Issue | Est. Effort |
|----------|-------|-------------|
| 🔴 P0 | #1 "Yesterday" matches "Tomorrow" | 5 min |
| 🔴 P0 | #2 Negative duration formatting | 5 min |
| 🟠 P1 | #4 Code duplication (4x `_formatDuration`) | 30 min |
| 🟠 P1 | #5 Code duplication (`_formatDate`) | 10 min |
| 🟡 P2 | #3 Timezone-aware comparison | 15 min |
| 🟡 P2 | #6 Reuse `isSameDay` in `formatDate` | 2 min |
| 🟡 P2 | #7 Barrel export | 5 min |
| 🟢 P3 | #8 Use `intl` package | 20 min |
| 🟢 P3 | #9 Documentation comments | 10 min |
| 🟢 P3 | #10 Extension method on DateTime | 5 min |
