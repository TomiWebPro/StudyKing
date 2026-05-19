# UI/UX Master Report

**Generated:** 2026-05-19
**Scope:** Complete codebase audit — 15 features, 96+ presentation files, navigation flows, accessibility, animations, responsive layout, i18n, and web platform readiness.

---

## BLOCKER — App crashes or user cannot proceed

### B1. `dart:io` imports crash the web build

**Severity:** BLOCKER (runtime crash on web)

Two presentation files import `dart:io`, which is unsupported on Flutter web and will cause a compile-time or runtime crash:

- `lib/features/settings/presentation/settings_screen.dart:2`
- `lib/features/dashboard/presentation/widgets/export_section.dart:1`

Both use `dart:io` for `File` operations (backup/restore settings, CSV/PDF export). On web, these operations must use `dart:html` or `dart:js` or a platform-abstracted API like `cross_file`.

Additionally, `path_provider` (used in `export_section.dart`) is not supported on web. The app will crash if a user on web taps "Export CSV/PDF/JSON."

**Acceptance criteria:**
- [ ] Remove all `import 'dart:io'` from presentation files
- [ ] Replace with platform-agnostic file operations (use `cross_file` + `universal_io` or conditional imports)
- [ ] Add `kIsWeb` guards around web-unsafe file operations
- [ ] Confirm web export paths work: CSV, PDF, JSON, and instrumentation exports
- [ ] Verify settings backup/restore works on web

**Affected files:**
- `lib/features/settings/presentation/settings_screen.dart`
- `lib/features/dashboard/presentation/widgets/export_section.dart`
- `lib/core/services/progress_export_service.dart` (uses `File` internally)

---

## MAJOR — Feature is broken or misleading

### M1. `SizedBox.shrink()` creates dead-end UI states (14 occurrences)

**Severity:** MAJOR (user clicks/taps and nothing happens — no feedback)

When data is missing or conditions aren't met, 14 widgets silently return `SizedBox.shrink()` with zero visual feedback. The user sees either blank space or nothing at all, with no hint of what went wrong or what to do next.

| File | Line | Trigger |
|---|---|---|
| `lib/features/practice/presentation/screens/practice_session_screen.dart` | 637 | Feature variant not available |
| `lib/features/dashboard/presentation/dashboard_screen.dart` | 482 | No data in collapsible card |
| `lib/features/dashboard/presentation/widgets/collapsible_card.dart` | 117 | Card collapsed state |
| `lib/features/dashboard/presentation/widgets/next_up_card.dart` | 40 | No next-up items |
| `lib/features/planner/presentation/planner_screen.dart` | 633 | No study plan exists |
| `lib/features/planner/presentation/planner_screen.dart` | 1030 | No missed lessons |
| `lib/features/planner/presentation/planner_screen.dart` | 1257 | Zero plan days |
| `lib/features/planner/presentation/planner_screen.dart` | 1260 | Loading state for plan days |
| `lib/features/planner/presentation/widgets/milestone_timeline.dart` | 88 | No milestones |
| `lib/features/planner/presentation/widgets/milestone_timeline.dart` | 113 | Zero duration |
| `lib/features/planner/presentation/widgets/calendar_view_widget.dart` | 60 | No calendar data |
| `lib/features/planner/presentation/widgets/progress_overlay_widget.dart` | 103 | Empty weekly progress |
| `lib/features/teaching/presentation/tutor_screen.dart` | 666 | Conversation manager null |
| `lib/features/practice/presentation/screens/review_answers_screen.dart` | 32 | Question null |

**Rationale:** These silent early-returns are particularly harmful in the **Planner screen** (4 instances) — if a user has no study plan, the entire screen section collapses to nothing with no guidance. Same for the **Dashboard** collapsible cards — when data hasn't loaded, there's no skeleton or placeholder at all (the card shows empty). The `collapsible_card.dart` case is the most widespread: when collapsed, the card body is `SizedBox.shrink()`, but this also happens during the **loading** and **error** fallback for generic `asyncValue` widgets.

