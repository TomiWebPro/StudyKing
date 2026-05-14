# Settings Screen: Non-Functional Notification Toggles & Duplicate Controls Erode User Trust

## Context

The Settings screen (`lib/features/settings/presentation/settings_screen.dart`) has two independent sections — **"Notification Preferences"** (~line 99) and **"Study Preferences"** (~line 161) — that both manage notification-related settings. The notification preferences section contains **four `SwitchListTile` widgets whose `onChanged` callbacks are empty no-ops** (`onChanged: (value) {}`), meaning users can toggle them but nothing ever happens. Additionally, both sections expose a `SwitchListTile` that reads `settings.studyRemindersEnabled` with identical subtitle text (`enableNotificationAlerts`), creating a confusing dual-control pattern where flipping one switch does not visually reflect on the other.

## Affected Files

| File | Lines | Issue |
|---|---|---|
| `lib/features/settings/presentation/settings_screen.dart` | 127–157 | Four notification toggles have empty `onChanged` handlers — no state is persisted, no behavior changes |
| `lib/features/settings/presentation/settings_screen.dart` | 99–109, 161–171 | Duplicate "Study Reminders" / "Enable Notifications" section — both control the same `settings.studyRemindersEnabled` field but render as independent widgets |
| `lib/features/settings/presentation/settings_screen.dart` | 111–130 | When notifications are enabled, subtitle text on daily reminders (`enableNotificationAlerts`) is identical to the parent's subtitle |
| `lib/features/settings/presentation/settings_screen.dart` | 107, 167 | Same subtitle string `l10n.enableNotificationAlerts` used for two different switches in two sections — semantically incorrect |

## Screenshots / Navigation Path

1. Open app → navigate to **Settings** (gear icon).
2. Scroll to **"Notification Preferences"** section.
3. Toggle **"Revision Reminders"**, **"Lesson Notifications"**, **"Overwork Alerts"**, **"Plan Adjustment Notifications"** — each moves visually but reverts on rebuild / does nothing.
4. Scroll to **"Study Preferences"** section — a second "Study Reminders" switch controls the same underlying boolean but is visually disconnected.

## Root Cause Analysis

- **Dead callbacks**: `SwitchListTile` widgets at lines 128, 136, 144, 153 were scaffolded with empty lambda `onChanged: (value) {}` and never wired to a provider action or state field.
- **Redundant section**: "Study Preferences" was added after "Notification Preferences" without consolidating the overlapping "Study Reminders" toggle. Both read/write `settings.studyRemindersEnabled` but do not synchronise their visual state reactively.
- **Duplicate subtitle l10n key**: `l10n.enableNotificationAlerts` is reused as the subtitle for both the master "Enable Notifications" switch and the child "Daily Reminders" switch, despite describing different scopes.

## Why This Is a High-Value Issue

- **Erodes user trust**: A settings toggle that silently does nothing is worse than a missing feature — users learn that the UI lies to them.
- **Blocks downstream features**: Without working notification preferences, features like revision reminders, overwork alerts, and plan adjustments cannot be rolled out without a settings prerequisite.
- **Accessibility failure**: Screen reader users who navigate by toggles will activate switches that have no effect, receiving no feedback or error.
- **Maintenance debt**: Any future developer adding a new notification type must reverse-engineer whether to use the "Notification Preferences" section, the "Study Preferences" section, or both.

## Acceptance Criteria

1. Every `SwitchListTile` in the "Notification Preferences" section must persist its value to a dedicated field in `SettingsBox` (e.g., `revisionRemindersEnabled`, `lessonNotificationsEnabled`, `overworkAlertsEnabled`, `planAdjustmentNotificationsEnabled`) and reflect the persisted state on rebuild.
2. The "Study Reminders" switch in **"Study Preferences"** must be either:
   - Removed (with the master switch in "Notification Preferences" promoted to cover both sections), **or**
   - Linked to the same provider so that toggling one immediately updates the other and the UI stays in sync.
3. All subtitle strings must be reviewed so that parent and child switches do not share the same `l10n` key when their meaning differs.
4. A quick integration test must verify that:
   - Toggling each notification preference persists across a widget rebuild.
   - The duplicated study-reminders switch (if kept) reflects the same state as its counterpart.
5. No existing functional switch (theme, high contrast, large touch targets, reduce motion, focus-mode settings) should be broken by these changes.
