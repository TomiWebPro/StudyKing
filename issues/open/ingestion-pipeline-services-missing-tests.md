# Add behavioral tests for ingestion pipeline and document extractor

## Description
Content ingestion (uploaded PDFs, docs, web, video, images) is the entry point for
all study material and is AI-heavy and high-risk, yet its core services are
untested, violating AGENTS.md test-placement rules:

- `lib/features/ingestion/services/content_pipeline.dart:32` — `ContentPipeline`
  orchestrates extraction → classification → chunking → question generation.
- `lib/features/ingestion/services/document_extractor.dart:23` — `DocumentExtractor`
  (PDF/doc/image/video text extraction, returns `ExtractionResult`).
- `lib/features/ingestion/services/chunked_content_processor.dart` — chunk
  classification / summarization / question generation.
- `lib/features/ingestion/services/web_scraper.dart` and `page_metadata.dart`.

A regression here can silently drop or mis-classify uploaded material with no test
coverage.

## Affected files/areas
- lib/features/ingestion/services/content_pipeline.dart
- lib/features/ingestion/services/document_extractor.dart
- lib/features/ingestion/services/chunked_content_processor.dart
- lib/features/ingestion/services/web_scraper.dart
- lib/features/ingestion/services/page_metadata.dart

## Expected vs Actual
- Expected: Each service has `test/features/ingestion/services/*_test.dart` with
  behavioral assertions, using fakes for the LLM/extraction boundaries (e.g. a fake
  extractor returns canned `ExtractionResult` and the pipeline routes it correctly;
  `DocumentExtractor` error path returns a failed `Result` rather than throwing).
- Actual: No test files exist for any ingestion service.

## Acceptance Criteria
- [ ] `test/features/ingestion/services/content_pipeline_test.dart` exists and verifies
      pipeline routing/classification using fakes.
- [ ] `test/features/ingestion/services/document_extractor_test.dart` exists and
      verifies success and error (`Result.failure`) handling.
- [ ] `flutter test test/features/ingestion/services` passes and `flutter analyze`
      is clean.
