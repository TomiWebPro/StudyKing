# UI/UX Master — Round 2 Issue Report

**Date:** 2026-05-20
**Scope:** Full codebase re-exploration — state management patterns, DI bypass, monolith screens, loading/error surfaces, missing dispose
**Method:** Screen-by-screen state management audit, dispose audit, async loading gap analysis, DI consistency check
**Note:** This is a supplement to the existing `issues/completed/ui_ux_master.md`. Findings below are **new** — not present in the Round 1 report.

---

## BLOCKER — App crashes or user cannot proceed

### B-1: PracticeScreen fragmented state — 15+ mutable fields, no dispose, silent failures never surfaced

**Context:** `lib/features/practice/presentation/screens/practice_screen.dart`

**Issue:** The screen manages state with 15+ individual mutable class fields scattered across the class body:

```dart
bool _isLoading = true;
String? _loadError;
Map<String, int> _dueCounts = {};
bool _isLoadingDueCounts = false;
bool _dueCountsLoadFailed = false;
int _totalQuestionCount = 0;
int _questionsToday = 0;
bool _questionCountLoadFailed = false;
bool _isLoadingActivity = true;
int _weeklyAccuracy = 0;
int _weeklyActivity = 0;
int _practiceStreak = 0;
int _weakTopicCount = 0;
int _mediumTopicCount = 0;
int _strongTopicCount = 0;
List<Session> _recentSessions = [];
```

Four parallel async load methods (`_loadSubjects`, `_loadDueCounts`, `_loadQuestionCount`, `_loadActivity`) race against each other and the widget lifecycle. There is **no `dispose()` override**. The `_dueCountsLoadFailed` and `_questionCountLoadFailed` booleans are **never surfaced in the UI** — the user sees zero-valued defaults as if no data exists. When `_loadDueCounts` fails silently, spaced repetition cards show "0 due reviews" and the user misses review sessions entirely.

**Root cause:** The screen predates the current Riverpod architecture and was never migrated. It uses imperative `setState` + manual `initState` loading instead of `AsyncValue.when()`.

**Rationale:** A user with due reviews sees "0 due" because `_dueCountsLoadFailed` silently defaults the map. This directly prevents spaced repetition practice — a core feature.

**Acceptance criteria (fixed):**
- Replace all 15+ mutable fields with a single `AsyncValue<PracticeScreenData>` sealed class or equivalent.
- Each data load method returns a `Result` or throws, caught at a single point in the widget tree.
- Loading, error, and data states are rendered via `AsyncValue.when()` for the aggregate state.
- A `dispose()` override is added (even if no resources need cleanup — prevents future leaks).
- Error states show the `ErrorRetryWidget` with a retry callback that re-runs all loads.
- Verify with a test: mock a failing due-count provider → UI shows error, not "0 due."

---

### B-2: ContentLibraryScreen creates fresh Repository instances, bypassing DI — stale data after navigation

**Context:** `lib/features/ingestion/presentation/content_library_screen.dart:39–41`

```dart
late final SourceRepository _sourceRepo = widget.sourceRepo ?? SourceRepository();
late final QuestionRepository _questionRepo = widget.questionRepo ?? QuestionRepository();
```

**Issue:** The screen creates fresh `SourceRepository()`, `QuestionRepository()`, and `SubjectRepository()` instances in `initState`. These bypass the `DatabaseService`-managed lifecycle. When the user uploads a source via `UploadScreen` (which uses providers connected to `DatabaseService`), then navigates to `ContentLibraryScreen`, the new inline `SourceRepository` may not see the uploaded data because it's a different Hive box connection. If Hive boxes were opened by `DatabaseService` and the new instance tries to re-open, it may read stale cached values.

There is also no `dispose()` override on a `StatefulWidget` that creates disposable resources.

**Rationale:** ContentLibraryScreen is the primary way users verify their uploaded materials. Stale data here means users re-upload content they think was "lost," creating wasted API calls and confusion.

