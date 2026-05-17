# UI/UX Master Audit — Comprehensive Findings

**Generated:** 2026-05-17  
**Audit scope:** All 15 feature modules + core layer (~200+ UI files reviewed)  
**Methodology:** Static code analysis of screen files, widgets, theme, routing, and utils for UI/UX defects.

---

## BLOCKER (app crashes or user cannot proceed)

### B1. Router returns `null` on bad argument types → black screen

**Files:** `lib/core/routes/app_router.dart:196,205,214,223,238,255`

Six routes return `null` from `onGenerateRoute` when the argument type does not match:
- `subjectDetail`, `practiceSession`, `lessonList`, `lessonDetail`, `tutor`, `examSession`

**Rationale:** Flutter treats a `null` return as "route not found" and does not fall through to the `default` case — the screen stays black with no error, no retry, no back button. The user must terminate and restart the app.

**Acceptance criteria:**
- Each of the 6 routes must either (a) show a user-friendly error screen with a "Go Back" button or (b) silently fall back to a default/empty state instead of `null`.
- Add a test that navigates to each route with wrong argument types and asserts no crash / black screen.

---

### B2. Unknown routes silently open Settings instead of showing a not-found page

**File:** `lib/core/routes/app_router.dart:261-262`

```dart
default:
  return _materialPageRoute(const SettingsScreen(), routeSettings);
```

**Rationale:** Navigating to any undefined route deep-links to the Settings screen with no explanation. The user has no idea they reached an invalid URL and cannot navigate back to where they intended.

**Acceptance criteria:**
- Replace with a dedicated `NotFoundScreen` widget that displays "Page not found" + a "Go to Dashboard" button.
- The `NotFoundScreen` must be accessible (heading semantics, focusable button).

---

### B3. Practice session question card has stub file/audio widgets that lose user input

**File:** `lib/features/practice/presentation/widgets/practice_session_question_card.dart:181,201-229`

- `_buildFileUploadWidget` and `_buildAudioRecordingWidget` are stubs that invoke `onAnswerSelected` with magic strings (`'file_uploaded'`, `'audio_recorded'`).
- Canvas drawing replaces actual drawing data with the string `"drawing submitted"`.
- File upload / audio buttons appear functional but capture no real data.

**Rationale:** Users who upload a file or record audio lose their input silently. The answer is recorded as a meaningless magic string — test results are invalid.

**Acceptance criteria:**
- Replace stubs with real `file_picker` / `speech_to_text` integrations OR remove the buttons if integration is deferred.
- If integration is deferred, hide the buttons entirely (do not show non-functional controls).
- Canvas drawings must serialize actual stroke data (not a placeholder string).

---

### B4. Onboarding navigation calls without `context.mounted` risk disposed-state crashes

**File:** `lib/features/onboarding/presentation/onboarding_dialog.dart:114,126,134`

`Navigator.pushNamed` and `Navigator.pop` are called without `if (!context.mounted) return;` guards.

**Rationale:** If the user rapidly dismisses the dialog (e.g., double-tapping "Skip"), the widget may be disposed before the async call completes. Flutter throws a `FlutterError` for `setState` or navigation on a disposed element.

**Acceptance criteria:**
- Every async navigation call in `onboarding_dialog.dart` must check `context.mounted` before invoking.
- Add tests that simulate rapid dialog dismissal and assert no crash.

---

### B5. Raw enum access on empty subject name crashes

**File:** `lib/features/subjects/presentation/subject_detail_screen.dart:96`

```dart
widget.args.subjectName[0].toUpperCase()
```

**Rationale:** If `subjectName` is an empty string (fallback or corrupt data), accessing index `[0]` throws a `RangeError`. The screen crashes immediately.

**Acceptance criteria:**
- Guard with `subjectName.isNotEmpty ? subjectName[0].toUpperCase() : '?'`.
- Add a test with empty subject name.

---

## MAJOR (feature is broken or misleading)

### M1. `e.toString()` leaked to users across 11+ files

**Files:**
- `tutor_screen.dart:116` — `l10n.tutorInitFailed(e.toString())`
- `mentor_screen.dart:101` — `l10n.mentorInitFailed(e.toString())`
- `session_history_screen.dart:178,230`
- `session_tracker_screen.dart:168`
- `settings_screen.dart:486,493,518,558`
- `profile_screen.dart:124`
- `subject_list_screen.dart:37,53`
- `subject_detail_screen.dart:307-309`
- `subject_selection_screen.dart:136`
- `focus_timer_screen.dart:174-177`
- `upload_screen.dart:93,127,162,237,253,288`
- `export_section.dart:106`

**Rationale:** Raw exception strings (stack traces, file paths, network error codes) are shown verbatim in SnackBars and dialogs. This is a privacy/security concern and produces incomprehensible technical error messages for end users.

