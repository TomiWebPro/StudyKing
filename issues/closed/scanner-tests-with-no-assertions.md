# [Scanner] Tests with empty try/catch and no assertions provide false confidence

**Source:** automatic scanner
**Severity:** major

## Finding

Several test files contain tests that wrap method calls in try/catch blocks with no `expect()` or `verify()` afterward. These tests pass even if the method throws, providing **zero regression protection**.

## Location 1: `test/core/services/notification_service_test.dart` (12 tests)

Lines 28–112 contain 12 tests that follow this pattern:

```dart
test('initialize does not throw', () async {
  try {
    await notificationService.initialize();
  } catch (_) {}  // ← silently swallows everything
  // ← NO expect() or assert() here
});
```

Every test in this file (except the last one at line 114) follows this pattern. They do NOT verify that:
- `initialize()` actually completed
- Any state changed
- No exceptions occurred

## Location 2: `test/core/services/voice_service_test.dart` (4 tests)

Lines 33, 42, 51, 75 follow the same "does not throw" try/catch pattern:
- `test('startListening does not throw', ...)`
- `test('stopListening does not throw', ...)`
- `test('isListening does not throw', ...)`
- `test('dispose does not throw', ...)`

While these have comments explaining the catch (plugin may not be available on test host), there is still **no assertion** — the test passes even if the method throws.

## Impact

- **False pass**: These tests always pass, even if the underlying code is completely broken
- **No regression detection**: If a developer introduces a bug that causes `initialize()` to throw, these tests will NOT catch it
- **Wasted test execution**: Running tests that can never fail consumes CI resources without providing value
- **Violates convention**: AGENTS.md requires that every catch log the error; these catches are completely silent

## Recommendation

- For `notification_service_test.dart`:
  - Remove the try/catch pattern entirely
  - Use `expect(notificationService.initialize(), completes)` to assert that the method completes without error
  - Add state-based assertions after each method call (e.g., verify `isInitialized` becomes true)
  
- For `voice_service_test.dart`:
  - Add `expect(methodCall, completes)` assertions instead of empty catches
  - If the plugin truly may not be available in tests, use `try { ... } on PlatformException catch (e) { _logger.w('Platform not available: $e'); }` with logging as required by convention

- General rule: Every test should have at least one assertion. If nothing can be asserted, the test should be removed.
