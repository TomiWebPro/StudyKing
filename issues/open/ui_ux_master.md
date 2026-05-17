# UI/UX Audit: Comprehensive Findings

## BLOCKER

### B1. Hardcoded `Colors.red.shade800` in `AppErrorHandler` breaks dark mode

**Files:** `lib/core/errors/handlers.dart:62`

**Issue:** `_showErrorUI` uses `Colors.red.shade800` as the SnackBar background. In dark mode this produces a near-black-on-dark-red that is very low contrast and visually jarring.

**Rationale:** System-wide error display that fires for every network, API, and DB error. Dark-mode users get a broken visual experience on every error.

**Acceptance Criteria:**
- Replace `Colors.red.shade800` with `colorScheme.errorContainer` as background and `colorScheme.onErrorContainer` for foreground, or use `SnackBar` theme's default error styling.
- Verify contrast passes WCAG AA in both light and dark themes.

---

### B2. `toStringAsFixed(4)` used for cost display — violates i18n conventions

**Files:**
- `lib/features/settings/presentation/settings_screen.dart:227`
- `lib/features/settings/presentation/settings_screen.dart:794`

**Issue:** `$'${ref.watch(llmUsageMeterProvider).getTotalCost().toStringAsFixed(4)}'` and `$'${totalCost.toStringAsFixed(4)}'`. This always produces period decimal separators regardless of locale. Spanish (`es`) users will see `"$85.5000"` instead of `"$85,5000"`.

**Rationale:** AGENTS.md explicitly forbids `toStringAsFixed()` for user-facing displays. The existing `formatCurrency()` helper in `number_format_utils.dart` should be used.

**Acceptance Criteria:**
- Replace both `toStringAsFixed(4)` calls with `formatCurrency(value, localeName, minFractionDigits: 4, maxFractionDigits: 4)`.
- Verify `es` locale renders comma decimal.
- Ensure `en` locale still renders period decimal.

---

### B3. FocusTimerScreen first-visit help text is hardcoded English

**File:** `lib/features/focus_mode/presentation/focus_timer_screen.dart:444-446`

**Issue:** The container shows `const Text('Set a timer and study distraction-free. Completed sessions count toward your daily plan.', ...)`. Not wrapped in `AppLocalizations`. Spanish/French/etc users see English text.

**Rationale:** Every non-English user sees broken UX on their first focus mode visit.

**Acceptance Criteria:**
- Add `focusFirstVisitHelp` key to `.arb` files (`app_en.arb`, `app_es.arb`).
- Replace the `const Text(...)` with `Text(l10n.focusFirstVisitHelp)`.

---

### B4. FocusTimerScreen daily cap warning dialog uses hardcoded English

**File:** `lib/features/focus_mode/presentation/focus_timer_screen.dart:197-198`

**Issue:** `title: Text('Daily Cap Warning')`, `content: Text('Starting this session... Continue?')`, button `Text('Continue Anyway')`. All hardcoded English.

**Rationale:** Non-English users cannot understand the warning. This is a user-facing dialog.

**Acceptance Criteria:**
- Localize all strings through `AppLocalizations`.
- Add keys to both `app_en.arb` and `app_es.arb`.
- Verify dialog text uses locale-aware strings.

---

### B5. Settings screen notification-related labels are hardcoded English

**File:** `lib/features/settings/presentation/settings_screen.dart:127-136`, `170-172`

**Issue:**
- `title: const Text('Daily Reminder')`, `subtitle: const Text('Get a daily reminder to study at your preferred time')`
- `title: const Text('Check Nudges Now')`, `subtitle: const Text('Run nudge checks immediately')`
- `helpText: 'Daily Reminder Time'`
- `title: 'Reminder Time'`, `subtitle: '${settings.dailyReminderHour....}'`

**Rationale:** These are user-facing settings labels. Non-English users see English.

**Acceptance Criteria:**
- Move all hardcoded notification strings to `.arb` files.
- Replace all occurrences with `l10n.*` lookups.
- Verify rendering for `es` locale.

---

## MAJOR

### M1. Dashboard partial-data flash shows all-empty content briefly

**File:** `lib/features/dashboard/presentation/dashboard_screen.dart:52-68`

