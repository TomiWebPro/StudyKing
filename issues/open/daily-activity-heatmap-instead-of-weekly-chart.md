# GitHub-style Daily Activity Heatmap Instead of Weekly Bar Chart

**Severity:** minor
**Affected area:** Dashboard — Weekly Chart card + Summary Row
**Reported by:** user (feature request)

## Description

The current weekly bar chart (showing "This Week", "Week 1", "Week 2" … "Week 7") is not motivating. The user requests replacing it with a **GitHub-style contribution heatmap** that shows daily activity as a grid of coloured squares, where green intensity scales with how active the student was each day. This is far more encouraging — it rewards daily consistency visually.

Additionally, the Summary Row currently displays "Weekly activity: N" — this should change to "Today: N" (using the already-tracked `dailyActivity` field).

## Proposed design

- Replace the `WeeklyChart` card entirely with a new `DailyActivityHeatmap` widget.
- The heatmap should follow the GitHub contribution graph layout:
  - Columns = weeks (last ~52 weeks, i.e. one year)
  - Rows = days of the week (Mon–Sun)
  - Each cell is a small square coloured by activity intensity:
    - No activity → light grey / empty
    - Low activity → light green
    - Medium activity → medium green
    - High activity → dark green
- **Activity is a composite score** — a combination of:
  - Questions answered (attempts count)
  - Accuracy (correct %)
  - Focus mode minutes
  - Sessions completed
- The Summary Row should replace `weeklyActivity` with `dailyActivity` (today's attempts).
- The weekly bar chart should be removed entirely (no need to keep it alongside).

## Steps to reproduce

N/A — feature request, not a bug.

## Code analysis

The following changes are needed:

### 1. New data model (`lib/features/dashboard/data/models/dashboard_models.dart`)

Add a `DailyTrendEntry` model:
```dart
class DailyTrendEntry {
  final DateTime date;
  final int attempts;
  final double accuracy;
  final int focusSeconds;
  final int sessions;
  final double compositeScore; // 0.0–1.0 used for colour intensity

  const DailyTrendEntry({...});
}
```

### 2. New service method (`lib/core/services/study_progress_tracker.dart`)

Add a `getDailyTrend(int days)` method that:
- Fetches all attempts via `_attemptRepo.getByStudent(studentId)`
- Fetches all sessions via `_sessionRepo?.getByStudent(studentId)`
- Buckets attempts and sessions by day (using `timestamp.dateOnly`)
- Computes per-day: attempt count, accuracy, focus time, session count
- Computes a composite score per day (normalised 0–1)
- Returns `Result<List<DailyTrendEntry>>`

### 3. New Riverpod provider (`lib/features/dashboard/providers/dashboard_data_providers.dart`)

Add `dashboardDailyTrendProvider`:
```dart
final dashboardDailyTrendProvider =
    FutureProvider.family<List<DailyTrendEntry>, String>(
  (ref, studentId) async {
    final tracker = ref.watch(dashboardStudyProgressTrackerProvider);
    final result = await tracker.getDailyTrend(365, studentId: studentId);
    return result.data ?? [];
  },
);
```

### 4. New heatmap widget (`lib/features/dashboard/presentation/widgets/daily_activity_heatmap.dart`)

Create a `DailyActivityHeatmap` `ConsumerWidget` that:
- Takes `List<DailyTrendEntry> dailyTrend`
- Renders a GitHub-style contribution grid using a `GridView` or `Wrap`
- Each cell is a small rounded square (12×12 px or so)
- Colour is determined by `compositeScore`:
  - 0 → surfaceContainerHighest (no activity)
  - 0.01–0.25 → lightest green
  - 0.26–0.50 → medium-light green
  - 0.51–0.75 → medium green
  - 0.76–1.0 → dark green
- Shows month labels along the top
- Shows day-of-week labels on the left (Mon, Wed, Fri — like GitHub)
- Has a tooltip on tap showing: date, attempts, accuracy, focus time, sessions
- Follows accessibility patterns (Semantics for each cell)

### 5. Update dashboard screen (`lib/features/dashboard/presentation/dashboard_screen.dart`)

- Replace the `WeeklyChart` card (lines 267–278) with the new `DailyActivityHeatmap` card
- Watch `dashboardDailyTrendProvider(studentId)` instead of `dashboardWeeklyTrendProvider(studentId)`
- Update `SummaryRow` to pass/display `dailyActivity` from `OverallStats`

### 6. Update Summary Row (`lib/features/dashboard/presentation/widgets/summary_row.dart`)

Change line 80 from:
```dart
label: l10n.weeklyActivity,
```
to:
```dart
label: l10n.dailyActivity,  // new l10n key
```
And wire it to `stats.dailyActivity` instead of `stats.weeklyActivity`.

### 7. Localization (`lib/l10n/generated/app_localizations.dart` and language files)

Add a new l10n key:
```dart
String get dailyActivity => 'Today';
```
Update `app_localizations_en.dart` and `app_localizations_es.dart` with the translation.

### 8. Tests

- Add test for `StudyProgressTracker.getDailyTrend()` in `test/core/services/study_progress_tracker_test.dart`
- Add widget test for `DailyActivityHeatmap` in `test/features/dashboard/presentation/widgets/daily_activity_heatmap_test.dart`
- Add test for new provider in `test/features/dashboard/providers/dashboard_data_providers_test.dart` (or update existing)
- The existing `weekly_chart_test.dart` and related weekly chart tests can be removed or updated

## Suggested approach

1. Start with the data layer: add `DailyTrendEntry` model and `getDailyTrend()` to `StudyProgressTracker`
2. Add the Riverpod provider
3. Build the `DailyActivityHeatmap` widget (the most involved piece — needs a custom paint or a grid layout)
4. Wire it into `DashboardScreen`, replacing `WeeklyChart`
5. Update `SummaryRow` to show `dailyActivity`
6. Add l10n strings
7. Write tests for each layer
8. Clean up: remove `WeeklyChart` widget and `dashboardWeeklyTrendProvider` if no longer referenced elsewhere
