# Spanish (es) ARB: Missing ICU Plural Rules & MentorService Hardcoded English

## Context

Spanish localization (`lib/l10n/app_es.arb`) contains keys that use simple `{count}` placeholders where the English template uses proper ICU plural syntax (`{count, plural, =1{...} other{...}}`). This produces grammatically incorrect Spanish when `count == 1` (e.g. renders `"1 preguntas"` instead of `"1 pregunta"`).

Additionally, `MentorService` (`lib/features/mentor/services/mentor_service.dart`) contains ~30+ user-facing strings hardcoded in English, with no mechanism to receive the current locale. Its intent-detection keywords (confirmation, rejection, schedule, progress, inactivity) are English-only, making the mentor feature effectively unlocalizable.

## Affected Files

| File | Issue |
|------|-------|
| `lib/l10n/app_es.arb` (lines 194, 675, 1569, 1801) | 4 keys lack ICU plural rules |
| `lib/l10n/app_en.arb` (lines 194, 675, 1569, 1801) | Reference template (all use correct plurals) |
| `lib/features/mentor/services/mentor_service.dart` (entire file) | All user-facing strings hardcoded in English |
| `lib/features/mentor/presentation/mentor_screen.dart` | No locale passed to `MentorService` |

## Detailed Breakdown

### A. Missing ICU Plural Rules in `app_es.arb`

**English (correct):**
```json
"randomQuestions": "{count, plural, =1{1 random question} other{{count} random questions}}",
```

**Spanish (broken — uses simple `{count}` without plural selectors):**
```json
"randomQuestions": "{count} preguntas aleatorias",
```

**Affected keys (all use simple `{count}` instead of `{count, plural, =1{...} other{...}}`):**
| Key | Current Spanish (incorrect) | Should be |
|-----|----------------------------|-----------|
| `randomQuestions` (line 194) | `{count} preguntas aleatorias` | `{count, plural, =1{1 pregunta aleatoria} other{{count} preguntas aleatorias}}` |
| `sessionsCount` (line 675) | `{count} sesiones` | `{count, plural, =1{1 sesión} other{{count} sesiones}}` |
| `questionsCountLabel` (line 1569) | `{count} preguntas` | `{count, plural, =1{1 pregunta} other{{count} preguntas}}` |
| `questionsCountMetric` (line 1801) | `{count} preguntas` | `{count, plural, =1{1 pregunta} other{{count} preguntas}}` |

All 4 keys are plural-sensitive (type: `int`). When `count == 1`, the current code produces `"1 preguntas"` instead of `"1 pregunta"`.

### B. Hardcoded English Strings in `MentorService`

**All user-facing strings in `mentor_service.dart` are hardcoded in English:**

| Method | Example hardcoded string | Lines |
|--------|-------------------------|-------|
| `_handleScheduleRequest` | `"You don't have any lessons scheduled yet…"` | 141 |
| `_handleScheduleRequest` | `"Here are your upcoming lessons:\n"` | 146 |
| `_handleScheduleRequest` | `"Would you like to reschedule any of these?"` | 154 |
| `_handleInactivityCheck` | `"Great job staying active! …"` | 203 |
| `_handleInactivityCheck` | `"You haven't started studying yet! …"` | 187 |
| `_handleInactivityCheck` | `"I noticed you haven't studied in $daysSince days…"` | 201 |
| `_executePendingAction` | `"I've noted the change. …"` | 221 |
| `_executePendingAction` | `"Great! I've added a new study session…"` | 223 |
| `getProgressReport` | `"📊 **Your Study Progress Report**\n"` | 312 |
| `getProgressReport` | `"Areas needing attention:"` | 322 |
| `suggestNextAction` | `"You haven't added any subjects yet…"` | 414 |
| `suggestNextAction` | `"You're doing well! Would you like to…"` | 417 |
| `_mentorSystemPrompt` | Full system prompt in English | 232–260 |
| `_buildContextPrompt` | Context template in English | 280–298 |

**English-only keyword patterns** — intent detection will not match Spanish input:
- `_isConfirmation` (line 90): matches `yes`, `sure`, `ok` — fails for `sí`, `claro`, `vale`, `confirmar`
- `_isRejection` (line 99): matches `no`, `don't` — fails for `no quiero`, `cancelar`
- `_isScheduleRequest` (line 107): matches `schedule`, `plan` — fails for `programar`, `planificar`
- `_isProgressRequest` (line 116): matches `progress`, `stats` — fails for `progreso`, `estadísticas`
- `_isInactivityCheck` (line 125): matches `inactive`, `reminder` — fails for `inactivo`, `recordatorio`

**No locale injection point** — `MentorService` constructor (line 22) has no `Locale` or `AppLocalizations` parameter. The class is instantiated in `_MentorScreenState._initializeMentor()` (line 52) where `AppLocalizations.of(context)!` is available in the same class, but never passed through.

## Rationale

1. **Spanish correctness**: Displaying `"1 preguntas"` is a grammatical error that degrades user trust. All 1149 keys in `app_es.arb` should follow the English template's pattern.
2. **Mentor feature unusable for Spanish speakers**: Even with UI fully localized, the chatbot's canned responses and intent detection remain English-only. A Spanish-speaking user who types `"sí"` to confirm an action will be treated as a rejection.
3. **Architecture**: Fixing `MentorService` establishes a pattern for all future service-layer localization (e.g. `TutorService`, `PlannerService`) and makes adding French, German, etc. straightforward.
4. **Leverages existing infrastructure**: The project already has `AppLocalizations`, `l10n.yaml`, and `flutter gen-l10n`. Adding more ARB keys is the intended path — no new dependencies needed.

## Acceptance Criteria

- [ ] **A1.** All 4 Spanish ARB keys (`randomQuestions`, `sessionsCount`, `questionsCountLabel`, `questionsCountMetric`) use proper ICU plural syntax matching the English template, including accent marks for singular forms (`pregunta` / `sesión`).
- [ ] **A2.** `app_localizations_coverage_test.dart` still passes (all keys present) and the new plural values are tested for both `count=1` and `count>1`.
- [ ] **A3.** `MentorService` receives the current `Locale` (or `AppLocalizations`) from `MentorScreen`.
- [ ] **A4.** All hardcoded user-facing strings in `MentorService` are replaced with calls to `AppLocalizations` via the injected locale.
- [ ] **A5.** Intent-detection keyword patterns (`_isConfirmation`, `_isRejection`, `_isScheduleRequest`, `_isProgressRequest`, `_isInactivityCheck`) are expanded to match Spanish equivalents (`sí`, `claro`, `programar`, `progreso`, `inactivo`, etc.) or replaced with a locale-aware matching strategy.
- [ ] **A6.** Generated Dart files are regenerated (`scripts/gen_l10n.sh`) with no compiler errors.
- [ ] **A7.** Running `flutter test` passes (existing Spanish localization tests continue to work).
- [ ] **A8.** Mentor chatbot renders localized response strings when device locale is `es`.
