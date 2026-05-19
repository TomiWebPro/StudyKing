# Future Functionality Planner — Vision Gap Analysis (Round 5)

**Generated:** 2026-05-19
**Source:** Re-validation of `agent_must_read.md` vision against `lib/` implementation. Previous Round 4 planner (`issues/completed/future_functionality_planner.md`) identified 19 items (3 BLOCKER, 6 MAJOR, 10 MINOR). This round re-assesses all previous items and identifies NEW gaps.

---

## Round 4 → Round 5 Progress

| Round 4 Ref | Description | Status | Evidence |
|---|---|---|---|
| **BLOCKER-1** | 22 lib compile errors | ✅ RESOLVED | `dart analyze lib/` — 0 errors, 9 warnings/info |
| **BLOCKER-2** | Fire-and-forget lesson generation | ✅ RESOLVED | `planner_service.dart:316-338` awaits `generateLesson()`, sets `lessonReady` flag, handles failure |
| **BLOCKER-3** | 81 test compile errors | ✅ RESOLVED | `dart analyze test/` — 0 errors |
| **M1** | Chat-only teaching (no lesson blocks) | ✅ RESOLVED | `tutor_screen.dart:531-536` — slide/chat toggle, `_buildSlidesView()` with `PageView`, `LessonBlockCard` |
| **M2** | No post-lesson practice flow | ✅ RESOLVED | `tutor_screen.dart:359-371` + `373-435` — summary dialog with Quick/Full practice buttons |
| **M3** | Cross-subject focus practice only per-subject | ✅ RESOLVED | `InlinePracticeWidget` accepts nullable `subjectId`; `null` = all subjects; per-subject accuracy tracking |
| **M4** | Session-Lesson records never linked | ✅ RESOLVED | `planner_service.dart:324-326` sets `lessonIds: [lesson.id]`; `Lesson` model has `sessionId` |
| **M5** | Quiz blocks use naive substring match | ✅ RESOLVED | `lesson_block_card.dart:302-319` uses `answerKey` (`||`-delimited exact matches) or scoped `answer:` marker check |
| **M6** | No proper slide presentation mode | ✅ RESOLVED | `tutor_screen.dart:818-868` — `PageView` with slide counter, prev/next nav, `LessonBlockCard` |
| **m1** | Redundant `VoiceController` in teaching | ❌ STILL OPEN | `voice_controller.dart` still exists with `@Deprecated`; imported by `voice_bar.dart` |
| **m2** | `IdleExecutor` queue always empty | ✅ RESOLVED | `tutor_service.dart:255,263` enqueues post-lesson adherence + weak topic reanalysis |
| **m3** | `InlinePracticePanel` dead code with errors | ✅ RESOLVED | File removed (confirmed: does not exist on disk) |
| **m4** | YouTube URL → wrong `SourceType` | ✅ RESOLVED | `upload_screen.dart:347-348` — correctly returns `SourceType.video` for YouTube URLs |
| **m5** | `SessionTrackerScreen` subjectId = 'all' | ❌ STILL OPEN | `session_tracker_screen.dart:172` — still hardcoded `subjectId: 'all'` |
| **m6** | No CI/CD pipeline | ❌ STILL OPEN | No `.github/workflows/` files exist |
| **m7** | No gallery button on upload screen | ❌ STILL OPEN | No dedicated gallery/image library button |
| **m8** | DOCX/EPUB raw byte read → garbled output | ❌ STILL OPEN | `document_extractor.dart:96-97` reads ZIP archive as UTF-8 — needs proper parser |
| **m9** | No topic dependency visualizer | ❌ STILL OPEN | Zero progress on graphical dependency tree |
| **m10** | No handwriting/ink recognition | ❌ STILL OPEN | Canvas drawing widget exists; no recognition |
| **m11** | LLM-dependent OCR/ASR only | ✅ RESOLVED | `OcrExtractor` uses LLM for vision OCR; `TranscriptionExtractor` fetches YouTube transcripts via API + LLM fallback. Adequate for v1. |
| **m12** | `checkWellbeingAndGenerateNudges()` not called periodically | ❌ STILL OPEN | Still only called reactively after mentor chat; `EngagementScheduler` runs separate nudge path |

