# Dry-Run Usability Validation: Practice Tab & Question Generation

**Scenario:** `dry-run-test/scenario_practice_tab_no_questions.md`
**Date:** 2026-05-17
**Method:** Static code trace of Practice tab, upload pipeline, question generation, practice session flow

---

## BLOCKER — App crashes or user cannot proceed

### B1. Upload pipeline never generates questions for the Practice tab

**Summary:** The upload screen calls `processFullPipeline()` with `generateQuestions: false`. Even if enabled, `studentId` and `modelId` are empty strings, so LLM generation would fail. The only way to get practice questions is via tutor lessons.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/ingestion/presentation/upload_screen.dart` | 207-208 | `studentId: ''`, `modelId: ''` passed to pipeline |
| `lib/features/ingestion/presentation/upload_screen.dart` | 212 | `generateQuestions: false` hardcoded |
| `lib/features/ingestion/services/content_pipeline.dart` | 307-345 | `_generateQuestions()` exists and works but is never invoked from upload |
| `lib/features/ingestion/services/content_pipeline.dart` | 200 | Same empty params in `processFullPipeline` definition |

**Why BLOCKER:** Without questions, the Practice tab is permanently empty for any user who only uploads content. The "question system is central to the product vision" (agent_must_read.md), but the only question-creation path from uploaded content is explicitly disabled.

**Acceptance criteria:**
- [ ] `UploadScreen` passes a real `studentId` (from `StudentIdService`) and `modelId` (from selected model provider) to `processFullPipeline()`
- [ ] `UploadScreen` provides a toggle or default `generateQuestions: true` for the pipeline
- [ ] After upload completes and questions are generated, the Practice tab shows available questions on next visit
- [ ] Unit test: `UploadScreen` calls pipeline with non-empty studentId and modelId
- [ ] Integration test: Upload a PDF → questions appear in Practice tab

---

### B2. Upload pipeline passes empty `studentId` and `modelId` — downstream LLM calls guaranteed to fail

**Summary:** Even if `generateQuestions` were true, the empty `studentId` breaks topic classification (content not linked to student) and empty `modelId` causes the LLM provider to reject the request.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/ingestion/services/content_pipeline.dart` | 200 | `processFullPipeline` receives and forwards empty IDs |
| `lib/core/data/extraction/ocr_extractor.dart` | 125 | `modelId: ''` — LLM call will fail |
| `lib/core/data/extraction/transcription_extractor.dart` | 284 | Same empty modelId pattern |

**Acceptance criteria:**
- [ ] `studentId` is passed through all extraction stages
- [ ] `modelId` is passed through all extraction stages
- [ ] Error shown to user when no model is configured instead of silent empty results

---

## MAJOR — Feature is broken, misleading, or critically incomplete

### M1. Practice tab shows all modes as available even with zero questions

**Summary:** When a user has subjects but no questions (the normal state after first adding a subject), the Practice tab displays the full mode grid with no indication that all modes will fail due to missing questions. Quick Practice shows "10 random questions" as if they exist. All modes result in various error dialogs/snackbars.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/practice/presentation/screens/practice_screen.dart` | 378-400 | `_buildBody()` shows full grid when `_subjects.isNotEmpty` — no check for question existence |
| `lib/features/practice/presentation/widgets/practice_mode_grid.dart` | 47-53 | Quick Practice shows static "10 random questions" regardless of actual count |
| `lib/features/practice/presentation/screens/practice_session_screen.dart` | 102-130 | `_loadQuestions()` shows no-questions dialog but caller (`_startPractice`) doesn't check first |

**Acceptance criteria:**
- [ ] Practice screen checks `_questionRepo.getBySubject()` count on load
- [ ] When count is 0, show "Upload materials to generate questions" CTA instead of/in addition to the mode grid
- [ ] Random question count in Quick Practice card reflects actual available count
- [ ] All mode cards are visually dimmed when count is 0, with explanation on tap

---

### M2. "No Questions Available" dialog has no action buttons

**Summary:** When `_loadQuestions()` finds zero questions, it shows a dialog with title and body only — no buttons, no suggested next action.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/practice/presentation/screens/practice_session_screen.dart` | 147-157 | `_showNoQuestionsDialog()` — no buttons, just text |
| `lib/features/practice/presentation/screens/exam_session_screen.dart` | 130-145 | Same pattern in exam mode |

**Acceptance criteria:**
- [ ] Dialog has "Upload Materials" button that navigates to upload
- [ ] Dialog has "Cancel" or "Go Back" button
- [ ] Dialog uses `AlertDialog.actions` properly

---

### M3. Back button during practice session exits without confirmation and skips session finalization

