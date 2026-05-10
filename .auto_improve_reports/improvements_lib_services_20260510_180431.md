# Code Improvement Report — `lib/services/`

**Generated:** 2026-05-10 18:04 UTC  
**Scope:** All 9 files in `lib/services/`  
**Total issues found:** 128

---

## File-by-File Analysis

---

### 1. `question_engine.dart` (243 lines)

| # | Line(s) | Severity | Category | Description | Suggested Fix |
|---|---------|----------|----------|-------------|---------------|
| 1 | 38 | **High** | Design | `LessonQuestion` extends `ChangeNotifier` but has no mutable state and never calls `notifyListeners()`. The class is a plain data model, not a reactive model. | Remove `extends ChangeNotifier` and the `import 'package:flutter/foundation.dart'`. Use a simple value class instead. |
| 2 | 8 | **Low** | Unused Import | `import 'package:uuid/uuid.dart';` is never used in this file. | Remove the import. |
| 3 | 98–101 | **Medium** | Logic Bug | `hasValidMcqOptions()` returns `true` when `options` is `null` and `questionType == 'multipleChoice'`. The condition `questionType != 'multipleChoice' \|\| options == null` short-circuits to `true` when `options == null`, incorrectly signaling validity. | Change to: `if (questionType != 'multipleChoice') return true; if (options == null \|\| options.length < McqOptionsConfig.minOptions \|\| options.length > McqOptionsConfig.maxOptions) return false; return true;` |
| 4 | 107 | **Medium** | Initialization | `_mcqOptionsByType` is declared `late` but only initialized inside the `try` block (line 117). If `fetchMcqOptionsByType()` throws before line 117 (e.g., network error on line 115), the catch block at line 127–129 re-assigns it. However, calling `getMcqOptionsForType()` **before** `fetchMcqOptionsByType()` has ever been called will throw `LateInitializationError`. | Initialize eagerly: `Map<String, int> _mcqOptionsByType = {};` and remove the `late`. |
| 5 | 113–130 | **Medium** | Error Handling | `fetchMcqOptionsByType()` catches all exceptions but provides no logging. Silent failures make debugging difficult. | Log the error or rethrow for upstream handling. |
| 6 | 115, 118 | **Medium** | Null Safety | `response.data` is used without a null check. If the API returns a non-200 status, `_mcqOptionsByType` remains uninitialized (see #4). | Check `response.statusCode == 200` and `response.data != null` before processing. |
| 7 | 148–149 | **Low** | Dead Code | `typeOptions == null` is always `false` (typeOptions is `int`, not nullable). The comparison is dead code. | Remove the `== null` check. |
| 8 | 148–149 | **Low** | Readability | The ternary expression is confusing due to mixed `??` and ternary operators. | Refactor with clearer branching. |
| 9 | 167 | **High** | Functional Bug | `correctAnswer: options.first` always assigns the first option as the correct answer (`"Option 0"`), making every MCQ trivial (answer is always "A"). | The correct answer should be determined by the API response or chosen randomly. Remove the hardcoded default. |
| 10 | 175–178 | **Medium** | Placeholder / Debug | `generateOption()` always returns `'Option $index'` — a placeholder that never actually generates real options. Line 176 uses `print()` for debugging. | Implement actual LLM-based or rule-based option generation. Remove the `print()` statement. |
| 11 | 186, 225 | **Critical** | Compile Error | `McqOptionsConfig.defaultOptions` references an **instance field** as if it were `static`. `defaultOptions` on line 23 is `int defaultOptions = 5;` (instance), not `static const`. This will not compile. | Either make `defaultOptions` static (`static const int defaultOptions = 5;`) or use an instance of `McqOptionsConfig`. |
| 12 | 211–216 | **Low** | Dead Code | `getQuestion()` returns a hardcoded test question. Appears to be a development leftover. | Remove if unused, or mark with a TODO. |

---

### 2. `question_engine_dynamic.dart` (80 lines — appears truncated)

| # | Line(s) | Severity | Category | Description | Suggested Fix |
|---|---------|----------|----------|-------------|---------------|
| 13 | 8 | **Critical** | Missing Import | `import 'dynamic_lesson_types.dart'` references a file that does not exist in the project (confirmed via glob search). This will cause a compile error. | Remove the import or create the file. |
| 14 | 24 | **Medium** | Initialization | `_questionTypes` is declared `late` but only initialized inside the `try`-implied success path (line 33). If the API returns a non-200 status, the field is never set. | Initialize eagerly: `Map<String, String> _questionTypes = {};` |
| 15 | 31 | **Medium** | Error Handling | `fetchQuestionTypes()` has no try/catch block. Network failures will throw an unhandled exception. | Wrap the API call in try/catch, provide a fallback. |
| 16 | 33–39 | **High** | Null Safety | `response.data` is used without null check. `types as List?` may produce a nullable list, but iterating a nullable `List?` with `for`-in is invalid — in Dart 3 you cannot iterate a nullable iterable. | Add null check: `if (response.data != null) { for (var type in response.data as List) { ... } }` |
| 17 | 35 | **Medium** | Type Safety | `_questionTypes.addAll(type)` where `type` is a `Map` entry of unknown shape. If `type` is not a `Map<String, String>`, this can throw. | Cast safely or validate each entry. |
| 18 | 52–65 | **Critical** | Logic Bug | Line 64 unconditionally executes `_mcqOptionsRanges = {'default': 5};` **after** the try/catch block. This **always overwrites** any successfully fetched data with the default, making the entire API call pointless. | Move the fallback into the `catch` block: `catch (e) { _mcqOptionsRanges = {'default': 5}; }` |
| 19 | 52–65 | **Medium** | Initialization | Same late-initialization issue as #14 for `_mcqOptionsRanges`. | Initialize eagerly. |
| 20 | 72–73 | **Medium** | Logic Bug | `getMinMcqOptions()` calls `_mcqOptionsRanges.values.firstWhere((v) => v >= 2)`. If no value satisfies the predicate, `firstWhere` **throws** (it doesn't return null, so `?? 2` is dead code). | Use `firstWhere(..., orElse: () => 2)` instead of `?? 2`. |
| 21 | 75–76 | **Low** | Code Style | `getMaxMcqOptions()` uses a convoluted `.where().fold()` to compute the maximum. | Simplify to `_mcqOptionsRanges.values.fold(0, (a, b) => a > b ? a : b)` or `reduce(max)`. |
| 22 | 44 | **Low** | Redundancy | `_questionTypes.keys.cast<String>()` — `.keys` already returns `Iterable<String>` from `Map<String, String>`. The `.cast<String>()` is redundant. | Remove `.cast<String>()`. |

---

### 3. `lesson_scheduler_engine.dart` (195 lines)

| # | Line(s) | Severity | Category | Description | Suggested Fix |
|---|---------|----------|----------|-------------|---------------|
| 23 | 6 | **Low** | Unused Import | `import 'dart:convert';` is not used. | Remove it. |
| 24 | 9 | **Low** | Unused Import | `import 'package:uuid/uuid.dart';` is not used. | Remove it. |
| 25 | 63–64 | **Medium** | Resource Waste | Line 63 creates `final dio = Dio();` but never uses it. Line 64 creates another `Dio()` instance for the actual request. Two Dio instances are created where zero or one is needed. | Remove line 63 and use a shared Dio instance (e.g., passed in or a field). |
| 26 | 69 | **Medium** | Type Safety | `entry.value?.toInt() ?? 5` — `entry.value` is `dynamic` and `?.toInt()` will throw if the value is not a numeric type. | Validate the type before calling `.toInt()`. |
| 27 | 74–79 | **Critical** | Compile Error | `_mcqOptionsRange` is typed `Map<String, int>` but line 76 assigns `'input': null` and `'graph': null`. In null-safe Dart 3, a `Map<String, int>` cannot store `null` values. | Use `Map<String, int?>` or omit null entries entirely. |
| 28 | 83–85 | **Low** | Redundancy | `_commandTemplates = {};` is set in the constructor body but the field is already declared as `late Map<String, Function> _commandTemplates;` — the `late` keyword is unnecessary if initialized immediately. | Simplify to `Map<String, Function> _commandTemplates = {};` |
| 29 | 95 | **Low** | Null Safety | `_mcqOptionsRange['mcq'] ?? 5` — already correct; no issue. |
| 30 | 113–114 | **Low** | Unnecessary Async | `generateOption` is `async` but never `await`s anything. The function body is synchronous. | Remove `async`/`Future` wrapper. |
| 31 | 117–119 | **High** | Functional Bug | `_selectCorrectAnswer()` always returns `'a'` (the string literal). The correct answer is hardcoded regardless of the options. | Randomly select a valid option or pass the correct answer from upstream logic. |
| 32 | 125–138 | **Critical** | Invalid Syntax | The type signature of `_graphFunc` contains `int[,] matrix` — Dart does not support C#-style multidimensional array syntax. This is a parse error. | Use `List<List<int>> matrix` instead. |
| 33 | 125–138 | **Medium** | Dead Code | `_graphFunc` is declared as a field but **never assigned** (no constructor parameter, no setter). It will always be null (though typed as non-nullable `final`). | Either make it nullable, initialize it, or remove it. |
| 34 | 140–173 | **Critical** | Undefined Variables | Inside `generateGraphFromStory`, the `data` map references `energyPlot`, `flowPlot`, `linePlot`, `scatterPlot`, `matrix`, `width`, `height`, `source`, `title` — **none** of which are parameters of this method or declared locally. They only exist as parameter names in the `_graphFunc` type signature, which is a different scope. This will not compile. | Add these as parameters to `generateGraphFromStory`, or remove them from the data map. |
| 35 | 146–161 | **Critical** | REST API Violation | `dio.post(...)` with `data: {...}` containing undefined variables (see #34). Even if variables were defined, sending undefined Dart variables would crash. | See #34. |
| 36 | 163–169 | **High** | Undefined Types | `GraphPath`, `GraphRendering`, `Box` are from the `graphing` package which is **not listed** in `pubspec.yaml` and **not installed**. These will cause compile errors. | Install the `graphing` package or implement the types locally. |
| 37 | 170 | **Critical** | Missing Import | `GraphError` is used on line 170 but not imported in this file. It is defined in `graph_type_detector.dart`. | Add the appropriate import. |
| 38 | 175–193 | **Critical** | Undefined Variables | `_getGraphData()` references `matrix`, `x`, `y` which are not defined anywhere in the method or class scope. Also uses `MatrixChart`, `ScatterChart`, `MatrixColor` which are undefined. | Define the required variables or remove this dead method. |
| 39 | 19–42 | **Medium** | Dead Code | `generateGraphPathFromStory()` is a top-level function using the `Graphing` constructor which references an uninstalled package. Likely non-functional. | Either install/implement the package or remove the function. |
| 40 | 162 | **Low** | Code Style | `dio.post(...)` — typical naming inconsistency; many files use `Dio()` in-line instead of sharing a client instance. | Consider dependency injection for Dio throughout. |

---

### 4. `graph_type_detector.dart` (194 lines)

| # | Line(s) | Severity | Category | Description | Suggested Fix |
|---|---------|----------|----------|-------------|---------------|
| 41 | 5–6 | **Low** | Unused Imports | `import 'dart:convert';` and `import 'dart:io';` are not used in this file. | Remove them. |
| 42 | 67–68 | **Medium** | Dead Code | `detectGraphTypeFromContent()` lines 67 and 68 both check `content.contains('}')`. Line 67 catches **all** `}` occurrences and returns `'pieChart'`. Line 68 is dead code — it can never be reached. | Change line 68 to detect a different pattern (e.g., `content.contains('"heatmap"')` or coordinates for heatmap). |
| 43 | 65–71 | **Medium** | Reliability | Graph type detection uses extremely crude heuristics (checking for `,`, `[`, `}`, `nodes`, `start`). These are unreliable for real-world data and will produce many false positives. | Implement proper JSON schema-based detection or use an ML-based approach. |
| 44 | 46–61 | **Low** | Logic | `validateAndDetect()` returns `"Graph valid but type ambiguous"` inside `isValid == true` path — the message is contradictory. | Clarify the semantics. |
| 45 | 149–151 | **Critical** | Compile Error | `traceError(BoxError error)` — `BoxError` type does not exist anywhere in the project. Inside the method, `Error(error: error)` calls `dart:core` `Error`'s constructor which does **not** accept a named `error:` parameter. | Remove the method or define the missing types. |
| 46 | 155–175 | **Critical** | Infinite Recursion + Missing Constructor | `GraphAnalysis.failure()` (line 162) calls `GraphAnalysis.failure(exception: exception)` — this is **infinite recursion** and will cause a stack overflow. Also, class `GraphAnalysis` has **no generative constructor** defined, so the call to `GraphAnalysis(...)` inside `fromJson` (line 167) will not compile. | Define a private generative constructor or use `_failure()`. Fix the recursion: `failure` should create a new instance, not call itself. |
| 47 | 156, 168 | **Critical** | Type Mismatch | Field `type` is declared as `GraphType` (line 156) but in `fromJson` (line 168) it's assigned `json['type']?.toString() ?? 'unknown'` which is a `String`, not a `GraphType`. | Change the field type to `String` or parse it into the `GraphType` enum. |
| 48 | 122 | **Low** | Unused Field | `GraphAnalyzer` has a `Dio dio` field but `renderGraphFromJSON()` (line 145) doesn't use it — it just calls `jsonEncode()`. | Remove the Dio dependency if no other methods need it. |
| 49 | 137–143 | **Medium** | Error Handling | `detectGraphTypes()` has no try/catch, unlike the other methods in this class. | Add error handling for consistency. |
| 50 | 143 | **Medium** | Invalid API Usage | `response.data.body` — Dio's `Response` has a `data` property, not `data.body`. | Use `response.data` directly (and cast appropriately). |

---

### 5. `graph_rendering_engine.dart` (186 lines)

| # | Line(s) | Severity | Category | Description | Suggested Fix |
|---|---------|----------|----------|-------------|---------------|
| 51 | 5 | **Low** | Unused Import | `import 'dart:ui';` is not used (Material re-exports what's needed). | Remove it. |
| 52 | 7–8 | **Critical** | Missing Packages | `import 'package:charting_flutter/charting_flutter.dart'` and `import 'package:graphing/graphing.dart'` reference packages **not listed** in `pubspec.yaml` and **not installed**. These will cause compile errors. | Either add the packages or implement the types locally. |
| 53 | 24, 28 | **Critical** | Missing Import | `Dio` is used on lines 24 and 28 but `import 'package:dio/dio.dart'` is missing from this file. The imports present are `dart:ui`, Flutter Material, and two unknown charting packages. | Add `import 'package:dio/dio.dart';` |
| 54 | 42 | **High** | REST API Violation | `dio.get('/api/v1/graph/render', data: {...})` — Dio's `get()` method does **not** send a request body (GET requests have no body by HTTP spec). The `data:` parameter is ignored for GET requests. | Change to `dio.post()` or use `queryParameters` for GET. |
| 55 | 49–54 | **Medium** | Undefined Types | `GraphData(...)` — `graphData`, `path`, `graphType`, `graphTitle` — these constructor parameters don't match the `GraphData` definition (which likely doesn't exist since `graphing` is not installed). | Fix once the package situation is resolved. |
| 56 | 60–75 | **Critical** | Type Mismatch | `renderGraphString()` return type is `Future<List<String>>` but `dio.get()` returns `Future<Response>`, and the method just returns `await dio.get(...)` which is a `Response`, not `List<String>`. | Map the response to the expected type: `final response = await dio.get(...); return List<String>.from(response.data);` |
| 57 | 78–90 | **Medium** | Type Mismatch | `generatePlotFromChart()` returns `Future<String>` but `dio.get().data` is `dynamic` (not necessarily a `String`). Same GET-with-body issue as #54. | Cast appropriately and fix the HTTP method. |
| 58 | 105–109 | **Medium** | Logic Bug | Line 107: `if (data.contains('[')) return GraphType.bar;` catches **all** data with `[`. Line 108: `if (data.contains('[') && data.contains(']')) return GraphType.scatter;` is **dead code** — anything reaching line 108 already has `[` (so it would have returned `bar` on line 107). | Reorder conditions: check scatter first (both `[` and `]`), then bar, then line. |
| 59 | 114–133 | **High** | Dead Code | `GraphDrawingService` — field `_coords` is unused. Method `drawCoordinates()` at line 131 does `_graphData = _graphData;` which is a no-op (assigning a variable to itself). `GraphCoordinates` and `GraphCoordinate` are undefined (missing package). | Remove the entire class or implement it properly. |
| 60 | 178 | **Low** | JSON Serialization | `toJson()` for `PlotConfiguration` uses `if (type != null) 'type': type` which serializes the `GraphType` enum as its **Dart object** (toString gives `GraphType.line`), not a clean string. | Use `'type': type?.name` for a clean serialized string. |

---

### 6. `pdf_processing_service.dart` (198 lines)

| # | Line(s) | Severity | Category | Description | Suggested Fix |
|---|---------|----------|----------|-------------|---------------|
| 61 | 14 | **Critical** | Syntax Error | The constructor signature `PDFProcessingService({Required LLMAIEngineProvider LLMAIEngineProvider llmEngineProvider})` has **two** consecutive type annotations (`LLMAIEngineProvider` repeated) and `Required` should be lowercase `required`. This is a parse error. | Change to: `PDFProcessingService({required LLMAIEngineProvider llmEngineProvider})` |
| 62 | 14–16 | **Critical** | Initialization | The initializer list `llmEngineProvider = llmEngineProvider` tries to assign to `llmEngineProvider`, but the class field is named `llmEngine` (line 9), not `llmEngineProvider`. This will not compile. | Change the field name to `llmEngineProvider` or change the initializer to `llmEngine = llmEngineProvider`. |
| 63 | 22–25 | **Critical** | Invalid Assignment | `LLMAIEngineProvider get _llmEngine => llmEngineProvider;` — `llmEngineProvider` is the constructor **parameter name**, not a class field (it's not stored). Then `setLLMEngine` tries `_llmEngine = engine;` which assigns to a **getter** (not a setter). This won't compile. | Store the parameter in a field (`this.llmEngineProvider`) and use it consistently. Remove the getter/setter pattern. |
| 64 | 32–38 | **Low** | Style Inconsistency | Mixes `await` and `.then()` — `fetchContextWindow` uses `.then()` for the operation but the method is `async`. | Use consistent `await` throughout. |
| 65 | 43–44 | **High** | Type Mismatch | `fetchContextPages()` return type is `Future<List<File>>` but `dio.get()` returns `Response`, and `pagesData.data` is `dynamic`. It will not be `List<File>`. | Parse the response data properly and convert to `File` objects if needed. |
| 66 | 48–52 | **Critical** | Undefined Methods | `chunkText()` calls `pages.groupBy(...)` — `groupBy` is not a standard `List` method (requires `package:collection`). Also calls `byteLength(page)` and `chunk(part: page, limit: ...)` — both undefined. This will not compile. | Either add the required imports/implementations or use built-in Dart operations. |
| 67 | 57–63 | **High** | Invalid Access | `response.data.id` and `response.data.generated` — Dio's `response.data` is `dynamic` (typically a `Map`). Accessing it with `.id` dot-notation is wrong. Should be `response.data['id']`. | Use bracket notation for map access. |
| 68 | 67–69 | **Low** | Debug Artifact | `onError()` uses `print()` to log errors. | Use a proper logging framework. |
| 69 | 72–74 | **High** | Deceptive API | `requestStream(String url)` accepts a URL string but simply creates a `File(url)` — it **does not make any HTTP request**. It treats the URL as a local file path. This is completely misleading. | Either make an actual HTTP request or rename the method to reflect what it does. |
| 70 | 77–80 | **High** | Deceptive API | `upload()` writes content to a local file — it does **not** upload to any server. The method name is misleading. | Implement actual upload logic or rename to `saveToFile()`. |
| 71 | 174–198 | **Critical** | Multiple Compile Errors | `StorageService`: (a) `import 'package:hive/hive.dart';` is missing. (b) `_box` type is `Box?` but `Box` is undefined without the import. (c) Line 182: `await Hive.openBox(...)` inside a **getter** — getters cannot be `async`. (d) `Hive.openBox` uses positional `path` parameter but Hive's API expects `name` as first positional and path as named. | Add the import, use a proper async init method instead of a getter, and fix Hive API usage. |
| 72 | 86 | **Low** | Dead Code | `text = '';` in `ApiContext` is never used meaningfully. | Remove or use it. |
| 73 | 95–144 | **Medium** | Code Duplication | `ContextGenerator` has 5 methods that do essentially the same thing (`getContextSize`, `getWithContextSize`, `getContextWindow`, `addContext`, `setContext`, `updateContext`). | Consolidate to 2–3 methods. |
| 74 | 139–141 | **Low** | Dead Code | `getModel(String model) { return model; }` — identity function, never used. | Remove it. |
| 75 | 162–165 | **Medium** | Dead Code | `HTTPResponseProcessor.setFile()` and `writeText()` create files but are never called anywhere. | Consider removing if unused. |

---

### 7. `pdf_upload_coordinator.dart` (241 lines)

| # | Line(s) | Severity | Category | Description | Suggested Fix |
|---|---------|----------|----------|-------------|---------------|
| 76 | 6 | **Critical** | Missing Type | `class PDFFileUploadCoordinator implements UploadTask` — `UploadTask` is not defined anywhere in the project. This will not compile. | Remove the `implements` clause or define the `UploadTask` interface. |
| 77 | 10 | **Low** | Unused | `_progressMBStr` is declared `late String` but its value is never read meaningfully (it's used in string concatenation at line 70 which produces garbage). | Either compute it correctly or remove it. |
| 78 | 20 | **Low** | Redundant | `late bool _cancel = false;` — `late` with an initializer is redundant. Use `bool _cancel = false;`. | Remove `late`. |
| 79 | 26–27 | **High** | Wrong Units | `_totalSizeMB = (_totalBytes / 1024).round();` divides bytes by 1024, yielding **kilobytes**, not megabytes. For a 5 MB PDF this would give ~5120, not 5. | Divide by `1024 * 1024` for MB, or rename the variable to `_totalSizeKB`. |
| 80 | 28 | **High** | String Literal Bug | `_progressMBStr = '_totalSizeMB / 1024 MB';` — this is a **literal string**, not a computed expression. It will always contain the characters `"_totalSizeMB / 1024 MB"` instead of the computed value. | Use string interpolation: `'${_totalSizeMB / 1024} MB'`, or better, compute MB correctly. |
| 81 | 34 | **Critical** | Syntax Error | `_setHeader('Accept-encoding'; 'gzip');` uses a **semicolon** instead of a **comma** between positional arguments. This is a parse error. | Replace `;` with `,`. |
| 82 | 35–37 | **Critical** | Memory/Performance Bug | `for (var i = 0; i < _totalBytes; i++) { _chunks.add(FileChunkData()); }` — iterates **once per byte**. A 1 MB PDF (~1,000,000 bytes) creates 1,000,000 `FileChunkData` objects. This will consume gigabytes of memory and crash the app. | Chunk by page or by fixed size (e.g., 4 KB), not per byte. |
| 83 | 39–40 | **Medium** | Timeout / Typo | `connectionTimeout` should be `connectTimeout` (Dio 4.x) or `connectionTimeout` in newer Dio. Regardless, 1,600,000 ms (26.7 minutes) is unreasonably long. | Use a reasonable timeout (e.g., 120,000 ms = 2 min) and verify the correct property name. |
| 84 | 55–56 | **Medium** | Scope Issue | Local function `_setHeader` (defined at line 82) is called at line 55 before its definition. While Dart hoists, this is confusing. | Move function definitions before their first use or use class methods. |
| 85 | 65–72 | **Low** | Nesting | `_addDownloadProgressListener` is a local function defined inside `startCoordinates()`, alongside 5+ other local functions. This deep nesting is extremely hard to read and maintain. | Extract local functions into private class methods. |
| 86 | 66–71 | **High** | Division Semantics | `dio.onReceiveProgress = (received, total) { _rec = total; _progressMBStr = received / (1024); _totalSizeMB = _rec / 1024; _totalMBStr = '${received / (1024)}$_progressMBStr'; }` — `_totalMBStr` concatenates two numeric strings without a separator, producing e.g. `"0.50.5"`. Also division by 1024 gives KB not MB. | Compute MB properly: `received / (1024 * 1024)` and format correctly. |
| 87 | 74–80 | **Critical** | Invalid Types / API | `_extractAuth(HttpRequest request)` — `HttpRequest` is a server-side class from `dart:io`, not used in Flutter. `request.header` doesn't exist (should be `request.headers`). `request.bodyBytes` exists but is a `Uint8List`, not the right thing for auth extraction. The method body at line 75–79 doesn't return a value when `statusCode != 401 && statusCode != 403`. | Use Dio's interceptor `RequestOptions` instead and fix the auth logic. |
| 88 | 77 | **Critical** | Undefined Function | `_methodError(request.url, request.bodyBytes)` — `_methodError` is not defined anywhere in the file or project. | Define or remove the call. |
| 89 | 82–87 | **Critical** | Invalid API | `Dio.headers.validate({...})` — `Dio` class has no static `headers` property or `validate` method. Then `request.headers.add(type, value)` — `request` is undefined in this local function's scope. | Remove this entirely and use Dio's interceptor API correctly. |
| 90 | 90 | **Critical** | Typo / Undefined | `zio.fileDataFromPath('$_filePath');` — `zio` is not defined (likely a typo for `dio`). `fileDataFromPath` is not a Dio method. | Fix the typo and use correct Dio API. |
| 91 | 91–98 | **Critical** | Invalid API | `dio.sendMultipartFormData(...)` — no such Dio method exists. `MultiPartFile.fromPath` — should be `MultipartFile.fromPath` (lowercase 'p'). | Use `dio.post(..., data: FormData.fromMap({'file': await MultipartFile.fromPath(_filePath), ...}))` |
| 92 | 100–107 | **Critical** | Undefined References | `addUsageRecord(UsageRecord(model: model, inputTokens: inputTokens, outputTokens: outputTokens, totalCost: totalCost)!)` — `model`, `inputTokens`, `outputTokens`, `totalCost` are all undefined. `addUsageRecord` is not a method on this class. This also uses a null assertion `!` on a non-nullable expression. | Remove this block or implement the referenced variables and function. |
| 93 | 110–114 | **Critical** | Invalid Method Chain | `_contentMap.addAll(await dio.readResponseBody(await requestWrapper().get('/content/stream')).toMap());` — `readResponseBody`, `toMap()` don't exist in Dio. `requestWrapper()` returns `Future<Future<Response>>` which doesn't have `.get()`. The line is syntax-nested in a broken way. | Replace with proper Dio GET request: `final response = await dio.get('/content/stream'); _contentMap.addAll(Map.from(response.data));` |
| 94 | 119 | **Medium** | Type Confusion | `_rec = _totalBytes;` — `_rec` is `late int`, `_totalBytes` is `int`. Fine. But `_rec` appears to be used for tracking received bytes, not total. Semantic confusion. | Use clearer variable names. |
| 95 | 120 | **Critical** | Undefined Variable | `_failures.addDefault(429, 0);` — `_failures` is not declared anywhere in the class. | Define a failure tracking collection or remove this line. |
| 96 | 121–122 | **Critical** | Type Mismatch | `_dnsTime = const Duration(milliseconds: 14000);` sets `_dnsTime` (type `Duration`) to a `Duration`. Then `_dnsTime = DateTime.utc().subtract(_dnsTime);` assigns a `DateTime` to a `Duration` field. This will not compile. | Use separate variables for Duration and DateTime. |
| 97 | 124–126 | **Medium** | Error Handling | `_chunks.forEach((chunk) { _failedPages[chunk.number] = true; });` — `FileChunkData` has no `.number` property (the class is undefined). | Define `FileChunkData` with a `number` field or use the chunk index. |
| 98 | 128–134 | **Critical** | Invalid API | `MultiPartFile.fromPath(_filePath)` should be `MultipartFile.fromPath`. `dio.sendFormData` doesn't exist. Use `dio.post('/upload', data: form)`. | Fix typo and method name. |
| 99 | 138–144 | **Critical** | Parameter Mismatch | `_error({required Object error})` declares `error` as a **named** parameter, but at line 59 it's called positionally: `_error(error);`. In Dart 3, required named parameters must be called with `name: value`. | Make `error` a positional parameter: `Future<void> _error(Object error)`. |
| 100 | 141–143 | **Critical** | Undefined References | `dio.get('/login', data: {'url': requestWrapper().url, 'auth': _auth})` — `requestWrapper()` returns `Future`, doesn't have `.url`. `_auth` is not defined anywhere in the class. | Implement proper authentication flow. |
| 101 | 147–156 | **Critical** | Invalid Types | `requestWrapper()` returns `Future<Future<Response>>` — a Future wrapping another Future. `Request(...)` is not a Dio class. `receivedData`, `extra` are not valid `RequestOptions` fields. | Return `Future<Response>` directly using `dio.fetch(RequestOptions(...))`. |
| 102 | 165 | **Critical** | Undefined Variable | `_chunks[i]` — variable `i` is undefined in this `forEach` callback. The callback parameter is named `chunk`. | Change to `_chunks[_chunks.indexOf(chunk)]` or use a regular for loop. |
| 103 | 173 | **Critical** | Syntax Error | `Dio Dio();` — This tries to create a variable named `Dio` of type `Dio`. In Dart this is syntactically ambiguous and will fail (conflicts with the `Dio` type name). | Use `final dio = Dio();` with a lowercase variable name. |
| 104 | 178 | **Medium** | Missing Type | `_extractAuth(headers)` — no return type, no parameter type. Uses implicit `dynamic`. | Add explicit type annotations. |
| 105 | 183–199 | **Critical** | Garbage Code | The `HeadersAPI.saveCredentials()` method body contains: `await cacheTimeout['curl -X POST $header().data = {}'] as T; output = curl.data; throw CurlException(...)` — this is not valid Dart. `cacheTimeout` is undefined, `curl -X POST ...` is Bash, not Dart. `CurlException` is undefined. | Delete this method entirely and reimplement real credential saving. |
| 106 | 207 | **Medium** | Null Safety | `T defaultData = null` — in null-safe Dart, `T` must be nullable for `= null` to be valid. Should be `T? defaultData`. | Use `T? defaultData`. |
| 107 | 209, 219 | **Low** | Unused | `_auth` is assigned but never used. `onSendProgress` callback only prints. | Remove or use the values. |
| 108 | 229–233 | **High** | Security | `callRaw` uses `'/${headers['Authorization']}'` as the URL path — this **leaks the auth token** into the URL path, which will be logged by servers and proxies. The auth token should be sent in the `Authorization` header, not the path. | Fix to use headers properly. |

---

### 8. `batch_processor_service.dart` (287 lines)

| # | Line(s) | Severity | Category | Description | Suggested Fix |
|---|---------|----------|----------|-------------|---------------|
| 109 | 9 | **Critical** | Type Mismatch | `String Function() uuidGen = const Uuid().v4;` — `Uuid().v4` returns a `String`, not a `String Function()`. The assigned value is a `String`, but the variable type says `String Function()`. This will cause a runtime type error at best, or compile error with stricter analysis. | Change type to `String uuidGen = const Uuid().v4;` |
| 110 | 15, 134 | **Critical** | Undefined Field | `dio.get(...)` is called inside `prefetchContextWindows` (line 15) and `processText` (line 134), but `dio` is **not declared** as a field of `BatchProcessingService`. | Add `final Dio dio;` field and pass it through the constructor. |
| 111 | 25, 38 | **Critical** | Undefined Fields | `contextApi.get(...)` and `batchApi.get(...)` are called but `contextApi` and `batchApi` are not declared as fields. | Declare and initialize these fields or pass them through the constructor. |
| 112 | 23 | **High** | Wrong Constructor | `PlatformDatabase(database: platformData)` — `PlatformDatabase` class (line 222) only has a positional parameter `this.database`, not a named one. | Use `PlatformDatabase(platformData)`. |
| 113 | 27–31 | **Critical** | Wrong Type | `ContextAPI.get()` returns `Future<Map<String, dynamic>>`, but the code treats the result as having a `.content` property with `.isNotEmpty`. `Map` doesn't have a `content` getter. | The API method is misdesigned. Either make it return an object with `.content`, or use map access `result['content']`. |
| 114 | 52 | **Critical** | Invalid Type Check | `if (contextData.content is Num)` — Dart type `num` is lowercase. `Num` (uppercase) doesn't exist as a standard type and will cause a compile error. | Use `is num` (lowercase). |
| 115 | 78 | **Critical** | Syntax Error | Missing parentheses in signature: `Future<List<TextSegment> processTextExtractedPages(...)` — missing `>` before `processTextExtractedPages`. Should be `Future<List<TextSegment>> processTextExtractedPages(...)`. | Add the missing `>`. |
| 116 | 82 | **Low** | Unused Variable | `pageCounter = 0` but declared as `final` (implicitly via `var` in `final` context? Actually line 82 `final pageCounter = 0;` but then line 90 does `pageCounter++` — can't increment a `final`! Actually `var pageCounter = 0;` on line 82 as written, so `pageCounter` is mutable. Then line 90 does `pageCounter++` which is fine. But `pageCounter` is incremented but `TextSegment` on line 91 uses `pageCounter++` (post-increment in expression), which gives 0 then increments. Then line 103 uses `pageCounter` again. OK this is messy but technically works (though `pageCounter` tracks index correctly is questionable). | Use clearer counter increment pattern. |
| 117 | 86 | **Medium** | Logic | `text.isEmpty` continue is fine, but segments are added to `segments` list at line 91 **and again** at line 110. This means every text is duplicated. | Remove one of the `segments.add(segment)` calls. |
| 118 | 94, 117 | **Critical** | Wrong Collection | `currentBatch.add(segment.id)` — `TextSegment` has no `.id` field (it has `messageId`). Line 117: `segments[segment.id]` — `segments` is a `List<TextSegment>`, not a `Map`. You cannot index a `List` with a `String`. This will not compile. | Use correct field name and either use a Map or numeric indexing. |
| 119 | 98 | **Medium** | Undefined Field | `batchAdmin` is not a declared field of `BatchProcessingService`. | Add the field or inject it. |
| 120 | 114–123 | **High** | Logic Bug | After the loop, `currentBatch.isNotEmpty` triggers processing. But the code then iterates `segments` and attempts `segments[segment.id]` (wrong, see #118), and `result.content[segment.page]` may be out of bounds. The logic seems fundamentally broken. | Rewrite the batch accumulation and result mapping logic. |
| 121 | 141–148 | **Critical** | Wrong Iteration | `for (var token in response.data)` iterates the response directly. If the API returns a Map like `{'choices': [...]}`, you can't iterate a Map. And `token.token` accesses a property that likely doesn't exist on the response structure. | Parse the API response correctly first, then iterate the appropriate list. |
| 122 | 163 | **Low** | Trivial Fallback | `_ensureContextWindow` always sets to 8192 regardless of input. The catch block sets to 4096 but there's no actual API call to fetch the real value. | Implement actual context window fetching from the model endpoint. |
| 123 | 227 | **Critical** | Syntax Error | `int get contextWindow;` is an abstract getter in a **concrete** (non-abstract) class `PlatformDatabase`. This will not compile. | Either make the class abstract or provide a body: `int get contextWindow => database['contextWindow']?.toInt() ?? 4096;` |
| 124 | 236–253 | **Critical** | Missing Return | `BatchAPI.get()` declares return type `Future<Map<String, dynamic>>` but the method body never returns a value on any path — it either throws or falls through with implicit `null`. | Add `return response.data;` after the status check, or `return {};` in the catch. |
| 125 | 257–275 | **Critical** | Missing Return | Same as #124 for `ContextAPI.get()`. | Add return statements. |
| 126 | 82 | **Low** | Unused | `pageCounter` is set to 0 right before the loop, then used in the loop. But it's never read outside the loop for meaningful reporting. | Remove if unused after the method. |

---

### 9. `llm_api_service.dart` (221 lines)

This is the most clean file in the directory, but still has issues.

| # | Line(s) | Severity | Category | Description | Suggested Fix |
|---|---------|----------|----------|-------------|---------------|
| 127 | 164–181 | **Critical** | Type Mismatch | `streamChat()` declares return type `Stream<List<int>>` but the method body returns `dio.post(...).timeout(...).then(...)` which is a `Future<dynamic>`, not a `Stream`. The method cannot be implemented this way — you can't return a Future where a Stream is expected. | Use Dio's `ResponseType.stream` properly by returning the response stream: `final response = await dio.post(...); return response.data.stream;` or use `response.data` after setting `responseType: ResponseType.stream`. |
| 128 | 159 | **Low** | Lost Stack Trace | `throw Exception('Failed to connect to OpenRouter: $e');` — catches the original error and wraps it in a new `Exception`, losing the original stack trace. | Use `Error.throwWithStackTrace` or include the original error: `throw Exception('Failed: $e');` with `e` being the original. |

---

## Summary Statistics

| Metric | Count |
|--------|-------|
| **Critical** (compile errors, type mismatches, crashes) | 56 |
| **High** (functional bugs, wrong behavior) | 16 |
| **Medium** (logic bugs, error handling, design issues) | 34 |
| **Low** (code style, dead code, unused imports) | 22 |
| **Total** | **128** |

### Breakdown by File

| File | Lines | Critical | High | Medium | Low | Total |
|------|-------|----------|------|--------|-----|-------|
| `question_engine.dart` | 243 | 1 | 2 | 4 | 5 | 12 |
| `question_engine_dynamic.dart` | 80 | 2 | 1 | 6 | 1 | 10 |
| `lesson_scheduler_engine.dart` | 195 | 8 | 2 | 4 | 4 | 18 |
| `graph_type_detector.dart` | 194 | 3 | 0 | 5 | 2 | 10 |
| `graph_rendering_engine.dart` | 186 | 3 | 2 | 3 | 2 | 10 |
| `pdf_processing_service.dart` | 198 | 5 | 5 | 4 | 3 | 17 |
| `pdf_upload_coordinator.dart` | 241 | 18 | 4 | 4 | 2 | 28 |
| `batch_processor_service.dart` | 287 | 11 | 1 | 4 | 2 | 18 |
| `llm_api_service.dart` | 221 | 1 | 0 | 0 | 1 | 2 |

### Top Recommendations (Quick Wins)

1. **Fix all `Critical` issues** — 56 items that prevent compilation or cause crashes, concentrated in `pdf_upload_coordinator.dart` (18), `batch_processor_service.dart` (11), and `lesson_scheduler_engine.dart` (8).
2. **Install missing packages** — `graphing` and `charting_flutter` are imported but not in `pubspec.yaml`.
3. **Remove/rewrite `pdf_upload_coordinator.dart`** — This file has the highest defect density (28 issues in 241 lines), including 18 critical bugs. The code appears to be a mix of non-functional prototypes, pseudocode, and syntax errors. It should be largely rewritten.
4. **Standardize Dio usage** — Many files create separate `Dio()` instances. Centralize Dio configuration through dependency injection.
5. **Add proper error handling** — Several methods lack try/catch blocks, and many catch blocks just swallow errors without logging.

---

*Report generated by automated code analysis.*
