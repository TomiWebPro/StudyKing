# UI/UX Issue: Canvas Drawing Widget Accessibility & Touch Target Violations

## Context
The `CanvasDrawingWidget` used for graph drawing and diagram questions in practice sessions has critical accessibility issues. It is completely inaccessible to screen reader users and has undersized touch targets that violate accessibility guidelines.

This widget is rendered in `practice_session_screen.dart` when handling `QuestionType.canvas` questions. Users rely on this feature for visual/diagrammatic question practice.

## Affected Files
- `lib/features/questions/ui/widgets/canvas_drawing_widget.dart` - Main widget implementation
- `lib/features/practice/presentation/practice_session_screen.dart` - Question rendering (lines 453-458)
- `lib/core/data/models/question_model.dart` - QuestionType.canvas definition

## Rationale
1. **Screen Reader Inaccessibility**: The canvas is a pure visual component with zero semantic information. Screen reader users cannot:
   - Understand that a drawing task is required
   - Perceive the instruction text associated with the canvas
   - Describe what they have drawn or receive feedback on their drawing

2. **Touch Target Violation**: The undo and clear icon buttons (lines 79-81) measure approximately 32x32px (8px padding + 20px icon), below the recommended 48x48px minimum for accessible touch targets per WCAG 2.1 Level AA.

This is a high-priority issue because it completely blocks a subset of users from an entire question type, and creates poor usability for users with motor impairments.

## Acceptance Criteria
1. Add `Semantics` widget wrapper around the drawing canvas with proper `label` and `hint` properties to communicate the drawing task to screen readers
2. Implement `SemanticsService` or similar to provide alternative feedback for canvas content (e.g., "Drawing with 3 strokes")
3. Increase icon button touch targets to minimum 48x48px by adjusting padding or wrapping in a larger tap target
4. Ensure instruction text is announced by screen readers before the canvas focus
5. Add visual indicator for drawing state that is accessible (not solely color-based)

## Priority
High - Blocks access to canvas question functionality for screen reader users