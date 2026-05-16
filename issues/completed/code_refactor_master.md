# Issue: Dead & Duplicated Question Card Widget — Refactor to Single Source of Truth

## Context

The `lib/features/questions/` feature is architecturally incomplete: it has no `screens/`, `providers/`, or `services/` directories — only `widgets/`, `data/`, and a barrel file. Its barrel (`questions.dart`) exports `question_card_widget.dart` but **no consumer in `lib/` actually imports it**. Instead, the `practice` feature built its own near-identical question card (`practice_session_question_card.dart`) that directly deep-imports from `questions/presentation/widgets/`, creating tight cross-feature coupling. This leaves 438 lines of dead code shipped in the bundle while duplicating rendering logic.

## Affected Files

| File | Lines | Role |
|---|---|---|
| `lib/features/questions/presentation/widgets/question_card_widget.dart` | 438 | **Dead code** — exported but never imported by any `lib/` consumer |
| `lib/features/practice/presentation/widgets/practice_session_question_card.dart` | 160 | **Duplicated logic** — reimplements question card with partial feature set; deep-imports from `questions/` widgets |
| `lib/features/questions/presentation/widgets/single_answer_widget.dart` | 168 | Shared widget, correctly split |
| `lib/features/questions/presentation/widgets/canvas_drawing_widget.dart` | 349 | SRP violation — domain models (`Stroke`, `DrawingPoint`) and painters (`DrawingPainter`, `GridPainter`) mixed in same file as widget |
| `lib/features/questions/questions.dart` | 8 | Barrel file — re-exports `question_card_widget.dart` that nothing uses |
| `lib/features/mentor/presentation/mentor_screen.dart` | 375 | Scattered — `_ChatMessage` private class defined at line 370 inside the screen file |
| `lib/core/utils/logger.dart` | 50 | Logging — `setVerbose` is static mutable global state |

## Rationale

1. **Dead code in production bundle.** `question_card_widget.dart` (438 lines) is exported from the barrel but not referenced by a single `lib/` file. Only test files import it. This adds unnecessary binary size and maintenance surface.

2. **Duplicated question rendering.** `practice_session_question_card.dart` reimplements the same switch-on-question-type pattern with different styling and a narrower set of question types. Any change to how a typed-answer or essay question renders must be made in two places. This has already diverged — `question_card_widget.dart` has `reduceMotion`/`largeTouchTargets`/`onNext` support that the practice version lacks.

3. **Cross-feature deep imports.** `practice_session_question_card.dart` directly imports `questions/presentation/widgets/single_answer_widget.dart`, `canvas_drawing_widget.dart`, and `math_expression_widget.dart`. This violates the principle that features should interact through well-defined public APIs (the barrel file), not by reaching into another feature's presentation internals.

4. **SRP violations.** `canvas_drawing_widget.dart` mixes domain models (`Stroke`, `DrawingPoint`) and rendering logic (`DrawingPainter`, `GridPainter`) into the same 349-line file. `mentor_screen.dart` defines `_ChatMessage` inline at the bottom of a 375-line screen file.

5. **Inappropriate log level.** `canvas_drawing_widget.dart:280` uses `_logger.d` (debug) for a JSON parse failure, which is an actual error condition — should be at least `warn`.

## Acceptance Criteria

- [ ] **Remove `question_card_widget.dart`** from the barrel export after migrating its unique capabilities (submit button, `reduceMotion`, `largeTouchTargets`, `onNext`, correct/incorrect debrief chips) into `practice_session_question_card.dart` or a shared widget.
- [ ] **Extract domain models** from `canvas_drawing_widget.dart` into `lib/features/questions/data/models/drawing_models.dart` for `Stroke` and `DrawingPoint`.
- [ ] **Extract painters** from `canvas_drawing_widget.dart` into `lib/features/questions/presentation/painters/` for `DrawingPainter` and `GridPainter`.
- [ ] **Fix log level** in `canvas_drawing_widget.dart:280` — change `_logger.d` → `_logger.w` for the JSON parse failure case.
- [ ] **Extract `_ChatMessage`** from `mentor_screen.dart` into `lib/features/mentor/data/models/chat_message_data.dart` as a public or package-private class.
- [ ] Verify no regressions: all existing tests in `test/features/questions/` and `test/features/practice/` pass.
