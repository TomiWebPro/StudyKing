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
| 3. Mentor can cite the textbook when answering questions | When the student asks "What did my textbook say about aldol condensation?", the mentor should find and quote the relevant chunk. | `lib/features/mentor/services/mentor_context_builder.dart:405-463` — `_getSourceInventory()` and `_appendSourceInventory()` now inject uploaded-material titles into the mentor context. Source search/retrieval is limited — no semantic search tool is registered. | PARTIAL |
| 4. System generates lesson blocks from ingested material | After ingestion, the mentor can call `generate_lesson_blocks` to create lesson content from the parsed textbook chunks. | `lib/features/mentor/services/tools/generate_lesson_blocks_tool.dart:6` — registered (`llp_agent_providers.dart:71`). Calls `LessonAgentService.generateLesson()` which calls the LLM. | PASS |
| 5. Student revisits source content later | A "revisit" view lists all ingested sources with search, so the student can re-read specific textbook sections. | `dry-run-test/scenario_new_user_learn_chemistry.md:step2` references `ingestion-revisit-view-missing-no-paged-ux.md`. No paged revisit UI exists. | FAIL |

## Tool/context audit

### Tools needed vs. tools available

| Tool needed | Available? | File |
|---|---|---|
| `ingest_pdf_to_kb` (parse PDF into knowledge base) | YES | `lib/features/mentor/services/tools/ingest_pdf_to_kb_tool.dart` |
| `get_syllabus_structure` (map source to syllabus topics) | YES | `lib/features/mentor/services/tools/get_syllabus_structure_tool.dart` |
| `generate_lesson_blocks` (create lessons from ingested content) | YES | `lib/features/mentor/services/tools/generate_lesson_blocks_tool.dart` |
| `search_sources` (semantic/keyword search across ingested content) | MISSING | No agent tool wraps source content search. |
| `revisit_sources` (paged revisit view of ingested materials) | MISSING | No agent tool for the revisit view. |

**Gap:** No `search_sources` or `revisit_sources` agent tools — the mentor cannot search or surface ingested content conversationally.
→ File `issues/open/e2e-ingestion-missing-search-sources-tool.md`

### Context the LLM needs vs. what AgentLoop injects

| Context needed | Injected? | File |
|---|---|---|
| Uploaded sources list (titles, subjects, sizes) | YES (partial) | `mentor_context_builder.dart:405-463` — `_appendSourceInventory` injects per-syllabus source titles. |
| Semantic search results across chunks | NO | No retrieval tool feeds search results into the system prompt. |
| Chunking quality (density of content per chunk) | NO | `ingestion-pdf-figures-dropped-no-chart-tool.md` — figures are dropped; no per-chunk quality signal. |
| Source-topic link confidence | NO | Ingestion does not score confidence of topic assignment; the mentor sees titles only. |

**Gap:** No semantic search context — the mentor cannot cite specific textbook content.
→ File `issues/open/scenario-ingestion-search-context-not-injected.md`

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
- Step 3: PARTIAL — source titles are injected but no content search is available.
- Step 4: PASS — `GenerateLessonBlocksTool` is reachable through AgentLoop.
- Step 5: FAIL — no paged revisit view exists.

Tool audit: 3 of 5 needed tools exist; `search_sources` and `revisit_sources` are missing.
Context audit: source content search and chunking quality not injected → new issues filed.
