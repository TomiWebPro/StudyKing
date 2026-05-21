# Dry-Run Scenario: Personalizing StudyKing — Theme, Language, Notifications, Profile & AI Task Monitor

## Persona

I'm a student who has been using StudyKing for about 2 weeks. I've created subjects, completed some practice, and attended a tutor lesson. Now I want to customize the app to match my personal preferences and understand my AI usage. I open the **Settings** tab (last in the bottom nav) for the first time.

I expect the app to:
1. Present settings in clearly organized sections that are easy to navigate
2. Apply theme changes immediately (dark mode should take effect right away)
3. Let me change the app language and have **every** screen show the new language
4. Let me control which notifications I receive (overwork alerts, revision reminders, lesson notifications)
5. Show me my AI token usage in a meaningful way (what tasks consumed tokens, how much it cost)
6. Offer a working auto-backup and clear export/import flow
7. Persist every setting across app restarts — no surprises
8. Give me clear feedback about what changed (snackbars, toasts, confirmation dialogs)
9. Not require me to configure things that aren't central to personalization

---

## Step 1: First Visit to Settings — Understanding the Layout

I tap the Settings tab (gear icon, 6th tab in bottom nav). The screen loads.

**What I expect:** A well-organized list of configuration sections grouped by category (Appearance, Notifications, AI, Study, etc.) with clear labels and immediately understandable controls.

**What I see:**

The `SettingsScreen` (`settings_screen.dart:139-377`) renders 12+ sections in a single scrollable `ListView`:

| # | Section Header | Controls |
|---|---|---|
| 1 | User Management | "Current User" → ProfileScreen |
| 2 | Quick Access | "Quick Guide" → QuickGuideScreen |
| 3 | Content Management | Upload, My Uploads, Question Bank, Failed Uploads |
| 4 | Appearance | Theme dialog, Font Size dialog |
| 5 | Accessibility | 4 switches: Bold, High Contrast, Large Touch Targets, Reduce Motion |
| 6 | AI Configuration | API Keys, AI Model, Request Timeout, Connection Health, AI Task Monitor |
| 7 | Notification Preferences | 6 switches + Reminder Time picker + "Check Nudges Now" |
| 8 | Study Preferences | Session Duration picker |
| 9 | Spaced Repetition | Min interval, Max interval, Daily review limit |
| 10 | Focus Mode | Daily Study Cap, Break Duration, Focus Timer link |
| 11 | Session Tracking | Manual Session Tracker, Session History |
| 12 | Study Analytics | Total sessions, total study time |
| 13 | Token Usage Summary | Total tokens, Total cost per feature |
| 14 | Backup and Restore | Export Backup, Import Backup, Auto Backup |
| 15 | About | About, Show Onboarding Tour, Sign Out |

**Issue 1 — "Spaced Repetition" section title is hardcoded English (MAJOR):** At `settings_screen.dart:297`, the section header reads `_section('Spaced Repetition', ...)` — the string literal `'Spaced Repetition'` is not passed through localization. Compare with all other sections which correctly use `l10n.spacedRepetition`, `l10n.notificationPreferences`, etc. Similarly, the subtitles "Min interval" (line 298) and "Max interval" (line 302) are hardcoded English strings rather than `l10n.srMinInterval` / `l10n.srMaxInterval`. For a Spanish-localized user, this section title and subtitles stay in English while everything else translates.

**Issue 2 — No per-section search or filter (MINOR):** With 15 sections and ~40 individual controls, finding a specific setting requires scrolling through the entire list. There's no search bar and no section index. A user who wants to find "auto-backup" must scroll past appearance, accessibility, AI, notifications, study preferences, spaced repetition, focus mode, session tracking, study analytics, and token usage before reaching the backup section — roughly 80% of the screen. This is acceptable for a single-scroll settings page common in mobile apps, but the density is notably high.

Everything loads and displays correctly. The `settingsProvider` is watched (line 129) and the `SettingsBox` state is populated. Controls appear as described above. ✓

---

## Step 2: Switching to Dark Mode

I want dark mode (I study at night). I tap the "Theme" row in the Appearance section.

**What I expect:** A bottom sheet with 3 options: Light, Dark, System. I tap "Dark." The app immediately switches to dark mode. I navigate to the Dashboard and back — dark mode persists. I restart the app — dark mode is still active.

