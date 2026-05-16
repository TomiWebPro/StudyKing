# Build a Comprehensive Content Ingestion & Processing Pipeline

## Context

The platform vision (from `agent_must_read.md`) states:

> "Students should be able to upload large amounts of study materials such as textbooks, PDFs, notes, question banks, syllabi, online video link, video/audio, online website link, screenshots, etc. The system should intelligently process, organize, classify, validate, and integrate this material into the broader learning system."

The current ingestion feature (`lib/features/ingestion/`) does not fulfill this vision. The `UploadScreen` has only three input modes:
- **Paste text** — stores raw text in `Source.content`
- **URL link** — stores the URL string in `Source.sourceUrl` without fetching or scraping
- **Camera** — captures a photo path but does **no OCR**; just stores the file path as text

The `ContentPipeline.processUpload` saves metadata but performs **no actual content transformation**: no text extraction, no chunking, no classification, no question generation, no summary generation, no integration with the question bank or knowledge graph.

Meanwhile, `PdfIngestionService` at `lib/core/services/pdf_ingestion_service.dart:122-132` makes direct HTTP calls to OpenRouter's `/chat/completions` endpoint, **bypassing the entire `LlmService` abstraction**. It hardcodes `openRouterBaseUrl`, ignores the user's configured provider, and would fail if a user switches to Ollama or OpenAI.

The `Source` model at `lib/features/ingestion/data/models/source_model.dart` stores all content in a single `content` field with no chunking, no embedding reference, no processing status tracking, and no link to generated questions or topics.

## Impact

| Area | Current State | Target State |
|---|---|---|
| PDF/document upload | No file picker; only paste text | Native file picker for PDF, DOCX, EPUB, Markdown, images; text extraction pipeline |
| URL/web scraping | Stores URL string only | Fetches page content, extracts main text, classifies topic |
| OCR (camera images) | Stores path string only | Runs OCR on captured images, stores extracted text |
| Video/audio processing | No support | Transcribes audio, extracts key content, links to topics |
| Content-to-question pipeline | No auto-generation | Uploaded content triggers AI question generation, markscheme creation, knowledge graph update |
| Provider abstraction | `PdfIngestionService` hardcodes OpenRouter HTTP calls | Uses `LlmService` through provider injection like every other feature |
| Processing state | None — Source has no status tracking | Sources have lifecycle: `pending → processing → completed/failed` with progress |
| Content chunking | Raw blob in a single field | Content is chunked, embedded (using `EmbeddingService`), and indexed for search |
| Multi-format support | Only `text` and `url` actually usable | PDF, image, URL, video, audio, document all produce usable content |

## Proposed Architecture

```
                    ┌─────────────────┐
                    │  Upload Entry    │
                    │  (File Picker /  │
                    │   Camera / URL)  │
                    └────────┬────────┘
                             │ raw bytes / URL
                             ▼
                    ┌─────────────────┐
                    │ Format Extractor │  ← PDF parser (pdfx?), OCR (mlkit?), 
                    │ (per SourceType) │     web scraper (html), audio transcriber
                    └────────┬────────┘
                             │ extracted text
                             ▼
                    ┌─────────────────┐
                    │ Content Chunker  │  ← split into ~2000-token chunks
                    └────────┬────────┘
                             │ chunks
                             ▼
              ┌──────────────┴──────────────┐
              │                             │
              ▼                             ▼
    ┌──────────────────┐          ┌──────────────────┐
    │ Topic Classifier  │          │ Question Generator│
    │ (LLM → topicId)   │          │ (LLM → Question[])│
    └────────┬─────────┘          └────────┬─────────┘
             │ topicId                      │ questionIds
             ▼                             ▼
    ┌──────────────────┐          ┌──────────────────┐
    │ Source saved      │          │ Questions +      │
    │ + linked to topic │          │ Markschemes saved│
    │ + summary stored  │          │ + linked to source│
    └──────────────────┘          └──────────────────┘
```

Each stage runs asynchronously with progress tracking. The user sees "Processing..." on the upload screen, then the source transitions through states.

## Affected Files

