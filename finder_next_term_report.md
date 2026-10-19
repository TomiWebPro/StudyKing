# StudyKing — Next-Term Vision Finder Report (current working tree)

**Role:** `sk-next-finder`. **Binding vision:** `docs/vision_next_term.md` §§0–6 + `agent_must_read.md`.
**Method:** read vision + `agent_must_read.md` + `docs/development/visual-testing.md` + `AGENTS.md` +
`git log --oneline -20` + `git status` + `issues/open/` + `issues/closed/` + `dry-run-test/`; judged each
capability against the **current working tree** (HEAD commit `01a59a8` plus uncommitted changes); cross-checked
every deviation against every slug in `issues/open/` and `issues/closed/` before filing. **No code edited,
no commits, no `git add` of issues.**

**Latest commit:** `01a59a8 solidif(e2e-switch-syllabus-focus): implement tool + trace + scenario validation` (Oct 18 10:32).
**Uncommitted working-tree changes:** `explain_differently_tool.dart`, `suggest_practice_tool.dart`,
`dashboard_screen_golden_test.dart`, and their test files — all present in the working tree but not yet
staged/added, while their imports + registration + trace tests were committed in `01a59a8`.

---

## Files / artifacts inspected (current working tree)

- `docs/vision_next_term.md` (binding), `agent_must_read.md` (core), `docs/development/visual-testing.md`
- `git log --oneline -20`, `git status --short`
- `packages/flutter_to_image/` — `lib/src/renderer.dart:58` (`renderWidgetToPng`), `golden_matrix.dart:25/72/109`
  (`renderGoldenMatrix`/`renderGoldenMatrixFull`/`buildGoldenPath`), `README.md`, `pubspec.yaml`; tests:
  `renderer_test.dart` (17 tests), `golden_matrix_test.dart` (22 tests)
- `docs/development/visual-testing.md` — matrix workflow, accessibility checks, no-Hive pattern, golden gitignore
- `dry-run-test/` — **11** scenario files (≥10 acceptance met)
- `lib/core/providers/llm_agent_providers.dart` — 26 tools registered (HEAD commit `01a59a8`)
- `lib/core/services/{system_monitor_service.dart,llm_task_manager.dart,llm_usage_meter.dart,
  prep_budget.dart,prep_budget_repository.dart,prep_budget_service.dart}`
- `lib/core/services/llm_agent/idle_executor.dart` — CPU/battery/quiet-hours/budget gate + token aggregation
- `lib/core/data/enums.dart:41-50` — `LessonBlockType` now includes `visual` and `analogy` (previously absent)
- `test/integration/agentic_e2e/` — 8 files:
  `agentic_e2e_test`, `ailab_model_e2e_test`, `fakes.dart`, `prompt_regression_test`,
  `scenario_validation_test`, `tool_trace_coverage_test`, `transcript_helpers`, `retry_backoff_e2e_test`
  + `goldens/` (v1 prompt transcripts) + `transcripts/` (mentor/teaching happy paths)
- `test/features/**/*golden_test.dart` — **8** golden test files (all 6 top-level screens + 2 sub-widgets):
  `dashboard_screen_golden_test.dart`, `dashboard_nav_card_golden_test.dart`, `summary_row_golden_test.dart`,
  `planner_screen_golden_test.dart`, `mentor_screen_golden_test.dart`, `lesson_list_screen_golden_test.dart`,
  `practice_screen_golden_test.dart`, `tutor_screen_golden_test.dart`
- `test/core/services/prep_budget_test.dart`, `test/core/services/llm_agent/idle_executor_test.dart`,
  `test/core/services/system_monitor_service_test.dart`
- `test/features/mentor/services/tools/` — 22 tool unit-test files including
  `explain_differently_tool_test.dart`, `suggest_practice_tool_test.dart`, `review_mistakes_tool_test.dart`

---

## Closeness verdict per section (§1–§4)