**What actually happens:**

`_showThemeDialog()` at line 484-518 fires a `ModalBottomSheet` with three `ListTile`s. I tap "Dark." This calls:
```dart
ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(themeMode: ThemeMode.dark));
```
which:
1. Persists via repository
2. Reloads settings into `settingsProvider`
3. The `settingsProvider` state change triggers `MainScreen.build()` rebuild (main.dart:443 reads `settings.themeModeEnum`)
4. `MaterialApp.themeMode` updates → dark theme applies

**This works correctly — theme applies immediately and persists.** ✓

**Issue 3 — Theme default is Light, not System (MINOR):** At `SettingsBox` line 112, the default value is `this.themeMode = 0` which is `ThemeMode.light.index`. But `UiConfig.defaultThemeMode` is `ThemeMode.system` (from `app_runtime_config.dart`). Most users expect "Follow system setting" as default. A new user on a device with dark mode enabled will see the app in light mode on first launch. The mismatch is between the data model default (light) and the runtime config default (system).

After tapping Dark, the bottom sheet closes and the Settings page is now in dark mode. ✓ The theme applies immediately because `settingsProvider` is watched at line 129 and the theme update triggers a provider rebuild.

---

## Step 3: Changing Language to Spanish

I want to use StudyKing in Spanish (my native language). I go to Settings → Current User → Profile Screen.

**What I expect:** A language dropdown with supported languages. I select Spanish ("Español"). The entire app immediately switches to Spanish. I tap "Save" to persist the change. After restarting the app, Spanish is still active.

**What actually happens:**

The `ProfileScreen` (`profile_screen.dart:470-492`) shows a `DropdownButton<String>` with `AppLocale.values` (English and Spanish). I select "Español."

**Issue 4 — Language change is committed on dropdown selection, not on save (MAJOR):** At line 489:
```dart
onChanged: (value) {
  if (value != null) {
    setState(() => _language = value);
    ref.read(localeProvider.notifier).state = Locale(value);
  }
},
```
The `localeProvider` is mutated **the moment the user selects a different language in the dropdown**. The locale immediately switches throughout the app (MaterialApp at main.dart:388 watches `localeProvider`). But the user hasn't tapped "Save" yet — they might change their mind and switch back, or navigate away.

If the user navigates away without saving (back button):
- The `localeProvider` is already set to `Locale('es')` — it won't revert
- But the profile in the Hive box still has `language: 'en'`
- On restart, `_initialLanguageCode` is loaded from the Hive profile → `'en'` → app starts in English
- **The in-memory locale and the persisted locale are inconsistent**

However:
- The `ProfileScreen.build()` watches `localeProvider` (line 289: `ref.watch(localeProvider)`), so it re-renders with the new locale immediately while on ProfileScreen ✓
- If the user taps "Save" (line 99-163), the profile is persisted with the new `_language` value ✓
- The `PopScope` mechanism: there's no `PopScope` wrapping the profile screen to warn about unsaved changes. The user can navigate away freely with the language already switched.

**Issue 5 — Settings screen shows stale text after language change (MAJOR):** The `SettingsScreen` does NOT watch `localeProvider` (its `build()` at line 125-137 watches `settingsProvider`, `apiKeyProvider`, `llmProviderProvider`, `apiBaseUrlProvider` — but not `localeProvider`). Even worse, it has `AutomaticKeepAliveClientMixin` (line 76), which means:
- When the user navigates from Settings → Profile, the Settings widget's state is kept alive
- After changing language in Profile and returning to Settings, the Settings widget is re-inserted into the tree
- BUT: `AutomaticKeepAliveClientMixin` means `build()` IS called when the tab becomes visible again
- `AppLocalizations.of(context)!` at line 127 reads from the current context, which should have the new locale

Let me trace more carefully. When `localeProvider` changes at line 489 of profile_screen.dart:
1. `MaterialApp` (main.dart:388) watches `localeProvider` → rebuilds with new locale
2. `Localizations` widget is rebuilt with `Locale('es')`
3. When user pops back to Settings, the Settings widget's `build()` is called because it was previously removed from the widget tree
4. Line 127: `final l10n = AppLocalizations.of(context)!;` — this traverses up the widget tree to find the nearest `Localizations` widget, which now has the Spanish locale
5. Spanish strings are returned

