# Future Functionality Plan: Updated Vision Gaps & Next Phase

## Context

Re-audit of the ~550+ source file codebase comparing the product vision (`agent_must_read.md`) against actual implementation. The previous `issues/completed/future_functionality_planner.md` identified 2 BLOCKERs, 7 MAJORs, and 4 MINORs. This report provides an updated delta — items resolved, still open, or regressed — plus **new findings** discovered during deep exploration. Since the last audit, the codebase has significantly matured in localization, session tracking, and LLM task monitoring. However, several foundational vision gaps remain untouched.

**User-reported issues (further_issues directory):** Not present. This analysis is entirely vision-vs-implementation.

---

## Progress Since Previous Report

| Previous Item | Status | Notes |
|---|---|---|
| **B1** Tutor image capture stubbed | **❌ STILL BROKEN** | Lines 133-136 unchanged |
| **B2** OCR `modelId: ''` | **❌ STILL BROKEN** | Line 125 unchanged |
| **M1** Background notifications | **❌ STILL MISSING** | `EngagementScheduler` still `Timer`-only |
| **M2** Multi-syllabus (model+service) | **⚠️ PARTIAL** | Model `syllabusGoals` exists; `generatePlanFromSyllabus` works — but **planner UI only accepts single course name** |
| **M3** Unused question types | **⚠️ REVISED** | All 10 types now have validation (basic) + rendering (some stubs). Previous report overstated the gap |
| **M4** `suggestNextAction()` | **⚠️ IMPROVED** | Now calls `getRecommendations()` (rule-based) instead of raw hardcoded English. Still **not LLM-driven** |
| **M5** `StudyProgressTracker` ignores sessions | **✅ RESOLVED** | `SessionRepository` injected; session time merged into `totalStudyTimeHours` |
| **M6** LLM Task Manager inaccessible | **✅ RESOLVED** | Settings now has "AI Task Monitor" tile at `settings_screen.dart:90-91` |
| **M7** VoiceController hardcoded en_US | **✅ RESOLVED** | `_localeForSpeech()` / `_localeForTts()` locale mapping methods added |
| **m1** DataBackupService no restore | **❌ STILL MISSING** | No `restoreData()` method |
| **m2** Focus mode not tracked | **✅ RESOLVED** | `SessionRepository` captures focus sessions; `StudyProgressTracker` reads them |
| **m3** Dashboard hidden discovery | **⚠️ UNCHANGED** | Still only accessible via FAB (mobile) / NavigationRail leader (tablet). No bottom tab. |

---

## BLOCKER — App crashes or user cannot proceed

### B1. Tutor image capture still stubbed "Coming Soon"

**Context:** `TutorScreen._pickImage()` at `lib/features/teaching/presentation/tutor_screen.dart:133-136` still shows a SnackBar with `comingSoon`. The vision requires the AI tutor to "interpret handwritten work" via camera/gallery.

**Affected files:**
| File | Change |
|---|---|
| `lib/features/teaching/presentation/tutor_screen.dart:133-136` | Replace stub with real image picker → LLM vision interpretation |
| `lib/features/teaching/services/conversation_manager.dart` | Add `processImage()` accepting image bytes and sending to LLM with appropriate tutor context |
| `lib/features/teaching/presentation/widgets/voice_bar.dart` | Coordinate image capture UI alongside voice bar |

**Dependencies:** `image_picker` package is **not imported** in tutor_screen.dart (exists in upload_screen.dart only — needs dependency audit or reuse).

**Acceptance criteria:**
1. `_pickImage()` opens camera/gallery and passes captured image to `ConversationManager.processImage()`
2. The LLM receives the image with context "The student submitted this work. Analyze and provide feedback."
3. The response appears in the chat flow
4. No new package imports needed if image_picker is uplifted to pubspec.yaml dependency

---

### B2. OCR pipeline passes empty `modelId` — silent data loss

**Context:** `OcrExtractor._extractWithLlm()` at `lib/core/data/extraction/ocr_extractor.dart:125` still passes `modelId: ''` to `_llmService.chat()`. Most LLM providers will reject an empty model ID or silently return empty. Additionally, when no LLM is available, the result silently returns `OcrExtractionResult(text: '')` with no user-facing error.

**Affected files:**
| File | Line | Issue |
|---|---|---|
| `lib/core/data/extraction/ocr_extractor.dart` | 125 | `modelId: ''` |
| `lib/core/data/extraction/ocr_extractor.dart` | 47-51 | Silent empty return when no LLM |
| `lib/features/ingestion/services/document_extractor.dart` | 147-178 | Image extraction continues with empty text |
| `lib/core/data/extraction/transcription_extractor.dart` | 284 | Also passes `modelId: ''` at transcription — same pattern |
| `lib/features/ingestion/services/content_pipeline.dart` | 200 | Upload flow passes `modelId: ''` and `studentId: ''` — parent caller should provide these |

