# Future Functionality: Enable AI-Powered Lesson Generation and Smart Study Planning

## Context

The codebase has a mismatch: advanced AI/LLM services exist in `lib/core/services/` but the primary learning UI flows (Planner, Lessons, Quick Guide) use hardcoded stubs or mock data. This creates a significant gap between the infrastructure and the user experience.

Key observations:

1. **`PlannerScreen`** (`lib/features/planner/presentation/planner_screen.dart:43-51`) generates placeholder topic strings like `'$course - Topic ${(dayIndex * sessionDuration) + 1}'` instead of real curriculum-aligned topics from the subject/topic graph.

2. **`QuickGuideScreen`** (`lib/features/quickguide/presentation/quick_guide_screen.dart:47-55`) has hardcoded `if/else` string matching for responses. The `LlmService` and `AiModelService` in `lib/core/services/` are never called.

3. **`PersonalLearningPlanService`** (`lib/core/services/personal_learning_plan_service.dart:260-274`) has `_getReadinessScore` and `_getReviewUrgency` returning hardcoded `0.5` and `0.3` instead of computing from actual mastery data.

4. **`QuestionGenerationService`** (`lib/core/services/question_generation_service.dart`) exists but has no UI integration path to generate questions for specific topics.

5. **Duplicate answer validation**: `lib/features/questions/services/answer_validator.dart` and `lib/features/practice/services/answer_validation_service.dart` do overlapping work with different class names, creating maintenance confusion.

6. **Session Tracker** (`lib/features/sessions/presentation/session_tracker_screen.dart:119-169`) requires manual entry of questions/correct answers. It should auto-capture results from `PracticeSessionScreen`.

7. **"Weak Areas" practice mode** (`lib/features/practice/presentation/practice_screen.dart:263`) has `onTap: null` — a stub with no implementation.

## Affected Files

Primary:
- `lib/features/planner/presentation/planner_screen.dart` — stub topic generation
- `lib/features/quickguide/presentation/quick_guide_screen.dart` — hardcoded responses
- `lib/core/services/personal_learning_plan_service.dart` — hardcoded readiness/urgency
- `lib/core/services/llm_service.dart` — unused by UI
- `lib/core/services/ai_model_service.dart` — unused by UI
- `lib/core/services/question_generation_service.dart` — unused by UI

Secondary:
- `lib/features/practice/presentation/practice_screen.dart` — missing weak areas mode
- `lib/features/sessions/presentation/session_tracker_screen.dart` — manual session logging
- `lib/features/practice/services/answer_validation_service.dart` — duplicate logic
- `lib/features/questions/services/answer_validator.dart` — duplicate logic
- `lib/features/lessons/presentation/lesson_detail_screen.dart` — passive read-only

## Rationale

The value proposition of StudyKing is an AI-powered study assistant. Users expect intelligent, adaptive study plans and content generation. The current implementation:
- Generates meaningless placeholder schedules
- Returns hardcoded AI responses that don't actually help
- Computes nothing useful from the mastery graph
- Leaves major practice modes unimplemented

This makes the "AI study assistant" promise feel hollow. Wiring up the existing AI services to the UI would deliver the core value proposition with minimal new code.

## Acceptance Criteria

1. **Smart Topic Generation for Study Plans**: `PlannerScreen` requests actual topic suggestions from `QuestionGenerationService` or `LlmService` based on the course name, using the subject/topic repository to pull real curriculum data. Generated plans reference real topic IDs, not placeholder strings.

2. **AI Quick Guide Integration**: `QuickGuideScreen` routes messages to `LlmService` or `AiModelService` instead of hardcoded string matching. The Quick Guide becomes a genuine AI assistant that can explain concepts, quiz users, and provide contextual help tied to their subjects.

3. **Computed Mastery Metrics**: `PersonalLearningPlanService._getReadinessScore` and `_getReviewUrgency` compute values from actual `MasteryState` data (accuracy trends, streak, time since last review, spaced repetition intervals) instead of returning static defaults.

4. **Auto-capture Practice Results**: Session tracking automatically records questions answered and accuracy from `PracticeSessionScreen` without requiring manual entry in `_SessionEndDialog`.

5. **Weak Areas Practice Mode**: The "Weak Areas" practice mode in `PracticeScreen` is implemented using `MasteryGraphService.getWeakTopics()` to surface topics with low accuracy/high review urgency for targeted practice.

6. **Consolidate Answer Validation**: Merge the duplicate `QuestionAnswerValidator` and `AnswerValidationService` into a single service to reduce maintenance burden and confusion.

## Implementation Hints

- Start by instrumenting `LlmService` to see what interface it exposes, then create a thin adapter to connect it to `QuickGuideScreen`
- Use the existing `MasteryGraphService.getWeakTopics()` for the weak areas mode
- The duplicate answer validation services can be merged by having `AnswerValidationService` become the single source of truth, with `QuestionAnswerValidator` refactored to a private inner class or utility
- Session auto-capture requires passing session results from `PracticeSessionScreen` to `SessionTrackerScreen` via a callback or state management solution