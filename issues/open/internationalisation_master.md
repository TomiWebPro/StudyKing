# Spanish Localisation Quality Audit — Translation Duplication, Register Inconsistency & Hardcoded English

## Summary

A systematic audit of the Spanish (`es`) localisation reveals three categories of issues: **(A)** critical duplicate keys in ARB files causing silent translation degradation, **(B)** inconsistent register and terminology in the Spanish translation itself, and **(C)** hardcoded English strings in widget code that bypass `AppLocalizations`.  These must be resolved before adding further locales (e.g. `fr`, `de`, `pt`) because they erode trust in the i18n pipeline and create a fragile foundation for scaling.

---

## A — Duplicate Translation Keys in Both ARB Files

### Issue
Both `lib/l10n/app_en.arb` and `lib/l10n/app_es.arb` contain **13 duplicate translation keys** in a second block starting at ~line 3856.  Because ARB files are parsed as JSON and JSON takes the **last** value for duplicate keys, the generated Dart code silently uses the *second* (duplicate) translation, which is of **lower quality**.

### Affected Keys (confirmed in both `.arb` files)

| Key | First occurrence | Duplicate (used) | Notes |
|---|---|---|---|
| `badgeAccuracyGoldDesc` | `¡Alcanzó más del 90% de precisión!` | `Logró más del 90% de precisión!` | Missing opening `¡` |
| `badgeDailyScholarDesc` | `¡Estudió constantemente hoy!` | `Estudió consistentemente hoy!` | Missing `¡` + word change |
| `badgeDailyScholarName` | `Estudioso Diario` | `Estudiante Diario` | Different translation |
| `badgeWeeklyWarriorDesc` | `¡Activo durante una semana completa!` | `Activo durante una semana completa!` | Missing `¡` |
| `nudgeOverwork` | `Ha estudiado {hours} horas hoy. ¡Considere tomar un descanso!` | `Ha estudiado {hours} horas hoy. Considere tomar un descanso!` | Missing `¡` |
| `nudgeRevision` | `¡Hora de repasar!` | `Es hora de repasar!` | Missing `¡`, different structure |
| `nudgePlanAdjustment` | `Ha tenido {days} días de bajo cumplimiento del plan. ¿Desea ajustar su plan de estudio?` | `Ha tenido {days} días de baja adherencia. Le gustaría ajustar su plan de estudio?` | Missing `¿`, different vocabulary |
| `badgeFirstStepDesc` | etc. | | See full diff below |

### Root Cause
The last ~450 lines of each ARB file appear to be a second generation pass or merge artifact that overlapped the original key set. The generated Dart (`lib/l10n/generated/app_localizations_es.dart`) confirms the **duplicate values are the ones actually used at runtime**.

### Rationale for Fix
- Flutter's `gen-l10n` + `dart:convert` picks the last duplicate — no warning is emitted.
- A developer adding a new language would copy one of these files as a template, propagating the duplicates.
- The build pipeline should be CI-gated to reject duplicate keys.

### Files
- `lib/l10n/app_es.arb` (lines 3504–3550 and 3856–3903 overlap)
- `lib/l10n/app_en.arb` (lines 3504–3550 and 3856–3903 overlap)
- `lib/l10n/generated/app_localizations_es.dart` (consumer)

---

## B — Spanish Translation Quality Issues

### B.1 Inconsistent Register

The project targets **neutral Latin American Spanish (formal "usted")** per `l10n.yaml:12`.  Most translations correctly use the formal imperative (e.g. `"Agregue materias"`, `"Concéntrese en sus errores"`), but one key slips into informal:

| Key | Current | Should be |
|---|---|---|
| `practiceQuestionsFrom` (line 936) | `"Practica preguntas de {subjectName}"` | `"Practique preguntas de {subjectName}"` |

### B.2 Inconsistent Terminology for Same Concept

| Concept | Translation A | Translation B | Location |
|---|---|---|---|
| "adherence" | `cumplimiento` (line 3745) | `adherencia` (line 3925) | l. 3745 vs 3925 |
| "consistency" | `constancia` (line 3762) | `consistencia` (line 4114) | l. 3762 vs 4114 |
| "weak areas" | `áreas por mejorar` (line 219) | `áreas débiles` (line 4179) | l. 219, 1663 vs 3814, 4179 |

**Fix**: Choose one term per concept and apply consistently across the entire `app_es.arb`.  `cumplimiento` (for adherence) and `áreas por mejorar` (for weak areas) are more idiomatic in formal Spanish.

### B.3 Anglicism / Spanglish

