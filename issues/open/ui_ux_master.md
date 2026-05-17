# UI/UX Master — Comprehensive User Experience Issue

## Executive Summary

Systemic audit of all 27 screens, 6 core widgets, the theme system, navigation, and accessibility across StudyKing. Findings are grouped by severity and affect approximately 35+ source files. Key themes: pervasive hardcoded English strings on 4 screens creating mixed-language UI for Spanish users, silent loading deadlocks where error handlers leave permanent spinners, missing error states that show empty lists instead of failures, and accessibility issues including double-announced semantics and sub-48px touch targets.

---

## BLOCKER

*None identified at the BLOCKER level. The app compiles, tests pass, and no crash-path was found in normal operation. However, several issues (notably the hardcoded English strings on ingestion/screens) defeat the entire purpose of the existing Spanish l10n system.*

---

## MAJOR

### M1. Hardcoded English Strings on 4 Screens Defeat l10n System

**Context:** The app has a complete English + Spanish localization pipeline (`lib/l10n/app_en.arb`, `app_es.arb`, generated localizations). However, 4 screens bypass it entirely with hardcoded English user-facing strings. Any user with `es` locale sees a mixed-language UI.

**Affected files:**
- `lib/features/ingestion/presentation/content_library_screen.dart` — ~30 hardcoded strings (lines 174, 179, 183, 223, 248, 252, 257, 260-263, 343, 350, 357, 390, 417, 443, 504-505, 567): 'Content Library', 'Sort order', 'Sort by', 'Date', 'Title', 'Status', 'Type', 'All subjects', 'All types', 'All statuses', 'Delete Source', 'Are you sure...', 'Also delete questions...', 'Source deleted', 'Reprocess'
- `lib/features/ingestion/presentation/source_detail_screen.dart` — ~25 hardcoded strings (lines 75, 119-120, 123, 172, 232, 296-302, 318, 329-350, 356-365, 370-399, 409-414, 443-456, 470-499, 512): 'Source not found', 'Reprocess Source', 'Reprocessing will replace...', 'Continue', 'Reprocess failed:', 'Source Detail', 'Status', 'Subject', 'Type', 'ID', 'Uploaded', 'Processing failed', 'Topic Classification', 'Not yet classified', 'Classify Now', 'Summary', 'No summary available', 'Extracted Text', 'Search in text', 'No extracted text available', 'Generated Questions', 'No questions from this source', 'Reprocess', 'Delete', 'Select Topic', 'Delete Source', 'Source deleted'
- `lib/features/questions/presentation/question_bank_screen.dart` — ~20 hardcoded strings (lines 119-120, 140, 158-159, 183, 196, 203, 209, 251, 256, 261, 267, 352, 356-358, 373, 375-377, 413, 426-441, 475, 499, 523): 'Question Bank', 'Cancel selection', 'Delete selected', 'Select multiple', 'Search questions', 'All subjects', 'All types', 'All sources', 'Delete Question', 'Question deleted', 'Edit Question', 'Question text', 'Explanation', 'question(s) deleted', 'Edit', 'Delete', 'Difficulty ', 'source(s)', 'AI-generated', 'Manual'
- `lib/features/subjects/presentation/subject_detail_screen.dart` — ~5 hardcoded strings (lines 168, 249, 252, 457, 475): 'Sources', 'View Sources', '$_sourceCount Source(s)', 'No sources for this subject', '${_items.length} Source(s)'

**Rationale:** The project invested in a complete ARB-based l10n pipeline with both English and Spanish locales. Bypassing it on 4 screens means Spanish users see a confusing mixed-language UI — localized navigation/discovery elements mixed with English content/source management labels. This nullifies the l10n investment for the ingestion and question-management workflows.

**Acceptance criteria:**
- [ ] Every hardcoded string listed above is replaced with `l10n.xxx` from `AppLocalizations`
- [ ] New ARB keys are added to both `app_en.arb` and `app_es.arb` for all replaced strings
- [ ] Generated localizations are regenerated (`flutter gen-l10n`)
- [ ] Screen renders entirely in Spanish when locale is set to `es`


### M2. Silent Loading Deadlocks After Error Handler Dialogs

**Context:** On at least 2 screens, when `AppErrorHandler.handleError()` shows a dialog for a loading failure, the `_isLoading = true` flag is never reset to `false`. After dismissing the error dialog, the user sees a permanent `CircularProgressIndicator` with no way to proceed.

**Affected files:**
- `lib/features/lessons/presentation/topic_list_screen.dart:39` — `AppErrorHandler.handleError()` on fetch failure; `_isLoading` stays `true` indefinitely (line 37-55 logic)
- `lib/features/lessons/presentation/lesson_list_screen.dart:50-56` — `AppErrorHandler.handleError()` on load failure; `_isLoading` stays `true`

