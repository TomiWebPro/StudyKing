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

## Validation Results (2026-05-20)

Each step was traced against the actual source code at `/home/tomi/StudyKing`. Results show what was fixed and what remains.

### Step 1: Finding the Backup Feature
**Status: PARTIAL**
- Code references: `export_section.dart:113-124`, `settings_screen.dart:340-345`
- The Dashboard export section now has a backup icon (`Icons.backup`) with label `l10n.exportBackup` that navigates directly to Settings. This was NOT mentioned in the original scenario. But backup/restore is still 2 levels deep from the main screen.

### Step 2: Starting a Full Backup — The Sensitive Data Dialog
**Status: COMPLETED** (Bug FIXED since scenario was written)
- Code reference: `settings_screen.dart:970-987`
- The dialog buttons now correctly return:
  - Cancel → `Navigator.pop(ctx, null)` → `includeSensitive == null` → early return ✓
  - Exclude Sensitive Data → `Navigator.pop(ctx, true)` → removes settings box ✓
  - Export Backup (full) → `Navigator.pop(ctx, false)` → proceeds to second confirmation + full export ✓
- The `null` return bug on the "Export Backup (full)" button has been fixed. The primary FilledButton now pops with `false`, not `null`.
- Additionally, a **second confirmation dialog** (lines 997-1013) warns about including sensitive data before proceeding.
- A **backup summary dialog** (lines 1028-1105) now shows total record count, per-box breakdowns, and file size preview.

### Step 3: Inspecting the Backup File
**Status: PARTIAL**
- **Size preview** — NOW EXISTS. Code at `settings_screen.dart:1111-1122` computes file size (B/KB/MB) and includes it in the share text at line 1127: `'...${l10n.recordCount(totalRecords)}, $sizeStr'`. ✓
- **Record count summary** — NOW EXISTS. Backup summary dialog at lines 1028-1105 shows per-box record counts and total. ✓
- **Missing boxes (`llmTasks`, `llmUsageRecords`)** — NOW INCLUDED. `_collectAllBoxData()` at lines 1451-1452 now adds both boxes. The total is 32 boxes (was 28 in the scenario). ✓
- **Still missing from backup** (5 boxes): `agentMemory`, `examResults`, `studentId`, `dashboardLayoutPrefs`, `dbVersion`. These are still excluded from `_collectAllBoxData()`.
- **No compression** — Still true. Plain JSON with 2-space indent. ✗
- **No encryption** — Still true. Plaintext API keys if full backup chosen. ✗

### Step 4: Reinstalling the App — The Restore Process
**Status: COMPLETED** (All major issues FIXED)
- Code references: `settings_screen.dart:1191-1352` (import), `1513-1585` (deserialization)
- **Deserialization gaps** — FIXED. `_deserializeRecord()` now handles 28+ box types with proper `fromJson()` calls. Only 4 types use raw map (`planAdherenceMetrics`, `masteryImprovementMetrics`, `answers`, `progress`, `sessions`). Scenario claimed 13+ were raw maps — this is incorrect for current code.
- **StudentId mismatch** — FIXED. Code at lines 1256-1303 explicitly checks for studentId mismatch between backup and current `StudentIdService`, warns the user, and rewrites all `studentId` fields to the current ID before writing.
- **Post-restore state refresh** — PARTIALLY FIXED. `ref.invalidate(settingsProvider)` at line 1312 is called. A success dialog suggests restarting. Full state tree invalidation is not performed.
- **Selective restore with per-box counts** — EXISTS in the selective restore dialog (line 1387: record count subtitle). ✓

### Step 5: Configuring Auto-Backup
**Status: PARTIAL** (Some fixes applied, core issue remains)
- Code references: `settings_screen.dart:81-114` (perform), `662-738` (dialog)
- **Core issue — No background schedule** — Still true. No `Timer.periodic`, no `WorkManager`, no background isolate. Auto-backup only runs when the user clicks "Backup Now" in the dialog. The interval setting tracks when the last backup was made but does NOT trigger automatic backups. ✗
- **Temp directory** — FIXED. `_performAutoBackup()` passes `outputDir: 'persistent'` → uses `getApplicationDocumentsDirectory()`. ✓
- **Path stored** — FIXED. `box.put('lastAutoBackupPath', filePath)` at line 97. ✓
- **Share button** — FIXED. The SnackBar now has a working Share action (lines 103-106). The dialog has a "Share Last Backup" button (lines 706-714). ✓
- **Manual trigger** — FIXED. "Backup Now" button exists in the dialog (lines 682-689). ✓
- **Last backup display** — EXISTS. Shows date and file path in dialog. ✓

