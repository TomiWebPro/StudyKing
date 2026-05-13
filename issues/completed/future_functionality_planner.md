# Future Functionality: Close the Learning Loop, Add AI Observability & Multi-Modal Interaction

## Summary

The foundational scaffolding from the previous roadmap (content ingestion, smart planner, analytics dashboard) has been built. However, three critical architectural gaps prevent StudyKing from functioning as the cohesive AI-native learning platform described in the vision. These gaps are not surface-level bugs — they are missing feedback loops, observability layers, and interaction modes.

---

## Issue 1: The Core Learning Loop (Plan → Study → Track → Adapt) Is Broken

### Current State

Three subsystems exist but are **completely disconnected from each other**:

| Component | Exists? | Actual Behavior |
|---|---|---|
| `PlanRepository` (`lib/core/data/repositories/plan_repository.dart`) | Yes | Persists plans to Hive. Works correctly. |
| `PersonalLearningPlanService` (`lib/core/services/personal_learning_plan_service.dart`) | Yes | Generates data-driven plans from mastery graph. Returns `PersonalLearningPlan`. |
| `PlanAdherenceTracker` (`lib/core/services/instrumentation_service.dart:84-151`) | Yes | Computes adherence scores from planned vs actual. **But `recordDay()` is NEVER called from any session flow.** |
| `MasteryImprovementTracker` (`lib/core/services/instrumentation_service.dart:153-203`) | Yes | Tracks accuracy deltas and level-ups. **`trackImprovement()` is NEVER called from practice flows.** |
| `PlanAdherenceTracker` storage | No | All metrics are **in-memory only** — data lost on app restart. No Hive adapter or persistence. |
| Plan adaptation | No | No mechanism detects under-adherence and suggests plan adjustments. |
| Planner → Session connection | No | Session tracker (`session_tracker_screen.dart`) never queries the plan for today's target. |

**Impact**: The vision says *"track actual adherence vs intended schedule"* and *"adapt plans as progress changes"*. Currently:
- Plans are saved but never referenced during study sessions
- Adherence is computed but never persisted — `getAverageAdherence()` always returns `0.0`
- After 3 days of under-adherence, nothing happens. The plan is static.
- The mentor cannot say "you completed 80% of your plan this week" because no data exists

### Affected Files

| File | Issue |
|---|---|
| `lib/core/services/instrumentation_service.dart:84-151` | `PlanAdherenceTracker.recordDay()` is defined but never invoked. All metrics are in-memory only. |
| `lib/core/services/instrumentation_service.dart:153-203` | `MasteryImprovementTracker.trackImprovement()` is defined but never invoked from practice flows. |
| `lib/features/sessions/presentation/session_tracker_screen.dart` | Session end does not call `recordDay()` with planned vs actual data. |
| `lib/features/planner/presentation/planner_screen.dart` | Generates plans but does not expose "today's targets" to session flow. |
| `lib/core/data/repositories/plan_repository.dart` | Saves/loads plans but no adherence metrics are persisted alongside them. |
| `lib/features/dashboard/presentation/dashboard_screen.dart:233-265` | Plan adherence section reads from `_instrumentationData` which returns zeros — section is decorative only. |
| `lib/features/mentor/services/mentor_service.dart` | Mentor cannot reference plan adherence because no persisted data exists. |

### Acceptance Criteria

- [ ] **Session → Adherence connection**: When a study session ends (`_endSession()` in `SessionTrackerScreen`), call `PlanAdherenceTracker.recordDay()` with the day's planned target (from the persisted plan) and actual completed values (questions answered, time spent).
- [ ] **Adherence persistence**: `PlanAdherenceMetric` and `MasteryImprovementMetric` are saved to Hive (new adapter + box) so data survives app restart. The in-memory-only tracker is replaced.
- [ ] **Practice → Mastery connection**: After each practice session ends, call `MasteryImprovementTracker.trackImprovement()` for all topics touched during the session.
- [ ] **Plan adaptation**: After 3 consecutive days of adherence < 50%, the system presents a suggestion to adjust the plan (reduce daily target, re-prioritize topics). This is surfaced via the dashboard and mentor.
- [ ] **Today's target**: Planner screen exposes "today's planned questions/minutes" which the session tracker reads to compute adherence.

---

## Issue 2: LLM Infrastructure Lacks Observability (Task Manager & Token Tracking)

### Current State

The vision says:
> *"It should track LLM token usage for different tasks and have a task manager-like portal to view actively running inferencing task and for what purpose."*

