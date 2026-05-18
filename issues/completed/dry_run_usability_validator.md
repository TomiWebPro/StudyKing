# Dry-Run Usability Validation: Study History, Session Tracking, and AI Activity Monitoring

## Scenario

[`dry-run-test/scenario_study_history_ai_monitor.md`](../dry-run-test/scenario_study_history_ai_monitor.md)

A returning student with weeks of study data wants to review their past sessions, manually track study time, browse the question bank, monitor AI token usage, and back up their data.

---

## BLOCKER Findings

### B1: SessionTrackerScreen is completely unreachable — orphaned route with zero entry points

**Files:**
- `lib/features/sessions/presentation/session_tracker_screen.dart` (entire file, 603 lines)
- `lib/core/routes/app_router.dart:42` (route `'/session-tracker'` registered)
- `lib/core/routes/app_router.dart:177-178` (route handler)

**What's wrong:** The `SessionTrackerScreen` is a fully implemented, tested screen with:
- Manual study timer (start/stop/record)
- Session end dialog to capture questions answered and correct answers
- Weekly analytics chart (`SessionAnalyticsWidget`)
- Recent sessions list with "View All" button to Session History
- Plan adherence tracking on session end
- Mastery improvement tracking
- WidgetsBindingObserver for lifecycle awareness

All 603 lines of UI code plus 10 test files are completely wasted because **no code in the entire app navigates to it**. A grep for `pushNamed.*sessionTracker` or `AppRoutes.sessionTracker` in `lib/` returns zero results outside the route definition itself. The route exists, the screen works, but the user cannot reach it.

**Acceptance criteria:**
- Add a navigation entry point to `SessionTrackerScreen` in at least one visible place:
  - Settings screen (e.g., under "Study Analytics" or a new "Session Tracking" section)
  - Dashboard (e.g., a "Manual Session" card or button)
  - Focus Mode screen (e.g., as an alternative to the pomodoro timer)
- OR merge the manual timer functionality into a more accessible screen
- Verify with a widget test that the entry point navigates to the correct route

### B2: SessionHistoryScreen is unreachable — the only navigation path is through the orphaned SessionTrackerScreen

**Files:**
- `lib/features/sessions/presentation/session_history_screen.dart:410` (sole navigation call)
- `lib/core/routes/app_router.dart:43` (route `'/session-history'` registered)
- `lib/core/routes/app_router.dart:179-180` (route handler)

**What's wrong:** The `SessionHistoryScreen` has comprehensive functionality:
- Full session list sorted by date
- Date and subject filters
- Summary stats (count, total time, average time)
- Swipe-to-delete with undo
- 6 export formats (CSV, PDF, JSON + comprehensive CSV/PDF/JSON)
- Proper empty states for "no sessions" vs "filtered nothing"

But the only navigation call to `AppRoutes.sessionHistory` is at `session_tracker_screen.dart:410` — from the orphaned Session Tracker screen (B1). Since no user can reach Session Tracker, no user can reach Session History through normal navigation.

The Dashboard's Export section has a button labeled "Session History" (`export_section.dart:65`) but this triggers a CSV export, not navigation.

**Acceptance criteria:**
- Add a direct navigation entry point to `SessionHistoryScreen` (not dependent on Session Tracker being reachable):
  - Dashboard: either replace the "Session History" CSV export button with actual navigation, or add a separate "View All Sessions" navigation button
  - Settings: under "Study Analytics" section
  - Any other tab where session data is relevant
- The existing CSV export in the Dashboard Export section should be relabeled to avoid confusion (it currently says "Session History" but exports CSV)

---

## MAJOR Findings

### M1: Dashboard "Session History" button is a CSV export, not navigation

**Files:**
- `lib/features/dashboard/presentation/widgets/export_section.dart:60-69`
- Localization keys: `l10n.sessionHistory` used as button label

**What's wrong:** The Dashboard's Export section has a `TextButton.icon` with label `l10n.sessionHistory` (Session History). The `onPressed` handler calls `_exportProgressCSV(context, tracker)` — which generates a CSV file and opens the system share sheet. A user who taps this expecting to see their session history will instead be presented with a file-sharing dialog. The button name and behavior are contradictory.

This button is the ONLY mention of "Session History" visible on the main screens. A user who sees it and taps it expecting a list of sessions gets a file export instead. They may not realize they need to look elsewhere (and there is no elsewhere to look, per B2).

**Acceptance criteria:**
- Relabel the button to indicate its actual function: "Export Progress CSV" or "Download Report"
- Add a separate, clearly labeled "Session History" button that navigates to the Session History screen
- OR remove the misleading label entirely and keep only "CSV", "PDF", "JSON" export buttons

### M2: AI Task Monitor data is in-memory only — all tracking lost on app restart

**Files:**
- `lib/core/services/llm_task_manager.dart:57-157` (entirely in-memory `_tasks` list)
- `lib/core/services/llm_usage_meter.dart:27-90` (entirely in-memory `_records` list)
- `lib/core/providers/llm_providers.dart:9-11` (`llmTaskManagerProvider` creates new instance with no persistence)
- `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart` (consumes in-memory data)

