# Internationalisation Master — Residual i18n Issues

**Created**: 2026-05-18
**Target Locale**: Spanish (`es`) — formal "usted" register, neutral Latin American
**Scope**: Full codebase residual sweep — `lib/`, `lib/l10n/`
**Severity Levels**: CRITICAL / MAJOR / MINOR

---

## CRITICAL

### C-1: Duplicate JSON keys in `app_en.arb` (data-integrity risk)

Three keys appear twice in the English ARB file. JSON parsers silently overwrite the first occurrence with the second, so one `@description` annotation is orphaned per duplicate.

| Duplicate Key | First Occurrence | Second Occurrence | Impact |
|---|---|---|---|
| `today` | L114 (desc: "Label for today's date") | L3496 (no `@today` metadata follows it; the `@timerPaused` annotation is at L3497) | `@today` metadata is silently dropped |
| `summary` | L4326 (desc: "Section title for summary card on dashboard") | L5658 (desc: "Section header for summary") | Second copy overwrites first |
| `questionBank` | L5346 (desc: "Tile title for question bank") | L5447 (desc: "Title for the question bank screen") | Second copy overwrites first |

**Affected file**: `lib/l10n/app_en.arb:114,3496,4326,5658,5346,5447`

**Rationale**: While both `summary` and `questionBank` duplicates happen to have the same English value, the Spanish file may need to differentiate between "tile title" vs "screen title" or "section header" vs "card title". Currently, only the second `@description` is retained — the first is silently discarded. The `today` duplicate is the worst: the `@today` annotation at L115–117 is orphaned because the parser only sees the second `today` at L3496.

**Acceptance criteria**:
- Remove the duplicate `today` at L3496. Move or merge its surrounding lines if needed so that `@timerPaused` correctly follows its `timerPaused` key.
- Rename the duplicate `summary` keys to differentiate them, e.g. `summarySection` (section header) and `summaryCard` (dashboard card title). Or keep one and ensure both call sites use the same ARB key.
- Rename the duplicate `questionBank` keys to e.g. `questionBankTile` (dashboard tile) and `questionBankScreen` (screen title). Or keep one.
- Verify that both EN and ES files have matching key sets after deduplication.

---

## MAJOR

### M-1: Enum `.name` displayed to users instead of localized labels

Four screens pass Dart enum `.name` directly to `Text()` widgets. `.name` returns the source-code identifier (always English), bypassing `AppLocalizations`.

| File | Line | Code | Enum Type |
|---|---|---|---|
| `lib/features/ingestion/presentation/source_detail_screen.dart` | 298 | `value: status.name` | `ProcessingStatus` |
| `lib/features/ingestion/presentation/source_detail_screen.dart` | 301 | `value: source.type.name` | `SourceType` |
| `lib/features/ingestion/presentation/content_library_screen.dart` | 427–431 | `Text(t.name)` in type-filter bottom sheet | `SourceType` |
| `lib/features/ingestion/presentation/content_library_screen.dart` | 454–458 | `Text(s.name)` in status-filter bottom sheet | `ProcessingStatus` |
| `lib/features/questions/presentation/question_bank_screen.dart` | 508–510 | `Text(t.name)` in type-filter bottom sheet | `QuestionType` |
| `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart` | 243 | `task.status.name` | `LlmTaskStatus` (or similar) |

**Rationale**: A Spanish user sees enum identifiers like `"singleChoice"`, `"pending"`, `"failed"`, `"completed"` instead of translated labels. The codebase already has helper functions (`_questionTypeLabel`, `_statusLabel`) that produce localized strings, but they are not consistently used. There's also a second-order problem: the `_typeFilter` / `_statusFilter` strings are stored as enum `.name` values and compared against the same for filtering, so the entire filter pipeline uses English identifiers.

**Acceptance criteria**:
- `source_detail_screen.dart:298`: Replace `status.name` with `l10n.processingStatusLabel(status)` (create a mapping or switch; reuse existing `ProcessingStatus`→ ARB key logic from `content_library_screen.dart:_statusLabel`).
- `source_detail_screen.dart:301`: Replace `source.type.name` with a `_sourceTypeLabel(type, l10n)` mapper that returns localized strings.
- `content_library_screen.dart:427–431, 454–458`: Replace `t.name` / `s.name` in filter bottom sheets with localized labels. Update filter-comparison logic to compare against a stable identifier (e.g. `SourceType.values.index`) instead of the display string.
- `question_bank_screen.dart:508–510`: Replace `t.name` with `_questionTypeLabel(t, l10n)` (already exists at L542). Update filter-comparison logic similarly.
- `llm_task_manager_screen.dart:243`: Replace `task.status.name` with a localized status label via a switch/map on the task-status enum type.

