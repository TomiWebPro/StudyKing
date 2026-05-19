# Dry-Run Usability Validator — Backup, Restore & Data Portability

**Scenario file:** `dry-run-test/scenario_backup_restore_data_portability.md`
**Date:** 2026-05-19
**Validator:** Codebase verification against actual source

---

## Scenario Summary

A student with 1+ month of StudyKing usage (two subjects, practice data, tutor sessions, focus mode, study plans, roadmaps, Mentor conversations, API key) wants to back up all data before reinstalling, export progress to share with a teacher, restore data after reinstallation, and configure auto-backup. The user discovers that:

1. The full-backup button ("Export Backup (full)") is a no-op due to a control-flow bug (`null` vs `null` check)
2. Auto-backup only triggers when the Settings screen initializes — not on app launch or periodically
3. Auto-backup files go to an inaccessible temp directory with a dead "View in Settings" button
4. 13+ Hive box types have no typed deserializer on restore
5. Two Hive boxes (`llmTasks`, `llmUsageRecords`) are silently excluded from all backups
6. Sign-out doesn't clear data, doesn't offer backup — just clears the API key
7. App version in About is a hardcoded translation string, not the real build version

---

## Findings by Severity

### BLOCKER — App crashes or user cannot proceed

#### Finding B1: "Export Backup (full)" button is a no-op due to null/boolean inversion

- **Files:**
  - `lib/features/settings/presentation/settings_screen.dart:764-781` — dialog button returns `null` for full export, then line 781 checks `includeSensitive == null` and returns early
  - `lib/features/settings/presentation/settings_screen.dart:773-776` — `FilledButton` labeled "Export Backup" returns `Navigator.pop(ctx, null)` on press
  - `lib/features/settings/presentation/settings_screen.dart:764-770` — "Exclude Sensitive Data" `TextButton` returns `Navigator.pop(ctx, true)` (works)
  - `lib/features/settings/presentation/settings_screen.dart:765-767` — "Cancel" returns `Navigator.pop(ctx, false)` (works)
- **Rationale:** The dialog has 3 buttons: Cancel (`false`), Exclude Sensitive Data (`true`), Export Backup full (`null`). The guard at line 781 — `if (includeSensitive == null || !mounted) return;` — treats the full-export option (`null`) the same as cancelled, causing an early return with zero user feedback. No snackbar, no file, no error. The primary/filled button is a dead end. The user who wants a full backup (with API keys) cannot create one through the intended UI path.
- **Acceptance criteria:** Invert the semantics OR change the return values. Options:
  - Change "Export Backup (full)" to return `false` and "Cancel" to return `null`: `if (includeSensitive == null)` means cancelled, `false` means full export, `true` means exclude sensitive.
  - Or keep current return values but change line 781 to: `if (includeSensitive == false || !mounted) return;` (treating `false` as cancel, `null` and `true` as proceed).
  - Must include unit test(s) covering all 3 dialog button paths.

#### Finding B2: Auto-backup only fires when Settings screen initializes

- **Files:**
  - `lib/features/settings/presentation/settings_screen.dart:57` — `initState` calls `_checkAutoBackup()` via `addPostFrameCallback`
  - `lib/features/settings/presentation/settings_screen.dart:66-86` — `_checkAutoBackup()` implementation — only runs when called, no timer, no background scheduling
  - `lib/main.dart:100-150` — app initialization only calls `_initHive()` and renders `MainScreen` — no periodic backup timer
- **Rationale:** The auto-backup check is tied to `_SettingsScreenState.initState()`. If the user configures weekly auto-backup and never opens the Settings screen again, the backup never runs. The user can use the app daily (Practice, Tutor, Mentor, Focus Mode) for weeks without triggering a single auto-backup. The EngagementScheduler at least runs a periodic timer (though in-process); the backup system has no timer at all outside the Settings screen lifecycle.
- **Acceptance criteria:** Move the auto-backup check to the app startup flow (in `main.dart` after `_initHive()`) so it fires every time the app launches, not just when Settings is opened. Consider adding a `Timer.periodic(Duration(days: 1))` in the app's root widget for daily checks regardless of screen state.

#### Finding B3: Auto-backup stores files in temp directory — user cannot retrieve them

