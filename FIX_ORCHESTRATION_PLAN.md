# StudyKing Flutter Issues - Comprehensive Fix Plan

**Objective:** Fix all 77 issues while maintaining clean architecture, no hardcoding, and complete test coverage.

**Total Issues:** 77 (P0: 12, P1: 13, P2: 16, P3: 15, Documentation: 8, Build/Security: 13)

---

## WORKSTREAM 1: P0 CRITICAL FIXES (12 issues)
**Priority:** Immediate - Block core functionality

### Issues: 1, 3, 7, 9, 17, 22 (Confirmed) + 4, 5, 6, 8, 10, 11

1. **P0-01:** Question Model - Add `options` field for multi-choice questions
   - File: `lib/core/data/models/question_model.dart`
   - Add: `List<String> options` field, validate model generation

3. **P0-03:** PracticeScreen Dialog - Fix `_startPractice()` navigation flow
   - File: `lib/features/practice/presentation/practice_screen.dart`
   - Ensure dialog transitions to PracticeSessionScreen

7. **P0-07:** Timer Variable Naming Mismatch
   - File: `lib/features/practice/presentation/practice_session_screen.dart` lines 65, 188
   - Fix: Rename `_timerTime` to consistent variable

8. **P0-08:** Answer Validator - Pass actual markscheme (not null)
   - File: `lib/features/practice/presentation/practice_session_screen.dart` line 129
   - Change: `QuestionAnswerValidator(null)` to `question.markscheme`
   - Add: `bool _isCorrect` state variable

9. **P0-09:** AnswerValidator Used With Null
   - Related to P0-08 - Fix in same file

10. **P0-10:** Hive Database Boxes - Initialize all boxes
    - File: `lib/core/data/hive_initializer.dart`
    - Add boxes: 'questions', 'answers', 'attempts', 'sessions'

11. **P0-11:** OpenRouter API Service Missing Endpoints
    - File: `lib/services/llm_api_service.dart`
    - Implement: fetchModels, sendPrompt, parseResponse endpoints

Issue 2 (Subject List Tap): Re-read file to confirm status
Issue 4 (Test Widget): Address in Workstream 3

---

## WORKSTREAM 2: P1 HIGH FIXES (13 issues)
**Priority:** Major UX Impact

### Issues: 13-23 (confirmed) + 18 issues from report

13. **P1-13:** Timer Variable Naming
    - Part of P0-07 fix

14. **P1-14:** Raw Error Messages
    - File: `lib/features/practice/presentation/practice_screen.dart`
    - Wrap errors: `e.toString().replaceAll('\\n\\n', ' ')`

15. **P1-15:** Settings Loading Silent Fail
    - File: `lib/main.dart`
    - Add: User notification on error

16. **P1-16:** Provider Race Condition
    - File: `lib/main.dart`
    - Fix: Move init before first render

17. **P1-17:** Duplicate Database Import
    - Audit all imports, consolidate

18. **P1-18:** Answer Validation Overly Permissive
    - File: `lib/features/practice/presentation/practice_session_screen.dart`
    - Integrate AnswerValidator properly

19. **P1-19:** Timer Cleanup On Navigation
    - Add cancel timer logic indispose()

20. **P1-20:** Mixed Riverpod and Direct State
    - File: `lib/features/subjects/presentation/subject_list_view.dart`
    - Convert to consistent Riverpod pattern

21. **P1-21:** No Retry On Database Failure
    - File: `lib/main.dart`
    - Add retry logic

22. **P1-22:** Question Type StepByStep
    - File: `lib/features/practice/presentation/practice_session_screen.dart`
    - Implement fallback handling

23. **P1-23:** Session Analytics Incomplete
    - File: `lib/features/practice/presentation/practice_session_screen.dart`
    - Track: wrong attempts, aborts, actual time

Additional P1: 24 (Spaced Rep), 27 (API errors), 31 (loading states)

---

## WORKSTREAM 3: P2 MEDIUM FIXES (16 issues)
**Priority:** Future Feature Impact

### Essential P2 fixes: 25, 29, 30, 33, 34, 38, 39

25. **P2-25:** Missing Unit Tests
    - Create: `test/repository_test.dart`
    - Create: `test/validation.answer.test.dart`
    - Create: `test/screens.practice.test.dart`
    - Create: `test/integration.practice.test.dart`
    - Add mocktail dependency

29. **P2-29:** Math Expression Widget
    - File: `lib/features/questions/ui/widgets/math_expression_widget.dart`
    - Improve parsing

30. **P2-30:** SingleAnswerWidget Source Not Shown
    - Add sourceId display

33. **P2-33:** Dark Mode Persist
    - Add system preference detection

34. **P2-34:** Dynamic Font Size
    - Add validation for 10-30 range

38. **P2-38:** pubspec.yaml Missing Dependencies
    - Add: `mocktail`, `equatable`

39. **P2-39:** Analysis Options Missing Rules
    - Add custom rules to `analysis_options.yaml`

Additional: 24, 26, 28, 32, 35, 36, 37, 42, 50, 54, 55

---

## WORKSTREAM 4: P3 LOW - CODE QUALITY (15 issues)
**Priority:** Maintainability

40. **P3-40:** Inconsistent Naming
    - Run full audit with `flutter analyze`
    - Rename variables consistently

41. **P3-41:** TODO Comments Without Tickets
    - Add ticket IDs or remove