**Summary:** Pressing the system back button during a practice session immediately pops back to the Practice screen. The session is never auto-saved nor is adherence recorded. Mastery data for individual answers is saved (from `_submitAnswer`) but the session record is lost.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/practice/presentation/screens/practice_session_screen.dart` | 349-484 | No `PopScope` or `WillPopScope` on the scaffold |
| `lib/features/practice/presentation/screens/practice_session_screen.dart` | 241-258 | `_completeSession()` handles finalization but is only called from `_nextQuestion()` when reaching the end |
| `lib/features/practice/presentation/screens/practice_session_screen.dart` | 228 | `_completeSession()` not called on back navigation |

**Acceptance criteria:**
- [ ] Add `PopScope(canPop: false, onPopInvokedWithResult: ...)` that shows confirmation dialog
- [ ] On confirm, call `_completeSession()` before popping
- [ ] On cancel, stay in session

---

### M4. Practice session results are not consumed by the Practice screen

**Summary:** `_navigateToResults()` pops the PracticeSessionScreen with a `PracticeSessionResult` via `Navigator.pop(result)`, but `_startPractice()` uses `pushNamed()` without `await`, so the result is discarded.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/practice/presentation/screens/practice_screen.dart` | 95-98 | `_startPractice()` uses `pushNamed` without awaiting result |
| `lib/features/practice/presentation/screens/practice_session_screen.dart` | 302-311 | `_navigateToResults()` returns data nobody reads |
| `lib/features/practice/presentation/screens/practice_screen.dart` | 80-92 | `_loadDueCounts()` only called in initState — not refreshed |

**Acceptance criteria:**
- [ ] `_startPractice()` `await`s the push result and refreshes due counts on return
- [ ] Spaced repetition due counts update immediately after session
- [ ] Unit test: verify `_loadDueCounts` is called after session completes

---

### M5. Practice results screen lacks topic breakdown

**Summary:** `PracticeResultsScreen` shows only total questions, correct count, and accuracy. `ExamSessionScreen` results show topic breakdown (`result.topicBreakdown`). The regular practice screen has the data (`_answerRecords` contains `questionId` which links to questions with `topicId`) but never computes or displays the breakdown.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/practice/presentation/screens/practice_results_screen.dart` | 19-67 | No topic breakdown section |
| `lib/features/practice/presentation/screens/exam_session_screen.dart` | 514-524 | Exam mode has topic breakdown |
| `lib/features/practice/presentation/screens/practice_session_screen.dart` | 61, 181-187, 302-311 | `_answerRecords` stores questionId data but never aggregates by topic |

**Acceptance criteria:**
- [ ] `PracticeResultsScreen` receives topic breakdown data
- [ ] Results show per-topic accuracy (like exam mode)
- [ ] Pass topic breakdown alongside PracticeSessionResult or compute from _answerRecords

---

### M6. Tutor-generated practice questions are low-quality stubs

**Summary:** `TutorService._persistExercisesAsQuestions()` creates questions with text `"Tutor exercise: {topicTitle}"` — this is the topic name, not the actual question the tutor asked. The actual exercise content is lost.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/teaching/services/tutor_service.dart` | 202 | Question text is "Tutor exercise: Atomic Structure" rather than the actual question |

**Acceptance criteria:**
- [ ] `_persistExercisesAsQuestions()` captures the actual question the tutor asked (from conversation history)
- [ ] The stored question text is the full exercise text, not a generic template
- [ ] `options` list is populated for multiple-choice exercises

---

### M7. Only 2 of 10 question types are reachable through any generation path

**Summary:** `QuestionType` enum defines 10 types. The content pipeline hardcodes `singleChoice`. The tutor generates `typedAnswer` stubs. Canvas, essay, multiChoice, mathExpression, graphDrawing, fileUpload, audioRecording, and stepByStep types have widgets that render correctly but no questions of these types are ever created.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/ingestion/services/content_pipeline.dart` | 345 | `type = QuestionType.singleChoice` hardcoded |
| `lib/features/ingestion/services/content_pipeline.dart` | 318-325 | LLM prompt instructs only singleChoice |
| `lib/core/data/enums.dart` | 3-14 | 10 types defined, 8 unreachable |
| `lib/features/practice/presentation/widgets/practice_session_question_card.dart` | 154-198 | Switch handles all 10 types, 8 are dead code paths |

**Acceptance criteria:**
- [ ] LLM prompt in `_generateQuestions()` instructs generation of `multiChoice`, `typedAnswer`, `mathExpression` alongside `singleChoice`
- [ ] Generated type is validated, not overridden
- [ ] At least 3 question types are reachable by end of Phase 1

---

### M8. No progress indicators on the Practice tab

**Summary:** The Practice tab shows a static mode grid and subject cards. There's no recent activity summary, no accuracy trend, no "questions answered today" counter. The `FocusTimerScreen` has a `SessionSummaryCard` and the Dashboard has progress charts, but the Practice tab has nothing.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/practice/presentation/screens/practice_screen.dart` | 350-454 | No stats/activity display anywhere in widget tree |