### Resolution Summary

| Category | Round 4 Count | Resolved | Still Open | New This Round |
|---|---|---|---|---|
| **BLOCKER** | 3 | 3 | 0 | 0 |
| **MAJOR** | 6 | 6 | 0 | 2 |
| **MINOR** | 10 | 4 | 6 | 3 |
| **Total** | **19** | **13** | **6** | **5** |

---

## MAJOR — Feature is broken or misleading

### M7. No TTS voice output during tutoring — tutor cannot speak back

**Severity: MAJOR** — the vision requires "voice conversation" and "speak naturally with the AI tutor." Currently the tutor accepts voice **input** (STT) but responds only as **text**. The student speaks; the AI types back.

**Context:**
- `VoiceService.speak()` exists and works (voice_service.dart:159-178) with locale-aware TTS
- `VoiceController.speak()` wraps it but is deprecated and never called in conversation flow
- `ConversationManager` has zero mentions of `speak`/`tts`/voice output
- `TutorScreen` renders `VoiceBar` for input only — no speaker/playback UI for tutor responses

**Affected files:**
- `lib/features/teaching/services/conversation_manager.dart` — no TTS trigger after `_llmService.chatStream()` returns each token
- `lib/features/teaching/presentation/tutor_screen.dart` — no "speaker" button on chat bubbles, no auto-play of tutor responses
- `lib/features/teaching/providers/teaching_providers.dart` — `voiceServiceProvider_` exists but is not consumed for output
- `lib/features/teaching/services/voice_controller.dart` — `speak()` exists but unused (deprecated wrapper)
- `lib/core/services/voice_service.dart:159-178` — `speak()` method is fully functional, just not wired into tutoring

**Acceptance criteria:**
1. After each complete tutor response is received (not token-by-token streaming bust), auto-play via TTS if voice option is enabled
2. Toggle button in tutor screen to enable/disable voice output
3. Each chat bubble has a manual "play aloud" speaker icon for re-reading
4. Voice output respects locale (same as STT locale)
5. Option persists across sessions via settings

---

### M8. Proactive engagement: mentor never initiates — only reacts after chat opens

**Severity: MAJOR** — the vision says "proactively engage students with reminders, prompts, revision nudges, lesson notifications, accountability messaging." The `EngagementScheduler` handles some of this via local notifications, but the mentor persona (the conversational AI companion) never proactively starts a conversation.

**Context:**
- `MentorService.checkWellbeingAndGenerateNudges()` (mentor_service.dart:783) returns nudges as text — but only when the student opens the mentor screen and triggers a chat
- `EngagementScheduler._sendNudgeNotifications()` (engagement_scheduler.dart) only sends local system notifications — not mentor-initiated conversations
- `NotificationService` has 8 channels but no "Mentor has a message for you" notification that opens the mentor screen
- No proactive "check-in" cadence exists beyond the daily notification-based nudge system

**Affected files:**
- `lib/features/mentor/services/mentor_service.dart:783` — `checkWellbeingAndGenerateNudges()` exists but is triggered only after mentor chat opens
- `lib/core/services/engagement_scheduler.dart:393` — no integration with `MentorService` for proactive mentorship nudges
- `lib/features/mentor/presentation/mentor_screen.dart` — no badge/indicator for "mentor has something to say"
- `lib/core/services/notification_service.dart` — no "mentor message" notification channel that deep-links into mentor screen

