# Dry-Run Scenario: Focus Mode & Study Hub — The Daily Deep-Work Learning Journey

## Persona

I'm a student who has been using StudyKing for about a week. I've created **IB Chemistry** and **IB Physics** subjects, uploaded textbooks for both, practiced about 40 questions total across both subjects, and attended 2 AI tutor lessons. I'm getting into a daily study routine. I open the **Focus Mode** tab (5th tab in bottom nav) because I want a **distraction-free study session** where I can review due questions, practice my weak areas, and track my focus time — all in one place.

I expect the app to:
1. Clearly explain what Focus Mode is when I first open it — is it timer-first or practice-first?
2. Let me practice questions **inline** without leaving the screen (since that's the point of "Focus Mode")
3. Show me my due reviews and weak areas upfront so I know what to work on
4. Let me start a timer session that actually links to practicing — not just counting minutes
5. Track my focus minutes accurately across sessions and days
6. Show me meaningful stats after each session (how many questions, accuracy, time spent)
7. Remember my inline practice results so I can review them later
8. Respond to the session type I chose (Quick Practice vs Spaced Repetition vs Weak Area Attack)
9. Use the duration suggested by the tutor when I'm sent here from a lesson

---

## Step 1: First Visit to Focus Mode — The Onboarding

I tap the **Study (Focus Mode)** tab for the first time. I see a help icon that I can tap in the app bar.

**What I expect:** A clear, brief explanation of what Focus Mode is and what I can do here. Something like: "Focus Mode is your daily study hub. Use the timer to track deep work sessions, or practice questions inline from the study hub below."

**What actually happens:**

I see the screen with a "Study Hub" toggle switch at the top (`focus_timer_screen.dart:693-725`), a loading indicator, then a list of subject cards with due counts, and two action buttons. If I scroll down, there's a stats card (`SessionSummaryCard` focus_timer_screen.dart:634-639).

There IS an onboarding mechanism:
- `SettingsBox` has a `firstFocusVisit` flag (`settings_box.dart:79`), default `true`
- `_initService()` at `focus_timer_screen.dart:126-132` reads it and sets `_showOnboarding = true`, then clears the flag
- An onboarding card appears at line 586-589: `_buildOnboardingCard` (line 647-691)
- But this onboarding card is just a generic help message — it doesn't explain:
  - The dual-mode toggle (Study Hub vs Timer setup)
  - What session types mean
  - How inline practice differs from full practice sessions
  - Where to find their focus stats
- The help icon in the app bar (`focus_timer_screen.dart:557-572`) shows the same generic help dialog — no deeper explanation

**Verdict (MAJOR FAIL):** The first-visit onboarding exists but is too generic. It doesn't explain the dual-mode design, session types, or the distinction between inline and full practice. A first-time user doesn't understand whether to start a timer first or practice first.

---

## Step 2: The Study Hub — Understanding What I See

After dismissing onboarding, I'm in Study Hub mode (default). I see:

1. **Due/Subjects stat row** (`_buildStatItem`, line 890-903): Shows total due questions and subject count
2. **Subject cards** (`_buildSubjectPracticeCard`, line 905-942): Each shows subject name, "X questions due" or "Ready for practice", with a chevron arrow
3. **Spaced Repetition button**: Labeled "Spaced Repetition" (line 828-835)
4. **Weak Areas button**: Labeled "Weak Areas" (line 837-845)
5. **Review Due Questions button**: Visible if `totalDue > 0` (line 846-856) — "Review Due Questions"
6. **SessionSummaryCard** (line 634-639): Shows today's focus time, weekly focus time, session counts, and recent sessions

**What I expect:** Clear labels, actionable buttons, a sense of what to do next.

**What I notice:**

**Issue — Session type labels in Study Hub are misleading:** The buttons at lines 828-856 are labeled "Spaced Repetition" and "Weak Areas". Tapping "Spaced Repetition" calls `_startSpacedRepetition()` (line 459-489) which navigates to a **full PracticeSessionScreen** — leaving Focus Mode entirely. Tapping "Weak Areas" similarly navigates away.

But above these buttons, I see subject cards. Tapping a subject card opens a bottom sheet (`_showPracticeOptions`, line 944-978) with two options:
- **Quick Practice**: Starts **inline** practice inside Focus Mode
- **Spaced Repetition**: Same as the button below — navigates to full PracticeSessionScreen

So a user sees "Spaced Repetition" twice — once in the bottom sheet, once as a standalone button — but one is inline! Wait, no — the bottom sheet's "Spaced Repetition" calls `_startQuickPractice` (line 971: `_startQuickPractice(subject)`), which navigates to full PracticeSessionScreen. Despite the name "Spaced Repetition" in the bottom sheet list tile, it actually calls `_startQuickPractice`...

Wait, let me re-read more carefully:

```dart
ListTile(
  leading: const Icon(Icons.quickreply),
  title: Text(l10n.quickPractice),
  subtitle: Text(l10n.inlinePracticeSubtitle),
  onTap: () {
    Navigator.pop(ctx);
    _startInlinePractice(subject);
  },
),
ListTile(
  leading: const Icon(Icons.open_in_new),
  title: Text(l10n.spacedRepetition),
  subtitle: Text(l10n.fullPracticeSubtitle),
  onTap: () {
    Navigator.pop(ctx);
    _startQuickPractice(subject);
  },
),
```

OK, so the bottom sheet options are:
1. **Quick Practice** → starts inline practice within Focus Mode ✓
2. **Spaced Repetition** → navigates to full PracticeSessionScreen (leaves Focus Mode)

This is clearer but still confusing:
- **Issue with `_startQuickPractice` name**: despite the method name `_startQuickPractice`, the list tile label says "Spaced Repetition". So the function name doesn't match its behavior.
- The user must understand that "Spaced Repetition" means leaving Focus Mode for a full-screen session, while "Quick Practice" means staying in Focus Mode with inline questions.
- There's no tooltip or hint explaining this distinction.

**Verdict (MAJOR FAIL):** The Study Hub has ambiguous navigation paths. The bottom sheet labels don't clearly distinguish between inline (stays in Focus Mode) and full-screen (leaves Focus Mode) practice. The `_startQuickPractice` method name is misleading — it launches a full SR practice session, not inline practice.

---

## Step 3: Inline Practice — Answering Questions Within Focus Mode

I tap a subject card → Quick Practice → inline practice starts. I see a `LinearProgressIndicator`, a progress counter "X/Y", and a question card (`PracticeSessionQuestionCard`).

**What I expect:** I can answer questions, see feedback, and move through them — all without leaving the Focus Mode screen. After finishing, I see my score.

**What actually happens:**

The `InlinePracticeWidget` (inline_practice_widget.dart:19-327) loads 10 questions (`questionCount: 10`, hardcoded at focus_timer_screen.dart:1164) and displays them one at a time. This works well for the basic flow:

1. Question appears (`PracticeSessionQuestionCard`, line 274-284)
2. I type/select an answer
3. I tap Submit (`_submitAnswer`, line 129-154)
4. I see feedback (`PracticeFeedbackWidget`, line 287-289)
5. I tap Next/Done (`_nextQuestion`, line 156-185)
6. On the last question: completion screen with score

**Issues I notice:**

**Issue — No confidence rating:** After answering, there's no confidence slider. At `inline_practice_widget.dart:167`:
```dart
confidence: _isCorrect ? 4 : 2,
```
This is hardcoded — same problem as exam mode (`scenario_exam_mode_spaced_repetition.md` finding #9). Correct answers always get confidence 4, incorrect always get 2. The SM-2 algorithm receives less information.

**Issue — Inline practice is always limited to 10 questions:** `focus_timer_screen.dart:1164` hardcodes `questionCount: 10`. The "Review Due Questions" button (which calls `_startAllSubjectsInlinePractice()`, line 988-993) also creates an `InlinePracticeWidget` with default 10 questions. If I have 40 due questions, I only see 10. There's no "show more" or pagination.

**Issue — No time-tracking during inline practice:** The timer doesn't integrate with inline practice. I start inline practice from Study Hub, and there's no timer running. The `PracticeSessionQuestionCard` doesn't show elapsed time. I get focus-mode practice without focus-mode timing.

**Verdict (MAJOR FAIL):** Inline practice has hardcoded confidence (4/2), hardcoded 10-question limit, and no timer integration. The experience is disconnected from the "focus timer" concept.

---

## Step 4: Starting a Timer Session — What Does the Session Type Do?

I switch the toggle from Study Hub to **Timer** mode (`_studyMode = false`, line 716). I see a "New Focus Session" form (`_buildSetupView`, line 1176-1255):

1. **Session Type selector** (line 1198): 4 chips with icons: Quick Practice, Spaced Repetition, Weak Area Attack, Free Focus
2. **Subject picker** (line 1200): Dropdown with "Optional" default
3. **Duration** (line 1202-1237): Preset chips (10, 15, 25, 30, 45, 60 min) + slider (1-180 min)
4. **"Focus for X minutes"** button (line 1243)

**What I expect:** The session type I choose changes what happens during the timer. For example:
- "Quick Practice" → inline practice questions appear alongside the timer
- "Spaced Repetition" → due questions appear, prioritized
- "Weak Area Attack" → weak topics are targeted during the session
- "Free Focus" → just a silent timer, no questions

**What actually happens:** I select "Spaced Repetition", set 25 minutes, tap "Focus for 25 minutes." The timer starts. I see the circular `FocusTimerWidget`. I can pause, resume, mark complete, or end.

**But no questions appear.** The session type only controls one thing:

```dart
// focus_timer_screen.dart:373-375
if (_sessionType != FocusSessionType.freeFocus) {
  await _captureMasteryBefore();
}
```

That's it. The session type determines whether BEFORE-mastery values are captured. It does NOT affect:
- Whether questions appear during the timer
- Which questions appear
- The timer behavior
- Post-session analytics

After I complete the session, the break view appears (`_buildBreakView`, line 1055-1096). Nothing happens with the captured mastery data — it's stored in `_masteryBeforeValues` and used ONLY if I happen to start inline practice afterward (comparing mastery before with after at `_onInlinePracticeComplete`, line 995-1053).

**The entire session type selector is effectively cosmetic for the timer flow.** Users select a type expecting different experiences but get the same experience regardless.

**Verdict (BLOCKER FAIL):** The session type selector in timer setup has no meaningful effect on the user's experience. Selecting "Quick Practice" vs "Spaced Repetition" vs "Free Focus" produces the exact same timer. The only difference is whether `_captureMasteryBefore()` is called — an invisible backend operation. This is actively misleading.

---

## Step 5: Post-Lesson Focus Mode — The Broken Duration Hint

After a tutor lesson, I tap "Practice what you just learned." I'm navigated to Focus Mode.

**Where this comes from:** The Tutor screen (`tutor_screen.dart:549-551`):
```dart
preselectedSubjectId: widget.subjectId,
preselectedTopicId: widget.topicId,
defaultDurationMinutes: 15,
```

And from lesson detail (`lesson_detail_screen.dart:81,95`):
```dart
static const int _defaultDurationMinutes = Timeouts.defaultLessonDurationMinutes;
```

**What I expect:** Focus Mode opens with the subject pre-selected, the duration pre-set to 15 minutes (as suggested by the tutor), and the timer setup ready to start a focused practice session on the lesson topic.

**What actually happens when I trace the code:**

1. FocusTimerScreen receives `defaultDurationMinutes: 15` (focus_timer_screen.dart:31, 37)
2. But `_selectedMinutes` is initialized to **`25`** at line 49: `int _selectedMinutes = 25;`
3. `defaultDurationMinutes` is **never read** in `initState()` or anywhere in setup
4. It IS used at lines 591-618: a banner displays the `preselectedTopicId` — but the duration is NOT pre-set

**The `defaultDurationMinutes` parameter is completely ignored.** The Tutor screen passes a suggested study duration, but the Focus Mode screen silently discards it. The user always sees "Focus for 25 minutes" regardless of what the tutor recommended.

**Verdict (BLOCKER FAIL):** `defaultDurationMinutes` is passed from TutorScreen (line 551, 565) and `FocusTimerScreenArgs` (app_router.dart:140) but is never applied to `_selectedMinutes` (line 49). The post-lesson shortcut to Focus Mode does not respect the recommended study duration.

---

## Step 6: Completing Inline Practice — Where Did My Results Go?

I finish inline practice. The `_onInlinePracticeComplete()` callback fires (focus_timer_screen.dart:995-1053). It creates a `FocusSession` object:

```dart
_lastFocusSession = FocusSession(
  id: 'focus_${now.millisecondsSinceEpoch}',
  studentId: studentId,
  ...
);
```

The `SessionSummaryCard` renders this as practice performance. I see my score. Good.

**But what happens next time I open Focus Mode?**

The `_lastFocusSession` is a plain instance variable (line 72: `FocusSession? _lastFocusSession;`). It's **never persisted** anywhere:
- No Hive box reference
- No `SessionRepository.save()` call
- No `FocusSessionRepository` exists (there IS no FocusSession repository)
- On screen rebuild (e.g., app restart, navigation away and back), `_lastFocusSession` is reset to `null`

The `FocusSession` model has full `toJson()`/`fromJson()` serialization (focus_session_model.dart:32-65), suggesting it was designed for persistence. But no code path ever calls `toJson()` to serialize it.

**Also:** The `topicBreakdown` in `FocusSession` is keyed by `subjectId`, not `topicId` (line 1011):
```dart
final topicPerformance = TopicPerformance(
  topicId: subjectId,  // <-- subjectId, NOT topicId!
  ...
);
```

This means the `PracticePerformanceCard` renders per-subject performance labeled with subject IDs instead of per-topic performance with topic names. The TopicPerformance model has a `topicId` field (focus_session_model.dart:99) that's set to a `subjectId` — the data is semantically incorrect.

**Verdict (BLOCKER FAIL for persistence, MAJOR FAIL for topic field):** Inline practice results are stored only in memory (`_lastFocusSession`). After app restart or navigation away, all practice history is lost. The `FocusSession` model's `toJson()` is dead code. Additionally, `TopicPerformance.topicId` is set to `subjectId` (focus_timer_screen.dart:1011), making topic breakdown labels show subject IDs instead of topic names.

---

## Step 7: Session Stats — The Dashboard Integration

I check the Dashboard to see my focus time stats.

**What I expect:** Today's focus time, weekly total, and recent sessions visible on the Dashboard.

**What I see:** The Dashboard's `SessionSummaryCard` (shared widget, dashboard_screen.dart) shows:
- Today's focus time ✓
- Weekly focus time ✓  
- Completed/total sessions ✓
- Recent sessions list ✓

The stats are pulled from `SessionRepository` via `StudyTimerService.getTodayStats()`. Focus timer sessions are saved as `Session` objects with `type: SessionType.focus`. ✓

**But inline practice results are Dashboard-invisible:** The `SessionSummaryCard` on the Dashboard can't show `lastPracticeSession` (the `FocusSession`) because the Dashboard's `SessionSummaryCard` doesn't receive it — `lastPracticeSession` is only passed from `FocusTimerScreen`. The Dashboard's `SessionSummaryCard` uses `todayStats`, `weeklyMs`, and `recentSessions` without any `lastPracticeSession`. So the inline practice performance shown in Focus Mode is never visible on the Dashboard.

**Verdict (MINOR FAIL):** Inline practice performance only visible within Focus Mode. Dashboard shows focus time but not inline practice results. Users cannot see their practice accuracy from the home screen.

---

## Step 8: The Dual-Data Problem — Session Type vs Study Hub

After using Focus Mode for a few days, I realize the timer setup and the Study Hub are **completely disconnected**:

| Flow | Timer Setup | Study Hub |
|---|---|---|
| Entry | Switch to Timer mode | Default/switch to Study Hub |
| Session type | Selects Quick/SR/Weak/Free | N/A (buttons are separate) |
| Practice | None during timer | Inline or full-screen |
| Questions shown | None | Via `FocusPracticeService` |
| Mastery tracking | `_captureMasteryBefore()` runs | Via `_onInlinePracticeComplete()` |
| Stats | `_onSessionComplete` records adherence | `_lastFocusSession` stored in-memory |

**The scenario-based contradiction:** If I select "Spaced Repetition" in the timer setup, the timer doesn't show SR questions. If I want SR questions, I must use the Study Hub's buttons — which then navigate to a full `PracticeSessionScreen` (leaving Focus Mode entirely). If I want inline practice, I use the Quick Practice option in the bottom sheet, which shows random questions regardless of the timer's session type selection.

**There is no flow that combines a timer with inline practice.** The "Focus" in "Focus Mode" and the "Practice" in "Study Hub" are two separate experiences sharing one screen.

**Verdict (MAJOR FAIL):** Timer setup and Study Hub are architecturally disconnected. Users cannot run a timer with concurrent inline practice. The session type selection has no effect on study hub behavior, and vice versa.

---

## Step 9: Break Timer — What Happens After a Session

The timer completes. I see the break view: "Break Time!" with a countdown.

**What I see:** A large countdown timer, "Session completed: X minutes" text, and "Great focus!" vibes. The break defaults to `_breakDuration = settings.breakDurationSeconds` (read from Settings, line 124).

**What I notice:**

- Break uses `_breakRemaining` decremented by a `Timer.periodic` second (line 282-298) — correct behavior ✓
- After break ends, the view resets to the setup/study hub (line 292-295) ✓
- Break can't be skipped — no "Skip Break" button
- No suggestion to practice during break — it's just a countdown

**The break has no "Start inline practice" action.** After a 25-minute focus session, I might want to practice a few questions during the 5-minute break. But the break view only shows a timer — no action buttons, no "Review due questions" link, nothing interactive.

**Verdict (MINOR FAIL):** Break view is a passive countdown with no interactive elements. No option to practice questions during break, no "skip break" button.

---

## Step 10: The `_loadStats()` Fire-and-Forget Pattern

Throughout the screen, several async methods call `_loadStats()` without `await`:

- Line 204: `_loadStats();` inside `_onSessionComplete()` — after session completes
- Line 524: `_loadStats();` inside `_onWillPop()` — after cancel session + pop navigation

**The issue:** `_loadStats()` does `setState()` at line 309-314. If called after `navigator.pop()` (line 550) returns, the widget might be disposed (popped from the navigation stack). But `_loadStats()` checks `mounted` at line 308 before `setState()`, so this won't crash. However, the stats update is lost — the user navigated away, and when they return, the old stats from the next `initState` → `_loadStats()` call will be loaded anyway.

**This is not a bug but it's a code smell:** fire-and-forget async calls that update UI state after navigation decisions.

**Verdict (MINOR FAIL):** `_loadStats()` is called without `await` at lines 204 and 524. Not causing crashes (mounted check protects setState), but semantically incorrect — the stats update after pop is wasted work.

---

## Summary of Expectations vs Reality

| # | Expectation | Reality | Status |
|---|---|---|---|
| 1 | First-visit onboarding explains Focus Mode's dual design | Onboarding exists but is generic — doesn't explain Study Hub vs Timer, session types, or inline vs full practice | **MAJOR FAIL** |
| 2 | Study Hub labels clearly distinguish inline vs full-screen practice | Bottom sheet labels (Quick Practice vs Spaced Repetition) don't explain which stays in Focus Mode and which leaves. `_startQuickPractice()` launches full SR session. | **MAJOR FAIL** |
| 3 | Confidence rating available during inline practice | Hardcoded 4/2 at inline_practice_widget.dart:167 — same as exam mode bug | **MAJOR FAIL** |
| 4 | Inline practice respects my due question count | Hardcoded 10 questions (focus_timer_screen.dart:1164), no "load more" option | **MAJOR FAIL** |
| 5 | Session type selection changes the timer experience | Timer experience is identical regardless of session type. Only effect: `_captureMasteryBefore()` flag. | **BLOCKER FAIL** |
| 6 | Post-lesson Focus Mode uses recommended duration | `defaultDurationMinutes: 15` passed from TutorScreen but ignored — always defaults to 25 | **BLOCKER FAIL** |
| 7 | Inline practice results are persisted | `_lastFocusSession` is in-memory only. No Hive storage. Lost on app restart/navigation. FocusSession.toJson() is dead code. | **BLOCKER FAIL** |
| 8 | Topic breakdown shows topic names | `TopicPerformance.topicId` set to `subjectId` (focus_timer_screen.dart:1011) — labels show subject IDs, not topic names | **MAJOR FAIL** |
| 9 | I can practice during a timer session | Timer setup and inline practice are disconnected. No "timer + inline practice" combination exists. | **MAJOR FAIL** |
| 10 | Break view offers practice options | Passive countdown — no interactive elements, no "skip break" | **MINOR FAIL** |
| 11 | Inline practice results visible on Dashboard | Dashboard's SessionSummaryCard doesn't receive `lastPracticeSession` — inline practice invisible from Dashboard | **MINOR FAIL** |
| 12 | `FocusPracticeService` follows `Result<T>` convention | `startPracticeSession()` and `endPracticeSession()` return raw types, not `Result<T>` | **MAJOR FAIL** |
| 13 | Session types align between Timer and Study Hub | Study Hub and Timer setup are architecturally disconnected — no shared session-type logic | **MAJOR FAIL** |
| 14 | `_loadStats()` is properly awaited | Fire-and-forget at lines 204, 524 — code smell, wasted work after pop | **MINOR FAIL** |

---

## Summary

| Severity | Count | Items |
|---|---|---|
| **BLOCKER** | 3 | #5 (session type doesn't affect timer), #6 (defaultDurationMinutes ignored), #7 (practice results not persisted) |
| **MAJOR** | 7 | #1 (generic onboarding), #2 (ambiguous labels), #3 (hardcoded confidence), #4 (10-question cap), #8 (topicId=subjectId), #9 (no timer+practice combo), #12 (non-Result return types), #13 (disconnected timer/hub) |
| **MINOR** | 3 | #10 (break passive), #11 (Dashboard invisible), #14 (fire-and-forget stats) |

The Focus Mode feature has a fundamental architectural problem: it's two disconnected features (a timer and a practice hub) sharing one screen under a misleading label. The session type selector in the timer setup is purely cosmetic — it doesn't change the user experience. Post-lesson integration is broken (`defaultDurationMinutes` discarded). Inline practice results vanish on app restart. The `FocusSession` model has serialization code that's completely unused.