| File | Role | Required Change |
|---|---|---|
| `lib/features/ingestion/data/models/source_model.dart` | Core data model | Add `processingStatus` enum, `chunkCount`, `embeddingIds`, `generatedQuestionIds` fields |
| `lib/features/ingestion/data/repositories/source_repository.dart` | Data access | Add status-based query methods (pending, failed, completed) |
| `lib/features/ingestion/services/content_pipeline.dart` | Orchestration | Rewrite to handle format extraction, chunking, classification, question gen as stages |
| `lib/features/ingestion/presentation/upload_screen.dart` | UI | Replace text-only with `file_picker` (PDF, images, documents), camera OCR flow, URL-fetch toggle |
| `lib/core/services/pdf_ingestion_service.dart` | PDF + classification | **Delete** — move classification to `ContentPipeline` using `LlmService`; create proper `DocumentExtractor` and `WebScraper` services |
| `lib/core/services/llm/llm_chat_service.dart` | LLM abstraction | Already provider-agnostic — `PdfIngestionService` should use this instead of raw HTTP |
| `lib/core/services/llm/llm_embeddings_service.dart` | Embedding | Already exists but hardcodes OpenRouter URL — fix to use provider config |
| `lib/features/questions/data/repositories/question_repository.dart` | Question storage | Ensure `create` is exposed and works for bulk AI-generated questions |
| `lib/core/data/enums.dart` | SourceType enum | Add `image`, `webPage`, `audio`, `video`, `document` types if needed |
| `lib/features/subjects/data/repositories/topic_repository.dart` | Topic matching | May need `findOrCreate` for auto-classified topics |
| `lib/core/providers/app_providers.dart` | DI wiring | Provide `ContentPipeline` as a Riverpod provider |
| `pubspec.yaml` | Dependencies | Add `file_picker`, `html` (web scraping), `pdfx` or `pdf_text_extraction`, `mlkit` or google_mlkit_text_recognition |

## Rationale

1. **Foundation gap**: Ingestion is the primary data entry point. Without comprehensive ingestion, the entire platform depends on manually authored questions and content — which makes the system impractical for real student use.

2. **Direct vision requirement**: The `agent_must_read.md` explicitly lists PDFs, notes, question banks, syllabi, videos, URLs, and screenshots as supported inputs. Currently only text-paste works.

3. **Bypassed abstraction**: `PdfIngestionService`—https://github.com/anomalyco/StudyKing/blob/main/lib/core/services/pdf_ingestion_service.dart — makes raw HTTP calls to OpenRouter, completely ignoring the `LlmService` provider abstraction that was built specifically for model-agnostic switching. This means PDF classification breaks under Ollama/OpenAI configs even if the rest of the app works.

4. **Feature synergy**: A working content pipeline would feed every other feature:
   - **Question bank** gets auto-generated questions from uploaded materials
   - **Practice system** gets topic-linked questions for spaced repetition
   - **Teaching/Tutor** gets lesson content from classified sources
   - **Planner** gets topic coverage estimates from uploaded syllabi
   - **Dashboard** gets richer progress data from content processing

5. **Developer velocity**: Current developers must hand-author test questions and topic data. With the pipeline, they can upload a sample PDF and have the system auto-generate the knowledge graph.

## Acceptance Criteria

1. `UploadScreen` (`lib/features/ingestion/presentation/upload_screen.dart`) offers a native file picker that supports at least PDF, image (JPG/PNG), and plain text selection. Camera capture triggers OCR (e.g. `google_mlkit_text_recognition`) and the extracted text is stored.

2. When a URL is entered, the system fetches the page content (using `http` + `html` package), extracts the main article text (e.g. via `Readability` algorithm or similar), and classifies it to a topic via `LlmService.chat()`.

3. `ContentPipeline` (`lib/features/ingestion/services/content_pipeline.dart`) is restructured into stages:
   - **Stage 1**: Extract raw text from source format (PDF parser, OCR, web scraper)
   - **Stage 2**: Classify topic via `LlmService` (replacing `PdfIngestionService.classifyTopic`)
   - **Stage 3**: Generate summary via `LlmService`
   - **Stage 4**: Optionally generate questions via `LlmService` (togglable in settings)
   - Each stage updates `Source.processingStatus` for progress visibility.

4. `Source` model gains `ProcessingStatus` enum (`pending`, `extracting`, `classifying`, `generatingQuestions`, `completed`, `failed`) and optional fields: `extractedText`, `summary`, `generatedQuestionIds`.

5. `PdfIngestionService` is either deleted or refactored to use `LlmService` through proper DI, removing all direct `http.post` calls and hardcoded `openRouterBaseUrl` references.

6. `EmbeddingService` at `lib/core/services/llm/llm_embeddings_service.dart` is updated to use `LlmConfiguration` provider settings instead of hardcoded `_openRouterBaseUrl`.

7. A new Riverpod provider `contentPipelineProvider` wires `ContentPipeline` with `LlmService`, `SourceRepository`, `QuestionRepository`, and `TopicRepository` for use by screens.

8. Zero analysis warnings are introduced. All existing unit tests for the ingestion feature continue to pass.

## Out of Scope

- Video/audio transcription (requires external service or local model — can be added as a future enhancement)
- Semantic chunk search / full-text search across all sources (would require a search index)
- Two-way sync: editing a source and having changes propagate to generated questions (versioning concern)
