# UI/UX Master Audit

> Generated: 2026-05-20
> Scope: Full codebase exploration — navigation flows, missing states, design inconsistencies, accessibility, animations, raw data leaks, onboarding gaps, reusability candidates.

---

# BLOCKER

## B1. Focus Mode tab inaccessible on mobile bottom navigation

**Context:** In `lib/main.dart:301-303`, the `_buildDestinations` function strips the focus mode tab on narrow screens (`isWideScreen == false`). Focus Mode is reachable only via deep-link routes (`AppRoutes.focusMode`) or the Settings screen. A phone user with no knowledge of these routes has **no way** to navigate to Focus Mode from the persistent bottom nav.

**Affected files:**
- `lib/main.dart:262-303`

**Rationale:** Focus Mode is a marquee feature shown during onboarding (page 5) yet is hidden from the primary navigation on phones. New mobile users will wonder where it went.

**Acceptance criteria:**
- On mobile (xs/sm breakpoints), Focus Mode must appear in the bottom `NavigationBar`. Consider combining tabs or adding a "More" overflow if the bar is crowded. The current `where()` filter must be removed or replaced with a scrollable/overflow-based navigation that includes all tabs regardless of screen width.

---

## B2. `exportFailed('')` and `failedToDeleteSession('')` pass empty strings to parameterized l10n

**Context:** At `lib/features/sessions/presentation/session_history_screen.dart:183-184` and `:288-291`, the l10n methods `exportFailed('')` and `failedToDeleteSession('')` are called with empty string arguments. Users will see dangling punctuation like `"Export failed: "` or `"Failed to delete session: "`.

**Affected files:**
- `lib/features/sessions/presentation/session_history_screen.dart:183-184, 288-291`

**Rationale:** Silent UX failure — the error appears broken/incomplete to the user, eroding trust. The actual error details are logged but never surfaced.

**Acceptance criteria:**
- Capture the underlying error message (from `catch` blocks) and pass a meaningful, localized string to `exportFailed()` and `failedToDeleteSession()`. If no user-safe message is available, use a generic localized fallback like `l10n.somethingWentWrong`.

---

## B3. Mentor and Tutor screens pass empty strings to localized init-failure messages

**Context:** `lib/features/mentor/presentation/mentor_screen.dart:155` calls `l10n.mentorInitFailed('')` with an empty argument. `lib/features/teaching/presentation/tutor_screen.dart:168` calls `l10n.tutorInitFailed('')` with an empty argument. The user sees a message with missing context, e.g. `"Mentor initialization failed: "`.

**Affected files:**
- `lib/features/mentor/presentation/mentor_screen.dart:155`
- `lib/features/teaching/presentation/tutor_screen.dart:168`

**Rationale:** Same as B2 — truncated/meaningless error messages are user-hostile.

**Acceptance criteria:**
- Provide a meaningful localized message or a generic fallback. The `catch` blocks should extract a user-safe description or use `l10n.somethingWentWrong`.

---

# MAJOR

## M1. Dead navigation taps in dashboard NextUpCard (no subjects)

**Context:** `lib/features/dashboard/presentation/widgets/next_up_card.dart:101-103, 112-114` — When `firstSubjectId` is null (user has no subjects), the "Reviews Due" and "Weak Topics" tiles are wrapped in `GestureDetector(onTap: () {})` which is a no-op. The tiles render with interactive styling (ripple, cursor) but produce zero feedback when tapped.

**Affected files:**
- `lib/features/dashboard/presentation/widgets/next_up_card.dart:101-103, 112-114`

**Rationale:** Dead taps violate the principle of least surprise. Users expect feedback (a snackbar, a disabled appearance, or navigation to a helpful screen).

**Acceptance criteria:**
- When `firstSubjectId` is null, either disable the tiles visually (grey out, no hover effect) or make them navigate to `/subject-selection` to add a first subject. At minimum, show a snackbar explaining "Add a subject first".

---

## M2. Topic detail screen shows raw internal labels and hardcoded colours

