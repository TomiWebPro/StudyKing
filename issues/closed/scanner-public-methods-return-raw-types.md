# [Scanner] Public methods returning raw types instead of `Result<T>`

**Source:** automatic scanner
**Severity:** major

## Finding

The project convention (AGENTS.md) requires that all public repository and service method return types must be `Result<T>`. Multiple services and repositories across the codebase violate this rule by returning raw types directly.

## Locations

### Service layer violations

| File | Methods | Return type (should be `Result<T>`) |
|---|---|---|
| `lib/features/lessons/services/lesson_service.dart` | `getLessonsForStudent`, `getLessonsByTopic`, `getTopicsWithLessons`, `getLessonCountBySubject`, `getCompletionRate`, `getTotalStudyMinutes`, `getRemainingLessonCount`, `getProgressBySubject`, `getRecentLessons`, `getUpcomingLessons` | `Future<List<Session>>`, `Future<List<Topic>>`, etc. |
| `lib/core/services/engagement_scheduler.dart` | `updateSettings`, `updateLocalization`, `init`, `runDailyChecksNow`, `getOverworkNudge`, `getRevisionNudges`, `getPlanAdjustmentNudge`, `getWeeklyDigest`, `getNudgeHistory` | `void`, `Future<void>`, `Future<List<EngagementNudgeModel>>`, `Future<String>` |
| `lib/core/services/progress_export_service.dart` | `exportComprehensiveJSON`, `exportComprehensiveCSV`, `exportComprehensivePDF`, `shareComprehensiveCSV`, `shareComprehensiveJSON`, `shareComprehensivePDF` | `Future<String>`, `Future<List<int>>`, `Future<void>` |
| `lib/features/practice/services/exam_session_service.dart` | `selectQuestions`, `finishExam`, `getSavedExamResults`, `startExam`, `cancelExam` | `List<Question>`, `Future<ExamResult>`, `Future<List<Map<String, dynamic>>>`, `void` |
| `lib/features/practice/services/readiness_scorer.dart` | `scoreQuestions` | `Future<List<ScoredQuestion>>` |
| `lib/features/focus_mode/services/focus_practice_service.dart` | `getDueQuestions`, `getWeakAreaQuestions`, `getQuestionsForSessionType` | `Future<List<Question>>` |
| `lib/features/llm_tasks/services/llm_task_service.dart` | `getAllTasks`, `getActiveTasks`, `getTasksByFeature`, `getTasksByStatus`, `getFilteredTasks`, `createTask` | `List<LlmTask>`, `String` |
| `lib/features/sessions/services/study_timer_service.dart` | `reconcileElapsedMs`, `pauseSession`, `resumeSession` | `void` |
| `lib/features/sessions/services/session_export_service.dart` | `sessionsToCSV`, `sessionsToJSON`, `sessionsToPDF` | `String`, `List<Map<String, dynamic>>`, `Future<List<int>>` |
| `lib/features/settings/services/data_backup_service.dart` | `collectAllBoxData` | `Map<String, List<Map<String, dynamic>>>` |
| `lib/features/lessons/services/lesson_agent_service.dart` | `generateLesson` | `Future<Lesson?>` |
| `lib/core/services/plan_adherence_orchestrator.dart` | `getDailyAdherenceFeedback` | `Future<String?>` |
| `lib/core/services/mastery_graph_service.dart` | `init` | `Future<void>` |

### Repository layer violations

| File | Method | Return type (should be `Result<T>`) |
|---|---|---|
| `lib/core/data/repositories/session_repository.dart:225` | `getConsecutiveStudyDays` | `Future<int>` |
| `lib/core/data/repositories/mastery_state_repository.dart:11` | `init` | `Future<void>` |
| `lib/core/data/repositories/question_mastery_state_repository.dart:11` | `init` | `Future<void>` |
| `lib/core/data/repositories/attempt_repository.dart:9` | `init` | `Future<void>` |
| `lib/features/focus_mode/data/repositories/focus_session_repository.dart:12` | `init` | `Future<void>` |

## Recommendation

These methods should be refactored to return `Result<T>` (e.g., `Future<Result<List<Session>>>` instead of `Future<List<Session>>`). Internal errors should be captured and propagated through `Result.failure()` rather than throwing or returning empty collections silently. This change improves error transparency and aligns with the project's established error handling pattern.
