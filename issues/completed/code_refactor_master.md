# Refactor subjects feature to remove duplicated creation flows and unify data access

## Context

The `subjects` feature currently has two separate subject-creation screens with overlapping responsibilities and diverging behavior, while data access is split between direct global database calls and a Riverpod provider.

- `SubjectManagementScreen` and `SubjectSelectionScreen` both create `Subject` entities, each with its own field set, color options, validation, and save flow.
- `SubjectManagementScreen` appears to be unused in navigation but is exported publicly, making it effectively dead/legacy code that still increases maintenance overhead.
- `SubjectListView` bypasses Riverpod and reads `database.subjectRepository` directly from `main.dart`, while other flows (for example practice) use `subjectsRepositoryProvider`.
- Comments such as "In production" and "don’t have full Riverpod setup yet" indicate temporary architecture that has persisted into feature code.

This creates a high-risk maintainability hotspot: every domain change to `Subject` must be repeated in multiple UIs and data paths, which invites drift and inconsistent behavior.

## Affected files

- `lib/features/subjects/presentation/subject_management_screen.dart`
- `lib/features/subjects/presentation/subject_selection_screen.dart`
- `lib/features/subjects/presentation/subject_list_view.dart`
- `lib/features/subjects/providers/subjects_repository_provider.dart`
- `lib/features/subjects/subject_feature.dart`
- `lib/features/practice/presentation/practice_screen.dart`

## Rationale

Refactoring this area will improve readability and structure by establishing one source of truth for subject creation and one consistent repository access pattern. It will also reduce dead code and remove outdated/inappropriate comments that no longer reflect the current architecture.

## Acceptance criteria

1. There is exactly one canonical subject-creation UI flow in the `subjects` feature (either merge or remove one screen), and all navigation points use that same flow.
2. Subject persistence for the feature is accessed through a single architectural path (provider-based or explicitly chosen alternative), with no direct `main.dart` global database import from `subjects` presentation widgets.
3. Any dead or legacy subject creation screen/code path is removed from exports and navigation references.
4. Reusable subject form concerns (validation, color options, input normalization) are centralized to avoid duplicated widget/business logic across screens.
5. Outdated transitional comments about architecture state are removed or replaced with accurate, durable documentation.
6. Existing behavior remains intact for creating, listing, and selecting subjects (no regression in user-visible flows).
