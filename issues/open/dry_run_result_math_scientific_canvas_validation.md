# Dry-Run Result: Mathematical & Scientific Content

**Source:** `dry-run-test/scenario_math_scientific_canvas_validation.md`
**Date of Validation:** May 2026

## Overall Status: 3/15 COMPLETED (~23%)

This scenario was traced against the actual codebase. Most concerns from the original scenario remain valid, though 3 steps have been resolved and 1 step is partially resolved.

---

## COMPLETED (3)

### Step 9: Question Type Dead Zones
`content_pipeline.dart:577-588` — `_defaultAllowedTypes` now includes **all 10 question types** (was 5 in original scenario). The pipeline no longer excludes canvas, graphDrawing, stepByStep, fileUpload, or audioRecording from auto-generation.

### Step 11: File Upload Functional
`file_upload_widget.dart:41-48` — Now uses `FilePicker.platform.pickFiles()` from the `file_picker` package to actually select files. No longer a placeholder stub. Stores `fileName||filePath` as the answer.

### Step 12: Audio Recording Functional
`audio_recording_widget.dart:24-78` — Now uses `AudioRecorder` from the `record` package to actually record audio. Checks permissions, records to temp `.m4a` file, monitors amplitude, stores file path as answer. No longer a placeholder stub.

---

## PARTIAL (1)

### Step 4: Graph Drawing — Axes and Tools Added, Still Incomplete

**What is done:**
- `GraphDrawingWidget` is a separate widget with dedicated graphing UI (`graph_drawing_widget.dart`)
- `GridPainter` supports `showAxes`, `axisColor`, `originX`, `originY`, `pixelsPerUnit` (`grid_painter.dart:14-22`)
- Coordinate axes with arrows, tick marks, and numeric labels are drawn (`grid_painter.dart:36-82`)
- Toolbar: freehand, line (straight line), plot point, eraser (`graph_drawing_widget.dart:167-173`)
- Color picker (6 colors) and stroke width selector (`graph_drawing_widget.dart:175-184`)
- Undo/redo/clear (`graph_drawing_widget.dart:114-119`)
- `CanvasDrawingWidget` has shape tools (rectangle, circle) behind `showTools: true` flag — used in tutor screen (`tutor_screen.dart:374-376`) but NOT in practice/question-bank

**What is missing:**
- No snap-to-grid for precise graph drawing
- No text tool for labeling axes or data points
- No measurement or scale indicators
- `CanvasDrawingWidget` shape tools hidden in practice/question-bank contexts (default params)
- No content-based validation of graph drawings (see Step 5)

---

## NOT_COMPLETED (11)

### Step 1: Math Formula Rendering
`math_expression_widget.dart` — Hand-rolled 394-line parser with ~30 commands. No LaTeX typesetting package in `pubspec.yaml`. Missing: `\int`, proper `\frac` (stacked), `\sum`, `\prod`, `\lim`, matrices, multi-line equations, error handling.

### Step 2: Math Answer Input
`practice_session_question_card.dart:183-184` — **No answer input field exists** for `mathExpression` type in practice sessions (only renders `MathExpressionWidget` display). `question_card_widget.dart:198-200` — Falls through to plain `TextField`. No math keyboard, no LaTeX helpers, no formula preview.

### Step 3: Math Validation
`answer_validation_service.dart:382-397` — Exact string comparison after minimal normalization (strip spaces, lowercase, `x`→`*`). No tolerance for equivalent expressions, no symbolic math evaluation.

### Step 5: Graph Drawing Validation
`answer_validation_service.dart:445-465` — Validates only that base64-decoded JSON is a non-empty List. No content-based evaluation. Any scribble is "correct."

### Step 6: Graph Renderer Feature
17+ l10n strings defined in `app_en.arb:1194-1364+` and `app_es.arb`. **Zero usage** in `lib/features/`. Dead localization placeholder — no widget, screen, service, or provider references these strings.

### Step 7: Question Validation in Pipeline
`content_pipeline.dart:396-405` — `_validateGeneratedQuestions` is a complete stub that only warns if question list is empty. No factual correctness check, no LLM validation, no cross-referencing.

### Step 8: Question Variant System
`question_model.dart:27-28` — `variantIds` field declared and serialized/deserialized. **Zero code** ever populates it. All questions created with `variantIds: const []`.

### Step 10: Canvas Drawing Validation
`answer_validation_service.dart:415-426` — Validates only that canvas data list is non-empty and each entry is non-empty. No content evaluation.

### Step 13: Cannot Flag/Report Incorrect AI Content
No mechanism exists anywhere in the codebase for students to flag, report, or provide feedback on incorrect AI-generated content.

### Step 14: No Trust/Verification Field
`question_model.dart:9-91` — No `isValidated`, `needsReview`, `verifiedBy`, `reviewedAt`, `trustScore`, or any similar field. No `GeneratedBy` indicator.

### Step 15: Content Validation Pipeline No LLM Re-Check
`content_pipeline.dart:657-701` — `_isValidGeneratedQuestion` performs only structural/schema validation. No LLM re-check after generation, no verification against source content.

---

## Action Items (Priority Ordered)

| Priority | Step | What to Fix | Files Involved |
|----------|------|-------------|----------------|
| P0 | 13 | Add "Report incorrect" / feedback mechanism for AI-generated content | New service + UI + Question model fields |
| P0 | 14 | Add trust/verification fields to Question model (`isValidated`, `generatedBy`, etc.) | `question_model.dart` |
| P0 | 15 | Implement LLM-based content validation in pipeline | `content_pipeline.dart` |
| P0 | 7 | Replace `_validateGeneratedQuestions` stub with real validation | `content_pipeline.dart` |
| P1 | 1 | Integrate a proper LaTeX rendering engine (e.g., `flutter_math` or `katex_flutter`) | `pubspec.yaml`, `math_expression_widget.dart` |
| P1 | 2 | Add math input keyboard/helpers for `mathExpression` answers | `practice_session_question_card.dart`, new `MathInputWidget` |
| P1 | 10 | Implement content-based canvas drawing validation | `answer_validation_service.dart` |
| P1 | 5 | Implement content-based graph drawing validation | `answer_validation_service.dart` |
| P2 | 4 | Add snap-to-grid, text tool, measurement to `GraphDrawingWidget` | `graph_drawing_widget.dart` |
| P2 | 4 | Enable shape tools in practice/question-bank `CanvasDrawingWidget` | `practice_session_question_card.dart`, `question_card_widget.dart` |
| P3 | 3 | Add symbolic math comparison or tolerant math validation | `answer_validation_service.dart` |
| P3 | 6 | Implement Graph Renderer feature or remove dead l10n strings | New feature or `app_*.arb` cleanup |
| P3 | 8 | Implement variant generation service | New service, wire into practice session |