**Acceptance criteria:**
1. Add a `showMentorMessage()` method to `NotificationService` that opens the mentor screen on tap (via deep-link payload)
2. `EngagementScheduler` periodically calls `MentorService.checkWellbeingAndGenerateNudges()` and shows a notification when a meaningful nudge is returned
3. Mentor screen shows an unread indicator when there are pending mentor messages
4. Student can configure "proactive mentor check-in frequency" in settings (daily / every 3 days / weekly / off)
5. Mentor's proactive nudges are saved in `EngagementNudgeRepository` and shown as a "While you were away" section on next mentor open

---

## MINOR — Code quality, UX friction, incomplete polish

### m13. Post-lesson practice navigates to bare `PracticeSession` — no focus mode bridge

**Severity: MINOR** — when a student finishes a lesson and taps "Quick Practice" or "Practice Mode" in the summary dialog, the app navigates to `AppRoutes.practiceSession` (tutor_screen.dart:361-370), which is a standalone practice session screen. The `focus_mode` feature (which exists precisely for this purpose per beta user feedback `issues/further_issues/open/focus_mode.md`) is bypassed.

**Affected files:**
- `lib/features/teaching/presentation/tutor_screen.dart:359-371` — `_startPostLessonPractice()` navigates to `PracticeSession` directly
- `lib/features/focus_mode/presentation/focus_timer_screen.dart` — has inline practice widget but no "post-lesson practice" entry point
- `lib/features/focus_mode/presentation/widgets/inline_practice_widget.dart` — could be used inside focus mode for post-lesson practice

**Acceptance criteria:**
1. Post-lesson practice launches FocusTimerScreen with preselected subject/topic (existing `preselectedSubjectId`, `preselectedTopicId` params) instead of standalone PracticeSession
2. FocusTimerScreen's study hub area shows "Lesson Practice: {topic}" label when entered post-lesson
3. Focus mode inline practice counts toward the lesson session record (back-links to the originating tutor session)
4. The standalone post-lesson practice path still exists as an alternative (user can choose "quick session" vs "focus mode practice")

---

### m14. No lesson → focus mode auto-suggest on idle

**Severity: MINOR** — the vision describes "when the app is idle, use the API to make lesson plan" and "system should nudge student to keep learning." Currently, the `IdleExecutor` is used only for 2 post-lesson tasks. No pre-lesson material generation or "ready for a lesson?" nudge exists.

**Affected files:**
- `lib/core/services/llm_agent/idle_executor.dart:109` — queue is used but only for 2 tasks
- `lib/features/teaching/services/tutor_service.dart:254-271` — only post-lesson tasks enqueued

**Acceptance criteria:**
1. After a tutor session ends, `IdleExecutor` enqueues "prep next suggested topic" background task that generates lesson blocks for the next weak topic
2. When app is idle > 5 minutes, show a local notification "Ready to continue learning? {topic} has a lesson ready"
3. A "Study Now" button on the notification opens the pre-generated lesson directly
4. `IdleExecutor` task queue shows progress in `LlmTaskManagerScreen`

---

### m15. `VoiceController` still exists with `@Deprecated` annotation but is still imported

**Severity: MINOR** — carries over from Round 4 m1. The deprecated `VoiceController` (28 lines) wraps `VoiceService` and is still imported by `VoiceBar`. Should be removed and references updated.

**Affected files:**
- `lib/features/teaching/services/voice_controller.dart` — entire file (deprecated wrapper)
- `lib/features/teaching/presentation/widgets/voice_bar.dart:4` — imports `VoiceController`
- `lib/features/teaching/providers/teaching_providers.dart:20` — provides `voiceServiceProvider_`

**Acceptance criteria:**
1. Delete `voice_controller.dart`
2. `VoiceBar` directly uses `VoiceService` from `voiceServiceProvider` instead of `VoiceController`
3. `teaching_providers.dart` removes the `voiceServiceProvider_` alias (use the core `voiceServiceProvider` directly)
4. `dart analyze` reports zero new issues after removal

---

## Beta User Issue Resolution — Updated Status

### File: `issues/further_issues/open/lessons.md`

