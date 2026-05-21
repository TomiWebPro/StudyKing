# Improvement Report: `lib/models/`

**Generated:** 2026-05-10 18:41:22
**Scope:** 5 files, 949 lines total

---

## 1. `llm_models.dart` (235 lines)

### BUG-1.1 — Syntax error: double `??` instead of `?` (Line 206)
- **File:** `lib/models/llm_models.dart:206`
- **Severity:** **CRITICAL** (compile error)
- **Description:** `final Map<String, dynamic>?? reasoning;` uses `??` (null-aware operator) instead of `?` (nullable type). This is syntactically invalid and will prevent compilation.
- **Fix:** Change `Map<String, dynamic>??` to `Map<String, dynamic>?`:

### BUG-1.2 — Syntax error: double `??` in `fromJson` (Line 224)
- **File:** `lib/models/llm_models.dart:224`
- **Severity:** **CRITICAL** (compile error)
- **Description:** `json['reasoning'] as Map<String, dynamic>??` — same double `??` syntax error.
- **Fix:** Change `as Map<String, dynamic>??` to `as Map<String, dynamic>?`.

### BUG-1.3 — `this` reference in factory constructor (Lines 82-96)
- **File:** `lib/models/llm_models.dart:96` (in `DynamicModel.calculateCost`)
- **Severity:** Minor — logical bug
- **Description:** `getBestPrice()` (line 66-77) always returns `prices[0]` ("First fetched price") but is named `getBestPrice`. It does not actually compute the "best" (lowest) price. The method name is misleading. Callers at lines 76 and 82 assume `prices[0]` is optimal.
- **Fix:** Either implement actual best-price logic (sort by inputPrice + outputPrice) or rename to `getFirstPrice()` / `getDefaultPrice()`.

### BUG-1.4 — Incorrect type for `topP` (Line 108)
- **File:** `lib/models/llm_models.dart:108`
- **Severity:** **HIGH** (runtime type mismatch with API)
- **Description:** `topP` is declared as `int?` but the OpenRouter API `top_p` parameter is a `double` (floating-point probability, 0–1). An `int` value will be sent as an integer (e.g., `1` instead of `0.95`) which may be rejected or misinterpreted by the API.
- **Fix:** Change `final int? topP;` to `final double? topP;` and update `toJson()` accordingly.

### BUG-1.5 — `topP` sent as `top_p` in JSON but contains `int?` default fallback issue (Line 134)
- **File:** `lib/models/llm_models.dart:134`
- **Severity:** Minor
- **Description:** `json['top_p'] = topP;` would send an `int` value (if not null), but `top_p` must be a `double` per the API spec.
- **Fix:** See BUG-1.4.

### BUG-1.6 — No null safety on `choices` parsing (Line 168-170)
- **File:** `lib/models/llm_models.dart:168`
- **Severity:** **HIGH** (runtime crash on null response)
- **Description:** `(json['choices'] as List)` will throw a `TypeError` if `json['choices']` is `null` or missing. There is no null check before the cast.
- **Fix:** Use `(json['choices'] as List?)?.map(...).toList() ?? []` or add an explicit null check.

### BUG-1.7 — `created` field type mismatch (Line 151)
- **File:** `lib/models/llm_models.dart:151`
- **Severity:** Medium
- **Description:** `created` is declared as `String` but the OpenRouter API returns a Unix timestamp (integer). This may cause serialization/parsing issues.
- **Fix:** Change `final String created;` to `final int created;` and update `fromJson` accordingly.

### BUG-1.8 — API key serialized in JSON body (Line 135)
- **File:** `lib/models/llm_models.dart:135`
- **Severity:** **HIGH** (security concern)
- **Description:** `if (apiKey != null) json['api_key'] = apiKey;` sends the API key in the request body. API keys should be sent via HTTP headers (e.g., `Authorization: Bearer`), not in the JSON payload where they may be logged or intercepted.
- **Fix:** Remove `apiKey` from the model; let the HTTP client (Dio) handle auth headers.

### BUG-1.9 — Hardcoded cost constant despite "dynamic pricing" claim (Lines 184-189)
- **File:** `lib/models/llm_models.dart:188`
- **Severity:** Low
- **Description:** `getTotalCost()` hardcodes `0.000006` per token. The file doc says "All prices are fetched dynamically, no hardcoded values."
- **Fix:** Either remove the method or make it use real dynamic pricing data.

