# Spanish (es) i18n Quality Audit — Translation Fixes, Hardcoded Strings & Number Format Bugs

## Context

StudyKing supports 2 locales (`en`, `es`) with 907 translated keys each. The Spanish translation uses a formal *usted* register targeting neutral Latin American Spanish. While key parity is maintained, several translation inaccuracies, hardcoded English strings, and locale-blind number formatting bugs exist. These issues reduce quality for Spanish users and the patterns discovered serve as a foundation for stricter i18n enforcement when adding future languages.

---

## 1. Translation Quality Issues (app_es.arb)

### 1.1 Malformed question punctuation — `adherenceLowDaysRegenerate`

**File:** `lib/l10n/app_es.arb:4117`

| | Current | Correct |
|---|---|---|
| ES | `"¿Ha tenido {days} días consecutivos de bajo cumplimiento. Le gustaría regenerar su plan con objetivos ajustados?"` | `"Ha tenido {days} días consecutivos de bajo cumplimiento. ¿Le gustaría regenerar su plan con objetivos ajustados?"` |
| EN | `"You have had {days} consecutive days of low adherence. Would you like to regenerate your plan with adjusted targets?"` | — |

**Problem:** The opening `¿` is placed on the first sentence (a declarative statement), but the closing `?` is after the second sentence (the actual question). This is malformed Spanish punctuation — the `¿` must immediately precede the interrogative clause.

**Fix:** Move `¿` from before `"Ha tenido"` to before `"Le gustaría"`. The first sentence is a statement, not a question.

---

### 1.2 False friend — `badgeDailyScholarDesc`

**File:** `lib/l10n/app_es.arb:3672`

| | Current | Correct |
|---|---|---|
| ES | `"¡Estudió constantemente hoy!"` | `"¡Estudió de manera constante hoy!"` or `"¡Estudió consistentemente hoy!"` |
| EN | `"Studied consistently today!"` | — |

**Problem:** *Constantemente* is a false friend meaning **"constantly"** (non-stop, all the time), not **"consistently"** (regularly/steadily). The badge implies the user studied non-stop, which is misleading and may cause confusion.

**Fix:** Replace with a correct equivalent. For a daily consistency badge, `"Estudió de manera constante hoy"` conveys the intended meaning accurately.

---

### 1.3 Wrong word for digital stylus — `drawYourAnswer`

**File:** `lib/l10n/app_es.arb:1470`

| | Current | Correct |
|---|---|---|
| ES | `"Dibuje su respuesta en el lienzo usando su dedo o lápiz"` | `"Dibuje su respuesta en el lienzo usando su dedo o lápiz óptico"` |
| EN | `"Draw your answer on the canvas using your finger or stylus"` | — |

**Problem:** *Lápiz* means **pencil** (a graphite writing stick). On a digital drawing canvas, users reasonably expect a pencil/stylus — *lápiz óptico* or simply *stylus* is the correct term.

---

### 1.4 Inconsistent "Upload" translation — `uploadOrPasteData`

**File:** `lib/l10n/app_es.arb:1135`

| Key | ES Translation |
|---|---|
| `uploadData` | `"Subir Datos"` |
| `uploadDataFile` | `"Subir Archivo de Datos"` |
| `uploadDataFileDialog` | `"Subir Archivo de Datos"` |
| `uploadContent` | `"Subir Contenido"` |
| `uploadMaterial` | `"Subir Material de Estudio"` |
| `uploading` | `"Subiendo..."` |
| **`uploadOrPasteData`** | **`"Cargue o pegue datos para visualizar"`** ← outlier |

**Problem:** 6 of 7 "upload" keys use *Subir* (standard Spanish for file upload). One key uses *Cargue* (from *cargar* = to load), which sounds like a different operation. This inconsistency is visible to users on the same screen.

**Fix:** Change to `"Sube o pegue datos para visualizar"` (note: maintain *usted* imperative: *Sube* → *Sube* is actually informal; should be *"Sube o pegue"* — wait, *subir* in formal imperative is *suba*, not *sube*. Let me reconsider: formal imperative of *subir* is *suba*. But the existing keys use *Subir* as an infinitive in titles. For an instruction sentence, the existing *Cargue* is *cargar* in formal imperative (3rd person singular). The correct formal imperative of *subir* is *suba*: `"Suba o pegue datos para visualizar"`.)

**Corrected fix:** `"Suba o pegue datos para visualizar"`

---

### 1.5 Wrong concept — `readiness` / `avgReadinessLabel`

**File:** `lib/l10n/app_es.arb:2642–2643`

| | Current | Correct |
|---|---|---|
| ES | `"Disposición"` / `"Disposición Prom.: {percent}"` | `"Preparación"` / `"Preparación Prom.: {percent}"` |
| EN | `"Readiness"` / `"Avg Readiness: {percent}"` | — |

