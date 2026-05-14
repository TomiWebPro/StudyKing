# Dashboard Architecture Overhaul: Riverpod State, Parallel Loading, Typed Data, and Collapsible Cards

## Context

The dashboard (`lib/features/dashboard/presentation/dashboard_screen.dart`) is the application's primary hub — accessible via FAB from every bottom-nav tab — yet it is implemented with the **most fragile state management pattern in the entire codebase**. A single 206-line `ConsumerStatefulWidget` loads **9 data sources** sequentially inside a monolithic `_loadData()` method, stores everything in `Map<String, dynamic>` loose maps, manages loading via a single `_isLoading` boolean, and renders every card unconditionally (many returning `SizedBox.shrink()` when empty). This pattern was identified as a high-value target during codebase inspection because it affects every user session and blocks every downstream feature that needs dashboard integration (planner adherence, practice stats, focus mode metrics, mastery snapshots, etc.).

The four other open issues cover planner intelligence, focus mode architecture, test coverage, and i18n. This issue is **orthogonal** — it addresses the structural layer on which all those features depend for visibility.

---

## Issue 1: Monolithic `setState` Loader with Sequential `await` Chain

`_loadData()` (lines 68–113) runs 9+ data fetches in strict sequence with a single try/catch that swallows all per-source errors:

```dart
Future<void> _loadData() async {
  setState(() => _isLoading = true);
  await _instrumentation.init();       // 1
  await _topicRepo.init();             // 2
  await _adherenceRepo.init();         // 3
  await _focusService.repository.init(); // 4
  _focusTodayStats = await _focusService.getTodayStats(); // 5
  final masteryResult = await _masteryService.getAllTopicMastery(...); // 6
  // ... 3 more awaits sequentially
  for (final state in _allMastery) {   // N sequential topic lookups
    await _topicRepo.get(state.topicId);
  }
  setState(() => _isLoading = false);
}
```

**Problems:**
- **No parallelism**: `_instrumentation.init()`, `_focusService.getTodayStats()`, `_masteryService.getAllTopicMastery()` are all I/O-bound Hive reads that could run concurrently with `Future.wait`.
- **Single loading gate**: The entire dashboard shows a `CircularProgressIndicator` until **all** data loads. If the adherence repository is slow (or throws), no data renders — not even mastery stats which loaded successfully three lines earlier.
- **Per-topic N+1**: Lines 100–109 fetch topic names one-by-one in a `for` loop instead of batching via `_topicRepo.getBySubject()` or caching the full topic map upfront.
- **Error swallowing**: Every `await` is in a single try/catch; a failure in `_focusService.getTodayStats()` (lines 75–77, caught silently) still blocks `_instrumentation.init()` from running because they're sequential.

**Fix**: Replace with per-card `FutureProvider.family` or `AsyncValue` providers so each card loads independently, shows its own loading skeleton, and retries individually.

---

## Issue 2: Loosely Typed `Map<String, dynamic>` Data Trivialises Type Safety

Every data structure in `_DashboardScreenState` is a `Map<String, dynamic>`:

```dart
Map<String, dynamic>? _snapshot;
Map<String, dynamic>? _overallStats;
List<Map<String, dynamic>> _weeklyTrend = [];
List<Map<String, dynamic>> _badges = [];
Map<String, dynamic>? _focusTodayStats;
```

Downstream widgets are forced to access by string key:

```dart
// mastery_progress_card.dart:14-18
final data = snapshot ?? {};
final totalTopics = data['totalTopics'] ?? 0;
final masteredTopics = data['masteredTopics'] ?? 0;
final weakTopics = data['weakTopics'] ?? 0;
final avgAccuracy = data['averageAccuracy'] ?? 0.0;
```

This pattern appears in **5 of 9 dashboard widgets** (`MasteryProgressCard`, `SummaryRow`, `WeakAreasCard`, `WeeklyChart`, `BadgesCard`). A field rename in the upstream service silently produces `null` at runtime — no compile-time error, no analyzer warning. The `??` fallback masks the bug.

**Affected models that should be used instead** (most already exist in `lib/core/data/models/`):
| Current `Map` key | Existing typed model |
|---|---|
| `'totalTopics'`, `'masteredTopics'`, `'weakTopics'`, `'averageAccuracy'` | `MasterySnapshot` or fields from `MasteryGraphService.getMasterySnapshot()` |
| `'accuracy'`, `'totalStudyTimeHours'`, `'weeklyActivity'`, `'topicsStudied'` | `StudyProgressSnapshot` (or similar from `StudyProgressTracker`) |
| `'attempts'` (weekly trend items) | Typed trend entry model |
| Badge maps with `'name'`, `'description'` | `Badge` model |

