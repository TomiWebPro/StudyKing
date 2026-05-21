# Dry-Run Issue: Custom Question Creation — PARTIAL Items

**Validated:** 2026-05-20
**Source:** `dry-run-test/scenario_custom_question_creation.md` (deleted — 82% complete)

---

## Summary

3 of 17 applicable items remain **PARTIAL**. Scenario was 82% complete (>80% threshold) so the scenario file was deleted. These issues remain open.

---

## Item 1: FAB / "Create Question" Visibility

**Severity:** Medium
**Code:** `practice_screen.dart:1192-1194`, `dashboard_screen.dart:682-685`, `question_bank_screen.dart:1031-1035`

**What's partial:** The Question Bank is reachable from Dashboard (1 tap) and Practice tab → Extra Modes (2 taps), but no "Create" button exists directly on any main screen. The FAB lives only inside the Question Bank screen. The Subjects tab's more-options menu has no Question Bank link at all.

**What's left to do:**
- Add a "Create Question" FAB or button directly on the Practice tab or Dashboard
- Add a "Question Bank" option to the Subjects tab's more-options menu

---

## Item 9: File-Based Question Import Not Exposed in UI

**Severity:** Low
**Code:** `question_bank_screen.dart:278-333`, `question_import_utils.dart:16-46`

**What's partial:** Text-based batch import (`importFromText`) exists and is accessible via the AppBar menu. `QuestionImportUtils.importFromJson()` and `importFromCsv()` support file-based import with conflict resolution, but the question bank UI only exposes the text-paste dialog — there's no file picker for CSV/JSON files.

**What's left to do:**
- Add a file picker option (CSV/JSON) to the import dialog using `file_picker` package
- Connect the file picker to `QuestionImportUtils.importFromJson()` or `importFromCsv()`

---

## Item 14: Empty topicId Still Skips Mastery Attribution

**Severity:** Low
**Code:** `question_bank_screen.dart:794-811`, `mastery_graph_service.dart:95-121`

**What's partial:** Topic selection is now available in both the create dialog and edit dialog, so users CAN link custom questions to topics. However, if a user does not select a topic (leaves it as "None"), the empty `topicId` still results in zero contribution to any named topic's mastery score.

**What's left to do:**
- Option A: Add a visual warning in the create/edit dialog when no topic is selected, explaining that mastery won't be tracked
- Option B: Auto-assign questions to a default topic or prompt the user to create one
- Option C: Treat empty-topicId attempts as contributing to a parent subject's mastery aggregate
