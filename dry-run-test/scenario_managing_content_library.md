# Dry-Run Scenario: Managing My Content Library — Uploaded Materials Are Invisible

## Persona

I'm a student who has been using StudyKing for over a week. I've uploaded several study materials: an IB Chemistry textbook PDF, a YouTube video link about atomic structure, a syllabus screenshot, and some typed notes about organic chemistry. I also uploaded a PDF for IB Physics. Now I want to review, organize, and manage my content library. Some uploads may have failed processing, and I want to find out.

---

## Step 1: Finding My Uploaded Materials — The Invisible Library

I open the app and tap the Dashboard. I see my study stats, weekly chart, mastery overview. But I don't see anything about my uploaded materials. Let me look at each tab.

**What I expect:** A "My Content" or "Library" section somewhere — ideally in the Subjects tab under each subject, or a dedicated tab, or the Dashboard. After all, I uploaded several files — they should be findable.

**What actually happens:** There is **no content library anywhere in the app**.

Let me trace every possible path:
- **Dashboard** — Shows planner card, summary, activity chart, adherence, mastery, weak areas, badges, export. **No content section.**
- **Subjects tab** — Shows my two subjects (IB Chemistry, IB Physics). I tap IB Chemistry. The subject detail screen has 4 tabs: Lessons, Practice, History, Stats. **None show my uploaded files.** The "more options" menu offers Upload Content (to upload *more*), Dashboard, and Delete Subject — **no "View Sources" or "Content Library" option.**
- **Practice tab** — Has "Source Practice" mode. I tap it. A bottom sheet lists sources with question counts. This is **the only place** my uploaded sources are listed — but within a practice mode filter, not as a content manager.
- **Settings tab** — Has Backup & Restore (which includes sources in the export), but no "View Uploaded Materials" option.
- **Mentor tab** — Chat interface. I could ask the mentor, but there's no "show me my uploads" intent handler.

**Verdict (BLOCKER FAIL):** Uploaded materials are functionally invisible after upload. The `SourceRepository` stores all sources with processing status, extracted text, and summaries, but there is zero UI to browse, search, or interact with the content library. The only place sources are listed is the "Source Practice" filter sheet in the Practice tab — which is practice-oriented, not a content management view.

---

## Step 2: Did My Uploads Process Successfully?

I uploaded a screenshot of my IB Chemistry syllabus. The upload screen showed a progress indicator briefly and then said "Content uploaded successfully." But did it actually process the OCR correctly? I want to check.

**What I expect:** I can tap on the source in a content library to see: processing status, extracted text, OCR confidence, auto-generated summary, topics it was classified under, and questions generated from it. I can verify the system understood my syllabus.

**What actually happens:** The `Source` model at `source_model.dart` stores:
- `processingStatus` (ProcessingStatus enum: pending/extracting/classifying/generatingQuestions/validating/completed/failed)
- `extractedText` (full extracted text)
- `summary` (AI-generated summary)
- `extractionMeta` (OCR confidence, page count, duration)
- `generatedQuestionIds` (linked questions)

All of this data is persisted in Hive. **None of it is displayed in any UI.** There is no source detail screen, no source viewer, no processing status indicator that persists after the upload completes.

