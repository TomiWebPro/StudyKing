# Dry-Run Usability Validation: Content Library Management

**Scenario:** "I'm a student who has been using StudyKing for over a week. I've uploaded multiple PDFs, URLs, screenshots, and notes across different subjects. Now I want to review, organize, and manage my content library."

**Scenario file:** `dry-run-test/scenario_managing_content_library.md`

**Validated against:** codebase as of 2026-05-17

---

## BLOCKER (app crashes or user cannot proceed)

### B1. No source browsing UI exists anywhere

Uploaded materials are functionally invisible after the upload completes. There is no screen, dialog, sheet, list, or any user interface element anywhere in the app that displays uploaded sources for browsing or interaction.

**Affected files:**
- `lib/features/ingestion/presentation/upload_screen.dart` — Upload-only, no post-upload management
- `lib/features/ingestion/data/repositories/source_repository.dart` — `getAll()` exists but no UI consumer
- `lib/features/dashboard/presentation/dashboard_screen.dart` — No sources section
- `lib/features/subjects/presentation/subject_detail_screen.dart` — 4 tabs (Lessons, Practice, History, Stats), none show sources
- `lib/features/settings/presentation/settings_screen.dart` — 12 sections, none for content management
- `lib/main.dart` — 6 bottom-nav tabs, none for content library

**Rationale:** The `Source` data model stores `title`, `type`, `subjectId`, `topicId`, `processingStatus`, `extractedText`, `summary`, `extractionMeta`, `generatedQuestionIds`, and `chunks`. Every one of these fields is persisted in Hive but has zero UI representation. The only place sources appear is the `SourcePracticeSheet` in the Practice tab, which is a filtering mechanism for practice questions — not a content browser.

**Acceptance criteria:**
- A "My Content" or "Sources" entry point must exist and be reachable from either the bottom navigation, the dashboard, or subject detail screens.
- The content library must display each source with at minimum: title, type icon, subject name, processing status, and upload date.
- The content library must support sorting and filtering (by subject, by type, by status).

---

### B2. Processing failures are invisible; no retry path

If the content pipeline fails (e.g., OCR fails on a screenshot, PDF extraction errors, LLM classification timeout), the source is saved with `ProcessingStatus.failed` but no user-facing notification, error banner, or retry mechanism exists.

**Affected files:**
- `lib/features/ingestion/services/content_pipeline.dart` — Pipeline sets `processingStatus: ProcessingStatus.failed` on error but error is only surfaced as a SnackBar during the upload flow; after the screen transitions, the status is invisible
- `lib/features/ingestion/data/models/source_model.dart` — Field `processingStatus` exists but is never displayed
- `lib/features/ingestion/data/repositories/source_repository.dart` — `getFailed()` query exists but no consumer

**Rationale:** Without a content library UI, `ProcessingStatus` is a dead field. Failed sources accumulate silently, wasting storage and causing users to believe their materials were processed successfully.

**Acceptance criteria:**
- Processing status must be visible in the content library list/detail view.
- Failed sources must have a visible error indicator and a "Retry" / "Reprocess" button.
- A count of failed uploads should be surfaced on the dashboard or settings.

---

### B3. Uploaded sources cannot be deleted

`SourceRepository.delete()` exists (inherited from `Repository.delete()` at `lib/core/data/repository.dart:30`) but no UI calls it. A user who uploads the wrong file, a duplicate, or outdated content has no way to remove it.

**Affected files:**
- `lib/features/ingestion/data/repositories/source_repository.dart` — `delete()` method never called from UI
- `lib/features/ingestion/presentation/upload_screen.dart` — No delete or management features
- All screens — No delete gesture, button, or menu for sources

**Rationale:** This is a data integrity issue. Users cannot curate their content library, and stale/incorrect sources accumulate indefinitely. Compare with Session History, which implements swipe-to-delete with undo.

**Acceptance criteria:**
- Sources must be deletable from the content library via a swipe gesture, contextual menu, or explicit delete button.
- Deletion must show a confirmation dialog.
- Deletion should have an "Undo" SnackBar (consistent with Session History behavior).
- Deleting a source must optionally prompt: "Also delete questions generated from this source?"

---

### B4. No reprocess/retry mechanism for uploaded sources

If a user uploads a source without checking "Generate questions from this content" and later wants questions generated, or if processing failed, there is no way to re-run the pipeline on an existing source. The user must re-upload the entire file.

**Affected files:**
- `lib/features/ingestion/services/content_pipeline.dart` — `processFullPipeline()` operates on raw content, not on existing Source objects (no `reprocessSource(Source)` method)
- `lib/features/ingestion/presentation/upload_screen.dart` — Only handles new uploads
- No screen — No way to select an existing source and re-process it

**Acceptance criteria:**
- A "Reprocess" button must exist in the source detail or context menu.
- Reprocessing must re-run the full pipeline (extract, classify, summarize, generate questions) on the existing source's stored `extractedText`.
- Reprocessing progress should be shown (reuse the existing progress callback pattern).
- The user must be warned: "Reprocessing will replace existing generated questions. Continue?"

---

## MAJOR (feature is broken or misleading)

### M1. Source-to-subject association is invisible

Sources are correctly tagged with `subjectId` in the data model. `SourceRepository.getBySubject(subjectId)` can retrieve them. But the SubjectDetailScreen has 4 tabs and none displays sources.

**Affected files:**
- `lib/features/subjects/presentation/subject_detail_screen.dart:144-155` — TabBar with Lessons, Practice, History, Stats tabs; no Sources tab
- `lib/features/subjects/presentation/subject_detail_screen.dart:196-261` — "More options" bottom sheet offers "Upload Content" but never "View Sources" or "Manage Content"

