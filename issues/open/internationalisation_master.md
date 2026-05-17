# Internationalisation Master — Comprehensive i18n Audit

**Created**: 2026-05-18
**Target Locale**: Spanish (`es`) — formal "usted" register, neutral Latin American
**Scope**: Full codebase — `lib/`, `lib/l10n/`, `lib/features/*/presentation/`
**Severity Levels**: BLOCKER / MAJOR / MINOR

---

## BLOCKER — None

No app-crashing or user-progression-blocking internationalisation issues found.

---

## MAJOR

### MAJOR-1: ~40 hardcoded user-facing strings in ingestion feature screens

**Files**:
- `lib/features/ingestion/presentation/source_detail_screen.dart`
- `lib/features/ingestion/presentation/content_library_screen.dart`

**Context**: Both screens use raw English string literals for every UI label, dialog title, tooltip, section header, placeholder, and status text — none go through `AppLocalizations.of(context)!`.

**Affected strings in `source_detail_screen.dart`**:
- `'Source not found'` (lines 75, 237)
- `'Reprocess Source'` (dialog title, line 119)
- `'Reprocessing will replace existing generated questions. Continue?'` (line 120)
- `'Continue'` (button, line 123)
- `'Reprocessing...'` (progress, line 131)
- `'Source Detail'` (error AppBar, line 232)
- `'Reprocess'` (tooltip + popup + button, lines 258, 271, 444)
- `'Delete'` (popup + button; lines 274, 453)
- `'Status'`, `'Subject'`, `'Type'`, `'ID'`, `'Uploaded'` (`_InfoRow` labels, lines 296–302)
- `'Processing failed'` (error banner, line 318)
- `'Topic Classification'`, `'Summary'`, `'Extracted Text (${...} chars)'`, `'Generated Questions (${...})'` (`_SectionHeader` titles, lines 329–409)
- `'Not yet classified'` (line 338)
- `'Classify Now'` (button, line 348)
- `'No summary available'` (placeholder, line 361)
- `'Search in text'` (hint, line 380)
- `'No extracted text available'` (placeholder, line 397)
- `'No questions from this source'` (placeholder, line 414)
- `'${q.type.name}  •  ${q.difficultyText ?? "Difficulty ${q.difficulty}"}'` (question subtitle, line 429)
- `'Select Topic'` (sheet title, line 472)
- `'Delete Source'` (dialog title, line 492)
- `'Are you sure you want to delete this source?'` (dialog content, line 493)
- `'Source deleted'` (snackbar, line 512)

**Affected strings in `content_library_screen.dart`**:
- `_statusLabel()` returns hardcoded English: `'Pending'`, `'Extracting'`, `'Processing'`, `'Generating Questions'`, `'Validating'`, `'Completed'`, `'Failed'` (lines 117–134)
- `'Delete Source'` + `'Are you sure you want to delete this source?'` + `'Also delete questions generated from this source'` (dialog, lines 174–183)
- `'Source deleted'` (snackbar, line 223)
- `'Content Library'` (AppBar, line 248)
- `'Sort order'`, `'Sort by'` (tooltips, lines 252, 257)
- `'Date'`, `'Title'`, `'Status'`, `'Type'` (sort menu items, lines 260–263)
- `'All subjects'`, `'All types'`, `'All statuses'` (filter chips + bottom sheets, lines 343–444)
- `'Reprocess'` (tooltip on failed source, line 567)

**Rationale**: These are all user-facing. A Spanish user sees English throughout the entire ingestion workflow. The ARB file already has `allSubjects`, `allTypes`, `allSources`, `date`, `delete` but the code doesn't use them.

**Acceptance Criteria**:
- Every hardcoded string above is replaced with `l10n.<key>(...)`
- New ARB keys added for: `sourceDetail`, `sourceNotFound`, `reprocessSource`, `reprocessingConfirm`, `continue`, `reprocessing`, `processingFailed`, `topicClassification`, `notYetClassified`, `classifyNow`, `summary`, `noSummaryAvailable`, `extractedText({charCount})`, `searchInText`, `noExtractedText`, `generatedQuestions({count})`, `noQuestionsFromSource`, `deleteSourceTitle`, `deleteSourceConfirm`, `sourceDeleted`, `processingStatusPending`, `processingStatusExtracting`, `processingStatusProcessing`, `processingStatusGeneratingQuestions`, `processingStatusValidating`, `processingStatusCompleted`, `processingStatusFailed`, `contentLibrary`, `sortOrder`, `sortBy`, `sortDate`, `sortTitle`, `sortStatus`, `sortType`, `allStatuses`
- Spanish translations provided for all new keys