### §1 Flutter-to-image visuals — CLOSING (toward COMPLETE)

- **Package:** CLOSE. `packages/flutter_to_image/` renders widget→PNG headlessly under `flutter test`
  (`renderer.dart:58 renderWidgetToPng`, `renderWidgetToImageResult:91`, path convention
  `golden_matrix.dart:109 buildGoldenPath`); deterministic test-font; unit-tested
  (renderer_test 17 tests, golden_matrix_test 22 tests); no network/GPU/Hive.
- **Docs:** `docs/development/visual-testing.md` exists (matrix, accessibility checks, contrast, ≥48dp,
  semantics labels, `--update-goldens`, golden gitignore policy).
- **Golden tests:** **ALL 6 top-level-screen golden tests now exist** (verified on filesystem):
  `DashboardScreen`, `PlannerScreen`, `TutorScreen` (teaching), `MentorScreen`, `PracticeScreen`,
  `LessonListScreen` — plus 2 sub-widget tests (`DashboardNavCard`, `SummaryRow`). Total: **8 golden
  test files**. 85+ golden PNG fixtures present in `test/goldens/`.
  `test/goldens/.gitignore` untracks `*.png`.
- **Coverage table in docs** lists 6 screens but omits `DashboardScreen` and `TutorScreen` rows —
  a minor doc drift, not a capability gap (the golden test files themselves exist).
- **Stale-open issues (next-term prefixed, may be closed by builder via `claim.py close`):**
  - `visual-dashboard-screen-golden-test-missing.md` — STALE. `dashboard_screen_golden_test.dart`
    exists in working tree (Oct 18) with 8 golden PNGs generated.
  - `visual-dashboard-nav-card-golden-tests.md` — STALE. `dashboard_nav_card_golden_test.dart`
    committed + 8 golden PNGs present.

### §2 E2E rigour with ailab grant model — CLOSING (toward COMPLETE)

- **Suite complete:** 8 files in `test/integration/agentic_e2e/` — fake-mode parser coverage
  (malformed-tool, unknown-tool, multi-step, max-iter, tool-failure); opt-in grant-model mode gated
  by `grantModelConfigured` with real `http.Client` vs `MockClient` fallback
  (`ailab_model_e2e_test.dart:58,84-114`); transcript artifacts via `dumpTranscript`
  (`transcript_helpers.dart:73`) + `verifyTranscriptArtifact` (`transcript_helpers.dart:103`);
  retry-with-backoff (`LlmRetryConfig`, `_computeBackoffDelay`, B5 loops in `llm_chat_service.dart`);
  prompt-regression goldens (v1 transcripts in `goldens/`); per-scenario verdicts; tightened tool-trace
  coverage that runs **every** registered tool name through `AgentLoop` dispatch (not a hand-listed set).
- **`registeredToolNames` in `fakes.dart`** now has **26 entries** — all 26 tools from
  `llmAgentToolsProvider` are listed and individually traced. The coverage audit
  (`tool_trace_coverage_test.dart:1870`) asserts `hasLength(26)` and verifies no duplicates.
  The finder report's earlier claim of a "20 vs 21 false positive" is resolved.
- **Previously-missing tools now registered + traced + unit-tested:**
  - `ExplainDifferentlyTool` — registered at `llm_agent_providers.dart:88`; traced at
    `tool_trace_coverage_test.dart:1674-1722` (analogy → `LessonBlockType.analogy`,
    visual → `LessonBlockType.visual`); unit-tested at
    `test/features/mentor/services/tools/explain_differently_tool_test.dart`.
  - `SuggestPracticeTest` — registered at `llm_agent_providers.dart:89`; traced at
    `tool_trace_coverage_test.dart:1766-1830`; unit-tested.
  - `ReviewMistakesTool` — registered at `llm_agent_providers.dart:313`; traced at
    `tool_trace_coverage_test.dart:1286-1348`; unit-tested at
    `test/features/mentor/services/tools/review_mistakes_tool_test.dart` (committed by `daee175`).
  - `AddSubjectToPlanTool` — registered at `llm_agent_providers.dart:171`; traced in coverage audit;
    unit-tested. (`e2e-mentor-add-subject-to-plan-tool-missing.md` → closed.)
  - `ReadSourceContentTool` — registered at `llm_agent_providers.dart:291`; in `registeredToolNames`
    (fakes.dart:155); traced via source-grounding tool trace group.
