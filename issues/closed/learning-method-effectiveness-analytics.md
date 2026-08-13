# Analytics: Track Learning Method Effectiveness and Personalize Teaching Approach

**Severity:** minor
**Affected area:** Core Analytics, Mentor, Teaching
**Reported by:** codebase audit

## Description

The vision document states that StudyKing should learn "what learning methods work best for" the student. Currently, the platform tracks extensive performance metrics (accuracy, streaks, study time, adherence) but does **not** analyze which teaching or learning methods are most effective for a given student.

Specifically, there is no tracking of:
1. Whether the student learns better with visual explanations (slides, diagrams) vs. textual explanations vs. interactive examples
2. Whether the student performs better with short, frequent sessions vs. longer, deeper sessions
3. Whether the student benefits more from spaced repetition review vs. new topic exploration
4. Whether the student prefers step-by-step worked examples vs. problem-solving from first principles
5. Which lesson block types (text, example, exercise, quiz, summary, slide) produce the best retention for this student

Without this data, the AI tutor and mentor cannot personalize their teaching approach to match the student's optimal learning style. Every student gets the same teaching approach regardless of their individual effectiveness patterns.

## Expected behavior

The system should:
- Track which lesson block types lead to highest quiz scores for each student
- Analyze whether visual (slides) or textual (reading) content produces better retention
- Correlate session length with accuracy improvement (do longer or shorter sessions work better?)
- Track whether the student improves more with spaced repetition vs cramming
- Surface recommendations to the mentor: "This student learns best with visual explanations and 25-minute sessions"
- Allow the AI tutor to adapt its teaching style based on what works for this student

## Actual behavior

No learning method analytics exist. All students receive the same teaching approach.

## Code analysis

- `lib/core/services/mastery_calculation_service.dart` — Tracks accuracy, confidence, speed, forgetting risk — but not learning method
- `lib/features/teaching/services/conversation_manager.dart:90-100` — Adaptive pace is based only on accuracy, not learning method preference
- `lib/features/teaching/services/conversation_manager.dart:300-316` — Chunk size adaptation is based on pace, not learning style
- `lib/features/mentor/services/mentor_context_builder.dart` — No learning preference data in context
- `lib/core/services/long_term_memory.dart` — Session summaries may contain preference mentions but aren't systematically analyzed

## Suggested approach

1. **Create a `LearningMethodAnalyticsService`** that:
   - Tracks per-student: which block types they engage with most, which produce best quiz scores, optimal session duration
   - Correlates teaching approach with outcomes (accuracy improvement, retention rate, time-to-mastery)
   - Stores results in a new Hive box `learning_method_analytics`

2. **Add a `LearningPreference` model**:
   ```dart
   class LearningPreference {
     final String studentId;
     final PreferredBlockType preferredBlockType; // text, slide, example, exercise, quiz, summary
     final int optimalSessionDurationMinutes;
     final bool prefersVisualExplanations;
     final bool prefersStepByStep;
     final double spacedRepetitionEffectiveness; // correlation between SR adherence and retention
     final Map<String, double> methodEffectivenessScores; // method -> effectiveness score
   }
   ```

3. **Integrate with the tutor** — Pass learning preferences as additional context in the tutor system prompt:
   ```
   "This student learns best with visual explanations. Use more slides and diagrams."
   ```

4. **Integrate with the mentor** — Include a learning-style summary in `MentorContextBuilder` so the mentor can suggest optimal study approaches:
   ```
   "Based on your learning patterns, you retain information best with 25-minute sessions 
   using interactive examples. Would you like to try that approach for today's lesson?"
   ```

5. **Add a dashboard card** — Show learning effectiveness insights on the dashboard (optional, could be in a dedicated analytics section)