- **Files:**
  - `lib/features/settings/presentation/settings_screen.dart:88-113` — `_performAutoBackup()` calls `backupService.exportAllData()` which saves to `getTemporaryDirectory()`
  - `lib/features/settings/services/data_backup_service.dart:23-24` — `getTemporaryDirectory()` used — system temp dir
  - `lib/features/settings/presentation/settings_screen.dart:103-106` — snackbar action `label: l10n.viewInSettings` with `onPressed: () {}` (empty callback)
- **Rationale:** Auto-backup files are written to `getTemporaryDirectory()` — a system temporary folder that can be cleaned by the OS at any time. The file path is not stored anywhere. The snackbar that appears on backup completion has a "View in Settings" action button, but its `onPressed` is an empty function (`() {}`). The user cannot retrieve, share, or manage their auto-backup files. The feature creates backups that exist for an indeterminate time and then vanish.
- **Acceptance criteria:** Either (a) save auto-backup files to a persistent, user-accessible location (e.g., app documents directory) and show a "Share" option in the snackbar, or (b) store the file path in the settings box and provide a "Last Auto-Backup" tile that lets users retrieve/share the file. Fix the `viewInSettings` action to actually navigate to Settings or show the backup file. Add auto-backup file management (view, share, delete).

---

### MAJOR — Feature is broken or misleading

#### Finding M1: 13+ Hive box types lack typed deserialization on restore

- **Files:**
  - `lib/features/settings/presentation/settings_screen.dart:1087-1126` — `_deserializeRecord()` only handles `subjects`, `topics`, `questions`, `sources`, `lessons`, `sessionsTyped`, `masteryStates`, `questionMasteryStates`, `questionEvaluations`, `learningPlans`, `planAdherence`, `planAdherenceMetrics`, `masteryImprovementMetrics`, `conversations`, `tutorSessions`, `topicDependencies`, `lessonBlocks` — 17 types
  - Boxes NOT deserialized (fall through to `default: return json`): `answers`, `attempts`, `badges`, `engagementNudges`, `focusSessions`, `pendingActions`, `progress`, `sessions` (legacy), `tasks`, `settings`, `profile`, `studentAvailability` — 12 types
  - `lib/features/settings/presentation/settings_screen.dart:994-1040` — `_collectAllBoxData()` lists 28 boxes but HiveBoxNames defines 35
  - `lib/core/data/hive_box_names.dart:35` — `llmTasks`, `llmUsageRecords` not in collection list
- **Rationale:** During restore, 12+ box types are stored as raw `Map<String, dynamic>` instead of their typed Hive model. For boxes opened with a generic type parameter (e.g., `Hive.openBox<Session>`), raw maps may fail to load or lose type-specific behavior (field defaults, computed getters). The `llmTasks` and `llmUsageRecords` boxes (tracking LLM token usage and task management) are excluded from `_collectAllBoxData()` entirely — they are lost in any backup/restore cycle. A user who backs up and restores will permanently lose their LLM usage tracking history.
- **Acceptance criteria:** Add `fromJson()` deserialization for all remaining box types, or confirm that raw-map storage is acceptable (add `// ok: stored as raw map` comments). Add `llmTasks` and `llmUsageRecords` to `_collectAllBoxData()`. Add round-trip tests for each box type verifying that `toJson()` → `fromJson()` → `toJson()` yields identical output.

#### Finding M2: No studentId/UUID reconciliation on restore

- **Files:**
  - `lib/core/services/student_id_service.dart:27` — generates UUID on first install, persists it
  - `lib/features/settings/presentation/settings_screen.dart:1054-1085` — `_writeBoxData()` / `_writeBoxDataMerge()` — writes all records with their original IDs
  - `lib/features/settings/presentation/settings_screen.dart:847-929` — `_importBackup()` — no studentId handling anywhere in the restore flow
- **Rationale:** When a user reinstalls the app, `StudentIdService` generates a NEW UUID. The backup file contains ALL records with the OLD UUID embedded in `studentId` fields across `attempts`, `sessionsTyped`, `tutorSessions`, `conversations`, etc. After restore, the old data still references the old UUID. The `profile` box contains the old UUID. Queries that filter by `studentId` will return empty for the new UUID, making all restored data invisible until the user somehow discovers the mismatch. There is zero user-facing indication of this issue.
- **Acceptance criteria:** On restore, either (a) detect and warn about UUID mismatch ("This backup was created on a different device/install. Your current student ID will be updated to match the backup."), or (b) provide an option to rewrite all `studentId` fields in restored records to match the current UUID. Store the backup's studentId in the restore summary dialog.