**Rationale:** This is a navigation dead-end disguised as a loading state. User taps a button, sees a spinner, an error dialog appears, they dismiss it, and the spinner remains forever. The only escape is app restart. This is functionally equivalent to a crash for the user.

**Acceptance criteria:**
- [ ] After `AppErrorHandler.handleError()` is called, `_isLoading` is set to `false`
- [ ] The screen shows a proper inline error widget (icon + message + retry button) instead of the spinner
- [ ] Retry button re-triggers the load


### M3. Missing Error States on Screens That Silently Show Empty Data

**Context:** 6+ screens use `valueOrNull` on async Riverpod values or silently catch exceptions in `try/catch` blocks with empty `catch` bodies, then render empty states instead of error messages. Users are misled into thinking there's no data when there's actually a failure.

**Affected files:**
- `lib/features/dashboard/presentation/dashboard_screen.dart:46-66` — Uses `valueOrNull ?? []` so provider errors produce empty state (`EmptyDashboardChecklist`) instead of error UI
- `lib/features/sessions/presentation/session_history_screen.dart:53-54` — Error is only `debugPrint()`'d; UI shows empty list
- `lib/features/sessions/presentation/session_tracker_screen.dart:84-88` — Error logged; UI shows empty data
- `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart` — No error state at all; provider failure shows empty state
- `lib/features/settings/presentation/settings_screen.dart:60` — `settingsProvider` watched with no error fallback
- `lib/features/subjects/presentation/subject_detail_screen.dart:437-440` — `_SubjectSourcesTab` `catch` block silently sets `_isLoading = false` with no error message

**Rationale:** Users who lose connectivity or hit a DB error are told "you have no data" rather than "something went wrong." This erodes trust and makes debugging impossible without developer tools. The guidance from Material Design and common UX practice is clear: errors must be distinguishable from empty states.

**Acceptance criteria:**
- [ ] All 6 screens check `hasError` on async values (for Riverpod) or catch exceptions (for manual futures)
- [ ] Error states show: a descriptive icon, a localized error message, and a retry/try-again action
- [ ] Empty states continue to show "no data" messaging for legitimate empty results
- [ ] Users can distinguish "network error" from "no sessions recorded" visually


### M4. No Loading Indicator on Profile Screen Initial Load

**Context:** `ProfileScreen` loads user data asynchronously in `_loadUserData()` (profile_screen.dart:69-73) but renders the form immediately with empty `TextEditingController` fields. The fields populate silently with no visual feedback.

**Affected file:** `lib/features/settings/presentation/profile_screen.dart:69-73`

**Rationale:** The screen appears "ready" with empty form fields, then suddenly fills in. For users with slow storage or large profiles, this creates a jarring pop-in effect. Screen reader users may encounter "empty field, empty field, empty field" followed by sudden data.

**Acceptance criteria:**
- [ ] A `CircularProgressIndicator` or skeleton is shown while `_loadUserData()` is in flight
- [ ] The form only renders after data is fully loaded
- [ ] Error state is shown if `_loadUserData()` fails (currently silences errors with default values)


### M5. `NotFoundScreen` Pushes Duplicate Dashboard Instead of Switching Tabs

**Context:** The 404 fallback (`NotFoundScreen`) navigates to `/dashboard` using `Navigator.pushNamedAndRemoveUntil(AppRoutes.dashboard, (_) => false)`. Since the app uses a tab-based `MainScreen` with 6 independent `Navigator` stacks, this pushes a new `DashboardScreen` on top of the tab shell, creating a duplicate dashboard outside the tab structure.

**Affected files:**
- `lib/core/widgets/not_found_screen.dart:50` — uses `pushNamedAndRemoveUntil`
- `lib/core/routes/app_router.dart` — the 404 route returns `NotFoundScreen`

**Rationale:** User hits a broken link, sees 404, taps "Go to Dashboard", and lands on a full-screen dashboard with no tab bar and no way to access other tabs. The only escape is back navigation (which may be broken if they used push). This is a navigation dead-end.

**Acceptance criteria:**
- [ ] The "Go to Dashboard" button on `NotFoundScreen` switches to the dashboard tab within `MainScreen` rather than pushing a full-screen route
- [ ] Options: use a callback, a global tab controller, or pop back then switch tab index
- [ ] The tab bar remains visible after navigation


### M6. Exam Results "Done" Button Returns to Config, Not Practice Home

**Context:** In `ExamSessionScreen`, when results are shown, the "Done" button calls `Navigator.pop(context)`. In exam mode, this pops back to the exam config screen (the same screen that shows question count sliders and start button), not to the main practice screen. User must press "back" again to reach practice home.