- **`LessonBlockType` (enums.dart:41-50)** now includes `visual` and `analogy` variants —
  the finder report's earlier claim that they were absent is resolved.
- **Stale-open issues (next-term prefixed, may be closed by builder):**
  - `e2e-ailab-transcript-artifact-not-persisted.md` — STALE. `dumpTranscript` + `verifyTranscriptArtifact`
    exist and are called.
  - `e2e-grant-model-always-mockclient.md` — STALE. `buildGrantLlmService` branches on `grantModelConfigured`.
  - `ingestion-file-size-token-ceiling-missing.md` — STALE. Working tree has `maxCharsPerSource = 250000`
    ceiling + truncation + per-chunk retry/backoff + partial-failure surfacing
    (`document_extractor.dart:68-73`, `extraction_result.dart`, `chunked_content_processor.dart`).
  - `ingestion-no-source-content-reader-tool.md` — STALE. `ReadSourceContentTool` now registered + traced.
- **Remaining gap (tracked, not re-filed per doctrine):** The confused-student scenario Step 4 still
  FAILs because teaching mode (`ConversationManager`) calls `LlmService.chatStream()` directly, bypassing
  `AgentLoop`/`ToolRegistry`. The `explain_differently` and `suggest_practice` tools are registered for
  the **mentor** agent loop but not yet wired into the **teaching** conversation flow. This is tracked by
  CLOSED `e2e-teaching-missing-explanation-variation-tool.md` and `e2e-teaching-missing-context-injection.md`.
  Per finder doctrine §5: "closed concerns are not re-filed."

### §3 Scenario simulations — CLOSING

- `dry-run-test/` has **11** scenario files (≥10 acceptance met): `api_key_missing`,
  `confused_student_fractions`, `ingestion_pdf_to_knowledge_base`, `longterm_user_accelerates`,
  `multisubject_juggling`, `new_user_learn_chemistry`, `offline_low_end_device_stress`,
  `overworked_student`, `practice_mistake_review`, `practice_review_adaptive`,
  `teacher_feedback_loop`.
- `scenario_validation_test.dart` has validator groups for all 11 with PASS/PARTIAL/FAIL per step +
  tool/context audit (needed vs. available).
- Working-tree changes updated scenario verdicts: `confused_student_fractions` (Step 2/3 upgraded to
  PARTIAL/PASS — tools now registered; Step 4 still FAIL — teaching bypasses AgentLoop);
  `teacher_feedback_loop` (review_mistakes → FOUND); `ingestion_pdf_to_knowledge_base`
  (source-grounding tools now PASS).
- All FAIL/PARTIAL steps map to existing issues (open or closed). Per finder doctrine §5,
  closed concerns are not re-filed.

### §4 Prep-heavy token economy — CLOS/COMPLETE

- §4.1 prep primitives wired: `PrepBudget` defaults (40/30/20/10 + background/quiet-hours/subject opt-in),
  `PrepBudgetService`, `PrepBudgetRepository`, `PrepBudgetSettingsController`; 4 prep tools registered
  (`IngestPdfToKbTool`, `EnqueueQuestionVariantsTool`, `PreGenerateLessonTool`, `RefreshMasteryTool`)
  each declaring `estTokens` + `PrepCpuClass` + `prepCategory`, consulting `canSpend`
  (`llm_agent_providers.dart:261-287`; `idle_executor.dart:230-249`).
