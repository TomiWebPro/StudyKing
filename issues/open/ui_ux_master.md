# UI/UX Master Audit

**Date:** 2026-05-17
**Auditor:** UI/UX Master
**Scope:** All 23 screens + core widgets across 14 feature modules

---

## BLOCKER — App crashes or user cannot proceed

### B1. Dead-end "Add Subject" button on PracticeScreen empty state

**Affected file:** `lib/features/practice/presentation/widgets/practice_empty_state.dart:48-50`

The `PracticeEmptyState` widget shows an `ElevatedButton` labeled "Add Subject". When tapped, it only shows a `SnackBar` telling the user to add subjects from the Subjects tab. It does **not** navigate to the Subjects tab or any subject-creation screen.

**Rationale:** New users who land on the Practice tab with no subjects hit a dead-end: they click the button and nothing useful happens. The SnackBar disappears after a few seconds with no actionable path forward.

**Acceptance criteria:**
- Tapping "Add Subject" in the Practice empty state navigates the user to the Subjects tab (switch tab index to 0) OR opens the SubjectSelectionScreen directly.
- OR: the button says "Go to Subjects" and switches the tab via a callback.

---

### B2. MentorScreen permanently stuck in loading state when LLM initialization fails

**Affected file:** `lib/features/mentor/presentation/mentor_screen.dart:55-88`

When `_initializeMentor()` fails (e.g., no API key, network error, LLM service unavailable), the `_isInitialized` flag is never set to `true`. The `ConversationInput` is disabled (`isEnabled: _isInitialized`), and no error message is displayed. The user sees a blank chat area with a permanently disabled input, no error banner, no retry button — no indication of what went wrong.

**Same pattern exists in:** `lib/features/teaching/presentation/tutor_screen.dart:60-68` (if `TutorService.startLesson()` fails silently).

**Rationale:** The user cannot proceed, cannot interact, and gets zero feedback. This is a hard dead-end.

**Acceptance criteria:**
- If MentorService initialisation fails, show an inline error card with:
  - A clear message (e.g., "API key not configured. Go to Settings to set up your AI provider.")
  - A "Go to Settings" button that navigates to `AppRoutes.apiConfig`.
  - A "Retry" button.
- The input field should show a disabled state with an explanation.
- Same treatment for the TutorScreen.

---

### B3. Router returns null for unmatched routes → Navigator crash

**Affected file:** `lib/core/routes/app_router.dart:248-249`

The `default` case in `onGenerateRoute` returns `null`. Flutter's `Navigator.onGenerateRoute` throws a `FlutterError` when `null` is returned, crashing the app.

**Rationale:** Any programming error leading to an unknown route name causes a hard crash.

**Acceptance criteria:**
- Add a fallback route that navigates to the root screen or shows a 404-like screen.
- Log the unmatched route for debugging.

---

## MAJOR — Feature is broken, misleading, or causes significant UX friction

### M1. ExamSessionScreen loads questions without visual feedback after config change

**Affected file:** `lib/features/practice/presentation/screens/exam_session_screen.dart:108-119`

When the user changes the question count in the exam config, `_loadQuestions()` is called but `_isLoadingConfig` stays `false`. The UI continues to show the config form with the old question count, and the "Start Exam" button is enabled/disabled based on a stale `_questions.isEmpty` check. The user sees no spinner or progress indicator.

**Rationale:** The application appears unresponsive while questions reload.

**Acceptance criteria:**
- Set a loading flag before calling `_loadQuestions()` from `_buildQuestionCountSelector`.
- Show a `LinearProgressIndicator` or `CircularProgressIndicator` overlay while questions are being fetched.
- Disable the "Start Exam" button during loading.

---

### M2. Dashboard renders cards incrementally with jarring layout shifts

**Affected file:** `lib/features/dashboard/presentation/dashboard_screen.dart:32-66`

The DashboardScreen watches **8 separate providers** independently. Each provider has its own loading/error state. Cards appear one-by-one as data arrives, causing content to jump down the page. There's no unified skeleton loading state.

**Rationale:** Users see a fragmented loading experience. Cards pop in sequentially rather than loading as a cohesive page.

**Acceptance criteria:**
- Replace individual `asyncValue.isLoading` checks with a single aggregated loading state.
- Show a unified shimmer/skeleton placeholder while any provider is loading.
- When all providers have resolved, reveal the full dashboard in one paint.

