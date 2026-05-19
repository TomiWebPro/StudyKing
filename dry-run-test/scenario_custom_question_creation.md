# Dry-Run Scenario: Creating and Managing Custom Questions — The Self-Made Flashcard Journey

## Persona

I'm a student who has been using StudyKing for a few weeks. I've uploaded my IB Chemistry textbook PDF and the AI generated some practice questions, but they're all multiple-choice and don't cover the specific things I want to memorize. I want to **create my own questions** — like digital flashcards — covering the exact content I'm studying. I also want to share my custom questions with a study partner and see my practice results.

I expect to be able to:
1. Easily find where to add a new question
2. Create questions in various formats (flashcard-style Q&A, multiple choice, fill-in-the-blank)
3. Assign questions to subjects and topics
4. Practice with my custom questions alongside AI-generated ones
5. Share or export my custom question bank
6. View my performance on custom vs AI-generated questions separately

---

## Step 1: Finding Where to Add a Question — The Hidden FAB

I want to create a flashcard for a chemistry concept. I look for an "Add Question" or "Create Flashcard" button.

**What I expect:** A clear "Create" or "+" button on a screen I visit regularly — ideally the **Practice tab** (where I answer questions) or the **Subjects tab** (where I manage my learning materials). Maybe a FAB that says "Create Question" or a card titled "My Flashcards."

**What actually happens:** There is no question creation functionality on the Practice tab, the Subjects tab, or the Dashboard. I search each screen:

- **Practice tab** — Shows mode grid (Quick Practice, Spaced Repetition, Topic Focus, Weak Areas, Exam Mode, Source Practice). There's a small "Question Bank" card in the Extra Modes section at the bottom. No FAB, no "Create Question" button.
- **Subjects tab** — Shows my IB Chemistry subject. I tap it. The subject detail has 4 tabs: Lessons, Practice, History, Stats. The "more options" menu has: Upload Content, Dashboard, Delete Subject. **No question management option.**
- **Dashboard** — Has 10+ cards of stats. There's a "Question Bank" card near the bottom that navigates to the question bank screen. **No create option.**
- **Settings** — Has "Content Management → Question Bank" 2 levels deep.

**The only path to create a question:** Settings → Content Management → Question Bank → tap the FAB (a small "+" icon in the bottom-right, `question_bank_screen.dart:514-517`). The FAB is the only way to create a question, and users must navigate 2+ levels through a settings menu to find it.

**Verdict (BLOCKER FAIL):** There is no direct "Create Question" button on the Practice tab, Subjects tab, or Dashboard — the three screens users interact with most. The Question Bank is buried 2 levels deep in Settings. Users naturally looking to create questions won't find the path without prior knowledge.

---

## Step 2: Using the Create Question Dialog — Multi-Choice Is Broken Immediately

I finally find the FAB and tap it. A create dialog appears.

**What I expect:** A well-designed form where I can type my question, select the type, pick the subject and topic, add answer options, mark the correct answer, and save.

**What actually happens — the bugs cascade:**

**Bug 1 — Multi-choice checkbox is non-functional.** If I select `multiChoice` as the question type ("multiple correct answers"), the checkbox UI renders at `question_bank_screen.dart:372-375`:
```dart
Checkbox(
  value: false,        // Hardcoded false — never changes
  onChanged: null,     // null — tapping does nothing
),
```
The `onChanged` is explicitly `null`. The `value` is hardcoded to `false`. I literally cannot select multiple correct answers. The radio button for single-choice works (`Radio<int?>(value: i)` with proper `groupValue` from `RadioGroup`), but the checkbox for multi-choice is completely inert. If I try to create a multi-choice question, I can add options but cannot indicate which are correct.

**Bug 2 — No topic selection.** The dialog has fields for question text, subject, type, difficulty, options, and explanation. **There is no topic selector.** `topicId` is hardcoded to `''` at line 445. My custom question about "Atomic Structure" cannot be associated with the Atomic Structure topic. It will appear as "unassigned" in the question bank list. The question bank's topic filter will never find it.

**Bug 3 — No source assignment.** `sourceIds` is empty (`''`). If I created this question after reading page 47 of my uploaded Chemistry textbook PDF, I cannot link my custom question to that source. The question floats without provenance.

