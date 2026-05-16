# Implement Multi-Format Real Content Ingestion Pipeline

## Context

The product vision requires students to upload "textbooks, PDFs, notes, question banks, syllabi, online video link, video/audio, online website link, screenshots, etc." and have the system "intelligently process, organize, classify, validate, and integrate this material." However, `DocumentExtractor` at `lib/features/ingestion/services/document_extractor.dart` is a **complete stub**: every `SourceType` (pdf, document, image, video, audio, textbook, syllabus, etc.) returns `rawContent` as-is with zero actual extraction logic. The `PdfIngestionService` at `lib/core/services/pdf_ingestion_service.dart` sends raw text to the LLM but never extracts it from an actual PDF. Similarly, `VoiceController` at `lib/features/teaching/services/voice_controller.dart` hardcodes `isAvailable = false`.

Additionally, the `ContentPipeline` at `lib/features/ingestion/services/content_pipeline.dart` has no validation stage — AI-generated questions/summaries are created with no correctness or consistency checks, contrary to the vision's mandate that "AI-generated content should not be blindly trusted."

## Rationale

This is the single biggest gap between the vision and the current implementation. Without real extraction, the ingestion system cannot process actual student materials. Students must manually copy-paste text, defeating the purpose of the feature. The LLM-based generation stages (classification, summarization, question generation) work on whatever string is passed in, but there is no actual pipeline from a real file upload to structured knowledge.

Three concrete problems block every student workflow:
1. A student uploads a PDF textbook — `DocumentExtractor` returns `rawContent` (probably base64 or binary garbage).
2. A student takes a photo of a whiteboard — `DocumentExtractor` returns `rawContent` as-is.
3. A student shares a YouTube link — the system has no way to get the transcript.

## Affected Files

| File | Problem |
|---|---|
| `lib/features/ingestion/services/document_extractor.dart` | Stub — all source types return `rawContent`. No PDF parsing, no OCR, no transcription. |
| `lib/core/services/pdf_ingestion_service.dart` | Sends PDF content to LLM but never actually extracts text from a PDF binary. Duplicates logic with `ContentPipeline._classifyTopic` and `_generateSummary`. |
| `lib/features/ingestion/services/content_pipeline.dart` | No validation/correctness stage after AI generation. No progress reporting for long-running jobs. Error handler in `processFullPipeline` creates a new `Source` instead of reusing the existing one (loses the original source ID). |
| `lib/features/ingestion/data/models/source_model.dart` | No fields for chunking/partitioning (large textbooks). No `ocrText` or `transcriptUrl` field separate from `extractedText`. |
| `lib/core/services/cross_feature_integrator.dart` | Only links `Session` records. Has no mechanism to connect an ingested source to the planner's topic structure or the teaching feature's lesson plans. |
| `lib/features/teaching/services/voice_controller.dart` | Stub — `isAvailable` always `false`, `requestPermission` returns `false`. Blocks the entire speech interaction modality. |
| `lib/core/data/enums.dart` (SourceType) | Types `image`, `video`, `audio` defined but no extraction implementation exists for any of them. |
| `pubspec.yaml` | Missing dependencies for: PDF text extraction (`pdf_text` or `syncfusion_flutter_pdf`), OCR (`google_mlkit_text_recognition`), audio transcription (whisper API or local model), video transcript fetching (YouTube API client). |

## Suggested Implementation Approach

### Phase 1 — real text extraction (high priority)

1. **DocumentExtractor** — replace the stub switch with real extraction:
   - `SourceType.pdf` / `document` / `textbook`: integrate a PDF parsing library (e.g., `syncfusion_flutter_pdf` or `pdfx`) to extract text page by page.
   - `SourceType.webPage`: the `WebScraper` already fetches HTML; move HTML→text stripping into `DocumentExtractor` so all extraction lives in one place.
   - `SourceType.image`: integrate OCR (e.g., `google_mlkit_text_recognition` for on-device, or send to an LLM vision model as a fallback).
   - `SourceType.video` / `audio`: integrate a transcription service (Whisper API via the LLM layer, or a local whisper model). For YouTube, add YouTube Data API transcript fetching.
   - Return the extracted plain text (same signature), but also populate new optional metadata fields on `Source`: `extractionMethod` (String), `pageCount` (int?), `ocrConfidence` (double?).

