# UI/UX Master Issue: Comprehensive Audit Findings

> **Audited:** 2026-05-19 by automated codebase exploration
> **Scope:** 28+ presentation screens, core widgets, theme, routing, services, providers

---

## BLOCKER — App crashes or user cannot proceed

### B1. `QuestionBankScreen` multi-choice `Checkbox` has `onChanged: null`

**Context:** `lib/features/questions/presentation/question_bank_screen.dart:381`
When creating a multiple-choice question, the `Checkbox` for each choice option has `onChanged: null`, making the checkbox non-interactive. Students cannot mark/unmark correct answers during question creation.

**Rationale:** This is a functional breakage of a core feature. Questions cannot be properly authored.

**Affected files:**
- `lib/features/questions/presentation/question_bank_screen.dart` (line 381)

**Acceptance criteria:**
- `Checkbox.onChanged` calls `_onChoiceChanged` callback
- Tapping the checkbox toggles the `isCorrect` flag for that choice
- Test: creating a multi-choice question with exactly one correct answer works end-to-end

---

## MAJOR — Feature is broken or misleading

### M1. Raw error strings displayed to user instead of localized messages

**Context:** `lib/features/planner/presentation/planner_screen.dart:1338-1341`
The `progressAsync.when(error:)` handler renders `Text('$err')`, which displays raw exception text (e.g., `Null check operator used on a null value`) directly to the user. No localization, no friendly message, no retry button.

**Rationale:** Raw Dart error messages are meaningless and frightening to end users.

**Affected files:**
- `lib/features/planner/presentation/planner_screen.dart` (line 1340)

**Acceptance criteria:**
- Error state uses `ErrorRetryWidget` with a localized `l10n.somethingWentWrong` message
- Retry button re-triggers the provider
- No raw Dart exception text is displayed

---

### M2. Duplicate identical error text — "Something went wrong" used as both title and body

**Context:** `lib/features/sessions/presentation/session_history_screen.dart:446-454` and `lib/features/sessions/presentation/session_tracker_screen.dart:292-303`
Both error states show `l10n.somethingWentWrong` twice — once as `titleMedium` (heading) and again as `bodySmall` (description). This is redundant, confusing, and fails to provide any actionable information.

**Rationale:** Users see the same text twice and learn nothing about what happened or how to recover.

**Affected files:**
- `lib/features/sessions/presentation/session_history_screen.dart` (lines 446-454)
- `lib/features/sessions/presentation/session_tracker_screen.dart` (lines 292-303)

**Acceptance criteria:**
- Title says something contextual (e.g., "Failed to load sessions")
- Body provides actionable guidance (e.g., "Check your connection and try again")
- Retry button is present and functional

---

### M3. Loading state without scaffold/appbar — user cannot navigate back

**Context:** `lib/features/lessons/presentation/lesson_list_screen.dart:107`, `lib/features/lessons/presentation/topic_list_screen.dart:57`
Both return a bare `const LoadingIndicator()` without a `Scaffold` or `AppBar`. When the loading hangs, the user sees an infinite spinner with no back button, no retry, and no way to exit.

**Rationale:** The normal loaded state wraps content in a `Scaffold` with `AppBar` and back navigation. The loading state should match. Without a back button, the user is trapped.

**Affected files:**
- `lib/features/lessons/presentation/lesson_list_screen.dart` (line 107)
- `lib/features/lessons/presentation/topic_list_screen.dart` (line 57)

**Acceptance criteria:**
- Loading state wraps `LoadingIndicator()` inside a `Scaffold` with an `AppBar` that has a back button
- Add a timeout or retry mechanism for long-running loads
- Consistent with how other screens (e.g., `session_tracker_screen.dart`) handle loading

---

### M4. Raw technical IDs displayed to user

**Context:**
- `lib/features/subjects/presentation/subject_detail_screen.dart:322` — `_InfoRow(label: l10n.id, value: source.id)` shows raw internal `source_1712345678901`
- `lib/features/ingestion/presentation/source_detail_screen.dart:322` — same pattern

**Rationale:** Internal auto-generated IDs like `source_1712345678901` are implementation details. Users should see meaningful identifiers (subject name, topic path, date created).

