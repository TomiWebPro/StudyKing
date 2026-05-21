# StudyKing - Issues Log & Resolution

## Initial Setup

| # | Issue | Severity | Resolution | Status |
|---|-------|----------|------------|--------|
| 1 | `git` not installed in the environment | Blocking | Installed git via `apt-get` (`sudo apt-get install -y git`) | ✅ Fixed |
| 2 | `flutter`/`dart` not in PATH | Blocking | Found Flutter at `/home/tomi/development/flutter/bin/flutter`; added to PATH | ✅ Fixed |
| 3 | Missing Linux build dependencies (`cmake`, `clang`, `ninja-build`, `libgtk-3-dev`, `pkg-config`) | Blocking | Installed via `sudo apt-get install -y cmake clang ninja-build libgtk-3-dev pkg-config` | ✅ Fixed |
| 4 | Missing `libsecret-1-dev` (required by `flutter_secure_storage_linux` plugin) | Blocking | Installed via `sudo apt-get install -y libsecret-1-dev` | ✅ Fixed |

## Package Incompatibilities

| # | Issue | Severity | Resolution | Status |
|---|-------|----------|------------|--------|
| 5 | `record_linux 0.7.2` incompatible with `record_platform_interface 1.5.0` — missing `startStream` implementation and `hasPermission` has wrong signature | Build Error | Upgraded `record` from `^5.0.5` to `^6.0.0`, which pulled in `record_linux 1.3.0` with compatible API | ✅ Fixed |

## Build Issues

| # | Issue | Severity | Resolution | Status |
|---|-------|----------|------------|--------|
| 6 | Linux platform not configured (`flutter build linux` failed with "No Linux desktop project configured") | Blocking | Ran `flutter create --platforms=linux .` to add Linux support | ✅ Fixed |
| 7 | CMake install prefix defaulted to `/usr/local` causing permission denied during install | Build Error | Cleaned build directory (`rm -rf build/linux`) and rebuilt; CMake correctly used bundle directory on fresh build | ✅ Fixed |

## Runtime Crashes

| # | Issue | Severity | Resolution | Status |
|---|-------|----------|------------|--------|
| 8 | `Null check operator used on a null value` in `LoadingIndicator.build` (`lib/core/widgets/loading_indicator.dart:11`) — force-unwrapped `AppLocalizations.of(context)!` caused crash during splash screen before localization was ready | Crash | Changed to null-coalescing: `l10n?.loading ?? 'Loading'` (consistent with project's `l10n` null-coalesce pattern) | ✅ Fixed |
| 9 | `Bad state: No ProviderScope found` — `main()` called `runApp(StudyKingApp())` without wrapping in Riverpod's `ProviderScope` | Crash | Wrapped `StudyKingApp()` in `ProviderScope` in `lib/main.dart:129` | ✅ Fixed |
| 10 | `Invalid argument(s): Linux settings must be set when targeting Linux platform` from `flutter_local_notifications` in `NotificationService.init()` | Crash | Added `LinuxInitializationSettings` to `InitializationSettings` in `lib/core/services/notification_service.dart` | ✅ Fixed |

## Database / Repository Runtime Errors

| # | Issue | Severity | Resolution | Status |
|---|-------|----------|------------|--------|
| 11 | `LateInitializationError: Field '_box@77192761' has not been initialized` — `databaseProvider` (Riverpod) created a **separate** `DatabaseService` from the one initialized in `main.dart`, so its repositories never had `init()` called | `LateInitializationError` | Changed `databaseProvider` to return the already-initialized `DatabaseService` instance from `main.dart` (via global `_databaseService` and `initDatabaseService()`) | ✅ Fixed |
| 12 | `HiveError: box "X" is already open and of type Box<dynamic>` — `HiveInitializer` opened boxes as untagged `Box<dynamic>`, then repositories tried to open them as typed `Box<T>`, causing Hive type mismatch | Warning | Added `Hive.isBoxOpen` check + type mismatch fallback (close existing box and reopen with correct type) in `Repository.openBox()` | ✅ Fixed |
| 13 | `LateInitializationError` on `EngagementNudgeRepository._box` — provider-created nudge repo never had `init()` called because `dashboardInitProvider` only initialized `engagementAdherenceRepoProvider`, not `engagementNudgeRepoProvider` | `LateInitializationError` | Added `ref.watch(engagementNudgeRepoProvider).init()` to `dashboardInitProvider` in `lib/features/dashboard/providers/dashboard_data_providers.dart` | ✅ Fixed |

## Code Warnings (non-blocking)

| # | Issue | Severity | Resolution | Status |
|---|-------|----------|------------|--------|
| 14 | `onReorder` is deprecated in `subject_topics_tab.dart:346:15` — should use `onReorderItem` instead | Info | Could not fix automatically; `onReorderItem` has different API (adjusts newIndex for removed items) | ⚠️ Noted |
| 15 | `file_picker` plugin warnings about missing inline implementations for linux/macos/windows | Warning | Upstream package issue; non-blocking | ⚠️ Noted |

## Files Modified

| File | Change |
|------|--------|
| `lib/main.dart:129` | Wrapped `StudyKingApp()` in `ProviderScope` |
| `lib/main.dart:148-149` | Added `initDatabaseService(mainDb)` after DB init |
| `lib/core/widgets/loading_indicator.dart:11` | Changed `AppLocalizations.of(context)!` to `l10n?.loading ?? 'Loading'` |
| `lib/core/services/notification_service.dart:34-37` | Added `LinuxInitializationSettings` |
| `lib/core/data/repository.dart:11-33` | Made `openBox` resilient to already-open boxes with type mismatch |
| `lib/core/providers/shared_providers.dart:21-42` | Changed `databaseProvider` to use shared initialized instance |
| `lib/core/providers/app_providers.dart` | No change (reverted FutureProvider experiment) |
| `lib/features/dashboard/providers/dashboard_data_providers.dart:31` | Added `ref.watch(engagementNudgeRepoProvider).init()` |

## Build Output

```
✓ Built build/linux/x64/debug/bundle/studyking
```

## Verified Behavior

- Hive boxes open and initialize cleanly
- Database migrations run successfully
- All repositories initialize without `LateInitializationError`
- App renders Flutter UI without exceptions
- **Zero runtime crashes** on launch
