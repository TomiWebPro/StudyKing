# Internationalisation Master Issue

**Created:** 2026-05-19
**Audit scope:** Entire codebase (`lib/`, `lib/l10n/`)
**Target locale:** Spanish (`es`); patterns extend to any language
**Generator:** `flutter gen-l10n` from `lib/l10n/app_{en,es}.arb` (1,342 keys, full parity)

---

## BLOCKER — App crashes or user cannot proceed

*None found.* All 1,342 ARB keys are present in both locales with matching `{param}` placeholders. No locale-unaware `toStringAsFixed()` calls remain in presentation code (all 9 extant calls are in CSV/LLM exports, exempt per `AGENTS.md`). Generated `AppLocalizations` compiles without error for both `en` and `es`.

---

## MAJOR — Feature broken or user-facing text is wrong/misleading

### M1. Hardcoded English user-facing strings in agent loop

`lib/core/services/llm_agent/agent_loop.dart`

Four error/success messages are hardcoded in English and sent directly to the user (not to the LLM):

| Line | Current EN | Issue |
|------|-----------|-------|
| 62 | `'I encountered an error processing your request.'` | Always English |
| 78 | `'I tried to use a tool "$parsed" but it is not available.'` | Always English |
| 117 | `'I completed the required actions. Is there anything else you need help with?'` | Always English |
| 126 | `'An error occurred during processing.'` | Always English |

**Fix:** Add ARB keys (e.g. `agentError`, `agentToolNotFound`, `agentCompleted`, `agentProcessingError`) to both `app_en.arb` and `app_es.arb`, then lookup via `AppLocalizations` or `lookupAppLocalizations`. The `agent_loop` class has no locale parameter — it must receive one or derive it from a provider.

**Acceptance:** A Spanish user sees `"Encontré un error al procesar tu solicitud."` instead of `"I encountered an error..."`.

---

### M2. Hardcoded English dashboard strings with `(s)` hack

`lib/features/dashboard/presentation/widgets/next_up_card.dart`

Three user-facing titles use manual string concatenation with the `(s)` hack instead of ARB plurals:

| Line | Current code |
|------|-------------|
| 84 | `subtitle: '${upcomingLessons.length} upcoming lesson(s)'` |
| 92 | `title: '$dueCount review(s) due'` |
| 101 | `title: '$weakCount weak topic(s)'` |

`lib/features/dashboard/presentation/widgets/workload_card.dart`

| Line | Current code |
|------|-------------|
| 82 | `'${topicsNeedingAttention.length} topics need attention'` |

All four strings are **hardcoded in English** and ignore the user's locale. They must be migrated to ARB plural keys (e.g. `upcomingLessonsCount`, `dueReviewsCount`, `weakTopicsCount`, `topicsNeedingAttentionCount`).

**Acceptance:**
- `next_up_card.dart` renders `"3 próximas lecciones"` for `es` locale.
- `workload_card.dart` renders `"3 temas necesitan atención"` for `es` locale.
- All four keys exist in both `app_en.arb` and `app_es.arb` with proper ICU `{count, plural, =1{...} other{...}}` syntax.

---

### M3. Hardcoded English fallback content in lesson generation

`lib/features/lessons/services/lesson_agent_service.dart:243-253`

`_fallbackBlocks()` contains hardcoded English strings:

```dart
content: 'Lesson: $topicTitle',
content: 'Study the key concepts of $topicTitle. Focus on understanding the core principles.',
```

When LLM generation fails, Spanish users receive English fallback text. Since this method has access to `localeName` (the caller chain passes it), the fix should use `lookupAppLocalizations(Locale(localeName))` to fetch translated fallback templates.

**Acceptance:** When LLM generation fails for a Spanish user, `_fallbackBlocks` produces `"Lección: $topicTitle"` / `"Estudia los conceptos clave de $topicTitle..."`.

---

### M4. Duplicate ARB keys in `app_es.arb` silently losing translations

`lib/l10n/app_es.arb`

Seven keys appear twice. JSON silently keeps the **last** occurrence, discarding the first translation:

| Key | 1st occurrence value (lost) | 2nd occurrence value (kept) |
|-----|----------------------------|----------------------------|
| `manualSessionTracker` | `"Rastreador Manual de Sesiones"` | `"Rastreador de Sesiones Manual"` |
| `manualSessionTrackerDescription` | `"Realice un seguimiento manual de sus sesiones de estudio"` | `"Seguimiento manual del tiempo de estudio"` |
| `sessionHistoryDescription` | `"Vea el historial de sus sesiones"` | `"Revisar sesiones de estudio anteriores"` |
| `sessionTracking` | `"Seguimiento de Sesiones"` (same) | `"Seguimiento de Sesiones"` (same) |
| `exportProgressCsv` | `"Exportar Progreso CSV"` (same) | `"Exportar Progreso CSV"` (same) |
| `tapToCollapse` | `"Toca para colapsar"` (same) | `"Toca para colapsar"` (same) |
| `tapToExpand` | `"Toca para expandir"` (same) | `"Toca para expandir"` (same) |