**Affected files:**
- `lib/features/subjects/presentation/subject_detail_screen.dart` (line 322)
- `lib/features/ingestion/presentation/source_detail_screen.dart` (line 322)

**Acceptance criteria:**
- Remove the "ID" row, or show a user-friendly alternative (e.g., creation date, source type icon)
- No raw internal IDs appear in any user-facing widget

---

### M5. i18n violation — raw number/percentage formatting instead of locale-aware helpers

**Context:** `lib/features/practice/presentation/screens/practice_screen.dart`
Multiple locations concatenate raw numbers and percent strings:
- Line 754: `'$_weeklyAccuracy%'` — always produces period decimal (`85.5%`), wrong for comma-decimal locales
- Line 758: `'$_weeklyActivity'` — raw integer, not formatted per locale
- Line 764: `'${_practiceStreak}d'` — English-only "d" suffix, not localized
- Lines 809-810: `'${(s.correctAnswers / s.questionsAnswered * 100).round()}%'` — hardcoded percent

Also `lib/features/practice/presentation/screens/exam_session_screen.dart`:
- Line 576: `'${_easyCount + _mediumCount + _hardCount} / $_questionCount'`
- Line 612: `'$value'` — raw slider number
- Line 633: `'$c'` — raw count number

**Rationale:** Per `AGENTS.md` i18n conventions: "Never use `toStringAsFixed()` for user-facing numeric displays." The app already has `formatDecimal()`, `formatPercent()`, `formatCompactNumber()` in `number_format_utils.dart` — these must be used.

**Affected files:**
- `lib/features/practice/presentation/screens/practice_screen.dart` (lines 754, 758, 764, 809-810)
- `lib/features/practice/presentation/screens/exam_session_screen.dart` (lines 576, 612, 633)

**Acceptance criteria:**
- All user-facing number/percentage strings use the appropriate helper from `number_format_utils.dart` with `l10n.localeName`
- Raw string concatenation of numbers is eliminated
- Test: verify formatted output for `es` locale produces comma decimals

---

### M6. "View Sources" menu item navigates to wrong tab

**Context:** `lib/features/subjects/presentation/subject_detail_screen.dart:283-284`
The overflow menu option "View Sources" calls `_tabController.animateTo(2)`, which scrolls to tab index 2 (the "Topics" tab). The "Sources" tab is at index 3. Users tapping "View Sources" see topics instead of sources.

**Rationale:** This is a functional navigation bug — the menu item lies about its destination.

**Affected files:**
- `lib/features/subjects/presentation/subject_detail_screen.dart` (line 283)

**Acceptance criteria:**
- `animateTo(3)` navigates to the correct Sources tab
- Or the menu label is updated to match the actual destination

---

### M7. Integer question count formatted as decimal

**Context:** `lib/features/subjects/presentation/subject_detail_screen.dart:391`
`formatDecimal(questions.toDouble(), l10n.localeName)` formats an integer question count (e.g., 5) as a double, potentially showing `5.0` or `5,0` instead of `5`.

**Rationale:** `formatDecimal` with default fraction digits will format integers with `.0` if `minFractionDigits > 0` or if the formatting locale adds decimals. Question counts are always whole numbers.

**Affected files:**
- `lib/features/subjects/presentation/subject_detail_screen.dart` (line 391)

**Acceptance criteria:**
- Use a dedicated `formatCount()` or pass `minFractionDigits: 0, maxFractionDigits: 0` to display whole numbers only

---

## MINOR — Code quality / UX friction

### m1. 6 navigation tabs overflow on small phone screens

**Context:** `lib/main.dart:641-654` — `NavigationBar` with 6 `NavigationDestination` items.
The navigation bar shows Dashboard, Subjects, Practice, Mentor, Focus, and Settings. On phones with 360-400dp width, 6 destinations with labels cause text truncation or overflow. Material spec recommends 3-5 destinations.

**Rationale:** Users on small screens see truncated labels. Focus Mode could be a sub-route of Dashboard or Practice.

**Affected files:**
- `lib/main.dart` (lines 262-299, 641-654)

**Acceptance criteria:**
- Reduce to 4-5 primary destinations on phone screens
- Consider merging Focus Mode into the Dashboard or Subjects tab
- Wide screens (tablet+) retain all 6 on NavigationRail

