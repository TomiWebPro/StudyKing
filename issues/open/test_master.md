# Critical Testing Gaps: Settings Feature & Service Layer Tests Are Surface-Level

## Context

The StudyKing project's testing infrastructure has **significant quality gaps** in the settings feature presentation layer and critical service tests. While surface-level widget rendering tests exist, they fail to validate core functionality, error handling, state management, and integration scenarios.

## Affected Files

### Settings Presentation Layer
- `lib/features/settings/presentation/settings_screen.dart` - 407 lines
- `lib/features/settings/presentation/profile_screen.dart`
- `lib/features/settings/presentation/api_config_screen.dart` - 184 lines

### Related Test Files (Surface-Level Only)
- `test/features/settings/presentation/settings_screen_test.dart` - 423 lines
- `test/features/settings/presentation/profile_screen_test.dart` - 435 lines
- `test/features/settings/presentation/api_config_screen_test.dart`
- `test/core.services.llm_service.test.dart` - 283 lines

### Key Services Needing Robust Tests
- `lib/core/services/llm_service.dart` - 449 lines
- `lib/core/services/pdf_ingestion_service.dart`
- `lib/core/services/adaptive_practice_engine.dart`

## Rationale

### 1. Settings Screen Tests - Widget-Only, No Logic Validation

**Current State**: Tests verify UI renders correctly but do NOT test:
- **API model selection** (`_showAiModelSelection`) - Makes real HTTP calls with timeout handling (lines 181-271)
- **Error handling** - Network failures, timeout exceptions, JSON parsing errors
- **State persistence** - Settings changes are not verified to persist
- **Validation logic** - Theme/font size bounds, timeout slider values (30-300 seconds)
- **Provider integration** - Settings state changes not verified through providers

**Gap**: The screen makes async HTTP requests to fetch AI models from OpenRouter API, but tests don't verify:
- Loading states during API calls
- Error dialogs on HTTP failures (status code != 200)
- Timeout handling (15-second timeout per line 217)
- Empty model list handling
- Model filtering/search functionality

### 2. Profile Screen Tests - Missing Critical User Flows

**Current State**: Tests verify form fields render, but don't test:
- **Profile persistence** - Saving profile doesn't verify data persists
- **Validation edge cases** - Student ID must be numeric only (test at line 247 shows expected error but doesn't test actual validation implementation)
- **Delete account flow** - No tests verify data is actually cleared
- **Language switch side effects** - Changing language has no tests for app-level effect

### 3. API Config Screen - No Tests for Critical Validation

**Current State**: Tests missing for:
- Empty API key validation (line 41-49 in source)
- Base URL format validation
- Save success/failure states
- Visibility toggle for password field
- Provider state updates after save

### 4. LLM Service Tests - Mock-Only Coverage

**Current State**: Tests only cover "empty API key" path (returns mocks). Missing:

| Scenario | Current Coverage |
|----------|------------------|
| Valid API key + HTTP 200 | Not tested |
| HTTP 401/403 auth errors | Not tested |
| HTTP 500 server errors | Not tested |
| JSON parse failures | Not tested |
| Ollama provider path | Not tested |
| Response structure variations | Not tested |
| Question/Lesson parsing edge cases | Not tested |

The service has 6 public methods generating questions, lessons, study plans, but tests only verify mock fallback behavior.

### 5. Missing Integration Tests

- Settings + LLM service integration (API key change triggers new service config)
- Settings + Profile persistence
- Quick Guide + LLM service
- Error states across feature boundaries

## Missing Test Scenarios

### SettingsScreen Priority Tests
1. **API Model Loading**: Test loading indicator appears during fetch, models populate correctly, search filters work
2. **Network Errors**: Test timeout dialog shows "Model request timed out", HTTP error shows "Unable to load models"
3. **Empty State**: Test empty API key shows warning dialog preventing model selection
4. **Slider Validation**: Test timeout slider clamps to 30-300 range, session duration shows only valid options
5. **State Verification**: Test that provider state actually updates after theme/font/timeout changes

### ProfileScreen Priority Tests
1. **Save Verification**: Test that save triggers repository call with correct data
2. **Validation Implementation**: Test numeric-only enforcement on student ID field
3. **Delete Verification**: Test account deletion clears all profile data

### LlmService Priority Tests
1. **HTTP Response Parsing**: Test `_parseQuestions`, `_parseLessonBlocks`, `_parseLesson` handle malformed JSON
2. **Provider Switching**: Test OpenRouter vs Ollama path selection
3. **Error Propagation**: Test API errors don't crash app, fallback to mocks works

## Acceptance Criteria

### Must Have (High Priority)
1. Add network error simulation tests to `settings_screen_test.dart` - test timeout, HTTP error responses
2. Add state verification tests - verify provider state changes after user interactions
3. Add API config validation tests - test empty key rejection, base URL handling
4. Expand `llm_service_test.dart` to cover HTTP response parsing, not just empty key fallback

### Should Have (Medium Priority)
5. Add integration tests for settings + profile save flow
6. Add tests for Quick Guide screen (help dialog, message flow, suggested prompts)
7. Add input validation edge case tests (extreme slider values, empty model list)

### Nice to Have (Lower Priority)
8. Add widget tests for error states (no network, API key invalid)
9. Add accessibility tests for settings screens
10. Add performance tests for screens with many items

## Priority

**HIGH** - Settings is a core user-facing feature with async operations, state management, and API integration. Current tests provide false confidence by checking only UI rendering, not business logic correctness.