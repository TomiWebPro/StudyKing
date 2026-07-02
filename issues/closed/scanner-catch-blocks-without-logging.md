# [Scanner] Catch blocks returning `Result.failure` without logging

**Source:** automatic scanner
**Severity:** major

## Finding

The project convention (AGENTS.md) states: "Empty `catch (_) {}` blocks are forbidden. Every catch must log the error with a descriptive message."

While no literally empty catch blocks exist, multiple catch blocks silently return `Result.failure(e.toString())` **without calling any logger method** (`.e()`, `.w()`, etc.). This makes debugging difficult because failures are silently swallowed with no log trace.

## Locations

### `lib/core/data/repository.dart`
- **Line 59-61** — `put()` method: `catch (e) { return Result.failure('Failed to put: $e'); }` — no `_logger` call
- **Line 68-70** — `get()` method: `catch (e) { return Result.failure('Failed to get: $e'); }` — no `_logger` call
- **Line 77-79** — `getAll()` method: `catch (e) { return Result.failure('Failed to get all: $e'); }` — no `_logger` call
- **Line 86-88** — `delete()` method: `catch (e) { return Result.failure('Failed to delete: $e'); }` — no `_logger` call

### `lib/core/data/repositories/attempt_repository.dart`
- **Line 65-67** — `getSubjectStats()`: `catch (e) { return Result.failure(e.toString()); }` — no `_logger` call

### `lib/core/data/repositories/engagement_nudge_repository.dart`
- **Line 35-37** — `getRecentByStudent()`: `catch (e) { return Result.failure(e.toString()); }` — no `_logger` call

### `lib/core/services/plan_adherence_orchestrator.dart`
- **Line 114-116** — `checkAdherence()`: `catch (e) { return Result.failure(e.toString()); }` — no `_logger` call
- **Line 143-145** — `suggestRegeneration()`: `catch (e) { return Result.failure(e.toString()); }` — no `_logger` call
- **Line 174-176** — `getAdherenceReport()`: `catch (e) { return Result.failure(e.toString()); }` — no `_logger` call

### `lib/features/planner/services/syllabus_resolver.dart`
- **Line 110-114** — `resolveSyllabus()`: `catch (e) { return Result.failure(...); }` — no `_logger` call
- **Line 129-133** — `getQuestionsForTopic()`: `catch (e) { return Result.failure(...); }` — no `_logger` call
- **Line 151-155** — `getQuestionsForTopics()`: `catch (e) { return Result.failure(...); }` — no `_logger` call

## Recommendation

Add a `_logger.w(e, st)` or `_logger.e(e, st)` call before each `return Result.failure(...)` in the affected catch blocks. For expected/anticipated error paths (e.g., Hive box not open), use `.w()`. For unexpected failures, use `.e()`. This ensures all failure paths are traceable in logs.
