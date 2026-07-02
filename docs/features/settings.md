# Settings Feature

## Overview

The Settings feature provides comprehensive app configuration including API provider management, user profile, accessibility preferences, theme customization, data backup/restore, and LLM model selection. Settings are persisted in Hive with a dedicated settings box and profile box.

## Key Files

| Layer | Files |
|---|---|
| Services | `DataBackupService` |
| Repositories | `SettingsRepository` |
| Models | `SettingsBox`, `SettingsUpdate`, `UserProfile`, `ModelPrice`, `DynamicModel`, `AccessibilityPreferences`, `SettingsAPIKey`, `UsageRecord` |
| Providers | `dataBackupServiceProvider` |
| Screens | `SettingsScreen`, `ProfileScreen`, `ApiConfigScreen` |

## Core Services

### DataBackupService

Handles export and import of all app data:

- `collectAllBoxData()` — Collect records from all open Hive boxes
- `exportAllData({boxData, filename, compress, encryptionPassword})` — Export to `.skbak` (gzip + optional AES encryption) or `.json`
- `exportSingleBox(boxName, records)` — Export a single Hive box
- `restoreData(filePath, {encryptionPassword})` — Restore from backup file, decrypting if needed
- Uses `sha256`-derived AES-256-CBC encryption when a password is provided

### SettingsRepository

Provides typed access to Hive-stored settings:

- `init()` — Open settings and profile boxes
- `saveApiKey(service, key)` / `getApiKey(service)` — API key management
- `saveSettings(update)` / `getAllSettings()` — Bulk read/write of `SettingsUpdate` fields
- `saveProfile(profile)` / `getProfileData()` / `updateProfile(updates)` — Profile CRUD

## Settings Categories

### AI Configuration (ApiConfigScreen)

- Provider selection (OpenRouter, Ollama, OpenAI, custom)
- Primary API key and base URL
- Backup LLM provider with separate API key, base URL, and model
- Test connection button with real-time validation
- Model selection with search and pricing display

### Profile (ProfileScreen)

- User name, avatar icon, learning goal
- Language/locale selection (English, Spanish)
- Notification preferences toggle
- Preferred study time setting

### Accessibility & Display

- Theme mode (light/dark/system)
- Font size adjustment
- High contrast mode
- Bold text
- Reduce motion (disables animations)
- Large touch targets

### Study Reminders

- Study reminders toggle
- Daily reminder time (hour/minute)
- Revision reminders
- Lesson notifications
- Overwork alerts
- Plan adjustment notifications

### Data Backup

- Export all data as `.skbak` (compressed, optionally encrypted) or `.json`
- Restore from backup file via file picker
- Web support limitations noted

## Key Models

| Model | Purpose |
|---|---|
| `SettingsBox` | Hive type adapter with fields for API key, base URL, model, theme, font size, study stats, reminders, accessibility flags |
| `SettingsUpdate` | Partial update model with all mutable settings fields as nullable properties |
| `UserProfile` | Hive-stored profile with name, student ID, avatar, learning goal, language, accessibility prefs |
| `AccessibilityPreferences` | Bold text, high contrast, reduce motion, large touch targets |
| `DynamicModel` | LLM model info with provider, name, pricing data, metadata |
| `ModelPrice` | Per-model pricing with input/output/cache read costs and context window |
| `SettingsAPIKey` | Provider-scoped API key with optional encryption password |

## Data Flow

1. **App Start:** `SettingsRepository.init()` opens Hive boxes; `settingsProvider` (from core) reads all settings
2. **Reading:** Screens use `ref.watch(settingsProvider)` or `ref.read(settingsRepositoryProvider)` for reactive access
3. **Writing:** Changes flow through `SettingsUpdate` objects to `SettingsRepository.saveSettings()` which writes to the Hive box
4. **Reactivity:** The `settingsProvider` notifier invalidates on writes, causing dependent widgets to rebuild
5. **Encryption:** API keys can be stored encrypted via `SecureApiKeyProvider` (from core)
