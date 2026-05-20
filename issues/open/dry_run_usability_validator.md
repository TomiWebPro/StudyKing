# Dry-Run Issue: Uploading Study Materials & First AI Processing — The Content Pipeline Journey

**Source scenario:** `dry-run-test/scenario_content_upload_pipeline.md`
**Audit date:** 2026-05-19
**Status:** 1 PASS, 2 BLOCKER, 9 MAJOR, 3 MINOR — below 80% threshold

---

## BLOCKER — User Cannot Proceed

### Issue 1: Save-Only Upload Path Is Dead Code — Users Without API Key Cannot Upload Anything

**File:** `lib/features/ingestion/presentation/upload_screen.dart:184, 214, 612-613`

**Root cause:** The "Upload & Analyze" button at line 612-613 always calls `_submitContent(fullPipeline: true)`. At line 214, the check `if (fullPipeline || _generateQuestions || _generateLessons)` is always true because `fullPipeline` is hardcoded to `true`. This means the `else` branch at line 272 calling `pipeline.processUpload()` (the save-only path) is **dead code — completely unreachable**.

When the user has no API key configured, the model check at lines 218-224 errors out: `if ((_generateQuestions || _generateLessons) && resolvedModelId.isEmpty)`. Since the pipeline path is always entered, this error always fires when there's no model.

**Impact:** A user who just installed the app, has no API key yet, but wants to upload content just to save it for later processing, is completely blocked. They must cancel the upload, configure the API key, and come back. There is no way to save a source record without AI processing.

**Acceptance criteria:**
1. Add a "Save Only" button or mode that calls `processUpload()` directly without the AI pipeline.
2. When `fullPipeline: true` is passed but model is empty, either: fall through to `processUpload()` instead of erroring, or offer the user a choice: "Configure API key now / Save without AI processing."
3. The `else` branch in `_submitContent()` should be reachable through a user-accessible UI path.

---

### Issue 2: Pipeline Error Details Lost on Navigation — Source Model Has No Error Field

**Files:**
- `lib/core/data/models/source_model.dart:60-79` — no `errorMessage` field
- `lib/features/ingestion/services/content_pipeline.dart:238-250` — error not persisted on Source
- `lib/features/ingestion/presentation/source_detail_screen.dart:327-349` — generic error banner

**Root cause:** When the pipeline fails at any stage, `content_pipeline.dart:238-250` catches the error and saves the Source with `processingStatus: ProcessingStatus.failed.name`. But the `Source` model has no `errorMessage` field — the specific error (e.g., "Timeout", "Invalid API key", "PDF parse failure") is only returned in the `Result.failure` and displayed temporarily on the upload screen.

If the user navigates away from the upload screen and returns via Content Library → Source Detail, the error banner at `source_detail_screen.dart:327-349` can only show a generic "Processing failed" message with no details about what went wrong.

**Impact:** The specific failure reason is permanently lost once the user leaves the upload screen. Users see a vague "Processing failed" banner with no actionable information. Troubleshooting is impossible without checking application logs.

**Acceptance criteria:**
1. Add `@HiveField(18) String errorMessage = ''` to the `Source` model.
2. In `content_pipeline.dart:242`, persist the error message on the source before saving as failed.
3. In `source_detail_screen.dart:327-349`, display the stored error message.
4. Localize common error types (timeout, rate limit, auth failure, parse error) into user-friendly language.

---

## MAJOR — Feature Broken or UX Misleading

### Issue 3: Pipeline Progress Indication Is Barely Informative

**Files:**
- `lib/features/ingestion/presentation/upload_screen.dart:626-654` — progress card
- `lib/features/ingestion/services/content_pipeline.dart:159-161, 175-176` — duplicate status

**Problems:**
1. **Always indeterminate:** `LinearProgressIndicator()` at line 636 has no `value` — always spinning. No percentage or step-of-total indication.
2. **Duplicate status:** `ProcessingStatus.classifying` is used for BOTH topic classification (line 159) AND summary generation (line 175). The UI description text differs but the enum value doesn't — any code checking status enum cannot distinguish these two phases.
3. **No elapsed time:** No `Stopwatch` or elapsed counter in the upload screen.
4. **No stage counter:** No "Step 2 of 6" label.

