# `FocusSessionService` / `FocusSessionRepository`: Triplicated Provider Definitions & Uninitialized Repository Instances

## Context

The `FocusSessionService` and its backing `FocusSessionRepository` are defined **in three separate places**, each producing a distinct object graph. This creates state fragmentation, unused dead provider declarations, and a silent initialization failure path.

## Affected Files

| File | Lines | Role |
|---|---|---|
| `lib/features/focus_mode/providers/focus_mode_providers.dart` | 5–12 | Defines `focusSessionRepositoryProvider` and `focusSessionServiceProvider` |
| `lib/core/providers/app_providers.dart` | 176–184 | **Same providers defined again** (`focusSessionRepositoryProvider`, `focusSessionServiceProvider`) |
| `lib/features/dashboard/providers/dashboard_providers.dart` | 28–32 | Defines `dashboardFocusServiceProvider` with a **third** `FocusSessionRepository()` — never calls `init()` |
| `lib/features/dashboard/presentation/dashboard_screen.dart` | 75 | Workaround: manually calls `_focusService.repository.init()` |
| `lib/features/focus_mode/presentation/focus_timer_screen.dart` | 52–54 | Reads `focusSessionServiceProvider` then manually initialises repo via `_init(repo)` |
| `lib/core/services/engagement_scheduler.dart` | 160 | Creates yet another `FocusSessionRepository()` inline |

## Rationale

1. **Provider name collision** – `focusSessionRepositoryProvider` and `focusSessionServiceProvider` are top-level `Provider` declarations in **two different libraries** (`focus_mode_providers.dart` and `app_providers.dart`). When both are imported (which happens in `focus_timer_screen.dart` and `dashboard_screen.dart`), Riverpod treats the first read as authoritative; the duplicate declarations are dead code that mislead developers about which provider is actually in use and will cause subtle runtime confusion or crashes if both files are imported in the same scope.

2. **State fragmentation** – The dashboard creates its own `FocusSessionService` via `dashboardFocusServiceProvider` with a **separate** `FocusSessionRepository`. This means the dashboard's focus stats (`_focusTodayStats`) come from an entirely different repository instance than the one backing the timer on the Focus tab. A user who completes a focus session on the Focus tab will **not** see updated stats on the Dashboard unless both repositories happen to point at the same Hive box (which they do, by coincidence of Hive box names, but the in-memory state is duplicated and `currentSession` is never shared).

3. **`init()` never called by providers** – `FocusSessionRepository` requires `init()` to open the Hive box, yet **none** of the three provider definitions call it:
   - `focus_mode_providers.dart:6` → `return FocusSessionRepository();`
   - `app_providers.dart:177` → `return FocusSessionRepository();`
   - `dashboard_providers.dart:30` → `FocusSessionRepository()`
   
   The only reason the app doesn't crash is because `focus_timer_screen.dart` manually calls `repo.init()` inside `_init()`, and `dashboard_screen.dart` manually calls `_focusService.repository.init()`. This coupling between screens and low-level infrastructure violates the dependency-injection pattern the rest of the app follows.

4. **Dead code** – `lib/features/focus_mode/providers/focus_mode_providers.dart` is imported by `focus_timer_screen.dart` but its providers are functionally dead if `app_providers.dart` is already loaded (Riverpod deduplicates by identity, and the `app_providers.dart` version will always win when both are present in the provider scope). The file should either be removed entirely or consolidated into a single source of truth.

5. **`engagement_scheduler.dart` creates an ad-hoc repository instance** (line 160–161) despite `FocusSessionService` already being available through providers. This bypasses all provider infrastructure and the init contract entirely (though it does call `init()` inline — a sign the developer knew the provider pattern was broken).

## Acceptance Criteria

- [ ] `focusSessionRepositoryProvider` and `focusSessionServiceProvider` are declared in exactly **one** place (recommended: `lib/features/focus_mode/providers/focus_mode_providers.dart`)
- [ ] The duplicate declarations in `lib/core/providers/app_providers.dart` are **removed**
- [ ] `dashboardFocusServiceProvider` in `lib/features/dashboard/providers/dashboard_providers.dart` is replaced by referencing the canonical `focusSessionServiceProvider` (or removed if unused directly)
- [ ] `FocusSessionRepository.init()` is called as part of the provider's `build()` method (or the lazy-init pattern is replaced with eager opening via `HiveInitializer`)
- [ ] `engagement_scheduler.dart` uses the canonical provider instead of constructing its own `FocusSessionRepository()`
- [ ] All screens that manually call `.repository.init()` or `_init(repo)` remove those workarounds (the dependency should be ready by the time it is injected)
- [ ] No top-level `final focusSessionRepositoryProvider` / `focusSessionServiceProvider` declaration exists in more than one file

## Suggested Approach

1. Remove `focusSessionRepositoryProvider` and `focusSessionServiceProvider` from `app_providers.dart`.
2. Remove `dashboardFocusServiceProvider` from `dashboard_providers.dart`; have the dashboard screen read `focusSessionServiceProvider` from focus_mode's canonical location.
3. Make `FocusSessionRepository`'s `init()` either:
   - Called inside the `Provider` builder so every consumer gets an initialised instance, or
   - Replaced with eager box opening in `HiveInitializer` (the box is already opened there — the repository just needs to grab the already-open box instead of calling `openBox` again).
4. Update `engagement_scheduler.dart` to inject `FocusSessionService` instead of constructing its own repository.
5. Remove manual `init()` calls in `focus_timer_screen.dart:_init()` and `dashboard_screen.dart:_loadData()`.