**What's wrong:** Both `LlmTaskManager` and `LlmUsageMeter` store all data in plain `List` fields with no persistence layer. When the app is closed and reopened:
- All LLM task history (status, tokens, cost, timestamps) is erased
- Token usage and cost totals reset to zero
- Failed tasks that the user intended to retry are gone
- Long-term cost tracking is impossible

The Settings screen (`settings_screen.dart:240-248`) shows "Total Tokens" and "Total Cost" from `LlmUsageMeter` — these appear correct during a session but reset to zero on restart. A user checking their cumulative AI costs will see different values each session.

**Acceptance criteria:**
- Persist `LlmTask` and `LlmUsageRecord` data to Hive (a new box or an existing one)
- On app start, load historical tasks and usage records from storage
- The settings token/cost display must reflect cumulative totals across all sessions, not just the current one
- Consider a retention limit (e.g., keep last 1000 records) to prevent unbounded growth
- Unit tests must verify persistence round-trip (save → restart → load → same data)

### M3: Backup export includes API key in settings box with no warning

**Files:**
- `lib/features/settings/presentation/settings_screen.dart:718-763` (`_collectAllBoxData` includes `HiveBoxNames.settings`)
- `lib/features/settings/presentation/settings_screen.dart:621-651` (`_exportBackup` shares file without sanitization)

**What's wrong:** The `_collectAllBoxData()` method includes `HiveBoxNames.settings` in its backup. The settings box stores the user's API key (`settingsBox.get('apiKey')`). The backup file is a plain JSON file shared via the system share sheet (`Share.shareXFiles`). The user receives no warning that their API key is included in the exported file. If the user shares this file via email, messaging, or cloud storage, their API key could be exposed.

**Acceptance criteria:**
- Before exporting, display a dialog warning the user that the backup contains sensitive data (API key, model configuration) and advise caution when sharing
- Provide an option to exclude sensitive settings from the backup
- OR strip the `apiKey` field from the backup JSON automatically and display a note that it will need to be re-entered on restore
- Test that the warning dialog appears and that the option to exclude sensitive data functions correctly

### M4: Backup restore is all-or-nothing — no selective restore

**Files:**
- `lib/features/settings/presentation/settings_screen.dart:778-792` (`_writeBoxData` clears boxes and writes all records)
- `lib/features/settings/presentation/settings_screen.dart:683-698` (confirmation dialog only shows box/record counts)

**What's wrong:** The `_writeBoxData()` method clears every Hive box (`await box.clear()`) before writing all records from the backup. There is no merge logic, no selective box restore, no per-record selection. The confirmation dialog only displays counts ("Importing 5 boxes with 150 records") but doesn't let the user choose what to restore.

A user who accidentally imports an old backup loses all data created since that backup. A user who only wants to restore specific items (e.g., subjects but not sessions) cannot do so.

**Acceptance criteria:**
- The restore dialog must show a list of boxes found in the backup with checkboxes to select which boxes to restore
- Provide "Select All" and "Deselect All" options
- Display a warning that selected boxes will be completely overwritten
- Consider an alternative merge strategy (skip duplicates by ID) instead of full clear-and-replace
- Unit tests must verify selective box restore

### M5: Question Bank has no "Add Question" button — read-only for review

**Files:**
- `lib/features/questions/presentation/question_bank_screen.dart` (entire screen)

**What's wrong:** The `QuestionBankScreen` allows browsing, searching, filtering, editing (text/explanation), and deleting questions. It has no "Add Question" or "Create Question" button. Users who want to contribute their own questions to the system cannot do so through any UI path. The only question generation paths are:
- Content pipeline (disabled by default — `generateQuestions: false` in upload screen)
- Tutor lessons (generates low-quality stubs with generic titles)

The product vision explicitly describes "expand questions through generated variants" but there's no way for users to add questions manually.

**Acceptance criteria:**
- Add a "Create Question" button (FAB or app bar action) on the Question Bank screen
- The creation form must support: question text, answer options (for single/multi choice), correct answer, question type selection, difficulty, topic assignment, explanation
- Consider also supporting an "Import Questions" option (CSV/JSON bulk import)
- Widget tests must verify the creation form renders and saves correctly

### M6: Source Detail question tap navigates to Question Bank without passing context

**Files:**
- `lib/features/ingestion/presentation/source_detail_screen.dart:434-436`

**What's wrong:** When a user taps a question in the Source Detail screen's "Generated Questions" list, the code calls:
```dart
onTap: () {
  Navigator.pushNamed(context, '/question-bank');
},
```
This navigates to the Question Bank screen **without any arguments**. The question bank loads from scratch — it doesn't scroll to, highlight, or filter for the specific question the user tapped. The user has to manually search or browse to find the question they were just looking at.

The `QuestionBankScreen` constructor (`question_bank_screen.dart:17`) accepts no arguments. The route registration (`app_router.dart:285-289`) passes no arguments.

