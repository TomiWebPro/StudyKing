# Issue: Custom Question Creation — Dry-Run Validation Results

**Scenario**: `dry-run-test/scenario_custom_question_creation.md`
**Validated**: 2026-05-20
**Completion**: ~11% (2 of 18 applicable items)
**Status**: NOT_COMPLETED — issue remains open

---

## What Is Fixed (COMPLETED)

1. **Multi-choice checkbox** (`question_bank_screen.dart:382-392`) — `onChanged` is now properly wired with `setInnerState()`. Tapping the checkbox toggles `selectedCorrectOptions`.
2. **Manual question tagging** (`question_bank_screen.dart:660-663`, `question_model.dart:43-44`) — `Question` model uses `model` field (null = manual, set = AI). Create dialog never sets `model`, so manual questions correctly display "manual" chip.

## What Is Partially Fixed

1. **FAB / "Create" button visibility** — Question Bank is now accessible from:
   - **Dashboard** (1 tap): Question Bank card `dashboard_screen.dart:684-686`
   - **Practice** (2 taps): Extra Modes → Question Bank `practice_screen.dart:1151-1156`
   - **Settings** (2 taps): Content Management → Question Bank
   
   **Still missing**: No direct "Create" / "+" button on the Practice tab, Subjects tab, or Dashboard itself. The FAB is only on the Question Bank screen.

---

## What Remains NOT_COMPLETED (15 items)

### P0 — Blockers (user cannot achieve core goal)

| # | Issue | Location | Fix Description |
|---|---|---|---|
| 8 | **No question export** — Questions cannot be exported as CSV/JSON individually. Only full database backup is available. | Missing feature | Add `exportQuestions()` to `QuestionRepository` or create `QuestionExportService`. Add share/export button in question bank AppBar. |
| 9 | **No selective question import** — `DataBackupService` only does full DB restore. Cannot import questions from another user without overwriting entire database. | `data_backup_service.dart` | Add selective import flow for questions, or create a JSON/CSV-based import for questions with ID conflict resolution. |
| 16 | **Cannot create questions during practice** — `PracticeSessionScreen` has no "Create Question" button or gesture. User must exit session, navigate to question bank, create, and restart. | `practice_session_screen.dart` | Add a `FloatingActionButton` or popup menu option to create a question mid-session. Consider "Save and resume" flow. |

### P1 — Major (significant usability loss)

| # | Issue | Location | Fix Description |
|---|---|---|---|
| 3 | **No topic selector** in create dialog — `topicId` hardcoded to `''`. Questions cannot be linked to topics at creation time. | `question_bank_screen.dart:464` | Add a `DropdownButtonFormField` topic selector (populated from `_allTopics` filtered by selected subject). |
| 4 | **No source selector** in create dialog — `sourceIds` always empty. Questions cannot be linked to sources at creation time. | `question_bank_screen.dart:461-471` | Add source multi-select (or dropdown) filtered by selected subject. |
| 7 | **Edit dialog too limited** — Only text and explanation editable. Subject, type, options, difficulty, topic, source all immutable after creation. | `question_bank_screen.dart:224-278` | Refactor `_editQuestion` to use the same full form as `_showCreateQuestionDialog` (pre-populated with existing values). |
| 10 | **No "My Flashcards" / "Custom Questions" practice mode** — All questions are mixed together. Users cannot practice only their custom-created questions. | `practice_mode_grid.dart:97-156` | Add a "My Questions" or "Custom Flashcards" mode card to `PracticeModeGrid`. Should query questions where `model == null`. |
| 11 | **No manual/AI filter in question bank** — Filters are subject, type, source, search text only. Cannot filter to see only custom questions. | `question_bank_screen.dart:125-136` | Add a `_filterChip` for `model` (null vs non-null), which acts as a manual/AI toggle filter. |
| 12 | **No custom vs AI breakdown in results** — `PracticeResultsScreen` shows total/topic only. Cannot evaluate whether custom flashcards are effective. | `practice_results_screen.dart:25` | Add a breakdown section: "Manual: X/Y (Z%)" and "AI: X/Y (Z%)". |
| 13 | **No share/export on results screen** — Results screen has only "Practice Again" and "Review Mistakes". Export is on Dashboard only. | `practice_results_screen.dart:44-113` | Add a share button to the AppBar or as a third action button. |
| 14 | **Empty topicId blocks mastery credit** — Custom questions with `topicId: ''` don't contribute to any named topic's mastery. Fixing #3 (topic selector) is prerequisite. | `mastery_graph_service.dart:91-117` | Fix the create dialog to allow topic selection (#3). This is the root cause. |
| 15 | **Options/correct answer not editable** — Same root cause as #7. | `question_bank_screen.dart:224-278` | Same fix as #7. |
| 17 | **No batch import** — Creating 20 flashcards means 20 full dialog workflows. No CSV paste or "Add Multiple" mode. | Missing feature | Add a batch import dialog: paste structured text, parse into multiple questions, save all at once. |
| 19 | **Custom questions invisible in Topic Focus** — Same root cause as #3/#14. No topicId means `_startTopicPractice()` filter misses them. | `practice_screen.dart:316-317` | Fix topic assignment (#3), and questions will naturally appear in Topic Focus. |

### P2 — Minor (quality of life)

| # | Issue | Location | Fix Description |
|---|---|---|---|
| 18 | **No "Save and add another"** — Dialog closes after saving. User must re-tap FAB for each new question. | `question_bank_screen.dart:534-539` | Add a "Save & Add Another" button (or checkbox) that saves and re-opens the create dialog. |

### NOT-APPLICABLE

| # | Issue | Reason |
|---|---|---|
| 6 | `reportCount` not persisted | Field was removed from `Question` model entirely, along with the flag/report UI. No longer relevant. |

---

## Suggested Fix Order

1. **P0**: #8 (export), #16 (create during practice)
2. **P1, root-cause**: #3 (topic selector) — unblocks #14 and #19
3. **P1**: #4 (source selector), #7 (full edit dialog)
4. **P1**: #10 (practice mode), #11 (manual/AI filter), #12 (results breakdown), #13 (share results)
5. **P2**: #18 (save and add another)
6. **P1**: #17 (batch import)