**The actual issue is the edge case where locale changes while the Settings screen is VISIBLE.** This happens if:
- User is on Settings tab
- Some other mechanism changes locale (e.g., a future "quick language switch" feature, or the locale is changed from a different part of the app while settings is visible)

With `AutomaticKeepAliveClientMixin` and the tab-based navigation:
- If user is on Settings tab → switches to Profile tab (2nd nav in a sub-screen, not a tab switch)
- Actually, Profile is a pushed route, not a tab. So Settings IS removed from the widget tree.
- When popping back from Profile, Settings widget is re-created → `build()` called → fresh `l10n`

**The verified issue is: the Settings screen does NOT watch `localeProvider`, making it resilient only to languages changed while the widget is not in the tree.** If language changes while Settings is visible (possible if language is changed from another entry point in the future), the text stays stale. This is a design fragility, not a guaranteed bug in the current navigation flow, but it violates the `AGENTS.md` "i18n Locale Switching Gotcha" guidance which says "Always read `l10n` inside the `build` method" AND the screen should watch `localeProvider`.

After selecting Spanish, I see:
- Profile screen content in Spanish ✓ (because it watches `localeProvider`)
- I navigate back to Settings → Settings content in Spanish ✓ (widget was rebuilt)
- I navigate to Dashboard → Dashboard content in Spanish ✓ (MaterialApp rebuild)
- I navigate to Practice → Practice content in Spanish ✓

I tap "Save" in Profile. Profile is persisted with `language: 'es'`. ✓

---

## Step 4: Configuring Notification Preferences

Back in Settings, I scroll to the **Notification Preferences** section. I want to keep daily reminders and lesson notifications, but turn off overwork alerts.

**What I expect:** Clear toggle switches with descriptions. Toggling a switch persists immediately and the scheduler respects my choice.

**What actually happens:**

The section at `settings_screen.dart:213-292` renders:
- **Enable Notifications** (master switch) — toggles `studyRemindersEnabled`
- When master is ON: Daily Reminders, Revision Reminders, Lesson Notifications, Overwork Alerts, Plan Adjustment Notifications appear
- **Check Nudges Now** button

I toggle **Overwork Alerts** OFF (line 254-259):
```dart
SwitchListTile(
  title: Text(l10n.overworkAlerts),
  value: settings.overworkAlertsEnabled,
  onChanged: (value) =>
      ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(overworkAlertsEnabled: value)),
),
```

The `SettingsUpdate` is persisted via `SettingsRepository`. ✓ The `engagementSchedulerProvider` at `app_providers.dart:53-80` reads the settings via `l10nProvider` but not dynamically from `settingsProvider`. However, the scheduler's `_isNotificationEnabled()` (line 201-212) checks `_settingsBox` which is set during construction. When settings change, `updateSettings()` on the scheduler is NOT called — the scheduler uses the `_settingsBox` reference it was constructed with.

**Issue 6 — EngagementScheduler uses a stale SettingsBox reference for nudge gating (MAJOR):** At `engagement_scheduler.dart:88`, `_settingsBox = settingsBox` is set once in the constructor. When the user changes notification preferences in Settings, the `SettingsRepository` persists the change, and `settingsProvider` updates. But `EngagementScheduler._settingsBox` is a direct reference to the original `SettingsBox` object passed at construction time. If the user turns OFF "Overwork Alerts," the scheduler's `_isNotificationEnabled('overwork')` at line 206 still returns `true` because `_settingsBox` still has the OLD value.

Wait, let me re-check. The `engagementSchedulerProvider` creates a new `EngagementScheduler` instance on every provider read? No — it's a `Provider<EngagementScheduler>` (not `AutoDispose`), so it's created once and cached. The `_settingsBox` is whatever `SettingsBox` was available at construction time.

BUT, the scheduler has `updateSettings(SettingsBox settingsBox)` at line 93-95. This method is never called from anywhere in the production code. Let me verify...

Search for `updateSettings` in the engagement_scheduler:
```dart
void updateSettings(SettingsBox settingsBox) {
    _settingsBox = settingsBox;
  }
```

And `updateLocalization` is called from `engagementSchedulerProvider` (app_providers.dart line 72, 74), but `updateSettings` is never called.

This means: **If a user changes notification preferences in Settings, the EngagementScheduler doesn't know about the change.** The scheduler continues using the stale `_settingsBox`. If overwork alerts were ON when the scheduler was created, they remain ON for the scheduler's lifetime (until app restart, when the scheduler is recreated with fresh settings).

