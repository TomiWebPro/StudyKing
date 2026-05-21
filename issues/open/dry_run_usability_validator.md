# Dry-Run Usability Validation Issues

**Validator:** Dry-Run Usability Validator
**Date:** 2026-05-21
**Scenario:** Scenario: Personalizing StudyKing — Theme, Language, Notifications, Profile & AI Task Monitor
**Scenario File:** `dry-run-test/scenario_settings_personalization.md`

---

## BLOCKER Items

None identified in this scenario.

---

## MAJOR Items

### M1 — "Spaced Repetition" section uses hardcoded English strings instead of l10n

**Affected files:**
- `lib/features/settings/presentation/settings_screen.dart:297` — `_section('Spaced Repetition', ...)`
- `lib/features/settings/presentation/settings_screen.dart:298` — `_tile('Min interval', ...)`
- `lib/features/settings/presentation/settings_screen.dart:302` — `_tile('Max interval', ...)`

**Rationale:** Every other section header in the settings screen correctly uses `l10n.spacedRepetition`, `l10n.notificationPreferences`, etc. But lines 297-303 use raw string literals. For a Spanish or other-locale user, these three strings remain in English while the rest of the screen translates. This is a basic localization hygiene issue — the l10n keys exist (check `app_localizations.dart` for `spacedRepetition`, `srMinInterval`, `srMaxInterval`).

**Acceptance criteria:**
- [ ] Replace `'Spaced Repetition'` with `l10n.spacedRepetition`
- [ ] Replace `'Min interval'` with `l10n.srMinInterval`
- [ ] Replace `'Max interval'` with `l10n.srMaxInterval`
- [ ] Verify all three strings render correctly in both English and Spanish

---

### M2 — Language committed on dropdown selection, not on save; no unsaved-changes guard

**Affected files:**
- `lib/features/settings/presentation/profile_screen.dart:489` — `ref.read(localeProvider.notifier).state = Locale(value)` fires on dropdown change
- `lib/features/settings/presentation/profile_screen.dart:99-163` — `_saveProfile()` exists but is separate from the locale change

**Rationale:** When the user changes language in the dropdown (line 489), `localeProvider` is mutated immediately. The entire app switches language at that moment. But the profile's `language` field is only updated when the user explicitly taps "Save." If the user changes language, then navigates away (back button, tab switch) without saving, the in-memory `localeProvider` retains the new locale but `_language` in the profile reverts when the screen is re-initialized. On app restart, the old persisted language loads. This creates an inconsistent state where the app shows one language during the session but reverts on restart. There is no `PopScope` or unsaved-changes warning on the profile screen.

**Acceptance criteria:**
- [ ] Language change should NOT mutate `localeProvider` on dropdown selection
- [ ] Language change should only commit when user taps "Save"
- [ ] `localeProvider` should be set inside `_saveProfile()` after profile persistence succeeds
- [ ] Add `PopScope` to warn about unsaved changes when language is different from persisted value
- [ ] OR (alternative): Commit immediately but also persist immediately and add revert capability

---

### M3 — Settings screen does not watch `localeProvider`; depends on widget recreation for re-render

**Affected files:**
- `lib/features/settings/presentation/settings_screen.dart:125-137` — `build()` watches `settingsProvider`, `apiKeyProvider`, `llmProviderProvider`, `apiBaseUrlProvider` — NOT `localeProvider`
- `lib/features/settings/presentation/settings_screen.dart:76` — `AutomaticKeepAliveClientMixin` keeps state alive

**Rationale:** The `AGENTS.md` "i18n Locale Switching Gotcha" explicitly warns: "Always read `l10n` inside the `build` method or use `Consumer`/`ConsumerWidget` that re-reads on every build. If stale text is observed after a locale switch, refactor to ensure `context` is fresh." While the current navigation flow (Settings → Profile → back to Settings) happens to work because the widget is removed from and re-inserted into the tree, any future feature that changes locale while Settings is visible (e.g., a quick-settings panel, locale change from another tab while Settings is kept alive) will display stale localized strings. The screen should explicitly watch `localeProvider` to guarantee freshness.