**Problem:** *Disposición* means **willingness/availability** (as in *estar dispuesto a* = to be willing to). "Readiness" (preparedness for a challenge/test) is *Preparación* or *Nivel de preparación*. Users will misunderstand what this metric represents.

---

### 1.6 Desktop terminology on mobile — `lessonTimeEnded`

**File:** `lib/l10n/app_es.arb:2160`

| | Current | Correct |
|---|---|---|
| ES | `"El tiempo de lección terminó. Haga clic en 'Finalizar Lección' para terminar."` | `"El tiempo de lección terminó. Toque 'Finalizar Lección' para terminar."` |
| EN | `"Click 'End Lesson' to finish."` | — |

**Problem:** *Haga clic* (= click) is desktop web terminology. StudyKing is a mobile app where users **tap** the screen. The standard mobile term is *Toque* (from *tocar* = to tap).

---

### 1.7 Wrong number agreement — `studyAnalytics`

**File:** `lib/l10n/app_es.arb:722`

| | Current | Correct |
|---|---|---|
| ES | `"Analíticas de Estudio"` | `"Analítica de Estudio"` |
| EN | `"Study Analytics"` | — |

**Problem:** *Analíticas* (feminine plural) implies multiple analytical reports. "Analytics" as a field/concept in Spanish is *Analítica* (feminine singular). Compare the EN pattern: "Analytics" → singular noun, not "Analytics items".

---

### 1.8 Awkward phrasing — `examAutoSubmitted`

**File:** `lib/l10n/app_es.arb:372`

| | Current | Correct |
|---|---|---|
| ES | `"El examen se envió automáticamente cuando se acabó el tiempo."` | `"El examen se envió automáticamente cuando se agotó el tiempo."` |
| EN | `"Exam was auto-submitted when time ran out."` | — |

**Problem:** *Acabarse el tiempo* is understood but awkward. *Agotarse el tiempo* (= time ran out / time expired) is the standard Spanish idiom for this concept.

---

### 1.9 Inconsistent "Medium" — `difficultyMedium` vs `fontSizeMedium`

**File:** `lib/l10n/app_es.arb:1409,648`

| Key | ES | EN |
|---|---|---|
| `difficultyMedium` | `"Medio"` | `"Medium"` |
| `fontSizeMedium` | `"Mediano"` | `"Medium"` |

**Problem:** The same English word "Medium" is translated two different ways. While *tamaño mediano* is natural for font sizes and *dificultad media* for difficulty, the standalone label "Medio" vs "Mediano" is inconsistent. For button/tab labels, a single word should be used — *Mediano* works for both contexts.

---

### 1.10 Calque translation — `usageSummary`

**File:** `lib/l10n/app_es.arb:4449`

| | Current | Correct |
|---|---|---|
| ES | `"Uso: {totalCost} sobre {totalTokens} tokens, promedio: {avgCost} por cada 1k tokens"` | `"Uso: {totalCost} de {totalTokens} tokens, promedio: {avgCost} por cada 1k tokens"` |
| EN | `"Usage: {totalCost} over {totalTokens} tokens, avg: {avgCost} per 1k tokens"` | — |

**Problem:** *Sobre* literally means "on top of / above", not "out of / among". The English "over" here means "out of" / "across". The natural Spanish preposition is *de*: `"{cost} de {count} tokens"`.

---

### 1.11 Past participle vs adjective — `completionOfValue`

**File:** `lib/l10n/app_es.arb:3052`

| | Current | Correct |
|---|---|---|
| ES | `"{value}% Completado"` | `"{value}% Completo"` |
| EN | `"{value}% Complete"` | — |

**Problem:** EN uses the adjective "Complete" (the task is in a state of being X% complete). ES uses *Completado* (past participle = "Completed"), which implies the process fully finished. *Completo* is the correct adjective to describe the degree of completeness.

---

## 2. Hardcoded User-Facing Strings (i18n Gaps)

These strings are displayed to users but are hardcoded in English with no localization path.

### 2.1 Share sheet text — `export_section.dart`

**File:** `lib/features/dashboard/presentation/widgets/export_section.dart:61,81,104`

```dart
text: 'StudyKing Progress Report',      // line 61
text: 'StudyKing Session History',       // line 81
text: 'StudyKing Instrumentation Data',  // line 104
```

**Fix:** Add ARB keys (`shareProgressReport`, `shareSessionHistory`, `shareInstrumentationData`) with Spanish translations and use `l10n.*` here.

### 2.2 Instrumentation text labels — `export_section.dart`

**File:** `lib/features/dashboard/presentation/widgets/export_section.dart:116–126`

