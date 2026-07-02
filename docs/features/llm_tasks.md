# LLM Tasks Feature

## Overview

The LLM Tasks feature tracks and manages asynchronous AI (LLM) operations across the app. It provides a centralized view of all queued, running, completed, failed, and cancelled AI tasks, along with token usage and estimated cost metrics per feature.

## Key Files

| Layer | Files |
|---|---|
| Services | `LlmTaskService` |
| Providers | `llmTaskServiceProvider`, `allTasksProvider`, `activeTasksProvider`, `filteredTasksProvider`, `taskTokenUsageProvider`, `taskCostProvider`, `totalTaskTokensProvider`, `totalTaskCostProvider`, `LlmTaskFilter` |
| Screens | `LlmTaskManagerScreen` |

## Core Services

### LlmTaskService

Wraps the core `LlmTaskManager` and provides query and lifecycle methods:

- `getAllTasks()` — Return all tasks
- `getActiveTasks()` — Return running + queued tasks
- `getTasksByFeature(feature)` — Filter by feature name
- `getTasksByStatus(status)` — Filter by status
- `getFilteredTasks({feature, status})` — Combined filter
- `createTask({feature, modelId})` — Queue a new LLM task
- `startTask(taskId)` — Mark as running
- `completeTask(taskId, {tokensUsed, estimatedCost})` — Mark as done
- `failTask(taskId, error)` — Mark as failed
- `cancelTask(taskId)` — Cancel a queued/running task
- `retryTask(taskId)` — Re-queue a failed task
- `totalTokenUsage` / `totalEstimatedCost` — Aggregated metrics
- `tokenUsageByFeature` / `costByFeature` — Per-feature breakdown

## Key Models

| Model | Purpose |
|---|---|
| `LlmTask` (from core) | Task with id, feature, modelId, status, timestamps, tokensUsed, estimatedCost, error |
| `LlmTaskStatus` | Enum: queued, running, done, failed, cancelled |
| `LlmTaskFilter` | Filter model with optional feature and status fields |

## Key UI Features

- **LlmTaskManagerScreen:** Lists all tasks in reverse chronological order with status icons, model info, timestamps, token/cost badges, and retry/cancel actions
- **Token Usage Meter:** Summary bar showing total tokens, cost, completed count, failed count, and completion progress bar
- **Failure Notifications:** When a task fails, a snackbar with retry action is shown
- **Empty State:** Displays a check-circle icon and "no tasks" message when the task list is empty
