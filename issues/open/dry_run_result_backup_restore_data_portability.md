# Dry-Run Result: Backup, Restore & Data Portability

Validated: 2026-05-20
Scenario: `dry-run-test/scenario_backup_restore_data_portability.md`

---

## Issues That Remain Unfixed

### 1. No Background Auto-Backup Schedule (BLOCKER)

**Location:** `lib/features/settings/presentation/settings_screen.dart`

**Problem:** Auto-backup has no background scheduling mechanism. The `_performAutoBackup()` method (line 81) is only called from the auto-backup dialog's "Backup Now" button (line 685). There is no `Timer.periodic`, `WorkManager`, `android_alarm_manager`, or any other background scheduling. The `autoBackupIntervalDays` setting tracks a target interval but has no daemon to enforce it.

**Acceptance criteria:**
- An auto-backup should be triggered without the user navigating to Settings.
- Consider using a background service (e.g., `workmanager` package) or at minimum a periodic check in the app's `MaterialApp` wrapper / `main.dart` lifecycle.
- The backup should still exclude sensitive data (`HiveBoxNames.settings`) as currently done.

---

### 2. 5 Hive Boxes Excluded from Backup (MAJOR)

**Location:** `lib/features/settings/presentation/settings_screen.dart`, `_collectAllBoxData()` at lines 1418-1453

**Problem:** `_collectAllBoxData()` collects 32 boxes but `HiveBoxNames` defines 37. Five boxes are silently excluded:

| Box Name | Purpose |
|---|---|
| `agent_memory` | LLM agent memory / conversation context |
| `exam_results` | Exam/quiz results data |
| `student_id` | Student identity box |
| `dashboard_layout_prefs` | Dashboard layout preferences |
| `db_version` | Database version metadata |

`student_id` and `db_version` are arguably internal metadata, but `agent_memory`, `exam_results`, and `dashboard_layout_prefs` contain actual user data that should be included in a full backup.

**Acceptance criteria:**
- Add the missing boxes to `_collectAllBoxData()`.
- For `agent_memory`, consider if any sensitive LLM context should be stripped.
- For `student_id` and `db_version`, consider whether they need to be included or if their exclusion is intentional and documented.

---

### 3. Backup Files Have No Compression or Encryption (MAJOR)

**Location:** `lib/features/settings/services/data_backup_service.dart:26`

**Problem:** The backup file is plain JSON with 2-space indent (`JsonEncoder.withIndent('  ')`). No compression, no encryption, no password protection. API keys are in plaintext if the user chooses the full export option.

**Acceptance criteria:**
- At minimum, add a size warning in the backup summary dialog when the backup contains sensitive data (API keys).
- Consider adding gzip compression for large backups.
- Consider providing an optional encryption layer (password-protected).

---

### 4. Sign-Out Does Not Clear Study Data (MAJOR)

**Location:** `lib/features/settings/presentation/settings_screen.dart:1722-1724`

**Problem:** Sign-out only clears the API key and selected model. All study data (subjects, questions, attempts, sessions, plans, badges, etc.) remains on-device. The dialog transparently states this (`signOutPreservesStudyData`), but:
- There is no "clear all data and start fresh" option.
- There is no "back up before signing out" prompt.
- A user handing their device to someone else has no way to wipe their study data.

**Acceptance criteria:**
- Add an optional "Clear all study data" checkbox to the sign-out confirmation dialog.
- Add a "Back up before signing out" option that triggers an export before clearing.
- Or provide a separate "Clear All Data" action with appropriate warnings.

---

### 5. StudentId Exposed in JSON Comprehensive Report (MINOR)

**Location:** `lib/core/services/progress_export_service.dart:42`

**Problem:** The JSON comprehensive report includes `'studentId': studentId` in plaintext. If a student shares this JSON report with their teacher, their internal student UUID is exposed.

**Acceptance criteria:**
- Remove `studentId` from the JSON output, or hash/obfuscate it, or add a note that the export contains identifying information.

---

### 6. Post-Restore State Refresh Is Partial (MINOR)

**Location:** `lib/features/settings/presentation/settings_screen.dart:1312`

**Problem:** After restoring data, only `settingsProvider` is invalidated. Other providers (subjects, questions, dashboard data, etc.) are not refreshed. The success dialog shows a hint to restart the app.

**Acceptance criteria:**
- After restore, invalidate all relevant Riverpod providers so the UI reflects restored data immediately.
- Or implement a full app state restart without requiring a manual restart.

---

### 7. Backup Discoverability (ENHANCEMENT)

**Location:** `lib/features/dashboard/presentation/widgets/export_section.dart:113-124`

**Problem:** Backup/restore is only available through Settings → Backup & Restore (2 levels deep). A backup button exists in the Dashboard Export section but it simply navigates to Settings.

**Acceptance criteria:**
- Consider adding a dedicated "Backup" option to the main navigation (bottom nav or drawer).
- Or consider making backup available from a more prominent first-level location.

---

## Issues That Were Fixed (Verified in Source Code)

These items from the original scenario are now resolved:

| # | Issue | Fixed In |
|---|---|---|
| 2 | "Export Backup (full)" button returns `null` → no-op | `settings_screen.dart:980` (returns `false`) |
| 3a | No file size preview | `settings_screen.dart:1111-1122` |
| 3b | No record count summary | `settings_screen.dart:1028-1105` |
| 3c | `llmTasks`/`llmUsageRecords` excluded | `settings_screen.dart:1451-1452` |
| 4a | Deserialization gaps (13+ raw maps) | `settings_screen.dart:1513-1585` (28+ typed) |
| 4b | No studentId mismatch handling | `settings_screen.dart:1256-1303` |
| 5a | Auto-backup saves to temp dir | `data_backup_service.dart:27-29` (`'persistent'`) |
| 5b | Auto-backup path not stored | `settings_screen.dart:97` |
| 5c | Share/View button is no-op | `settings_screen.dart:103-106` (Share action) |
| 5d | No manual trigger | `settings_screen.dart:682-689` (Backup Now) |
| 6a | `ProgressExportService` bypasses DI | `dashboard_providers.dart:38-43` |
| 8 | About dialog version hardcoded | `settings_screen.dart:1747-1749` (uses `PackageInfo`) |