**Acceptance criteria:**
1. Calculate overall progress fraction (stage index / total stages) and pass it to `LinearProgressIndicator(value: ...)`.
2. Add elapsed time counter: "Processing... 45 seconds elapsed."
3. Use distinct progress statuses for classification vs. summary, or add a stage counter label.
4. Ensure the progress card shows cumulative meaningful information (e.g., "Extracting text... ✓ Generating summary... ✓ Generating questions... ⟳").

---

### Issue 4: Source Detail Has No "Practice Generated Questions" Button

**File:** `lib/features/ingestion/presentation/source_detail_screen.dart:432-485`

**Problem:** The Source Detail screen shows generated questions as a numbered list at lines 432-464, followed by "Reprocess" and "Delete" buttons at lines 466-485. There is no "Practice All Questions" or "Practice from This Source" button. After uploading content and seeing the AI-generated questions, the user must:
1. Note the subject name
2. Navigate back to Practice tab
3. Find Source Practice mode (under "Extra Modes")
4. Select subject → select source → start practice

This is 4-5 navigational steps for what should be a single tap.

**Acceptance criteria:**
1. Add a "Practice All Questions" `FilledButton` below the questions list on Source Detail.
2. The button should navigate to `PracticeSessionScreen` with the source's `sourceId` as a filter, so only this source's questions are practiced.
3. The button should be disabled when `generatedQuestionIds` is empty, with a hint explaining why.

---

### Issue 5: Reprocessing Orphans Old Questions with No Cleanup

**Files:**
- `lib/features/ingestion/presentation/source_detail_screen.dart:133-201` — `_reprocess()` method
- `lib/features/ingestion/services/content_pipeline.dart:253-283` — `reprocessSource()`

**Problem:** When a source is reprocessed:
1. `reprocessSource()` calls `processFullPipeline()` which generates new question IDs via `IdGenerator.generate('q')`.
2. The source's `generatedQuestionIds` is overwritten with the new IDs.
3. **Old questions are NOT deleted** — they remain in the `QuestionRepository` as orphaned records (no source references them).
4. After multiple reprocesses, orphaned questions accumulate as database bloat.
5. `reprocessSource()` at `content_pipeline.dart:253-283` always generates a NEW source ID — the Source Detail screen works around this by merging, but it's fragile.

**Acceptance criteria:**
1. Before reprocessing, warn the user: "This will regenerate questions. Old questions will be replaced."
2. On successful reprocess, delete old questions referenced by the previous `generatedQuestionIds`.
3. Fix `reprocessSource()` to preserve the existing source ID instead of generating a new one.
4. Consider adding a "Keep old questions" checkbox to the reprocess confirmation dialog.

---

### Issue 6: Pipeline Error Messages Are Raw Dart Exceptions

**Files:**
- `lib/features/ingestion/presentation/upload_screen.dart:265-269` — error display
- `lib/features/ingestion/services/content_pipeline.dart:238-250` — exception propagation

**Problem:** When the pipeline fails, the error shown to the user is `e.toString()` — a raw Dart exception string. Users see messages like:
- "Upload failed: TimeoutException after 0:00:30.000000: Future not completed"
- "Upload failed: HttpException: Connection closed before full response"
- "Upload failed: FormatException: Unexpected character"

These are developer-oriented messages with no localization or user-friendly translation.

**Acceptance criteria:**
1. Map common exception types to user-friendly localized messages:
   - Timeout → "The AI service timed out. Check your internet connection or try a different model."
   - Rate limit (429) → "You've been rate-limited. Please wait a moment and try again."
   - Auth failure (401) → "Your API key is invalid or expired. Update it in Settings."
   - Model not found (404) → "The selected model wasn't found. Try a different model."
   - LLM JSON parse error → "The AI response was malformed. Try reprocessing."
   - PDF parse failure → "Could not read this file. Make sure it's a valid PDF or document."
2. Fall through to the raw error only for unclassified exceptions.
3. Log the original error internally for debugging.

---

### Issue 7: No Model-Capability Check for Image/Audio Content Types

**Files:**
- `lib/features/ingestion/presentation/upload_screen.dart:208-224` — only checks model ID emptiness
- `lib/features/ingestion/services/document_extractor.dart:41-64` — routes all types to LLM

