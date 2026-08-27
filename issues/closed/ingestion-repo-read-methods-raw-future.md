# Ingestion repository public read methods return raw `Future` instead of `Result`

## Description
AGENTS.md requires public repository and service methods to return `Result<T>`. Several public read methods in `lib/features/ingestion/data/repositories/source_repository.dart` perform Hive I/O (`_ensureReady()`, `box.values`) and can throw, yet return a raw `Future<List<Source>>`:

- `getBySubject(String subjectId)` (line 22)
- `getByTopic(String topicId)` (line 27)
- `getByStudent(String studentId)` (line 32)
- `getByType(String sourceType)` (line 37)
- `getByStatus(ProcessingStatus status)` (line 42)
- `getPending()` (line ~47, delegates to `getByStatus`)

Returning a raw `Future` forces every caller to wrap in `try/catch` and bypasses the app's uniform `Result` error-handling convention. The companion write methods (`create`, `update`, `delete`) already return `Result`, so the read methods are inconsistent.

## Affected files/areas
- lib/features/ingestion/data/repositories/source_repository.dart:22,27,32,37,42,~47
- Callers of these methods (update to handle `Result`)

## Expected vs Actual
- Expected: each read method returns `Future<Result<List<Source>>>`; on success `Result.success(list)`, on failure `Result.failure(e.toString())` after logging via a `Logger`.
- Actual: methods return raw `Future<List<Source>>` and may throw, breaking the `Result` convention and caller consistency.

## Acceptance Criteria
- [ ] All listed `SourceRepository` read methods return `Future<Result<List<Source>>>`.
- [ ] Each catch logs via a `static final Logger` before returning `Result.failure`.
- [ ] All call sites are updated to handle the `Result` (using `.data`/`.isFailure`), and the app still builds.
- [ ] `flutter analyze` and the source_repository tests pass.