---

### M-2: `question_bank_screen.dart` type-type filter uses raw enum name despite having a localizer

**File**: `lib/features/questions/presentation/question_bank_screen.dart:508`

```dart
...QuestionType.values.map((t) => ListTile(
  title: Text(t.name),   // <-- shows "singleChoice" instead of "Multiple Choice"
  trailing: _typeFilter == t.name ? ...  // <-- filter stores enum identifier
  ...
))
```

The file already defines `_questionTypeLabel(QuestionType type, AppLocalizations l10n)` at L542 that returns localized strings (e.g. `l10n.multipleChoice` for `QuestionType.singleChoice`). The filter bottom sheet at L507–511 ignores it and uses `t.name` directly.

**Acceptance criteria**: Same as M-1 resolution for `question_bank_screen.dart`. Additionally verify that filtering still works after switching to a non-English identifier by using the enum index or string name as the stable filter key while displaying the localized label.

---

### M-3: `notification_service.dart` English fallbacks create permanent Android channel names

**File**: `lib/core/services/notification_service.dart:55–98`

The `_createNotificationChannels()` method uses `??` fallbacks for all 8 Android notification channels:

```dart
l10n?.notifChannelGeneral ?? 'StudyKing Notifications',
l10n?.notifChannelGeneralDesc ?? 'General StudyKing notifications',
// ...7 more identical patterns
```

**Rationale**: Android notification channels are created once — the name and description are set permanently on first creation. If `setAppLocalizations()` has not been called before `init()` (which calls `_createNotificationChannels()`), `_l10n` is `null`, and the channels are created with English names that can never be updated. The same issue applies to `showNotification()` channel name lookups which also use `??` fallbacks.

**Acceptance criteria**:
- Ensure `setAppLocalizations()` is called before `init()` in the app startup sequence. Verify in `main.dart`.
- Consider `assert(_l10n != null, 'must call setAppLocalizations before init')` at the start of `_createNotificationChannels()`.
- Document the init-order requirement in `docs/i18n.md`.

---

### M-4: `answer_validation_service.dart` fallback methods return English

**File**: `lib/core/services/answer_validation_service.dart:248–275`

Six instance methods check `_l10n != null` and return English if null:

```dart
String someAnswersIncorrect(String explanation) {
  if (_l10n != null) return _l10n.someAnswersIncorrect;
  return explanation.isNotEmpty ? explanation : 'Some answers are incorrect';
}
String correctAnswerIs(String answer) {
  if (_l10n != null) return _l10n.correctAnswerIs(answer);
  return 'The correct answer is: $answer';
}
// ... allStepsFormat, partialStepsFormat, noStepsFormat, allRequiredStepsMissing
```

**Rationale**: The `ValidationMessages.english` static at L182 is used as a default in services that don't hold a reference to `AppLocalizations`. When the service hasn't been initialized with localized messages, students see English feedback on their answers. This is a user-facing bug.

**Acceptance criteria**:
- Trace all call sites where `ValidationMessages.english` is used and verify `ValidationMessages.fromLocalizations(l10n)` is passed instead.
- If any service path can legitimately operate without l10n, add an `assert()` or log warning.
- Add a test that verifies `fromLocalizations` is properly wired in all production providers.

---

### M-5: `source_detail_screen.dart` exception strings shown to user

**File**: `lib/features/ingestion/presentation/source_detail_screen.dart:109,239`

```dart
// Line 109:
if (mounted) setState(() { _error = e.toString(); _isLoading = false; });

// Line 239:
Text(_error ?? l10n.sourceNotFound, ...),
```

**Rationale**: `e.toString()` renders the Dart exception type and message in English. When `_load()` fails, `_error` is set to a raw English exception string and displayed directly in the error state. This bypasses all locale support.

