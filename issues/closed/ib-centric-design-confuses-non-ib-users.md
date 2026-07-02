# Excessive IB-centric design alienates non-IB users

**Severity:** minor
**Affected area:** Subject creation, planner, roadmap, onboarding hints
**Reported by:** user

## Description

The app is heavily biased toward the International Baccalaureate (IB) curriculum system. Every user-facing hint/placeholder example references IB ("e.g., IB Physics", "e.g., IB-PHYS", "e.g., I want to learn IB Physics in 180 days"). The autocomplete list is dominated by 19 IB entries. The seed curriculum data has 4 IB curricula vs only 3 non-IB curricula. However, many users have no idea what IB is — they study under A-Levels, AP, GCSE, national curricula, or entirely custom/self-directed programs. The app provides no explanation of what IB is, no curriculum type selector, and no way to opt out of the IB-centric framing.

## Steps to reproduce

1. Open the app fresh (no subjects created yet).
2. Tap "Add Subject" to create a new subject.
3. Observe the subject name hint: "e.g., IB Physics".
4. Look at the subject code hint: "e.g., IB-PHYS".
5. Tap the Syllabus/Scope field — 93 suggestions pop up, with IB entries listed first.
6. Open the Study Planner or Roadmap feature and see the goal hint: "e.g., I want to learn IB Physics in 180 days".

## Expected behavior

The app should be curriculum-agnostic or allow the user to select their curriculum system upfront. Hints and examples should either use a neutral example (e.g., "e.g., Biology 101") or adapt to the user's selected curriculum. IB should not be treated as the default/only curriculum.

## Actual behavior

IB is the implicit default everywhere:
- 4 of 7 seed curricula are IB
- 19 of ~93 autocomplete syllabus suggestions are IB (listed first)
- All hint/placeholder strings use IB examples
- The product vision doc (`agent_must_read.md`) uses IB as the sole example
- No onboarding or explanation of what IB is
- No curriculum type field on the Subject model

## Code analysis

### Localization strings (all hint examples reference IB)
- `lib/l10n/app_en.arb:31` — `"courseHint": "e.g., IB Physics"`
- `lib/l10n/app_en.arb:885` — `"subjectCodeHint": "e.g., IB-PHYS"`
- `lib/l10n/app_en.arb:3313` — `"roadmapGoalHint": "e.g., I want to learn IB Physics in 180 days"`
- `lib/l10n/app_es.arb:31` — `"courseHint": "p. ej., Física IB"`
- `lib/l10n/app_es.arb:885` — `"subjectCodeHint": "p. ej., IB-FIS"`
- `lib/l10n/app_es.arb:3313` — `"roadmapGoalHint": "p. ej., Quiero aprender Física IB en 180 días"`

### Autocomplete suggestions dominated by IB
- `lib/features/subjects/presentation/subject_form_widgets.dart:6-25` — 19 IB entries listed first in `_commonSyllabi`

### Seed curriculum data is IB-heavy
- `lib/features/subjects/data/curriculum_seed_data.dart:31-400` — 4 IB curricula (IB Chemistry, IB Biology, IB Physics, IB Math AA)
- `lib/features/subjects/data/curriculum_seed_data.dart:401-535` — only 3 non-IB curricula (A-Level Chemistry, A-Level Biology, AP Chemistry)

### Vision doc uses IB example
- `agent_must_read.md:76` — `"I want to learn IB Physics in 180 days."`

### Subject model has no curriculum type
- `lib/core/data/models/subject_model.dart` — No `curriculumType` field, no enum, no structured differentiation

## Suggested approach

1. **Make hint examples curriculum-agnostic** — Change all hint strings in ARB files to use neutral examples (e.g., "e.g., Organic Chemistry", "e.g., BIO-101", "e.g., I want to learn Python in 90 days"). This is the simplest fix with highest impact.

2. **Add a `curriculumType` field to the Subject model** — Create an enum with values like `ib`, `aLevel`, `ap`, `gcse`, `custom`, `other`. Add it to the subject creation form as a dropdown/selector before the name field.

3. **Reorder autocomplete suggestions** — Group curriculum types and allow the user to filter by type after selecting their curriculum. Don't show all 93 entries mixed together.

4. **Expand seed data evenly** — Either add more non-IB seed curricula (AP, A-Level, GCSE for more subjects) or make the seed data pluggable/modular.

5. **Update the vision doc example** — Change to a neutral example or use a comment noting it's just an illustration.
