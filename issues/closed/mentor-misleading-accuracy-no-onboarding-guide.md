# Mentor shows misleading "accuracy below 60%" and lacks onboarding guide for new users

**Severity:** major
**Affected area:** Mentor screen & recommendations
**Reported by:** user

## Description

Two related issues on the Mentor screen that hurt the first-day / new-user experience:

### Issue A: Misleading accuracy recommendation with no practice data

On a user's first day (zero practice attempts), the mentor's **suggested action card** and **progress report** show "Your overall accuracy is below 60%. Focus on reviewing fundamental concepts." This is incorrect and irrelevant — accuracy is 0% not because the user performed poorly, but because they haven't answered any questions yet. The system should detect the "no data" case and show a helpful onboarding/start-practicing message instead.

### Issue B: No persistent onboarding guide for what the Mentor can do

The mentor screen has no help button, onboarding tutorial, or persistent feature cards explaining what the AI mentor can do. The only explanation is the welcome message that appears in the chat (which lists scheduling, progress review, planning, motivation), but:
- The empty state only shows "AI Mentor" + "Your personal AI academic assistant" — too generic
- If the user clears the conversation, they get the welcome again, but there's no always-visible reference
- There's no way to discover the mentor's capabilities without sending a chat message first

## Steps to reproduce

### Issue A
1. Install app / fresh start with zero practice attempts
2. Open the Mentor section
3. Observe the suggested action card at the top: "Your overall accuracy is below 60%..."
4. Tap the analytics icon to open the progress report
5. Observe accuracy shown as 0% with a red bar

### Issue B
1. Open the Mentor section with no prior conversation history
2. Observe the empty state: just title "AI Mentor" and subtitle "Your personal AI academic assistant"
3. No help icon, no onboarding card, no "what can I do" hint

## Expected behavior

### Issue A
- If `totalAttempts == 0`, the accuracy recommendation should **not** be generated. Instead, a message like "Start practicing to see your accuracy data" or "No practice data yet — try a practice session!" should be shown.
- The progress report should indicate "No data yet" or hide the accuracy section when there are zero attempts.

### Issue B
- The mentor should have a visible way for new users to discover its capabilities (e.g., a help icon, an onboarding carousel, a persistent info card, or feature suggestion chips).

## Actual behavior

### Issue A
- `getRecommendations()` in `study_progress_tracker.dart` triggers the "below 60%" recommendation when accuracy is 0 (which happens because accuracy defaults to 0.0 when `totalAttempts == 0`).
- The suggested action card and progress report show this irrelevant advice.

### Issue B
- Only `_buildEmptyState()` renders the generic greeting and subtitle. No onboarding/guide component exists.

## Code analysis

### Issue A — Root cause

- **`lib/core/services/study_progress_tracker.dart:211`** — `getRecommendations()` checks `if ((stats['accuracy'] as int) < 60)` without verifying `totalAttempts > 0`. When `totalAttempts == 0`, accuracy is 0, which incorrectly triggers the "accuracy below 60%" recommendation.

- **`lib/core/services/study_progress_tracker.dart:44`** — `getOverallStats()` correctly sets accuracy to `0.0` when `totalAttempts == 0`, but this 0 is then propagated as a meaningful deficiency rather than "no data."

- **`lib/features/mentor/services/mentor_service.dart:417-425`** — `suggestNextAction()` picks the first recommendation without checking whether the user has any data yet.

- **`lib/features/mentor/services/mentor_service.dart:390-415`** — `getProgressReport()` creates a `ProgressReport` with `accuracy: 0.0` even when there are no attempts, and the progress report dialog displays it as if it's meaningful.

### Issue B — Root cause

- **`lib/features/mentor/presentation/mentor_screen.dart:823-852`** — `_buildEmptyState()` only shows `mentorGreeting` ("AI Mentor") and `mentorSubtitle` ("Your personal AI academic assistant"). No onboarding content is rendered.

- No help button, onboarding flow, or feature-discovery widget exists in the mentor screen.

## Suggested approach

### Issue A
1. In `getRecommendations()` (`study_progress_tracker.dart:204`), add an early check:
   ```dart
   final totalAttempts = stats['totalAttempts'] as int? ?? 0;
   if (totalAttempts == 0) {
     return Result.success([
       {'type': 'onboarding', 'priority': 'high', 'message': l10n.mentorNoDataYet, 'action': l10n.mentorStartPracticing}
     ]);
   }
   ```
2. In the progress report dialog (`mentor_screen.dart:1128-1159`), conditionally hide the accuracy section or show "No data yet" when `report.totalAttempts == 0`.

### Issue B
1. Add a help/onboarding icon in the mentor AppBar that opens a dialog listing capabilities.
2. Or add feature suggestion chips in the empty state that are clickable and send predefined messages (e.g., "Show my progress", "Schedule a lesson").
3. Or add a persistent info banner below the suggested action card that explains what the mentor can do.
