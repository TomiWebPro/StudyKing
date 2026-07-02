# [Scanner] Widespread duplicated test setup code across large test files

**Source:** automatic scanner
**Severity:** medium

## Finding

Several test files contain extensively duplicated setup code where the same service/test fixture construction is copy-pasted across multiple `group()` blocks. This makes maintenance harder and increases the risk of inconsistencies (e.g., one group using different parameters than another).

## Locations

### `test/features/planner/services/planner_service_test.dart` (1863 lines)

`PlannerService(...)` constructor is called with the same 10+ parameters across dozens of test groups:
- `masteryService: MasteryGraphService()` — repeated 24+ times
- `tutorService: MockTutorService()` — repeated across groups
- Same `topicRepo`, `sessionRepo`, `attemptRepo` creation pattern

Each group creates its own fresh service instance with identical parameters but the code is copy-pasted rather than shared.

### `test/features/planner/providers/planner_providers_test.dart` (1558 lines)

Same `PlannerService(...)` construction with real `MasteryGraphService()` repeated 6+ times.
The `ProviderContainer` with overrides is also duplicated across test groups.

### `test/features/planner/presentation/planner_screen_test.dart` (2037 lines)

While `_buildTestApp` helper exists, many test groups still create their own custom setup with duplicated `ProviderScope` overrides and mock data seeding.

### `test/core/services/notification_service_test.dart` (130 lines)

`NotificationService()` is instantiated fresh in every single test (13 times) instead of using `setUp` with a shared instance.

### `test/features/teaching/presentation/tutor_screen_test.dart` (448 lines)

`_FakeTutorService` (lines 84–106) and `_FailingTutorService` (lines 125–147) are nearly identical classes differing only in `startLesson` behavior. Could be a single parameterized fake.

## Impact

- **Maintenance burden**: Changing a constructor parameter requires updating it in every copy-pasted location
- **Inconsistency risk**: Some groups may accidentally use different fakes or parameters, causing inconsistent test behavior
- **Noise in diffs**: PRs that add new test groups produce large diffs from duplicated boilerplate
- **Harder to review**: Reviewers must check every copy-pasted block to ensure correctness

## Recommendation

- Extract shared setup into:
  - A `createPlannerService()` factory function with sensible defaults and named parameters for overrides
  - A `setUpPlannerService()` extension on `group` or a mixin that handles common setup
- For provider tests, create a `withProviderOverrides` helper that sets up common override chains
- In `notification_service_test.dart`, move `NotificationService` creation into `setUp`
- Make `_FakeTutorService` and `_FailingTutorService` into a single parameterized fake class
- Consider creating `test/helpers/` directory for shared test utilities
