# UI/UX Master — Comprehensive Issue Report

**Date:** 2026-05-20
**Scope:** Full codebase exploration — 15 feature modules, core widgets, theme, routing, accessibility, i18n
**Method:** Screen-by-screen tracing of navigation flows, state-gap analysis (loading/empty/error), accessibility audit, design consistency review

---

## BLOCKER — App crashes or user cannot proceed

### B-1: `ErrorBoundary` is a non-functional placebo; retry on `_AppErrorWidget` is broken

**Context:** `lib/core/utils/error_boundary.dart` — `ErrorBoundary` widget (line 4) and `_AppErrorWidget` (line 34)

**Issue:**
- `ErrorBoundary` is a `StatelessWidget` that returns `Builder(_ => child)`. Despite the name suggesting error-catching behavior (like React Error Boundaries or Flutter's `ErrorWidget.builder`), it does **nothing** — no `FlutterError.onError`, no `ErrorWidget.builder`, no `Zone` wrapper. It is a pure pass-through. Any developer importing `ErrorBoundary` believing errors are contained is misled.
- The `_AppErrorWidget` (shown when `ErrorWidget.builder` fires) has a "Retry" button that calls `setState(() {})`. This merely rebuilds the **same** error screen with the **same** `FlutterErrorDetails`. There is no mechanism to clear the error or re-execute the failed operation. The button is deceptive.

**Rationale:** Both components give false confidence. `ErrorBoundary` appears to catch errors but does not — developers may rely on it for resilience. The retry button suggests recoverability but never succeeds.

**Acceptance criteria (fixed):**
- `ErrorBoundary` wraps children in a `FlutterError.onError` / `Zone` boundary that actually catches build-phase errors and renders a fallback UI.
- `_AppErrorWidget`'s retry button either: (a) rebuilds the failed widget subtree, or (b) is removed if recovery is impossible.
- Tests assert that `ErrorBoundary` catches and does not crash on a throwing child.

---

### B-2: Memory leaks — `TextEditingController`s never disposed (upload_screen, question_bank_screen)

**Context:**
- `lib/features/ingestion/presentation/upload_screen.dart` — three `TextEditingController`s (`_titleController`, `_contentController`, `_urlController`) at lines 40–42, no `dispose()` override exists.
- `lib/features/questions/presentation/question_bank_screen.dart` — `_editQuestion` dialog (line ~226) and `_showCreateQuestionDialog` (line ~286) create controllers that are only disposed on explicit "remove" action, not when the dialog is dismissed via back button or tap-outside.

**Rationale:** Each undiposed controller leaks a `TextEditingController` + listener. Over time, repeated dialog opens cause progressive memory growth.

**Acceptance criteria (fixed):**
- `UploadScreenState.dispose()` disposes all three controllers.
- Edit/create question dialogs dispose their controllers in a `State.dispose()` override (use a StatefulWidget for the dialog body, or add a `DisposeBag` pattern).
- Leak detection passes when running with `leak_tracker_flutter_testing`.

---

### B-3: Raw exception messages shown to users (`e.toString()` in snackbars)

**Context:** `lib/features/sessions/presentation/session_history_screen.dart` — lines 183 and 290

```dart
// Line 183
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: ${e.toString()}')));

// Line 290
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: ${e.toString()}')));
```

**Rationale:** Shows internal exception details (stack traces, type names, possibly sensitive data) directly to the user. Violates security best practices and creates a poor UX ("what is _TypeError?...").

**Acceptance criteria (fixed):**
- Replace `e.toString()` with user-friendly localized messages (e.g., `l10n.exportFailed` / `l10n.deleteFailed`).
- Log the technical error to the logger; display only a human-readable summary.

---

### B-4: `showConfirmationDialog` always shows English Cancel/Confirm regardless of locale

**Context:** `lib/core/widgets/dialog_utils.dart` — lines 18, 22

```dart
child: Text(cancelLabel ?? 'Cancel'),   // line 18
child: Text(confirmLabel ?? 'Confirm'), // line 22
```

**Rationale:** This utility is used across features for confirmation dialogs. The hardcoded English fallback violates the AGENTS.md l10n null-coalesce pattern ("confirm/cancel labels use `l10n?.key ?? 'English fallback'`"). Non-English users always see "Cancel"/"Confirm".

**Acceptance criteria (fixed):**
- Accept optional `AppLocalizations` or read from context: `AppLocalizations.of(context)?.cancel ?? 'Cancel'`.
- All existing callers continue to work (they already pass their own labels, but the fallback should be localized).

---

## MAJOR — Feature is broken or misleading

### M-1: Hardcoded English strings in 5+ screens bypassing l10n

**Affected files and locations:**

| File | Line | Hardcoded string |
|---|---|---|
| `lib/features/dashboard/presentation/widgets/mastery_progress_card.dart` | 67 | `'Last updated $daysSinceUpdate days ago'` |
| `lib/features/practice/presentation/screens/exam_session_screen.dart` | 599–600 | `'Questions will be randomly distributed by difficulty'` |
| `lib/features/practice/presentation/screens/exam_session_screen.dart` | 611–612 | `'Remaining: ...'` |
| `lib/features/dashboard/presentation/widgets/topic_breakdown_card.dart` | 191–196 | Mastery level fallback labels (`'Novice'`, `'Browsing'`, etc.) |
| `lib/features/settings/presentation/api_config_screen.dart` | 517–525, 641–652 | Provider names `'OpenRouter'`, `'Ollama'`, `'OpenAI'` |
| `lib/features/sessions/presentation/session_history_screen.dart` | 411 | `'0m'` |

**Note on provider names:** While "OpenAI" is a proper noun and arguably locale-independent, "OpenRouter" and "Ollama" could have localized descriptions. At minimum, these should be in l10n for consistency.

**Acceptance criteria (fixed):**
- Every user-facing string uses an `AppLocalizations` key.
- Provider names have l10n entries (even if they mirror the English text) for consistency.
- The `topic_breakdown_card` mastery fallback uses `l10n?.key ?? 'English'` pattern per AGENTS.md.

---

### M-2: `.normalized` misuse on display strings (capitalization corruption)

**Affected files:**
- `lib/features/dashboard/presentation/widgets/due_reviews_card.dart:44` — `l10n.dueForReview.normalized`
- `lib/features/dashboard/presentation/widgets/weekly_chart.dart:55` — `l10n.sessionsLabel.normalized`

**Issue:** The `.normalized` extension (from `lib/core/utils/string_extensions.dart`) calls `.trim().toLowerCase()`, intended for **comparison** not **display**. Calling it on an l10n string lowercases the label. For English labels this produces `"due for review"` instead of `"Due for Review"`; for proper nouns or capitalized words in other locales, the corruption is worse.

**Rationale:** Per AGENTS.md convention: "Use the `.normalized` extension... instead of `.trim().toLowerCase()`...". That instruction is for **string matching/normalization**, not for display rendering.

**Acceptance criteria (fixed):**
- Remove `.normalized` from all display strings.
- Revert to the raw l10n value.

---

### M-3: Dual interactive controls on `CollapsibleCard` — confusing for screen readers

**Context:** `lib/features/dashboard/presentation/widgets/collapsible_card.dart:84–111`

**Issue:** Both the card title row (wrapped in `Semantics(button: true, expanded:...)` with `InkWell`) AND a separate `IconButton` (with its own `Semantics`) toggle the collapse state. Screen reader users encounter two controls that do the same thing, creating confusion and excessive navigation steps.

**Rationale:** WCAG Success Criterion 2.5.3 (Label in Name) and 4.1.2 (Name, Role, Value) — redundant controls should be merged into a single accessible element.

**Acceptance criteria (fixed):**
- Remove the `Semantics(button: true)` from the title row's `InkWell`, OR remove the `IconButton`.
- The remaining control has a clear `Semantics(label: l10n.expandCollapse(name), expanded: _isExpanded, button: true)`.

---

### M-4: Exam session dead-end — "Mistake Review" has no practice-again action

**Context:** `lib/features/practice/presentation/screens/exam_session_screen.dart:892–903`

**Issue:** After an exam session completes, the "Done" button calls `Navigator.popUntil((route) => route.isFirst)` — popping to root (unexpected, user loses context). The "Practice Again" flow only calls `_showMistakeReview` (a dialog), then pops to root. There is no navigation to a **new** practice session with the same parameters.

**Rationale:** Users completing an exam naturally want to review mistakes AND start another session. Currently they must manually navigate back through tabs.

**Acceptance criteria (fixed):**
- After review, offer a "Start New Session" button that pushes a new `examSession` route with the same subject/topic/configuration.
- The "Done" pop uses a more targeted pop (pop to the originating screen, not all the way to root) when possible.

---

### M-5: Profile/account deletion leaves user on a blank / orphaned screen

**Context:** `lib/features/settings/presentation/profile_screen.dart:545–571`

**Issue:** `_showDeleteConfirmation` calls `clearProfile()` then `Navigator.maybePop(context)`. If `maybePop` fails (no previous route), the user remains on a screen that expects profile data — causing null errors or a blank UI. There is no confirmation toast or redirect.

**Rationale:** Destructive action with no post-execution safety net. User has no feedback that deletion succeeded and no clear next step.

**Acceptance criteria (fixed):**
- After deletion, navigate to a safe screen (dashboard or onboarding) regardless of navigation stack state.
- Show a confirmation snackbar: `l10n.profileDeleted`.
- Handle `maybePop` failure with fallback navigation.

---

### M-6: Mentor screen deep-nav `pop()` assumes modal presentation

**Context:** `lib/features/mentor/presentation/mentor_screen.dart:1050–1067`

**Issue:** `_showProgressReport` calls `Navigator.of(context).pop()` before showing a dialog. This assumes the mentor screen was presented modally. If the user navigated to mentor via a pushed route (e.g., from a notification or deep link), `pop()` unexpectedly navigates backward instead of just dismissing a sheet.

**Rationale:** Navigation should be context-aware. Calling `pop()` without checking the route stack can cause unpredictable navigation.

**Acceptance criteria (fixed):**
- Remove the unconditional `pop()` before `showDialog`, or check `Navigator.of(context).canPop()` first.
- Use `showDialog` (which stacks a dialog on the current route) without pre-popping.

---

### M-7: Responsive breakage — fixed 100px label width too narrow for long translations

**Context:** `lib/features/practice/presentation/screens/review_answers_screen.dart:130–131`

```dart
SizedBox(width: 100, child: Text(label, ...))
```

**Issue:** The label column has a fixed 100px width. In German, French, or Spanish locales, translations like "Deine Antwort" (Your Answer) or "Réponse correcte" (Correct Answer) are longer and will overflow or truncate.

**Rationale:** Fixed pixel widths for text labels are a known l10n anti-pattern. Even within English, accessibility font scaling (up to 200%) will cause overflow.

**Acceptance criteria (fixed):**
- Replace `SizedBox(width: 100)` with `IntrinsicWidth` or a flexible layout (e.g., `Row` with cross-axis alignment and flexible space distribution).
- Test with longest-known translation and 200% font scale.

---

### M-8: Question bank search has no debounce — excessive rebuilds

**Context:** `lib/features/questions/presentation/question_bank_screen.dart:70–72`

```dart
_searchController.addListener(() {
  setState(() => _searchQuery = _searchController.text);
});
```

**Issue:** Every keystroke triggers `setState` and rebuilds the question list. For large question banks (500+), this causes a noticeable UI jank. No debounce or throttling.

**Rationale:** Standard UX pattern: search inputs should debounce by 300–500ms to batch rapid keystrokes into a single query.

**Acceptance criteria (fixed):**
- Add a debounce timer (300ms) that delays `setState` until the user stops typing.
- Show a subtle "searching..." indicator if query execution is async.
- Cancel the timer on `dispose`.

---

### M-9: Missing loading/empty/error states on dashboard sub-widgets

**Affected widgets (all in `lib/features/dashboard/presentation/widgets/`):**

| Widget | Missing state(s) |
|---|---|
| `next_up_card.dart` | Loading (silently shows 0 if provider is loading), Error (no retry) |
| `summary_row.dart` | Loading (defaults to empty `OverallStats()`), Error |
| `topic_breakdown_card.dart` | Loading, Error |
| `weak_areas_card.dart` | Loading, Error |
| `mastery_progress_card.dart` | Loading (defaults to zero-valued `MasterySnapshot()`), Error |
| `workload_card.dart` | Loading, Error |
| `badges_card.dart` | Loading, Error |
| `weekly_chart.dart` | Loading, Error |

Note: The parent `dashboard_screen.dart` does show skeleton shimmer during loading and `ErrorRetryWidget` per-card for errors. However, the individual widgets themselves have no inline state handling — if a provider returns `AsyncLoading` or `AsyncError`, the widget silently shows its empty/null fallback. This means transient loading states and persistent errors (after retry) are indistinguishable from empty-data states.

**Rationale:** A user seeing "0 sessions" during loading believes they have no data. Similarly, an error state silently showing "no weak areas" is misleading.

**Acceptance criteria (fixed):**
- Each widget accepts `AsyncValue<T>` or explicit `isLoading`/`hasError` parameters.
- During loading: show a small shimmer/skeleton matching the widget's layout.
- During error: show a compact inline error message with retry.
- Only show the empty-state UI when data is genuinely empty (not loading, not error).

---

### M-10: Inconsistent skeleton/loading patterns across the app

**Context:** Various screens

**Issue:** The app has three different loading patterns that are used inconsistently:

1. **`ShimmerWidget`** (core widget, shimmer animation) — used by `dashboard_screen.dart`
2. **`LoadingIndicator`** (core widget, `CircularProgressIndicator`) — used by `subject_list_screen.dart`, `topic_list_screen.dart`, `lesson_list_screen.dart`
3. **`LoadingScreen`** (core widget, full-screen `LoadingIndicator`) — used by `practice_screen.dart`, `session_history_screen.dart`, `profile_screen.dart`
4. **Raw `CircularProgressIndicator`** — used by `collapsible_card.dart:37–39` during skeleton loading (raw `SizedBox(height:100)` with spinner)

Additionally, the `CollapsibleCard` loading skeleton (line 37–39) uses a hardcoded `SizedBox(height: 100)` with a `CircularProgressIndicator` rather than a `ShimmerWidget`, creating a visual inconsistency within the same dashboard.

**Acceptance criteria (fixed):**
- Establish a convention: content-loading uses `ShimmerWidget` skeletons; action-loading uses `LoadingIndicator` with optional message; full-page loading uses `LoadingScreen`.
- `collapsible_card.dart` uses `ShimmerWidget` matching the card's height and layout during loading.

---

### M-11: Subject detail screen — subject name `Text` without `overflow` may overflow

**Context:** `lib/features/subjects/presentation/subject_detail_screen.dart:151–155`

```dart
Text(
  subject.name,
  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
)
```

**Issue:** Subject names can be long ("Advanced Quantum Mechanics and Relativity Theory"). Displayed in `SliverAppBar` without `overflow: TextOverflow.ellipsis`, `maxLines`, or `softWrap`. On narrow screens, this causes an overflow or pushes other elements off-screen.

**Acceptance criteria (fixed):**
- Add `overflow: TextOverflow.ellipsis` and `maxLines: 2` or use `Flexible` / `Expanded` wrapping.

---

### M-12: Weekly chart uses technical "W1", "W2" labels instead of user-friendly format

**Context:** `lib/features/dashboard/presentation/widgets/weekly_chart.dart:73–74`

```dart
'W${trend.length - i}'
```

**Issue:** Chart x-axis labels read "W1", "W2", etc. — a developer shorthand. Users see raw technical labels. Should use relative labels like "This week", "Last week", or formatted dates.

**Acceptance criteria (fixed):**
- Use relative labels: `l10n.thisWeek`, `l10n.lastWeek`, or date-formatted labels using `l10n.localeName`.
- Only fall back to "W1" if there are more than ~6 weeks shown.

---

## MINOR — Code quality / UX friction

### m-1: 69+ hardcoded `fontSize` values bypassing theme text styles

**Context:** Throughout `lib/features/` — screens/widgets use inline `fontSize:` values instead of `theme.textTheme.titleMedium`, `bodySmall`, etc.

**Examples:**
- `focus_timer_screen.dart:815` — `fontSize: 12`
- `topic_breakdown_card.dart:173` — `fontSize: 11`
- `api_config_screen.dart:502` — `fontSize: 10`
- `export_section.dart:83,95,108,121` — `fontSize: 12`
- `graph_drawing_widget.dart:64` — `fontSize: 14`
- `subject_detail_screen.dart:140` — `fontSize: 24`

**Rationale:** Bypassing the theme's text style system means: (a) accessibility font scaling via `createTextTheme()` is partially defeated, (b) dark mode / high-contrast adjustments are missed, (c) the app has visual inconsistency in text sizing.

**Acceptance criteria (fixed):**
- Replace hardcoded `fontSize` with closest `theme.textTheme.*` style.
- Where `copyWith` is needed for color/weight only, avoid overriding `fontSize`.
- Document exceptions in AGENTS.md (math expressions, drawing tools) where custom sizing is justified.

---

### m-2: 300+ hardcoded `EdgeInsets` / padding values ignoring `AppSpacing` constants

**Context:** `lib/core/constants/app_spacing.dart` defines `AppSpacing.xs=4, sm=8, md=16, lg=24, xl=32, xxl=48` with pre-built `EdgeInsets` constants. Feature code uses raw values instead (e.g., `EdgeInsets.all(16)` instead of `AppSpacing.allMd`).

**Impact in `lib/core/`:** ~35 instances of raw `EdgeInsets`. Key examples:
- `error_boundary.dart:42` — `EdgeInsets.all(32)` vs `AppSpacing.allXl`
- `animated_bar_chart.dart:137` — `EdgeInsets.only(bottom: 8)` vs `AppSpacing.onlyB8`
- `conversation_input.dart:116` — custom `EdgeInsets.symmetric(horizontal: 20, vertical: 12)` (no named constant)
- `practice_performance_card.dart:59,96` — `EdgeInsets.only(bottom: 4)`, `bottom: 2`

**Acceptance criteria (fixed):**
- Systematically replace raw padding values with `AppSpacing.*` constants across the codebase.
- Add any missing constants to `app_spacing.dart` (e.g., `allXxl`, `allXxs`, `symH20V12` if widely used).
- Enforce via lint rule if possible.

---

### m-3: 6 remaining legacy `MediaQuery.of(context)` calls

**Affected files:**

| File | Line | Current call | Should be |
|---|---|---|---|
| `conversation_input.dart` | 168 | `MediaQuery.of(context).padding.bottom` | `MediaQuery.paddingOf(context).bottom` |
| `main.dart` | 408 | `MediaQuery.of(context).copyWith(...)` | static `MediaQuery.copyWith(...)` |
| `exam_session_screen.dart` | 633 | `MediaQuery.of(context).size.width` | `MediaQuery.sizeOf(context).width` |
| `practice_session_question_card.dart` | 82 | `MediaQuery.of(context).size.height` | `MediaQuery.sizeOf(context).height` |
| `lesson_booking_sheet.dart` | 94 | `MediaQuery.of(context).viewInsets.bottom` | `MediaQuery.viewInsetsOf(context).bottom` |
| `quick_guide_screen.dart` | 320 | `MediaQuery.of(context).padding.bottom` | `MediaQuery.paddingOf(context).bottom` |

**Rationale:** Rest of the codebase uses modern static `MediaQuery.*Of()` methods. These 6 are oversights that may cause spurious rebuilds in the long term (legacy `MediaQuery.of` rebuilds on any MediaQuery change, while static methods are more targeted).

**Acceptance criteria (fixed):**
- Migrate all 6 to the appropriate static accessor.
- Add a lint rule prohibiting `MediaQuery.of(context)`.

---

### m-4: NavigationRail / NavigationBar destinations have redundant `Semantics` + `Tooltip`

**Context:** `lib/main.dart:717–718, 743–744`

```dart
Semantics(
  label: d.tooltip,
  child: Tooltip(
    message: d.tooltip,
    child: Icon(...),
  ),
)
```

**Issue:** The `Semantics` already labels the icon for screen readers. Nesting `Tooltip` inside with the same string causes double-announcement (screen reader reads the label, then the tooltip). Sighted users get the tooltip on hover — the redundancy only harms accessibility.

**Rationale:** WCAG SC 2.5.3 — avoid redundant labeling.

**Acceptance criteria (fixed):**
- Remove `Semantics` wrapper and rely on `Tooltip`'s built-in semantics (Tooltip already adds a semantic label), OR
- Keep `Semantics` and remove `Tooltip` (use `MaterialStateTooltipText` or similar if tooltip is needed).
- Ensure accessibility label is still present (test with TalkBack/VoiceOver).

---

### m-5: Confidence selector widget duplicated across two screens (~170 lines each)

**Context:**
- `lib/features/practice/presentation/screens/practice_session_screen.dart:779–850`
- `lib/features/practice/presentation/screens/exam_session_screen.dart:683–753`

**Issue:** The confidence selector (1–5 scale with labels and colors) is nearly identical in both files. Any UI change must be made in both places, leading to drift.

**Acceptance criteria (fixed):**
- Extract into a shared widget (e.g., `ConfidenceSelector`) in `lib/features/practice/presentation/widgets/`.
- Both screens import and use the shared widget.

---

### m-6: LLM Task Manager shows raw cost with 4 decimal places — developer-oriented

**Context:** `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart:337`

```dart
formatCurrency(task.estimatedCost, ..., minFractionDigits: 4, maxFractionDigits: 4)
```

**Issue:** Micro-costs shown as `$0.0004` are accurate but confusing to non-developer users. Typical users expect `~$0.00` or `<$0.01`.

**Acceptance criteria (fixed):**
- Show with 2 decimal places by default.
- Add a tooltip or expandable detail showing exact cost for advanced users.

---

### m-7: `absence_banner.dart` missing `MergeSemantics` on two-line message

**Context:** `lib/features/dashboard/presentation/widgets/absence_banner.dart:55–73`

**Issue:** The banner has a `Column` with two `Text` widgets. Screen readers read them as two separate nodes. They should be merged into one semantic node (e.g., "Welcome back! It's been 5 days since your last study session.") for efficient navigation.

**Acceptance criteria (fixed):**
- Wrap the `Column` in `MergeSemantics`.

---

### m-8: Dashboard `_onRetry` invalidates ALL providers instead of the failing one

**Context:** `lib/features/dashboard/presentation/dashboard_screen.dart:492`

**Issue:** When retrying a single failed card, both `dashboardInitProvider` AND the specific card's provider are invalidated. This reloads the entire dashboard instead of just the broken section.

**Acceptance criteria (fixed):**
- Pass a retry callback per card that only invalidates the specific provider for that card.

---

### m-9: Mentor screen uses 10+ boolean state flags — risky state explosion

**Context:** `lib/features/mentor/presentation/mentor_screen.dart`

**Issue:** The screen manages `_isInitialized`, `_initError`, `_isRetrying`, `_isSending`, `_suggestedActionError`, and ~5 more boolean flags. This creates 2^n possible states, some of which are invalid (e.g., `_initError` true + `_isInitialized` true).

**Acceptance criteria (fixed):**
- Replace boolean flags with an enum or sealed class for screen state (e.g., `initializing`, `ready`, `error`, `sending`, `errorWithRetry`).
- Ensure mutually exclusive states remain exclusive.

---

### m-10: Practice screen creates services inline (not via providers)

**Context:**
- `lib/features/practice/presentation/screens/practice_screen.dart:293` — `PrerequisiteCheckService()` instantiated directly
- `lib/features/practice/presentation/screens/practice_screen.dart:704` — `SourceRepository()` created every invocation

**Rationale:** Inline instantiation defeats Riverpod's caching, lifecycle management, and testability. Every call creates a fresh, unconnected instance.

**Acceptance criteria (fixed):**
- Create providers for `PrerequisiteCheckService` and `SourceRepository` (if not already existing).
- Use `ref.read()` in the screen.

---

### m-11: Charts use `.normalized` on l10n label (capitalization corruption)

**Context:** Already covered in M-2. Listed separately because it affects multiple chart widgets.
- `weekly_chart.dart` — `sessionsLabel.normalized`
- `due_reviews_card.dart` — `dueForReview.normalized`

---

### m-12: `AppRadius` mutable `RoundedRectangleBorder` constants

**Context:** `lib/core/constants/app_radius.dart`

```dart
static RoundedRectangleBorder roundedSm = RoundedRectangleBorder(borderRadius: BorderRadius.circular(sm));
```

**Issue:** These are mutable `static` fields, not `static const` or `static get`ters. If any code mutates them at runtime, it affects all consumers.

**Acceptance criteria (fixed):**
- Change to `static RoundedRectangleBorder get roundedSm => ...` (getter returning a fresh instance) or mark `const`.

---

### m-13: `DropdownButtonFormField` uses `initialValue` parameter (11 occurrences)

**Affected files:**

| File | Line(s) |
|---|---|
| `focus_timer_screen.dart` | 1355 |
| `planner_screen.dart` | 322, 808 |
| `session_tracker_screen.dart` | 375 |
| `api_config_screen.dart` | 510, 637 |
| `upload_screen.dart` | 524 |
| `question_bank_screen.dart` | 320, 336, 352 |
| `topic_edit_dialog.dart` | 112 |

**Issue:** `DropdownButtonFormField` expects `value` parameter (not `initialValue`). While `initialValue` may compile (inherited from `FormField`), using it is non-idiomatic and may produce unexpected behavior with form state reset/validation. Using `initialValue` means the field won't re-render when the parent widget recreates it with a different initial value — it only uses the value during the first build.

**Acceptance criteria (fixed):**
- Replace `initialValue:` with `value:` on all `DropdownButtonFormField` usages.
- Verify form behaviors still work (reset, validation, editing).

---

### m-14: Subject and Session ID generation uses timestamp + random — collision risk

**Affected files:**
- `lib/features/subjects/presentation/subject_selection_screen.dart:75–95` — ID = `'subject_${DateTime.now().millisecondsSinceEpoch}'`
- `lib/features/sessions/presentation/session_tracker_screen.dart:198` — ID = `'${endTime.millisecondsSinceEpoch}_${Random().nextInt(99999)}'`

**Issue:** Milliseconds timestamp has 1000 possible values per second. The random component has 99999 possible values. Under rapid creation (common in testing/demo), collisions are possible. The existing `IdGenerator` utility in `lib/core/utils/id_generator.dart` should be used instead.

**Acceptance criteria (fixed):**
- Use `IdGenerator` (or `Uuid` from the `uuid` package, already in pubspec) for all ID generation.

---

### m-15: Upload screen `stageOrder` hardcoded enum list

**Context:** `lib/features/ingestion/presentation/upload_screen.dart:296–299`

```dart
final stageOrder = ['extracting', 'classifying', 'chunking', 'creating_questions', 'checking'];
```

**Issue:** The stage order is a hardcoded list of strings that must mirror an enum. If the enum (`SourceProcessingStage` or similar) is reordered or renamed, the UI silently shows wrong labels or crashes.

**Acceptance criteria (fixed):**
- Derive `stageOrder` from the enum's `values` list or add a `displayOrder` property to the enum.

---

### m-16: Summary row uses manual breakpoint mapping instead of `SliverGrid`

**Context:** `lib/features/dashboard/presentation/widgets/summary_row.dart:27–31`

```dart
int crossAxisCount;
if (width > 600) crossAxisCount = 4;
else if (width > 400) crossAxisCount = 3;
else crossAxisCount = 2;
```

**Issue:** Manual mapping is fragile and doesn't adapt to content width dynamically. `SliverGridDelegateWithFixedCrossAxisCount` or `Wrap` with computed widths would be more robust.

**Acceptance criteria (fixed):**
- Use `SliverGrid` with `maxCrossAxisExtent` for truly responsive columns.

---

### m-17: Export section uses inline `fontSize: 12` instead of theme text style

**Context:** `lib/features/dashboard/presentation/widgets/export_section.dart:83,95,108,121`

```dart
TextButton.icon(
  style: TextButton.styleFrom(
    textStyle: const TextStyle(fontSize: 12),  // hardcoded
  ),
  ...
)
```

**Acceptance criteria (fixed):**
- Use `theme.textTheme.labelSmall` or `labelMedium` instead of hardcoded `fontSize: 12`.

---

### m-18: No feedback when onboarding "Don't show again" is saving

**Context:** `lib/features/onboarding/presentation/onboarding_dialog.dart:32–43`

**Issue:** The `_completeOnboarding()` method performs async write operations but shows no loading indicator. The dialog dismisses immediately. If the write is slow (Hive flush), the preference may not persist before the app navigates away.

**Acceptance criteria (fixed):**
- Show a brief loading state (disable buttons, show spinner) while the write completes.
- Handle errors gracefully (show snackbar if preference save fails).

---

### m-19: Focus mode break timer not shown in onboarding

**Context:** `lib/features/focus_mode/presentation/focus_timer_screen.dart`

**Issue:** The focus screen has its own onboarding card (`_buildOnboardingCard`, line 647) shown on first visit. This is good — but the onboarding doesn't mention the break timer, Pomodoro-style flow, or how inline practice works. Users discover these only by exploring.

**Acceptance criteria (fixed):**
- Add brief explanations for break flow and inline practice to the focus mode onboarding card.

---

### m-20: No tooltip on some IconButtons

**Context:** Various screens (e.g., dashboard detail actions, subject detail settings icon)

**Issue:** While most `IconButton`s have `tooltip:`, some are missing it (e.g., dashboard header backup/export icons if they don't have explicit `tooltip`).

**Acceptance criteria (fixed):**
- Audit all `IconButton`s in the app and ensure every one has a localized `tooltip`.

---

## Summary

| Severity | Count | Key themes |
|---|---|---|
| BLOCKER | 4 | Non-functional ErrorBoundary, memory leaks, raw errors in snackbars, hardcoded English in dialog_utils |
| MAJOR | 12 | Hardcoded strings, .normalized misuse, accessibility dual-controls, dead-end flows, missing states, responsive breakage, search debounce |
| MINOR | 20 | Inconsistent theming, deprecated APIs, code duplication, fragile ID generation, mutable constants |
