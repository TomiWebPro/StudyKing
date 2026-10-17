# StudyKing — Next-Term Vision Finder Report (refresh)

Role: `sk-next-finder`. Binding vision: `docs/vision_next_term.md` §1–4 + `agent_must_read.md`.
Method: read vision + `agent_must_read.md` + `docs/README.md` + `AGENTS.md` + git log + `issues/open|closed/`
+ `dry-run-test/`; judged each capability against the **current working tree** (committed HEAD plus
in-tree builder changes); cross-checked every deviation against every slug in `issues/open/` and
`issues/closed/` before filing. **No code edited, no commits, no `git add` of issues.**

Latest commit: `355fc97 solidif(e2e-switch-syllabus-focus): implement tool + trace + scenario validation` (Oct 17 13:19).
Uncommitted working-tree changes (builder in-progress): registration + e2e traces for `SwitchProviderTool`,
`ReviewMistakesTool`, `ReadSourceContentTool` in `llmAgentToolsProvider`; ingestion robustness (file-size
ceiling `maxCharsPerSource` + truncation + per-chunk retry/backoff + partial-failure surfacing + tests);
`registeredToolNames` updated to 20 entries (added `switch_provider`, `review_mistakes`; `read_source_content`
still NOT added — test-drift tracked by `ingestion-no-source-content-reader-tool.md`).

## Files / artifacts inspected (current working tree)

- `docs/vision_next_term.md` (binding), `agent_must_read.md` (core), `docs/README.md`, `AGENTS.md`
- `git log --oneline -20`, `git status --short`, `git diff` (working-tree changes)
- `packages/flutter_to_image/` (`lib/src/renderer.dart:58`, `golden_matrix.dart:25/72/109`, `src/`,
  `lib/flutter_to_image.dart`; tests: `renderer_test.dart` 17 tests, `golden_matrix_test.dart` 22 tests)
- `docs/development/visual-testing.md`
- `dry-run-test/` — **11** scenario files (≥10 acceptance met)
- `lib/core/services/llm_agent/{agent_loop.dart,idle_executor.dart,llm_agent.dart}`
- `lib/core/services/{system_monitor_service.dart,llm_task_manager.dart,llm_usage_meter.dart,
  prep_budget.dart,prep_budget_repository.dart,prep_budget_service.dart}`
- `lib/core/providers/llm_agent_providers.dart` (working-tree: 21 tools registered incl. uncommitted
  `switch_provider`, `review_mistakes`, `read_source_content`)
- `lib/features/{mentor/teaching/ingestion/practice/planner}/` (services, tools, screens, providers)
- `test/integration/agentic_e2e/` — 8 files: `agentic_e2e_test`, `ailab_model_e2e_test`, `fakes.dart`,
  `prompt_regression_test`, `scenario_validation_test`, `tool_trace_coverage_test`, `transcript_helpers`
  + `goldens/` (v1 prompt transcripts) + `transcripts/` (mentor_teaching happy paths)
- `test/features/**/*golden_test.dart` (5 golden test files), `test/features/mentor/services/tools/`
  (20 tool unit-test files + `test_helpers.dart`)
- `lib/core/data/enums.dart:41-48` (`LessonBlockType`: text/example/exercise/slide/quiz/summary —
  still no visual/analogy)

## Closeness verdict per section (§1–§4)

### §1 Flutter-to-image visuals — CLOSING

- **Package:** CLOSE. `packages/flutter_to_image/` renders widget→PNG headlessly under `flutter test`
  (`renderer.dart:58 renderWidgetToPng`, `renderWidgetToImageResult:91`, path convention
  `golden_matrix.dart:109`); deterministic test-font; unit-tested (renderer_test 17 tests,
  golden_matrix_test 22 tests); no network/GPU/Hive.
- **Docs:** `docs/development/visual-testing.md` exists (matrix, accessibility, contrast, 48dp,
  `--update-goldens`, golden gitignore policy).
- **Integration:** golden tests exist for tutor screen, mentor screen, lesson list screen, plus
  `dashboard_nav_card` + `summary_row` widget goldens (commits `3870c06`, `43e5f20`, `6c4d4d3`).
