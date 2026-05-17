# Future Functionality Plan: Vision Gaps & Next Development Phase

## Context

Comprehensive audit comparing the product vision (agent_must_read.md) against the actual implementation across ~150 source files. The codebase has strong foundations (Riverpod state management, Hive persistence, LLM service abstraction, CanvasDrawingWidget, VoiceController, MathExpressionWidget, LlmTaskManager, full question/attempt lifecycle). However, critical vision features are missing, stubbed, or architecturally blocked.

**User-reported issues (further_issues directory):** None found — this analysis is based on vision-vs-implementation gap analysis.

---

## BLOCKER — App cannot proceed or crashes

### B1. Image capture in TutorScreen stubbed as "Coming Soon"

**Context:** `TutorScreen._pickImage()` (line 133) shows a SnackBar with `comingSoon` instead of implementing vision-based student work interpretation. The vision requires the AI tutor to "interpret handwritten work" and provide "vision-based interpretation of student work."

**Affected files:**
| File | Change |
|---|---|
| `lib/features/teaching/presentation/tutor_screen.dart:133-136` | Replace stub with actual image capture → OCR → LLM interpretation flow |
| `lib/features/teaching/services/conversation_manager.dart` | Add `processImage()` method that passes image data to LLM with appropriate system prompt |
| `lib/core/data/extraction/ocr_extractor.dart` | Requires real OCR pipeline (see B2) |

**Rationale:** This is the #1 student-facing gap between the vision and reality. A student in a live tutoring session who tries to show their work to the AI tutor gets a dead-end.

**Acceptance criteria:**
1. `_pickImage()` opens camera / gallery picker and passes the image to `ConversationManager.processImage()`
2. The LLM receives the image with context: "The student has submitted this work. Analyze it and provide feedback."
3. The response appears in the chat flow
4. Existing image_picker dependency is reused (no new packages needed)

---

### B2. OCR pipeline 100% dependent on LLM vision — no fallback and fails silently

**Context:** `OcrExtractor` delegates ALL OCR to the LLM via `_extractWithLlm()`. When the LLM model lacks vision capabilities (most text-only models), or when the API key is missing, it silently returns `OcrExtractionResult(text: '', extractionMethod: 'llm_not_available')`. The `DocumentExtractor._extractImage()` then returns this empty result, and the pipeline continues with empty text — losing the content entirely with no user feedback.

Additionally, `_extractWithLlm()` passes `modelId: ''` (empty string) which is likely invalid for most providers.

**Affected files:**
| File | Line(s) | Issue |
|---|---|---|
| `lib/core/data/extraction/ocr_extractor.dart` | 107-150, 125 | Empty `modelId` passed to `_llmService.chat()` |
| `lib/core/data/extraction/ocr_extractor.dart` | 47-51 | Silent empty return when no LLM available |
| `lib/features/ingestion/services/document_extractor.dart` | 147-178 | Image extraction silently continues with empty text |
| `lib/core/services/llm/llm_chat_service.dart` | 53-54 | Empty apiKey returns '' silently — no error surfaced |

**Fix:**
1. Pass a real `modelId` to `_llmService.chat()` in OcrExtractor (use vision-capable model)
2. When LLM is unavailable or returns empty, show user-facing error via `Result.failure()` instead of silent empty text
3. Consider adding Tesseract OCR as local fallback (or at minimum, show a clear error message)

**Acceptance criteria:**
1. Uploading an image without a vision-capable LLM shows a clear error to the user
2. Uploading an image with a vision-capable LLM returns extracted text
3. The `modelId` passed to the LLM is not empty

---

## MAJOR — Features broken, misleading, or critically incomplete

### M1. Proactive engagement notifications only fire while app is running

**Context:** `EngagementScheduler` uses `Timer` (line 80: `Timer(_config.nextCheckDelay, _runDailyChecks)`) which is tied to the app's process lifecycle. When the app is backgrounded or killed, no notifications fire. The vision states: "The system should proactively engage students with reminders, prompts, revision nudges, lesson notifications, accountability messaging, and practice encouragement" — implying 24/7 engagement capability.