**Acceptance criteria**:
- Replace `e.toString()` with a localized fallback such as `l10n.errorLoadingSource`.
- Log the original exception to `dart:developer` for debugging.

---

### M-6: Content library filter values mix internal keys and display labels

**File**: `lib/features/ingestion/presentation/content_library_screen.dart:144,159,352,427–431,454–458`

The `_typeFilter` and `_statusFilter` strings are:
- Stored as `SourceType.name` (English enum identifier)
- Compared against `s.type.name` for filtering (L144)
- Displayed directly in the filter chip label (L352): `Text(t.name)` falls back to "allStatuses" → displays the stored string when a specific filter is active

**Rationale**: This means when a user selects "PDF" (enum name), the chip shows "pdf" (or whatever the identifier is). The same enum-name-instead-of-label problem as M-1, but with additional coupling between storage and display.

**Acceptance criteria**: Same as M-1 resolution for `content_library_screen.dart`. Store filter state using the enum value/index; display using localized labels.

---

### M-7: RTL-unsafe hardcoded positions (3 widgets)

| File | Line | Code | Issue |
|---|---|---|---|
| `lib/features/ingestion/presentation/content_library_screen.dart` | 497 | `alignment: Alignment.centerRight` | In RTL, swipe-to-delete icon stays on visual right instead of start |
| `lib/features/practice/presentation/widgets/practice_mode_card.dart` | 79 | `Positioned(right: 8, top: 8, ...)` | Count/status badge pinned to visual right; RTL should be left |
| `lib/features/questions/presentation/widgets/canvas_drawing_widget.dart` | 94 | `Positioned(right: 8, top: 8, ...)` | Undo/clear toolbar buttons pinned to visual right; RTL should be left |

**Rationale**: While the project currently only supports LTR languages (en, es), these are tech debt for future RTL support (Arabic, Hebrew). They create a "works for me" trap where RTL support requires a full re-audit.

**Acceptance criteria**:
- `content_library_screen.dart:497`: Replace `Alignment.centerRight` with `AlignmentDirectional.centerEnd`.
- `practice_mode_card.dart:79`: Replace `Positioned(right: 8)` with `Positioned.directional(textDirection: Directionality.of(context), end: 8, top: 8)`.
- `canvas_drawing_widget.dart:94`: Replace `Positioned(right: 8)` with `Positioned.directional(textDirection: Directionality.of(context), end: 8, top: 8)`.

---

### M-8: Fixed-width MetricCards may clip translated labels

**File**: `lib/features/focus_mode/presentation/widgets/session_summary_card.dart:59,68,77`

```dart
width: narrow ? (constraints.maxWidth - 12) / 2 : 140,
```

Three `MetricCard` widgets with hardcoded `140px` width (or half-width on narrow screens). Labels like "Sessions" / "Sesiones" or "Today" / "Hoy" are short enough, but the "Focus Time" / "Tiempo de enfoque" or German compound words like "Sitzungsdauer" could be clipped. The card layout doesn't use `Flexible` or `Expanded`.

**Acceptance criteria**:
- Remove the fixed `140px` width constraint.
- Allow the parent `Wrap` to distribute space naturally.
- Add `Flexible` or `ConstrainedBox` with `minWidth` instead of fixed width.

---

## MINOR

### m-1: `time_utils.dart` English fallback strings

**File**: `lib/core/utils/time_utils.dart:62,68,72`

```dart
final unknown = l10n?.unknown ?? 'Unknown';   // L62
return l10n?.today ?? 'Today';                // L68
return l10n?.yesterday ?? 'Yesterday';         // L72
```

**Rationale**: In normal operation `l10n` is never null because `formatDateFromContext` (the main entry point) always passes an `AppLocalizations` instance. However, `formatDate()` is a public API and could be called from contexts where `l10n` is null (e.g. tests, or during app initialization before the widget tree is built).

**Acceptance criteria**:
- Keep the fallbacks (defensive programming) but add a test in `test/core/utils/time_utils_test.dart` that verifies the context-bearing wrappers (`formatDateFromContext`, `formatDurationFromContext`) never trigger the fallback path.
- Consider marking `formatDate()` as `@visibleForTesting` or adding a `@required`-style lint.

---

### m-2: `practice_mode_card.dart` and `roadmap_card.dart` restrictive `maxLines`

