# UI/UX Master — Comprehensive Audit

**Auditor:** UI/UX Master
**Date:** 2026-05-18
**Scope:** All 26 screens across 14 features, navigation system, theming, widgets, onboarding, and accessibility

---

## BLOCKER — App Crash or User Cannot Proceed

### B1. No global error boundary — init failure produces white screen

**Context:** `main.dart:127-131` — `runApp(StudyKingApp())` is inside a try block, but if `MaterialApp` or any top-level widget constructor throws, nothing catches it.

**Affected files:**
- `lib/main.dart:127-131`

**Rationale:** A failed `MaterialApp` build (e.g. corrupt locale data, missing delegate) produces a white screen with no feedback. The user cannot exit, retry, or see an error message.

**Acceptance criteria (fixed):**
- A `ErrorWidget.builder` override catches all unhandled build errors and displays a user-friendly message with a retry button.
- `runApp` is wrapped in a `PlatformDispatcher.onError` handler that shows a native dialog if possible.

### B2. Mentor progress report dialog — potential crash from double `Navigator.pop`

**Context:** `mentor_screen.dart:644-653` — A loading `AlertDialog` is shown, then the first `Navigator.of(context).pop()` (line 653) closes it. There are two `if (!mounted) return;` guards on lines 652 and 654, but no guard against the second `showDialog` (line 655) if the first pop already closed the route and the build context is stale.

**Affected files:**
- `lib/features/mentor/presentation/mentor_screen.dart:644-654`

**Rationale:** Between the two mounted checks, the widget could be disposed. Calling `Navigator.of(context).pop()` on a disposed context throws. Also, the second `showDialog` uses the same context which may no longer be valid.

**Acceptance criteria (fixed):**
- Use a `StateKey` or `BuildContext` captured at the start of the method.
- After the loading pop, await a short post-frame callback before showing the report dialog.
- Wrap the dialog show in a try-catch with fallback toast.

### B3. Subject list screen shows raw error text to user

**Context:** `subject_list_screen.dart:39` — `error.toString()` is passed directly to `Text()`, exposing stack traces or technical Dart error messages to the end user.

**Affected files:**
- `lib/features/subjects/presentation/subject_list_screen.dart:39`

**Rationale:** Raw `toString()` on errors can include file paths, Dart internals, or API keys in exception messages. This is both a security concern and a poor UX.

**Acceptance criteria (fixed):**
- Map `error` to a user-friendly localized message (`l10n.somethingWentWrong`).
- Log the raw error using `Logger` for debugging.

---

## MAJOR — Feature Is Broken or Misleading

### M1. Dashboard skeleton never shows under real conditions

**Context:** `dashboard_screen.dart:69-76` — The `isFirstLoad` boolean requires ALL seven async providers to be in `isLoading` state simultaneously. In practice, providers resolve at different speeds (some are cached in memory, others hit Hive), so the skeleton almost never renders. Users see mixed loading spinners + partial data, then a jarring full-rebuild when remaining data arrives.

**Affected files:**
- `lib/features/dashboard/presentation/dashboard_screen.dart:69-101`

**Rationale:** The loading state is a fragile all-or-nothing check. A single fast-resolving provider invalidates the skeleton. The empty-state check (`allEmpty`) also requires every provider to have null/empty data, which fails if even one provider returned a non-null value (e.g. empty list `[]` vs. null).

**Acceptance criteria (fixed):**
- Show a skeleton layout immediately on build, before any provider resolves.
- As each provider completes, replace its section with real data using `AnimatedSwitcher` or `AnimatedCrossFade`.
- If a provider errors, show the error only in that section's card, not replacing the whole page.

### M2. No pull-to-refresh on several key content screens

**Context:** Practice screen (`practice_screen.dart`) and Subject list screen (`subject_list_screen.dart`) do not support `RefreshIndicator`. Users must navigate away and back to reload data.

**Affected files:**
- `lib/features/practice/presentation/screens/practice_screen.dart`
- `lib/features/subjects/presentation/subject_list_screen.dart`

**Rationale:** Both screens rely on `initState` + `FutureBuilder` for data loading. If a background sync, upload, or import completes, there is no way for the user to refresh without leaving the tab.

