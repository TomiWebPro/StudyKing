# StudyKing — Next-Term Vision (Further Vision)

> Companion to `agent_must_read.md` (core product vision).
> This file defines **next-term goals**: where the majority of LLM tokens,
> e2e rigour, and agent tooling must go next. Builders and finders should
> treat this as binding product direction alongside `AGENTS.md` conventions
> (`Result<T>`, `static final` Logger, `.normalized`, locale-aware numbers,
> test-placement table, hand-written fakes, `Status: open` issue protocol).

## 0. Thesis

Live lesson rendering / on-the-spot discussion is **not enough**.
The system wins by **preparing** — during off-periods — so that scheduled
lessons start with rich, validated, personalised material already built.

**Token principle:** preparation of courses must take the **majority of
tokens**, not live chat. Students must be able to see and steer where
tokens go.

---

## 1. Flutter-to-image package for visual UI tests

**Goal:** a small, continuously-developed Dart/Flutter package that renders
any StudyKing UI element to an image (PNG) headlessly, so tests and agents
can *see* the UI and optimise it.

Why: widget tests today assert `findsOneWidget` but never judge visual
quality — overflow, contrast, density, hierarchy, stale-l10n, desktop
width. Agents need pixels to improve pixels.

### 1.1 What to build

- New package, e.g. `packages/flutter_to_image/` (or `tool/flutter_to_image/`
  if a separate pub package is overkill — decide once, document in README):
  - `renderWidgetToPng(Widget, {size, pixelRatio, locale, themeMode, textScale})`
    → `Uint8List` PNG, no emulator, works under `flutter test`.
  - Helpers: `renderScreenToPng`, multi-locale matrix (`en`/`es`), light/dark,
    phone/desktop widths, text-scale sweep.
  - Deterministic: seeded, font-stable, golden-friendly; output path
    convention `test/goldens/<screen>_<locale>_<width>.png`.
- Integration into StudyKing:
  - At least one golden/visual test per top-level screen (dashboard,
    planner, teaching, mentor, practice, lessons) using the package.
  - Docs: `docs/development/visual-testing.md` — when to add a golden,
    how to regenerate (`--update-goldens`), CI thresholds, accessibility
    checks (contrast, touch-target ≥48dp, semantics labels).
  - Agent loop: visual diffs are attached to issues (`expected vs actual`
    PNG + diff) so future UI work can be judged visually.

### 1.2 Acceptance criteria (for issues)

- Package renders a representative screen to PNG in `flutter test` without
  network/GPU; unit-tested itself (sizes, locales, themes).
- No Hive I/O in visual tests — use `fixedStudentId` + fakes per `AGENTS.md`.
- Goldens are untracked or explicitly versioned — decide and enforce via
  `.gitignore` + docs (no 100MB PNG dumps in git).
- Finder issues must cite `file:line` of the untested screen/widget and
  propose the exact golden matrix to add.

---

## 2. E2E rigour with ailab grant model — agentic behaviour + prompt optimisation

**Goal:** graduate `test/integration/e2e_test.dart` from fake-LLM smoke
tests to **agentic behaviour** tests that justify the ailab grant.

Current gap: `_IntegrationFakeLlmService` yields canned strings; it never
exercises `AgentLoop` think→act→observe, tool calls, prompt quality, or
failure modes. Grant compute must be spent on exactly that.

### 2.1 What to build

- `test/integration/agentic_e2e/` suite (separate from unit/widget files
  per `AGENTS.md`):
  - Scenario-driven: plan → schedule → teach → practice → nudge, end to end.
  - LLM-backed mode (opt-in via env, e.g. `STUDYKING_E2E_MODEL`, default off
    in CI): runs real prompts against the ailab grant model; records
    transcripts, tool-call traces, token counts.
  - Fake mode (default CI): deterministic fakes that still exercise the
    `AgentLoop` parser (`TOOL_CALL:`/`ARGUMENTS:`), including malformed-tool,
    unknown-tool, and multi-step sequences.
  - Prompt-regression harness: each prompt template has version + golden
    transcript; diffs on prompt change require explicit re-baselining with
    reviewer note (optimise prompts deliberately, not by drift).
- Harness rules:
  - Never commit keys. Model/base-URL come from `--dart-define`/env
    (see `.env.example` pattern); missing key → clear skip message, not crash.
  - Token/cost of every e2e LLM call goes through `LlmUsageMeter` +
    `LlmTaskManager` so grant spend is auditable.
  - Flaky-network resilient: retry with backoff, timeout per step,
    `CHECK: PASS/FAIL` style verdict per scenario.