---

### M3. Practice FAB behavior is inconsistent across subject counts

**Affected file:** `lib/features/practice/presentation/screens/practice_screen.dart:360-380`

- **0 subjects:** FAB is disabled (correct).
- **1 subject:** FAB immediately starts a basic practice session with no mode selection. User skips mode selection, spaced repetition, exam mode, etc.
- **2+ subjects:** FAB shows subject selection sheet.

This means a user with exactly 1 subject can never access practice mode selection via the FAB. They must use the mode grid or subject cards instead.

**Rationale:** The FAB is the most prominent CTA on the screen. Its behaviour should be predictable regardless of subject count.

**Acceptance criteria:**
- FAB always shows the subject selection sheet when there are 1+ subjects (select subject, then pick mode).
- OR: FAB opens the practice mode sheet directly regardless of subject count.
- The single-subject shortcut should be reserved for a long-press or alternative gesture.

---

### M4. Navigator.stack accumulates within tabs with no escape hatch

**Affected file:** `lib/main.dart:294-298`, `lib/core/routes/tab_navigator.dart`

The dashboard FAB and all screen-level navigation push onto the **current tab's** `Navigator`. Over time, users accumulate deep navigation stacks (e.g., Subjects → SubjectDetail → LessonList → LessonDetail → Dashboard → Planner → ...). Pressing the system back button pops screens one-by-one within the tab, which is disorienting — users expect back to go to the previous tab or to the app's root.

**Rationale:** This is a fundamental navigation architecture issue. Users get trapped in deep stacks within a single tab with no "pop to tab root" affordance.

**Acceptance criteria (choose one):**
- **Option A:** After pushing a route, replace the current tab's stack entry (like iOS navigation). The tab always shows its "root" as the initial back destination.
- **Option B:** Add a "double-press tab to go home" behaviour that pops to the root of the current tab's navigator.
- **Option C:** Show a back-to-root FAB when the stack depth exceeds 3.

---

### M5. Fake loading indicator in practice start dialog

**Affected file:** `lib/features/practice/presentation/screens/practice_screen.dart:442-461`

`_showStartingPracticeDialog()` shows a modal `AlertDialog` with a `CircularProgressIndicator` and a hardcoded `Future.delayed(500ms)` before dismissing it. This dialog does not represent actual loading progress — it's a fake spinner that closes after a fixed duration regardless of whether the navigation has completed.

**Rationale:** Deceptive UX. If the push navigation is slow (e.g., loading questions), the dialog closes before the actual work is done. If it's fast, the user waits unnecessarily.

**Acceptance criteria:**
- Replace with an async loading overlay tied to the actual `Navigator.pushNamed` completion.
- Or remove entirely — navigation happens fast enough that this artificial delay adds only friction.

---

### M6. SessionTrackerScreen duplicates Focus Timer functionality

**Affected file:** `lib/features/sessions/presentation/session_tracker_screen.dart`

The SessionTrackerScreen has its own start/stop timer, break counter, and session logging — completely separate from the FocusTimerScreen. After ending a session, it forces the user through a dialog to manually input "questions answered" and "correct answers" before saving.

**Rationale:** Two competing timer experiences confuse users. The forced manual data entry dialog creates friction for what should be an automatic log.

**Acceptance criteria:**
- Either consolidate the two timer screens or clearly differentiate their purposes (Focus = Pomodoro timer, SessionTracker = passive analytics).
- Make the post-session dialog skippable without data entry (already has "Skip" but default values of 0/0 are misleading).
- Show the dialog counts pre-filled from actual practice data when possible.

---

### M7. Navigation on Session export: JSON export shows wrong success message

**Affected file:** `lib/features/sessions/presentation/session_history_screen.dart:126-128`

The JSON export handler calls `l10n.sessionHistoryExportedCsv` instead of a JSON-specific message. Users see "Exported as CSV" when they exported JSON.

**Rationale:** Misleading feedback, erodes trust in the export feature.

**Acceptance criteria:**
- Use `l10n.sessionHistoryExportedJson` or equivalent for the JSON export success SnackBar.

---

### M8. PracticeEmptyState snackbar doesn't navigate; dead end for new users

**Affected file:** `lib/features/practice/presentation/widgets/practice_empty_state.dart:47-54`

