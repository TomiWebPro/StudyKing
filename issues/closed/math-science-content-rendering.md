# Rich Content: Add LaTeX/Math Rendering Support for STEM Subjects

**Severity:** major
**Affected area:** Questions, Teaching, Lessons — Content Display
**Reported by:** codebase audit

## Description

StudyKing is an AI-native learning platform, yet it has **no dedicated math or science rendering engine**. Mathematical expressions, equations, chemical formulas, and scientific notation are displayed as plain text. This renders the platform largely unusable for STEM subjects (mathematics, physics, chemistry, engineering).

For example, the quadratic formula `x = (-b ± √(b² - 4ac)) / (2a)` would appear as raw ASCII text rather than a properly typeset formula. Students cannot distinguish between `x^2` and `x₂`, and complex expressions become unreadable.

## Expected behavior

The platform should render:
- **Inline math** (e.g., `$E = mc^2$`) as properly typeset equations
- **Display math** (block equations) with appropriate sizing and centering
- **Chemical formulas** (e.g., `H_2O`, `C_6H_{12}O_6`) with proper subscripts/superscripts
- **Scientific notation** with proper formatting
- **Graphs and charts** for functions and data visualization

## Actual behavior

All math/science content is displayed as plain text with no rendering. The `LessonBlock.content` field stores markdown-like text but there is no math rendering pipeline.

## Code analysis

- `lib/core/data/models/question_model.dart:7-85` — `Question.text` stores question content as plain string
- `lib/features/lessons/data/models/lesson_block_model.dart:7-38` — `LessonBlock.content` stores content as plain string
- `lib/features/lessons/presentation/widgets/lesson_block_card.dart` — Renders block content as `Text` widget, no math parsing
- `lib/features/questions/presentation/widgets/question_card.dart` — Renders question text as plain text
- `lib/features/teaching/presentation/widgets/chat_bubble.dart` — Renders tutor messages as plain text with basic markdown
- `lib/features/teaching/services/prompts/prompts.dart` — LLM prompts request content in markdown but don't specify math formatting

## Suggested approach

1. **Integrate a math rendering library**:
   - `flutter_math_fork` (KaTeX-based) — Renders LaTeX math expressions inline and in display mode. Pure Dart, no native dependencies.
   - `catex` — Alternative LaTeX renderer for Flutter

2. **Add a content format field** to `LessonBlock` and `Question`:
   ```dart
   enum ContentFormat { plainText, markdown, latex, html }
   ```
   This tells the renderer how to interpret the content string.

3. **Create a `RichContentRenderer` widget** that:
   - Detects math delimiters (`$...$`, `$$...$$`, `\(...\)`, `\[...\]`)
   - Renders math expressions using KaTeX
   - Falls back to plain text for non-math content
   - Supports color, font size, and accessibility settings

4. **Update the LLM prompts** to include instructions like:
   ```
   When writing mathematical expressions, use LaTeX notation with $...$ 
   for inline math and $$...$$ for display math.
   ```

5. **Add graph/chart rendering** for function visualization:
   - `fl_chart` for data charts (bar, line, pie)
   - `function_graph` or custom `CustomPainter` for mathematical function plots