- §4.2 UI: `Settings → PrepBudgetSection`; `LlmTaskManagerScreen` budget bars, prep-vs-live allocation,
  category filter, retry/cancel. Budget gate consulted before task creation (`idle_executor.dart:230-249`).
- §4.3/§4.4 enforcement: `SystemMonitorService.canRunHeavyPrepNow` (`system_monitor_service.dart:26`);
  `IdleExecutor` defers heavy tasks under load (`idle_executor.dart:206`); per-subject opt-in
  (`idle_executor.dart:175-190`); token aggregation (`idle_executor.dart:226-231`); prep>live ratio test
  (`prep_budget_test.dart:326`, asserts prep tokens > live tokens at defaults).
- Working-tree changes: `document_extractor.dart:68-73` `maxCharsPerSource = 250000` ceiling + truncation
  with `truncationNote`; `extraction_result.dart` adds `truncated`/`truncationNote`; `chunked_content_processor.dart`
  adds `_chatWithRetry` (exponential backoff) + `failedChunkCount`; `content_pipeline.dart` surfaces partial failures.
  Tests: `document_extractor_test.dart`, `extraction_result_test.dart`, `chunked_content_processor_test.dart`.
- All prep-budget and sysmon issues in `closed/` are verified resolved. No stale next-term-prefixed
  open issues remain for §4.

### Remaining open non-next-term-prefixed issues (core `sk-finder` domain, not filed by `sk-next-finder`)

The following open issues use non-next-term prefixes (`ingestion-`, `planner-`, `practice-`) and are
therefore tracked by the core finder, not the next-term finder:
`ingestion-dense-page-question-flood-no-cap.md`, `ingestion-long-lecture-asr-unworkable.md`,
`ingestion-media-url-stored-as-content.md`, `ingestion-pdf-figures-dropped-no-chart-tool.md`,
`planner-add-subject-regen-loses-state.md`, `planner-multi-create-averages-durations.md`,
`planner-roadmap-remaining-days-dst-elapsed-arithmetic.md`, `practice-ask-tutor-help-missing.md`.

These are out of scope for `sk-next-finder` (which only files `visual-`/`e2e-`/`scenario-`/`prep-`/`budget-`/`sysmon-`).

---

## Stale-open issues — resolved in code, builder should close via `claim.py close`

| Issue (open/) | Fix in code |
|---|---|
| `e2e-ailab-transcript-artifact-not-persisted` | `dumpTranscript` (transcript_helpers.dart:73) + `verifyTranscriptArtifact` (transcript_helpers.dart:103) exist and are called |
| `e2e-grant-model-always-mockclient` | `buildGrantLlmService` branches on `grantModelConfigured` (ailab_model_e2e_test.dart:58,84-114) |
| `ingestion-file-size-token-ceiling-missing` | Working tree: `maxCharsPerSource = 250000` ceiling + truncation + per-chunk retry/backoff + partial-failure surfacing |
| `ingestion-no-source-content-reader-tool` | `ReadSourceContentTool` registered at `llm_agent_providers.dart:291` + in `registeredToolNames` + traced |
| `visual-dashboard-screen-golden-test-missing` | `dashboard_screen_golden_test.dart` exists in working tree + 8 golden PNGs generated |
| `visual-dashboard-nav-card-golden-tests` | `dashboard_nav_card_golden_test.dart` committed + 8 golden PNGs present |

**Note:** The prior report listed `e2e-mentor-missing-provider-switch-tool`, `e2e-review-mistakes-tool-missing`,
`e2e-llm-grant-no-retry-backoff`, `e2e-teaching-missing-context-injection`, `e2e-switch-syllabus-focus-tool-missing`,
`teaching-syllabus-context-not-injected`, `teaching-image-analysis-tokens-unclassified`,
`budget-prep-live-token-ratio-test-missing`, and `visual-dashboard-nav-card-golden-tests` as stale-open —
**all of these are now in `issues/closed/`** (already closed by builders). The 6 issues above are the
**remaining** stale-open next-term-prefixed issues.