**Affected files:**
| File | Issue |
|---|---|
| `lib/core/services/engagement_scheduler.dart:80` | Timer-based scheduling lost on app close |
| `lib/main.dart:84-99` | Scheduler created per-launch but no background/headless task |
| `pubspec.yaml:62` | `flutter_local_notifications` present but used only for foreground-triggered notifications |

**Fix:** Implement platform-specific background scheduling:
1. Use `workmanager` or `android_alarm_manager` for Android background checks
2. On iOS, use BGTaskScheduler via platform channels
3. Store last-check timestamp in Hive so the scheduler can catch up on app launch
4. The EngagementScheduler's init() should check time since last check and fire missed nudges

**Acceptance criteria:**
1. Nudge checks run at least once every 24h even when app is closed (platform-dependent)
2. On app reopen after >24h, missed nudges are caught up within 60 seconds
3. No new external dependencies beyond workmanager or native platform scheduling

---

### M2. Multi-syllabus simultaneous learning has zero implementation

**Context:** The vision requires: "The system should allow a student to learn and track from multiple syllabi simultaneously. Lessons are for one syllabus. A relative remaining lesson count should be given by the system towards mastery." Currently:
- `PersonalLearningPlan` has `syllabusGoals` field but `SyllabusGoal` is not a Hive-registered type
- `PlannerService.generatePlan()` accepts a single `course` string, not multiple syllabi
- `DashboardService` computes per-student stats, not per-syllabus
- No `RemainingWorkloadEstimator` exists

**Affected files:**
| File | Change |
|---|---|
| `lib/features/planner/data/models/personal_learning_plan_model.dart` | `SyllabusGoal` needs Hive TypeAdapter registration |
| `lib/features/planner/services/planner_service.dart` | `generatePlan()` must accept `List<String> syllabi` |
| New: `lib/core/services/remaining_workload_estimator.dart` | New service (was planned in Phase 4.2 of previous planner) |
| `lib/features/dashboard/services/dashboard_service.dart` | Add per-syllabus stats aggregation |
| `lib/features/dashboard/providers/dashboard_data_providers.dart` | Surface per-syllabus data |

**Rationale:** This is the second-most-requested feature in the vision document and completely absent. It blocks the core value proposition of "learn multiple subjects simultaneously" that differentiates StudyKing from single-subject tools.

**Acceptance criteria:**
1. User can add multiple syllabi/goals to a single learning plan
2. PlannerService.generatePlan() accepts multiple syllabi
3. Dashboard shows per-syllabus AND combined stats
4. `RemainingWorkloadEstimator` computes "lessons remaining to mastery" per topic
5. Existing plan migration: old single-syllabus plans continue to work

---

### M3. 5 question types defined in enum but completely unusable

**Context:** `QuestionType` enum defines 14 values but only 5 have any implementation downstream:

| QuestionType | Answer UI | Validation | Used in practice? |
|---|---|---|---|
| `singleChoice` | ✅ Yes | ✅ Yes | ✅ Yes |
| `multiChoice` | ✅ Yes | ✅ Yes | ✅ Yes |
| `typedAnswer` | ✅ Yes | ✅ Yes | ✅ Yes |
| `canvas` | ✅ Yes | ✅ Yes | ✅ Yes |
| `mathExpression` | ✅ Yes | ✅ Yes | ✅ Yes |
| `essay` | ❌ No | ❌ No | ❌ No |
| `stepByStep` | ❌ No | ❌ No | ❌ No |
| `graphDrawing` | ❌ No | ❌ No | ❌ No |
| `fileUpload` | ❌ No | ❌ No | ❌ No |
| `audioRecording` | ❌ No | ❌ No | ❌ No |

The `AnswerValidationService` doesn't handle these types. The `PracticeSessionQuestionCard` doesn't render them. The `QuestionGenerationService` never generates them.

**Affected files:**
| File | Issue |
|---|---|
| `lib/core/services/answer_validation_service.dart` | Missing cases for essay, stepByStep, graphDrawing, fileUpload, audioRecording |
| `lib/features/practice/presentation/widgets/practice_session_question_card.dart` | Missing rendering for these types |
| `lib/features/questions/presentation/widgets/question_card_widget.dart` | Missing rendering for these types |