**Problem:** The upload screen checks only `resolvedModelId.isEmpty` before processing. It does not check whether the user's selected model supports:
- **Vision** (for image/camera uploads — OCR needs vision capabilities)
- **Audio transcription** (for audio/video uploads)

If a user uploads a photo with a text-only model (e.g., Llama 3 8B), the `OcrExtractor` sends a vision prompt that the model doesn't understand, producing garbage output or errors. The user has no warning beforehand.

**Acceptance criteria:**
1. Add a model capability registry or at minimum a warning dialog before processing image/audio content: "Your selected model may not support image analysis. Proceed anyway?"
2. If the pipeline produces empty extracted text from an image/audio source, show a helpful error: "No text could be extracted. Your model may not support this content type. Try a different model or upload a text-based file."
3. Consider adding a user-facing model capability viewer in AI Configuration.

---

### Issue 8: No Duplicate Content Detection

**File:** `lib/features/ingestion/services/content_pipeline.dart:58-92, 94-251`

**Problem:** Uploading the same PDF file twice creates two separate source records with different IDs, two sets of generated questions, and no indication to the user that this content already exists. There is no content hashing, title comparison, or any form of deduplication.

**Acceptance criteria:**
1. Compute SHA-256 hash (or similar) of uploaded file content before processing.
2. Check repository for existing sources with the same hash.
3. If match found, show dialog: "This content appears to already exist as '[title]'. Upload anyway?"
4. Same check for text pasting and URL content (hash the extracted text).

---

### Issue 9: Pipeline Has No Cancel Button and No Back-Navigation Guard

**Files:**
- `lib/features/ingestion/presentation/upload_screen.dart:608-654` — no cancel UI
- `lib/features/ingestion/services/content_pipeline.dart:94-251` — no cancellation mechanism