| Component | Exists? | Actual Behavior |
|---|---|---|
| `UsageRecord` (`lib/features/settings/data/models/settings_model.dart`) | Yes | Records token counts and calculates cost with **hardcoded per-token pricing** (becomes stale). Never shown except in raw settings list. |
| Task manager portal | **No** | No UI exists to view active/pending inference tasks. |
| Request cancellation | **No** | No mechanism to cancel an in-flight LLM request (e.g., if a student starts a long lesson generation then navigates away). |
| Per-feature token tracking | **No** | `LlmService` / `LlmProvider` calls go through `http` directly — no wrapper meters token usage per feature (teaching vs mentor vs planner vs ingestion classification vs question generation). |
| Provider health checking | **No** | No periodic health check or fallback between providers. If OpenRouter is down, the app does not try Ollama. |

**Impact**: Without observability:
- Students cannot see how much AI usage is costing them
- There is no way to cancel a long-running generation
- Token attribution per feature is impossible — can't know "the tutor used 80% of my budget"
- Provider failures are opaque: the UI stalls until timeout with no feedback

### Affected Files

| File | Issue |
|---|---|
| `lib/features/settings/data/models/settings_model.dart:106-112` | `UsageRecord.calculateTotalCost` hardcodes token pricing that goes stale. |
| `lib/core/services/llm_service.dart` (if it wraps provider calls) | No per-request metering, no cancellation tokens, no timeout management. |
| `lib/features/settings/presentation/api_config_screen.dart` | API key configuration exists but no "test connection" button for provider health check. |
| `lib/features/teaching/services/tutor_service.dart` | Generates lesson content with no user-facing progress indicator or cancellation. |
| All LLM-consuming features | No way to attribute tokens to a specific feature/use-case. |

### Acceptance Criteria

- [ ] **Task manager portal**: A new screen (accessible from settings or bottom nav) shows all active, queued, and recent LLM inference tasks. Each task shows: feature name (tutor, planner, ingestion, etc.), model, status (running/queued/done/failed), start time, tokens used, estimated cost.
- [ ] **Request cancellation**: Each running task has a cancel button. Cancelling sends an abort signal (API-dependent; at minimum cancels the local future and marks the task as cancelled in the UI).
- [ ] **Dynamic pricing**: Token pricing is configurable (read from settings, defaulting to known rates for common models). Pricing constants are moved to a config file, not hardcoded in a model.
- [ ] **Per-request metering**: A `LlmUsageMeter` service wraps all LLM calls, recording tokens consumed per feature. The task manager reads from this meter.
- [ ] **Provider health check**: The API config screen has a "Test Connection" button that sends a minimal request and reports round-trip latency and status.
- [ ] **Graceful degradation**: If a provider call fails, the UI shows a clear error with "try different provider" or "retry" action — not an eternal spinner.

---

## Issue 3: No Proactive Engagement System (Reminders, Nudges, Notifications)

### Current State

The vision says the system should *"proactively engage students with reminders, prompts, revision nudges, lesson notifications, accountability messaging, and practice encouragement"* and *"nudge student to keep learning whilst prevent student from overworking and stress"*.

| Component | Exists? | Actual Behavior |
|---|---|---|
| `NotificationSettings` in settings_model | Yes | User can configure preferences but **nothing reads these to schedule notifications**. |
| Background notification scheduling | **No** | No use of `flutter_local_notifications` or platform-specific scheduling. |
| Nudge engine | **No** | No logic evaluates "has it been 3 days since this student practiced topic X?" to generate a revision nudge. |
| Overwork detection | **No** | No logic detects "student studied 6 hours today" to send a break reminder. |
| Lesson reminders | **No** | No pre-class notification for scheduled lesson time. |

**Impact**: The app is purely reactive — it only works when the student opens it. A learning companion should be proactive, especially for retention (spaced repetition nudges) and wellbeing (overwork prevention).

### Affected Files

| File | Issue |
|---|---|
| `lib/features/settings/data/models/settings_model.dart` | `NotificationSettings` fields (`dailyReminder`, `lessonReminders`, `revisionNudges`, `practiceReminders`, `quietHoursStart/End`) exist but are never read by any scheduling service. |
| `lib/features/settings/presentation/settings_screen.dart` | Notification toggle UI exists but triggers no platform notification permission request or scheduling. |
| `lib/features/planner/presentation/planner_screen.dart` | Lesson times are specified but no alarm/notification is scheduled for them. |
| `lib/core/services/mastery_graph_service.dart` | `getWeakTopics()` returns topics needing review but no service checks if it's time to nudge. |

### Acceptance Criteria