---

### MAJOR-2: Hardcoded English strings in question bank screen

**File**: `lib/features/questions/presentation/question_bank_screen.dart`

**Affected strings**:
- `'Edit Question'` (dialog title, line 196)
- `'Question text'`, `'Explanation'` (input labels, lines 203, 209)
- `'Question Bank'` (AppBar title, line 251)
- `'Cancel selection'`, `'Delete selected'`, `'Select multiple'` (tooltips, lines 256–267)
- `'Difficulty ${q.difficulty}'` (chip, line 352) — ARB already has `difficultyLabel(level)` at line 1507
- `'${q.sourceIds.length} source(s)'` (chip, line 356)
- `'AI-generated'`, `'Manual'` (chips, line 358)
- `'Edit'` (popup menu, line 373)
- `'Search questions'` (hint, line 413) — ARB already has `searchQuestions` at line 5410
- `'All subjects'`, `'All types'`, `'All sources'` (filters + sheets, lines 426–523) — ARB already has `allSubjects`, `allTypes`, `allSources`

**Acceptance Criteria**:
- Replace all with `l10n.*()` calls
- Use `l10n.difficultyLabel(...)` instead of `'Difficulty ...'`
- Add ARB keys: `editQuestionTitle`, `questionTextLabel`, `explanationLabel`, `searchQuestionsHint`, `aiGenerated`, `manual`, `sourceCountChip({count})`
- Spanish translations for all new keys

---

### MAJOR-3: Dashboard screen has hardcoded strings

**File**: `lib/features/dashboard/presentation/dashboard_screen.dart`

**Affected strings**:
- `'Remaining Workload'` (card title, line 164) — no ARB key exists
- `'Content Library'` (card title, line 256) — no ARB key exists
- `'Loading...'` (line 260)
- `'$count source(s)'` (line 261)

**Acceptance Criteria**:
- Add ARB keys: `remainingWorkload`, `contentLibrary`, `loading`, `sourceCountCard({count})`
- Replace with `l10n.*()` calls

---

### MAJOR-4: Mentor screen schedule dialog hardcoded English

**File**: `lib/features/mentor/presentation/mentor_screen.dart`

**Affected strings**:
- `'Topic: ${proposal.topicTitle}'` (line 306, schedule confirmation dialog)
- `'${l10n.duration}: ${proposal.durationMinutes} min'` (line 308, uses `min` directly rather than a formatted duration string)

**Acceptance Criteria**:
- Add ARB key: `mentorScheduleTopic({topicTitle})`
- Use `l10n.*` for label construction
- Replace `' min'` hardcode with locale-aware duration formatting via `formatDuration` from `time_utils.dart`

---

### MAJOR-5: Source practice sheet popup-menu items hardcoded

**File**: `lib/features/practice/presentation/widgets/source_practice_sheet.dart`

**Affected strings**:
- `'Practice'` (line 146)
- `'View Details'` (line 149)

**Acceptance Criteria**:
- Add ARB keys: `practiceAction`, `viewDetailsAction`
- Replace with `l10n.*()` calls

---

### MAJOR-6: Subject detail screen hardcoded strings

**File**: `lib/features/subjects/presentation/subject_detail_screen.dart`

**Affected strings**:
- `'Sources'` (tab label, line 168) — ARB has no `sourcesTab` key
- `'View Sources'` (semantics label, line 249)
- `'$_sourceCount Source(s)'` (list tile, line 252)
- `'No sources for this subject'` (empty state, line 457)
- `'${_items.length} Source(s)'` (subtitle, line 475)
- `item.status.name` (line 505) — uses English enum `.name` directly

**Acceptance Criteria**:
- Add ARB keys: `sourcesTab`, `viewSources`, `sourceCountTile({count})`, `noSourcesForSubject`, `sourceCountSubtitle({count})`
- Use `ProcessingStatus` labels from ARB (see MAJOR-1) instead of `.name`

---

### MAJOR-7: Processing status labels lack ARB keys entirely

**Files**: `content_library_screen.dart`, `source_detail_screen.dart`, `subject_detail_screen.dart`, `source_practice_sheet.dart`

