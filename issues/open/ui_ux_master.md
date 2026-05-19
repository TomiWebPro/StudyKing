# UI/UX Master Audit

**Date:** 2026-05-19
**Scope:** Full codebase exploration — all 29 screens, routing, theming, l10n, accessibility, responsiveness, animations, navigation flows.

---

## BLOCKER — User cannot proceed

### B1. Dashboard "Next Up" cards navigate to NotFoundScreen

**Files:**
- `lib/features/dashboard/presentation/widgets/next_up_card.dart:97,106`

**Issue:** Two `Navigator.pushNamed(context, AppRoutes.practiceSession)` calls pass **no arguments**. The router's `onGenerateRoute` requires `PracticeSessionArgs` — the `is` check fails, the fallback `_errorRoute` fires, and the user sees the "Page Not Found" screen instead of a practice session.

**Impact:** "Reviews Due" and "Practice Weak Areas" cards on the Dashboard are completely non-functional. User taps and gets a dead end.

**Fix:** Pass `PracticeSessionArgs(subjectId: ...)` with the correct subject ID in both call sites.

**Acceptance criteria:**
- Tapping "Reviews Due" on Dashboard starts a practice session (not the 404 screen)
- Tapping "Practice Weak Areas" on Dashboard starts a practice session (not the 404 screen)

---

## MAJOR — Feature broken or misleading

### M1. TutorScreen silently drops FocusTimer presets

**File:** `lib/features/teaching/presentation/tutor_screen.dart:397,411`

**Issue:** `_startFocusModePractice()` and `_startPostLessonPractice()` pass `arguments: FocusTimerScreen(...)` (a **Widget**) instead of `arguments: FocusTimerScreenArgs(...)`. The router checks `if (args is FocusTimerScreenArgs)` — this always fails, so the fallback `const FocusTimerScreen()` runs with **zero presets**.

**Impact:** After a lesson, pressing "Focus Mode Practice" opens a fresh timer with default 25 minutes and no preselected subject/topic. The intended contextual session (15 min, specific subject+topic) is lost silently — no error, no crash, just wrong behavior.

**Fix:** Replace `arguments: FocusTimerScreen(...)` with `arguments: FocusTimerScreenArgs(preselectedSubjectId: ..., preselectedTopicId: ..., defaultDurationMinutes: ...)`.

**Acceptance criteria:**
- After a lesson, tapping "Focus Mode Practice" opens the timer with the correct subject pre-selected
- The timer duration matches what was intended (15 min / 30 min)
- The subject/topic are reflected in the timer UI

---

### M2. TopicListScreen is a dead screen (not registered in routing)

**File:** `lib/features/lessons/presentation/topic_list_screen.dart`

**Issue:** `TopicListScreen` is a full `ConsumerStatefulWidget` with loading, empty, and error states, but has **no route constant** in `AppRoutes` and **no case** in `onGenerateRoute`. It cannot be navigated to via the routing system. No code in the codebase instantiates it directly.

**Impact:** The topic list view is completely inaccessible to users. It's dead code.

**Fix:** Register a route (e.g., `/topic-list`) in `AppRoutes` and `onGenerateRoute`, or remove the file if the feature is intentionally disabled. If kept: add the route constant, add the route handler, and add navigation callers.

**Acceptance criteria:**
- Topics can be browsed via a navigable route
- OR the file is removed with a note in changelog

---

### M3. No onboarding re-trigger mechanism

**Files:**
- `lib/features/onboarding/services/onboarding_service.dart`
- `lib/features/settings/presentation/settings_screen.dart`

**Issue:** The onboarding tour (`OnboardingDialog` with 6 pages) is shown only once on first launch. `OnboardingService` exposes `markCompleted()` and `markDontShowAgain()` but **no reset/retrigger method**. There is no option in Settings, Profile, or anywhere else to re-experience the tour.

**Impact:** A user who skipped through onboarding, or wants to revisit after an update, cannot. The feature exists but is single-use.

**Fix:** Add a "Show onboarding tour" or "Reset onboarding hints" option in Settings > About/Help section. Implement `OnboardingService.resetOnboarding()` that clears the Hive flags.

**Acceptance criteria:**
- Settings screen has a tappable option to re-trigger onboarding
- The onboarding dialog shows again when activated
- The "Don't show again" checkbox still works as expected

