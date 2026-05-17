# Future Functionality Plan: Delta Audit & Next Phase

## Context

Re-audit following commit `aaf5caf` which resolved **9 of 16** previously identified gaps from the completed `issues/completed/future_functionality_planner.md`. The codebase now stands at 14/15 features fully implemented with ~310 test files. This report documents: (1) progress since the previous plan, (2) 7 remaining open items, (3) 9 new findings discovered during deep exploration, and (4) a prioritised phase plan.

**Further issues (`issues/further_issues/`):** Not present. No user-reported issues to integrate.

---

## Progress Since Previous Report

| Previous ID | Description | Status | Notes |
|---|---|---|---|
| **B1** | Tutor image capture stubbed "Coming Soon" | ✅ FIXED | `_pickImage()` now uses `ImagePicker` + `ConversationManager.processImage()` (tutor_screen.dart:158-206) |
| **B2** | OCR/transcription empty `modelId` silent data loss | ✅ FIXED | Both extractors now validate `modelId.isEmpty` and return typed error results (ocr_extractor.dart:131-139, transcription_extractor.dart:290-294) |
| **B3** | Question auto-generation hardcodes `singleChoice` only | ✅ FIXED | `_defaultAllowedTypes` includes `multiChoice`, `typedAnswer`, `mathExpression`, `essay`; ARB prompt instructs varied types; validation handles all types (content_pipeline.dart:331-418) |
| **M1** | Background notifications only while app running | ❌ STILL OPEN | `EngagementScheduler` still `Timer`-based (engagement_scheduler.dart:80) |
| **M2** | Multi-syllabus plan creation blocked by single-course UI | ✅ FIXED | Planner screen now has `SyllabusGoalEntry` list with add/remove, calls `generatePlanFromSyllabus(List<SyllabusGoal>)` (planner_screen.dart:130-158) |
| **M3** | `suggestNextAction()` still rule-based, not LLM-driven | ❌ STILL OPEN | Calls `_progressTracker.getRecommendations()` — rule-based thresholds (mentor_service.dart:535-557) |
| **M4** | TutorScreen has no voice conversation flow | ⚠️ PARTIAL | VoiceBar integrated (tutor_screen.dart:458-463) but no auto-send on silence, no TTS playback loop, no conversational voice toggle |
| **M5** | Upload screen blocks audio/video file types | ✅ FIXED | `allowedExtensions` now includes `mp3`, `mp4`, `wav`, `m4a`, `ogg`, `webm` (upload_screen.dart:67-78) |
| **M6** | VoiceBar widget not rendered in TutorScreen | ✅ FIXED | `VoiceBar` rendered as leading widget in `ConversationInput` (tutor_screen.dart:458) |
| **m1** | DataBackupService export-only, no restore | ❌ STILL OPEN | No `restoreData()`, no Settings UI entry |
| **m2** | CSV uses `toStringAsFixed` (correct per convention) | ✅ NO ACTION NEEDED | Confirmed correct convention for CSV exports |
| **m3** | Dashboard not in bottom navigation | ❌ STILL OPEN | FAB (mobile) / NavigationRail leading (tablet) only |
| **m4** | No `RemainingWorkloadEstimator` service exists | ❌ STILL OPEN | Service file exists (147 lines) but not integrated into any UI flow |
| **m5** | Upload flow passes empty `studentId`/`modelId` | ✅ FIXED | Resolves from `fixedStudentId`/`StudentIdService` + `selectedModelProvider` (upload_screen.dart:203-207) |
| **—** | LLM Task Manager inaccessible from UI | ✅ FIXED | Settings now has "AI Task Monitor" tile |
| **—** | Focus mode not tracked in progress | ✅ FIXED | `SessionRepository` captures focus sessions |
| **—** | VoiceController hardcoded en_US | ✅ FIXED | `_localeForSpeech()` / `_localeForTts()` locale mapping added |

---

