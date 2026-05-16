# Code Quality & Architecture Refactor: Layer Violations, Dead Code, Log Hygiene, and Hardcoded Components

## Context

The codebase has accumulated significant architectural debt across three main dimensions: (1) **layer violations** where `lib/core/services/` depends on `lib/features/*/` — breaking the feature-based dependency rule, (2) **dead code and silent failure swallowing** with 30+ empty catch blocks and no-op methods, (3) **inappropriate log levels** where high-frequency operational events use `.i()` instead of `.d()`, (4) **pervasive hardcoded components** — system prompts, fallback strings, default URLs — and (5) **singleton anti-patterns** that hinder test isolation.

Additional defects surfaced: malformed CSV export due to stray parentheses, likely incorrect improvement calculation due to operator precedence, and a top-level eagerly-initialized `database` variable that triggers eager repository creation at import time.

---

## 1. Layer Violation: Core Services Importing from Feature Modules

**Rationale:** In a feature-first architecture, dependencies should flow **inward** (features → core). Every `lib/core/services/` file that imports from `lib/features/*/` creates a reverse dependency, making the core package unreusable, untestable in isolation, and fragile to feature refactors.

### Affected Files (16+ files)

| Core File | Feature Imports From |
|---|---|
| `lib/core/services/plan_adapter.dart` | `features/planner/data/repositories/` + `features/planner/data/models/` |
| `lib/core/services/badge_service.dart` | `features/dashboard/data/repositories/`, `features/practice/data/repositories/`, `features/dashboard/data/models/` |
| `lib/core/services/engagement_scheduler.dart` | `features/planner/data/repositories/`, `features/sessions/data/repositories/`, `features/planner/data/models/` |
| `lib/core/services/mastery_graph_service.dart` | `features/practice/data/repositories/` (5 repos), `features/practice/data/models/` (3 models), `features/questions/data/models/` |
| `lib/core/services/instrumentation_service.dart` | `features/practice/data/repositories/`, `features/practice/data/models/`, `features/planner/data/models/` |
| `lib/core/services/progress_export_service.dart` | `features/practice/data/models/`, `features/practice/data/repositories/` |
| `lib/core/services/study_progress_tracker.dart` | `features/practice/data/repositories/`, `features/practice/data/models/` |
| `lib/core/services/personal_learning_plan_service.dart` | `features/practice/data/repositories/`, `features/subjects/data/repositories/`, `features/planner/data/repositories/` + services + models |
| `lib/core/services/mastery_integration_service.dart` | `features/practice/data/models/`, `features/practice/data/repositories/` |
| `lib/core/services/question_generation_service.dart` | `features/questions/data/models/`, `features/questions/data/repositories/` |
| `lib/core/services/answer_validation_service.dart` | `features/questions/data/models/` |
| `lib/core/services/conversation_memory.dart` | `features/teaching/data/models/`, `features/teaching/data/repositories/` |
| `lib/core/services/mastery_calculation_service.dart` | `features/practice/data/models/` |
| `lib/core/services/llm_usage_meter.dart` | `features/settings/data/models/` |
| `lib/core/data/models/question_model.dart` | `features/questions/data/models/` |

### Acceptance Criteria

- All services currently in `lib/core/services/` that depend on feature-domain types are moved under the appropriate `lib/features/*/services/` directory.
- Shared interfaces or abstract models (e.g., `MasteryState`) that need to be referenced by both core and features are extracted into `lib/core/domain/` or `lib/core/models/`.
- The dependency graph is verified to be acyclic and strictly inward (features → core, never core → features).
- Tests for moved services are relocated per the AGENTS.md conventions.

---

## 2. Dead Code: Empty Methods and 30+ Silent Empty Catch Blocks

**Rationale:** Dead code creates maintenance burden (readers wonder what it does). Silent `catch (_) {}` blocks across 30+ sites swallow all exceptions with zero logging, making production failures invisible and debugging impossible.

### 2.1 Empty Methods with Zero Callers

**File:** `lib/core/services/adaptive_practice_engine.dart`
- **Line 51-59:** `updateQuestionState()` — accepts 4 required parameters, body is **completely empty**. Comment says retained for "backward compatibility" but there are **zero callers** in the entire codebase.
- **Line 105:** `clearCache()` — entirely empty body, zero callers.

### 2.2 Silent Empty Catch Blocks (representative sample)

