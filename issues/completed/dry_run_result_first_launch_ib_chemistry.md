# Dry-Run Issue: First Launch — Learning IB Chemistry

**Source:** `dry-run-test/scenario_first_launch_ib_chemistry.md`
**Validated:** 2026-05-19
**Overall completion:** ~59% — below 80% threshold. Issue file retained.

---

## Remaining Issues by Step

### Step 1: First Launch (PARTIAL, ~70%)

| # | Issue | Severity | Files |
|---|---|---|---|
| 1.1 | Onboarding dialog doesn't mention that AI features require an API key | medium | `lib/features/onboarding/presentation/onboarding_dialog.dart:136-168` |
| 1.2 | Onboarding doesn't suggest a specific first action (e.g. "Add a subject") | low | same file |

---

### Step 2: Adding a Subject (PARTIAL, ~50%)

| # | Issue | Severity | Files |
|---|---|---|---|
| 2.1 | No pre-built syllabus database for common curricula (IB, A-Levels, AP, GCSE, etc.) | high | `lib/features/subjects/presentation/subject_form_widgets.dart` — plain `TextFormField`, no autocomplete |
| 2.2 | No auto-complete suggestions when typing subject name or syllabus | medium | same file |
| 2.3 | Subject's `syllabus` field is a free-text `String?` — no structured syllabus data model | medium | `lib/core/data/models/subject_model.dart:3` |

---

### Step 3: Planner — "Learn IB Chemistry in 90 days" (PARTIAL, ~60%)

| # | Issue | Severity | Files |
|---|---|---|---|
| 3.1 | Empty-mastery fallback (`_buildEmptyMasteryPlan`) generates synthetic `topicId` values (`'generated_${day}_$studentId'`) with no connection to real DB topics | high | `lib/core/services/personal_learning_plan_service.dart:269` |
| 3.2 | `subjectId` is empty string `''` in generated `PlannedTopic` — no link to any real subject | high | `lib/core/services/personal_learning_plan_service.dart:278` |
| 3.3 | When mastery data exists, `courseName` is completely ignored for plan content (only checked at line 132) | medium | `lib/core/services/personal_learning_plan_service.dart:144+` |
| 3.4 | Planner validates subject+topics exist but doesn't guide user to add topics when none exist | low | `lib/features/planner/presentation/planner_screen.dart:240-249` |

---

### Step 4: Upload — Auto-Generation (NOT_COMPLETED, ~30%)

| # | Issue | Severity | Files |
|---|---|---|---|
| 4.1 | **Router creates `UploadScreen` without a `pipeline` parameter** — `widget.pipeline` is always `null` in normal navigation, so the entire full-pipeline branch is dead code | **critical** | `lib/core/routes/app_router.dart:167-175` |
| 4.2 | Upload falls through to bare `_sourceRepo.create(source)` — no text extraction, no classification, no summary, no question generation, no lesson generation | **critical** | `lib/features/ingestion/presentation/upload_screen.dart:293-307` |
| 4.3 | Full pipeline is only accessible via Source Detail -> "Reprocess" — hidden 2-step workflow unknown to new users | high | `lib/features/ingestion/presentation/source_detail_screen.dart:155-172` |
| 4.4 | Settings "My Uploads" navigates to Content Library, not Upload screen — no direct upload route from Settings | low | `lib/features/settings/presentation/settings_screen.dart:167-168` |
| 4.5 | UploadScreen should read `contentPipelineProvider` directly (or router should inject one) to make "Upload & Analyze" work as advertised | high | `lib/features/ingestion/presentation/upload_screen.dart:212` |

---

### Step 5: API Key — AI Feature Setup (PARTIAL, ~50%)

| # | Issue | Severity | Files |
|---|---|---|---|
| 5.1 | **QuickGuide silently falls back to canned responses when no API key** — zero user-facing indication that AI isn't working; user can interact indefinitely thinking the app is "dumb" | **critical** | `lib/features/quickguide/presentation/quick_guide_screen.dart:125-128` |
| 5.2 | Onboarding doesn't mention API keys or AI configuration | medium | `lib/features/onboarding/presentation/onboarding_dialog.dart:136-168` |
| 5.3 | `LlmChatService.chatStream()` silently returns empty stream when API key is empty — no error emitted | medium | `lib/core/services/llm/llm_chat_service.dart:84-85` |

---

### Step 7: Dashboard Progress Guidance (PARTIAL, ~50%)

| # | Issue | Severity | Files |
|---|---|---|---|
| 7.1 | Checklist has no completion state tracking — same 4 items shown regardless of user progress; no checkmarks, no "X of 4" counter | medium | `lib/features/dashboard/presentation/widgets/empty_dashboard_checklist.dart` |
| 7.2 | No "next step" visual emphasis — all 4 items are identically styled; no "Start Here" badge, no numbering, no highlighting | low | same file |
| 7.3 | Binary state transition: checklist → full 12-card dashboard with no intermediate partial-progress state | medium | `lib/features/dashboard/presentation/dashboard_screen.dart:80-103` |
| 7.4 | `NextUpCard` hides itself when zero data — invisible precisely when most useful | low | `lib/features/dashboard/presentation/widgets/next_up_card.dart:40` |

---

## Completed Items (no action needed)

These concerns from the original scenario are resolved in current code:

- ✅ Onboarding dialog EXISTS (was missing) — `lib/main.dart:427-439`
- ✅ Checklist items ARE tappable (were static) — `lib/features/dashboard/presentation/widgets/empty_dashboard_checklist.dart:76-77`
- ✅ Post-creation upload prompt exists — `lib/features/subjects/presentation/subject_selection_screen.dart:104-120`
- ✅ Course parameter IS passed to plan generation — `lib/features/planner/services/planner_service.dart:118`
- ✅ Empty-mastery plan generates non-empty days with topic names — `lib/core/services/personal_learning_plan_service.dart:231-319`
- ✅ Upload accessible from 10+ entry points — `lib/features/ingestion/presentation/upload_screen.dart`
- ✅ ApiKeyBanner shown after onboarding — `lib/main.dart:442-450`
- ✅ Mentor shows inline error for missing API key — `lib/features/mentor/presentation/mentor_screen.dart:203-219`
- ✅ Settings > AI Model shows API key dialog — `lib/features/settings/presentation/settings_screen.dart:514-534`
- ✅ Lesson scheduling auto-generates content — `lib/features/planner/services/planner_service.dart:292-341`
- ✅ "Start Tutoring" one-tap button exists — `lib/features/planner/presentation/widgets/daily_plan_card.dart:147-153`

---

## Priority Order for Fixes

1. **Critical:** Upload pipeline not triggered (4.1, 4.2) — Router must inject pipeline or UploadScreen must use `contentPipelineProvider`
2. **Critical:** QuickGuide silent fallback (5.1) — Must warn user about missing API key instead of silently returning canned responses
3. **High:** Empty-mastery plan generates disconnected data (3.1, 3.2) — Synthetic topic IDs and empty subjectId
4. **High:** UploadScreen should trigger pipeline (4.5) — Make "Upload & Analyze" work as advertised
5. **High:** No syllabus database (2.1) — Pre-built curricula for IB, A-Levels, AP, etc.
6. **Medium:** API key not mentioned in onboarding (1.1, 5.2)
7. **Medium:** Course name ignored when mastery data exists (3.3)
8. **Medium:** Checklist lacks progress tracking (7.1)
9. **Medium:** No autocomplete for subject creation (2.2)
10. **Low:** Binary dashboard state transition (7.3), NextUpCard hidden (7.4), planner validation guidance (3.4), Settings upload route (4.4)