**Acceptance criteria (fixed):**
- Remove inline `SourceRepository()` / `QuestionRepository()` / `SubjectRepository()` creation.
- Use existing Riverpod providers (`sourceRepositoryProvider`, `questionRepositoryProvider`, `subjectRepositoryProvider`).
- Add a `dispose()` override (even if the provider-refactored version has nothing to dispose).
- Test: upload a source → navigate to ContentLibrary → assert the new source appears.

---

## MAJOR — Feature is broken or misleading

### M-1: TutorScreen initialization shows raw `e.toString()` in user-facing error message

**Context:** `lib/features/teaching/presentation/tutor_screen.dart:168`

```dart
_initErrorMessage = l10n.tutorInitFailed(e.toString());
```

**Issue:** The raw exception string is passed as a placeholder to the localized template. Users see messages like:

> "Failed to initialize tutor: SocketException: Connection refused (OS Error: Connection refused, errno = 111)"

This exposes internal architecture, hostnames (if embedded in error), and implementation details.

**Rationale:** Violates the project's Error Handling Conventions (AGENTS.md: "log the error with a descriptive message" for internal handling). This is the tutor screen — the most AI-intensive screen. Errors here should be empathetic and actionable.

**Acceptance criteria (fixed):**
- Replace `e.toString()` with a generic localized message: `l10n.tutorInitFailedGeneric`.
- Log the full exception to the Logger with a descriptive tag.
- If additional details help the user (e.g., "Check your API key in Settings"), provide a separate localized string.

---

### M-2: Dashboard `_buildSourcesCard` duplicates ~80 lines of identical layout between zero/has-sources branches

**Context:** `lib/features/dashboard/presentation/dashboard_screen.dart:560–650` (~90 lines)

**Issue:** The method has two branches — one for `count == 0` (loading not in progress) and one for `count > 0 || isLoading`. Both branches produce a `Card` with an identical structure: `Semantics(button:) > InkWell > Padding > Row > Icon + Column(Text + Text/Text) + chevron`. Only the icon color, subtitle text, and RTL chevron handling differ. Any design change (new padding, different icon, different chevron behavior) must be made in both branches. Missing one creates a visual inconsistency.

**Rationale:** This pattern appears 4+ times in the same file (SessionHistoryCard, PlannerCard, QuestionBankCard, SourcesCard). Each duplicates ~30-50 lines. The total duplication exceeds 200 lines within one file.

**Acceptance criteria (fixed):**
- Extract a reusable `DashboardNavCard` widget with parameters: `icon`, `iconColor`, `title`, `subtitle`, `onTap`.
- Replace all 4 inline card builders (`_buildSessionHistoryCard`, `_buildSourcesCard`, `_buildPlannerCard`, `_buildQuestionBankCard`) with the new widget.
- Verify: no visual change, all semantics preserved.

---

### M-3: PracticeScreen bypasses all repository layers by reading Hive directly

**Context:** `lib/features/practice/presentation/screens/practice_screen.dart:~155`

```dart
final settingsBox = await Hive.openBox(HiveBoxNames.settings);
final apiKey = settingsBox.get('apiKey', defaultValue: '') as String;
```

**Issue:** The practice screen reads the Hive settings box directly instead of going through `SettingsRepository` > `settingsProvider`. This bypasses caching, secure storage abstraction, and the provider-based reactivity system. If the settings repository implements encryption or migration in the future, the practice screen will read stale/unencrypted data.

**Rationale:** Direct Hive access in presentation layer violates the layered architecture. The AGENTS.md conventions specify repositories as the data access boundary.

**Acceptance criteria (fixed):**
- Remove the direct `Hive.openBox` call.
- Read the API key from `ref.watch(settingsProvider).apiKey` or the secure API key provider.
- The `_loadQuestionCount` method should be refactored as part of B-1 to use providers.

---

### M-4: SessionHistoryScreen — 715-line StatefulWidget with no Riverpod, manual state, no dispose

**Context:** `lib/features/sessions/presentation/session_history_screen.dart`

**Issue:** This is the only major screen in the app that uses `StatefulWidget` + `setState` exclusively — no Riverpod at all. It manages 8+ mutable fields manually:

