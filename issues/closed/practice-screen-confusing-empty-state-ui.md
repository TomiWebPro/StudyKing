# Practice screen: confusing empty-state with disabled "Run" button, redundant buttons

**Severity:** major
**Affected area:** Practice screen (empty state / no subjects)
**Reported by:** user

## Description

When a user has **no subjects** on the Practice screen, the UI is confusing in several ways:

1. A **disabled FAB** ("Run" button with play icon) is displayed at the bottom of the screen showing the text "No Subjects" but it is greyed out and cannot be tapped (`onPressed: null`).
2. Simultaneously, a **`PracticeEmptyState`** widget is shown in the center of the screen with its own "Add Subject" button and an "Upload Material" text link.
3. This creates **redundant messaging**: the user is told "no subjects" twice in two different visual locations, but one of them is a dead button that cannot be used.
4. When subjects exist but there are **no questions**, the `_buildNoQuestionsBanner()` appears with an "Upload Materials" button — but the FAB still says "Practice" while being disabled (because no questions exist), so the user has a primary action button they can't use.

Overall, the screen is not guiding new users through a clear onboarding flow. The question "what should I do first?" is not answered well.

## Steps to reproduce

1. Open the app for the first time (or delete all subjects).
2. Navigate to the **Practice** tab.
3. Observe:
   - A floating "Run" button (play icon) at the bottom-right that is greyed out and says "No Subjects".
   - A centered empty-state card saying "No Practice Sessions Yet" with an "Add Subject" button and a smaller "Upload Material" link.

## Expected behavior

- When there are **no subjects**, the screen should show a **single, clear onboarding state** that guides the user step-by-step:
  1. Create a subject first (primary action).
  2. Upload study material (secondary action, shown after or alongside).
- The disabled FAB should be **hidden entirely** when there are no subjects (or replaced with a **meaningful**, enabled CTA like "Add Your First Subject").
- When subjects exist but **no questions** are available, the FAB should be hidden or show a clear CTA that works (e.g., "Upload Materials" instead of "Practice").

## Actual behavior

- Disabled FAB remains visible with `Icons.play_arrow` + "No Subjects" text — visually a dead end.
- Empty state below repeats the same "no subjects" message.
- The play icon implies "run" / "start" but the button does nothing.
- When subjects exist but no questions: FAB says "Practice" but is disabled, while the body shows a "Upload Materials" card. The user has a primary nav button they can't use.

## Code analysis

- **`lib/features/practice/presentation/screens/practice_screen.dart:858-887`** — The `floatingActionButton` is always rendered regardless of state. When `_subjects.isEmpty`, `onPressed` is set to `null` (disabled) and the label shows `l10n.noSubjects`. The disabled FAB is visually confusing because the play icon suggests action but the button is dead.

- **`lib/features/practice/presentation/screens/practice_screen.dart:1113`** — When `_subjects.isEmpty`, `_buildBody()` returns early with only `PracticeEmptyState()`. But the FAB is still painted by the Scaffold, creating two redundant "no subjects" indicators.

- **`lib/features/practice/presentation/widgets/practice_empty_state.dart:1-32`** — The `PracticeEmptyState` widget shows an `EmptyStateWidget` with "Add Subject" button and a secondary `TextButton` for "Upload Material". The visual hierarchy doesn't clearly communicate the two-step onboarding flow (subject → upload → practice).

- **`lib/features/practice/presentation/screens/practice_screen.dart:1076-1096`** — `_buildNoQuestionsBanner()` is shown when subjects exist but `_totalQuestionCount == 0`. It has an "Upload Materials" filled button, but the FAB still shows "Practice" disabled.

- **`lib/features/practice/presentation/screens/practice_screen.dart:869-874`** — The FAB's `onPressed` check is only `_subjects.isEmpty ? null : ...`. It does not account for the "no questions" case. When subjects exist but there are zero questions, the FAB is enabled but `_showSubjectSelector` → `_startPractice` → eventually shows a snackbar "no questions available" — this is a poor UX flow.

## Suggested approach

1. **Hide the FAB when there are no subjects.** The empty state is enough. If we want a FAB, make it a meaningful enabled button that says "Add Subject" with an `add` icon (not `play_arrow`).

   ```dart
   // In build():
   floatingActionButton: _subjects.isEmpty
       ? null  // or a FloatingActionButton with add-icon that navigates to subject creation
       : (existing FAB logic)
   ```

2. **Improve `PracticeEmptyState` to show a clear two-step onboarding:**
   - Primary button: "Add Subject" (already exists)
   - After adding a subject, guide the user to upload materials
   - Consider showing both options together with clearer explanation text

3. **When subjects exist but no questions:**
   - Change the FAB label from "Practice" to "Upload Materials" and navigate to the upload screen
   - OR hide the FAB and let the `_buildNoQuestionsBanner()` be the sole CTA

4. **Consolidate the logic so there is exactly one primary CTA per state:**
   - **No subjects →** "Add Subject" (in empty state, no FAB or an enabled Add Subject FAB)
   - **Subjects exist, no questions →** "Upload Materials" (no disabled FAB)
   - **Subjects exist, questions exist →** "Practice" (current behavior, enabled)
