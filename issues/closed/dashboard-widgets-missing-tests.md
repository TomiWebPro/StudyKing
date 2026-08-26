# Add widget tests for dashboard syllabus widgets

## Description
Per AGENTS.md test-placement table, files under `lib/features/*/presentation/widgets/*.dart` must have a corresponding `test/features/*/presentation/widgets/*_test.dart` with behavioral assertions. The dashboard feature already has tests for `dashboard_service`, `dashboard_providers`, `dashboard_data_providers`, `dashboard_screen`, and `due_reviews_card`, but two presentation widgets had no test file:

- `lib/features/dashboard/presentation/widgets/syllabus_breakdown_card.dart`
- `lib/features/dashboard/presentation/widgets/syllabus_switcher.dart`

The open `dashboard-service-providers-missing-tests.md` issue covers only service/providers, not these widgets, so this gap was unaddressed. Untested dashboard widgets can render incorrect syllabus progress/selection UI with no CI signal.

## Affected files/areas
- lib/features/dashboard/presentation/widgets/syllabus_breakdown_card.dart
- lib/features/dashboard/presentation/widgets/syllabus_switcher.dart

## Expected vs Actual
- Expected: `test/features/dashboard/presentation/widgets/syllabus_breakdown_card_test.dart` and `syllabus_switcher_test.dart` exist, using `ProviderScope` with overrides (fake repos / fixedStudentId) and asserting rendered state (e.g. breakdown sections render for given syllabi, switcher reflects selection).
- Actual: tests are missing entirely.

## Acceptance Criteria
- [x] `test/features/dashboard/presentation/widgets/syllabus_breakdown_card_test.dart` exists with at least one behavioral widget assertion.
- [x] `test/features/dashboard/presentation/widgets/syllabus_switcher_test.dart` exists with at least one behavioral widget assertion.
- [x] Tests use hand-written fakes (no mockito/mocktail) and `fixedStudentId` to avoid Hive I/O.
- [x] `flutter test test/features/dashboard/presentation/widgets` passes and `flutter analyze` is clean.