**Acceptance criteria (fixed):**
- Wrap the scrollable body in both screens with `RefreshIndicator` calling the data reload logic.
- Invalidate the relevant Riverpod providers on pull-to-refresh.

### M3. API key banner reappears every app launch after dismissal

**Context:** `main.dart:306-316` — The banner dismissal (`_apiKeyBannerDismissed`) is a state variable that resets when the widget rebuilds. It is not persisted to Hive or SharedPreferences.

**Affected files:**
- `lib/main.dart:276-316`

**Rationale:** A user who dismisses the banner sees it again on next app launch. This creates frustration, especially if they intentionally plan to configure the API key later.

**Acceptance criteria (fixed):**
- Persist the dismissal timestamp or boolean to `SettingsBox`.
- Only show the banner if it has not been dismissed in the last 7 days.
- Provide a "Don't show again" option.

### M4. Practice mode grid cards are non-functional (disabled) without explanation

**Context:** `practice_mode_grid.dart:49-81` — When `totalQuestionCount == 0`, the Quick Practice card is disabled. When `dueCounts` are all zero, Spaced Repetition is disabled. The disabled state uses greyed-out icons and text, but there is no tooltip or hint explaining WHY it's disabled or what the user should do to enable it.

**Affected files:**
- `lib/features/practice/presentation/widgets/practice_mode_grid.dart`
- `lib/features/practice/presentation/widgets/practice_mode_card.dart`

**Rationale:** New users see four grey cards with no actionable path forward. They must infer that uploading study materials will unlock these features.

**Acceptance criteria (fixed):**
- When a card is disabled, show a clear subtitle explaining what's needed (e.g., "Upload study materials to enable quick practice").
- Tapping a disabled card shows a dialog or snackbar with a call-to-action button ("Upload now").

### M5. Session history export menu is too complex for mobile

**Context:** `session_history_screen.dart:279-354` — The overflow menu contains 9 items: 3 simple export formats (CSV, PDF, JSON), a divider, 3 comprehensive report formats (CSV, PDF, JSON), plus a non-interactive section header. On mobile this scrolls off-screen and is overwhelming.

**Affected files:**
- `lib/features/sessions/presentation/session_history_screen.dart:279-354`

**Rationale:** A `PopupMenuButton` with 9 items violates mobile UX best practices. Users cannot easily scan or compare formats.

**Acceptance criteria (fixed):**
- Reduce to 2-3 options: "Export filtered sessions (CSV)" and "Comprehensive report".
- Or replace with a dedicated export bottom sheet with descriptions of each format.
- Move format selection (CSV vs JSON) behind a secondary choice within the comprehensive option.

### M6. Onboarding dialog is text-heavy and not interactive

**Context:** `onboarding_dialog.dart:37-65` — The dialog shows a list of 5 features as text + icon rows. There is no interactive walkthrough, no pagination, and no visual demonstration of the app's interface.

**Affected files:**
- `lib/features/onboarding/presentation/onboarding_dialog.dart`

**Rationale:** First-impression onboarding is a long scrollable list of bullet points. Users on mobile likely skip reading it entirely. The "Get Started" button navigates to subject selection without explaining the tab bar or core navigation.

**Acceptance criteria (fixed):**
- Replace the text list with a horizontally swipable `PageView` (2-3 pages) with illustrations or app mock-ups explaining tabs.
- Keep text minimal — one headline + one sentence per page.
- Add a "Skip" button and a page indicator.

### M7. Empty states are inconsistent across the app

**Context:** The app has at least 5 different empty-state patterns:
- `EmptyStateWidget` (core widget, used rarely)
- `EmptyDashboardChecklist` (dashboard-specific)
- `PracticeEmptyState` (practice-specific)
- Inline empty states in subject list, session history, sources tab
- `_buildNoQuestionsBanner` (inline banner in practice screen)

Each has different icon sizes, spacing, button styles, and layout.

**Affected files:**
- `lib/core/widgets/empty_state_widget.dart`
- `lib/features/dashboard/presentation/widgets/empty_dashboard_checklist.dart`
- `lib/features/practice/presentation/widgets/practice_empty_state.dart`
- `lib/features/subjects/presentation/subject_list_screen.dart:61-90`
- `lib/features/sessions/presentation/session_history_screen.dart:485-511`
- More in individual screens

