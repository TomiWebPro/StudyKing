# Add behavioral tests for dashboard service and providers

## Description
The dashboard is the student's home screen and aggregates progress intelligence. Per
AGENTS.md, services and providers must have `test/features/*/services/*_test.dart` and
`test/features/*/providers/*_test.dart` with behavioral assertions, but the following
have no coverage:

- `lib/features/dashboard/services/dashboard_service.dart` — aggregates mastery,
  weak areas, adherence, badges, and activity into dashboard models.
- `lib/features/dashboard/providers/dashboard_providers.dart` and
  `lib/features/dashboard/providers/dashboard_data_providers.dart` — Riverpod
  providers exposing the aggregated data.

Untested aggregation logic can surface wrong progress/weak-area data to users with no
CI signal.

## Affected files/areas
- lib/features/dashboard/services/dashboard_service.dart
- lib/features/dashboard/providers/dashboard_providers.dart
- lib/features/dashboard/providers/dashboard_data_providers.dart

## Expected vs Actual
- Expected: A `test/features/dashboard/services/dashboard_service_test.dart` asserting
  that aggregation produces correct weak-area ordering / adherence values from
  hand-written fakes, plus `test/features/dashboard/providers/*_test.dart` verifying
  provider wiring (singleton or override behavior) with `ProviderScope` overrides.
- Actual: No test files exist for the dashboard service or providers.

## Acceptance Criteria
- [ ] `test/features/dashboard/services/dashboard_service_test.dart` exists with
      behavioral assertions on aggregated output.
- [ ] `test/features/dashboard/providers/dashboard_providers_test.dart` (and
      `dashboard_data_providers_test.dart`) exist with at least one behavioral
      assertion verifying dependency wiring via overrides.
- [ ] `flutter test test/features/dashboard` passes and `flutter analyze` is clean.