---

### m2. RTL layout violations — hardcoded `arrow_forward_ios` icons

**Context:** Hardcoded `Icons.arrow_forward_ios` used in:
- `lib/features/subjects/presentation/subject_list_screen.dart:189`
- `lib/features/settings/presentation/settings_screen.dart` (lines 264, 409, 452, 1827, 1870)
- `lib/features/practice/presentation/widgets/practice_mode_option.dart:60`

Other screens correctly use `Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right`.

**Rationale:** In RTL languages (Arabic, Hebrew, Urdu), `arrow_forward_ios` points right which is the "back" direction. This confuses users who expect chevrons pointing toward content.

**Affected files:**
- `lib/features/subjects/presentation/subject_list_screen.dart` (line 189)
- `lib/features/settings/presentation/settings_screen.dart` (5 locations)
- `lib/features/practice/presentation/widgets/practice_mode_option.dart` (line 60)

**Acceptance criteria:**
- All list tiles use the bidirectional chevron pattern (`Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right`)
- Test: verify icon direction with `Directionality.rtl` wrapping

---

### m3. Inconsistent destructive button styling

**Context:** Destructive actions use different button patterns:
- `lib/features/questions/presentation/question_bank_screen.dart:198-199` — `ElevatedButton` with inline `styleFrom(backgroundColor: error)`
- `lib/features/planner/presentation/planner_screen.dart:415-418` — same pattern
- `AppTheme.destructiveButtonStyle()` exists but is unused in these locations

**Rationale:** `AGENTS.md` conventions encourage reuse. `ElevatedButton` with manual error color styling is inconsistent with `FilledButton` used elsewhere.

**Affected files:**
- `lib/features/questions/presentation/question_bank_screen.dart` (line 197-199)
- `lib/features/planner/presentation/planner_screen.dart` (line 415-418)

**Acceptance criteria:**
- All destructive buttons use `FilledButton` with `AppTheme.destructiveButtonStyle(context)` or equivalent styling
- Inline `ElevatedButton` with manual `backgroundColor: error` is eliminated

---

### m4. `(context as Element).markNeedsBuild()` anti-pattern in settings screen

**Context:** `lib/features/settings/presentation/settings_screen.dart:638,716`
Two locations call `(context as Element).markNeedsBuild()` to force a rebuild after updating Hive boxes directly. This is a Flutter anti-pattern that tightly couples UI logic to widget tree internals.

**Rationale:** This approach bypasses Riverpod's state management, makes screens hard to test, and the cast could throw if context is no longer a `StatefulElement`.

**Affected files:**
- `lib/features/settings/presentation/settings_screen.dart` (lines 638, 716)

**Acceptance criteria:**
- Replace direct Hive writes and `markNeedsBuild()` with Riverpod `StateNotifier` mutations
- The screen rebuilds automatically through provider subscriptions
- Remove the dangerous `(context as Element)` cast

---

### m5. Empty catch blocks (forbidden per AGENTS.md)

**Context:** `lib/features/focus_mode/presentation/focus_timer_screen.dart:209-211`
```dart
catch (e) {
  // silent - badge check is non-critical
}
```
And `lib/features/mentor/services/mentor_service.dart:122-123` and line 358:
```dart
try { await _longTermMemory?.init(); } catch (_) {}
```

**Rationale:** Per `AGENTS.md`: "Empty `catch (_) {}` blocks are forbidden. Every catch must log the error with a descriptive message."