| File | Lines |
|---|---|
| `lib/core/services/engagement_scheduler.dart` | 106, 130, 150, 160, 177, 186, 197, 245 |
| `lib/core/services/study_progress_tracker.dart` | 184, 202 |
| `lib/core/services/personal_learning_plan_service.dart` | 99, 160, 195, 308, 370, 428, 607, 617, 627, 637 |
| `lib/features/planner/services/planner_service.dart` | 264, 279, 292, 307, 318 |
| `lib/features/practice/services/practice_data_service.dart` | 51, 61, 81 |
| `lib/features/ingestion/services/content_pipeline.dart` | 186, 344 |
| `lib/features/dashboard/services/dashboard_data_loader.dart` | 74, 104 |

### Acceptance Criteria

- `updateQuestionState()` and `clearCache()` are removed from `adaptive_practice_engine.dart`.
- Every `catch (_) {}` block is replaced with at minimum a `_logger.e(...)` or `_logger.w(...)` call. If a fallback or recovery path exists, it should be implemented explicitly.
- All removal changes compile and existing tests pass.

---

## 3. Inappropriate Log Levels: `.i()` Used for High-Frequency Routine Events

**Rationale:** Using `.i()` (info) for per-session events like "Session started", "Stage 2 complete" pollutes production logs with noise that should only appear in debug mode. Info should be reserved for noteworthy state changes (config loaded, sync completed, user action).

### Affected Files

| File | Lines | Log Statement |
|---|---|---|
| `lib/features/sessions/services/study_timer_service.dart` | 96, 120, 126, 152, 175 | `_logger.i('Session started/paused/resumed/completed/cancelled')` |
| `lib/features/ingestion/services/content_pipeline.dart` | 67, 105, 116, 131, 140, 165 | `_logger.i('Source saved/created', 'Stage 1/2/3 complete', 'Pipeline complete')` |
| `lib/core/services/instrumentation_service.dart` | 280 | `_logger.i('Instrumentation data exported: ... categories')` |

### Acceptance Criteria

- All `.i()` calls for routine operational tracing (session state changes, pipeline stage progression, data export events) are changed to `.d()`.
- Any `.i()` calls that actually represent meaningful state transitions (e.g., "User first sign-in", "Sync completed with errors") remain at info level after review.

---

## 4. Pervasive Hardcoded Components: Prompts, Fallbacks, URLs

**Rationale:** Hardcoded system prompts (scattered across 8+ files) with near-duplicate text, hardcoded English fallback strings bypassing the localization layer, and hardcoded default URLs make the system inflexible, harder to test, and require code changes for string/URL modifications.

### 4.1 Duplicate Hardcoded System Prompts

**File:** `lib/core/services/llm/llm_chat_service.dart`
- Line 55: `'You are a helpful AI study assistant called StudyKing Quick Guide. Keep responses concise and educational.'`
- Line 79: `'You are a helpful AI study assistant called StudyKing. Keep responses concise and educational.'`

These two prompts are **almost identical** (one has "Quick Guide") but differ between `chat()` and `chatStream()` methods with no explanation.

Other hardcoded prompts: `lib/core/services/pdf_ingestion_service.dart` (lines 37, 64, 87, 116), `lib/features/mentor/services/mentor_service.dart` (148-153), `lib/features/teaching/services/prompts/prompts.dart` (68-69, 133).

### 4.2 Hardcoded English Fallbacks Bypassing Localization

Every `_localizationService?.someMethod() ?? 'Hardcoded English string'` pattern is a hardcoded fallback. The project has a localization system (`AppLocalizations`, `LocalizationService`), but these fallbacks will always render English regardless of user locale on null LocalizationService.

Key locations:
- `lib/core/services/plan_adapter.dart` lines 63-64, 73-74, 203-204, 207-208, 211
- `lib/core/services/engagement_scheduler.dart` lines 205, 223, 241, 265
- `lib/core/services/notification_service.dart` lines 61, 93, 137, ... (20+ fallbacks)
- `lib/core/services/study_progress_tracker.dart` lines 141-181
- `lib/core/services/personal_learning_plan_service.dart` lines 219-258
- `lib/core/services/mastery_integration_service.dart` lines 71-76
- `lib/core/services/answer_validation_service.dart` lines 182-194

### 4.3 Hardcoded Default URLs