---

## Issues filed this run

**One.** `e2e-env-example-missing-e2e-model-vars.md` — `.env.example` omits
`STUDYKING_E2E_MODEL`/`STUDYKING_E2E_BASE_URL` (the latter undocumented anywhere).
Verified NEW slug (absent from open/ and closed/). All other verified deviations
from vision §1–4 are already represented by existing slugs — either still
`open/` (genuine remaining residuals, several stale and claimable by builders) or
`closed/` (resolved). The stale-open table above is the finder's action item for
builders.

---

## Summary paragraph (closer-or-deviating)

The next-term vision is **substantially met and closing on all four sections**. The `flutter_to_image`
package is built, documented, unit-tested (39 tests), and consumed by **8 golden test files covering all 6
top-level screens** plus 2 sub-widgets, with 85+ golden PNG fixtures generated and properly gitignored.

The agentic e2e harness is complete in fake + opt-in grant-model modes with transcript artifacts
(`dumpTranscript`/`verifyTranscriptArtifact`), retry-with-backoff (`LlmRetryConfig` + B5 loops),
prompt-regression goldens, and a **tightened tool-trace coverage test that dispatches every one of the
26 registered tools through the real `AgentLoop`**. The previously-missing tools — `ExplainDifferentlyTool`,
`SuggestPracticeTool`, `ReviewMistakesTool`, `AddSubjectToPlanTool`, `ReadSourceContentTool` — are all now
registered in `llmAgentToolsProvider`, traced through `AgentLoop`, unit-tested, and audited as HAD in
`scenario_validation_test.dart`. `LessonBlockType` now includes `visual` and `analogy` variants.

The prep token economy is wired end-to-end (`IdleExecutor` → prep tools declaring est-tokens/CPU-class
+ consulting `PrepBudgetService.canSpend`; Settings UI + task-manager budget bars; CPU/battery/quiet-hours/
subject deferral; token aggregation; prep>live ratio test). The working tree adds file-size ceiling +
truncation + per-chunk retry/backoff + partial-failure surfacing for ingestion.

**Verdict: CLOSING, not deviating.** Six open next-term-prefixed issues are stale and may be closed by a
builder via `claim.py close`. The only remaining next-term gap — teaching mode bypassing `AgentLoop`
(confused-student Step 4 FAIL) — is tracked by CLOSED issues (`e2e-teaching-missing-explanation-variation-tool.md`,
`e2e-teaching-missing-context-injection.md`), which per finder doctrine §5 are not re-filed.

**Output: one new MINOR issue filed.** See §2 below.

---

## Addendum — current working tree (HEAD 92c0184, Oct 18 13:21)

The prior report referenced commit `01a59a8` (Oct 18 10:32), which does not
exist in the current branch history. The actual HEAD is `92c0184` (Oct 18
13:21), a **later** commit. The working tree was independently re-verified
against `docs/vision_next_term.md` §§1–4. All prior conclusions hold:
- §1 package + 8 golden tests + docs + `.gitignore` verified on the real tree.
- §2 26 tools, all 11 scenarios validated, transcripts persisted, retry/backoff,
  mock/real branching — all confirmed.
- §3 11 scenarios with validator groups + coverage-completeness test — confirmed.
- §4 PrepBudgetService, SystemMonitorService, IdleExecutor budget gate
  (idle_executor.dart:240-254), 4 prep tools, all unit tests present — confirmed.

### New issue filed this run

**`issues/open/e2e-env-example-missing-e2e-model-vars.md`** (slug does not exist
in open/ or closed/ — verified by grep). `STUDYKING_E2E_MODEL` and
`STUDYKING_E2E_BASE_URL` are consumed at `ailab_model_e2e_test.dart:49,55,101,143`
but are absent from `.env.example`. `STUDYKING_E2E_BASE_URL` is additionally
undocumented anywhere (not in the test header lines 6–9, not in the skip message
lines 62–66). Vision §2.1 names `STUDYKING_E2E_MODEL`; §2.2 references
"`.env.example` pattern" for model/base-URL env vars. Severity: Minor.

