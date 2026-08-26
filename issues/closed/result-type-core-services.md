# Public core service methods return raw types instead of Result<T>

## Description
AGENTS.md mandates that **public repository and service method return types must be `Result<T>`**, and `throw` is only allowed in private helpers or startup config validation. A sweep of `lib/core/services` found public methods that read/write secure storage, Hive boxes, or platform channels yet return raw `Future<T>` / plain types. Some internally `try` and return empty/throw on failure, which bypasses the typed-error contract used elsewhere (`Result.capture` wrappers).

This complements the feature-layer sweep in `result-type-feature-services.md` and is distinct from the already-closed `scanner-public-methods-return-raw-types.md` sweep.

## Affected files/areas
- lib/core/services/secure_api_key_service.dart:31 — `Future<String> getApiKey()` (secure storage read; can fail / returns `''` on error)
- lib/core/services/long_term_memory.dart:27 — `String? recallFact(String, String)` (storage read)
- lib/core/services/conversation_memory.dart:53 — `Future<void> addMessage(...)` (DB write)
- lib/core/services/voice_service.dart:123 — `Future<void> startListening(...)` (platform I/O)
- lib/core/services/notification_service.dart:21 — `Future<void> init(...)` (platform I/O)
- lib/core/services/student_id_service.dart:20 — `String getStudentId()` (storage read; throws if uninitialized)

## Expected vs Actual
- Expected: every public core service method that can fail returns `Result<T>` so callers handle failures via the `Result` API rather than `try/catch` or silent empty returns.
- Actual: the methods above return raw `Future<T>` / plain types and either swallow failures or throw, inconsistent with the codebase's `Result`-based error handling.

## Acceptance Criteria
- [ ] Each listed method's return type is changed to `Result<T>` (e.g. `Future<Result<String>>`, `Result<String?>`).
- [ ] Each method wraps its I/O work in `Result.capture(() async { ... })` or returns explicit `Result.failure(...)` on known error paths; `getStudentId()` either returns `Result<String>` or is explicitly documented/relocated as a startup config-validation exception.
- [ ] No `throw` remains in these public methods.
- [ ] All call sites are updated to handle the `Result`, and existing tests still pass.
- [ ] `flutter analyze` reports no new warnings/errors.