**Context:** `lib/features/dashboard/presentation/screens/topic_detail_screen.dart` contains multiple non-localised hardcoded strings:
- Line 141: `'Mastery Level'`
- Line 152: `'Best Streak'`
- Lines 163-164: `'Confidence'`
- Lines 167-168: `'Forgetting Risk'`
- Lines 171-172: `'Review Urgency'`
- Line 177: `'Last Attempted'`
- Line 180: `'Last Updated'`
- Line 184: `'Accuracy Trend'`

Also hardcoded colour constants instead of theme colours:
- Lines 202-206 (`_accuracyColor`): `Color(0xFF4CAF50)`, `Color(0xFFFF9800)`, `Color(0xFFF44336)`
- Lines 208-219 (`_levelColor`): Same pattern, plus `Color(0xFF2196F3)`
- Lines 318, 328: sparkline painter uses `Color(0xFF4CAF50)` regardless of theme.

**Affected files:**
- `lib/features/dashboard/presentation/screens/topic_detail_screen.dart:141, 152, 163-172, 177, 180, 184, 202-219, 318, 328`

**Rationale:** Breaks i18n (labels are English-only) and theming (colours clash in dark mode/high-contrast mode). The `theme.progressColor` / `AppTheme.masteryColor` utilities already exist but are unused here.

**Acceptance criteria:**
- Replace all hardcoded label strings with `l10n.*` calls.
- Replace hardcoded colour constants with `Theme.of(context).colorScheme.*` or the existing `AppTheme.masteryColor` / `AppTheme.progressColor` helpers.
- The `_DetailSparklinePainter` should accept a theme-aware colour.

---

## M3. Practice screen shows unlocalised raw English strings in error/snackbar messages

**Context:** `lib/features/practice/presentation/screens/practice_screen.dart` has several hardcoded English error messages:
- Lines 366-367: `'${subject.name}: Need at least $minAttempts attempted questions (30% of this subject) to identify weak areas'`
- Lines 380-381: `'Need at least $minAttempts attempted questions (30% of this subject). ...'`

**Affected files:**
- `lib/features/practice/presentation/screens/practice_screen.dart:366-367, 380-381`

**Rationale:** These messages are shown directly in `SnackBar`s to users. They are not localised, contain technical threshold values (`30%`, `minAttempts`), and expose implementation details.

**Acceptance criteria:**
- Create localised l10n messages for these scenarios (e.g. `l10n.insufficientAttemptsForWeakAreas(subjectName, minAttempts)`).
- Use `formatPercent` for any displayed percentage values.

---

## M4. Planner screen shows unlocalised/raw provider errors in snackbar

**Context:** `lib/features/planner/presentation/planner_screen.dart:439` — `SnackBar(content: Text(next.error!))`. The `error` field from `PlannerState` may contain unlocalised exception messages, raw error codes, or internal identifiers.

**Affected files:**
- `lib/features/planner/presentation/planner_screen.dart:439`

**Rationale:** Users see technical error text. The provider should already produce user-friendly strings; if not, the screen must sanitise before display.

**Acceptance criteria:**
- Ensure `PlannerState.error` is always a user-facing, localised string. Add a defence at the UI layer: if the raw error appears unlocalised, fall back to `l10n.somethingWentWrong`.

---

## M5. Session history screen has fragile colour fallback chain

**Context:** `lib/features/sessions/presentation/session_history_screen.dart:472-477` — Colour chain `theme.textTheme.bodyMedium?.color ?? theme.textTheme.bodySmall?.color`. Both `TextStyle.color` properties can return `null` (inherited colour), producing `null` as the actual text colour.

**Affected files:**
- `lib/features/sessions/presentation/session_history_screen.dart:472-477`

**Rationale:** A `null` colour causes invisible text in some widget configurations. This is a correctness issue.

**Acceptance criteria:**
- Use `theme.colorScheme.onSurface` as the ultimate fallback after the TextStyle chain.

---

## M6. No loading indicator on Planner screen during initial data fetch

**Context:** `lib/features/planner/presentation/planner_screen.dart:476` (`_buildStudyPlanTab`) renders the plan form eagerly without a loading state. The plan data arrives asynchronously, causing a layout flash when it appears.