| Line | Current | Suggested |
|---|---|---|
| 1078 | `"Sube o pegue datos para visualizar"` | `"Cargue o pegue datos para visualizar"` |
| 1798 | `"Error al subir"` | `"Error al cargar"` |

In computing contexts `subir` (direct calque of "upload") is widely accepted but `cargar` is more formal and consistent with "usted" register.

### B.4 Missing Opening Punctuation in Duplicate Section

Every exclamation and question in the duplicate block (lines 3856–4302) is missing the **opening** Spanish punctuation mark (`¡` / `¿`):

- `"Logró más del 90% de precisión!"` → should be `"¡Logró más del 90% de precisión!"`
- `"Le gustaría ajustar su plan de estudio?"` → `"¿Le gustaría ajustar su plan de estudio?"`
- `"Considere tomar un descanso!"` → `"¡Considere tomar un descanso!"`

These are **actively displayed to users** because the duplicate overrides take precedence.

---

## C — Hardcoded English Strings Bypassing AppLocalizations

### C.1 `ConversationInput` default tooltip — Localisation Trap

**File:** `lib/core/widgets/conversation_input.dart:24`

```dart
this.sendTooltip = 'Send',  // hardcoded English fallback
```

While the main caller (`tutor_screen.dart:291`) correctly passes `l10n.send`, any *other* widget using `ConversationInput` without explicitly setting `sendTooltip` will silently show "Send" in every locale.

### C.2 Overtime Duration Format in Lesson Progress Bar

**File:** `lib/features/teaching/presentation/widgets/lesson_progress_bar.dart:56`

```dart
'+${elapsedMinutes - plannedDurationMinutes}m'
```

Hardcodes the `+` prefix and `m` suffix.  A localised version should delegate to `AppLocalizations` so that Spanish users see `+5 min` (not `+5m`).

### C.3 LLM Keyword Lists are English-Only

**File:** `lib/features/teaching/services/conversation_manager.dart`

| Lines | Purpose | Problem |
|---|---|---|
| 220–222 | Answer-correctness keywords | `['correct', 'right', 'yes', ...]` — wrong for Spanish student input |
| 225–226 | Incorrect-answer keywords | `['wrong', 'incorrect', 'not sure', ...]` — wrong for Spanish |
| 249–250 | Exercise-detection keywords | `['exercise', 'practice', 'question', ...]` — wrong for Spanish |

A Spanish student writing `"correcto"`, `"sí"`, or `"ejercicio"` will not match any keyword.  These lists should either be localised via ARB keys or replaced with locale-agnostic heuristics.

---

## D — Systematic Gaps for Adding New Languages

### Infrastructure Issues

1. **No CI validation for duplicate ARB keys**: a pre-commit hook or CI step should run `flutter gen-l10n` and reject any output diff that introduces duplicates.
2. **No lint rule for `AppLocalizations` usage**: a custom lint (or code review checklist) should ensure every `"hardcoded string"` in a presentation widget is replaced with a localised lookup.
3. **Locale selector currently limited to `en`/`es`**: `lib/features/settings/presentation/profile_screen.dart` only offers two `DropdownMenuItem` options.  New locales require updating the dropdown, the locale provider fallback in `lib/main.dart`, and the `localeResolutionCallback`.
4. **`l10n.yaml` only lists `en`/`es`**: adding a third language (e.g. `fr`) requires adding `app_fr.arb` and updating `supported-locales` in both `l10n.yaml` and `lib/main.dart`.

---

## Acceptance Criteria

- [ ] **A.1** — Duplicate keys removed from `app_en.arb` (keep first occurrences).
- [ ] **A.2** — Duplicate keys removed from `app_es.arb` (keep first occurrences).
- [ ] **A.3** — `flutter gen-l10n` re-run; generated files reflect correct (first) translations.
- [ ] **A.4** — A validation script/CI step exists that rejects duplicate keys in ARB files.
- [ ] **B.1** — `"Practica"` → `"Practique"` in `app_es.arb:936`.
- [ ] **B.2** — Chosen terminology (e.g. `cumplimiento`, `constancia`, `áreas por mejorar`) is applied consistently.
- [ ] **B.4** — All Spanish strings use `¡` / `¿` where required.
- [ ] **C.1** — Remove default `sendTooltip` in `conversation_input.dart` or make it required.
- [ ] **C.2** — `lesson_progress_bar.dart:56` delegates overtime format to `AppLocalizations`.
- [ ] **C.3** — Keyword lists in `conversation_manager.dart` are either localised or replaced with locale-agnostic logic.
