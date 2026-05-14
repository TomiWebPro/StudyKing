# Internationalisation: Spanish Localization Audit & Hardcoded String Remediation

## Context

The app supports English (`en`) and Spanish (`es`) via `flutter_localizations` (ARB-based). Two ARB files exist at `lib/l10n/app_en.arb` and `lib/l10n/app_es.arb` with ~300 keys. The generated Dart classes live in `lib/l10n/generated/`. Despite good coverage, several issues degrade the UX for Spanish-speaking users and set a poor pattern for adding future languages.

## Issues Found

### 1. Hardcoded English Strings Bypassing l10n (5 occurrences)

| File | Line(s) | String | Impact |
|------|---------|--------|--------|
| `lib/features/subjects/presentation/subject_detail_view.dart` | 611, 614 | `'Upload Content'` (semantics + Text) | Even though `l10n.uploadContent` exists in ARB, the code uses a hardcoded literal. Spanish users see English. |
| `lib/features/subjects/presentation/subject_detail_view.dart` | 629, 632 | `'Dashboard'` (semantics + Text) | Missing ARB key entirely. Spanish users see English. |
| `lib/core/widgets/canvas_drawing_widget.dart` | 81, 89 | `'Clear'`, `'Save Drawing'` | Missing ARB keys. Spanish users see English. |
| `lib/features/settings/presentation/settings_screen.dart` | 452 | `'Retry'` | `l10n.retry` exists in ARB but is not used here. |

### 2. Inconsistent Register: Formal vs. Informal Address in Spanish

The app uses **formal ("usted")** address in most screens (settings, subjects, practice):
- `"complete"`, `"agregue"`, `"seleccione"`, `"su"`

But the Mentor feature consistently uses **informal ("tú")** address:
- `"tienes"`, `"tus lecciones"`, `"Te gustaría"`, `"has empezado"`, `"has añadido"`

This tonal inconsistency is noticeable to native speakers. Example strings in `app_es.arb`:
- Line 1963: `"Aún no tienes lecciones programadas. ¿Te gustaría..."` (informal)
- Line 609: `"Por favor complete todos los campos correctamente"` (formal imperative)

**Action:** Choose one register and apply it consistently across all Spanish strings. The prevailing formal register in the rest of the app suggests the Mentor strings should be converted to formal ("usted") as well.

### 3. Unlocalized Enum-Derived Display Strings

In `lib/features/practice/presentation/practice_session_screen.dart:330`:
```dart
AppLocalizations.of(context)!.practiceModeType(
    AppLocalizations.of(context)!.spacedRepetitionMode,
    question.type.name,  // <-- raw English enum name
)
```

`question.type.name` returns the Dart enum value name (e.g., `"multipleChoice"`, `"essay"`) which is displayed directly to the user in the app bar. The question type labels *are* available in l10n (`l10n.multipleChoice`, `l10n.essay`, etc.) but the code never maps to them.

**Fix:** Replace `question.type.name` with a mapping function that returns the localized label.

### 4. Obsolete/Inconsistent ARB Key for Mastery Level

`app_es.arb` line 1668:
```json
"masteryLevelBrowsing": "Iniciado"
```
The English "Browsing" represents someone exploring a topic. "Iniciado" (initiated/begun) shifts the meaning. For consistency with mastery-level progression (Novice → Browsing → Developing → Proficient → Expert), a better translation would be "Explorando".

### 5. Minor Grammar / Capitalization Issues in Spanish

| ARB Key | Current | Suggested |
|---------|---------|-----------|
| `noLessonsUsePlanner` | `"¿No hay lecciones? ¡use el Planificador para generar!"` | `"¿No hay lecciones? ¡Use el Planificador para generar!"` — Capitalize after `¡` |
| `noTopicsYetAddSome` | `"¿No hay temas? ¡agregue algunos!"` | `"¿No hay temas? ¡Agregue algunos!"` — Capitalize after `¡` |
| `fillAllFieldsCorrectly` | `"Por favor complete todos los campos correctamente"` | `"Por favor, complete todos los campos correctamente"` — Missing comma after "Por favor" |

### 6. Missing `Dashboard` ARB Key

A new key `dashboard` is needed in both ARB files since the hardcoded `'Dashboard'` string in `subject_detail_view.dart:632` must be replaced.

## Affected Files

| File | Issue |
|------|-------|
| `lib/l10n/app_en.arb` | Add `dashboard` key |
| `lib/l10n/app_es.arb` | Fix register inconsistency, capitalization, `masteryLevelBrowsing` translation, add `dashboard` key, add `clearLabel`/`saveDrawing` missing keys |
| `lib/features/subjects/presentation/subject_detail_view.dart` | Lines 611-614, 629-632: replace hardcoded strings with `l10n.*` |
| `lib/core/widgets/canvas_drawing_widget.dart` | Lines 81, 89: replace `const Text('Clear')`, `const Text('Save Drawing')` with localized versions |
| `lib/features/settings/presentation/settings_screen.dart` | Line 452: replace `const Text('Retry')` with `Text(l10n.retry)` |
| `lib/features/practice/presentation/practice_session_screen.dart` | Line 330: map `question.type.name` via localized labels |

## Rationale

Fixing these issues before adding more languages ensures:
- New translators have a consistent register (formal "usted") to follow
- No hardcoded English strings pollute the UI when locale != `en`
- Enum-based display values are properly localizable
- The ARB/ARB-to-generated pipeline is verified as reliable
- Future language additions (e.g., French, German, Portuguese) only require a new `.arb` file

## Acceptance Criteria

- [ ] All 5 hardcoded English strings replaced with `AppLocalizations.of(context)!.*` calls
- [ ] New `dashboard` key added to `app_en.arb` and translated in `app_es.arb`
- [ ] Register in Spanish Mentor strings converted from informal ("tú") to formal ("usted") to match the rest of the app
- [ ] Capitalization fixed in `noLessonsUsePlanner` and `noTopicsYetAddSome` in `app_es.arb`
- [ ] Comma added in `fillAllFieldsCorrectly` in `app_es.arb`
- [ ] `masteryLevelBrowsing` reviewed and updated from "Iniciado" to a more accurate translation
- [ ] `question.type.name` replaced with a localized lookup in `practice_session_screen.dart`
- [ ] Generated Dart files regenerated (`flutter gen-l10n`) and verified no errors
- [ ] App builds and runs without warning with both `es` and `en` locales