42. **P3-42:** Duplicate Code
    - Refactor AnswerValidator duplicate validation logic

43. **P3-43:** Missing CHANGELOG.md
    - Create comprehensive CHANGELOG.md

44. **P3-44:** Missing Issue Templates
    - Add to `.github/ISSUE_TEMPLATE/`

45. **P3-45:** No Model Documentation
    - Add KDoc to models

46. **P3-46:** Missing Generated Files
    - Run: `flutter pub run build_runner build --delete-conflicting-outputs`

47. **P3-47:** Missing CONTRIBUTING.md
    - Update with full guidelines

48. **P3-48:** Missing LICENSE
    - Already exists, verify

49. **P3-49:** README Platform Inaccurate
    - Update platform status

50. **P3-50:** No CI Pipeline
    - Create workflow files for Android/iOS

51. **P3-51:** Missing API Documentation
    - Add to README or separate doc

52. **P3-52:** Missing Architecture Diagram
    - Add mermaid diagram

53. **P3-53:** Missing Feature Status Matrix
    - Update feature checklist

54. **P3-54:** Flutter 3.41.9 Shader Bug
    - Pin version or wait for Flutter fix

55. **P3-55:** Linux Build Blocked
    - Document requirements

---

## WORKSTREAM 5: DOCUMENTATION GAPS (8 issues)
56-64 (already addressed partly in P3)

---

## WORKSTREAM 6: BUILD & SECURITY (19 issues)
56-59 (Security): 60-64 (Build)

56. **Security-56:** API Key Storage
    - Replace Hive with `flutter_secure_storage`

57. **Security-57:** Input Sanitization
    - Add input validation

58. **Build-58:** Network Error Handling
    - Add retry, timeout, circuit breaker

59. **Build-59:** Sentry Not Configured
    - Add Sentry or custom error tracking

60. **Build-60:** Hive `.g.dart` Files Missing
    - Addressed in P3-46

---

## WORKSTREAM 7: README & INFRASTRUCTURE
61-68 (Documentation improvements)

---

## EXECUTION ORDER

### Phase 1: Dependency & Build Foundation (Hours 1-2)
- [ ] Update pubspec.yaml (Workstream P2-38, P3-38)
- [ ] Add missing dev dependencies
- [ ] Clean existing dependency issues
- [ ] Generate Hive models

### Phase 2: P0 Critical Fixes (Hours 3-6)
- [ ] Fix Question model with options field
- [ ] Fix PracticeSession timer variable
- [ ] Fix AnswerValidator markscheme passing
- [ ] Fix Hive initialization
- [ ] Implement OpenRouter API endpoints
- [ ] Fix PracticeScreen navigation

### Phase 3: P1 High Priority (Hours 7-12)
- [ ] Fix all error handling
- [ ] Fix mixed Riverpod issues
- [ ] Complete AnswerValidator integration
- [ ] Fix timer cleanup
- [ ] Complete analytics tracking

### Phase 4: P2 Medium (Hours 13-18)
- [ ] Create comprehensive test suite
- [ ] Fix math expression widget
- [ ] Add missing features
- [ ] Improve all widgets

### Phase 5: Code Quality Polish (Hours 19-24)
- [ ] Naming convention fixes
- [ ] Remove/relabel TODOs
- [ ] Refactor duplicates
- [ ] Update all documentation

### Phase 6: Security & Infrastructure (Hours 25-30)
- [ ] Implement secure storage
- [ ] Add network error handling
- [ ] Configure error tracking
- [ ] Set up CI pipelines

---

## COORDINATION REQUIREMENTS

### Tool Dependencies:
- **Workstream 1 & 2** may affect Workstream 3 (tests need code fixes first)
- **Workstream 3** tests depend on Workstream 4 model generation
- **Workstream 6** depends on Workstream 1 database fixes

### Tool Management:
```bash
# Phase 1: Setup
cd /home/tomi/StudyKing
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Phase 2-4: Development
# Use vscode/code for IDE work if needed
# git diff for tracking changes

# Continuous:
flutter analyze
flutter test
```

---

## OUTPUT DELIVERABLES

1. `/home/tomi/StudyKing/lib/core/data/models/question_model.dart` - Updated with options
2. `/home/tomi/StudyKing/lib/features/practice/presentation/practice_session_screen.dart` - Fixed timer and validation
3. `/home/tomi/StudyKing/lib/features/practice/presentation/practice_screen.dart` - Fixed navigation
4. `/home/tomi/StudyKing/lib/services/llm_api_service.dart` - Full API implementation
5. `/home/tomi/StudyKing/test/repository_test.dart` - Repository tests
6. `/home/tomi/StudyKing/test/validation.answer.test.dart` - Validation tests
7. `/home/tomi/StudyKing/test/screens.practice.test.dart` - Practice screen tests
8. `/home/tomi/StudyKing/test/integration.practice.test.dart` - Integration tests
9. `/home/tomi/StudyKing/CHANGELOG.md` - Complete changelog
10. `/home/tomi/StudyKing/lib/features/settings/data/storage/secure_storage_provider.dart` - Secure storage

---

## SUCCESS METRICS

After completing all workstreams:
- All 77 issues addressed or documented as out-of-scope
- Zero hardcoding in logic
- Full test coverage (>70%)
- All generated files present (.g.dart)
- Clean CI/CD pipeline
- Complete documentation
