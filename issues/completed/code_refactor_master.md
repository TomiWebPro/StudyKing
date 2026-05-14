# Code Refactor Master Issue

## 1. Duplicate `AnswerValidationService` — Dead Wrapper with Proliferated API

### Summary
`lib/features/questions/services/answer_validator.dart` defines classes (`ValidationResult`, `AnswerValidationService`, `QuestionAnswerValidator`) that **identically shadow** the canonical versions in `lib/core/services/answer_validation_service.dart`. The feature-layer wrapper:
- Contains a **dead instance cache** (`_cache`, `_cacheSignatures`, `_evictIfNeeded`) that is **bypassed** by its own 6+ static pass-through methods
- Exposes an inconsistent API surface (e.g., `validateWithMarkschemeInstance` instance vs `validateWithMarkscheme` static — same name, different semantics)
- **Drops** `ValidationMessages` support that the core service provides
- Is re-exported through the `questions_feature.dart` barrel, polluting the public API and risking ambiguous imports

### Rationale
This is a DRY violation that doubles maintenance surface area. Any change to validation logic requires edits in **two files** plus **two test files** (542-line wrapper test + core test). The wrapper's caching layer is pure dead code — the static methods used by consumers bypass it entirely.

### Affected Files
| File | Role |
|---|---|
| `lib/features/questions/services/answer_validator.dart` | **DELETE** — whole file is a dead wrapper |
| `lib/features/questions/questions_feature.dart:3` | Remove `export 'services/answer_validator.dart'` |
| `test/features/questions/services/answer_validator_test.dart` | Remove — tests duplicate core coverage |
| `lib/features/practice/presentation/practice_session_screen.dart:42,74` | Already imports core directly — no change needed |
| `lib/core/services/answer_validation_service.dart` | Canonical service — untouched |

### Acceptance Criteria
1. `answer_validator.dart` is removed from the project
2. No remaining code imports from `features/questions/services/answer_validator.dart`
3. All tests pass (`flutter test`)
4. `questions_feature.dart` no longer exports the removed file

---

## 2. `PracticeResultsScreen` Misplaced in `widgets/` Directory

### Summary
`lib/features/practice/presentation/widgets/practice_results_screen.dart` contains a full `Scaffold`-based screen (AppBar, body, FocusTraversalGroup) but lives in the `widgets/` subdirectory. It should sit alongside `practice_screen.dart` and `practice_session_screen.dart` in `lib/features/practice/presentation/`.

### Rationale
File placement conventions exist to make navigation predictable. A new contributor looking for screen files will not find this one in the expected location.

### Affected Files
| File | Action |
|---|---|
| `lib/features/practice/presentation/widgets/practice_results_screen.dart` | Move → `lib/features/practice/presentation/practice_results_screen.dart` |
| `lib/features/practice/presentation/practice_session_screen.dart:269` | Update import path |

### Acceptance Criteria
1. `PracticeResultsScreen` lives in `presentation/`, not `presentation/widgets/`
2. The app builds and navigates to the results screen correctly
3. All tests pass

---

## 3. `LessonService` — Unused Constructor Parameters

### Summary
`LessonService` constructor accepts `TutorService tutorService` and `MasteryGraphService? masteryService` but **never assigns or uses either**. The provider at `lesson_providers.dart` eagerly constructs a `TutorService` (with a hardcoded model ID `'openai/gpt-4o-mini'`) and a `MasteryGraphService` that are both silently discarded.

### Rationale
Dead parameters mislead developers about the class's dependencies and waste instantiation cost. The provider constructs heavyweight services (LLM service chain, mastery graph) for nothing.

### Affected Files
| File | Line(s) |
|---|---|
| `lib/features/lessons/services/lesson_service.dart` | 11–14 |
| `lib/features/lessons/providers/lesson_providers.dart` | 8–19 |

### Acceptance Criteria
1. `tutorService` and `masteryService` parameters are removed from `LessonService`
2. `lessonServiceProvider` no longer constructs `TutorService` or `MasteryGraphService` for `LessonService`
3. All tests pass

---

## 4. Hardcoded Semantically Empty Fallback Options

### Summary
In `lib/features/practice/presentation/widgets/practice_session_question_card.dart:117`:

```dart
final fallbackOptions = [1, 2, 3, 4].map((i) => l10n.fallbackOption(i)).toList();
```

When `question.options` is empty, the widget falls back to the literal strings `["Option 1", "Option 2", "Option 3", "Option 4"]`. These have no semantic meaning — they are never the correct answer, so every selection will always be wrong.

### Rationale
This creates a confusing user experience: the user selects "Option 1" but it is always marked incorrect. The fallback should either (a) show a descriptive message that no options are available, or (b) prevent display of questions with no options at an earlier layer.

### Affected Files
| File | Line(s) |
|---|---|
| `lib/features/practice/presentation/widgets/practice_session_question_card.dart` | 117 |
| `lib/features/practice/presentation/widgets/practice_session_question_card.dart` | 148–149 (default case also shows generic "unsupported" message) |

### Acceptance Criteria
1. Questions of type `singleChoice` or `multiChoice` with empty `options` list do not render meaningless fallback options
2. Either the UI shows a clear message ("No options available") or the question is skipped
3. All tests pass

---

## 5. `ExportSection` — Service Injection Bypasses Riverpod

### Summary
`lib/features/dashboard/presentation/widgets/export_section.dart` accepts `StudyProgressTracker` and `InstrumentationService` as direct constructor parameters. The rest of the project uses Riverpod `Provider`/`ref.watch` for dependency injection. This inconsistency makes the widget harder to test and less composable.

### Affected Files
| File | Lines |
|---|---|
| `lib/features/dashboard/presentation/widgets/export_section.dart` | 6–16 |
| `lib/features/dashboard/presentation/dashboard_screen.dart` | 194 |

### Acceptance Criteria
1. `ExportSection` reads services from Riverpod providers (e.g., `ref.watch(progressTrackerProvider)`) instead of constructor injection
2. The app builds and export buttons function correctly
3. All tests pass

---

## 6. `SpacedRepetitionSheet` — Static `showAllCaughtUp` Duplicates Bottom Sheet Shape

### Summary
`showAllCaughtUp()` and `showSubjectPicker()` in `spaced_repetition_sheet.dart` hardcode the same `RoundedRectangleBorder(borderRadius: Vertical(top: Radius.circular(20)))` shape. If the app-wide bottom sheet shape changes, this must be updated in multiple places.

### Affected Files
| File | Lines |
|---|---|
| `lib/features/practice/presentation/widgets/spaced_repetition_sheet.dart` | 79–80, 120–121 |

### Acceptance Criteria
1. Bottom sheet shape is defined centrally (e.g., in a theme or constant) and reused
2. All bottom sheets in the app use the same shape
3. Visual behavior is unchanged

---

## Priority Order
1. **Duplicate AnswerValidationService** (highest impact — dead code, DRY violation, API pollution)
2. **Misplaced PracticeResultsScreen** (structural clarity)
3. **LessonService dead params** (misleading API, wasted instantiation)
4. **Hardcoded fallback options** (user-facing bug)
5. **ExportSection DI inconsistency** (architectural drift)
6. **SpacedRepetitionSheet hardcoded shape** (maintainability)
