# UI/UX Master Audit — Full Codebase Review

**Date:** 2026-05-18  
**Scope:** All 22 named routes + 6 tab screens + dialog/widget ecosystem  
**Severity Legend:** 🔴 BLOCKER | 🟠 MAJOR | 🟡 MINOR

---

## 🔴 BLOCKER

### B1. PracticeSessionScreen — Empty questions with no graceful exit path
**File:** `lib/features/practice/presentation/screens/practice_session_screen.dart:148-172`  
**Context:** When `_loadQuestions()` finds zero questions for the subject/topic, `_showNoQuestionsDialog()` presents a dialog. If the user taps "OK" the dialog closes but the session screen remains showing `CircularProgressIndicator` (line 426) because `_questions` is still `[]` and `_isSessionComplete` is false. There is no back-navigation or "go back" affordance on this stuck state.  
**Rationale:** User cannot proceed and must force-close the app or use system back (which has its own confirmation dialog).  
**Acceptance:** After the "no questions" dialog is dismissed, the screen should pop back to the previous screen automatically.

### B2. PracticeSessionScreen — Submit button permanently disabled when answer is null
**File:** `lib/features/practice/presentation/screens/practice_session_screen.dart:507-512`  
**Context:** The `FilledButton` for submission is `onPressed: _currentAnswer != null ? _submitAnswer : null`. For question types that don't populate `_currentAnswer` (e.g., drawing/canvas questions that use a different interaction model), the user can never submit and is trapped.  
**Rationale:** Certain question types lack an answer callback, making the session unfinishable.  
**Acceptance:** Every question type must wire into `_onAnswerSelected` or provide its own submit pathway. At minimum, a "skip" button should be available when no answer is selected.

---

## 🟠 MAJOR

### M1. Screen-by-screen error-state inconsistency — raw `e.toString()` exposed to users
**Files:**
- `lib/features/practice/presentation/screens/practice_screen.dart:83` — `_loadError = e.toString()`
- `lib/features/practice/presentation/screens/practice_screen.dart:554` — renders `_loadError!` directly
- `lib/features/settings/presentation/settings_screen.dart:286` — `e.toString()` in error card
- `lib/features/sessions/presentation/session_tracker_screen.dart:95` — `_error = e.toString()`
- `lib/features/subjects/presentation/subject_list_screen.dart:38` — `error.toString()` in `when()` error
- `lib/features/subjects/presentation/subject_detail_screen.dart:465` — `_error!` in error widget
- `lib/features/sessions/presentation/session_history_screen.dart:468` — `_error!` shown directly

**Context:** Multiple screens display raw exception text to the user. This leaks implementation details (Hive errors, null pointer traces, network error codes) and is not localized.  
**Rationale:** Error messages are a user-facing surface; raw stack data is confusing and reflects poorly on app quality.  
**Acceptance:** Every `e.toString()` in a `build` / error-widget path must be replaced with a localized, user-friendly message. The raw error string may be used for logging but never displayed.

### M2. Dashboard all-or-nothing error handling hides partial data
**File:** `lib/features/dashboard/presentation/dashboard_screen.dart:58-87`  
**Context:** `hasAnyError` is true if *any* of 9+ async providers has an error. When true, the entire dashboard body is replaced with a generic error + retry button, hiding any successfully loaded card data.  
**Rationale:** If 8 of 9 providers load successfully and only one fails (e.g., `dashboardBadgesProvider`), the user loses visibility into all their stats, weekly trends, and focus time.  
**Acceptance:** Error state should be per-card (which `CollapsibleCard` already supports via `asyncValue`). Remove the blanket `hasAnyError` override so successful cards remain visible and failed cards show inline error/retry.

### M3. TutorScreen phase indicator shows untranslated enum names
**File:** `lib/features/teaching/presentation/tutor_screen.dart:528`  
**Context:** `phase.name` is used in the phase indicator label. `ConversationPhase` enum `.name` returns the Dart enum constant string (e.g., `"greeting"`, `"teaching"`, `"closing"`) in English regardless of locale.  
**Rationale:** Spanish (`es`) users will see English phase labels mixed into their tutor UI.  
**Acceptance:** Replace `phase.name` with a localized string (`l10n.phaseGreeting`, etc.) for every phase value.

### M4. MentorScreen progress report shows raw topic IDs instead of names
**File:** `lib/features/mentor/presentation/mentor_screen.dart:686`  
**Context:** The weak topics list in the progress report dialog displays `topic.topicId` directly. Topic IDs are UUID-like strings meaningless to users. A `TopicRepository` is available in scope (line 596) but not used to resolve names.  
**Rationale:** A user seeing "Weak areas: a1b2c3d4..." gets zero actionable information.  
**Acceptance:** Resolve topic IDs to their human-readable titles using the already-available `topicRepo.get()` before rendering.