### ISSUE-1.10 — Redundant getter `getContent()` (Line 231)
- **File:** `lib/models/llm_models.dart:231`
- **Severity:** Low (code style)
- **Description:** `String getContent() => content;` is a redundant getter — `content` is already a public final field.
- **Fix:** Remove the method; callers should use `.content` directly.

### ISSUE-1.11 — `bool pricesFetched` is mutable on `@immutable` class (Line 51)
- **File:** `lib/models/llm_models.dart:51`
- **Severity:** Low (code style / lint warning)
- **Description:** `DynamicModel` is annotated `@immutable` but has a mutable field `bool pricesFetched`. This violates the contract.
- **Fix:** Either remove `@immutable` or make `pricesFetched` final (set via constructor).

### ISSUE-1.12 — Unused import `uuid` (Line 2)
- **File:** `lib/models/llm_models.dart:2`
- **Severity:** Low (code cleanliness)
- **Description:** `import 'package:uuid/uuid.dart';` is never used anywhere in this file.
- **Fix:** Remove the import.

### ISSUE-1.13 — `@immutable` missing on `Message` class (Line 203)
- **File:** `lib/models/llm_models.dart:203`
- **Severity:** Low (inconsistency)
- **Description:** `ModelPrice`, `DynamicModel`, `OpenRouterRequest`, and `OpenRouterResponse` all have `@immutable`, but `Message` does not. It appears to be intended to be immutable as all fields are final (except `reasoning` has a syntax error).
- **Fix:** Add `@immutable` annotation to `Message` class after fixing the syntax error.

### ISSUE-1.14 — `hashCode` should use `Object.hash` (Line 95)
- **File:** `lib/models/llm_models.dart:95`
- **Severity:** Low (best practice)
- **Description:** `provider.hashCode ^ modelName.hashCode` uses XOR which can produce collisions (e.g., `hash(a,b) == hash(b,a)`). Dart best practice is `Object.hash(provider, modelName)`.
- **Fix:** Change to `Object.hash(provider, modelName)`.

---

## 2. `settings_model.dart` (206 lines)

### BUG-2.1 — `this` used in factory constructor (Line 96)
- **File:** `lib/models/settings_model.dart:96`
- **Severity:** **CRITICAL** (compile error)
- **Description:** `this.calculateTotalCost(inputTokens, outputTokens, cachedTokens);` — factory constructors do not have access to `this` because the instance does not exist yet. This will not compile.
- **Fix:** Make `calculateTotalCost` a static method or inline the calculation. Also, the `totalCost` parameter is shadowed by the local `final totalCost`.

### BUG-2.2 — `final` field reassigned (Lines 137, 150, 160)
- **File:** `lib/models/settings_model.dart:137`
- **Severity:** **CRITICAL** (compile error)
- **Description:** `final SettingsAPIKey? _apiKey;` is declared `final` but is reassigned in `addApiKey()` (line 150) and `removeApiKey()` (line 160). `final` fields cannot be reassigned.
- **Fix:** Change `final SettingsAPIKey? _apiKey;` to `SettingsAPIKey? _apiKey;`.

### BUG-2.3 — String division / operator precedence (Line 129)
- **File:** `lib/models/settings_model.dart:129`
- **Severity:** **HIGH** (runtime bug — produces NaN)
- **Description:** `${totalCost / totalTokens.toStringAsFixed(10)}` — `totalTokens.toStringAsFixed(10)` returns a `String`. Dividing a `double` by a `String` produces `NaN` at runtime.
- **Fix:** Change to `${(totalCost / totalTokens).toStringAsFixed(10)}`.

### BUG-2.4 — Undefined variable `cachedTokens` in method body (Line 115)
- **File:** `lib/models/settings_model.dart:115`
- **Severity:** **CRITICAL** (compile error)
- **Description:** Method signature is `calculateTotalCost(int inputTokens, int outputTokens, int cachedTokensCost)` but the body references `cachedTokens` (line 115), which is not defined in scope. The parameter is named `cachedTokensCost`.
- **Fix:** Change `cachedTokens` to `cachedTokensCost`.

