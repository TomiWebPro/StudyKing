# Teaching: Add Student Feedback Mechanism for Lesson/Tutor Quality

**Severity:** major
**Affected area:** Teaching Mode — Post-Lesson, Mentor Mode
**Reported by:** codebase audit

## Description

The vision document states that AI-generated content should not be blindly trusted — "correctness, consistency, and usefulness should be continuously validated and improved." However, there is **no mechanism for the student to provide feedback** on the quality of lessons, tutor explanations, or generated content.

Currently, the system tracks quantitative metrics (accuracy, completion, time spent) but has no qualitative feedback loop:
- No "Was this helpful?" prompt after tutor explanations
- No star rating or thumbs up/down for lesson quality
- No way to report incorrect AI-generated content
- No feedback collection at the end of lessons
- No mechanism to identify which teaching approaches work vs don't work for a given student

Without this feedback, the system cannot:
- Identify and fix incorrect AI explanations
- Learn which teaching styles are most effective per student
- Improve lesson quality over time
- Detect when the AI tutor is underperforming

## Steps to reproduce

1. Complete a tutor lesson
2. Notice the AI gave an incorrect or unclear explanation
3. There is no button, form, or mechanism to report this

## Expected behavior

After each lesson (or at natural breakpoints during lessons), the student should be able to:
- Rate the lesson quality (1-5 stars or emoji-based)
- Report incorrect or unhelpful content
- Provide free-text feedback
- Thumbs up/down individual tutor explanations in chat

## Actual behavior

No student feedback mechanism exists. Lesson quality is never measured subjectively.

## Code analysis

- `lib/features/teaching/presentation/tutor_screen.dart:850-920` — `_endLesson()` completes the session but has no feedback step
- `lib/features/teaching/data/models/tutor_session_model.dart` — `TutorSession` has `confidenceRating` but this is the student's self-assessment, not feedback on the tutor
- `lib/features/teaching/services/tutor_service.dart` — No feedback-related methods
- `lib/features/mentor/services/mentor_wellbeing_service.dart` — Checks student wellbeing but not lesson quality

## Suggested approach

1. **Create a `LessonFeedback` data model**:
   ```dart
   class LessonFeedback {
     final String sessionId;
     final int rating; // 1-5
     final bool wasHelpful;
     final String? incorrectContent; // What the student thinks was wrong
     final String? studentComment;
     final List<String> tags; // "too_fast", "too_slow", "confusing", "excellent", etc.
     final DateTime timestamp;
   }
   ```

2. **Add a feedback step at lesson end** — Before the closing screen, show a brief feedback dialog:
   - "How was this lesson?" (5-star rating or emoji faces)
   - "Was anything incorrect or confusing?" (free text + optional highlight of specific chat messages)
   - "Any other comments?"

3. **Add per-message feedback** in the chat bubbles — A small thumbs up/down button on each tutor message allows the student to flag specific responses as helpful or unhelpful

4. **Store feedback in a new Hive box** `lesson_feedback` and surface it in:
   - The mentor's context (so the mentor knows which topics the tutor taught poorly)
   - The dashboard (show "lessons needing review")
   - The LLM task manager (flag low-rated lessons for investigation)

5. **Use feedback to improve the tutor** — Inject past feedback into the tutor system prompt:
   ```
   Note: The student has previously reported that explanations about {topic} 
   were confusing. Please provide clearer, more step-by-step explanations for this topic.
   ```

6. **Create a `FeedbackAnalyzer`** that periodically analyzes feedback trends and identifies patterns (e.g., "Topic X consistently receives low ratings — regenerate lesson content")