**Problem:** During pipeline processing:
- There is no cancel/abort button on the upload screen.
- There is no `PopScope` preventing back navigation during processing.
- If the user navigates back, the pipeline continues in the background (it's not bound to widget lifecycle).
- The `mounted` checks at the upload screen prevent crashes but the pipeline bleeds — consuming API credits and time invisibly.
- There's no elapsed time counter, so users can't tell if they've been waiting 30 seconds or 5 minutes.

**Acceptance criteria:**
1. Add elapsed time display during processing: "Processing... 1m 23s elapsed."
2. Add a cancel button that cancels in-flight LLM calls.
3. Add `PopScope` to show confirmation dialog before allowing back-navigation during processing: "Upload in progress. Cancel and go back?"
4. For very long operations (>2 minutes), consider showing a notification or estimate.

---

### Issue 10: Generated Questions May Have Empty TopicId Making Them Unfindable

**File:** `lib/features/ingestion/services/content_pipeline.dart:410-475`

**Problem:** At line 454, `_generateQuestions()` creates `Question` objects with `topicId: topicId` where `topicId` comes from the pipeline's parameter. If the source's `topicId` is empty (classification was skipped or failed — no `possibleTopics`, or no match found), all generated questions have `topicId: ''`. These questions are invisible in Topic Focus practice mode and do not contribute to any named topic's mastery score.

**Acceptance criteria:**
1. After the pipeline completes, if `source.topicId` is empty but questions were generated, show a warning on the Source Detail: "These questions aren't linked to any topic. Use the topic classifier or edit the source's topic to enable topic-specific practice."
2. Consider providing a fallback: if questions have no topic, create a generic topic for the source.
3. In the Source Detail screen's topic section, highlight when topic is missing and questions exist.

---

### Issue 11: All Processing Stages Use the Same "classifying" Status

**File:** `lib/features/ingestion/services/content_pipeline.dart:159-161, 175-176`

**Problem:** Two distinct pipeline stages — topic classification (line 159-161) and summary generation (line 175-176) — both use `ProcessingStatus.classifying`. This means:
1. The progress card shows the same status enum twice, making it impossible for UI code to distinguish between "classifying content topic" and "generating summary" by enum alone.
2. If a user glances at the progress indicator, they see "classifying" for what feels like twice as long as expected.
3. Any future code that tracks stage-level progress would need to parse the description text instead of checking the enum.

**Acceptance criteria:**
1. Add a new `ProcessingStatus.summarizing` to the `ProcessingStatus` enum, or
2. Track stage index separately (not just status enum) to provide accurate stage information to the UI.

---

## MINOR — UX Friction

### Issue 12: Content Library Filters Are Single-Select Only

**File:** `lib/features/ingestion/presentation/content_library_screen.dart:139-141`

**Problem:** The status and type filters are single-select (`_statusFilter` and `_typeFilter` are `String`, not `List<String>`). Users cannot view multiple statuses simultaneously (e.g., show both "Completed" AND "Failed" sources). Filter comparison uses fragile enum index comparison at line 140-141: `s.type.index.toString()`.

**Acceptance criteria:**
1. Change filter variables to `List<String>` to support multi-select.
2. Replace enum index comparison with stable string comparison (type name or identifier).

### Issue 13: Source Practice Mode Is Hidden Under "Extra Modes"

**Files:**
- `lib/features/practice/presentation/screens/practice_screen.dart` — mode grid
- `lib/features/ingestion/presentation/source_detail_screen.dart` — no practice button

**Problem:** Source Practice mode is in the "Extra Modes" section at the bottom of the Practice tab's mode grid, below the main 6 cards. Users who just uploaded content and want to practice its questions must scroll down, discover Source Practice, select the subject, then find their source. There is no "Recently Uploaded" shortcut or badge indicating new questions are available.

**Acceptance criteria:**
1. After upload completes, consider showing a "Practice New Questions" option in the success snackbar (alongside "Content Library").
2. Add a badge/banner to the Practice tab when sources were recently processed.
3. Consider promoting Source Practice cards with recently-processed sources above other modes.

### Issue 14: No Post-Upload Guidance for Next Steps

**File:** `lib/features/ingestion/presentation/upload_screen.dart:306-315`

**Problem:** After successful upload, the snackbar says "Content uploaded successfully" with a "Content Library" action. There is no guidance on what to do next: "You can now practice the generated questions in the Practice tab!" or "View your extracted text in the Content Library."

**Acceptance criteria:**
1. Enhance the success snackbar to include a secondary action: "Start Practice" (navigating to practice with this source's questions).
2. Consider showing a brief one-time success dialog after first upload: "Your content has been processed! Tap 'Practice' to start answering questions, or explore the Content Library to see the extracted text and summary."

---

## Summary of Work Items

| Priority | Issue | Effort | Key Files |
|---|---|---|---|
| **BLOCKER** | Save-only path dead code (API key requirement unnecessary) | Small | `upload_screen.dart:184, 214, 612-613` |
| **BLOCKER** | Pipeline error details lost — Source needs errorMessage field | Medium | `source_model.dart`, `content_pipeline.dart`, `source_detail_screen.dart` |
| **MAJOR** | Progress indicator always indeterminate, no stage counter | Small | `upload_screen.dart:626-654`, `content_pipeline.dart` |
| **MAJOR** | No "Practice Generated Questions" button on Source Detail | Small | `source_detail_screen.dart:432-485` |
| **MAJOR** | Reprocessing orphans old questions | Medium | `source_detail_screen.dart`, `content_pipeline.dart:253-283` |
| **MAJOR** | Raw Dart exceptions shown as error messages | Medium | `upload_screen.dart`, `content_pipeline.dart` |
| **MAJOR** | No model-capability check for image/audio content types | Small | `upload_screen.dart`, `document_extractor.dart` |
| **MAJOR** | No duplicate content detection | Medium | `content_pipeline.dart` |
| **MAJOR** | Pipeline has no cancel button or back-navigation guard | Medium | `upload_screen.dart` |
| **MAJOR** | Generated questions may have empty topicId (unfindable) | Small | `content_pipeline.dart:410-475` |
| **MAJOR** | Two stages share same "classifying" progress status | Trivial | `content_pipeline.dart:159-176` |
| **MINOR** | Content Library filters single-select, fragile index comparison | Small | `content_library_screen.dart:139-141` |
| **MINOR** | Source Practice mode hidden under "Extra Modes" | Small | `practice_screen.dart`, `source_detail_screen.dart` |
| **MINOR** | No post-upload next-steps guidance | Small | `upload_screen.dart:306-315` |
