# Practice: Implement Proper Validation for Graph Drawing, File Upload, and Audio Recording Question Types

**Severity:** major
**Affected area:** Practice Mode — Question Validation
**Reported by:** codebase audit

## Description

The vision document specifies support for "handwritten/drawn responses on canvas" and "vision-based interpretation of student work." The UI widgets for these question types exist, but their validation/auto-grading is essentially stubbed:

1. **Graph Drawing** (`validateGraphDrawing`) — Only checks the answer is non-empty base64. Does NOT verify: correct shape, correct slope/intercepts, correct data points plotted, axis labels correct
2. **File Upload** (`validateFileUpload`) — Always returns `isCorrect: true` if the answer string is non-empty. No file content analysis at all
3. **Audio Recording** (`validateAudioRecording`) — Always returns `isCorrect: true` if the answer string is non-empty. No transcription or audio analysis

This means for these question types:
- Auto-grading in practice sessions is meaningless
- Mastery tracking is inaccurate (students always get these "correct")
- The spaced repetition engine receives no meaningful performance data
- Students cannot identify mistakes in their graph drawings or audio responses

## Steps to reproduce

1. Create a practice session with a graph drawing question
2. Draw anything (a line, a scribble, nothing)
3. Submit
4. Observe: marked as correct regardless of what was drawn

## Expected behavior

- Graph drawing: AI evaluates the graph against the expected answer (correct shape, intercepts, slope, labeled axes)
- File upload: File content is analyzed (text extraction for documents, image analysis for pictures)
- Audio recording: Audio is transcribed and compared against expected answer

## Actual behavior

Stub validation: non-empty check only.

## Code analysis

- `lib/core/services/answer_validation_service.dart:20-60` — `QuestionAnswerValidator.validateStatic()` dispatches by type:
  - `validateGraphDrawing` (line ~130): `return ValidationResult(isCorrect: true)` if non-empty
  - `validateFileUpload` (line ~140): `return ValidationResult(isCorrect: true)` if non-empty
  - `validateAudioRecording` (line ~150): `return ValidationResult(isCorrect: true)` if non-empty
- `lib/features/practice/services/exam_session_service.dart:90-120` — Exam mode auto-grading uses the same stub validators
- `lib/features/practice/services/mastery_recorder.dart:40-80` — `recordAttempt()` uses validation result, so mastery tracking is inaccurate for these types

## Suggested approach

1. **Create an `LlmAnswerEvaluator` that handles rich types**:
   ```dart
   class LlmAnswerEvaluator {
     Future<EvaluationResult> evaluateGraphDrawing({
       required String studentDrawingBase64,
       required String expectedAnswer,
       required String questionText,
     });
     
     Future<EvaluationResult> evaluateFileUpload({
       required String fileContent,
       required String expectedAnswer,
       required String mimeType,
     });
     
     Future<EvaluationResult> evaluateAudioRecording({
       required String audioBase64,
       required String expectedAnswer,
     });
   }
   ```

2. **Graph Drawing Evaluation** — Send the student's drawing (base64 PNG) and the expected answer to a multimodal LLM:
   ```
   "Does this graph correctly represent: {expectedAnswer}? 
    Evaluate: correct shape, correct intercepts, correct scale, labeled axes.
    Return: {isCorrect: bool, score: 0-1, feedback: string}"
   ```

3. **File Upload Evaluation** — For images: use OCR + LLM analysis. For documents: extract text and compare. For other files: check file type and metadata.

4. **Audio Recording Evaluation** — Transcribe the audio (via the transcription service) and compare against expected answer using semantic similarity.

5. **Add a "needs manual review" flag** — If the LLM evaluator has low confidence, flag the attempt for manual review by the student/mentor rather than auto-grading.

6. **Update `MasteryRecorder`** to use `LlmAnswerEvaluator` for rich question types, falling back to stub validation if the LLM evaluator is unavailable.