- **Verified:** tutor, mentor, lessons screen goldens exist; dashboard nav card + summary row goldens exist.
- **Residual:** 3 of the 6 top-level **screen**-level goldens still missing — dashboard screen,
  planner screen, practice screen. Verified by glob: no `*golden*` in `test/features/dashboard/presentation/`
  (only `dashboard_screen_test.dart` — not golden), `test/features/planner/presentation/` (only
  `planner_screen_test.dart` etc. — not golden), or `test/features/practice/presentation/` (only
  `shared_test_helpers.dart`). All 3 tracked by `visual-dashboard-screen-golden-test-missing.md`,
  `visual-planner-screen-golden-test-missing.md`, `visual-practice-screen-golden-test-missing.md` (open).

### §2 E2E rigour with ailab grant model — CLOSING

- **Suite complete:** 8 files in `test/integration/agentic_e2e/` — fake-mode parser coverage (single/multi/
  malformed/unknown-tool/tool-failure/max-iter/no-tool); opt-in grant-model mode gated by `grantModelConfigured`
  with real `http.Client` vs `MockClient` fallback (`ailab_model_e2e_test.dart`); transcript artifacts via
  `dumpTranscript` (`transcript_helpers.dart:73-97`) writing to `transcripts/`; retry-with-backoff
  (`LlmRetryConfig`, `_computeBackoffDelay`, B5 loops in `llm_chat_service.dart:67-103,225-351`);
  prompt-regression goldens (v1 transcripts in `goldens/`); per-scenario verdicts; tool-trace coverage
  asserts all registered tools traced.
- **Resolved (stale-open, builder should `claim.py close`):**
  - `e2e-mentor-missing-provider-switch-tool` — `SwitchProviderTool` now imported + registered in
    `llm_agent_providers.dart:36,126-145`; added to `registeredToolNames` in `fakes.dart:134`; e2e traces
    (4 tests) + scenario assertions updated `switch_provider -> HAD`.
  - `e2e-review-mistakes-tool-missing` — `ReviewMistakesTool` now exists + imported + registered
    (`llm_agent_providers.dart:35,217-221`); added to `registeredToolNames`; e2e trace group (1 test)
    + scenario assertions updated `review_mistakes -> HAD`.
  - `e2e-grant-model-always-mockclient` — resolved (buildGrantLlmService branches on grantModelConfigured).
  - `e2e-ailab-transcript-artifact-not-persisted` — resolved (dumpTranscript writes + called).
  - `e2e-llm-grant-no-retry-backoff` — resolved (LlmRetryConfig + retry loops in llm_chat_service.dart).
  - `e2e-teaching-missing-context-injection` — resolved (_buildConfusionDirective at prompts.dart:89-91).
  - `e2e-switch-syllabus-focus-tool-missing` — resolved (SwitchSyllabusFocusTool registered
    llm_agent_providers.dart:108-121; committed by 355fc97).
- **Still-valid (genuinely remaining):**
  - `e2e-teaching-missing-explanation-variation-tool` — teaching mode (`conversation_manager.dart:293-301`)
    still calls `_llmService.chatStream()` directly with no `AgentLoop`/`ToolRegistry`; `LessonBlockType`
    (`enums.dart:41-48`) still lacks `visual`/`analogy`; `explain_differently` + `suggest_practice` still
    MISSING in `scenario_validation_test.dart:156,167,890,895`.
- **Working-tree test-drift (tracked, in-progress):**
  - `read_source_content` registered in production (`llm_agent_providers.dart:34,209-212`) but NOT in
    `registeredToolNames` (`fakes.dart` has 20 entries; production has 21). `tool_trace_coverage_test.dart`
    asserts `registeredToolNames` hasLength(20) — false positive. Tracked by `ingestion-no-source-content-reader-tool.md`.
- **`review_mistakes_tool_test.dart` missing:** `ReviewMistakesTool` is registered + e2e-traced but has NO
  dedicated unit test file (solidification criteria for `e2e-review-mistakes-tool-missing.md` requires
  `test/features/mentor/services/tools/review_mistakes_tool_test.dart`). Builder in-progress.

### §3 Scenario simulations — CLOSING

- `dry-run-test/` has **11** scenario files (≥10 acceptance met): new_user_learn_chemistry,
  api_key_missing, longterm_user_accelerates, confused_student_fractions, overworked_student,
  multisubject_juggling, offline_low_end_device_stress, practice_mistake_review,
  practice_review_adaptive, teacher_feedback_loop, ingestion_pdf_to_knowledge_base.
