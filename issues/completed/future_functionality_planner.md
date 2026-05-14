# Future Functionality Planner: High-Value Gaps & Roadmap Opportunities

## 1. AI Content Validation Pipeline — Fact-Check & Quality Gate

**Context:** The vision mandates: *"AI-generated content should not be blindly trusted; correctness, consistency, and usefulness should be continuously validated and improved."* Currently `QuestionGenerationService` (`lib/core/services/question_generation_service.dart:1-379`) generates questions via LLM, parses the JSON, and saves them directly — no factual validation, no cross-referencing against existing content, no deduplication, no human-in-the-loop workflow. This means a single hallucinated question enters the question bank silently and gets served to students during practice and exams.

**Affected files:**
- `lib/core/services/question_generation_service.dart` (generates questions without validation)
- `lib/core/services/answer_validation_service.dart` (validates student answers, not generated content)
- `lib/core/data/models/question_model.dart` (needs `validationStatus`, `validatedAt`, `validatedBy` fields, or equivalent quality tracking)
- `lib/features/ingestion/services/content_pipeline.dart` (same trust issue — ingested content, mark schemes, topics all pass without validation)
- New file: `lib/core/services/content_validator_service.dart` (validation orchestration)
- New file: `lib/core/services/content_validators/question_validator.dart` (per-question fact-check)
- New file: `lib/features/quality/presentation/` (review queue UI)

**Rationale:** Without a validation gate, the system compounds errors. A wrong question generates wrong mark schemes, wrong mastery data, and wrong adaptive recommendations. This undermines the entire loop of practice → evaluation → mastery tracking. Adding validation retroactively after the question bank grows large is exponentially harder.

**Acceptance criteria:**
- `ContentValidatorService` intercepts every Question/Markscheme/Source before persistence
- Validator categories: (a) Structural validity — JSON parseable, required fields non-null, enum values in range; (b) Semantic validity — LLM double-check: "Is this question answerable from the given markscheme? Is the correct answer actually correct?"; (c) Deduplication — Levenshtein or embedding-similarity check against existing questions in the same topic, flag near-duplicates; (d) Cross-reference — source text exists, topic exists, subject exists
- Question saved with status `unvalidated` initially; validated async; status transitions to `validated` or `flagged`
- A review screen (`QualityDashboardScreen`) lists flagged/unvalidated content with accept/reject/edit actions
- Student-facing practice session skips `flagged` questions or marks them as "unverified"
- Metrics: validation pass rate tracked over time per model per topic

---

## 2. Formal Spaced Repetition Engine (SM-2 / FSRS)

**Context:** The vision says *"the system should continuously test understanding, focus on weak areas, revisit old content intelligently, and optimize for retention and mastery."* The current `MasteryCalculationService` (`lib/core/services/mastery_calculation_service.dart:1-165`) tracks attempts with a custom ELO-like heuristic (accuracy × streak × confidence), but it does NOT implement any formal spaced repetition algorithm (SM-2, FSRS-4, or similar). There is no optimal interval scheduling, no forgetting-curve modeling, no daily review queue. The `EngagementScheduler` (`lib/core/services/engagement_scheduler.dart:115-132`) simply checks "days since last practice ≥ 3" as a flat threshold.

**Affected files:**
- `lib/core/services/mastery_calculation_service.dart` (replace heuristic with SM-2/FSRS)
- `lib/core/data/models/mastery_state_model.dart` (add `easinessFactor`, `interval`, `repetitions`, `nextReviewDate` or FSRS-equivalent parameters)
- `lib/core/services/adaptive_practice_engine.dart` (exists, needs to consume scheduled review queue)
- `lib/features/practice/presentation/practice_screen.dart` (add "Due for Review" section that shows cards due today)
- `lib/core/services/engagement_scheduler.dart` (replace flat threshold with algorithm-driven nudge timing)
- `lib/core/repositories/spaced_repetition_repository.dart` (new file — persist scheduling state)

**Rationale:** Students forget exponentially. Without a formal spacing algorithm, review becomes random or cramming-based. SM-2/FSRS are battle-tested (Anki, SuperMemo). Integrating a formal algorithm converts "revisit old content" from a vague aspiration into a data-driven engine that minimizes retention loss while minimizing total review time — directly fulfilling the vision's optimization requirement.

