# Future Functionality Plan: Delta Audit & Next Phase

## Context

Re-audit comparing the vision (`agent_must_read.md`) against current implementation. This report documents: (1) progress since the previous completed report, (2) remaining open items, (3) new findings discovered during deep exploration, and (4) a prioritised phase plan.

**Further issues (`issues/further_issues/`):** Directory does not exist. No user-reported issues to integrate.

---

## Progress Since Previous Report

| Previous ID | Description | Status | Notes |
|---|---|---|---|
| **B1** | Background notification scheduling | ❌ STILL OPEN | `EngagementScheduler` still `Timer`-based (engagement_scheduler.dart:80); no `workmanager` in pubspec.yaml |
| **B2** | OCR/Transcription constructors default `modelId` to `''` | ✅ FIXED | Both now use `required String modelId` with validation warning on empty (ocr_extractor.dart:31-38, transcription_extractor.dart:34-46) |
| **M1** | Voice conversation flow (auto-send, TTS, interrupt, toggle) | ⚠️ PARTIAL | VoiceBar + VoiceController in tutor screen; TTS `speak()` exists but never wired to AI response; no auto-send on silence; no interrupt; no conversation toggle |
| **M2** | LLM-driven `suggestNextAction()` | ❌ STILL OPEN | Still rule-based via `_progressTracker.getRecommendations()` (mentor_service.dart:542-564) |
| **M3** | Handwriting recognition for canvas | ❌ STILL OPEN | Drawing widgets exist, no OCR/vision pipeline for strokes |
| **M4** | Spaced repetition review dashboard | ✅ FIXED | Practice screen shows "Due for Review" count, subject picker via `SpacedRepetitionSheet`, sessions filtered to due cards |
| **M5** | Remaining workload estimator surfaced in UI | ⚠️ PARTIAL | `WorkloadCard` exists in dashboard with lessons-remaining estimate, but uses its own hardcoded logic (novice=3, browsing=2) instead of the `RemainingWorkloadEstimator` service (workload_card.dart:114-130) |
| **M6** | DataBackupService restore + Settings UI | ✅ FIXED | `restoreData()` implemented; Settings has Backup & Restore section with export/import (settings_screen.dart:187-192, 478-573) |
| **m1** | Dashboard in bottom navigation | ✅ FIXED | Dashboard is tab 0 in both NavigationBar and NavigationRail (main.dart:422-453) |
| **m2** | Voice in Mentor/Quick Guide | ❌ STILL OPEN | No `VoiceBar`, no voice controller, no voice input in either MentorScreen or QuickGuideScreen |
| **m3** | Cross-feature voice state management | ❌ STILL OPEN | `voiceControllerProvider` is `Provider<VoiceController>` not `KeepAlive` (teaching_providers.dart:30-32) |
| **m4** | Image compression in tutor screen | ✅ FIXED | `maxWidth: 1024, maxHeight: 1024, imageQuality: 80` via `ImagePicker` (tutor_screen.dart:193-195) |
| **m5** | Token usage tracking in Settings | ✅ FIXED | Settings has "Token Usage Summary" section with per-feature breakdown dialog (settings_screen.dart:177-186, 691-742) |
| **m6** | Cross-feature pub/sub design | ❌ STILL OPEN | No event bus; `CrossFeatureIntegrator` uses direct repository calls |

---

## BLOCKER — App crashes or user cannot proceed

### B1. Background notifications tied to app process — proactive engagement stops when app is closed

**Context:** `EngagementScheduler` (engagement_scheduler.dart:80) uses `Timer` which dies with the app process. `flutter_local_notifications` is used only for foreground-triggered delivery. No `workmanager`, `android_alarm_manager`, or other background scheduling package exists in `pubspec.yaml`. When the app is killed, all nudges, reminders, and notifications stop.

