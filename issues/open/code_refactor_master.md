# Codebase Architectural Decay: Inconsistent Result Types, Dead Code, Duplicate Barrels, and Repository Anti-patterns

## Context

The codebase shows signs of architectural drift where multiple contributors introduced overlapping, inconsistent, or dead patterns over time. Several issues degrade maintainability, type safety, and onboarding clarity.

---

## Issue 1: Three Incompatible `Result<T>` Types

Three separate `Result<T>` classes exist with incompatible APIs:

| File | Definition | API |
|---|---|---|
| `lib/core/errors/handlers.dart:292` | `class Result<T>` | `const Result.success(this.data)` / `const Result.failure(this.error)` |
| `lib/core/data/repositories/mastery_graph_repository.dart:8` | `class Result<T>` | `Result.success()` / `Result.failure()` named constructors |
| `lib/core/data/repositories/question_repository.dart:8` | `sealed class Result<T>` | `SuccessResult<T>` / `FailureResult<T>` subclasses |

These are **type-incompatible** — a `Result` from one file cannot be used with code expecting another. This is a latent compilation/shared-code hazard.

### Affected
- `lib/core/errors/handlers.dart`
- `lib/core/data/repositories/mastery_graph_repository.dart`
- `lib/core/data/repositories/question_repository.dart`

### Rationale
Three incompatible monads for the same abstraction will cause confusion and blocks shared error-handling infrastructure. A single `Result` type should be defined in `lib/core/errors/` and used consistently across all repositories.

---

## Issue 2: `core/core.dart` and `core/common.dart` Are Identical

Both barrels export the **exact same 20 re-exports** and define the **same `IterableExtension`** inline extension. One is 100% redundant.

### Affected
- `lib/core/core.dart` (36 lines)
- `lib/core/common.dart` (36 lines)

### Rationale
Duplicate barrels are a trap — developers will import one vs the other arbitrarily, and any divergence in the future will cause hidden import inconsistencies. Remove one and update imports across the codebase.

---

## Issue 3: `DatabaseService` Is a Useless Shell

`lib/core/data/database_service.dart` (19 lines) has:
- 6 constructor parameters stored as public fields
- **Zero methods, zero logic, zero orchestration**

It does not init repositories, handle errors, or provide any lifecycle. It is a pure pass-through. `main.dart` must still call `init()` on each repository individually:

```dart
final database = DatabaseService(...);
await database.topicRepository.init();
await database.questionRepository.init();
// ... 4 more manual inits
```

### Affected
- `lib/core/data/database_service.dart`
- `lib/main.dart` (lines 20–27, 191–199)

### Rationale
The service provides no abstraction benefit. Either give it an `init()` that cascades to all child repositories, or remove it and declare independent top-level repository variables.

---

## Issue 4: `app_runtime_config.dart` Is a 269-Line Dumping Ground

This file contains **9 unrelated classes** — several of which are completely dead code (constants defined but never used anywhere):

| Class | External Usage | Verdict |
|---|---|---|
| `StudyConfig` | **None** — all 7 fields unused | Dead code |
| `PdfConfig` | **None** — all 3+ fields and 3 methods unused | Dead code |
| `ErrorKeys` | **None** — all 3 strings unused | Dead code |
| `MediaConfig` | **None** — both members unused | Dead code |
| `UiConfig` | Only `defaultThemeMode` used (in `runtimeSnapshot()`) | Mostly dead |
| `CacheConfig` | Only `cacheExpiration` used (in `runtimeSnapshot()`) | Mostly dead |
| `SecurityConfig` | Heavily used | Keep |
| `AppConfig` | Heavily used | Keep |
| `AppConstants` | Used in `main.dart` | Keep |

### Affected
- `lib/core/constants/app_runtime_config.dart`

### Rationale
269 lines with 4 dead classes and 2 mostly-dead classes creates unnecessary cognitive load. Split into separate files by concern and remove dead classes.

---

## Issue 5: Cross-Layer Dependency from `core/data/data.dart` to `features/`

`lib/core/data/data.dart` line 21:
```dart
export '../../features/subjects/data/repositories/subject_repository.dart';
```

This creates a **layering violation**: `core/` depends on `features/`, which is the wrong direction in a clean architecture.

