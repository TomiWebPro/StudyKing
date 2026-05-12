## UI/UX: Canvas Drawing Widget Accessibility Improvements

### Changes Made
- `lib/features/questions/ui/widgets/canvas_drawing_widget.dart` — All changes

### Summary
Implemented accessibility improvements for the CanvasDrawingWidget used in graph drawing and diagram questions:

1. **Semantics wrapper around canvas** — Wrapped the drawing canvas in a `Semantics(container: true)` widget with proper `label` and `hint` properties, making the drawing task discoverable by screen readers.

2. **Stroke count feedback** — Added a `Semantics(liveRegion: true)` text widget below the canvas that dynamically announces stroke count (e.g., "Drawing with 3 strokes"), providing alternative feedback for canvas content.

3. **Icon button touch targets** — Increased undo/clear icon button padding from 8px to 14px, achieving the minimum 48x48px touch target per WCAG 2.1 Level AA. Added Semantics `button: true` with descriptive labels ("Undo last stroke", "Clear all drawings").

4. **Instruction text accessibility** — Wrapped instruction text in `Semantics(header: true)` to ensure it's announced by screen readers before the canvas receives focus.

5. **Visual drawing state indicator** — Canvas border now changes to blue (width 2px) during active drawing, providing a non-color-based visual state indicator alongside existing text-based state feedback.
