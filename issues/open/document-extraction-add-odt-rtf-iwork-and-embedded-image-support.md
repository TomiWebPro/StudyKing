# Document Extraction: Add ODT, RTF, iWork Format Support and Embedded Image Extraction

**Severity:** minor
**Affected area:** Content Ingestion — Document Extraction
**Reported by:** codebase audit

## Description

The current `DocumentExtractor` (`lib/features/ingestion/services/document_extractor.dart`) supports PDF, DOCX, EPUB, XLSX, PPTX, TXT, MD, images, and URLs. However, there are gaps:

1. **Unsupported formats** — ODT (OpenDocument Text, common in academic settings), RTF (Rich Text Format), and Apple iWork formats (Pages, Numbers, Keynote) are not supported
2. **No embedded image extraction** — Charts, diagrams, screenshots, and illustrations embedded in DOCX/PPTX documents are discarded during text extraction
3. **No table structure preservation** — Tables in DOCX are extracted as raw concatenated text with no row/column awareness
4. **No footnote/endnote capture** — Citations and footnotes are lost

For academic use, these are significant limitations:
- Many universities use ODT for assignments
- Lecture slides (PPTX) often contain important diagrams
- Textbooks contain figures, charts, and diagrams essential to understanding

## Expected behavior

The document extractor should:
- Support ODT, RTF, and iWork formats (at minimum, ODT)
- Extract embedded images from DOCX/PPTX and store them alongside the text
- Preserve table structure as markdown tables
- Capture footnotes and endnotes with links to their reference points
- Store image references with positional metadata within the text

## Actual behavior

ODT/RTF/iWork formats are not supported. Embedded images are lost. Tables are flattened.

## Code analysis

- `lib/features/ingestion/services/document_extractor.dart:130-180` — `extractText()` switches on `SourceType` and `extension`, no ODT/RTF/pages/numbers/keynote handling
- `lib/features/ingestion/services/document_extractor.dart:90-120` — DOCX extraction parses `word/document.xml` but only extracts `<w:t>` elements (text), ignoring `<w:drawing>`, `<w:object>`, and table structure
- `lib/features/ingestion/services/document_extractor.dart:100-115` — PPTX extraction extracts `<a:t>` elements (text in shapes), ignoring embedded images, charts, SmartArt
- `lib/core/data/extraction/pdf_extractor.dart` — Same issue: extracts text only, no embedded image extraction

## Suggested approach

1. **Add ODT support** — Parse `content.xml` from ODT archives (ZIP-based, similar to DOCX):
   - Extract text from `<text:p>` elements
   - Extract images from `Pictures/` directory within the archive
   - Handle lists, headings, and tables

2. **Add RTF support** — Use a simple RTF parser or regex to extract text content (RTF is mostly ASCII, well-documented format)

3. **Add iWork format support**:
   - Pages (.pages) — ZIP archive containing `index.xml` (similar structure to DOCX)
   - Numbers (.numbers) — ZIP with `index.xml` containing spreadsheet data
   - Keynote (.key) — ZIP with `index.xml` containing slide data

4. **Extract embedded images** from DOCX/PPTX:
   - DOCX: Extract from `word/media/` directory within the ZIP
   - PPTX: Extract from `ppt/media/` directory
   - Store as separate `SourceImage` objects linked to the source document with positional metadata
   - Pass to LLM for analysis during content processing (e.g., "describe this diagram")

5. **Preserve table structure** — Extract DOCX table XML (`<w:tbl>`) and render as markdown tables:
   ```markdown
   | Header 1 | Header 2 |
   |----------|----------|
   | Cell 1   | Cell 2   |
   ```

6. **Capture footnotes** — Extract `<w:footnote>` elements from DOCX and append them with markers in the extracted text