### BUG-2.5 — Division by zero in `projectedMonthlyCost` (Line 196)
- **File:** `lib/models/settings_model.dart:196`
- **Severity:** Medium (runtime Infinity)
- **Description:** `(getTotalCost() / _usageHistory.length * 30 * 10000) * 100` — if `_usageHistory` is empty, `_usageHistory.length` is `0`, causing division by zero (returns `Infinity`). Also the magic numbers `10000` and `100` are unexplained.
- **Fix:** Add a guard for empty history and document/clean up the formula.

### BUG-2.6 — Incorrect string formatting in `formatUsageSummary` (Lines 200-205)
- **File:** `lib/models/settings_model.dart:200-205`
- **Severity:** Medium (display bug)
- **Description:** `$\$` results in double dollar sign `$$`. Also `\$${totalTokens.toStringAsFixed(0)}` puts a `$` prefix before token count (a unitless integer), which is semantically wrong. The label says "over \$... tokens" making the output confusing.
- **Fix:** Use proper string interpolation:
  ```dart
  'Usage: \$${totalCost.toStringAsFixed(2)} over ${totalTokens} tokens, avg: \$${avgCostPer1000Tokens.toStringAsFixed(2)} per 1k tokens';
  ```

### BUG-2.7 — `==` operator omits `password` field (Lines 37-42)
- **File:** `lib/models/settings_model.dart:37-42`
- **Severity:** Low (possible logic bug)
- **Description:** `SettingsAPIKey` equality checks only `provider` and `key`, ignoring `password`. Two objects differing only in `password` are considered equal, which may cause unexpected behavior in collections.
- **Fix:** Add `password == other.password` to the equality check (or document why it is intentionally omitted).

### ISSUE-2.8 — Unused parameter `totalCost` in `fromResponse` factory (Line 88)
- **File:** `lib/models/settings_model.dart:88`
- **Severity:** Low
- **Description:** `double totalCost` is a named parameter but is never used — it is immediately shadowed by `final totalCost = this.calculateTotalCost(...)`. The parameter is dead code.
- **Fix:** Remove the `totalCost` parameter.

### ISSUE-2.9 — Redundant `== true` in null-aware chain (Line 146)
- **File:** `lib/models/settings_model.dart:146`
- **Severity:** Low (code style)
- **Description:** `_apiKey?.key.isNotEmpty == true` — the `== true` is unnecessary since the expression already evaluates to `bool?` and the `hasApiKey` getter returns `bool`. The `?? false` pattern is more idiomatic.
- **Fix:** Change to `_apiKey?.key.isNotEmpty ?? false`.

### ISSUE-2.10 — `hashCode` should use `Object.hash` (Line 45)
- **File:** `lib/models/settings_model.dart:45`
- **Severity:** Low (best practice)
- **Description:** XOR-based hash code can cause collisions.
- **Fix:** Use `Object.hash(provider, key)`.

### ISSUE-2.11 — `password` exposed in `toJson()` (Line 33)
- **File:** `lib/models/settings_model.dart:33`
- **Severity:** Medium (security)
- **Description:** The `password` field is serialized to JSON in `toJson()`. If this JSON is persisted to disk or sent over the network, it exposes sensitive credentials.
- **Fix:** Consider omitting `password` from `toJson()` or encrypting it before serialization.

---

## 3. `llm_config.dart` (284 lines)

### BUG-3.1 — Syntax error: `->` instead of `=>` in `toString` (Line 51)
- **File:** `lib/models/llm_config.dart:51`
- **Severity:** **CRITICAL** (compile error)
- **Description:** `String toString() -> 'LLMConfig(...)';` uses `->` (comment/arrow in some pseudocode) instead of `=>` (Dart fat arrow). This is syntactically invalid.
- **Fix:** Change `->` to `=>`.

### BUG-3.2 — Malformed constructor parameter for `apiKey` (Line 66)
- **File:** `lib/models/llm_config.dart:66`
- **Severity:** **CRITICAL** (compile error)
- **Description:** `required this.apiKey.isEmpty ? '' : this.apiKey` — this is an expression in the formal parameter list, which is not valid Dart syntax. You cannot inline a ternary into a `this.field` initializing formal.
- **Fix:** Move the logic to an initializer list:
  ```dart
  const APIEndpointConfig({
    required this.provider,
    required this.baseUrl,
    required String apiKey,
    this.modelName = '',
    this.contextWindow = 4096,
  }) : apiKey = apiKey.isEmpty ? '' : apiKey;
  ```