- [ ] **Notification scheduling service**: A new `EngagementScheduler` service reads `NotificationSettings` on app start (and when settings change) and schedules/cancels platform notifications via `flutter_local_notifications`.
- [ ] **Spaced revision nudges**: For each topic where it's been 3+ days since the last practice, schedule a daily nudge at the user's preferred time. Nudge count respects `quietHoursStart/End`.
- [ ] **Overwork detection**: If a student's study session exceeds a daily threshold (configurable, default 4 hours), show an in-app nudge suggesting a break. Do not block studying — just nudge.
- [ ] **Lesson reminders**: When a lesson is scheduled, send a notification 15 minutes before start time.
- [ ] **Weekly progress digest**: Every Sunday (or configurable day), send a summary notification: "This week: 4h studied, 80% accuracy, 2 topics mastered."
- [ ] **Settings wiring**: Notification toggle in settings triggers platform permission dialog (first time) and schedules/unschedules all notifications.

---

## Issue 4: Voice & Multi-Modal Interaction Is Absent Despite Being a Core Product Differentiator

### Current State

The vision explicitly calls for:
> *"The platform should support multiple forms of interaction: typed input, voice conversation, speech-to-text and text-to-speech, multiple choice responses, handwritten/drawn responses on canvas, vision-based interpretation of student work."*

| Component | Exists? | Actual Behavior |
|---|---|---|
| Canvas drawing widget (`lib/core/widgets/canvas_drawing_widget.dart`) | Yes | Exists but is **not integrated into any question workflow**. Never used for student responses. |
| Speech recognition | **No** | No `speech_to_text` package or platform STT integration. |
| Text-to-speech | **No** | No TTS for reading questions aloud or tutoring via voice. |
| Camera/vision input | **No** | No way to snap a photo of handwritten work or a textbook page and have it processed. |
| Voice conversation in tutor | **No** | Tutor is text-only chat. No voice I/O. |

**Impact**: The vision describes StudyKing as *"conversational, not static"* with *"real-time back-and-forth discussion through both text and voice"*. Without multi-modal input, the app is indistinguishable from a standard quiz app.

### Affected Files

| File | Issue |
|---|---|
| `lib/core/widgets/canvas_drawing_widget.dart` | Exists as a reusable widget but is never embedded in any question/answer screen. |
| `lib/features/teaching/presentation/tutor_screen.dart` | No microphone button, no voice input, no TTS output. |
| `lib/features/questions/presentation/` | All question response types are text-based or multiple-choice. No handwriting canvas answer option. |
| `lib/features/ingestion/presentation/upload_screen.dart` | No camera/live photo option for snapping textbook pages or screenshots. |

### Acceptance Criteria

- [ ] **Voice I/O in tutor**: Tutor screen gains a microphone button that captures speech (via `speech_to_text`), sends it as student input, and optionally reads the AI response aloud (via TTS). Voice is a parallel input — text/type remains available.
- [ ] **Canvas answer input**: When a question is presented, the student can choose to answer via a drawing canvas (for math, diagrams, etc.). The canvas widget is embedded in the question-answer flow.
- [ ] **Vision-based upload**: Upload screen adds a "Camera" option. A photo of a textbook page or handwritten notes is processed through the ingestion pipeline (OCR via LLM vision or a dedicated OCR service).
- [ ] **Multi-modal toggle**: Each interaction (tutor, practice, question) allows the student to switch between text, voice, and drawing input modes.

---

## Issue 5: Hardcoded `'anonymous'` Student ID Blocks Personalization & Export (Half-Migrated)

### Current State

`StudentIdService` (`lib/core/services/student_id_service.dart`) exists and generates UUIDs. It is used in newer code like `DashboardScreen` and `PlannerScreen`. However, **6+ files still hardcode `'anonymous'`**, and the provider at `student_id_service.dart:51` defaults back to `'anonymous'` when the future hasn't resolved:

```dart
final studentIdValueProvider = Provider<String>((ref) {
  return ref.watch(studentIdProvider).valueOrNull ?? 'anonymous';
});
```

| File | Line | 
|---|---|
| `lib/features/teaching/presentation/tutor_screen.dart` | ~73 |
| `lib/features/mentor/services/mentor_service.dart` | ~58 |
| `lib/core/services/personal_learning_plan_service.dart` | ~280 |
| `lib/core/services/study_progress_tracker.dart` | ~81, 224, 253 |
| `lib/features/sessions/presentation/session_tracker_screen.dart` | ~16 |
| `lib/features/practice/presentation/practice_screen.dart` | ~805 |
| `lib/core/services/student_id_service.dart:51` | Fallback to `'anonymous'` |

**Impact**: As long as `'anonymous'` is used anywhere:
- Multi-device progress sync is impossible (whose data to sync?)
- Export conflates all users' data
- Personalized mentoring is unreliable (mentor sees wrong history)
- Analytics shows aggregate of all local users

### Acceptance Criteria

- [ ] Replace all `'anonymous'` strings with injected `StudentIdService.getStudentId()` or the `studentIdProvider`.
- [ ] Remove the `'anonymous'` fallback in `studentIdValueProvider` — if the future hasn't resolved, return a loading state or an empty string (callers handle empty gracefully).
- [ ] Verify that every service/repository/screen that accepts a `studentId` parameter is called with a real ID at every call site.