The "Check Nudges Now" button at line 274 calls `scheduler.runDailyChecksNow()` which triggers `_sendNudgeNotifications()`. Inside that method, `_isNotificationEnabled()` checks `_settingsBox.overworkAlertsEnabled` — which is the STALE value. So the "Check Nudges Now" button respects the settings that were active when the app started, NOT the current settings.

**Issue 7 — "Check Nudges Now" doesn't show which nudges were sent (MINOR):** The button at line 274-291 calls `scheduler.runDailyChecksNow()` and shows a generic "Nudge checks complete" SnackBar. There's no indication of:
- How many nudges were sent
- What type of nudges
- Whether they were blocked by settings
- Whether any new notifications appeared

The user taps the button and gets a vague confirmation with no actionable information.

---

## Step 5: Viewing AI Token Usage and Task Monitor

I scroll further down to the **Token Usage Summary** section. I see two tiles: "Total Tokens" and "Total Cost."

**What I expect:** A detailed breakdown of AI usage by feature — how many tokens were used for content uploads, mentor chats, tutor lessons, question generation, etc. I tap a tile and see a per-feature breakdown.

**What actually happens:**

The tiles at `settings_screen.dart:337-345` show:
- **Total Tokens** (reads `ref.watch(llmUsageMeterProvider).getTotalTokens()`)
- **Total Cost** (reads `ref.watch(llmUsageMeterProvider).getTotalCost()`)

Tapping the tokens tile calls `_showTokenUsageDetails()` (line 1572-1624), which shows an `AlertDialog` with:
- Usage summary (total cost, total tokens, avg cost per 1K tokens)
- Per-feature breakdown: "Ingestion" group (OCR, transcription, classification, summarization, question gen) and "General" (mentor, chat, etc.)

**This works correctly.** The data is live because `llmUsageMeterProvider` is watched. ✓

**Issue 8 — AI Task Monitor tile shows stale counts (MAJOR):** Above the token usage section is the "AI Task Monitor" tile (`_AiTaskMonitorTile`, line 1976-2017). It shows a badge with active + failed task counts and subtitle "View active AI tasks" or "No active AI tasks."

The problem: `_updateCounts()` is called only in `initState()` (line 1988):
```dart
@override
void initState() {
    super.initState();
    _updateCounts();
}

void _updateCounts() {
    final taskManager = ref.read(llmTaskManagerProvider);
    _activeCount = taskManager.activeTasks.length;
    _failedCount = taskManager.tasks.where((t) => t.status == LlmTaskStatus.failed).length;
}
```

`ref.read()` (not `ref.watch()`) means:
- The tile reads the task manager ONLY once during initialization
- If a task completes or fails after the tile is built, the counts stay at their initial values
- The user sees "0 active tasks" badge even when the upload pipeline is actively processing content
- The tile's `build()` is not reactive because `build()` doesn't watch `llmTaskManagerProvider`

**This is a fully stale UI component.** The AI Task Monitor tile's badge count is frozen at the moment the settings screen was first built. It never updates until the settings screen widget is re-created.

Looking at the tile's `build()` method (line 1998-2016):
```dart
Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = _activeCount + _failedCount;
    // uses _activeCount and _failedCount from initState
```

Since these instance variables are never updated after initState, the badge always shows the count from when the settings screen was first loaded. For an average user, this means the badge shows "0" at startup if no tasks were actively running at that exact moment. If the user later starts a content upload (which creates tasks), the task monitor tile still shows "0."

I also check whether `ref.invalidate` or `ref.listen` would help — the tile uses `ConsumerStatefulWidget` but doesn't listen to any provider for updates. Adding `ref.watch(llmTaskManagerProvider)` in the build method would fix this.

---

## Step 6: Setting Up Auto-Backup

I scroll to the **Backup and Restore** section. I tap "Auto Backup."

**What I expect:** A dialog showing backup frequency options (Never, Daily, Weekly). I select Weekly. From now on, the app automatically backs up my data every week.

**What actually happens:**

`_showAutoBackupDialog()` at line 675-749 shows a modal bottom sheet with options. I tap "Weekly." This calls:
```dart
box.put('autoBackupIntervalDays', days);
ref.invalidate(settingsProvider);
```