### 2.2 Acceptance criteria

- `flutter test test/integration/` passes offline (fake mode) with zero keys.
- With grant model configured, at least the teaching + mentor happy paths
  run against the real model and produce a transcript artifact.
- Every agent tool (`CreatePlanTool`, `ScheduleLessonTool`, …) has an e2e
  trace proving it is reachable from a realistic student utterance.

---

## 3. Scenario simulations — can the student understand the agent? Does the LLM have enough?

**Goal:** systematically simulate student journeys and answer two questions:

1. Would a real student **encounter difficulty understanding** the agent
   (confusing replies, dead ends, jargon, missing next step)?
2. Does the underlying LLM have **enough tools and context** to provide
   wonderful service (or is it starved of history, mastery, schedule,
   content)?

### 3.1 What to build

- `dry-run-test/scenario_<topic>.md` library (the `auto_improve.py`
  dry-run masters already point here; actually create the folder + first
  5–10 scenarios):
  - New user / first launch (“learn IB Chemistry in 90 days, no materials”).
  - Long-term user accelerates pace; switches subject; reschedules class.
  - API-key missing / provider switch; offline / low-end device.
  - Confused student (“I don’t get fractions, explain differently” ×3).
  - Overworked student (late-night, streak break, wellbeing nudge).
- Each scenario: plain-language goal → step expectations →
  `PASS/PARTIAL/FAIL` trace against code (`file:line` refs) →
  severity (`BLOCKER/MAJOR/MINOR`) + fix acceptance.
- Tool/context audit per scenario:
  - List tools the agent *needed* vs tools it *had* (gap → new-tool issue).
  - List context the LLM *needed* (mastery weak topics? adherence? lesson
    history? uploaded PDFs?) vs what `AgentLoop` system prompt actually
    injects (gap → context-enrichment issue).
  - Comprehension rubric: reading level, actionability (exactly one clear
    next action?), confirmation discipline (no silent schedule changes —
    see `agent_must_read.md` §Mentor).
- Validator loop: a scheduled agent re-traces scenarios against current
  code, marks `COMPLETED/PARTIAL/NOT_COMPLETED`, deletes done scenarios
  (>80% complete), files `issues/open/dry_run_*.md` for the rest.

### 3.2 Acceptance criteria

- ≥10 scenarios covering the personas above; no duplicates.
- Every `FAIL/PARTIAL` maps to one `issues/open/*.md` with `Status: open`,
  severity, affected files, repro, expected-vs-actual, suggested approach.
- Quarterly prompt/tool review driven by scenario scores, not vibes.

---

## 4. Prep-heavy token economy — off-period work, student-steered budgets, CPU-aware

**Goal:** flip spend so **off-period preparation dominates**. Live lessons
consume pre-built plans, blocks, variants, and knowledge — not raw
reasoning from scratch.

### 4.1 Principle

- Prep tasks (all LLM-backed, all off-period via `IdleExecutor` or equivalent
  background queue):
  - PDF/textbook parsing → knowledge base (chunk → embed → link to
    topics/syllabi).
  - Question-bank expansion (variants per `docs/question_variant_pipeline.md`,
    difficulty tags, markschemes, validation).
  - Lesson pre-generation (blocks, examples, exercises, homework, recap
    scaffolds) ahead of each scheduled lesson.
  - Mastery/plan refresh (weak-topic analysis, readiness scoring, roadmap
    adjustment proposals — never silent commits).
- Live tasks stay lean: conversational delivery, adaptive explanation,
  answer review, encouragement — reading pre-built artefacts, not synthesising
  the course from zero.

### 4.2 Student-adjustable expenditure

- Settings → “Preparation budget”:
  - Per-category toggles + token caps (e.g. PDF→KB: 40%, Q-bank: 30%,
    lesson prep: 20%, embeddings: 10%; defaults sensible, all editable).
  - “Prepare while I’m away” master switch + quiet-hours; per-syllabus opt-in.
  - Live counters: tokens + est. cost per category (extend `LlmTaskManager` /
    `LlmUsageMeter` + `LlmTaskManagerScreen`), over-budget warnings, pause/resume.
- All prep jobs are visible tasks (`queued → running → done/failed`,
  retry/cancel) — the existing task-manager portal is the UI, extended with
  category filters and budget bars. Reuse `IdleTask`/`LlmTask` types; do not
  invent a parallel tracker.

### 4.3 CPU / system monitoring + adequate prep tools

