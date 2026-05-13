# UI/UX: Fractured Navigation, Theming Inconsistency, and Responsive Fragmentation

## Summary

The app uses three competing navigation patterns, mixes deprecated theme APIs with hardcoded colors, and has a responsive layout system that is inconsistently applied — leading to confusing UX, poor screen reader output, broken animations, and jarring visual transitions.

## Context

After inspecting `lib/features/settings/presentation/`, `lib/features/practice/presentation/`, `lib/features/teaching/presentation/`, `lib/features/sessions/presentation/`, `lib/features/planner/presentation/`, `lib/core/widgets/`, `lib/core/theme/`, `lib/core/utils/`, and `lib/main.dart`, multiple compounding UI/UX issues emerged that affect every screen in the app.

---

## Issue 1: Three Competing Navigation Patterns (Critical)

**File:** `lib/main.dart:154-160`, `lib/features/settings/presentation/settings_screen.dart:41-46`, `lib/features/subjects/presentation/subject_list_view.dart:29-35`, `lib/features/practice/presentation/practice_screen.dart:100-108`, `lib/features/planner/presentation/planner_screen.dart:216-225`, `lib/features/teaching/presentation/tutor_screen.dart:216-225`

**Problem:**
- **Pattern A — Named routes in `main.dart`:** `/settings`, `/profile`, `/api-config`, `/quick-guide`, `/mentor`. Accessed via `Navigator.pushNamed(context, '/settings')`.
- **Pattern B — Direct `Navigator.push(MaterialPageRoute(...))`:** `SubjectListView`, `SubjectDetailScreen`, `PracticeScreen`, `PlannerScreen`, `SessionTrackerScreen`, `SessionHistoryScreen` all use this. Bypasses route definitions.
- **Pattern C — Mixed in same widget tree:** `PracticeScreen` uses `MaterialPageRoute` for practice sessions, but the `SettingsScreen` uses `pushNamed` for its sub-screens. `PlannerScreen` pushes `TutorScreen` directly with `MaterialPageRoute` but other navigation in the same screen uses the same pattern.

**Impact:** No centralized route management. Screen transition customization is impossible globally. Deep linking / direct URL navigation cannot be implemented. New developers are forced to guess which pattern to follow.

**Acceptance Criteria:**
- All screen transitions use a single navigation pattern (prefer named routes with `onGenerateRoute` for type safety)
- Deep linking is supported for all primary screens
- Transition animations are consistent across the app

---

## Issue 2: Pervasive Hardcoded Colors Instead of Theme System (High)

**Files:**
- `lib/features/settings/presentation/settings_screen.dart:327` — `Colors.green` for check icon
- `lib/features/settings/presentation/profile_screen.dart:108` — `Colors.green` for success snackbar; `line 522` — hardcoded red asterisk
- `lib/features/practice/presentation/analytics_dashboard.dart:114-118,127,136,139,144` — hardcoded `Colors.green`, `Colors.orange`, `Colors.red`, `Colors.blue`, `Colors.teal`, `Colors.purple`
- `lib/features/practice/presentation/learning_plan_dashboard.dart:210-216,229-231,392` — hardcoded `Colors.red`, `Colors.orange`, `Colors.green`, `Colors.grey.shade200`
- `lib/features/sessions/presentation/session_tracker_screen.dart:246-258` — hardcoded `Colors.green` and `Colors.red` for start/end buttons
- `lib/features/sessions/presentation/session_history_screen.dart:339` — hardcoded `Colors.green`, `Colors.orange`
- `lib/features/subjects/presentation/subject_list_view.dart:169-171` — hardcoded `Colors.grey.shade600`, `Colors.grey.shade500`
- `lib/features/practice/presentation/practice_screen.dart:882,894` — hardcoded `Colors.green.shade400`, `Colors.grey.shade600`
- `lib/features/practice/presentation/practice_session_screen.dart:669` — hardcoded `TextStyle(fontSize: 24)` bypassing text theme