---

### M4. Inconsistent button type usage — `ElevatedButton` for destructive/primary actions

**Files (representative sample of 12+ occurrences):**
- `lib/features/settings/presentation/settings_screen.dart:1593` (sign out — uses `ElevatedButton` with error color)
- `lib/features/ingestion/presentation/source_detail_screen.dart:524` (delete source)
- `lib/features/ingestion/presentation/content_library_screen.dart:505` (delete source)
- `lib/features/questions/presentation/question_bank_screen.dart:156` (delete questions)
- `lib/features/subjects/presentation/subject_detail_screen.dart:348` (delete subject)
- `lib/features/lessons/presentation/lesson_detail_screen.dart:249` ("AI Tutor" primary CTA)
- `lib/features/ingestion/presentation/upload_screen.dart:609` ("Upload and Analyze" primary CTA)

**Issue:** `ElevatedButton` is used interchangeably for:
1. **Destructive actions** (delete, sign out) — should use `FilledButton` with `AppTheme.destructiveButtonStyle(context)`
2. **Primary CTAs** ("Upload", "AI Tutor") — should use `FilledButton`

The utility `AppTheme.destructiveButtonStyle(context)` is defined at `app_theme.dart:270` but is **never called** anywhere.

**Impact:** Users receive no visual distinction between neutral, primary, and destructive buttons. The Material 3 semantic hierarchy (text → outlined → filled → destructive) is not followed, reducing scannability and increasing error risk.

**Fix:** Replace destructive `ElevatedButton`s with `FilledButton(style: AppTheme.destructiveButtonStyle(context), ...)`. Replace primary CTAs with plain `FilledButton`.

**Acceptance criteria:**
- All destructive actions (delete, sign out, remove) use `AppTheme.destructiveButtonStyle()`
- All primary page-level CTAs use `FilledButton` (not `ElevatedButton`)
- No visual regression — colors and shapes remain consistent with M3

---

### M5. Snackbar utilities exist but are never used; 110+ raw `SnackBar` calls

**Files:**
- `lib/core/widgets/snackbar_utils.dart` — defines `showSuccessSnackBar` (green) and `showErrorSnackBar` (red) — **zero callers**
- 110+ raw `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))` calls across the codebase

**Issue:** The centralized snackbar utilities are orphaned. Every screen builds its own plain, uncolored `SnackBar`. There is no consistent error/success visual feedback system:
- `AppErrorHandler` (at `lib/core/errors/handlers.dart:37`) has its own colored snackbar scheme but isn't used everywhere
- Most snackbars inherit the default theme color (no success=green, error=red distinction)

**Impact:** Users get no visual cue differentiating success from failure. A delete confirmation looks identical to a save confirmation. This reduces feedback clarity and increases user errors.

**Fix:** Either (a) delete `snackbar_utils.dart` and route everything through an improved `AppErrorHandler`, or (b) refactor all raw calls to use the centralized utilities. Add success/error color differentiation.

**Acceptance criteria:**
- Successful operations show green-tinted snackbars
- Error operations show red-tinted snackbars
- No raw `ScaffoldMessenger.of(context).showSnackBar` calls remain (or they all go through a wrapper)
- Any unused utility file is removed to avoid dead code

---

### M6. Missing Spanish translation for `pageIndicator`

**Files:**
- `lib/l10n/app_en.arb` — contains `pageIndicator`
- `lib/l10n/app_es.arb` — **missing** `pageIndicator`

**Issue:** The `pageIndicator` key (`"{current} / {total}"`, used for slide/page indicators) exists in English but is absent from Spanish. Spanish users will see the English fallback.

**Fix:** Add the key to `app_es.arb`:
```json
"pageIndicator": "{current} / {total}",
"pageIndicatorParameters": {
  "current": "int",
  "total": "int"
}
```

**Acceptance criteria:**
- Running `flutter gen-l10n` produces no warnings about missing translations
- Page indicators on Spanish locale use localized format (e.g., `"1 / 5"`)

---

## MINOR — UX friction / code quality

### m1. Stale l10n in non-build methods

**Files:** 264+ `AppLocalizations.of(context)!` reads across the codebase. Many are inside `build()` (safe), but several async methods cache `l10n` at method start, risking stale text after a locale switch.