For items 1-3, the discarded values are different translations — the user sees the wrong variant. For items 4-7, the duplicates waste bytes and create maintenance risk (one could be updated while the other stays stale).

**Acceptance:** No duplicate keys exist in `app_es.arb`. Each key appears exactly once with the most appropriate Spanish translation.

---

### M5. Formal/informal register mixing in `app_es.arb`

Multiple strings mix `tú` (informal) and `usted` (formal) registers. The file's predominant register is formal `usted`, making the informal strings inconsistent.

| Key | Line | Value | Issue |
|-----|------|-------|-------|
| `unsavedChangesDescription` | 2893 | `"Tienes cambios sin guardar. ¿Estás seguro de que quieres descartarlos?"` | Should be `"Tiene cambios sin guardar. ¿Está seguro de que quiere descartarlos?"` |
| `focusForMinutes` | 3505 | `=1{Enfócate por 1 minuto} other{Enfóquese por {minutes} minutos}` | MIXED: singular uses `tú`, plural uses `usted`. Both should use `usted`. |
| `onboardingSettingsDesc` | 4804 | `"Configura claves API, apariencia y preferencias"` | `"Configure..."` |
| `needApiKeyNotice` | 4812 | `"Configúrala en Ajustes."` | `"Configúrela en Ajustes."` |

**Acceptance:** All Spanish strings use the same register (formal `usted`), consistent with the majority of the ARB file. The `focusForMinutes` singular and plural forms agree on register.

---

### M6. Missing ICU plurals in English ARB (grammatical errors)

| Key | Line | Current | Problem |
|-----|------|---------|---------|
| `downstreamTopicWarning` | 6513 | `"⚠ {count} downstream topic(s) depend..."` | `(s)` hack; displays `"⚠ 1 downstream topic(s)"` |
| `prerequisitesCount` | 6491 | `"{count} prerequisites"` | Shows `"1 prerequisites"` (grammar error) |
| `downstreamCount` | 6498 | `"{count} downstream"` | Shows `"1 downstream"` (grammar edge case) |
| `sourcesCountLabel` | 6044 | `other{{count} Source(s)}` | `(s)` hack in `other` form |

**Acceptance:** Each of these keys uses proper ICU plural syntax `{count, plural, =1{1 ...} other{{count} ...}}` in both `app_en.arb` and `app_es.arb`.

---

### M7. RTL-unaware directional icons

Hardcoded `Icons.chevron_left` / `Icons.chevron_right` / `Icons.arrow_back` / `Icons.arrow_forward` / `Icons.arrow_forward_ios` that do not respect `Directionality.of(context)`:

| File | Lines | Current Icon | Should be |
|------|-------|-------------|-----------|
| `lib/features/lessons/presentation/widgets/lesson_block_card.dart` | 164, 188 | `Icons.chevron_left`, `Icons.chevron_right` | Check `Directionality` and flip |
| `lib/features/lessons/presentation/lesson_detail_screen.dart` | 128 | `Icons.arrow_back` | Check `Directionality` and flip |
| `lib/features/practice/presentation/widgets/practice_session_nav_buttons.dart` | 31, 44, 64, 79 | `Icons.arrow_back`, `Icons.arrow_forward` | Check `Directionality` and flip |
| `lib/features/teaching/presentation/tutor_screen.dart` | 961, 972 | `Icons.chevron_left`, `Icons.chevron_right` | Check `Directionality` and flip |
| `lib/features/dashboard/presentation/widgets/next_up_card.dart` | 124 | `Icons.chevron_right` | Check `Directionality` and flip |
| `lib/features/dashboard/presentation/dashboard_screen.dart` | 536 | `Icons.chevron_right` | Check `Directionality` and flip |
| `lib/features/subjects/presentation/subject_list_screen.dart` | 188 | `Icons.arrow_forward_ios` | Check `Directionality` and flip |
| `lib/features/practice/presentation/widgets/practice_mode_option.dart` | 59–60 | `Icons.arrow_forward_ios` | Check `Directionality` and flip |
| `lib/features/settings/presentation/settings_screen.dart` | 251, 394, 437, 1798, 1841 | `Icons.arrow_forward_ios` | Check `Directionality` and flip |

The project already has a correct pattern for this in ~18 other locations (e.g. `dashboard_screen.dart:222`):
```dart
Directionality.of(context) == TextDirection.rtl
    ? Icons.chevron_left
    : Icons.chevron_right
```

**Acceptance:** All directional icons use the existing `Directionality.of(context)` pattern (or `Icons.chevron_left`/`chevron_right` triple-check pattern). No hardcoded LTR-only arrows remain in production code.

---

### M8. `Alignment.centerLeft` in planner (RTL-unaware)

`lib/features/planner/presentation/planner_screen.dart:1377`

```dart
alignment: Alignment.centerLeft,  // should be AlignmentDirectional.centerStart
```

**Acceptance:** `AlignmentDirectional.centerStart` is used instead, which flips automatically in RTL.

---

## MINOR — Code quality / UX friction

### m1. Hardcoded gradient direction in lesson blocks