```dart
buffer.writeln('=== Instrumentation Dashboard ===');
buffer.writeln('Generated: ${data['generatedAt']}');
buffer.writeln('--- Plan Adherence ---');
buffer.writeln('--- Mastery Improvement ---');
```

**Fix:** Extract to ARB keys. The `'generatedAt'` map key should also be abstracted (or the data layer should use a constant).

### 2.3 Chart fallback labels — `weekly_chart.dart`

**File:** `lib/features/dashboard/presentation/widgets/weekly_chart.dart:46`

```dart
: {'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0}
```

**Problem:** Hardcoded English day abbreviations used as bar chart axis labels when no trend data exists. These labels are visible to users in the rendered chart.

**Fix:** Compute day labels from `DateTime` using `DateFormat('E', localeName)` or add ARB keys for abbreviated day names.

### 2.4 Accessibility labels — `chat_bubble.dart`

**File:** `lib/features/teaching/presentation/widgets/chat_bubble.dart:155`

```dart
label: score >= 0.7 ? 'Correct' : (score <= 0.3 ? 'Incorrect' : 'Partial'),
```

**Problem:** Hardcoded English semantic labels for screen readers. Visually impaired Spanish users hear English evaluation feedback.

**Fix:** Add ARB keys (`correctLabel`, `incorrectLabel`, `partialLabel`) and use `l10n.*` here.

---

## 3. Number Format Bugs (Locale-Unaware `toStringAsFixed`)

Although `number_format_utils.dart` exists with locale-aware helpers and 19+ files use them correctly, two code paths bypass the helpers and pass raw `toStringAsFixed` output into localized string templates. This produces wrong decimal separators for Spanish (e.g. `"1.5 horas"` instead of `"1,5 horas"`).

### Root cause — `study_progress_tracker.dart`

**File:** `lib/core/services/study_progress_tracker.dart:51`

```dart
'totalStudyTimeHours': (totalTimeMs / 3600000).toStringAsFixed(1),
```

A locale-invariant string (e.g. `"1.5"`) is stored in the data map. Most consumers parse it back to `double` and reformat correctly, but two do not.

### Downstream bug 1 — `mentor_screen.dart`

**File:** `lib/features/mentor/presentation/mentor_screen.dart:304`

```dart
buffer.writeln(l10n.mentorTotalStudyTime(report.totalStudyTimeHours));
```

The ARB template interpolates directly:
- EN: `"**Total Study Time:** {hours} hours"` → `"**Total Study Time:** 1.5 hours"` ✅
- ES: `"**Tiempo Total de Estudio:** {hours} horas"` → `"**Tiempo Total de Estudio:** 1.5 horas"` ❌ (should be `1,5`)

**Fix:** Parse `report.totalStudyTimeHours` to `double`, apply `formatDecimal(hours, l10n.localeName, minFractionDigits: 1, maxFractionDigits: 1)`, then pass to `l10n.mentorTotalStudyTime(...)`.

### Downstream bug 2 — `engagement_scheduler.dart`

**File:** `lib/core/services/engagement_scheduler.dart:271,276–283`

```dart
final totalHours = stats['totalStudyTimeHours'] as String? ?? '0';
return _l10n?.nudgeWeeklyDigest(
  weeklyActivity,
  accuracy,
  totalHours,     // raw "1.5" – locale-blind
  weakCount,
  badges.length,
) ?? 'Weekly Digest: ...';
```

Same pattern: the ARB template receives raw en-formatted string.

**Fix:** Convert to `double`, apply `formatDecimal`, then pass the formatted string. The fallback string on line 283 also needs locale-aware formatting.

### Additional: Non-CSV `toStringAsFixed` call sites for audit

| File | Line | Context | Verdict |
|---|---|---|---|
| `lib/features/mentor/services/mentor_service.dart` | 158, 197 | LLM prompt context | **Exempt** (LLM-facing) |
| `lib/features/teaching/services/prompts/prompts.dart` | 170 | LLM prompt template | **Exempt** (LLM-facing) |
| `lib/features/teaching/services/conversation_manager.dart` | 271 | Tutor notes stored in DB | **Exempt** (LLM-facing) |
| `lib/core/services/study_progress_tracker.dart` | 311 | CSV export | **Exempt** (CSV is data) |
| `lib/features/sessions/services/session_export_service.dart` | 30, 32 | CSV export | **Exempt** (CSV is data) |
| `lib/core/services/progress_export_service.dart` | 63 | CSV export | **Exempt** (CSV is data) |

---

## 4. Adding New Languages: Process Gaps

The 7-step process in `docs/i18n.md` is thorough, but three gaps exist:

### 4.1 Hardcoded string detection

**Problem:** No automated check exists to catch hardcoded user-facing strings when adding a new locale. Steps 7 shows a manual `grep` that is incomplete.