**Context**: Four files display processing status (Pending, Extracting, Processing, Generating Questions, Validating, Completed, Failed) using either:
- `_statusLabel()` with hardcoded English strings
- `source.status.name` (enum `.name` output is always English)

**Acceptance Criteria**:
- Add 7 ARB keys: `processingPending`, `processingExtracting`, `processingProcessing`, `processingGenerating`, `processingValidating`, `processingCompleted`, `processingFailed`
- Create a shared helper (or use a map from the ARB) to convert `ProcessingStatus` values to localized strings
- Spanish translations provided

---

### MAJOR-8: Hardcoded plural constructions `${count} source(s)` repeated across the codebase

**Files**: `dashboard_screen.dart` (line 261), `subject_detail_screen.dart` (lines 252, 475), `question_bank_screen.dart` (line 356)

**Context**: These use string interpolation with English plural convention `source(s)` instead of a plural-aware ARB key. In Spanish the word order and plural form differ (`fuente` → `fuentes`), and the parenthetical `(s)` convention doesn't exist.

**Acceptance Criteria**:
- Create plural ARB keys: `sourceCountCard({count, plural, =1{1 source} other{{count} sources}})` and similar
- Replace all `${count} source(s)` patterns with `l10n.sourceCountCard(count)` calls

---

### MAJOR-9: LLM `_buildContextPrompt()` context labels are invariant English

**File**: `lib/features/mentor/services/mentor_service.dart`

**Context**: The `_buildContextPrompt()` method (lines 157–258) builds context for the LLM with labels like `'Current student context:'`, `'Total attempts: '`, etc. The code comment says "labels are a data-formatting convention, not user-facing text". However, a significant portion of this context is sent to the LLM which then generates the nudge / mentor messages that are displayed to users. If the LLM picks up English patterns from the context, the mentor may respond in English despite the locale being `es`.

**Affected lines**: 175–255 (all `buffer.writeln()` calls with English text)

**Acceptance Criteria**:
- Audit which context labels bleed into LLM-generated output
- Where labels affect LLM output style, localise them using `lookupAppLocalizations(Locale(_localeName)).<key>()`
- Add ARB keys for LLM context labels if needed

---

### MAJOR-10: `formatCompactNumber` fallback is not locale-aware for values < 1000

**File**: `lib/core/utils/number_format_utils.dart` (line 36)

```dart
String formatCompactNumber(int value, String localeName) {
  // ...
  return value.toString();  // <-- no thousand separators for values < 1000
}
```

**Rationale**: For values under 1000, `toString()` produces `"999"` or `"500"`. While single-language OK, in some locales values like `9999` would be formatted by `compact` but `999` would not. This is minor because numbers < 1000 rarely need separators.

**Acceptance Criteria**: Add a locale-aware `NumberFormat` for the fallback path, or confirm via test that `NumberFormat.decimalPattern(localeName)` handles the fallback correctly for all locales.

---

## MINOR

### MINOR-1: `time_utils.dart` has English fallback strings

**File**: `lib/core/utils/time_utils.dart` (lines 62, 68, 72)

```dart
final unknown = l10n?.unknown ?? 'Unknown';
// ...
return l10n?.today ?? 'Today';
return l10n?.yesterday ?? 'Yesterday';
```

