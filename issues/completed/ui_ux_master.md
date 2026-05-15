# Responsive Layout Fragmentation & Dashboard Accessibility Gaps

## Context

The codebase defines a centralized responsive breakpoint system in `ResponsiveUtils` (`lib/core/utils/responsive.dart`) with four tiers (xs <600, sm <840, md <1200, lg 1200+) plus a `ScreenBreakpoint` enum and convenience extension on `BuildContext`. However, most dashboard widgets and several shared components ignore this system entirely, using fixed pixel values or ad-hoc inline breakpoints instead. This creates visual fragmentation across device sizes, especially on tablets and large screens where content becomes either too cramped or excessively stretched.

Additionally, the dashboard uses `InkWell` for toggling collapsible sections without proper ARIA heading semantics or accessible collapse/expand roles, making screen-reader navigation of study data impossible.

---

## Affected Files

| File | Issue |
|---|---|
| `lib/features/dashboard/presentation/widgets/collapsible_card.dart:75,91` | Title row uses fixed `EdgeInsets.symmetric(horizontal: 16, vertical: 12)`; content uses fixed `EdgeInsets.all(16)`. Ignores `ResponsiveUtils.cardPadding` or `screenPadding`. `InkWell` has no `Semantics` button/label for collapse toggle. |
| `lib/features/dashboard/presentation/widgets/summary_row.dart:23-65` | Uses hardcoded `constraints.maxWidth < 400` breakpoint instead of `ResponsiveUtils.breakpointOf`. `SizedBox` widths of `160` don't adapt to tablet layouts. |
| `lib/features/dashboard/presentation/widgets/weak_areas_card.dart:22-80` | Fixed `EdgeInsets.all(16)`. Renders a `Card` inside `CollapsibleCard`'s `Card` → nested card-in-card visual artifact. |
| `lib/features/dashboard/presentation/widgets/topic_breakdown_card.dart:37-57` | Fixed `EdgeInsets.all(16)`. Same nested card-in-card as `WeakAreasCard`. |
| `lib/features/dashboard/presentation/widgets/mastery_progress_card.dart` | Fixed `EdgeInsets.all` absent (uses no padding — relies on parent). `Row` with 3 `Expanded` children can squeeze text on xs screens. |
| `lib/features/dashboard/presentation/widgets/plan_adherence_card.dart` | Fixed layout, no responsive adaptation. |
| `lib/features/dashboard/presentation/widgets/badges_card.dart` | No responsive padding, `Wrap` with fixed spacing doesn't account for breakpoint gaps. |
| `lib/features/dashboard/presentation/widgets/dashboard_header.dart` | Uses `headlineMedium` with `fontWeight: FontWeight.bold` but no `Semantics(headingLevel:)` — invisible to screen-reader heading navigation. |
| `lib/features/dashboard/presentation/dashboard_screen.dart:215-223` | `_cardTitle` returns a `Row` with no heading semantics — collapsible section titles are not navigable headings. |
| `lib/core/widgets/animated_bar_chart.dart:21` | `barWidth: 32` is fixed. On xs screens with 7+ bars the chart overflows horizontally. |
| `lib/core/widgets/animated_bar_chart.dart:86-156` | Outer `Container` uses fixed `Radius.circular(12)` and fixed padding — should adapt to breakpoint. |
| `lib/core/widgets/metric_card.dart` | Uses `ResponsiveUtils.cardPadding` correctly, but its parent `SummaryRow` constrains it with fixed `SizedBox` widths, defeating the responsive intent. |
| `lib/core/widgets/conversation_input.dart:48-52` | Uses `EdgeInsets.only(left: 16, right: 16, top: 8, bottom: ...)` — ignores responsive padding on tablet/desktop. |
| `lib/features/teaching/presentation/widgets/chat_bubble.dart:24-28` | Asymmetric horizontal padding: applies `horizontalSpacing` only on one side, doubling visual gap between student/mentor bubbles. |

---

## Rationale