### M5. SessionHistoryScreen subject filter shows raw `subjectId` instead of subject names
**File:** `lib/features/sessions/presentation/session_history_screen.dart:632-652`  
**Context:** The subject filter dialog lists `subjects` which are derived from `_allSessions.map((s) => s.subjectId)` — raw IDs, not resolved to `Subject.name`.  
**Rationale:** Users can't identify which subject to filter by when they see `"uuid-string-1234"`.  
**Acceptance:** Resolve each `subjectId` via `SubjectRepository` to show `subject.name` in the filter list.

### M6. FocusTimerScreen `_buildSubjectPicker` creates a new `FutureBuilder` on every frame
**File:** `lib/features/focus_mode/presentation/focus_timer_screen.dart:778-840`  
**Context:** `_buildSubjectPicker` calls `subjectsAsync.when(data: ...)` which returns a fresh `FutureBuilder` that calls `repo.getAll()` every rebuild. Since this widget is inside the focus screen's `build` (which is called on every timer tick / setState), it triggers a repository network/database call every ~second.  
**Rationale:** Unnecessary I/O every second degrades performance and battery.  
**Acceptance:** Cache the subject list with a simple state variable or use a Riverpod `FutureProvider` instead of the nested `FutureBuilder`.

### M7. PlannerScreen calendars — tapping a day opens tutor instead of showing the day's plan
**File:** `lib/features/planner/presentation/planner_screen.dart:872-875`  
**Context:** `CalendarViewWidget.onDayTap` opens `_openTutorMode`, jumping directly into a tutoring session for that topic. The user expectation when tapping a calendar day is to see what's scheduled for that day, not to immediately start a lesson.  
**Rationale:** Destroys the mental model of a planner/calendar. Users lose the ability to review their schedule.  
**Acceptance:** Add a "tap to view day details" step that shows the daily plan card, then offers a "Start tutoring" CTA within that view.

### M8. No conversation reset affordance in MentorScreen or TutorScreen
**Files:**
- `lib/features/mentor/presentation/mentor_screen.dart`
- `lib/features/teaching/presentation/tutor_screen.dart`

**Context:** Both mentor and tutor chat screens accumulate messages indefinitely with no "clear conversation" or "start fresh" button. If the conversation context becomes confused (which happens with LLM-based systems), the user has no way to reset without leaving the screen and coming back.  
**Rationale:** Users are stuck with a broken conversation context until they navigate away.  
**Acceptance:** Add an overflow menu in the AppBar with "Clear conversation" that resets the message list and reinitializes the conversation manager after confirmation.

### M9. `subject_color` used without contrast check for text legibility
**Files:**
- `lib/features/subjects/presentation/subject_detail_screen.dart:78-98` — gradient background uses subject color; title text is rendered in `onPrimary` which may have insufficient contrast against arbitrary subject colors
- `lib/features/subjects/presentation/subject_list_screen.dart:137` — icon container uses the raw subject color

**Context:** Subject colors are user-defined strings parsed by `ColorUtils.stringToColor()`. There is no luminance check before rendering white text (`onPrimary`) on top of these colors. A bright yellow or light green subject color would render white-on-yellow effectively invisible.  
**Rationale:** Accessibility failure — users who pick light subject colors cannot read the subject title in `SubjectDetailScreen`.  
**Acceptance:** Compute relative luminance of the subject color and switch between `Colors.white` and `Colors.black` (or use a semi-transparent overlay) to ensure WCAG AA contrast (4.5:1).

### M10. ExamSessionScreen and PracticeSessionScreen share nearly identical logic with no code reuse
**Files:** `lib/features/practice/presentation/screens/exam_session_screen.dart`, `lib/features/practice/presentation/screens/practice_session_screen.dart`  
**Context:** The exam session screen duplicates ~80% of the practice session logic (question loading, answer validation, timer, navigation, confidence selector, results). The only differences are timer mode (countdown vs. untimed), question selection strategy, and some UI text.  
**Rationale:** Violates DRY — any bug fix or UX improvement in one must be manually replicated in the other. The files have already diverged slightly.  
**Acceptance:** Extract a shared `QuestionSessionScreen` base widget or mixin with parameterization for timed/untimed mode, question selection strategy, and result screen. Both screens become thin wrappers.

---

## 🟡 MINOR