| Original Complaint | Current State | Verdict | Fixes Needed |
|---|---|---|---|
| Calendar view for lesson planning | Calendar exists with `onDayTap` that opens tutor mode | ✅ PARTIALLY RESOLVED | Interactive scheduling (drag-to-create, time-picker integration) not yet implemented |
| LLM agents for preparation; tool execution | `LlmAgent` wired with 6 tools; agent memory Hive-backed; background tasks enqueued | ✅ RESOLVED | — |
| Separate scheduling time from lesson plan | Planner separates `Session` (time slot) from `Lesson` (content blocks); `lessonReady` flag tracks content readiness | ✅ RESOLVED | — |
| Presentations with LLM explanations | Slide/chat toggle in tutor screen; PageView with LessonBlockCard; 6 block types rendered | ✅ RESOLVED | — |
| Long-term memory for agents | `AgentMemoryStore` (Hive-backed) with facts, session summaries, student profiles | ✅ RESOLVED | — |
| "When app is idle, use API to make lesson plan" | `IdleExecutor` runs 2 post-lesson tasks only; no pre-lesson prep or idle-time lesson generation | ❌ NOT RESOLVED | m14 (idle lesson prep) |
| "LLM is not just a fucking chatbot" — must continue to help make materials | Lesson generation, question variant generation, conversation-based tutoring all use LLM pervasively; background content generation via agents | ✅ RESOLVED | — |

**Remaining blockers to close `lessons.md`:**
1. M7 (TTS voice output) for spoken lesson narration
2. m14 (idle lesson prep via background LLM)

### File: `issues/further_issues/open/focus_mode.md`

| Original Complaint | Current State | Verdict | Fixes Needed |
|---|---|---|---|
| "Focus mode should be a place where student can practice questions from different subjects after lessons" | `InlinePracticeWidget` supports cross-subject (null subjectId = all subjects). Post-lesson summary dialog has practice buttons (Quick Practice, Practice Mode). | ✅ RESOLVED | — |
| "Focus mode is fucking useless" — must be actually useful | Focus timer exists with Pomodoro cycle, inline practice, per-subject accuracy tracking, session persistence, badge integration, adherence recording | ✅ RESOLVED | — |

**Remaining blockers to close `focus_mode.md`:**
1. m13 (post-lesson practice should use FocusTimerScreen instead of bare PracticeSession for better UX)
2. Consider adding a "default post-lesson practice mode" setting (quick vs focus mode)

### Process for closing further_issues files

When ALL criteria in the "Remaining blockers" sections above are met:
1. Move `issues/further_issues/open/lessons.md` → `issues/further_issues/completed/lessons.md`
2. Move `issues/further_issues/open/focus_mode.md` → `issues/further_issues/completed/focus_mode.md`
3. Add a note in CHANGELOG acknowledging the resolution

---

## Immediate Priority Order (Next Development Phase)

| Priority | Issue | Effort | Impact | Dependencies |
|---|---|---|---|---|
| **P0** | **M7: TTS voice output during tutoring** | Medium — wire existing `VoiceService.speak()` into conversation loop + UI toggle | High — enables "voice conversation" vision; rich UX leap | None |
| **P0** | **M8: Proactive mentor engagement** | Medium — integrate MentorService with EngagementScheduler + notification deep-link | High — enables "persistent mentor" vision; addresses proactive engagement | None |
| **P1** | **m13: Post-lesson practice → focus mode bridge** | Low — change navigation target to FocusTimerScreen with preselected params | Medium — directly addresses focus_mode.md beta feedback | None |
| **P1** | **m5: SessionTrackerScreen subjectId fix** | Low — one-line change `'all'` → actual subject selector | Low — per-subject tracking fidelity | None |
| **P2** | **m14: Idle lesson prep** | Medium — enqueue pre-lesson generation + idle notification | Medium — addresses "when app is idle, make lesson plan" from lessons.md | None |
| **P2** | **m1/m15: Remove VoiceController** | Low — delete file + update 2 imports | Low — code cleanup | None |
| **P2** | **m8: DOCX/EPUB proper parsing** | Medium — add `archive` package or extract text via LLM (content already sent as raw bytes) | Medium — ingestion pipeline complete for all document types | None |
| **P3** | **m6: CI/CD pipeline** | Medium — GitHub Actions config with `dart analyze` + `flutter test` | Medium — quality gating | Existing test infra |
| **P3** | **m9: Topic dependency visualizer** | High — requires D3-like graph widget or custom painter | Low — nice-to-have visualization | None |
| **P4** | **m7: Gallery button on upload screen** | Low — add `Icons.photo_library` button alongside Camera/File | Low — UX polish | None |
| **P4** | **m10: Handwriting recognition** | High — requires LLM vision API integration or ML Kit | Low — long-term vision item | None |

