# Study Planner "Course/Subject" input is free-text instead of selecting from existing subjects

**Severity:** major
**Affected area:** Study Planner — Create Study Plan form
**Reported by:** user

## Description

In the Study Planner's "Create Study Plan" form, the **default single-subject mode** uses a free-text `TextField` for the "Course/Subject" field, requiring the user to manually type the name of an existing subject. This is inconsistent with the **multi-syllabus mode**, which correctly uses a `DropdownButtonFormField` populated from the list of existing subjects.

Worse, if the user has **no subjects configured yet**, the field still accepts free text — it only shows an error *after* the user clicks "Generate Plan." There is no proactive guidance to create a subject first.

The error message itself (`courseNotFound`) even advises the user to "select from existing subjects using multi-syllabus mode," which validates that the current UI flow is suboptimal.

## Steps to reproduce

1. Open the Study Planner screen (`/study-planner`).
2. Observe the default single-subject "Course/Subject" field (a free-text `TextField`).
3. Type a subject name that does not exist (or leave the subjects list empty).
4. Fill in days and hours, then press "Generate Plan."
5. An error snackbar appears: "Course 'X' not found. Create it first in the Subjects tab, or select from existing subjects using multi-syllabus mode."

## Expected behavior

- The default "Course/Subject" field should allow **selecting from existing subjects** (e.g., via `DropdownButtonFormField` or `Autocomplete`) — consistent with the multi-syllabus mode.
- If **no subjects exist**, the form should proactively inform the user and offer a button/link to create a subject first (navigating to the Subject Creation screen).
- The two modes (single-subject vs. multi-syllabus) should provide a **consistent selection experience** — both should use a dropdown-style selector.

## Actual behavior

- The default single-subject mode provides a plain `TextField` for course/subject input.
- The entered text is fuzzy-matched against existing subjects after submission; if no match is found, an error is shown.
- If no subjects exist, no proactive guidance is given — the user can type anything and only discovers the problem on submission.
- The multi-syllabus mode (toggled via a button) already uses a correct `DropdownButtonFormField<String>` populated with existing subjects, creating an inconsistency between the two modes.

## Code analysis

### `lib/features/planner/presentation/widgets/study_plan_tab.dart`

- **Line 38:** `final TextEditingController _courseController = TextEditingController();` — free-text controller for the course field.
- **Lines 291–298:** The single-subject mode renders a plain `TextField` (using `_courseController`) with no suggestion/dropdown for existing subjects.
- **Lines 153–165:** After submission, the typed text is fuzzy-matched via `AnswerComparator.areEquivalent()` against `_allSubjects`. If no match is found, an error is shown.
- **Lines 43:** `List<Subject> _allSubjects = [];` — the list of subjects is already loaded from `SubjectRepository` on init, so all necessary data exists to render a dropdown.
- **Lines 299–308:** A helper text ("Enter an existing subject name") is shown below the field, but this is a weak UX band-aid rather than a proper selector.

### `lib/features/planner/presentation/widgets/multi_syllabus_input.dart`

- **Lines 60–76:** The multi-syllabus mode uses `DropdownButtonFormField<String>` populated from `allSubjects` — this is the correct approach that the single-subject mode should follow.

### Root cause

The single-subject mode was designed with a free-text `TextField` and post-submission name-matching instead of a proper subject selector. The data (`_allSubjects`) is already loaded at widget init, so there is no technical barrier to using a `DropdownButtonFormField<String>` or `Autocomplete<String>` in single-subject mode. The inconsistency exists purely because the two modes were implemented independently rather than sharing a consistent subject-selection component.

## Suggested approach

1. **Replace the free-text `TextField`** in single-subject mode (lines 291–298) with a `DropdownButtonFormField<String>` populated from `_allSubjects`, matching the multi-syllabus pattern. Alternatively, use an `Autocomplete<String>` that filters as the user types while restricting selections to existing subjects.

2. **Handle the empty-subjects case:** When `_allSubjects` is empty, show a message card (e.g., "No subjects found. Create a subject first to build a study plan.") with an `ElevatedButton` that navigates to the Subject Creation screen (`AppRoutes.subjectSelection` or `AppRoutes.subjectDetail`). Disable the "Generate Plan" button until at least one subject exists.

3. **Optionally, unify the two modes** into a single consistent experience: always show a subject selector (dropdown/autocomplete), and allow adding multiple subjects from the same selector. The toggle between single/multi modes becomes unnecessary if the selector itself supports multiple selections.

4. **Clean up the `_courseController`** and related validation logic (lines 153–190) that exist solely to work around the free-text input.