**Acceptance criteria:**
- Add a "Sources" tab (or integrate into existing tabs) on the SubjectDetailScreen listing all sources for that subject.
- Each source item must show: title, type, processing status, upload date.
- Tapping a source should navigate to a source detail view.

---

### M2. No question bank browsing or curation

Generated questions are linked to sources via `generatedQuestionIds` on the `Source` model and can be queried via `QuestionRepository`. But there is no UI to browse the question bank, review auto-generated questions, edit them, or delete them.

**Affected files:**
- `lib/features/questions/` — Entire feature has zero screens (only widgets: `QuestionCardWidget`, `SingleAnswerWidget`, `CanvasDrawingWidget`, `MathExpressionWidget`)
- `lib/features/questions/presentation/widgets/question_card_widget.dart` — Renders individual questions in practice sessions but has no management mode (edit/delete)
- `lib/features/practice/` — Questions are consumed by practice/exam sessions but never displayed in a browse view

**Rationale:** The pipeline can generate dozens of questions from an uploaded textbook. The user has zero ability to review quality, remove bad questions, edit question text, or even see how many questions exist. This undermines the "AI-generated content should not be blindly trusted" value from the product vision.

**Acceptance criteria:**
- A browseable question bank screen must exist, filterable by subject, topic, source, and type.
- Each question card in browse mode must show: question text, type, difficulty, topic, source, and generated-by indicator.
- The question bank must support bulk operations: select multiple questions → delete.
- Individual questions must support editing (question text, options, correct answer, explanation).
- Question count per source should be displayed on the source detail view.

---

### M3. Extracted text and AI summaries are stored but never shown

The content pipeline produces `extractedText` and `summary` for every source. These are stored on the `Source` model but never rendered in any screen. The user who uploads a web article or pastes notes cannot reread the extracted version through the app.

**Affected files:**
- `lib/features/ingestion/data/models/source_model.dart` — Fields `extractedText` and `summary` present
- `lib/features/ingestion/services/content_pipeline.dart:128-170` — Extraction and summarization stages produce these fields
- No screen — No source detail or viewer screen

**Acceptance criteria:**
- A source detail view must exist and display: source title, type, upload date, processing status, subject, topic classification, extracted text (scrollable), and AI-generated summary.
- The extracted text viewer should support basic text search within the source.

---

### M4. Topic classification is stored but never shown or correctable

Content pipeline stage 2 (`_classifyTopic` at `content_pipeline.dart:148-161`) calls the LLM to classify uploaded content into a topic and stores the resulting `topicId`. But this classification is invisible and uncorrectable.

**Affected files:**
- `lib/features/ingestion/services/content_pipeline.dart:148-161` — Classification result stored as `topicId` on source
- `lib/features/ingestion/data/models/source_model.dart` — `topicId` field present
- No screen — Classification never displayed

**Acceptance criteria:**
- The source detail view must show the assigned topic name.
- The user must be able to change the topic assignment from a dropdown of available topics for the subject.
- If classification fails, the UI must show "Not yet classified" and offer a "Classify Now" button.

---

### M5. Source Practice sheet lists sources but is not a content manager

The only place sources are listed is `SourcePracticeSheet` (`lib/features/practice/presentation/widgets/source_practice_sheet.dart`) which shows source titles and question counts for filtering practice by source. Tapping a source starts a practice session; there is no way to view source details, edit, or delete from here.

**Affected file:**
- `lib/features/practice/presentation/widgets/source_practice_sheet.dart` — Only entry point displaying source titles; no management actions

**Acceptance criteria:**
- Either the Source Practice sheet should gain management actions (long-press menu with View Details, Delete), or a proper content library screen should exist that subsumes this functionality.
- The sheet should display processing status and an error icon for failed sources.

---

## MINOR (UX friction)

### m1. No content-related entry point in Settings

Settings has 12 sections (User Management, Quick Access, Appearance, Accessibility, AI Configuration, Notifications, Study Preferences, Focus Mode, Study Analytics, Token Usage, Backup and Restore, About). None mentions content, sources, or uploads. Users looking for their uploaded files naturally check Settings and find nothing.

**Affected file:**
- `lib/features/settings/presentation/settings_screen.dart:65-244` — All sections enumerated; no Content Management section

**Acceptance criteria:**
- Add a "Content Management" or "My Uploads" section in Settings, or at minimum a "View Uploaded Materials" tile linking to the new content library screen.

---

### m2. Empty states don't suggest uploading content

The SubjectDetailScreen's tabs (Lessons, Practice, History, Stats) show empty states when there's no data. Without a Sources tab, a user who has uploaded materials for the subject gets no confirmation that those materials exist.

**Affected file:**
- `lib/features/subjects/presentation/subject_detail_screen.dart` — Empty states on all 4 tabs; no indicator of uploaded sources

**Acceptance criteria:**
- Add a sources count indicator to the subject card in the subject list (e.g., "3 sources").
- Even without a dedicated Sources tab, show a "View X uploaded materials" dismissible card on the subject detail when sources exist.

---

### m3. Upload success message gives no next-step guidance

After upload completes, the snackbar says "Content uploaded successfully." It does not offer: "View in content library," "Review generated questions," or "Check processing status."

**Affected file:**
- `lib/features/ingestion/presentation/upload_screen.dart` — Success/failure handling around lines 288-299

**Acceptance criteria:**
- Upload success snackbar should include an action button: "View Library" that navigates to the content library or subject detail.
- If questions were generated, also show: "View Questions" action button.

---

## Summary

| Severity | Count |
|---|---|
| BLOCKER | 4 |
| MAJOR | 5 |
| MINOR | 3 |
| **Total** | **12** |