**Affected file:** `lib/features/practice/presentation/screens/exam_session_screen.dart:613`

**Rationale:** After completing a full exam, users expect "Done" to return to the practice hub. Instead they see the pre-exam configuration screen again, which is confusing — especially if they already saw the results.

**Acceptance criteria:**
- [ ] "Done" in exam results navigates to the main practice screen (`/practice` or equivalent)
- [ ] "Done" in practice session results continues to use `Navigator.pop` or callback (existing behavior preserved for that flow)
- [ ] Clear visual distinction: exam results has a "Back to Practice" / "Done" button that exits cleanly


### M7. `ApiKeyBanner` Uses Deprecated `MaterialBanner`

**Context:** The `ApiKeyBanner` shown on `MainScreen` when no API key is configured uses `MaterialBanner`, which is deprecated in Flutter ≥3.10. It may produce deprecation warnings or break in future Flutter versions.

**Affected files:**
- `lib/main.dart:156` — usage of `MaterialBanner`
- `lib/features/onboarding/presentation/onboarding_dialog.dart:148-173` — `ApiKeyBanner` definition

**Rationale:** Deprecated widgets are removed in later Flutter versions. The banner is a critical user-facing component (without an API key, the app's LLM features don't work). Its removal would silently break the setup flow.

**Acceptance criteria:**
- [ ] `ApiKeyBanner` is migrated from `MaterialBanner` to a custom `Container`-based banner or a non-deprecated equivalent
- [ ] Visual appearance (icon, colors, dismiss behavior) is preserved
- [ ] The banner is still dismissable and has "Configure" / "Dismiss" actions


### M8. High Contrast Theme Drops Input Decoration Fields via `.copyWith()`

**Context:** The high-contrast theme variants use `.copyWith()` on `inputDecorationTheme` but only re-specify `border`-related fields. Fields like `filled`, `fillColor`, `labelStyle`, `hintStyle`, `errorStyle`, `disabledBorder`, `errorBorder`, and `focusedErrorBorder` inherited from `_baseTheme()` are lost because `.copyWith()` replaces the entire `InputDecorationTheme`.

**Affected file:** `lib/core/theme/app_theme.dart:184-210, 266-292`

**Rationale:** Users who enable high-contrast mode (an accessibility feature) get input fields with missing styles — no fill, no hint styling, no error styling. This can make text fields harder to read, defeating the purpose of high-contrast mode.

**Acceptance criteria:**
- [ ] High contrast `inputDecorationTheme` copies all fields from `_baseTheme` before overriding border thickness
- [ ] Alternative: use a custom merge function that deep-merges `InputDecorationTheme` properties
- [ ] High contrast input fields have visible fill, proper label/hint/error colors, and thicker borders


### M9. No Shared Loading Widget — 32 Inline `CircularProgressIndicator` Repetitions

**Context:** Every screen independently implements `Center(child: CircularProgressIndicator(...))` with inconsistent `strokeWidth` (default, 2, sometimes wrapped in `SizedBox`). There is no shared loading widget in `lib/core/widgets/`. The `ResponsiveUtils.loaderInTouchTarget()` helper exists but is only used in 2 places.

**Affected files:** 20+ feature screen files, notably:
- `subject_list_screen.dart:36` — `const Center(child: CircularProgressIndicator())`
- `practice_screen.dart:542` — `const Center(child: CircularProgressIndicator())`
- `session_history_screen.dart:349` — same
- `planner_screen.dart:895` — same
- `focus_timer_screen.dart:290` — same
- `tutor_screen.dart:455` — same
- (27 more instances across all screens)

**Rationale:** (1) Inconsistent visual: some screens show a tiny spinner (`strokeWidth: 2`), others the default. (2) No accessibility: none of these spinners have `Semantics` labels like "Loading...". (3) Maintenance: any change to loading appearance requires touching 20+ files.

**Acceptance criteria:**
- [ ] A `LoadingScreen` widget is created in `lib/core/widgets/` (e.g., `CenteredLoader` or `LoadingIndicator`)
- [ ] It accepts optional `strokeWidth`, `color`, `message` (localized), and `semanticsLabel`
- [ ] All 32 inline `CircularProgressIndicator` usages in presentations are replaced with the shared widget
- [ ] The shared widget wraps the spinner in `Semantics(label: l10n.loading, liveRegion: true)`


### M10. Inaccessible Conversation Input — Double Semantics Wrapping

**Context:** `ConversationInput` wraps both `TextField` and `IconButton.filled` in additional `Semantics` wrappers that duplicate what those widgets already announce. Screen readers may read each element twice.

**Affected file:** `lib/core/widgets/conversation_input.dart:75-78, 125-150`