**Key examples:**
- `lib/features/teaching/presentation/tutor_screen.dart:126` — `_startLesson()` fetches l10n once; greeting stays in old locale if user switches mid-lesson
- `lib/features/focus_mode/presentation/focus_timer_screen.dart` — multiple non-build re-reads
- `lib/features/mentor/presentation/mentor_screen.dart` — 10+ non-build methods each re-read l10n

**Fix:** Ensure all async/promise-based methods that display user-facing strings re-read `AppLocalizations.of(context)!` rather than using a cached reference. For long-lived screens, consider adding `ref.watch(localeProvider)` to force rebuilds on locale change.

**Acceptance criteria:**
- Changing locale in Settings then performing any action shows the new locale's text
- Long-running methods (lesson, mentor init) use fresh locale at each string display

---

### m2. Loading spinner sizes are inconsistent

**Files:**
- `lib/core/utils/responsive.dart:141` — `loaderInTouchTarget()` standardizes at 20x20, **used only once** (`profile_screen.dart:349`)
- Inline spinners vary: 18×18 (mentor), 20×20 (common), 16×16 (upload, canvas), default size (loading_indicator)

**Fix:** Replace all inline `SizedBox(width: X, height: X, child: CircularProgressIndicator(strokeWidth: 2))` patterns with `ResponsiveUtils.loaderInTouchTarget()`.

**Acceptance criteria:**
- All button/small-area loading spinners are 20×20 with strokeWidth 2
- The utility is used in place of inline definitions

---

### m3. NotFoundScreen hardcodes `'/dashboard'` instead of `AppRoutes.dashboard`

**File:** `lib/core/widgets/not_found_screen.dart:54`

```dart
navigator.pushNamedAndRemoveUntil('/dashboard', (route) => false);
```

**Fix:** Replace `'/dashboard'` with `AppRoutes.dashboard`.

**Acceptance criteria:**
- No hardcoded route strings remain in the codebase
- If `AppRoutes.dashboard` is ever changed, `NotFoundScreen` stays in sync

---

### m4. LessonListArgs.subjectId default `''` is ambiguous

**File:** `lib/core/routes/app_router.dart:105`

**Issue:** `LessonListArgs.subjectId` defaults to `''`, but `topic_list_screen.dart:86` omits it entirely (using the default). Caller `planner_screen.dart:1208` explicitly passes `first.subjectId ?? ''`. This inconsistency means some lesson lists may not have a valid subject association.

**Fix:** Either make `subjectId` required (and fix all callers) or use `String?` to explicitly represent "unknown subject."

**Acceptance criteria:**
- `LessonListArgs` has no ambiguous default string values
- Topic→Lesson navigation passes subject ID where available

---

### m5. Hardcoded widths in exam_session_screen

**File:** `lib/features/practice/presentation/screens/exam_session_screen.dart`

**Issue:** `width: 80` (stats icon) and `width: 20` (divider) could overflow or look wrong on very small screens (<360dp).

**Fix:** Use responsive sizing or `ConstrainedBox` with `maxWidth` relative to available width.

**Acceptance criteria:**
- Exam session screen renders without overflow on 320dp width devices

---

### m6. EmptyDashboardChecklist duplicates EmptyStateWidget pattern

**File:** `lib/features/dashboard/presentation/widgets/empty_dashboard_checklist.dart`

**Issue:** This is a dashboard-specific empty state that duplicates the icon+text+action pattern already handled by `EmptyStateWidget` in `core/widgets/`.

**Fix:** Refactor to wrap `EmptyStateWidget` with dashboard-specific overrides.

**Acceptance criteria:**
- No duplicate empty-state implementations exist
- Dashboard checklist uses the shared `EmptyStateWidget`

---

### m7. OnboardingDialog overrides DialogTheme (20px vs 16px radius)

**File:** `lib/features/onboarding/presentation/onboarding_dialog.dart:46`

```dart
Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)))
```

**Issue:** The theme's `DialogTheme` sets `borderRadius: 16` for all dialogs. The onboarding dialog explicitly overrides to `20`, creating a 4px inconsistency.

**Fix:** Either remove the override (inherit 16px from theme) or add a comment justifying the intentional difference.

**Acceptance criteria:**
- All dialogs in the app use consistent border radius (either all 16 or all 20)