**Rationale**: These fallbacks are only used when `AppLocalizations` is null (shouldn't happen in normal usage). Low risk but a potential English leak in edge cases.

**Acceptance Criteria**: Either ensure `l10n` is never null in these paths, or keep the fallbacks but add a test that verifies context-bearing overloads (`formatDateFromContext`) never hit these branches.

---

### MINOR-2: RTL layout readiness — minimal Directionality usage

**Files** (only 4): `chat_bubble.dart`, `lesson_block_card.dart`, `lesson_list_item.dart`, `lesson_booking_sheet.dart`

**Context**: Only 4 files use `Directionality.of(context)`. Many layout widgets use hardcoded `start`/`end` correctly via `EdgeInsetsDirectional`, `AlignmentDirectional`, etc., but:
- `content_library_screen.dart` line 493: `DismissDirection.endToStart` — correct, already uses directional enum
- No RTL language currently supported (no Arabic/Hebrew in `l10n.yaml`)
- The `l10n.yaml` lists locales: `en, es` — no RTL locale yet

**Acceptance Criteria**: Document RTL readiness status. When adding an RTL language (Arabic, Hebrew), audit all files for `EdgeInsets.only(left/right)` vs `EdgeInsetsDirectional.only(start/end)`, `Alignment.topLeft` vs `AlignmentDirectional.topStart`, and `TextAlign.left` vs `TextAlign.start`.

---

### MINOR-3: `source_practice_sheet.dart` uses `const Text()` for menu items

**File**: `lib/features/practice/presentation/widgets/source_practice_sheet.dart` (lines 144–150)

```dart
const PopupMenuItem(
  value: 'select',
  child: Text('Practice'),
),
const PopupMenuItem(
  value: 'view_details',
  child: Text('View Details'),
),
```

**Rationale**: `const` prevents runtime locale switching — these strings will never update when locale changes.

**Acceptance Criteria**: Remove `const` from these `PopupMenuItem` widgets, pass `l10n.*` text.

---

### MINOR-4: No `locale_config.dart` tested for locale persistence edge cases

**File**: `lib/core/config/locale_config.dart`

**Context**: Locale config persistence handles basic save/load. No test validates fallback when saved locale key no longer exists in supported list, or when device locale is unsupported.

**Acceptance Criteria**: Add test for `resolveLocale()` with unsupported device locale — verify it falls back to `en`.

---

### MINOR-5: ARB `@@locale` comments vs `localeName` consistency

**Context**: `app_es.arb` has `"@@locale": "es"`. The generated code uses `localeName` getter from `AppLocalizations`. Some Dart files reference `l10n.localeName` for `NumberFormat` and `DateFormat`. This works correctly but should be documented for translators.

**Acceptance Criteria**: No code change needed. Add documentation in `docs/i18n.md` that `localeName` must match `@@locale` in the `.arb` file for generated locale-aware formatting to work correctly.

---

## Summary of Required ARB Key Additions

| Group | Keys needed | Priority |
|---|---|---|
| Ingestion feature | ~30 keys (sourceDetail, reprocess*, processing*, deleteSource*, section headers, status labels) | HIGH |
| Question Bank | 6 keys (editQuestionTitle, questionTextLabel, explanationLabel, aiGenerated, manual, sourceCountChip) | HIGH |
| Dashboard | 4 keys (remainingWorkload, contentLibrary, loading, sourceCountCard) | HIGH |
| Mentor | 1 key (mentorScheduleTopic) | HIGH |
| Practice sheet | 2 keys (practiceAction, viewDetailsAction) | HIGH |
| Subject detail | 4 keys (sourcesTab, viewSources, sourceCountTile, noSourcesForSubject) | HIGH |
| Status labels | 7 keys (processingPending through processingFailed) | HIGH |
| Sort/filter | 4 keys (sortOrder*, sortBy*, sortDate, sortTitle, sortStatus, sortType) + allStatuses | MEDIUM |

**Total new ARB keys estimated**: ~55–60

## Existing ARB Keys Not Used in Source Code

The following keys exist in both `app_en.arb` and `app_es.arb` but are hardcoded in presentation files:

| ARB Key | Hardcoded in File | Line(s) |
|---|---|---|
| `allSubjects` | `question_bank_screen.dart`, `content_library_screen.dart` | 426, 343 |
| `allTypes` | `question_bank_screen.dart`, `content_library_screen.dart` | 433, 350 |
| `allSources` | `question_bank_screen.dart` | 440 |
| `searchQuestions` | `question_bank_screen.dart` | 413 |
| `questionBank` | `question_bank_screen.dart` | 251 |
| `editQuestion` | `question_bank_screen.dart` | 196 (different capitalisation — ARB is `Edit Question`, code uses `Edit Question`) |
| `questionText` | `question_bank_screen.dart` | 203 (code uses `'Question text'`, ARB has `questionText`: `Question text`) |
| `cancelSelection` | `question_bank_screen.dart` | 256 |
| `deleteSelected` | `question_bank_screen.dart` | 261 |
| `selectMultiple` | `question_bank_screen.dart` | 267 |
| `difficultyLabel` | `question_bank_screen.dart` | 352 (code uses `'Difficulty ${q.difficulty}'` instead of `l10n.difficultyLabel(...)`) |
| `date` | `content_library_screen.dart` | 260 (uses `'Date'` instead of `l10n.date`) |
| `practiceBySource` | `source_practice_sheet.dart` | Already used at line 59 |
| `practiceBySourceDescription` | `source_practice_sheet.dart` | Already used at line 64 |

**Recommendation**: Audit and replace these usages. Low-hanging fruit — ARB keys exist, just not wired up.