### Affected
- `lib/core/data/data.dart:21`

### Rationale
Core should be independent of feature modules. The `SubjectRepository` export belongs in `subjects/subject_feature.dart` (which already exports it). Remove this export from `data.dart` and fix any imports that break.

---

## Issue 6: Inconsistent Repository Initialization Patterns

| Repository | init() pattern | Return type | Hive access |
|---|---|---|---|
| TopicRepository | `_box = Hive.box<Topic>('topics')` | `Future<void>` | Assumes box open |
| QuestionRepository | `_box = await Hive.openBox<Question>('questions')` | `Future<Result<void>>` | Opens itself |
| MasteryGraphRepository | `await Hive.openBox<...>(...)` | `Future<Result<void>>` | Opens itself |
| SpacedRepetitionRepository | `await Hive.openBox<...>(...)` | `Future<Result<void>>` | Opens itself |
| SubjectRepository | nullable `Box<Subject>?` + lazy getter | `Future<void>` | Assumes box open |

Three different init patterns with two different return types. The `Result<void>` return in three repos is **never inspected** by `main.dart` (which calls init and ignores the return value).

### Affected
- `lib/core/data/repositories/topic_repository.dart`
- `lib/core/data/repositories/question_repository.dart`
- `lib/core/data/repositories/mastery_graph_repository.dart`
- `lib/core/data/repositories/spaced_repetition_repository.dart`
- `lib/core/data/repositories/subject_repository.dart` (uses nullable + getter — unique)
- `lib/main.dart` (ignores Result returns)

### Rationale
Inconsistency forces every developer to read each file to understand its contract. Standardize on one pattern: either all use `Future<void>` and throw on error, or all use a shared `Result<T>` and gracefully handle initialization errors.

---

## Issue 7: Dead Code — Empty Files, Duplicate Repository, Silent Catch

| Item | File | Severity |
|---|---|---|
| Empty barrel stub | `lib/features/lessons/services/services.dart` | Low |
| Empty barrel stub | `lib/features/planner/services/services.dart` | Low |
| Empty barrel stub | `lib/features/sessions/services/services.dart` | Low |
| Empty repository file | `lib/core/data/repositories/hive_repository.dart` (0 lines) | Low |
| Silent catch (no log, no feedback) | `lib/features/practice/presentation/practice_screen.dart:631-633` | Medium |
| Duplicate `SessionRepository` (unused) | `lib/core/data/repositories/session_repository.dart` (exists alongside `study_session_repository.dart`) | Medium |
| `_logError` uses `bool.hasEnvironment('flutter.debug')` — **always false** | `lib/core/errors/handlers.dart:217` | High |

The `_logError` bug means `AppErrorHandler` silently discards all errors in debug mode — the one environment where detailed logging is most valuable.

### Affected
Multiple files listed above.

### Rationale
Dead code increases maintenance surface. The `_logError` bug is a correctness issue that should be fixed immediately.

---

## Acceptance Criteria

1. **Single `Result<T>`**: Consolidate the three incompatible `Result<T>` types into one, defined in `lib/core/errors/`. Migrate all repositories to use it consistently.
2. **Remove duplicate barrel**: Delete `lib/core/common.dart` and update all imports to use `core.dart`, or differentiate the two and document the distinction.
3. **Fix or remove `DatabaseService`**: Either add cascade `init()`, error handling, and lifecycle, or remove it and inline repository declarations.
4. **Clean up `app_runtime_config.dart`**: Extract `SecurityConfig`, `AppConfig`, and `AppConstants` into their own files. Remove dead classes (`StudyConfig`, `PdfConfig`, `ErrorKeys`, `MediaConfig`).
5. **Fix layering violation**: Remove `export '../../features/subjects/...'` from `lib/core/data/data.dart`.
6. **Standardize repository init**: All repositories under `lib/core/data/repositories/` must use the same `init()` signature and box-accessing strategy. Remove or use the `Result` return values.
7. **Remove dead code**: Delete empty files, `hive_repository.dart`, and `session_repository.dart` (confirms unused). Add error logging to the silent `catch` block.
8. **Fix `_logError`**: Replace `const bool.hasEnvironment('flutter.debug')` with `kDebugMode` from `package:flutter/foundation.dart`.