The vision requires a "persistent mentor" that "proactively engage[s] students with reminders, prompts, revision nudges, lesson notifications, accountability messaging, and practice encouragement" — this is the single biggest gap between vision and reality.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/core/services/engagement_scheduler.dart` | 80, 88 | `Timer` — lost on app close |
| `lib/main.dart` | 86-99 | Scheduler started per-launch, no headless task |
| `lib/core/services/notification_service.dart` | — | `flutter_local_notifications` exists but not wired to background scheduling |
| `pubspec.yaml` | — | Missing `workmanager` dependency |

**Acceptance criteria:**
1. Nudge checks run at least once every 6h even when app is closed (platform-permitted)
2. On app reopen after >24h closed, missed nudges are caught up and displayed
3. Lesson reminders fire 15min before scheduled lesson time
4. Practice nudges fire if no practice session recorded in last 48h
5. All notification scheduling uses platform-native APIs, not app-process `Timer`
6. Existing foreground notification behavior is preserved

---

## MAJOR — Features broken, misleading, or critically incomplete

### M1. No true voice conversation flow — STT transcription only, no TTS playback, no interrupt

**Context:** VoiceBar is rendered in TutorScreen and `_onTranscriptionSubmitted()` fills text and sends. However:
- No auto-send on silence detection — user must tap send manually
- No TTS playback of AI responses — VoiceController.speak() exists (voice_controller.dart:157-177) but is never called after an AI response arrives
- No voice conversation mode toggle (voice-only, text-only, mixed)
- No "interrupt AI speaking with new voice input"
- Mentor screen and Quick Guide screen have no voice support at all despite the vision requiring "speak naturally with the AI tutor"

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/teaching/presentation/tutor_screen.dart` | VoiceBar present but no conversational voice loop; TTS never triggered |
| `lib/features/teaching/services/voice_controller.dart` | `speak()` exists (line 157) but never called after AI response; `startListening()` has 3s pause but no auto-send after silence |
| `lib/features/teaching/presentation/widgets/voice_bar.dart` | Works in "transcribe and send" mode, not conversation mode |
| `lib/features/mentor/presentation/mentor_screen.dart` | No VoiceBar, no voice controller |
| `lib/features/quickguide/presentation/quick_guide_screen.dart` | No VoiceBar, no voice controller |

**Acceptance criteria:**
1. Tap-to-talk triggers speech recognition; after 1.5s silence, recognized text is auto-sent
2. After AI response arrives, it is read aloud via TTS
3. User can interrupt AI speaking by tapping mic again (stops TTS, starts new recognition)
4. Voice conversation mode toggle appears in tutor screen (voice-only, text-only, mixed)
5. Mentor screen has microphone button alongside text input
6. Quick Guide screen has microphone button alongside text input
7. Voice mode respects `settingsProvider.locale` for both STT and TTS

---

### M2. Mentor `suggestNextAction()` rule-based, not LLM-driven

**Context:** `MentorService.suggestNextAction()` (mentor_service.dart:542-564) calls `_progressTracker.getRecommendations()` which returns rule-based messages. The vision requires an AI mentor that "dynamically decide[s] what to study next based on student context."

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/mentor/services/mentor_service.dart` | 542-564 | Rule-based via `getRecommendations()` |
| `lib/core/services/study_progress_tracker.dart` | 166-223 | `getRecommendations()` purely rule-based thresholds |

**Acceptance criteria:**
1. `suggestNextAction()` composes an LLM prompt with student context (weak topics, adherence %, recent sessions, upcoming lessons)
2. Returns AI-generated contextual recommendation
3. Graceful fallback to rule-based if LLM unavailable
4. LLM recommendation cached for 15min to avoid redundant API calls
5. Recommendation includes actionable `MentorAction.type` that student can tap to execute

---

### M3. No handwriting recognition for canvas submissions

**Context:** Canvas drawing widget exists (`canvas_drawing_widget.dart`, `drawing_painter.dart`) but there is no handwriting recognition pipeline. Strokes are stored but never interpreted. The vision requires "handwritten/drawn responses on canvas" and "vision-based interpretation of student work."

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/questions/presentation/widgets/canvas_drawing_widget.dart` | Drawing exists, no recognition layer |
| `lib/features/questions/presentation/painters/drawing_painter.dart` | Only renders strokes, no analysis |
| `lib/core/data/extraction/ocr_extractor.dart` | Has OCR but not wired to canvas |
| `lib/features/teaching/services/exercise_evaluator.dart` | Evaluates typed answers only |