| File | Line | Constraint |
|---|---|---|
| `lib/features/practice/presentation/widgets/practice_mode_card.dart` | 60–61, 70–71 | `maxLines: 2, overflow: TextOverflow.ellipsis` |
| `lib/features/planner/presentation/widgets/roadmap_card.dart` | 72–73 | `maxLines: 2, overflow: TextOverflow.ellipsis` |

**Rationale**: Spanish translations are on average 20–30% longer than English. A 2-line constraint may truncate otherwise visible content. German compound words are even longer. These cards already use `Expanded`/`Flexible`, so removing or increasing the line limit should not break layouts.

**Acceptance criteria**:
- Increase `maxLines` to 3 or remove the constraint entirely.
- Verify the layout still fits within cards (the `Expanded` parent should prevent unbounded growth).

---

### m-3: `calendar_view_widget.dart` day label `maxLines: 1`

**File**: `lib/features/planner/presentation/widgets/calendar_view_widget.dart:138`

```dart
maxLines: 1,
overflow: TextOverflow.ellipsis,
```

**Rationale**: Day abbreviations in most locales are 1–4 characters, but if the widget is eventually used with longer locale day names (e.g. `DateFormat.E()` in some locales), single-line truncation may hide the label entirely. Low risk.

**Acceptance criteria**: Change to `maxLines: 2` or verify that all supported and planned locales produce abbreviations short enough for the cell width.

---

### m-4: `main.dart` does not guard notification-service init order

**File**: `lib/main.dart` (notification service initialization and `setAppLocalizations` call order)

**Rationale**: M-3 (notification_service English fallbacks) requires that `setAppLocalizations` is called before `init()`. If someone reorders the startup sequence, the fallback path silently creates English channels. There is no assert or documentation enforcing this order.

**Acceptance criteria**: Add an `assert` in `notification_service.dart:_createNotificationChannels()`:
```dart
assert(_l10n != null, 'setAppLocalizations must be called before init');
```

---

### m-5: `formatCompactNumber` fallback was fixed but the test coverage is weak

**File**: `lib/core/utils/number_format_utils.dart` (the `< 1000` path now uses `NumberFormat.decimalPattern(localeName)`)

**Context**: The completed issue MAJOR-10 was fixed — `value.toString()` was replaced with `NumberFormat.decimalPattern(localeName).format(value)`. However, the test file (`test/core/utils/number_format_utils_test.dart`) should explicitly cover:
- The `< 1000` code path (decimal pattern, e.g. `formatCompactNumber(999, 'es')` → `"999"`)
- The `>= 1000` code path (compact pattern, e.g. `formatCompactNumber(1500, 'es')` → `"1,5 mil"` for `es`)

**Acceptance criteria**: Add test cases covering all three branches of `formatCompactNumber`.

---

### m-6: `source_detail_screen.dart` line 298 shows `status.name` for `ProcessingStatus`

(Already covered in M-1, listed here as a cross-reference for completeness.)

---

## Summary of Issues by Type

| Severity | Count | Key Areas |
|---|---|---|
| CRITICAL | 1 | ARB duplicate keys (`today`, `summary`, `questionBank`) |
| MAJOR | 8 | Enum `.name` displayed (5 files), notification fallbacks, answer-validation fallbacks, exception strings shown, filter value/label coupling, 3 RTL-unsafe positions, fixed-width cards |
| MINOR | 5 | `time_utils` English fallbacks, restrictive `maxLines`, calendar day truncation, init-order guard missing, compact-number test gaps |

## Key Technical Debt Items

1. **Android notification channels are permanent** — once created with English names, locale switching won't update them. The only fix is a `forceCreate` or reinstallation. Mitigation: ensure `setAppLocalizations` always fires before `init`.
2. **Enum-to-localized-label pattern not centralized** — 4 different files have ad-hoc switch statements for `QuestionType`, `ProcessingStatus`, `SourceType`, and `LlmTaskStatus`. Consider a single `source_type_localizer.dart`, `processing_status_localizer.dart`, etc. (pattern: `question_type_localizer.dart` already exists).
3. **Filter model uses display strings as keys** — `_typeFilter`, `_statusFilter` are `String` fields compared against `.name`. Changing the display label (e.g. from `"pdf"` to `"PDF"`) would silently break filtering. Should use enum values or stable keys.
