# Code Refactor: Orphaned Components & Dead Code (~1,400 lines)

## Context

The codebase contains multiple large component files that are defined, exported in barrel files, or instantiated but **never imported or referenced anywhere** outside their own definition. This adds cognitive overhead, increases build times, and signals incomplete or abandoned features. Additionally, several screens instantiate services with **hardcoded empty configuration** while the settings system already stores the correct values — the providers exist but are never read by the consumers.

---

## Affected Files

### Dead/Orphaned Components

| File | Lines | Status |
|------|-------|--------|
| `lib/features/practice/presentation/learning_plan_dashboard.dart` | 447 | `LearningPlanDashboard` widget defined but never imported. Not exported from `practice.dart` barrel. |
| `lib/features/practice/presentation/analytics_dashboard.dart` | 627 | `AnalyticsDashboard` widget defined but never imported. Not exported from `practice.dart` barrel. |
| `lib/features/subjects/presentation/subject_management_screen.dart` | 297 | Nearly identical to `SubjectSelectionScreen`. Never imported or routed to. |
| `lib/features/teaching/services/conversation_manager.dart` (lines 345–357) | 13 | `AdaptiveMetrics` class defined but never instantiated or referenced. |
| `lib/features/questions/ui/widgets/math_expression_widget.dart` (lines 386–415) | 30 | `FormulaWidget` defined alongside `MathExpressionWidget` but never exported or imported. |
| `lib/core/constants/app_features.dart` | 20 | `FeatureFlagService` and `AppFeature` enum defined but never referenced anywhere. |

### Hardcoded LLM Configuration (bypasses settings)

| File | Lines | Issue |
|------|-------|-------|
| `lib/features/mentor/presentation/mentor_screen.dart` | 41–44 | `apiKey: ''` hardcoded instead of reading `apiKeyProvider`. Also `studentId: 'anonymous'` hardcoded at line 58. |
| `lib/features/teaching/presentation/tutor_screen.dart` | 59–62 | `apiKey: ''` hardcoded instead of reading `apiKeyProvider`. |
| `lib/features/quickguide/presentation/quick_guide_screen.dart` | 72–75 | `apiKey: ''` hardcoded instead of reading `apiKeyProvider`. |
| `lib/features/practice/presentation/practice_session_screen.dart` | 260 | `studentId: 'anonymous'` hardcoded instead of using `StudentIdService`. |

---

## Rationale

1. **Dead code misleads developers** — New contributors or AI-assisted workflows see `LearningPlanDashboard` and `AnalyticsDashboard` in the file tree and assume they are functional. Time is wasted investigating why features don't appear or why changes to these files have no effect.

2. **Hardcoded empty API key silently degrades all AI features** — The `apiKeyProvider` at `lib/core/providers/app_providers.dart:162` stores the user's configured key, but the three consumer screens (`MentorScreen`, `TutorScreen`, `QuickGuideScreen`) recreate `LlmConfiguration` with `apiKey: ''`. The `LlmService` falls back to mock data, making AI tutoring, mentoring, and quick-guide features non-functional despite a valid key being saved in settings.

3. **Hardcoded `studentId: 'anonymous'`** — Two screens hardcode `'anonymous'` as the student ID instead of using `StudentIdService().getStudentId()`. This means all student-level data (practice sessions, mentor conversations) is stored under an unidentifiable user, making per-student analytics useless.

4. **Configuration logic is duplicated** — The same 4-line LLM initialization block (`LlmConfiguration` → `LlmService`) is replicated across 3 screens. Any change (e.g., adding a new provider option, changing the default model) must be made in 3 places.

---

## Acceptance Criteria

1. [ ] Remove or archive the 6 dead/orphaned components (or re-integrate if features are planned):
   - `learning_plan_dashboard.dart` (447 lines)
   - `analytics_dashboard.dart` (627 lines)
   - `subject_management_screen.dart` (297 lines)
   - `AdaptiveMetrics` class in `conversation_manager.dart` (13 lines)
   - `FormulaWidget` in `math_expression_widget.dart` (30 lines)
   - `FeatureFlagService` / `AppFeature` enum in `app_features.dart` (20 lines)

2. [ ] In `mentor_screen.dart`, `tutor_screen.dart`, and `quick_guide_screen.dart`: replace the hardcoded `apiKey: ''` with `ref.read(apiKeyProvider)` (or inject via constructor / service locator).

3. [ ] In `mentor_screen.dart` (line 58) and `practice_session_screen.dart` (line 260): replace `studentId: 'anonymous'` with `StudentIdService().getStudentId()`.

4. [ ] Extract LLM initialization into a shared factory/util function or provider to eliminate the copy-paste across 3 screens.

5. [ ] Verify no regressions: run `flutter analyze` with zero new warnings, and confirm that the settings screen's API key field actually propagates to the AI screens.