**Rationale:** Users who navigate between tabs see visually different empty states. This undermines the app's polish and makes it feel like disconnected pages rather than a cohesive product.

**Acceptance criteria (fixed):**
- Create a consistent empty-state pattern using `EmptyStateWidget` as the single source of truth.
- Update all feature empty states to use the same icon size, heading style, spacing, and action button pattern.
- Every empty state must include: icon, title, subtitle, and a primary action button that guides the user to fix the empty state.

---

## MINOR — Code Quality / UX Friction

### m1. Destructive button styling is inconsistent

**Context:** Delete/remove actions use three different button patterns:
- `ElevatedButton(styleFrom(backgroundColor: error))` — subject detail, sign out
- `FilledButton(styleFrom(backgroundColor: error))` — session history
- `TextButton` with red text — various dialogs

**Affected files:**
- `lib/features/subjects/presentation/subject_detail_screen.dart:324-329`
- `lib/features/settings/presentation/settings_screen.dart:1199-1202`
- `lib/features/sessions/presentation/session_history_screen.dart:209-213`
- Various dialog files

**Rationale:** Users learn to associate a visual pattern with destructive actions. Inconsistent styling erodes that learning and increases the risk of accidental data loss.

**Acceptance criteria (fixed):**
- Define a `destructiveButtonTheme` in `AppTheme` using a consistent `FilledButton` style with error container colors.
- Use this theme everywhere destructive actions appear.
- All delete confirmations should use the same dialog layout: title, description, cancel + delete buttons.

### m2. Missing semantic labels on interactive elements

**Context:** Many `IconButton`, `FilledButton.icon`, and `InkWell` instances lack `Semantics` wrappers or `tooltip` attributes:
- Onboarding `FilledButton.icon` (no tooltip)
- Dashboard navigation cards (`InkWell` without explicit button role)
- Practice mode cards use `InkWell` within `Semantics(button: true)` but the card's disabled state does not convey `enabled: false`
- Various `PopupMenuButton` items lack tooltips

**Affected files:**
- `lib/features/onboarding/presentation/onboarding_dialog.dart:87-95`
- `lib/features/dashboard/presentation/dashboard_screen.dart:249-279`
- `lib/features/practice/presentation/widgets/practice_mode_card.dart:33-34`
- And many more

**Rationale:** Screen reader users cannot navigate or understand the app without proper semantic annotations. Flutter automatically assigns some semantics but explicit overrides for disabled states, button roles, and labels are essential.

**Acceptance criteria (fixed):**
- Every `IconButton` must have a `tooltip` (or `Semantics(label:)`).
- Every `InkWell`/`GestureDetector` used as a button must be wrapped in `Semantics(button: true)`.
- Disabled interactive elements must have `Semantics(enabled: false)`.
- Run `flutter analyze` with strict semantic rules.

### m3. Plain `CircularProgressIndicator()` without context message on multiple screens

**Context:** Several screens show a bare `Center(child: CircularProgressIndicator())` with no message, no `Semantics(liveRegion:)`, and no `LoadingScreen` wrapper:
- Practice session: `practice_session_screen.dart:499`
- Subject list: `subject_list_screen.dart:38`
- Session history: `session_history_screen.dart:358`
- AI model loading sheet: `settings_screen.dart:1289`

**Affected files:**
- Multiple screen files listed above

**Rationale:** Screen reader users hear "loading" in some places and silence in others. Users cannot distinguish between a quick spinner and a long wait.

**Acceptance criteria (fixed):**
- Replace all bare `CircularProgressIndicator` with `LoadingScreen` or `LoadingIndicator`, both of which provide `Semantics(liveRegion: true)` and optional descriptive messages.
- Use meaningful localized messages (e.g., "Loading questions…", "Preparing session…").

### m4. Multi-choice question options use `CheckboxListTile` within a `Column` — can overflow

**Context:** `practice_session_question_card.dart:79-101` — `options.map(...)` returns a list of `CheckboxListTile` wrapped in a `Column`. If there are 10+ options, this can overflow the available space. Additionally, `overflow: TextOverflow.ellipsis` on tile titles may cut off important answer text.

