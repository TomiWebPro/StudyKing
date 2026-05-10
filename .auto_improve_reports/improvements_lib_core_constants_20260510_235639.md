# Improvement Report: `lib/core/constants`

Generated: 2026-05-10
Scope analyzed: `lib/core/constants`
Files analyzed: `lib/core/constants/app_constants.dart`

## Findings

| # | File Path | Line | Severity | Category | Description | Suggested Fix |
|---|---|---:|---|---|---|---|
| 1 | `lib/core/constants/app_constants.dart` | 79 | **Critical** | Security bug | A hardcoded encryption key (`encryptionKey`) is stored in source code. This is a secret-management vulnerability and risks data compromise if reused across environments. | Remove the hardcoded key. Load encryption material from secure platform keystores (Android Keystore / iOS Keychain) or an environment-backed secret provider. Enforce rotation and fail fast if key is missing in production. |
| 2 | `lib/core/constants/app_constants.dart` | 9-11 | **High** | Security / configuration | API keys are mutable global statics (`static String?`). This allows runtime mutation from anywhere, complicates reasoning, testing, and secure lifecycle handling. | Replace with a dedicated immutable config object initialized once at startup (dependency injection). Store secrets in secure storage and expose via typed getters with null-safe validation. |
| 3 | `lib/core/constants/app_constants.dart` | 58 | **High** | Portability bug | `defaultStoragePath` is hardcoded to an Android-specific absolute path. This breaks portability (iOS/web/desktop) and may fail on scoped storage rules. | Resolve paths at runtime using platform APIs (`path_provider`) and app-specific directories. Keep only relative folder names as constants. |
| 4 | `lib/core/constants/app_constants.dart` | 38-39 | **High** | Logic/design bug | `themeMode = 'system'` and `useDarkTheme = true` can express contradictory states and create ambiguous behavior. | Replace both with a single typed enum-backed setting (e.g., `ThemeMode.system/light/dark`) and remove duplicate boolean toggle. |
| 5 | `lib/core/constants/app_constants.dart` | 38 | **Medium** | Type-safety / style | `themeMode` is stored as a free-form string (`'system'`). Typos are possible and not compiler-checked. | Use `ThemeMode` enum (or project-specific enum) instead of string literals. |
| 6 | `lib/core/constants/app_constants.dart` | 77 | **High** | Security posture | `requireAuthentication` defaults to `false`, which can accidentally ship without auth protection if checked directly in security-sensitive flows. | Invert to secure-by-default (`true`) for production profiles, or derive from build flavor/environment with explicit non-production overrides. |
| 7 | `lib/core/constants/app_constants.dart` | 4-5 | **Medium** | Maintainability | `appVersion` and `appBuildNumber` are hardcoded and may drift from package metadata/release pipeline values. | Source version/build from build-time variables (`pubspec`/CI injection) and generate these constants automatically. |
| 8 | `lib/core/constants/app_constants.dart` | 23-24 | **Medium** | Data/schema safety | Database and Hive box names are plain literals without namespacing/version strategy; migrations and multi-environment isolation become riskier. | Add explicit versioned naming conventions (e.g., `studyking_v1.db`, `studyking_storage_v1`) or centralized migration mapping. |
| 9 | `lib/core/constants/app_constants.dart` | 15,20 | **Medium** | Reliability/performance | Timeout constants are raw integers with unit comments (`seconds`), which is error-prone and weakly typed. | Store as `Duration` constants (e.g., `Duration(seconds: 120)`) to prevent unit mistakes and simplify API usage. |
| 10 | `lib/core/constants/app_constants.dart` | 54-55 | **Medium** | Performance tuning | `defaultPdfChunkSize` and `pdfChunkOverlap` are fixed values with no constraints or adaptive tuning; overlap ratio may create inefficient repeated processing. | Add validation and adaptive chunk sizing based on document size/device memory; expose as config with safe min/max bounds. |
| 11 | `lib/core/constants/app_constants.dart` | 73 | **Medium** | Input validation | `imageCompressionQuality` comment says `0-100`, but there is no enforced bound check. Invalid values elsewhere could break behavior. | Guard with runtime assertion/validation where consumed, or wrap in a validated config model. |
| 12 | `lib/core/constants/app_constants.dart` | 34 | **Low** | Domain correctness | `minScoreForMastery = 80` is unvalidated magic number and may not align with configurable pedagogy requirements. | Move to a typed settings/profile model and allow controlled override per curriculum/feature flag. |
| 13 | `lib/core/constants/app_constants.dart` | 63-65 | **Low** | UX/i18n | Error messages are hardcoded English strings in constants, which blocks localization and context-aware messaging. | Move user-facing strings to localization resources (`arb`/i18n layer), keep only keys or fallback identifiers in constants. |
| 14 | `lib/core/constants/app_constants.dart` | 27-29,72 | **Low** | Release management | Feature flags are compile-time booleans only. This prevents remote kill-switches and runtime experimentation. | Route feature flags through a feature-management service (local defaults + remote config override). |
| 15 | `lib/core/constants/app_constants.dart` | 79 | **High** | Security / data protection | The comment “Change in production!” is not enforceable and can be ignored accidentally. | Add startup guardrails: assert non-default key in release mode, fail app initialization if default/placeholder secret is detected. |
| 16 | `lib/core/constants/app_constants.dart` | 1 | **Low** | API design | `AppConstants` can be instantiated implicitly (no private constructor), despite being a static holder. | Add a private constructor (`AppConstants._();`) to prevent accidental instantiation. |
| 17 | `lib/core/constants/app_constants.dart` | 1-80 | **Medium** | Separation of concerns | A single class mixes metadata, secrets, network config, theme, notifications, storage, and security. This increases coupling and change risk. | Split into domain-focused config classes/files (e.g., `ApiConfig`, `StudyConfig`, `SecurityConfig`, `UiConfig`). |
| 18 | `lib/core/constants/app_constants.dart` | 57-60 | **Low** | Path robustness | `tempDirectory` and `cacheDirectory` are plain names without canonical joining strategy, increasing risk of inconsistent path composition. | Standardize path composition with `path` package join helpers and central utility methods. |
| 19 | `lib/core/constants/app_constants.dart` | 31-55,67-75 | **Low** | Observability | Many runtime-impacting values are static but have no telemetry linkage, making tuning difficult in production. | Add instrumentation points (e.g., log/config snapshot in debug, metric tags in production-safe form) and document tuning playbook. |
| 20 | `lib/core/constants/app_constants.dart` | 14,19 | **Low** | Environment strategy | Base URLs are fixed constants; staging/dev/prod switching is not represented. | Introduce environment-specific config loading (flavors/build-time defines) and avoid hardcoded endpoint selection in code. |

## Priority Fix Plan

1. **Immediate (Critical/High):** remove hardcoded encryption key, secure key storage flow, and auth-default hardening.
2. **Short term (High/Medium):** replace mutable global API-key statics with typed immutable config and environment/flavor handling.
3. **Short term (Medium):** convert raw timeout ints to `Duration`, remove theme setting ambiguity with enum-based model.
4. **Medium term (Medium/Low):** split monolithic constants class by concern, introduce localization-backed error strings, and improve path portability.
5. **Ongoing (Low):** add observability and configuration governance (validation, documentation, migration/versioning patterns).

## Notes

- No direct runtime call sites were evaluated in this report; findings are based on static analysis of `lib/core/constants/app_constants.dart`.
- Severity reflects likely impact if these constants are used in production paths.