---

## Issue 3: All Cards Always Mounted — No Visibility-Aware Rendering

The dashboard renders all 9 cards unconditionally (lines 130–200):

```dart
const DashboardHeader(),                    // always visible
SummaryRow(overallStats: _overallStats),    // visible even if empty stats
WeeklyChart(weeklyTrend: _weeklyTrend),     // visible even if empty
PlanAdherenceCard(adherence...),            // visible even if 0%
MasteryProgressCard(snapshot: _snapshot),   // visible even if null
WeakAreasCard(allMastery: _allMastery),     // returns SizedBox.shrink() when empty
TopicBreakdownCard(allMastery: _allMastery),// visible even if empty
BadgesCard(badges: _badges),               // returns SizedBox.shrink() when empty
ExportSection(...),                          // always visible
```

Five of nine widgets handle empty data by returning `SizedBox.shrink()` (a zero-height widget). This means:
- A new user with no data sees a header, an empty summary row, an empty chart, a 0% adherence card, an empty mastery card, and an export section — but **no guidance** on what to do next.
- The scrollable list is 4–5 actual cards interspersed with invisible zero-height widgets, making keyboard/screen-reader navigation unpredictable.
- No card supports collapsing, reordering, or dismissal.

**Expected behavior**: Empty cards should show **suggested actions** ("Add your first subject to see stats here"), cards should be **collapsible**, and a **getting-started checklist** should replace the empty dashboard for new users.

---

## Issue 4: Hardcoded `NumericFocusOrder` Is Fragile

Lines 133–199 assign hardcoded `NumericFocusOrder(1)` through `NumericFocusOrder(10)` to cards. Adding, removing, or conditionally showing a card (e.g., hiding `ExportSection` for non-premium users) requires renumbering every subsequent focus order — a manual, error-prone process with no analyzer guard. This is identical to the pattern the `code_refactor_master` issue identified as problematic in Focus Mode.

**Fix**: Remove explicit focus orders from the dashboard column (cards are already in DOM order); or derive orders dynamically from the visible card list.

---

## Issue 5: `_resolveTopicName` N+1 on Every Rebuild

`_loadData()` (lines 100–109) iterates `_allMastery` and fetches topic names one-by-one via `_topicRepo.get(state.topicId)`. Since the topic names are cached only in `_topicNameCache`, and the cache is populated **during the loading phase**, every pull-to-refresh re-fetches every topic name. For a student with 50+ topics, this is 50 sequential Hive reads on every dashboard load.

The `TopicRepository` already has `getBySubject(subjectId)` which returns all topics for a subject in one call. Since all mastery states belong to the same student, a single `_topicRepo.getAll()` call (or getting topics by subject) would replace the N+1 loop.

---

## Affected Files

