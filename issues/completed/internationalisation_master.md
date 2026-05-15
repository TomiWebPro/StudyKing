# Planner Feature L10n Bleed: Hardcoded English Strings Bypass Translation System

## Context

The project has a well-engineered ARB-based i18n pipeline with full English/Spanish coverage (1757 keys each). However, the **planner feature** — the app's most complex feature — contains **30+ hardcoded English strings** across providers, widgets, and services that completely bypass the translation system. These strings appear as success/error messages, progress labels, calendar headers, empty-state text, and button labels. A Spanish user sees a jarring mix of Spanish (from ARB keys) and untranslated English in adjacent UI elements. When adding future languages (French, German, etc.), these strings will remain stubbornly in English.

The `planner_providers.dart` `StateNotifier` is the single worst offender: it cannot access `AppLocalizations` because there is no `BuildContext` in a `StateNotifier`. The existing pattern of threading an `AppLocalizations?` parameter through individual methods (used in `createRoadmap` and `scheduleLessonWithConflictCheck`) is inconsistent — 16 of 18 error/success messages remain hardcoded.

---

## Affected Files

| File | Problem | Count |
|---|---|---|
| `lib/features/planner/providers/planner_providers.dart:280-471` | Hardcoded English success/error messages in `PlannerNotifier` that have no access to `AppLocalizations` | **21 strings** |
| `lib/features/planner/presentation/widgets/progress_overlay_widget.dart:24,50,60,64,106,122,148,163,167,181` | Hardcoded English "Progress Overview", "Today's Progress", "Planned: X min", "Actual: Y min", "Weekly", English day abbreviations `['M','T','W','T','F','S','S']`, "Actual"/"Planned" legend, "X/Y days — Z% of plan" | **10 strings** |
| `lib/features/planner/presentation/widgets/calendar_view_widget.dart:96` | Hardcoded English day header abbreviations `['M','T','W','T','F','S','S']` | **7 strings** |
| `lib/features/planner/presentation/widgets/calendar_view_widget.dart:80` | `DateFormat.yMMM()` without locale parameter → always shows English month names | **1 usage** |
| `lib/features/planner/presentation/widgets/milestone_timeline.dart:110,123` | `DateFormat.yMMMd()` / `DateFormat.MMMd()` without locale → always English dates | **2 usages** |
| `lib/features/planner/presentation/widgets/roadmap_card.dart:98` | `DateFormat.yMMMd()` without locale → always English dates | **1 usage** |
| `lib/features/planner/presentation/widgets/roadmap_card.dart:90` | `${l10n.milestones.toLowerCase()}` — `.toLowerCase()` is a non-l10n hack that breaks for languages with different casing rules | **1 usage** |
| `lib/features/planner/presentation/widgets/roadmap_card.dart:123` | Hardcoded `'${milestone.topicsCovered.length} topics'` | **1 string** |
| `lib/features/planner/presentation/planner_screen.dart:225` | `const Tab(text: 'Calendar')` — hardcoded tab label | **1 string** |
| `lib/features/planner/presentation/planner_screen.dart:417,421` | `${l10n.days.toLowerCase()}` — `.toLowerCase()` hack | **2 usages** |
| `lib/features/planner/presentation/planner_screen.dart:501` | `const Text('Redistribute')` — hardcoded button label | **1 string** |
| `lib/features/planner/presentation/planner_screen.dart:539` | Manual `'${hour}:${minute}'` time formatting — not locale-aware (should use `DateFormat.jm()` with locale) | **1 usage** |
| `lib/features/planner/presentation/planner_screen.dart:610` | `Text('No study plan yet')` — hardcoded empty-state text | **1 string** |
| `lib/features/planner/services/planner_service.dart:176` | Hardcoded `'Topics: ${milestoneTopics.length} syllabus topics'` | **1 string** |
| `lib/features/planner/services/planner_service.dart:184` | Hardcoded `'Mastery >= 80% on all milestone topics'` | **1 string** |
| `lib/features/planner/services/syllabus_resolver.dart:50,109,122,140` | Hardcoded English error messages | **4 strings** |

---

## Rationale

1. **Broken Spanish UX:** ARB keys exist for `failedToGeneratePlan` ("Error al generar el plan"), `timeConflict` ("Conflicto de horario con una lección programada"), `milestones` ("Hitos"), `topics` ("Temas"), `targetCompletion` ("Finalización Prevista"), and `noStudyPlanToday` ("No hay plan de estudio para hoy") — **none of which are used** in the planner code. Instead, hardcoded English equivalents appear.

2. **Day abbreviations are language-specific:** `['M', 'T', 'W', 'T', 'F', 'S', 'S']` is correct for English but wrong for Spanish (where it should be `['L', 'M', 'M', 'J', 'V', 'S', 'D']` for lunes→domingo). Using `DateFormat.E()` with the user's locale solves this properly.

3. **`.toLowerCase()` breaks l10n:** `${l10n.milestones.toLowerCase()}` works by accident in English and Spanish (Latin script) but breaks in Turkish (`İ` → `i` instead of `i`), and is meaningless for scripts like Arabic or Chinese. The ARB keys should return text in the correct case for each locale.