## BLOCKER — App crashes or user cannot proceed

### B1. No background notification scheduling — proactive engagement only works while app is running

**Context:** `EngagementScheduler` (engagement_scheduler.dart:80) uses `Timer` which is tied to the app process. `flutter_local_notifications` is used only for foreground-triggered delivery. No background scheduling package (`workmanager`, `android_alarm_manager`) is in `pubspec.yaml`. When the app is killed, notifications stop entirely.

This is the **single biggest gap in the product vision**: StudyKing is meant to be a "persistent mentor" that "proactively engage[s] students with reminders, prompts, revision nudges, lesson notifications, accountability messaging, and practice encouragement." Currently it can only do this while the student is already using the app.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/core/services/engagement_scheduler.dart` | 80, 88 | `Timer` — lost on app close |
| `lib/main.dart` | 84-99 | Scheduler started per-launch, no headless task |
| `lib/core/services/notification_service.dart` | — | `flutter_local_notifications` exists but not wired to background scheduling |
| `pubspec.yaml` | — | Missing `workmanager` or `android_alarm_manager` dependency |

**Acceptance criteria:**
1. Nudge checks run at least once every 6h even when the app is closed (platform-permitted)
2. On app reopen after >24h closed, missed nudges are caught up and displayed
3. Lesson reminders fire 15min before scheduled lesson time
4. Practice nudges fire if no practice session recorded in the last 48h
5. All notification scheduling uses platform-native APIs, not app-process `Timer`
6. Existing foreground notification behavior is preserved

---

### B2. OCR/Transcription constructors still default `modelId` to `''`

**Context:** While the previous B2 (empty modelId causing silent data loss) was fixed by adding validation checks inside `_extractWithLlm()` and `_transcribeWithLlm()`, the constructors still default to `modelId = ''`. This means any caller that doesn't explicitly pass a modelId will trigger the "no model configured" error path even when a model IS configured in settings. The root cause (constructor default) was not addressed.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/core/data/extraction/ocr_extractor.dart` | 20-25 | `OcrExtractor({... String modelId = ''})` — default should be removed/required |
| `lib/core/data/extraction/transcription_extractor.dart` | 25-30 | `TranscriptionExtractor({... String modelId = ''})` — same issue |
| `lib/features/ingestion/services/document_extractor.dart` | 147-178 | Creates extractors without explicit modelId in some code paths |

**Acceptance criteria:**
1. `OcrExtractor` constructor requires `modelId` (or removes default, forcing caller to supply it)
2. `TranscriptionExtractor` constructor requires `modelId` (same)
3. All callers in `DocumentExtractor` and `ContentPipeline` provide the modelId
4. Clear error if modelId is still empty at extraction time (the validation gate already exists)

---

## MAJOR — Features broken, misleading, or critically incomplete

### M1. Mentor/service/text-to-speech has no voice conversation flow

**Context:** VoiceBar is now rendered in TutorScreen and `_onTranscriptionSubmitted()` puts recognized text into `_textController` and calls `_sendMessage()`. However:

- There is no auto-send on silence detection — user must tap send manually
- There is no TTS playback of AI responses — user must read them
- There is no voice conversation mode toggle — always text-first
- There is no "interrupt AI speaking with new voice input"
- The Mentor screen has **no voice support at all** despite the vision stating "The student should be able to speak naturally with the AI tutor" and the mentor being the "persistent companion"

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/teaching/presentation/tutor_screen.dart` | 455-463 | VoiceBar present but no conversational voice mode |
| `lib/features/teaching/services/voice_controller.dart` | 1-195 | `startListening()` exists but auto-stop + auto-send not wired |
| `lib/features/teaching/presentation/widgets/voice_bar.dart` | — | Widget exists but works in "transcribe and send" mode, not conversation mode |
| `lib/features/mentor/presentation/mentor_screen.dart` | — | No VoiceBar, no voice controller, no voice input at all |
| `lib/core/widgets/conversation_input.dart` | — | Shared widget used by both tutor and mentor; could host voice button |

**Acceptance criteria:**
1. Tap-to-talk button triggers speech recognition with auto-send on silence detection (1.5s silence timeout)
2. After AI response arrives, it is read aloud via TTS
3. User can interrupt AI speaking by tapping microphone again (triggers new recognition, stops current TTS)
4. Voice conversation mode toggle appears in tutor screen (voice-only, text-only, mixed)
5. Mentor screen also has VoiceBar integration (at minimum, a "hold to speak" button)
6. Voice mode respects `settingsProvider.locale` for both STT and TTS

---

### M2. Mentor `suggestNextAction()` purely rule-based, not LLM-driven

**Context:** `MentorService.suggestNextAction()` (mentor_service.dart:535-557) calls `_progressTracker.getRecommendations()` which returns rule-based messages based on accuracy thresholds, study hours, etc. The vision requires an AI mentor that "dynamically decide[s] what to study next based on student context." The `_buildContextPrompt()` method exists but is not used here.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/mentor/services/mentor_service.dart` | 535-557 | Rule-based recommendations |
| `lib/core/services/study_progress_tracker.dart` | 166-223 | `getRecommendations()` is purely rule-based thresholds |

**Acceptance criteria:**
1. `suggestNextAction()` composes an LLM prompt with student context (weak topics, adherence %, recent sessions, upcoming lessons)
2. Returns AI-generated contextual recommendation (e.g., "You've been avoiding stoichiometry — let's tackle 10 practice questions today")
3. Falls back gracefully to rule-based `getRecommendations()` if LLM unavailable
4. LLM recommendation is cached and reused for 15min to avoid redundant API calls
5. Recommendation includes an actionable `MentorAction.type` that the student can tap to execute

---

### M3. No handwriting recognition or ink-to-text for canvas questions

**Context:** The drawing canvas widget (`canvas_drawing_widget.dart`) exists with `DrawingPainter` and `GridPainter`. However, there is no handwriting recognition pipeline. Strokes are stored as raw point data but never interpreted into text or math expressions. The vision requires "handwritten/drawn responses on canvas" and "vision-based interpretation of student work."

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/questions/presentation/widgets/canvas_drawing_widget.dart` | Drawing exists but no recognition layer |
| `lib/features/questions/presentation/painters/drawing_painter.dart` | Only renders strokes, no analysis |
| `lib/core/data/extraction/ocr_extractor.dart` | Has OCR capabilities but not wired to canvas drawings |
| `lib/features/teaching/services/exercise_evaluator.dart` | Evaluates typed answers only, not canvas submissions |

**Acceptance criteria:**
1. Canvas strokes can be submitted for LLM-based interpretation (sent as image bytes via vision API)
2. Recognized text/math is shown to the student for confirmation before submission
3. Handwritten math expressions are evaluated for correctness via `ExerciseEvaluator`
4. Canvas questions appear alongside typed questions in practice sessions

---

### M4. No spaced repetition review dashboard

**Context:** `SpacedRepetitionService` (269 lines) + `SpacedRepetitionEngine` implement a full SM-2 algorithm with proper scheduling. However, there is **no UI** showing students their due reviews, overdue cards, or review queue. Students cannot see "10 cards due for review today" or prioritize overdue topics. The spaced repetition engine is invisible to the student.

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/practice/services/spaced_repetition_service.dart` | Engine exists but no UI exposes it |
| `lib/features/practice/services/practice_session_service.dart` | Uses SR internally but doesn't surface due cards |
| `lib/features/dashboard/services/dashboard_service.dart` | Doesn't pull spaced repetition due counts |
| `lib/features/practice/presentation/screens/practice_screen.dart` | No "Review Due Cards" section |