**Problem:** Hardcoded color values break dark mode, high-contrast mode, and system accessibility settings. When the user enables `highContrastEnabled`, most of these hardcoded colors do not adjust. The `AppTheme` already provides a color scheme — these should be using `Theme.of(context).colorScheme.*` tokens consistently.

**Acceptance Criteria:**
- Zero hardcoded `Colors.*` values in presentation layer widgets
- All indicators (correct/incorrect, urgency, priority) use `colorScheme` tokens
- Success/error states use `colorScheme.primary`/`colorScheme.error`
- The `_getProgressColor()` pattern (duplicated in `analytics_dashboard.dart:627` and `learning_plan_dashboard.dart:423`) is extracted to a shared utility
- The results screen in `practice_session_screen.dart` uses `Theme.of(context).textTheme.headlineMedium` instead of `const TextStyle(fontSize: 24)`

---

## Issue 3: Non-Functional Typing Animation in ChatBubble (Medium)

**File:** `lib/features/teaching/presentation/widgets/chat_bubble.dart:121-135`

**Problem:** The `_dot` method creates `AnimatedOpacity` widgets with `opacity: 1.0` and no state change. The `duration` field is set but the opacity value never transitions. The result is three static dots that look like a rendering glitch rather than a typing indicator. The intended animated "thinking" dots for AI streaming responses do not work.

**Acceptance Criteria:**
- A working animated typing indicator with staggered opacity/scale animation on the three dots
- The animation only plays while `message.isStreaming` is true
- Dots settle to a static state when streaming completes

---

## Issue 4: Dialog UX and Keyboard Navigation Issues (Medium)

**Files:**
- `lib/features/settings/presentation/settings_screen.dart:267-293` — `_showAiModelSelection`: Shows a full-screen `CircularProgressIndicator` dialog with `barrierDismissible: false`, then immediately tries to `Navigator.pop` it. If the API returns fast enough, the dialog may not have rendered yet, causing an unpopable frozen loading state.
- `lib/features/sessions/presentation/session_tracker_screen.dart:387-454` — `_SessionEndDialog`: Uses `ElevatedButton` for "Save" instead of `FilledButton` (inconsistent with other dialogs in the app like `settings_screen.dart:375` and `profile_screen.dart:485` which use `FilledButton`)
- `lib/main.dart:133-145` — Escape key closes dialogs, but this is not announced to screen readers and doesn't work for `showModalBottomSheet` (which uses `DraggableScrollableSheet` internally and consume the escape key differently)
- `lib/features/settings/presentation/settings_screen.dart:151-161` — Every `_tile` and switch tile is wrapped in `Semantics(label: ...)` but `ListTile`/`SwitchListTile` already generates semantic nodes from `title`. This creates duplicate screen reader announcements.

**Acceptance Criteria:**
- Loading indicator dialog has a timeout fallback or uses an inline loading state instead
- All dialog buttons use a consistent style (`FilledButton` for primary action, `TextButton` for secondary)
- Escape key handler also dismisses bottom sheets
- Accessibility semantics do not produce duplicate announcements — `Semantics` wrapper is removed where `ListTile`/`SwitchListTile` automatically provides it, or `excludeSemantics: true` is used on inner nodes

---

## Issue 5: Fragmented Responsive Layout System (Medium)

**Files:**
- `lib/core/utils/responsive.dart:73-84` — `gridCrossAxisCount` returns `double` but `GridView.count(crossAxisCount:)` expects `int`. Requires `.toInt()` at every call site, which is easy to forget.
- `lib/features/practice/presentation/practice_screen.dart:227` — `childAspectRatio: 1.2 / MediaQuery.textScalerOf(context).scale(1.0)` can produce values < 0.3 on large font scales, causing layout overflow
- `lib/features/planner/presentation/planner_screen.dart:256` — Uses a hardcoded 400px breakpoint instead of the existing `ScreenBreakpoint` enum
- `lib/features/sessions/presentation/session_history_screen.dart:182,200` — Uses `MediaQuery.sizeOf(context).width > 400` as inline breakpoint instead of `ResponsiveUtils.breakpointOf(context)`