When the user taps the "Add Subject" CTA, a SnackBar says "Add subjects from the Subjects tab." The user must manually swipe to the Subjects tab. No automatic navigation, no deep-link.

**Rationale:** Friction for new users who don't know the app layout.

**Acceptance criteria:**
- Tapping the CTA switches the `MainScreen` tab index to 0 (Subjects).
- Add a callback parameter `onAddSubject` to `PracticeEmptyState`.

---

### M9. LessonDetailScreen shows spinner forever on error

**Affected file:** `lib/features/lessons/presentation/lesson_detail_screen.dart:96-105`

When `_loadError` is true, the screen shows a `CircularProgressIndicator` — exactly the same as the loading state. The `AppErrorHandler.handleError` is called in the catch block, which might show a SnackBar, but the screen body still renders an infinite spinner.

**Rationale:** An error state should be visually distinct from a loading state.

**Acceptance criteria:**
- When `_loadError` is true, show an error UI with:
  - An error icon/message.
  - A "Retry" button.
  - A "Go Back" button.
- Do NOT show an infinite spinner for an error state.

---

### M10. Upload screen `DropdownButtonFormField` uses unsupported `initialValue`

**Affected file:** `lib/features/ingestion/presentation/upload_screen.dart:320`

`DropdownButtonFormField` does not have an `initialValue` parameter in recent Flutter versions. This may cause a runtime error, or the parameter may be silently ignored.

**Rationale:** Either crashes or silently breaks the subject selection dropdown.

**Acceptance criteria:**
- Replace `initialValue` with `value` parameter on the `DropdownButtonFormField`.

---

### M11. QuickGuide fallback messages use English keyword matching

**Affected file:** `lib/features/quickguide/presentation/quick_guide_screen.dart:178-185`

The `_fallbackResponse` method checks the user's input for English keywords: `'explain'`, `'quiz'`, `'math'`. In Spanish locale (or any non-English locale), a user typing `"explica"` gets the generic fallback instead of the explain-specific response.

**Rationale:** LLM-dependent responses break for non-English users when the API key is not configured.

**Acceptance criteria:**
- Use localized keyword lists for fallback matching (e.g., `l10n.fallbackExplainKeywords` as a list of words to match).
- Or: send the fallback query to a simpler/cheaper local model instead of hardcoded keyword matching.

---

### M12. Dashboard header shows subject detail navigation with wrong args

**Affected file:** `lib/features/subjects/presentation/subject_detail_screen.dart:225-228`

Navigating to the dashboard from the subject detail screen passes `{'studentId': ...}` (a `Map`) as route arguments. The router expects `DashboardArgs` or `null`. The Map is silently ignored, and a new `StudentIdService().getStudentId()` is used. The code works by accident but sets a bad pattern.

**Rationale:** Silent argument mismatch indicates fragile coupling between screens and the router.

**Acceptance criteria:**
- Use `DashboardArgs(studentId: StudentIdService().getStudentId())` instead of a raw Map.

---

### M13. Focus mode break timer leaks after navigating away

**Affected file:** `lib/features/focus_mode/presentation/focus_timer_screen.dart:96-113`

If the user enters a break and navigates to another screen, `_breakTimer` continues firing. The callback checks `mounted` and calls `setState` — safe from crashing, but the timer continues consuming resources and the break state is lost when the user returns.

**Rationale:** Resource leak and state inconsistency when the user leaves mid-break.

