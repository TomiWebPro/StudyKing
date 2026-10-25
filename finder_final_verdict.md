# StudyKing Vision Alignment — Final Finder Verdict

**Role:** `sk-next-finder` (Vision Next-Term §1–4) + `sk-finder` (core `agent_must_read.md`).
**Method:** End-to-end trace of every vision capability against the current working tree (HEAD
`92c0184`); every deviation cross-checked against `issues/open/` and `issues/closed/` before filing.
**No code edited, no commits, no `git add` of issues.**

---

## Capability → closeness verdict (with code evidence)

### Core vision — `agent_must_read.md`

| Capability | Verdict | Evidence |
|---|---|---|
| **Conversational teaching** (teaching mode) | CLOSE | `TutorService` drives `ConversationManager`↔`AgentLoop`; `LlmService.chatStream`, onTokenUsage callback (`conversation_manager.dart:155-164`), `LessonBlockType` incl. `visual`/`analogy` (`enums.dart:41-50`). Lesson record saved on end (`tutor_service.dart:452-460`). |
| **Mentor off-period planning + nudges** | CLOSE | `MentorService.checkWellbeingAndGenerateNudges()` (`mentor_service.dart:460`), proactive `LlmTaskManagerScreen`, `EngagementNudgeRepository` + `MentorSessionRepository`. |
| **Adaptive practice + mastery** | CLOSE | `MasteryGraphService` (`mastery_graph_service.dart:15`), `getWeakTopics`/`getAtRiskQuestions`, spaced-repetition core. |
| **Content ingestion** (PDFs/notes/banks/syllabi/media) | CLOSE | `BulkIngestionService` (`bulk_ingestion_service.dart:276`), chunked extraction, figure-drop issue tracked (`ingestion-pdf-figures-dropped-no-chart-tool.md`, open). File-size ceiling in working tree (`document_extractor.dart:68-73`). |
| **Planner roadmaps + adherence** | CLOSE | `PlannerOrchestrator.checkAdherence`, plan-summary providers, adherence trends tool. |
| **Multi-syllabus tracking** | CLOSE | `dashboardSyllabusBreakdownProvider` (`dashboard_data_providers.dart:428`), `SyllabusSwitcher`, `SyllabusBreakdownCard`, `SyllabusFocusService` (`syllabus_focus_service.dart:16`), `SwitchSyllabusFocusTool` (`switch_syllabus_focus_tool.dart:20`), `getTodayDurationBySubject`. |
| **Token/task transparency** | DRIFTING | `LlmUsageMeter` tracks per feature/taskType/session; `LlmTaskManager` tracks status; `LlmTaskManagerScreen` shows prep-vs-live allocation bars + budget bars. **Gap: `SessionHistoryScreen` never renders `TutorMetadata.totalTokensUsed`** (`session_history_screen.dart:570-692`) — data is accurate & persisted (`conversation_manager.dart:155-164`, `tutor_service.dart:460`, `session_adapter.dart:72,84`) but not surfaced. Covered by **open issue `budget-session-token-visibility.md` (claimed by sk-builder)**. |
| **Proactive engagement / non-silent schedule changes** | CLOSE | Quiet-hours + per-subject opt-in gates (`llm_agent_providers.dart:354-357`), confirmation discipline in mentor scheduling tools. |

### Next-Term vision — `docs/vision_next_term.md`

