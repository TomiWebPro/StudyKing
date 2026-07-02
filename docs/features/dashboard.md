# Dashboard Feature

## Overview

The Dashboard is the home screen of the app, providing a comprehensive overview of the student's study progress, mastery status, upcoming reviews, focus sessions, plan adherence, and quick navigation to other features. It serves as the central hub that aggregates data from across the platform and presents it in a scrollable, card-based layout. The dashboard also includes an onboarding checklist for new users and a data export section.

## Key Files

| Layer | Files |
|---|---|
| Services | `DashboardService` |
| Repositories | `BadgeRepository` |
| Models | `MasterySnapshot`, `OverallStats`, `WeeklyTrendEntry`, `FocusTodayStats`, `AdherenceData`, `BadgeDisplay`, `SubjectDueCount`, `DueReviewsData`, `ChecklistProgress`, `BadgeModel`, `BadgeDefinition` |
| Screens | `DashboardScreen`, `TopicDetailScreen` |
| Widgets | `DashboardHeader`, `NextUpCard`, `EmptyDashboardChecklist`, `SummaryRow`, `WeeklyChart`, `PlanAdherenceCard`, `MasteryProgressCard`, `WorkloadCard`, `DueReviewsCard`, `WeakAreasCard`, `TopicBreakdownCard`, `BadgesCard`, `AbsenceBanner`, `DashboardNavCard`, `DashboardCard`, `ExportSection` |
| Providers | `dashboardInitProvider`, `dashboardAllMasteryProvider`, `dashboardMasterySnapshotProvider`, `dashboardOverallStatsProvider`, `dashboardWeeklyTrendProvider`, `dashboardFocusStatsProvider`, `dashboardAdherenceDataProvider`, `dashboardTopicNamesProvider`, `dashboardBadgesProvider`, `dashboardWorkloadProvider`, `dashboardDueReviewsProvider`, `dashboardSourceCountProvider`, `dashboardSyllabusProgressProvider`, `dashboardChecklistProgressProvider`, `dashboardLastFocusSessionProvider`, `dashboardStudyProgressTrackerProvider`, `dashboardInstrumentationServiceProvider`, `dashboardExportServiceProvider` |

## Core Services

### DashboardService

Aggregates data from multiple core services to populate the dashboard:

- `init()` — Initialize all dependencies (mastery graph, adherence repository, topic/session repos)
- `getAllTopicMastery(studentId)` — Get all topic mastery states
- `getMasterySnapshot(studentId)` — Get a summary snapshot of overall mastery
- `getOverallStats(studentId)` — Get aggregate statistics (accuracy, study time, weekly activity)
- `getWeeklyTrend(studentId)` — Get weekly trend data (attempts and accuracy per week)
- `getFocusStats()` — Get today's focus session statistics
- `getAdherenceData(studentId)` — Get overall and weekly plan adherence scores
- `getTopicNamesMap(studentId)` — Build a map of topic ID to topic name
- `getBadges(studentId)` — Get earned badge displays

## Key Models

| Model | Purpose |
|---|---|
| `MasterySnapshot` | Summary of total, mastered, and weak topics, average accuracy and readiness |
| `OverallStats` | Aggregate stats: total attempts, accuracy, study time, weekly/daily activity |
| `WeeklyTrendEntry` | Per-week record of attempts, accuracy, and improvement trend |
| `FocusTodayStats` | Today's focus session metrics: seconds, completions, planned minutes |
| `AdherenceData` | Overall and weekly plan adherence percentages |
| `DueReviewsData` | Total due reviews with per-subject breakdown |
| `ChecklistProgress` | Tracks whether the student has subjects, sources, practice sessions, and scheduled lessons |
| `BadgeModel` | Hive-stored badge earned by a student |
| `BadgeDefinition` | Static badge criteria definitions with check operators |

## Widget Descriptions

- **DashboardHeader** — Title bar with navigation to export, settings, and quick guide
- **NextUpCard** — Shows upcoming lessons, due reviews, and weak topic count with quick-action tiles
- **EmptyDashboardChecklist** — Onboarding checklist guiding new users through adding subjects, uploading materials, practicing, and scheduling lessons
- **SummaryRow** — Displays key metrics (accuracy, study hours, weekly activity, topics, total questions) in a responsive grid
- **WeeklyChart** — Bar chart showing weekly attempt trends with gap indicators for inactive weeks
- **PlanAdherenceCard** — Shows overall and weekly adherence scores with color-coded severity
- **MasteryProgressCard** — Overview of mastered vs in-progress topics, accuracy, and readiness
- **WorkloadCard** — Estimated remaining lessons based on topic mastery levels
- **DueReviewsCard** — Lists total due reviews with per-subject breakdown
- **WeakAreasCard** — Lists topics with accuracy below 60%, with practice shortcuts
- **TopicBreakdownCard** — Sorted list of all topics with accuracy sparklines and progress bars
- **BadgesCard** — Shows earned achievement badges
- **AbsenceBanner** — Warning banner shown when the student returns after 1+ days away
- **DashboardNavCard** — Reusable navigation card used for planner, content library, question bank, and session history links
- **DashboardCard** — Async-aware card wrapper that handles loading, error, and data states
- **ExportSection** — CSV, PDF, JSON, and backup export options with share integration

## Data Flow

1. `DashboardScreen` loads and reads `studentId`
2. Watches multiple `FutureProvider.family` providers from `dashboard_data_providers.dart`
3. Each provider calls `dashboardInitProvider` first to ensure core services are initialized
4. Providers delegate to core services (`MasteryGraphService`, `StudyProgressTracker`, `SessionRepository`, `PlanAdherenceRepository`, `SpacedRepetitionService`)
5. Raw data is transformed into dashboard model classes (`OverallStats`, `MasterySnapshot`, etc.)
6. The screen renders cards conditionally based on data availability, showing skeletons during loading and error-retry widgets on failure

## Provider Architecture

- `dashboardInitProvider` — Ensures all backing services are initialized before data is fetched
- `dashboardDataProviders` — Family of `FutureProvider.family` providers keyed by `studentId`, each responsible for a specific data slice (mastery, stats, trend, focus, adherence, badges, workload, due reviews)
- `dashboardStudyProgressTrackerProvider` — Constructs `StudyProgressTracker` with locale-aware localization and reactive l10n updates
- `dashboardInstrumentationServiceProvider` / `dashboardExportServiceProvider` — Wired for data export functionality
- Pull-to-refresh invalidates `dashboardInitProvider`, which cascades to all dependent providers