| Scope | Files |
|---|---|
| **Dashboard Screen** | `lib/features/dashboard/presentation/dashboard_screen.dart` (lines 37–206, entire `_DashboardScreenState`) |
| **Dashboard Providers** | `lib/features/dashboard/providers/dashboard_providers.dart` (all 36 lines — 5 providers that return singletons, no `FutureProvider`) |
| **MasteryProgressCard** | `lib/features/dashboard/presentation/widgets/mastery_progress_card.dart` (loose map access, lines 13–19) |
| **SummaryRow** | `lib/features/dashboard/presentation/widgets/summary_row.dart` (loose map access, lines 14–18) |
| **WeeklyChart** | `lib/features/dashboard/presentation/widgets/weekly_chart.dart` (loose map access via `item['attempts']`, line 19) |
| **WeakAreasCard** | `lib/features/dashboard/presentation/widgets/weak_areas_card.dart` (hardcoded 60% threshold, empty subjectId in navigation) |
| **TopicBreakdownCard** | `lib/features/dashboard/presentation/widgets/topic_breakdown_card.dart` (sorted by accuracy only, no trend/practice history context) |
| **PlanAdherenceCard** | `lib/features/dashboard/presentation/widgets/plan_adherence_card.dart` (no integration with planner's adherence deviation banner) |
| **BadgesCard** | `lib/features/dashboard/presentation/widgets/badges_card.dart` (empty state returns SizedBox.shrink, no gamification system backing it) |
| **ExportSection** | `lib/features/dashboard/presentation/widgets/export_section.dart` (SnackBar-only feedback, no actual file save/share) |
| **Dashboard Barrel** | `lib/features/dashboard/dashboard.dart` (exports all widgets) |
| **Tests** | `test/features/dashboard/presentation/dashboard_screen_test.dart`, `test/features/dashboard/providers/dashboard_providers_test.dart` |
| **Route config** | `lib/core/routes/app_router.dart` (dashboard route passes `Map<String, dynamic>` as arg — lines 151–165) |
| **Mastery models** | `lib/core/data/models/mastery_state_model.dart`, `mastery_snapshot_model.dart` (for defining typed snapshot type) |
| **Progress tracker** | `lib/core/services/study_progress_tracker.dart` (for returning typed objects instead of `Map<String, dynamic>`) |

---

## Rationale

### Why fix the dashboard now?

1. **It is the app's navigation hub** — the FAB on every bottom-nav tab opens the dashboard. Every user sees it on every session.

2. **The current implementation blocks parallel work** — six open/completed issues (planner intelligence, focus mode, test coverage, i18n, settings UX, code refactoring) all produce data that should surface on the dashboard, but the monolithic `setState` pattern makes it risky to add new cards.

3. **No card-level error recovery** — if the mastery snapshot provider throws, the entire dashboard fails to render (or, worse, silently shows 0s everywhere). Per-provider error boundaries give each card independent recovery.

4. **The type-safety gap widens as the app grows** — `Map<String, dynamic>` patterns in 5 dashboard widgets will silently break when `StudyProgressTracker` or `MasteryGraphService` refactors its return values (both of which are likely given the planner and test issues).

5. **The N+1 topic-name lookup will become a performance bottleneck** as student topic counts grow. A student with 10 subjects × 20 topics each = 200 sequential Hive reads per dashboard load.

### Existing analysis supports this refactor

The completed `test_master` issue identified that dashboard widget tests existed but were written before this architecture issue was defined. The `code_refactor_master` issue (triplicated providers) is a prerequisite — the dashboard currently creates its own `FocusSessionService` instance, which must be consolidated before dashboard providers can become canonical.

---

## Acceptance Criteria

1. **Per-card Riverpod providers**: Replace the single `_loadData()` method with individual `FutureProvider` or `AsyncNotifierProvider` instances for each data source (mastery snapshot, overall stats, weekly trend, badges, adherence, focus stats, topic names). Each provider must have its own loading, error, and data states.

2. **Parallel initialization**: All independent initializations (`_instrumentation.init()`, `_adherenceRepo.init()`, `_topicRepo.init()`, `_focusService.getTodayStats()`, `_masteryService.getAllTopicMastery()`) run via `Future.wait` or equivalent parallel dispatch. Topic name resolution uses `_topicRepo.getAll()` (single call) instead of N sequential `get()` calls.

3. **Typed data models**: Replace `Map<String, dynamic>` with typed Dart objects in all dashboard widgets:
   - `MasteryProgressCard` receives a typed `MasterySnapshot` (or similar) instead of `Map<String, dynamic>?`
   - `SummaryRow` receives a typed `OverallStats` instead of `Map<String, dynamic>?`
   - `WeeklyChart` receives `List<WeeklyTrendEntry>` instead of `List<Map<String, dynamic>>`
   - `BadgesCard` receives `List<Badge>` instead of `List<Map<String, dynamic>>`
   - `WeakAreasCard` receives the resolved topic name as a `Map<String, String>` via a single batch lookup, not an N+1 cache populate

4. **Collapsible sections**: Each card has a `Card` wrapper with a `ExpansionTile`-like header (or a simple collapse toggle). State (collapsed/expanded per card) is persisted in a `DashboardLayoutPreferences` box so the user's layout choice survives restarts.

5. **Guided empty state**: When the student has **no data** across all cards (new user), the dashboard shows a **getting-started checklist**: "Add a subject", "Upload study material", "Take your first practice quiz", "Schedule a lesson with the AI tutor". This checklist replaces the empty-card grid.

6. **Card-level error states**: If a single provider fails (e.g., adherence repository init throws), its card shows an inline error with a retry button — **other cards continue to render normally**.

7. **Dynamic focus ordering**: Remove hardcoded `NumericFocusOrder` from the dashboard column. Cards are ordered by a `List<Type>` configuration that can be reordered by the user (future enhancement: drag-to-reorder).

8. **`ExportSection` improvement**: The "export" buttons should actually download/share a file (using `share_plus`, already a dependency per `session_export_service.dart:7`) instead of showing a SnackBar with the CSV length. A `file_saver` path or temporary file + share sheet should be used.

9. **Existing dashboard widget tests continue to pass** — all changes to card constructors and data types must be backward-compatible or have corresponding test updates. The `dashboard_screen_test.dart` must be extended to cover loading states, error states, and the empty-state checklist.

10. **`dart analyze` passes with zero errors** after all changes.