`lib/features/lessons/presentation/widgets/lesson_block_card.dart:66-67`

```dart
begin: Alignment.topLeft,
end: Alignment.bottomRight,
```

Should use `AlignmentDirectional.topStart` / `AlignmentDirectional.bottomEnd`. The core `gradient_container.dart` already does this correctly.

---

### m2. Row text overflow risks with long translations

Text widgets inside `Row` without `Flexible`/`Expanded` — will overflow when translated strings are longer:

| File | Lines | Widget | Risk |
|------|-------|--------|------|
| `lib/features/lessons/presentation/widgets/lesson_list_item.dart` | 35–43 | `Row > Text(l10n.blocksCount(...))` + `SizedBox` + `Container` | Blocks count label + status chip in a `Row` — long translation pushes chip off-screen |
| `lib/features/questions/presentation/widgets/single_answer_widget.dart` | 113–128 | `Row > Text(l10n.correctFeedback/l10n.incorrectFeedback)` | Feedback text after `SizedBox(width:8)` + icon — no overflow handling |
| `lib/features/planner/presentation/widgets/milestone_timeline.dart` | 155–174 | `Container(symmetric(horizontal:8)) > Text(milestone + date)` | Hard-constrained horizontal padding, concatenated strings |

**Acceptance:** Each location wraps the `Text` in `Flexible(child: Text(... overflow: TextOverflow.ellipsis))` or changes the layout to prevent overflow.

---

### m3. `EdgeInsets.fromLTRB` where symmetrical — should be `EdgeInsetsDirectional`

| File | Lines | Pattern |
|------|-------|---------|
| `lib/features/settings/presentation/settings_screen.dart` | 654, 667, 677 | `fromLTRB(16, ..., 16, ...)` |
| `lib/features/questions/presentation/question_bank_screen.dart` | 682 | `fromLTRB(16, 8, 16, 4)` |
| `lib/features/ingestion/presentation/content_library_screen.dart` | 348 | `fromLTRB(16, 8, 16, 0)` |

All have equal `left`/`right`, so they are functionally safe, but should use `EdgeInsetsDirectional` for clarity and maintenance consistency.

---

### m4. Content mismatch: `onboardingFocusDesc`

`app_en.arb`: `"Quick practice hub with timer — practice questions and track focus"`
`app_es.arb` line 4800: `"Mantenga el enfoque con sesiones de estudio estilo Pomodoro"`

The Spanish translation introduces "Pomodoro-style study sessions" which does not appear in the English source. If the app does not use Pomodoro timing, this is misleading.

**Acceptance:** The Spanish translation matches the English semantics, or the English source is updated to reflect Pomodoro timing if that is the actual feature.

---

### m5. ARB descriptions in Spanish

~30+ `@description` fields in `app_es.arb` are written in Spanish instead of English (e.g. lines 2891, 2895, 2899 for `unsavedChanges` group). Descriptions are metadata for translators and should be in English regardless of the target locale.

**Acceptance:** All `@description` values in `app_es.arb` are in English, matching the conventions in the rest of the file.

---

### m6. Punctuation / style inconsistencies in ES

| Key | English | Spanish | Issue |
|-----|---------|---------|-------|
| `breakTime` | `"Break Time!"` | `"Descanso"` | Missing exclamation mark |
| `timerDone` | `"DONE!"` | `"TERMINADO"` | Missing exclamation mark |

---

### m7. Missing keyword maps for `fr`/`de` in conversation manager

`lib/features/teaching/services/conversation_manager.dart:304-326`

`_continueKeywordsByLocale` and `_exerciseKeywordsByLocale` only support `en` and `es`. The `mentor_service.dart:316-328` already supports `en`, `es`, `fr`, `de`. These should be aligned so `fr` and `de` keyword detection works in the tutor conversation flow.

---

### m8. `hoursPerDayAbbrev` structural format difference

`app_en.arb`: `"{hours}/Days"` — uses `/Days` suffix
`app_es.arb`: `"{hours} h/día"` — uses `h/día`

Verify that consuming code does not assume the `/Days` suffix. If the code strips or matches on `/Days`, the Spanish variant would not render as intended.

---

## Summary by area

| Area | Major | Minor |
|------|-------|-------|
| User-facing English hardcoded strings | M1, M2, M3 | — |
| ARB file quality | M4, M5, M6 | m4, m5, m6, m8 |
| RTL / Directionality | M7, M8 | m1, m3 |
| Layout overflow with long strings | — | m2 |
| Keyword maps | — | m7 |

## Recommended fix order

1. **M2, M6** (dashboard strings + EN plurals) — most visible to users, low risk
2. **M1** (agent_loop) — users get English error messages, medium effort
3. **M4** (duplicate ARB keys) — silent data loss, easy fix
4. **M5** (register mixing) — UX polish, affects many strings
5. **M3** (lesson fallback) — edge case but wrong text for Spanish users
6. **M7, M8, m1** (RTL) — foundational for future RTL language support
7. **m2** (overflow) — prevent layout breaks with longer translations
8. **m3–m8** — code quality / docs polish