**Issue:** The `allEmpty` check requires every single provider to be empty before showing `EmptyDashboardChecklist`. But since providers load independently, the screen computes `allEmpty` on every build. If one provider returns data mid-frame while others are still loading, there's a render that shows all cards collapsed/loading before the data arrives. Conversely, if all providers start as loading+empty, it briefly shows the skeleton, then cards flash in one-by-one.

**Rationale:** First impressions matter. The dashboard is the app home screen.

**Acceptance Criteria:**
- Use a single `AsyncValue` composite or use `ref.listen` to gate the entire dashboard on a single `isLoading` / `hasData` signal.
- After the initial data load completes, don't re-show the skeleton on pull-to-refresh.
- Test with slow network conditions (throttled emulator).

---

### M2. PracticeScreen uses manual `_isLoading` state instead of Riverpod `AsyncValue`

**File:** `lib/features/practice/presentation/screens/practice_screen.dart:44-84`

**Issue:** `_isLoading`, `_subjects`, `_dueCounts` are plain state variables manually managed. There is no centralized error state for the full screen — errors from `_loadSubjects` are handled with `AppErrorHandler` (SnackBar) but the FAB remains disabled with no clear indication of what went wrong.

**Rationale:** Inconsistent with the rest of the codebase (most screens use Riverpod async providers). Manual state management increases risk of stale/inconsistent UI.

**Acceptance Criteria:**
- Migrate subject loading to a Riverpod `AsyncValue<List<Subject>>` provider.
- Show a full-screen error state (with retry button) on failure, not just a SnackBar.
- Maintain the same empty state UI for no-subjects.

---

### M3. SubjectStatsTab silently swallows errors with empty array

**File:** `lib/features/subjects/presentation/widgets/subject_stats_tab.dart:30-31`

**Issue:** When `loadSessions()` throws, the `catch` returns `[]`. The UI renders "0 sessions" with a progress bar at 0% as if the data legitimately shows nothing. No error indicator, no retry.

**Rationale:** User cannot distinguish between "no data yet" and "something broke."

**Acceptance Criteria:**
- Use Riverpod or `AsyncSnapshot` error state to show an error card with retry.
- Display the loading indicator while `ConnectionState.waiting`.
- Add Semantics to communicate error state to screen readers.

---

### M4. No loading state on Mentor screen retry

**File:** `lib/features/mentor/presentation/mentor_screen.dart:317-326`

**Issue:** When the retry button in `_buildInitErrorCard` is pressed, `setState` clears the error and calls `_initializeMentor()` but the UI remains showing the full error card with enabled buttons until the async operation completes. No spinner or visual feedback.

**Rationale:** User taps retry, sees no change for potentially several seconds (LLM service init), and may tap again, causing duplicate initializations.

**Acceptance Criteria:**
- Show a loading overlay or disable the buttons with spinner when retrying.
- Use a `FutureBuilder` or `AsyncValue` to track the init status.

---

### M5. Hardcoded colors in SubjectFormWidgets ignore theme

**Files:**
- `lib/features/subjects/presentation/subject_form_widgets.dart:41` — `Colors.grey.shade300`
- `lib/features/subjects/presentation/subject_form_widgets.dart:60` — `Colors.black87`

**Issue:** These hardcoded colors do not adapt to dark mode. Grey borders on dark surface are invisible; black text on dark background fails contrast.

**Rationale:** Form widgets for a core data entry screen.

**Acceptance Criteria:**
- Replace `Colors.grey.shade300` with `colorScheme.outlineVariant`.
- Replace `Colors.black87` with `colorScheme.onSurface`.
- Verify visual rendering in both light and dark themes.

---

### M6. FocusTimerScreen subject picker shows `SizedBox.shrink` with no guidance when no subjects exist

**File:** `lib/features/focus_mode/presentation/focus_timer_screen.dart:520`

**Issue:** The callback for `FutureBuilder` maps `subjects.isEmpty` to `const SizedBox.shrink()`. When a new user has no subjects, there is no hint or link to create subjects. The setup view renders without the subject picker and no explanation.

**Rationale:** New users may wonder why the dropdown is missing.

**Acceptance Criteria:**
- Replace `SizedBox.shrink()` with a brief info card: "Add subjects in Settings to track focus by subject."
- Include a tappable link to `AppRoutes.subjectSelection`.
- Add Semantics label.

