# Dry-Run Scenario: Mathematical & Scientific Content, Handwriting Input, and Trusting AI-Generated Questions

## Persona

I'm an IB Physics & Mathematics student who has been using StudyKing for a few weeks. I've uploaded my physics textbook PDF, configured my API key, and attended a couple of AI tutor lessons. Now I want to engage with **mathematical and scientific content** properly — formulas, equations, scientific notation, graphs, and handwritten responses. I also want to understand whether the AI-generated questions I'm answering are actually **correct** — after all, the product promises that "AI-generated content should not be blindly trusted."

---

## Step 1: Seeing a Question with Mathematical Notation — Does the App Render It Correctly?

I start a practice session on "Kinematics" in IB Physics. The first question reads:

> **"What is the displacement of an object moving with $v = 3t^2 + 2t$ from $t = 0$ to $t = 4$ seconds?"**

**What I expect:** The formula `v = 3t² + 2t` with a superscript 2, rendered cleanly like real mathematical notation. The integral symbol if needed. Proper fraction rendering.

**What actually happens:** The `MathExpressionWidget` (`lib/features/questions/presentation/widgets/math_expression_widget.dart`) processes the expression character-by-character. It has a custom LaTeX-like parser that:
- Handles `\sqrt` → maps to Unicode √
- Handles `^` → renders superscript as a smaller `WidgetSpan` with `TextScaler.linear(0.75)`
- Handles `_` → subscript similarly
- Maps Greek letters to Unicode (e.g., `\alpha` → α)
- Handles `\frac` by rendering a `/` (not actual fraction layout)
- Handles `\times` → ×, `\cdot` → ·, `\infty` → ∞

**But there are critical gaps:**
1. **No integral symbol support** — `\int` is not handled. The expression `\int_0^4 (3t^2+2t) dt` would render the command `int` as literal text.
2. **No proper fractions** — `\frac{3}{4}` renders as `3/4` using a plain slash, not a stacked fraction.
3. **No matrix notation** — `\begin{matrix}...\end{matrix}` is not supported.
4. **No alignment or equation environment** — multi-line equations, aligned equals signs, step-by-step derivations not supported.
5. **Limited operator support** — no sum `\sum`, product `\prod`, limit `\lim`, derivative `\frac{d}{dx}`.
6. **No LaTeX error handling** — if the AI generates malformed LaTeX, the widget produces garbled output with no fallback.

**The real concern:** The widget is a 394-line hand-rolled parser that covers only ~30 commands. For advanced IB Physics and Mathematics content (integrals, matrices, thermodynamics notations), it will produce incorrect or missing visual output. There is **no** `flutter_math`, `katex_flutter`, or any LaTeX typesetting package in `pubspec.yaml`.

**Verdict (MAJOR FAIL):** Math rendering is a custom hand-written parser with ~30 commands. No proper LaTeX engine. No integral, sum, product, matrix, or derivative support. For a student working with IB-level math/physics content, this will frequently produce incorrect rendering.

---

## Step 2: Answering a Math Expression Question — The Text Input Has No Math Keyboard

I want to answer: `\int_0^4 (3t^2 + 2t) dt = 80` meters. I tap the answer field.

**What I expect:** A specialized math input keyboard or at least helper buttons for common symbols (integral, superscript, Greek letters, square root).

**What actually happens:** The answer field for `mathExpression` question type is a **plain `TextField`** (`practice_session_question_card.dart:190-192`, same as `typedAnswer`). There is:
- No math symbol keyboard
- No superscript button
- No LaTeX helpers
- No formula preview while typing
- No validation that my input is valid math
- `TextInputType.multiline` only

The validation (`answer_validation_service.dart:380-395`) normalizes by stripping spaces, lowercasing, and replacing `x` with `*`, then does **exact string comparison**. If I type "80 m" instead of "80", or "∫₀⁴ (3t²+2t) dt" instead of the exact expected LaTeX, it's marked wrong. The validation has zero tolerance for semantically equivalent but syntactically different answers — no symbolic math evaluation.

**Verdict (MAJOR FAIL):** Math expression answers are typed in a plain text field with no math input helpers. Validation is exact string comparison after minimal normalization — semantically equivalent answers are rejected.

---

## Step 3: Submitting a Hand-Drawn Answer — The Canvas Widget in Practice