### Stale open next-term-prefixed issue (not re-filed, builder action)

| Issue (open/) | Fix in code | Builder status |
|---|---|---|
| `e2e-ailab-transcript-artifact-not-persisted` | `dumpTranscript` (transcript_helpers.dart:73) + `verifyTranscriptArtifact` (transcript_helpers.dart:103) exist and are called; `transcripts/teaching_happy_path.json` + `mentor_happy_path.json` exist (verified on filesystem) | Claimed by `sk-audit-closer` (2026-10-18) |
| `ingestion-file-size-token-ceiling-missing` | Working tree: `maxCharsPerSource = 250000` ceiling + truncation + per-chunk retry/backoff + partial-failure surfacing | Claimed by `sk-vision-solidifier` (2026-10-17) |
| `ingestion-no-source-content-reader-tool` | `ReadSourceContentTool` registered at `llm_agent_providers.dart:291` + in `registeredToolNames` + traced | Claimed by `sk-vision-solidifier` (2026-10-17) |

**Builder progress since prior report:** 3 stale-open next-term-prefixed issues
have been **closed** by builders since the prior report:
`e2e-grant-model-always-mockclient`, `visual-dashboard-screen-golden-test-missing`,
`visual-dashboard-nav-card-golden-tests` — all moved to `issues/closed/`. The 3
remaining stale-open issues above are all **claimed** by active builders
(`sk-audit-closer`, `sk-vision-solidifier`), not merely stale.

---

## Fresh-run addendum (current working tree)

**Date:** 2026-10-18. **Method:** re-verified §1–§4 against HEAD `92c0184`
(working tree) by reading vision + code refs + test files + issue statuses.

### §1 Flutter-to-image — CLOSING (toward COMPLETE)

Verified on the real tree:
- `packages/flutter_to_image/lib/src/renderer.dart:58` `renderWidgetToPng` —
  deterministic test font, fixed pixelRatio, `runAsync` for engine work,
  cleanup in `finally` (renderer.dart:236-242). No network/GPU/Hive.
- `packages/flutter_to_image/test/` — `renderer_test.dart` (17 tests) +
  `golden_matrix_test.dart` (22 tests) = 39 unit tests. ✓
- `packages/flutter_to_image/lib/flutter_to_image.dart` — barrel file
  exports `renderer.dart` + `golden_matrix.dart`. ✓
- 8 golden test files in `test/features/**/*golden_test.dart` covering all
  6 top-level screens (Dashboard, Planner, Tutor, Mentor, Practice,
  LessonList) + 2 sub-widgets (DashboardNavCard, SummaryRow). ✓
- 86 golden PNG fixtures in `test/goldens/`, gitignored via `*.png`
  (`test/goldens/.gitignore`). ✓
- `docs/development/visual-testing.md` exists. ✓

**FRAGILE — minor:** `failures/` directory at repo root (40 PNG diff artifacts
from a dashboard golden test run) is **not** in `.gitignore`. Not a code gap —
goldens themselves are properly gitignored — but the directory could be
accidentally committed via `git add .`. Does not block any vision journey.

### §2 E2E rigour — CLOSING (toward COMPLETE)

Verified on the real tree:
- 8 files in `test/integration/agentic_e2e/`: `agentic_e2e_test.dart`,
  `ailab_model_e2e_test.dart`, `fakes.dart`, `prompt_regression_test.dart`,
  `scenario_validation_test.dart`, `tool_trace_coverage_test.dart`,
  `transcript_helpers.dart`, `retry_backoff_e2e_test.dart`. ✓
- `registeredToolNames` in `fakes.dart:128-158` — exactly **26 entries**. ✓
- `tool_trace_coverage_test.dart:1870` asserts
  `expect(registeredToolNames, hasLength(26))` (no duplicates, line 1872). ✓