### BUG-3.3 — `$M` interpreted as string interpolation of undefined variable `M` (Line 36)
- **File:** `lib/models/llm_config.dart:36`
- **Severity:** **HIGH** (runtime error or compile warning)
- **Description:** `'${inputPricePerMillionTokens}/$M input, ...'` — `$M` is treated as string interpolation of variable `M`, which does not exist. This will produce either a compile error or output like `0.5/null input` at runtime.
- **Fix:** Escape the `$` signs: `'${inputPricePerMillionTokens}/\$M input, ...'`.

### BUG-3.4 — Incorrect logic: `requestsPerDay` divides by 24 (hours) (Line 172)
- **File:** `lib/models/llm_config.dart:172`
- **Severity:** **HIGH** (logical bug)
- **Description:** `totalRequests / 24.0` divides by 24 as if 24 represents hours. But this is supposed to be "requests per day", which requires knowing the time span of the data. Without a time range, this calculation is meaningless and always gives the wrong result.
- **Fix:** Remove the method or add a time range parameter (e.g., `Duration period`) and compute based on actual elapsed time.

### BUG-3.5 — Division by zero in `monthlyProjection` (Line 176)
- **File:** `lib/models/llm_config.dart:176`
- **Severity:** Medium (runtime Infinity)
- **Description:** `totalCost / totalRequests * 30 * 1000000` — if `totalRequests` is `0`, this produces `Infinity`. Also `1000000` is an unexplained magic number.
- **Fix:** Add a zero-guard and document/remove magic numbers.

### BUG-3.6 — Hardcoded model pricing contradicts "dynamically fetched" claim (Lines 186-283)
- **File:** `lib/models/llm_config.dart:186-283`
- **Severity:** Low (maintenance issue)
- **Description:** `AvailableModels.openrouterModels` contains hardcoded pricing for 9 models. The comment at line 5 says "All prices are fetched dynamically." These static values will become stale as API pricing changes.
- **Fix:** Either remove the static list and rely entirely on dynamic fetching, or remove the comment claiming dynamic pricing.

### ISSUE-3.7 — `LLMUsageSummary` missing validation (Lines 152-183)
- **File:** `lib/models/llm_config.dart:152-183`
- **Severity:** Low (data integrity)
- **Description:** The `const` constructor does not validate that `totalInputTokens + totalOutputTokens == totalTokens`. Inconsistent data could be passed without detection.
- **Fix:** Consider an assertion in an optional non-`const` constructor, or document that validation is the caller's responsibility.

### ISSUE-3.8 — `AvailableModels` has no private constructor (Line 186)
- **File:** `lib/models/llm_config.dart:186`
- **Severity:** Low (code style)
- **Description:** `AvailableModels` is a utility class with only static members but no private constructor to prevent instantiation.
- **Fix:** Add `AvailableModels._();` private constructor.

### ISSUE-3.9 — Inconsistent `@immutable` usage (Lines 107, 151, 186)
- **File:** `lib/models/llm_config.dart:107, 151, 186`
- **Severity:** Low (code style / lint)
- **Description:** `LLMModelConfig` and `APIEndpointConfig` have `@immutable`, but `LLMUsageRecord`, `LLMUsageSummary`, and `AvailableModels` do not, even though they appear to be immutable data classes.
- **Fix:** Add `@immutable` to `LLMUsageRecord`, `LLMUsageSummary`, and add a private constructor to `AvailableModels`.

### ISSUE-3.10 — `hashCode` should use `Object.hash` (Lines 48, 103)
- **File:** `lib/models/llm_config.dart:48, 103`
- **Severity:** Low (best practice)
- **Description:** XOR-based hash codes used. `Object.hash()` is the Dart-preferred approach for multi-field hashing.
- **Fix:** Use `Object.hash(provider, modelName)` and `Object.hash(provider, baseUrl)`.

---

## 4. `dynamic_lesson_types.dart` (151 lines)

