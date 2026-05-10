# StudyKing - Current Issues & Remaining Tasks
**Date:** May 10, 2026  
**Status:** Alpha Beta - Functional foundation, critical gaps remain

---

## CRITICAL (Block User Flow) - P0

### 1. Single/Multi-Choice: markscheme used as options (line 434)
**File:** `lib/features/practice/presentation/practice_session_screen.dart`

```dart
final options = question.markscheme?.split(',').map((opt) => opt.trim())...
```

**Problem:** markscheme is the CORRECT answer, not the options list. Questions show "Option 1, Option 2" instead of actual choices.

**Impact:** Users cannot test multi-choice questions properly.

**Fix Required:** Question model needs dedicated `options: List<String>` field. Current QuestionModel has this at field 12, but it's not being read/displayed.

---

### 2. AnswerValidator initialized with null markscheme (line 133)
**File:** `lib/features/practice/presentation/practice_session_screen.dart`

```dart
final validationService = service ?? AnswerValidationService(QuestionAnswerValidator(null));
```

**Problem:** Validator always passes null to constructor, bypassing actual question.markscheme.

**Impact:** Answer validation returns "No markscheme available" error even when markscheme exists.

---

### 3. Test file checks wrong UI (test/widget_test.dart)
**Problem:** Test expects counter UI ("0", "1") which doesn't exist in StudyKing.

**Impact:** Test fails immediately, gives false CI/CD warnings.

---

## HIGH (Major UX Impact) - P1

### 4. Error messages show raw exceptions
**Files:** Multiple practice/screen files

```dart
SnackBar(content: Text('Failed to load subjects: $e'))
```

**Problem:** Full stack traces shown to users.

**Fix**: Use `_sanitizeErrorMessage()` helper to truncate stack traces.

---

### 5. Settings loading fails silently
**File:** `lib/main.dart`

```dart
} catch (e) {
  debugPrint('Error loading settings: $e');
  state = SettingsBox();  // No notification
}
```

**Problem:** User unaware settings failed to load.

**Fix**: Show SnackBar alert with Retry option.

---

### 6. Timer state variable mismatch (fixed but needs cleanup)
**File:** `lib/features/practice/presentation/practice_session_screen.dart`

**Problem:** `_startTimer()` calculates elapsed time but state redeclares `_timer` vars (lines 189-193) creating duplicate state.

**Impact:** Timer tracking may be inconsistent.

---

## MEDIUM (Future Feature Impact) - P2

### 7. Spaced Repetition Algorithm exists but not wired up
**File:** `lib/spaced_repetition/algorithm.dart`

**Status:** Algorithm implemented with interval-based review (1d, 6d, 27d).

**Problem:** UI shows "Spaced Repetition" mode but no cards are scheduled. Repository lacks spaced repetition queries.

**Impact:** Feature cannot be tested or used.

---

### 8. OpenRouter API Service complete but no workflow
**File:** `lib/services/llm_api_service.dart`

**Status:** Full implementation exists (fetch models, send prompts, parse responses).

**Problem:** No UI triggers API calls, no PDF ingestion workflow connected.

**Impact:** AI features inactive.

---

### 9. Dynamic font size not validated (10-30 range)
**File:** `pubspec.yaml` uses `google_fonts` but theme doesn't clamp values.

**Problem:** User can set font size too large/small, breaking UI layout.

---

### 10. No question analytics dashboard
**Problem:** Users cannot see accuracy trends, difficulty distribution, topic performance.

---

### 11. Session history has no export feature
**File:** `lib/features/sessions/presentation/session_history_screen.dart`

**Problem:** Users cannot export study logs for backup or review.

---

## LOW (Maintainability) - P3

### 12. CHANGELOG.md missing
**Problem:** Contributors cannot track changes across versions.

---

### 13. TODO comments lack ticket IDs
**Problem:** Comments like "// TODO: implement filtering" have no ticket reference.

**Fix**: Add [T001] style references or remove comments.

---

### 14. README platform claims inaccurate
**Problem:** README says iOS/Desktop "work in progress" but app doesn't build for these platforms.

**Fix**: Update platform support section to reflect reality.

---

### 15. No CONTRIBUTING.md improvements
**Missing:** Code of conduct, PR checklist, build requirements per platform.

---

## BUILD ISSUES

### 16. Flutter 3.41.9 shader compilation bug
**Impact:** Web build blocked until Flutter engine fix.

**Workaround:** Use GitHub Actions CI pipeline.

---

### 17. Linux build requires sudo for build-essential
**Problem:** Cannot install clang/build-essential tools.

**Workaround:** Use GitHub CI for native builds.

---

## SUMMARY

| Category | Issues | Status |
|----------|--------|--------|
| P0 Critical | 3 | Needs fix before beta |
| P1 High | 4 | UX blocking, fix soon |
| P2 Medium | 6 | Feature impact, fix in sprint |
| P3 Low | 4 | Maintainability, fix when time |
| Build Issues | 2 | Platform limitations |

**Total:** ~20 prioritized issues (from original 77, grouped and deduplicated)

---

## RECOMMENDED ACTIONS

### Before Beta Release
1. Fix single/multi-choice options display (P0-1)
2. Wire up markscheme to validator (P0-2)
3. Rewrite test/widget_test.dart (P0-3)

### Short-term (Next Sprint)
4. Add error message sanitization (P1-1)
5. Show settings load errors (P1-2)
6. Complete timer state cleanup (P1-3)
7. Add spaced repetition repository queries (P2-1)

### Medium-term
8. Build analytics dashboard (P2-5)
9. Add export feature to sessions (P2-6)
10. Complete OpenRouter workflow integration (P2-2)

---

**File Location:** `/home/tomi/StudyKing/STUDYKING_CURRENT_ISSUES.md`