**Acceptance criteria:**
- Add an optional `initialQuestionId` argument to `QuestionBankScreen`
- The screen must scroll to and highlight the specified question on load
- Update the route to pass the argument from `SourceDetailScreen`
- Widget test must verify that when called with `initialQuestionId`, the correct item is scrolled into view

---

## MINOR Findings

### m1: Question Bank is hard to discover — buried 2 levels deep in Settings

**Files:**
- `lib/features/settings/presentation/settings_screen.dart:87-88` (only entry point)
- `lib/features/questions/presentation/question_bank_screen.dart` (the screen)

**What's wrong:** The Question Bank is only accessible via Settings → Content Management → Question Bank (2 navigation steps from a non-obvious starting point). It has no entry point from:
- The **Practice tab** (where users naturally interact with questions)
- The **Subjects tab** (where users manage subject-related content)
- The **Dashboard** (which already shows question-related metrics)

Users who want to review, edit, or delete questions must know to look in Settings, which is not an intuitive location for question management.

**Acceptance criteria:**
- Add a "Question Bank" link in the Practice tab (e.g., in the app bar or as a card)
- OR add it to the subject detail screen's overflow menu
- OR surface it on the Dashboard as a "Manage Questions" card

### m2: No backup automation — data loss risk for local-only storage

**Files:**
- `lib/features/settings/presentation/settings_screen.dart:250-254` (manual backup only)

**What's wrong:** StudyKing stores all data locally in Hive boxes. There is no automatic backup mechanism, no scheduled backup, and no in-app reminder to perform backups. If the user's device is lost, damaged, or the app data is cleared, all study data is irrecoverable unless the user has manually exported a backup.

The `LocalDataNotice` dialog shown on first launch does warn about local storage, but it says "use the Export feature in Dashboard" — referring to the Dashboard's export (which is a progress report CSV, not a full data backup). The actual backup is in Settings → Backup & Restore, which is not mentioned in the onboarding.

**Acceptance criteria:**
- Add a setting for automatic periodic backups (e.g., daily, weekly)
- Add an in-app reminder at configurable intervals
- Consider cloud backup option (at minimum, export to app-specific documents directory)
- Update the `LocalDataNotice` to point to Settings → Backup & Restore, not Dashboard export

### m3: No notification when an AI task fails

**Files:**
- `lib/core/services/llm_task_manager.dart:102-111` (`failTask` only updates in-memory state)
- `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart` (screen only shows failures if user opens it)

**What's wrong:** When an AI task fails (e.g., content processing error, LLM API timeout), the `LlmTaskManager.failTask()` method updates the in-memory task status but does not trigger any user-facing notification. The user must manually navigate to Settings → AI Configuration → AI Task Monitor to discover failures. If the app is restarted, the failure record is lost entirely (M2).

**Acceptance criteria:**
- When `failTask()` is called, show a notification via `NotificationService` or a SnackBar if the app is in the foreground
- Add a badge or indicator to the Settings AI Task Monitor tile showing active/failed task counts
- If the task was user-triggered (e.g., content upload), surface the error in the originating screen's UI

### m4: Settings screen creates new DataBackupService and PlanAdapter instances each time

**Files:**
- `lib/features/settings/presentation/settings_screen.dart:623` (`final backupService = DataBackupService();`)
- `lib/features/settings/presentation/settings_screen.dart:665` (same — new instance on import)

**What's wrong:** The Settings screen creates new instances of `DataBackupService` on every export/import call. While this is functional (the service has no state), it bypasses dependency injection. The `DataBackupService` should be provided via a Riverpod provider or constructor injection for testability.

**Acceptance criteria:**
- Provide `DataBackupService` via a Riverpod provider
- Inject the service into SettingsScreen via `ref.read()` or constructor
- Update tests to use the provider override pattern

---

## Finding Count Summary

| Severity | Count |
|----------|-------|
| **BLOCKER** | 2 |
| **MAJOR** | 6 |
| **MINOR** | 4 |
| **PASS** | 3 (Content Library, Source Detail, Source Detail search) |

## Files Summary

```
lib/features/sessions/presentation/session_tracker_screen.dart     — B1 (orphaned route, 603 lines unreachable)
lib/features/sessions/presentation/session_history_screen.dart     — B2 (unreachable, only entry is through B1)
lib/features/dashboard/presentation/widgets/export_section.dart    — B2 (misleading "Session History" label), M1
lib/core/services/llm_task_manager.dart                            — M2 (in-memory only), m3 (no failure notification)
lib/core/services/llm_usage_meter.dart                             — M2 (in-memory only)
lib/core/providers/llm_providers.dart                              — M2 (no persistence provider)
lib/features/llm_tasks/presentation/llm_task_manager_screen.dart   — M2 (consumes in-memory data), m3
lib/features/settings/presentation/settings_screen.dart            — M3 (API key in backup), M4 (no selective restore), m2 (no automation), m4 (new instances)
lib/features/questions/presentation/question_bank_screen.dart       — M5 (no add button), M6 (no argument support)
lib/features/ingestion/presentation/source_detail_screen.dart      — M6 (navigates to question-bank without context)
lib/core/routes/app_router.dart                                    — B1, B2 (routes registered but no callers)
```
