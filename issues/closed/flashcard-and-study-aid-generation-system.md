# Study Aids: Add Flashcard, Study Guide, and Concept Map Generation System

**Severity:** major
**Affected area:** Content Ingestion, Lessons, Questions
**Reported by:** codebase audit

## Description

The vision document states the system should support "generated learning materials" and that "AI-generated content should not be blindly trusted; correctness, consistency, and usefulness should be continuously validated." However, the system has **no flashcard generation, no study guide creation, and no concept map generation** — three of the most fundamental study aids in any learning platform.

The existing `SpacedRepetitionService` is for **question reviews** only (SM-2 algorithm for practice questions), not for flashcards (term-definition pairs). The system can generate lessons, summaries, and questions from source content, but it cannot generate:
1. **Flashcards** — Term-definition pairs for active recall
2. **Study guides** — Condensed topic summaries with key formulas, dates, concepts
3. **Concept maps** — Visual relationship diagrams showing how concepts connect
4. **Key term extraction** — Automatic extraction of important vocabulary with definitions
5. **Cheat sheets** — One-page condensed reference for exam preparation

## Expected behavior

When content is ingested or a topic is studied, the system should optionally generate:
- A deck of flashcards (term → definition) from the content
- A condensed study guide with key concepts, formulas, and summaries
- A concept map showing relationships between topics
- Key vocabulary lists with auto-generated definitions
- Export to Anki APKG format or printable PDF

## Actual behavior

No flashcard, study guide, or concept map generation exists. The word "flashcard" appears nowhere in the codebase.

## Code analysis

- `lib/features/ingestion/services/content_pipeline.dart:264-272` — `_generateSummary()` produces only a plain text summary
- `lib/features/ingestion/services/content_pipeline.dart:274-319` — `_generateQuestions()` produces only questions
- `lib/features/lessons/services/lesson_agent_service.dart` — Generates lessons only, no flashcards
- `lib/features/practice/services/spaced_repetition_service.dart` — SM-2 engine for questions only, no flashcard support

## Suggested approach

1. **Create a `Flashcard` data model**:
   ```dart
   class Flashcard {
     final String id;
     final String sourceId; // Source document
     final String topicId;
     final String subjectId;
     final String front; // Term / question
     final String back; // Definition / answer
     final List<String> tags;
     final double mastery; // 0.0-1.0
     final DateTime nextReview; // For SR scheduling
     // SM-2 fields
   }
   ```

2. **Create a `FlashcardGenerator` service** that:
   - Takes content (text, lesson blocks, or topic) and uses LLM to extract key term-definition pairs
   - Validates each flashcard (term is meaningful, definition is accurate)
   - Can generate from: source documents, lesson content, topic summaries, question answer keys
   - Batch generates 10-20 cards per call

3. **Create a `FlashcardReviewService`** that extends the existing `SpacedRepetitionService` to support flashcard review sessions:
   - Shows the front, student recalls the answer, reveals the back
   - Self-rating (1-5) drives SM-2 scheduling
   - Integrates with the existing practice session UI

4. **Create a `StudyGuideGenerator`** that:
   - Per-topic condensed guide (key concepts, formulas, dates)
   - Can export to text, markdown, or PDF
   - Includes auto-generated practice questions

5. **Create a `ConceptMapGenerator`** that:
   - Uses LLM to extract concept-relationship triples from content
   - Generates a graph structure (concepts as nodes, relationships as edges)
   - Renders as an interactive visual map in the app

6. **Add a "Study Aids" tab** to the source detail and topic detail screens showing:
   - Flashcards generated from this content
   - Study guide
   - Practice question count
   - Concept map (if available)

7. **Support Anki export** via APKG file format for users who want to use external flashcard systems
