# Internationalisation Master — Full Codebase Audit

**Target:** Spanish (`es`) as primary target locale; findings apply to all future locales.
**Audit date:** 2026-05-18
**Scope:** All `.dart` source files, `.arb` files, and l10n config.

---

## BLOCKER — App crashes or user cannot proceed

*(None identified. The l10n infrastructure is sound: `AppLocalizations` is wired via `MaterialApp`, `locale_config.dart` resolves variants, and all generated methods compile. No crash-causing gaps found.)*

---

## MAJOR — Feature is broken or misleading for Spanish users

### M1. Hardcoded English strings in subject dependency & topic dialogs

**Files:**
- `lib/features/subjects/presentation/dialogs/topic_dependency_dialog.dart`
- `lib/features/subjects/presentation/dialogs/topic_edit_dialog.dart`
- `lib/features/subjects/presentation/widgets/subject_topics_tab.dart`

**Instances (all will render English regardless of locale):**

| File | Line | String |
|------|------|--------|
| `topic_dependency_dialog.dart` | 59 | `'${widget.topic.title} — Dependencies'` |
| `topic_dependency_dialog.dart` | 67 | `'Prerequisites'` |
| `topic_dependency_dialog.dart` | 73 | `'No other topics available for prerequisites.'` |
| `topic_dependency_dialog.dart` | 80 | `'No description'` |
| `topic_dependency_dialog.dart` | 94 | `'Mastery Threshold: ${...}%'` |
| `topic_dependency_dialog.dart` | 107 | `'Required Topic'` |
| `topic_dependency_dialog.dart` | 108-110 | `'Student must master this topic'` / `'Optional topic — can be skipped'` |
| `topic_dependency_dialog.dart` | 119 | `'Syllabus Weight: ${...}'` |
| `topic_edit_dialog.dart` | 113 | `'Parent Topic'` |
| `topic_edit_dialog.dart` | 117 | `'None (Root Topic)'` |
| `topic_edit_dialog.dart` | 130 | `'Sort Order: $_sortOrder'` |
| `subject_topics_tab.dart` | 85 | `'Topic "${result.title}" created'` |
| `subject_topics_tab.dart` | 91 | `'Failed to create topic: $e'` |
| `subject_topics_tab.dart` | 101 | `'Edit Topic'` |
| `subject_topics_tab.dart` | 115 | `'Topic "${result.title}" updated'` |
| `subject_topics_tab.dart` | 121 | `'Failed to update topic: $e'` |
| `subject_topics_tab.dart` | 146 | `'Dependencies updated'` |
| `subject_topics_tab.dart` | 152 | `'Failed to update dependencies: $e'` |
| `subject_topics_tab.dart` | 188-189 | `'Delete Topic'` / `'Delete "${topic.title}"?\n...'` |
| `subject_topics_tab.dart` | 232 | `'Topic deleted'` |
| `subject_topics_tab.dart` | 238 | `'Failed to delete topic: $e'` |
| `subject_topics_tab.dart` | 372 | `'Edit Topic'` (second site) |
| `subject_topics_tab.dart` | 380 | `'Dependencies'` |
| `subject_topics_tab.dart` | 389 | `'Delete'` |

**Rationale:** The topic dependency dialog is an internal modeling tool primarily used during content authoring, but it appears as a full-screen dialog. Every string above bypasses `AppLocalizations.of(context)!` and will display in English for es users.

**Acceptance criteria:**
- Every hardcoded string above is migrated to an `app_en.arb` / `app_es.arb` key pair and accessed via `l10n.keyName`.
- All `Text(...)`, `SnackBar(content: Text(...))`, `title: Text(...)`, and dialog `content` strings in these three files are localised.

---

### M2. `toStringAsFixed()` used for user-facing numeric display

**Files:**
- `lib/features/subjects/presentation/dialogs/topic_dependency_dialog.dart:119` — `Text('Syllabus Weight: ${_syllabusWeight.toStringAsFixed(1)}')`
- `lib/features/subjects/presentation/dialogs/topic_dependency_dialog.dart:129` — `label: _syllabusWeight.toStringAsFixed(1)`