**Affected files:**
- `lib/features/planner/presentation/planner_screen.dart:476-648` (entire `_buildStudyPlanTab`)

**Rationale:** Users see an empty form that suddenly fills with data. No visual feedback during network/LLM plan generation.

**Acceptance criteria:**
- Add an initial loading state (shimmer or `LoadingScreen`) that shows while `state.isLoading` is true and no plan exists yet. The existing `state.isGenerating` should also show a progress indicator overlaid on the form.

---

## M7. Dashboard loads 11 separate async providers causing cascading rebuilds

**Context:** `lib/features/dashboard/presentation/dashboard_screen.dart:70-87` watches 11 individual providers independently. Each `AsyncValue` triggers a separate rebuild. On a slow data layer (Hive), these cascade and cause noticeable layout flicker.

**Affected files:**
- `lib/features/dashboard/presentation/dashboard_screen.dart:70-87`

**Rationale:** Performance — the dashboard is the entry point and needs to feel snappy. A single aggregated provider would batch-load and emit once.

**Acceptance criteria:**
- Create a single `dashboardDataProvider` that bundles all dashboard data and emits one combined snapshot. The screen should watch only this provider and destructure once.

---

## M8. Settings "AI Tasks" tile shows same subtitle for both empty and active states

**Context:** `lib/features/settings/presentation/settings_screen.dart:1972-1974` — The `_AiTaskMonitorTile` always shows `l10n.viewActiveAiTasks` as subtitle regardless of whether there are any active tasks. A user with zero tasks sees a misleading invitation.

**Affected files:**
- `lib/features/settings/presentation/settings_screen.dart:1972-1974`

**Rationale:** Misleading UX — "View active AI tasks" implies there is something to view.

**Acceptance criteria:**
- If there are zero active tasks, display a different subtitle: `l10n.noActiveAiTasks` or `l10n.noTasksQueued`.

---

## M9. Raw feature key leaked in Settings `_featureLabel` default case

**Context:** `lib/features/settings/presentation/settings_screen.dart:1652-1653` — The default case of `_featureLabel` returns the raw key string (e.g. `"ocr_extraction"`, `"question_generation"`) as the display label.

**Affected files:**
- `lib/features/settings/presentation/settings_screen.dart:1652-1653`

**Rationale:** Internal identifiers leak to users. If a new LLM feature is registered without updating this switch, the user sees a snake_case key.

**Acceptance criteria:**
- The default case should return a localised fallback: `l10n.unknown`.

---

## M10. Planner Calendar tab empty state has no call-to-action

**Context:** `lib/features/planner/presentation/planner_screen.dart:1374-1387` — When `state.plan == null`, the calendar tab shows an icon and `"No study plan yet"` but no button to create one. The user must manually switch to the first tab.

**Affected files:**
- `lib/features/planner/presentation/planner_screen.dart:1374-1387`

**Rationale:** The natural response to "No study plan yet" is "How do I create one?" but there is no affordance.

**Acceptance criteria:**
- Add a `FilledButton` in the empty state: `l10n.createStudyPlan`. Tapping it should switch `_tabController` to index 0.

---

## M11. Workload card empty state has no action button

**Context:** `lib/features/dashboard/presentation/widgets/workload_card.dart:19-31` — Empty state shows `l10n.noTopicsYetAddSome` but offers no actionable button to add topics.

**Affected files:**
- `lib/features/dashboard/presentation/widgets/workload_card.dart:19-31`

**Rationale:** UX friction — the user reads the message but must manually navigate elsewhere to act.

**Acceptance criteria:**
- Add a `TextButton` or `FilledButton`: `l10n.uploadMaterials` or `l10n.addTopic`, navigating to `/upload` or `/subject-selection`.

---

# MINOR

## m1. Onboarding "don't show again" error silently converts to "completed"

**Context:** `lib/features/onboarding/presentation/onboarding_dialog.dart:38-41` — In `_completeOnboarding`, if `markDontShowAgain()` throws, the catch block calls `markCompleted()`. A user who checked "Don't show again" may see the onboarding again (or not) without understanding why.

**Affected files:**
- `lib/features/onboarding/presentation/onboarding_dialog.dart:38-41`

