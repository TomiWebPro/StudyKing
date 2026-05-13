# Internationalisation Master — Spanish Localisation Audit & i18n Infrastructure

## Summary

The app supports English (`en`) and Spanish (`es`) via `flutter_localizations` + ARB files (410 keys each). Below are actionable findings — from broken infrastructure blocking runtime locale switching, to Spanish translation quality issues. Fixing these for Spanish establishes a clean, reproducible pattern for adding future languages.

---

## Finding 1: Language Selector Does Not Change the App Locale (BROKEN)

**Severity:** Critical — functional bug

**Context:** The Profile screen (`lib/features/settings/presentation/profile_screen.dart:371-382`) renders a `DropdownButton<String>` with values `'en'` / `'es'`, but `onChanged` only calls `setState(() => _language = value)` (line 379). It **never** writes to the `localeProvider` defined in `lib/main.dart:55`. The `_language` value is persisted to the profile DB (line 94), but the `MaterialApp.locale` on line 235 of `main.dart` reads from `localeProvider`, which is **never updated** after initialisation.

```dart
// main.dart:55 — never written to after initialisation
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));
```

**Affected files:**
- `lib/main.dart:55` — localeProvider defined but never mutated downstream
- `lib/features/settings/presentation/profile_screen.dart:371-382` — dropdown updates local state only
- `lib/features/settings/presentation/profile_screen.dart:94` — language persisted but not consumed
- `lib/features/settings/data/models/settings_box.dart` — ProfileData contains `language` field but nothing bridges it to `localeProvider`

**Acceptance criteria:**
- Changing the language dropdown in Profile must immediately update the `MaterialApp` locale
- The chosen language must survive app restarts (loaded from profile DB → fed to `localeProvider`)
- Both `'en'` and `'es'` must render all UI strings correctly after switching

---

## Finding 2: No Device Locale Auto-Detection

**Severity:** Medium — poor UX for international users

**Context:** `lib/main.dart:55` hardcodes `const Locale('en')` as the default. There is no call to `WidgetsBinding.instance.platformDispatcher.locale` or any `LocaleResolutionCallback` on `MaterialApp`. A user whose device is set to `es-ES` (or any other locale) always sees English on first launch.

**Affected files:**
- `lib/main.dart:55` — hardcoded default

**Acceptance criteria:**
- App should detect and respect the device locale on first launch
- Only fall back to English if the device locale is unsupported
- Must integrate with the saved profile preference (explicit user choice overrides device locale)

---

## Finding 3: Spanish ARB — Inconsistent Register (tú / usted Mixing)

**Severity:** High — native speakers will perceive the app as unpolished

**Context:** The Spanish ARB (`lib/l10n/app_es.arb`) switches between formal *usted* and informal *tú* register within the same file, creating a jarring inconsistency.

**Formal (usted) examples** — correct for educational software aimed at students:
| Key | Spanish | Line |
|-----|---------|------|
| `fillAllFieldsCorrectly` | *Por favor **complete** todos los campos* | 73 |
| `enterYourName` | ***Ingrese** su nombre* | 472 |
| `yourStudentIdNumber` | *Su número de ID* | 480 |
| `pleaseEnterSubjectName` | *Por favor **ingrese** un nombre* | 802 |
| `tryAgain` | ***Intente** de nuevo* | 1354 |
| `configureApiKeysDescription` | ***Ingrese** sus credenciales* | 1415 |
| `reviewDueQuestions` | ***Repasar** preguntas pendientes* | 369 |

**Informal (tú) examples** — inconsistent:
| Key | Spanish | Line |
|-----|---------|------|
| `yourSubjects` | ***Tus** Materias* (informal possessive) | 227 |
| `yourStudySchedule` | ***Tu** Horario de Estudio* (informal possessive) | 51 |
| `yourAnswer` | ***Tu** Respuesta* (informal possessive) | 295 |
| `addSubjectsAndQuestionsToStartPracticing` | ***Agrega** materias* (informal imperative) | 174 |
| `addSubjectsFromSubjectsTab` | ***Agrega** materias* (informal imperative) | 178 |
| `noTopicsYetAddSome` | *¿No hay temas todavía? ¡**agrega** algunos!* (informal imperative) | 1646 |
| `noLessonsUsePlanner` | *¿No hay lecciones? ¡**usa** el Planificador para generar!* (informal imperative) | 1650 |
| `keepPracticing` | *¡**Siga** practicando...!* (formal) | 952 |
| `keepPracticingToUnlock` | *¡**Sigue** practicando...!* (informal) | 1768 |

**Rule:** Decide on ONE register (recommended: formal *usted* for educational software) and apply it consistently across all user-facing strings.

**Affected file:**
- `lib/l10n/app_es.arb` — ~15 keys need register normalisation

**Acceptance criteria:**
- All possessive adjectives use *su/sus* (not *tu/tus*)
- All imperative verbs use formal *usted* conjugation (-e/-a endings)
- The register choice is documented so future translations follow the same rule

---