---

### m8. Redundant AppBar style overrides

**Files:**
- `lib/features/sessions/presentation/session_tracker_screen.dart:273-274,284-285,321-322`
- `lib/features/sessions/presentation/session_history_screen.dart:314`

**Issue:** These screens explicitly set `elevation: 0` and `centerTitle: false` on AppBars, even though the theme's `AppBarTheme` at `app_theme.dart:37-42` already defaults to these values.

**Fix:** Remove redundant overrides.

**Acceptance criteria:**
- No AppBar in the codebase explicitly sets values that match the theme defaults

---

### m9. No Hero animations for screen transitions

**Issue:** Zero `Hero` widgets exist in the codebase. Transitions between related screens (e.g., SubjectList → SubjectDetail, ContentLibrary → SourceDetail) could benefit from shared-element transitions to provide visual continuity.

**Fix:** Add `Hero` tags to shared content (subject avatars, source thumbnails) for contextual navigation.

**Acceptance criteria:**
- Navigation between list and detail screens uses shared-element transitions where contextually appropriate
- Respects `reduceMotion` / `disableAnimations` settings

---

### m10. SourceDetailScreen shows bare AppBar during loading

**File:** `lib/features/ingestion/presentation/source_detail_screen.dart:252`

```dart
Scaffold(appBar: AppBar(), body: const LoadingScreen())
```

**Issue:** During initial loading, the AppBar has no title, making the screen look incomplete. Other screens either include the title in the AppBar during loading or show a full-screen loading widget.

**Fix:** Add a title to the loading-state AppBar (use the source name if available, or a localized "Loading..." string).

**Acceptance criteria:**
- Loading state of SourceDetailScreen shows an AppBar with a contextual title

---

### m11. Chat streaming lacks initial "connecting" indicator (minor UX)

**File:** `lib/features/quickguide/presentation/quick_guide_screen.dart:111-119`

**Issue:** When sending a message, the streaming bubble appears empty until the first chunk arrives. On slow connections, there's a visible gap where the bubble is blank.

**Fix:** Add a pulsing cursor or "…" indicator to the empty bubble while waiting for the first chunk.

**Acceptance criteria:**
- The streaming chat bubble immediately shows a visual "thinking" indicator (pulsing dots or cursor) while awaiting the first LLM chunk

---

### m12. No `Semantics` on NavigationRail icons

**File:** `lib/main.dart:566-580`

**Issue:** NavigationRail and NavigationBar destinations have `Tooltip` around `Icon`, but no explicit `Semantics` wrapper. While `Tooltip` partially covers accessibility, an explicit `Semantics(label:)` would be more robust.

**Fix:** Wrap icons in `Semantics(label: d.tooltip, child: Icon(...))` instead of or in addition to `Tooltip`.

**Acceptance criteria:**
- TalkBack/VoiceOver announces the label for each nav destination icon
- No regressions in visual appearance

---

### m13. AppBars lack scrolled-under elevation on scrollable screens

**File:** `lib/core/theme/app_theme.dart:40`

**Issue:** The theme sets `scrolledUnderElevation: 0`, meaning when content scrolls behind the AppBar, no elevation shadow appears. This makes the AppBar blend into scrolled content, reducing the visual separation.

**Fix:** Consider setting `scrolledUnderElevation: 3` for better visual hierarchy on scrollable screens.

**Acceptance criteria:**
- Scrolling content behind the AppBar shows an elevation shadow
- NavigationRail label type consistency maintained

---

### m14. ProfileScreen uses `ElevatedButton` for avatar selection instead of `ChoiceChip` / grid

**File:** `lib/features/settings/presentation/profile_screen.dart:198-214`

**Issue:** The avatar picker renders avatar options as `ElevatedButton` widgets (with `styleFrom` padding adjusted to circular), which is a semantic misuse — buttons imply an action, not a selection. Better choices would be `ChoiceChip`, `FilterChip`, or a simple `GestureDetector` with selection styling.

**Fix:** Replace with `ChoiceChip` or `ActionChip` in a `Wrap` layout, with `selected` state controlling visual styling.

**Acceptance criteria:**
- Avatar options use a selection widget (chip, radio, or grid) rather than buttons
- Selected state is visually distinct from unselected
- Semantics `selected:` attribute is set correctly
