# Strengthen practice question UI test coverage (interaction matrix + edge paths)

## Why this matters

The practice flow currently has only basic happy-path coverage and almost no direct tests for the question UI widgets that drive answer capture and grading behavior. This leaves high-risk paths unprotected: question-type rendering switches, submit gating, feedback visibility, and drawing/math-specific interactions.

Current tests (`test/features.practice.test.dart`, `test/screens.practice.test.dart`, `test/widget_test.dart`) mostly validate app boot, loading states, and a single typed-answer flow. Regressions in other question types can ship undetected.

## Coverage gaps to address

1. **Question type rendering matrix is largely untested**
   - `PracticeSessionScreen._buildQuestionWidget` has multiple branches (`singleChoice`, `multiChoice`, `mathExpression`, `canvas`, `typedAnswer`, `essay`, fallback), but tests only exercise typed-answer behavior.
   - Multi-choice and single-choice currently share `SingleAnswerWidget`; without tests, incorrect selection semantics can slip through.

2. **Question UI widget behavior is untested in isolation**
   - `QuestionCardWidget` contains substantial state logic (`didUpdateWidget`, local answer syncing, submit enablement, correctness evaluation, multi-select serialization with `||`), but there are no widget tests covering this.
   - `SingleAnswerWidget` feedback states (`isSubmitted`, `isFeedbackVisible`, option color semantics, disabled tap after submit) are not tested.

3. **Canvas and math paths lack interaction tests**
   - `CanvasDrawingWidget` has undo/clear/save state transitions and initial drawing parsing; no tests verify save button gating, message states, or malformed payload handling.
   - `MathExpressionWidget` token styling and `showPrefix`/`isSolution` variants are untested, creating risk when refactoring rendering.

4. **Existing baseline test is overly basic**
   - `test/widget_test.dart` only checks app load/material presence and does not protect feature behavior.

## Affected files

- `lib/features/practice/presentation/practice_session_screen.dart`
- `lib/features/questions/ui/widgets/question_card_widget.dart`
- `lib/features/questions/ui/widgets/single_answer_widget.dart`
- `lib/features/questions/ui/widgets/canvas_drawing_widget.dart`
- `lib/features/questions/ui/widgets/math_expression_widget.dart`
- `test/features.practice.test.dart`
- `test/screens.practice.test.dart`
- `test/widget_test.dart`

## Proposed test additions

- Add focused widget tests for each questions UI widget (`QuestionCardWidget`, `SingleAnswerWidget`, `CanvasDrawingWidget`, `MathExpressionWidget`).
- Expand `PracticeSessionScreen` tests to cover each question type branch and answer submission lifecycle.
- Add negative/edge tests (empty options fallback, malformed initial drawing JSON, submit disabled with empty answer, post-submit controls disabled).

## Acceptance criteria

- New widget tests cover all `QuestionType` branches used in `PracticeSessionScreen._buildQuestionWidget`.
- `QuestionCardWidget` tests verify:
  - submit button enable/disable transitions,
  - answer sync behavior when `currentAnswer` changes,
  - multi-select serialization/parsing (`||`),
  - correctness chip for submitted answers.
- `SingleAnswerWidget` tests verify:
  - selection callback only when not submitted,
  - feedback container visibility rules,
  - correct/incorrect visual state behavior.
- `CanvasDrawingWidget` tests verify:
  - save disabled when empty,
  - undo/clear behavior updates state,
  - graceful handling of invalid `initialDrawing` payload.
- `MathExpressionWidget` tests verify:
  - prefix rendering when `showPrefix=true`,
  - solution container variant when `isSolution=true`.
- Existing broad smoke test(s) are either replaced or complemented so they assert meaningful practice-flow behavior rather than only app boot.