**Specific issues:**
- `TextField` is wrapped in `Semantics(label:, hint:)` (line 75-78). `TextField` already has its own semantics node. The outer `Semantics` adds a duplicate node that reads "label hint text field editing" instead of the intended single announcement.
- `IconButton.filled` (send button, line 144) already derives semantics from its `tooltip` parameter. The outer `Semantics(button: true, label: ...)` (line 125-130) creates a second node with the same label. Sighted users see `tooltip` text that doesn't change during loading; screen reader users hear changing `Semantics` label — inconsistency.

**Rationale:** Screen reader users experience double announcements or conflicting information. This makes the primary input mechanism of the chat/Mentor feature confusing to use with TalkBack or VoiceOver.

**Acceptance criteria:**
- [ ] Remove outer `Semantics` from `TextField`; pass `semanticsLabel` directly to `TextField`'s `semanticsProperties` or use `InputDecoration.semanticsLabel`
- [ ] Remove outer `Semantics` from send `IconButton.filled`; use `tooltip` property that changes based on loading state (e.g., `widget.isLoading ? l10n.sending : widget.sendTooltip`)
- [ ] Verify with Flutter's Semantics debugger that no duplicate nodes exist
- [ ] Ensure screen reader announces exactly one meaningful label per interactive element


### M11. WCAG Contrast Failure on ConversationInput Hint Text

**Context:** The chat input hint text uses `onSurfaceVariant.withValues(alpha: 0.6)` layered on a `surfaceContainerHighest.withValues(alpha: 0.5)` fill background. The compound alpha reduction (60% of `onSurfaceVariant` over 50% of `surfaceContainerHighest`) produces an estimated contrast ratio of ~3:1, failing WCAG AA (minimum 4.5:1 for small text).

**Affected file:** `lib/core/widgets/conversation_input.dart:87-89, 92-93`

**Rationale:** Hint text ("Type a message...") is small text (14px, bodySmall) at a contrast ratio that fails WCAG AA. Users with low vision or on bright/low-quality displays cannot read the hint text.

**Acceptance criteria:**
- [ ] Hint text contrast ratio is ≥ 4.5:1 against the actual rendered background
- [ ] Possible fixes: remove or reduce alpha on hint text color, use `onSurfaceVariant` directly without alpha, or adjust fill background opacity
- [ ] Visual design remains consistent (the translucent input look is intentional)


### M12. Missing Semantic Heading on `NotFoundScreen` (Heading Hierarchy Inverted)

**Context:** `NotFoundScreen` sets `Semantics(headingLevel: 1)` on an icon widget (line 22-28) and `Semantics(headingLevel: 2)` on the title text (line 31-38). Screen reader users navigating by headings hear the icon first as the most important heading, then the text as a sub-heading.

**Affected file:** `lib/core/widgets/not_found_screen.dart:22-38`

**Rationale:** Standard heading hierarchy is: page title = H1, sections = H2, sub-sections = H3. An icon should not be a heading at all. This creates confusion for screen reader users who rely on heading structure for navigation.

**Acceptance criteria:**
- [ ] The title text is wrapped in `Semantics(headingLevel: 1)`
- [ ] The icon has no heading role (or is wrapped in `ExcludeSemantics` / marked as decorative)
- [ ] Description text (if any) has no heading role


### M13. Hardcoded `Colors.green` in `statusColor` — Not Theme-Adaptive

**Context:** `AppTheme.statusColor()` returns hardcoded `Colors.green` (Material 400) for `LlmTaskStatus.done`. This is the only non-`ColorScheme` color in the theme's status color functions and does not adapt to dark mode or high-contrast mode.

**Affected file:** `lib/core/theme/app_theme.dart:253`

Additionally, 6+ feature files hardcode `Colors.green`/`Colors.red`/`Colors.orange` for inline status indicators instead of using `AppTheme.statusColor()`, `progressColor()`, or `masteryColor()`:
- `lib/features/planner/presentation/planner_screen.dart:484` — `Colors.red`
- `lib/features/teaching/presentation/tutor_screen.dart:498-518` — multiple hardcoded colors
- `lib/features/subjects/presentation/subject_detail_screen.dart:486-489` — green/red/orange
- `lib/features/ingestion/presentation/content_library_screen.dart:105-113` — green/red/orange
- `lib/features/ingestion/presentation/source_detail_screen.dart` — hardcoded status colors

**Rationale:** Hardcoded `Colors.green` appears as the same shade in both light and dark mode. In dark mode, material green 400 on a dark surface may have insufficient contrast. Users who customize the theme seed color expect status colors to adapt.