1. **Responsive inconsistency** — The `ResponsiveUtils` system exists but is only partially adopted. `SummaryRow` uses a `400px` hardcoded check even though the official xs breakpoint is `600px`. This means on a phone in landscape (~640px) the summary metrics switch to narrow mode when the breakpoint system considers this a "sm" layout. The result is unpredictable card sizing.

2. **Accessibility gap** — The entire dashboard is a flat list of collapsible cards whose titles are plain `Text` widgets inside `Row`. Screen-reader users cannot navigate by heading level, cannot discover which sections are collapsible, and receive no feedback about expanded/collapsed state beyond the icon rotation (which has no semantic label).

3. **Nested card visual bug** — `WeakAreasCard` and `TopicBreakdownCard` each wrap their content in a `Card` widget. `CollapsibleCard` already provides the outer `Card`. This produces a double-card appearance (double border radius, double background) visible on all themes.

4. **Chart overflow on small screens** — `AnimatedBarChart` has a fixed `barWidth: 32` and renders bars in a `Row` with `Expanded` children, but the bar width is absolute while the container is flexible. On xs screens with 7 days of data, bars either overflow or get clipped.

5. **Chat bubble spacing asymmetry** — `ChatBubble` applies `ResponsiveUtils.horizontalSpacing(context)` only on one side (left for tutor, right for student). Combined with the 8px avatar spacing, the gap between a student bubble and the next tutor bubble is `horizontalSpacing + 8px` while the reverse gap is only `horizontalSpacing`. This creates uneven chat layout.

6. **Conversation input not responsive on larger screens** — The input bar uses fixed 16px horizontal padding, so on tablets/desktops the text field remains narrow while large empty margins appear on either side.

---

## Acceptance Criteria

- [ ] `CollapsibleCard` uses `ResponsiveUtils.cardPadding` (or adapts padding based on breakpoint) for both the title row and content area, and wraps the title in `Semantics(headingLevel: 2, expanded: ..., button: true)` with a proper label for collapse toggle.
- [ ] `WeakAreasCard` and `TopicBreakdownCard` remove their inner `Card` wrapper (content is already inside `CollapsibleCard`'s `Card`), eliminating the double-card artifact.
- [ ] `SummaryRow` removes the `constraints.maxWidth < 400` hardcoded check and uses `ResponsiveUtils.breakpointOf(context)` or `LayoutBuilder` with breakpoint-aware column count for metric tiles. Responsive widths replace fixed `160`.
- [ ] `DashboardHeader` adds `Semantics(headingLevel: 1)` so screen readers can identify the page title.
- [ ] `AnimatedBarChart` makes `barWidth` responsive: computed from available width and data count, with a minimum readable width of 24px. Bars no longer overflow on xs screens with full-week data.
- [ ] `ChatBubble` removes asymmetric horizontal padding — applies equal padding on both sides or uses a symmetric approach so inter-bubble spacing is uniform.
- [ ] `ConversationInput` uses `ResponsiveUtils.screenPadding` horizontally so the input field width scales with screen size on tablets/desktops.
- [ ] All dashboard card titles that serve as section headings (`_cardTitle` in `DashboardScreen`, `PlanAdherenceCard`, `BadgesCard`, `MasteryProgressCard`, `WeeklyChart`) include `Semantics(headingLevel: 3)`.

---

## Verification

1. Run the app on an xs-width device (360–599px) and a tablet (768–1024px). Compare the dashboard layout: card padding, metric tile sizing/column count, bar chart overflow. Each viewport must render without clipping or excessive whitespace.
2. Enable TalkBack (Android) or VoiceOver (iOS). Navigate by headings through the dashboard. Every section title must be a navigable heading; collapse/expand actions must be announced.
3. Open the Mentor or Tutor screen on a tablet. The input bar should span a reasonable fraction of screen width, not a phone-sized text field with large side margins.
4. Visually inspect the dashboard — no double-card borders/shading on Weak Areas or Topic Performance cards.
5. The weekly bar chart on a 360px-wide screen must render all 7 bars without horizontal scroll or overflow.
