# StudyKing Documentation

StudyKing is a Flutter-based, AI-native learning platform designed to maximize student learning efficiency and act as a complete long-term study companion.

## Documentation Index

### Architecture

| Document | Description |
|---|---|
| [Architecture Overview](architecture/overview.md) | High-level architecture, folder structure, design patterns |
| [Features Overview](architecture/features.md) | Overview of all features and their responsibilities |
| [Data Layer](architecture/data-layer.md) | Database, repositories, models, and Hive persistence |

### Core

| Document | Description |
|---|---|
| [LLM Integration](core/llm-integration.md) | AI provider support, chat service, agent system, token tracking |
| [Error Handling](core/error-handling.md) | Result pattern, error codes, logging conventions |
| [Routing & Navigation](core/routing.md) | Route definitions, tab navigation, navigation args |
| [Theming & Accessibility](core/theme.md) | Theme system, dark/light mode, accessibility features |

### Features

| Document | Description |
|---|---|
| [Dashboard](features/dashboard.md) | Home screen, progress overview, stats, badges, export |
| [Planner](features/planner.md) | Study planning, roadmaps, scheduling, adherence tracking |
| [Teaching / Tutor Mode](features/teaching.md) | Interactive AI tutoring, lesson delivery, conversation management |
| [Mentor Mode](features/mentor.md) | AI mentor, engagement nudges, wellbeing support |
| [Practice & Spaced Repetition](features/practice.md) | Practice sessions, spaced repetition, mastery tracking |
| [Subjects](features/subjects.md) | Subject/topic management, seed curricula, dependency tracking |
| [Questions](features/questions.md) | Question bank, input widgets, evaluation, export/import |
| [Content Ingestion](features/ingestion.md) | File upload, OCR, web scraping, content pipeline |
| [Lessons](features/lessons.md) | Lesson content, blocks, agent generation, session querying |
| [Sessions](features/sessions.md) | Study timer, session history, analytics, data export |
| [Settings](features/settings.md) | App config, profile, AI providers, accessibility, data backup |
| [Focus Mode](features/focus_mode.md) | Pomodoro timer, inline practice, session tracking |
| [LLM Task Manager](features/llm_tasks.md) | AI inference monitoring, token usage, task tracking |
| [Quick Guide](features/quickguide.md) | In-app help, mode navigation, suggested prompts |
| [Onboarding](features/onboarding.md) | First-run wizard, API key setup, completion tracking |

### Development

| Document | Description |
|---|---|
| [Setup Guide](development/setup.md) | Getting started, prerequisites, running the app |
| [Coding Conventions](development/conventions.md) | Code style, naming, provider patterns, i18n rules |
| [Testing Guide](development/testing.md) | Test structure, conventions, provider testing requirements |
| [i18n Guide](i18n.md) | Internationalization, adding new languages, ARB conventions |

## Key Technologies

- **Framework:** Flutter (Material Design 3)
- **State Management:** Riverpod (flutter_riverpod)
- **Database:** Hive (local NoSQL storage)
- **AI Providers:** OpenRouter, OpenAI, Ollama (model-agnostic)
- **Localization:** Flutter intl with ARB files (EN, ES)
- **Error Handling:** Sealed `Result<T>` pattern (no exceptions in public API)