**Bug 4 — `generatedBy` defaults to `'ai'` even for manual questions.** At `question_model.dart:104`, the default for `generatedBy` is `'ai'`. The `_showCreateQuestionDialog()` at line 477-496 never passes `generatedBy: 'manual'`. So my manually typed question is internally tagged as "AI-generated." The chip display at line 627-630 partially compensates — it shows `l10n.manual` when `q.model == null` (which is true for custom questions since no `model` is set) — but the `generatedBy` field itself is wrong. This is misleading for any consumers of `generatedBy` in the data layer.

**Bug 5 — Report count is not persisted across restarts.** The `reportCount` field at `question_model.dart:80` lacks a `@HiveField` annotation. It is only in-memory. If I flag a question, and the app restarts, the report count resets to 0. This makes the flagging system unreliable for tracking problematic questions.

**Bug 6 — No markscheme steps for `stepByStep` type.** If I select `stepByStep` as the question type, there is no UI for defining evaluation steps or individual grading criteria. The `Markscheme` is used generically for the correct answer, without step-by-step breakdown support.

**Verdict (MAJOR FAIL):** The create question dialog has at least 4 functional bugs:
1. Multi-choice checkbox is non-functional (`onChanged: null`)
2. No topic selection — `topicId` is always empty
3. No source association — `sourceIds` is always empty
4. Manual questions tagged as `'ai'` in `generatedBy`
5. `reportCount` not persisted (only in-memory)
Manually created questions cannot be organized into topics, linked to sources, or properly tagged as user-created.

---

## Step 3: After Saving — Where Did My Question Go?

I manage to create a simple single-choice question (the only working type). The dialog closes, a SnackBar says "Question created," and my new question appears in the question bank list.

**What I expect:** I can now practice this question. It should appear in Quick Practice, Topic Focus, and Spaced Repetition modes.

**What actually happens:** The question IS saved to the repository and DOES appear in the question bank. It IS picked up by `QuestionRepository.getBySubject()` and `getAll()`. So it WILL appear in practice sessions.

But there's a problem: **my question has no topicId**. In the Practice tab → Topic Focus mode, questions are filtered by topic display name string matching (`practice_screen.dart:142-169`: `q.topic == topic`). Since my question's `topic` (the denormalized name field at `Question.topic`, not `topicId`) is also `null` (never set in the dialog), the string comparison `q.topic == topic` will never match. My custom question will be invisible in Topic Focus mode.

Furthermore, the **Spaced Repetition** mode assigns `nextReview` dates via the SM-2 algorithm only after I answer the question — but initially, `nextReview` is null. The question will appear in Quick Practice (which just shuffles all questions), but not in any focused practice mode without a topic.

**Verdict (MAJOR FAIL):** Custom questions without topics are invisible in Topic Focus mode and may be missed by spaced repetition scheduling until first answered.

---

## Step 4: Editing and Curating My Custom Questions

I want to fix a typo in my question or update the explanation.

**What I expect:** Long-press or tap my question → see an "Edit" option → change the text → save.

**What actually happens:** Tapping a question in the question bank opens an **edit dialog** (line 592: `_editQuestion(q)`). The edit dialog at lines 227-256 lets me edit **only the question text and explanation**. I cannot:
- Change the subject after creation
- Change the question type after creation
- Add or modify answer options
- Change the difficulty
- Assign a topic
- Add a source link

The `_editQuestion()` method uses a generic `AlertDialog` with two text fields — it's a simplified version of the create dialog. This means any mistake in the initial creation requires deleting and recreating the question.

**Verdict (MAJOR FAIL):** The edit dialog only supports text and explanation changes. Subject, type, options, difficulty, topic, and source are immutable after creation.

---

## Step 5: Sharing Custom Questions with a Study Partner

I've carefully crafted 15 custom questions covering stoichiometry. My classmate is also studying IB Chemistry. I want to share these questions with them.

**What I expect:** A "Share" or "Export" button on the question bank that lets me export my questions as CSV, JSON, or a shareable format. My classmate can import them on their StudyKing installation.

