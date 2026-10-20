# Scenario: Student uploads a PDF textbook and it becomes a linked knowledge base entry

**Persona:** Student with study materials to ingest

## Goal

> "I uploaded my Organic Chemistry textbook (PDF). The app parsed it into
> chunks, linked them to the 'Chemistry' subject and 'Reactions' topic, and
> generated a lesson plan I could review. When I asked the mentor about
> 'aldol condensation', it found the relevant textbook page."

## Step expectations

| Step | Expectation | Current code | Status |
|------|------------|-------------|--------|
| 1. Student uploads a PDF textbook | The ingestion pipeline should accept the file, extract text, chunk it, and persist as `Source` entries with subject/topic links. | `lib/features/ingestion/` — ingestion exists. `lib/features/mentor/services/tools/ingest_pdf_to_kb_tool.dart:9` — `IngestPdfToKbTool` registered (`llp_agent_providers.dart:107-113`). Calls `LlmService.chat()` for chunk parsing. | PASS |
| 2. System extracts chunks and links to syllabus topics | After ingestion, each chunk should be linked to the relevant syllabus topic so the mentor can cite it. Topics come from the plan's `SyllabusGoal` list. | `lib/features/ingestion/data/repositories/source_repository.dart` — `Source` model persists ingested content. `lib/features/planner/data/models/personal_learning_plan_model.dart:1` — `SyllabusGoal` lists subjects/topics. `get_syllabus_structure_tool.dart` surfaces structure. | PARTIAL |
| 3. Mentor can cite the textbook when answering questions | When the student asks "What did my textbook say about aldol condensation?", the mentor should find and quote the relevant chunk. | `lib/features/mentor/services/mentor_context_builder.dart:405-463` — `_getSourceInventory()` and `_appendSourceInventory()` inject uploaded-material titles into the mentor context. `search_sources` tool (`lib/features/mentor/services/tools/search_sources_tool.dart`) and `read_source_content` tool (`lib/features/mentor/services/tools/read_source_content_tool.dart`) are registered and traced through AgentLoop in `tool_trace_coverage_test.dart`. | PASS |
| 4. System generates lesson blocks from ingested material | After ingestion, the mentor can call `generate_lesson_blocks` to create lesson content from the parsed textbook chunks. | `lib/features/mentor/services/tools/generate_lesson_blocks_tool.dart:6` — registered (`llp_agent_providers.dart:71`). Calls `LessonAgentService.generateLesson()` which calls the LLM. | PASS |
| 5. Student revisits source content later | A "revisit" view lists all ingested sources with search, so the student can re-read specific textbook sections. | `lib/features/mentor/services/tools/revisit_sources_tool.dart` — `RevisitSourcesTool` registered and traced through AgentLoop in `tool_trace_coverage_test.dart`. Paged, recency-ordered listing with source search via `search_sources` tool. | PASS |

## Tool/context audit

### Tools needed vs. tools available

| Tool needed | Available? | File |
|---|---|---|
| `ingest_pdf_to_kb` (parse PDF into knowledge base) | YES | `lib/features/mentor/services/tools/ingest_pdf_to_kb_tool.dart` |
| `get_syllabus_structure` (map source to syllabus topics) | YES | `lib/features/mentor/services/tools/get_syllabus_structure_tool.dart` |
| `generate_lesson_blocks` (create lessons from ingested content) | YES | `lib/features/mentor/services/tools/generate_lesson_blocks_tool.dart` |
| `search_sources` (semantic/keyword search across ingested content) | YES | `lib/features/mentor/services/tools/search_sources_tool.dart` — registered and traced in `tool_trace_coverage_test.dart`. |
| `revisit_sources` (paged revisit view of ingested materials) | YES | `lib/features/mentor/services/tools/revisit_sources_tool.dart` — registered and traced in `tool_trace_coverage_test.dart`. |
| `read_source_content` (read specific chunk/page of a source) | YES | `lib/features/mentor/services/tools/read_source_content_tool.dart` — registered and traced in `tool_trace_coverage_test.dart`. |

**Gap:** All 5 needed tools now exist (search_sources, revisit_sources, and read_source_content were added since this scenario was first written).

### Context the LLM needs vs. what AgentLoop injects

| Context needed | Injected? | File |
|---|---|---|
| Uploaded sources list (titles, subjects, sizes) | YES (partial) | `mentor_context_builder.dart:405-463` — `_appendSourceInventory` injects per-syllabus source titles. |
| Semantic search results across chunks | NO | No retrieval tool feeds search results into the system prompt. |
| Chunking quality (density of content per chunk) | NO | `ingestion-pdf-figures-dropped-no-chart-tool.md` — figures are dropped; no per-chunk quality signal. |
| Source-topic link confidence | NO | Ingestion does not score confidence of topic assignment; the mentor sees titles only. |

**Gap:** No semantic search context — the mentor cannot cite specific textbook content.
→ File `issues/closed/scenario-ingestion-search-context-not-injected.md`

## Comprehension rubric

| Criterion | Assessment |
|---|---|
| Reading level | PASS — `l10n` strings used for system messages. |
| Actionability (one clear next action) | PARTIAL — ingestion succeeds but the next action (generate lesson vs. search vs. revisit) is not surfaced as one clear prompt. |
| Confirmation discipline | PASS — ingestion is a read-only parse; no schedule changes without confirmation. |

## Validation Results

Traced against code at:
`lib/features/mentor/services/tools/ingest_pdf_to_kb_tool.dart:9-60`,
`lib/features/mentor/services/mentor_context_builder.dart:405-463`,
`lib/features/mentor/services/tools/generate_lesson_blocks_tool.dart:6`,
`lib/features/ingestion/data/repositories/source_repository.dart`.

- Step 1: PASS — `IngestPdfToKbTool` is registered and callable.
- Step 2: PARTIAL — source-topic linking exists but confidence is not scored.
- Step 3: PASS — `search_sources` and `read_source_content` tools are registered and traced through AgentLoop.
- Step 4: PASS — `GenerateLessonBlocksTool` is reachable through AgentLoop.
- Step 5: PASS — `revisit_sources` tool provides paged, recency-ordered listing.

Tool audit: all 5 needed tools exist and are traced (ingest_pdf_to_kb, get_syllabus_structure, search_sources, read_source_content, revisit_sources, generate_lesson_blocks).
RESULT: all needed tools available (0 missing).
Context audit: source content search now available via agent tools; chunking quality and source-topic link confidence not yet scored → enhancement issues.
**Last re-traced:** 2026-10-20 against commit `5732329` (`scenario_validation_test.dart` Steps 1–5, `tool_trace_coverage_test.dart`, `ingest_pdf_to_kb_tool.dart:9`).