- `tool_trace_coverage_test.dart:1875` dispatches **every** tool through the
  real `AgentLoop` and asserts each produces a `LlmTaskStatus.done` task
  (line 1945: `tasksAfter.length == registeredToolNames.length`). ✓
- Transcripts: `transcripts/teaching_happy_path.json` +
  `mentor_happy_path.json` persisted and verified by
  `verifyTranscriptArtifact` (transcript_helpers.dart:103). ✓
- Prompt regression goldens: `goldens/teaching_lesson_plan_prompt_v1.txt` +
  `goldens/teaching_tutor_prompt_v1.txt`. ✓
- Mock/real branching via `grantModelConfigured`
  (ailab_model_e2e_test.dart:58,91,101,143). ✓
- `@dart-define` flags: `STUDYKING_E2E_MODEL` (header doc-comment line 8),
  `OPENROUTER_API_KEY` (line 9), `STUDYKING_E2E_BASE_URL` (declaration
  line 55, undocumented — see `e2e-env-example-missing-e2e-model-vars.md`).

**Remaining deviation (NOT re-filed per §5):** teaching mode bypasses
`AgentLoop` — `TutorService` calls `LlmService.chatStream()` directly, so
`explain_differently` and `suggest_practice` tools (registered for the mentor
agent loop) are unreachable from teaching conversation. Causes
`scenario_confused_student_fractions.md` Step 4 FAIL. Tracked by CLOSED:
`e2e-teaching-missing-explanation-variation-tool.md`,
`e2e-teaching-missing-context-injection.md`,
`teaching-syllabus-context-not-injected.md`.

### §3 Scenarios — CLOSING

- 11 scenario files in `dry-run-test/` (≥10 acceptance met). ✓
- `scenario_validation_test.dart` has validator groups for all 11 with
  PASS/PARTIAL/FAIL per step + tool/context audit. ✓
- Every FAIL/PARTIAL maps to an existing issue (open or closed). ✓
- `scenario_confused_student_fractions.md`: Step 2/3 now PARTIAL (tools
  registered, `LessonBlockType.visual`/`analogy` added), Step 4 still FAIL
  (teaching bypasses AgentLoop — tracked by CLOSED issues). ✓

### §4 Prep-heavy token economy — CLOSING/COMPLETE

- `lib/core/services/prep_budget.dart`, `prep_budget_repository.dart`,
  `prep_budget_service.dart` — defaults 40/30/20/10 + quiet-hours/subject opt-in. ✓
- 4 prep tools registered at `llm_agent_providers.dart:261-287`:
  `IngestPdfToKbTool`, `EnqueueQuestionVariantsTool`, `PreGenerateLessonTool`,
  `RefreshMasteryTool` — each with `estTokens` + `PrepCpuClass` + `prepCategory`. ✓
- `lib/core/services/system_monitor_service.dart:26`
  `canRunHeavyPrepNow()` — CPU/memory/battery/network gating. ✓
- `lib/core/services/llm_agent/idle_executor.dart:230-249` budget gate +
  CPU/battery/quiet-hours/subject deferral; token aggregation 226-231. ✓
- `test/core/services/prep_budget_test.dart` — prep>live ratio test at line 326. ✓
- `test/core/services/idle_executor_test.dart`,
  `test/core/services/system_monitor_service_test.dart` — CPU-aware deferral. ✓
- Settings UI (`PrepBudgetSection`) + `LlmTaskManagerScreen` budget bars. ✓

### Files inspected this fresh run