The next question is: "Draw the velocity-time graph for an object accelerating at 2 m/s² from rest." This is a `graphDrawing` type question.

**What I expect:** A drawing canvas with basic graph tools — axes, grid lines, maybe a straight-line tool or shape tools. I expect I can draw a straight line representing constant acceleration.

**What actually happens:** The `graphDrawing` question type renders identically to `canvas` (`practice_session_question_card.dart:181-188`):
- Both use `CanvasDrawingWidget` with a freehand drawing surface
- Both have a simple grid (`GridPainter` at `grid_painter.dart`) — just equally spaced horizontal and vertical lines at 20px intervals
- Both have: freehand drawing (finger/stylus), undo last stroke, clear all, save as PNG
- **Neither has any graphing tools**: no axes labels, no coordinate system, no straight-line tool, no shape tools, no text tool, no color picker

For a "draw a velocity-time graph" question, the student must draw a perfectly straight diagonal line freehand — which is nearly impossible on a phone screen. There is:
- No snap-to-grid
- No straight-line tool
- No coordinate axes rendering
- No origin marker
- No scale or measurement

**Validation of the drawing** (`answer_validation_service.dart:443-463` for `graphDrawing`, `413-424` for `canvas`): validates only that data is non-empty and can be base64-decoded. There is **zero content-based evaluation** — no check that the line is actually a straight line, no check that the slope represents 2 m/s², no comparison with the correct answer. Any scribble on the canvas is marked "correct."

**Verdict (BLOCKER FAIL):** The `graphDrawing` question type is identical to `canvas` — freehand drawing only, no graphing tools whatsoever. Validation is structural only (non-empty data), never content-based. A random scribble is marked "correct."

---

## Step 4: The Graph Renderer — A Feature That Exists Only in Localization Files

After the practice session, I go to check my study statistics. The product vision mentions "rich rendering for mathematical and scientific content, including graphs and charts." I look for a way to render or visualize graphs.

**What I expect:** Some kind of graph/chart visualization tool — maybe in the dashboard, in practice results, or as a standalone feature.

**What I find on the code level:** The `lib/l10n/generated/app_localizations.dart` file contains **17+ getters and methods** for a "Graph Renderer" feature:
- `graphRenderer` — "Graph Renderer"
- `refreshGraph` — "Refresh graph"
- `validateGraphType` — "Validate graph type"
- `graphTypeDetection` — "Graph Type Detection"
- `graphVisualization(String graphType)` — "Showing $graphType visualization"
- `graphTypeDetectionError` — "Graph type detection failed"
- `useLlmToValidateGraph` — "Use LLM to validate graph:"
- `validateWithLlm` — "Validate with LLM"
- `graphTypeMatchesData` — "Graph type matches data structure"
- Plus labels for `lineGraph`, `barChart`, `scatterPlot`, `pieChart` in the types

**These strings are defined in both English and Spanish ARB files, with generated methods in `app_localizations.dart:1671-1887`.**

**However: A search for these strings in `lib/` reveals ZERO usage outside the l10n files.** There is:
- No widget that references `graphRenderer`
- No screen or route for a graph renderer
- No service that implements graph rendering
- No provider that manages graph state
- No import of these methods anywhere in `lib/features/`

**The l10n git history shows these strings were added in a single commit as part of a planned feature that was never built.** The feature description in `app_en.arb` mentions: "Tool that renders and validates graphs from student-submitted data, supporting detection and visualization of line, bar, scatter, and pie chart types."

**Verdict (BLOCKER FAIL):** The Graph Renderer exists only as localization strings — 17+ entries in English and Spanish with full descriptions, but zero implementation. This is dead placeholder code. The feature it describes (AI graph type detection, validation, LLM-based validation) sounds transformative but completely inaccessible to users.

---

## Step 5: Checking If Generated Questions Are Actually Correct — The "Validation" Stage

I go to my content library and look at questions generated from my physics textbook upload. The product vision says: "AI-generated content should not be blindly trusted; correctness, consistency, and usefulness should be continuously validated and improved."

**What I expect:** The AI-generated questions have gone through some validation process — perhaps the LLM double-checks them, or they're flagged for my review, or at least I can see a "verified" badge. I trust the app to tell me if a question might be wrong.