**Acceptance criteria:**
- Every `e.toString()` in a user-facing string must be replaced with a user-friendly mapped message.
- Create a utility function `userFriendlyError(dynamic error)` that maps common exception types to localized messages.
- The original error should still be logged via `_logger.e()` for debugging.

---

### M2. Silent error-to-empty conversion in ALL dashboard providers

**Files:**
- `dashboard_screen.dart:42-55` — all providers use `valueOrNull ?? []` / `valueOrNull ?? const X()`
- `mastery_progress_card.dart:15` — `snapshot ?? const MasterySnapshot()`
- `session_history_screen.dart:42` — `sessionsResult.data ?? []`
- `subject_stats_tab.dart:26-33` — silent `return []`
- `subject_lessons_tab.dart:27-33` — silent `return []`
- `subject_history_tab.dart:26-34` — silent `return []`
- `focus_timer_screen.dart:67-71,132-133`
- `upload_screen.dart:68`
- `planner_screen.dart:845-855`

**Rationale:** Every provider error is silently converted to empty/default data. The user can never distinguish between "no data exists" and "data failed to load." A completely broken backend looks identical to a fresh install.

**Acceptance criteria:**
- Each provider must expose its error state via `AsyncValue.error`.
- Each card/section must show a distinct error state (icon + message + retry button) when its provider is in error, rather than showing zero-value defaults.
- Error states must be distinguishable from empty/loading states.

---

### M3. Raw internal data shown to users in 7+ locations

**Files:**
- `planner_screen.dart:561` — `goal.subjectId` shown as display text when title is empty
- `planner_screen.dart:690,708` — `lesson.topicId ?? ''` in card subtitle
- `color_utils.dart:52,77` — raw hex codes like `"#AABBCC"` for unknown colors
- `subject_detail_screen.dart:37,53` — `'${snapshot.error}'` string interpolation
- `exam_session_screen.dart:602-605` — raw `e.key` from `result.topicBreakdown`
- `topic_breakdown_card.dart:118-119` — `level.name` (raw enum name) fallback
- `session_history_screen.dart:381` — `_selectedSubject` which is `session.subjectId`
- `weak_areas_card.dart:97-109` — empty `subjectId: ''` used as navigation arg

**Rationale:** Users see internal database identifiers, enum names, hex color codes, and raw exception strings. This erodes trust and makes the app feel unfinished.

**Acceptance criteria:**
- Every user-facing string must be derived from a display-friendly field (e.g., `subjectTitle` not `subjectId`).
- Where display data is unavailable, show a localized fallback like "Unknown" rather than raw IDs.
- Remove all raw `e.toString()` from UI (covered by M1).

---

### M4. No loading state during initial data loads on 5+ major screens

**Files:**
- `planner_screen.dart:60-64,312-455` — empty form while `loadInitialData()` runs
- `mentor_screen.dart:253-263` — no spinner while initializing, just a disabled input
- `tutor_screen.dart:444` — bare `CircularProgressIndicator` with no label / cancel button
- `profile_screen.dart:44-74` — blank fields while profile loads
- `subject_list_screen.dart:17-18,46` — double-loader flicker (outer `AsyncValue.when` + inner `FutureBuilder`)
- `subject_stats_tab.dart:35-154` — flash of zero values before stats load
- `subject_history_tab.dart:36` — no `ConnectionState.waiting` check at all
- `lesson_booking_sheet.dart:57-73` — availability loads silently, values may abruptly change

**Rationale:** Users see empty forms, blank screens, or flash of zero values before data arrives. On slow devices this makes the app feel broken or unresponsive.

**Acceptance criteria:**
- Every screen with async data must show a loading indicator (skeleton/shimmer preferred over plain spinner) during initial load.
- Loading states must be distinguishable from empty states.
- No "flash of empty data" — loaders must appear until data is ready.
- Combined outer/inner loaders must be unified into a single loading path.

---

### M5. Calendar week-start not locale-aware

**File:** `lib/features/planner/presentation/widgets/calendar_view_widget.dart:38,127`

```dart
firstDay.weekday % 7     // assumes Monday = 1 -> 0-indexed
now.subtract(Duration(days: now.weekday - 1))  // Monday is always week start
```

**Rationale:** Many locales (US English `en_US`, Arabic `ar`, Hebrew `he`) start their week on Sunday. The calendar grid columns will be misaligned — Sunday appears in the Monday column and vice versa.