---

### M7. Mentor report weak-topic tap navigates with empty `subjectId`

**File:** `lib/features/mentor/presentation/mentor_screen.dart:483-490`

**Issue:** `subjectId: ''` is passed to `PracticeSessionArgs`. If `_launchWeakAreasForSubject` or `PracticeSessionScreen` requires a valid subject ID, this navigation is a no-op or throws.

**Rationale:** Clicking a weak topic in the mentor progress report should lead to practice but may silently fail.

**Acceptance Criteria:**
- Resolve the actual `subjectId` for the weak topic before navigating.
- If subject ID cannot be resolved, show a helpful SnackBar instead of navigating.

---

### M8. Lack of Semantics labels on several icon buttons

**Files (representative sample):**
- `lib/features/planner/presentation/planner_screen.dart:736` — reschedule `IconButton` has `tooltip` but no `Semantics` wrapper.
- `lib/features/planner/presentation/planner_screen.dart:748` — cancel `IconButton` has `tooltip` but no `Semantics`.
- Multiple `Icon(Icons.chevron_right)` used as tappable affordances with no semantics (e.g. `dashboard_screen.dart:115`, `mentor_screen.dart:627`).
- `lib/features/lessons/presentation/lesson_list_screen.dart` — entire file, if similar patterns exist.

**Rationale:** Accessibility regressions for TalkBack/VoiceOver users.

**Acceptance Criteria:**
- Wrap all `IconButton`s with `Semantics(button: true, label: ...)` if not already done.
- Ensure chevron icons used as ListTile trailing navigation affordances inherit the parent `ListTile` semantics.
- Audit with Flutter's Semantics debugger on both Android and iOS.

---

### M9. Tab navigation resets child Navigator stacks

**File:** `lib/main.dart:350-360`

**Issue:** The `MainScreen` uses `Offstage` + `TickerMode` to show/hide tab content. While this preserves state of the active tab's widget tree, pushing routes within a tab (e.g., SubjectDetail from Subjects) and switching tabs then back resets the inner Navigator to the root screen. The route stack is lost.

**Rationale:** User navigates Subjects -> taps a subject -> sees SubjectDetail -> switches to Dashboard -> switches back to Subjects -> sees SubjectList again, not SubjectDetail. This is unexpected.

**Acceptance Criteria:**
- Maintain the inner `Navigator` route stack per tab using `TabNavigator`, which already preserves the `GlobalKey<NavigatorState>`. Ensure routes are not popped on tab switch.
- Verify: navigate deep into a tab, switch away, switch back, depth is preserved.
- Test with at least 3 levels of nested routes.

---

### M10. Empty state icon size inconsistency

**File:** `lib/features/sessions/presentation/session_tracker_screen.dart:389`

**Issue:** `Icon(Icons.history, size: ResponsiveUtils.emptyStateIconSize(context) * 0.6, ...)`. The `* 0.6` multiplier makes the icon significantly smaller than every other empty state in the app (dashboard, subjects, practice, etc.), which all use `emptyStateIconSize` without multiplier.

**Rationale:** Visual inconsistency on the session tracker's empty state.

**Acceptance Criteria:**
- Remove the `* 0.6` multiplier.
- Use `emptyStateIconSize(context)` directly.
- Keep surrounding spacing proportional.

---

### M11. Settings `Token Cost` display shows raw decimal regardless of locale

**File:** `lib/features/settings/presentation/settings_screen.dart:227`

**Issue:** `'$'${...toStringAsFixed(4)}'`. Same as B2, but the impact is limited to the settings screen. Listed as MAJOR because it's in a user-facing settings summary.

**Acceptance Criteria:**
- Use `formatCurrency()` from `number_format_utils.dart`.
- Respect locale decimal separators.

---

### M12. `_ExtraModeCard` not extracted as reusable widget

**File:** `lib/features/practice/presentation/screens/practice_screen.dart:608-659`

**Issue:** This widget is defined as a private class inside `PracticeScreen`. The same card pattern appears in the planner screen's mode cards. No shared widget.

**Rationale:** Code duplication makes maintenance harder and UI consistency harder to enforce.

**Acceptance Criteria:**
- Extract to `lib/core/widgets/` as `ActionCard` or similar.
- Reuse in both `PracticeScreen` and `PlannerScreen`.
- Add tests in `test/core/widgets/`.