**What actually happens (tracing the pipeline):**

The `ContentPipeline.processFullPipeline()` (`content_pipeline.dart`) has these stages:
1. `extracting` — text extraction
2. `classifying` — topic classification + summary
3. `generatingQuestions` — LLM generates questions
4. **`validating`** — validates generated questions

**Stage 4 — the "validating" stage (lines 202-210):**
```dart
onProgress?.call(ProcessingStatus.validating, 'Validating generated questions...');
updated = _updateStatus(updated, ProcessingStatus.validating);
final validationResults = _validateGeneratedQuestions(updated, questionIds);
if (validationResults.isNotEmpty) {
  _logger.w('Question validation warnings: $validationResults');
}
```

**The actual `_validateGeneratedQuestions()` method (lines 265-274):**
```dart
List<String> _validateGeneratedQuestions(Source source, List<String> questionIds) {
  final warnings = <String>[];
  if (questionIds.isEmpty) {
    warnings.add('No questions were generated for source ${source.id}');
  }
  return warnings;
}
```

**This is a complete stub.** The validation stage:
- Does NOT check factual correctness against source content
- Does NOT verify answer consistency  
- Does NOT cross-reference questions with each other
- Does NOT use the LLM for validation
- Does NOT score or rank question quality
- Does NOT check for duplicate or contradictory questions
- Does NOT flag anything for user review
- Only adds a warning if ZERO questions were generated (the empty list case)

During generation itself (`_isValidGeneratedQuestion()`, lines 452-496), there IS structural validation (question text non-empty, MCQ has at least 2 options, correct answer exists in options, explanation non-empty). But this is schema validation, not content validation. If the AI generates a question with the wrong correct answer, it passes structural validation.

**There is NO mechanism to flag questions for human review.** The `Question` model has:
- No `isValidated` field
- No `needsReview` field
- No `verifiedBy` field
- No `reviewedAt` timestamp

**Verdict (BLOCKER FAIL):** The "validating" pipeline stage is a stub that only checks if the question list is empty. No content-level validation exists. The product vision's requirement to not blindly trust AI-generated content is unimplemented. Incorrect AI-generated questions pass through with zero scrutiny.

---

## Step 6: The Variant System — A Declared Field That's Never Populated

The product vision says questions should be "expanded through generated variants." I'd expect that after answering a question, the app can generate a variant — same concept, different numbers or wording — to ensure I truly understand.

**What I expect:** After answering a stoichiometry question correctly, the app offers a variant: "Great! Try this similar question: If 2.5 mol of NaOH reacts with 1.5 mol of HCl..." so I can't just memorize the answer.

**What actually happens:** The `Question` model at `question_model.dart:28` declares:
```dart
@HiveField(6, defaultValue: [])
final List<String> variantIds;
```

This field is:
- Declared in the model constructor (`line 77`: `this.variantIds = const []`)
- Serialized in `toJson()` (`line 100`: `'variantIds': variantIds`)
- Deserialized in `fromJson()` (`line 147`: `variantIds: List<String>.from(json['variantIds'] ?? [])`)
- Preserved in `copyWith()` (`line 194`: `variantIds: variantIds ?? this.variantIds`)

**But it is NEVER populated.** There is:
- No service that generates question variants
- No provider that manages variant state
- No UI for creating or displaying variants
- No code anywhere in `lib/` that writes to `variantIds`
- Every question is created with `variantIds: const []` or defaulted to `[]`

**The entire variant system is a structural placeholder.** The field exists in the model and all serialization paths, but no business logic ever populates it. This feature is 0% implemented.

**Verdict (BLOCKER FAIL):** The question variant system (`variantIds` field) is fully declared in the model — model, serialization, deserialization, copyWith — but completely unimplemented. No code generates variants. The feature described in the product vision doesn't exist.

---

## Step 7: Question Type Dead Zones — 8 of 10 Types Are Unreachable

I notice in my practice sessions that I only see two types of questions: multiple choice and typed answer. I recall the product mentioning canvas drawing, graph drawing, file upload, audio recording...