**Affected files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart` (lines 209-211)
- `lib/features/mentor/services/mentor_service.dart` (lines 122-123, 358)

**Acceptance criteria:**
- Each catch block logs the error using `_logger.w()` with a descriptive message
- No empty catch blocks remain

---

### m6. Duplicated widgets that should be shared

**Context:** Several widget/utility patterns are duplicated across files:
1. `ApiKeyBanner` — defined in `onboarding_dialog.dart:213` and duplicated in `quick_guide_screen.dart:352`
2. `_InfoRow` / `_SectionHeader` — defined in both `subject_detail_screen.dart` and `source_detail_screen.dart`
3. `_inferSourceType` — duplicated in `upload_screen.dart:329-358` and partially in `subject_detail_screen.dart`'s `_typeIcon`
4. Dashboard navigation cards (`_buildPlannerCard`, `_buildQuestionBankCard`, etc.) in `dashboard_screen.dart` — nearly identical patterns that could be a single `DashboardNavCard` widget

**Rationale:** Code duplication increases maintenance burden and risks drift between copies.

**Affected files:**
- `lib/features/onboarding/presentation/onboarding_dialog.dart`
- `lib/features/quickguide/presentation/quick_guide_screen.dart`
- `lib/features/subjects/presentation/subject_detail_screen.dart`
- `lib/features/ingestion/presentation/source_detail_screen.dart`
- `lib/features/ingestion/presentation/upload_screen.dart`
- `lib/features/dashboard/presentation/dashboard_screen.dart`

**Acceptance criteria:**
- Each duplicated widget exists in exactly one shared location (e.g., `lib/core/widgets/`)
- Existing code imports the shared widget
- No functional change

---

### m7. `AnimatedContainer` in onboarding doesn't respect `reduceMotion`

**Context:** `lib/features/onboarding/presentation/onboarding_dialog.dart:68-79` — The page indicator dots use `AnimatedContainer` for width transition (expanding the active dot). It does not check the user's `reduceMotion` accessibility preference before animating.

**Rationale:** Users with vestibular disorders who enable reduce motion expect static transitions. The `AnimatedSwitcher` in `main.dart` handles this correctly by checking `ref.watch(settingsProvider).reduceMotion`, but onboarding animations do not.

**Affected files:**
- `lib/features/onboarding/presentation/onboarding_dialog.dart` (lines 68-79)

**Acceptance criteria:**
- When `reduceMotion` is enabled, page indicator dots use static width (no animation)
- The `SettingsProvider` / accessibility preferences are accessible from the dialog

---

### m8. Accessibility: `Semantics(button: true)` without label on focus card

**Context:** `lib/features/dashboard/presentation/dashboard_screen.dart:194-196`
```dart
Semantics(
  button: true,
  child: InkWell(...)
)
```
The `Semantics` marks this as a button but provides no label. Screen readers will announce "button" without describing what it does.

**Affected files:**
- `lib/features/dashboard/presentation/dashboard_screen.dart` (line 194)

**Acceptance criteria:**
- Add `label:` with appropriate localized text (e.g., `l10n.focusMode`)
- The InkWell's `onTap` handler description is announced

---

### m9. `VoiceService` streams expose raw error messages

**Context:** `lib/core/services/voice_service.dart` — The `_errorController` stream pushes raw strings like `"Failed to start listening: $e"` which UI consumers may display directly. This technically exposes implementation details.

**Rationale:** Error messages with raw exception text could reach users if a widget subscribes without wrapping.

**Affected files:**
- `lib/core/services/voice_service.dart` (stream error messages)

**Acceptance criteria:**
- Stream errors are typed (e.g., enum) or at minimum wrapped with user-friendly messages
- UI consumers display localized equivalents

---

### m10. Large files needing decomposition

**Context:** Several screens exceed healthy size and mix too many responsibilities:
- `lib/features/planner/presentation/planner_screen.dart` — 1488 lines (plan creation, calendar, roadmaps, scheduling)
- `lib/features/settings/presentation/settings_screen.dart` — 1882 lines (backup, import, export, AI models, theme, accessibility)
- `lib/features/practice/presentation/screens/practice_screen.dart` — 1105 lines (stats, activity, due questions, spaced repetition)
- `lib/features/questions/presentation/question_bank_screen.dart` — 826 lines (question list, filters, creation dialog, edit)

**Rationale:** Large files violate the Single Responsibility Principle, make testing harder, and increase merge conflict surface.

**Affected files:**
- `lib/features/planner/presentation/planner_screen.dart`
- `lib/features/settings/presentation/settings_screen.dart`
- `lib/features/practice/presentation/screens/practice_screen.dart`
- `lib/features/questions/presentation/question_bank_screen.dart`

**Acceptance criteria:**
- Each file is under 500 lines
- Dialogs, bottom sheets, and sub-widgets extracted to separate files
- Tab content extracted to separate widget files (planner, settings)
- No functional regression

---

### m11. `LessonDetailScreen` timer starts before lesson loads

**Context:** `lib/features/lessons/presentation/lesson_detail_screen.dart:41-46` — The elapsed-seconds timer starts in `initState`, before the lesson data loads. If loading fails, the timer keeps running and accumulating phantom duration.

**Rationale:** Users see incorrect elapsed time if lesson content fails to load.

**Affected files:**
- `lib/features/lessons/presentation/lesson_detail_screen.dart` (lines 41-46)

**Acceptance criteria:**
- Timer starts only after lesson data is successfully loaded
- If lesson load fails, timer never starts and the user sees an error state
- Timer resets to 0 if the page is re-entered

---

### m12. Missing semantic labels in filter chips

**Context:**
- `lib/features/questions/presentation/question_bank_screen.dart:733-751` — Filter chip's delete icon button lacks individual semantic label
- `lib/features/ingestion/presentation/content_library_screen.dart:362` — Same issue

**Rationale:** Users relying on TalkBack/VoiceOver cannot identify which filter is being removed when they tap the delete icon.

**Affected files:**
- `lib/features/questions/presentation/question_bank_screen.dart` (lines 733-751)
- `lib/features/ingestion/presentation/content_library_screen.dart` (line 362)

**Acceptance criteria:**
- Delete icon on each filter chip has `Semantics(label: "Remove X filter")` or equivalent
- The chip group has `MergeSemantics` or appropriate grouping

---

### m13. `MentorScreen` fragile `Navigator.pop()` inside try/catch

**Context:** `lib/features/mentor/presentation/mentor_screen.dart:850-858` — Calls `Navigator.of(context).pop()` inside a try/catch. On failure, it catches and shows a snackbar on a potentially wrong context (the dialog may already be dismissed).

**Rationale:** This pattern is fragile — catching a pop failure doesn't guarantee the snackbar will display either. The navigator state may be inconsistent.

**Affected files:**
- `lib/features/mentor/presentation/mentor_screen.dart` (lines 850-858)

**Acceptance criteria:**
- Check `Navigator.of(context).canPop()` before calling pop
- Remove the try/catch around `pop()` — or at minimum verify the context is still mounted for the snackbar fallback

---

### m14. Risky `as String` casts in `MentorScreen`

**Context:** `lib/features/mentor/presentation/mentor_screen.dart:1008,1035`
```dart
badge['name'] as String
rec['message'] as String
```
These hard-cast from `Map<String, dynamic>` values. If the key is missing or the value is `null`, a `TypeError` is thrown at runtime.

**Affected files:**
- `lib/features/mentor/presentation/mentor_screen.dart` (lines 1008, 1035)

**Acceptance criteria:**
- Use `as String?` with null-aware fallback, or validate the map structure before casting
- Test with malformed badge/recommendation data

---

### m15. `SubjectListScreen` `FutureBuilder` per card creates N storage calls

**Context:** `lib/features/subjects/presentation/subject_list_screen.dart:167-183` — Each subject card creates its own `FutureBuilder` that calls `SessionRepository().getBySubject(subject.id)`. For N subjects, this makes N repository calls instead of 1 batch call.

**Rationale:** Performance — the `FutureBuilder` also re-executes on every rebuild of the `ListView`.

**Affected files:**
- `lib/features/subjects/presentation/subject_list_screen.dart` (lines 167-183)

**Acceptance criteria:**
- Load session counts once (e.g., in `initState` or via a Riverpod provider) and cache per subject
- Remove per-card `FutureBuilder`

---

### m16. Subject detail has 6 tabs — too many for phone screens

**Context:** `lib/features/subjects/presentation/subject_detail_screen.dart` — 6 `Tab` entries: Lessons, Practice, Topics, Sources, History, Stats. Tabs are scrollable but users can only see 2-3 at a glance on small screens.

**Rationale:** Navigation fatigue — users must scroll through unseen tabs to find what they need. Information density overwhelms.

**Affected files:**
- `lib/features/subjects/presentation/subject_detail_screen.dart` (tab definitions)

**Acceptance criteria:**
- Consolidate into 4-5 tabs for phone screens (e.g., merge History into Stats)
- Or use a side drawer on mobile
- Or use a sliver-based vertical layout with section headers

---

### m17. Duplicate error message in `session_tracker_screen` and `session_history_screen`

**Context:** Already covered in M2 above — but worth noting both files have identical erroneous code patterns, suggesting copy-paste.

**Affected files:**
- `lib/features/sessions/presentation/session_history_screen.dart`
- `lib/features/sessions/presentation/session_tracker_screen.dart`

**Acceptance criteria:**
- Extract a shared `SessionErrorState` widget or consolidate the error display logic

---

### m18. Focus timer `StatsContainer` icons lack semantic labels

**Context:** `lib/features/focus_mode/presentation/focus_timer_screen.dart:743-753` — The `_buildStatItem` method wraps content in `MergeSemantics` but individual stat icons are just icons without labels. Screen readers may announce "icon" without context.

**Affected files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart` (lines 743-753)