**Impact:** Widget layouts degrade unpredictably on tablets and accessibility font sizes. The `ScreenBreakpoint` system is designed for this but is pervasively bypassed.

**Acceptance Criteria:**
- `gridCrossAxisCount` returns `int` (not `double`)
- All inline breakpoints (`width > 400`) replaced with `ResponsiveUtils.breakpointOf()`
- Practice mode cards have a min-width or use `LayoutBuilder` to prevent overflow at large font scales

---

## Issue 6: `AnimatedBarChart` Re-Animates on Every Rebuild (Low-Medium)

**File:** `lib/core/widgets/animated_bar_chart.dart:48-65`

**Problem:** `TweenAnimationBuilder` is created fresh each `build` with `begin: 0`. This causes the bars to re-animate from zero every time the parent widget rebuilds (e.g., on pull-to-refresh, or when any parent state changes). The animation should only play once on initial mount, or use a stable target value.

**Acceptance Criteria:**
- Bars animate in once on initial load
- Subsequent rebuilds do not replay the animation from zero
- Alternatively, convert to a stateful widget that tracks whether the initial animation has played

---

## Issue 7: Single Subject Card Layout Shifts When Subjects Change (Low)

**File:** `lib/features/practice/presentation/practice_screen.dart:271-344`

**Problem:** `_buildSubjectSection` returns `_buildSingleSubjectCard` when there is exactly 1 subject, and `_buildSubjectPracticeCard` for each subject when there are 2+. The two card variants have different visual designs (different icon containers, different metadata). If a user has 1 subject and adds another, the card they were familiar with changes appearance — a jarring layout shift.

**Acceptance Criteria:**
- Subject cards use the same visual design regardless of count
- The "single subject" special case only affects spacing/layout, not card structure

---

## Files Affected

| File | Issues |
|------|--------|
| `lib/main.dart` | 1 (mixed navigation), 4 (escape key) |
| `lib/features/settings/presentation/settings_screen.dart` | 1, 2, 4 |
| `lib/features/settings/presentation/profile_screen.dart` | 2 |
| `lib/features/practice/presentation/analytics_dashboard.dart` | 2 |
| `lib/features/practice/presentation/learning_plan_dashboard.dart` | 2 |
| `lib/features/practice/presentation/practice_screen.dart` | 2, 5, 7 |
| `lib/features/practice/presentation/practice_session_screen.dart` | 2 |
| `lib/features/sessions/presentation/session_tracker_screen.dart` | 2, 4 |
| `lib/features/sessions/presentation/session_history_screen.dart` | 2, 5 |
| `lib/features/subjects/presentation/subject_list_view.dart` | 2 |
| `lib/features/teaching/presentation/widgets/chat_bubble.dart` | 3 |
| `lib/features/planner/presentation/planner_screen.dart` | 1, 5 |
| `lib/core/widgets/animated_bar_chart.dart` | 6 |
| `lib/core/utils/responsive.dart` | 5 |

## Rationale for Grouping

These issues are grouped because they all stem from a common root cause: the presentation layer grew without a unified design system contract. Navigation patterns diverged, theming was done ad-hoc, and responsive utilities were treated as optional. Fixing them in isolation would risk further fragmentation — they need a coordinated pass.

## Acceptance Criteria (Overall)

1. All screens use named routes with `onGenerateRoute` for type-safe navigation
2. Zero hardcoded `Colors.*` — every color comes from `Theme.of(context).colorScheme`
3. The typing indicator in `ChatBubble` actually animates when streaming
4. Dialog buttons use consistent `FilledButton`/`TextButton` pattern throughout
5. Screen reader output has no duplicate announcements from nested `Semantics` wrapping semantic widgets
6. Every screen adapts layout using the existing `ScreenBreakpoint` system (no inline `width > 400`)
7. `AnimatedBarChart` does not replay its intro animation on rebuild
8. Subject cards in `PracticeScreen` use the same visual design regardless of count