**Acceptance criteria:**
- [ ] Add `ref.watch(localeProvider)` to the settings screen's `build()` method
- [ ] Verify that changing language from any entry point causes the settings screen text to update immediately
- [ ] Test with `AutomaticKeepAliveClientMixin` active: change language from another tab, return to Settings, verify text is updated

---

### M4 — EngagementScheduler uses stale `_settingsBox` reference; live preference changes are ignored

**Affected files:**
- `lib/core/services/engagement_scheduler.dart:88` — `_settingsBox = settingsBox` set once in constructor
- `lib/core/services/engagement_scheduler.dart:93-95` — `updateSettings()` method exists but is never called from production code
- `lib/core/providers/app_providers.dart:53-80` — `engagementSchedulerProvider` creates scheduler but never passes `settingsProvider` updates

**Rationale:** When a user toggles notification preferences in Settings (e.g., turns OFF "Overwork Alerts"), the `SettingsRepository` persists the change and `settingsProvider` updates. But the `EngagementScheduler._settingsBox` is a direct reference to the original `SettingsBox` instance from construction time. The scheduler has an `updateSettings()` method (line 93) but no production code path calls it. This means:
- The scheduler's `_isNotificationEnabled('overwork')` at line 206 reads the STALE value
- "Check Nudges Now" (`runDailyChecksNow()`) uses stale preference values
- A user who disables all notifications will continue receiving nudges until app restart
- The `updateSettings()` method on `EngagementScheduler` is dead code

The `engagementSchedulerProvider` should listen to `settingsProvider` changes and call `scheduler.updateSettings()` with the new `SettingsBox` instance.

**Acceptance criteria:**
- [ ] In `engagementSchedulerProvider`, add a `ref.listen(settingsProvider, ...)` that calls `scheduler.updateSettings(newSettings)`
- [ ] Verify that toggling notification preferences immediately affects `_isNotificationEnabled()` behavior
- [ ] Verify "Check Nudges Now" respects current toggle state
- [ ] Remove dead `updateSettings()` method OR keep it as a documented public API with a test

---

### M5 — AI Task Monitor tile shows stale counts; never updates after initState

**Affected files:**
- `lib/features/settings/presentation/settings_screen.dart:1981-2017` — `_AiTaskMonitorTileState`
- `lib/features/settings/presentation/settings_screen.dart:1988` — `_updateCounts()` called only in `initState()`
- `lib/features/settings/presentation/settings_screen.dart:1992` — uses `ref.read()` instead of `ref.watch()`

**Rationale:** The `_AiTaskMonitorTile` reads `llmTaskManagerProvider` once during `initState()` using `ref.read()` (not `ref.watch()`). The counts (`_activeCount`, `_failedCount`) are never updated after initial load. If the user starts a content upload pipeline (which creates LLM tasks) after the settings screen is built, the tile still shows "0 active tasks" and "No active AI tasks." The badge count is frozen at initial load. Since the tile uses `ConsumerStatefulWidget`, it should use `ref.watch(llmTaskManagerProvider)` in the `build()` method to reactively update counts.

**Acceptance criteria:**
- [ ] Replace `ref.read(llmTaskManagerProvider)` in `initState()` with `ref.watch(llmTaskManagerProvider)` in `build()`
- [ ] Remove `_updateCounts()` from `initState()` entirely
- [ ] Compute `_activeCount` and `_failedCount` directly in `build()` from the watched provider
- [ ] Remove `_activeCount` and `_failedCount` instance variables (they should be derived from provider state)
- [ ] Verify: start a content upload, navigate to Settings, see badge count reflect active tasks in real time

---

### M6 — Seven settings values stored via direct `box.put()` bypassing repository

