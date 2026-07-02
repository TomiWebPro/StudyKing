# Content Ingestion: Add Dedicated OCR Engine Instead of LLM-Only OCR

**Severity:** major
**Affected area:** Content Ingestion — Image/Scanned PDF OCR
**Reported by:** codebase audit

## Description

The current OCR implementation at `lib/core/data/extraction/ocr_extractor.dart` uses the **LLM's vision capabilities** as its sole OCR engine. When an image or scanned PDF is uploaded, the image bytes are base64-encoded and sent directly to the LLM with the prompt "Extract all text visible in this image content."

This approach has critical shortcomings:

1. **Cost** — Every OCR operation consumes LLM tokens (input: image + prompt, output: potentially thousands of tokens), making bulk OCR of a 300-page textbook prohibitively expensive
2. **Speed** — LLM vision inference is 5-30x slower than dedicated OCR engines (Tesseract processes a page in <1s; LLMs take 3-15s per image)
3. **Model dependency** — Only works with multimodal LLMs (GPT-4 Vision, Claude 3, Gemini). Text-only models or local Ollama models without vision support cannot perform OCR
4. **No offline capability** — LLM-based OCR requires internet connectivity (or a very powerful local model)
5. **No confidence scoring** — The current implementation hardcodes `ocrConfidence: 0.7` regardless of actual extraction quality

## Steps to reproduce

1. Open the Upload screen with an image containing text (screenshot, photo of notes, scanned document page)
2. Select the image
3. Observe slow processing (5-15s per image)
4. If using a text-only LLM provider, OCR silently fails with extraction method `'ocr_no_llm_available'`

## Expected behavior

OCR should:
- Work offline with dedicated OCR engines
- Process a page in under 1 second
- Work with any LLM provider (including text-only)
- Provide confidence scores per extracted text segment
- Fall back to LLM-based OCR only for complex cases (handwritten text, unusual layouts)

## Actual behavior

OCR is entirely LLM-dependent. Expensive, slow, requires multimodal model, no confidence scoring.

## Code analysis

- `lib/core/data/extraction/ocr_extractor.dart:1-185` — Entire file uses LLM for OCR via `_extractWithLlm()` method
- `lib/core/data/extraction/ocr_extractor.dart:122-150` — Image bytes are base64-encoded and sent to LLM chat completion
- `lib/features/ingestion/services/document_extractor.dart:187-210` — `_extractImage()` calls `OcrExtractor.extractText()` with no local OCR fallback
- `lib/features/ingestion/presentation/upload_screen.dart:248-278` — Warning about OCR capability shown to user

## Suggested approach

1. **Integrate Google ML Kit's text recognition** (`google_mlkit_text_recognition`) as the primary OCR engine:
   - On-device, free, fast (<1s per page)
   - Works offline
   - Provides confidence scores per text block
   - Supports Latin-based and CJK character sets

2. **Use Tesseract** (`tesseract_ocr` or similar Flutter plugin) as a secondary offline option

3. **Keep LLM-based OCR as fallback only** for:
   - Handwritten text that ML Kit struggles with
   - Unusual layouts (tables, diagrams with labels)
   - Low-confidence detections (where ML Kit confidence < 0.6)

4. **Make OCR configurable** in Settings — users should be able to choose between:
   - "Fast (ML Kit)" — default, offline
   - "Accurate (LLM)" — for complex documents
   - "Hybrid" — ML Kit first, LLM fallback on low confidence

5. **Report actual confidence scores** in `Source.extractionMeta` instead of hardcoded `0.7`