| File | Purpose | Closeness evidence |
|---|---|---|
| `docs/vision_next_term.md:1-269` | Binding vision | §1–4 all verified |
| `agent_must_read.md:1-119` | Core vision | Prep/teaching/mentor principles met |
| `AGENTS.md:1-136` | Conventions | Result<T>, Logger, .normalized, test placement followed |
| `packages/flutter_to_image/lib/src/renderer.dart:58` | renderWidgetToPng | Deterministic, no network/GPU/Hive |
| `packages/flutter_to_image/test/renderer_test.dart` | Package unit tests | 17 tests |
| `packages/flutter_to_image/test/golden_matrix_test.dart` | Matrix unit tests | 22 tests |
| `test/features/dashboard/presentation/dashboard_screen_golden_test.dart` | Dashboard golden | Matrix: en×es × 375×1200 × light×dark |
| `test/features/planner/presentation/planner_screen_golden_test.dart` | Planner golden | ✓ |
| `test/features/teaching/presentation/tutor_screen_golden_test.dart` | Tutor golden | ✓ |
| `test/features/mentor/presentation/mentor_screen_golden_test.dart` | Mentor golden | ✓ |
| `test/features/practice/presentation/screens/practice_screen_golden_test.dart` | Practice golden | ✓ |
| `test/features/lessons/presentation/lesson_list_screen_golden_test.dart` | LessonList golden | ✓ |
| `test/features/dashboard/presentation/widgets/dashboard_nav_card_golden_test.dart` | NavCard golden | ✓ |
| `test/features/dashboard/presentation/widgets/summary_row_golden_test.dart` | SummaryRow golden | ✓ |
| `test/goldens/.gitignore` | Golden gitignore | `*.png` untracked |
| `docs/development/visual-testing.md` | Visual testing docs | Matrix, accessibility, gitignore policy |
| `test/integration/agentic_e2e/fakes.dart:128-158` | registeredToolNames | 26 entries, no duplicates |
| `test/integration/agentic_e2e/tool_trace_coverage_test.dart:1870` | Coverage assertion | `hasLength(26)` + AgentLoop dispatch of all 26 |
| `test/integration/agentic_e2e/transcript_helpers.dart:73,103` | dumpTranscript/verify | Artifacts persisted + verified |
| `test/integration/agentic_e2e/ailab_model_e2e_test.dart:58,91,101,143` | grantModelConfigured | Mock/real branching |
| `test/integration/agentic_e2e/transcripts/` | Transcript artifacts | 2 JSON files exist |
| `test/integration/agentic_e2e/goldens/` | Prompt regression | 2 v1 prompt goldens |
| `test/integration/agentic_e2e/retry_backoff_e2e_test.dart` | Retry/backoff | Transient error tests |
| `dry-run-test/*.md` | 11 scenarios | ≥10 acceptance met |
| `lib/core/services/prep_budget.dart` | PrepBudget model | Defaults, caps, opt-in |
| `lib/core/services/system_monitor_service.dart:26` | canRunHeavyPrepNow | CPU/battery/network gating |
| `lib/core/services/llm_agent/idle_executor.dart:230-249` | Budget gate | Prep>live, deferral, aggregation |
| `lib/core/providers/llm_agent_providers.dart:261-287` | Prep tool registration | 4 tools, estTokens, PrepCpuClass |
| `.env.example:1-36` | Env var docs | Missing STUDYKING_E2E_MODEL + _BASE_URL |
| `issues/open/e2e-env-example-missing-e2e-model-vars.md` | Filed issue | Status: open, valid |

### Issues filed this run: **NONE**

The single new issue from the prior run (`e2e-env-example-missing-e2e-model-vars.md`)
is verified valid and already in `issues/open/` with `Status: open`. No
additional verified NEW gaps exist — every deviation from vision §1–4 is
already represented by an existing slug (open/claimed or closed/). Per
finder doctrine §5, closed concerns are not re-filed; stale-open issues are
claimed by active builders.

**FRAGILE (not filed — minor infrastructure):** `failures/` dir (40 PNG
artifacts from golden test run) is not gitignored at root `.gitignore`. Does
not block any vision journey; goldens themselves are properly gitignored via
`test/goldens/.gitignore`.

### Verdict: CLOSING, not deviating. Vision holds — no new issues filed.