**What the `QuestionType` enum declares** (`enums.dart:3-14`):
- `singleChoice` ✓ (generated by pipeline)
- `multiChoice` ✓ (generated by pipeline)
- `typedAnswer` ✓ (generated by pipeline)
- `canvas` ✗ (generated but removed by pipeline — must be manually created)
- `essay` ✓ (generated by pipeline)
- `stepByStep` ✗ (never generated)
- `mathExpression` ✓ (generated by pipeline)
- `graphDrawing` ✗ (never generated — filtered out by `_defaultAllowedTypes`)
- `fileUpload` ✗ (never generated + stub widget)
- `audioRecording` ✗ (never generated + stub widget)

**The generation pipeline's `_defaultAllowedTypes`** (`content_pipeline.dart:378-383`):
```dart
static const _defaultAllowedTypes = [
  'singleChoice',
  'multiChoice',
  'typedAnswer',
  'mathExpression',
  'essay',
];
```

**Only 5 types are generated.** The other 5 (`canvas`, `stepByStep`, `graphDrawing`, `fileUpload`, `audioRecording`) are excluded from auto-generation. However:
- `canvas` and `graphDrawing` DO have fully functional UI widgets (`CanvasDrawingWidget`)
- `stepByStep` has a UI (plain text field, same as `typedAnswer`)
- `fileUpload` and `audioRecording` have **stub widgets** (`SizedBox.shrink()` in practice sessions, placeholder buttons in question bank)

**In the actual rendering** (`practice_session_question_card.dart:197-199`):
```dart
case QuestionType.fileUpload:
case QuestionType.audioRecording:
  return const SizedBox.shrink();
```

These question types render as **nothing** — zero pixels. If somehow a question of these types existed (e.g., manually inserted), it would be invisible during a practice session. The file picker and audio recording stubs exist only in the question bank view and don't actually invoke any system APIs.

**Verdict (MAJOR FAIL):** 5 of 10 question types are excluded from auto-generation by the pipeline's `_defaultAllowedTypes`. The `fileUpload` and `audioRecording` types have stub widgets that render invisible (`SizedBox.shrink()`) during practice sessions, making them completely non-functional even if questions of those types existed.

---

## Step 8: The Canvas Drawing Answer Validation — Empty Scribbles Are "Correct"

I submit a canvas drawing to answer a question. I literally just scribble on the screen.

**What I expect:** The app should evaluate my drawing against the expected answer — check if I drew the correct molecular structure, the correct graph shape, etc.

**What actually happens** (`answer_validation_service.dart:413-424`):
```dart
static ValidationResult validateCanvasDrawing(List<Map<String, dynamic>> canvasData, Markscheme? markscheme, ...) {
  if (canvasData.isEmpty) {
    return ValidationResult(isCorrect: false, explanation: msgs.noDrawingDetected);
  }
  for (final point in canvasData) {
    if (point.isEmpty) {
      return ValidationResult(isCorrect: false, explanation: msgs.invalidDrawingData);
    }
  }
  return ValidationResult(isCorrect: true, explanation: msgs.drawingDetected);
}
```

**And for `graphDrawing`** (lines 443-463): same pattern — base64-decode, JSON-parse, check non-empty list. If there's data, it's correct.

**There is NO evaluation of drawing content:**
- A random scribble is "correct"
- A blank canvas with one dot is "correct"  
- The correct molecular structure is "correct"
- A completely wrong graph is "correct"

The validation falls back to the `markscheme.explanation` for display, but the `isCorrect` boolean is based purely on whether the student drew anything.

**Verdict (BLOCKER FAIL):** Canvas and graph drawing submissions are validated on presence only — any non-empty drawing is automatically correct. No content-based evaluation exists. Students can pass canvas/graph questions by scribbling randomly.

---

## Step 9: What About File Upload and Audio Recording — Completely Non-Functional

I try to answer the next question by uploading a file. But there are no file upload or audio recording questions in practice because they're never auto-generated. Let's say they were somehow created.

**What I find in the code:**

**Question Bank (`question_card_widget.dart`):**
- `fileUpload` (lines 324-349): Shows a placeholder "Upload File" button. Tapping it sets the answer to the literal string `'file_uploaded'` — no actual `file_picker` integration.
- `audioRecording` (lines 352-365): Shows a placeholder "Record Audio" button. Tapping it sets the answer to `'audio_recorded'` — no actual recording integration.

