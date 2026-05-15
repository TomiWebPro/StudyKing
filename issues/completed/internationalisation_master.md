# Dashboard & Settings: Hardcoded English strings bypassing ARB l10n system

## Context

The codebase has a well-established ARB-based l10n system (2,213 keys, `en` + `es`). However, several high-traffic screens contain hardcoded English strings that bypass `AppLocalizations.of(context)!`, so Spanish users see English text on critical UI surfaces.

## Translation mistakes / inappropriate localisation

Most Spanish ARB translations are correct. The root cause is **code that ignores existing ARB keys** — not mistranslation of the ARB file itself. The Spanish translations exist but are never rendered because the code passes raw English string literals to `Text()` instead of `l10n.someKey`.

## Affected files

### 1. `lib/features/dashboard/presentation/dashboard_screen.dart` (lines 88–164)

Seven of the eight `CollapsibleCard` titles use hardcoded English in `_cardTitle(...)`:

| Line | Hardcoded string | Existing ARB key | Spanish translation (already in `app_es.arb`) |
|---|---|---|---|
| 88 | `'Summary'` | **missing** — needs new key | — |
| 96 | `'Focus Time'` | `focusTime` | `"Tiempo de Enfoque"` |
| 113 | `'Weekly Activity'` | `weeklyActivity` | `"Actividad Semanal"` |
| 121 | `'Plan Adherence'` | `planAdherence` | `"Adherencia al Plan"` |
| 132 | `'Mastery Overview'` | `masteryOverview` | `"Resumen de Dominio"` |
| 140 | `'Weak Areas'` | `weakAreas` | `"Áreas por mejorar"` |
| 153 | `'Topic Performance'` | `topicPerformance` | `"Rendimiento por Tema"` |
| 164 | `'Achievements'` | `achievements` | `"Logros"` |

For `'Summary'` a new key must be added to both ARB files (e.g. `"summary": "Summary"` / `"summary": "Resumen"`).

### 2. `lib/features/settings/presentation/settings_screen.dart` (lines 159–165)

```dart
_section('Focus Mode', [
  _tile('Focus Timer', 'Start a focused study session', ...),
  _tile('Daily Study Cap', _getDailyCapLabel(), ...),
]),
```

- `'Focus Mode'` → use existing `focusMode` key (`"Modo de Enfoque"` in `app_es.arb`)
- `'Focus Timer'` → use existing `focusTime` key (`"Tiempo de Enfoque"`)
- `'Start a focused study session'` → **missing** — needs new key
- `'Daily Study Cap'` → **missing** — needs new key

### 3. `lib/features/settings/presentation/settings_screen.dart` (lines 400–421, `_getDailyCapLabel` and `_showDailyCapDialog`)

```dart
return cap > 0 ? '$cap min/day' : 'No limit';
// ...
title: Text(m == 0 ? 'No limit' : '$m minutes'),
```

- `'No limit'` → **missing** — needs new key in both ARB files
- `'$cap min/day'` / `'$m minutes'` → should use `minutesValue` key (already exists: `"{count} minutos"`)

### 4. `lib/features/planner/presentation/planner_screen.dart` (lines 147–148)

```dart
labelText: 'Subject ID (optional)',
hintText: 'e.g. sub_physics',
```

The profile screen already has `studentIdOptional: "Student ID (Optional)"` in ARB — the planner should reuse this key instead of hardcoding.

### 5. `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart` (lines 109–125)

```dart
Text('Token Usage Summary'),
_buildUsageStat(context, 'Total Tokens', ...),
_buildUsageStat(context, 'Total Cost', ...),
_buildUsageStat(context, 'Done', ...),
_buildUsageStat(context, 'Failed', ...),
```

All five strings are hardcoded. ARB keys exist for `done` and `failed`; new keys needed for `'Token Usage Summary'`, `'Total Tokens'`, and `'Total Cost'`.

## Rationale

1. **Dashboard** is the app's landing screen — the first thing Spanish users see. Having English card titles (`Plan Adherence`, `Weak Areas`, etc.) on this screen is the most visible l10n defect.
2. **Settings** is where users configure their experience. Untranslated section headers diminish trust.
3. **Planner** and **LLM Task Manager** are secondary but still actively used screens.
4. All fixes follow the existing, well-tested pattern (`AppLocalizations.of(context)!`) already used in 182+ places across the codebase.
5. Adding a `summary` key and a `noLimit` key to the ARB files establishes reusable translations for future screens.

## Acceptance criteria

- [ ] `lib/features/dashboard/presentation/dashboard_screen.dart` uses `l10n.focusTime`, `l10n.weeklyActivity`, `l10n.planAdherence`, `l10n.masteryOverview`, `l10n.weakAreas`, `l10n.topicPerformance`, `l10n.achievements`, and a new `l10n.summary` key instead of hardcoded strings.
- [ ] `lib/features/settings/presentation/settings_screen.dart` uses `l10n.focusMode`, `l10n.focusTime`, and new keys for `'Start a focused study session'`, `'Daily Study Cap'`, and `'No limit'` / `'$cap min/day'`.
- [ ] `lib/features/planner/presentation/planner_screen.dart` uses `l10n.studentIdOptional` instead of `'Subject ID (optional)'` and a new key for `'e.g. sub_physics'`.
- [ ] `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart` uses `l10n.done`, `l10n.failed`, and new keys for `'Token Usage Summary'`, `'Total Tokens'`, `'Total Cost'`.
- [ ] New translation keys (`summary`, `noLimit`, `focusTimerDescription`, `dailyStudyCap`, `tokenUsageSummary`, `totalTokens`, `totalCost`, `subjectIdHint`) are added to both `app_en.arb` and `app_es.arb` with proper `@` metadata annotations.
- [ ] `flutter gen-l10n` regenerates without errors.
- [ ] Existing l10n tests (`test/l10n/*`) still pass.
- [ ] Visual verification on both `en` and `es` locales confirms no hardcoded English remains on these screens.