**Acceptance criteria:**
- Each stat has `Semantics(label: l10n.statName)` or equivalent
- Merged semantics announce the stat value together with its label

---

### m19. `PlannerScreen` uses `ElevatedButton` with error color instead of `destructiveButtonStyle`

**Context:** `lib/features/planner/presentation/planner_screen.dart:415-418` and line 1236
Uses `ElevatedButton.styleFrom(backgroundColor: error)` rather than `AppTheme.destructiveButtonStyle()`.

See also M3 above (same issue in `question_bank_screen`).

**Affected files:**
- `lib/features/planner/presentation/planner_screen.dart` (lines 417, 1236)

**Acceptance criteria:**
- All destructive actions use `FilledButton` with `AppTheme.destructiveButtonStyle()`

---

### m20. Onboarding finish jumps straight to subject creation — no app overview

**Context:** `lib/features/onboarding/presentation/onboarding_dialog.dart:91,110` — Both "Skip" and "Get Started" navigate to `AppRoutes.subjectSelection`. Users land immediately on a subject creation screen with no explanation of the dashboard, planner, or mentor features they were just shown in the onboarding carousel.

**Rationale:** The onboarding shows feature highlights but then dumps users into a creation flow. A brief tour of the main screen would improve first-run experience.

**Affected files:**
- `lib/features/onboarding/presentation/onboarding_dialog.dart` (lines 91, 110)