**Fix:**
1. Require `modelId` parameter in `OcrExtractor` and `TranscriptionExtractor` constructors
2. When LLM returns empty, propagate `Result.failure()` instead of silent empty `OcrExtractionResult`
3. Fix `content_pipeline.dart` upload flow to pass actual modelId and studentId from context

**Acceptance criteria:**
1. Uploading an image without a vision-capable model shows a clear error
2. Uploading an image with a vision-capable model returns extracted text
3. `modelId` is never empty when passed to `_llmService.chat()`

---

### B3. Question auto-generation pipeline hardcodes ALL questions as singleChoice

**NEW FINDING.** Context: `ContentPipeline._generateQuestions()` at `lib/features/ingestion/services/content_pipeline.dart:345` explicitly hardcodes `"type": "singleChoice"` in the LLM prompt. The ingestion pipeline can never auto-generate multiChoice, typedAnswer, mathExpression, essay, canvas, or any other type. This means:
- All auto-generated content from uploaded PDFs, URLs, images, and YouTube transcripts results in single-choice questions only
- The vision's "question system is central" promise is severely limited
- Workaround requires manual question creation, which most students won't do

**Affected files:**
| File | Line | Issue |
|---|---|---|
| `lib/features/ingestion/services/content_pipeline.dart` | 318-325, 345 | LLM prompt hardcodes `"type": "singleChoice"` |

**Fix:**
1. Update the LLM prompt to instruct generation of varied question types: `singleChoice`, `multiChoice`, `typedAnswer`, `mathExpression`, `essay`
2. Add `allowedTypes` parameter to let students (or the system) choose which types to generate
3. Validate generated questions parse into the declared type

**Acceptance criteria:**
1. Auto-generated questions include at least `typedAnswer` and `mathExpression` types alongside `singleChoice`
2. Generated questions of each type are correctly parsed and stored
3. Existing singleChoice-only behavior remains default when no type preference is specified

---

## MAJOR — Features broken, misleading, or critically incomplete

### M1. Proactive engagement notifications only fire while app is running

**Context:** `EngagementScheduler` at `lib/core/services/engagement_scheduler.dart:80` still uses `Timer` — tied to the app's process lifecycle. When the app is backgrounded or killed, no nudges fire. The `flutter_local_notifications` package (v0.9.3+2) is present but used only for foreground-triggered notifications. No background scheduling package (`workmanager`, `android_alarm_manager`) is listed in `pubspec.yaml`.

**Affected files:**
| File | Issue |
|---|---|
| `lib/core/services/engagement_scheduler.dart:80` | Timer-based — lost on app close |
| `lib/main.dart:84-99` | Scheduler per-launch, no headless task |
| `pubspec.yaml` | Missing background scheduling package |

**Acceptance criteria:**
1. Nudge checks run at least once every 24h even when app is closed (platform-dependent)
2. On app reopen after >24h, missed nudges are caught up
3. No existing functionality regressed

---

### M2. Multi-syllabus plan creation UI blocks the feature

**Context:** The data model (`PersonalLearningPlan.syllabusGoals`), service layer (`PlannerService.generatePlanFromSyllabus` accepting `List<SyllabusGoal>`), and display code (`_buildSubjectProgressTabs`) all support multi-subject plans. However, the **planner screen UI** at `lib/features/planner/presentation/planner_screen.dart:97-121` only has a single `_courseController` text field and calls `generatePlan(course: ..., ...)` — the single-course path. There is no UI for adding multiple syllabi before generating a plan.

**Affected files:**
| File | Change |
|---|---|
| `lib/features/planner/presentation/planner_screen.dart:97-121` | Add multi-syllabus input UI (list of subject/syllabus pairs with add/remove) |
| `lib/features/planner/providers/planner_providers.dart:263-295` | `generatePlan()` still takes single `course` — needs `List<SyllabusGoal>` path exposed to UI |
| `lib/features/planner/services/planner_service.dart:89-115` | `generatePlan()` still single-course — callers should use `generatePlanFromSyllabus` |
| `lib/features/planner/data/models/personal_learning_plan_model.dart:68-73` | `syllabusGoals` getter reads from metadata — should be a top-level Hive field for queryability |
| **New:** `lib/core/services/remaining_workload_estimator.dart` | Not yet created — calculate "lessons remaining to mastery" per subject |

