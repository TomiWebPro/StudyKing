# Mentor Agent: Add Plan Adjustment/Modification Tool

**Severity:** major
**Affected area:** Mentor Mode — Agent Toolset
**Reported by:** codebase audit

## Description

The mentor agent has a `create_plan` tool that can create new study plans, but it **cannot modify, extend, or adjust existing plans**. When a student says "Can we slow down the pace?" or "I need to extend my plan by two weeks" or "Can we add more practice time?", the agent has no tool to make these changes.

The planner service already supports all these operations (`adjustPace()`, `extendPlan()`, `redistributeMissedWorkload()`, `regeneratePlan()`), but the agent has no access to them. The agent currently relies on `MentorScheduleHandler.extractScheduleProposal()` and keyword-based intent detection to create `PlanProposal` objects — but these are just suggestions displayed to the user, not actual plan modifications.

## Expected behavior

The mentor agent should be able to:
- Adjust the daily pace (more/less time per day)
- Extend or shorten the plan duration
- Redistribute missed workload across remaining days
- Regenerate the plan with new parameters
- Add or remove subjects from an existing multi-subject plan
- Change daily targets (questions per day, minutes per day)

## Actual behavior

No plan modification tool exists. The `CreatePlanTool` only creates new plans from scratch. All plan adjustments require the user to manually navigate to the Planner screen.

## Code analysis

- `lib/features/planner/services/planner_service.dart:598-669` — `adjustPace()` scales daily targets
- `lib/features/planner/services/personal_learning_plan_service.dart:681-749` — `redistributeMissedWorkload()` spreads missed hours
- `lib/features/planner/services/personal_learning_plan_service.dart:751-787` — `extendPlan()` adds days
- `lib/features/planner/services/planner_service.dart:149-200` — `regeneratePlan()` creates new plan from existing parameters
- `lib/features/mentor/services/tools/create_plan_tool.dart` — Only creates new plans

## Suggested approach

1. **Create a new `ModifyPlanTool`** implementing `AgentTool`:
   ```dart
   class ModifyPlanTool extends AgentTool {
     name: 'modify_plan'
     description: 'Modify an existing study plan: adjust pace, extend duration, redistribute missed workload, or regenerate.'
     parameters: {
       type: 'object',
       properties: {
         action: {
           type: 'string',
           enum: ['adjust_pace', 'extend', 'redistribute', 'regenerate', 'change_targets'],
           description: 'What modification to perform'
         },
         planId: {type: 'string', description: 'Plan ID (omit to use current active plan)'},
         newTargetMinutesPerDay: {type: 'integer', description: 'For adjust_pace: new daily target in minutes'},
         extendDays: {type: 'integer', description: 'For extend: number of days to add'},
         newDailyQuestions: {type: 'integer', description: 'For change_targets: new daily question target'},
         newDailyMinutes: {type: 'integer', description: 'For change_targets: new daily minute target'},
         redistributionStrategy: {
           type: 'string',
           enum: ['next_3_days', 'all_remaining'],
           default: 'next_3_days',
         },
       },
       required: ['action'],
     }
   }
   ```

2. **Return confirmation with updated plan summary**:
   ```json
   {
     "success": true,
     "planId": "plan_001",
     "newTotalDays": 62,
     "newTargetMinutesPerDay": 45,
     "newEndDate": "2026-09-30",
     "message": "Plan extended by 2 weeks. New target is 45 min/day."
   }
   ```

3. **Wire through `PlannerService`** — all required methods already exist
