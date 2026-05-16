# Exam session screen is entirely unlocalised — hardcoded English strings bypass `AppLocalizations`

## Context

The `exam_session_screen.dart` implements an exam-mode workflow (config, timer, results) that lives alongside the regular practice screens. Despite the broader practice feature being well-localised (50+ `AppLocalizations` usages, 4 correct `formatPercent` calls with `localeName`), **this screen contains 9+ hardcoded English user-facing strings and one locale-unaware duration abbreviation**. No corresponding ARB keys exist for any exam-related labels in either `app_en.arb` or `app_es.arb`.

For a Spanish user the entire exam configuration screen, the result "Incorrect"/"Skipped" labels, and the auto-submission notice are always shown in English regardless of locale selection. The existing Spanish ARB file (380+ keys, formal *usted* register) is fully bypassed for this workflow.

## Affected files

| File | Issue |
|---|---|
| `lib/features/practice/presentation/screens/exam_session_screen.dart:384` | Hardcoded `'Exam Configuration'` heading |
| `lib/features/practice/presentation/screens/exam_session_screen.dart:397` | Hardcoded `'Start Exam'` button |
| `lib/features/practice/presentation/screens/exam_session_screen.dart:412` | Hardcoded `'Exam Duration'` label |
| `lib/features/practice/presentation/screens/exam_session_screen.dart:417` | Hardcoded `'$d min'` — English abbreviation, not locale-aware |
| `lib/features/practice/presentation/screens/exam_session_screen.dart:431` | Hardcoded `'Number of Questions'` label |
| `lib/features/practice/presentation/screens/exam_session_screen.dart:464` | Hardcoded `'Incorrect'` result row label |
| `lib/features/practice/presentation/screens/exam_session_screen.dart:465` | Hardcoded `'Skipped'` result row label |
| `lib/features/practice/presentation/screens/exam_session_screen.dart:474` | Hardcoded `'Exam was auto-submitted when time ran out.'` notice |
| `lib/features/practice/presentation/screens/exam_session_screen.dart:481` | Hardcoded `'Topic Breakdown'` section heading |
| `lib/l10n/app_en.arb` | Missing ARB keys for all exam-related strings |
| `lib/l10n/app_es.arb` | Missing ARB keys for all exam-related strings |

## Detailed findings

### 1. Config screen — completely unlocalised (`exam_session_screen.dart:375-405`)
Three headings and one button label are raw string literals. The method already receives a `l10n` parameter (`_buildConfigScreen(AppLocalizations l10n)`) but does not use it for these strings.

### 2. Duration selector — locale-unaware abbreviation (`exam_session_screen.dart:407-424`)
The chip labels `'$d min'` use the English convention (`"m"`). Per the documented abbreviation policy in `docs/i18n.md`:
| Unit | EN | ES |
|---|---|---|
| Minutes | `1m` / `{count}m` | `1min` / `{count}min` |

The hardcoded `'min'` happens to match the Spanish convention, but when a future locale uses a different abbreviation (e.g. French `"min"` → `"m"` invariant, Portuguese `"min"`), this will silently display the wrong token. The correct approach is to use the existing `l10n.sessionDurationMinutes(minutes)` key.

### 3. Results screen — mixed localisation (`exam_session_screen.dart:448-514`)
- `l10n.totalQuestions` and `l10n.correctAnswers` are used correctly (lines 462–463)
- `'Incorrect'` and `'Skipped'` are hardcoded (lines 464–465) even though the ARB file already has `incorrectFeedback` / `correctFeedback` / `skip` keys
- `'Exam was auto-submitted when time ran out.'` is hardcoded (line 474) — a user-facing informational message
- `'Topic Breakdown'` is hardcoded (line 481) — a section heading

### 4. No ARB keys exist for any exam concept
A search of both `app_en.arb` and `app_es.arb` confirms **zero** keys for: `exam`, `examConfiguration`, `startExam`, `examDuration`, `numberOfQuestions`, `examResults`, `skipped`, `autoSubmitted`, `timeRanOut`, or `topicBreakdown`.

## Rationale

1. **Spanish users are fully blocked from using Exam mode in their language.** The formal *usted* register, positive framing ("Áreas por mejorar"), and locale-aware number formatting that work everywhere else in the app are absent for this entire feature.

2. **Bad precedent.** If a new contributor adds a feature screen and copies the existing exam code pattern, they will replicate the unlocalised approach. All other practice screens use `final l10n = AppLocalizations.of(context)!;` — this screen should too.

3. **Low-hanging fruit for a template to add future languages.** The exam screen's strings are a small, self-contained set (~10 keys) that can be extracted to ARB in a single pass. Adding those keys to `app_es.arb` creates a clear template for any future language (fr, de, pt, etc.).

4. **The i18n infrastructure is ready.** `l10n.yaml` supports locale fallback, `AppLocale.resolveLocale()` maps regional variants, the coverage script validates key parity, and `number_format_utils.dart` provides locale-aware formatting — none of which is used by this screen.

## Acceptance criteria

- [ ] Add 10 new ARB keys to `app_en.arb`:
  - `examConfiguration` — `"Exam Configuration"`
  - `startExam` — `"Start Exam"`
  - `examDuration` — `"Exam Duration"`
  - `numberOfQuestions` — `"Number of Questions"`
  - `incorrectResults` — `"Incorrect"` (distinct from `incorrectFeedback`)
  - `skippedResults` — `"Skipped"` (distinct from `skip` verb)
  - `autoSubmittedNotice` — `"Exam was auto-submitted when time ran out."`
  - `topicBreakdown` — `"Topic Breakdown"`
- [ ] Add the same 10 keys to `app_es.arb` with formal *usted* Spanish translations:
  - `examConfiguration` → `"Configuración del Examen"`
  - `startExam` → `"Iniciar Examen"`
  - `examDuration` → `"Duración del Examen"`
  - `numberOfQuestions` → `"Número de Preguntas"`
  - `incorrectResults` → `"Incorrectas"`
  - `skippedResults` → `"Omitidas"`
  - `autoSubmittedNotice` → `"El examen se envió automáticamente al agotarse el tiempo."`
  - `topicBreakdown` → `"Desglose por Tema"`
- [ ] Replace all 9 hardcoded English strings in `exam_session_screen.dart` with calls to the new `l10n.*` getters
- [ ] Replace `'$d min'` (line 417) with `l10n.sessionDurationMinutes(d)` to use the existing locale-aware key
- [ ] Replace `'${result.questionResults.length}'`, `'${result.totalCorrect}'`, `'${result.totalIncorrect}'`, `'${result.totalSkipped}'` with `l10n.ofLabel` or `formatDecimal` for locale-aware number formatting
- [ ] Run `bash scripts/gen_l10n.sh` to regenerate Dart code
- [ ] Run `bash scripts/check_i18n_coverage.sh` to validate 100% key parity between EN and ES ARB files
- [ ] Run `dart run scripts/validate_arb_no_duplicates.dart` to check for duplicate keys
- [ ] Verify the screen renders correctly under `en` and `es` locales in a hot-reload test
