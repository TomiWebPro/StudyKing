# UI/UX Audit: Accessibility, Animation, and Locale-Formatting Fragmentation

## Context

A systematic audit of the StudyKing UI surface reveals three cross-cutting problems that degrade the experience for real users — especially screen-reader users, motion-sensitive users, dark-mode users, and Spanish/French/German locale users. None of these are surface-level bugs; each reflects a missing architectural pattern or convention.

---

## Problem 1: Pervasive Missing & Redundant Semantic Accessibility

### Rationale
Screen-reader users cannot effectively use the app because:
- Dynamic content (streaming tutor replies, countdown timers, session elapsed time) is never wrapped in `Semantics(liveRegion: true)`, so updates are never announced.
- ~20 interactive elements (icon buttons, chip groups, tappable cards) lack `Semantics(button: true)` or meaningful labels.
- ~5 `ElevatedButton`/`FilledButton` widgets are *doubly wrapped* in `Semantics(button: true, label: ...)` when Flutter's material buttons already expose correct semantics, causing double-announcement noise.
- Color-only feedback (green check / red X in evaluation bubbles, practice feedback widgets) has no text alternative.

### Affected Files (representative sample)

| File | Line(s) | Issue |
|---|---|---|
| `lib/features/teaching/presentation/widgets/chat_bubble.dart` | 99–118 | No `liveRegion: true` on streaming text |
| `lib/features/mentor/presentation/mentor_screen.dart` | 124–137 | No `liveRegion` on streaming mentor replies |
| `lib/features/focus_mode/presentation/widgets/focus_timer_widget.dart` | 100–214 | Timer value not exposed as live region; buttons lack `Semantics(button: true)` |
| `lib/features/sessions/presentation/widgets/session_analytics.dart` | 96–141 | `MetricCard` uses color-only indicators; no semantic grouping |
| `lib/features/practice/presentation/widgets/practice_session_stats_bar.dart` | 50–61 | Double-semantics wrapping on each mini-stat |
| `lib/features/practice/presentation/widgets/practice_session_question_card.dart` | 30–52 | `TextField` has no semantic label for screen readers |
| `lib/features/practice/presentation/widgets/practice_mode_card.dart` | 26, 71–90 | Badge count not included in `Semantics` label; disabled state not conveyed |
| `lib/features/practice/presentation/widgets/practice_feedback_widget.dart` | 16–56 | Feedback not in `liveRegion` |
| `lib/features/practice/presentation/widgets/practice_mode_option.dart` | 58–62 | Trailing arrow not semantically grouped |
| `lib/features/subjects/presentation/topic_list_screen.dart` | 73–74 | Chevron icon + `onTap` have no semantic label |
| `lib/features/sessions/presentation/session_tracker_screen.dart` | 256–308 | Timer not live; start/end buttons lack explicit semantics |
| `lib/features/sessions/presentation/session_history_screen.dart` | 267–326 | `PopupMenuButton` double-wrapped in `Semantics` |
| `lib/features/questions/presentation/widgets/question_card_widget.dart` | 147–187 | Submit/Next buttons double-wrapped in `Semantics(button: true)` |

---

## Problem 2: Incomplete Reduced-Motion Support & Problematic Animation Patterns

### Rationale
The app exposes a `SettingsBox.reduceMotion` toggle and **does** check it in a few places, but the following animations are **not** gated by it — meaning motion-sensitive users who opt in get no benefit:

- **Focus timer pulse** (`lib/features/focus_mode/presentation/widgets/focus_timer_widget.dart:108–116`): Continuous 1.0→1.03 scale animation during active sessions. Checks `MediaQuery.disableAnimationsOf(context)` but **not** the app's own `reduceMotion` setting. Users who turn on "Reduce Motion" in-app will still see pulsing.
- **Voice bar waveform** (`lib/features/teaching/presentation/widgets/voice_bar.dart:30–33`): Repeating 800ms wave animation during recording, not gated by reduce-motion.
- **AnimatedSwitcher in answer widget** (`lib/features/questions/presentation/widgets/single_answer_widget.dart:88–96`): The `AnimatedSwitcher`'s fade transition is **not** gated — only the inner `_buildFeedbackContent` is. When `reduceMotion=true`, the `AnimatedSwitcher` still runs its 300ms fade.
- **Rapid auto-scroll during streaming** (`lib/features/teaching/presentation/tutor_screen.dart:228–234`, `lib/features/mentor/presentation/mentor_screen.dart:169–177`, `lib/features/quickguide/presentation/quick_guide_screen.dart:187–195`): `animateTo` with 100ms duration fires on every streaming chunk, causing jerky, disorienting scroll jumps that cannot be disabled.
- **No transition between questions** (`lib/features/practice/presentation/practice_session_screen.dart:304–308`): Questions swap via `setState` with zero transition; the abrupt change is disorienting and the content is not announced by screen readers.
- **AnimatedBarChart first-run animation** (`lib/core/widgets/animated_bar_chart.dart:58–77`): The `_hasAnimated` flag's `begin: _hasAnimated ? height : 0` means the chart animates from 0 on first render even when `widget.reduceMotion == true`, because `_hasAnimated` is initialized to `false`.