- `scenario_validation_test.dart` has validator groups for all 11 (verdicts: PASS/PARTIAL/FAIL per step).
- Working-tree change: `scenario_practice_mistake_review.md` updated (`review_mistakes -> FOUND`, 6/6 tools).
- Remaining tool/context audit MISSINGs — all tracked:
  - `explain_differently` → `e2e-teaching-missing-explanation-variation-tool.md` (teaching bypasses AgentLoop)
  - `suggest_practice` → same issue (see `scenario_teacher_feedback_loop.md` line 32: "See e2e-teaching-missing-explanation-variation-tool.md")
  - `search_sources`/`revisit_sources` → `ingestion-no-source-content-reader-tool.md`
  - `check_file_size` → `ingestion-file-size-token-ceiling-missing.md` (partially resolved in working tree: `maxCharsPerSource` ceiling added to `document_extractor.dart:68-73`)

### §4 Prep-heavy token economy — CLOSING

- §4.1 prep primitives wired: `PrepBudget` defaults (40/30/20/10 + background/quiet-hours/subject opt-in),
  `PrepBudgetService`, `PrepBudgetSettingsController`, `PrepBudgetRepository`; 4 prep tools registered
  (`ingest_pdf_to_kb`, `enqueue_question_variants`, `pre_generate_lesson`, `refresh_mastery`) +
  `ReadSourceContentTool` (uncommitted) each declaring est-tokens + `PrepCpuClass` + `prepCategory`,
  consulting `canSpend`.
- §4.2 UI: `settings_screen.dart` `_PrepBudgetSection`; `LlmTaskManagerScreen` budget bars, prep-vs-live
  allocation, category filter, retry/cancel.
- §4.3/§4.4 enforcement: `SystemMonitorService.canRunHeavyPrepNow`; `IdleExecutor` defers heavy tasks
  under load (`idle_executor.dart:168`); per-subject opt-in (`idle_executor.dart:175-190`); token
  aggregation (`idle_executor.dart:226-231`); prep>live ratio test (`prep_budget_test.dart:326`).
- Working-tree changes: `document_extractor.dart:68-73` `maxCharsPerSource = 250000` ceiling + truncation
  with `truncationNote`; `extraction_result.dart` adds `truncated`/`truncationNote` fields;
  `chunked_content_processor.dart` adds `_chatWithRetry` (exponential backoff) + `failedChunkCount` +
  `content_pipeline.dart` surfaces partial failures. Tests: `document_extractor_test.dart`,
  `extraction_result_test.dart`, `chunked_content_processor_test.dart` all modified.
- Resolved (stale-open): `budget-prep-live-token-ratio-test-missing` (ratio test at prep_budget_test.dart:326);
  `budget-prep-quiet-hours-not-wired`, `budget-prep-settings-ui-missing`, `budget-prep-tasktype-key-misalignment`,
  `prep-budget-enforcement-missing`, `prep-enqueue-prep-tool-not-wired`, `prep-tools-missing`,
  `prep-per-subject-optin-never-enforced`, `sysmon-service-missing`, `sysmon-idle-executor-cupressure-deferral-untested`,
  `idle-executor-completetask-no-tokens`, `budget-agent-token-tracking` — all committed before current HEAD.
- Note-worthy (closed, residual NOT re-filed per doctrine): `teaching-tutor-post-lesson-prep-placeholder.md`
  — `PreGenerateLessonTool` wired (`teaching_providers.dart:79`, `tutor_service.dart:535-542`), but
  `_enqueueWeakTopicAnalysis` (`tutor_service.dart:500-505`) still calls `_masteryService.getWeakTopics()`
  directly instead of `RefreshMasteryTool.execute()`.

## Stale-open issues — resolved in code, builder should close via `claim.py close`

