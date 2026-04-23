# StudyKing - Project Statement

## Overview
StudyKing is an adaptive learning platform built with Flutter, focusing on maximum learning efficiency through database-first design, AI-powered content generation, and continuous optimization.

## Core Philosophy
1. **Database-First Design** - Everything revolves around a structured database
2. **Maximum Learning Efficiency** - Optimize retention, understanding, practice, and time
3. **Continuous Iteration** - Never stop improving algorithms, UX, and systems

## Current Status

### Completed Features
- ✅ Flutter project setup with clean architecture at /home/tomi/Documents
- ✅ Hive database initialization and setup
- ✅ Core database layer with 9 models:
  - Topic, TopicProgress
  - Question, Answer
  - Source
  - StudentAttempt
  - TopicProgress
  - Lesson, LessonBlock
  - StudySession
- ✅ Repository layer with 8 repositories for CRUD operations
- ✅ Core enums: QuestionType, SourceType, LessonBlockType, GeneratedBy
- ✅ UI Screens implemented:
  - **Lesson Mode**: TopicListScreen, LessonListScreen, LessonDetailScreen
  - **Quick Guide Mode**: Chat-based interface (QuickGuideScreen)
  - **Planner Mode**: Schedule generator (PlannerScreen)
  - **Practice Mode**: Coming soon placeholder (PracticeScreen)
- ✅ 3-tab home navigation with TabController
- ✅ Cron job for continuous monitoring (every 20 minutes)
- ✅ Dart/Flutter environment setup (Flutter 3.41.7)

### Current State
- ✅ **Flutter analyze**: 9 warnings (all code-level warnings, no errors!)
- ✅ App runs successfully
- ✅ Database persistence working
- ✅ Navigation between screens functional

### Next Priorities (In Order)
1. Remove unused imports to achieve zero warnings
2. Implement full Question-Answer database system with variants
3. Create LLM validation pipeline for content generation
4. Develop PDF ingestion pipeline
5. Build adaptive practice engine (spaced repetition)
6. Implement lesson AI generation system
7. Add study progress analytics and tracking
8. Build multi-input answering system (text, drawing, canvas)
9. Configure LLM backend (OpenRouter/Ollama support)
10. Add voice input/output capabilities

### Known Issues/Technical Notes
- flutter_latex and flutter_canvas_drawer not available on pub.dev (using placeholders)
- form_builder_validators_localized not available (using standard FormBuilder)
- Android toolchain not configured (web-first approach)
- Chrome not available for web testing (use other browser)
- 9 minor warnings remaining (unused imports, dead code)

### Architectural Decisions
- **State Management**: Global `database` instance in main.dart (simple, effective)
- **Local Database**: Hive with TypedBox for type-safe storage
- **Architecture**: Clean Architecture with features directory structure
- **Project Structure**: lib/features/[feature]/presentation/
- **Deployment Target**: Web-first (no Android SDK available)
- **Theme**: Material 3 with Flutter default color scheme
- **Code Quality**: Zero errors, 9 warnings (approaching zero)

## Database Schema (Implemented)

### Core Tables (Hive Boxes)

#### Topic (TypeId: 0)
- id: String (primary key)
- title: String
- description: String
- parentId: String? (for hierarchy)
- sortOrder: int
- syllabusText: String
- childTopicIds: List<String>

#### Lesson (TypeId: 7)
- id: String (primary key)
- title: String
- topicId: String
- blocks: List<LessonBlock>
- difficulty: int
- generatedBy: GeneratedBy (ai/manual/hybrid)
- createdAt: DateTime

#### LessonBlock (TypeId: 6)
- type: LessonBlockType
- content: String
- order: int

#### Question, Answer, Source, StudentAttempt, StudySession
- All models implemented with proper Hive annotations
- Full CRUD operations via repositories
- Type-safe access through TypedBox

### Repository Layer
- TopicRepository, LessonRepository, QuestionRepository
- ResponseRepository, AttemptRepository, SessionRepository
- Clean separation of data access logic

## Project Structure Summary
```
lib/
├── main.dart                    # App entry, database init
├── core/
│   ├── data/
│   │   ├── models/              # 9 Hive models
│   │   ├── repositories/        # 8 repositories
│   │   ├── enums.dart           # 4 enums
│   │   └── core.dart            # Exports
│   └── theme/                   # App themes
└── features/
    ├── lessons/                 # Lesson Mode
    │   └── presentation/
    │       ├── topic_list_screen.dart
    │       ├── lesson_list_screen.dart
    │       └── lesson_detail_screen.dart
    ├── quickguide/              # Quick Guide Mode
    │   └── presentation/
    │       └── quick_guide_screen.dart
    ├── planner/                 # Planner Mode
    │   └── presentation/
    │       └── planner_screen.dart
    └── practice/                # Practice Mode
        └── presentation/
            └── practice_screen.dart
```

## Cron Job Status
- **Job ID**: 56f1590affb8
- **Name**: StudyKing Continuous Monitor
- **Schedule**: Every 20 minutes
- **Status**: Active and monitoring

---

## Notes
- This project statement should be updated after every iteration
- Log completed features, current issues, next priorities, and architectural changes
- **Current validation**: 9 issues found (all warnings, no errors) - approaching zero!
- Flutter analyze runs successfully with minimal warnings