**Acceptance criteria:**
- [ ] `statusColor()` uses `colorScheme.tertiary`, `colorScheme.primary`, or a derived color instead of `Colors.green`
- [ ] Status colors in all 6+ feature files are replaced with calls to `AppTheme.statusColor()`, `progressColor()`, or `masteryColor()`
- [ ] Colors adapt correctly in light mode, dark mode, and high-contrast mode


### M14. No Tooltips on Icon-Only Buttons (Only 1 Tooltip in Entire Feature Layer)

**Context:** Audit found exactly 1 `Tooltip` usage in the entire features presentation layer (`collapsible_card.dart:86`). The other ~37 `IconButton` usages and navigation icons have no tooltips, making their purpose ambiguous to sighted users unfamiliar with the icon, and leaving screen reader users reliant solely on potentially incomplete `Semantics` labels.

**Affected files:** All files with `IconButton` not wrapped in `Tooltip`, including:
- `mentor_screen.dart:250`
- `planner_screen.dart:483, 716, 734, 741`
- `question_bank_screen.dart:254, 259, 265`
- `upload_screen.dart:469`
- `content_library_screen.dart:250, 565`
- `source_detail_screen.dart:256, 341`
- `settings_screen.dart` (multiple)
- (Many more across features)

**Rationale:** `IconButton` with no `tooltip` and no explicit `Semantics` label provides no visual hint of its purpose. While most `IconButton` instances have a `Semantics` wrapper (which helps screen readers), sighted users see an unlabeled icon. Material Design guidelines state that all icon buttons should have a tooltip.

**Acceptance criteria:**
- [ ] Every `IconButton` in the features layer has a `tooltip` parameter set to a localized string
- [ ] Automated check: grep for `IconButton(` not followed by `tooltip:`; all results addressed
- [ ] Tooltips match the `Semantics` label (if both exist) to ensure consistency


### M15. Onboarding Dialog Has 3 CTAs with Different Destinations — Confusing First Launch

**Context:** The `OnboardingDialog` shows three action buttons:
1. "Add Subjects" — navigates to subject selection
2. "Quick Guide" — navigates to quick guide
3. "Dismiss" — closes dialog

These three CTAs compete for attention. A first-time user has no context for which path to take. The "right" choice (add subjects first) is not visually distinguished from "Quick Guide" or "Dismiss."

**Affected file:** `lib/features/onboarding/presentation/onboarding_dialog.dart:79-105`

**Rationale:** Onboarding should guide users through a clear, linear path or offer minimal, well-prioritized choices. Three unprioritized CTAs on a first-launch dialog is confusing and may lead users to dismiss without setting up their subjects (leaving them on a blank dashboard).

**Acceptance criteria:**
- [ ] The onboarding flow has a clear primary action (e.g., "Add Subjects" as a prominent `FilledButton`)
- [ ] Secondary actions are visually de-emphasized (`TextButton`) and fewer in number
- [ ] Alternatively: convert to a multi-step onboarding (step 1: welcome + subjects, step 2: quick guide option)
- [ ] A single "Get Started" CTA with sequential setup wizard is preferred over 3 parallel choices


### M16. Sign Out Clears API Key but Leaves User on Same Screen With No Feedback

**Context:** The "Sign Out" action in `SettingsScreen` clears the API key and model setting (lines 862-883) but does not navigate anywhere, show a confirmation, or clear other user data. The user remains on the settings screen with an empty API key field and no indication of what happened.

**Affected file:** `lib/features/settings/presentation/settings_screen.dart:862-883`

**Rationale:** "Sign Out" implies a clear state transition. The current implementation is silent and incomplete — user data (subjects, practice history, sessions) is not cleared, no confirmation is shown, and the user must figure out that their API key was removed. This is a confusing, dead-end UX.

**Acceptance criteria:**
- [ ] "Sign Out" shows a confirmation dialog: "This will clear your API key and local data. Continue?"
- [ ] On confirm: optionally clear subject/topic/session data, show a loading indicator, then navigate to onboarding or a "welcome back" screen
- [ ] A success SnackBar or dialog confirms sign-out is complete
- [ ] User is not left on the settings screen with no clear next step


### M17. No Retry Mechanism on LLM Task Manager for Stalled/Crashed Tasks

**Context:** `LlmTaskManagerScreen` shows task status (queued/running/done/failed/cancelled) with no retry action for failed tasks. If an LLM task fails, the user sees "failed" with no way to retry.

**Affected file:** `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart`

**Rationale:** LLM tasks (content processing, question generation) can fail due to transient API errors. A "Retry" button on failed tasks is the standard UX pattern and is expected by users.

**Acceptance criteria:**
- [ ] Failed tasks show a "Retry" button or IconButton
- [ ] Retry re-submits the task via `LlmTaskManager`
- [ ] Task status updates after retry (queued → running → done/failed)


