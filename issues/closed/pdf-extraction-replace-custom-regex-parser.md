# PDF Extraction: Replace Custom Regex Parser with Proper PDF Library

**Severity:** critical
**Affected area:** Content Ingestion — PDF Extraction
**Reported by:** codebase audit

## Description

The current PDF extraction in `lib/core/data/extraction/pdf_extractor.dart` uses a custom regex-based parser that extracts text by searching for content between parentheses `(...)` in the raw PDF bytes (line 89: `RegExp(r'\((?:[^()\\]|\\.)*\)')`). This approach:

1. **Fails on scanned PDFs** — No OCR fallback for image-based PDFs
2. **Fails on compressed PDF streams** — Most modern PDFs use FlateDecode compression; raw byte scanning yields garbage
3. **Fails on complex layouts** — Multi-column, tables, headers/footers are jumbled
4. **Has no page boundary tracking** — Can't determine which text belongs to which page
5. **No text positioning** — Can't reconstruct reading order for complex layouts

For the product to credibly claim "upload a 300-page textbook," this is the single most critical blocker.

## Steps to reproduce

1. Open the Upload screen
2. Select a PDF file (preferably a scanned PDF or a PDF with FlateDecode compression)
3. Observe the extraction result — likely empty or garbled text
4. Check the `Source.extractionMethod` field — likely `no_text_found` or `extraction_failed`

## Expected behavior

The PDF extractor should reliably extract text from:
- Text-based PDFs (all compression types)
- Scanned/image-based PDFs (via OCR fallback)
- PDFs with complex layouts (tables, columns)
- PDFs of any size (with proper streaming/chunking)

## Actual behavior

Only simple, uncompressed text PDFs work. Any modern PDF with compression, images, or complex layouts produces empty or corrupted extraction.

## Code analysis

- `lib/core/data/extraction/pdf_extractor.dart:18-152` — Entire `PdfExtractor` class uses `String.fromCharCodes(bytes)` and regex matching on raw PDF syntax
- `lib/core/data/extraction/pdf_extractor.dart:89` — `RegExp(r'\((?:[^()\\]|\\.)*\)')` matches parenthesized content in raw PDF, which is fragile
- `lib/core/data/extraction/pdf_extractor.dart:53` — Falls back to `_cleanRawPdfContent()` if simple extraction yields < 50 chars, which just filter-lines non-PDF content
- `lib/features/ingestion/services/document_extractor.dart:156-170` — Routes PDF file:// paths to `PdfExtractor`
- `lib/features/ingestion/services/content_pipeline.dart:214-228` — Full extracted text is then sent in a single LLM call, compounding the problem

## Suggested approach

1. **Replace `PdfExtractor`** with a proper PDF parsing library such as:
   - `syncfusion_flutter_pdf` (commercial but free for individuals) — provides `PdfDocument` with page-by-page text extraction
   - `pdf_text` — pure Dart PDF text extraction
   - `pdfrx` — Flutter PDF viewer with text extraction
2. **Add page-level metadata** — Track which text came from which page number
3. **Add streaming/chunked reading** — Read large PDFs in page batches rather than loading entire file into memory
4. **Add OCR fallback** — When text extraction yields < 50 chars per page, trigger OCR (via Tesseract or ML Kit)
5. **Preserve extraction quality metrics** — Report per-page character count, confidence score