```dart
List<Session> _allSessions = [];
List<Session> _filteredSessions = [];
DateTime? _selectedDate;
String? _selectedSubject;
bool _isLoading = true;
String? _error;
// ... plus _filterError from _buildFilterSection
```

It creates `SubjectRepository()` directly. No `dispose()` override. No `AsyncValue` patterns. The data loading and client-side filtering all run on the main isolate.

**Rationale:** Inconsistency with the rest of the app. Manual state management is more error-prone for async data (missing mounted checks, stale closures). The lack of Riverpod means no reactivity — sessions added elsewhere don't appear without manual refresh.

**Acceptance criteria (fixed):**
- Migrate to Riverpod: create `sessionHistoryProvider` or `allSessionsProvider`.
- Use `AsyncValue.when()` for loading/data/error.
- Remove direct `SubjectRepository()` creation; use provider.
- Add a `dispose()` override.
- Retain client-side filtering but derive from a single async provider.

---

### M-5: PlannerScreen (1706 lines) and SettingsScreen (1987 lines) — monolithic screens violating Single Responsibility

**Context:**
- `lib/features/planner/presentation/planner_screen.dart` (1706 lines)
- `lib/features/settings/presentation/settings_screen.dart` (1987 lines)

**Issue (PlannerScreen):** This single file contains 5+ distinct responsibilities:
1. Plan generation form (course input, days, hours)
2. Multi-syllabus entry management
3. Plan display (daily plans, summary, pace adjustment)
4. Calendar tab view
5. Roadmap CRUD (create, edit, delete)
6. Pending action handling
7. Adherence warnings and catch-up flows
8. Syllabus progress display
9. Pace adjustment slider with completion date estimation

Internal methods like `_buildStudyPlanTab` are 300+ lines. `_buildPaceAdjustment` duplicates ~60% of its code between single-subject and multi-subject paths.

**Issue (SettingsScreen):** 1987 lines mixing:
1. Auto/manual backup & restore
2. Theme mode (light/dark/high-contrast)
3. Font size slider
4. Accessibility options (bold, reduce motion, touch targets)
5. API key management (with secure storage)
6. LLM provider selection + model search
7. LLM usage/cost display
8. Notification settings
9. Data management (clear all data)
10. Profile link, onboarding re-trigger, about section

**Rationale:** A developer changing roadmap creation must understand the entire 1706-line PlannerScreen context. Merge conflicts are more likely. Test coverage is harder to reason about. Widget rebuilds are broader than necessary.

**Acceptance criteria (fixed):**
- PlannerScreen: Extract calendar tab into `PlannerCalendarTab`, roadmap tab into `PlannerRoadmapsTab`, plan generation into `PlanGenerationForm`. Each extracted widget gets its own file in `features/planner/presentation/widgets/`.
- SettingsScreen: Extract backup section into `BackupRestoreSection`, accessibility into `AccessibilitySection`, LLM config into `LlmConfigSection`. Each gets its own file in `features/settings/presentation/widgets/`.
- Verify: no visual change, all functionality preserved.

---

### M-6: Dashboard rebuilds 10+ times on first load due to 10+ individual `ref.watch` calls

**Context:** `lib/features/dashboard/presentation/dashboard_screen.dart:128–156`

**Issue:** The build method watches 10+ providers independently:

```dart
final allMasteryAsync = ref.watch(dashboardAllMasteryProvider(studentId));
final snapshotAsync = ref.watch(dashboardMasterySnapshotProvider(studentId));
final overallStatsAsync = ref.watch(dashboardOverallStatsProvider(studentId));
final weeklyTrendAsync = ref.watch(dashboardWeeklyTrendProvider(studentId));
final focusStatsAsync = ref.watch(dashboardFocusStatsProvider(studentId));
final adherenceAsync = ref.watch(dashboardAdherenceDataProvider(studentId));
final topicNamesAsync = ref.watch(dashboardTopicNamesProvider(studentId));
final badgesAsync = ref.watch(dashboardBadgesProvider(studentId));
final workloadAsync = ref.watch(dashboardWorkloadProvider(studentId));
final dueReviewsAsync = ref.watch(dashboardDueReviewsProvider(studentId));
final checklistProgressAsync = ref.watch(dashboardChecklistProgressProvider(studentId));
// + syllabusGoalsAsync
// + asyncSnapshot
```

