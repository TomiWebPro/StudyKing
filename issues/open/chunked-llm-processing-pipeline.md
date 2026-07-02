# Content Pipeline: Replace Single-LLM-Call with Multi-Subagent Chunked Processing

**Severity:** critical
**Affected area:** Content Ingestion — LLM Processing Pipeline
**Reported by:** codebase audit

## Description

The content ingestion pipeline (`lib/features/ingestion/services/content_pipeline.dart`) sends the **entire extracted document text** to the LLM in a single call for each stage:

1. **Classification** (line 234-262): `_classifyTopic()` sends full content to LLM
2. **Summarization** (line 264-272): `_generateSummary()` sends full content to LLM
3. **Question Generation** (line 274-319): `_generateQuestions()` sends full content, expects 3-5 questions
4. **Lesson Generation** (line 322-334): sends full content to LLM

This has three critical problems:

1. **Context window overflow** — A 200-page textbook (~300K chars) exceeds most LLM context limits (128K for GPT-4, 200K for Claude). The LLM call will fail or produce garbage.
2. **Information loss** — Even within context limits, sending a huge document in one call means the LLM cannot give adequate attention to each section.
3. **Superficial output** — Only 3-5 questions from an entire textbook is useless. Each chapter should yield multiple questions.
4. **No section-level granularity** — Questions, summaries, and lessons aren't linked to specific sections/pages.

## Expected behavior

The pipeline should process documents in chunks (by page, section, or token budget) and spawn **parallel sub-agents** for each chunk. Each sub-agent should: classify its chunk, generate relevant questions, extract key concepts, and contribute to a consolidated output.

## Actual behavior

The entire document is sent as one prompt. Chunks exist in the `Source` model (`SourceChunk`) but are never used in LLM processing stages.

## Code analysis

- `lib/features/ingestion/services/content_pipeline.dart:214-228` — Extraction result stored but full text forwarded to next stage
- `lib/features/ingestion/services/content_pipeline.dart:234-272` — Classification and summarization receive full `extractionResult.extractedText`
- `lib/features/ingestion/services/content_pipeline.dart:274-319` — Question generation: `_generateQuestions(textToClassify, ...)` where `textToClassify` is the full text
- `lib/features/ingestion/services/content_pipeline.dart:415-460` — `_classifyTopic()` sends the entire content as one LLM prompt
- `lib/features/ingestion/services/document_extractor.dart:289-320` — `_chunkContent()` splits by double-newlines but chunks are stored as JSON and never used by the LLM stages
- `lib/core/data/models/source_model.dart` — `chunks` field exists but is purely informational

## Suggested approach

1. **Implement chunked LLM processing** using the app's existing `LlmAgent` infrastructure:
   - Create a `ContentChunkProcessor` agent that:
     a. Splits content into manageable chunks (by page, by token budget ~4000 tokens, or by section heading)
     b. Spawns parallel sub-agents for each chunk
     c. Each sub-agent: classifies, extracts key concepts, generates 2-3 questions, identifies topics
     d. Aggregates results: consolidated topic classification, deduplicated questions, merged summaries

2. **Use the existing agent loop** (`lib/core/services/llm_agent/agent_loop.dart`) — it already supports multi-step tool calling and iterative processing. Create a new `ContentProcessingAgent` tool that the pipeline invokes.

3. **Link results to source chunks** — Each generated question should store which `SourceChunk` it came from (via chunk index).

4. **Implement progressive processing** — Process pages/sections while the user waits (show per-section progress), cache results, allow resumption.

5. **Question generation per section** — Goal: 2-3 questions per section/chunk, so a 30-chapter textbook yields 60-90 questions, not 3-5.