**Affected files:**
- `lib/features/practice/presentation/widgets/practice_session_question_card.dart:79-101`

**Rationale:** Long option lists overflow below the fold with no scrolling. Users cannot see or select all options.

**Acceptance criteria (fixed):**
- Wrap the options column in a `ConstrainedBox` with `maxHeight` and `ListView` for internal scrolling.
- Or limit visible options to 6 with a "Show all" expand button.

### m5. Subject detail `SliverAppBar` text color may be unreadable

**Context:** `subject_detail_screen.dart:80-85` — The `FlexibleSpaceBar` title uses `textOnColor` (computed from the subject color). However, the `FlexibleSpaceBar` applies its own overlay styling (scrim) which may reduce contrast. The gradient background (`color.withValues(alpha: 0.4-0.8)`) also affects readability.

**Affected files:**
- `lib/features/subjects/presentation/subject_detail_screen.dart:74-89`

**Rationale:** Users who choose light-colored subject themes (e.g. yellow, light blue) may get white text on a white/gradient background.

**Acceptance criteria (fixed):**
- Apply a semi-transparent scrim overlay on the `FlexibleSpaceBar` background to guarantee minimum contrast ratio (4.5:1 for normal text).
- Use `Theme.of(context).colorScheme.onSurface` with appropriate alpha rather than `textOnColor` in the `FlexibleSpaceBar` title.

### m6. `CollapsibleCard` title tap area is too narrow

**Context:** `collapsible_card.dart:78-99` — The expand/collapse action is triggered by tapping the title row (`InkWell` wrapping a `Row` with `ResponsiveUtils.cardPadding`). On mobile (xs breakpoint), card padding is only 12px all around, making the tap target roughly 36-40px tall — below the 48px recommended minimum.

**Affected files:**
- `lib/features/dashboard/presentation/widgets/collapsible_card.dart:78-99`

**Rationale:** Users with larger fingers or motor impairments may struggle to tap the collapse area accurately.

**Acceptance criteria (fixed):**
- Increase the `InkWell` minimum tap target using `InkWell(containing: true)` or padding.
- Ensure the collapse indicator icon also has a 48x48px tap target.

### m7. Tutor screen initialization: no user feedback during 3+ second LLM call

**Context:** `tutor_screen.dart:79-121` — `_startLesson()` calls `_tutorService.startLesson(...)` which is an async LLM operation. While it runs, the user sees only `Center(child: CircularProgressIndicator())` with no message, timing, or cancellation option. The call can take 5-10 seconds depending on network.

**Affected files:**
- `lib/features/teaching/presentation/tutor_screen.dart:504`

**Rationale:** Users may think the app froze. No feedback about what's happening (e.g., "Connecting to AI tutor…", "Preparing your lesson…").

**Acceptance criteria (fixed):**
- Show a `LoadingScreen` with a localized message that updates: "Starting tutor…" → "Loading topic content…".
- Show a "Cancel" button that stops the initialization.
- Add a timeout (e.g. 30s) with an error state.

### m8. `FloatingActionButton.extended` text overflows on xs screens

**Context:** `practice_screen.dart:560-574` — The FAB uses `Flexible(child: Text(..., overflow: TextOverflow.ellipsis))`. On a 320px-wide screen (small phone), the "Practice" label with icon can overflow or clip.

**Affected files:**
- `lib/features/practice/presentation/screens/practice_screen.dart:560-574`

**Rationale:** The `Flexible` wrapper helps but the FAB itself has no `maxWidth` constraint. The default `FloatingActionButton.extended` has a fixed minWidth but no maxWidth.

**Acceptance criteria (fixed):**
- Constrain the FAB to `MediaQuery.sizeOf(context).width - 64`.
- Or reduce to `FloatingActionButton.small` on xs breakpoints.

### m9. Navigation tab labels are duplicated in the navigation body layout

**Context:** `main.dart:371-477` — The `MainScreen` lists all 6 `NavigationDestination` items twice: once for `NavigationRail` (wide) and once for `NavigationBar` (narrow). The labels and icons are identical but written as separate inline lists. Any future tab modification requires updating both lists.

**Affected files:**
- `lib/main.dart:393-473`