| Issue (open/) | Fix in code |
|---|---|
| `e2e-mentor-missing-provider-switch-tool` | Working tree: SwitchProviderTool registered + traced |
| `e2e-review-mistakes-tool-missing` | Working tree: ReviewMistakesTool registered + e2e traced (unit test `review_mistakes_tool_test.dart` still missing — solidification criteria) |
| `e2e-grant-model-always-mockclient` | `buildGrantLlmService` branches on `grantModelConfigured` |
| `e2e-ailab-transcript-artifact-not-persisted` | `dumpTranscript` writes + called |
| `e2e-llm-grant-no-retry-backoff` | `LlmRetryConfig` + B5 retry loops |
| `e2e-teaching-missing-context-injection` | `_buildConfusionDirective` injected `prompts.dart:89-91` |
| `e2e-switch-syllabus-focus-tool-missing` | `SwitchSyllabusFocusTool` registered `llm_agent_providers.dart:108-121` |
| `teaching-syllabus-context-not-injected` | `availableSyllabi` passed `tutor_service.dart:175-187` |
| `teaching-image-analysis-tokens-unclassified` | `feature: 'teaching_image_analysis'` at `conversation_manager.dart:359` |
| `budget-prep-live-token-ratio-test-missing` | `prep_budget_test.dart:326` asserts prep > live |
| `visual-dashboard-nav-card-golden-tests` | goldens committed (`6c4a322`) |
| `ingestion-file-size-token-ceiling-missing` | Working tree: `maxCharsPerSource` ceiling + truncation + retry + partial-failure surfacing |

## Issues filed this run

**None.** Every verified deviation from vision §1–4 is already represented by an existing slug — either still
`open/` (genuine remaining residuals, several claimed/in-progress by builders) or `closed/` (resolved).
Filing would duplicate. The check log above is the finder's output.

## Summary paragraph (closer-or-deviating)

The next-term vision is **substantially met and closing on all four sections**. The `flutter_to_image`
package is built, documented, unit-tested, and consumed by real golden tests (tutor/mentor/lessons screens
covered; dashboard/planner/practice screen goldens remain); the agentic e2e harness is complete in
fake + opt-in grant-model modes with transcript artifacts, retry-with-backoff, prompt-regression
goldens, full tool-trace coverage, and verdicts for all 11 dry-run scenarios. The prep token economy
is wired end-to-end (IdleExecutor→`enqueuePrepTool`/prep tools declaring est-tokens/CPU-class and
consulting the budget; Settings UI + task-manager budget bars; CPU/battery/quiet-hours/subject
deferral; IdleExecutor token aggregation; prep>live ratio test).

**We are closing, not deviating.** The working tree has resolved four previously-open issues that the
prior report listed as genuinely remaining: `switch_provider` (tool authored, now registered + e2e
traced), `review_mistakes` (tool authored, now registered + e2e traced — but its unit test file
`review_mistakes_tool_test.dart` is still missing per that issue's own solidification criteria),
`read_source_content` (tool authored + registered + unit-tested — but NOT yet in the test's
`registeredToolNames`, so the tool-trace coverage test falsely claims 20/20 when production has 21),
and `ingestion-file-size-token-ceiling-missing` (file-size ceiling + truncation + per-chunk retry/
backoff + partial-failure surfacing all added in working tree).

The only residuals not yet resolved at the capability level:
- `e2e-teaching-missing-explanation-variation-tool`: teaching mode bypasses `AgentLoop` entirely
  (`conversation_manager.dart:292-302` calls `chatStream` directly with no `ToolRegistry`);
  `LessonBlockType` lacks `visual`/`analogy` variants; `explain_differently` + `suggest_practice`
  tools absent.
- 3 top-level-screen golden tests still missing (dashboard, planner, practice).
- Ingestion: `ingestion-revisit-view-missing-no-paged-ux`, `ingestion-dense-page-question-flood-no-cap`,
  `ingestion-media-url-stored-as-content`, `ingestion-no-disambiguation-enrichment-stage`,
  `ingestion-pdf-figures-dropped-no-chart-tool`, `ingestion-long-lecture-asr-unworkable`,
  `ingestion-textbook-chapters-flattened` — untouched by working-tree changes.
- Planner: 4 DST/structural issues (`planner-add-subject-regen-loses-state`,
  `planner-multi-create-averages-durations`, `planner-roadmap-remaining-days-dst-elapsed-arithmetic`,
  `planner-year-plan-scale-single-blob`).
- Practice: `practice-ask-tutor-help-missing`, `practice-review-log-dropped-on-save`.
- Other: `quickguide-chat-tokens-unclassified`, `mentor-empty-user-dead-end-blocks-agent`.

All of the above are tracked by existing open-issue slugs. **Output: no new issues filed — vision holds
(all deviations already tracked).** Twelve open issues are stale-open (code-fixed, working-tree or
committed) and may be closed by a builder via `claim.py close`; two (`review_mistakes_tool_test.dart`
missing, `read_source_content` not in `registeredToolNames`) remain as in-progress completion details
within their own claimed issues' solidification criteria.