Each provider transitions through `AsyncLoading → AsyncData` (or `AsyncError`). Each transition triggers a full widget rebuild. During first load, the dashboard rebuilds 13+ times. The skeleton shimmer appears, disappears, and reappears as each provider resolves.

**Rationale:** Excessive rebuilds cause visible flickering, especially on slower devices where the gap between provider resolutions is larger. The `showSkeleton` variable only checks if ALL are loading at the exact moment of build, so partial loading states show partial content mixed with placeholders.

**Acceptance criteria (fixed):**
- Combine the 10+ stat providers into 2-3 aggregate providers (e.g., `dashboardStatsProvider` returning a record/class, `dashboardLearningProvider`, `dashboardEngagementProvider`).
- Or: wrap the section in a single `AsyncValue.when()` that shows a unified skeleton until all data is ready.
- Measure: verify dashboard builds < 5 times during initial load.

---

### M-7: ResponsiveUtils is partially implemented — LayoutBuilder used instead in some screens

**Context:** `lib/features/planner/presentation/planner_screen.dart:680` and others

```dart
// planner_screen.dart uses LayoutBuilder instead of ResponsiveUtils
LayoutBuilder(
  builder: (context, constraints) {
    final narrow = ResponsiveUtils.breakpointOf(context).isMobile;
    ...
  },
)
```

**Issue:** `lib/core/utils/responsive.dart` defines `breakpointOf()`, `screenPadding()`, `cardPadding()`, `gridCrossAxisCount()`, and extension methods. However:
- Many screens only use `screenPadding` and `verticalSpacing` — not breakpoint-aware layout
- `planner_screen.dart:680` uses `LayoutBuilder` with manual responsive detection instead of `ResponsiveUtils.breakpointOf(context)`
- `summary_row.dart` (via m-16 in Round 1) uses manual width breakpoints
- There is no standard responsive grid system — `gridCrossAxisCount` returns 2 or 4 with no gap configuration

**Rationale:** Partial adoption creates inconsistent responsive behavior. On a 900px-wide tablet, some views use tablet layouts while others use phone layouts.

**Acceptance criteria (fixed):**
- Add `ResponsiveUtils` breakpoint-based layout helpers for common patterns (single-column vs multi-column, narrow vs wide form layout).
- Replace `LayoutBuilder` + manual breakpoints in `planner_screen.dart` with `ResponsiveUtils` calls.
- Remove the `summary_row.dart` manual breakpoints (from Round 1 m-16) as part of this change.
- Test on xs (360px), sm (600px), md (900px), lg (1400px) widths.

---

### M-8: Dashboard skeleton loading is synchronous — all shimmer cards pulse in unison

**Context:** `lib/features/dashboard/presentation/dashboard_screen.dart:_buildSkeletonLoading()`

**Issue:** The skeleton builder creates 6 `ShimmerWidget` instances. Each `ShimmerWidget` uses its own `AnimationController` that starts in `initState` and `repeat(reverse: true)`. Since all 6 are created in the same build call, all 6 controllers start at the same time. The opacity fades in/out on all cards simultaneously, creating a single pulsing block rather than a cascading shimmer effect.

**Rationale:** Cascading animations (each card slightly delayed) feel more natural and are the standard for skeleton loading patterns (Facebook, GitHub, Slack). The current synchronous pulse looks like a rendering glitch.

**Acceptance criteria (fixed):**
- Create a single shared `AnimationController` in the parent and pass staggered delays to each `ShimmerWidget` (e.g., `delay: index * 150ms`).
- Or: use a single `AnimatedBuilder` wrapping all skeleton cards with a staggered opacity curve.
- Verify: shimmer appears as a wave from top to bottom.

---

### M-9: TutorScreen shows empty body during async initialization (no loading indicator)

**Context:** `lib/features/teaching/presentation/tutor_screen.dart`