2. **Source model** — add fields:
   - `chunks` (`List<SourceChunk>`?) — for partitioning large textbooks into sub-sections with page ranges.
   - `extractionMeta` (`Map<String, dynamic>`?) — store OCR confidence, page count, audio duration, etc.
   - Add a `SourceChunk` model with `chunkIndex` (int), `pageStart` (int?), `pageEnd` (int?), `text` (String), `heading` (String?).

### Phase 2 — AI output validation (medium priority)

3. **ContentPipeline** — add a validation stage after `_generateQuestions`:
   - Before persisting each generated question, validate that the question text is non-empty, the options list has ≥2 entries, `correctAnswer` appears in `options`, and `explanation` is non-empty.
   - Add a configurable `validator` callback parameter to `processFullPipeline` so callers can inject domain-specific validation.
   - Refactor the error handler to reuse the original `source` object (update its ID to the failed state) instead of creating a new one.

4. **Merge PdfIngestionService into ContentPipeline** — the `PdfIngestionService` duplicates topic classification and summary generation that `ContentPipeline` already handles. Deprecate `PdfIngestionService` and move its question extraction logic into `ContentPipeline._generateQuestions` (which currently only generates *new* questions, not *extracts* existing ones from text).

### Phase 3 — voice interaction (medium priority)

5. **VoiceController** — replace the stub:
   - Integrate a real speech-to-text (on-device: `speech_to_text` package; cloud: Whisper API via the LLM service).
   - Integrate a real text-to-speech (on-device: `flutter_tts`; cloud: TTS via the LLM service or dedicated TTS API).
   - Make `isAvailable` reflect actual platform capability.
   - Wire the transcribed text into `ConversationManager.sendMessage()` in the teaching feature.

### Phase 4 — cross-feature source linking (low priority)

6. **CrossFeatureIntegrator** — add methods:
   - `linkSourceToTopic(String sourceId, String topicId)` — associates a processed source with planner topics for syllabus tracking.
   - `notifyPlannerOfNewContent(String sourceId, List<String> topicIds)` — triggers planner to re-evaluate workload if significant new material was ingested.

## Acceptance Criteria

1. **PDF extraction**: Uploading a real PDF textbook extracts ≥90% of readable text correctly (verified against manual copy-paste). Page breaks and headings are preserved in `SourceChunk` metadata.
2. **Web page extraction**: A URL paste into the ingestion screen extracts readable article text (not HTML boilerplate) and stores it as `extractedText`.
3. **Image OCR**: A screenshot or photo of text is OCR'd and the recognized text is stored in `extractedText` with `extractionMeta.ocrConfidence`.
4. **Audio/video transcription**: An audio file or YouTube link produces a text transcription stored in `extractedText` with `extractionMeta.durationSeconds`.
5. **Validation guard**: If the LLM generates a question with `<2` options or an empty correct answer, the question is skipped (not persisted) and a warning is logged.
6. **Error recovery**: If the pipeline fails mid-way (e.g., classification succeeds but question generation fails), the `Source` is saved with `processingStatus = failed` and the original `sourceId` is preserved (no orphan Source created).
7. **Voice availability**: `VoiceController.isAvailable` returns `true` on devices with speech recognition support; `startListening` produces real transcribed text events.
8. **Existing tests continue to pass** — all current `DocumentExtractor`, `ContentPipeline`, and `VoiceController` tests (if any) are updated or extended.
9. **No regression** — `processUpload` (the non-pipeline path) still saves sources immediately without attempting extraction.