### BUG-4.1 — `late` field accessed before initialization (Line 7)
- **File:** `lib/models/dynamic_lesson_types.dart:7`
- **Severity:** **HIGH** (runtime crash)
- **Description:** `late Map<String, String> _lessonTypesMap;` — if `getLessonTypes()`, `getLessonTypeById()`, or `containsLessonType()` is called before `fetchLessonTypes()`, a `LateInitializationError` will be thrown.
- **Fix:** Initialize with an empty map: `Map<String, String> _lessonTypesMap = {};` instead of using `late`.

### BUG-4.2 — Dio instance created without base URL (Line 8)
- **File:** `lib/models/dynamic_lesson_types.dart:8`
- **Severity:** **HIGH** (runtime failures)
- **Description:** `final Dio dio = Dio();` creates a Dio instance with no `BaseOptions`. All requests use relative URLs (`/models/platform/database.json`, `/api/v1/lesson/types`) that require a base URL to resolve. These requests will fail with connection errors unless the caller configures a base URL externally (i.e., `dio.options.baseUrl`).
- **Fix:** Either require a `Dio` instance via the constructor (dependency injection) or configure a base URL.

### BUG-4.3 — Null-unsafe cast of `data['types']` (Line 19)
- **File:** `lib/models/dynamic_lesson_types.dart:19`
- **Severity:** **HIGH** (runtime crash)
- **Description:** `for (var type in data['types'] as List?)` — casting to `List?` but then immediately iterating without a null check. If `data['types']` is null, the cast succeeds (producing null) but iterating `null` throws a `TypeError`.
- **Fix:** Add a null check: `final types = data['types'] as List?; if (types != null) { for (...) }`.

### BUG-4.4 — Missing `LessonTypeError` class (Line 55)
- **File:** `lib/models/dynamic_lesson_types.dart:55`
- **Severity:** **CRITICAL** (compile error)
- **Description:** `throw LessonTypeError('Failed to fetch lesson type: $e');` references `LessonTypeError` which is not defined anywhere in the codebase. This will not compile.
- **Fix:** Define the `LessonTypeError` class:
  ```dart
  class LessonTypeError implements Exception {
    final String message;
    LessonTypeError(this.message);
    @override String toString() => message;
  }
  ```

### BUG-4.5 — Unhandled exceptions in `addLessonType` / `removeLessonType` (Lines 59-72)
- **File:** `lib/models/dynamic_lesson_types.dart:60, 68`
- **Severity:** Medium (unhandled async errors)
- **Description:** `addLessonType` and `removeLessonType` make network calls with no try-catch. If the network fails, the future completes with an unhandled error that the caller may not expect.
- **Fix:** Add try-catch blocks (or ensure all callers handle errors).

### BUG-4.6 — Unsafe cast to `Map` in `fetchLessonType` (Line 53)
- **File:** `lib/models/dynamic_lesson_types.dart:53`
- **Severity:** Medium (runtime crash)
- **Description:** `LessonType.fromJson(response.data)` passes `response.data` to `fromJson` which expects `Map<String, dynamic>`. If the API returns a non-Map response (e.g., a list or primitive), a `TypeError` is thrown.
- **Fix:** Add explicit casting: `response.data as Map<String, dynamic>` with error handling.

### ISSUE-4.7 — `print()` used for error logging (Line 26)
- **File:** `lib/models/dynamic_lesson_types.dart:26`
- **Severity:** Low (code quality)
- **Description:** `print('Error fetching lesson types: $e');` uses `print()` instead of a proper logging framework. In production, `print` output is often invisible or discarded.
- **Fix:** Use `package:logging` or a project-specific logger.

### ISSUE-4.8 — Static mutable state in `DBLessonTypes` (Lines 77, 99-112)
- **File:** `lib/models/dynamic_lesson_types.dart:77`
- **Severity:** Medium (testability / concurrency)
- **Description:** `static final Map<String, String> _store = {};` is mutable static state shared across all instances. This makes unit tests non-isolated (state leaks between tests) and is unsafe in multi-isolate contexts.
- **Fix:** Remove the static pattern; make `DBLessonTypes` instance-based. If singleton is needed, use a proper dependency injection container.

### ISSUE-4.9 — `LessonType` has mutable fields (Lines 120-122)
- **File:** `lib/models/dynamic_lesson_types.dart:120-122`
- **Severity:** Low (code style)
- **Description:** `description`, `config`, and `createdAt` are not `final`, making `LessonType` mutable. Immutable data classes are preferred in Dart.
- **Fix:** Make all fields `final` and use `copyWith` for mutations.

