# BadgeRepository public methods return raw types instead of Result<T>

## Description
`lib/features/dashboard/data/repositories/badge_repository.dart` is a `Repository<BadgeModel>` subclass whose public read methods return raw domain types instead of `Result<T>`, violating AGENTS.md ("Public repository and service method return types must be Result<T>"). Affected methods:

- `:16` `Future<List<BadgeModel>> getByStudent(String studentId)`
- `:22` `Future<bool> hasBadge(String studentId, String badgeId)`
- `:27` `Future<Map<String, BadgeModel>> getBadgeMap(String studentId)`
- `:32` `Future<int> getBadgeCount(String studentId)`

These are Hive-backed reads that can fail (box not open, deserialization error). Returning raw types forces callers to catch exceptions ad hoc and prevents uniform error handling via the `Result` pattern used elsewhere (e.g. `attempt_repository`, `session_repository` in `lib/core/data/repositories/`).

## Affected files/areas
- lib/features/dashboard/data/repositories/badge_repository.dart:16,22,27,32

## Expected vs Actual
- Expected: the four methods return `Future<Result<List<BadgeModel>>>`, `Future<Result<bool>>`, `Future<Result<Map<String, BadgeModel>>>`, and `Future<Result<int>>` respectively, wrapping failures in `Result.failure`.
- Actual: they return raw futures that throw on failure, breaking the repository `Result<T>` convention and forcing inconsistent caller error handling.

## Acceptance Criteria
- [ ] All four listed methods return `Result<T>` and wrap failures via `Result.failure` (with logged, descriptive errors).
- [ ] Call sites are updated to read `.data`/handle `Result`, and tests (hand-written fakes, no mockito) are added under `test/features/dashboard/data/repositories/`.
- [ ] `flutter analyze` still passes.