**What actually happens:** The Question Bank screen has **zero export functionality** (`question_bank_screen.dart:1-898`). Searching the entire file:
- No `share_plus` or `ExportService` imports
- No share/export button in the AppBar or body
- No multi-select export mode (the multi-select is for delete only)
- No "Share" option in the question's popup menu (which only has: edit, verify, report, delete)

The `ProgressExportService` methods (`exportComprehensiveCSV`, `shareComprehensiveCSV`, etc.) export session stats and attempts — but NOT questions. There is no question export service anywhere in the codebase.

**The only way to share questions:** Use Settings → Backup & Restore → Export Backup, which exports ALL data including questions. But this:
1. Exports everything (subjects, sessions, settings, API keys), not just questions
2. Cannot selectively export only custom questions (vs AI-generated)
3. Cannot be imported by another user without overwriting their entire database
4. Contains the API key (security risk when sharing)

**Verdict (BLOCKER FAIL):** Custom questions cannot be exported, shared, or imported independently. There is no question-specific export format (CSV, JSON, or otherwise). The only export path is a full database backup that includes sensitive data and cannot be selectively imported.

---

## Step 6: Importing Questions from My Classmate

My classmate managed to export their full backup file. They send it to me. I want to import only the questions, not their entire database.

**What I expect:** A selective import: "Choose what to import" with checkboxes for Subjects, Questions, Sessions, etc.

**What actually happens:** The Backup & Restore screen at Settings does support selective restore (`_importBackup` in `settings_screen.dart`). I can choose which boxes to import and select "merge" mode.

**But there are problems:**
1. The backup includes ALL data boxes, not just questions. Even with selective restore, I must know that questions are stored in a "questions" box.
2. If my classmate and I both have questions with the same ID (e.g., both have a question with `id: "1700000000000"` based on timestamp), the merge might create conflicts.
3. Question-source and question-topic relationships will be broken if I import questions without also importing the corresponding subjects, topics, and sources.
4. API keys from my classmate's backup would need to be explicitly excluded — the restore dialog shows box names like "Settings" which includes the API key, but the user may not realize this.

**Verdict (PARTIAL):** Selective restore exists but is a blunt instrument. Sharing individual questions requires full-database backup and restore with all the associated complexity and risks.

---

## Step 7: Finding and Practicing Custom Questions

After creating several custom questions, I want to practice them specifically — just my flashcards, not the AI-generated ones.

**What I expect:** A filter or mode: "Practice my custom questions" or "My Flashcards." Or at least a subject/topic filter that includes my custom questions.

**What actually happens:** The Practice tab's mode grid has no "Custom Questions" or "My Flashcards" mode. The existing modes (Quick Practice, Spaced Repetition, Topic Focus, Weak Areas) mix AI-generated and manually created questions without distinction.

The question bank displays each question with a chip showing `q.model != null ? l10n.aiGenerated : l10n.manual` (line 627-630). So I CAN see which is which in the bank. But I cannot:
- Filter by manual/ai in the question bank (filters are subject, type, source, and search text only — no `generatedBy` filter)
- Practice only manual questions (no such mode or filter exists in the Practice tab)
- See custom/AI breakdown in my practice history

**Verdict (MAJOR FAIL):** The question bank shows the manual/AI distinction but has no filter for it. The Practice tab has no "Custom Questions" or "My Flashcards" mode. Custom questions are mixed indistinguishably with AI-generated ones during practice.

---

## Step 8: Viewing Practice Results — Can I See How I Did on Custom Questions?

I complete a practice session that included both my custom flashcards and AI-generated questions.

**What I expect:** The results screen shows a breakdown: which questions I got right/wrong, with a filter to see custom vs AI-generated performance. Maybe I can see "Custom questions: 5/7 correct (71%)" and "AI-generated: 8/10 correct (80%)".

**What actually happens:** The `PracticeResultsScreen` (`practice_results_screen.dart:1-112`) shows:
- Total questions, correct answers, accuracy %
- Topic breakdown (per-topic accuracy)
- "Practice Again" button
- "Review Mistakes" button

There is no breakdown by `generatedBy` (custom vs AI). There is no per-question detail on the results screen. The Review Mistakes screen shows individual questions but doesn't distinguish source type.

Furthermore, the `PracticeSessionResult` that is passed back via `Navigator.pop()` at the end of a session is **never captured** by the calling code in `practice_screen.dart` (as documented in prior scenarios). The result is lost.

