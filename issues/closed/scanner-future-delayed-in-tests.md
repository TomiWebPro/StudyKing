# [Scanner] Hardcoded `Future.delayed` in tests adds ~13s to wall-clock runtime

**Source:** automatic scanner
**Severity:** medium

## Finding

18+ instances of `Future.delayed(...)` across 8 test files add approximately **13 seconds** of real wall-clock delay to the test suite. These delays are used instead of `fake_async`, `FakeClock`, or `tester.runAsync` patterns, making tests slow and potentially flaky (timing-dependent).

## Locations

| File | Lines | Delay | Cumulative |
|---|---|---|---|
| `test/features/practice/services/practice_session_service_test.dart` | 148, 218, 232 | `Duration(milliseconds: 1100)` × 3 | 3.3s |
| `test/features/practice/services/practice_session_service_test.dart` | 224, 238 | `Duration(milliseconds: 500)` × 2 | 1.0s |
| `test/features/questions/presentation/widgets/canvas_drawing_widget_ui_test.dart` | 533, 553, 570, 591, 610, 641 | `Duration(seconds: 1)` × 6 | 6.0s |
| `test/features/questions/presentation/widgets/question_card_widget_test.dart` | 1216 | `Duration(seconds: 1)` | 1.0s |
| `test/features/subjects/providers/subjects_repository_provider_fake_repo_test.dart` | 44 | `Duration(seconds: 1)` | 1.0s |
| `test/features/subjects/providers/subjects_repository_provider_test.dart` | 49, 57 | `Duration(milliseconds: 10)` × 2 | 0.02s |
| `test/features/onboarding/presentation/onboarding_dialog_test.dart` | 869 | `Duration(milliseconds: 50)` | 0.05s |
| `test/features/mentor/presentation/mentor_screen_test.dart` | 145 | `responseDelay!` (variable) | Unknown |
| `test/integration/llm_tasks_ingestion_integration_test.dart` | 168, 195 | `Future.delayed(...)` × 2 | Unknown |

## Impact

- **Slow CI pipeline**: Adding 13+ seconds of forced waits to every test run across all developers and CI
- **Flakiness**: Timing-dependent tests can fail on slower CI runners or under load
- **Poor developer experience**: Developers must wait for real-time delays during `flutter test --watch` or pre-commit runs
- **Brittle assertions**: Tests that rely on exact timing may break when delays change

## Recommendation

- Use `fake_async` (from `package:fake_async`) for unit tests that need to simulate time passage — it advances time instantly without real delays
- For widget tests, use `tester.pump(Duration(...))` instead of `Future.delayed(Duration(...))` — pump advances the clock by the specified duration without waiting in real time
- For timer-dependent tests in practice_session_service_test.dart, inject a `Clock` dependency (the project already has `lib/core/utils/clock.dart`) so tests can use `FakeClock` instead of `Future.delayed`
- Keep `Future.delayed` only in integration tests where real timer behavior is being verified (and even there, prefer shorter delays)