**Acceptance criteria:**
- After onboarding, user lands on the main Dashboard screen
- A subtle hint/badge points to the "+" FAB or subject list tab
- The onboarding carousel remains accessible from Settings

---

### m21. `SubjectSelectionScreen` loading spinner in AppBar lacks semantics

**Context:** `lib/features/subjects/presentation/subject_selection_screen.dart:212` — `ResponsiveUtils.loaderInTouchTarget()` in the AppBar actions. The spinner has no `Semantics` label for screen readers.

**Affected files:**
- `lib/features/subjects/presentation/subject_selection_screen.dart` (line 212)

**Acceptance criteria:**
- The loading spinner has `Semantics(label: l10n.saving, liveRegion: true)`

---

### m22. `dashboardAllMasteryProvider` returns `[]` on failure without logging

**Context:** `lib/features/dashboard/data/dashboard_data_providers.dart:31-37`
All other providers in the same file log errors with `.w()`. This one checks `result.isSuccess` but returns `[]` on failure silently.

**Affected files:**
- `lib/features/dashboard/data/dashboard_data_providers.dart` (lines 31-37)

**Acceptance criteria:**
- Add `_logger.w('Failed to load dashboard mastery data: \$error')` in the failure branch

---

### m23. Infinite spinner in `PracticeSessionScreen` with no back navigation

**Context:** `lib/features/practice/presentation/screens/practice_session_screen.dart:581-589` — When `_questions.isEmpty && !_isSessionComplete`, shows `LoadingIndicator()`. If question loading fails, the user sees an infinite spinner. The AppBar has a title but relies on `ModalRoute` for the back button, which may not function during the transition.

**Affected files:**
- `lib/features/practice/presentation/screens/practice_session_screen.dart` (lines 581-589)

**Acceptance criteria:**
- Add a timeout to detect failed question loading
- Show an error state with retry and back buttons when loading fails
- Ensure the AppBar has a visible back button during loading

---

### m24. `settings_repository_provider` initializes without try/catch

**Context:** `lib/features/subjects/providers/subjects_repository_provider.dart` (full file, not shown in exploration but mentioned in analysis) — `AsyncNotifier.build()` calls `repository.init()` with no error handling. A failure during repo initialization (e.g., Hive box cannot open) would throw an uncaught exception.