**Fix:** Introduce a CI script that parses Dart files for `Text(`, `Semantics(label:`, `SnackBar(content: Text(`, etc. and flags string literals that don't come from `l10n.*` or `AppLocalizations.of(context)!`.

### 4.2 Locale dropdown scaling

**File:** `lib/features/settings/presentation/profile_screen.dart:416–419`

```dart
final label = switch (appLocale) {
  AppLocale.en => l10n.english,
  AppLocale.es => l10n.spanish,
};
```

**Problem:** Every new locale requires a new `switch` arm here. This doesn't scale — should use a `Map<AppLocale, String Function(AppLocalizations)>` or auto-discover labels from ARB.

**Fix:** Add an ARB key per locale (e.g. `localeEn`, `localeEs`) and refactor the dropdown to derive labels dynamically from the active `AppLocalizations` instance. A new ARB file then automatically provides its own label.

### 4.3 Enum ↔ ARB coupling

**File:** `lib/core/config/locale_config.dart`

The `AppLocale` enum and `l10n.yaml` `supported-locales` list must be kept in sync manually. There is no validation that `AppLocale.values` matches the generated `AppLocalizations.supportedLocales`.

**Fix:** Add a unit test that asserts `AppLocale.values.length == AppLocalizations.supportedLocales.length` and that each `AppLocale`'s language code appears in the generated list.

---

## Acceptance Criteria

### Translation fixes (app_es.arb)
- [ ] `adherenceLowDaysRegenerate`: `¿` moved to correctly precede the interrogative clause
- [ ] `badgeDailyScholarDesc`: `constantemente` replaced with correct equivalent for "consistently"
- [ ] `drawYourAnswer`: `lápiz` changed to `lápiz óptico`
- [ ] `uploadOrPasteData`: `Cargue` changed to match the rest of the app's `Subir` convention
- [ ] `readiness` / `avgReadinessLabel`: `Disposición` changed to `Preparación`
- [ ] `lessonTimeEnded`: `Haga clic` changed to `Toque`
- [ ] `studyAnalytics`: `Analíticas` changed to `Analítica`
- [ ] `examAutoSubmitted`: `se acabó el tiempo` changed to `se agotó el tiempo`
- [ ] `difficultyMedium` and `fontSizeMedium`: harmonized to use the same word
- [ ] `usageSummary`: `sobre` changed to `de`
- [ ] `completionOfValue`: `Completado` changed to `Completo`

### Hardcoded strings
- [ ] `export_section.dart`: Share text and instrumentation labels extracted to ARB keys
- [ ] `weekly_chart.dart`: Day abbreviations sourced from `DateFormat` or ARB
- [ ] `chat_bubble.dart`: Accessibility labels extracted to ARB keys

### Number format bugs
- [ ] `mentor_screen.dart:304`: `report.totalStudyTimeHours` formatted via `formatDecimal` before interpolation
- [ ] `engagement_scheduler.dart:271,276–283`: `totalHours` formatted via `formatDecimal` before interpolation; fallback string also corrected

### New locale readiness
- [ ] `profile_screen.dart`: Locale dropdown label derivation is data-driven (not switch/case per locale)
- [ ] Validation test added: `AppLocale.values` matches `AppLocalizations.supportedLocales`
- [ ] CI script added (or `check_i18n_coverage.sh` extended) to detect hardcoded user-facing strings in `lib/features/` and `lib/core/`

---

## Affected Files Summary

| File | Issue |
|---|---|
| `lib/l10n/app_es.arb` | 11 translation quality issues (lines 372, 648, 722, 1135, 1409, 1470, 2160, 2642–2643, 3052, 3672, 4117, 4449) |
| `lib/features/dashboard/presentation/widgets/export_section.dart` | 3 hardcoded share texts + 4 instrumentation labels (lines 61, 81, 104, 116–126) |
| `lib/features/dashboard/presentation/widgets/weekly_chart.dart` | Hardcoded day abbreviations (line 46) |
| `lib/features/teaching/presentation/widgets/chat_bubble.dart` | Hardcoded accessibility labels (line 155) |
| `lib/core/services/study_progress_tracker.dart` | Root cause: `toStringAsFixed` in data map (line 51) |
| `lib/features/mentor/presentation/mentor_screen.dart` | Downstream locale-blind number in localized template (line 304) |
| `lib/core/services/engagement_scheduler.dart` | Downstream locale-blind number in localized template (lines 271, 276–283) |
| `lib/features/settings/presentation/profile_screen.dart` | Non-scalable locale dropdown switch (lines 416–419) |
| `lib/core/config/locale_config.dart` | Missing validation between enum and generated locales |
| `scripts/check_i18n_coverage.sh` | Extend to detect hardcoded user-facing strings |
