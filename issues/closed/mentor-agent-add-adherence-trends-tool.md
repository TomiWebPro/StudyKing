# Mentor Agent: Add Adherence Trends Query Tool

**Severity:** major
**Affected area:** Mentor Mode — Agent Toolset
**Reported by:** codebase audit

## Description

The mentor agent has only 6 tools, and none of them can query adherence trends, plan progress, or historical performance patterns. When a student asks "How am I doing with my study plan?" or "Am I keeping up with my schedule?", the agent must rely on pre-built context from `MentorContextBuilder` which provides a static snapshot — it cannot query detailed adherence trends or answer nuanced follow-up questions dynamically.

The context builder provides a one-shot summary (current day, average adherence, consecutive low days), but if the student asks "Which days did I miss last week?" or "Is my adherence getting better or worse?", the agent has no tool to look up this information.

## Expected behavior

The mentor agent should have a tool to query adherence data with flexible parameters:
- By date range (last 7 days, last 30 days, custom range)
- By trend direction (improving, declining, steady)
- By subject/topic breakdown
- With daily detail (which days were missed, adherence scores per day)

## Actual behavior

No adherence query tool exists. The agent can only reference the static context snapshot provided at chat start.

## Code analysis

- `lib/core/services/plan_adherence_orchestrator.dart:59-118` — `checkAdherence()` detects absences and low adherence periods
- `lib/core/services/plan_adherence_orchestrator.dart:185-246` — `getDailyAdherenceFeedback()` provides daily feedback text
- `lib/features/planner/services/planner_service.dart` — Has `checkAdherence()` method returning adherence data
- `lib/features/planner/data/repositories/plan_adherence_repository.dart` — Hive-backed adherence storage with date-range queries
- `lib/features/mentor/services/mentor_context_builder.dart:67-75` — Current context only provides average adherence, not trends
- `lib/features/mentor/services/tools/` — No adherence-related tool exists

## Suggested approach

1. **Create a new `GetAdherenceTrendsTool`** implementing `AgentTool`:
   ```dart
   class GetAdherenceTrendsTool extends AgentTool {
     name: 'get_adherence_trends'
     description: 'Get detailed adherence data and trends for the study plan.'
     parameters: {
       type: 'object',
       properties: {
         days: {type: 'integer', description: 'Number of past days to analyze', default: 14},
         subjectId: {type: 'string', description: 'Optional: filter by subject'},
       },
       required: [],
     }
   }
   ```

2. **Return structured adherence data**:
   ```json
   {
     "averageAdherence": 0.72,
     "trend": "declining",
     "lowAdherenceDays": ["2026-06-28", "2026-06-29"],
     "missedDays": 3,
     "perDayBreakdown": [
       {"date": "2026-06-28", "plannedMinutes": 120, "actualMinutes": 45, "adherence": 0.38},
       ...
     ],
     "weeklyAdherence": [0.85, 0.72, 0.65],
     "recommendation": "Your adherence has been declining for 3 days. Consider redistributing missed workload."
   }
   ```

3. **Register the tool** in `lib/core/providers/llm_agent_providers.dart` alongside existing tools

4. **Wire the tool** to `PlanAdherenceOrchestrator` or `PersonalLearningPlanService` for data access
```