| File | Line | URL |
|---|---|---|
| `lib/core/services/llm/llm_chat_service.dart` | 249, 293 | `'http://localhost:11434'` |
| `lib/core/services/llm/llm_chat_service.dart` | 354, 393 | `'https://api.openai.com/v1'` |
| `lib/core/services/llm/llm_embeddings_service.dart` | 23 | `'https://openrouter.ai/api/v1'` |
| `lib/core/services/llm/llm_embeddings_service.dart` | 26 | `'http://localhost:11434'` |
| `lib/core/services/llm/llm_embeddings_service.dart` | 29 | `'https://api.openai.com/v1'` |

These duplicate the default URL logic across multiple classes. They should be centralized in configuration.

### Acceptance Criteria

- Duplicate/near-duplicate system prompts are consolidated into a single source (e.g., `lib/core/services/llm/prompts.dart` or a constants file).
- Hardcoded LLM default URLs are centralized in `lib/core/constants/app_constants.dart` or an `ApiConfig` class.
- All hardcoded English fallback strings are either removed (replaced with nullable/wrapping to guarantee LocalizationService availability) or guaranteed to never be reachable through structured dependency injection.

---

## 5. NotificationService Singleton Hinders Test Isolation

**File:** `lib/core/services/notification_service.dart`, lines 7-13

```dart
static final NotificationService _instance = NotificationService._internal();
factory NotificationService() => _instance;
@visibleForTesting
FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
```

**Rationale:** The singleton pattern combined with a mutable `@visibleForTesting` field means any two tests sharing this service will interfere with each other's state. The `plugin` field being `@visibleForTesting` is a code smell signaling difficulty isolating the dependency.

Same pattern exists in `lib/core/services/student_id_service.dart` (lines 6-8).

### Acceptance Criteria

- `NotificationService` is converted to a injectable class (no static singleton). Existing consumers receive it through Riverpod or constructor injection.
- `StudentIdService` is similarly converted, or replaced with the `fixedStudentId` approach already used in widget tests per AGENTS.md.
- All existing tests continue to pass without relying on `@visibleForTesting` mutations.

---

## 6. Defects: Malformed CSV Export and Likely Incorrect Improvement Calculation

### 6.1 CSV Export Produces Malformed Rows

**File:** `lib/core/services/study_progress_tracker.dart`, lines 246-251, 256

```dart
csvLines.add('"$studentId","totalAttempts","${stats['totalAttempts']}")');  // stray `)` after `}"`
```

The closing `)` after the CSV quote `}"` appears on lines 246, 247, 249, 250, 251, and 256. Each of these will produce a CSV row ending with `")` which is not valid CSV syntax.

### 6.2 Potential Improvement Calculation Error

**File:** `lib/core/services/study_progress_tracker.dart`, line 128

```dart
return ((currentAccuracy - previousAccuracy / 100.0) * 100).roundToDouble();
```

Due to operator precedence, `/` binds tighter than `-`, so this evaluates as:
```
(currentAccuracy - (previousAccuracy / 100.0)) * 100
```

**File:** `lib/core/services/study_progress_tracker.dart`, line 109:
`previousAccuracy` is stored as `(accuracy * 100).round()` (line 109), e.g., `75` for 75%.
`currentAccuracy` is derived as a ratio (line 123-125), e.g., `0.75` for 75%.

With these values: `(0.75 - 75.0 / 100.0) * 100 = (0.75 - 0.75) * 100 = 0.0` — the intended result should be `0` (no change), so this happens to work. But if the data format ever changes (both stored as percentages or both as ratios), the formula silently produces wrong results due to the inconsistent unit handling.

### Acceptance Criteria

- CSV export lines 246-251 and 256 have stray `)` characters removed, producing valid CSV.
- Improvement calculation (`_calculateImprovement`) is corrected to handle both terms in consistent units (both as ratios or both as percentages).
- Unit tests verify the CSV output format and the improvement calculation with known inputs.

---

## 7. Eager Top-Level `database` Variable

**File:** `lib/core/providers/app_providers.dart`, lines 22-31

```dart
final database = DatabaseService(
  topicRepository: TopicRepository(),
  questionRepository: QuestionRepository(),
  // ... 9+ repositories
);
```

**Rationale:** This top-level variable is initialized at import time. Any file importing `app_providers.dart` triggers eager instantiation of all repositories and their Hive boxes. This causes unnecessary I/O at startup and makes test setup harder.

### Acceptance Criteria

- The `database` top-level variable is replaced with a Riverpod provider or lazy initialization pattern.
- Repositories are only instantiated when first requested, not at import time.
- All existing consumers of `database` are updated to use the new provider/lazy accessor.
