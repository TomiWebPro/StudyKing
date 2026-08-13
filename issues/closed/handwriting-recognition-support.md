# Canvas/Input: Add Handwriting Recognition Support

**Severity:** major
**Affected area:** Teaching Mode, Practice Mode — Canvas/Drawing Input
**Reported by:** codebase audit

## Description

The vision document specifies that students should be able to submit "handwritten/drawn responses on canvas" and have the system perform "vision-based interpretation of student work." Currently, the canvas drawing widget (`lib/features/questions/presentation/widgets/canvas_drawing_widget.dart`) captures drawings as base64-encoded PNG images and sends them to the LLM for interpretation.

This approach has fundamental limitations:

1. **No handwriting-to-text conversion** — Handwritten math expressions, chemical formulas, or code are sent as images rather than being transcribed to text that the system can process structurally
2. **No structured evaluation** — The LLM must visually interpret handwriting from scratch each time, with no specialized handwriting model
3. **No math expression parsing** — Handwritten equations like "x² + 2x + 1 = 0" are treated as images, not parseable math
4. **No local inference** — Handwriting recognition requires an internet-connected multimodal LLM
5. **Latency** — Sending canvas captures to LLM and waiting for visual interpretation creates 3-10s delays in the tutor conversation

## Steps to reproduce

1. Start a tutor session
2. Click the drawing button to open the canvas
3. Write a math expression by hand (e.g., "x^2 + 2x + 1 = 0")
4. Submit the drawing
5. Observe: the drawing is sent as a base64 image to the LLM, which must visually interpret it

## Expected behavior

Handwriting should be:
- Transcribed to text in real-time (as the student draws, or within 500ms of submission)
- Math expressions should be parsed into structured format (LaTeX or similar)
- The system should be able to evaluate handwritten answers against mark schemes
- Local/offline recognition should be available as an option

## Actual behavior

Canvas drawings are sent as raw images to the LLM with no handwriting-specific processing.

## Code analysis

- `lib/features/questions/presentation/widgets/canvas_drawing_widget.dart` — Captures drawing as PNG bytes
- `lib/features/teaching/presentation/tutor_screen.dart:690-730` — Drawing sent via `manager.processImage(base64Drawing)` to LLM
- `lib/features/teaching/services/conversation_manager.dart` — Processed as generic image, no handwriting-specific handling
- `lib/core/services/llm/llm_chat_service.dart` — Image sent as multimodal content in chat completion

## Suggested approach

1. **Integrate a handwriting recognition library** such as:
   - `google_mlkit_digital_ink_recognition` — Google's on-device handwriting recognition. Supports text, math expressions, and gestures. Works offline.
   - `myscript` or similar math handwriting recognition SDK — optimized for mathematical notation

2. **Add an `InputMode` to the canvas** with three modes:
   - **Draw** (current) — freeform drawing, sent as image
   - **Handwrite Text** — strokes interpreted as text characters in real-time
   - **Handwrite Math** — strokes interpreted as math expressions, rendered as LaTeX

3. **Convert recognized text/math to structured input**:
   - Text transcripts go directly into the chat as if typed
   - Math expressions are rendered as LaTeX for the tutor context
   - Both are evaluable against mark schemes

4. **Keep LLM visual interpretation only as fallback** for:
   - Diagrams, graphs, charts
   - Mixed text+drawing responses
   - Low-confidence handwriting detections
