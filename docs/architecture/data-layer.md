# Data Layer

## Storage

StudyKing uses **Hive** as its local NoSQL database. All data is stored locally on the device.

### Hive Boxes

Each logical entity has its own Hive box. Box names are defined in `lib/core/data/hive_box_names.dart`:

| Box Name | Contents |
|---|---|---|
| `agent_memory` | LLM agent conversation memory |
| `answers` | Student answer records |
| `attempts` | Student answer attempts |
| `badges` | Achievement badges earned |
| `conversations` | Tutor conversation history |
| `dashboard_layout_prefs` | Dashboard layout customization |
| `db_version` | Database schema version |
| `engagement_nudges` | Engagement nudge records |
| `exam_results` | Exam simulation results |
| `focus_sessions` | Focus timer session records |
| `learning_plans` | Study plans |
| `lessonBlocks` | Lesson content blocks |
| `lessons` | Lesson plans and content |
| `llm_tasks` | LLM inference task tracking |
| `llm_usage_records` | LLM token usage history |
| `mastery_improvement_metrics` | Mastery improvement delta metrics |
| `mastery_states` | Per-topic mastery tracking |
| `pending_actions` | Mentor-generated action items |
| `plan_adherence` | Plan adherence snapshots |
| `plan_adherence_metrics` | Plan adherence calculation metrics |
| `plan_advisor_suggestions` | AI planner suggestions |
| `progress` | Study progress tracking |
| `profile` | User profile data |
| `questions` | Question bank (all questions) |
| `question_evaluations` | Question evaluation results |
| `question_mastery_states` | Per-question mastery states |
| `roadmaps` | Learning roadmaps |
| `sessions` | Study session records (legacy) |
| `sessions_typed` | Study session records (typed) |
| `settings` | App settings, API keys |
| `sources` | Uploaded/ingested content |
| `student_availability` | Student scheduling availability |
| `student_id` | Local student identifier |
| `subjects` | Subject definitions |
| `tasks` | Planner task items |
| `topic_dependencies` | Prerequisite topic relationships |
| `topics` | Topic trees with dependencies |
| `tutor_sessions` | Active/completed tutor sessions |

### Hive Type Adapters

Custom type adapters are registered in `lib/core/data/hive_type_ids.dart`. Models stored in Hive must be registered before use:

```dart
Hive.registerAdapter(AccessibilityPreferencesAdapter());
Hive.registerAdapter(UserProfileAdapter());
Hive.registerAdapter(MasteryImprovementMetricAdapter());
```

## Repositories

Repositories provide a clean API over Hive box operations. They follow the Result pattern — all public methods return `Result<T>`.

### Core Repositories (`lib/core/data/repositories/`)

| Repository | Responsibility |
|---|---|
| `TopicRepository` | Topic CRUD, list by subject |
| `AttemptRepository` | Student attempts, query by question/date |
| `SessionRepository` | Study sessions, duration totals |
| `EngagementNudgeRepository` | Nudge records, today's count |
| `MasteryStateRepository` | Topic-level mastery tracking |
| `PlanAdherenceRepository` | Plan adherence snapshots |
| `QuestionMasteryStateRepository` | Question-level mastery |

### Feature Repositories (`lib/features/*/data/repositories/`)

| Feature | Repository |
|---|---|
| `subjects/` | `SubjectRepository` |
| `questions/` | `QuestionRepository` |
| `lessons/` | `LessonRepository` |
| `practice/` | `MasteryGraphRepository`, `QuestionEvaluationRepository`, `TopicDependencyRepository` |
| `planner/` | `PlanRepository`, `RoadmapRepository`, `PendingActionRepository`, `AdvisorSuggestionsRepository`, `StudentAvailabilityRepository` |
| `teaching/` | `ConversationRepository`, `TutorSessionRepository` |
| `settings/` | `SettingsRepository` |
| `ingestion/` | `SourceRepository` |
| `dashboard/` | `BadgeRepository` |
| `focus_mode/` | `FocusSessionRepository` |

## Models

Models are plain Dart classes stored in Hive. They typically include:
- `@HiveType()` and `@HiveField()` annotations
- `toJson()` / `fromJson()` serialization
- `copyWith()` for immutable updates

### Key Models

| Model | Location | Purpose |
|---|---|---|
| `Subject` | `core/data/models/` | Subject/course definition |
| `Topic` | `core/data/models/` | Topic within a subject |
| `Question` | `core/data/models/` | Question with content and metadata |
| `StudentAttempt` | `features/practice/data/models/` | Student answer to a question |
| `Session` | `core/data/models/` | Study session record |
| `Lesson` | `features/lessons/data/models/` | Lesson with content blocks |
| `LessonBlock` | `features/lessons/data/models/` | Lesson content block |
| `PersonalLearningPlan` | `features/planner/data/models/` | Full study plan |
| `Roadmap` | `features/planner/data/models/` | Milestone-based pathway |
| `PendingAction` | `features/planner/data/models/` | Mentor-generated action items |
| `PlanAdherenceMetric` | `features/planner/data/models/` | Plan adherence calculation data |
| `PlanAdvisorSuggestion` | `features/planner/data/models/` | AI planner suggestions |
| `EngagementNudge` | `features/planner/data/models/` | Engagement nudge record |
| `StudentAvailability` | `features/planner/data/models/` | Scheduling availability |
| `TutorSession` | `features/teaching/data/models/` | Active tutoring session |
| `ConversationMessage` | `features/teaching/data/models/` | Chat message in tutor |
| `Source` | `core/data/models/` | Uploaded study material |
| `MasteryState` | `core/data/models/` | Topic mastery snapshot |
| `QuestionMasteryState` | `core/data/models/` | Per-question mastery |
| `MasteryImprovementMetric` | `core/data/models/` | Mastery change over time |
| `Badge` | `features/dashboard/data/models/` | Achievement badge |
| `FocusSession` | `features/focus_mode/data/models/` | Focus timer session |
| `UserProfile` | `features/settings/data/models/` | User profile and preferences |
| `AccessibilityPreferences` | `features/settings/data/models/` | Accessibility settings |
| `OnboardingState` | `features/onboarding/data/models/` | Onboarding completion state |

## DatabaseService

`DatabaseService` in `lib/core/data/database_service.dart` acts as an **initialization coordinator** only. It collects all repositories and calls `.init()` on each to open their Hive boxes. Individual repositories should be injected independently in production code.

## Migration

Database migrations are handled by `lib/core/data/database_migration.dart`. The migration system runs at startup to evolve the data schema as the app changes.
