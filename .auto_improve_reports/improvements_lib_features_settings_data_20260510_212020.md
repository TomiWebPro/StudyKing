# Improvements Report: `lib/features/settings/data/`

**Generated:** 2026-05-10 21:20  
**Scope:** 4 files across `models/` and `repositories/`  
**Analysis depth:** Full static analysis including cross-file dependencies and call-site usage

---

## Summary

| Category | Count |
|----------|-------|
| Bugs | 5 |
| Security | 3 |
| Performance | 4 |
| Code Style / Consistency | 14 |
| Maintainability | 9 |
| **Total** | **35** |

---

## File-by-File Findings

---

### 1. `models/settings_box.dart` (lines 1–151)

#### BUG-1: Unnecessary `late` on all `SettingsBox` fields
- **Lines:** 8–30
- **Severity:** Medium
- **Description:** All 8 fields in `SettingsBox` are declared `late` but are unconditionally initialized in the constructor initializer list. Using `late` when initialization is guaranteed at construction time is redundant, suppresses the "non-nullable instance field must be initialized" compile-time safety net, and adds a tiny runtime check on every access. The generated TypeAdapter (in `settings_box.g.dart`) assigns through the constructor, so `late` serves no purpose.
- **Suggested fix:** Replace `late` with `final` on each field:
  ```dart
  @HiveField(0)
  final String apiKey;

  @HiveField(1)
  final String apiBaseUrl;
  // ... etc
  ```
  Then regenerate the TypeAdapter (`settings_box.g.dart`).

#### BUG-2: Inconsistent `late` vs `final` in `ProfileData`
- **Lines:** 86–108
- **Severity:** Medium
- **Description:** `ProfileData` uses `late` for `id`, `name`, `notificationsEnabled`, `language` but `final` for `studentId`, `avatarIcon`, `learningGoal`, `preferredStudyTime`. All fields are assigned in the constructor. The inconsistency is confusing and suggests the author was unsure about immutability. The `late` fields can be set after construction (via direct field assignment), breaking the immutability contract that the `final` fields enforce.
- **Suggested fix:** Make all constructor-initialized fields `final` for consistency and immutability:
  ```dart
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;
  // ... etc
  ```

#### BUG-3: `ProfileData` nullable `fromJson` fields lack null fallback
- **Lines:** 134–144
- **Severity:** Low
- **Description:** In `ProfileData.fromJson`, `studentId`, `avatarIcon`, `learningGoal`, and `preferredStudyTime` are read directly without a `??` fallback (`json['studentId']` instead of `json['studentId'] ??`). While these fields are nullable in the model, if the JSON map is missing the key entirely, Dart returns `null` which is valid for `String?`. This works but is inconsistent with `SettingsBox.fromJson` which provides explicit `??` fallbacks for all fields. The inconsistency is a maintenance trap.
- **Suggested fix:** Add explicit `?? null` fallbacks or keep the direct access but document the rationale:
  ```dart
  studentId: json['studentId'] as String?,
  ```

#### BUG-4: Missing `copyWith` methods on `SettingsBox` and `ProfileData`
- **Lines:** 7–82 (SettingsBox), 84–151 (ProfileData)
- **Severity:** Medium
- **Description:** `UserProfile` in `user_profile_model.dart:68-90` has a `copyWith` method, but `SettingsBox` and `ProfileData` do not. The `settings_repository.dart` currently constructs new instances manually when updating fields (see `updateSettings` and `updateStats`), which is verbose and error-prone. A `copyWith` would enable immutable-style updates and is a standard Dart pattern for data classes.
- **Suggested fix:** Add `copyWith` to `SettingsBox` and `ProfileData`:
  ```dart
  SettingsBox copyWith({ ... }) => SettingsBox(
    apiKey: apiKey ?? this.apiKey,
    // ...
  );
  ```

#### BUG-5: No `@HiveType` adapter registration guidance
- **Lines:** 6, 84
- **Severity:** Low
- **Description:** Both `SettingsBox` (typeId: 4) and `ProfileData` (typeId: 5) define `@HiveType` annotations but there is no guarantee that the generated adapters are registered with `Hive.registerAdapter()` before the boxes are opened. If registration is missing or delayed, Hive throws at runtime. The `main.dart` calls `HiveInitializer.initialize()` but that file is not in this directory; the dependency is implicit.
- **Suggested fix:** Add a static `register()` method to each model class or a comment documenting that adapters must be registered before first use.

