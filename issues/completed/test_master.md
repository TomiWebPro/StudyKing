# Test Coverage Audit: Questions Feature — Gaps, Misplaced Tests, and Overly Basic Coverage

## Context

The questions feature (`lib/features/questions/`) is the core instructional component of StudyKing, handling 8+ question types (singleChoice, multiChoice, typedAnswer, mathExpression, essay, canvas, graphDrawing, stepByStep). A thorough audit of its 7 test files (~2,781 lines) and surrounding test infrastructure revealed: a production rendering bug for `stepByStep` questions, a memory leak in `AnswerValidationService`'s static cache, a test file that superficially only checks widget existence (440 lines of shallow assertions), structurally misplaced core-model tests, and two entirely untested features.

---

## Issues Found

### 1. Production Bug: `stepByStep` Question Type Falls to "Not Supported" (Missing Test Scenario)

**Affected file:** `lib/features/questions/ui/widgets/question_card_widget.dart:214`

The `_buildQuestionContent` switch statement handles: singleChoice, multiChoice, typedAnswer, mathExpression, essay, canvas, graphDrawing — but NOT `stepByStep`. It falls to the `default` branch rendering "This question type is not yet supported in this view." The type label IS defined (line 379: "Step-by-Step"), so users see a label suggesting the type works but get a broken UI.

**Root cause:** No test covered the `stepByStep` rendering path. The test file (`question_card_widget_test.dart`) tests the label (line 410-414) but never tests the content rendering. A simple `testWidgets('renders step-by-step content')` would have caught this before deployment.

**Action:** Add a switch case for `QuestionType.stepByStep` in `_buildQuestionContent` and add corresponding widget tests that verify actual content renders.

---

### 2. Memory Leak: `AnswerValidationService` Static Cache Has No Eviction Policy

**Affected file:** `lib/features/questions/services/answer_validator.dart:36-37`

```dart
static final Map<String, QuestionAnswerValidator> _cache = {};
static final Map<String, String> _cacheSignatures = {};
```

These static `Map` fields grow unboundedly for the lifetime of the application process. Every unique question ID ever encountered accumulates an entry. In a long tutoring session or repeated practice runs, this leaks memory. There is no:
- Maximum size limit
- LRU/aging eviction
- `clear()` or reset mechanism
- Any test verifying cache behavior under memory pressure or sequential question loads

**Action:** Implement a cache eviction strategy (e.g., `LinkedHashMap` with `maxSize`, or `sweep` on configurable threshold) and add tests that verify:
- Cache does not grow beyond a configured limit
- Old entries are evicted when limit is exceeded
- Evicted entries are re-created correctly on subsequent access

---

### 3. Overly Basic Tests: `math_expression_widget_test.dart` (440 Lines, Nearly Zero Behavior Verification)

**Affected file:** `test/features/questions/ui/widgets/math_expression_widget_test.dart`

This file contains ~40 individual `testWidgets` blocks, but **every single one** only asserts that `find.byType(RichText)` finds at least one widget. None verify:
- The actual text content of the generated `TextSpan`s
- Font styling (italic for variables, bold for numbers, superscript for exponents)
- Color coding (deep orange for decimals, default for operators)
- Correct substitution of LaTeX-like command tokens (e.g., `\sqrt{x}` should produce √ symbol, `\frac{a}{b}` should produce numerator/denominator)
- The `isSolution` prop's effect on Container decoration/color
- The `showPrefix` prop beyond checking the first child exists

This is **40 structurally identical tests** that add very little value beyond "the widget doesn't crash." A single test verifying one rendered `TextSpan`'s properties would be more valuable than all 40 combined.

**Action:** Replace/reduce the shallow rich-text-existence checks with targeted tests that verify parsed output correctness (span text, style, nesting), removing the ~30 tests that provide zero behavioral coverage.

---

### 4. Misplaced Test Files: Core Model Tests in Feature Directory

**Affected files:**
- `test/features/questions/models/markscheme_model_test.dart` — tests `lib/core/data/models/markscheme_model.dart`
- `test/features/questions/services/answer_test.dart` — tests `lib/core/services/answer_validation_service.dart`

The project follows a `test/core/` ↔ `test/features/` split. Core data models and services should have tests under `test/core/data/models/` and `test/core/services/` respectively. These two files are the only core-level tests misplaced under `test/features/questions/`. This creates inconsistency: future developers might hesitate to add core tests, and coverage reports misattribute test ownership.

**Action:** Move `markscheme_model_test.dart` to `test/core/data/models/markscheme_model_test.dart` and `answer_test.dart` to `test/core/services/answer_validation_service_test.dart`. Keep a forwarding import (or just move and update CI paths).

---

### 5. Entirely Untested Features: `ingestion` and `llm_tasks`

**Affected directories:**
- `lib/features/ingestion/` (3 source files: `ingestion.dart`, `upload_screen.dart`, `content_pipeline.dart`) — **zero test files**
- `lib/features/llm_tasks/` (1 source file: `llm_task_manager_screen.dart`) — **zero test files**

The `content_pipeline.dart` service and `upload_screen.dart` (293 lines, with image picker, form validation, state management) have no test coverage at all. Neither does `llm_task_manager_screen.dart`. This is a blind spot for two relatively complex features.

**Action:** Create `test/features/ingestion/` and `test/features/llm_tasks/` directories with at minimum:
- Unit tests for `ContentPipeline` service methods
- Widget tests for `UploadScreen` (form validation, submission, error states)
- Widget tests for `LlmTaskManagerScreen`

---

### 6. Additional Minor Findings

| Finding | File | Severity |
|---------|------|----------|
| Test named "kanji builder with zero difficulty color" at line 617 doesn't match the code — no kanji builder exists in question_card_widget | `question_card_widget_test.dart:617` | Low |
| `DrawingPainter` tests instantiate `Stroke`/`DrawingPoint` directly but never test the `paint()` method's path/rendering logic | `canvas_drawing_widget_test.dart:268-289` | Medium |
| No test for `_handleSave` exception path (line 222-228 in source) showing `failedToSaveDrawing` when `_generateDrawingData()` throws | `canvas_drawing_widget_test.dart` (missing) | Medium |
| `widget_test.dart` duplicates coverage from `test/features/practice/` (both test the practice flow with identical fake providers) | `test/widget_test.dart` | Low |
| `run_full_coverage.sh` only targets `test/core/constants/*_test.dart` — does not run feature tests or aggregate overall coverage | `scripts/run_full_coverage.sh` | Medium |

---

## Acceptance Criteria

1. `QuestionType.stepByStep` renders content (not "not supported") in `QuestionCardWidget` and a widget test verifies this
2. `AnswerValidationService._cache` / `_cacheSignatures` has an eviction policy with tests proving bounded growth
3. `math_expression_widget_test.dart` has at least 3 tests verifying span text content, style, and token substitution (and the 30+ shallow RichText-existence checks are removed/reduced)
4. `markscheme_model_test.dart` and `answer_test.dart` are relocated to `test/core/data/models/` and `test/core/services/` respectively
5. `test/features/ingestion/` exists with at least one test file for `ContentPipeline` or `UploadScreen`
6. No test in the suite is named in a way that contradicts the code under test (fix "kanji builder")
7. CI/coverage scripts (`scripts/run_full_coverage.sh`) are updated to run the full test suite, not just `test/core/constants/`