## Finding 4: Duplicate `"medium"` Key in English ARB

**Severity:** High — structural bug in the source-of-truth template

**Context:** The English ARB (`lib/l10n/app_en.arb`) defines `"medium"` **twice**:
- Line 593: `"medium": "Medium"` — font-size label
- Line 1346: `"medium": "Medium"` — difficulty level label

JSON parsers / ARB generators handle duplicate keys inconsistently (last-wins). This means only **one** `medium` getter is generated. In English, both happen to be "Medium", so the bug is invisible. In the Spanish ARB (`lib/l10n/app_es.arb`), only the font-size translation *"Mediano"* is present (line 593), and the difficulty-level `"medium"` key is **absent**. The generated Spanish class therefore maps `l10n.medium` to *"Mediano"* in all contexts — correct for font size, but a translation error for difficulty (should be *"Medio"* or *"Media"*).

**Affected files:**
- `lib/l10n/app_en.arb:593,1346` — duplicate key
- `lib/l10n/app_es.arb:593` — only one `"medium"` entry, serving double duty
- `lib/l10n/generated/app_localizations.dart` — generated getter is ambiguous

**Acceptance criteria:**
- Rename font-size key to `fontSizeMedium` (or similar disambiguated key)
- Rename difficulty key to `difficultyMedium` (or similar)
- Update all `l10n.medium` references in Dart code to use the correct key
- Spanish: add `"difficultyMedium": "Medio"` (or the agreed translation)

---

## Finding 5: English Fallback for Color Names in `color_utils.dart`

**Severity:** Low-Medium — visible when context is unavailable

**Context:** `lib/core/utils/color_utils.dart:56-76` has a fallback `switch` block returning hardcoded English strings (`'Blue'`, `'Green'`, `'Orange'`, etc.). This code path runs when no `BuildContext` (and therefore no `AppLocalizations`) is available. While the first branch (lines 22-53) correctly uses `l10n`, the fallback is pure English.

**Affected file:**
- `lib/core/utils/color_utils.dart:55-76`

**Acceptance criteria:**
- Consider whether this fallback can ever be reached at runtime (if not, document it)
- If reachable, inject a locale-aware mechanism or remove the English fallback in favour of the raw hex string

---

## Finding 6: Examples/Hints Not Localised to Spanish Context

**Severity:** Low — cosmetic but noticeable

**Context:** Several hint/example strings in `lib/l10n/app_es.arb` copy English names and references without adapting them to a Spanish audience:

| English (app_en.arb) | Spanish (app_es.arb) | Issue |
|---|---|---|
| `"e.g., IB Physics"` | `"ej., Física IB"` | Abbreviation `ej.,` should be `p. ej.,` in formal Spanish |
| `"e.g., Dr. John Smith"` | `"ej., Dr. John Smith"` | Example uses an English name; should use a Spanish name (e.g., *Dr. Juan García*) |
| `"e.g., Final Exams, Certifications"` | `"ej., Exámenes Finales, Certificaciones"` | Same `ej.,` abbreviation issue |
| `"e.g., Evening (6-9 PM)"` | `"ej., Tarde (6-9 PM)"` | Same `ej.,` issue |

**Affected file:**
- `lib/l10n/app_es.arb:31-34, 488-498, 757-768, 818-828`

**Acceptance criteria:**
- All examples in the Spanish ARB should use culturally appropriate names and references
- Abbreviations should follow Spanish typographic conventions (`p. ej.` not `ej.,`)

---

## Finding 7: Missing Architectural Pattern for Adding New Languages

**Severity:** Medium — will cause friction when adding e.g. French, German, Portuguese

**Context:** To add a new language, a developer would need to:
1. Create a new `lib/l10n/app_XX.arb` file (easy)
2. Add `Locale('xx')` to `supportedLocales` in `lib/main.dart:244-247` (easy)
3. Add the locale to the generated delegate's `isSupported` check (auto-generated)
4. Re-run `flutter gen-l10n` (documented but not scripted)
5. Update the language dropdown in `ProfileScreen` to include the new option (manual)
6. Ensure the device-locale-detection logic (from Finding 2) includes the new locale

There is no `CONTRIBUTING.md` or `i18n.md` documenting this workflow.

**Acceptance criteria:**
- Create a brief `docs/i18n.md` (or equivalent) describing the 6-step process above
- Add a `scripts/gen_l10n.sh` (or npm script) so new translators can regenerate without remembering the exact command
- This document should be referenced from a PR template or contributing guidelines

---

## Priority Order for Fixing

1. **Finding 1 + 2** (locale switching + auto-detection) — functional bug, blocks all i18n work
2. **Finding 4** (duplicate `medium` key) — structural bug in the source ARB
3. **Finding 3** (register inconsistency) — highest impact on Spanish UX
4. **Finding 7** (documentation) — enables future contributors
5. **Finding 5 + 6** (fallback strings + examples) — polish items

---

*Generated by Internationalisation Master — issue focuses on Spanish as the reference locale so the same patterns can be applied when adding French, German, Portuguese, etc.*