**Affected files:**
- `lib/features/subjects/providers/subjects_repository_provider.dart`

**Acceptance criteria:**
- Wrap `build()` logic in try/catch returning `AsyncValue.error()` with localized message

---

### m25. `subjects_list_provider.dart` silently returns `[]` on failure

**Context:** `lib/features/subjects/providers/subjects_list_provider.dart:6-10`
No try/catch. `repo.getAll()` failure silently returns `[]` without logging.

**Affected files:**
- `lib/features/subjects/providers/subjects_list_provider.dart` (lines 6-10)

**Acceptance criteria:**
- Wrap in try/catch with `.w()` logging
- UI handles the error state (either via `AsyncValue.error` or a fallback)

---

### m26. `SubjectDetailScreen` stateful tab manages its own state outside Riverpod

**Context:** `lib/features/subjects/presentation/subject_detail_screen.dart:428-601` — The `_SubjectSourcesTab` uses manual `setState` and `initState` instead of Riverpod providers, inconsistent with the parent screen.

**Affected files:**
- `lib/features/subjects/presentation/subject_detail_screen.dart` (lines 428-601)

**Acceptance criteria:**
- Convert to a Riverpod-based approach with `AsyncValue` for loading/error/data states
- Or at minimum document why manual state management is preferred for this specific tab

---

### m27. `PlannerScreen` "More lessons" navigates with potentially empty `topicId`

**Context:** `lib/features/planner/presentation/planner_screen.dart:1209-1212`
```dart
final first = state.scheduledLessons.first;
Navigator.pushNamed(context, AppRoutes.lessonList, arguments: LessonListArgs(
  topicId: first.topicId ?? '',
  ...
));
```
If `first.topicId` is null, the empty string `''` is passed as `topicId`, causing the `LessonListScreen` to receive an invalid argument and likely crash or show empty.

**Affected files:**
- `lib/features/planner/presentation/planner_screen.dart` (lines 1209-1215)

**Acceptance criteria:**
- Check that `first.topicId` is non-null before navigating, or handle the empty case in `LessonListScreen`
- Show a user-friendly message if topic ID is missing

---

### m28. `LessonDetailScreen` shows "generating" state when blocks are empty

**Context:** `lib/features/lessons/presentation/lesson_detail_screen.dart:152-179` — When lesson blocks are empty, shows a nice "generating" state with a progress indicator. This is good UX. BUT the loading state for `_lesson == null` (line 145-148) shows just a bare spinner with no AppBar or back button — inconsistent.

**Affected files:**
- `lib/features/lessons/presentation/lesson_detail_screen.dart` (lines 145-148 vs 152-179)

**Acceptance criteria:**
- Both loading states should have a consistent Scaffold with AppBar and back button

---

### m29. Filter bottom sheets in `ContentLibraryScreen` are near-duplicates

**Context:** `lib/features/ingestion/presentation/content_library_screen.dart` — `_showSubjectFilter`, `_showTypeFilter`, `_showStatusFilter` are nearly identical. Only the data type changes.

**Affected files:**
- `lib/features/ingestion/presentation/content_library_screen.dart`

**Acceptance criteria:**
- Extract a generic `FilterBottomSheet<T>` widget that accepts a list of filters and a selection callback
- Eliminate duplicated sheet-building code

---

### m30. `MentorScreen` `_showProgressReport` method is 200+ lines

**Context:** `lib/features/mentor/presentation/mentor_screen.dart` — The `_showProgressReport` method spans ~200 lines with deeply nested dialogs, error handling, and data fetching.

**Affected files:**
- `lib/features/mentor/presentation/mentor_screen.dart`

**Acceptance criteria:**
- Extract the progress report into a separate dialog widget
- Break into smaller methods (max 30 lines each)

---

### m31. `AnswerValidationService` uses inline `Logger` (not static final)

**Context:** `lib/core/services/answer_validation_service.dart` — Uses inline logger (convention violation per AGENTS.md).

**Affected files:**
- `lib/core/services/answer_validation_service.dart`

**Acceptance criteria:**
- All Logger instances are `static final` at class level

---