**Verdict (MAJOR FAIL):** Practice results show no distinction between custom and AI-generated questions. Users cannot evaluate whether their custom flashcards are effective. Session results are also lost on return to the Practice screen.

---

## Step 9: Sharing My Practice Results

I aced my stoichiometry practice with my custom flashcards. I want to share my results with my study group.

**What I expect:** A "Share Results" or "Export Results" button on the Practice Results screen.

**What actually happens:** The `PracticeResultsScreen` has exactly 2 action buttons: "Practice Again" and "Review Mistakes" (`practice_results_screen.dart:72-93`). There is no share button, no export button, no "Send to..." option. The screen has a plain `AppBar` with just a title and a back button (line 30).

To share anything resembling my practice results, I would need to:
1. Navigate back to the Practice screen
2. Navigate to the Dashboard
3. Scroll to the Export section at the bottom
4. Use one of the CSV/PDF/JSON export options

These exports contain comprehensive session stats but NOT per-question breakdowns specifically tagged as "custom question performance."

**The `ExportSection` widget** on the Dashboard has 6 export buttons — all for comprehensive progress data. None for per-session results.

**Verdict (MAJOR FAIL):** Practice results cannot be shared from the results screen. Users must navigate to a completely separate screen (Dashboard) and use a generic export not designed for per-session sharing.

---

## Step 10: How Do Custom Questions Affect Mastery Tracking?

I notice my custom flashcards don't have a stated difficulty level (they default to `difficulty: 1` since the dialog defaults to "easy"). I also wonder how they affect my mastery stats.

**What I expect:** The app tracks my performance on custom questions separately or at least accurately, since these are the questions I specifically created to help with my weak areas.

**What actually happens:** Custom questions are treated identically to AI-generated questions in the mastery engine. `MasteryRecorder.recordAttempt()` records attempts against the question ID regardless of `generatedBy`. The `MasteryGraphService` computes topic-level mastery using ALL attempts for that topic.

**The issue:** Since my custom questions have `topicId: ''` (empty string), the mastery system has no topic to attribute them to. The `MasteryGraphService.getTopicMastery()` at `mastery_graph_service.dart` builds mastery maps keyed by `question.topicId`. Questions with `topicId: ''` are grouped under an empty-string key. Their contribution to any *named* topic's mastery is zero. My custom Stoichiometry flashcards, despite being about Stoichiometry, contribute nothing to my Stoichiometry mastery score because their `topicId` is empty.

This means:
- Practicing with custom questions does NOT improve the displayed topic mastery for Stoichiometry
- The "Weak Areas" detection will never flag my custom-question weaknesses because they're not linked to any topic
- Spaced repetition for custom questions works (SM-2 on individual question IDs), but the aggregate mastery display is misleading

**Verdict (MAJOR FAIL):** Custom questions have empty `topicId`, so their practice data doesn't contribute to any topic's mastery score. The user's effort creating and practicing custom flashcards is invisible in the mastery tracking system.

---

## Step 11: Verification and Trust — Correcting Custom Questions

After practicing, I realize one of my custom questions has the wrong answer marked as correct. I need to fix it.

**What I expect:** Open the question, see the edit dialog, change the correct answer selection, save.

**What actually happens:** The edit dialog (`_editQuestion()`, lines 227-271) only has text and explanation fields. There is no way to change the answer options or correct answer after creation. The question must be deleted and recreated.

The `_deleteQuestion()` method (around line 175) prompts for confirmation and shows an undo snackbar. This works. But having to recreate from scratch means re-entering all the question text, explanation, options — a UX regression.

**Verdict (MAJOR FAIL):** The edit dialog is too limited. It can only modify text and explanation. Changing options, correct answer, type, subject, difficulty, or topic requires deletion and full recreation.

---

## Step 12: Creating Questions During a Practice Session

While practicing, I realize there's a concept the AI didn't generate a question for. I want to create a flashcard immediately.

**What I expect:** During the practice session, a button or gesture lets me "Create a similar question" or "Add this concept as a flashcard." I can quickly type a question and answer without leaving the session.

