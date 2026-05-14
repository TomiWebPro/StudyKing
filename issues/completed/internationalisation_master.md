# Internationalisation Audit: Hardcoded Strings & Spanish Register Violations

## Summary

The app has two high-impact i18n defects: (1) user-facing strings hardcoded in English in source code, bypassing the `AppLocalizations` l10n system entirely, and (2) a Spanish formal register violation (`tú`/`usted` mismatch) in `app_es.arb`. Both issues block adding new languages and degrade the UX for Spanish-speaking users.

---

## Issue 1: Hardcoded English Strings in Source Code

The following files contain user-visible strings that are **not routed through `AppLocalizations.of(context)`**. These strings will always appear in English regardless of the user's selected locale.

### Affected Files

| File | Hardcoded Strings |
|---|---|
| `lib/features/settings/presentation/settings_screen.dart:158` | `'Focus Mode'` (section title) |
| `lib/features/settings/presentation/settings_screen.dart:159` | `'Focus Timer'` + `'Start a focused study session'` (list tile) |
| `lib/features/settings/presentation/settings_screen.dart:161` | `'Daily Study Cap'` (list tile) |
| `lib/features/settings/presentation/settings_screen.dart:399-406` | `'$cap min/day'`, `'No limit'` (`_getDailyCapLabel()`) |
| `lib/features/settings/presentation/settings_screen.dart:419` | `'No limit'` + `'$m minutes'` (dialog options) |
| `lib/features/planner/providers/planner_providers.dart:157` | `'Plan generated successfully'` (success message) |
| `lib/features/planner/providers/planner_providers.dart:162` | `'Failed to generate plan'` (error message) |
| `lib/features/questions/presentation/widgets/math_expression_widget.dart:384` | `'Expression: '` (label prefix) |
| `lib/features/sessions/services/session_export_service.dart:23-24` | CSV headers: `'Session ID,Student ID,...'` |
| `lib/features/mentor/services/mentor_service.dart:161-202` | LLM context prompt strings: `'No plan adherence data available.'`, `'Subjects: '`, `'No badges yet'`, etc. |
| `lib/features/teaching/services/conversation_manager.dart:192-225` | AI tutor system prompt: `'The student is doing well. Accelerate pace.'`, `'Start the lesson warmly.'`, etc. |

### Rationale

Every hardcoded string is a **blocker** for any new locale. A Spanish speaker navigating the Settings screen sees "Focus Mode" and "No limit" while the rest of the app is in Spanish. Adding French or German would require source-code changes instead of just new ARB files. The AI system prompts (`conversation_manager.dart`, `mentor_service.dart`) instruct the LLM to respond in English because the prompts themselves are English, defeating the `quickGuideSystemPrompt` key that tells the AI to respond in Spanish.

### Required ARB Keys (to be added to both `app_en.arb` and `app_es.arb`)

- `focusModeSection` — "Focus Mode"
- `focusTimer` — "Focus Timer"
- `startFocusedSession` — "Start a focused study session"
- `dailyStudyCap` — "Daily Study Cap"
- `noLimit` — "No limit"
- `minutesPerDay` — "{minutes} min/day"
- `planGeneratedSuccessfully` — "Plan generated successfully"
- `failedToGeneratePlan` — "Failed to generate plan"
- `expressionLabel` — "Expression: "
- `planAdherenceUnavailable` — "No plan adherence data available." (same for other mentor context strings)

---

## Issue 2: Spanish Formal Register Violation — Mixed `tú`/`usted`

The project convention (`docs/i18n.md`) mandates formal **usted** register for all Spanish translations. One key violates this:

### Affected Key

**`uploadOrPasteData`** in `lib/l10n/app_es.arb:1078`

```json
"uploadOrPasteData": "Sube o pegue datos para visualizar"
```

- `Sube` — **informal *tú* imperative** (wrong)
- `pegue` — **formal *usted* imperative** (correct)

This mixes registers in a single sentence.

### Other Keys to Verify for Ensuring Consistency

| Key (app_es.arb) | Current Value | Check Against |
|---|---|---|
| `addSubjectsAndQuestionsToStartPracticing` | `"Agregue materias..."` — formal `Agregue` ✅ | — |
| `practiceSpecificTopics` | `"Practique temas..."` — formal `Practique` ✅ | — |
| `focusOnMistakes` | `"Concéntrese en sus errores"` — formal `Concéntrese` ✅ | — |
| `uploadOrPasteData` | `"Sube o pegue..."` — **informal `Sube`** ❌ | Must be `"Suba o pegue..."` |

### Required Fix

Change `app_es.arb:1078` from:
```json
"Sube o pegue datos para visualizar"
```
to:
```json
"Suba o pegue datos para visualizar"
```

Also regenerate Dart code with `bash scripts/gen_l10n.sh`.

---

## Acceptance Criteria

- [ ] All strings listed in Issue 1 are extracted to ARB keys in both `app_en.arb` and `app_es.arb`.
- [ ] Each affected source file uses `AppLocalizations.of(context)!.<key>` instead of the hardcoded literal.
- [ ] `uploadOrPasteData` in `app_es.arb` is changed to use formal imperative (`Suba`).
- [ ] `bash scripts/gen_l10n.sh` is run and `app_localizations_es.dart` is regenerated with the fix.
- [ ] The `test/l10n/app_localizations_test.dart` test for `uploadOrPasteData` (es) is updated to match `"Suba o pegue datos para visualizar"`.
- [ ] AI tutor/mentor system prompts (`conversation_manager.dart`, `mentor_service.dart`) are either localized or include a language instruction in the matching locale's prompt key (e.g., `quickGuideSystemPrompt`).
- [ ] Lint: `grep -rn "'[A-Z][a-z]" lib/features/ lib/core/ | grep -v '.arb' | grep -v 'import'` returns no user-facing hardcoded strings.

---

## Additional Context

The `docs/i18n.md` already provides detailed guidelines for adding new languages (steps 1–7) and a PR review checklist for Spanish translations. Hardcoded strings are not covered by the coverage test (`test/l10n/app_localizations_coverage_test.dart`), which only checks ARB key parity, not whether the keys are actually used. A future improvement could add a lint rule banning bare string literals in widget trees.