**Practice Session (`practice_session_question_card.dart:197-199`):**
- Both types render as `const SizedBox.shrink()` — invisible!

**Both `file_picker` and `speech_to_text`/`flutter_tts` packages exist in `pubspec.yaml`, but they are never wired into the question answer flow.** The voice input functionality (`VoiceBar`, microphone button) is a separate feature for the tutor conversation, not connected to `audioRecording` question type answers.

**Verdict (BLOCKER FAIL):** The `fileUpload` and `audioRecording` question types are completely non-functional. File upload sets a placeholder string, not an actual file. Audio recording is similarly stubbed. In practice sessions, they render as invisible (`SizedBox.shrink()`).

---

## Step 10: Trust Score — How Do I Know If the AI-Taught Content Is Right?

I've been using the AI tutor and practicing with AI-generated questions for a week. The product vision says I shouldn't blindly trust AI content. But the app gives me no tools to verify correctness.

**What I expect:** Some mechanism to verify or flag questionable AI content:
- A "Report incorrect" button on questions
- A "This explanation seems wrong" feedback option
- An indicator showing which content was AI-generated vs. verified
- The ability to compare AI answers against the source textbook

**What actually happens:** There is none of this. The content pipeline:
1. Generates questions from the LLM
2. Validates structure only (schema checks)
3. Saves them as regular questions with no "human reviewed" marker
4. Never re-evaluates correctness against source material

The `Question` model has no trust-related fields. The `Source` model has `processingStatus` which only tracks pipeline stage, not correctness. The `Markscheme` stores just the correct answer, explanation, and acceptable answers — no confidence score, no validation source.

If the AI generates a question that contradicts the textbook, the student has no way to:
- Flag it for review
- See that it was AI-generated (not verified)
- Compare against the source material
- Trigger regeneration or correction

**Verdict (BLOCKER FAIL):** The app provides zero mechanisms for students to verify, flag, or report AI-generated content. The product vision's explicit requirement to not blindly trust AI content is entirely unimplemented at the user-facing level. AI-generated questions are presented with the same authority as verified content.

---

## Summary of Expectations vs Reality

| # | Expectation | Reality | Status |
|---|---|---|---|
| 1 | Math formulas render properly (integrals, fractions, matrices) | Custom hand-rolled parser with ~30 commands; no LaTeX engine | **FAIL (MAJOR)** |
| 2 | Math answer input has specialized keyboard/helpers | Plain TextField — identical to typedAnswer | **FAIL (MAJOR)** |
| 3 | Math validation tolerates equivalent answers | Exact string comparison after minimal normalization | **FAIL (MAJOR)** |
| 4 | Graph drawing has coordinates, axes, shape tools | Identical to canvas — freehand drawing only | **FAIL (BLOCKER)** |
| 5 | Graph drawing validation checks content | Validates only that data is non-empty | **FAIL (BLOCKER)** |
| 6 | Graph Renderer feature exists for chart visualization | 17+ l10n strings defined; zero implementation | **FAIL (BLOCKER)** |
| 7 | AI-generated questions are validated for correctness | `_validateGeneratedQuestions()` is a stub (empty-list check only) | **FAIL (BLOCKER)** |
| 8 | Question variant system auto-generates alternates | `variantIds` field declared but NEVER populated | **FAIL (BLOCKER)** |
| 9 | All 10 question types are reachable | Pipeline only generates 5 types; `_defaultAllowedTypes` excludes 5 | **FAIL (MAJOR)** |
| 10 | `fileUpload` type actually picks files | Stub — sets answer to literal `'file_uploaded'` | **FAIL (BLOCKER)** |
| 11 | `audioRecording` type actually records audio | Stub — sets answer to `'audio_recorded'`; practice renders invisible | **FAIL (BLOCKER)** |
| 12 | Canvas drawing is evaluated for correctness | Any non-empty drawing is "correct" | **FAIL (BLOCKER)** |
| 13 | I can flag/report incorrect AI-generated content | No "report," "flag," or "not verified" mechanism exists | **FAIL (BLOCKER)** |
| 14 | Questions show AI-generated vs. verified status | No trust/verification field on Question model | **FAIL (BLOCKER)** |
| 15 | Content validation pipeline uses LLM for re-check | Never called after generation; structural checks only | **FAIL (BLOCKER)** |