### m1. Dashboard skeleton loading doesn't match card layout
**File:** `lib/features/dashboard/presentation/dashboard_screen.dart:306-340`  
**Context:** `_buildSkeletonLoading` renders 6 identical placeholder cards (shimmer box + line). The actual dashboard has 10+ cards of varying heights (header row, charts, adherence bars, topic names, badges). The mismatch makes the loading state misleading.  
**Acceptance:** Match skeleton count and relative sizes to actual card layout, or switch to a single centered `LoadingScreen` during initial load.

### m2. All page transitions use the same 200ms fade regardless of direction
**File:** `lib/core/routes/app_router.dart:293-305`  
**Context:** `_materialPageRoute` always applies `FadeTransition` identically. Forward and back navigation feel the same. There is no slide gesture, no directional cue.  
**Acceptance:** Use `SlideTransition` + `FadeTransition` with direction-aware offsets: forward slides left, back slides right. Match iOS/Material design conventions.

### m3. `ConversationInput` lacks send debouncing
**File:** `lib/core/widgets/conversation_input.dart:110-113`  
**Context:** `onSubmitted` and the send button icon both invoke `widget.onSend` without debouncing. Rapid taps or pressing Enter multiple times can send the same message multiple times before `_isSending` updates.  
**Acceptance:** Add a `ValueNotifier<bool>` or use `isLoading` synchronously before calling `onSend`. Alternatively, debounce with a 100ms timer.

### m4. PracticeScreen subject cards show "Practice sessions" as static text with no actual count
**File:** `lib/features/subjects/presentation/subject_list_screen.dart:166-174`  
**Context:** The `Row` with `Icons.timer` shows `l10n.practiceSessions` as a static label. There is no session count or progress indicator for the subject.  
**Acceptance:** Show actual practice session count or last-practiced date for the subject by querying the session repository.

### m5. `assets/fonts/` directory exists but is empty
**File:** `pubspec.yaml` likely references fonts, but `assets/fonts/` has no files.  
**Context:** The project doesn't bundle any custom font files. If the intent was to use a custom typeface, it's missing. If not, the directory should be removed to avoid confusion.  
**Acceptance:** Either bundle the intended font files or remove the empty `assets/fonts/` directory and any references from `pubspec.yaml`.

### m6. Cross-tab navigation loses previous tab scroll position
**File:** `lib/main.dart:361-368`  
**Context:** `Offstage` widgets used for inactive tabs cause the widget subtree to be unmounted/rebuilt when `TickerMode` is disabled. This means scroll position, form state, and other ephemeral state in inactive tabs is lost when switching tabs and coming back.  
**Acceptance:** Use `AutomaticKeepAliveClientMixin` or `IndexedStack` instead of `Offstage` to preserve tab state, or at minimum preserve scroll offset.

### m7. UploadScreen lacks real-time processing step labels
**File:** `lib/features/ingestion/presentation/upload_screen.dart`  
**Context:** During upload/processing, there's a `LinearProgressIndicator` but no text label showing which step is active ("Extracting text...", "Generating questions...", "Saving..."). Multi-step LLM processing can take 30-60 seconds with no user-facing progress communication.  
**Acceptance:** Display step name / status text above or below the progress indicator.

### m8. No haptic feedback on key interaction completions
**Context:** Completing a focus session, submitting a practice answer, and finishing an exam session have no haptic/vibration feedback. This reduces the tactile satisfaction of completing an action.  
**Acceptance:** Call `HapticFeedback.mediumImpact()` on session complete, `HapticFeedback.lightImpact()` on answer submission, and `HapticFeedback.heavyImpact()` on exam finish.

### m9. QuestionBankScreen loads all data upfront with no pagination or lazy loading
**File:** `lib/features/questions/presentation/question_bank_screen.dart:60-87`  
**Context:** `_load()` fetches all questions, subjects, topics, and sources from Hive at once. For a large question bank (1000+ questions), this causes a visible delay and high memory usage.  
**Acceptance:** Use `ListView.builder` with lazy loading — fetch and display in pages of 50, or use a `ValueNotifiable` cursor for incremental loading.

### m10. FocusTimerScreen `_onElapsedChanged` fires `setState` every second even when timer isn't visible
**File:** `lib/features/focus_mode/presentation/focus_timer_screen.dart:96-100`  
**Context:** The `_onElapsedChanged` listener always calls `setState` every second regardless of whether the timer UI is currently displayed (e.g., if the user scrolled down and the timer is off-screen).  
**Acceptance:** Only rebuild if the timer widget's `TickerMode` is enabled, or use a mounted/visible check.