4. **DateFormat defaults to English:** `DateFormat.yMMMd()` without a locale argument always formats in English. It must receive the current locale from `AppLocalizations` (e.g., `DateFormat.yMMMd(l10n.localeName)`).

5. **PlannerNotifier pattern is broken:** A `StateNotifier` has no `BuildContext`, so it cannot call `AppLocalizations.of(context)`. The fix should pass `AppLocalizations` as a parameter (already done for `createRoadmap` and `scheduleLessonWithConflictCheck`) but must be applied **consistently** to all methods.

---

## Acceptance Criteria

- [ ] **AC1 — ARB keys added:** Add the following new keys to both `app_en.arb` and `app_es.arb` (Spanish values provided):
  - `planGeneratedSuccessfully` → "Plan generated successfully" / "Plan generado exitosamente"
  - `failedToGeneratePlan` → Already exists — just wire it up
  - `syllabusPlanGenerated` → "Syllabus-based plan generated successfully" / "Plan basado en el programa generado exitosamente"
  - `failedToGenerateSyllabusPlan` → "Failed to generate syllabus plan" / "Error al generar el plan basado en el programa"
  - `failedToCreateRoadmap` → "Failed to create roadmap" / "Error al crear la hoja de ruta"
  - `failedToUpdateMilestone` → "Failed to update milestone" / "Error al actualizar el hito"
  - `actionAccepted` → "Action accepted" / "Acción aceptada"
  - `failedToExecuteAction` → "Failed to execute action — missing parameters" / "Error al ejecutar la acción — faltan parámetros"
  - `failedToAcceptAction` → "Failed to accept action" / "Error al aceptar la acción"
  - `failedToDismissAction` → "Failed to dismiss action" / "Error al descartar la acción"
  - `lessonScheduled` → "Lesson scheduled" / "Lección programada"
  - `failedToScheduleLesson` → "Failed to schedule lesson" / "Error al programar la lección"
  - `planRegeneratedFromAdherence` → "Plan regenerated based on your adherence" / "Plan regenerado según tu cumplimiento"
  - `failedToRegeneratePlan` → "Failed to regenerate plan" / "Error al regenerar el plan"
  - `missedWorkloadRedistributed` → "Missed workload redistributed over next 3 days" / "Trabajo pendiente redistribuido en los próximos 3 días"
  - `failedToRedistributeWorkload` → "Failed to redistribute workload" / "Error al redistribuir el trabajo pendiente"
  - `progressOverview` → "Progress Overview" / "Resumen de Progreso"
  - `todaysProgress` → "Today's Progress" / "Progreso de Hoy"
  - `weekly` → "Weekly" / "Semanal"
  - `actual` → "Actual" / "Real"
  - `planned` → "Planned" / "Planificado"
  - `noStudyPlanYet` → "No study plan yet" / "Aún no hay plan de estudio"
  - `calendar` → "Calendar" / "Calendario"
  - `redistribute` → "Redistribute" / "Redistribuir"

- [ ] **AC2 — PlannerNotifier uses ARB keys:** Refactor `PlannerNotifier` so all methods that set `successMessage` or `error` accept `AppLocalizations l10n` as a parameter (like `createRoadmap` already does). The caller in `planner_screen.dart` must pass `l10n` when invoking these methods.

- [ ] **AC3 — ProgressOverlayWidget uses ARB keys:** Replace all hardcoded English strings in `progress_overlay_widget.dart` with `AppLocalizations.of(context)!` lookups.

- [ ] **AC4 — Day abbreviations use DateFormat:** Replace hardcoded `['M', 'T', 'W', 'T', 'F', 'S', 'S']` in both `calendar_view_widget.dart` and `progress_overlay_widget.dart` with `DateFormat.E()` using the user's locale.

- [ ] **AC5 — All DateFormat calls pass locale:** Every `DateFormat.xxx().format(...)` call in the planner feature must include the locale parameter, e.g. `DateFormat.yMMMd(l10n.localeName).format(...)`.

- [ ] **AC6 — `.toLowerCase()` removed:** Eliminate all `.toLowerCase()` hacks on localized strings in `roadmap_card.dart` and `planner_screen.dart`. Use properly cased ARB values or ICU plural variants.

- [ ] **AC7 — Hardcoded `'topics'` string replaced:** Replace `'${milestone.topicsCovered.length} topics'` in `roadmap_card.dart` with an ICU plural ARB key (e.g., `topicCount` with `{count, plural, =1{1 topic} other{{count} topics}}`).

- [ ] **AC8 — `planner_screen.dart` hardcoded strings replaced:**
  - `'Calendar'` tab label → use new `l10n.calendar` key
  - `'Redistribute'` button → use new `l10n.redistribute` key
  - `'No study plan yet'` → use new `l10n.noStudyPlanYet` key
  - Manual time formatting → `DateFormat.Hm(l10n.localeName)` or `DateFormat.jm(l10n.localeName)`

- [ ] **AC9 — Service-layer errors wired:** Add `AppLocalizations` parameter to `planner_service.dart` and `syllabus_resolver.dart` error messages, or raise errors with codes that the provider translates.

- [ ] **AC10 — Verify with Spanish locale:** Run the app with `Locale('es')` and confirm every hardcoded English string listed above now appears in Spanish.