**Acceptance criteria:**
- Implement SM-2 algorithm (or FSRS-4 for state-of-the-art) in `MasteryCalculationService`
- Each topic question card gets: `easinessFactor`, `interval` (days), `repetitions` (consecutive correct), `nextReviewDate`
- After each practice session, recalculate intervals; sort practice queue by `nextReviewDate` ascending
- Dashboard shows "X cards due for review today" with count
- Practice screen has a "Spaced Review" mode distinct from "Free Practice" that serves only due cards
- Spaced review data is persisted in Hive with migration path from legacy mastery states
- Optional: FSRS-4 parameter optimization (user-level or global `w` matrix)

---

## 3. Multi-Provider LLM Failover & Health-Check Routing

**Context:** The `LlmService` (`lib/core/services/llm/llm_chat_service.dart:74-119`) supports `LlmProvider.openRouter`, `ollama`, and `openAI`, but the app picks ONE provider via configuration and stays with it. If OpenRouter has an outage, returns 429s, or the Ollama instance goes down, the entire app's AI features (tutoring, question generation, mentor chat, ingestion classification) become non-functional. There is no: health checking, automatic fallback, load-aware routing, or circuit-breaker pattern.

**Affected files:**
- `lib/core/services/llm/llm_chat_service.dart` (add failover routing logic)
- `lib/core/constants/app_api_config.dart` (add fallback provider configs)
- `lib/features/settings/presentation/api_config_screen.dart` (let users configure provider priority order)
- `lib/core/services/llm/llm_model_service.dart` (provider metadata for routing decisions)
- New file: `lib/core/services/llm/llm_router.dart` (failover logic, circuit breaker)
- `lib/core/data/models/llm_models.dart` or new: provider health model

**Rationale:** A single-provider architecture is a single point of failure for a production AI-native app. Students mid-lesson lose their tutor when the API is unreachable. Teachers lose confidence. The vision demands reliability. A circuit-breaker with automatic fallback to a secondary provider (e.g., OpenRouter → Ollama local → OpenAI) ensures continuity.

**Acceptance criteria:**
- `LlmRouter` accepts a list of provider configs ordered by priority
- Before routing, `LlmRouter` runs lightweight health checks (`HEAD /v1/models` or equivalent) with configurable timeout (5s)
- If primary provider fails health check or returns HTTP 4xx/5xx, automatic fallback to next provider in priority list
- Circuit-breaker: after 3 consecutive failures within 5 minutes, provider is marked `degraded` and skipped for a cooldown period (configurable, default 60s)
- Token/cost tracking continues to work across failover switches
- Settings UI lets users configure priority order, health-check interval, circuit-breaker thresholds
- Toast notification or status indicator warns user when failover occurs ("Using fallback provider: Ollama local")

---

## 4. Handwriting Recognition & Vision-Based Answer Interpretation

**Context:** The vision explicitly lists: *"handwritten/drawn responses on canvas"* and *"vision-based interpretation of student work"* as required interaction modes. A canvas drawing widget exists (`lib/features/questions/ui/widgets/canvas_drawing_widget.dart`) which lets students draw/write their answers, but the drawn content is only saved as a PNG image — it is NEVER interpreted. There is no handwriting recognition (OCR/HTR), no mathematical expression recognition, no diagram grading. The drawn answer cannot be automatically evaluated against the markscheme.

**Affected files:**
- `lib/features/questions/ui/widgets/canvas_drawing_widget.dart` (add "submit for recognition" action)
- New file: `lib/core/services/vision/handwriting_recognition_service.dart`
- New file: `lib/core/services/vision/math_expression_recognizer.dart`
- `lib/core/services/answer_validation_service.dart` (handle recognized text from canvas as answer input)
- `lib/features/practice/presentation/practice_session_screen.dart` (canvas → recognition → validation flow)
- `pubspec.yaml` (may need `google_mlkit_digital_ink_recognition` or on-device `flutter_ocr`; or use LLM vision API)
- `lib/core/services/llm/llm_chat_service.dart` (vision-capable model call for image-to-text)

**Rationale:** This is a core differentiator. No other study app lets a student draw a free-body diagram, write a chemical equation by hand, or sketch a graph, then have it automatically recognized and evaluated against the expected answer. Without this, canvas drawing is a gimmick — a dead-end input that can never be graded. The vision explicitly calls this out as "vision-based interpretation of student work."

