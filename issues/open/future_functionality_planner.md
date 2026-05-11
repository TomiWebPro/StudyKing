# [Feature] Wire Up Spaced Repetition Mode — Backend Exists, UI is a Dead Button

**Date:** May 11, 2026
**Priority:** High
**Type:** Future Functionality / Missing Feature Wiring
**Status:** Open

---

## Context

StudyKing presents **four practice modes** on the Practice home screen (`lib/features/practice/presentation/practice_screen.dart:173-209`):

| Mode | Icon | Subtitle | Status |
|------|------|----------|--------|
| Quick Practice | `flash_on` | "10 random questions" | ✅ Functional |
| **Spaced Repetition** | `schedule` | "Coming soon" | ❌ **Dead button** |
| Topic Focus | `category` | "Practice specific topics" | ⚠️ Snackbars "coming soon" |
| Weak Areas | `bar_chart` | "Focus on mistakes" | ❌ Dead button |

Two modes are displayed as enticing cards with icons and colors — but both **"Coming soon" modes** are entirely non-functional (`onTap: null`). Users see the cards, tap them, and get nothing. This creates a broken promise and erodes trust in the app's feature depth.

Critically, **Spaced Repetition has a complete backend** (`lib/core/data/repositories/spaced_repetition_repository.dart`) with:
- `getQuestionsDueForReview()` — fetch questions whose `nextReview` date has passed
- `updateNextReviewDate()` — schedule next review based on mastery (7d, 3d, 1d, 12h, 30m)
- `getSubjectDueCount()` — count due questions per subject
- `SpacedRepetitionQueries` static helpers for filtering

The infrastructure is ready. The UI is a placeholder.

---

## Affected Files

- **Primary UI:** `lib/features/practice/presentation/practice_screen.dart` (lines 188-194 — disabled Spaced Repetition card)
- **Backend:** `lib/core/data/repositories/spaced_repetition_repository.dart`
- **Question Model:** `lib/core/data/models/question_model.dart` (`nextReview` field at line 64)
- **Session Tracking:** `lib/core/data/repositories/study_session_repository.dart`
- **Attempts:** `lib/core/data/repositories/attempt_repository.dart`

---

## Rationale

1. **Spaced repetition is a core differentiator** for a study app — it directly impacts learning retention and user stickiness
2. **Backend is complete but unused** — `SpacedRepetitionRepository` has been built but never connected to the practice workflow
3. **User-visible dead buttons** damage first impressions — two of four practice modes do nothing
4. **Topic Focus is also non-functional** but shown as a mode — `_showTopicSelector()` only shows a snackbar (line 479)
5. **"Weak Areas"** mode would require analytics infrastructure, but Spaced Repetition is a prerequisite for meaningful weakness detection

---

## Acceptance Criteria

1. **Spaced Repetition card becomes interactive** — tapping opens a subject selector, then begins a practice session with due questions
2. **Due questions are fetched** via `SpacedRepetitionRepository.getQuestionsDueForReview()` filtered by subject
3. **Session completion updates `nextReview`** — after each answer, call `updateNextReviewDate()` with the mastery level
4. **Due count badge** appears on the Spaced Repetition card showing how many questions are ready for review (using `getSubjectDueCount`)
5. **Empty state** shown when no questions are due ("All caught up! No reviews scheduled.")
6. **Topic Focus card** becomes functional with actual topic selection from the lessons feature
7. **"Weak Areas"** mode can remain as a placeholder or be scoped to a future analytics iteration

### Test Scenarios

| Scenario | Expected Behavior |
|----------|-------------------|
| Tap Spaced Repetition with 0 due questions | Show "All caught up" empty state |
| Tap Spaced Repetition with due questions | Show subject selector, then start session |
| Complete a question in SR mode | Update `nextReview` based on correctness |
| Tap Topic Focus | Show actual topic list from lessons |
| Tap Weak Areas | Either work or show "Coming soon" message |

---

## Supporting Notes

- The `SpacedRepetitionRepository` uses Hive boxes — ensure `init()` is called before use
- Mastery level calculation should use attempt history (correct/total attempts ratio)
- The interval scaling in `updateNextReviewDate()` already exists with 5 tiers (0.9+, 0.7+, 0.5+, 0.3+, below 0.3)
- Consider adding a "due today" home screen widget for quick access