**Fix:** Either implement these types or deprecate them in the enum. Priority order based on vision: `essay` (needed for written responses), `stepByStep` (needed for math/science tutoring), `graphDrawing` (needed for scientific charts).

**Acceptance criteria:**
1. Each unused QuestionType either has a basic rendering widget + validation OR is removed from the enum
2. At minimum, `essay` type should have a textarea input with basic validation
3. `answer_validation_service.dart` does not crash with `UnimplementedError` for any QuestionType

---

### M4. Mentor's `suggestNextAction()` returns hardcoded English messages — no AI intelligence

**Context:** `MentorService.suggestNextAction()` (lines 533-554) returns hardcoded strings like "You haven't added any subjects yet..." and "You're doing well!...". The vision expects the AI mentor to "help with deciding what to study next, adjusting study pacing, creating new courses or subject plans." The current implementation bypasses the LLM entirely.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/mentor/services/mentor_service.dart` | 533-554 | Hardcoded responses |
| `lib/features/mentor/services/mentor_service.dart` | 232-234 | System prompt hardcoded English (also noted in internationalisation_master.md) |

**Fix:**
1. `suggestNextAction()` should compose an LLM prompt with current student context (weak topics, adherence, recent sessions) and return an AI-generated recommendation
2. Use the same `_buildContextPrompt()` pattern already used in `chat()`

**Acceptance criteria:**
1. `suggestNextAction()` uses the LLM to generate a contextual recommendation
2. The recommendation considers weak topics, plan adherence, and recent activity
3. Falls back gracefully if LLM is unavailable (cache last recommendation)

---

### M5. `StudyProgressTracker` ignores TutorSession and FocusMode data for study hours

**Context:** `StudyProgressTracker.getOverallStats()` (line 24-50) computes stats exclusively from `AttemptRepository` (practice question attempts). It does NOT include:
- Tutor lesson durations (hours spent in teaching mode)
- Focus mode sessions (hours spent in focused study)
- This means the dashboard's "total study time" and "accuracy" metrics are incomplete: they only reflect practice, not actual total learning time

The `SessionRepository` (which tracks all session types) is never consulted.

**Affected files:**
| File | Issue |
|---|---|
| `lib/core/services/study_progress_tracker.dart` | Only uses `AttemptRepository` for stats |
| `lib/features/dashboard/services/dashboard_service.dart` | `getOverallStats()` calls `_progressTracker` which returns incomplete data |

**Fix:**
1. Inject `SessionRepository` into `StudyProgressTracker`
2. Merge session durations into totalStudyTimeHours
3. Include focus mode and tutor session time in activity counts

**Acceptance criteria:**
1. `getOverallStats().totalStudyTimeHours` includes tutor lesson time and focus mode time
2. Dashboard shows accurate total study time (previously it only reflected practice time)
3. No double-counting across overlapping data sources

---

### M6. `LlmTaskManagerScreen` inaccessible from app UI — users cannot see token usage

**Context:** The `LlmTaskManagerScreen` is a fully functional UI (327 lines of polished Flutter) that shows running tasks, token usage, cost, and completion status. However, there is **no navigation entry** to reach it. The screen is registered in `app_router.dart` at `AppRoutes.llmTasks` but has no button, menu entry, or deep link in the app. A user can never see their AI token consumption or active inference tasks.

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart` | Complete UI — never reachable |
| `lib/core/routes/app_router.dart:226-229` | Route registered but no UI entry point |
| `lib/features/settings/presentation/settings_screen.dart` | Should have an entry like "AI Task Monitor" or similar |

**Fix:**
1. Add a "Token Usage / Task Monitor" tile in Settings screen
2. Consider a mini-indicator in the app bar when tasks are running

**Acceptance criteria:**
1. User can navigate to `LlmTaskManagerScreen` from Settings or a developer menu
2. The screen shows real task data (tokens used, cost, status)
3. Active task indicator is visible somewhere (e.g., settings gear badge)

---

### M7. `VoiceController` and `FlutterTts` hardcoded to English locale

**Context:** `VoiceController.startListening()` uses `localeId: 'en_US'` (line 94), and `VoiceController.speak()` uses `setLanguage('en-US')` (line 118). The app supports Spanish, but voice interaction will always be English regardless of the user's selected UI language.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/teaching/services/voice_controller.dart` | 94, 118 | Hardcoded `en_US` / `en-US` |