**Acceptance criteria:**
1. Canvas strokes can be submitted for LLM-based interpretation (sent as image bytes via vision API)
2. Recognized text/math shown to student for confirmation before submission
3. Handwritten math expressions evaluated for correctness via `ExerciseEvaluator`
4. Canvas questions appear alongside typed questions in practice sessions
5. Practice session question card canvas stub (`"drawing submitted"` magic string) replaced with real submission flow

---

### M4. Workload card uses hardcoded estimation instead of `RemainingWorkloadEstimator` service

**Context:** `WorkloadCard` (workload_card.dart:114-130) has its own `_estimateLessonsRemaining()` method using hardcoded values (novice=3, browsing=2). The dedicated `RemainingWorkloadEstimator` service (147 lines, with per-topic question counts, mastery thresholds, `questionsPerLesson` config) exists but is never used by any UI.

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/dashboard/presentation/widgets/workload_card.dart` | Hardcoded estimation (lines 114-130) |
| `lib/core/services/remaining_workload_estimator.dart` | Sophisticated service exists but unused by UI |
| `lib/features/subjects/presentation/subject_detail_screen.dart` | Could show per-topic workload breakdown |
| `lib/features/planner/presentation/planner_screen.dart` | Could show "estimated lessons needed" during planning |

**Acceptance criteria:**
1. WorkloadCard switches from `_estimateLessonsRemaining()` to `RemainingWorkloadEstimator`
2. Subject detail screen shows per-topic workload estimates using the service
3. Planner screen shows workload estimate during plan creation/adjustment
4. Estimate updates as student progresses

---

### M5. Dashboard does not surface spaced repetition due reviews count

**Context:** The practice screen shows "Due for Review" count and `SpacedRepetitionSheet` exists, but the Dashboard has no card/widget showing how many cards are due for review. Students must navigate to the Practice screen to see due counts.

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/dashboard/presentation/dashboard_screen.dart` | No SR due reviews card |
| `lib/features/dashboard/providers/dashboard_data_providers.dart` | No SR due count provider exists |

**Acceptance criteria:**
1. Dashboard shows "X cards due for review" card with topics breakdown
2. Tapping navigates to Practice screen's spaced repetition flow
3. Due count includes overdue cards and today's due cards

---

## MINOR — Code quality, UX friction, or technical debt

### m1. VoiceController not auto-sending on silence — 3s pause set but no auto-submit

**Context:** `VoiceController.startListening()` sets `pauseFor: const Duration(seconds: 3)` (voice_controller.dart:96) which causes the STT engine to pause after speech, but the `onResult` callback only populates partial results into the stream. There is no logic to detect "final result after silence" and auto-submit.

**Acceptance criteria:**
1. After 1.5s of silence following speech, the final transcription is auto-submitted
2. Auto-send can be cancelled by tapping the mic button again
3. Manual send via text field still works as before

---

### m2. Cross-feature voice state not persisted across navigation

