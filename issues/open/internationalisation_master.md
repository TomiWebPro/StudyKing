# Issue: Spanish Localization Audit — Register Inconsistency, Anglicisms, Missing Translation Hooks

## Context

The Spanish (`es`) ARB file at `lib/l10n/app_es.arb` contains 1,425 keys and is largely well-translated. However, a detailed audit reveals several categories of issues that degrade the user experience for Spanish speakers and create architectural friction for adding future languages.

---

## 1. Register Inconsistency: `tú` (informal) vs. `usted` (formal)

**Severity: High**

The app overwhelmingly uses formal `usted` imperatives (the standard register for Latin American Spanish educational/professional apps):

- `"Agregue"` (add — formal imperative)
- `"Escriba"` (write — formal imperative)
- `"Ingrese"` (enter — formal imperative)
- `"Seleccione"` (select — formal imperative)
- `"Intente"` (try — formal imperative)
- `"Siga"` (continue — formal imperative)
- `"Toque"` (tap — formal imperative)
- `"Comience"` (start — formal imperative)
- `"Verifique"` (verify — formal imperative)
- `"Obtenga"` (get — formal imperative)
- `"Pregúntele"` (ask him/her — formal imperative)
- `"Asegúrese"` (make sure — formal imperative)
- `"Configúrela"` (configure it — formal imperative)
- `"Dibuje"` (draw — formal imperative)

However, **one string uses informal `tú`**:

| Key | Current Spanish | Issue |
|---|---|---|
| `quickGuideSystemPrompt` (line 2358) | `"Eres la Guía Rápida de StudyKing..."` | Uses `"Eres"` (informal *tú* form) while the entire rest of the app uses formal *usted* |

**Fix**: Change to `"Es la Guía Rápida de StudyKing..."` (formal *usted* form) to match the app-wide register.

---

## 2. Anglicisms and Unnatural Translations

**Severity: Medium**

Several Spanish strings use direct calques from English that sound unnatural to native Spanish speakers.

| Key | Current Spanish | Suggested Improvement | Rationale |
|---|---|---|---|
| `sessionDurationMinutes` | `"{minutes} min de sesión"` | `"Sesión de {minutes} min"` | Spanish places the noun before the quantity, not after |
| `studySessionTracker` | `"Rastreador de Sesiones de Estudio"` | `"Seguimiento de sesiones"` or `"Control de sesiones de estudio"` | "Rastreador" is a technical anglicism; "Seguimiento" is the natural UX term |
| `renderedGraph` | `"Gráfico Renderizado"` | `"Gráfico generado"` or `"Gráfico visualizado"` | "Renderizado" is a direct English borrowing; native alternatives exist |
| `graphTypeSetTo` | `"Tipo de gráfico cambiado a {graphType}"` | `"Gráfico cambiado a {graphType}"` or `"Tipo de gráfico: {graphType}"` | "Tipo de gráfico cambiado a" is overly verbose and awkward |
| `graphTypeDetectionError` | `"La detección del tipo de gráfico falló"` | `"Error al detectar el tipo de gráfico"` | "falló" is correct but "Error al ..." is more idiomatic for error messages in Spanish |
| `exportFailed` | `"Exportación fallida: {error}"` | `"Error al exportar: {error}"` | "Exportación fallida" is a calque; "Error al exportar" is the standard Spanish pattern |
| `noAtRiskTopics` | `"Sin temas con dificultades. ¡Siga así!"` | `"No hay temas en riesgo. ¡Siga así!"` | "Sin temas con dificultades" is grammatically awkward; "en riesgo" is more direct |
| `noWeakAreasFound` | `"No se encontraron áreas débiles. ¡Siga así!"` | `"No se encontraron áreas por mejorar. ¡Siga así!"` | Inconsistent with `weakAreas` key which uses `"Áreas por mejorar"` (line 219) |

---

## 3. Intra-Spanish Dialect Inconsistency

**Severity: Medium**