**Even worse:** If my screenshot processing failed (e.g., OCR couldn't read it), the `processingStatus` would be `failed`. But I would never know — the upload screen doesn't redirect me to any persistent status view. The source is silently stored with `failed` status, and I have no way to see that or retry.

**Verdict (BLOCKER FAIL):** Processing status, extracted content, and all source metadata exist in the data layer but are completely invisible to the user. Failed uploads are silently stored with no user notification or retry path.

---

## Step 3: Deleting a Mistaken Upload

I accidentally uploaded the wrong PDF — an old version of the syllabus. I want to delete it.

**What I expect:** Long-press on the source in my content library → "Delete" → confirmation dialog → gone.

**What actually happens:** `SourceRepository.delete()` exists at `source_repository.dart` (inherited from base `Repository` at `repository.dart:30`). But **no UI calls it**. There is no delete button, menu option, or swipe gesture on any screen to delete a source.

The only delete functionality for *any* content type is in Session History (swipe-to-delete on session items). There is no equivalent for uploaded sources.

**What I must do:** The only way to "remove" a mistaken upload is:
1. Wait until the Export/Import backup feature is used — but that includes all sources, so the bad file is still there.
2. There is literally no user-facing way to delete an uploaded source.

**Verdict (BLOCKER FAIL):** Uploaded materials cannot be deleted. The data-layer delete method exists but has no UI connection.

---

## Step 4: Did the Pipeline Generate Questions From My Upload?

When I uploaded my IB Chemistry textbook PDF, I checked the "Generate questions from this content" checkbox. The pipeline ran. I want to see what questions were generated.

**What I expect:** After upload, I can navigate to a question bank view for the source or subject. I see the questions that were auto-generated, their type, difficulty, and topic. I can review, edit, or delete individual questions.

**What actually happens:** The `Source` model has `generatedQuestionIds: List<String>` linking to generated questions. The `QuestionRepository` can query by subject or topic. But there is:

1. **No question bank browse UI** — The `questions` feature has zero screens. Questions are only displayed one-at-a-time in practice/exam sessions.
2. **No way to see "these questions came from upload X"** — The source-to-question link exists in the data model but is never surfaced.
3. **No way to manually edit generated questions** — `Question.copyWith()` and `QuestionRepository.save()` exist, but no edit UI.
4. **No way to delete generated questions** — `Repository.delete()` exists but no UI calls it.

**Verdict (MAJOR FAIL):** Generated questions are linked to sources in the data layer but invisible to the user. There is no question bank overview, no way to review or curate auto-generated questions, and no way to see that "upload X produced Y questions."

---

## Step 5: Organizing Sources by Subject

I uploaded three chemistry materials and one physics material. I want to confirm they're organized correctly.

**What I expect:** In the IB Chemistry subject detail, I see a list of my 3 chemistry sources. In IB Physics, I see my 1 physics source.

**What actually happens:** The `Source` model has a `subjectId` field. `SourceRepository.getBySubject(subjectId)` is implemented. But the **SubjectDetailScreen** has zero mention of sources in any of its 4 tabs or options. The "more options" menu lets me *upload* more content but never shows what's already there.

**Verdict (MAJOR FAIL):** Sources are correctly tagged with subject IDs in the data model, but the subject detail screen never displays them. Users cannot see which materials belong to which subject.

---

## Step 6: Viewing Extracted Text for Study Reference

I uploaded an article URL about periodic trends. The document extractor scraped it and extracted clean text. I want to read the extracted text for study reference without re-browsing to the URL.

**What I expect:** Tap the source in my content library → see a "View Extracted Text" section → read the AI-cleaned content. Maybe the LLM-generated summary is also visible for quick review.

**What actually happens:** The `Source` model stores both `extractedText` (full text, potentially thousands of words) and `summary` (LLM-generated summary). But no screen renders them. The data exists but is inaccessible.

**Verdict (MAJOR FAIL):** Extracted text and summaries are stored but never shown to the user. The upload pipeline does valuable content extraction work that is immediately discarded from the user's perspective.

---

## Step 7: I Want to See What the AI "Knows" About My Syllabus

The ingestion pipeline has a stage (`processFullPipeline` stage 2) that classifies uploaded content into a topic. I uploaded my IB Chemistry syllabus PDF and want to see what the AI classified the syllabus into.

**What I expect:** In the source details, I see which topic the AI assigned to my syllabus. If it was misclassified, I can correct it.

**What actually happens:** The `Source` model has `topicId` field. The `content_pipeline.dart` stage 2 (`_classifyTopic`) calls LLM to classify the content into a topic title, then looks up the matching `Topic` by title. But:
- The classified `topicId` is saved to the source
- There is no UI that displays this
- There is no way to see or correct the classification
- If classification fails, the source has no `topicId` and no notification is shown

**Verdict (MAJOR FAIL):** Topic classification results exist in data but are never shown to the user. No correction mechanism exists for misclassifications.

---

## Step 8: Trying to Find Upload Via Settings

I go to Settings → scroll through all sections. I see:
- User Management, Quick Access, Appearance, Accessibility, AI Configuration, Notifications, Study Preferences, Focus Mode, Study Analytics, Token Usage, Backup and Restore, About.

**No "Content Management" or "My Uploads" or "Sources".**

The Backup and Restore section does include sources in the export/import, but that's a full-database operation, not a content manager.

**Verdict (BLOCKER FAIL):** Settings has no section for managing uploaded materials.

---

## Step 9: The One Place Sources ARE Listed — Source Practice Sheet

I go to Practice tab → Source Practice. A bottom sheet appears listing all my sources with their titles and question counts. This is the **only** place in the entire app that lists sources.

**What this is useful for:** I can select a source and practice questions from it — assuming the questions were generated (which requires the checkbox and subject ID to be properly configured during upload).

**What this is NOT:** A content manager. I cannot:
- Tap a source to see its details
- Delete a source
- See its processing status
- See its extracted text
- Re-process it
- See which subject it belongs to

**Verdict (PARTIAL):** Sources are listed in the Practice → Source Practice sheet, but only as a filtering mechanism. No management actions are available.

---

## Summary of Expectations vs Reality

| Expectation | Reality | Status |
|---|---|---|
| After upload, I can browse my content library | No source browsing UI exists anywhere | **BLOCKER FAIL** |
| I can see processing status of each source (success/failed/pending) | ProcessingStatus stored in Hive but never displayed | **BLOCKER FAIL** |
| I can delete a mistaken upload | `SourceRepository.delete()` exists but no UI calls it | **BLOCKER FAIL** |
| I can see questions generated from my upload | No question bank browse UI; source-to-question links invisible | **MAJOR FAIL** |
| Subject detail shows materials for that subject | SubjectDetailScreen has no source display in any tab | **MAJOR FAIL** |
| I can view extracted text from scraped articles/PDFs | `extractedText` stored but never rendered | **MAJOR FAIL** |
| I can read the AI-generated summary of my upload | `summary` stored but never displayed | **MAJOR FAIL** |
| I can see the topic classification assigned to my upload | `topicId` stored but never shown; no correction mechanism | **MAJOR FAIL** |
| Settings has a Content Management section | No such section; Backup/Restore is the only data-related entry | **BLOCKER FAIL** |
| Failed uploads show an error I can act on | Silent failure; no user-facing error or retry path | **BLOCKER FAIL** |
| I can re-process a failed upload | No reprocess button or UI anywhere | **BLOCKER FAIL** |
| Sources are visible somewhere (even just for filtering) | Practice → Source Practice lists them — read-only, practice-focused only | PARTIAL |