#### Finding M3: No post-restore state refresh

- **Files:**
  - `lib/features/settings/presentation/settings_screen.dart:912-921` — after `_writeBoxDataMerge()` or `_writeBoxData()`, only a success snackbar is shown
  - `lib/features/settings/presentation/settings_screen.dart:847-929` — `_importBackup()` — no `ref.invalidate()` calls
- **Rationale:** After a successful restore, all Hive boxes have new/updated data, but all Riverpod providers still hold their pre-restore state. The user sees the old data (or empty state) on every screen until they restart the app. No UI refresh is triggered. The success snackbar misleadingly implies the restore is complete, but the user navigates to the Dashboard to find nothing changed.
- **Acceptance criteria:** After restore completes, call `ref.invalidate()` for all data-dependent providers, or at minimum show a dialog: "Data restored successfully. Please restart the app to see your data." Better yet, trigger a hot restart or invalidate key providers.

#### Finding M4: No backup size preview or record count summary

- **Files:**
  - `lib/features/settings/presentation/settings_screen.dart:742-818` — `_exportBackup()` — the sensitive-data dialog says nothing about what data is in the backup
  - `lib/features/settings/services/data_backup_service.dart:10-31` — `exportAllData()` — returns only the file path, no metadata
- **Rationale:** The user sees: "The backup contains sensitive data. You can choose to exclude it." They have no idea how much data is included — how many subjects, questions, sessions, conversations. A user with 50MB of data might be surprised when the share sheet shows a huge file. A user with empty data might not realize their backup is empty. No size estimation, no record count, no "what's included" preview.
- **Acceptance criteria:** Before showing the share sheet, display a summary dialog: "Backup contains: 2 subjects, 240 questions, 800 attempts, 15 sessions, 4 conversations. File size: ~1.2 MB." Either compute this from `boxData` before passing to `exportAllData()` or have `exportAllData()` return a result with metadata (file size, record counts).

#### Finding M5: No backup encryption — API keys in plaintext

- **Files:**
  - `lib/features/settings/services/data_backup_service.dart:15-19` — backup is plain JSON with `JsonEncoder.withIndent`
  - `lib/features/settings/presentation/settings_screen.dart:783-789` — full export (if the bug were fixed) includes the `settings` box with plaintext API key
- **Rationale:** If the full-backup option is used (or the B1 bug is fixed), the backup JSON file contains all API keys in plaintext. The file is shared via `Share.shareXFiles`, which means it goes through the system share sheet — potentially uploaded to cloud storage, emailed, sent via messaging apps. There is no encryption, no password protection, no warning that the backup contains credentials. For a local-only app where the API key is the only sensitive credential, this is a significant data leakage risk.
- **Acceptance criteria:** At minimum, add a clear warning dialog when including the settings box: "Your API keys will be stored in plaintext in this backup file. Anyone with access to this file can use your API keys." Consider implementing optional password-based encryption for backup files.

#### Finding M6: Sign-out doesn't clear data, doesn't offer backup — clears only API key

- **Files:**
  - `lib/features/settings/presentation/settings_screen.dart:1197-1221` — `_showSignOutDialog()` — only clears `apiKey`, `selectedModel`, and calls `Navigator.popUntil`
  - `lib/l10n/generated/app_localizations_en.dart` — `signOut` string implies account-level action
- **Rationale:** The "Sign Out" option is labeled and styled like an account-level action (red text, icon is `Icons.logout`). But it only clears the API key and selected model. All study data (subjects, questions, attempts, sessions, conversations, plans) remains untouched. There is no backup-first prompt. There is no actual user account system — `StudentIdService` uses a fixed UUID. The feature is a misleadingly labeled "clear API key" action. A user who signs out intending to hand the device to someone else leaves all their personal study data accessible.
- **Acceptance criteria:** Either (a) rename to "Clear API Key" and add a description: "This will remove your API key. Your study data will be preserved.", or (b) implement true sign-out that offers backup first, then clears all local data. Add a warning if study data exists: "You have study data. Would you like to back it up first?"