The Spanish ARB predominantly uses Latin American conventions — `"Agregar"` (not Spain's `"Añadir"`), `"Materias"` (not `"Asignaturas"`). However one string uses the Spain-preference variant:

| Key | Current Spanish | Issue |
|---|---|---|
| `mentorNewSessionAdded` (line 2732) | `"He añadido una nueva sesión de estudio a su horario."` | Uses `"añadido"` (Spain *voseo*/*castellano* preference) while the entire rest of the app uses `"Agregar/Agregue"` (Latin American preference) |

**Fix**: Change to `"He agregado una nueva sesión de estudio a su horario."` for consistency with the Latin American convention used elsewhere in the app.

---

## 4. Terminology Inconsistency Within ARB

**Severity: Medium**

The same English concept is translated differently in different keys:

| English | Spanish in Key A | Spanish in Key B | Issue |
|---|---|---|---|
| "weak areas" | `"Áreas por mejorar"` (`weakAreas`, line 219) | `"áreas débiles"` (`noWeakAreasFound`, line 267) | Different translations for the same concept |
| "at-risk topics" | `"Temas con dificultades"` (`atRiskTopics`, line 2224) | `"temas con dificultades"` (`noAtRiskTopics`, line 2228) | The empty-state variant drops capitalization — minor but noticeable |

**Fix**: Normalize to `"Áreas por mejorar"` (the more positive and idiomatic Spanish phrasing) and `"Temas en riesgo"` (or keep `"Temas con dificultades"` but use consistently).

---

## 5. 60+ Hardcoded English Strings in Core Services (Bypass the ARB System Entirely)

**Severity: Critical — Architectural**

While every presentation widget correctly uses `AppLocalizations.of(context)`, the following service-layer files generate user-facing messages with hardcoded English strings that never go through the localization system:

### 5a. `lib/core/data/models/badge_model.dart` — Badge names & descriptions (12 strings)

```dart
// Lines 56–107 — hardcoded English
BadgeDefinition(id: 'first_attempt', name: 'First Step',
    description: 'Answered your first question!'),
BadgeDefinition(id: 'century', name: 'Century Club',
    description: 'Answered 100+ questions!'),
// ... 4 more badges
```

**Fix**: Move badge names and descriptions to ARB keys (e.g., `badgeFirstStepName`, `badgeFirstStepDesc`) and look them up via `AppLocalizations` in the UI. Create an `BadgeLocalizer` service that maps `badgeId` → localized name/description.

### 5b. `lib/core/services/notification_service.dart` — Push notifications (17+ strings)

All notification titles, bodies, channel names, and channel descriptions are hardcoded in English:
- `'Time to Review!'`, `'Take a Break'`, `'Plan Adjustment'`, `'Upcoming Lesson'`, `'Topics Need Attention'`, `'Badge Unlocked!'`
- Bodies like `'It\'s been $daysSince days since you practiced "$topicName".'`
- Channel names: `'StudyKing Notifications'`, `'Revision Reminders'`, `'Wellbeing Alerts'`, etc.

**Fix**: Accept `AppLocalizations` as a parameter (or inject it) and use localized strings for all user-facing notification text.

### 5c. `lib/core/services/engagement_scheduler.dart` — Nudge messages (4 strings)

```dart
message: 'You have studied ${totalHours.toStringAsFixed(1)} hours today. Consider taking a break!'
message: 'It has been $daysSince days since you practiced "${state.topicId}". Time for a review!'
message: 'You have had $consecutiveLow days of low plan adherence. Would you like to adjust your study plan?'
// Weekly digest in getWeeklyDigest()
```

### 5d. `lib/core/services/personal_learning_plan_service.dart` — Plan explanations & reasons (20+ strings)

```dart
'Accuracy is below 60% — needs focused practice'
'Review is overdue — forgetting risk is high'
'Streak is low — consistency needed'
'Prerequisite for upcoming topics — must master first'
'High mastery — ready to advance'
'Good progress — maintain consistency'
'Developing — needs more practice'
'At risk — review overdue'
'Needs attention — focus on fundamentals'
'General review', 'Focus on weak areas', 'Practice and review'
'Required for dependent topics', 'Weak performance', 'High forgetting risk'
'New syllabus topic', 'Part of syllabus goal'
'Rest and review'
// ... and more
```

### 5e. `lib/core/services/plan_adapter.dart` — Adherence messages (2 strings)

```dart
'You have had $lowDays consecutive days of low adherence. Consider adjusting your study plan ...'
'You have had $lowDays consecutive days of low adherence. Would you like to regenerate ...'
```

### 5f. `lib/core/services/study_progress_tracker.dart` — Recommendations (8 strings)

```dart
'Your overall accuracy is below 60%. Focus on reviewing fundamental concepts.'
'Review basic topics before advancing'
'Excellent progress! Ready for advanced topics.'
'Try challenging practice questions'
'You studied less than 1 hour total. Consistency is key!'
'No study activity this week. Get back on track!'
'You have ${weakTopics.data!.length} topic(s) that need improvement...'
'Review weak topics with the AI tutor'
```

### 5g. `lib/core/services/adaptive_practice_engine.dart` — Suggestions (3 strings)

```dart
'Review basic concepts first'
'More practice questions recommended'
'Ready for advanced topics'
```

### 5h. `lib/features/sessions/services/session_export_service.dart` — CSV headers & share text

```dart
// Line 23-24 — hardcoded English CSV header
buffer.writeln('Session ID,Student ID,Subject,Start Time,End Time,'
    'Duration (min),Questions Answered,Correct,Accuracy (%)');

// Lines 211, 219, 228 — hardcoded share text
await Share.shareXFiles([XFile(file.path)], text: 'Study Sessions');
```

---

## 6. Poor Descriptions in `app_es.arb` (39 entries)

**Severity: Low (metadata quality)**

39 keys have `"description": "Auto-generated key for xyz"` rather than a meaningful Spanish description. Examples:

| Key | Current Description |
|---|---|
| `csvOverallStats` | `"Auto-generated key for csvOverallStats"` |
| `pdfNoBadges` | `"Auto-generated key for pdfNoBadges"` |
| `pdfTableLevel` | `"Auto-generated key for pdfTableLevel"` |

While descriptions don't affect runtime output, they are metadata for future translators and should describe the string's purpose in Spanish (or at least in English). The `app_en.arb` likely has the same issue.

---

## 7. No Regional Variant Support

**Severity: Medium**

The app registers `supportedLocales: [Locale('en'), Locale('es')]` without regional variants. A user with `es-MX` (Mexico), `es-ES` (Spain), or `es-AR` (Argentina) all get the same translation. This is acceptable for now, but the `localeResolutionCallback` in `main.dart` should be explicitly documented to note that all Spanish variants map to `es`, and the ARB commentary should note that `app_es.arb` targets neutral Latin American Spanish (and that a future `app_es_ES.arb` could be added for Spain-specific vocabulary like `"ordenador"`, `"vale"`, `"añadir"`, etc.).

---

## Architecture Recommendation: Localization Service for Non-Widget Code

**Severity: Critical (follow-up)**

The root cause of Issue #5 is architectural: core services (notifications, plans, badges, nudges, recommendations) generate user-facing text without access to `AppLocalizations`, which is only available in widget context via `BuildContext`. 

**Recommended approach**: Create a `LocalizationService` that wraps `AppLocalizations` and can be injected into non-widget code:

```dart
class LocalizationService {
  final AppLocalizations _l10n;
  LocalizationService(this._l10n);

  String badgeName(String badgeId) { /* lookup from ARB */ }
  String nudgeMessage(NudgeType type, Map<String, dynamic> params) { /* ... */ }
  String recommendationMessage(/* ... */) { /* ... */ }
  String csvHeader(String columnKey) { /* ... */ }
}
```

This service would be created once in `MaterialApp`'s builder and passed down via Provider or constructor injection.

---

## Acceptance Criteria

1. **Register consistency**: `quickGuideSystemPrompt` uses formal *usted* ("Es" instead of "Eres") to match the rest of the app.
2. **Anglicism fix**: At least 5 of the identified unnatural translations (section 2) are revised to idiomatic Spanish.
3. **Dialect fix**: `mentorNewSessionAdded` uses "agregado" instead of "añadido" for Latin American consistency.
4. **Terminology normalization**: "weak areas" is consistently `"Áreas por mejorar"` across the entire ARB file.
5. **`LocalizationService` created** in `lib/core/services/localization_service.dart` with documented pattern for non-widget localization.
6. **Badge names/descriptions** moved to ARB keys and looked up via the new `LocalizationService`.
7. **Notification service** updated to accept `AppLocalizations` (or `LocalizationService`) and use localized strings.
8. At least one other core service (e.g., `study_progress_tracker.dart`) has its hardcoded strings migrated to ARB.
9. ARB descriptions for the 39 "Auto-generated" entries are replaced with meaningful descriptions.
10. `l10n.yaml` and `main.dart` documented to clarify that `es` targets neutral Latin American Spanish.

---

## Affected Files

| File | Issue |
|---|---|
| `lib/l10n/app_es.arb` | Sections 1–4, 6 |
| `lib/l10n/app_en.arb` | Section 6 (mirror fix) |
| `lib/core/data/models/badge_model.dart` | Section 5a |
| `lib/core/services/notification_service.dart` | Section 5b |
| `lib/core/services/engagement_scheduler.dart` | Section 5c |
| `lib/core/services/personal_learning_plan_service.dart` | Section 5d |
| `lib/core/services/plan_adapter.dart` | Section 5e |
| `lib/core/services/study_progress_tracker.dart` | Section 5f |
| `lib/core/services/adaptive_practice_engine.dart` | Section 5g |
| `lib/features/sessions/services/session_export_service.dart` | Section 5h |
| `lib/main.dart` | Section 7 (documentation) |
| `lib/l10n/l10n.yaml` | Section 7 (documentation) |
| `lib/core/services/localization_service.dart` | **New file** (architecture recommendation) |