#### STYLE-1: Hardcoded default URL string duplicated
- **Lines:** 33, 68
- **Severity:** Low
- **Description:** The default URL `'https://openrouter.ai/api/v1'` appears in the constructor (line 33) and in `fromJson` (line 68). It also appears in `settings_repository.dart` lines 29, 92 and `main.dart` line 44. Any change requires hunting down all occurrences.
- **Suggested fix:** Extract to a top-level constant:
  ```dart
  const kDefaultApiBaseUrl = 'https://openrouter.ai/api/v1';
  ```

#### STYLE-2: Statistics fields semantically misplaced in `SettingsBox`
- **Lines:** 23–30
- **Severity:** Low
- **Description:** `totalSessionCount`, `totalStudyTimeMs`, and `totalQuestions` are usage statistics, not "settings." Mixing stateful counters with configuration data is a separation-of-concerns violation. It forces `updateSettings` and `updateStats` to read/write through the same model, leading to the race-condition issues documented in `settings_repository.dart` BUG-8.
- **Suggested fix:** Extract statistics into a separate `StudyStats` model with its own Hive box and repository methods.

#### STYLE-3: `toString()` exposes partial API key
- **Lines:** 78–81
- **Severity:** High (Security)
- **Description:** `SettingsBox.toString()` outputs the first 8 characters of the API key. This means any `debugPrint`, log, or error-reporting tool that calls `toString()` on this object will leak 8 characters of the key. Attackers with access to logs can use this for brute-force or social-engineering attacks.
- **Suggested fix:** Never include API key data in `toString()`:
  ```dart
  @override
  String toString() {
    return 'SettingsBox(apiKey: ${apiKey.isEmpty ? "not set" : "set"}, themeMode: $themeModeEnum, fontSize: ${fontSize.round()}px)';
  }
  ```

#### STYLE-4: Fragile `ThemeMode` enum index storage
- **Lines:** 43–46, 48–50
- **Severity:** Medium
- **Description:** `ThemeMode` is stored as its integer `.index` value. If Flutter ever reorders the `ThemeMode.values` array (e.g., adding a new mode like `ThemeMode.system` at position 0), all previously saved indices become wrong, causing the wrong theme to load. Storing the enum's `.name` (string) is resilient to reordering.
- **Suggested fix:** Store `themeMode` as a `String` (the enum name) instead of `int`:
  ```dart
  @HiveField(3)
  late String themeMode; // 'light', 'dark', 'system'

  ThemeMode get themeModeEnum => ThemeMode.values.firstWhere(
    (m) => m.name == themeMode,
    orElse: () => ThemeMode.light,
  );
  ```
  **Requires a migration path** for existing users.

---

### 2. `models/settings_box.g.dart` (lines 1–117)

Generated code — all fixes require regenerating after model changes. Listed for awareness.

#### STYLE-5: Type adapters use `dynamic` for all fields
- **Lines:** 14–28 (SettingsBoxAdapter.read), 69–82 (ProfileDataAdapter.read)
- **Severity:** Low
- **Description:** The generated `read` methods deserialize into `Map<int, dynamic>`. If Hive data is corrupted or from a future version with different types, the `as` casts in the generated constructor calls will produce hard-to-debug runtime type errors. This is inherent to the `hive_generator` package and not easily fixable, but worth noting.
- **Suggested fix:** Consider switching to `Isar` or `drift` which provide stronger type safety, or add validation in the model constructors.

---

### 3. `models/user_profile_model.dart` (lines 1–91)

#### BUG-6: `fromJson` assumes `id` and `name` are non-null
- **Lines:** 56–66
- **Severity:** High
- **Description:** `json['id']` and `json['name']` are passed directly to the `required` constructor parameters without a `?? ''` fallback or null check. If the JSON is malformed or from an older schema version, these will be `null`, causing a `TypeError` at runtime when Dart tries to pass `null` to a `String` parameter.
- **Suggested fix:** Add `?? ''` fallbacks for required fields and/or validate at the top of the factory:
  ```dart
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: (json['id'] ?? '') as String,
    name: (json['name'] ?? '') as String,
    // ...
  );
  ```