**Acceptance criteria:**
1. Plan creation UI allows adding 1+ syllabi with subject, days, hours per day
2. Plan generation calls `generatePlanFromSyllabus(List<SyllabusGoal>)` when multiple syllabi present
3. Dashboard shows per-subject stats alongside aggregated stats
4. `RemainingWorkloadEstimator` computes "lessons remaining" per topic
5. Single-course plan creation still works unchanged

---

### M3. `MentorService.suggestNextAction()` still rule-based, not LLM-driven

**Context:** `MentorService.suggestNextAction()` at `lib/features/mentor/services/mentor_service.dart:535-557` calls `_progressTracker.getRecommendations()` which returns **rule-based** messages (accuracy thresholds, study hours). The vision requires the AI mentor to dynamically decide what to study next based on student context. The `_buildContextPrompt()` method already exists for the chat path but is not used here.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/mentor/services/mentor_service.dart` | 535-557 | Rule-based recommendations, not LLM-generated |
| `lib/core/services/study_progress_tracker.dart` | 166-223 | `getRecommendations()` is purely rule-based |

**Acceptance criteria:**
1. `suggestNextAction()` composes an LLM prompt with current student context (weak topics, adherence, recent sessions)
2. Returns an AI-generated contextual recommendation
3. Falls back gracefully if LLM is unavailable (cached last recommendation)
4. Existing `getRecommendations()` rule-based path used as fallback only

---

### M4. TutorScreen has no active voice conversation flow

**NEW FINDING.** Context: While `VoiceController` (195 lines) is fully implemented with speech recognition, TTS, and locale support, and `VoiceBar` widget exists with a microphone button, the `TutorScreen` does not integrate these into an active conversational flow. `_onTranscriptionSubmitted` puts recognized text into `_textController` but the user must still manually press send. There is no back-and-forth voice conversation mode where the AI speaks and listens in turn.

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/teaching/presentation/tutor_screen.dart` | No voice conversation mode — microphone only inputs text, doesn't trigger auto-send |
| `lib/features/teaching/presentation/widgets/voice_bar.dart` | Voice bar exists but tutor screen doesn't activate conversational mode |
| `lib/features/teaching/services/voice_controller.dart` | `startListening()` with auto-stop + auto-send not connected |

**Acceptance criteria:**
1. Tap-to-talk button triggers speech recognition, auto-sends on silence detection
2. AI response is read aloud via TTS after text response arrives
3. User can interrupt AI speaking with new voice input
4. Toggle between voice-only and text-only modes in tutor screen
5. Voice mode respects user's selected app locale

---

### M5. Upload screen does not support audio/video file types despite having extraction pipeline

**NEW FINDING.** Context: `UploadScreen._pickFile()` at `lib/features/ingestion/presentation/upload_screen.dart:67` restricts file types to `['pdf', 'txt', 'md', 'jpg', 'jpeg', 'png', 'docx', 'epub']`. The `DocumentExtractor` and `TranscriptionExtractor` fully support video (YouTube transcripts, LLM transcription) and audio (file transcription, LLM transcription), but **there's no UI path to upload mp3, mp4, wav, m4a, or other media files**. Audio/video content must be pasted as URLs only.

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/ingestion/presentation/upload_screen.dart:67` | `allowedExtensions` missing `mp3`, `mp4`, `wav`, `ogg`, `webm`, `m4a` |
| `lib/core/data/extraction/transcription_extractor.dart:37-58` | Audio file extraction exists but unreachable from upload UI |

**Acceptance criteria:**
1. File picker allows selecting audio/video files (mp3, mp4, wav, m4a, ogg, webm)
2. Selected media files are passed through `DocumentExtractor._extractAudio()` or `_extractVideo()`
3. Transcribed text is stored as source content
4. User sees transcription progress indicator

---

### M6. VoiceBar widget disconnected from TutorScreen lesson flow

**NEW FINDING.** Context: `VoiceBar` (`lib/features/teaching/presentation/widgets/voice_bar.dart`) is a standalone widget with microphone button and transcribed text display. However, `TutorScreen.build()` does not include it in the main input area. The `VoiceController` instance is not shared between `TutorScreen` and `VoiceBar`. There is `_voiceController` in `TutorScreen` state but no `VoiceBar` is rendered.

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/teaching/presentation/tutor_screen.dart` | `VoiceBar` widget not rendered in layout |
| `lib/features/teaching/presentation/tutor_screen.dart` | `_voiceController` exists (likely) but not plumbed to VoiceBar |

**Acceptance criteria:**
1. `VoiceBar` appears in tutor screen input area alongside/below text input
2. Tapping microphone activates speech recognition
3. Recognized text appears and can be sent as a message
4. VoiceBar respects `VoiceController` lifecycle (disposed when leaving screen)

---

## MINOR — Code quality, UX friction, or technical debt