**Rationale:** `toStringAsFixed()` always produces a period decimal separator (`"1.5"`). Spanish locale requires comma (`"1,5"`). Project convenion in `AGENTS.md` and `lib/core/utils/number_format_utils.dart` mandates using `formatDecimal()` for all user-facing decimals.

**Acceptance criteria:**
- `formatDecimal(value, localeName)` replaces `toStringAsFixed()` in both instances.
- The locale name is obtained from `AppLocalizations.of(context)!.localeName`.
- The Syllabus Weight label is localised via an `.arb` key (see M1).

---

### M3. `question_bank_screen.dart` hardcoded "None" filter item

**File:** `lib/features/questions/presentation/question_bank_screen.dart:315`

```dart
const DropdownMenuItem(value: '', child: Text('None')),
```

**Rationale:** The "None" option in the question bank filter dropdown is always English.

**Acceptance criteria:**
- `Text('None')` replaced with `Text(l10n.none)` (key `"none"` exists in both `.arb` files as `"None"` / `"Ninguno"`).

---

### M4. Translation quality issues in `app_es.arb`

#### M4a. Mismatched/clipped Spanish badge-unlock notification

**File:** `lib/l10n/app_es.arb`

**Key:** `notifBodyBadgeUnlocked`
- English: `You earned the "{badgeName}" badge: {badgeDescription}`
- Spanish: `¡Obtuvo la insignia "{badgeName}": {badgeDescription}`

**Issue:** The `!` is only at the beginning (opening `¡` but no closing `!`). The English has a period. The Spanish should end with matching punctuation.

**Suggested fix:** `¡Obtuvo la insignia "{badgeName}": {badgeDescription}!`

#### M4b. Hardcoded Spanish comma syntax in `allStepsFormat`

**File:** `lib/l10n/app_es.arb`

**Key:** `allStepsFormat`
- English: `All {count} steps identified correctly!`
- Spanish: `¡Los {count} pasos identificados correctamente!`

**Issue:** Missing verb — `"han sido"` — makes it read like a newspaper headline. More natural: `"¡Los {count} pasos se han identificado correctamente!"`

#### M4c. Verbosity mismatches in Spanish vs English

Several Spanish translations are significantly longer than their English counterparts. While not a bug per se, this can cause UI truncation in fixed-width layouts (buttons, chips, tab labels). Key examples:

| Key | EN | ES | Ratio |
|-----|----|----|-------|
| `focusForMinutes(=plural)` | `Focus for {count} minutes` | `Enfóquese por {count} minutos` | ~1.5x |
| `scheduledLessons` | `Scheduled Lessons` | `Lecciones Programadas` | ~1.4x |
| `deleteAccountConfirmation` | `Are you sure...?` | `¿Está seguro de que...?` | ~1.3x |
| `planAdjustmentSuggested` | `You've had {count} days...` | `Ha tenido {count} días...` | ~1.2x |

**Acceptance criteria:**
- Check all UI containers that display these strings (buttons, card titles, snackbars) for `overflow: TextOverflow.ellipsis` or text clipping.
- Add `flexible` / `Expanded` / `FittedBox` / `overflow` handling where needed.

---

### M5. Mixed register (formal vs informal) in Spanish translations

**File:** `lib/l10n/app_es.arb`

The project targets neutral Latin American Spanish with formal `usted` register per `l10n.yaml` line 10:
> `'es' targets neutral Latin American Spanish (formal "usted" register).`

However, several strings use informal `tú`:

| Key | Spanish text | Register |
|-----|-------------|----------|
| `noQuestionsPracticeHint` | `Aún no tienes preguntas...` | informal (`tienes`) |
| `confirmExitPracticeBody` | `Tu progreso ... se guardará, pero saldrás` | informal (`tu`, `saldrás`) |
| `confirmExitFocusBody` | `Tienes una sesión ... Al finalizarla temprano se guardará tu progreso` | informal (`Tienes`, `tu`) |
| `deleteQuestionConfirm` | `¿Estás seguro de que quieres eliminar...` | informal (`Estás`, `quieres`) |
| `deleteQuestionsConfirm` | `¿Estás seguro de que quieres eliminar...` | informal |
| `questionsDeleted` | `...pregunta eliminada` | acceptable (impersonal) |
| `onboardingFocusDesc` | `Mantén el enfoque...` | informal imperative (`Mantén`) |