---

### M13. Transitions: all route transitions are `FadeTransition` — no platform-appropriate behavior

**File:** `lib/core/routes/app_router.dart:271-278`

**Issue:** `PageRouteBuilder` with `FadeTransition` for all routes. On Android, the standard is slide-up; on iOS, slide-right. The current implementation ignores platform conventions.

**Rationale:** Users on each platform expect native transition animations. A single fade transition for every route feels foreign on both platforms.

**Acceptance Criteria:**
- Use `MaterialPageRoute` for simple routes (it provides platform-appropriate transitions by default).
- Keep `PageRouteBuilder` + `FadeTransition` only for cases where a custom transition is intentionally desired.
- Verify transitions on both Android emulator and iOS simulator.

---

## MINOR

### m1. SubjectFormFields uses `shrinkWrap: true` + `NeverScrollableScrollPhysics`

**File:** `lib/features/subjects/presentation/subject_form_widgets.dart:101-102`

**Issue:** The form has `shrinkWrap: true` and `NeverScrollableScrollPhysics`. If the parent (SubjectSelectionScreen) wraps this in a scrollable, the form fields expand fully. But on very short screens with many fields, the bottom fields may be clipped or require the parent to scroll the entire form. This creates a nested-scroll hazard.

**Rationale:** User cannot scroll the form independently if the parent has overflow.

**Acceptance Criteria:**
- Remove `NeverScrollableScrollPhysics` from the form.
- Let the form scroll independently if needed.
- OR wrap the parent in a `SingleChildScrollView` and leave `NeverScrollableScrollPhysics` in place.
- Test on a small-screen device (e.g., 4.7" iPhone SE or 5" Android).

---

### m2. `AppTheme` doesn't define `fontFamily` — uses device default

**File:** `lib/core/theme/app_theme.dart`

**Issue:** No `fontFamily` is set on any `TextStyle`. The app relies entirely on the system default font. For a study app, a consistent reading-friendly font (e.g., Noto Sans, Atkinson Hyperlegible) would improve readability.

**Rationale:** Minor because the system default is functional, but inconsistent with many educational apps.

**Acceptance Criteria:**
- Add a `fontFamily` constant to `AppTheme`.
- Apply it globally via `TextTheme.apply(fontFamily: ...)`.
- Ensure CJK and RTL scripts still render correctly (the font should have broad Unicode coverage or fallback).

---

### m3. `ChatBubble` uses hardcoded padding instead of responsive padding

**File:** `lib/features/teaching/presentation/widgets/chat_bubble.dart:44`

**Issue:** `const EdgeInsets.symmetric(horizontal: 16, vertical: 12)` — on a 600px+ tablet, 16px horizontal padding inside a `Flexible` feels cramped. Should use `ResponsiveUtils.cardPadding` or similar.

**Rationale:** Minor UX friction on larger screens.

**Acceptance Criteria:**
- Replace hardcoded padding with `ResponsiveUtils` padding.
- Verify chat bubbles scale correctly on tablet landscape.

---

### m4. `AnimatedBarChart` `yAxisLabel` uses hardcoded small font size

**File:** `lib/core/widgets/animated_bar_chart.dart:121-125`

**Issue:** `fontSize: 11` hardcoded. Should use `theme.textTheme.labelSmall` which already has a proportional size.

**Rationale:** Minor — the 11px label may be illegible when user cranks up font size in Settings.

**Acceptance Criteria:**
- Replace `fontSize: 11` with `theme.textTheme.labelSmall`.
- Verify the chart label scales with user's font size preference.

---

### m5. `ExportSection.formatInstrumentation()` writes raw JSON keys to user-facing file

**File:** `lib/features/dashboard/presentation/widgets/export_section.dart:217-224`

**Issue:** `adherence.forEach((k, v) => buffer.writeln('$k: $v'))` and `mastery.forEach(...)`. The keys like `planAdherence`, `masteryImprovement` are technical identifiers, not user-friendly labels.

**Rationale:** Users who export get a file with machine key names instead of readable text.

**Acceptance Criteria:**
- Map technical keys to localized labels before writing.
- Use `AppLocalizations` for the key names in the exported text.
- Keep the raw JSON export option for technical users.