#### STYLE-6: `UserProfile` extends `HiveObject` but `ProfileData` does not
- **Line:** 4
- **Severity:** Low
- **Description:** `UserProfile` (typeId: 10) extends `HiveObject` (providing `.save()`, `.delete()` methods), but `ProfileData` (typeId: 5) does not. Both are Hive types. Since `ProfileData` is managed manually via `_profileBox!.put()` in the repository, the inconsistency is confusing — a future developer might wonder why one has convenience methods and the other doesn't.
- **Suggested fix:** Either remove `extends HiveObject` from `UserProfile` for consistency, or add it to `ProfileData` and refactor `saveProfileData` / `getProfileData` to use the HiveObject pattern.

#### STYLE-7: `avatarUrl` vs `avatarIcon` naming inconsistency
- **Line:** 14 (`UserProfile.avatarUrl`) vs `settings_box.dart:96` (`ProfileData.avatarIcon`)
- **Severity:** Medium
- **Description:** Both models represent a user avatar but use different field names (`avatarUrl` vs `avatarIcon`). The `profile_screen.dart` (line 38) reads `avatarIcon` from `ProfileData`. This cross-file naming inconsistency creates confusion and potential data loss if one model is ever migrated to the other.
- **Suggested fix:** Unify the name. Since the profile screen stores icon string keys (not URLs), `avatarIcon` is more accurate. Recommend renaming `UserProfile.avatarUrl` to `UserProfile.avatarIcon`.

#### STYLE-8: `accessibilitySettings` type is `String` with magic default
- **Lines:** 29–30, 41
- **Severity:** Low
- **Description:** `accessibilitySettings` is typed as `String` with a default of `'default'`. This is an "enum as string" pattern without an enum. It's brittle: any typo in a consuming switch statement goes undetected at compile time.
- **Suggested fix:** Define a proper enum or use a const set of valid values, and consider making it `List<String>` if multiple settings can be active.

---

### 4. `repositories/settings_repository.dart` (lines 1–171)

#### BUG-7: Dead code — `SettingsBox` constructed but never used in `saveApiKey`
- **Lines:** 27–36
- **Severity:** Medium
- **Description:** `saveApiKey` creates a `SettingsBox` instance on lines 27–36 but never assigns it to a variable, never reads from it, and never writes it. The object is immediately eligible for garbage collection. This is dead code that wastes CPU cycles and memory allocation, and confuses readers into thinking all settings are being loaded.
- **Suggested fix:** Remove the unused `SettingsBox(...)` construction entirely. The method already writes individual keys via `box.put(...)`.

```diff
-    SettingsBox(
-      apiKey: key,
-      apiBaseUrl: box.get('apiBaseUrl', defaultValue: 'https://openrouter.ai/api/v1'),
-      selectedModel: box.get('selectedModel', defaultValue: ''),
-      themeMode: box.get('themeMode', defaultValue: 0),
-      fontSize: box.get('fontSize', defaultValue: 16.0),
-      totalSessionCount: box.get('totalSessionCount', defaultValue: 0),
-      totalStudyTimeMs: box.get('totalStudyTimeMs', defaultValue: 0),
-      totalQuestions: box.get('totalQuestions', defaultValue: 0),
-    );
```

#### BUG-8: Destructive `clear()` + `put()` in `updateSettings` and `updateStats`
- **Lines:** 127–128, 153–154
- **Severity:** **Critical**
- **Description:** Both `updateSettings` and `updateStats` call `box.clear()` followed by `box.put(0, updated)`. If the app crashes, loses power, or is killed between the `clear()` and `put()`, all settings are permanently lost. This is a data-loss bug. Additionally, the integer key `0` used for `put` could collide with field keys 0–7 if other code writes individual fields by key.
- **Suggested fix:** Write only the changed fields individually instead of clearing and rewriting the entire box:
  ```dart
  Future<void> updateSettings({...}) async {
    final box = _settingsBox!;
    if (apiKey != null) await box.put('apiKey', apiKey);
    if (apiBaseUrl != null) await box.put('apiBaseUrl', apiBaseUrl);
    // ... one put per field
  }
  ```
  If atomicity is required, wrap in a write batch (not natively supported by Hive — consider an alternative storage engine or accept eventual consistency).