Contrast with formal-`usted` strings:
- `deleteAccountConfirmation`: `¿Está seguro de que desea eliminar su cuenta?` — formal ✓
- `fillAllFieldsCorrectly`: `Por favor, complete todos los campos correctamente` — formal ✓

**Acceptance criteria:**
- All Spanish translations in `app_es.arb` use consistent formal voice (`usted`, `su`, `complete`, `desea`).
- Fix the 7+ informal strings above to match the project's stated register.

---

## MINOR — Code quality / UX friction / maintainability

### m1. Fallback locale-aware strings with English defaults in `time_utils.dart`

**File:** `lib/core/utils/time_utils.dart`

The functions `formatDate()` and `_durationPart()` have hardcoded English fallback strings:

```dart
// line 62
final unknown = l10n?.unknown ?? 'Unknown';
// line 68
return l10n?.today ?? 'Today';
// line 72
return l10n?.yesterday ?? 'Yesterday';
// line 58
return '$count$fallback';  // fallback like '5d'
```

**Rationale:** These fallbacks are only reached when `l10n` is null, which should never happen in production since `AppLocalizations.of(context)` is called upstream. However, it's a maintenance hazard — if a caller fails to pass `l10n`, English silently appears.

**Acceptance criteria:**
- Either remove the null fallbacks and make `l10n` required (breaking change), or leave with a `// covariant: l10n is always non-null in production` comment.

### m2. Notification strings with duplicate/triplicate keys

**File:** `lib/l10n/app_en.arb`

Duplicate/redundant keys covering the same semantic content:

- `notifBodyRevision` (line 3971) and `notificationTimeToReviewBody` (line 4206) — same body text, different key names
- `notifBodyLessonReminder` (line 4013) and `notificationUpcomingLessonBody` (line 4218) — same concept
- `notifBodyBadgeUnlocked` (line 4042) and `notificationBadgeUnlockedBody` (line 4230)

**Rationale:** Two keys for the same notification body means double translation work, potential drift, and confusion about which to use. One should delegate to the other or be removed.

**Acceptance criteria:**
- Consolidate each pair into a single key; the duplicate becomes an alias or is removed.

### m3. No RTL locale support in infrastructure

**Current state:** The codebase has 20+ `Directionality.of(context)` usages for chevron flipping (left/right arrows), which is good. But `AppLocale` enum (`locale_config.dart`) only has `en` and `es`. No RTL locales (Arabic `ar`, Hebrew `he`, Urdu `ur`, Persian `fa`) are supported.

RTL layout issues that would surface if RTL were added:
- `chat_bubble.dart:27` checks `TextDirection.rtl` — but no RTL locale exists to trigger it
- `canvas_drawing_widget.dart:94` and `practice_mode_card.dart:78` pass `Directionality.of(context)` for text direction in `TextPainter` — correct but untested
- All `MainAxisAlignment.start` / `MainAxisAlignment.end` usages rely on `Directionality` resolving correctly (they do in Flutter)

**Acceptance criteria:**
- Not an actionable fix for this sprint, but document that before adding an RTL locale (`ar`, `he`):
  1. Add the locale to `AppLocale` in `locale_config.dart`
  2. Create `app_ar.arb` (right-to-left marker `"@@locale": "ar"`)
  3. Run `scripts/check_i18n_coverage.sh` to validate 100% key parity
  4. Test all screens with `Directionality` — especially `chat_bubble.dart`, `canvas_drawing_widget.dart`, and all chevron-flipping logic

### m4. `questionTypeDefault` inconsistency

**File:** `lib/l10n/app_en.arb`
- Key: `questionTypeDefault` — value: `"Question"`
- File: `lib/l10n/app_es.arb`
- Key: `questionTypeDefault` — value: `"Pregunta"`

But `lib/features/mentor/services/mentor_service.dart` imports `question_type_localizer.dart` which likely uses a different mechanism for question type display names.