### m1. `DataBackupService` has export-only — no restore function

**Context:** `DataBackupService` at `lib/core/services/data_backup_service.dart` only has `exportAllData()` and `exportSingleBox()`. No `importBackup()`/`restoreData()` exists. No Settings UI entry for backup/restore.

**Acceptance criteria:**
1. `restoreData(String filePath)` method reads a previously exported JSON backup
2. Restore validates format, warns about data overwrite, then imports
3. Settings has "Backup & Restore" section with export and import actions
4. Import shows confirmation dialog with data size preview

---

### m2. CSV export uses `toStringAsFixed()` for hours — correct per convention but redundant

**Context:** `StudyProgressTracker.exportProgressCSV()` at `lib/core/services/study_progress_tracker.dart:291` uses `toStringAsFixed(1)` for totalStudyTimeHours. Per AGENTS.md: "CSV exports should remain in invariant en format (CSV is data, not display)." This is **correct**. Not a bug, just noting consistency is maintained.

✅ No action needed.

---

### m3. Dashboard still not in bottom navigation bar

**Context:** Dashboard accessible only via `FloatingActionButton.small` (mobile) or `NavigationRail` leading (tablet). Not a tab in the `NavigationBar` bottom destinations. Users may not discover it.

**Fix:** Either promote dashboard to its own tab, or add a "Dashboard" entry in the existing settings overflow menu.

---

### m4. No `RemainingWorkloadEstimator` service exists

**Context:** The vision requires: "A relative remaining lesson count should be given by the system towards mastery, so not all lessons must be planned at once." No such service exists. Noted in M2 as a required new file.

---

### m5. Content pipeline passes empty `studentId` and `modelId` in UI upload flow

**Context:** `upload_screen.dart:200-203` passes `studentId: ''` and `modelId: ''` to `processFullPipeline()`. This means uploaded content is not associated with any student in the extraction pipeline. The `ContentPipeline` eventually delegates to `OcrExtractor` and `TranscriptionExtractor` which also receive empty modelId.

**Affected files:**
| File | Line | Issue |
|---|---|---|
| `lib/features/ingestion/presentation/upload_screen.dart` | 200-203 | `studentId: ''`, `modelId: ''` |

**Acceptance criteria:**
1. Upload screen gets studentId from `StudentIdService`
2. Upload screen gets modelId from Settings/selectedModelProvider
3. These values flow through to `ContentPipeline`, `OcrExtractor`, `TranscriptionExtractor`

---

## Dependency Graph & Ordering

```
Phase 1 — Fix BLOCKERS (immediate)
├── B1: Tutor image capture unblock
├── B2: OCR/transcription modelId empty fix
├── B3: Question auto-generation diversity
│
Phase 2 — Critical MAJOR features
├── M1: Background notification scheduling
├── M2: Multi-syllabus plan creation UI + RemainingWorkloadEstimator
├── M3: AI-powered mentor suggestions
│
Phase 3 — Voice & media interaction
├── M4: Voice conversation flow in tutor
├── M5: Audio/video file upload support
├── M6: VoiceBar integration in tutor screen
│
Phase 4 — Data accuracy & polish
├── m1: Data backup/restore
├── m3: Dashboard discoverability
├── m4: RemainingWorkloadEstimator (if not done in Phase 2)
├── m5: StudentId/modelId in upload pipeline
```

## Rationale Summary

The codebase has made measurable progress since the previous planner:
- **5 of 13 issues resolved** (M5, M6, M7, m2, and the LLM task manager accessibility)
- **3 new BLOCKERs discovered** (B3: singleChoice-only generation; plus the existing B1/B2 unresolved)
- **2 new MAJOR gaps identified** (M4: no voice conversation in tutor; M5: no audio/video upload UI; M6: VoiceBar not wired into tutor)

The critical remaining gaps in order of student impact:

1. **Vision-interaction gap (B1/B2):** The tutor cannot see/interpreter student work. Still the #1 promised feature not delivered.
2. **Auto-generation monoculture (B3):** The ingestion pipeline only creates singleChoice questions. Uploading any content yields only multiple-choice — severely limiting practice depth.
3. **Proactive mentor gap (M1):** The "persistent mentor" only exists while app is open. No 24/7 engagement.
4. **Multi-subject gap (M2):** The vision's core claim — multi-syllabus learning — has backend support but no UI to use it.
5. **Voice interaction gap (M4/M6):** VoiceController infrastructure exists but is disconnected from the actual tutoring experience.
6. **Media ingestion gap (M5):** Video/audio extraction pipeline exists but users can only paste URLs — no file upload path.

**further_issues directory:** Not present. No user-reported issues to integrate.