**Issue 9 — Auto-backup interval and path stored via direct Hive access, bypassing repository (MAJOR):** Lines 737-738:
```dart
box.put('autoBackupIntervalDays', days);
ref.invalidate(settingsProvider);
```

This writes directly to the Hive `settings` box with key `'autoBackupIntervalDays'`. Compare with the correct pattern used elsewhere (e.g., theme changes at line 494):
```dart
ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(themeMode: ThemeMode.dark));
```

The direct Hive access:
1. Bypasses the `SettingsRepository` layer
2. Bypasses the `SettingsController` state management
3. `ref.invalidate(settingsProvider)` forces a re-read from the repository — but the repository reads from the JSON `'settings'` key, not from individual box keys
4. The auto-backup interval is therefore **invisible** to the `settingsProvider` state
5. The `settings_screen.dart` at line 679 reads it back with `box.get('autoBackupIntervalDays', defaultValue: 0) as int` — direct Hive access again

Similarly at lines 103-105:
```dart
box.put('lastAutoBackupDate', DateTime.now().toIso8601String());
box.put('lastAutoBackupPath', filePath);
```

These use direct `box.put()` instead of the repository. The same pattern is used for:
- `dailyCapMinutes` (line 662)
- `srMinIntervalDays` (line 806)
- `srMaxIntervalDays` (line 806) 
- `srDailyReviewLimit` (line 806)
- `autoBackupIntervalDays` (line 737)
- `mentorCheckinFrequencyDays` (settings_screen.dart)
- `defaultScheduleDuration` (settings_screen.dart)
- `defaultTeachingDuration` (settings_screen.dart)

Seven separate settings values bypass the repository. This is an architectural inconsistency — the migration from individual box keys to a unified JSON `'settings'` key was incomplete.

---

## Step 7: Signing Out

I scroll to the bottom and tap "Sign Out" in the About section.

**What I expect:** A clear dialog explaining what signing out means — whether my data will be deleted, whether I can come back, etc.

**What actually happens:**

`_showSignOutDialog()` at line 1642-1759 shows an `AlertDialog` with:
- Warning icon and text
- "Clear all study data" checkbox (optional)
- "Backup first" checkbox (optional)
- "Sign Out" button
- "Cancel" button

If "Clear all study data" is checked, it clears all Hive boxes and repositories. If not checked, only API keys are cleared.

**Issue 10 — "Sign Out" does not clear user profile from Hive (MINOR):** At line 1754-1755:
```dart
updateSettings(SettingsUpdate(apiKey: '', selectedModel: ''))
await ref.read(secureApiKeyServiceProvider).clearAll()
```

The `UserProfile` in the `'profile'` Hive box is NOT cleared. The Hive `'profile'` box is neither deleted nor reset. This means:
- After sign-out and re-launch, the old profile data (name, student ID, learning goal, language, avatar) persists
- A new user who picks up this device sees the previous user's profile data
- The profile persistence outlives sign-out, which could be a privacy concern

However, this may be intentional — the sign-out primarily clears API keys and study data stops. The profile is considered device-local metadata, not study data. But there's no UI indication that the profile survives sign-out.

The "Clear all study data" option at lines 1677-1736 does wipe all Hive boxes including `'profile'` through `DatabaseService.clearAll()`. But the default state (checkbox unchecked) leaves the profile intact. This is ambiguous for the user — "Sign Out" usually implies a clean slate.

---

## Step 8: Restarting the App — Settings Persistence

I completely close and restart StudyKing.

**What I expect:** Dark mode is still active, Spanish language is selected, notification preferences are as I configured them, token usage still shows my history, auto-backup is set to weekly.

**What actually happens:**

On restart (`main.dart`):
1. `HiveInitializer.initialize()` opens all boxes — settings, profile, etc.
2. `DatabaseService` initializes with all repositories
3. `SettingsController._loadSettings()` reads from repository
4. `localeProvider` reads `_initialLanguageCode` from profile (set via `setInitialLanguageCode()` in main.dart line 166-178 which reads from `SettingsRepository.getProfileData()`)

**Dark mode:** Persisted via `SettingsRepository` → Hive JSON 'settings' key → themeMode field. On restart, `settingsProvider` reads it back. `themeModeEnum` returns `ThemeMode.dark`. ✓