### M18. Unlabeled Subject ID Field in Create Roadmap Dialog

**Context:** The "Create Roadmap" dialog in PlannerScreen has a text field with the hint/label "Student ID" (line 222), but it actually expects a subject ID. The label is confusing — users will wonder why they need to provide a student ID.

**Affected file:** `lib/features/planner/presentation/planner_screen.dart:186-264 (line 222)`

**Rationale:** Mislabeled form fields cause data entry errors and user confusion. The field should clearly indicate what it expects (e.g., "Subject" or "Subject ID").

**Acceptance criteria:**
- [ ] The field label/hint is changed to "Subject" or "Subject ID"
- [ ] Validation matches the label (e.g., validates it's a valid subject reference)
- [ ] Localized string is used

---

## MINOR

### m1. Static Non-Animated Skeleton on Dashboard

**Context:** `DashboardScreen` shows a hand-rolled skeleton (lines 275-308) that is just static grey boxes with no shimmer/pulse animation. It looks incomplete compared to animated loading states.

**Affected file:** `lib/features/dashboard/presentation/dashboard_screen.dart:275-308`

**Rationale:** Static grey boxes look like a rendering bug. Animated skeletons (shimmer) are the established Material pattern and signal "content is loading" vs. "content is broken."

**Acceptance criteria:**
- [ ] Dashboard skeleton uses a subtle shimmer/pulse animation (e.g., `AnimatedContainer` with cycling opacity or a custom `ShimmerWidget`)


### m2. "Show More Details" Tooltip on CollapsibleCard Is the Only Tooltip

**Context:** The only `Tooltip` usage in the entire features layer is on `collapsible_card.dart:86`. All other icon-only buttons rely solely on `Semantics` for discovery.

**Affected file:** `lib/features/dashboard/presentation/widgets/collapsible_card.dart:86`

**Rationale:** Inconsistent with rest of app — this card has a tooltip but other widget's icon buttons don't. See M14 for the broader issue.


### m3. Hardcoded "Content Library" and "Loading..." on Dashboard

**Context:** Dashboard screen has hardcoded English strings: 'Content Library' (line 256), 'Loading...' (line 260), '$count source(s)' (line 261), 'Remaining Workload' (line 164).

**Affected file:** `lib/features/dashboard/presentation/dashboard_screen.dart:164, 256, 260-261`

**Rationale:** These strings should use `l10n.*` keys consistent with the rest of the dashboard's localization pattern.

**Acceptance criteria:** All hardcoded display strings replaced with localized lookups.


### m4. "Done" in Mentor Report Generation Has No Loading Indicator

**Context:** `MentorScreen._showProgressReport()` (mentor_screen.dart:393) generates a progress report but shows the dialog only when data is ready. No loading indicator appears during the async computation.

**Affected file:** `lib/features/mentor/presentation/mentor_screen.dart:393`

**Rationale:** User sees nothing after tapping "Generate Report" until the full data is ready. On slow devices or with large datasets, this appears unresponsive.

**Acceptance criteria:** A loading indicator (e.g., a centered spinner in the dialog with "Generating report...") appears during report computation.


### m5. `OutlinedButton` Uses `disabledBackgroundColor` — Unusual

**Context:** `OutlinedButtonTheme` (app_theme.dart:77) sets `disabledBackgroundColor`, but `OutlinedButton`'s disabled state is conventionally indicated by a reduced-opacity border, not a background fill.

**Affected file:** `lib/core/theme/app_theme.dart:74-84`

**Rationale:** The `OutlinedButton` visual language is "border-only." Adding a disabled background fill conflicts with this convention and may confuse users.

**Acceptance criteria:** Remove `disabledBackgroundColor` from `OutlinedButtonTheme` (or verify the visual is intentional and looks correct).


### m6. Low-Opacity Gradient May Be Invisible on Some Displays

**Context:** `GradientContainer` uses 8–15% alpha gradients (dark mode: 10–30%). On low-brightness displays or for users with reduced contrast sensitivity, this gradient is invisible.

**Affected file:** `lib/core/widgets/gradient_container.dart:27-28`

**Rationale:** The gradient is the only visual differentiator of these "accent" cards. If users can't see it, they just see a plain card with no visual distinction.

**Acceptance criteria:** Baseline opacity increased to minimum 20% (light) / 40% (dark), or alternative visual differentiation added (thin accent border, small color strip).


### m7. Break Timer Runs When Focus Screen Is Not Visible

**Context:** Focus timer break countdown runs even if the user navigates to another tab. Timer state and notifications are not paused when the screen is offstage.

**Affected file:** `lib/features/focus_mode/presentation/focus_timer_screen.dart`

**Rationale:** User sets a break timer, switches to Dashboard, and the break ends without them knowing. They return to find the timer in an unexpected state.

**Acceptance criteria:** Timer pauses when screen is not visible (via `WidgetsBindingObserver` or `TickerMode`) and resumes when user returns, or a notification/alert is shown when break ends.


### m8. No Exit Confirmation When Leaving Active Lesson

**Context:** `LessonDetailScreen` starts a timer in `initState` (line 37) but has no confirmation dialog when the user navigates away (back button or tab switch). The timer continues running in the background.

**Affected file:** `lib/features/lessons/presentation/lesson_detail_screen.dart:37`

**Rationale:** Users may accidentally navigate away from an active lesson and lose their timing data.

**Acceptance criteria:** `PopScope` (or equivalent) shows a confirmation dialog: "You have an active lesson timer. Leave anyway?"


### m9. `MergeSemantics` Underused (9 occurrences)

**Context:** The project uses `MergeSemantics` in only 9 places despite many composite widgets (list items, stat rows, card summaries) where merging semantics would provide cleaner screen reader output.

**Affected files:** `practice_results_screen.dart:40-48`, `onboarding_dialog.dart:122`, `profile_screen.dart:206`, and 6 other instances.

**Rationale:** Without merging, screen readers announce each piece of a composite widget separately ("42", "sessions", "completed") instead of as one coherent statement ("42 sessions completed").

**Acceptance criteria:** Identify 10+ additional composite display widgets (stat rows, summary cards, list item tiles) where `MergeSemantics` wraps the row for coherent announcement.


### m10. Redundant Duplicate Logic in Onboarding Dialog

**Context:** `OnboardingDialog` repeats the async "mark completed/don't show again" logic in 2 callback blocks (lines 81-87 and 93-99) instead of extracting a shared method.

**Affected file:** `lib/features/onboarding/presentation/onboarding_dialog.dart:80-100`

**Rationale:** DRY violation. Any future change to the completion logic must be made in 2 places, risking inconsistency.

**Acceptance criteria:** Duplicate async block extracted to a private method `_completeOnboarding()`.


### m11. `LocalDataNotice` Dialog Has No SafeArea

**Context:** The local data notice dialog (`onboarding_dialog.dart:175-192`) has no `SafeArea` or scroll wrapping. On devices with large system fonts or notch-heavy displays, content may overflow.

**Affected file:** `lib/features/onboarding/presentation/onboarding_dialog.dart:175-192`

**Rationale:** Overflowing dialog content can make buttons unreachable.

**Acceptance criteria:** Dialog content wrapped in `SingleChildScrollView` + `SafeArea`.


### m12. Dead `??` Fallback Code on Text Theme Colors

**Context:** Multiple widgets use `theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurfaceVariant`. Since `createTextTheme()` never sets `color` on text styles, `bodySmall?.color` is always `null` and the `??` always fires. The null guard is dead code.

**Affected files:**
- `lib/core/widgets/animated_bar_chart.dart:158, 169`
- `lib/core/widgets/metric_card.dart:48`

**Rationale:** Misleading code. Either set colors on text theme entries or remove the `??` and use `onSurfaceVariant` directly.

**Acceptance criteria:** Remove `?.color ?? theme.colorScheme.onSurfaceVariant` and use `theme.colorScheme.onSurfaceVariant` directly, OR set explicit colors on all `TextTheme` entries in `createTextTheme()`.


### m13. Inconsistent Inline Text Styles vs. Theme Text Styles (56+ Inline `fontSize:`)

**Context:** 56+ hardcoded `fontSize:` values appear across feature screens instead of using `theme.textTheme.*`. Notable offenders:
- `math_expression_widget.dart` — 20+ inline `TextStyle` definitions with sizes 11, 14, 16, 18
- `focus_timer_screen.dart` — inline sizes 13, 16
- `subject_detail_screen.dart` — inline sizes 11, 12, 24
- `question_bank_screen.dart` — inline size 11
- 8+ uses of `fontSize: 11` for status labels across multiple files

**Affected files:** Multiple feature screens (see counts above)

**Rationale:** Inline font sizes ignore the user's font size preference from settings (the app supports font scaling 10–30). Users who set "large font" in accessibility settings won't see these inline-styled texts scale.

**Acceptance criteria:**
- [ ] All inline `fontSize:` values replaced with `theme.textTheme.*.copyWith()` calls
- [ ] The `fontSize: 11` orphan replaces with either `labelSmall` (10px) or `bodySmall` (14px)
- [ ] `math_expression_widget.dart` refactored to use theme text styles
- [ ] Hardcoded sizes in `math_expression_widget.dart` validated — some may need to remain for math rendering constraints


### m14. `fontSize: 11` Orphan in Chart Labels

**Context:** `AnimatedBarChart` day labels use `fontSize: 11` (line 168), which matches no entry in the text theme (10, 12, 14, 16, 18, 20, 24, 28, 32, 40).

**Affected file:** `lib/core/widgets/animated_bar_chart.dart:168`

**Rationale:** `fontSize: 11` is non-standard and unaffected by theme updates. Should use `labelSmall` (10px) or `bodySmall` (14px).

**Acceptance criteria:** Replace with `theme.textTheme.labelSmall?.copyWith(...)` or `bodySmall`, adjusting padding/layout as needed.


### m15. Animation Re-Animates From Zero on Data Change

**Context:** `AnimatedBarChart` resets `_hasAnimated` to `false` in `didUpdateWidget` (line 93), causing bar animations to replay from 0 height on every data update. This produces jarring motion.

**Affected file:** `lib/core/widgets/animated_bar_chart.dart:62-95`

**Rationale:** Bar chart data updates (e.g., changing date range) should animate smoothly from previous heights, not from zero.

**Acceptance criteria:** Animation start value uses the previous height (stored in `_previousHeights` map) rather than resetting to 0 on every data change.


### m16. `getSubjectColor()` Uneven Probability Distribution

**Context:** `getSubjectColor()` (color_utils.dart:34-42) cycles through `[primary, secondary, tertiary, primary, secondary, tertiary, primary, secondary]` — primary and secondary each have 3/8 chance (37.5%), tertiary has 2/8 (25%).

**Affected file:** `lib/core/utils/color_utils.dart:34-42`

**Rationale:** Uneven distribution may cause subject confusion when multiple subjects are assigned the same color.

**Acceptance criteria:** Change the cycle to give all 3 colors equal probability: e.g., `[primary, secondary, tertiary]` cycling.

---

## Summary of Affected Areas

| Layer | Files | Issues |
|---|---|---|
| Theme | `app_theme.dart`, `color_utils.dart` | M8, M13, m5, m16 |
| Core Widgets | `conversation_input.dart`, `not_found_screen.dart`, `animated_bar_chart.dart`, `metric_card.dart`, `gradient_container.dart` | M10, M11, M12, M14, m6, m12, m14, m15 |
| Main / Navigation | `main.dart`, `app_router.dart`, `not_found_screen.dart`, `tab_navigator.dart` | M5, M7 |
| Dashboard | `dashboard_screen.dart` | M3, m1, m3 |
| Mentor | `mentor_screen.dart` | m4 |
| Practice | `practice_screen.dart`, `practice_session_screen.dart`, `exam_session_screen.dart` | M6 |
| Lessons | `lesson_list_screen.dart`, `topic_list_screen.dart`, `lesson_detail_screen.dart` | M2, m8 |
| Planner | `planner_screen.dart` | M18 |
| Subjects | `subject_detail_screen.dart` | M1 |
| Ingestion | `content_library_screen.dart`, `source_detail_screen.dart` | M1, M13 |
| Questions | `question_bank_screen.dart` | M1 |
| Sessions | `session_history_screen.dart`, `session_tracker_screen.dart` | M3 |
| Settings | `settings_screen.dart`, `profile_screen.dart` | M3, M4, M16 |
| LLM Tasks | `llm_task_manager_screen.dart` | M3, M17 |
| Focus Mode | `focus_timer_screen.dart` | m7 |
| Onboarding | `onboarding_dialog.dart` | M15, m10, m11 |
| (Cross-cutting) | All feature screens | M9, M14, m9, m13 |

---

## Summary by Severity

| Severity | Count | Key Themes |
|---|---|---|
| **MAJOR** | 18 | Hardcoded English on 4 screens (M1), silent loading deadlocks (M2), missing error states (M3), no loading indicator on profile (M4), duplicate dashboard from 404 (M5), exam results navigation loop (M6), deprecated `MaterialBanner` (M7), high-contrast theme bug (M8), no shared loading widget (M9), conversation input accessibility (M10), WCAG contrast failure (M11), inverted heading hierarchy (M12), non-theme-adaptive colors (M13), missing tooltips (M14), confusing onboarding (M15), silent sign-out (M16), no retry on failed LLM tasks (M17), mislabeled form field (M18) |
| **MINOR** | 16 | Static skeleton (m1), lone tooltip (m2), hardcoded dashboard strings (m3), no loading on report gen (m4), unusual OutlinedButton style (m5), invisible gradient (m6), break timer runs offscreen (m7), no exit confirm on lesson (m8), underused MergeSemantics (m9), duplicate onboarding logic (m10), no SafeArea in notice dialog (m11), dead null fallback code (m12), inline font sizes ignore scaling (m13), orphan 11px font (m14), jarring chart re-animation (m15), uneven color distribution (m16) |
