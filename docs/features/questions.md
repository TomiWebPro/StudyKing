# Questions Feature

## Overview

The Questions feature manages a local question bank with support for multiple question types (single choice, multiple choice, text, drawing, graphing, audio, file upload, math expression). It provides question creation, editing, filtering, batch import/export, markscheme evaluation, and a card-based practice interface.

## Key Files

| Layer | Files |
|---|---|
| Repositories | `QuestionRepository` |
| Models | `QuestionEvaluation`, `EvaluationStep`, `Stroke`, `DrawingPoint`, `DrawingTool`, `UndoableStroke` |
| Adapters | `QuestionEvaluationAdapter`, `EvaluationStepAdapter`, `MarkschemeAdapter`, `MarkSchemeStepAdapter` |
| Providers | `questionRepositoryProvider`, `sourceRepositoryProvider` |
| Screens | `QuestionBankScreen` |
| Widgets | `QuestionCardWidget`, `SingleAnswerWidget`, `CanvasDrawingWidget`, `GraphDrawingWidget`, `AudioRecordingWidget`, `FileUploadWidget`, `MathExpressionWidget`, `MathInputToolbar` |
| Painters | `DrawingPainter`, `GridPainter` |

## Core Services

### QuestionRepository

Extends `Repository<Question>` for Hive-backed CRUD:

- `init()` — Open the questions Hive box
- `create(question)` — Save a new question
- `getByTopic(topicId)` / `getBySubject(subjectId)` — Filter queries
- `getBySubjectAndTopic(subjectId, topicId)` — Combined filter
- `getByType(type)` — Filter by `QuestionType`
- `getQuestionsWithMarkschemes(subjectId)` — Questions that have markschemes
- `updateMarkscheme(questionId, markscheme)` — Update a markscheme

### QuestionExportUtils / QuestionImportUtils

Utility classes (from core) for CSV and JSON export/import of questions with share support.

## Key Models

| Model | Purpose |
|---|---|
| `QuestionEvaluation` | Hive-stored evaluation config with `correctAnswer`, `acceptableAnswers`, `evaluationType`, `steps`, `maxPoints` |
| `EvaluationType` | Enum: exactMatch, acceptableMatch, fuzzyMatch, partialMatch, stepBased |
| `EvaluationStep` | Per-step evaluation with stepNumber, requiredAnswer, points, partialCredit |
| `Stroke` / `DrawingPoint` | Canvas drawing data for freehand/graph questions |
| `DrawingTool` | Enum: freehand, line, rectangle, circle, plotPoint, eraser |
| `QuestionWithMarkscheme` | Composite of a `Question` and its `Markscheme` |

## Key Input Widgets

| Widget | Purpose |
|---|---|
| `SingleAnswerWidget` | Radio/checkbox option selection for single/multi-choice questions |
| `CanvasDrawingWidget` | Freehand drawing canvas with tool selection (pen, eraser, shapes) |
| `GraphDrawingWidget` | Grid-backed drawing canvas for plotting points and graphing |
| `AudioRecordingWidget` | Voice answer recording with microphone input |
| `FileUploadWidget` | File picker for uploading answer documents |
| `MathExpressionWidget` | Renders formatted math expressions with symbols |
| `MathInputToolbar` | Toolbar with math symbol buttons (Greek letters, integrals, fractions, operators) |
| `QuestionCardWidget` | Composite card that renders the appropriate input widget based on question type |

## Key UI Features

- **QuestionBankScreen:** Full CRUD screen with search, subject/type/source/model filters, selection mode for batch delete, and export (CSV/JSON)
- **Create/Edit Dialog:** Inline dialog with fields for text, subject, topic, type, difficulty, sources, options with radio/checkbox correct answer selection, and explanation
- **Markscheme Evaluation:** Supports exact, fuzzy, step-based, and acceptable-answer matching via `AnswerComparator`
- **RefreshIndicator** for reloading the question list
- **Empty and error states** with retry support