---

## Summary

| Category | Count | Details |
|---|---|---|
| **MAJOR** (new) | 2 | M7 (no TTS output), M8 (proactive mentor) |
| **MINOR** (open from Round 4) | 5 | m1 (VoiceController), m5 (subjectId 'all'), m6 (CI/CD), m8 (DOCX/EPUB), m9 (topic dep viz) |
| **MINOR** (new) | 3 | m13 (post-lesson → focus mode bridge), m14 (idle lesson prep), m15 (merged with m1) |
| **Total open** | **10** | |
| **Open further_issues** | **2** | `lessons.md`, `focus_mode.md` |

---

## Actionable Next Phase

### Phase 1: Voice + Engagement (P0)
1. **M7**: Wire `VoiceService.speak()` into `ConversationManager` after each complete tutor response. Add auto-play toggle + per-bubble speaker icon in `TutorScreen`.
2. **M8**: Integrate `MentorService.checkWellbeingAndGenerateNudges()` into `EngagementScheduler._runDailyChecks()`. Add `showMentorMessage()` to `NotificationService` with deep-link to mentor screen.

### Phase 2: Focus Mode Integration + Quick Fixes (P1)
3. **m13**: Change `_startPostLessonPractice()` to navigate to `FocusTimerScreen` with `preselectedSubjectId`, `preselectedTopicId`, `defaultDurationMinutes`.
4. **m5**: Replace `'all'` with a subject picker in `SessionTrackerScreen` (default to the subject shown in the timer).

### Phase 3: Background Intelligence + Cleanup (P2)
5. **m14**: Enqueue "next topic lesson prep" in `IdleExecutor` after each tutor session ends. Add idle notification with "Study Now" deep-link.
6. **m1/m15**: Delete `VoiceController`. Update `VoiceBar` to use core `voiceServiceProvider`.
7. **m8**: Add conditional DOCX/EPUB parsing — or at minimum, pass the raw bytes through to the LLM with format hints rather than garbled UTF-8 decode.

### Phase 4: Quality Infrastructure (P3)
8. **m6**: Add `.github/workflows/ci.yml` that runs `dart format --check`, `dart analyze`, `flutter test` on every push/PR.
9. **m9**: (Optional) Basic topic dependency tree widget using `CustomPainter` or a graph layout algorithm.

### Closing Further Issues
- Once Phase 1-2 is complete, `focus_mode.md` can be moved to `completed/`
- Once Phase 1 + Phase 3 (m14) is complete, `lessons.md` can be moved to `completed/`

---

## Cross-References

- `issues/completed/future_functionality_planner.md` — Round 4 analysis (baseline for this round)
- `issues/further_issues/open/lessons.md` — beta user lesson complaint (blocked on M7 + m14)
- `issues/further_issues/open/focus_mode.md` — beta user focus mode complaint (blocked on m13)
- `issues/open/code_refactor_master.md` — m1 VoiceController residual
- `issues/open/ui_ux_master.md` — m5 SessionTracker subjectId residual