**What actually happens:** The `PracticeSessionScreen` (890 lines) has no question creation capability. The only "on-the-fly" action is flagging the current question for review via `_flagCurrentQuestion()` at line 482 (`question_bank_screen.dart:500-512` is the flag dialog method). The flagging reports an existing question — it does NOT create a new one.

There is no mechanism to pause the session, create a new question, and resume. The user must exit the session, navigate to the question bank (2 levels deep in Settings, or via Practice → Extra Modes → Question Bank), create the question, return to Practice, and hope their session state is preserved.

**Verdict (BLOCKER FAIL):** Custom questions cannot be created during practice sessions. Users must abandon their session to create a question, and there is no "create from practice" flow.

---

## Step 13: The Practitioner's Perspective — Batch Creating Multiple Questions

I want to create 20 flashcards for my exam. Doing them one-by-one through the dialog would take forever.

**What I expect:** A batch import feature — maybe paste a CSV or structured text, or an "Add Multiple" mode.

**What actually happens:** There is no batch import. The only way to create questions is one-at-a-time through the `AlertDialog`. Each question requires:
1. Tapping the FAB
2. Filling in the form
3. Tapping Save
4. Dialog closes
5. Scrolling to find the new question
6. Repeating 19 more times

For 20 questions, this is 80+ form interactions with no way to speed up the process. There is no "Add another" checkbox or "Save and add another" button.

**Verdict (MAJOR FAIL):** No batch import or quick-add mode. Each custom question requires a full dialog workflow with navigation overhead.

---

## Summary of Expectations vs Reality

| # | Expectation | Reality | Status |
|---|---|---|---|
| 1 | "Create Question" button is on Practice or Subjects tab | Only reachable 2 levels deep in Settings → Content Management → Question Bank → FAB | **FAIL (BLOCKER)** |
| 2 | Multi-choice checkbox allows selecting multiple correct answers | `onChanged: null` — checkbox is non-functional | **FAIL (BLOCKER)** |
| 3 | Topic selection available when creating a question | No topic selector — `topicId` hardcoded to `''` | **FAIL (MAJOR)** |
| 4 | Custom question can be linked to a source | No source selection — `sourceIds` always `[]` | **FAIL (MAJOR)** |
| 5 | Manual questions tagged as `generatedBy: 'manual'` | Defaults to `'ai'` — not overridden in create dialog | **FAIL (MAJOR)** |
| 6 | `reportCount` persists across restarts | No `@HiveField` annotation — only in-memory | **FAIL (MAJOR)** |
| 7 | Edit dialog allows changing all question fields | Only text and explanation can be edited | **FAIL (MAJOR)** |
| 8 | Custom questions can be exported/shared | No question export exists anywhere in the app | **FAIL (BLOCKER)** |
| 9 | Custom questions can be imported individually | Only full-database backup/restore with security risks | **FAIL (BLOCKER)** |
| 10 | Practice tab has "My Flashcards" or "Custom Questions" mode | No such mode — custom questions mixed with AI ones | **FAIL (MAJOR)** |
| 11 | Question bank has `generatedBy` filter | Filters: subject, type, source only — no manual/AI toggle | **FAIL (MAJOR)** |
| 12 | Practice results show custom vs AI breakdown | Results show total/topic only — no source type distinction | **FAIL (MAJOR)** |
| 13 | Practice results can be shared | Results screen has no share/export button | **FAIL (MAJOR)** |
| 14 | Custom questions contribute to topic mastery | Empty `topicId` means zero contribution to displayed topic mastery | **FAIL (MAJOR)** |
| 15 | Options/correct answer can be edited after creation | Edit dialog is text-only; options immutable | **FAIL (MAJOR)** |
| 16 | Questions can be created during practice sessions | No creation mechanism in practice session screen | **FAIL (BLOCKER)** |
| 17 | Questions can be batch-imported (CSV, etc.) | No batch import — one-at-a-time dialog only | **FAIL (MAJOR)** |
| 18 | Save dialog supports "Save and add another" | Dialog closes after save — must re-navigate to FAB | **FAIL (MINOR)** |
| 19 | Custom questions appear in Topic Focus mode | `topic` field is null — string-matching filter misses them | **FAIL (MAJOR)** |

(End of file - total 377 lines)
