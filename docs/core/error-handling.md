# Error Handling

## Result Pattern

StudyKing uses a sealed `Result<T>` type (from `lib/core/errors/result.dart`) for all public repository and service method returns. **Exceptions are never thrown from public APIs.**

```dart
sealed class Result<T> {
  final T? data;
  final String? error;

  bool get isSuccess;
  bool get isFailure;

  S fold<S>(S Function(T data) onSuccess, S Function(String error) onFailure);
  Result<S> map<S>(S Function(T data) transform);
}
```

### Usage

```dart
// In a service
Future<Result<List<Question>>> getQuestions(String topicId) async {
  return Result.capture(() async {
    return await _repository.getByTopic(topicId);
  }, context: 'QuestionService.getQuestions');
}

// In a consumer
final result = await questionService.getQuestions(topicId);
if (result.isSuccess) {
  final questions = result.data!;
  // use questions
} else {
  showError(result.error!);
}
```

### Static Helpers

| Helper | Purpose |
|---|---|
| `Result.capture(fn, {context})` | Wraps async function, catches exceptions |
| `Result.captureSync(fn, {context})` | Wraps sync function, catches exceptions |
| `Result.success(data)` | Creates success result |
| `Result.failure(error)` | Creates failure result |

## Error Codifications

For spaced repetition errors, use `SpacedRepetitionErrorCode` from `lib/core/errors/spaced_repetition_error_codes.dart` instead of string literals.

## Throw Policy

- **`throw` is only allowed** in:
  - Private helper methods
  - Config validation at startup (e.g., invariant checks)
- **Never throw** from public API methods

## Logging

### Logger Conventions (`lib/core/utils/logger.dart`)

```dart
class MyService {
  static final Logger _logger = const Logger('MyService');

  Future<Result<void>> doSomething() async {
    try {
      // ...
    } catch (e) {
      _logger.w('Expected error path: $e');  // caught exception in expected path
    }
  }
}
```

Rules:
- All Logger instances must be `static final` at class level
- **Never** use inline `const Logger('Name').e(...)`
- `.e()` → unexpected exceptions requiring immediate investigation
- `.w()` → caught exceptions in expected error paths

## Error Boundaries

`lib/core/utils/error_boundary.dart` provides `ErrorBoundary` — a `StatefulWidget` that catches build-phase errors and displays a user-friendly fallback screen. Use it to wrap individual screens or widgets. `AppErrorWidgetBuilder` provides the default fallback UI used by the boundary.

## Empty Catch Rule

Empty `catch (_) {}` blocks are **forbidden**. Every catch must log the error with a descriptive message.