**Affected files:**
- `lib/features/settings/presentation/settings_screen.dart:662` — `dailyCapMinutes`
- `lib/features/settings/presentation/settings_screen.dart:806` — `srMinIntervalDays`, `srMaxIntervalDays`, `srDailyReviewLimit`
- `lib/features/settings/presentation/settings_screen.dart:737` — `autoBackupIntervalDays`
- `lib/features/settings/presentation/settings_screen.dart:103-105` — `lastAutoBackupDate`, `lastAutoBackupPath`
- Also: `mentorCheckinFrequencyDays`, `defaultScheduleDuration`, `defaultTeachingDuration` (via settings_screen.dart patterns)

**Rationale:** These 7+ Hive keys are written directly via `Hive.box(HiveBoxNames.settings).put(key, value)` instead of going through `SettingsRepository.updateSettings()` and `SettingsController`. This means:
1. They are NOT part of the `SettingsBox` model — `settingsProvider` knows nothing about them
2. `ref.invalidate(settingsProvider)` (called after direct writes) forces a repository re-read, but the repository reads from the JSON `'settings'` key, not from individual box keys — invalidating does NOT pick up the new values
3. Any code that needs these values must use direct `box.get()` with magic string keys
4. A future refactoring that normalizes settings storage will silently drop these orphaned keys
5. The pattern is inconsistent with the rest of the codebase's repository-backed architecture

The migration to a unified JSON settings key appears to have been incomplete.

**Acceptance criteria:**
- [ ] Add missing fields to `SettingsBox` model: `dailyCapMinutes`, `srMinIntervalDays`, `srMaxIntervalDays`, `srDailyReviewLimit`, `autoBackupIntervalDays`, `lastAutoBackupDate`, `lastAutoBackupPath`, `mentorCheckinFrequencyDays`, `defaultScheduleDuration`, `defaultTeachingDuration`
- [ ] Handle null/default values for these fields in existing profiles (migration)
- [ ] Update `SettingsRepository` to read/write these fields as part of the unified JSON `'settings'` key
- [ ] Replace all `box.put(key, value)` calls with `settingsProvider.notifier.updateSettings(SettingsUpdate(...))`
- [ ] Remove `_getSrValue()` and `_setSrValue()` helper methods; use `settings.field`
- [ ] Verify all 7 values survive the migration without data loss

---

### M7 — Spaced repetition config values are orphaned from the SettingsBox model

**Affected files:**
- `lib/features/settings/presentation/settings_screen.dart:794-811` — `_getSrValue()` / `_setSrValue()` reading/writing orphaned Hive keys
- `lib/features/settings/data/models/settings_box.dart` — no SR field definitions exist

**Rationale:** This is a specific instance of M6 but merits its own entry because SR values are consumed by the spaced repetition and practice engines. The current implementation reads SR values via `_getSrValue()` which directly accesses Hive with magic string keys (`SrConfig.keyMinIntervalDays`, etc.). The `SpacedRepetitionService` or `PracticeService` must also read these keys directly. If any component tries to read SR settings from `settingsProvider.state.srMinIntervalDays`, the field doesn't exist — it returns null. The `EngagementScheduler` and practice pipeline may silently use defaults instead of user preferences.

**Acceptance criteria:**
- [ ] Same as M6 for SR fields
- [ ] Also audit all consumers of SR config values to ensure they read from the new unified location after migration
- [ ] Verify that changing SR min/max/review-limit in settings actually affects practice scheduling

---

## MINOR Items

### m1 — "Check Nudges Now" button gives vague feedback

**Affected files:**
- `lib/features/settings/presentation/settings_screen.dart:274-291` — onTap handler
- `lib/core/services/engagement_scheduler.dart:196-199` — `runDailyChecksNow()`

**Rationale:** After tapping "Check Nudges Now," the user sees a SnackBar with "Nudge checks complete." There is no indication of what was checked, how many nudges were sent, what types, or if any were blocked by settings. A user who just disabled all notification preferences and taps this button gets the same feedback as a user who has all notifications enabled and receives 5 nudges. The feedback should be informative.

**Acceptance criteria:**
- [ ] Return a result summary from `runDailyChecksNow()` (count per nudge type, or at least "X nudges sent, Y blocked by preferences")
- [ ] Display the summary in the SnackBar or a brief dialog

---