| Section | Verdict | Evidence |
|---|---|---|
| **§1 Flutter-to-image** | CLOSE | `packages/flutter_to_image/` renders widget→PNG headlessly under `flutter test` (`renderer.dart:58`); unit-tested (renderer 17 + golden_matrix 22 = 39 tests); docs `docs/development/visual-testing.md`; ≥1 golden per top-level screen (8 golden-test files exist: dashboard, planner, tutor, mentor, practice, lessons + 2 sub-widgets); `~/.gitignore` untracks `*.png`. Minor doc-table drift (omits Dashboard/Tutor rows) — not a capability gap. |
| **§2 E2E rigour (grant model)** | DRIFTING → resolving | `test/integration/agentic_e2e/` suite complete: 26 tools traced through real `AgentLoop` (`fakes.dart:128-158`, `tool_trace_coverage_test.dart:1870` asserts `hasLength(26)`); transcript artifacts persisted (`dumpTranscript`/`verifyTranscriptArtifact`); retry-with-backoff (`LlmRetryConfig`+B5 loops); prompt-regression goldens. **Remaining deviation: teaching mode bypasses `AgentLoop`** — `TutorService` calls `LlmService.chatStream()` directly so `explain_differently`/`suggest_practice` are unreachable from teaching conversation (confused-student scenario Step 4 FAIL). Tracked by **closed** `e2e-teaching-missing-explanation-variation-tool.md` + `e2e-teaching-missing-context-injection.md` — not re-filed per §5. |
| **§3 Scenario simulations** | DRIFTING | 11 scenario files in `dry-run-test/` (≥10 acceptance met); `scenario_validation_test.dart` runs PASS/PARTIAL/FAIL + tool/context audit per scenario. **Gap: scenario verdicts in the `.md` files are stale** relative to current code. Tracked by **closed** `scenario-dry-run-stale-assessments.md` (claimed by e2e-scenario-builder). |
| **§4 Prep-heavy token economy** | FRAGILE → DRIFTING | §4.1 primitives: 4 prep tools registered (`IngestPdfToKbTool`, `EnqueueQuestionVariantsTool`, `PreGenerateLessonTool`, `RefreshMasteryTool`, each with `estTokens`+`PrepCpuClass`), `PrepBudget` defaults, `IdleExecutor` budget gate consulted (`idle_executor.dart:230-249`), `prep>live` ratio test (`prep_budget_test.dart:326`). §4.2 UI: Settings PrepBudgetSection + task-manager budget bars. §4.3 `SystemMonitorService.canRunHeavyPrepNow` (`system_monitor_service.dart:26`). **Critical residual gaps (two open issues, 1 newly filed this run):** |
| | | (a) `AgentFactory.create()` calls `idleExecutor.startIdleMonitoring()` (`llm_agent.dart:156`) but **never `init()`** — `idle_tasks` box never opened for the agent's executor; `_persist()` is a no-op (`idle_executor.dart:253-268`); all post-lesson prep tasks vanish on process termination. **Open issue `agent-factory-idle-executor-not-initialized.md` (claimed by sk-solidifier).** |
| | | (b) `AgentFactory.create()` / `llmAgentProvider` (`llm_agent_providers.dart:347`) **never call `setTaskReconstructor`** — even after (a) is fixed, tasks restored from the box have `taskFn == null` (closures can't serialize) and `_tryExecuteNext` drains each as a no-op at `idle_executor.dart:448-460` (marked `isCompleted = true` with zero tokens consumed). The only registered reconstructor handles `pdf_ingestion` only (`bulk_ingestion_service.dart:330`); `lesson_prep`/`background` task types are unhandled. **Open issue `prep-agent-idle-executor-task-reconstructor-missing.md` (NEW — filed this run).** |

---

## Issues filed this run

**One (1) NEW, verified gap:** `issues/open/prep-agent-idle-executor-task-reconstructor-missing.md`
— `AgentFactory.create()` calls `startIdleMonitoring()` but never
`setTaskReconstructor`, so post-lesson prep tasks (adherence check, weak-topic
reanalysis, next-topic lesson pre-generation enqueued by `TutorService.endLesson()`
at `tutor_service.dart:514-518`/`521-538`/`541-557`/`647-661`) are silently drained
as no-ops on restore. This is NOT subsumed by the `init()` open issue (that one
ensures tasks *persist*; this one ensures restored tasks *execute*).

Cross-referenced: the remaining 2 open issues pre-date this run and are in-progress
(claimed by builders). Every other deviation from §1–4 is already represented by an
existing slug in `open/` or `closed/` — no re-filing per §5 doctrine.

## Minor FRAGILE items (not filed — infrastructure, not vision-breaking)

- `LlmTaskManager.init()` and `LlmUsageMeter.init()` are fire-and-forget (unawaited) in
  `llm_providers.dart:14,20`; boxes are small and the app is usually initialized before
  first LLM use — a minor race, no existing closed issue flags it specifically.
- `failures/` at repo root (40 golden-diff PNGs) is not gitignored (goldens themselves
  are properly gitignored via `test/goldens/.gitignore` at line `*.png`).
- `.env.example` now documents `STUDYKING_E2E_MODEL`/`_BASE_URL` (lines 54-57) — the
  prior `e2e-env-example-missing-e2e-model-vars.md` issue is therefore **closed** (in
  `issues/closed/`), confirmed not re-filed.

## Verdict: DRIFTING on §2, §3, and §4 — but not deviating

The platform is **substantially ahead** of the next-term vision: the `flutter_to_image`
package is built, documented (39 tests), and consumed by 8 golden-test files covering
all 6 top-level screens; the agentic E2E harness exercises all 26 registered tools
through the real `AgentLoop` with transcript artifacts, retry-with-backoff, and
prompt-regression goldens; 11 scenarios run with tool/context audits; and the prep
token economy is wired end-to-end (IdleExecutor → 4 prep tools with est-tokens/CPU-class →
PrepBudgetService.canSpend → Settings UI + task-manager budget bars →
SystemMonitorService CPU-aware deferral → prep>live ratio test).

The residual gaps are all **known, tracked, and in-progress**: the two open
prep-economy issues (IdleExecutor `init()` missing + `setTaskReconstructor` missing —
the latter freshly filed this run) are the single real blocker to the §4.4
"survive app termination + resume execution" acceptance criterion; token transparency is
one open issue (`budget-session-token-visibility.md`, claimed) from complete; teaching-mode
AgentLoop bypass is tracked by closed issues per §5. Vision is **closing on every section**;
the only genuine *new* deviation from §4.2 ("the polling timer resumes and executes them")
is the task-reconstructor gap filed here.

**One new issue filed. No convention-only or crash-only issues.**
