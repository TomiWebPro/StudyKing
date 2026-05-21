# Dry-Run Issue: Backup/Restore/Data Portability — Remaining Items

**Scenario:** `dry-run-test/scenario_backup_restore_data_portability.md`
**Validated:** 2026-05-20
**Overall status:** 7/9 steps COMPLETED, 2 steps PARTIAL (~78%)

---

## Issue 1: Auto-backup has no background schedule trigger (MEDIUM)

**Location:** `settings_screen.dart:664-741`

**What's wrong:** The `autoBackupIntervalDays` setting is stored in the Hive box but there is no mechanism to automatically trigger backups on schedule. The original `_checkAutoBackup()` method (referenced in the scenario) no longer exists. Auto-backup only runs when:
- User clicks "Backup Now" in the auto-backup dialog
- User triggers sign-out with "backup first" option

**What's needed:** Implement a periodic check — either via `Timer.periodic` in the app lifetime, a `WorkManager` background task, or an app lifecycle callback that checks the interval and performs backups autonomously.

---

## Issue 1a: Phantom backup timestamp when selecting interval (MINOR)

**Location:** `settings_screen.dart:726-728`

**What's wrong:** When the user selects an auto-backup interval in the dialog:
```dart
if (days > 0) {
  box.put('lastAutoBackupDate', DateTime.now().toIso8601String());
}
```
This sets `lastAutoBackupDate` to `DateTime.now()` *before* any backup is performed. If the user selects "Daily" and closes the app, the system thinks a backup was made when it wasn't. The next check (if one existed) would skip a backup because the phantom timestamp is recent.

**What's needed:** Only write `lastAutoBackupDate` after a successful backup, or remove this premature write.

---

## Issue 2: Backup files are not encrypted (MEDIUM)

**Location:** `data_backup_service.dart:46-73`

**What's wrong:** Backup files are gzip-compressed (`.skbak`) but not encrypted. When the user chooses "Export Backup (full)", API keys are stored in plaintext inside the compressed archive. Anyone who gains access to the file can decompress and read all data including API keys.

**What's needed:** Add optional encryption (e.g., AES with a user-chosen password) for backup files. The sensitive data dialog already warns about API keys being in plaintext; encryption would address this concern.

---

## Issue 3: Dashboard backup shortcut bypasses sensitive data dialog (MINOR)

**Location:** `export_section.dart:285-291`

**What's wrong:** The Dashboard's `_exportBackupDirect()` method calls `_showExportConfirmation()` with `l10n.exportCsvDetail` as the detail text (incorrect label for backup) and does not offer the option to exclude sensitive data. It always exports a full backup with API keys. Users backing up from the Dashboard won't see the sensitive data warning.

**What's needed:** Either:
- (a) Route to the Settings backup flow (show the proper sensitive data dialog), or
- (b) Always exclude sensitive data from Dashboard backups (since it's a quick-export shortcut), or
- (c) Show the sensitive data dialog inline in the Dashboard.

Also fix the detail text from `l10n.exportCsvDetail` to a backup-appropriate string.

---

## Issue 4: Post-restore state refresh is incomplete (MINOR)

**Location:** `settings_screen.dart:1319-1321`

**What's wrong:** After restoring data, only three providers are invalidated (`settingsProvider`, `databaseProvider`, `subjectListProvider`). Other screens that depend on different providers (e.g., Practice screen, Mentor screen, Focus Mode) may still show stale data until the user navigates away and back or restarts the app. The success dialog suggests restarting.

**What's needed:** Either broaden the invalidation to cover more providers, or add a mechanism to force-refresh all active Riverpod providers after a restore.

---

## Issue 5: Backup feature discoverability (LOW)

**Location:** Top-level navigation

**What's wrong:** The primary backup path is Settings → Backup & Restore (2 levels deep). The Dashboard has a direct backup button but it's among 6+ other small text buttons at the bottom of the Export section, and it bypasses the sensitive data dialog (Issue 3).

**What's needed:** Consider adding a more prominent "Backup" option (e.g., in the app drawer, as a Settings card, or via a dedicated Dashboard tile) that routes through the full backup flow.
