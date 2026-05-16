# UI/UX Master Issue

**Issues identified across the codebase — accessibility, responsive layout, animation, sizing, navigation, and design consistency.**

---

## 1. [A11Y-CRITICAL] Screen reader context lost in `AlertDialog` & raw dialogs

**Affected files:**

- `lib/features/quickguide/presentation/widgets/help_dialog.dart:8-18`
- `lib/features/planner/presentation/planner_screen.dart:131-180`
- `lib/features/mentor/presentation/mentor_screen.dart:337-357`

**Problem:** Several `AlertDialog` calls pass no `semanticLabel`, and the wrapping context has no `Semantics` node. `showQuickGuideHelpDialog` is a bare top-level function—screen readers announce the dialog content fields in flat order without recognizing it as a dialog landmark.

**Acceptance Criteria:**

- Every `AlertDialog` must receive `semanticLabel` or be wrapped in `Semantics(dialog: true, ...)`.
- `showQuickGuideHelpDialog` should be refactored into a widget so Semantics can be attached at the Scaffold/dialog level.

---

## 2. [A11Y] `GestureDetector`-based interactive elements are not keyboard-focusable

**Affected files:**

- `lib/features/practice/presentation/practice_session_screen.dart:478-508`
- `lib/features/practice/presentation/widgets/practice_mode_card.dart:33`

**Problem:** The confidence-selector circles and the practice-mode cards use `GestureDetector` with only `onTap`. These elements cannot receive keyboard focus, cannot be activated via Space/Enter, and are not announced as buttons by screen readers. Users relying on switch devices or keyboard-only navigation cannot interact with them.

**Acceptance Criteria:**

- Replace `GestureDetector` + `onTap` with `InkWell`/`TextButton`/`Semantics(button: true)` for interactive elements.
- Each confidence rating circle should be a `FocusableActionDetector` or `InkWell` with appropriate accessibility roles.
- Verify focus order with Tab key navigation on the practice session screen.

---

## 3. [A11Y] Typography below minimum legible size

**Affected files:**

- `lib/features/planner/presentation/widgets/milestone_timeline.dart:86-91` — fontSize 9 for milestone labels
- `lib/features/planner/presentation/widgets/calendar_view_widget.dart:168-171` — fontSize 8 for minute counts
- `lib/features/teaching/presentation/tutor_screen.dart:216-219` — fontSize 11 for stat chips
- `lib/features/practice/presentation/widgets/practice_feedback_widget.dart:43-45` — hardcoded fontSize 18

**Problem:** Font sizes of 8–11 sp fall below WCAG AA minimum thresholds. `fontSize: 8` and `fontSize: 9` are practically illegible on many devices and cannot be scaled by system font settings. The hardcoded `fontSize: 18` in `practice_feedback_widget.dart` bypasses the user's system text scale.

**Acceptance Criteria:**

- No hardcoded `fontSize` below 12 sp in text `TextStyle` declarations.
- Use theme text styles (e.g., `labelSmall`, `bodySmall`) which respect `MediaQuery.textScaler`.
- Remove hardcoded `fontSize: 18` in `PracticeFeedbackWidget` — use `titleMedium` or `titleLarge` instead.

---

## 4. [RESPONSIVE] 4-item GridView creates uneven layout on sm breakpoint

**Affected file:** `lib/features/practice/presentation/widgets/practice_mode_grid.dart:39-80`

**Problem:** `gridCrossAxisCount` returns 3 for sm breakpoint (601–840 px), but there are exactly 4 grid children. This produces a 3+1 split row layout with one isolated card on the second row. Visual asymmetry causes confusion about which mode is "extra."

**Acceptance Criteria:**

- At sm breakpoint, either force 2 columns or re-flow to a 2+2 grid.
- Alternatively, limit visible cards and group the fourth under a "more" expander.

---

## 5. [ANIMATION] Question-card `AnimatedSwitcher` lacks directional cue

**Affected file:** `lib/features/practice/presentation/practice_session_screen.dart:438-447`

**Problem:** Only `FadeTransition` is used when switching between questions. Users have no spatial feedback about whether they moved forward or backward — especially critical on mobile where swipe gestures suggest left-right motion.

**Acceptance Criteria:**

- Add a horizontal `SlideTransition` (offset from right for "next", from left for "previous") combined with the existing fade.
- Respect `reduceMotion` setting: fall back to instantaneous swap when animations are disabled.
- Verify with `NavigatorObserver` that the transition doesn't interfere with accessibility focus placement.

---

## 6. [ANIMATION] Focus timer pulse animation risks vestibular issues

**Affected file:** `lib/features/focus_mode/presentation/widgets/focus_timer_widget.dart:111-122`

**Problem:** The entire timer circle pulses at ±3% scale continuously via `_pulseController.repeat(reverse: true)`. While `reduceMotion` and `MediaQuery.disableAnimationsOf` are checked, the default experience creates continuous motion in the user's peripheral awareness zone — this can trigger discomfort for users with vestibular or seizure disorders.

**Acceptance Criteria:**

- Replace full-circle pulse with a more subtle approach (e.g., a gentle color shift on the progress ring, or a small "breathing" ring overlay).
- Ensure pulse amplitude is reduced from 3% to ≤1% if kept.
- Verify `reduceMotion` branch works as expected and produces a fully static timer.

---

## 7. [DESIGN LANGUAGE] Inconsistent border radii across interactive surfaces

**Affected file:** `lib/core/theme/app_theme.dart`

| Element | Radius | Location |
|---|---|---|
| `CardTheme` | `12` | line 44 |
| `ElevatedButton` | `8` | line 53 |
| `FloatingActionButton` | `16` | line 73 |
| `InputDecoration` (border) | `4` (default `OutlineInputBorder`) | — |
| `BottomSheet` shape | varies inline | multiple files |

