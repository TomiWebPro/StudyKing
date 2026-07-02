# [Scanner] Empty catch blocks in test files violate AGENTS.md convention

**Source:** automatic scanner
**Severity:** major

## Finding

24+ empty `catch (_) {}` blocks found across 8 test files. The AGENTS.md convention explicitly states: *"Empty `catch (_) {}` blocks are forbidden. Every catch must log the error with a descriptive message."*

These empty catches silently swallow exceptions, providing **false confidence** — tests will pass even when code throws, and no error is logged for debugging.

## Worst offender

`test/core/services/notification_service_test.dart` has **12 empty catch blocks** (lines 33, 40, 48, 55, 62, 69, 76, 83, 90, 97, 104, 111) — most without explanatory comments. These wrap tests that check "does not throw" behavior, but the empty catch means the test will pass regardless of what happens.

## All locations

| File | Lines | Count |
|---|---|---|
| `test/core/services/notification_service_test.dart` | 33, 40, 48, 55, 62, 69, 76, 83, 90, 97, 104, 111 | 12 |
| `test/core/services/voice_service_test.dart` | 37, 46, 55, 64, 79 | 5 (has comments but no logging) |
| `test/features/subjects/providers/subjects_repository_provider_test.dart` | 137, 155, 190, 268 | 4 |
| `test/features/settings/data/repositories/settings_repository_hive_test.dart` | 21, 24, 27 | 3 |
| `test/features/teaching/services/tutor_service_test.dart` | 337, 341 | 2 |
| `test/features/planner/services/planner_service_test.dart` | 279 | 1 |
| `test/features/planner/services/personal_learning_plan_service_test.dart` | 300 | 1 |
| `test/features/planner/providers/planner_providers_test.dart` | 402 | 1 |
| `test/features/subjects/providers/topic_repository_provider_test.dart` | 120 | 1 |
| `test/core/data/database_service_test.dart` | 191 | 1 |

## Impact

- Tests with empty catches and no `expect()` after them (notification_service_test.dart: 12 tests, voice_service_test.dart: 4 tests) **pass even when the method throws**, providing zero regression protection
- Silent failures go undetected during development and CI
- The `tearDownAll` cleanup catches (e.g., `Directory.delete`) are pragmatic but should at minimum log at `.w()` level

## Recommendation

- Replace each `catch (_) {}` with `catch (e, st)` and call the appropriate Logger method
- For expected error-path tests, use `expect(methodCall, throwsA(...))` instead of try/catch
- For tearDown cleanup catches, use `_logger.w('Cleanup failed: $e')`
- In `notification_service_test.dart`, rewrite the 12 no-assertion tests to actually verify behavior
