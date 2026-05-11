# UI/UX Master Issue Report

## Issue: Broken Feedback Animation and Non-Functional UI Elements

### Context
The StudyKing app contains problematic UI/UX patterns that create confusing user experiences and broken visual feedback.

### Affected Files
- `lib/features/questions/ui/widgets/single_answer_widget.dart` (lines 78-121)
- `lib/pages/graph_rendering_page.dart` (lines 175-181)

### Rationale

**1. Broken AnimatedOpacity in SingleAnswerWidget**
The feedback animation is fundamentally broken. The `AnimatedOpacity` widget at line 79-81 uses:
```dart
AnimatedOpacity(
  duration: const Duration(milliseconds: 300),
  opacity: isSubmitted ? 1.0 : 0.0,
```
Since `isSubmitted` is already `true` when feedback becomes visible, the animation instantly jumps to full opacity instead of smoothly transitioning. The opacity value should be based on a trigger that transitions from 0 to 1, not a boolean that's already true.

**2. Empty Stub Functions with Active UI**
In `graph_rendering_page.dart`, several methods are empty stubs but the UI presents them as functional:
- `_setGraphType(String type)` - line 175
- `_validateWithLLM(BuildContext context)` - line 177
- `_reRenderGraph(BuildContext context)` - line 179
- `_validateGraphType(BuildContext context)` - line 181

Users see action buttons (upload, validate, refresh, verify) but tapping them does nothing. This creates misleading interaction expectations.

**3. Accessibility Gap**
The `Semantics` widget in `single_answer_widget.dart` (line 31-34) lacks proper `hint` and `description` for screen reader users. Only `label` is provided.

### Acceptance Criteria

1. **Fix AnimatedOpacity**: Replace with a proper animation trigger (e.g., `AnimatedSwitcher` with `FadeTransition` or a dedicated animation controller) so feedback smoothly fades in when displayed.

2. **Implement or Remove Stub Functions**: Either implement functional versions of the graph methods or remove the misleading action buttons from the UI. If implementing, add proper loading states and error handling.

3. **Improve Accessibility**: Add comprehensive semantic descriptions:
   ```dart
   Semantics(
     label: option,
     hint: 'Select as answer',
     button: true,
     selected: selectedAnswer == option,
   )
   ```

4. **Add Empty State Handling**: Display appropriate empty state UI when no graph data is uploaded, rather than placeholder text.