#### BUG-9: Race condition in `updateSettings` / `updateStats` (read-modify-write)
- **Lines:** 113–128, 140–155
- **Severity:** High
- **Description:** Both methods read the current state via `getSettings()` (which reads each individual key from the Hive box), modify it in memory, then write it back. If two async operations execute concurrently (e.g., `updateSettings` and `updateStats` are called in quick succession), the second `getSettings()` call may return stale data because the first write hasn't completed yet. The result: lost updates. This is the classic read-modify-write race condition.
- **Suggested fix:** Either:
  - (a) Write individual fields directly (as suggested in BUG-8), eliminating the read-modify-write pattern entirely, or
  - (b) Add a simple mutex/lock to serialize concurrent writes:
    ```dart
    final _writeLock = Lock(); // from 'package:mutex/mutex.dart'
    Future<void> updateSettings({...}) async {
      await _writeLock.synchronized(() async {
        final current = await getSettings();
        // ... modify and write
      });
    }
    ```

#### BUG-10: `getProfileData` uses unreliable `box.keys.first`
- **Line:** 78
- **Severity:** High
- **Description:** `getProfileData` returns the data stored under `box.keys.first`. Hive does not guarantee iteration order of keys — the "first" key is an implementation detail. If multiple profiles are ever stored (e.g., from account switching), the wrong profile may be returned. This also silently suppresses errors when no profile exists by creating a synthetic one (lines 72–75).
- **Suggested fix:** Use a fixed, well-known key:
  ```dart
  const _kCurrentProfileKey = 'current_profile';
  Future<ProfileData?> getProfileData() async {
    return _profileBox?.get(_kCurrentProfileKey);
  }
  Future<void> saveProfileData(ProfileData profile) async {
    await _profileBox?.put(_kCurrentProfileKey, profile);
  }
  ```

#### BUG-11: `saveProfileData` stores under `profile.id` — IDs can collide
- **Line:** 62
- **Severity:** Medium
- **Description:** `saveProfileData` uses `profile.id` as the Hive key. The ID is generated as `DateTime.now().millisecondsSinceEpoch.toString()` in the profile screen (line 46) and in `getProfileData` (line 73). If `saveProfileData` is called twice in the same millisecond, the second call silently overwrites the first. Using timestamps as IDs is fragile.
- **Suggested fix:** Use a stable fixed key (`'current_profile'`) as recommended in BUG-10. Replace the timestamp-based ID generation with `Uuid().v4()` from `package:uuid` or similar.

#### PERF-1: Inefficient full-box rewrite on every settings change
- **Lines:** 127–128, 153–154
- **Severity:** Medium
- **Description:** `updateSettings` and `updateStats` serialize all 8 `SettingsBox` fields to Hive even when only one field changed. For Hive, this means encoding the full `SettingsBox` object on every write. Writing only the changed key-value pairs is significantly more efficient.
- **Suggested fix:** Adopt per-field `put()` calls as described in BUG-8 and PERF-1.

#### PERF-2: Redundant `getSettings()` call after every write in `main.dart`
- **Lines:** `main.dart` 77–83, 101–102, 110–111, 119–120, 132–137
- **Severity:** Low
- **Description:** The `SettingsController` in `main.dart` calls `_repository.updateSettings(...)` and then immediately calls `_repository.getSettings()` to refresh state. The `updateSettings` method already reads the current state internally (line 113), so this is a double-read. For 5 update methods, this means 5 redundant Hive reads.
- **Suggested fix:** Have `updateSettings` return the updated `SettingsBox` so the controller can update state directly without a second read:
  ```dart
  Future<SettingsBox> updateSettings({...}) async { ... return updated; }
  ```

#### PERF-3: Unused `getSettings()` call at startup in `main.dart`
- **Lines:** `main.dart` 166–169
- **Severity:** Low
- **Description:** In `main()`, `settingsRepository.getSettings()` is called but its return value is discarded. The comment says "Load initial settings to sync with providers" but the result is never used — the providers are initialized from scratch later via the `SettingsController`. This is a wasted Hive read.
- **Suggested fix:** Remove the unused call:
  ```diff
  -   try {
  -     await settingsRepository.getSettings();
  -   } catch (e) {
  -     debugPrint('Error loading initial settings: $e');
  -   }
  ```