#### Finding M7: App version in About dialog is a hardcoded translation string

- **Files:**
  - `lib/features/settings/presentation/settings_screen.dart:1225-1235` — `_showAboutDialog()` calls `l10n.aboutVersion` for the version parameter
  - `lib/l10n/generated/app_localizations_en.dart:4636` — `String get aboutVersion => '1.0.0';`
  - `lib/l10n/generated/app_localizations_es.dart:4683` — `String get aboutVersion => '1.0.0';`
- **Rationale:** The displayed version (`"1.0.0"`) is a hardcoded string in ARB translation files. It does NOT change when the app is built at a different version. If the app's `pubspec.yaml` version is bumped to `1.2.0`, the About dialog still shows `"1.0.0"`. The `package_info_plus` package is available in the dependency tree but never used for version display.
- **Acceptance criteria:** Use `package_info_plus` (or `Platform.version` on web) to read the actual build version from the platform. Fall back to `pubspec.yaml` version via `PackageInfo.fromPlatform()`. The translation strings should be used only for labels, not version values.

#### Finding M8: Two LLM-related Hive boxes silently excluded from backup

- **Files:**
  - `lib/features/settings/presentation/settings_screen.dart:994-1040` — `_collectAllBoxData()` iterates 28 box names
  - `lib/core/data/hive_box_names.dart:34-35` — `llmTasks`, `llmUsageRecords` constants defined
  - `lib/core/services/llm_task_manager.dart:97` — opens `HiveBoxNames.llmTasks`
  - `lib/core/services/llm_usage_meter.dart:56` — opens `HiveBoxNames.llmUsageRecords`
- **Rationale:** The `llmTasks` and `llmUsageRecords` boxes store LLM task execution history and token usage records. These are active boxes that maintain state across app restarts. They are not included in `_collectAllBoxData()` and therefore are never backed up. On a full backup/restore cycle, this data is permanently lost. A user relying on the LLM usage meter for cost tracking will see their history reset to zero after restore.
- **Acceptance criteria:** Add `llmTasks` and `llmUsageRecords` to the `_collectAllBoxData()` box list. Add corresponding entries to `_deserializeRecord()` and `_boxDisplayName()`.

#### Finding M9: Export confirmation dialogs give no information about what will be exported

- **Files:**
  - `lib/features/dashboard/presentation/widgets/export_section.dart:103-123` — `_showExportConfirmation()` — generic title + description, same for all formats
  - `lib/features/dashboard/presentation/widgets/export_section.dart:127-131` — CSV export passes `l10n.exportCsv` as both title and description content
- **Rationale:** Before exporting, the user sees a confirmation dialog with the export format name and "Comprehensive report exported" — no information about what data is included. CSV, PDF, and JSON exports contain different data (CSV has attempt-level detail, PDF has formatted tables, JSON has structured data), but the dialog is identical for all three. The user has no way to know which format contains what they need.
- **Acceptance criteria:** Each export format should show a brief description of its contents: "CSV: overall stats, topic mastery, all attempts (one per row), weekly trend, badges." — "PDF: formatted report with tables, charts, and mastery breakdowns suitable for printing." — "JSON: structured data export for programmatic analysis."

#### Finding M10: ProgressExportService bypasses dependency injection

- **Files:**
  - `lib/core/services/progress_export_service.dart:23-37` — default constructor creates `AttemptRepository()` and `MasteryGraphService()` directly
