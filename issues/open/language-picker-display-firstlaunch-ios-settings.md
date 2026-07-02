# Language picker shows localized names, first-launch auto-detect not saved, no iOS Settings integration

**Severity:** minor
**Affected area:** Language/locale system — profile screen, locale provider, iOS configuration
**Reported by:** user

## Description

Three interrelated issues with the language/locale system:

### 1. Spanish language option shows English name in picker

In the Profile > Account Information > Language dropdown, when the app is in English, the Spanish option displays as **"Spanish"** instead of **"Español"**. This is confusing because users who want to switch to Spanish may not recognise the English name "Spanish" — especially if they are not fluent in English. The standard UX pattern across platforms (iOS Settings, Gmail, etc.) is to display each language in its own native name (e.g., "English", "Español", "Français") regardless of the current app locale.

### 2. First-launch system language auto-detection is not persisted

The `localeProvider` does detect the device locale on first launch (when no saved language exists), but the detected locale is **never saved to the user's profile**. This means:
- On every fresh launch where no saved language exists, the device locale is re-evaluated.
- If a user never explicitly opens and saves the Profile screen, their language preference is never persisted.
- If a user changes their system language, the app will silently follow it, which violates the expected "set once, keep forever" behaviour.

### 3. No iOS Settings.app integration

There is no `Settings.bundle` or `CFBundlePreferenceSpecifiers` configured for iOS. Users must open the app and navigate to Profile > Account Information to change the language. On Apple iPhone, language/appearance settings should be exposed via the system Settings app for convenience, consistent with other well-designed apps.

## Steps to reproduce

### Bug 1
1. Launch the app with the device language set to English (or any non-Spanish locale).
2. Navigate to Profile > Account Information.
3. Open the Language dropdown.
4. Observe that the Spanish option is labelled **"Spanish"** (English translation) instead of **"Español"** (native name).

### Missing feature 2
1. Launch the app for the very first time on a device set to Spanish (es).
2. The app correctly shows Spanish UI during the session.
3. Close and restart the app (without ever visiting Profile).
4. Observe that the language detection fires again — the preference is never persisted to the Hive profile box.

### Missing feature 3
1. Open the iOS Settings app on an iPhone.
2. Scroll to the StudyKing settings pane.
3. There is no StudyKing settings pane — no language options are exposed in the system Settings app.

## Expected behavior

### Bug 1 fix
- Every language in the picker should be displayed in its **own native name**:
  - English → `"English"`
  - Spanish → `"Español"`
  - (future languages → their native names)
- This should hold regardless of the current app locale.

### Feature 2 fix
- On the **very first launch ever** (no saved profile language), the system locale should be detected, used, and **automatically persisted** to the user's profile (via `SettingsRepository.saveProfileData()`).
- On all subsequent launches, the persisted language should be used. The device locale should **never** be re-evaluated after the first save.
- A boolean flag like `_languageInitialized` or a profile field like `languageAutoDetected` should be set to prevent re-detection.

### Feature 3 fix
- On iOS, a `Settings.bundle` should be created with a `CFBundlePreferenceSpecifiers` entry for the language option.
- The iOS app should register a `UserDefaults` suite or use `FlutterAppSettings`/`app_settings` plugin to synchronise the language preference between the app and system Settings.
- Changes made in iOS Settings should be reflected in the app immediately (or on next foreground).

## Actual behavior

### Bug 1
- `lib/l10n/app_en.arb:4875` defines `"localeEs": "Spanish"` — the English translation of the Spanish language name.
- The dropdown in `profile_screen.dart:432-435` uses `appLocale.localizedLabel(l10n)`, which calls the `_AppLocaleLabel` extension that maps `AppLocale.es → l10n.localeEs`. When the app locale is `en`, `l10n.localeEs` returns `"Spanish"`.
- Contrast this with `AppLocale` enum in `locale_config.dart:4-5` where native names are already correctly used: `en(Locale('en'), 'English')`, `es(Locale('es'), 'Español')`.

### Feature 2
- `shared_providers.dart:133-156` (`localeProvider`): The detection logic at lines 145-150 checks the device locale, but the result is **never written back to the profile**. The detected locale is only used in-memory for the current session.
- In `main.dart:168-173`, the saved profile language is loaded and set via `setInitialLanguageCode()`, but if the profile has no `language` field (first launch), nothing is saved.

### Feature 3
- No `ios/Runner/Settings.bundle` exists in the project.
- No iOS-specific plugin or native channel code is configured for settings exposure.

## Code analysis

### Bug 1: Localised language names in ARB files

**File:** `lib/l10n/app_en.arb:4871-4878`
```arb
"localeEn": "English",       // ✓ correct — native name
"localeEs": "Spanish",       // ✗ wrong — should be "Español"
```

**File:** `lib/l10n/app_es.arb:4863-4870`
```arb
"localeEn": "Inglés",        // ✓ correct — native name in Spanish
"localeEs": "Español",       // ✓ correct — native name
```

The English ARB file translates the Spanish name into English. It should use the native name `"Español"` instead.

**File:** `lib/features/settings/presentation/profile_screen.dart:12-17`
```dart
extension _AppLocaleLabel on AppLocale {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    AppLocale.en => l10n.localeEn,
    AppLocale.es => l10n.localeEs,
  };
}
```