### Step 6: Exporting Progress Reports from the Dashboard
**Status: PARTIAL**
- Code references: `export_section.dart:1-338`, `dashboard_providers.dart:38-43`, `progress_export_service.dart:17-28`
- **`ProgressExportService` DI** — FIXED. The service is created via `dashboardExportServiceProvider` at `dashboard_providers.dart:38-43` using Riverpod providers for all dependencies (`tracker`, `masteryService`, `attemptRepo`). The scenario's claim about default constructor `AttemptRepository()` is INCORRECT for current code. ✓
- **Two CSV exports** — Still present but have distinct labels (`l10n.exportCsv` vs `l10n.exportProgressCsv`) and are in different visual sections. PARTIAL.
- **StudentId in JSON** — Still present at `progress_export_service.dart:42`: `'studentId': studentId`. ✗
- **"What's included?" details** — NOW EXISTS. The `_showExportConfirmation` dialog takes format-specific `details` parameter (e.g., `l10n.exportCsvDetail`, `l10n.exportJsonDetail`). ✓

### Step 7: Session History Export
**Status: COMPLETED** ✓
- Code references: `session_export_service.dart` (312 lines)
- CSV, JSON, PDF exports all verified correct.

### Step 8: The About Dialog — Version Info
**Status: COMPLETED** (FIXED)
- Code references: `settings_screen.dart:1742-1765`
- The About dialog now calls `PackageInfo.fromPlatform()` at line 1765 to get the real app version and build number: `'${info.version}+${info.buildNumber}'`. The translated string `l10n.aboutVersion` (`"1.0.0"`) is only used as a fallback if `PackageInfo.fromPlatform()` throws.
- The scenario's claim that the version is hardcoded is INCORRECT for current code.

### Step 9: Sign Out
**Status: NOT_COMPLETED**
- Code references: `settings_screen.dart:1657-1728`
- Sign-out still only clears API key and model (`apiKeyProvider`, `selectedModelProvider`, `settingsProvider`). ✗
- No backup prompt before clearing. ✗
- Study data (subjects, questions, etc.) is preserved — the dialog now explicitly informs the user (`l10n.signOutPreservesStudyData` at line 1699). This transparency is improved, but the feature still doesn't offer a true "sign out and clear all data" option.
- No multi-user account switching support.

### Summary of Fixes Since Scenario Was Written

| # | Status | Change |
|---|---|---|
| 2 | FIXED | "Export Backup (full)" button no longer returns `null` — correctly returns `false` |
| 3a | FIXED | File size preview now shown in share text |
| 3b | FIXED | Record count summary dialog added before export |
| 3c | FIXED | `llmTasks` and `llmUsageRecords` boxes included in backup |
| 4a | FIXED | Full typed deserialization for 28+ box types |
| 4b | FIXED | StudentId mismatch detection and reconciliation |
| 4c | PARTIAL | `ref.invalidate(settingsProvider)` added but not full state refresh |
| 5a | FIXED | Auto-backup saves to persistent storage (not temp) |
| 5b | FIXED | Auto-backup file path stored and accessible |
| 5c | FIXED | Share action works in SnackBar and dialog |
| 5d | FIXED | "Backup Now" manual trigger in dialog |
| 6a | FIXED | `ProgressExportService` uses DI (Riverpod providers) |
| 6b | FIXED | Export confirmation dialog shows format-specific details |
| 8 | FIXED | About dialog uses `PackageInfo.fromPlatform()` for real version |

### Remaining Issues

| # | Issue | Location |
|---|---|---|
| 1 | Backup discoverability could be improved | Dashboard has nav link, but feature is 2 levels deep |
| 3d | No compression or encryption for backup files | `data_backup_service.dart:26` |
| 3e | 5 Hive boxes excluded from backup | `settings_screen.dart:1418-1453` — `agentMemory`, `examResults`, `studentId`, `dashboardLayoutPrefs`, `dbVersion` |
| 5 | No background auto-backup schedule trigger | `settings_screen.dart` — no periodic timer/worker |
| 6 | StudentId exposed in JSON comprehensive report | `progress_export_service.dart:42` |
| 9 | Sign-out doesn't clear study data or offer backup | `settings_screen.dart:1722-1724` |