### Additional animation concerns
- `lib/features/sessions/presentation/session_history_screen.dart:97` — Empty `setState(() {})` call triggers unnecessary full rebuild.
- `lib/features/questions/presentation/widgets/canvas_drawing_widget.dart:180–199` — `setState` on every pan event rebuilds the entire widget tree; should limit to strokes-length changes or use a repaint notifier.

---

## Problem 3: Hardcoded Display Colors and Locale-Formatting Violations

### Rationale

**Dark-mode / high-contrast breakage**: Several widgets hardcode `Colors.green`, `Colors.red`, `Colors.orange`, `Colors.blue` instead of using `colorScheme` values. These are invisible or unreadable in dark mode and ignored by high-contrast themes.

| File | Line(s) | Hardcoded Color |
|---|---|---|
| `lib/features/teaching/presentation/widgets/chat_bubble.dart` | 143–147 | `Colors.green`, `Colors.red`, `Colors.orange` |
| `lib/features/subjects/presentation/topic_list_screen.dart` | 70 | `Colors.blue` |

**Locale-breakage (~20+ locations)**: The project's `AGENTS.md` explicitly requires locale-aware helpers from `number_format_utils.dart` (`formatPercent`, `formatDecimal`, etc.). Yet nearly every user-facing percent string uses `'${(value * 100).round()}%'` which always produces a period decimal separator — wrong for `es`, `fr`, `de`, and other comma-decimal locales.

| File | Line(s) | Offending Pattern |
|---|---|---|
| `lib/features/dashboard/presentation/widgets/summary_row.dart` | 43 | `'$accuracy%'` (also double-appends `%` if already formatted) |
| `lib/features/dashboard/presentation/widgets/weak_areas_card.dart` | 49 | `'${(state.accuracy * 100).round()}%'` |
| `lib/features/dashboard/presentation/widgets/topic_breakdown_card.dart` | 79 | Same |
| `lib/features/dashboard/presentation/widgets/mastery_progress_card.dart` | 60–61 | Same |
| `lib/features/dashboard/presentation/widgets/plan_adherence_card.dart` | 41, 49 | Same |
| `lib/features/practice/presentation/widgets/practice_session_stats_bar.dart` | 56 | `'$scoreValue%'` — scoreValue already contains `%` from `formatPercent`, producing `"85%%"` |
| `lib/features/teaching/presentation/widgets/lesson_progress_bar.dart` | 108 | `'${(progress * 100).round()}%'` |
| `lib/features/teaching/presentation/widgets/chat_bubble.dart` | 151 | `'${(score * 100).round()}%'` |
| `lib/features/planner/presentation/widgets/plan_summary_card.dart` | 62 | Same |
| `lib/features/planner/presentation/widgets/roadmap_card.dart` | 86 | `'${progress * 100}'` — no rounding, no symbol |
| `lib/features/subjects/presentation/widgets/subject_history_tab.dart` | 49 | `'${(state.accuracy * 100).round()}%'` |
| `lib/features/planner/presentation/widgets/progress_overlay_widget.dart` | 77 | Same |
| `lib/features/focus_mode/presentation/widgets/session_summary_card.dart` | 18–26 | `_formatDuration` uses raw `'${hours}h ${minutes}m'` — not locale-aware |

---

## Acceptance Criteria

1. **Live regions**: Every streaming-text widget (`ChatBubble`, mentor message area) and every auto-updating display (timer, elapsed time, countdown) is wrapped in `Semantics(liveRegion: true)` so screen readers announce changes.
2. **Semantics hygiene**: Every interactive element has exactly one `Semantics` ancestor with `button: true` (no double-wrapping). Icon-only buttons have an explicit `label`. Disabled interactive elements convey `enabled: false`.
3. **Reduced motion completeness**: Every animation in the codebase (pulse, wave, auto-scroll, `AnimatedSwitcher`, bar-chart entrance, question transitions) respects _both_ `MediaQuery.disableAnimationsOf(context)` and `SettingsBox.reduceMotion`.
4. **No hardcoded display colors**: All user-facing colors come from `Theme.of(context).colorScheme` — no `Colors.green`, `Colors.red`, `Colors.orange`, `Colors.blue`, etc.
5. **Locale-safe number formatting**: Every user-facing percentage and duration string uses the helpers in `number_format_utils.dart` (`formatPercent`, `formatHours`, `formatDuration`). No `toStringAsFixed` or `'${...}%'` string interpolation in display contexts.
6. **CSV/LLM strings unchanged**: CSV exports remain `en`-invariant; LLM-facing prompt strings remain unformatted. The `AGENTS.md` convention is preserved.
