# Focus Mode systemic design language, accessibility, and layout inconsistencies

## Context

The Focus Mode feature (`lib/features/focus_mode/`) is one of five bottom-nav tabs and a core feature of the app (estimated study timer with break period). However, it was developed with a different set of conventions from the rest of the app, leading to a poor user experience that degrades overall app cohesion.

## Issues identified

### 1. Hardcoded English strings — no internationalization

Every other feature uses `AppLocalizations.of(context)` for all user-facing strings. Focus Mode hardcodes English in multiple files:

| File | Hardcoded strings |
|---|---|
| `focus_timer_screen.dart` | `'Focus Mode'` (AppBar title), `'New Focus Session'`, `'Duration'`, `'Refresh stats'`, `'Error starting session: '`, `'Daily Limit Reached'`, `'Break Time!'`, `'Session completed: '`, `'Focus for '`, `' minutes'`, `'OK'` (dialog), dialog body text |
| `focus_timer_widget.dart` | `'remaining'`, `'PAUSED'`, `'DONE!'`, `'Resume'`, `'Pause'`, `'End'`, `'Mark Complete'` |
| `focus_session_service.dart` | Any error messages or status logs |

**Severity**: High. Spanish-speaking users get a mixed English/Spanish interface.

### 2. Hardcoded semantic colors ignored in high-contrast mode

The rest of the app uses `Theme.of(context).colorScheme.*` for all colored elements. Focus Mode hardcodes semantic colors:

- `focus_timer_widget.dart:112,123,132` — uses `Colors.green` for completion states
- `focus_timer_widget.dart:130` — uses `Colors.orange` for paused state
- `focus_timer_screen.dart:233,238` — uses `Colors.orange` for break view icon and title

When a user enables **high-contrast mode** (via system settings or the accessibility preference), these hardcoded colors bypass the theme entirely, producing low-contrast or invisible elements.

**Severity**: High. Breaks WCAG SC 1.4.6 (contrast enhanced) for users who need high contrast.

### 3. Fixed-size timer circle does not respond to screen size

```dart
SizedBox(
  width: 260,
  height: 260,
  child: CircularProgressIndicator(...)
)
```

The `FocusTimerWidget` uses a hardcoded `260×260` box for the circular timer and `displaySmall` text (at a clamped 14–30px range). On phones `< 360px` wide (e.g., iPhone SE, small Android devices), this consumes nearly the full viewport width with no horizontal padding. On tablets, the 260px circle looks disproportionately small compared to available space.

The `displaySmall` font for the countdown digits also does not scale to accommodate longer strings (e.g., `01:23:45` when sessions exceed one hour), causing potential overflow or an inconsistent sizing experience.

**Severity**: Medium. Degrades experience on extreme screen sizes.

### 4. Pulse animation continues running when timer is paused

```dart
// In didUpdateWidget:
if (!widget.isActive && oldWidget.isActive) {
  _pulseController.stop();    // stops ONLY on transition to isActive=false
  _pulseController.reset();
}
```

When the user pauses the session, `widget.isActive` stays `true` — only `widget.isPaused` changes. The pulse `AnimationController` never stops. This means:

- The `_pulseController.repeat(reverse: true)` runs indefinitely during a paused session
- The `AnimatedBuilder` triggers rebuilds on every frame even though nothing is animating visually (pulse = 1.0 while paused)
- Wasted CPU/battery for no benefit

**Severity**: Medium. Performance regression during paused state.

### 5. No Riverpod dependency injection, inconsistent with the rest of the app

Every other feature injects services/repositories via Riverpod providers. Focus Mode manually instantiates:

```dart
final FocusSessionService _service = FocusSessionService(
  repository: FocusSessionRepository(),
);
```

This means:
- The `FocusSessionRepository` and `FocusSessionService` cannot be overridden for widget tests
- The repository `init()` is called inside `_init()` in the screen, making it impossible to test the screen without real Hive I/O
- The Dashboard feature already creates a `FocusSessionService` via a Riverpod provider (`dashboardFocusServiceProvider`) — creating a second, independent instance wastes resources and can lead to inconsistent state

**Severity**: High. Blocks automated widget testing and can cause state duplication bugs.

### 6. Daily-limit-reached AlertDialog uses hardcoded English and icon color

In `focus_timer_screen.dart:133`, the icon is hardcoded to `Colors.green`:

```dart
icon: const Icon(Icons.celebration, size: 48, color: Colors.green),
```

This bypasses the user's theme and high-contrast settings.

**Severity**: High. Compounds issues 1 and 2.

## Affected files

| File | Issues |
|---|---|
| `lib/features/focus_mode/presentation/focus_timer_screen.dart` | 1, 2, 5, 6 |
| `lib/features/focus_mode/presentation/widgets/focus_timer_widget.dart` | 1, 2, 3, 4 |
| `lib/features/focus_mode/services/focus_session_service.dart` | 1 (if any user-facing strings exist) |
| `lib/features/focus_mode/presentation/widgets/session_summary_card.dart` | 1, 2 (if any) |

## Rationale

Focus Mode occupies a primary navigation slot (one of 5 bottom tabs), yet it feels like a separate app bolted onto StudyKing. Users who switch between features immediately notice the inconsistency: the Practice screen uses translated strings and theme-aware colors, but the Focus timer shows hardcoded English in raw green/orange. For accessibility users who rely on high-contrast mode, the hardcoded colors can render text invisible. For Spanish-speaking users, the feature is partially broken. For developers, the lack of Riverpod injection makes widget tests impossible without real Hive IO — a significant quality gap.

## Acceptance criteria

1. All user-facing strings in `focus_timer_screen.dart`, `focus_timer_widget.dart`, and `session_summary_card.dart` are replaced with `AppLocalizations.of(context)!` lookups
2. All hardcoded `Colors.green` and `Colors.orange` uses in these files are replaced with `Theme.of(context).colorScheme.*` equivalents
3. The `FocusTimerWidget` timer circle (`SizedBox(width: 260, height: 260)`) is replaced with a responsive size derived from `MediaQuery.sizeOf` or `LayoutBuilder`, with minimum 200px and maximum 80% of available width
4. The pulse animation stops when `isPaused` is true (not just when `isActive` becomes false)
5. `FocusSessionService` and `FocusSessionRepository` are provided via Riverpod providers (in a new `focus_mode/providers/` directory), and `FocusTimerScreen` uses `ref.read`/`ref.watch` to obtain them
6. The daily-limit-reached dialog uses `Theme.of(context).colorScheme.primary` for the icon color instead of `Colors.green`
7. A widget test for `FocusTimerScreen` exists (using test overrides for the new Riverpod providers) that verifies the setup→active→break flow renders correctly
