# Subjects Feature

## Overview

The Subjects feature manages academic subjects and their topic hierarchies. Users can create subjects from seed curricula (IB, AP, A-Levels), organize topics with dependency relationships, track topic progress, and view subject-level analytics including session history, practice stats, and lesson associations.

## Key Files

| Layer | Files |
|---|---|
| Repositories | `SubjectRepository` |
| Models | `TopicDependency`, `TopicProgress` |
| Adapters | `TopicDependencyAdapter` |
| Providers | `subjectRepositoryProvider`, `subjectsRepositoryProvider`, `subjectsListProvider`, `topicRepositoryProvider`, `subjectSessionCountsProvider` |
| Screens | `SubjectListScreen`, `SubjectDetailScreen`, `SubjectSelectionScreen` |
| Widgets | `SubjectFormWidgets` (syllabus picker, color picker), `SubjectTopicsTab`, `SubjectLessonsTab`, `SubjectPracticeTab`, `SubjectHistoryTab`, `SubjectStatsTab` |
| Dialogs | `TopicDependencyDialog`, `TopicEditDialog` |

## Core Services

### SubjectRepository

Extends `Repository<Subject>` for Hive-backed CRUD:

- `init()` — Open the subjects Hive box
- `create(subject)` — Save a new subject
- `getWithTopics(topicIds)` — Find subjects that reference given topic IDs
- `addTopicToSubject(subjectId, topicId)` / `removeTopicFromSubject(subjectId, topicId)` — Manage topic membership
- `updateColor(subjectId, colorHex)` — Update subject color

### CurriculumSeedData

Static seed data with entries for IB Chemistry, IB Physics, IB Biology, IB Mathematics, IB English, AP Biology, AP Chemistry, and AP Physics. Each entry contains a hierarchy of `SeedTopic` objects with titles, descriptions, syllabus text, and subtopics.

## Key Models

| Model | Purpose |
|---|---|
| `Subject` (from core) | Subject with id, name, code, teacher, color, topicIds, syllabus, description |
| `TopicDependency` | Hive-stored dependency graph: prerequisites, downstream topics, syllabus weight, mastery threshold, estimated time/questions, sort order |
| `TopicProgress` | Per-topic progress tracking: questions answered, correct answers, average time, accuracy |
| `CurriculumSeedEntry` | Seed curriculum entry with name and hierarchical topic list |
| `SeedTopic` | Seed topic with title, description, syllabus text, sort order, and nested subtopics |

## Key UI Features

- **SubjectListScreen:** Lists all subjects with color-coded cards, session counts, and quick-add FAB
- **SubjectSelectionScreen:** Create or edit subjects with name, color, syllabus picker, and optional seed curriculum auto-population of topics
- **SubjectDetailScreen:** Tabbed detail view with 6 tabs:
  - **Topics Tab:** Topic tree with progress bars, dependency visualization, and edit/dependency dialogs
  - **Lessons Tab:** Lessons associated with this subject
  - **Practice Tab:** Practice sessions filtered by subject
  - **History Tab:** Session history filtered by subject
  - **Stats Tab:** Performance metrics, accuracy trends, and time distribution
- **SubjectFormWidgets:** Reusable syllabus dropdown (pre-populated with AP, A-Level, IB curricula), color picker with swatches
- **TopicDependencyDialog:** Visual editor for prerequisite/downstream relationships between topics
- **TopicEditDialog:** Inline editor for topic metadata, difficulty, and estimated effort

## Workflow

1. **Creation:** User adds a subject via `SubjectSelectionScreen`, optionally selecting a seed curriculum that auto-generates topics
2. **Topic Management:** Topics can be added, edited, reordered, and linked with dependencies in the detail screen
3. **Progress Tracking:** As the student practices, `TopicProgress` is updated per topic with accuracy and volume metrics
4. **Dependency Analysis:** `TopicDependency.isReady()` checks if prerequisites are met; `calculatePriority()` ranks topics by mastery gap, prerequisite status, and downstream impact
5. **Seed Data:** `CurriculumSeedData` provides ready-made topic hierarchies for common curricula to accelerate setup
