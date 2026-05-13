# Spanish Formal Register Violations in ARB Translations

## Summary

The project's i18n convention (documented in `docs/i18n.md`) mandates **formal *usted* register** for all Spanish translations. Multiple strings in `lib/l10n/app_es.arb` use informal *tú* register, creating an inconsistent tone-of-voice. This must be fixed before adding more languages, as it establishes the wrong pattern for future localizers.

Additionally, several code-level i18n scalability issues prevent smooth addition of new locales.

---

## Formal Register Violations in `lib/l10n/app_es.arb`

| Key | Current (informal) | Should be (formal *usted*) |
|---|---|---|
| `quickGuideWelcomeMessage` | `"Pregúntame lo que sea sobre **tus** estudios"` | `"Pregúnteme lo que sea sobre **sus** estudios"` |
| `quickGuideHelpContent` | `"**tu** asistente... **Puedes**: ... **escribe** tu pregunta y **presiona** enviar"` | `"**su** asistente... **Puede**: ... **escriba** su pregunta y **presione** enviar"` |
| `fallbackExplainResponse` | `"¿Qué tema **te** gustaría que explique?"` | `"¿Qué tema **le** gustaría que explique?"` |
| `fallbackQuizResponse` | `"**Pregunta** lo que **quieras** y haré lo mejor posible."` | `"**Pregunte** lo que **quiera** y haré lo mejor posible."` |
| `fallbackMathResponse` | `"¿Qué problema o tema específico **te** gustaría trabajar?"` | `"¿Qué problema o tema específico **le** gustaría trabajar?"` |
| `fallbackGeneralResponse` | `"**Déjame ayudarte** a entenderla mejor."` | `"**Déjeme ayudarle** a entenderla mejor."` |
| `noAtRiskTopics` | `"Sin temas en riesgo. ¡**Sigue** así!"` | No issue — ARB already has `"Siga"` ✅ |
| `keepPracticingToUnlock` | `"¡**Sigue** practicando..."` | No issue — ARB already has `"Siga"` ✅ |

Note: `noTopicsYetAddSome` and `noLessonsUsePlanner` already use formal register (`"agregue"`, `"use"`) — these are correct.

---

## Missing Key in Spanish ARB

The `quickGuide` key is **defined twice** in `app_en.arb` (JSON duplicate — lines 557 and 1240, last wins) but **entirely absent** from `app_es.arb`. Spanish users see the English fallback `"Quick Guide"` instead of `"Guía Rápida"` in settings.

---

## Test Assertions Out of Sync with ARB (`test/l10n/app_localizations_coverage_test.dart`)

Several Spanish expectations do not match the actual ARB content:

| Line in test | Test expects | ARB value | Formal mismatch? |
|---|---|---|---|
| L197 | `'No hay temas todavía? ¡agrega algunos!'` | `"¿No hay temas? ¡agregue algunos!"` | Tests expect informal `"agrega"`, ARB has formal `"agregue"` |
| L198 | `'No hay lecciones? ¡usa el Planificador...'` | `"¿No hay lecciones? ¡use el Planificador..."` | Tests expect informal `"usa"`, ARB has formal `"use"` |
| L221 | `'Sin temas en riesgo. ¡Sigue así!'` | `"Sin temas en riesgo. ¡Siga así!"` | Tests expect informal `"Sigue"`, ARB has formal `"Siga"` |
| L223 | `'¡Sigue practicando...'` | `"¡Siga practicando..."` | Tests expect informal `"Sigue"`, ARB has formal `"Siga"` |
| L328 | `'Tú dijiste: Hola'` | `"Usted dijo: Hola"` | Tests expect informal `"Tú dijiste"`, ARB has formal `"Usted dijo"` |

**These tests currently FAIL** (or were written before the formal register clean-up).

---

## Code-Level Locale Scalability Issues

### 1. Locale auto-detection is hardcoded per-language (`lib/main.dart:58-65`)

```dart
if (deviceLocale.languageCode == 'es') return const Locale('es');
// ...
return const Locale('en');
```

Adding a third language requires another `if` branch. Should use a map or iterate `AppLocalizations.supportedLocales`.

### 2. Language dropdown subtitle is a hardcoded ternary (`lib/features/settings/presentation/profile_screen.dart:407`)

```dart
subtitle: Text(_language == 'en' ? l10n.english : l10n.spanish),
```

This fails silently when a third language is added — it would show `l10n.spanish` for any non-`'en'` locale. Should look up the language name via the locale value.

### 3. `drawingWithStrokes` uses manual plural string parameter

The key `drawingWithStrokes` passes a separate `plural` string parameter (`""` or `"s"`) rather than using ICU plural rules (`{count, plural, ...}`). This makes translation harder (e.g., Spanish has different plural rules than simply appending "s").

---

## Affected Files

| File | Issue |
|---|---|
| `lib/l10n/app_es.arb` | 6 strings violate formal register; missing `quickGuide` key |
| `lib/l10n/app_en.arb` | `quickGuide` key duplicated (lines 557, 1240) |
| `test/l10n/app_localizations_coverage_test.dart` | 5 ES assertions mismatch ARB values; tests expect informal register |
| `lib/main.dart:58-65` | Locale auto-detection doesn't scale — per-language `if` chain |
| `lib/features/settings/presentation/profile_screen.dart:407` | Language subtitle hardcoded ternary — breaks with 3+ languages |
| `docs/i18n.md` | Guide exists but no mention of formal-register validation step in PR review |
| `lib/l10n/generated/app_localizations_es.dart` | Generated file — must be regenerated after ARB fixes |

---

## Rationale

1. **User trust**: Mixing `tú` and `usted` within the same screen (or worse, same sentence) is jarring for native Spanish speakers and projects an unprofessional image.
2. **Documented convention**: The `docs/i18n.md` explicitly mandates formal register; violations are a failure to follow documented policy.
3. **Test correctness**: The coverage test must match the ARB content or it cannot validate completeness. Currently the tests assert wrong values.
4. **Extensibility**: Each code-level hardcoded locale branch means every new language addition touches non-i18n code. This should be data-driven.

---

## Acceptance Criteria

- [ ] All 6 strings in `app_es.arb` listed above are corrected to formal *usted* register
- [ ] The `quickGuide` key is added to `app_es.arb` with value `"Guía Rápida"`
- [ ] The duplicate `quickGuide` key in `app_en.arb` is deduplicated (remove one, keep the other)
- [ ] All Spanish test assertions in `app_localizations_coverage_test.dart` match the corrected ARB values
- [ ] `app_localizations_test.dart` Spanish assertions are reviewed and updated if necessary
- [ ] Locale auto-detection in `lib/main.dart` is refactored to iterate `AppLocalizations.supportedLocales` instead of per-language `if` chain
- [ ] Language subtitle in `lib/features/settings/presentation/profile_screen.dart` replaces hardcoded ternary with a proper locale-to-label lookup (e.g., a map)
- [ ] `bash scripts/gen_l10n.sh` runs cleanly after all changes
- [ ] All existing tests pass (`flutter test`)
- [ ] `docs/i18n.md` is updated to include a PR-review checklist item verifying formal register compliance