### m2 — "Sign Out" does not clear the user profile; no explanation of what survives

**Affected files:**
- `lib/features/settings/presentation/settings_screen.dart:1642-1759` — `_showSignOutDialog()`
- `lib/features/settings/presentation/settings_screen.dart:1754` — only API keys and selected model are cleared

**Rationale:** The sign-out flow clears API keys and optionally all study data, but the `UserProfile` in the `'profile'` Hive box is never deleted (unless the "Clear all study data" checkbox is checked, which is off by default). The dialog text at line 1656 says "Are you sure you want to sign out?" with no mention that profile data (name, avatar, language preference) survives. A privacy-conscious user would expect sign-out to return the app to first-launch state. The profile persistence may be intentional but should be communicated.

**Acceptance criteria:**
- [ ] Add text to the sign-out dialog explaining what data survives (e.g., "Your profile name and language preference will be kept. Study data and API keys will be cleared.")
- [ ] OR add a separate "Clear profile" checkbox
- [ ] OR clear the profile by default and add a "Keep profile" checkbox

---

### m3 — Theme default (light) mismatches runtime config expectation (system)

**Affected files:**
- `lib/features/settings/data/models/settings_box.dart:112` — `this.themeMode = 0` (ThemeMode.light)
- `lib/core/constants/app_runtime_config.dart` — `defaultThemeMode = ThemeMode.system`

**Rationale:** Two different defaults exist. `SettingsBox` defaults to `ThemeMode.light` (index 0), but `UiConfig.defaultThemeMode` is `ThemeMode.system`. A user with system dark mode enabled sees the app in light mode on first launch. The `SettingsBox` default should match the runtime config default.

**Acceptance criteria:**
- [ ] Change `SettingsBox` default to `ThemeMode.system.index` (2) to match `UiConfig.defaultThemeMode`
- [ ] Verify migration path for users with existing settings that stored `themeMode: 0`

---

### m4 — Profile screen has no unsaved-changes guard when language is changed

**Affected files:**
- `lib/features/settings/presentation/profile_screen.dart:486-491` — language change commits immediately
- `lib/features/settings/presentation/profile_screen.dart` — no `PopScope` for unsaved changes

**Rationale:** If the user changes the language dropdown (which immediately mutates `localeProvider`) but then navigates away via back button without tapping Save, the locale is already switched in-memory but the profile's language field is not persisted. On restart, the old language loads. The screen has no `PopScope` to warn about this. While the language switching is intended to be immediate (it takes effect right away), the missing persistence means the effect is session-only without explicit save.

**Acceptance criteria:**
- [ ] Add `PopScope` that checks if `_language !=` the initial language loaded from profile
- [ ] If unsaved, show a dialog: "Language has been changed but not saved. Keep changes for this session?"
- [ ] OR persist the language immediately on dropdown change (in addition to mutating `localeProvider`)

---

### m5 — No search or section index in settings (code quality / UX)

**Affected files:**
- `lib/features/settings/presentation/settings_screen.dart:143-377` — 15 sections in a single ListView

**Rationale:** With 15 distinct sections containing ~40 controls, finding a specific setting requires scrolling through the entire page. There is no search bar, section index, or quick-jump navigation. This is acceptable for most mobile app settings pages but is worth noting for future UX improvement.

**Acceptance criteria:**
- [ ] (Future enhancement) Add a search bar that filters visible sections/controls by matching label text
- [ ] (Future enhancement) Add a sticky section header index on the right side

---

## Summary

| Severity | Count | IDs |
|---|---|---|
| **BLOCKER** | 0 | — |
| **MAJOR** | 7 | M1, M2, M3, M4, M5, M6, M7 |
| **MINOR** | 5 | m1, m2, m3, m4, m5 |

The settings and personalization layer has architectural fragmentation (three persistence patterns), stale data in reactive components, premature state mutation on dropdown controls, and incomplete localization. The most impactful issues are M5 (AI Task Monitor never updates), M4 (scheduler ignores live preference changes), M6/M7 (orphaned settings keys), and M2 (premature locale mutation).