**Acceptance criteria:**
- Audit all usages of question type display names. Ensure they funnel through a single localisation path (either `question_type_localizer.dart` or `.arb` keys, not both).

### m5. `lib/features/questions/presentation/question_bank_screen.dart:315` — `Text('None')`

Already listed in M3. This is a minor quick-fix item but categorised as MAJOR because it appears in a filter dropdown the user interacts with.

---

## Summary of required `.arb` key additions

To fix M1, the following new keys are needed in both `app_en.arb` and `app_es.arb`:

| Key | EN value | ES value |
|-----|----------|----------|
| `dependenciesTitle` | `"{topic} — Dependencies"` | `"{topic} — Dependencias"` |
| `prerequisites` | `Prerequisites` | `Requisitos previos` |
| `noTopicsForPrerequisites` | `No other topics available for prerequisites.` | `No hay otros temas disponibles como requisitos previos.` |
| `noDescription` | `No description` | `Sin descripción` |
| `masteryThreshold` | `Mastery Threshold: {percent}%` | `Umbral de Dominio: {percent}%` |
| `requiredTopic` | `Required Topic` | `Tema Requerido` |
| `requiredTopicOn` | `Student must master this topic` | `El estudiante debe dominar este tema` |
| `requiredTopicOff` | `Optional topic — can be skipped` | `Tema opcional — puede omitirse` |
| `syllabusWeight` | `Syllabus Weight: {weight}` | `Peso del Temario: {weight}` |
| `parentTopic` | `Parent Topic` | `Tema Padre` |
| `rootTopic` | `None (Root Topic)` | `Ninguno (Tema Raíz)` |
| `sortOrderValue` | `Sort Order: {order}` | `Orden: {order}` |
| `topicCreated` | `Topic "{title}" created` | `Tema "{title}" creado` |
| `topicCreateFailed` | `Failed to create topic: {error}` | `Error al crear tema: {error}` |
| `editTopicTitle` | `Edit Topic` | `Editar Tema` |
| `topicUpdated` | `Topic "{title}" updated` | `Tema "{title}" actualizado` |
| `topicUpdateFailed` | `Failed to update topic: {error}` | `Error al actualizar tema: {error}` |
| `dependenciesUpdated` | `Dependencies updated` | `Dependencias actualizadas` |
| `dependenciesUpdateFailed` | `Failed to update dependencies: {error}` | `Error al actualizar dependencias: {error}` |
| `deleteTopicTitle` | `Delete Topic` | `Eliminar Tema` |
| `deleteTopicConfirm` | `Delete "{topic}"? This will remove it from all dependency lists.` | `¿Eliminar "{topic}"? Esto lo eliminará de todas las listas de dependencias.` |
| `topicDeleted` | `Topic deleted` | `Tema eliminado` |
| `topicDeleteFailed` | `Failed to delete topic: {error}` | `Error al eliminar tema: {error}` |

**Total: 24 new key pairs required for M1 fix.**

---

## Actionable Fix Plan

1. **Create 24 new `.arb` key pairs** (EN + ES) in `app_en.arb` and `app_es.arb`.
2. **Replace hardcoded strings** in `topic_dependency_dialog.dart`, `topic_edit_dialog.dart`, `subject_topics_tab.dart`, and `question_bank_screen.dart` with `l10n.keyName` calls.
3. **Fix `toStringAsFixed`** → `formatDecimal` + locale name in `topic_dependency_dialog.dart:119,129`.
4. **Fix Spanish register** — change informal `tú` forms to formal `usted` in `app_es.arb`.
5. **Fix `notifBodyBadgeUnlocked`** punctuation in `app_es.arb`.
6. **Consolidate duplicate notification keys** in `app_en.arb`.
7. **Run `scripts/check_i18n_coverage.sh`** to validate no keys are missed.
8. **Run `scripts/validate_arb_no_duplicates.dart`** to catch any key conflicts.
9. **Run `flutter gen-l10n`** to regenerate `AppLocalizations`.
10. **Verify** `flutter analyze` passes with no new i18n-related warnings.