**Acceptance criteria:**
- Canvas "Submit" button triggers: (a) capture PNG from canvas, (b) send to recognition pipeline
- Recognition pipeline has two strategies: (1) On-device OCR via ML Kit or `flutter_ocr` for handwriting; (2) LLM vision API (gpt-4o, claude-3-vision, gemini-vision) as fallback/upgrade for complex content (diagrams, math)
- Recognized text is surfaced to the user for confirmation/correction before submission
- Recognized answer flows into `AnswerValidationService` matching against the question's markscheme
- Math mode: recognizes LaTeX from handwritten math (e.g., "x^2 + 2x + 1 = 0")
- Diagram mode: for physics/biology, checks key labeled elements against expected diagram criteria
- Performance: on-device inference where possible to avoid latency; vision API only for complex cases
- Settings: toggle between "on-device only" and "use cloud vision"

---

## 5. Study Timer / Focus Mode with Overwork Prevention

**Context:** The vision repeatedly references time awareness: *"respect the requested class hour," "prevent student from overworking and stress," "estimate realistic workload," "track actual adherence vs intended schedule."* There is zero time-management infrastructure in the app — no Pomodoro timer, no focus session tracker, no break reminder, no daily/weekly study time cap enforcement. The `EngagementScheduler` (`lib/core/services/engagement_scheduler.dart:101-113`) has an `overwork` nudge that fires only once after 4+ hours of study, but it cannot actively enforce limits because it doesn't know when the student started studying.

**Affected files:**
- New file: `lib/features/focus_mode/presentation/focus_timer_screen.dart`
- New file: `lib/features/focus_mode/presentation/widgets/` (timer widget, session summary card)
- New file: `lib/features/focus_mode/services/focus_session_service.dart`
- New file: `lib/features/focus_mode/data/models/focus_session_model.dart`
- `lib/core/services/engagement_scheduler.dart` (consume focus session data for overwork detection)
- `lib/core/routes/app_router.dart` (route to focus mode)
- `lib/features/dashboard/presentation/dashboard_screen.dart` (show today's focus time)
- `lib/core/providers/app_providers.dart` (register focus session provider)

**Rationale:** Time management is fundamental to the "long-term study companion" vision. A student saying "I want to study 30 minutes of IB Physics" needs a timer that enforces exactly that — and stops them from over-studying. The Pomodoro technique (25 min focus + 5 min break) is the gold standard for student productivity. Integration with the planner and engagement scheduler creates a virtuous loop: plan → focus → track → adjust.

**Acceptance criteria:**
- Focus timer: student sets duration (linked to planned class hour), starts a countdown, focus session begins
- Break enforcement: after focus block, a break timer counts down (5 min default, configurable); during break, the student cannot start another focus block
- Daily cap: student sets max study hours/day; once reached, the app blocks starting new focus sessions and shows a non-dismissible "You've reached your daily limit — well done!" message (configurable in settings)
- Session data persisted: `FocusSession` model with `startTime`, `endTime`, `plannedDuration`, `actualDuration`, `subjectId`, `topicId`, `completed`
- Dashboard shows today's total focus time vs. planned time vs. daily cap
- `EngagementScheduler` uses focus session data for accurate overwork detection (not just attempt-based estimate)
- Planner integration: if a lesson is planned for a given time slot, one-tap "Start focus for this lesson" button
- Responsive design: works on mobile (portrait timer) and desktop (side panel timer)

---

## Prioritization Guidance

| Priority | Item | Effort | Impact |
|----------|------|--------|--------|
| **P0** | AI Content Validation Pipeline | Medium (3-4 weeks) | Critical — prevents systemic data quality rot |
| **P0** | Multi-Provider LLM Failover | Medium (2-3 weeks) | Critical — production reliability for all AI features |
| **P1** | Formal Spaced Repetition Engine | Medium (3-4 weeks) | High — core pedagogical differentiator |
| **P2** | Vision-Based Handwriting Recognition | Large (5-8 weeks) | Medium — differentiating but technically complex |
| **P2** | Study Timer / Focus Mode | Small (1-2 weeks) | High — immediately useful, solves overwork problem |