**Acceptance criteria:**
1. Practice screen shows "X cards due for review" section with count and topics
2. Tapping opens a review session filtered to due cards only
3. After each review attempt, the SR engine is updated and next review date shown
4. Dashboard shows "Due Reviews" count alongside other stats
5. Adherence includes "spaced repetition adherence" (ratio of completed to due reviews)

---

### M5. Remaining workload estimator not surfaced in any UI

**Context:** `RemainingWorkloadEstimator` exists (147 lines) with topic-level estimation logic. However, no screen or widget uses it to show "lessons remaining to mastery" — a key vision requirement ("A relative remaining lesson count should be given by the system towards mastery").

**Affected files:**
| File | Issue |
|---|---|
| `lib/core/services/remaining_workload_estimator.dart` | Service exists but unreferenced by any UI |
| `lib/features/dashboard/presentation/dashboard_screen.dart` | Could show "~X lessons to mastery" per subject |
| `lib/features/subjects/presentation/subject_detail_screen.dart` | Could show workload breakdown per topic |
| `lib/features/planner/presentation/planner_screen.dart` | Could show "estimated lessons needed" during planning |

**Acceptance criteria:**
1. Dashboard shows "~X lessons remaining to mastery" for each active subject
2. Subject detail screen shows per-topic workload estimates
3. Planner screen shows workload estimate during plan creation/adjustment
4. Estimate updates as student progresses (fewer lessons remaining after practice)

---

### M6. DataBackupService has no restore function

**Context:** `DataBackupService` only has `exportAllData()` and `exportSingleBox()`. No `restoreData(path)` method exists. No Settings UI entry for backup/restore. Students who export their data cannot import it again.

**Affected files:**
| File | Issue |
|---|---|
| `lib/core/services/data_backup_service.dart` | Export-only, no restore |
| `lib/features/settings/presentation/settings_screen.dart` | No backup/restore UI entry |

**Acceptance criteria:**
1. `restoreData(String filePath)` reads JSON backup, validates format, overwrites Hive boxes
2. Settings has "Backup & Restore" section with export and import actions
3. Import shows confirmation dialog with data summary (date, size, box count)
4. Existing data is backed up before overwrite (restore creates a pre-restore snapshot)

---

## MINOR — Code quality, UX friction, or technical debt

### m1. Dashboard still not in bottom navigation bar

**Context:** Dashboard accessible only via `FloatingActionButton.small` (mobile) or `NavigationRail` leading (tablet). Not a tab in the bottom `NavigationBar`. Users may not discover it.

**Acceptance criteria:**
1. Dashboard is accessible from the bottom navigation bar on mobile
2. Dashboard is accessible from the navigation rail on tablet
3. No existing navigation behavior is broken

---

### m2. No voice interaction in Mentor or Quick Guide screens

**Context:** VoiceBar is now in TutorScreen. But the Mentor screen and Quick Guide screen have no voice input. Students can't speak to their mentor even though the vision says "The student should be able to speak naturally with the AI tutor" and the mentor is the "always-available" companion.

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/mentor/presentation/mentor_screen.dart` | No VoiceBar, no voice controller |
| `lib/features/quickguide/presentation/quick_guide_screen.dart` | No VoiceBar, no voice controller |

**Acceptance criteria:**
1. Mentor screen has microphone button alongside text input
2. Quick Guide screen has microphone button alongside text input
3. Both use the same `VoiceController` pattern as TutorScreen

---

### m3. No cross-feature voice state management

**Context:** `VoiceController` is created per-screen via `voiceControllerProvider` (a simple `Provider`, not `KeepAlive`). This means voice state is lost when navigating between screens. If a student is speaking to the tutor and switches to the mentor, the voice session is dropped.

**Acceptance criteria:**
1. Voice state persists across navigation (or cleanly stops when leaving)
2. Only one voice controller is active at a time
3. Platform mic resource is properly released/granted

---

### m4. Tutor screen sends image bytes via base64 — no compression

**Context:** `_pickImage()` reads the picked image as full-resolution bytes and base64-encodes them before sending to the LLM. A 12MP phone camera image can be 3-6MB, which as base64 becomes 4-8MB of text. This will be slow and expensive for both the student (mobile data) and API costs.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/teaching/presentation/tutor_screen.dart` | 196 | `readAsBytes()` → no resize/compression |

