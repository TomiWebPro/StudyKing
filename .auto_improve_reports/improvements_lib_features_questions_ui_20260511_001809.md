# Improvement Report: `lib/features/questions/ui`

Date: 2026-05-11

This report reviews all code under `lib/features/questions/ui/widgets` and lists potential bugs, performance issues, code quality concerns, and enhancement opportunities.

## Severity Legend

- **High**: Likely user-facing bug, broken behavior, or serious correctness issue.
- **Medium**: Functional gap, UX issue, maintainability risk, or non-trivial technical debt.
- **Low**: Style, consistency, minor UX/accessibility issue, or small optimization.

## Findings

| # | File | Line | Severity | Issue | Suggested fix |
|---|---|---:|---|---|---|
| 1 | `lib/features/questions/ui/widgets/question_card_widget.dart` | 57-60 | High | Correctness check compares `currentAnswer` to `question.markscheme` directly. For MCQ, `markscheme` is also used as comma-separated options elsewhere, so this can mark correct answers as incorrect. | Separate data fields: `options` and `correctAnswer`. Compare selection against dedicated correct answer key/value. |
| 2 | `lib/features/questions/ui/widgets/question_card_widget.dart` | 131-135 | High | MCQ options are derived from `question.markscheme`, conflating marking rubric with answer choices. This is a schema misuse and can break grading/UI. | Add explicit `question.options` in model and use it here. Keep `markscheme` for evaluation metadata only. |
| 3 | `lib/features/questions/ui/widgets/question_card_widget.dart` | 144-146 | High | `onAnswerSelected` callback is empty, so tapping options does not propagate state. Selection in `SingleAnswerWidget` cannot update parent answer. | Wire `onAnswerSelected` to a parent callback (e.g., `onAnswerChanged`) and update state in parent/controller. |
| 4 | `lib/features/questions/ui/widgets/question_card_widget.dart` | 151-162 | High | Text answer `TextField` `onChanged` handler is empty. Typed answers are never captured/submitted. | Bind to answer state via controller/callback and pass value to `onAnswerSubmitted`. |
| 5 | `lib/features/questions/ui/widgets/question_card_widget.dart` | 166-174 | High | Essay answer field has no value binding or callback, so user input is lost from submission flow. | Add `TextEditingController` or `onChanged` callback and connect to current answer state. |
| 6 | `lib/features/questions/ui/widgets/question_card_widget.dart` | 177-183 | High | Canvas completion callback is empty, so drawing output is discarded and cannot be submitted. | Forward bytes from `onDrawingComplete` to answer state/submission callback. |
| 7 | `lib/features/questions/ui/widgets/canvas_drawing_widget.dart` | 117-135 | High | `_buildIconButton` ignores `onTap`; controls render but are non-interactive (undo/clear broken). | Wrap button UI with `InkWell`/`GestureDetector`/`IconButton` and invoke `onTap`. |
| 8 | `lib/features/questions/ui/widgets/canvas_drawing_widget.dart` | 188-192 | High | `_generateDrawingData` returns placeholder `Uint8List([1])`, not actual drawing content; saved drawing is invalid. | Render canvas to image (`ui.PictureRecorder`/`RepaintBoundary.toImage`) and encode PNG bytes. |
| 9 | `lib/features/questions/ui/widgets/canvas_drawing_widget.dart` | 146-147 | Medium | Uses `context.findRenderObject()` from widget root, which may not map to drawing surface coordinates (offset mismatch in nested layouts). | Use a `GlobalKey` on drawing container and get local coordinates from that render box. |
| 10 | `lib/features/questions/ui/widgets/canvas_drawing_widget.dart` | 150-153 | Medium | Stores one point per pan update and paints circles only; no stroke segmentation or smoothing, resulting in dotted/jagged drawings. | Model strokes as list of paths/point groups and draw lines/paths between consecutive points. |
| 11 | `lib/features/questions/ui/widgets/canvas_drawing_widget.dart` | 164-172 | Medium | Undo removes single point, not last stroke, which is poor UX and expensive for long strokes. | Track stroke boundaries; undo should remove last stroke atomically. |
| 12 | `lib/features/questions/ui/widgets/canvas_drawing_widget.dart` | 24, 154, 169, 178 | Medium | `_isEmpty` duplicates derivable state from `_drawings.isEmpty`, risking desynchronization bugs. | Remove `_isEmpty` and compute emptiness directly from `_drawings`. |
| 13 | `lib/features/questions/ui/widgets/canvas_drawing_widget.dart` | 97-100 | Medium | `Save Drawing` is always visible and only disabled for empty state; no progress/error handling or confirmation feedback. | Add async state (`isSaving`), disabled/loading UI, success/error message, and retry path. |
| 14 | `lib/features/questions/ui/widgets/canvas_drawing_widget.dart` | 7-15 | Medium | `initialDrawing` prop exists but is never used. | Parse/apply initial drawing on init and repaint canvas. |
| 15 | `lib/features/questions/ui/widgets/canvas_drawing_widget.dart` | 128 | Medium | `Colors.black.withValues(alpha: 10)` likely invalid intent (alpha is normalized double in Flutter API); shadow opacity can be wrong. | Use normalized alpha (e.g., `0.10`) or `withOpacity(0.1)` depending on SDK conventions. |
| 16 | `lib/features/questions/ui/widgets/canvas_drawing_widget.dart` | 40-42 | Low | No input filtering for stylus/mouse/finger distinctions; may capture unintended gestures on desktop/web. | Consider `Listener`/`GestureDetector` tuning and device-kind handling where needed. |
| 17 | `lib/features/questions/ui/widgets/canvas_drawing_widget.dart` | 52-59, 110-113 | Low | Two full-size `CustomPaint` layers are redrawn frequently; could be optimized for large drawings. | Cache static grid with `RepaintBoundary` and isolate dynamic drawing layer. |
| 18 | `lib/features/questions/ui/widgets/canvas_drawing_widget.dart` | 195-203 | Low | `DrawingPoint.color` has default and required point only; no stroke width, tool type, pressure metadata for richer input. | Extend model to include stroke width/style and optional pressure for better drawing quality. |
| 19 | `lib/features/questions/ui/widgets/single_answer_widget.dart` | 69 | Medium | Option text is plain `Text(option)` with no overflow handling; long options can overflow or clip. | Add `Expanded` + `Text(overflow: TextOverflow.visible/ellipsis, softWrap: true)` with layout constraints. |
| 20 | `lib/features/questions/ui/widgets/single_answer_widget.dart` | 43 | Medium | Entire row is tappable but lacks semantics for selected state/role, reducing accessibility for screen readers. | Use `RadioListTile` or add `Semantics` labels/selected/button roles and focus handling. |
| 21 | `lib/features/questions/ui/widgets/single_answer_widget.dart` | 48, 121-131 | Medium | Option feedback colors rely on hardcoded red/green only; inaccessible for color-blind users and theming inconsistency. | Use theme color scheme + icons/text indicators; ensure contrast and non-color cues. |
| 22 | `lib/features/questions/ui/widgets/single_answer_widget.dart` | 37 | Low | `entry` index is unused (`asMap().entries` unnecessary). | Iterate directly over `options` or use index meaningfully (e.g., labels A/B/C/D). |
| 23 | `lib/features/questions/ui/widgets/single_answer_widget.dart` | 30-33 and 137-138 in parent | Low | Question text is rendered in both `QuestionCardWidget` and `SingleAnswerWidget`, causing duplicate question content in MCQ mode. | Remove duplicate `questionText` display from child or pass a flag to suppress one rendering. |
| 24 | `lib/features/questions/ui/widgets/single_answer_widget.dart` | 87-88, 124, 127 | Low | Uses `withValues(alpha: ...)`; API compatibility depends on Flutter version and may reduce portability. | Use stable API compatible with project SDK (`withOpacity` or validated `withValues` usage). |
| 25 | `lib/features/questions/ui/widgets/math_expression_widget.dart` | 44 | High | Splitting by spaces removes exact expression formatting and drops spaces between tokens in output (`TextSpan` list has no explicit spacing). | Implement proper parser/tokenizer preserving whitespace; or render raw text with dedicated math library. |
| 26 | `lib/features/questions/ui/widgets/math_expression_widget.dart` | 45-47 | Medium | Escape sequence checks are inconsistent (`r'\\['`, `r'\('`, `'
| 27 | `lib/features/questions/ui/widgets/math_expression_widget.dart` | 57-60 | Medium | Operator highlighting is naive (`contains`) and can style non-math text accidentally (e.g., hyphenated words, URLs). | Tokenize mathematical syntax explicitly before applying styles. |
| 28 | `lib/features/questions/ui/widgets/math_expression_widget.dart` | 70-77 | Low | Dot-based italic rule (`word.contains('.')`) is semantically wrong for math; decimal numbers and sentence punctuation become italicized. | Replace with meaningful token classes (variables, numbers, operators, functions). |
| 29 | `lib/features/questions/ui/widgets/math_expression_widget.dart` | 88-91 | Low | Always prepends `Expression: `, which may be noisy and duplicates parent context. | Make prefix optional or remove; let parent provide labels. |
| 30 | `lib/features/questions/ui/widgets/math_expression_widget.dart` | 100-108, 102, 107 | Medium | `FormulaWidget.variable` is unused and widget duplicates partial math-rendering concerns with `MathExpressionWidget`. | Remove unused prop or use it in rendering; consolidate shared rendering strategy. |
| 31 | `lib/features/questions/ui/widgets/question_card_widget.dart` | 82-91 | Medium | Submit button allows submission even when no answer exists (`currentAnswer == null`), potentially recording empty attempts unintentionally. | Disable button until valid input exists per question type; show validation hint. |
| 32 | `lib/features/questions/ui/widgets/question_card_widget.dart` | 126 | Low | Fallback text `Question type not supported` is not localized and provides no recovery UX. | Add localization and optionally support/help action for unsupported type. |
| 33 | `lib/features/questions/ui/widgets/question_card_widget.dart` | 110-113 | Medium | `multiChoice` is routed to `SingleAnswerWidget` (single-select radio behavior), functionally incorrect for multiple-select questions. | Implement dedicated multi-select widget with checkbox state and list of selected answers. |
| 34 | `lib/features/questions/ui/widgets/question_card_widget.dart` | 150-175 | Medium | `TextField` widgets are uncontrolled in a `StatelessWidget`; rebuilding can lose visible state and parent cannot reliably read latest value. | Use stateful parent/controller-based architecture or external state management binding. |
| 35 | `lib/features/questions/ui/widgets/question_card_widget.dart` | 2-3 and overall | Low | UI logic tightly depends on domain model internals (`markscheme`, `difficulty` raw int), reducing readability and increasing coupling. | Introduce UI view model / mapper for display-ready fields and typed difficulty enum. |
| 36 | `lib/features/questions/ui/widgets/canvas_drawing_widget.dart` | 182-186 | Low | `_handleSave` marked async but has no await and no error boundary; misleading and may hide future failures. | Either make synchronous now or add real async save flow with try/catch and awaited operations. |

## Cross-cutting enhancement suggestions

1. **Introduce explicit answer model per question type**: Use a sealed/union answer type (single choice, multiple choice, text, essay, drawing bytes) to avoid null/string overloading and submission mistakes.
2. **Separate content vs evaluation data**: Keep `options`, `correctAnswer`, and `markscheme/rubric` as different fields in `Question` to prevent logic collisions.
3. **Adopt consistent state flow**: Lift answer state to a controller/view-model and make widgets purely presentational with deterministic callbacks.
4. **Accessibility pass**: Add semantics, focus order, larger tap targets, and non-color feedback for correctness states.
5. **Testing**: Add widget tests for each question type covering answer capture, submit enable/disable rules, grading correctness, and canvas save output validity.