### m11. SettingsScreen "Sign Out" doesn't actually clear local data
**File:** `lib/features/settings/presentation/settings_screen.dart:906-927`  
**Context:** The sign-out action clears `apiKey` and `selectedModel` but leaves all Hive data (subjects, questions, sessions, attempts) intact. This is neither a true sign-out nor a data reset — it's ambiguous.  
**Acceptance:** Split into two distinct actions: "Clear API key" (current behavior) and "Reset all data" (clears all Hive boxes + resets onboarding). Label the current button clearly.

### m12. Onboarding — "Get Started" button goes to empty subject selection, confusing first-time users
**File:** `lib/features/onboarding/presentation/onboarding_dialog.dart:88-91`  
**Context:** The primary CTA "Get Started" navigates directly to `subjectSelection`. A brand-new user lands on an empty screen with no guidance about what to do next. The onboarding journey should have a more guided handoff.  
**Acceptance:** Show a brief interstitial or overlay explaining: "First, add a subject you're studying" or navigate to a guided subject-creation flow.

### m13. PracticeSession confidence selector uses hardcoded circle size
**File:** `lib/features/practice/presentation/screens/practice_session_screen.dart:596-597`  
**Context:** The confidence rating circles use `ResponsiveUtils.minTouchTarget` (48px) for width/height. On small screens, 5 circles × 48px + spacing may overflow the wrap area.  
**Acceptance:** Use `MediaQuery.sizeOf(context).width / 6` cap as max width, or switch to compact buttons at the `xs` breakpoint.

### m14. `NotFoundScreen` "Go to Dashboard" button doesn't work when navigated from tab's own Navigator
**File:** `lib/core/widgets/not_found_screen.dart:48-55`  
**Context:** The go-to-dashboard fallback tries `Navigator.pop()` which may fail if the route was pushed fresh (no history). It doesn't try to push to the dashboard tab's root.  
**Acceptance:** If `canPop()` is false, use `Navigator.pushNamedAndRemoveUntil(context, AppRoutes.dashboard, (route) => false)`.

### m15. SessionTrackerScreen "centerTitle" inconsistency
**File:** `lib/features/sessions/presentation/session_tracker_screen.dart:249,296`  
**Context:** The loading state AppBar has `centerTitle: false` but the main state AppBar has `centerTitle: true`. This inconsistency causes visual jump when data loads.  
**Acceptance:** Keep `centerTitle` consistent across all states (prefer `false` per Material 3 guidelines for screens with navigation).

### m16. Dashboard empty state "Take a Practice Quiz" passes empty subjectId
**File:** `lib/features/dashboard/presentation/widgets/empty_dashboard_checklist.dart:31-33`  
**Context:** The checklist's "Take a Practice Quiz" item navigates with `subjectId: ''`. This will likely result in zero questions being found, showing the "No questions" dialog — a confusing dead end for a "getting started" CTA.  
**Acceptance:** The empty-state checklist item should first guide the user to upload material or add a subject, not attempt a practice session with no data.

### m17. Weekly chart legend / tooltips not localized
**File:** `lib/features/dashboard/presentation/widgets/weekly_chart.dart`  
**Context:** If the weekly chart uses `fl_chart` or similar, axis labels and tooltip text may default to English or raw data formats.  
**Acceptance:** Pass `l10n.localeName` through to chart formatting, ensure tooltip values use `formatPercent`/`formatDecimal`.

### m18. ApiKeyBanner uses hardcoded orange icon color
**File:** `lib/features/onboarding/presentation/onboarding_dialog.dart:155`  
**Context:** `const Icon(Icons.key, color: Colors.orange)` ignores the theme. In dark mode or high-contrast mode, orange may not provide sufficient contrast.  
**Acceptance:** Use `theme.colorScheme.error` (with appropriate alpha) or a theme-aware warning color instead of hardcoded `Colors.orange`.

### m19. Ingestion screen doesn't handle processing errors per-source
**File:** `lib/features/ingestion/presentation/upload_screen.dart`  
**Context:** When uploading multiple files or processing one file, if a step fails (OCR, question generation), the only feedback is a generic SnackBar. The source item in the content library may show as `failed` but the user doesn't know why or what to do.  
**Acceptance:** Show per-source error details in the content library / source detail, with a "Retry processing" button for failed sources.

### m20. No pull-to-refresh on QuestionBankScreen
**File:** `lib/features/questions/presentation/question_bank_screen.dart`  
**Context:** The question bank is a `ListView.builder` (line 307) inside a `RefreshIndicator`, but the RefreshIndicator's `onRefresh` reloads everything. The outer `Column` layout (search bar + filters) is not scrollable with the list, so pull-to-refresh doesn't work properly when the list is short (content doesn't fill screen).  
**Acceptance:** Ensure the `RefreshIndicator` wraps the entire scrollable content including filters, or separate the search/filter from the scrollable list.