**Acceptance criteria:**
- [ ] Every `SizedBox.shrink()` replacement shows a user-meaningful widget:
  - **Loading:** `ShimmerWidget` or skeleton placeholder
  - **Empty (no data):** Short inline text like `"No items yet"` with an optional action button
  - **Error:** Inline error text or `ErrorRetryWidget`
- [ ] Planner screen: when no plan exists, show a "Create your first study plan" CTA
- [ ] Dashboard collapsible cards: when collapsed, keep a thin visual indicator (not zero-height `SizedBox`)
- [ ] `next_up_card.dart`: when nothing is next up, show `"All caught up!"` or similar
- [ ] Verify every collapsible card section has a loading skeleton, not `SizedBox.shrink()` during loading

### M2. `SingleChildScrollView` without `AlwaysScrollableScrollPhysics` (32 instances)

**Severity:** MAJOR (content doesn't scroll when viewport is large enough)

Every `SingleChildScrollView` in the project uses default physics (`NeverScrollableScrollPhysics`-like), meaning content **cannot be dragged/overscrolled** when it fits within the viewport. On desktop/tablet with large screens or resized windows, users may see clipped content with no scroll affordance.

**All 22 affected files — 32 scroll views:**
- `lib/features/mentor/presentation/mentor_screen.dart:786`
- `lib/features/practice/presentation/screens/practice_results_screen.dart:47`
- `lib/features/dashboard/presentation/dashboard_screen.dart:114`
- `lib/features/planner/presentation/planner_screen.dart:278,460`
- `lib/features/sessions/presentation/session_tracker_screen.dart:307`
- `lib/features/settings/presentation/settings_screen.dart:946,1145`
- `lib/features/settings/presentation/profile_screen.dart:356`
- `lib/features/settings/presentation/api_config_screen.dart:171`
- `lib/features/ingestion/presentation/upload_screen.dart:384`
- `lib/features/ingestion/presentation/source_detail_screen.dart:313,415`
- `lib/features/questions/presentation/question_bank_screen.dart:226,295,694`
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:474,918`
- `lib/features/teaching/presentation/tutor_screen.dart:386,838`
- `lib/features/subjects/presentation/subject_selection_screen.dart:166`
- `lib/features/ingestion/presentation/content_library_screen.dart:349`
- `lib/features/lessons/presentation/widgets/lesson_block_card.dart:131`
- `lib/features/questions/presentation/widgets/graph_drawing_canvas_widget.dart:220`
- `lib/features/subjects/presentation/dialogs/topic_dependency_dialog.dart:64`
- `lib/features/subjects/presentation/dialogs/topic_edit_dialog.dart:71`
- `lib/features/planner/presentation/widgets/milestone_timeline.dart:122`
- `lib/features/questions/presentation/widgets/math_input_toolbar.dart:41`
- `lib/features/practice/presentation/screens/exam_session_screen.dart:486,654`
- `lib/features/onboarding/presentation/onboarding_dialog.dart:268`
- `lib/features/practice/presentation/widgets/spaced_repetition_sheet.dart:80`

**Acceptance criteria:**
- [ ] Add `physics: const AlwaysScrollableScrollPhysics()` to every `SingleChildScrollView` in presentation files
- [ ] Verify scroll works correctly on desktop browser (resized window) and tablet
- [ ] For list-heavy screens (question bank, content library, session history), consider using `ListView` or `CustomScrollView` instead

### M3. `AnimatedSwitcher` in tab navigator bypasses reduce motion

**Severity:** MAJOR (accessibility — vestibular disorder trigger)

The main tab switcher in `lib/main.dart:429` wraps all tab content in an `AnimatedSwitcher` with a 200ms cross-fade animation. This does NOT check the `reduceMotion` accessibility preference. Users who have enabled "Reduce Motion" in settings or system-wide will still see tab-switching animations, which can trigger discomfort for users with vestibular disorders.

```dart
// lib/main.dart:429 — NO reduce motion check
final bodyContent = AnimatedSwitcher(
  duration: const Duration(milliseconds: 200),
  switchInCurve: Curves.easeIn,
  switchOutCurve: Curves.easeOut,
  child: KeyedSubtree(
    key: ValueKey(_selectedIndex),
    child: RepaintBoundary(child: _tabNavigators[_selectedIndex]),
  ),
);
```

All other `AnimatedSwitcher` uses (2 instances) respect `reduceMotion`. This is the only gap.

**Acceptance criteria:**
- [ ] Read `settingsProvider.reduceMotion` (or `MediaQuery.disableAnimationsOf(context)`) in `MainScreen.build`
- [ ] When reduce motion is enabled, replace `AnimatedSwitcher` with a plain `KeyedSubtree` (no animation)
- [ ] Verify the tab content still renders correctly without animation

### M4. Accessibility: 35% of presentation files lack Semantics labels

**Severity:** MAJOR (screen reader users get no context)

34 of 96 presentation files (~35%) have zero `Semantics` or `MergeSemantics` widgets. Key gaps include:

- **Chat/Tutor interface:** `tutor_screen.dart` — entire AI tutor screen has no semantics
- **Lesson progress bar:** `lesson_progress_bar.dart` — no semantic labels for progress, stats, or controls
- **Export actions:** `export_section.dart` — export buttons lack screen reader context
- **Detail widgets:** `lesson_block_card.dart`, `lesson_list_item.dart` — lesson content not labeled
- **Subject tabs:** `subject_history_tab.dart`, `subject_lessons_tab.dart`, `subject_topics_tab.dart` — tab content not semantic
- **Review screens:** `review_answers_screen.dart`, `mistake_review_widget.dart` — no review content labels
- **API config:** `api_config_screen.dart` — API key field, test connection button lack semantics
- **Ingestion screens:** `content_library_screen.dart`, `source_detail_screen.dart` — source list items not semantic
- **Quick guide:** `help_dialog.dart`, `message_list_widget.dart` — dialog content not labeled
- **Practice sheets:** `practice_mode_sheet.dart`, `practice_sheet_template.dart`, `source_practice_sheet.dart`, `topic_selection_sheet.dart` — bottom sheet controls not semantic

**Acceptance criteria:**
- [ ] Add `Semantics` wrappers to all interactive elements (buttons, cards, list items) in the 34 identified files
- [ ] Every `IconButton` needs a `Semantics(button: true, label: ...)` or a tooltip (which Flutter auto-exposes to semantics)
- [ ] Expandable/collapsible sections need `Semantics(expanded: ...)` state
- [ ] Progress indicators need `Semantics(value: ..., label: ...)`
- [ ] Verify with TalkBack (Android) or VoiceOver (iOS) that the major screens are navigable
- [ ] Add `Semantics(header: true)` or `headingLevel` to section titles

### M5. Duplicate `OnboardingStorage` abstraction — code drift risk

**Severity:** MAJOR (duplicate code will diverge)

Two files define the same abstract class and identical implementations:

| File | Classes |
|---|---|
| `lib/features/onboarding/services/onboarding_service.dart` | `OnboardingStorage` (abstract), `HiveOnboardingStorage`, `InMemoryOnboardingStorage` |
| `lib/features/onboarding/services/onboarding_storage.dart` | `OnboardingStorage` (abstract), `HiveOnboardingStorage` (with `implements`), `InMemoryOnboardingStorage` |

The `onboarding_storage.dart` version uses `implements` instead of `extends` and has `try/catch` error handling with `Logger`. The `onboarding_service.dart` version is what `main.dart` imports. These will inevitably diverge as one file is updated and the other is not.

**Acceptance criteria:**
- [ ] Consolidate into a single file (prefer `onboarding_storage.dart` with error handling)
- [ ] Update all imports to point to the single source
- [ ] Remove the duplicated definitions
- [ ] Verify tests still pass

### M6. PWA manifest uses template defaults — unprofessional first impression

**Severity:** MAJOR (branding failure on installable web app)

The web PWA manifest (`web/manifest.json`) still contains:
- `"description": "A new Flutter project."` — should say "An adaptive learning platform for students"
- `"orientation": "portrait-primary"` — locks desktop web to portrait mode, poor UX on wide screens

**Acceptance criteria:**
- [ ] Update `web/manifest.json` description to match `pubspec.yaml` description
- [ ] Remove orientation lock or change to `"any"` for desktop web responsiveness
- [ ] Verify PWA install prompt shows correct metadata
- [ ] Update `<meta name="description">` in `web/index.html`

---

## MINOR — Code quality / UX friction

### m1. `CollapsibleCard` inner `InkWell` with dead `onTap: () {}`

**Severity:** MINOR (dead code, unintended ink splash)

In `lib/features/dashboard/presentation/widgets/collapsible_card.dart:96`, there is a nested `InkWell` inside the expand/collapse chevron that has `onTap: () {}` (empty callback). This creates an ink splash animation on tap but performs no action. The actual toggle is handled by the parent `InkWell`.

**Acceptance criteria:**
- [ ] Remove the inner `InkWell` — the `IconButton` or `Semantics` wrapper should handle the tap
- [ ] If the chevron needs its own tap target, wire it to the same toggle action
- [ ] Verify expand/collapse still works correctly

### m2. `CollapsibleCard` `AnimatedSize` without reduce motion check

**Severity:** MINOR (accessibility)

`lib/features/dashboard/presentation/widgets/collapsible_card.dart:113` uses `AnimatedSize` for expand/collapse animation with no conditional for reduce motion.

**Acceptance criteria:**
- [ ] Pass `reduceMotion` from settings provider
- [ ] When enabled, use a non-animated `SizeTransition` or static widget instead
- [ ] Verify expand/collapse still works without animation

### m3. Tutor screen has hardcoded tooltip strings

**Severity:** MINOR (i18n gap)

`lib/features/teaching/presentation/tutor_screen.dart:~539`:
```dart
tooltip: 'Chat'  // should be l10n.chat or similar
tooltip: 'Slides' // should be l10n.slides or similar
```

These tooltips will not localize for Spanish users.

**Acceptance criteria:**
- [ ] Add `chat` and `slides` keys to `app_en.arb` and `app_es.arb`
- [ ] Replace hardcoded strings with `l10n.chat` / `l10n.slides`

### m4. `Colors.grey` fallback in session analytics

**Severity:** MINOR (theme inconsistency)

`lib/features/sessions/presentation/widgets/session_analytics.dart:74` uses `Colors.grey` as a fallback color. This may not blend with the active theme (especially dark mode or high-contrast mode).

**Acceptance criteria:**
- [ ] Replace `Colors.grey` with `theme.colorScheme.onSurfaceVariant` or appropriate theme-derived color

### m5. No URL-based routing for deep linking

**Severity:** MINOR (web UX friction)

The app uses `Navigator 1.0` with `MaterialPageRoute` for all navigation. There is no `go_router` or named-route structure that maps to browser URLs. On web, this means:
- No browser back/forward button support
- No deep linking (can't share a URL to a specific screen)
- Page refreshes lose navigation state

**Acceptance criteria:**
- [ ] Evaluate if `go_router` or `beamer` can be introduced for web deep linking
- [ ] At minimum, ensure browser back button closes modals and returns to previous logical state
- [ ] Not urgent — revisit when web becomes a primary target

### m6. Touch targets not consistently configured

**Severity:** MINOR (accessibility on mobile)

`ResponsiveUtils.minTouchTarget = 48.0` is defined but only used in a handful of places. `materialTapTargetSize` is only configured once in the entire project (in `daily_plan_card.dart`). The Material 3 default `MaterialTapTargetSize.padded` (48dp) is usually adequate, but custom widgets and IconButton replacements may have smaller targets.

**Acceptance criteria:**
- [ ] Audit custom button/replacements and ensure they meet the 48dp minimum
- [ ] Consider setting `materialTapTargetSize: MaterialTapTargetSize.padded` globally in the theme

### m7. No onboarding guided walkthrough after dialog

**Severity:** MINOR (first-launch UX)

After the onboarding dialog and `LocalDataNotice`, the user is directed to the Subject Selection screen. But there is no **in-app guided walkthrough** or tooltip overlay. The Subject Selection screen has no onboarding hints, and after that, the user is dumped into the dashboard with 12+ collapsible cards and no "what to do next" guidance beyond the `EmptyDashboardChecklist`.

**Acceptance criteria:**
- [ ] Add subtle first-launch hints on key screens (e.g., "Tap + to add your first subject," "Swipe to see more options")
- [ ] Consider a "First steps" indicator that highlights the initial actions a new user should take
- [ ] The existing `EmptyDashboardChecklist` is well-designed — consider making it more prominent on first launch only

### m8. Subject detail SliverAppBar has inconsistent compressed title

**Severity:** MINOR (visual polish)

`lib/features/subjects/presentation/subject_detail_screen.dart:75` uses a `SliverAppBar` with `pinned: true`. When collapsed, the `flexibleSpace` gradient disappears and the title is clipped to a circle avatar. On some text scales, this can visually overlap with the navigation back button.

**Acceptance criteria:**
- [ ] Test on large font sizes (accessibility scaling) — ensure the back button and title don't overlap
- [ ] Consider using a `medium` or `large` Material 3 top app bar style instead of SliverAppBar

### m9. Ingestion screen sorting has no persistent state

**Severity:** MINOR (UX friction)

`lib/features/ingestion/presentation/content_library_screen.dart` allows sorting and filtering sources. The sort/filter state resets each time the screen is entered. A user who filters by subject must re-apply filters on every visit.

**Acceptance criteria:**
- [ ] Persist the last-used sort/filter state in Hive or query parameters
- [ ] Or at minimum, restore defaults consistently

### m10. Dashboard weekly chart gap-weeks legend uses non-localized dash character

**Severity:** MINOR (i18n edge case)

`lib/core/widgets/animated_bar_chart.dart` uses `'\u2014'` (em dash) to indicate gap weeks in bar charts. This character is rendered raw and may not be accessible to screen readers. The gap week label is never exposed through the semantics builder for empty/gap bars.

**Acceptance criteria:**
- [ ] Ensure gap week bars have `Semantics(label: "No activity")` through the `semanticsLabelBuilder`
- [ ] Confirm the dash character shows correctly across all locales

### m11. `AnimatedBarChart` animations run even when widget is off-screen

**Severity:** MINOR (performance)

The shimmer widget (`shimmer_widget.dart`) and `AnimatedBarChart` (`animated_bar_chart.dart`) both use `AnimationController.repeat()`. These controllers run continuously even when the widgets are scrolled off-screen (in the dashboard's scrollable content). This is wasteful.

**Acceptance criteria:**
- [ ] Use `AddAutomaticKeepAliveClientMixin` or intersection observer to pause animations when off-screen
- [ ] Or use `TickerMode` to pause when the tab is not active

---

## Summary

| Severity | Count | Key themes |
|---|---|---|
| BLOCKER | 1 | Web platform crash from `dart:io` |
| MAJOR | 6 | Dead-end UI, scroll behavior, accessibility (reduce motion + semantics), duplicate code, PWA metadata |
| MINOR | 11 | Polish, dead code, i18n gaps, touch targets, persistent filters, performance, first-launch guidance |
| **Total** | **18** | |

### Quick wins (can fix in <30 minutes each):
- m1: Remove dead `InkWell` in `collapsible_card.dart`
- m2: Add reduce motion check to `CollapsibleCard`
- m3: Localize tutor tooltip strings
- m4: Replace `Colors.grey` with theme color
- m6: Web manifest metadata update
- m7: PWA orientation fix

### High-impact fixes (invest 1-2 hours each):
- M1: Replace all `SizedBox.shrink()` with meaningful placeholders
- M2: Add `AlwaysScrollableScrollPhysics` to all scroll views
- M3: Add reduce motion check to tab navigator animation
- M4: Bulk-add Semantics to 34 files (can be parallelized)
- M5: Consolidate onboarding storage files