**Rationale:** Silent state corruption — user intent ("never show again") is silently downgraded to "mark as completed (but may show again under certain conditions)".

**Acceptance criteria:**
- If `markDontShowAgain()` fails, log the error and let onboarding replay next time rather than marking completed. Or retry `markDontShowAgain()` once.

---

## m2. ConversationInput has redundant Ctrl+Enter shortcut

**Context:** `lib/core/widgets/conversation_input.dart:56` — `Ctrl+Enter` bound via `CallbackShortcuts`. However, the `TextField.onSubmitted` callback at line 121 also triggers send on plain `Enter`. Both `Enter` and `Ctrl+Enter` do the same thing, making the Ctrl modifier redundant and confusing.

**Affected files:**
- `lib/core/widgets/conversation_input.dart:56, 121`

**Rationale:** Users expect Ctrl+Enter for "newline without sending" and Enter for "send", or vice versa. Having both do the same thing wastes a useful shortcut.

**Acceptance criteria:**
- Change so that plain `Enter` sends (as it does now) and `Shift+Enter` inserts a newline. Remove the `Ctrl+Enter` binding or re-purpose it for an alternate action.

---

## m3. ShimmerWidget has hardcoded English fallback string

**Context:** `lib/core/widgets/shimmer_widget.dart:65` — `l10n?.loading ?? 'Loading'`. The English string `'Loading'` is the fallback when l10n is null.

**Affected files:**
- `lib/core/widgets/shimmer_widget.dart:65`

**Rationale:** Minor — violates the convention in AGENTS.md against hardcoded strings.

**Acceptance criteria:**
- Remove the hardcoded fallback. Use an empty string or `'…'` as the final fallback.

---

## m4. Badges card empty state lacks actionable guidance

**Context:** `lib/features/dashboard/presentation/widgets/badges_card.dart:13-24` — Empty state shows only `"No badges yet"` text with no hint about how badges are earned.

**Affected files:**
- `lib/features/dashboard/presentation/widgets/badges_card.dart:13-24`

**Rationale:** Users don't know what actions lead to badges (e.g. practice streaks, completing sessions).

**Acceptance criteria:**
- Add a subtitle: `l10n.badgesEarnedByPracticing` or similar.

---

## m5. `topic_breakdown_card.dart` falls back to raw enum name when l10n is null

**Context:** `lib/features/dashboard/presentation/widgets/topic_breakdown_card.dart:190` — `if (l10n == null) return level.name;` emits internal identifiers like `"novice"`, `"browsing"` as user-facing text.

**Affected files:**
- `lib/features/dashboard/presentation/widgets/topic_breakdown_card.dart:190`

**Rationale:** Raw data leak. Should use a user-friendly English fallback.

**Acceptance criteria:**
- Provide a static mapping from `MasteryLevel` to user-friendly strings when l10n is unavailable.

---

## m6. Lesson detail screen has redundant null coalescing

**Context:** `lib/features/lessons/presentation/lesson_detail_screen.dart:91-95` — `(widget.args.subjectId ?? '').isNotEmpty ? (widget.args.subjectId ?? '') : _lesson?.subjectId ?? ''`. The `(widget.args.subjectId ?? '')` is evaluated twice.

**Affected files:**
- `lib/features/lessons/presentation/lesson_detail_screen.dart:91-95`

**Rationale:** Code quality — redundant null checks produce unnecessary noise.

**Acceptance criteria:**
- Extract `widget.args.subjectId` to a local variable and null-coalesce once.

---

## m7. Session tracker silent failure when subjects fail to load

**Context:** `lib/features/sessions/presentation/session_tracker_screen.dart:77-78` — The `catch` block only logs the error. The subject dropdown simply disappears with no user feedback.

**Affected files:**
- `lib/features/sessions/presentation/session_tracker_screen.dart:77-78`

**Rationale:** The user is left wondering why the subject field is missing.

**Acceptance criteria:**
- Show an inline error or snackbar: `l10n.failedToLoadSubjects`. Include a retry action.

---

## m8. `SessionHistoryScreen.exportCsv` uses deprecated theme API