- New `SystemMonitorService` (or extend instrumentation):
  - CPU, memory, battery/charging, network type; exposes
    `canRunHeavyPrepNow()` (e.g. defer embeddings when CPU >80% or battery
    saver on).
  - Prep scheduler respects it: heavy jobs yield/defer, light jobs proceed;
    all decisions logged at `d`/`w`, never `e` unless unexpected.
- LLM prep toolbox (agent tools, all `Result<T>`, all unit-tested):
  - `IngestPdfToKbTool`, `EnqueueQuestionVariantsTool`,
    `PreGenerateLessonTool`, `RefreshMasteryTool` (names negotiable —
    mirror existing `mentor/services/tools/` pattern).
  - Each tool declares est. tokens + needs-network/CPU class so the budget
    scheduler can order them.
- Guardrails: prep never mutates schedules/commitments without explicit
  confirmation for important changes; every auto-created artefact is marked
  `ai-generated + validation status` until human/validator approves
  (see `agent_must_read.md` correctness mandate).

### 4.4 Acceptance criteria

- With budgets at defaults, a week of simulated off-periods shows prep tokens
  > live tokens in `LlmUsageMeter` aggregates (test proves the ratio).
- Student can halve PDF-parsing spend and see variant/plan prep continue
  within caps (widget test on settings + service test on enforcement).
- Heavy prep defers under simulated CPU pressure (fake monitor → scheduler
  test), resumes when pressure clears.
- No new public API throws; all new services/providers have matching
  `test/**` files per `AGENTS.md` placement (unit vs widget separated,
  behavioural provider assertions, hand-written fakes).

---

## 5. How finders work (binding) — vision alignment, not lint

Finder doctrine (applies to `sk-finder` for core vision and `sk-next-finder`
for this file): the compiler owns style. `flutter analyze` already covers
conventions (`Result<T>`, Logger placement, `.normalized`, number formatting,
test placement). Finders do NOT file convention-only or crash-only issues
unless the defect directly breaks a vision journey for a real student.

Finders trace vision capabilities end to end and judge closeness:

- Core vision (`agent_must_read.md` → `sk-finder`): conversational teaching,
  mentor off-period planning and nudges, adaptive practice and mastery,
  ingestion of PDFs notes banks syllabi media, planner roadmaps adherence,
  multi-syllabus tracking, token task transparency.
- Next-term (`this file` → `sk-next-finder`): sections 1–4 above.

For each capability, state `Closeness: CLOSE / DRIFTING / MISSING / FRAGILE`,
call out deviations where code contradicts vision, assess whether we are
getting closer or deviating, and define what must be solidified to make it
actually work (validation, persistence, wiring, UX, background prep).

Issue format — one gap per file, `Status: open` line right after title:

- `Vision ref` (which vision paragraph or section 1–4 item)
- `Closeness` + one-paragraph closer-or-deviating assessment
- `Severity`, `Affected area`, `Description`, `Student impact`
- `Steps to reproduce` via a real student journey (not a unit edge case)
- `Expected per vision vs Actual in code`
- `Code analysis (file:line)`
- `Solidification criteria` (what done looks like in student terms)

Slug prefixes so the board stays triageable: core uses
`vision-`, `teaching-`, `mentor-`, `practice-`, `ingestion-`, `planner-`;
next-term uses `visual-`, `e2e-`, `scenario-`, `prep-`, `budget-`, `sysmon-`.
Skip slugs already present in `issues/open/` (claimed or not) or
`issues/closed/`; never edit another issue's `Status:`; never touch `closed/`.
`issues/open/` + `issues/closed/` stay untracked — never `git add` them.
Each finder run ends with a short closer-or-deviating verdict even when it
files nothing.

Steady state (binding): filing an issue is optional, never a quota. A fully
aligned capability is a COMPLETE SUCCESS — log what was checked
(`capability → CLOSE + evidence file:line`), file nothing, and stop. Do NOT
manufacture gaps, restyle working code, or re-file closed concerns to justify
a run. We are not in permanent feature-build mode: if vision is met, the
correct output is `no new issues — vision holds` plus the check log.

## 6. Roadmap order (suggested)

1. `prep-*` budget model + task-manager surfacing (unlocks everything else).
2. `visual-*` package skeleton + first 3 goldens (unblocks UI optimisation).
3. `e2e-*` fake-mode agentic harness (unblocks grant spend).
4. `scenario-*` first 10 journeys + tool/context audit (drives tool backlog).
5. `sysmon-*` CPU-aware deferral + heavy prep tools (polish at scale).