---

## Issue 6 [Tech Debt]: Internationalization Bypass — 70+ Strings Hardcoded in English

### Current State

The ARB localization system exists (`lib/l10n/app_en.arb`, `app_es.arb`) and is used by some screens. However, a large number of strings bypass it entirely:

- `lib/core/errors/handlers.dart:114-140`: 17 error messages hardcoded in English
- `lib/features/dashboard/presentation/dashboard_screen.dart`: 30+ UI labels hardcoded (e.g., `'Study Dashboard'`, `'Plan Adherence'`, `'Mastery Overview'`, `'Weak Areas'`, `'Export CSV'`, etc.)
- `lib/features/ingestion/presentation/upload_screen.dart`: 6+ strings hardcoded
- `lib/features/planner/presentation/planner_screen.dart`: Multiple hardcoded labels

**Impact**: Spanish-speaking users see English for all errors and most analytics/planner/upload labels. This directly contradicts the vision requirement: *"localised prompt and strings for different world languages"*.

### Affected Files

| File | Count | Examples |
|---|---|---|
| `lib/core/errors/handlers.dart` | ~17 | `'An unexpected error occurred'`, `'No data found'`, etc. |
| `lib/features/dashboard/presentation/dashboard_screen.dart` | ~30+ | `'Study Dashboard'`, `'Accuracy'`, `'Study Time'`, `'Weekly Activity'`, `'Plan Adherence'`, `'Mastery Overview'`, `'Topic Performance'`, `'Achievements'`, `'Export CSV'`, etc. |
| `lib/features/ingestion/presentation/upload_screen.dart` | ~6 | `'Upload Content'`, `'Title *'`, `'Content *'`, etc. |
| `lib/features/planner/presentation/planner_screen.dart` | ~10+ | Form labels, button text |

### Acceptance Criteria

- [ ] All error messages in `handlers.dart` are moved to ARB and referenced via `AppLocalizations.of(context)`.
- [ ] All hardcoded labels in `dashboard_screen.dart`, `upload_screen.dart`, and `planner_screen.dart` are replaced with ARB lookups.
- [ ] Spanish translations (`app_es.arb`) are updated for all new keys.

---

## Priority & Risk Assessment

| Issue | Priority | Risk | Why Now |
|---|---|---|---|
| **#1: Learning loop broken** | Critical | High | Core product workflow (plan→study→track→adapt) is a paper tiger — data flows into a void. Without this, the product cannot deliver on its core value proposition. |
| **#2: LLM observability** | High | Medium | Users cannot see AI costs or cancel runaway tasks. Opaque provider failures create poor UX. Task manager is explicitly called out in the vision. |
| **#3: Proactive engagement** | High | Medium | App is purely reactive. No reminders, no spaced repetition nudges, no overwork prevention. This is what separates a "companion" from a "tool." |
| **#4: Multi-modal interaction** | Medium | High | Differentiator feature but requires new dependencies (STT, TTS, platform permissions). Canvas widget exists but is unused. |
| **#5: Anonymous student ID** | Critical | Medium | Actively blocks personalization, export, multi-device. Half-migrated state is dangerous (some code uses UUID, some uses 'anonymous'). |
| **#6: i18n bypass** | High | Low | Straightforward migration. Spanish users currently see English everywhere. Low risk, high user-facing impact. |

## New Files Needed

| File | Purpose |
|---|---|
| `lib/core/services/engagement_scheduler.dart` | Reads notification settings, schedules/cancels platform notifications for reminders, nudges, digests. |
| `lib/core/services/llm_task_manager.dart` | Portal-like service tracking all active/completed LLM inference tasks with cancellation support. |
| `lib/core/services/llm_usage_meter.dart` | Wraps LLM calls to record per-request token usage, cost, and feature attribution. |
| `lib/features/llm_tasks/` | New feature module for the LLM task manager UI screen. |
| `lib/core/data/adapters/plan_adherence_adapter.dart` | Hive adapter for `PlanAdherenceMetric` persistence. |
| `lib/core/data/adapters/mastery_improvement_adapter.dart` | Hive adapter for `MasteryImprovementMetric` persistence. |

## Excluded from This Issue (Tackled Separately)

- Redundant state management (Riverpod vs Provider) — being addressed in the code refactor tracker
- MasteryState mutability refactor — being addressed in the code refactor tracker
- AnimatedBarChart axis labels — being addressed in the UI/UX tracker
- Empty scaffolding directories — being addressed in the code refactor tracker
- Settings importing main.dart — being addressed in the code refactor tracker
- Subject model in wrong directory — being addressed in the code refactor tracker
- Duplicate ProfileData vs UserProfile — being addressed in the code refactor tracker