- **Rationale:** The default constructor instantiates raw repository objects (`AttemptRepository()`, `MasteryGraphService()`) instead of using provider-injected instances. If these repositories have constructor dependencies (e.g., `AttemptRepository` requires a `Hive` box that isn't initialized at construction time), the export could fail. This also breaks testability — tests must rely on the default internal fakes rather than injected fakes.
- **Acceptance criteria:** The Dashboard section should pass the already-available `tracker` and `instrumentation` objects to the export service, or the export service should obtain them from providers. Make all constructor parameters required (remove defaults) or obtain them from Riverpod's `ref.read()`.

---

### MINOR — UX friction

#### Finding N1: Backup is only discoverable via Settings — no Dashboard shortcut

- **Files:**
  - `lib/features/settings/presentation/settings_screen.dart:315-322` — backup section only in Settings
  - `lib/features/dashboard/presentation/widgets/export_section.dart:27-100` — Dashboard Export section has no backup option
- **Rationale:** Users looking for "how do I back up my data?" will naturally look at the Dashboard's Export section, which has "CSV", "PDF", "JSON" labels. These are progress reports, not full data backups. The actual backup feature is two navigation levels deep in Settings. Users may export a progress report thinking it's a backup, then later lose their data on reinstall.
- **Acceptance criteria:** Add a "Backup All Data" card or button to the Dashboard's Export section, or add a Settings shortcut tile. At minimum, add a note in the Export section: "For a full data backup (subjects, questions, settings), go to Settings → Backup & Restore."

#### Finding N2: Two CSV buttons with different scope but similar labels

- **Files:**
  - `lib/features/dashboard/presentation/widgets/export_section.dart:41-44` — `_exportCSV` — comprehensive CSV with stats + mastery + attempts + trend + badges
  - `lib/features/dashboard/presentation/widgets/export_section.dart:61-70` — `_exportProgressCSV` — different CSV via `StudyProgressTracker.exportProgressCSV()`
- **Rationale:** Both buttons say "Export CSV" (the smaller one says "Progress CSV"). A user might not understand the difference. Exporting both produces two different CSV formats, which is confusing for a user who expects a single "Export as CSV" action.
- **Acceptance criteria:** Rename the smaller "Progress CSV" button to clearly distinguish its content: "Stats CSV" or "Summary CSV". Alternatively, merge the two CSV exports into one comprehensive CSV and remove the duplicate.

#### Finding N3: Auto-backup has no manual trigger in its dialog

- **Files:**
  - `lib/features/settings/presentation/settings_screen.dart:611-661` — `_showAutoBackupDialog()` — only interval selection options
- **Rationale:** The auto-backup dialog only lets the user choose an interval (Never/Daily/Weekly). There's no "Back Up Now" button. To manually trigger a backup, the user must leave the dialog, find the "Export Backup" tile, and use that. After configuring auto-backup, the natural next action would be to trigger the first backup immediately.
- **Acceptance criteria:** Add a "Back Up Now" button at the top of the auto-backup bottom sheet that runs `_performAutoBackup()` immediately. Show a progress indicator and success/failure feedback within the sheet.

#### Finding N4: Export section is at the very bottom of a long Dashboard scroll

- **Files:**
  - `lib/features/dashboard/presentation/screens/dashboard_screen.dart:138-155` — ExportSection is the last widget in the Dashboard column
- **Rationale:** The Dashboard has ~10+ cards of stats, charts, and metrics before the Export section. On a phone, users must scroll past all 10+ cards to find export. Most users won't scroll that far. The export functionality is functionally invisible for casual users.
- **Acceptance criteria:** Add an "Export" icon button in the Dashboard's AppBar that scrolls to or opens the export section directly. Or move the export to a more prominent position.

#### Finding N5: Backup file has no human-readable description in the share sheet

- **Files:**
  - `lib/features/settings/presentation/settings_screen.dart:795-797` — `Share.shareXFiles([XFile(file.path)], text: 'StudyKing Backup')`
- **Rationale:** When sharing the backup file, the share sheet shows "StudyKing Backup" as the text. There's no context about when the backup was created, how large it is, or what data it contains. If a user has multiple backup files, they can't distinguish them without opening each.
- **Acceptance criteria:** Include the export date and record count in the share text: "StudyKing Backup — 2026-05-19 — 2 subjects, 240 questions, 800 attempts (1.2 MB)". Derive this from the backup data before exporting.

#### Finding N6: Sign-out confirmation doesn't mention what will be cleared

- **Files:**
  - `lib/features/settings/presentation/settings_screen.dart:1199-1213` — `_showSignOutDialog()` content is just `l10n.signOutConfirmation` with no specifics
- **Rationale:** The sign-out confirmation says "Are you sure you want to sign out?" but doesn't explain what happens: "Your API key and selected model will be cleared. Your study data will be preserved." The user might think sign-out deletes everything or does nothing.
- **Acceptance criteria:** The confirmation dialog should list exactly what will be cleared and what will be preserved.