### ISSUE-4.10 — `DBLessonTypes.getStore()` exposes mutable reference (Line 95-97)
- **File:** `lib/models/dynamic_lesson_types.dart:95`
- **Severity:** Low (encapsulation)
- **Description:** `Map<String, String> getStore() => _dbStore;` returns the internal mutable map reference, allowing callers to modify internal state without going through the class methods.
- **Fix:** Return an unmodifiable view: `Map.unmodifiable(_dbStore)`.

---

## 5. `dynamic_context_config.dart` (73 lines)

### ISSUE-5.1 — Unused import (Line 2)
- **File:** `lib/models/dynamic_context_config.dart:2`
- **Severity:** Low (code cleanliness)
- **Description:** `import 'package:dio/dio.dart';` is imported but never used in this file.
- **Fix:** Remove the import.

### ISSUE-5.2 — `_contextMap` recreated on every `fromModel` call (Lines 26-37)
- **File:** `lib/models/dynamic_context_config.dart:26`
- **Severity:** Low (performance)
- **Description:** The `_contextMap` local map is created and populated every time `factory DynamicContextConfig.fromModel()` is called. This is unnecessary garbage allocation.
- **Fix:** Make it `static const`:
  ```dart
  static const _contextMap = {
    'anthropic/claude-3-5-sonnet': 200000,
    // ...
  };
  ```

### ISSUE-5.3 — Fallback context window too conservative (Line 41)
- **File:** `lib/models/dynamic_context_config.dart:41`
- **Severity:** Low
- **Description:** Fallback is `4096` tokens when the model is not in `_contextMap`. Most modern LLMs have much larger context windows (8K–200K+). A 4096 fallback may unnecessarily truncate prompts for unknown models.
- **Fix:** Consider a larger fallback (e.g., 8192 or 16384) or dynamically query the model. Also consider that unreachable model IDs might be better served by a more generous default.

### ISSUE-5.4 — Inconsistent defaults between `fromModel` and `fromJson` (Lines 42 vs 64)
- **File:** `lib/models/dynamic_context_config.dart:42, 64`
- **Severity:** Low
- **Description:** `fromModel()` sets `batchSize: 10` (line 43), while `fromJson()` defaults `batchSize` to `5` (line 64). This inconsistency means the same model could have different batch sizes depending on how the object is created.
- **Fix:** Align the defaults. Choose one canonical default (e.g., `10`).

### ISSUE-5.5 — `hashCode` not overridden (Line 71)
- **File:** `lib/models/dynamic_context_config.dart:71`
- **Severity:** Low
- **Description:** `DynamicContextConfig` is annotated `@immutable` but does not override `==` and `hashCode`. Two instances with the same values will not be equal, which may cause issues in collections or tests.
- **Fix:** Add `==` and `hashCode` overrides.

### ISSUE-5.6 — `toString` omits important fields (Line 72)
- **File:** `lib/models/dynamic_context_config.dart:72`
- **Severity:** Low
- **Description:** `toString()` only shows `modelId`, `contextWindow`, and `batchSize`, but omits `actualContextUsed` and `autoFetched`, which are relevant for debugging.
- **Fix:** Include all fields in `toString()`.

---

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL (compile error) | 6 |
| HIGH (runtime crash/bug) | 7 |
| Medium | 9 |
| Low | 21 |
| **Total** | **43** |

### Key findings:
- **6 compile errors** across 3 files (`llm_models.dart`, `settings_model.dart`, `llm_config.dart`) that will prevent the project from building.
- **Missing `LessonTypeError` class** referenced but never defined.
- **Security issues**: API key sent in JSON body (`llm_models.dart`), password serialized to JSON (`settings_model.dart`).
- **Dio misconfiguration**: No base URL set, relative paths will fail (`dynamic_lesson_types.dart`).
- **LateInitialization risk**: `late` field accessed before initialization (`dynamic_lesson_types.dart`).
- **Multiple formula bugs** in cost/projection calculations (`settings_model.dart`, `llm_config.dart`).
- **String interpolation bugs** causing NaN or wrong display values.