**Spanish language:** Persisted via profile save. `_initialLanguageCode = 'es'` → `localeProvider` creates `Locale('es')`. ✓

**Notification preferences:** Persisted via `SettingsRepository` → Hive JSON → `settingsProvider` → `SettingsBox` fields. On restart, all toggles are read back. ✓

**Token usage:** Persisted in `llm_usage_records` Hive box. `llmUsageMeterProvider` reads from it. ✓

**Auto-backup:** Settings are stored in individual Hive keys → `_getSrValue()` and `box.get()` read them back. BUT the `settingsProvider` state doesn't include these values. If any other part of the app needs to read auto-backup interval, it would need to access Hive directly. ✓ (The auto-backup mechanism at `_performAutoBackup()` also reads directly from Hive.)

**Issue 11 — SR settings persist but are invisible to the provider model (MAJOR):** The spaced repetition config values (min/max interval, daily review limit) survive restart because they're stored in Hive directly. But they're NOT in the `SettingsBox` model. The `SpacedRepetitionService` or `PracticeService` — any component that needs these values — must read them through the same direct Hive access pattern. If a future refactoring moves to a unified settings model, these orphaned keys will be silently dropped.

---

## Summary of Expectations vs Reality

| # | Expectation | Reality | Status |
|---|---|---|---|
| 1 | All setting sections are localized | "Spaced Repetition", "Min interval", "Max interval" are hardcoded English strings | **MAJOR FAIL** |
| 2 | Theme change applies immediately and persists | Theme change uses correct controller → repository → provider → UI flow | PASS |
| 3 | Language is committed on save, not on dropdown selection | `localeProvider` is mutated on dropdown change (line 489). Unsaved locale persists in-memory but not in profile | **MAJOR FAIL** |
| 4 | Settings screen re-renders when locale changes | Settings screen does NOT watch `localeProvider`. Works only because widget is rebuilt on navigation; fragile design | **MAJOR FAIL** |
| 5 | Notification preference changes are respected by EngagementScheduler | Scheduler uses stale `_settingsBox` reference. `updateSettings()` is never called after construction | **MAJOR FAIL** |
| 6 | "Check Nudges Now" shows results of the check | Generic "Nudge checks complete" SnackBar. No detail on what was sent or blocked | MINOR FAIL |
| 7 | AI Task Monitor tile shows live counts | `_updateCounts()` called only in `initState()` with `ref.read()`. Counts are frozen at initial load | **MAJOR FAIL** |
| 8 | Auto-backup settings persist through repository | 7 settings values stored via direct `box.put()` bypassing repository. Architectural inconsistency | **MAJOR FAIL** |
| 9 | "Sign Out" explains what profile data survives | Profile data is NOT cleared on sign-out (unless "Clear all data" checkbox is checked). No explanation of what survives | MINOR FAIL |
| 10 | Spaced repetition settings are part of unified settings model | Stored as orphaned Hive keys. Not in SettingsBox model. Only accessible via direct Hive reads | **MAJOR FAIL** |
| 11 | Theme default matches runtime config expectation | SettingsBox defaults to light (0) but UiConfig.defaultThemeMode is system | MINOR FAIL |
| 12 | Profile screen has unsaved-changes guard on language change | No PopScope, no warning when navigating away after changing language in dropdown but before saving | MINOR FAIL |

---

## Summary

| Severity | Count | Items |
|---|---|---|
| **MAJOR** | 7 | #1 (hardcoded English strings), #3 (premature locale mutation), #4 (settings not watching localeProvider), #5 (stale scheduler settings), #7 (frozen task monitor), #8 (direct Hive bypass for 7 settings), #10 (orphaned SR keys) |
| **MINOR** | 4 | #2 (no search), #6 (vague nudge feedback), #9 (profile survives sign-out), #11 (theme default mismatch), #12 (no unsaved-changes guard on profile) |
| **PASS** | 1 | #2 (theme persistence) |

The personalization layer has architectural fragmentation: three different persistence patterns (repository-backed, individual Hive keys, and FlutterSecureStorage) coexist with no clear boundary. Seven settings values bypass the main repository, creating orphaned keys that `settingsProvider` cannot see. The AI Task Monitor tile is fully stale after initialization. The locale switching commits state prematurely on dropdown change. And the EngagementScheduler doesn't receive live notification preference updates — it uses a frozen reference from construction time.
