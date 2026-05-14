# Navigation Architecture Fragmentation & Planner UI Inconsistencies

## Context

StudyKing provides five bottom-nav tabs (Subjects, Practice, Mentor, Focus, Settings), but two core features — **Planner** and **Dashboard** — exist outside this navigation structure. The Planner has **no discoverable UI entry point** anywhere in the app (no button, no menu item, no link). The Dashboard is only reachable via a single FAB on the main screen. Feature screens use inconsistent UI patterns, and the Planner screen contains hardcoded strings, dead UI elements, and hardcoded semantic colors that break theme/high-contrast mode.

## Rationale

1. **Navigation discoverability**
   - Planner (`/planner` route) is registered in `AppRoutes` but never navigated to from any production widget — only from tests. A user can never discover the study planner through the interface.
   - Dashboard is exposed only through a `FloatingActionButton.small` on the main screen (`lib/main.dart:237`). There is no tab, menu item, or dashboard link in any other screen. The FAB itself lacks `Semantics` labeling for screen readers.
   - The bottom `NavigationBar` has 5 fixed destinations. Neither Planner nor Dashboard appears as a tab. No tab serves as a "home" or overview hub.

2. **Planner i18n coverage gap**
   - Strings hardcoded in English at `lib/features/planner/presentation/planner_screen.dart:254` (`'Subject Progress'`), `:434` (`'Pending Actions'`), `:509` (`'Scheduled Lessons'`), `:488` (`'Regenerate Plan'`).
   - `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart` — every label is hardcoded: `'Schedule Lesson'`, `'Date'`, `'Time'`, `'Duration'`, `'Change'`, `'Scheduling...'`. Zero l10n usage.
   - `lib/features/planner/presentation/widgets/pending_action_card.dart:89-93` — `'Schedule a lesson'`, `'Reschedule lesson'`, `'Plan adjustment suggested'`.
   - `lib/features/dashboard/presentation/widgets/collapsible_card.dart:45,55` — `'Something went wrong'`, `'Retry'`.

3. **Hardcoded semantic colors break theme/high-contrast**
   - `lib/features/planner/presentation/widgets/milestone_timeline.dart:62` — `Colors.green`, line 63: `Colors.orange`, lines 116-131: `Colors.green.withValues(alpha:0.1)`, `Colors.green.shade700`, `Colors.orange.shade700`, `Colors.orange.withValues(alpha:0.1)`.
   - `lib/features/planner/presentation/widgets/roadmap_card.dart:31` — `Colors.green`, `Colors.orange`.
   - `lib/features/planner/presentation/widgets/pending_action_card.dart:57` — `Colors.green.shade600`.
   - These will not adapt to high-contrast theme, dark mode, or user color-scheme preferences.

4. **Dead UI / broken user flow**
   - `lib/features/planner/presentation/planner_screen.dart:530-534`: Scheduled Lessons section shows "N more..." `TextButton` with an **empty `onPressed: () {}`** — users cannot expand the list.

5. **Accessibility: missing Semantics**
   - `lib/main.dart:237-241`: FAB has no explicit `Semantics` label.
   - `lib/features/planner/presentation/widgets/daily_plan_card.dart:84-100`: `IconButton`s for "Schedule Lesson" and tutoring lack `Semantics` labels (though `tooltip` exists, it is not sufficient for all screen readers).

## Affected Files

| File | Issue |
|---|---|
| `lib/main.dart:214-277` | Planner/Dashboard absent from bottom nav; FAB as sole dashboard entry point |
| `lib/features/planner/presentation/planner_screen.dart:254,434,488,509,530-534` | Hardcoded strings; dead "more" button |
| `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart` | Zero l10n usage |
| `lib/features/planner/presentation/widgets/pending_action_card.dart:57,89-93` | Hardcoded color + strings |
| `lib/features/planner/presentation/widgets/milestone_timeline.dart:62-131` | Hardcoded semantic colors |
| `lib/features/planner/presentation/widgets/roadmap_card.dart:31-32` | Hardcoded colors |
| `lib/features/dashboard/presentation/widgets/collapsible_card.dart:45,55` | Hardcoded strings |

## Recommended Approach

1. **Audit navigation structure** — Decide whether Planner and Dashboard should become permanent tabs in the bottom `NavigationBar`, or whether a Home/Dashboard tab should provide gateway cards to Planner and other features. Currently the 5-tab layout lacks a hub.
2. **Add Planner entry point** — Place a navigation link in at least one discoverable location (Dashboard "quick action" card, subject detail screen action menu, or dedicated navigation item).
3. **Replace all hardcoded English strings** with `AppLocalizations.of(context)!` calls across the Planner feature and Dashboard `CollapsibleCard`.
4. **Replace hardcoded `Colors.green`/`Colors.orange`** with semantic theme colors from `Theme.of(context).colorScheme` (e.g., `colorScheme.primary`, `colorScheme.tertiary`, `colorScheme.error`). Use text + background contrast that respects the active theme.
5. **Fix the dead "N more..." button** at `planner_screen.dart:530-534` — either navigate to a full list or replace with an inline expansion.
6. **Add `Semantics` labels** to the main-screen FAB and the interactive icon buttons in `DailyPlanCard`.

## Acceptance Criteria

- [ ] Planner is reachable from the UI without knowing the raw route string (tab or navigation link).
- [ ] All user-facing strings in `planner_screen.dart`, `lesson_booking_sheet.dart`, `pending_action_card.dart`, and `collapsible_card.dart` use `AppLocalizations`.
- [ ] No hardcoded `Colors.green`, `Colors.orange`, or non-theme color values remain in the above files.
- [ ] Scheduled Lessons "more" button navigates to a full lesson list or expands inline.
- [ ] Main-screen FAB has explicit `Semantics` label for screen readers.
- [ ] Dark mode and high-contrast mode correctly style milestone/roadmap status indicators without relying on hardcoded non-theme colors.