**Context:** `voiceControllerProvider` is `Provider<VoiceController>` (teaching_providers.dart:30-32) — a simple auto-dispose provider. Navigating away from the tutor screen destroys the voice controller, losing any active recognition or TTS session.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/teaching/providers/teaching_providers.dart` | 30-32 | Simple `Provider`, not `KeepAlive` |
| `lib/features/teaching/services/voice_controller.dart` | — | No auto-pause on navigation |

**Acceptance criteria:**
1. Voice state persists across tab switches (or cleanly pauses)
2. Only one voice controller active at a time
3. Mic resource properly released when not in use

---

### m3. TTS speak() exists but is never invoked after AI response

**Context:** `VoiceController.speak()` (voice_controller.dart:157-177) has a full TTS implementation with locale-aware language, rate, volume, and pitch settings. However, no code path in the tutor screen, mentor screen, or conversation manager calls `speak()` after receiving an AI response.

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/teaching/services/voice_controller.dart:157` | `speak()` implemented but unreferenced by UI |
| `lib/features/teaching/presentation/tutor_screen.dart` | Message list doesn't trigger TTS on new AI messages |

**Acceptance criteria:**
1. After AI response text is displayed, `voiceController.speak(responseText)` is called
2. Speaking can be interrupted by new user mic input
3. TTS respects locale from settings

---

### m4. Cross-feature event bus still missing — tight coupling between services

**Context:** `CrossFeatureIntegrator` (cross_feature_integrator.dart) uses direct repository calls for all cross-feature integration. Adding new behaviors (e.g., "after practice session, update spaced repetition AND check mentor nudge") requires modifying existing services. No pub/sub or event bus exists.

**Affected files:**
| File | Issue |
|---|---|
| `lib/core/services/cross_feature_integrator.dart` | Direct repository calls, no event system |
| `lib/features/practice/services/practice_session_service.dart` | Writes directly to session repo |
| `lib/features/teaching/services/tutor_service.dart` | Writes directly to session/conversation repos |

**Acceptance criteria (investigation, not implementation):**
1. Document all current cross-feature coupling points
2. Propose an event system design (Riverpod StreamProvider or lightweight EventBus)
3. No implementation required — design doc only

---

## Dependency Graph & Ordering

```
Phase 1 — Fix BLOCKER (immediate student impact)
├── B1: Background notification scheduling (workmanager integration)

Phase 2 — Voice interaction overhaul (highest vision gap)
├── M1: Voice conversation flow (auto-send, TTS, interrupt, toggle)
├── m1: Auto-send on silence detection
├── m3: Wire TTS speak() into AI response flow
├── m2: Mentor/Quick Guide voice integration
├── m3: Cross-feature voice state management

Phase 3 — AI-driven mentor & smart content
├── M2: LLM-powered suggestNextAction()
├── M3: Handwriting recognition for canvas questions
├── M4: Switch WorkloadCard to RemainingWorkloadEstimator

Phase 4 — Student-facing analytics & visibility
├── M5: Dashboard spaced repetition due reviews card

Phase 5 — Architecture & data coupling
├── m4: Cross-feature pub/sub design doc
```

## Rationale Summary

**6 of 14** previously identified gaps remain open. The codebase has made significant progress: backup/restore, image compression, token usage UI, and spaced repetition dashboard were all added. However, several high-impact vision gaps persist:

1. **Proactive engagement gap (B1):** The #1 deferred vision feature — a "persistent mentor" that engages outside the app. Still Timer-based.
2. **Voice interaction gap (M1/m1/m3):** TTS `speak()` exists but is completely disconnected from the UI. The infrastructure is 90% there but the loop is not closed.
3. **AI mentor gap (M2):** `suggestNextAction()` is still rule-based. The LLM context builder (`_buildContextPrompt()`) exists but is not used for recommendations.
4. **Workload estimator gap (M4):** A 147-line sophisticated estimator service is built but completely unused — WorkloadCard uses 17 lines of hardcoded logic instead.
5. **Handwriting invisibility (M3):** Canvas drawing infrastructure exists but no recognition pathway. Practice session still uses `"drawing submitted"` magic string.
6. **Dashboard visibility gap (M5):** Spaced repetition engine (SM-2) is fully implemented and the practice screen shows due counts, but the dashboard — the student's home screen — does not surface this data.