**Fix:**
1. Add an optional `localeName` parameter to `VoiceController`
2. Map `AppLocalizations.localeName` to the appropriate `localeId` for speech recognition
3. Map locale to TTS language code with fallback to `en-US`

**Acceptance criteria:**
1. VoiceController respects user's selected language for speech recognition
2. TTS speaks in the user's selected language
3. Fallback to English if the locale is not supported by the platform speech engine

---

## MINOR — Code quality, UX friction, or technical debt

### m1. `DataBackupService` has no restore function and no Settings UI entry

**Context:** `DataBackupService` exists (42 lines) but only does manual export to temp directory. There is no `importBackup()`/`restoreData()` method, no file picker for restore, no Settings screen entry for backup/restore.

**Affected files:**
| File | Change |
|---|---|
| `lib/core/services/data_backup_service.dart` | Add `restoreData()` method |
| `lib/features/settings/presentation/settings_screen.dart` | Add "Backup & Restore" section |

**Acceptance criteria:**
1. User can export all Hive data to a portable JSON file via Settings
2. User can import/restore from a previously exported file
3. Restore warns about data overwrite

---

### m2. `FocusTimerScreen` study sessions not tracked in study progress

**Context:** Focus mode sessions are tracked in `SessionRepository` but `StudyProgressTracker` never reads them. Focus mode time "disappears" from progress statistics.

**Fix:** Add `SessionRepository` data to `StudyProgressTracker.getOverallStats()` (same as M5, but a smaller subset: just add focus session durations).

---

### m3. Dashboard only accessible via FAB — hidden discovery

**Context:** The dashboard is accessible only through a `FloatingActionButton.small` in the `MainScreen` (lines 331-335, 373-379). On wide screens it's a NavigationRail leading action; on mobile it's a floating button. No bottom navigation tab, no gesture, no keyboard shortcut.

**Fix:** Consider adding a Dashboard tab to the bottom navigation bar or at minimum ensuring the FAB is always visible and has a clear label.

---

### m4. Three test files contain only barrel-export type checks (as noted in test_master.md)

Already documented in `issues/open/test_master.md` Issue 2. Not duplicating details here, but flagging that these incomplete tests reduce confidence in refactoring.

---

## Dependency Graph & Ordering

```
Phase 1 — Fix BLOCKERS (immediate)
├── B1 + B2: Image capture in tutor + OCR pipeline
│   └── Unblocks: student work submission during lessons
│
Phase 2 — Critical MAJOR features
├── M1: Background notification scheduling
├── M2: Multi-syllabus support + RemainingWorkloadEstimator
├── M3: Unused question types (implement or deprecate)
├── M4: AI-powered mentor suggestions
│
Phase 3 — Data accuracy & UI completeness
├── M5: StudyProgressTracker includes all session types
├── M6: LLM Task Manager accessibility in UI
├── M7: VoiceController locale support
│
Phase 4 — Polish
├── m1: Data backup/restore
├── m2: Focus mode tracking
├── m3: Dashboard discovery
├── m4: Test quality improvements
```

## Rationale Summary

The codebase has evolved substantially since the first `future_functionality_planner.md` (now in `issues/completed/`). The dual-model consolidation (Phase 1 of the previous plan) has been addressed — `TopicReadinessService`, `DashboardService`, and `DataBackupService` now exist. The LLM task manager and usage meter are properly wired.

The critical remaining gaps are:

1. **Vision-interaction gap:** The tutor cannot see or interpret student work (B1/B2). This is the #1 feature the vision promises that the app cannot deliver.
2. **Proactive engagement gap:** The app cannot reach the student when closed (M1). The vision promises a "persistent mentor" but it only exists while the app is open.
3. **Multi-subject learning gap:** The vision's core claim — "learn and track from multiple syllabi simultaneously" — has no implementation (M2).
4. **Data completeness gap:** Study time and progress metrics are systematically underreported (M5, m2).
5. **Feature discoverability gap:** The LLM task manager and dashboard are hidden (M6, m3).