**Acceptance criteria:**
- Cancel `_breakTimer` in `dispose()` (already done, but verify it's effective when timer is running).
- Persist break state or reset on return.

---

## MINOR — Code quality / UX friction / accessibility

### m1. Hardcoded Colors.white in SubjectDetailScreen ignores theme

**Affected file:** `lib/features/subjects/presentation/subject_detail_screen.dart:63,109,116,127`

Title, subtitle, and icon-button inside the SliverAppBar are hardcoded to `Colors.white`. In high-contrast mode or with bold text enabled, white-on-gradient may not provide sufficient contrast.

**Rationale:** Accessibility violation — ignores user's high-contrast and bold-text preferences.

**Acceptance criteria:**
- Use `colorScheme.onPrimary` or `colorScheme.onSurface` instead of hardcoded white.
- Verify contrast ratios meet WCAG AA standards.

---

### m2. Three separate chat/message implementations with inconsistent styling

**Affected files:**
- `lib/features/mentor/presentation/mentor_screen.dart` — uses `ChatBubble` from `teaching/presentation/widgets/chat_bubble.dart`
- `lib/features/teaching/presentation/tutor_screen.dart` — uses the same `ChatBubble`
- `lib/features/quickguide/presentation/quick_guide_screen.dart` — uses `MessageListWidget` from within quickguide

The Mentor and Tutor screens share a `ChatBubble` widget, but the QuickGuide screen has its own message rendering with different styling, different scroll behaviour, and different empty states.

**Rationale:** Three chat UIs means three places to fix bugs, three different interaction patterns, inconsistent visual language.

**Acceptance criteria:**
- Extract a shared `ChatMessageList` widget that all three screens use.
- Ensure consistent styling, scrolling, and accessibility across all chat surfaces.

---

### m3. Accessibility: Inconsistent `MergeSemantics` usage

**Affected files:**
- `lib/features/practice/presentation/screens/practice_results_screen.dart:38,42,46` — uses `MergeSemantics` around stat rows
- `lib/features/settings/presentation/profile_screen.dart:206` — uses `MergeSemantics` around avatar choices

`MergeSemantics` merges the semantics of a widget subtree into a single node. When used around a Row of "Label: Value", the screen reader announces them as one concatenated string. This may or may not produce grammatical announcements depending on locale.

**Rationale:** Inconsistent and potentially incorrect screen reader output.

**Acceptance criteria:**
- Audit all `MergeSemantics` usages.
- Replace with explicit `Semantics` labels or `ExcludeSemantics` where appropriate.
- Ensure each `MergeSemantics` usage has been tested with TalkBack/VoiceOver.

---

### m4. No keyboard shortcuts for tab navigation

**Affected file:** `lib/main.dart:253-421`

The 5-tab navigation (Subjects, Practice, Mentor, Focus, Settings) has no keyboard shortcuts. Desktop/web users cannot quickly switch between tabs.

**Rationale:** Power-user friction on desktop/web platforms.

**Acceptance criteria:**
- Add `LogicalKeySet(LogicalKeyboardKey.digit1)` through `digit5` bindings to switch tabs.
- Show shortcut hints in tooltips.

---

### m5. Dashboard `valueOrNull` fallback pattern leads to misleading partial renders

**Affected file:** `lib/features/dashboard/presentation/dashboard_screen.dart:42-58`

Each of the 8 watched providers falls back to a default (empty list, zero values) via `valueOrNull`. If one provider has data and another is still loading, the user sees a partially populated dashboard. The `allEmpty` flag only triggers when ALL providers are empty — but partial data with some still-loading providers renders mixed states.

**Rationale:** The loading logic is fragile. A partial render with missing sections is confusing.

**Acceptance criteria:**
- Track which providers have returned data vs. are still loading.
- Only render the dashboard when all data-dependent providers have resolved, OR show skeleton placeholders for still-loading sections.

---

### m6. Upload screen silent failure when pipeline is null

**Affected file:** `lib/features/ingestion/presentation/upload_screen.dart:126-159`

`_fetchUrlContent` immediately returns if `widget.pipeline` is null (line 127-128). The user sees no feedback — the button click does nothing.

**Rationale:** Silent failure — user action produces zero response.

**Acceptance criteria:**
- Show a SnackBar: "Content pipeline not available" when `widget.pipeline` is null.
- Consider providing a default pipeline instance instead of making it nullable.

---

### m7. Settings screen reads Hive box directly (bypassing repository pattern)

**Affected file:** `lib/features/settings/presentation/settings_screen.dart:366-374`

`_getDailyCapLabel` calls `Hive.box(HiveBoxNames.settings).get(...)` directly instead of going through the `SettingsRepository`. The try/catch silently swallows errors, returning "No limit".

**Rationale:** Inconsistent data access pattern; fragile; error states are hidden.

**Acceptance criteria:**
- Add a `getDailyCap()` method to `SettingsRepository`.
- Use the provider/repository chain instead of direct Hive access.

---

### m8. Planner error message only shows on first tab

**Affected file:** `lib/features/planner/presentation/planner_screen.dart:353`

The planner error display is gated by `_tabController.index == 0`. If the user is on the Calendar or Roadmaps tab when an error occurs, it's not visible.

**Rationale:** Errors may go unnoticed when the user switches tabs.

**Acceptance criteria:**
- Show errors in a persistent banner (above the tab bar or as a SnackBar) regardless of which tab is active.

---

### m9. Single FadeTransition for all route navigation

**Affected file:** `lib/core/routes/app_router.dart:253-264`

Every route uses `FadeTransition`. There's no platform-adaptive transition (slide-up on iOS, no transition on Android). Fade-only navigation feels generic and doesn't communicate direction (forward/back).

**Rationale:** Navigation lacks platform-appropriate motion cues.

**Acceptance criteria:**
- Use platform-adaptive transitions:
  - Android: `FadeTransition` or shared element.
  - iOS: `CupertinoPageRoute` slide-from-right.
  - Desktop: minimal transition or slide.

---

### m10. All chat screens use hardcoded `Duration(milliseconds: 100)` for scroll animation

**Affected files:**
- `lib/features/mentor/presentation/mentor_screen.dart:199`
- `lib/features/teaching/presentation/tutor_screen.dart:237`
- `lib/features/quickguide/presentation/quick_guide_screen.dart:195`

The scroll-to-bottom animation is 100ms `easeOut` everywhere. While consistent, this is not configurable and does not respect the user's animation settings beyond the `reduceMotion` toggle.

**Rationale:** Minor accessibility concern — some users with vestibular disorders may prefer slower animations.

**Acceptance criteria:**
- Use a configurable scroll duration (e.g., `kScrollDuration` constant) that can be adjusted.
- When `reduceMotion` is enabled, use `jumpTo` (already implemented).

---

### m11. Font weight inconsistency across headings

**Affected files (partial list):**
- `lib/features/subjects/presentation/subject_list_screen.dart:70` — `fontWeight: FontWeight.bold` on headlineSmall.
- `lib/features/dashboard/presentation/widgets/dashboard_header.dart:19` — `fontWeight: FontWeight.bold` on headlineMedium.
- `lib/features/settings/presentation/settings_screen.dart:178` — `fontWeight: FontWeight.bold` on titleMedium.

Some screens use `FontWeight.bold`, others use `FontWeight.w600`. The theme does not define a consistent font weight for each text style.

**Rationale:** Minor visual inconsistency across screens.

**Acceptance criteria:**
- Define the desired font-weight for each text style in the `TextTheme` definition in `app_theme.dart`.
- Remove inline `fontWeight` overrides from screen widgets.

---

### m12. SubjectCard in subject list shows icon with hardcoded `Icons.school`

**Affected file:** `lib/features/subjects/presentation/subject_list_screen.dart:142`

Every subject card shows the `Icons.school` icon regardless of the subject type. This is visually repetitive and doesn't help users distinguish subjects.

**Rationale:** Missed opportunity for visual differentiation.

**Acceptance criteria:**
- Allow subjects to have a configurable icon (stored in the Subject model).
- Fallback to `Icons.school` when no icon is set.

---

### m13. Upload screen text input uses `TextStyle(fontSize: 16)` instead of theme text style

**Affected file:** `lib/features/ingestion/presentation/upload_screen.dart:300`

The `"Add study materials"` label uses a hardcoded `TextStyle(fontSize: 16)` instead of `Theme.of(context).textTheme.bodyLarge`.

**Rationale:** Inconsistent with the design system; ignores user's font size setting.

**Acceptance criteria:**
- Replace with `Theme.of(context).textTheme.bodyLarge`.

---

### m14. Animation jarring: practice session `AnimatedSwitcher` slide distance

**Affected file:** `lib/features/practice/presentation/screens/practice_session_screen.dart:455-471`

The `AnimatedSwitcher` uses `Offset(0.15, 0.0)` slide distance (15% of widget width). Combined with a `FadeTransition`, the question card appears to slide slightly while fading. The short 100ms duration makes the slide barely perceptible, which may feel like a glitch rather than a deliberate transition.

**Rationale:** Very short duration + small offset = transition that looks like an animation bug.

**Acceptance criteria:**
- Increase the slide distance to `Offset(0.5, 0.0)` for a more deliberate slide.
- OR increase duration to 200-300ms.
- OR use a simple cross-fade without slide for a cleaner feel.

---

### m15. No haptic feedback on key actions

**Affected files across the app:**

Actions like submitting an answer, completing a session, or toggling settings switches provide no haptic feedback. On mobile, this makes interactions feel flat.

**Rationale:** Haptic feedback improves perceived responsiveness and accessibility.

**Acceptance criteria:**
- Add `HapticFeedback.lightImpact()` on answer submission.
- Add `HapticFeedback.mediumImpact()` on session completion.
- Add `HapticFeedback.selectionClick()` on tab switches and toggle changes.

---

### m16. Dashboard cards lack descriptive semantic hints

**Affected file:** `lib/features/dashboard/presentation/dashboard_screen.dart:87-169`

Each `CollapsibleCard` has a title with an `Icon` and `Text`, but there's no hint explaining that tapping the title refreshes the card's data (`onRetry`). Screen reader users won't know the tap action exists.

**Rationale:** Missing accessibility semantics for an interactive element.

**Acceptance criteria:**
- Add `Semantics(hint: "Tap to refresh this section")` to each collapsible card's header.

---

### m17. Focus mode duration preset includes 5 minutes — too short to be useful

**Affected file:** `lib/features/focus_mode/presentation/focus_timer_screen.dart:304`

The presets list includes `5` minutes. A 5-minute "focus" session is too short to be productive and adds visual noise to the preset chips.

**Rationale:** Unhelpful default option clutters the UI.

**Acceptance criteria:**
- Change the minimum preset to `10` or `15` minutes, keeping 1–180 range on the slider.

---

### m18. SessionHistoryScreen shares same export icon for CSV and PDF comprehensively

**Affected file:** `lib/features/sessions/presentation/session_history_screen.dart:315-338`

Both "Export CSV" and "Comprehensive CSV" use `Icons.assessment`. Both "Export PDF" and "Comprehensive PDF" use `Icons.picture_as_pdf`. Users can't visually distinguish standard from comprehensive exports.

**Rationale:** Visual confusion in the export menu.

**Acceptance criteria:**
- Use different icons for comprehensive export variants (e.g., `Icons.assignment` for comprehensive).
- Or add a "Comprehensive" prefix badge to the menu items.

---

### m19. Planner screen dialog controllers leak if dismissed via back button

**Affected file:** `lib/features/planner/presentation/planner_screen.dart:123-188`

`goalController` and `daysController` are created with `TextEditingController()` inside the dialog builder. They are disposed via `addPostFrameCallback` after the dialog completes, but if the user dismisses the dialog via the system back button, the callback runs on a potentially stale context.

**Rationale:** Minor memory leak risk.

**Acceptance criteria:**
- Dispose controllers in a `finally` block after the dialog completes.
- Use a `StatefulBuilder` with proper lifecycle management.

---

### m20. No onboarding flow for first-launch users

**Observation:** The QuickGuide screen exists and is accessible from Settings, but there is no automatic first-launch onboarding flow. New users are dropped into the Subjects tab with an empty list and must discover all features themselves.

**Rationale:** Steep learning curve for new users.

**Acceptance criteria:**
- On first launch, show a welcome dialog or a brief carousel introducing: Subjects, Practice, Mentor, Focus, and Planner.
- Alternatively, auto-open the QuickGuide screen on first launch.

---

### m21. `largeTouchTargets` setting declared but not implemented in widgets

**Affected file:** `lib/features/settings/presentation/settings_screen.dart:66-73` (setting exists)
**Not implemented in:** Throughout the app (no widget reads `largeTouchTargets`)

The accessibility setting `largeTouchTargets` is persisted but no widget actually uses it to increase its touch target size. The setting is a dead affordance.

**Rationale:** Accessibility setting does nothing — misleading for users who enable it.

**Acceptance criteria:**
- Audit all tappable widgets (IconButtons, ListTiles, chips, etc.).
- When `largeTouchTargets` is true, increase `minSize` to 56x56 or apply a `MediaQuery` padding.
- Or remove the setting if it's not going to be implemented.

---

## SUMMARY

| Severity | Count |
|----------|-------|
| BLOCKER  | 3 |
| MAJOR    | 13 |
| MINOR    | 21 |
| **Total** | **37** |

### Quick wins (can fix in <30 min each):
- `m1` — Replace hardcoded white in SubjectDetailScreen
- `m6` — Show SnackBar when pipeline is null in UploadScreen
- `m12` — Hardcoded `Icons.school` in subject cards
- `m13` — Hardcoded `fontSize: 16` in upload screen
- `m18` — Different icons for comprehensive export menu items
- `M7` — Fix JSON export success message
- `M10` — Fix `initialValue` → `value` in upload dropdown