**Issue:** From `initState` (or post-frame callback) until `_startLesson()` completes and `_isInitialized = true`, the user sees the Scaffold with AppBar and an empty body. The initialization sequence includes:
1. Prerequisite check (async Hive reads)
2. `_tutorService.startLesson()` (calls LLM agent, generates lesson plan)
3. `_sendInitialGreeting()` (streams first LLM response)

This can take 3-10+ seconds (especially on slow networks). No `LinearProgressIndicator`, `CircularProgressIndicator`, or skeleton placeholder is shown during this window.

**Rationale:** A 5-second empty screen looks like the app froze or the navigation didn't work. Users may tap back or re-tap the tutor button, creating duplicate sessions.

**Acceptance criteria (fixed):**
- Show a `LoadingScreen` or `LoadingIndicator` with a localized message (e.g., `l10n.preparingTutorLesson`) while `_isInitialized == false`.
- Add a timeout (30 seconds) that shows an error state if initialization doesn't complete.
- Show a `LinearProgressIndicator` in the AppBar during streaming (already partially done via `_isSending`).

---

### M-10: QuestionBankScreen `_searchController` never disposed — leaked listener

**Context:** `lib/features/questions/presentation/question_bank_screen.dart`

**Issue:** The screen creates `final _searchController = TextEditingController();` for the search field. The `addListener` at line ~70 sets up a callback but there is no `dispose()` override to dispose the controller. The previous Round 1 report (B-2) mentioned dialog-level controllers in this file but not the main `_searchController`. Confirmed: no `dispose()` exists in the file.

**Rationale:** Every keystroke listener fires a `setState`. If the widget is removed from the tree (tab switch), the listener callback closes over a potentially stale `State`. Combined with the missing `dispose()`, the controller leaks.

**Acceptance criteria (fixed):**
- Add a `dispose()` override that calls `_searchController.dispose()`.
- Verify with `leak_tracker_flutter_testing` that no controller leaks after navigation.

---

## MINOR — Code quality / UX friction

### m-1: `SplashScreen` uses hardcoded English strings for tagline and loading

**Context:** `lib/core/widgets/splash_screen.dart:31-36`

```dart
Text('AI-Native Learning Companion', ...)
```

**Issue:** The tagline "AI-Native Learning Companion" is hardcoded. While the app title "StudyKing" is a proper noun and acceptable, the tagline is descriptive content that should be localized. This displays before `AppLocalizations` is loaded, but a `Builder` could defer rendering until locale is available or use `l10n?.tagline ?? 'AI-Native Learning Companion'` per the AGENTS.md null-coalesce pattern.

**Acceptance criteria (fixed):**
- Either add a `TaglinePlaceholder` l10n key with locale-specific translations, or
- Use a getter that returns a safe English fallback until l10n loads.
- Add tests that splash screen renders without crashing before l10n is available.

---

### m-2: `ApiKeyBanner` uses 30% opacity errorContainer — potential WCAG contrast failure

**Context:** `lib/main.dart:728` and `lib/features/onboarding/presentation/onboarding_dialog.dart:331`

```dart
color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
```

**Issue:** The error container is tinted at 30% opacity. On a white/light scaffold background, the resulting color is a very light pink/purple. The text rendered on top uses `theme.colorScheme.error` (typically red) and `theme.colorScheme.onSurface`. Depending on the theme seed color, this may produce a contrast ratio below WCAG AA (4.5:1 for normal text at 14pt, 3:1 for large text at 18pt).

**Rationale:** The API key banner is critical — it warns users they cannot use AI features. Low contrast makes it easy to miss or dismiss without reading.