The extension fetches the **translated** name of each language. This is correct only if the ARB values contain native names (e.g., `localeEs: "Español"` in all ARB files).

**File:** `lib/features/settings/presentation/profile_screen.dart:432-435`
```dart
items: AppLocale.values.map((appLocale) {
  return DropdownMenuItem(
    value: appLocale.locale.languageCode,
    child: Text(appLocale.localizedLabel(l10n)),
  );
}).toList(),
```

The dropdown uses `localizedLabel` which resolves to the translated ARB string. Since `app_en.arb` returns `"Spanish"` for `localeEs`, the dropdown shows the English translation.

Note: The `subtitle` at line 425-429 uses `AppLocale.displayName` which is hardcoded to native names in the enum, so it correctly shows `"Español"`. This is inconsistent with the dropdown.

### Feature 2: First-launch detection not persisted

**File:** `lib/core/providers/shared_providers.dart:133-156`
```dart
final localeProvider = StateProvider<Locale>((ref) {
  try {
    if (_initialLanguageCode != null && _initialLanguageCode!.isNotEmpty) {
      return Locale(_initialLanguageCode!);
    }
    if (Hive.isBoxOpen(HiveBoxNames.profile)) {
      final box = Hive.box(HiveBoxNames.profile);
      final lang = box.get('language', defaultValue: '') as String;
      if (lang.isNotEmpty) { return Locale(lang); }
    }
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    for (final supported in AppLocalizations.supportedLocales) {
      if (supported.languageCode == deviceLocale.languageCode) {
        return supported;  // ← in-memory only, never saved to profile
      }
    }
  } catch (e) { ... }
  return const Locale('en');
});
```

The device locale branch (lines 145-150) detects the language but never writes it back to the profile via `saveProfileData`. The result is purely in-memory.

**File:** `lib/main.dart:166-173`
```dart
// Load saved locale
final initProfileResult = await initSettingsRepo.getProfileData();
if (initProfileResult.isSuccess) {
  final profile = initProfileResult.data;
  if (profile != null && profile.language.isNotEmpty) {
    setInitialLanguageCode(profile.language);
  }
}
```

If the profile exists but `language` is empty (first launch), `_initialLanguageCode` stays null and no auto-save occurs.

### Feature 3: No iOS settings exposure

- No `ios/Runner/Settings.bundle` exists in the project.
- No native iOS code or Flutter plugin handles `UIApplication.openSettingsURLString` or `App-Prefs` integration.

## Suggested approach

### Fix 1: Use native language names in all ARB files

Change `lib/l10n/app_en.arb:4875`:
```arb
"localeEs": "Español",  // was: "Spanish"
```

The description at `@localeEs` should remain in English per the ARB convention. Do the same for any future language keys — always use the language's native name regardless of the ARB file's locale.

After changing the ARB file, regenerate Dart code:
```bash
bash scripts/gen_l10n.sh
```

### Fix 2: Auto-save detected language on first launch

In `main.dart`, after detecting the device locale (or in the `localeProvider`), add logic to auto-save the detected locale when `_initialLanguageCode` is null and no saved language exists:

**Option A (recommended): Save in `main.dart` after locale initialisation**
```dart
// After loading profile, if no saved language exists:
if (profile == null || profile.language.isEmpty) {
  final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
  final detectedLang = AppLocale.fromLocale(deviceLocale).locale.languageCode;
  setInitialLanguageCode(detectedLang);
  // Auto-save to profile so it's never re-detected
  await initSettingsRepo.saveProfileData(
    UserProfile(language: detectedLang),
  );
}
```

**Option B: Move persistence into `localeProvider`** — have the provider write back to Hive when it falls through to device locale detection. This is less clean because providers should not have side effects during construction.

Either way, introduce a guard (e.g., a simple `bool _languageInitialized = false` flag or a dedicated Hive key `'language_initialized'`) to ensure the system locale is used **only once ever** and never overwrites a user's explicit choice.

### Fix 3: iOS Settings bundle integration

1. Create `ios/Runner/Settings.bundle/` with a `Root.plist` containing a `CFBundlePreferenceSpecifiers` array with a `PSTitleValueSpecifier` or `PSMultiValueSpecifier` for language selection.
2. Use a Flutter plugin such as [`app_settings`](https://pub.dev/packages/app_settings) or handle the native channel manually to read/write the shared `UserDefaults` suite.
3. In the app's `AppDelegate`, register for `UserDefaults.didChangeNotification` to detect changes made in system Settings.
4. Wire the native iOS preference change back to the Dart `localeProvider` via a method channel or a shared Hive-backed store.

A simpler alternative: use a `shared_preferences` key that the `Settings.bundle` reads from via a `UserDefaults` suite identifier matching the app's App Group.

### Files to modify:
- `lib/l10n/app_en.arb` — change `"localeEs"` to `"Español"`
- `lib/l10n/generated/app_localizations_en.dart` — after regeneration
- `lib/core/providers/shared_providers.dart` — optionally refactor detection logic
- `lib/main.dart` — add auto-save of detected locale on first launch
- `ios/Runner/Settings.bundle/Root.plist` — new file for iOS settings integration
- `ios/Runner/AppDelegate.swift` or `ios/Runner/AppDelegate.m` — handle settings change notifications