**Context:** `lib/features/sessions/presentation/session_history_screen.dart:331, 337, 340, 354` — Uses `theme.primaryColor` (Material 2) instead of `theme.colorScheme.primary`.

**Affected files:**
- `lib/features/sessions/presentation/session_history_screen.dart:331, 337, 340, 354`

**Rationale:** Deprecated API will produce warnings and may behave incorrectly in Material 3 modes.

**Acceptance criteria:**
- Replace `theme.primaryColor` with `theme.colorScheme.primary`.

---

## m9. `CollapsibleCard` duplicates expand/collapse semantics on both the title and the icon

**Context:** `lib/features/dashboard/presentation/widgets/collapsible_card.dart:84-108` — Both the title `InkWell` (lines 90-93) and the `IconButton` (lines 97-108) dispatch the same `toggleCollapsed` action. Both have `Semantics` with `button: true`. TalkBack/VoiceOver users encounter two adjacent controls that do the same thing.

**Affected files:**
- `lib/features/dashboard/presentation/widgets/collapsible_card.dart:84-108`

**Rationale:** Accessibility — redundant controls clutter the accessibility tree.

**Acceptance criteria:**
- Make only the title `InkWell` the primary toggle. Give the icon `Semantics(explicitChildNodes: true, child: Icon(...))` with `label: ''` so it is skipped by screen readers.

---

## m10. Two different colour-coding patterns for progress/mastery across the app

**Context:** 
- `lib/core/theme/app_theme.dart:245-264` defines `progressColor`, `masteryColor` using theme-aware colour scheme.
- `lib/features/dashboard/presentation/screens/topic_detail_screen.dart:202-219` defines `_accuracyColor`, `_levelColor` using hardcoded hex colours.
- `lib/features/dashboard/presentation/widgets/topic_breakdown_card.dart` uses the theme utility.
- `lib/features/practice/presentation/screens/practice_screen.dart:920-931` uses `theme.colorScheme.error/tertiary/primary` directly.

**Affected files:**
- `lib/core/theme/app_theme.dart:245-264`
- `lib/features/dashboard/presentation/screens/topic_detail_screen.dart:202-219`
- `lib/features/practice/presentation/screens/practice_screen.dart:920-931`

**Rationale:** Design inconsistency — three different approaches to colouring progress/mastery. The same data (mastery level) should use the same colour palette everywhere.

**Acceptance criteria:**
- Define a single source of truth for mastery/progress colour coding in `AppTheme` (already exists as `masteryColor`, `progressColor`, `priorityColor`). Refactor all call sites to use these static methods.

---

## m11. Chat message rendering re-parses JSON on every build

**Context:** `lib/features/teaching/presentation/widgets/chat_bubble.dart:152-159` — Every build of every chat bubble calls `jsonDecode(message.content)` inside `_isEvaluationMessage` to check for evaluation-type messages. This is O(n) string parsing for each bubble in a list.

**Affected files:**
- `lib/features/teaching/presentation/widgets/chat_bubble.dart:152-159`

**Rationale:** Performance jank on long chat histories. The message model should carry a typed flag instead.

**Acceptance criteria:**
- Add a boolean field `isEvaluation` to `ConversationMessage` (or `ChatMessageData`) so parsing is done once at message creation time, not on every build.

---

## m12. Focus mode onboarding shows only once; dismissed users get no guidance

**Context:** `lib/features/focus_mode/presentation/focus_timer_screen.dart:121-128` — The `_showOnboarding` flag is set only on the very first visit (`settings.firstFocusVisit`). If the user dismisses it (or the screen closes before they read it), there is no persistent help, tooltip, or "?" icon to re-trigger guidance.

**Affected files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:121-128`

**Rationale:** First-launch guidance that can never be revisited is a UX gap. Users who skip or miss it lose access to help.

**Acceptance criteria:**
- Add a persistent help icon (e.g. `Icons.help_outline`) in the app bar that re-shows the focus mode onboarding content in a bottom sheet or dialog.

---

# Summary

| Severity | Count |
|----------|-------|
| BLOCKER | 3 |
| MAJOR | 11 |
| MINOR | 12 |
| **Total** | **26** |
