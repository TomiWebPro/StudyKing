# Architecture Overview

## High-Level Structure

StudyKing follows a **feature-first** architecture with a shared core layer. Each feature is self-contained with its own data layer, providers, services, and presentation.

```
lib/
├── main.dart                  # App entry point, initialization, tabs
├── core/                      # Shared infrastructure
│   ├── config/                # App configuration constants
│   ├── constants/             # Build/API/config constants
│   ├── data/                  # Core data layer (models, repos, DB init)
│   ├── errors/                # Result type, error codes, handlers
│   ├── providers/             # Riverpod providers (AI config, LLM, etc.)
│   ├── routes/                # Navigation routing
│   ├── services/              # Core services (LLM, engagement, progress, etc.)
│   ├── theme/                 # Material 3 theming
│   ├── utils/                 # Shared utilities
│   └── widgets/               # Shared UI components
├── features/                  # Feature modules
│   ├── dashboard/             # Student overview and metrics
│   ├── planner/               # Study planning and scheduling
│   ├── practice/              # Question practice and spaced repetition
│   ├── teaching/              # AI tutor mode
│   ├── mentor/                # AI mentor/assistant mode
│   ├── subjects/              # Subject and topic management
│   ├── questions/             # Question bank and management
│   ├── ingestion/             # Content upload and processing
│   ├── lessons/               # Lesson content and delivery
│   ├── sessions/              # Study session tracking
│   ├── settings/              # App settings and profile
│   ├── focus_mode/            # Focus timer and deep work
│   ├── llm_tasks/             # LLM task manager portal
│   ├── quickguide/            # Quick start guide
│   └── onboarding/            # First-run onboarding
└── l10n/                      # Localization (ARB files)
```

## Design Patterns

### Result Pattern
Public repository and service methods return `Result<T>` (a sealed class with `Success`/`Failure` variants). Exceptions are never thrown from public APIs. See [Error Handling](../core/error-handling.md).

### Repository Pattern
Data access is abstracted behind repository interfaces. Repositories manage Hive box initialization and provide CRUD operations. They are injected individually, not through a monolithic database service (though `DatabaseService` exists as an initialization coordinator).

### Provider Pattern (Riverpod)
Services and repositories are exposed through Riverpod providers. Providers are composed through dependency injection using `.family` and `.autoDispose` modifiers where appropriate. See [Coding Conventions](../development/conventions.md).

### Agent Pattern (LLM)
Complex AI interactions use an agent loop pattern:
- **Agent Loop:** Coordinates tool execution and LLM calls
- **Tools:** Individual capabilities (search questions, create plans, etc.)
- **Memory:** Conversation memory for context preservation
- **Idle Executor:** Automatic engagement without user prompt

## Two AI Modes

StudyKing has two distinct AI interaction systems:

1. **Teaching Mode** (active learning) — Interactive AI tutor during lessons
2. **Mentor Mode** (off-periods) — AI companion for planning, motivation, and support

See [Features Overview](features.md) for details.

## Data Flow

```
UI (Widgets/Screens)
    ↕ Riverpod Providers (state management)
    ↕ Services (business logic)
    ↕ Repositories (data access)
    ↕ Hive Boxes (persistent storage)
```

LLM calls flow through:
```
Feature Service → LlmService → LLM Provider API (OpenRouter/Ollama/OpenAI)
                                       ↕
                              LlmTaskManager (tracking)
                              LlmUsageMeter (token recording)
```

## App Initialization

The app boots in phases:

1. **Splash screen** shown immediately
2. **Hive initialization** — open all boxes, run migrations
3. **Repository initialization** — via `DatabaseService.init()`
4. **Settings loading** — profile, locale, API keys
5. **Student ID service** — identify the local user
6. **Engagement scheduler** — proactive nudging system
7. **AI configuration** — restore provider/model selections
8. **Post-init checks** — orphaned sessions, plan auto-extension, API key banner