**Acceptance criteria (fixed):**
- Remove the 0.3 alpha multiplier, or use a pre-defined semi-transparent color with verified contrast.
- Use `theme.colorScheme.errorContainer` at full opacity (it's already a light container color by design).
- Test contrast ratio ≥ 4.5:1 for body text using a color contrast analyzer.

---

### m-3: FocusTimerScreen calls `_service.dispose()` — may affect shared StudyTimerService

**Context:** `lib/features/focus_mode/presentation/focus_timer_screen.dart:497`

```dart
_service.dispose();
```

**Issue:** The focus timer screen creates `_service = ref.read(studyTimerServiceProvider)` and calls `_service.dispose()` in its own `dispose()`. If `StudyTimerService` is scoped as a shared provider (not auto-disposing), disposing it here kills the service for all other consumers (e.g., SessionTrackerScreen, StudyProgressTracker). The `studyTimerServiceProvider` definition should determine whether this is safe, but the screen should not dispose shared dependencies.

**Acceptance criteria (fixed):**
- Remove `_service.dispose()` from `FocusTimerScreen.dispose()`.
- Let the Riverpod provider lifecycle manage service disposal.
- If `StudyTimerService` must be cleaned up, do so via `ref.onDispose` in the provider itself.

---

### m-4: NavigationBar `Tooltip` only wraps the Icon, not the full destination touch target

**Context:** `lib/main.dart:743-745`

```dart
NavigationDestination(
  icon: Tooltip(message: d.tooltip, child: Icon(d.icon)),
  selectedIcon: Tooltip(message: d.tooltip, child: Icon(d.selectedIcon)),
  label: d.label,
),
```

**Issue:** The `Tooltip` wraps only the `Icon` widget (typically 24×24dp), not the entire `NavigationDestination` (which is 48+ dp tall). On desktop/web, the tooltip only appears when the cursor is precisely over the icon, not the larger touch target area. This is especially problematic because `NavigationDestination` already shows the label — the tooltip is most useful during label-only-show-selected mode (which this app uses on mobile), but on desktop (where NavigationRail also shows labels) the tooltip is redundant.

**Rationale:** Desktop users (Linux/web) who hover over the destination's label or padding area won't see the tooltip. The tooltip only appears when hovering exactly on the 24dp icon.

**Acceptance criteria (fixed):**
- Move `Tooltip` to wrap the entire `NavigationDestination` widget, or
- On desktop/web, increase the `NavigationRail` `minWidth` so labels are always shown and remove Tooltips entirely.
- For mobile `NavigationBar`, remove redundant Tooltips (m-4 in Round 1 covered this for semantics; now address the hover target issue).

---

### m-5: `EmptyStateWidget` hardcodes 64px icon — ignores `ResponsiveUtils.emptyStateIconSize`

**Context:** `lib/core/widgets/empty_state_widget.dart:29`

```dart
ExcludeSemantics(
  child: Icon(icon, size: 64, color: ...),
),
```

**Issue:** The icon size is hardcoded to 64px. `ResponsiveUtils.emptyStateIconSize(context)` exists and returns responsive values (64/80/96/96 for xs/sm/md/lg breakpoints) but is not used here.

**Acceptance criteria (fixed):**
- Use `ResponsiveUtils.emptyStateIconSize(context)` for the icon size.

---

### m-6: Dashboard has 4 structurally identical inline card builders

**Context:** `lib/features/dashboard/presentation/dashboard_screen.dart`
- `_buildSessionHistoryCard` (~35 lines)
- `_buildSourcesCard` (~90 lines, duplicated for zero/has-sources)
- `_buildPlannerCard` (~30 lines)
- `_buildQuestionBankCard` (~30 lines)

**Issue:** All four use the same pattern: `Card > Semantics(button:, label:) > InkWell(onTap:, borderRadius:) > Padding > Row > Icon + Column(Text + Text) + RTL-aware chevron`. This is identical structure with different icons, colors, and text. Together they represent ~220 lines of duplicated layout code.

**Rationale:** M-2 calls out the sources card duplication specifically. This expands the scope: all four cards should be a single reusable widget.

**Acceptance criteria (fixed):**
- Extract a `DashboardNavCard` (linked to M-2 acceptance criteria).
- Verify all four cards render identically before and after.

---

### m-7: `PlannerScreen._buildPaceAdjustment` has two branches with ~60% shared code

**Context:** `lib/features/planner/presentation/planner_screen.dart:_buildPaceAdjustment()`

**Issue:** The method has three branches:
1. `state.plan == null` — simple "no plan yet" card
2. `!hasMultipleSubjects` — single-subject pace slider with estimated completion date
3. `hasMultipleSubjects` — per-subject sliders

Branches 2 and 3 share the same card layout (Row with icon + title, Column of controls, Slider, apply button) but duplicate it entirely. Changing the card shape, adding a help tooltip, or adjusting padding must be replicated.

**Acceptance criteria (fixed):**
- Extract the common card wrapper into a shared widget.
- Parameterize the content (single slider vs multiple sliders).
- No visual change to either branch.

---

### m-8: Auto-backup check runs on every app resume, iterating all Hive boxes

**Context:** `lib/main.dart:75-150` (`_runAutoBackupCheck`), called at line 271 (startup) and line 371 (`didChangeAppLifecycleState.resumed`)

**Issue:** `_runAutoBackupCheck()` iterates 35+ Hive box names, opens each box (if not already open), reads ALL values, and serializes each to a Map. This runs synchronously in the Flutter event loop. On every app resume — even just switching apps and switching back — this potentially serializes thousands of records. For a user with 6+ months of data, this causes a visible UI freeze of 100-500ms.

**Rationale:** `didChangeAppLifecycleState` is called on every app foreground transition, even lock/unlock. Unnecessary I/O on every resume drains battery and janks the UI.

**Acceptance criteria (fixed):**
- Only run backup check once per day (check `lastAutoBackupDate` before iterating boxes).
- Move backup serialization to an isolate (via `compute` or `Isolate.run`) to avoid blocking the UI thread.
- Show a brief notification/snackbar if backup is running, so the user understands any brief stutter.

---

### m-9: `DashboardHeader` export button opens Settings as fallback — non-obvious navigation

**Context:** `lib/features/dashboard/presentation/widgets/dashboard_header.dart:41`

```dart
onPressed: onExportTap ?? () => Navigator.pushNamed(context, AppRoutes.settings),
```

**Issue:** The export icon button's fallback (when `onExportTap` is null) navigates to Settings. The export section is actually on the dashboard (below the fold), so if the user taps the export icon, they expect to see export options — not Settings. This fallback is misleading. If `onExportTap` is null, the export button should either be hidden or the scroll-to-export should work unconditionally.

**Acceptance criteria (fixed):**
- Remove the fallback navigation to Settings.
- Make `onExportTap` required (not nullable), or scroll to the export section unconditionally.
- If export section isn't available, hide the icon button.

---

### m-10: `DialogUtils.showConfirmationDialog` doesn't read `context` for l10n fallback

**Context:** `lib/core/widgets/dialog_utils.dart` (Round 1 B-4 addressed the hardcoded English. This expands: even if English fallback is fixed, the function signature doesn't accept `AppLocalizations`, relying on the caller to pass labels every time.)

**Issue:** Every caller of `showConfirmationDialog` must provide `cancelLabel` and `confirmLabel` manually. This creates the pattern seen across the codebase:

```dart
showConfirmationDialog(
  context,
  title: l10n.deleteTitle,
  message: l10n.deleteMessage,
  cancelLabel: l10n.cancel,  // manual every time
  confirmLabel: l10n.delete,  // manual every time
);
```

If a caller forgets to pass localized labels, the hardcoded English fallback is used.

**Acceptance criteria (fixed):**
- Change function signature to read `AppLocalizations.of(context)` internally for default labels.
- Add `String? cancelLabel` and `String? confirmLabel` (optional, defaults to `l10n.cancel` / `l10n.confirm` or localized equivalent).
- Migrate all callers to remove redundant label passing.
- Verify with tests: no caller passes hardcoded English strings.

---

## Summary

| Severity | Count | Key themes |
|---|---|---|
| BLOCKER | 2 | Fragmented state with silent failures, DI bypass causing stale data |
| MAJOR | 10 | Raw error leaks, massive code duplication, direct Hive access, non-Riverpod screens, monoliths, excessive rebuilds, incomplete responsive layer, missing loading states, leaked controllers |
| MINOR | 10 | Hardcoded strings, contrast issues, shared service disposal, tooltip target, responsive gaps, duplicated code patterns, startup jank, non-obvious navigation, dialog patterns |
