# Spanish Localisation Quality Audit

## Summary

Audit of `lib/l10n/app_es.arb` and hardcoded strings in `lib/main.dart` and `lib/core/widgets/` reveals four distinct classes of i18n defects that degrade the Spanish user experience and block clean addition of future locales.

---

## Issue 1: Hardcoded strings in `lib/main.dart` bypassing `AppLocalizations`

Two strings in `MainScreen.build()` render in English regardless of the selected locale.

| Location | Current value | Problem |
|---|---|---|
| `lib/main.dart:242` | `tooltip: 'Dashboard'` | `l10n.dashboard` (→ `"Panel"`) exists in both ARB files but is not used. The FAB tooltip remains `'Dashboard'` in Spanish mode. |
| `lib/main.dart:272` | `label: 'Focus'` | No ARB key for a simple `"focus"` nav label exists. The bottom navigation tab shows `'Focus'` even when the locale is `es`. Nearby tabs (`subjects`, `practice`, `mentor`, `settings`) all use `l10n.*` correctly. |

**Rationale:** These are regressions from the i18n pattern used everywhere else in the codebase (`final l10n = AppLocalizations.of(context)!`). They cause a disjointed experience where 80% of the UI is in Spanish but key navigation elements remain English.

**Action required:**
1. Replace `tooltip: 'Dashboard'` with `tooltip: l10n.dashboard`.
2. Add a new key `"focus"` to both ARB files (English: `"Focus"`, Spanish: `"Concentración"` or `"Enfoque"`), regenerate, and use it at line 272.

---

## Issue 2: Inconsistent Spanish formality register (tú / usted)

Most of `app_es.arb` uses formal *usted* imperative and possessive forms, which is the safe default for an educational/professional app. Two strings break this convention by using informal *tú* forms.

| Key | Current Spanish | Register | Expected (formal) |
|---|---|---|---|
| `focusForMinutes` (`lib/l10n/app_es.arb:3114`) | `"Enfócate por {minutes} minutos"` | Informal tú | `"Enfóquese por {minutes} minutos"` |
| `dailyLimitReachedBody` (`lib/l10n/app_es.arb:3101`) | `"Has alcanzado tu límite diario…"` | Informal tú | `"Ha alcanzado su límite diario…"` |

**Rationale:** A mixed register is jarring to native speakers. The app should be consistent — either all *usted* (recommended for this domain) or all *tú*. Currently ~696 keys use formal register while 2 keys use informal.

**Action required:** Change the two keys above to use formal *usted* imperative/possessive forms.

---

## Issue 3: Spanish `@@description` strings in `app_es.arb` (breaking ARB convention)

The `@@description` field in ARB files is metadata for translators and MUST match the template locale (English). Thirteen keys have descriptions written in Spanish instead of English.

| `app_es.arb` lines | Keys affected |
|---|---|
| 3011–3091 | `markschemeUnavailable`, `answerTooShort`, `goodResponseLength`, `answerTooShortForCredit`, `noDrawingDetected`, `invalidDrawingData`, `allStepsIdentified`, `specialHandlingRequired`, `someAnswersIncorrect`, `correctAnswerIs`, `allStepsFormat`, `partialStepsFormat`, `noStepsFormat`, `allRequiredStepsMissing` |

Example:
```json
// app_es.arb (WRONG — description in Spanish)
"markschemeUnavailable": "No hay esquema de calificación disponible",
"@markschemeUnavailable": {
  "description": "Mensaje cuando no hay un esquema de calificación para una pregunta"
}

// app_en.arb (correct — description in English, the template language)
"markschemeUnavailable": "No markscheme available",
"@markschemeUnavailable": {
  "description": "Message when no markscheme exists for a question"
}
```

**Rationale:** These descriptions are shown to translators when adding a new locale (e.g. `app_fr.arb`). Spanish descriptions are meaningless to a French translator who doesn't speak Spanish. They must be in English, which is the agreed template language.

**Action required:** Copy the English `@@description` values from `app_en.arb` for each key into `app_es.arb`, overwriting the Spanish text.

---

## Issue 4: Untranslated English loanword in Spanish ARB

| Key | `app_es.arb` value | Expected translation |
|---|---|---|
| `roadmaps` (`lib/l10n/app_es.arb:2852`) | `"Roadmaps"` | `"Hojas de ruta"` or `"Rutas de aprendizaje"` |

**Rationale:** Every other string in `app_es.arb` is a proper Spanish translation. Leaving an English word is a gap that stands out.

**Action required:** Translate to an appropriate Spanish equivalent.

---

## Extensibility note

The underlying ARB + `flutter gen-l10n` infrastructure is sound and well-tested. Once the above defects are fixed, adding a third locale (e.g. French `app_fr.arb`) requires only:
1. Copying `app_en.arb` → `app_fr.arb`
2. Translating all values (descriptions stay in English)
3. Adding `Locale('fr')` to `supportedLocales` in `lib/main.dart:130`
4. Adding the locale code to `l10n.yaml`

No structural changes are needed — the i18n architecture already supports an arbitrary number of locales.

---

## Acceptance criteria

- [ ] `lib/main.dart:242` uses `l10n.dashboard` instead of `'Dashboard'`
- [ ] `lib/main.dart:272` uses a new `l10n.focus` key instead of `'Focus'`
- [ ] ARB keys `"focus"` added to `app_en.arb` and `app_es.arb`, code regenerated
- [ ] `focusForMinutes` uses formal imperative `"Enfóquese"` consistently
- [ ] `dailyLimitReachedBody` uses formal `"Ha alcanzado su"` consistently
- [ ] All `@@description` fields in `app_es.arb` are in English (copy from `app_en.arb`)
- [ ] `roadmaps` translated to Spanish (`"Hojas de ruta"` / `"Rutas de aprendizaje"`)
- [ ] `flutter gen-l10n` succeeds with zero warnings
- [ ] Coverage test `test/l10n/app_localizations_coverage_test.dart` still passes
- [ ] Visual inspection: switch app to Spanish, confirm FAB tooltip, nav label, focus timer, and daily limit dialog show correct Spanish text