---

### m6. `PlannerScreen` `_showCreateRoadmapDialog` creates `TextEditingController` without disposing

**File:** `lib/features/planner/presentation/planner_screen.dart:248-251`

**Issue:** `goalController` and `daysController` are disposed in a `WidgetsBinding.instance.addPostFrameCallback`. But if `showDialog`'s builder returns before the dialog is dismissed (e.g., user taps outside to dismiss), the controllers leak until the next frame. Minor memory concern.

**Rationale:** Minor — controllers will be GC'd eventually, but it's a pattern that can cause issues if the dialog is re-shown.

**Acceptance Criteria:**
- Use `StatefulBuilder` or `StatefulWidget` for the dialog to properly manage controller lifecycle.
- OR dispose controllers in the dialog's `Navigator.pop` callback.

---

### m7. Dashboard `CollapsibleCard` `asyncValue` is re-watched on every build

**File:** `lib/features/dashboard/presentation/widgets/collapsible_card.dart:33-34`

**Issue:** Each `CollapsibleCard` calls `asyncValue!.when(...)` but `asyncValue` is passed from the parent which already watches the provider. No Riverpod `ref.watch` is used inside `CollapsibleCard`, so it doesn't rebuild independently when the data changes — only when the parent rebuilds. This works but creates unnecessary rebuild cascades.

**Rationale:** Minor performance concern. On a slow device with 6+ dashboard cards, each parent rebuild retriggers all children.

**Acceptance Criteria:**
- Make `CollapsibleCard` watch its own provider via `ref` instead of receiving the `AsyncValue` from the parent.
- OR wrap each card section in a `Consumer` that watches only its provider.

---

### m8. No loading state at all for Settings screen

**File:** `lib/features/settings/presentation/settings_screen.dart:55-249`

**Issue:** The entire `build` method reads `ref.watch(settingsProvider)` and renders immediately. On first load (or cold start), the settings box may not be fully initialized, causing a brief render with default/empty values before the provider emits.

**Rationale:** Minor because Hive is initialized before `runApp` and settings are cached.

**Acceptance Criteria:**
- Add a loading state: `isLoading` flag from `settingsLoadingProvider` (already exists in `main.dart:145` but unused here).
- Render `CircularProgressIndicator` while loading.

---

### m9. Inconsistent `centerTitle` usage across AppBars

**Files:**
- `lib/features/sessions/presentation/session_tracker_screen.dart:248` — `centerTitle: true`
- `lib/core/theme/app_theme.dart:37-41` — AppBar theme sets `centerTitle: false`

**Issue:** The AppBar theme has `centerTitle: false` by default, but `SessionTrackerScreen` overrides with `centerTitle: true`. This creates one-off visual inconsistency.

**Rationale:** Minor visual nit.

**Acceptance Criteria:**
- Remove the `centerTitle: true` override from `SessionTrackerScreen`.
- Let the theme default apply.
- If the session title truly needs centering, update the theme default for all screens.

---

### m10. `QuickGuideScreen` not reviewed — potential pattern duplication

**File:** `lib/features/quickguide/` (6 files)

**Issue:** The quick guide feature has a separate screen, help dialog, message list, mode navigation, and suggested prompts widgets. These may overlap with the `MentorScreen` chat pattern. Not reviewed in detail, but flagged for potential consolidation.

**Rationale:** Risk of duplicated chat infrastructure across mentor, quick guide, and tutor screens.

**Acceptance Criteria:**
- Audit `QuickGuideScreen` for shared patterns with `MentorScreen` and `TutorScreen`.
- Extract shared chat infrastructure (message list, input, bubble) to `lib/core/widgets/` if not already done.
- Ensure any `ConversationInput` customization is unified.

---

## Summary

| Severity | Count | Key Areas |
|----------|-------|-----------|
| BLOCKER  | 5     | Hardcoded colors/text breaking i18n & dark mode |
| MAJOR    | 13    | Loading/error states, navigation loss, accessibility, theme compliance |
| MINOR    | 10    | Code quality, font scaling, responsive polish, performance |

**Total: 28 findings**

Prioritize BLOCKER items first (they affect all users in specific scenarios), then MAJOR items (feature-specific broken UX), then MINOR items (polish and code health).