**Acceptance criteria:**
- Use `intl` package `DateFormat` or derive first-day-of-week from `localeName` (e.g., via `material_localizations`' `firstDayOfWeekIndex`).
- Calendar headers and grid columns must match the user's locale.
- Add tests for `en_US` (Sunday start) and `ar` (Saturday start) locales.

---

### M6. Missing empty states in bottom sheets and sections

**Files:**
- `subject_selection_sheet.dart:51-71` — empty subjects list shows only the title
- `topic_selection_sheet.dart:16-31,38-52` — empty topics list shows only the title
- `weak_areas_sheet.dart:49-62` — empty subjects renders nothing useful
- `lesson_detail_screen.dart:163-174` — zero-block lesson shows blank body
- `topic_list_screen.dart:55-57` — weak empty state with no action button (dead end)
- `weekly_chart.dart:16-23` — zero-data shows 40px-tall bars (misleading)

**Rationale:** Users encounter blank sheets, empty white space, or misleading zero-value bars with no explanation or call to action.

**Acceptance criteria:**
- Every bottom sheet / section that receives a list must check for empty and show: icon + message + (optionally) a CTA button.
- Weekly chart must show a "No activity data yet" message instead of fake bars.
- Empty states must be semantically labeled for screen readers.

---

### M7. Bottom sheet unbounded `Column` overflow risk

**Files:** `subject_selection_sheet.dart:51-71`, `topic_selection_sheet.dart:18-31`, `weak_areas_sheet.dart`, `settings_screen.dart:812`

`Column(mainAxisSize: MainAxisSize.min, children: [...map()...])` will overflow when there are many items (>8-10).

**Rationale:** On devices with many subjects/topics, the bottom sheet exceeds the viewport height — users cannot scroll to see all items. The last items are cut off.

**Acceptance criteria:**
- Replace `Column` with `ListView(shrinkWrap: true)` or wrap in `SingleChildScrollView` with constrained height.
- Test with 15+ items to verify scrolling.

---

### M8. No loading/error/empty states on export section (only plain `Card`)

**File:** `lib/features/dashboard/presentation/widgets/export_section.dart:90-206`

All other dashboard cards use `CollapsibleCard` with `asyncValue` error/loading handling. The export section uses a plain `Card` with no state management.

**Rationale:** Export operations (PDF generation, CSV export) can take 5-30 seconds. Users see no spinner, no progress indicator. If providers fail, export buttons remain enabled and may crash on tap. No confirmation dialog — accidental taps trigger long operations.

**Acceptance criteria:**
- Add a loading overlay or inline spinner on each export button while the operation runs.
- Add a confirmation dialog before initiating exports.
- Disable buttons when underlying data providers are in loading/error state.
- Show a success SnackBar with file path when complete, or error SnackBar on failure (user-friendly, not `e.toString()`).

---

### M9. Accessibility: `liveRegion` on countdown timer fires every second — screen reader noise

**Files:**
- `focus_timer_widget.dart:154-192` — `Semantics(liveRegion: true)` on timer text updates every tick
- `focus_timer_screen.dart:279-281` — same pattern in break view
- `chat_bubble.dart:124-133` — `liveRegion: true` on every streaming chunk

**Rationale:** Screen readers re-announce the full timer string every second ("Timer remaining, 24 minutes and 53 seconds... 24 minutes and 52 seconds..."). This is extremely disruptive — users will turn off their screen reader.

**Acceptance criteria:**
- Timer `liveRegion` should update at most every 30 seconds, or only announce on significant state changes (pause/resume/complete).
- Use `liveRegion: false` with a periodic `announce()` call instead.
- Chat bubble streaming should only use `liveRegion` on the *first* chunk, not every word.

---

### M10. Keyboard shortcut `onSubmitted` bypasses loading/enabled check

**File:** `lib/core/widgets/conversation_input.dart:114`

```dart
onSubmitted: (_) => widget.onSend(),
```

**Rationale:** The `TextFormField.onSubmitted` always fires when the user presses Enter/Return, even when `widget.isLoading` is true or `widget.isEnabled` is false. The button's `onPressed` correctly checks these conditions, but the keyboard path does not.

**Acceptance criteria:**
- `onSubmitted` must guard with `if (!widget.isEnabled || widget.isLoading) return;` before calling `widget.onSend()`.
- Add tests for keyboard submission during loading state.

---

### M11. `BottomSheetTheme.bottomSheetShape` constant defined but never wired

**File:** `lib/core/theme/app_theme.dart:150-152`

```dart
static const bottomSheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
);
```

No `bottomSheetTheme` is set in the theme, so every bottom sheet in the app uses default sharp corners unless each individual sheet manually references this constant.

**Rationale:** Visual inconsistency across bottom sheets — some may have rounded corners, others sharp, depending on whether the developer remembered to apply the constant.

**Acceptance criteria:**
- Wire `bottomSheetShape` into the theme via `bottomSheetTheme: BottomSheetThemeData(shape: bottomSheetShape)` in `_baseTheme`.

---

### M12. Inconsistent navigation affordances — tappable card without chevron

**File:** `dashboard_screen.dart:101-111` vs `223-249`

The Focus Mode card uses `InkWell` with no visual chevron. The Planner card uses `InkWell` with `Icons.chevron_right`. Both navigate to another screen.

**Rationale:** Users cannot visually distinguish the Focus card as tappable. It looks like a static info card while the Planner card clearly invites navigation. Discoverability is broken.

**Acceptance criteria:**
- All navigable cards on the dashboard must have a consistent visual affordance (chevron or ">" indicator).
- Or, use a system-wide pattern like colored underline on hover/focus for tappable cards.

---

### M13. Placeholder skeleton has no animation

**File:** `dashboard_screen.dart:186-218`

`_buildSkeletonLoading` renders static gray `Container` boxes with no shimmer/pulse animation.

**Rationale:** Static gray boxes look like the app is frozen or broken. Users perceive the app as unresponsive.

**Acceptance criteria:**
- Add a shimmer/pulse animation to skeleton loading placeholders using `AnimatedContainer` or `ShaderMask`.
- The animation should continue until all providers finish loading.

---

### M14. `isFirstLoad` prevents skeleton from showing during refresh

**File:** `dashboard_screen.dart:60-67`

`isFirstLoad` is only `true` on the very first render. Pull-to-refresh shows individual `CircularProgressIndicator` per card instead of the unified skeleton.

**Rationale:** Inconsistent loading UX — initial load shows a skeleton, refresh shows individual spinners (jarring mixed state when providers load at different speeds).

**Acceptance criteria:**
- Show a unified full-screen loading overlay during pull-to-refresh (not individual card spinners).
- Or, show skeleton for all cards that are currently reloading.

---

### M15. No "skip to main content" landmark for keyboard/screen reader users

**Files:** All screens

**Rationale:** Every screen with a header/app bar forces screen reader and keyboard users to navigate through all header elements before reaching the main content. There is no "Skip to content" link.

**Acceptance criteria:**
- Add a `Focus`-based skip link as the first focusable element on every major screen.
- The link should be visually hidden but visible on focus: "Skip to main content."
- On activation, focus moves to the main content `Semantics` container.

---

### M16. Weak areas card has no error/loading states and dead-end navigation

**File:** `lib/features/dashboard/presentation/widgets/weak_areas_card.dart`

**Rationale:** No loading skeleton, no error state, no empty state. "Practice All Weak Areas" button uses error color (signals danger, but the action is positive). Navigation passes `subjectId: ''` which can lead to broken practice sessions.

**Acceptance criteria:**
- Add loading/error/empty states matching other cards.
- Change button color from `error` to `primary` or `tertiary`.
- Pass valid subject IDs or disable the button when no valid subject is available.

---

### M17. Running/done LLM task status share same color

**File:** `lib/core/theme/app_theme.dart:188-193`

```dart
LlmTaskStatus.running => cs.primary,
LlmTaskStatus.done => cs.primary,
```

**Rationale:** Users cannot distinguish between an actively processing task and a completed one. This is functionally misleading — a task may appear to still be running when it is finished.

**Acceptance criteria:**
- `running` should remain `primary` (purple/blue).
- `done` should use a distinct color such as `Colors.green` or `cs.tertiary`.

---

### M18. Missing disabled/error/focus/hover theming in base theme

**File:** `lib/core/theme/app_theme.dart:25-97`

No `disabledColor`, `errorBorder`, `focusColor`, `hoverColor`, `dividerTheme`, `snackBarTheme`, `dialogTheme`, or `textSelectionTheme` are configured.

**Rationale:** Disabled fields, error states, focus rings, dividers, and selection handles use Material 3 defaults (Material blue) instead of the app's purple palette. Visual inconsistency across the app. Focus indicators are not visible enough for keyboard accessibility.

**Acceptance criteria:**
- Add explicit theme properties: `disabledColor`, `disabledTextColor`, `inputDecorationTheme.errorBorder`, `focusColor` with 10-15% opacity, `hoverColor` with 5-8% opacity, `splashFactory`, `dividerTheme`, `snackBarTheme`, `dialogTheme`, `textSelectionTheme`.
- All values must derive from the app's color scheme (deep purple seed).

---

### M19. `ensureMinTouchTarget` does not center child widget

**File:** `lib/core/utils/responsive.dart:130-139`

```dart
SizedBox(width: minTouchTarget, height: minTouchTarget, child: child);
```

**Rationale:** A 24x24 icon child is positioned in the top-left corner of the 48x48 box. The visual touch target remains 24x24 even though the hit area is 48x48. Screen reader focus rectangle also appears in the wrong position.

**Acceptance criteria:**
- Wrap `child` in `Center()` or `Align()` inside the `SizedBox`.

---

### M20. Unlocalized hardcoded English strings

**Files & occurrences:**
- `tutor_screen.dart:180` — `const Text('Gallery')`
- `settings_screen.dart:476` — `'StudyKing Backup'`
- `practice_session_question_card.dart:205,211,220,226` — `'Upload file'`, `'File attached'`, `'Record audio'`, `'Start recording'`
- `session_history_screen.dart:367` — date format `'${day}/${month}/${year}'` (hardcoded `d/M/yyyy`)
- `animated_bar_chart.dart:144` — default semantics label `'$day: $count sessions'`
- `onboarding_dialog.dart:7-9` — magic string keys `_onboardingKey`, `_dontShowAgainKey`
- `quick_guide_screen.dart:181-184` — English-only keyword matching in `_fallbackResponse`

**Rationale:** Hardcoded English strings break i18n for Spanish (`es`) users and any future locales. Date formats that don't respect locale are confusing (US users see `3/5/2026` as March 5 but the code produces `3/5/2026` as day/month/year format if they are in US).

**Acceptance criteria:**
- Replace every hardcoded English string with `AppLocalizations.of(context)!`.
- Replace raw date formatting with `DateFormat.yMd()` or `DateFormat.yMMMd()` from `intl`.
- Localize keyword detection or use a language-agnostic approach for fallback responses.
- Version onboarding keys so existing users don't re-see onboarding after a key rename.

---

### M21. Localization concatenation anti-pattern (number + label)

**File:** `plan_summary_card.dart:59-62`

```dart
'${summary.newTopics} ${l10n.newTopics}'
```

**Rationale:** Word order varies by language. In German, "5 neue Themen" places the number before the noun (same as English). In Japanese, the noun comes last: "5 新しいトピック". Concatenation breaks translation.

**Acceptance criteria:**
- Use parameterized localization strings: `l10n.newTopicsCount(summary.newTopics)` where the ARB file defines `newTopicsCount` with `{count}` placeholder.
- Verify the fix for `en` and `es` locales.

---

### M22. Skeleton loading shows all 6 cards even if some providers finish early

**File:** `dashboard_screen.dart:60-67,186-218`

`isFirstLoad` waits for ALL providers before showing any content. Fast providers' data is unnecessarily delayed.

**Rationale:** If one provider is very slow (e.g., LLM-based mastery recalculation), the entire dashboard stays in skeleton mode while data from 5 other providers is ready to display. The user waits longer than necessary.

**Acceptance criteria:**
- Show each card as soon as its individual provider completes, rather than waiting for all.
- Use individual `AsyncValue.when` per card, not a single `isFirstLoad` gate.

---

### M23. `CollapsibleCard` semantics hint says "refresh" but it collapses

**File:** `lib/features/dashboard/presentation/widgets/collapsible_card.dart:75`

`Semantics(hint: l10n.tapToRefreshSection)`

**Rationale:** The semantic hint tells screen reader users that tapping refreshes the section. The actual behavior is toggling collapse/expand. The user receives incorrect guidance.

**Acceptance criteria:**
- Change hint to `l10n.tapToCollapse` / `l10n.tapToExpand` based on current state.

---

### M24. No loading states anywhere in 14 of 18 widget files audited

**Affected files (representative):**
- `badges_card.dart`, `plan_adherence_card.dart`, `summary_row.dart`, `topic_breakdown_card.dart`, `weak_areas_card.dart`, `mistake_review_widget.dart`, `weak_areas_sheet.dart`, `milestone_timeline.dart`, `roadmap_card.dart`, `plan_summary_card.dart`, `metric_card.dart`, `animated_bar_chart.dart`, `pending_action_card.dart`, `practice_empty_state.dart`

**Rationale:** These widgets expect data to be pre-loaded and have no loading, error, or empty states. If the parent loads them while data is being fetched, the user sees a flash of empty/default content.

**Acceptance criteria:**
- Every widget that displays fetched data must accept an `AsyncValue<T>` parameter and render distinct loading / error / data / empty states.
- Minimum: loading skeleton (with animation), error icon + retry, empty icon + message.

---

## MINOR (code quality / UX friction)

### m1. Inconsistent button styles

- `practice_results_screen.dart:70` — uses `ElevatedButton.icon` while other screens use `FilledButton.icon` for primary actions.
- `export_section.dart:60-83` — top and bottom rows both use `TextButton.icon` with no clear visual hierarchy.
- `subject_list_screen.dart:79` — `ElevatedButton.icon` in empty state vs `FilledButton.icon` / `OutlinedButton.icon` elsewhere.

**Acceptance criteria:** Define a single button style per hierarchy level (primary = `FilledButton`, secondary = `OutlinedButton`, tertiary = `TextButton`) and use consistently across the app.

---

### m2. Duplicate code — `_getSubjectColor` in two files

**Files:** `subject_selection_sheet.dart:19-32`, `subject_practice_card.dart:16-29`

Same hash-based color algorithm duplicated verbatim.

**Acceptance criteria:** Extract to a shared utility function in `core/utils/color_utils.dart`.

---

### m3. Duplicate code — `_sessionIcon`, `_sessionColor` in two session files

**Files:** `session_history_screen.dart:622-646`, `session_tracker_screen.dart:381-405`

SessionType → icon and color mapping duplicated.

**Acceptance criteria:** Extract to a shared utility or extension method in the sessions feature.

---

### m4. Duplicate `_statChip` implementation

**Files:** `lesson_progress_bar.dart:181-199`, `tutor_screen.dart:351-372`

Identical visual concept (icon + label + value), different implementation (one wraps in `Container` with background, other is bare `Row`).

**Acceptance criteria:** Extract a shared `StatChip` widget to `core/widgets/`.

---

### m5. `_ExtraModeCard` duplicates `PracticeModeCard`

**File:** `practice_screen.dart:607-657` duplicates `practice_mode_card.dart`

**Acceptance criteria:** Reuse `PracticeModeCard` with different parameters instead of duplicating.

---

### m6. Deprecated `theme.primaryColor` used

**File:** `subject_detail_screen.dart:146`

```dart
labelColor: theme.primaryColor
```

Should use `theme.colorScheme.primary`.

**Acceptance criteria:** Replace all uses of `.primaryColor` with `.colorScheme.primary`.

---

### m7. Provider anti-pattern — direct `.state` mutation

**Files:** `settings_screen.dart:348,692`, `profile_screen.dart:61`

```dart
ref.read(provider.notifier).state = value;
```

**Rationale:** Direct state mutation bypasses Riverpod's intended `update`/`controller` pattern and can cause unexpected rebuilds.

**Acceptance criteria:** Use `ref.read(provider.notifier).update(value)` or a dedicated notifier method.

---

### m8. Duplicate welcome messages in mentor history

**File:** `mentor_screen.dart:80-95,119-123`

Welcome message added to `_messages` in `initState` and also loaded from `memory.getHistory()`. If history already contains a welcome from a previous session, the user sees two welcome messages.

**Acceptance criteria:** Deduplicate — only add the welcome message if history is empty.

---

### m9. `NaN` progress value in `LinearProgressIndicator`

**File:** `subject_stats_tab.dart:132`

```dart
value: avgScore / 100
```

When `avgScore` is `NaN` (0 questions / 0 correct), `0/0 = NaN`, causing indeterminate animation.

**Acceptance criteria:** Guard with `avgScore.isNaN || avgScore.isFinite ? avgScore / 100 : 0.0`.

---

### m10. `Null` check after catch for collapsed service

**File:** `main.dart:67-102,270-296`

The entire init chain (`Hive.initFlutter`, `DatabaseService.init`, `SettingsRepository.init`, `EngagementScheduler.init`) is wrapped in a try-catch that logs but continues to `runApp`. If initialization partially fails, the app runs with partially broken state but no indication to the user.

**Acceptance criteria:** Show a persistent error banner ("Some services failed to load. Some features may be unavailable.") if critical services fail during init.

---

### m11. Animation resets on data identity changes

**File:** `animated_bar_chart.dart:90-95`

```dart
if (oldWidget.data != widget.data) {
  _hasAnimated = false;
}
```

If the parent creates a new `Map` with identical values, the bars re-animate from 0. Unnecessary visual disruption.

**Acceptance criteria:** Use deep equality (e.g., `mapEquals`) instead of identity comparison.

---

### m12. `reduceMotion` path never sets `_hasAnimated`

**File:** `animated_bar_chart.dart:50-60,69-72`

When `widget.reduceMotion` is true, `_hasAnimated` stays `false`. If motion preference changes later, bars jump from 0.

**Acceptance criteria:** Set `_hasAnimated = true` in the `reduceMotion` path.

---

### m13. Screen reader double-label on Send button during loading

**File:** `conversation_input.dart:122-134`

Semantics label still says `widget.sendTooltip` ("Send message") even when `isLoading` is true and the button shows a spinner.

**Acceptance criteria:** Change semantics label to `l10n.sending` when `isLoading == true`.

---

### m14. No `maxLines`/`overflow` on long text in 10+ locations

**Files (representative):**
- `metric_card.dart:37-50` — value and label
- `practice_feedback_widget.dart:52-56` — explanation text
- `practice_session_question_card.dart:141-146` — question text
- `mistake_review_widget.dart:161-163` — mistake question text
- `lesson_block_card.dart:29` — block content
- `lesson_detail_screen.dart:169` — block content
- `daily_plan_card.dart:72` — topic title
- `milestone_timeline.dart:126-128` — milestone title
- `plan_summary_card.dart:68-73` — focus areas
- `planner_screen.dart:700,708` — lesson subtitle concatenation

**Rationale:** Long text overflows container bounds, breaking layout or causing horizontal overflow warnings.

**Acceptance criteria:** Add `maxLines` + `TextOverflow.ellipsis` to every unbounded `Text` widget that displays user-generated or localized content.

---

### m15. No scroll overflow protection in bottom sheets

**Files:** `subject_selection_sheet.dart`, `topic_selection_sheet.dart`, `weak_areas_sheet.dart`, `settings_screen.dart:812`

All use `Column(mainAxisSize: MainAxisSize.min)` which overflows with many items.

**Acceptance criteria:** Replace with `ListView(shrinkWrap: true)` or `SingleChildScrollView`.

---

### m16. `GradientContainer` near-invisible on light theme

**File:** `gradient_container.dart:27-28,32`

```dart
alpha: isDark ? 0.3 : 0.05  // end color, light theme: 5% opacity
```

An end color at 5% opacity is virtually invisible on most screens.

**Acceptance criteria:** Increase light-theme minimum alpha to 0.08 for end color and 0.15 for start color.

---

### m17. `WeakAreasCard` "Practice All" uses error color

**File:** `weak_areas_card.dart:87`

`theme.colorScheme.error` signals danger but the action is positive.

**Acceptance criteria:** Use `theme.colorScheme.primary` or `theme.colorScheme.tertiary`.

---

### m18. No progress indicator on session result navigation

**File:** `practice_session_screen.dart:328-336`

`Future.delayed(Timeouts.ms500, ...)` before navigating to results — unexplained delay with no feedback.

**Acceptance criteria:** Show a brief "Loading results..." overlay instead of a silent delay.

---

### m19. `ExamSessionScreen` builds its own results screen (duplicates `PracticeResultsScreen`)

**File:** `exam_session_screen.dart:565-631`

**Acceptance criteria:** Reuse `PracticeResultsScreen` with exam-specific parameters.

---

### m20. `mounted` not checked in `addPostFrameCallback`

**Files:** `main.dart:137-147`, `planner_screen.dart:59-64`, `tutor_screen.dart:375`

Post-frame callbacks that call `setState` / `context.read` without checking `mounted`.

**Acceptance criteria:** Add `if (!mounted) return;` as the first line of every post-frame callback body.

---

### m21. Hardcoded break duration / timer presets (not configurable)

**File:** `focus_timer_screen.dart:44,352,404`

Break duration hardcoded to 300s (5 min). Presets are `[10, 15, 25, 30, 45, 60]` minutes with no backend configuration or user customization.

**Acceptance criteria:** Add a settings UI for custom timer durations, or load defaults from `AppConfig`.

---

### m22. Stale subject list after create/delete (no refresh on pop)

**Files:**
- `subject_list_screen.dart:81` — `pushNamed` does not `await` result
- `subject_detail_screen.dart:305` — pop after delete doesn't notify list
- `subject_selection_screen.dart:123` — pop with result but caller doesn't await

**Rationale:** After creating or deleting a subject, the list screen shows stale data.

**Acceptance criteria:** Use `await Navigator.pushNamed` + `refresh` pattern, or invalidate the list provider.

---

### m23. Exam results ephemeral — no way to revisit after leaving

**File:** `exam_session_screen.dart:565-631`

`_buildResultsScreen` is rendered inline within the exam screen. The `ExamResult` is lost when the user navigates back.

**Acceptance criteria:** Save exam results to session history and add a "View Previous Exam Results" entry point.

---

### m24. No animation coordination between tab navigators

**File:** `tab_navigator.dart:20-36`

When switching tabs, the transition is abrupt with no cross-fade or shared-element animation.

**Acceptance criteria:** Add a subtle fade or slide transition when switching between tab navigators.

---

### m25. `onPopPage` not handled in nested navigator

**File:** `tab_navigator.dart:20-36`

**Rationale:** Combined with Android back-button handling, the nested navigator's history stack may not be properly managed, causing unexpected app exits.

**Acceptance criteria:** Define `onPopPage` in each `TabNavigator` and coordinate with the parent navigator.

---

### m26. Grid columns don't adjust for landscape orientation

**File:** `responsive.dart:72-84`

```dart
case ScreenBreakpoint.xs: return 2;
case ScreenBreakpoint.sm: return 2;
```

On phones in landscape (600-840dp wide, `sm`), 2-column grids produce very wide cards.

**Acceptance criteria:** Check `MediaQuery.orientation` and return 3 columns in landscape for `xs`/`sm` breakpoints.

---

### m27. `BadgeCard` shows name-only chips with no description

**File:** `badges_card.dart:45-49`

`BadgeDisplay.description` field exists but is never rendered. Each badge chip shows only the name via `Icons.emoji_events`.

**Acceptance criteria:** Show badge description as a tooltip or subtitle, and use category-specific icons.

---

### m28. Milestone timeline dots overlap on narrow screens

**File:** `milestone_timeline.dart:68-100`

`Positioned` widgets with `left: left - 6` collide when milestones are temporally close.

**Acceptance criteria:** Implement collision detection — if dots would overlap, stack them vertically with an offset or show a "+N more" indicator.

---

### m29. `PendingActionCard` uses fragile string-based type matching

**File:** `pending_action_card.dart:83-93,96-106`

```dart
action.actionType == 'schedule'
```

No enum or sealed class — a typo in data silently falls through to `default`.

**Acceptance criteria:** Use a `sealed class` or `enum` for action types with exhaustive pattern matching.

---

### m30. `RoadmapCard` progress shows 0% when no milestones exist

**File:** `roadmap_card.dart:26-28`

Falls back to `roadmap.completionPercentage / 100.0` when `totalMilestones == 0`. Shows "0% complete" even though no milestones exist yet.

**Acceptance criteria:** Show "Set up milestones to begin" instead of a 0% progress bar.

---

## BLOCKER Summary (5 items)

| ID | File | Issue |
|---|---|---|
| B1 | `app_router.dart` | 6 routes return `null` → black screen |
| B2 | `app_router.dart` | Unknown routes silently open Settings |
| B3 | `practice_session_question_card.dart` | Stub widgets lose user input |
| B4 | `onboarding_dialog.dart` | No `mounted` check → disposed-state crash |
| B5 | `subject_detail_screen.dart` | Empty name index-out-of-range crash |

## MAJOR Summary (24 items)

| ID | Issue | Primary files |
|---|---|---|
| M1 | Raw `e.toString()` leaked in 11+ files | 15+ feature files |
| M2 | Silent error-to-empty in all providers | `dashboard_screen.dart`, `session_history_screen.dart`, etc. |
| M3 | Raw internal data shown to users | `planner_screen.dart`, `color_utils.dart`, etc. |
| M4 | No loading state on 5+ major screens | `planner_screen.dart`, `mentor_screen.dart`, `profile_screen.dart`, etc. |
| M5 | Calendar not locale-aware | `calendar_view_widget.dart` |
| M6 | Missing empty states in sheets/sections | 6+ files |
| M7 | Unbounded Column in bottom sheets | `subject_selection_sheet.dart`, `topic_selection_sheet.dart`, etc. |
| M8 | Export section has no states | `export_section.dart` |
| M9 | `liveRegion` fires every second | `focus_timer_widget.dart`, `chat_bubble.dart` |
| M10 | Keyboard shortcut bypasses `isLoading` | `conversation_input.dart` |
| M11 | `bottomSheetShape` unwired | `app_theme.dart` |
| M12 | Inconsistent navigation affordances | `dashboard_screen.dart` |
| M13 | Static skeleton (no animation) | `dashboard_screen.dart` |
| M14 | Skeleton not shown during refresh | `dashboard_screen.dart` |
| M15 | No skip-to-content landmark | All screens |
| M16 | Weak areas card missing states/error color | `weak_areas_card.dart` |
| M17 | Running/Done LLM status same color | `app_theme.dart` |
| M18 | Missing disabled/focus/error theming | `app_theme.dart` |
| M19 | `ensureMinTouchTarget` doesn't center | `responsive.dart` |
| M20 | Hardcoded English strings / unlocalized dates | 6+ files |
| M21 | Number+label concatenation anti-pattern | `plan_summary_card.dart` |
| M22 | All-or-nothing skeleton (fast providers delayed) | `dashboard_screen.dart` |
| M23 | CollapsibleCard semantics hint wrong | `collapsible_card.dart` |
| M24 | 14/18 widgets have no loading/error/empty states | 14 widget files |

## MINOR Summary (30 items)

| ID | Issue |
|---|---|
| m1-m5 | Inconsistent button styles + 4 code duplications |
| m6 | Deprecated `primaryColor` API |
| m7 | Provider direct state mutation anti-pattern |
| m8-m10 | Duplicate welcome, NaN progress, silent init failure |
| m11-m13 | Animation reset, reduceMotion bug, double semantics label |
| m14 | No overflow handling on 10+ long-text widgets |
| m15 | No scroll protection in 4 bottom sheets |
| m16-m19 | Near-invisible gradient, error-color confusion, 500ms delay, duplicate results screen |
| m20-m23 | Missing mounted checks, hardcoded presets, stale lists, ephemeral results |
| m24-m26 | Tab animation, onPopPage handling, landscape grid columns |
| m27-m30 | Badge descriptions hidden, milestone overlap, string-based action types, 0% progress confusion |