**Problem:** Four different corner radii for primary interactive surfaces create visual dissonance. The bottom sheet radius is defined inline per-file (20 in `MistakeReviewWidget`, 20 in `SourcePracticeSheet`, via `bottomSheetShape` in `PracticeModeSheet`) instead of centralized.

**Acceptance Criteria:**

- Standardize to 2–3 distinct radii (e.g., 8 for buttons, 12 for cards, 16 for sheets/FABs).
- Extract bottom sheet shape into `AppTheme` as a static getter used by all bottom sheet calls.
- Verify no broken golden tests or visual regressions.

---

## 8. [NAVIGATION] Dashboard "collapsible card" affordance is too subtle

**Affected file:** `lib/features/dashboard/presentation/widgets/collapsible_card.dart:72-91`

**Problem:** The only visual cue that a card can be collapsed/expanded is a chevron (`expand_more`/`expand_less`) icon. Users do not know the entire card header is tappable. Combined with 7+ cards in a single scroll, the page feels like an endless list of equally-weighted sections.

**Acceptance Criteria:**

- Add a visible "Tap to collapse" tooltip or label.
- Consider an `AnimatedCrossFade` between collapsed and expanded states for better feedback.
- Prioritize the first 3–4 cards by default and collapse the rest, or add a "Show more" button.

---

## 9. [A11Y] Chat evaluation score lacks screen-reader detail

**Affected file:** `lib/features/teaching/presentation/widgets/chat_bubble.dart:153-171`

**Problem:** The `Semantics` label for evaluation feedback is just `'Correct'`, `'Incorrect'`, or `'Partial'` — the actual percentage score (e.g., "85 percent") is rendered visually via `Text` inside an `ExcludeSemantics` area. A screen reader user only hears "Correct" without knowing the actual score.

**Acceptance Criteria:**

- The `Semantics` label should include the numeric score, e.g., `"Correct, 85 percent"`.
- Avoid `ExcludeSemantics` on the score text; or merge label + `Text` into one `Semantics` node with merge semantics.

---

## 10. [RESPONSIVE] `ConversationInput` keyboard-return as only send action, no hint

**Affected file:** `lib/core/widgets/conversation_input.dart:42-48` and `111`

**Problem:** The `TextField` uses `textInputAction: TextInputAction.send` (line 80) which maps the "return" key on software keyboards to "Send." However: (a) `onSubmitted` only fires when the send key is pressed; (b) there is no visual hint in the UI that `Ctrl+Enter` (via `CallbackShortcuts`) is an alternative; (c) if the keyboard lacks a dedicated send key, users have no discoverable way to submit.

**Acceptance Criteria:**

- Show a visible hint line under the input field or inside the hint text: e.g., "Press Enter to send, Ctrl+Enter for new line."
- The `onSubmitted` callback should handle multi-line input gracefully (e.g., submit only if the text ends with a period/question mark and the keyboard send key was pressed).
- Ensure the `CallbackShortcuts` is properly scoped so it doesn't interfere with other keyboard shortcuts on the same screen.

---

## 11. [SIZING] PracticeSessionNavButtons layout shift on first/last question

**Affected file:** `lib/features/practice/presentation/widgets/practice_session_nav_buttons.dart:20-50`

**Problem:** On xs screens, `onPrevious` being null for the first question removes the entire "Previous" button row, causing the "Next" button to shift upward. This creates a jarring re-layout every time the user hits the first question.

**Acceptance Criteria:**

- Reserve consistent height for navigation buttons regardless of whether "Previous" is shown.
- Show "Previous" as disabled rather than absent on the first question, OR keep a fixed spacer that maintains the same layout height.

---

## 12. [DESIGN SYSTEM] No centralized bottom sheet shape — defined inline in 3+ files

**Affected files:**

- `lib/features/practice/presentation/widgets/mistake_review_widget.dart:27-29`
- `lib/features/practice/presentation/widgets/source_practice_sheet.dart:23-25`
- `lib/features/practice/presentation/widgets/practice_mode_sheet.dart:76` (references undefined `bottomSheetShape`)

**Problem:** `practice_mode_sheet.dart:76` references `bottomSheetShape` which is not imported or defined in the file (`BottomSheet shape: bottomSheetShape,`). This may compile only if an import from an intermediate barrel file resolves it, but it's not explicit — a refactoring risk.

**Acceptance Criteria:**

- Define `static const bottomSheetShape = RoundedRectangleBorder(...)` in `AppTheme`.
- All bottom sheet `show()` methods reference `AppTheme.bottomSheetShape`.
- Remove inline shape definitions from individual sheet files.

---

## Severity Summary

| # | Area | Severity | Effort |
|---|------|----------|--------|
| 1 | A11Y: Dialog context | Critical | Small |
| 2 | A11Y: Keyboard focus | Critical | Medium |
| 3 | A11Y: Font size | High | Small |
| 4 | Responsive: Grid | Medium | Small |
| 5 | Animation: Direction | Medium | Medium |
| 6 | Animation: Vestibular | High | Small |
| 7 | Design: Radius | Medium | Small |
| 8 | Navigation: Affordance | Low | Medium |
| 9 | A11Y: Score readout | High | Small |
| 10 | Input: Discoverability | Low | Small |
| 11 | Sizing: Layout shift | Medium | Small |
| 12 | Design: Bottom sheet | High | Trivial |

---

*All 12 issues are independent and can be tackled in any order. Start with #1, #2, #3, and #6 for the highest accessibility + safety impact.*