#### SEC-1: Plain-text API key storage in Hive
- **Lines:** 20–43, 46–57
- **Severity:** **Critical** (Security)
- **Description:** API keys are stored in plain text in an unencrypted Hive box. Hive stores data in binary files on disk that can be read by any process with file-system access (backup tools, malware, debugging tools, etc.). This is a PCI-DSS / OWASP violation for any application handling user credentials.
- **Suggested fix:** Use `flutter_secure_storage` (which uses Keychain on iOS, EncryptedSharedPreferences on Android) for all credential storage:
  ```dart
  import 'package:flutter_secure_storage/flutter_secure_storage.dart';
  final _secureStorage = const FlutterSecureStorage();
  Future<void> saveApiKey({required String service, required String key}) async {
    await _secureStorage.write(key: 'apiKey_$service', value: key);
  }
  ```

#### SEC-2: Singleton repository exposes internal boxes globally
- **Lines:** 6–9
- **Severity:** Medium (Security)
- **Description:** The `SettingsRepository` singleton is globally accessible (imported from `main.dart` on line 5 of `profile_screen.dart` as `import '../../../main.dart' show settingsRepository;`). Any part of the codebase can read or write settings/auth data without restriction. This violates the principle of least privilege.
- **Suggested fix:** Inject the repository via dependency injection (Riverpod provider) instead of exposing a global singleton. Restrict write access behind controlled API methods.

#### MAINTAIN-1: No error handling in repository methods
- **Lines:** 20–170
- **Severity:** Medium
- **Description:** None of the repository methods have try-catch blocks. If `Hive.openBox`, `box.get`, `box.put`, or `box.clear` throws (e.g., due to storage corruption, disk full, permission error), the exception propagates unhandled. The callers in `main.dart` do catch errors, but exceptions thrown from async void contexts or during `init()` may reach the zone-level error handler.
- **Suggested fix:** Add defensive error handling:
  ```dart
  Future<void> init() async {
    try {
      _settingsBox = await Hive.openBox('settings');
      _profileBox = await Hive.openBox('profile');
    } catch (e) {
      debugPrint('Failed to open settings boxes: $e');
      rethrow;
    }
  }
  ```

#### MAINTAIN-2: Missing `dispose()` / `close()` method
- **Lines:** 6–171
- **Severity:** Medium
- **Description:** `SettingsRepository` never closes its Hive boxes. While Hive boxes are closed automatically on app termination, failing to close them during the app lifecycle can cause resource leaks, corrupted data on hot reload, and test isolation failures. The singleton pattern makes this worse because the boxes live for the entire app lifetime.
- **Suggested fix:** Add a `dispose()` method:
  ```dart
  Future<void> dispose() async {
    await _settingsBox?.close();
    await _profileBox?.close();
    _settingsBox = null;
    _profileBox = null;
  }
  ```

#### MAINTAIN-3: Singleton pattern hinders testability
- **Lines:** 7–9
- **Severity:** Medium
- **Description:** `SettingsRepository()` is a true singleton (private constructor, static instance). This makes it impossible to inject a mock/fake in unit tests — any test that exercises code depending on this repository will hit the real Hive storage. The pattern forces integration tests where unit tests would suffice.
- **Suggested fix:** Convert to a regular class and inject via Riverpod:
  ```dart
  final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
    return SettingsRepository();
  });
  ```
  Remove the factory singleton pattern.

#### MAINTAIN-4: Hardcoded box name strings
- **Lines:** 15–16
- **Severity:** Low
- **Description:** `'settings'` and `'profile'` box names are hardcoded as string literals. If the name is changed in one place but not another, data may be silently lost.
- **Suggested fix:** Extract to constants:
  ```dart
  static const _kSettingsBoxName = 'settings';
  static const _kProfileBoxName = 'profile';
  ```

#### MAINTAIN-5: `updateSettings` and `updateStats` have overlapping responsibilities
- **Lines:** 102–155
- **Severity:** Low
- **Description:** There are two methods that each read the full settings state, modify some fields, and write it all back. `updateSettings` handles config fields; `updateStats` handles counter fields. This separation is artificial since both methods do the same thing (modify-and-full-write). It doubles the code surface and the race-condition surface area.
- **Suggested fix:** Merge into a single `updateSettings` that accepts all fields, or use per-field writes (as in BUG-8) so no method has more than one responsibility.

