# Dry-Run Scenario: Backing Up, Restoring, and Exporting Data — The Complete Data Portability Journey

## Persona

I'm a student who has been using StudyKing for over a month. I have 2 subjects (IB Chemistry, IB Physics), 15+ practice sessions, 4 AI tutor lessons, 8 focus mode sessions, a 90-day study plan with adherence records, earned badges, several roadmaps, and conversations with the Mentor. I have an API key configured. Now I want to:

1. **Back up my data** before reinstalling the app
2. **Export my progress** to share with my teacher
3. **Restore my data** after reinstallation
4. **Set up automatic backups** so I never lose progress
5. Understand **what data is included** in each export option

---

## Step 1: Finding the Backup Feature — Two Levels Deep in Settings

I open the app and look for a "Backup" option. I check each tab:

- **Dashboard** — Shows study stats, charts, mastery overview. No "Backup" section. There IS an "Export" section at the very bottom with CSV, PDF, JSON buttons — but those are *progress reports* (what I've achieved), not *full data backups*.
- **Subjects** — No backup option.
- **Practice** — No backup option.
- **Mentor** — Chat interface. No backup option.
- **Focus Mode** — Timer interface. No backup option.
- **Settings** — I scroll down. I find a section titled "Backup & Restore" with three options:
  - **Export Backup** — "Export all data to a file"
  - **Import Backup** — "Restore from a backup file"
  - **Auto Backup** — "Schedule automatic backups"

**What I expect:** Backup/restore is an important data safety feature. I should be able to find it from the Dashboard, or at minimum it should have a prominent place in Settings.

**What actually happens:** The only path to backup is Settings → Backup & Restore, 2 levels deep from the main screen. The Dashboard's Export section is for *progress reports* (not full data), and there's no mention of backup anywhere else.

**Verdict (PARTIAL):** The backup feature exists and works, but it's only discoverable through Settings. The Dashboard's Export section looks like a backup feature but is actually progress reporting. A user looking for "I need to save all my data" might try Dashboard Export first and get confused.

---

## Step 2: Starting a Full Backup — The Sensitive Data Dialog

I tap "Export Backup." A dialog appears:

> **Title:** "Export Backup"
> **Text:** "The backup contains sensitive data. You can choose to exclude it."
> **Subtitle:** "Sensitive data such as API keys will be excluded from the backup if you choose this option."
> **Buttons:** Cancel | Exclude Sensitive Data | Export Backup (full)

**What I see:** I want a full backup including everything before reinstalling. I tap "Export Backup" (the primary filled button, which seems like the recommended action).

**What actually happens:**

Nothing. The dialog closes. No backup is created. No error message. No snackbar. No file sharing dialog. **The primary button is a no-op.**

I try again. I tap "Exclude Sensitive Data" instead. This time, a file sharing dialog opens with a JSON file. The backup works.

**What the code does:** The dialog's three buttons return:
- Cancel → `Navigator.pop(ctx, false)` — cancelled correctly
- Exclude Sensitive Data → `Navigator.pop(ctx, true)` — works correctly
- Export Backup (full) → `Navigator.pop(ctx, null)` — **BUG**

At `settings_screen.dart:781`:
```dart
if (includeSensitive == null || !mounted) return;
```

When the user taps "Export Backup (full)", `includeSensitive` is `null`, which triggers an early return. The full-export code at lines 783-817 **never executes**. The primary button on the dialog is a dead end with zero user feedback.

**Verdict (BLOCKER FAIL):** The "Export Backup (full)" option is broken. Tapping the primary button silently does nothing. Only the "Exclude Sensitive Data" option works. The user wanting a full backup with API keys must discover this workaround or lose their API configuration in the backup.

---

## Step 3: Inspecting the Backup File — Plain JSON with All Data

The backup file appears in the share dialog as `studyking_backup.json`. I open it to see what's inside.

**What I expect:** A well-structured backup format that I could manually inspect if needed. Maybe compressed or at least clearly organized.

**What I see:** A plain, human-readable JSON file with:
```json
{
  "version": 1,
  "exportedAt": "2026-05-19T10:30:00.000000",
  "boxes": {
    "subjects": [ ... ],
    "topics": [ ... ],
    "questions": [ ... ],
    ...
    "settings": [ ... ]  // if I chose "Exclude Sensitive Data", this box is removed
  }
}
```

**Observations:**

1. **No compression** — For a heavy user with conversation history, question banks, and adherence records, this JSON file can be multiple megabytes. The whole file is sent via `Share.shareXFiles` as-is, with no compression.

2. **No encryption** — The backup is plain JSON. Anyone who gets the file can read all data including (if the user chose full backup) API keys in plaintext. There is no encryption option, no password protection, nothing.

3. **No size preview** — Before sharing, the app doesn't show how big the file is. The user might be surprised when the share sheet shows a 50MB JSON file.

4. **No record count summary** — The dialog just asks to "include sensitive data" without telling the user: "This backup contains 15 subjects, 240 questions, 800 attempts, 4 conversations..." The user has no idea what's in their backup.

5. **Missing boxes** — The `_collectAllBoxData()` method iterates 28 boxes but the actual HiveBoxNames class defines 35 constants. Missing: `llmTasks`, `llmUsageRecords`. If the user has LLM task history and usage records, those are silently excluded from backup with no warning.

**Verdict (MAJOR FAIL):** The backup is plain JSON with no encryption, no compression, no size preview, no record count summary. Two Hive boxes (`llmTasks`, `llmUsageRecords`) are silently excluded. API keys in plaintext if included. The missing-box bug means LLM usage tracking data is permanently lost on a restore-from-backup cycle.

---

## Step 4: Reinstalling the App — The Restore Process

I reinstall StudyKing (or switch devices). I open the app for the first time, go through onboarding, create a dummy subject to get to the main screen, then navigate to Settings → Backup & Restore → Import Backup.

**What I expect:** A straightforward restore process where I pick my backup file and get my data back.

**What actually happens:**

1. I tap "Import Backup." A file picker opens filtered to `.json` files.
2. I select my `studyking_backup.json` file.
3. The `DataBackupService.restoreData()` validates the format (version, exportedAt, boxes fields must exist). ✓
4. If the format is invalid, a snackbar shows: "Invalid backup file: ..." ✓
5. A **Selective Restore Dialog** appears listing all boxes in the backup file with checkboxes (all checked by default).
6. I can select/deselect which boxes to restore. ✓
7. After selecting boxes, I choose **Merge** (skip existing keys) or **Overwrite** (clear box, then write). ✓
8. The restore completes and a success snackbar appears. ✓

**But there are critical problems:**

**Problem 1 — No restore confirmation summary.** Before committing to restore, the dialog shows "Selected boxes will be overwritten/merged." It does NOT show: how many records per box, what the current state is vs. what will be replaced, or any preview of the data being restored.

**Problem 2 — Deserialization gaps.** The `_deserializeRecord()` method only handles 15 box types. The other 13+ boxes in the backup fall through to `default: return json;` — they are stored as raw `Map<String, dynamic>` objects rather than typed Hive objects. These boxes include:
- `attempts` — core practice data
- `badges` — earned gamification data
- `focusSessions` — timer session records
- `engagementNudges` — nudge history
- `pendingActions` — pending plan actions
- `studentAvailability` — scheduling preferences
- `answers` — stored answer records
- `progress` — progress tracking data
- `sessions` — legacy sessions (non-typed)
- `tasks` — task data
- `settings` — settings + API key (only if included)
- `profile` — user profile

If a Hive box expects typed objects (e.g., `Hive.openBox<Session>(HiveBoxNames.sessionsTyped)`) and receives a raw map, the `fromJson()` flow still works because Hive adapters use `fromJson()` internally. But boxes opened without a generic type parameter will store raw maps, which may not be compatible with code that expects HiveObject subclasses.

**Problem 3 — No "restore from fresh install" guidance.** After a fresh install, Hive boxes may not be open yet. But the init in `main.dart` calls `_initHive()` before the UI renders, so boxes should be open. However, if the user restores from a backup that has a different `studentId` (from the old install), there could be a UUID mismatch. The `StudentIdService` generates a new UUID on first launch — the old data still has the old studentId embedded in every record. The backup includes ALL boxes including the `profile` box which has the old studentId. When restored, the old profile is imported, but the current `StudentIdService` still holds the new UUID in memory. This mismatch could cause data queries to return empty results.

**Problem 4 — No post-restore state refresh.** After importing, the success snackbar is shown but **the app doesn't refresh its state**. The user sees the Settings screen with the old data (or empty state for first-run boxes). They need to restart the app or manually navigate to see the restored data. No `ref.invalidate()` or state refresh is triggered.

**Verdict (MAJOR FAIL):** The restore flow works for simple cases but has deserialization gaps affecting 13+ important data types, no UUID mismatch handling, no post-restore state refresh, and no preview of what's being restored. The data integrity of a full restore cycle is not guaranteed.

---

## Step 5: Configuring Auto-Backup — Runs Only When Settings Is Open

I go back to Settings → Backup & Restore → Auto Backup.

**What I expect:** The app backs up my data automatically on a schedule (daily or weekly) regardless of whether I open the app. The backup file is stored somewhere accessible.

**What actually happens:**

The auto-backup dialog shows options: Never, Daily, Weekly. I choose Weekly. The dialog closes.

**Behind the scenes:**

1. The interval is stored in the `settings` Hive box as `autoBackupIntervalDays: 7`.
2. The **only trigger** for auto-backup is when the Settings screen is initialized — in `_SettingsScreenState.initState()` at line 57:
   ```dart
   WidgetsBinding.instance.addPostFrameCallback((_) => _checkAutoBackup());
   ```
3. `_checkAutoBackup()` reads the interval and last backup date, checks if the interval has elapsed, and if so, calls `_performAutoBackup()`.

**Critical problems:**

**Problem 1 — Auto-backup only runs when Settings is init'd.** If I never open the Settings screen, auto-backup never runs. The app can be open for weeks (using Mentor, Practice, Focus Mode) but the check only happens when `_SettingsScreenState` constructs. If I set up auto-backup and then only use the Dashboard and Practice tabs, my data is never auto-backed up.

**Problem 2 — Auto-backup saves to temp directory with no path stored.** The exported file goes to `getTemporaryDirectory()` — a system temp folder that can be cleaned at any time. The file path is not stored anywhere. The user gets a snackbar saying "Backup completed" with a "View in Settings" action button — which does nothing (`onPressed: () {}` is an empty function at `settings_screen.dart:105`). The user cannot retrieve or share the auto-backup file.

**Problem 3 — Missed backups are not accumulated.** If the app was closed for 2 weeks, the auto-backup check fires once (on first Settings screen open) and catches up. But the files from the missed weeks are gone forever — there's no "you missed X backups" summary or retroactive backfill.

**Problem 4 — No backup file management.** There's no list of past auto-backups, no way to manually trigger a backup from the auto-backup dialog, no way to see when the last backup was created (other than the date string in the dialog), and no way to delete old backups.

**Verdict (MAJOR FAIL):** Auto-backup only runs when the Settings screen is opened. It stores files in a temp directory with no user access. The "View in Settings" button is a no-op. No backup history or management exists.

---

## Step 6: Exporting Progress Reports from the Dashboard — What's Available

I want to share my study progress with my Physics teacher. I go to the Dashboard and scroll to the bottom Export section.

**What I see:**
- **CSV, PDF, JSON** — Three "comprehensive report" buttons (each triggers a confirmation dialog before exporting)
- **Progress CSV, Session History, Instrumentation** — Three smaller buttons below

**What I notice about the Dashboard export:**

1. **CSV button is labeled "Export CSV"** — but there are TWO CSV exports. The main "CSV" button exports the comprehensive report. The smaller "Progress CSV" button exports a different format via `StudyProgressTracker.exportProgressCSV()`. A user might not understand the difference.

2. **Session History now navigates correctly** ✓ (This was fixed or the earlier scenario was based on an older version — it now navigates to `SessionHistoryScreen` at `export_section.dart:74`).

3. **JSON export includes studentId in plaintext** — The JSON output contains `"studentId": "uuid-here"` at the top level. If shared, this exposes the internal student identifier.

4. **No "What's included?" info** — Before exporting, the confirmation dialog just says "Comprehensive report exported" for all formats. The user has no way to know what data is in the CSV vs. PDF vs. JSON without exporting all three and comparing.

5. **ProgressExportService creates new instances of repositories** — At `progress_export_service.dart:31`:
   ```dart
   attemptRepo: AttemptRepository(),
   ```
   The default constructor creates `AttemptRepository()` directly rather than using dependency injection. This means if the repository has constructor dependencies (like a Hive box), the export might fail silently or use uninitialized state.

**Verdict (PARTIAL):** The Dashboard export section is functional but confusing (two CSV exports with different data), has no "what's included" preview, and creates raw repository instances bypassing DI.

---

## Step 7: Session History Export — The Most Complete Export

I navigate from Dashboard Export → Session History (which correctly navigates now). The session history screen has comprehensive export capabilities.

**What I see:**
- A list of all my study sessions ✓
- AppBar actions for: **Share CSV**, **Share JSON**, **Share PDF** ✓
- Session-specific export with proper formatting ✓

**What actually happens:**

The Session Export Service (`sessions_to_csv.dart`, `sessions_to_json.dart`, `sessions_to_pdf.dart`) processes sessions correctly. The CSV export has proper escaping. The PDF is formatted with locale-aware numbers. Everything works end-to-end. ✓

**But the path is confusing:** To get here, I navigated: Dashboard → scroll to bottom → Export section → Session History button → Session History screen → tap share button. That's 5 steps and a long scroll to find the most complete export. There's no direct "export all session data" button on the Dashboard.

**Verdict (PASS):** Session history export works correctly with multiple formats. But it's buried behind a navigation step from the Dashboard.

---

## Step 8: The About Dialog — Version Info Is a Translated String

I check the "About" section in Settings to see my app version.

**What I see:** The About dialog uses Flutter's standard `AboutDialog` widget with:
- `applicationName: l10n.aboutApplicationName` — translated
- `applicationVersion: l10n.aboutVersion` — translated
- `applicationLegalese: l10n.aboutLegalese` — translated

**What the code shows:** All three values come from ARB translation files, NOT from `package_info_plus` or `pubspec.yaml`:

```dart
// In app_localizations_en.dart:
String get aboutVersion => '1.0.0';
String get aboutApplicationName => 'StudyKing';
String get aboutLegalese => '© 2026 StudyKing';
```

The version string `"1.0.0"` is hardcoded in translations — it will display the same value regardless of the actual build version. If I install version 1.2.0, the About dialog still says "1.0.0". The `package_info_plus` package is not used anywhere in the app.

**Verdict (MAJOR FAIL):** The app version displayed in About is a hardcoded translation string, not the actual build version. It will always show "1.0.0" regardless of the real app version.

---

## Step 9: Sign Out — What Happens to My Data?

I want to clear my data and start fresh. I go to Settings → About section → "Sign Out" (red text).

**What I expect:** Clear all local data, reset the app to first-launch state. Maybe offer a backup option before clearing.

**What actually happens:**

The sign-out dialog asks for confirmation. I confirm. The code at `settings_screen.dart:1215-1220`:
```dart
ref.read(apiKeyProvider.notifier).state = '';
ref.read(selectedModelProvider.notifier).state = '';
ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(apiKey: '', selectedModel: ''));
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.signOutComplete)));
Navigator.of(context).popUntil((route) => route.isFirst);
```

**Problems:**

1. **Sign-out only clears API key and model** — It does NOT clear subjects, questions, attempts, sessions, plans, or any other data. The user's study data remains. If I sign out and sign back in, all my old data is still there.

2. **No backup prompt** — Before clearing, there's no "Would you like to back up your data first?" prompt. The user who signs out to hand the device to someone else will leave all their study data accessible.

3. **Sign-out is misnamed** — This is really "clear API key and model," not a true sign-out. Since there's no multi-user system (StudentIdService generates a fixed UUID), "signing out" doesn't change the student identity. The user can't switch accounts or profiles.

**Verdict (MAJOR FAIL):** Sign-out doesn't clear study data, doesn't offer backup, and doesn't change user identity. It's a misleadingly named "clear API key" function.

---

## Summary of Expectations vs Reality

| # | Expectation | Reality | Status |
|---|---|---|---|
| 1 | Backup feature is discoverable from Dashboard or main nav | Only in Settings → Backup & Restore, 2 levels deep. Dashboard's "Export" is progress reports, not data backup. | PARTIAL |
| 2 | "Export Backup (full)" button exports all data including API keys | `includeSensitive == null` triggers early return — primary button is a no-op | **FAIL (BLOCKER)** |
| 3 | Backup file is encrypted or at minimum warns about plaintext API keys | Plain JSON, no encryption. API keys in plaintext if included. Warning dialog exists but is misleading due to bug #2. | FAIL (MAJOR) |
| 4 | Backup shows file size and record count before sharing | No size preview, no record count, no "what's included" summary | FAIL (MAJOR) |
| 5 | All Hive boxes are included in backup | `llmTasks`, `llmUsageRecords` are silently excluded from `_collectAllBoxData()` | FAIL (MAJOR) |
| 6 | Restored data maintains full type fidelity | 13+ box types fall through to `default: return json;` — stored as raw maps, not typed objects | FAIL (MAJOR) |
| 7 | Restore handles UUID mismatch between old backup and new install | No studentId reconciliation — old data may have mismatched UUIDs | FAIL (MAJOR) |
| 8 | Post-restore state refresh is triggered | No `ref.invalidate()` after restore — user must restart app | FAIL (MAJOR) |
| 9 | Auto-backup runs on schedule regardless of which screen is open | Only triggered on Settings screen `initState()`. Never runs if user doesn't open Settings. | **FAIL (BLOCKER)** |
| 10 | Auto-backup file is accessible to the user | Saved to temp directory with no path stored. "View in Settings" button is a no-op. | **FAIL (BLOCKER)** |
| 11 | Missed auto-backups accumulate and catch up | Only one check fires on next Settings open. No backlog accumulation. | FAIL (MAJOR) |
| 12 | Auto-backup can be manually triggered from the dialog | No manual trigger in auto-backup dialog. | FAIL (MINOR) |
| 13 | Dashboard CSV export is clearly distinguishable from progress CSV | Two "CSV" export buttons with different data but similar labels | PARTIAL |
| 14 | Export confirmation shows what data is included | Generic "Comprehensive report exported" text for all formats | FAIL (MAJOR) |
| 15 | Session history export is discoverable | Works correctly but requires 5-step navigation from Dashboard | PARTIAL |
| 16 | App version in About shows actual build version | Hardcoded `"1.0.0"` in translation strings — always shows same value | FAIL (MAJOR) |
| 17 | Sign-out clears all user data or offers backup | Only clears API key and model — study data remains | FAIL (MAJOR) |
| 18 | Sign-out allows switching user accounts | No multi-user support. Sign-out just clears the API key. | FAIL (MAJOR) |
| 19 | `ProgressExportService` uses dependency injection for repositories | Default constructor creates `AttemptRepository()` directly | FAIL (MINOR) |
| 20 | JSON export doesn't expose internal identifiers | StudentId is in plaintext in JSON output | FAIL (MINOR) |

---

## Re-Validation Results (2026-05-20) — Corrected

Each step was traced against the actual source code at `/home/tomi/StudyKing/lib/`. The previous validation section contained several factual errors (marked **ERR** below). This corrected pass re-verifies every claim.

### Step 1: Finding the Backup Feature
**Status: PARTIAL**
- Code references: `export_section.dart:115-127` (Dashboard button), `settings_screen.dart:341-347` (Settings section)
- The Dashboard export section has a backup icon (`Icons.backup`) with label `l10n.exportBackup` that directly calls `_exportBackupDirect()` — it performs a full backup immediately from the Dashboard, not just a nav link. This is better than a navigation link. ✓
- However, the Dashboard backup shortcut skips the sensitive data dialog entirely. It uses generic `_showExportConfirmation()` with `l10n.exportCsvDetail` as detail text (wrong label for backup). It also skips the backup summary dialog (record count preview, size preview).
- The Settings path remains the proper full-featured path with all dialogs.

### Step 2: Starting a Full Backup — The Sensitive Data Dialog
**Status: COMPLETED**
- Code reference: `settings_screen.dart:915-986`
- Buttons: Cancel → `null` → early return ✓ | Exclude → `true` → settings box removed ✓ | Full → `false` → proceeds ✓
- Second confirmation dialog for full backup at lines 997-1015. ✓
- Backup summary dialog at lines 1036-1107 with per-box counts and total records. ✓
- File size computed at lines 1113-1123 and included in share text at line 1128. ✓

### Step 3: Inspecting the Backup File
**Status: COMPLETED**
- **Size preview** — EXISTS at `settings_screen.dart:1113-1123` ✓
- **Record count summary** — EXISTS at `settings_screen.dart:1024-1035` ✓
- **Missing boxes** — ALL 37 boxes defined in `HiveBoxNames` are included via `HiveBoxNames.allBackupBoxes` in `data_backup_service.dart:16-30`. **ERR**: The previous validation claimed 5 boxes (`agentMemory`, `examResults`, `studentId`, `dashboardLayoutPrefs`, `dbVersion`) are excluded — this is INCORRECT. All 37 are included.
- **Compression** — EXISTS. `DataBackupService.exportAllData()` defaults `compress = true` (`data_backup_service.dart:46`). Uses `GZipEncoder` from the `archive` package. Output file extension is `.skbak`. **ERR**: The previous validation claimed "No compression — Still true" — this is INCORRECT.
- **Encryption** — Not present. API keys in plaintext if full backup chosen. This is a known limitation.

### Step 4: Reinstalling the App — The Restore Process
**Status: COMPLETED**
- Code references: `settings_screen.dart:1198-1361` (import), `1465-1537` (deserialization)
- **Deserialization** — Handles 27 box types with proper `fromJson()`. 5 types return raw maps (`planAdherenceMetrics`, `masteryImprovementMetrics`, `answers`, `progress`, `sessions`). 5 more (`agentMemory`, `examResults`, `studentId`, `dashboardLayoutPrefs`, `dbVersion`) fall to `default: return json;` but these are metadata/config boxes where raw maps are acceptable. ✓
- **StudentId mismatch** — FIXED at lines 1263-1309. Detects mismatch, warns user, rewrites all studentId fields. ✓
- **Post-restore state refresh** — `ref.invalidate(settingsProvider)`, `ref.invalidate(databaseProvider)`, `ref.invalidate(subjectListProvider)` called at lines 1319-1321. Success dialog suggests restart. Not a full tree invalidation but functional. PARTIAL.
- **Selective restore with per-box counts** — EXISTS at line 1396 (`Text(l10n.recordCount(records.length))`). ✓

### Step 5: Configuring Auto-Backup
**Status: PARTIAL**
- Code references: `settings_screen.dart:83-116` (perform), `664-741` (dialog)
- **No background schedule** — The original `_checkAutoBackup()` referenced in the scenario no longer exists. The interval is stored (`autoBackupIntervalDays`) but there is no `Timer.periodic`, `WorkManager`, or background isolate. Auto-backup only runs on explicit "Backup Now" click or sign-out flow. ✗
- **Temp directory** — FIXED. `outputDir: 'persistent'` → `getApplicationDocumentsDirectory()`. ✓
- **Path stored** — FIXED. `box.put('lastAutoBackupPath', filePath)` at line 99. ✓
- **Share button** — FIXED. Working share in SnackBar (lines 103-108) and dialog (lines 708-716). ✓
- **Manual trigger** — FIXED. "Backup Now" button in dialog (lines 684-692). ✓
- **Last backup display** — EXISTS. Shows date (lines 694-702) and path. ✓
- **Bug**: When selecting an interval in the dialog (lines 726-728), `lastAutoBackupDate` is set to `DateTime.now()` before any backup is actually performed. This records a phantom backup that was never created.

### Step 6: Exporting Progress Reports from the Dashboard
**Status: COMPLETED**
- Code references: `export_section.dart:1-383`, `dashboard_providers.dart:38-44`, `progress_export_service.dart:17-382`
- **`ProgressExportService` DI** — FIXED. Uses Riverpod provider `dashboardExportServiceProvider` at `dashboard_providers.dart:38-44`. ✓
- **Two CSV exports** — Present with distinct labels (`l10n.exportCsv` vs `l10n.exportProgressCsv`) and separate visual sections. Intentional. ✓
- **StudentId in JSON** — NOT present. The `exportComprehensiveJSON()` method at `progress_export_service.dart:40-53` does NOT include `studentId` in the JSON output. It only includes `exportDate`, `overallStats`, `topicMastery`, `attempts`, `badges`. **ERR**: The previous validation claimed "Still present at progress_export_service.dart:42" — this is INCORRECT.
- **"What's included?" details** — EXISTS. Format-specific `details` parameter in `_showExportConfirmation()`. ✓

### Step 7: Session History Export
**Status: COMPLETED**
- CSV, JSON, PDF exports verified. Works correctly with locale-aware formatting.

### Step 8: The About Dialog — Version Info
**Status: COMPLETED**
- Code references: `settings_screen.dart:1741-1764`
- Uses `PackageInfo.fromPlatform()` at line 1764. Falls back to `l10n.aboutVersion` string only on error. ✓
- **ERR**: The previous validation agreed with the scenario that "About dialog uses PackageInfo.fromPlatform()" — this is CORRECT.

### Step 9: Sign Out
**Status: COMPLETED**
- Code references: `settings_screen.dart:1609-1725`
- The sign-out dialog now offers two optional checkboxes: **"Clear all study data"** (line 1667) and **"Back up before signing out"** (line 1677, conditional on clear being checked). ✓
- When clear is selected, `HiveBoxNames.allStudyDataBoxes` are all cleared (lines 1709-1717). ✓
- When backup first is selected, `_performAutoBackup()` is called before clearing (lines 1704-1706). ✓
- Always clears API key, selected model, and settings (lines 1719-1721). ✓
- The dialog explicitly informs the user of what will be preserved/cleared. ✓
- **ERR**: The previous validation claimed "Sign-out still only clears API key and model" and "No backup prompt before clearing" — both are INCORRECT for current code. The sign-out has proper clear/backup options.
- Multi-user account switching: Out of scope for this feature.

### Summary Table (Corrected)

| # | Step | Previous Status | Corrected Status | Key Changes |
|---|---|---|---|---|
| 1 | Backup discoverability | PARTIAL | PARTIAL | Dashboard has direct backup but skips sensitive-sensitive dialog. Settings is still primary path. |
| 2 | Sensitive data dialog | COMPLETED | COMPLETED | Button bug fixed. Summary dialog added. |
| 3 | Backup file contents | PARTIAL | **COMPLETED** | All 37 boxes included (not 32). Gzip compression works (not "no compression"). Size preview & record count exist. Encryption remains absent. |
| 4 | Restore process | COMPLETED | COMPLETED | Deserialization handles all core types. StudentId reconciliation works. State refresh is reasonable. |
| 5 | Auto-backup | PARTIAL | PARTIAL | No background scheduler (original `_checkAutoBackup` removed). Manual trigger works. Phantom-backup bug on interval select. |
| 6 | Dashboard export | PARTIAL | **COMPLETED** | No studentId in JSON (was wrong claim). DI via Riverpod. Two CSV exports intentional. Details dialog exists. |
| 7 | Session history | COMPLETED | COMPLETED | Verified working. |
| 8 | About dialog | COMPLETED | COMPLETED | PackageInfo.fromPlatform used correctly. |
| 9 | Sign-out | NOT_COMPLETED | **COMPLETED** | Clear study data AND backup-first options exist. Multi-user switching out of scope. |

### Remaining Issues (After Corrected Validation)

| # | Issue | Location | Severity |
|---|---|---|---|
| 1 | Auto-backup has no background schedule trigger; interval stored but never automatically checked | `settings_screen.dart:664-741` — no periodic check | MEDIUM |
| 1a | Selecting auto-backup interval sets `lastAutoBackupDate` to now without performing a backup (phantom backup) | `settings_screen.dart:726-728` | MINOR |
| 2 | Backup files are gzip-compressed but not encrypted; API keys in plaintext when full backup chosen | `data_backup_service.dart` | MEDIUM |
| 3 | Dashboard backup shortcut (`_exportBackupDirect`) skips sensitive data dialog and uses wrong detail text (`l10n.exportCsvDetail` instead of backup-specific text) | `export_section.dart:285-291` | MINOR |
| 4 | Post-restore state refresh invalidates key providers but is not a full state tree refresh | `settings_screen.dart:1319-1321` | MINOR |
| 5 | Backup discoverability requires going to Settings (Dashboard shortcut exists but is incomplete) | Top-level nav | LOW |
