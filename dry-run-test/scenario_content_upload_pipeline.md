# Dry-Run Scenario: Uploading Study Materials & First AI Processing — The Content Pipeline Journey

## Persona

I'm a new student who just installed StudyKing after hearing about it from a friend. I've completed the onboarding, dismissed the API key banner (I'll configure it later), and I'm now staring at the main screen. I have **IB Chemistry** exam coming up and I have a PDF textbook saved on my phone. I need to get my study materials into the app so I can start learning.

I expect the app to:
1. Make it obvious how to upload my first textbook — I shouldn't have to hunt for it
2. Let me upload my PDF and watch the AI process it into organized study material
3. Show me clear progress as the content pipeline runs (extracting text, classifying topics, generating questions)
4. After processing, let me find and practice the generated questions immediately
5. Let me see the details of my uploaded content (extracted text, AI summary, generated questions)
6. Let me reprocess content if results are poor
7. Handle failures gracefully (no silent hangs, clear error messages)
8. Let me manage multiple uploads and find them in a library
9. Tell me if I need to configure an API key before I can upload (since the pipeline needs the LLM)

---

## Step 1: Finding the Upload Feature — Where Do I Tap?

I open the app for the first time after onboarding. I see a bottom navigation bar with 6 tabs: Dashboard, Subjects, Practice, Mentor, Focus Mode, Settings.

**What I expect:** A clear "+" FAB, a "Upload" button on the Dashboard (since it's my home screen), or a prominent card that says "Upload your first study material."

**What I actually see:**

1. **Dashboard** — Shows an `EmptyDashboardChecklist` with 3 steps: "Create a Subject", "Upload Materials", "Start Learning." The checklist is visible and the upload step is a tappable `ListTile`. **This is good** — I can tap "Upload Materials" right from the Dashboard.

2. **But what if I dismiss or complete the checklist?** After I've uploaded once and the checklist is gone, how do I upload again? The Dashboard has `MetricCard`s (study time, adherence, sessions) and a `WeakAreasCard` — but no persistent upload button. The FAB on the Practice tab only navigates to practice modes. If the checklist is gone, **there is no upload button on the Dashboard at all**.

3. **Subjects tab** — I create "IB Chemistry" from here. After creation, a success dialog offers to navigate to the subject detail. The subject detail has a "more options" button that shows an Upload Content option. **Two levels deep** from the main screen to find upload when the checklist is gone.

4. **Settings** — Has an "Upload Material" `ListTile` at the top. Two levels deep.

5. **Practice tab** — Shows mode grid. If I have zero questions, a `PracticeEmptyState` widget shows with "Upload Material" text button. Otherwise, no upload path.

**My experience:** On first launch, the checklist guides me. After that, I have to go through Subjects → Subject Detail → More Options → Upload Content (4 taps) or Settings → Upload Material (2 taps). There's no persistent upload FAB or button on the main screen.

**Verdict (PARTIAL):** Onboarding checklist provides good first-time upload discovery. After dismissal, upload is 2-4 navigation levels deep with no persistent top-level access. Power users who regularly upload new materials must navigate away from their current task.

---

## Step 2: I Haven't Configured My API Key Yet — What Happens?

I tap "Upload Materials" from the checklist. Before the upload screen, I realize I haven't set up my API key. The onboarding had a banner about it, but I dismissed it and forgot.

**What I expect:** The app either prevents me from uploading until I configure an API key, or lets me upload without AI processing (just save the file), with a clear note about what I'm missing.

**What actually happens:**

Upload screen opens. I fill in the title, select my subject, pick my PDF file. Both checkboxes are enabled by default: "Generate questions from content" (ON) and "Generate lesson from content" (OFF). I tap "Upload & Analyze."

The pipeline checks `resolvedModelId.isEmpty` at `upload_screen.dart:218-224`:
```dart
if ((_generateQuestions || _generateLessons) && resolvedModelId.isEmpty) {
  setState(() {
    _error = l10n.modelNotConfigured;
    _isUploading = false;
  });
  return;
}
```

I see an error message in a red container below the form: **"Model not configured"** (or similar). The upload button re-enables. My form data is still there.

**But here's the problem:** The error message only appears if BOTH `_generateQuestions` and `_generateLessons` are enabled. Wait no — let me re-read: `if ((_generateQuestions || _generateLessons) && resolvedModelId.isEmpty)`. This fires if EITHER is enabled AND model is empty. Since `_generateQuestions` defaults to `true`, this guards correctly.

But there's a subtle issue: if the user unchecks BOTH checkboxes (generate questions = OFF, generate lessons = OFF), the code at `upload_screen.dart:214` checks `if (fullPipeline || _generateQuestions || _generateLessons)` — with both off, `fullPipeline` is `true` (always passed), so the pipeline still runs. Wait, no — let me look again:

Line 612-613:
```dart
onPressed: _isUploading ? null : () => _submitContent(fullPipeline: true),
```

The button ALWAYS passes `fullPipeline: true`. Then at line 214:
```dart
if (fullPipeline || _generateQuestions || _generateLessons) {
```

So `fullPipeline` is always `true`, which means the AI pipeline path always runs, which means the model check at line 218 always fires when model is empty, even if both checkboxes are off. **The user cannot upload content without AI processing if they have no model configured.** The save-only path (`processUpload()`) at line 272-291 is unreachable from the UI because the button always passes `fullPipeline: true`.

Wait, let me re-read more carefully. `fullPipeline` is a parameter of `_submitContent`. At line 184: `Future<void> _submitContent({bool fullPipeline = false}) async {`. The default is `false`, but line 613 calls it with `fullPipeline: true`.

Then at line 214: `if (fullPipeline || _generateQuestions || _generateLessons)`. Since `fullPipeline` is always `true`, the condition is always true. This means:
- The model check at line 218 always fires
- The pipeline always runs
- The save-only path at line 272 (the `else` block calling `processUpload()`) is **dead code** — it can never be reached

If I haven't configured my API key, I'm completely stuck. I can't even save the PDF as a source record without AI processing. The only option is to cancel the upload, go configure the API key, and come back.

**Verdict (BLOCKER FAIL):** The `fullPipeline: true` is hardcoded on the upload button, making the save-only `processUpload()` path completely unreachable. Users without an API key configured cannot upload any content — even just to save it for later. They must configure the API key first or the button produces an error.

---

## Step 3: I Configure the API Key — Now the Upload Works (Sometimes)

I go to Settings, find AI Configuration, paste my OpenRouter API key, select a model, and go back to upload. Now the upload works.

I fill in:
- Title: "IB Chemistry Textbook — Chapter 1"
- Subject: "IB Chemistry" (selected from dropdown)
- File: Pick my PDF from storage

I tap "Upload & Analyze." The button shows a loading spinner. A card appears below showing:

```
[========------------------]  (indeterminate progress)
○ Extracting text from content...
```

**What I expect:**
- An **indeterminate** progress bar (which is what I see) — fine for LLM operations
- Stage descriptions that update as each phase completes
- A clear indication of how many stages remain
- Some sense of time — "This may take 1-2 minutes..."

**What actually happens:**

The progress card shows `LinearProgressIndicator` (always indeterminate) and a text description that updates. The descriptions are:

| Stage | Description Text | Duration (typical) |
|---|---|---|
| extraction | "Extracting text from content..." | 1-5s (PDF parsing) |
| classification | "Classifying content topic..." | 5-20s (LLM call) |
| classification | "Generating summary..." | 5-20s (LLM call) |
| question generation | "Generating questions from content..." | 30-120s (LLM call, multiple questions) |
| validation | "Validating generated questions..." | Instant (stub) |
| completion | "Pipeline complete" | Instant |

**Problems I notice:**

1. **The progress bar is always indeterminate.** I have no idea if I'm 10% or 90% done. For a 2-minute pipeline, an indeterminate spinner with zero percentage information is stressful — I don't know if it's hung or just slow.

2. **The "classifying" stage appears TWICE** — once for topic classification and once for summary generation. Both use `ProcessingStatus.classifying`. The descriptions are different ("Classifying content topic..." and "Generating summary...") but a user glancing at it might think the classification is taking twice as long as it should.

3. **No overall progress calculation.** The `LinearProgressIndicator` has no `value` — it's always indeterminate. No "Step 3 of 6" or percentage. The description is the only clue about progress.

4. **On success**, the screen clears the form, shows a green success container briefly, then shows a snackbar with "Content uploaded successfully" and a "Content Library" action button to navigate there.

5. **On failure**, the error container shows "Upload failed: [reason]" and the form stays populated. I can retry.

**Verdict (MAJOR FAIL):** The progress indicator is always indeterminate with no overall progress sense. The "classifying" status is duplicated for two different stages. No stage counter (2/5, 3/6) is shown. Users cannot tell if the pipeline is progressing normally or stuck.

---

## Step 4: Processing Completed — Now Where Do I Find My Content?

The upload finishes. The form clears. I tap "Content Library" on the snackbar action. I'm taken to the Content Library screen.

**What I expect:** A list or grid of my uploaded sources. I see my "IB Chemistry Textbook — Chapter 1" with a green "Completed" status badge. I can tap it to see details.

**What I see:** The Content Library screen has:
- A filter bar with dropdowns for subject, type, and processing status
- A sort button and sort options (date, title, status, type)
- A list of sources, each showing: type icon, title, subject name, status chip, upload date

I see my source with a "Complete" status chip. **Good.**

**But wait — what if I tap a source while it's still processing?** The pipeline runs asynchronously. If I navigate away from the upload screen before the pipeline finishes and check the Content Library, I'll see the source with "Pending" or "Extracting" status. If the pipeline fails, I'll see "Failed" with a red icon. The Content Library handles this well — it updates when I pull-to-refresh.

**But there's a navigation gap:** The filter bar doesn't auto-apply when I change filters. I select "Completed" from the status dropdown... and nothing happens until I close the bottom sheet. This is actually fine — the `_subjectFilter` state changes on selection and triggers rebuild. Let me check that... Looking at the `_buildFilterBar`, it uses `showModalBottomSheet` for each filter. When the sheet pops with a value, `setState` is called to update the filter. The `_filteredSources` getter then re-filters. This works. ✓

**Verdict (PASS):** Content Library correctly shows sources with status, filter, sort, and navigation to source detail.

---

## Step 5: Exploring the Source Detail — What Did the AI Do?

I tap my source in the Content Library. The Source Detail screen opens.

**What I expect:**
- A summary of what the AI found in my textbook
- The extracted text from my PDF (if I want to read it)
- A list of generated questions I can start practicing
- The ability to reprocess if results are poor
- Topic classification showing which topic this belongs to

**What I see (section by section):**

1. **Info row** — Shows status, subject, type, ID (UUID), upload date. ✓

2. **Topic classification** — Shows the current topic or "Not yet classified." If classified, I can edit it via a topic picker. If not, there's a "Classify Now" button. ✓

3. **Summary** — Shows the AI-generated summary of my textbook. Or "No summary available" if it failed. ✓

4. **Extracted text** — Shows the full extracted text from my PDF in a scrollable monospace container with a search field. **Very useful** — I can verify the AI correctly extracted the text. ✓

5. **Generated questions** — Lists the questions generated from this source. Each line is numbered and tappable. Tapping navigates to the Question Bank filtered to that question. ✓

**But here are the problems:**

**Problem 1 — No "Practice Now" button.** I see my generated questions listed, but there's no "Practice All" or "Practice from this Source" button directly on the source detail. I have to:
- Note the subject name
- Navigate back to Practice tab
- Select Source Practice mode
- Find the source in a list
- Start practice

Or:
- Tap each question individually to navigate to Question Bank
- Start a practice session from there (which doesn't have a "practice selected questions" mode)

The `SourceDetailScreen` has `Reprocess` and `Delete` buttons at the bottom. **No "Practice Generated Questions" button.** This is a missing workflow step — the primary action a user wants after uploading (practice the questions!) requires 3-4 navigational steps.

**Problem 2 — Generated questions are listed by index only.** The list at `source_detail_screen.dart:432-464` shows:
```
1. [question text truncated]
2. [question text truncated]
...
```
The text might be too long and get truncated. There's no question type icon, no difficulty indicator, no "this question needs review" marker. Just numbers and text.

**Problem 3 — Questions may be associated with NO topic.** As discovered in the syllabus scenario, `_generateQuestions()` (content_pipeline.dart:410-475) passes `topicId: topicId` to created questions. But `topicId` at this point comes from `source.topicId` which may be empty if classification failed or no `possibleTopics` were provided. In that case, all generated questions have `topicId: ''`, making them invisible in Topic Focus mode.

**Verdict (MAJOR FAIL):** Source detail shows what the AI did but offers no "Practice Generated Questions" button. Users must navigate away and through multiple screens to practice. Generated questions may have empty `topicId` making them unfindable in topic-filtered practice modes.

---

## Step 6: Pipeline Failure — What If Something Goes Wrong?

During processing, the LLM might timeout, the PDF might be corrupted, or the model might be rate-limited.

**What I expect:** A clear error message at each stage with suggested action: "Failed to extract text — the PDF may be corrupted. Try a different file." or "Question generation timed out — your model may be overloaded. Try a different model."

**What actually happens:**

The pipeline catches errors globally (content_pipeline.dart:238-250):
```dart
catch (e) {
  _logger.w('Pipeline failed', e);
  try {
    final failed = source.copyWith(processingStatus: ProcessingStatus.failed.name);
    await _sourceRepository.save(failed.id, failed);
    return Result.failure(e.toString());
  } catch (e2) { ... }
}
```

The error `e.toString()` is returned to the upload screen, which sets `_error` to `l10n.uploadFailed(e.toString())`. The error message shown to the user is the raw Dart exception string — something like:
- "TimeoutException after 0:00:30.000000: Future not completed"
- "HttpException: Connection closed before full response"
- "FormatException: Unexpected character"

**These are NOT user-friendly.** A student with no programming background sees:
- "Upload failed: TimeoutException after 0:00:30.000000: Future not completed"

Instead of:
- "Upload failed: The AI service timed out. Check your internet connection or try a different model."

**Furthermore, only ONE error banner is shown** — at the upload screen. If the pipeline fails mid-way, the source is saved with `ProcessingStatus.failed`. On the Source Detail screen, a "Retry" button in the error banner lets me reprocess. But the error message on the Source Detail screen is... where exactly? Let me check.

The `SourceDetailScreen._reprocess()` method (source_detail_screen.dart:133-201) shows a confirmation dialog when reprocessing, and uses a snackbar for success/failure results. But the `_source` error state is only set from `_load()` failure (loading the source itself), not from pipeline processing failure. If the source loaded fine from Hive but its status is `failed`, the detail screen shows an error banner at lines 327-349:

```dart
// Failed state banner
if (_source!.statusEnum == ProcessingStatus.failed)
  // Shows error icon, "Processing failed" text, Retry button
```

The banner says "Processing failed" generically — it doesn't show the specific error that caused the failure, because the `Source` model has **no error message field**. The pipeline sets the status to `failed` but stores no error details on the source itself. The original error `e.toString()` is only logged and returned to the upload screen caller. If the user navigates away from the upload screen and comes back via Content Library, the specific error is lost.

**Verdict (MAJOR FAIL):** Error messages from pipeline failures are raw Dart exception strings shown to users. The `Source` model has no `errorMessage` field — once the user leaves the upload screen, the specific failure reason is lost. The Source Detail screen shows only a generic "Processing failed" banner.

---

## Step 7: Reprocessing — Can I Get Better Results?

The AI generated 3 questions from my 50-page PDF. That seems too few. I want to reprocess with better parameters.

**What I expect:** A "Reprocess" button that re-runs the pipeline. Maybe I can toggle "Generate more questions" or adjust the prompt. The old questions should either be replaced or I get a warning about duplicates.

**What actually happens:**

Tapping "Reprocess" on the Source Detail screen:
1. A confirmation dialog appears: "This will regenerate questions. Old questions will remain."
2. The pipeline runs again with the same content.
3. New questions are generated (with NEW IDs — `IdGenerator.generate('q')`).
4. `source.generatedQuestionIds` is updated to include ONLY the new IDs.

**But the old questions are NOT deleted.** At `source_detail_screen.dart:177-183`:
```dart
if (result.isSuccess) {
  _source = result.data!;
  // ... setState to reload
}
```

Wait, let me look at `_reprocess()` more carefully. I need to read source_detail_screen.dart from line 130-200. Let me check if it handles old question cleanup.

Actually, looking at the ContentPipeline reprocess flow:
1. `reprocessSource()` (content_pipeline.dart:253-283) calls `processFullPipeline()` which generates NEW question IDs.
2. The returned `Source` object has NEW `generatedQuestionIds`.
3. But the `SourceDetailScreen._reprocess()` method — I need to check what it does with the result.

Based on the earlier analysis: "SourceDetailScreen._reprocess() merges fields from the new source into the existing one (deleting the new source record since processFullPipeline generates a new ID)." But does it handle the old questions?

The old questions remain in Hive as orphans. Each reprocess adds more questions alongside the old ones. After 5 reprocesses, I might have 15 orphaned questions in the database that are no longer linked to any source. This is database bloat.

**Also**, the reprocess doesn't let me change parameters. I can't say "generate 10 questions this time" or "focus on multiple choice." The same `_defaultAllowedTypes` and prompt are used.

**Verdict (MAJOR FAIL):** Reprocessing generates new questions but never cleans up old orphaned questions. Users cannot adjust generation parameters when reprocessing. Old questions accumulate as database bloat.

---

## Step 8: Content Types Matter — Uploading Images and Audio

I have a photo of a chemistry formula sheet and an audio recording of my teacher explaining redox reactions.

**What I expect:** Uploading an image triggers OCR to extract text. Uploading audio triggers transcription. Both produce questions from the extracted content.

**What the code shows:**

The `DocumentExtractor` handles all types:
- **Images** → `OcrExtractor` (LLM-based OCR via vision-capable model)
- **Audio/Video** → `TranscriptionExtractor` (LLM-based transcription)

**But there's a critical dependency:** Both OCR and transcription require an LLM with vision/audio capabilities. If the user's chosen model doesn't support vision (e.g., a text-only model), OCR silently produces garbage or fails. There's NO check or warning before processing: "Your selected model may not support image analysis. OCR results may be poor."

The `upload_screen.dart` at line 218 only checks `resolvedModelId.isEmpty` — it doesn't check if the model supports the required features for the selected content type.

**Additionally**, for camera capture, there's no cropping, rotation, or enhancement step before sending to the LLM. A photo of a whiteboard taken at an angle might be unreadable by the LLM's vision model, producing poor text extraction with no user feedback.

**Verdict (MAJOR FAIL):** No model-capability check before processing images/audio. Users may get poor or failed results without understanding why their model can't handle that content type.

---

## Step 9: Uploading the Same PDF Twice — Duplicate Sources

After my first successful upload, I accidentally upload the same PDF again (or upload a similar file).

**What I expect:** Either a warning "This looks like content you already uploaded" or I end up with two identical source entries.

**What actually happens:** The pipeline has NO deduplication logic. The `Source.id` is generated from `IdGenerator.generate('src')` which produces a unique ID every time. Even if the title, content, and subject are identical, a new source record is created with a different ID. The Content Library now shows two near-identical entries.

There's no:
- Content hash check (MD5/SHA of file content)
- Title comparison
- "Already uploaded" dialog
- Merge option

**Verdict (MAJOR FAIL):** No deduplication of uploaded content. Users can upload the same file multiple times, creating redundant sources and duplicate questions.

---

## Step 10: Practice from Source — Can I Practice Just This Upload's Questions?

After uploading and seeing my generated questions, I want to practice only the questions from "IB Chemistry Textbook — Chapter 1."

**What I expect:** A "Practice from Source" button on the Source Detail screen, or at least Source Practice mode in the Practice tab.

**What actually happens:**

There IS a Source Practice mode in the Practice tab (`practice_mode_grid.dart` — the teal "Source Practice" card). Let me trace this path:

1. Practice tab → Source Practice card → bottom sheet with subject picker and source picker
2. I select "IB Chemistry" subject, then "IB Chemistry Textbook — Chapter 1" source
3. Practice session starts with only that source's questions ✓

**But this requires:**
- Going back to Practice tab (if I'm on Source Detail)
- Finding Source Practice in the mode grid
- Selecting subject first, then source

**The Source Detail screen has NO direct "Practice" button.** I have to switch contexts entirely.

Also, what if I loaded an image and no questions were generated (because my model doesn't support vision)? The Source Detail shows "0 generated questions" — but there's no graceful guidance like "Your model may not support image analysis. Try a different model or upload a text-based file."

**Verdict (MAJOR FAIL):** Source Detail has no "Practice questions from this source" button. Users must navigate to the Practice tab and use Source Practice mode separately. The disconnect between "where I view my content" and "where I practice" creates a broken workflow.

---

## Step 11: Deleting a Source — What Happens to Questions?

I uploaded a practice test PDF and realized it's from an old syllabus. I want to delete it.

**What I expect:** I can delete the source and optionally delete its generated questions. Clear confirmation dialog.

**What actually happens:**

In Content Library:
1. Swipe-left or tap delete (with confirmation dialog)
2. Dialog has a checkbox: "Also delete generated questions" (appears if `generatedQuestionIds.isNotEmpty`)
3. On confirm, source is deleted. Questions deleted if checkbox checked.
4. Undo snackbar appears.

**This works correctly.** ✓ The undo even restores the source record and its questions.

**But there's a gap:** After deletion, if I chose NOT to delete the questions, they become orphans — questions in the database with no associated source. They still appear in practice sessions (since they have subjectId) but their `sourceIds` reference a deleted source. There's no indication in the practice session that a question's source was deleted.

**Verdict (PARTIAL):** Delete flow works correctly. Orphaned questions (when user chooses not to delete them) have no indication their source was deleted.

---

## Step 12: The Content Library Filter — Hidden Gaps

I have several sources uploaded. I want to filter by "Completed" status to see only finished ones.

**What I expect:** A status filter dropdown showing all statuses. I pick "Completed" and see only completed sources.

**What the code shows:** The filter uses `showModalBottomSheet` with `SingleChildScrollView` containing checkboxes for each status. Each checkbox toggles inclusion. Multiple statuses can be selected simultaneously. Wait, let me look more carefully...

Actually, `_buildFilterBar()` at content_library_screen.dart — I need to check if it uses radio or checkbox selection. Based on the filter variables (`_statusFilter`, `_typeFilter`, `_subjectFilter` are all `String` not `List<String>`), these are single-select filters. So I can only show sources with ONE status at a time (e.g., "Completed" OR "Failed" but not both).

If I want to see both "Pending" and "Extracting" sources (to track pipeline progress), I can't do that in one view — I'd have to filter twice.

**But wait** — looking at the filter implementation, `_typeFilter` and `_statusFilter` check by index comparison (`s.type.index.toString()`), not by name. If the enum values change order, existing filters break. This is fragile.

**Verdict (MINOR FAIL):** Status/type filters are single-select only. Cannot view multiple statuses simultaneously. Filter types use fragile enum index comparison.

---

## Step 13: Source Practice Mode — The 7th Mode That Exists but Is Hidden

After processing, I go to the Practice tab to try Source Practice mode. I see 6 mode cards in the grid. I scroll down — there's a section labeled "Extra Modes" with Source Practice as the 7th card.

**What I expect:** Source Practice should be prominent if I just uploaded content. Maybe a notification badge or a recent-upload shortcut.

**What actually happens:** Source Practice works correctly when I find it. But it's hidden under "Extra Modes" — not in the main grid of 6 cards. A user who just uploaded and wants to practice their new content has to:
1. Know that Source Practice mode exists
2. Scroll down to find Extra Modes
3. Select subject, then source from a potentially long list

There's no "Recently Uploaded" shortcut anywhere. No badge on the Practice tab showing "New questions available from upload."

**Verdict (MINOR FAIL):** Source Practice is buried under "Extra Modes" with no recent-upload shortcut or notification.

---

## Step 14: What If the Pipeline Runs for Too Long?

My 500-page textbook PDF takes the LLM a long time to process. The pipeline shows an indeterminate progress bar for 5+ minutes.

**What I expect:** A timeout or at least some indication that it's still working. Maybe elapsed time counter, or a "This is taking longer than expected" message after a threshold.

**What actually happens:** The `LinearProgressIndicator` keeps spinning. The description text stays on "Generating questions from content..." for potentially many minutes. There is:
- No elapsed time display
- No timeout on individual LLM calls (the LLM service's default timeout applies)
- No "cancel" button to abort the pipeline
- No way to navigate away and come back (the upload screen blocks navigation during processing — actually, does it? Let me check)

Looking at the upload screen, there's no `WillPopScope` or `PopScope` preventing back navigation during upload. If I tap the back button while processing, the screen pops and the pipeline continues in the background (it's not tied to the widget's lifecycle). When it completes, the snackbar fires on a disposed context... which would cause a crash or silent swallow.

Actually wait, the pipeline catches errors globally. If the upload screen is disposed, the `mounted` check at `upload_screen.dart:257` (`if (mounted) { setState(...) }`) would prevent the UI update. But the pipeline continues processing in the background, consuming API credits and time with no way to cancel or observe.

**Verdict (MAJOR FAIL):** No time estimates, no elapsed counter, no cancel button during pipeline processing. Users cannot abort a stuck pipeline. Navigating away during processing leaves the pipeline running with no UI feedback.

---

## Summary of Expectations vs Reality

| # | Expectation | Reality | Status |
|---|---|---|---|
| 1 | Upload is discoverable from main screen after onboarding | Dashboard checklist offers it; after dismissal, 2-4 levels deep | PARTIAL |
| 2 | Upload without API key lets me save (no AI) or warns clearly | `fullPipeline: true` is hardcoded — save-only path unreachable. Blocked completely without API key. | **FAIL (BLOCKER)** |
| 3 | Progress bar shows overall pipeline progress (step N of M) | Always indeterminate. No stage counter. "classifying" status duplicated for two different stages. | FAIL (MAJOR) |
| 4 | Pipeline duration estimates or elapsed time shown | No elapsed counter, no time estimate, no cancel button | FAIL (MAJOR) |
| 5 | Content Library shows sources with filterable statuses | Works correctly with filter and sort. Filter is single-select, uses fragile enum-index comparison. | PASS (with caveats) |
| 6 | Source Detail shows what AI produced + "Practice Now" button | Shows extracted text, summary, questions — but NO "Practice all from this source" button | **FAIL (MAJOR)** |
| 7 | Error messages are user-friendly (not raw exceptions) | Raw Dart exception strings shown to user (`TimeoutException`, `HttpException`, etc.) | FAIL (MAJOR) |
| 8 | Pipeline error details persist on Source for later review | `Source` model has no error message field. Specific error lost on navigation away. | **FAIL (BLOCKER)** |
| 9 | Reprocessing replaces old questions or warns about duplicates | New questions generated alongside old. Old questions become orphans. No cleanup. | FAIL (MAJOR) |
| 10 | Reprocessing allows parameter adjustment (question count, types) | Uses same prompt and defaults. No user-configurable parameters. | FAIL (MAJOR) |
| 11 | Image/Audio upload checks model capability first | No pre-check. Vision-unaware models silently produce garbage OCR/transcription. | FAIL (MAJOR) |
| 12 | Duplicate upload detection prevents redundant sources | No deduplication at all — same file can be uploaded infinitely | FAIL (MAJOR) |
| 13 | Deleting a source allows optional question deletion | Works correctly with undo. Orphaned questions have no "deleted source" indicator. | PASS (PARTIAL) |
| 14 | Source Practice mode is prominent after upload | Buried under "Extra Modes" in Practice tab; no recent-upload shortcut | MINOR FAIL |
| 15 | Navigating away during upload safely cancels or pauses pipeline | No cancel button; back button doesn't stop pipeline; `mounted` check prevents crash but pipeline bleeds | FAIL (MAJOR) |
| 16 | Generated questions have proper topic association | `topicId` passed from source — if source topic is empty, all questions have empty topicId | **FAIL (MAJOR)** |
| 17 | "Tutorial" or first-upload guidance exists for new users | No post-upload guidance on next steps. Snackbar just says "Content uploaded successfully." | MINOR FAIL |
| 18 | Generated questions can be reviewed before practicing | Questions appear in Source Detail list — but truncated text, no type/difficulty info | PARTIAL |

---

## Dry-Run Validation Results (2026-05-19)

Validation performed against production source code. The following analysis traces each claim against the actual implementation.

### Step 1: Finding the Upload Feature
**Assessment: PARTIAL**

| Claim | Actual |
|---|---|
| Dashboard checklist offers upload on first visit | **Confirmed.** `EmptyDashboardChecklist` at `empty_dashboard_checklist.dart:34-41` has step 2 "Upload Materials" as a tappable `ListTile`. |
| No persistent upload access after checklist dismissed | **Confirmed.** Dashboard has no FAB. Practice tab has no FAB for upload. Only access paths are: Settings → Upload Material (settings_screen.dart:146-147), Subject Detail → More Options → Upload Content (subject_detail_screen.dart:269), Content Library empty state (content_library_screen.dart:284-287), various empty/error dialogs. |

**Still missing:** A persistent upload button/FAB accessible from the main navigation layer.

### Step 2: API Key Check
**Assessment: BLOCKER FAIL**

| Claim | Actual |
|---|---|
| `fullPipeline: true` is hardcoded, blocking save-only path | **Confirmed.** `upload_screen.dart:613`: `_submitContent(fullPipeline: true)`. At line 214: `if (fullPipeline || _generateQuestions || _generateLessons)` — always true. The `else` branch at line 272 (`pipeline.processUpload()`) is dead code — unreachable. With no model configured, error at line 218-224 blocks any upload. |
| User can uncheck both generate checkboxes to bypass AI | **Not true.** `fullPipeline: true` causes the check at line 214 to always enter the AI path, even with both checkboxes off. The model check then blocks. |

**What needs to change:** Either (a) add a "save only" button/mode that calls `processUpload()` directly, or (b) change the hardcoded `fullPipeline: true` to be conditional on the checkboxes, or (c) when `fullPipeline: true` but model is empty, fall through to `processUpload()` instead of erroring.

### Step 3: Progress Indication
**Assessment: MAJOR FAIL**

| Claim | Actual |
|---|---|
| Progress bar is always indeterminate | **Confirmed.** `upload_screen.dart:636`: `LinearProgressIndicator()` with no `value` parameter. No overall progress calculation. |
| "classifying" status used for two stages | **Confirmed.** `content_pipeline.dart:159-161` (topic classification) and `content_pipeline.dart:175-176` (summary generation) both use `ProcessingStatus.classifying`. |
| No stage counter | **Confirmed.** `upload_screen.dart:638-647` shows only the description text with a small loader. No "Step 2 of 5" or similar label. |
| No elapsed time | **Confirmed.** No `Stopwatch` or elapsed-time counter in the upload screen. |

**What needs to change:** (1) Calculate overall progress fraction (e.g., stage 2 of 6 = 33%) and pass as `LinearProgressIndicator(value: ...)`. (2) Add elapsed time counter. (3) Use distinct progress statuses for classification vs. summary, or add a stage counter.

### Step 4: Content Library
**Assessment: PASS (with minor caveats)**

| Claim | Actual |
|---|---|
| Sources listed with status, filter, sort | **Confirmed.** `content_library_screen.dart:270-299` shows filtered sources list. `_buildFilterBar()` renders subject/type/status filter sheets. Sort button with 4 options. |
| Refresh works | **Confirmed.** `RefreshIndicator` at line 292-294 wraps the list. |
| Filter is single-select | **Confirmed.** `_statusFilter` and `_typeFilter` are `String` (single value), not list. Filtering by index comparison at line 140-141: `s.type.index.toString()`. |
| Sort by date uses ID comparison | **Confirmed.** Line 151: `cmp = a.id.compareTo(b.id)` — fragile, assumes lexicographic ordering by creation time. |

### Step 5: Source Detail
**Assessment: MAJOR FAIL**

| Claim | Actual |
|---|---|
| No "Practice All Questions" button | **Confirmed.** `SourceDetailScreen` (source_detail_screen.dart:1-599) shows: info rows (318-324), error banner (327-349), topic section (351-376), summary (378-390), extracted text (392-430), questions list (432-464), reprocess/delete buttons (466-485). No "Practice" button anywhere. |
| Questions listed with truncated text | **Confirmed.** Lines 432-464 build a numbered list. The question text may be truncated by the `ListTile` layout. No type icon, difficulty indicator, or status shown. |
| Questions may have empty topicId | **Confirmed.** `content_pipeline.dart:410-475` passes `topicId: topicId` to `Question` constructor at line 454. If source's `topicId` is empty (classification skipped or failed), questions have `topicId: ''`. |
| Summary and extracted text shown | **Confirmed.** Sections 3-4 correctly render summary and extracted text with search. ✓ |

**What needs to change:** (1) Add a "Practice All Questions" `FilledButton` below the questions list. (2) Add question type icons and difficulty to the list items. (3) Provide hint when questions have no topic: "These questions aren't linked to a topic. Use Source Practice mode or classify this source first."

### Step 6: Pipeline Error Handling
**Assessment: MAJOR FAIL** *(BLOCKER for error persistence)*

| Claim | Actual |
|---|---|
| Error messages are raw Dart exceptions | **Confirmed.** `upload_screen.dart:267`: `l10n.uploadFailed(result.error ?? '')` — shows the raw error string from `Result.failure(e.toString())`. For LLM timeout: "TimeoutException after 0:00:30.000000: Future not completed". For PDF parse failure: "Exception: File format not recognized". |
| Source has no errorMessage field | **Confirmed.** `Source` model (source_model.dart:60-79) has no `errorMessage` field. The pipeline at `content_pipeline.dart:238-250` only sets `processingStatus: failed`, losing the specific error. |
| Source Detail shows generic "Processing failed" | **Confirmed.** `source_detail_screen.dart:327-349` shows a generic error banner with no specific error details. The original error from the pipeline call is lost. |

**What needs to change:** (1) Add `errorMessage` field to `Source` model. (2) Store the error message when pipeline fails. (3) Display the stored error in Source Detail screen. (4) Localize common errors into user-friendly messages (timeout, rate limit, invalid model, PDF parse failure, etc.).

### Step 7: Reprocessing
**Assessment: MAJOR FAIL**

| Claim | Actual |
|---|---|
| Old questions not deleted on reprocess | **Confirmed.** `source_detail_screen.dart:133-201` calls `pipeline.reprocessSource()` which calls `processFullPipeline()` generating new IDs. The source's `generatedQuestionIds` is overwritten with new IDs. Old questions remain in `QuestionRepository` as orphans. |
| No parameter adjustment on reprocess | **Confirmed.** `reprocessSource()` at `content_pipeline.dart:253-283` accepts `generateQuestions` bool and `allowedQuestionTypes` but the Source Detail screen hardcodes these — no UI controls for adjusting generation parameters. |
| The `reprocessSource()` creates a new Source ID | **Confirmed.** `processFullPipeline()` at line 112 calls `IdGenerator.generate('src')` every time. The `_reprocess()` method at source_detail_screen.dart:159-188 works around this by merging, but this is fragile. |

**What needs to change:** (1) In `SourceDetailScreen._reprocess()`, delete old questions referenced by `source.generatedQuestionIds` before reprocessing (or after, on success). (2) Add optional parameter controls to the reprocess dialog. (3) Fix `reprocessSource()` to preserve the existing source ID instead of generating a new one.

### Step 8: Content Type Model Capability
**Assessment: MAJOR FAIL**

| Claim | Actual |
|---|---|
| No model-capability check for image/audio | **Confirmed.** `upload_screen.dart:214-224` only checks `resolvedModelId.isEmpty`. No check for vision support when uploading images, or audio support for audio files. The `DocumentExtractor._extractImage()` and `_extractAudio()` call the LLM with vision/transcription prompts regardless of model capability. |
| No enhancement before OCR | **Confirmed.** Camera capture (`_captureFromCamera`, line 111-142) passes raw photo. No cropping, rotation, or contrast enhancement before OCR. |
| No user guidance on model limitations | **Confirmed.** When `_inferSourceType` returns `image` or `audio`, there's no warning like "Your model may not support this content type." |

**What needs to change:** (1) Add a model capability registry or check. (2) Before processing image/audio, warn the user if their model may not support it. (3) Consider adding image preprocessing (auto-contrast, crop, rotate) before OCR.

### Step 9: Duplicate Detection
**Assessment: MAJOR FAIL**

| Claim | Actual |
|---|---|
| No deduplication | **Confirmed.** `processFullPipeline()` and `processUpload()` always create a new source with `IdGenerator.generate('src')`. No content hash comparison, no title matching, no "already exists" check in the upload flow. |
| Users can upload same file infinitely | **Confirmed.** No guard at any level. |

**What needs to change:** (1) Compute content hash (SHA-256) of uploaded file content. (2) Check against existing sources' content before saving. (3) Show "This content appears to already exist as [title]. Upload anyway?" dialog.

### Step 10: Practice from Source Detail
**Assessment: MAJOR FAIL** *(confirmed)*

No "Practice questions from this source" button exists on the Source Detail screen. Users must navigate to Practice tab → Source Practice mode → select subject → select source. The disconnect is significant.

**What needs to change:** Add a "Practice All Questions" button on Source Detail that navigates to `PracticeSessionScreen` with `sourceId` filter, or navigates to Source Practice mode with this source preselected.

### Step 11: Delete Flow
**Assessment: PASS (PARTIAL)**

Delete flow works correctly (`content_library_screen.dart:163-236`) with:
- Confirmation dialog ✓
- Checkbox for deleting questions ✓
- Undo via snackbar ✓

**Minor gap:** Orphaned questions (kept after source deletion) have no indication their source was deleted.

### Step 12: Content Library Filters
**Assessment: MINOR FAIL**

Single-select status/type filters confirmed. Fragile enum index comparison at line 140-141.

### Step 13: Source Practice Mode Discoverability
**Assessment: MINOR FAIL**

Source Practice is in "Extra Modes" section at bottom of Practice tab grid. No recent-upload shortcut or badge exists.

### Step 14: Pipeline Monitoring
**Assessment: MAJOR FAIL**

| Claim | Actual |
|---|---|
| No cancel button during upload | **Confirmed.** Upload screen has no cancel mechanism. `_isUploading` prevents button re-press but no cancel/abort. |
| No back-button prevention | **Confirmed.** No `PopScope` wrapping. User can navigate back during processing. Pipeline continues with `mounted` checks to prevent UI updates after dispose. |
| No elapsed time | **Confirmed.** No `Stopwatch` in `_UploadScreenState`. |
| Pipeline runs to completion even after screen dispose | **Confirmed.** `processFullPipeline()` is a `Future` that runs independently of widget lifecycle. The `mounted` check at line 257 prevents UI updates but pipeline continues. |

**What needs to change:** (1) Add `PopScope` to prevent accidental back-navigation during processing. (2) Add elapsed time counter. (3) Add cancel button that cancels the pipeline's LLM calls. (4) Consider a bounded progress fraction (stage-based: 5 stages → 20% each).

---

## Summary Table

| Step | Scenario Verdict | Validation Result | Details |
|---|---|---|---|
| 1 — Upload discoverability | PARTIAL | **CONFIRMED** | Dashboard checklist for first-time; 2-4 levels deep after. No persistent FAB. |
| 2 — API key blocking | BLOCKER FAIL | **CONFIRMED** | `fullPipeline: true` hardcoded. Save-only path (`processUpload()`) is dead code. Blocked without API key. |
| 3 — Progress indication | MAJOR FAIL | **CONFIRMED** | Indeterminate bar. "classifying" duplicated. No stage counter. No elapsed time. |
| 4 — Content Library | PASS | **CONFIRMED** | Filter/sort works. Single-select filter. Fragile enum index comparison. |
| 5 — Source Detail | MAJOR FAIL | **CONFIRMED** | No "Practice" button. Truncated question list. Questions may have empty topicId. |
| 6 — Error handling | MAJOR FAIL / BLOCKER | **CONFIRMED** | Raw Dart exceptions. No errorMessage on Source model. Specific error lost on navigation. |
| 7 — Reprocessing | MAJOR FAIL | **CONFIRMED** | Old questions orphaned. No parameter adjustment. New source ID generated each time. |
| 8 — Content type gaps | MAJOR FAIL | **CONFIRMED** | No model-capability pre-check for image/audio. No image preprocessing. |
| 9 — Duplicate detection | MAJOR FAIL | **CONFIRMED** | No deduplication. Same file can be uploaded infinitely. |
| 10 — Practice from Source Detail | MAJOR FAIL | **CONFIRMED** | No "Practice All" button. Must navigate to Practice tab > Source Practice > select subject > select source. |
| 11 — Delete flow | PASS (PARTIAL) | **CONFIRMED** | Works correctly. Orphaned questions have no indicator. |
| 12 — Content Library filters | MINOR FAIL | **CONFIRMED** | Single-select only. Enum index comparison. |
| 13 — Source Practice discoverability | MINOR FAIL | **CONFIRMED** | Under "Extra Modes." No recent-upload badge. |
| 14 — Pipeline monitoring | MAJOR FAIL | **CONFIRMED** | No cancel. No back-button guard. No elapsed time. Pipeline bleeds after screen dispose. |

### Severity Counts

| Severity | Count | Items |
|---|---|---|
| **BLOCKER** | 2 | Step 2 (API key block), Step 6 (error persistence on Source) |
| **MAJOR** | 9 | Steps 3, 5, 6 (raw errors), 7, 8, 9, 10, 14, plus Step 6 (orphan questions) |
| **MINOR** | 3 | Steps 12, 13, 4 (caveats) |
| **PASS** | 1 | Step 11 (delete flow — partial) |

### Key Files Referenced

| File | Key Lines | Role |
|---|---|---|
| `upload_screen.dart` | 184, 214, 218-224, 612-613, 626-654 | Upload UI, `fullPipeline` hardcode, progress card |
| `content_pipeline.dart` | 94-251, 112, 159-173, 175-182, 238-250, 253-283, 320-364, 410-475 | Pipeline stages, error handling, reprocess, classification |
| `source_detail_screen.dart` | 78-131, 133-201, 286-288, 327-349, 432-464, 466-485 | Source detail view, reprocess, error banner |
| `content_library_screen.dart` | 58-86, 134-161, 163-236, 270-299 | Content Library list, filter, sort, delete |
| `source_model.dart` | 60-79 | No `errorMessage` field |
| `document_extractor.dart` | 41-64, 66-80 | Content type extraction routing |
| `empty_dashboard_checklist.dart` | 34-41 | First-time upload discovery |
| `practice_screen.dart` | ~610, ~974 | Source Practice in Extra Modes |
