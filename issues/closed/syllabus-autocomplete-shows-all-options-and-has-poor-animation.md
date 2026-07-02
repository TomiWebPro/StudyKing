# Syllabus/Scope Autocomplete shows all 93 options at once with awkward overlay behavior

**Severity:** minor
**Affected area:** Add Subject / Edit Subject screen — Syllabus/Scope field
**Reported by:** user

## Description

The Syllabus/Scope field uses Flutter's `Autocomplete<String>` widget, but when the user taps the field, **all 93 predefined syllabus options are displayed at once** in an overlay. This is overwhelming and visually jarring. Additionally, the overlay animation appears awkward — described by the user as "pops down strange af" — because:

1. The default `Autocomplete` overlay uses a basic fade transition with no custom positioning logic.
2. The overlay's position may be miscalculated when the text field is near the bottom of the scrollable area, causing it to appear in unexpected places.
3. No `optionsViewBuilder` is provided, so the options list uses default Material styling (simple raw list, no elevation/padding customization).

## Steps to reproduce

1. Open the app and tap "Add Subject".
2. Scroll down to the "Syllabus/Scope (Optional)" field.
3. Tap the field (leave it empty).
4. Observe that all 93 syllabus suggestions pop up at once in an overlay.
5. Observe the animation — the overlay appears abruptly or at an odd position.

## Expected behavior

- When the field is empty and tapped, either show nothing, show a small subset of popular suggestions, or show a brief helper message.
- The overlay animation should be smooth and properly positioned relative to the text field.
- A custom `optionsViewBuilder` should provide consistent styling (rounded corners, proper elevation, max height constraint).

## Actual behavior

- `if (value.text.isEmpty) return _commonSyllabi;` — all 93 items returned on empty input.
- Default `Autocomplete` overlay with no custom builder.
- Overlay may appear at incorrect position (especially on smaller screens or when scrolled down).
- User typed text in the field is NOT synced to `syllabusController` until a suggestion is explicitly selected (line 252 `onSelected`), meaning free-text input is silently lost.

## Code analysis

### Root cause — all 93 items shown on focus
- `lib/features/subjects/presentation/subject_form_widgets.dart:248` — `if (value.text.isEmpty) return _commonSyllabi;`
  This returns all 93 syllabus entries when the Autocomplete field is tapped with no text. Compare with the subject name Autocomplete (line 201) which returns `[]` for empty input — the inconsistency shows the syllabus Autocomplete was intentionally set to show everything, but this creates a bad UX.

### No custom optionsViewBuilder
- `lib/features/subjects/presentation/subject_form_widgets.dart:246-265` — No `optionsViewBuilder` parameter is provided. Flutter's default `Autocomplete` overlay uses a simple Material list with default animation/positioning, which is not optimized for 93 items.

### syllabusController only updated on selection, not on typing
- `lib/features/subjects/presentation/subject_form_widgets.dart:252` — `onSelected: (selection) => syllabusController.text = selection`
  If the user types free text instead of picking a suggestion, `syllabusController` stays empty, and the typed syllabus is lost on save.

## Suggested approach

1. **Change empty-field behavior** — Replace `return _commonSyllabi` with `return []` (like the name field) or return a short curated list (e.g., top 5 popular entries). The full list is still accessible by typing.

2. **Add a custom `optionsViewBuilder`** — Provide an `AutocompleteOptionsBuilder` that renders a constrained-height list (max 200-300px) with rounded corners, proper elevation, and scroll physics. This also allows customizing the entrance animation.

3. **Sync free-text input to syllabusController** — Add a listener to the `fieldViewBuilder`'s text controller that updates `syllabusController` on every change, so typed (non-selected) text is not lost.

4. **Consider replacing Autocomplete with a dropdown** — For the syllabus field, a `DropdownButton` or `DropdownMenu` (Material 3) may be more appropriate since the list is finite and predefined. Or keep Autocomplete but with a proper UX design.
