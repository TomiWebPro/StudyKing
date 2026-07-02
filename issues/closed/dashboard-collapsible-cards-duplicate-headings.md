# Dashboard collapsible cards show duplicate section headings

**Severity:** minor
**Affected area:** Dashboard — collapsible card widgets and body widgets
**Reported by:** user

## Description

The dashboard uses `CollapsibleCard` as a wrapper for each section (Weekly Activity, Plan Adherence, Mastery Overview, etc.). Each `CollapsibleCard` renders a header row with a title text and an expand/collapse arrow. However, every body widget (e.g., `WeeklyChart`, `PlanAdherenceCard`, `MasteryProgressCard`) **also renders its own identical heading row** inside its body content. This causes each section heading to appear twice in the UI — once in the collapsible card header and once inside the expanded body.

The user additionally suggests that the collapsible/dropdown behavior may not be needed at all, and that removing the collapsible toggle would simplify the UI.

## Affected cards (all have duplicate headings)

| Card ID | CollapsibleCard title | Duplicate in body widget |
|---|---|---|
| `weekly_chart` | `l10n.weeklyActivity` | `WeeklyChart` (line 36–44) |
| `adherence` | `l10n.planAdherence` | `PlanAdherenceCard` (line 23–34) |
| `mastery` | `l10n.masteryOverview` | `MasteryProgressCard` (line 31–42) |
| `workload` | `l10n.remainingWorkload` | `WorkloadCard` (line 54–66) |
| `due_reviews` | `l10n.dueForReview` | `DueReviewsCard` (line 21–53) |
| `weak_areas` | `l10n.weakAreas` | `WeakAreasCard` (line 48–60) |
| `topic_breakdown` | `l10n.topicPerformance` | `TopicBreakdownCard` (line 100–113) |
| `badges` | `l10n.achievements` | `BadgesCard` (line 43–51) |

Cards that do NOT have the problem:
- `summary` — `SummaryRow` has no inner heading (good).
- `focus` — `SessionSummaryCard` has no inner heading (good).

## Steps to reproduce

1. Open the Dashboard screen with any data loaded.
2. Observe any collapsible card section (e.g., "Weekly Activity", "Plan Adherence", "Mastery Overview", "Remaining Workload", "Due for Review", "Weak Areas", "Topic Performance", "Achievements").
3. Notice that the section title text appears twice: once in the card header row (alongside the expand/collapse arrow) and again inside the card body as a separate heading.

## Expected behavior

Each section title should appear **only once**. The UI should be clean and not repeat the same heading.

Two possible approaches:
- **Option A:** Remove the collapsible card wrapper entirely and replace it with plain `Card` widgets (no expand/collapse). Keep the title inside each body widget as the sole heading.
- **Option B:** Keep the `CollapsibleCard` wrapper but strip the duplicate title/icon from each body widget, letting only the collapsible header be the heading.

## Actual behavior

Every collapsible dashboard section renders its heading twice — once in the `CollapsibleCard` header and once inside the body widget.

## Code analysis

### CollapsibleCard (the wrapper)

`lib/features/dashboard/presentation/widgets/collapsible_card.dart` (lines 71–133):
- Renders a `Card` with a header row containing the `title` widget and a collapse/expand icon.
- Below the header, the `body` content is shown/hidden based on collapse state.
- The `title` is passed from `dashboard_screen.dart` via `_cardTitle()` which creates a `Row` with an icon and label text.

### Dashboard screen (the call sites)

`lib/features/dashboard/presentation/dashboard_screen.dart`:
- Lines 218–287 (weekly_chart): `CollapsibleCard(title: _cardTitle(..., l10n.weeklyActivity), body: WeeklyChart(...))`
- Lines 289–307 (adherence): `CollapsibleCard(title: _cardTitle(..., l10n.planAdherence), body: PlanAdherenceCard(...))`
- Lines 309–323 (mastery): `CollapsibleCard(title: _cardTitle(..., l10n.masteryOverview), body: MasteryProgressCard(...))`
- (and so on for each section)

### Body widgets with duplicate headings

Each body widget independently renders its own heading:

- `lib/features/dashboard/presentation/widgets/weekly_chart.dart:36–44` — renders `Icons.show_chart` + `l10n.weeklyActivity`
- `lib/features/dashboard/presentation/widgets/plan_adherence_card.dart:23–34` — renders `Icons.event_note` + `l10n.planAdherence`
- `lib/features/dashboard/presentation/widgets/mastery_progress_card.dart:31–42` — renders `Icons.analytics` + `l10n.masteryOverview`
- `lib/features/dashboard/presentation/widgets/workload_card.dart:54–66` — renders `Icons.trending_up` + `l10n.remainingWorkload`
- `lib/features/dashboard/presentation/widgets/due_reviews_card.dart:21–53` — renders `Icons.autorenew` + `l10n.dueForReview`
- `lib/features/dashboard/presentation/widgets/weak_areas_card.dart:48–60` — renders `Icons.warning_amber` + `l10n.weakAreasAccuracy`
- `lib/features/dashboard/presentation/widgets/topic_breakdown_card.dart:100–113` — renders `Icons.pie_chart` + `l10n.topicPerformance`
- `lib/features/dashboard/presentation/widgets/badges_card.dart:43–51` — renders `Icons.emoji_events` + `l10n.achievements`

### Root cause

The `CollapsibleCard` was designed as a generic reusable wrapper with its own title, but the body widgets were originally standalone cards that had their own titles. When they were wrapped inside `CollapsibleCard`, the body titles were never removed, creating the duplication.

## Suggested approach

**Option A (recommended — simpler UI per user feedback):**
1. Replace all `CollapsibleCard(...)` usages in `dashboard_screen.dart` with plain `Card(...)` widgets, removing the expand/collapse toggle entirely.
2. Keep the existing body widgets as-is (they already have their own headings).
3. Delete or archive `collapsible_card.dart` and `dashboard_layout_providers.dart` (including the Hive box for persisted collapse preferences) since they would no longer be used.

**Option B (keep collapsible behavior):**
1. Remove the duplicate heading rows from each body widget (`WeeklyChart`, `PlanAdherenceCard`, `MasteryProgressCard`, `WorkloadCard`, `DueReviewsCard`, `WeakAreasCard`, `TopicBreakdownCard`, `BadgesCard`).
2. Ensure each widget can function as pure content without a self-contained heading.
