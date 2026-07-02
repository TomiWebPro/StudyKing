# Ingestion Feature

## Overview

The Ingestion feature handles importing external study content into the app. It supports file uploads (PDF, DOCX, EPUB, images, audio, video), URL scraping, and direct text input. The content pipeline processes raw material through extraction, classification, summarization, question generation, and optional lesson generation stages.

## Key Files

| Layer | Files |
|---|---|
| Services | `ContentPipeline`, `DocumentExtractor`, `WebScraper`, `ExtractionResult` |
| Repositories | `SourceRepository` |
| Models | `SourceChunk` |
| Adapters | `SourceAdapter` (Hive TypeAdapter) |
| Screens | `UploadScreen`, `ContentLibraryScreen`, `SourceDetailScreen` |
| Providers | `contentPipelineProvider`, `documentExtractorProvider`, `webScraperProvider`, `ingestionSourceRepositoryProvider`, `ingestionTopicRepositoryProvider`, `ingestionQuestionRepositoryProvider` |

## Core Services

### ContentPipeline

The main orchestrator that ties together extraction, classification, summarization, and question generation:

- `processUpload(title, content, type, studentId, ...)` — Save a source without processing (just persist)
- `processFullPipeline(title, content, type, studentId, modelId, ...)` — Run the complete extract -> classify -> summarize -> generate questions -> generate lessons pipeline
- `reprocessSource(source, modelId, ...)` — Re-run the pipeline on an existing source, optionally replacing old questions
- `fetchAndScrapeUrl(url)` — Fetch and extract text from a URL via WebScraper
- `cancel()` — Cancel an ongoing pipeline
- `userFriendlyError(error)` — Map exceptions to user-readable error messages

### DocumentExtractor

Extracts text from various file formats:

- `extractText(rawContent, sourceType, sourceUrl)` — Route to the correct extraction strategy based on source type
- Handles PDF (via `PdfExtractor`), DOCX/EPUB/XLSX/PPTX (via ZIP parsing), images (via `OcrExtractor`), audio/video (via `TranscriptionExtractor`), and HTML (via tag stripping)
- Produces `ExtractionResult` with extracted text, page count, OCR confidence, duration, and content chunks

### WebScraper

Fetches and extracts readable text from web pages:

- `fetchPageContent(url)` — HTTP GET the URL, strip HTML tags using `DocumentExtractor.stripHtmlToText()`, return clean text

## Content Pipeline Workflow

1. **Save** — Content is saved as a `Source` with a SHA-256 content hash (duplicate prevention)
2. **Extract** — `DocumentExtractor` extracts raw text from the file/URL. For PDFs and office documents, specialized parsers handle the format; for images, OCR is used; for audio/video, transcription is attempted
3. **Classify** — If possible topics are provided, the LLM classifies the content to the best-matching topic. For syllabus uploads, topics are extracted from the content and auto-created
4. **Summarize** — An LLM generates a summary of the extracted text
5. **Generate Questions** — The LLM generates questions (single/multi choice, typed answer, math, essay, etc.) which are validated, parsed, and persisted
6. **Generate Lessons** — Optionally, `LessonAgentService` creates a structured lesson from the content
7. **Complete** — The source status is updated to `ProcessingStatus.completed`

## Source Management

- Sources are stored in a Hive box with status tracking (`pending`, `extracting`, `classifying`, `summarizing`, `generatingQuestions`, `validating`, `completed`, `failed`)
- `SourceRepository` provides filtering by subject, topic, student, type, and processing status
- Failed sources retain an error message for debugging
- Sources can be reprocessed from `SourceDetailScreen`, optionally replacing old questions

## Upload Flow

1. `UploadScreen` allows three input methods: paste text, URL (with fetch & scrape), or file picker
2. A camera capture option is available for images
3. User sets title, optionally selects a subject, and toggles question generation, lesson generation, and syllabus mode
4. Upload saves the source immediately; the full pipeline runs asynchronously with progress callbacks
5. Progress is displayed as a linear progress indicator with stage labels and elapsed time
6. On completion, the user is offered navigation to the content library or to start practice immediately
7. Duplicate content (matching content hash) is rejected with a user-friendly error

## Supported File Types

| Type | Extensions | Extraction Method |
|---|---|---|
| PDF | `.pdf` | `PdfExtractor` (text extraction or OCR fallback) |
| Document | `.docx`, `.epub`, `.md` | ZIP parsing (DOCX/EPUB) or direct read |
| Image | `.jpg`, `.jpeg`, `.png` | `OcrExtractor` (LLM-based OCR) |
| Audio | `.mp3`, `.wav`, `.m4a`, `.ogg` | `TranscriptionExtractor` |
| Video | `.mp4`, `.webm` | `TranscriptionExtractor` (audio track) |
| Web Page | URL | `WebScraper` (HTTP + HTML stripping) |
| Text | `.txt`, pasted content | Direct read |
| Spreadsheet | `.xlsx` | ZIP parsing (shared strings + sheet XML) |
| Presentation | `.pptx` | ZIP parsing (slide XML text extraction) |
