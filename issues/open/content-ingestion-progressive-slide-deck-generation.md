# Content Ingestion: Progressive Slide Deck Generation from Study Materials

**Severity:** minor
**Affected area:** Content Ingestion — Lesson/Slide Generation
**Reported by:** codebase audit

## Description

The current content pipeline has a "Generate Lesson" stage that calls `LessonAgentService.generateLessonFromSource()` to produce a single `Lesson` with `LessonBlock` objects. However, this produces a single flat lesson — it doesn't generate a **progressive slide deck** that can serve as a structured presentation guide for studying the source material.

The vision asks for "PPT-like structured guides" that can be used alongside the AI tutor. For a 300-page textbook, the system should generate:
- A full chapter-by-chapter slide deck (like an auto-generated PowerPoint)
- Each chapter/section as a separate lesson with multiple slides
- Slides with: key concepts, definitions, diagrams (described), example problems, summaries, quiz questions
- Navigation structure: table of contents, next/previous chapter, section markers

## Expected behavior

When a source document is processed, the system should optionally generate a multi-lesson slide deck that:
- Follows the document's structure (chapters → sections → subsections)
- Each chapter becomes a lesson, each section becomes a slide block
- Includes summary slides, key formula/definition slides, example slides, and quiz slides
- Is navigable (table of contents, sequential, random-access)
- Can be used in the tutor's slides mode for structured study
- Can be regenerated with different styles (detailed vs overview, theoretical vs practical)

## Actual behavior

The pipeline generates a single flat lesson with mixed blocks (text, example, exercise, etc.) that doesn't respect the source document's chapter/section structure.

## Code analysis

- `lib/features/ingestion/services/content_pipeline.dart:322-334` — Calls `_lessonAgentService.generateLessonFromSource()` which produces a single lesson
- `lib/features/lessons/services/lesson_agent_service.dart` — `generateLessonFromSource()` prompts LLM to create blocks, no structure awareness
- `lib/features/lessons/data/models/lesson_model.dart` — `Lesson` has a flat list of blocks, no hierarchy/chapter structure
- `lib/features/lessons/data/models/lesson_block_model.dart` — `LessonBlock` has `type` and `order` but no section/chapter field

## Suggested approach

1. **Create a `SlideDeckGenerator` service** that:
   - Takes the extracted, chunked source content
   - Uses the LLM to identify chapter/section boundaries (from headings, table of contents, or document structure)
   - For each chapter: generates a set of slides (title slide, concept slides, example slides, summary slide, quiz slide)
   - Returns a multi-lesson deck (one `Lesson` per chapter, or one `Lesson` with hierarchical blocks)

2. **Extend the `LessonBlock` model** with:
   ```dart
   String? chapterTitle;     // Which chapter this block belongs to
   String? sectionTitle;     // Which section within the chapter
   int? chapterOrder;        // Chapter number
   int? sectionOrder;        // Section number within chapter
   SlideType? slideType;     // title, concept, definition, formula, example, summary, quiz, reference
   ```

3. **Generate a table of contents** — An overview `LessonBlock` listing all chapters and sections with links/indices

4. **Update the slides/presentation UI** to support:
   - Chapter navigation (skip between chapters)
   - Section markers within slides
   - "Slide X of Y in Chapter Z" counter
   - Table of contents access

5. **Make slide style configurable** — The LLM prompt should include a style parameter:
   ```
   "Generate slides for this textbook chapter in {detailed|concise|exam-focused} style."
   ```