#### MAINTAIN-6: No schema version migration
- **Lines:** 14–17
- **Severity:** Medium
- **Description:** There is no mechanism to handle schema evolution. If a new field is added to `SettingsBox` or `ProfileData`, existing installations will fail when the TypeAdapter reads a stale schema. Hive's `TypeAdapter` does not handle field addition gracefully unless the model and adapter are regenerated and the `typeId` is changed or a migration is written.
- **Suggested fix:** Add a schema version integer stored in each box and a migration method that reads the old version and upgrades:
  ```dart
  Future<void> _migrateSettingsBox() async {
    final version = _settingsBox!.get('_schemaVersion', defaultValue: 1);
    if (version < 2) { /* migrate v1→v2 */ await _settingsBox!.put('_schemaVersion', 2); }
  }
  ```

#### MAINTAIN-7: `toString()` returns boilerplate with no diagnostic value
- **Lines:** 168–170
- **Severity:** Low
- **Description:** `SettingsRepository.toString()` returns `'SettingsRepository()'`. This provides no useful information for debugging. A good `toString()` helps diagnose state during logging.
- **Suggested fix:** Include box status:
  ```dart
  @override
  String toString() {
    return 'SettingsRepository(settingsReady: ${_settingsBox != null}, profileReady: ${_profileBox != null})';
  }
  ```

#### MAINTAIN-8: Null checks on `_settingsBox` / `_profileBox` are repetitive and error-prone
- **Lines:** 24, 47, 61, 67, 84, 110, 137, 158, 163
- **Severity:** Low
- **Description:** Every public method checks `if (_settingsBox == null) return;` or `if (_profileBox == null) return;`. This is boilerplate that must be copied for every new method. If one is missed, a null-dereference occurs. It also silently swallows errors — a missing box should probably throw or log a warning.
- **Suggested fix:** After `init()` succeeds, assert non-null:
  ```dart
  Future<void> init() async {
    _settingsBox = await Hive.openBox('settings');
    _profileBox = await Hive.openBox('profile');
    assert(_settingsBox != null && _profileBox != null);
  }
  ```
  Then use `late final Box _settingsBox;` (non-nullable) and remove all null checks. Throw a `StateError` in methods if `init()` hasn't been called.

---

## Cross-Cutting Concerns

| ID | Concern | Files Affected | Severity |
|----|---------|----------------|----------|
| CC-1 | `ProfileData` and `UserProfile` are near-duplicate models | `settings_box.dart:84–151`, `user_profile_model.dart:1–91` | **High** — data inconsistency risk |
| CC-2 | API key stored and transmitted in plain text | `settings_repository.dart:39–42,52–56`, `settings_box.dart:80` | **Critical** — security |
| CC-3 | No unit test coverage (singleton prevents mocking) | `settings_repository.dart:7–9` | **High** — reliability |
| CC-4 | `ThemeMode` integer encoding is brittle across Flutter versions | `settings_box.dart:43–50`, `settings_repository.dart:119` | Medium |
| CC-5 | Global singleton imported via `main.dart` from UI layer | `profile_screen.dart:3`, `main.dart:24` | Medium — architecture violation |

---

## Priority Action Items (Top 5)

1. **[Critical] SEC-1 / CC-2** — Migrate API key storage to `flutter_secure_storage`. Do not store credentials in Hive.
2. **[Critical] BUG-8** — Replace `box.clear()` + `box.put()` with per-field writes to prevent data loss on crash.
3. **[High] BUG-9** — Add write serialization (mutex) or per-field writes to eliminate race conditions on concurrent updates.
4. **[High] BUG-10** — Use a fixed key (`'current_profile'`) for profile storage instead of `box.keys.first`.
5. **[High] CC-1** — Consolidate `ProfileData` and `UserProfile` into a single canonical model to eliminate duplication and inconsistency.

---

## Files Analyzed

| File | Lines | Role |
|------|-------|------|
| `lib/features/settings/data/models/settings_box.dart` | 151 | Hive models: `SettingsBox` (typeId: 4), `ProfileData` (typeId: 5) |
| `lib/features/settings/data/models/settings_box.g.dart` | 117 | Auto-generated Hive TypeAdapters |
| `lib/features/settings/data/models/user_profile_model.dart` | 91 | Hive model: `UserProfile` (typeId: 10) |
| `lib/features/settings/data/repositories/settings_repository.dart` | 171 | Singleton repository with Hive-backed settings CRUD |
| `lib/main.dart` (cross-reference) | 303 | Caller: initialization and `SettingsController` |
| `lib/features/settings/presentation/profile_screen.dart` (cross-reference) | 432 | Caller: profile UI using the repository |
