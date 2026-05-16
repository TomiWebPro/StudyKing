# Test Coverage & Structural Gaps

## Summary

Despite near-100% file-level test coverage, several structural and qualitative issues undermine test maintainability and completeness.

---

## Issue 1: Duplicate SettingsController Test Files

**Affected Files:**
- `test/core/providers/app_providers_test.dart` (tests `SettingsController` with unsafe mock)
- `test/core/providers/settings_controller_test.dart` (tests same `SettingsController` with proper fake)

**Problem:**
Both files test the same `SettingsController` class from `lib/core/providers/app_providers.dart`. They use different fake/mock strategies and have inconsistent quality:

| Dimension | `app_providers_test.dart` | `settings_controller_test.dart` |
|---|---|---|
| Fake type | `_MockSettingsRepository` (no `implements`) | `_FakeSettingsRepository implements SettingsRepository` |
| Type safety | `mockRepo as dynamic` (unsafe) | Proper interface implementation |
| Assertions | Only checks repo was called | Asserts state change on controller |
| Error handling | Test with zero assertions | Validates state unchanged on error |

**Rationale:** Violates DRY—any change to `SettingsController` requires updating two test files. The `app_providers_test.dart` version is the weaker of the two and should be removed (or restructured to only test the pure `Provider` declarations, not `SettingsController`).

**Acceptance Criteria:**
- Only one test location for `SettingsController` exists
- The surviving test uses `implements SettingsRepository` (not `as dynamic`)
- All `updateXxx` methods verify controller state changed, not just that the repo was called
- Error cases assert state remains unchanged

---

## Issue 2: Missing Test Files for Constants

**Affected Files:**
- `lib/core/constants/app_constants.dart` → **no test** (should be `test/core/constants/app_constants_test.dart`)
- `lib/core/constants/llm_defaults.dart` → **no test** (should be `test/core/constants/llm_defaults_test.dart`)

**Rationale:** `app_constants.dart` defines `defaultModelForProvider` and other app-wide constants; `llm_defaults.dart` defines model pricing and configuration constants. Per `AGENTS.md` convention, every source file must have a companion test.

**Acceptance Criteria:**
- `test/core/constants/app_constants_test.dart` exists, covering `defaultModelForProvider` and exported constants
- `test/core/constants/llm_defaults_test.dart` exists, covering pricing/default configurations

---

## Issue 3: `clock.dart` Has No Dedicated Unit Test

**Affected Files:**
- `lib/core/utils/clock.dart` (8 lines: `Clock` abstract class + `SystemClock`)
- No file at `test/core/utils/clock_test.dart`

**Rationale:** `clock.dart` is used by at least 4 services (`teaching_providers`, `practice_session_service`, `conversation_manager`, `tutor_service`) through codebase trace. Its `Clock` abstraction is the standard mechanism for making time-based logic testable. Without a dedicated test, there is no guarantee that `SystemClock.now()` fulfills the contract.

**Acceptance Criteria:**
- `test/core/utils/clock_test.dart` exists
- Verifies `Clock` can be subclassed
- Verifies `SystemClock.now()` returns a `DateTime` close to real time (within tolerance)

---

## Issue 4: Test Placement Anomaly—`localization_helpers` Test in Wrong Directory

**Affected Files:**
- Source: `lib/core/utils/localization_helpers.dart`
- Test: `test/core/services/localization_service_test.dart`

**Rationale:** Per `AGENTS.md`, the test file for `lib/core/utils/localization_helpers.dart` should be at `test/core/utils/localization_helpers_test.dart`, not under `services/`. This causes confusion when developers search for tests by location convention.

**Acceptance Criteria:**
- Test file moved/content copied to `test/core/utils/localization_helpers_test.dart`
- Original `test/core/services/localization_service_test.dart` removed or replaced with a redirecting import comment

---

## Issue 5: Heavy Fake Pattern in Lesson Provider Tests

**Affected Files:**
- `test/features/lessons/providers/lesson_providers_test.dart`

**Problem:**
`_FakeLessonService` extends `LessonService`, which requires passing a full `DatabaseService` with **8 concrete repositories** to `super()`:

```dart
super(database: DatabaseService(
  topicRepository: TopicRepository(),
  questionRepository: QuestionRepository(),
  attemptRepository: AttemptRepository(),
  lessonRepository: LessonRepository(),
  sessionRepository: SessionRepository(),
  subjectRepository: SubjectRepository(),
  conversationRepository: ConversationRepository(),
  tutorSessionRepository: TutorSessionRepository(),
));
```

All 8 repositories are dead weight—every overridden method in the fake ignores them entirely. This pattern repeats across other fake/service test files. The fakes are fragile: if `DatabaseService` or `LessonService` constructors change, all fakes break even though no real behavior depends on those parameters.

**Accepted Criteria (for a targeted refactor):**
- `_FakeLessonService` (and similar fakes) should not depend on concrete `DatabaseService` construction
- Options: Extract a `LessonServiceBase` abstract class, or make the fake not extend the real class (just implement the same public interface)

---

## Issue 6: Orphan Test File `test/core/model_test.dart`

**Affected Files:**
- `test/core/model_test.dart`

**Problem:**
This file exists at `test/core/model_test.dart` but there is no corresponding source at `lib/core/model.dart`. It tests `main.dart` (app loading) and `QuestionModel` (which already has its own test at `test/core/data/models/question_model_test.dart`). This creates confusion about where tests live.

**Acceptance Criteria:**
- App loading test moved to a more appropriate location (e.g., `test/app_test.dart` or integrated into existing widget tests)
- `QuestionModel` tests removed from this file (already covered elsewhere)
- Orphan file deleted