**Acceptance criteria:**
1. Images are resized to max 1024px on the longest edge before base64 encoding
2. JPEG compression at 80% quality is applied to reduce payload size
3. Processing runs in an isolate to avoid UI jank on large images

---

### m5. No LLM token usage tracking exposed to user

**Context:** `LlmUsageMeter` exists in core services but there's no UI showing students their token consumption, costs, or usage trends. The vision requires "track LLM token usage for different tasks."

**Acceptance criteria:**
1. Settings has a "Token Usage" section showing total tokens used (input/output)
2. Usage is broken down by feature (teaching, mentor, ingestion, practice)
3. Estimated cost is shown based on `token_pricing_config.dart`
4. Student can set a monthly token budget and get warned when approaching it

---

### m6. No activity pub/sub for cross-feature reactivity

**Context:** Cross-feature integration currently uses direct repository calls (e.g., `PracticeService` writes to `SessionRepository` directly). There is no event bus or pub/sub system for loosely coupled cross-feature communication. Adding new cross-feature behaviors (e.g., "after practice session, update spaced repetition AND check if a mentor nudge should fire") requires modifying multiple existing services.

**Acceptance criteria (investigation, not implementation):**
1. Document all current cross-feature coupling points
2. Propose an event system design (could be as simple as a Riverpod StreamProvider)
3. No implementation required — design doc only

---

## Dependency Graph & Ordering

```
Phase 1 — Fix BLOCKER (immediate)
├── B1: Background notification scheduling (workmanager integration)
├── B2: OCR/Transcription constructor modelId required

Phase 2 — Voice interaction overhaul (highest student impact)
├── M1: Voice conversation flow (auto-send, TTS, interrupt)
├── m2: Mentor/Quick Guide voice integration
├── m3: Cross-feature voice state management
├── m4: Image compression in tutor screen

Phase 3 — AI-driven mentor & content
├── M2: LLM-powered suggestNextAction()
├── M3: Handwriting recognition for canvas questions

Phase 4 — Student-facing analytics
├── M4: Spaced repetition review dashboard
├── M5: Remaining workload estimator surfaced in UI
├── m5: Token usage tracking exposed in Settings

Phase 5 — Data safety & discoverability
├── M6: Backup/restore implementation
├── m1: Dashboard in bottom navigation
├── m6: Cross-feature pub/sub design doc
```

## Rationale Summary

**9 of 16** previously identified issues were resolved in commit `aaf5caf`. The codebase is remarkably mature for a solo project with 14/15 features fully implemented and ~310 test files. However, several high-impact vision gaps remain:

1. **Proactive engagement gap (B1):** The #1 deferred vision feature — a "persistent mentor" that engages outside the app. This is the single biggest remaining gap between the vision and reality.
2. **Voice interaction gap (M1/m2/m3):** Voice infrastructure exists but is not wired into a true conversational loop. The tutor image capture fix (B1 ✅) and VoiceBar integration (M6 ✅) provide the foundation but the conversational flow is missing.
3. **AI mentor gap (M2):** The mentor's `suggestNextAction()` is still rule-based, not AI-driven. The LLM context builder exists (`_buildContextPrompt()`) but is not used for recommendations.
4. **Spaced repetition invisibility (M4):** One of the most powerful features (SM-2 algorithm) is completely invisible to students. No "10 cards due" counter anywhere.
5. **Workload visibility (M5):** The "lessons remaining to mastery" concept — a core vision requirement — has a service but no UI.

No `issues/further_issues/` directory exists. This analysis is entirely vision-vs-implementation.
