# Improvement Report: `lib/core/constants`

Date: 2026-05-11
Scope: `/home/tomi/StudyKing/lib/core/constants`

## Findings

| ID | File | Line | Severity | Description | Suggested fix |
|---|---|---:|---|---|---|
| CONST-001 | `lib/core/constants/app_runtime_config.dart` | 41 | Medium | `adaptiveChunkSize` can return `4 * 1024`, which is inconsistent with `minChunkSizeBytes = 1024` and `defaultChunkSizeBytes = 10 * 1024`, and it is not clamped to the declared min/max bounds. Future threshold edits could accidentally return out-of-range values. | Return `validatedChunkSize(...)` from `adaptiveChunkSize` (or clamp at the end) so all branches always respect configured bounds. |
| CONST-002 | `lib/core/constants/app_runtime_config.dart` | 52 | Medium | `validatedChunkOverlap` accepts `chunkSize` without validating it first. If callers pass a value smaller than `minChunkSizeBytes` (or negative), resulting overlap behavior is surprising and silently masked by double-clamp. | Validate `chunkSize` via `validatedChunkSize` first; optionally assert/throw on non-positive `chunkSize` for fail-fast behavior. |
| CONST-003 | `lib/core/constants/app_runtime_config.dart` | 54 | Low | `bounded.clamp(...)` returns `num` in Dart; implicit return typing relies on inference and may become brittle with stricter lints. Same issue appears in other `clamp` helpers. | Cast explicitly: `(bounded.clamp(min, max) as int)` or compute with `math.min/math.max` to preserve `int` type clearly. |
| CONST-004 | `lib/core/constants/app_runtime_config.dart` | 123 | Low | `validatedImageCompressionQuality` has the same `clamp` typing ambiguity (`num` vs `int`). | Return `(quality.clamp(0, 100) as int)` (or equivalent min/max math) to keep type explicit and lint-clean. |
| CONST-005 | `lib/core/constants/app_runtime_config.dart` | 106 | Medium | `enforceStartupGuards` is only triggered through `AppConfig.bootstrap`. Code paths that directly instantiate `ApiSecrets.fromEnvironment()` or use constants elsewhere may bypass startup guard checks. | Move critical checks to app startup entrypoint and/or make guarded APIs private/internal so all consumers go through one validated bootstrap path. |
| CONST-006 | `lib/core/constants/app_runtime_config.dart` | 88 | Medium | `encryptionKeyOrThrow` only checks empty/default-like strings; weak but non-default keys (e.g., very short values) still pass in production. | Add minimum entropy policy (e.g., length + charset requirements), or require platform-keystore generated key material with format validation. |
| CONST-007 | `lib/core/constants/app_runtime_config.dart` | 95 | Low | Placeholder key checks use a small hardcoded denylist and simple `toLowerCase()`. Common variants (spaces, underscores, prefixed defaults) can bypass detection. | Normalize input (`trim`, collapse punctuation) and expand denylist/regex checks for likely placeholder patterns. |
| CONST-008 | `lib/core/constants/app_runtime_config.dart` | 181 | Medium | `AppConstants.instance` lazily creates global singleton with hardcoded `featureOverrides: const {}` and no reset/injection path, which hurts testability and environment-specific override flows. | Add explicit initializer/reset for tests and optional injection path; consider dependency injection over static global singleton. |
| CONST-009 | `lib/core/constants/app_runtime_config.dart` | 167 | Low | `debugLogSnapshot` logs runtime snapshot in debug mode. Snapshot currently excludes secrets, but future additions risk accidental exposure. | Add defensive redaction utility and a comment/test ensuring sensitive fields can never enter `runtimeSnapshot`. |
| CONST-010 | `lib/core/constants/app_features.dart` | 4 | Medium | `FeatureFlagService` stores caller-provided map by reference. External mutation after construction changes flag behavior unexpectedly. | Copy defensively in constructor (e.g., `Map.unmodifiable({...?overrides})`) to guarantee immutability. |
| CONST-011 | `lib/core/constants/app_features.dart` | 8 | Low | `_defaults` is mutable at runtime if accessed internally; while private, it is still a normal map object. | Make defaults unmodifiable (`const` map is already compile-time const, but enforce usage via unmodifiable copy if ever refactored to non-const sources). |
| CONST-012 | `lib/core/constants/app_features.dart` | 15 | Low | `?? false` fallback is redundant because `_defaults` covers all enum members today; redundancy can hide missing-default mistakes when enum grows. | Replace with stricter behavior: assert `_defaults.containsKey(feature)` in debug/test, then return required value; or use exhaustive `switch` on enum. |
| CONST-013 | `lib/core/constants/app_storage_config.dart` | 13 | Medium | Path getters return joined paths but do not ensure directories exist. Callers may fail later with file-system errors depending on usage timing. | Add methods that create directories (`Directory(path).create(recursive: true)`) or clearly document that callers must create paths before writing. |
| CONST-014 | `lib/core/constants/app_storage_config.dart` | 11 | Low | `studyMaterialsDirectoryName = 'StudyKing'` uses title-cased app name as on-disk folder. This can be fragile for app rename/multi-flavor scenarios and inconsistent with lowercase identifiers elsewhere. | Use stable, flavor-aware identifier (e.g., `studyking` or package-name-based path segment). |
| CONST-015 | `lib/core/constants/app_api_config.dart` | 15 | Medium | API keys are sourced from compile-time `String.fromEnvironment`, which can embed secrets into app binaries and makes rotation harder. | Prefer runtime secure secret provisioning (platform keystore, remote config bootstrap with secure channel, or native layer injection). |
| CONST-016 | `lib/core/constants/app_api_config.dart` | 44 | Low | `ApiConfig.forEnvironment` duplicates identical base URLs across all environments; repetition increases maintenance risk and obscures what actually differs (timeouts only). | Extract shared constants and vary only environment-specific deltas to improve readability and reduce drift. |
| CONST-017 | `lib/core/constants/app_api_config.dart` | 49 | Low | Production timeout of 120s for OpenRouter is high for mobile UX; prolonged waits can degrade responsiveness and battery/network usage. | Revisit timeout policy (e.g., shorter request timeout with retry/backoff and user-facing cancellation). |
| CONST-018 | `lib/core/constants/app_build_config.dart` | 17 | Medium | Unknown `APP_ENV` values silently fall back to `development`, which can mask deployment misconfiguration and disable production safeguards unexpectedly. | Fail fast on unknown values in release/staging builds (throw/assert) or log a prominent warning and optionally default to safer mode. |
| CONST-019 | `lib/core/constants/app_build_config.dart` | 7 | Low | `appVersion` and `appBuildNumber` default to static values (`1.0.0`, `1`) if env vars are missing, which can produce misleading metadata in CI/CD artifacts. | Validate these values in release pipeline; in release mode, throw or assert when defaults are still present. |
| CONST-020 | `lib/core/constants/app_constants.dart` | 1 | Low | Barrel exports only; no module-level docs describing expected import usage (`app_constants.dart` vs direct files), which may lead to inconsistent imports across codebase. | Add short library-level documentation and enforce import style via lints/conventions. |

## Additional Enhancement Suggestions (Non-blocking)

1. Add unit tests for all guardrails in `SecurityConfig`, especially release/production behavior and key validation edge cases.
2. Add boundary tests for `PdfConfig` (`min/max`, overlap behavior, and `adaptiveChunkSize` threshold transitions).
3. Introduce strongly typed value objects for sizes/timeouts (instead of raw ints in bytes) to prevent unit mistakes.
4. Consider centralizing configuration validation into one `validate()` routine that runs once at startup and emits actionable diagnostics.
5. Add lint rules for explicit return types and forbidden direct environment secret access in non-bootstrap layers.

## Severity Legend

- High: security, data loss, or production outage risk.
- Medium: realistic reliability/testability/security concern that can cause defects.
- Low: maintainability/style/readability issues with lower immediate risk.