**Rationale:** Maintenance burden and risk of inconsistency (e.g., one list gets an updated icon but the other doesn't).

**Acceptance criteria (fixed):**
- Define a single `List<DestinationData>` (or similar) and use `for` loops to build both navigation widgets.
- Or create a private method that returns `List<NavigationDestination>`.

### m10. `SizedBox.shrink()` is used as a no-op body in cards when data is null

**Context:** `dashboard_screen.dart:175, 208` — When `workloadData` is null, the `WorkloadCard` is replaced by `SizedBox.shrink()`. When `allMasteryData` is empty, the `WeakAreasCard` is replaced by `SizedBox.shrink()`. The card header (title + collapse icon) is still rendered but the body is 0-height, resulting in a collapsed card that cannot be expanded (tapping shows nothing).

**Affected files:**
- `lib/features/dashboard/presentation/dashboard_screen.dart:175, 208`

**Rationale:** Users see a card header but tapping it reveals nothing. This is confusing.

**Acceptance criteria (fixed):**
- Replace `SizedBox.shrink()` with a localized message like "No data yet" or "Complete more practice to see your weak areas".
- If the card should be hidden entirely, set the whole card to `SizedBox.shrink()`, not just the body.

### m11. Accessibility: No high-contrast/large-text support for custom gradient and colored containers

**Context:** `subject_detail_screen.dart:87-93` — The gradient background uses `color.withValues(alpha: 0.8)` and text uses `textOnColor`. When high-contrast mode is enabled (`theme.dart:180-181`), the theme doubles borders and increases card elevation, but the subject detail `FlexibleSpaceBar` gradient is unaffected.

**Affected files:**
- `lib/features/subjects/presentation/subject_detail_screen.dart:87-98`
- `lib/core/theme/app_theme.dart:180-335`

**Rationale:** High-contrast mode is supposed to increase visibility, but colored gradients are not adjusted.

**Acceptance criteria (fixed):**
- In high-contrast mode, increase the gradient opacity (from 0.8 to 1.0) and use solid colors instead of gradients where possible.
- Ensure all custom painted containers respect `MediaQuery.highContrastOf(context)`.

### m12. Tooltips missing on navigation icons in tab bar

**Context:** `main.dart:393-473` — `NavigationRailDestination` and `NavigationDestination` use icons only (with labels). The icons themselves lack tooltips. On mobile, labels are visible, but on desktop (NavigationRail), the label is shown but the icon lacks a tooltip for quick reference.

**Affected files:**
- `lib/main.dart:393-473`

**Rationale:** Desktop users with `NavigationRail` see labels, but the icons could benefit from tooltips when the rail is minimized (although this config is not used yet).

**Acceptance criteria (fixed):**
- Add `tooltip` properties to all `Icon(Icons.xxx)` used in navigation destinations.

### m13. `ConversationInput` in mentor and tutor screens lacks `Semantics` for loading state

**Context:** `mentor_screen.dart:465-474`, `tutor_screen.dart:509-533` — The `ConversationInput` has `isLoading` but the loading spinner within the send button is not semantically labeled as "loading" or "sending".

**Affected files:**
- `lib/core/widgets/conversation_input.dart`

**Rationale:** Screen reader users hear "send button" even when the button is replaced by a spinner.

**Acceptance criteria (fixed):**
- When `isLoading`, replace the send button's semantics label with `AppLocalizations.of(context)!.sending`.
- Add `Semantics(liveRegion: true)` to the loading indicator.

### m14. Practice results screen: no way to review answers after session

**Context:** `practice_session_screen.dart:503-509` — After completing a session, `PracticeResultsScreen` is shown with total/correct answers but no "Review answers" option. The mistake review widget only appears if there were mistakes (`_mistakeQuestionIds.isNotEmpty`), and it only offers redo, not review.

**Affected files:**
- `lib/features/practice/presentation/screens/practice_session_screen.dart:332-361`
- `lib/features/practice/presentation/screens/practice_results_screen.dart`

**Rationale:** Students often want to scroll back through their answers and see what they got right/wrong, not just redo mistakes.

**Acceptance criteria (fixed):**
- After session completion, show a "Review answers" button that displays each question with the user's answer and the correct answer highlighted.
- Use `AnimatedList` or `PageView` for the review flow.