**Acceptance criteria:**
- [ ] Practice tab shows a summary row: questions today, current accuracy streak, due count
- [ ] Summary is pulled from `StudyProgressTracker` or equivalent
- [ ] Summary updates when returning from a practice session

---

### M9. Quick Practice mode description is misleading

**Summary:** The Quick Practice card subtitle is hardcoded to `l10n.randomQuestions(10)` = "10 random questions" regardless of actual available count.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/practice/presentation/widgets/practice_mode_grid.dart` | 47-53 | Static "10 random questions" subtitle |

**Acceptance criteria:**
- [ ] Subtitle shows actual count: "X questions available"
- [ ] When count < 10, it shows available count
- [ ] When count is 0, subtitle reads "Upload materials to create questions"

---

### M10. Exam mode lets user configure duration/question count before checking if questions exist

**Summary:** `ExamSessionScreen` shows configuration UI (duration, question count) before `_loadQuestions()` completes. If the result is empty, the user has already configured everything before seeing the error.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/practice/presentation/screens/exam_session_screen.dart` | 288-290 | `_buildConfigScreen()` always shown when `!_isExamActive && !_examFinished` — no early empty-state check |

**Acceptance criteria:**
- [ ] `ExamSessionScreen` checks question count on load
- [ ] If count is 0, shows empty-state CTA directly (not configuration UI)
- [ ] Configuration fields show the actual total question count as upper bound

---

### M11. Source Practice reports "No sources available" after upload

**Summary:** `SourcePracticeSheet` groups questions by `sourceIds`. Since the content pipeline creates no questions (B1), the source map is always empty even when sources exist in the system.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/practice/presentation/screens/practice_screen.dart` | 225-274 | `_showSourcePracticeSheet()` groups questions, not sources |
| `lib/features/practice/presentation/widgets/source_practice_sheet.dart` | (full file) | Displays sources only if questions link to them |

**Acceptance criteria:**
- [ ] Once B1 is resolved, sources are listed with question counts
- [ ] Sources with zero questions show "0 questions — generate questions from this source"
- [ ] Direct link to re-process a specific source with question generation

---

## MINOR — UX friction, polish, or technical debt

### m1. No manual question creation UI

**Summary:** There is no screen or form for users to create questions manually. All questions must come from LLM generation (which is broken per B1/B2) or tutor lessons (which produce stubs per M6).

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| (new feature needed) | — | No UI for manual question creation exists anywhere in the app |

**Acceptance criteria:**
- [ ] Settings or subject detail has "Create Question" button
- [ ] Form allows selecting type, entering text, options, correct answer, explanation
- [ ] Manual questions are persisted through the existing QuestionRepository

---

### m2. Weak areas message is misleading for new users

**Summary:** When no mastery data exists, `_startWeakAreasPractice` shows "No weak areas found" — this reads like a compliment ("you're doing great!") rather than indicating "practice first, then we can identify weak areas."

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/practice/presentation/screens/practice_screen.dart` | 130-140 | `_launchWeakAreasForSubject()` shows "No weak areas found" |

**Acceptance criteria:**
- [ ] Message distinguishes: "Practice at least 10 questions to identify weak areas" vs. "No weak areas found — great job!"
- [ ] Check `_masteryRecorder` has any attempts before showing "no weak areas"

---

### m3. Topic Focus empty state has no guidance

**Summary:** When `loadTopics()` returns empty, a SnackBar says "No topics available" — no CTA to upload materials or create topics.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/practice/presentation/screens/practice_screen.dart` | 290-310 | `_showTopicSelector` — empty state just shows SnackBar |

**Acceptance criteria:**
- [ ] Show dialog with "Upload materials to generate topics" when list is empty
- [ ] Include navigation button to upload screen

---

### m4. Practice screen does not auto-refresh after returning from session

**Summary:** `_loadDueCounts()` and `_loadSubjects()` are only called in `initState`. After completing a practice session, the user returns to the same widget instance (not recreated). Due counts and subject lists are stale until pull-to-refresh.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/practice/presentation/screens/practice_screen.dart` | 58-59 | `_loadSubjects()` only called in `initState` |

**Acceptance criteria:**
- [ ] After pushNamed returns (see M4), call `_loadDueCounts()` to refresh
- [ ] Alternatively, use `AsyncAutomaticKeepAliveClientMixin` with periodic refresh
