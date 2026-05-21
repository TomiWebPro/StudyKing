# Dry-Run Scenario: Using StudyKing with Voice-First Interaction & Accessibility Features

## Persona

I'm a university student recovering from a repetitive strain injury (RSI) in both hands. Typing is painful and I can only manage short bursts. I rely on:
- **Voice input** (speech-to-text): to send messages, answer questions, navigate the app
- **Text-to-speech (TTS)**: to hear AI responses, questions, and feedback read aloud
- **Large text and high contrast**: for quick glances when needed
- **Screen reader** (TalkBack / VoiceOver): for full screen-reading navigation
- **Minimal precise tapping**: no small buttons, no drag gestures

I'm studying IB Chemistry. I already have a subject set up, uploaded materials, and an API key configured from before my injury. Now I need to continue studying without relying on my hands.

---

## Step 1: Navigating the App with a Screen Reader — Bottom Navigation Labels

I open StudyKing. TalkBack is active. I swipe right to explore the screen.

**What I expect:** Every icon button, tab item, and custom widget has a proper semantic label. The bottom navigation tabs read their names aloud. I can navigate the app entirely via touch exploration.

**Code reality check — Screen reader support pattern:**
- `Semantics` widgets are used in many places (`ChatBubble`, `ConversationInput`, `PracticeSessionScreen`, `FocusTimerWidget`, etc.)
- However, custom-painted widgets (timer rings, waveform animation, milestone timeline, circular progress) may lack semantic labels because `CustomPaint` doesn't produce semantics automatically
- The `VoiceBar` widget at `voice_bar.dart:72-121` is used in the Tutor screen — **but the IconButton has only a `tooltip`**, no `Semantics` wrapper. The waveform `CustomPaint` has no semantics. The transcription `Text` has no label. A screen reader user won't know what this widget is or what it does.
- The `IconButton` at `voice_bar.dart:111-118`:
  ```dart
  IconButton(
    icon: Icon(isListening ? Icons.mic : Icons.mic_none, ...),
    onPressed: _toggleListening,
    tooltip: l10n.voiceInput,
  )
  ```
  The `tooltip` provides a hint on long-press but is NOT a semantic label for screen readers. `IconButton` without `Semantics` wrapper relies on Flutter's default which may or may not expose the tooltip.

**Specific check needed:** 
- Does the `IconButton` default semantics produce a useful announcement?
- The waveform `_WaveformPainter` has zero semantic overlay — a `CustomPaint` that spans 24x24 with animated bars is invisible to screen readers entirely.
- Bottom navigation tabs: `NavigationBar` with `NavigationDestination` — Flutter's `NavigationBar` does provide built-in semantics via `label` field. This likely works. ✓
- But the Tutor screen `VoiceBar` sits inside `ConversationInput.leading` — the entire leading area may be merged into a single semantic node with no differentiation.

**What I worry about:** Voice interaction widget itself has no screen reader support — the primary tool for a voice-first user is invisible to their navigation method.

---

## Step 2: Voice Input in the Mentor Tab — Mic Button Behavior

I navigate to the Mentor tab (4th tab). I want to ask the Mentor a question by voice instead of typing.

**What I expect:** I see a microphone button. I tap it (or double-tap via TalkBack). It starts listening. My speech is transcribed into the text field. I can review and edit it if needed, then send.

**What the code shows:**
1. `_buildVoiceButton()` at `mentor_screen.dart:505-531` creates an `IconButton` with mic/mic_none icon
2. **Guard:** `if (!voiceService.isAvailable) return null;` — if the `speech_to_text` library reports unavailable on this device, **the button is completely removed from the UI** with no fallback message, no disabled state, no "Voice not available" indicator.
3. On press: starts listening with the current locale. Transcribed text goes directly into `_textController.text` via `voiceService.transcribedText.listen(...)`.
4. **Microphone subscription leak:** Each time the user presses the mic button, a NEW subscription is created via `.listen()` (line 522). The old subscription is **never cancelled**. If the user taps the mic button 5 times, there are 5 active listeners all writing transcribed text into the text field, potentially causing race conditions and repeated text.
5. No `VoiceBar` widget is used here — the Mentor builds its own mic button entirely independently of the shared `VoiceBar` component used in the Tutor screen. This means the Mentor's voice input has different behavior (no waveform animation, no permission auto-request, no auto-submit on stop).

**Multiple pressing problem:** If `isAvailable` is true and the user taps the mic button, `startListening()` is called. If they tap again while listening, `stopListening()` is called. But `transcribedText.listen()` is called every time `startListening` is pressed — creating subscriptions that are never cleaned up (since `dispose()` at line 534-539 doesn't cancel the subscription subscription handle... wait, `_buildVoiceButton` builds a new `IconButton` every time the parent `build()` runs, and the `listen()` call creates a `StreamSubscription` that's stored nowhere. Each press leaks a subscription.

**Text field population:** The transcription is written to `_textController.text` and `_textController.selection` is set to the end. But there's no visual distinction between transcribed text and typed text — if I said "What is Avogadro's number" and it transcribed "What is avocado number" (a common STT error), I might not notice the error before sending. No "transcription confidence" indicator, no "did you mean...?" correction.

---

## Step 3: Voice Input in the Tutor Screen — The VoiceBar Component

I navigate to the Planner and start a scheduled tutor lesson. The Tutor screen shows a `VoiceBar` widget in the `ConversationInput.leading`.

**What the code shows:**
1. `VoiceBar` at `voice_bar.dart:6-121` — auto-requests microphone permission on init (line 42 via `addPostFrameCallback`)
2. **The `requestPermission` call happens even if the user has never asked for voice input.** Permission dialog pops up immediately when the Tutor screen opens, before any user interaction. This is aggressive — the user might be startled by a permission dialog on screen load.
3. Toggle behavior (line 53): single press toggles listening on/off. On stop, if transcription is non-empty, auto-submits via `onTranscriptionSubmitted`.
4. The `VoiceBar` is inside the `ConversationInput.leading` Row alongside an image picker button (tutor_screen.dart:670-684). Both fit in a tight horizontal space.
5. **No error handling for partial / failed transcription**: If speech recognition doesn't understand the user, `_currentTranscription` remains empty, and `onTranscriptionSubmitted` is called with an empty string. The conversation manager receives an empty message — which may produce an unexpected AI response ("I didn't understand that") or a silent failure.

**Auto-submit on stop vs. review:** The VoiceBar auto-submits transcription when the user stops listening (line 58-60). There's no review step — the text goes directly to the conversation. If the transcription is wrong (e.g., "Avogadro" → "avocado"), the user has no chance to correct it. In contrast, the Mentor's voice button puts the text in the text field for review.

---

## Step 4: TTS — Auto-Reading AI Responses

During the tutor lesson, the AI tutor responds to my question. I want to hear it spoken aloud.

**What the code shows:**
1. **TTS toggle**: The Tutor screen AppBar has a volume icon button (line 588-597) — `_voiceOutputEnabled` flag toggles between `Icons.volume_up` and `Icons.volume_off`.
2. **Auto-TTS**: `ConversationManager._speakResponse()` at `conversation_manager.dart:219-224` calls `vs.speak(text, localeName: localeName)` when `enableVoiceOutput` is true after every AI response.
3. **The TTS starts immediately** when the AI response finishes streaming — it fires the `voiceService.speak()` at line 222, which calls `_tts!.speak(text)` (voice_service.dart:174).
4. **No interruption logic**: If the user starts speaking while TTS is reading, there's no ducking or interruption. The TTS and STT run on separate channels but neither checks the other's state. If I try to speak while TTS is reading, both audio streams may play simultaneously, creating noise.
5. **Per-message speak button**: `tutor_screen.dart:913-914` — each ChatBubble has an `onSpeak` callback that reads `voiceServiceProvider` and calls `.speak()`.
6. **The `VoiceService.speak()` method at line 159-179** sets `_isSpeaking = true` at the start and resets it to `false` in completion/error handlers. But there's no `isSpeaking` guard in `startListening()` — if TTS is playing and the user triggers voice input, both compete.

**Locale handling:** TTS uses `_localeForTts(localeName)` (voice_service.dart:142-146) to convert locale codes (e.g., `es` → `es-ES`). Supported: en, es, fr, de, pt, it, ja, zh. Falls back to `en-US`. For Spanish-speaking users, TTS will speak in Spanish — this generally works. ✓

---

## Step 5: Voice Input in Practice Sessions — Answering Questions by Voice

I want to answer practice questions by voice. I start a practice session on Stoichiometry.

**What the code shows:**
1. `_useVoiceInput()` at `practice_session_screen.dart:516-524`: reads `voiceServiceProvider`, calls `startListening(localeName: l10n.localeName)`, and subscribes to `transcribedText` — calling `_onAnswerSelected(text)` with every partial transcription.
2. **Partial results treated as final answers**: Because `_onAnswerSelected` is called on every transcription event (every partial update), if speech-to-text produces "5.6" then corrects to "5.8", the question is first answered with "5.6" (wrong), and only briefly shows the correct answer "5.8" before the feedback freezes. The user sees "Wrong!" flash briefly before the correct answer registers.
3. **Same subscription leak as Mentor**: Each press of the mic button creates a new `listen()` subscription. Since `_useVoiceInput` is called from `onPressed` (line 644), each press adds another listener. The subscription handle is never stored or cancelled.
4. **Mic button visibility**: The mic button at lines 634-646 only shows when `vs.isAvailable`. Returns `SizedBox.shrink()` otherwise — no disabled state, no fallback.
5. **No "press to stop" behavior**: Unlike the VoiceBar (which auto-stops and submits), the practice screen mic button toggles listening but the transcription listener never stops — it keeps calling `_onAnswerSelected` for every word recognized even after the first submission. This can lead to multiple rapid answer submissions.

**Specific scenario that breaks:** I say "two point five moles" — speech-to-text transcribes incrementally: "two" → _onAnswerSelected("two") marked wrong, "two point" → submitted again, "two point five" → submitted again, "two point five moles" → submitted again. Each submission is a new attempt recorded in the mastery graph. In 3 seconds, 4 incorrect attempts are recorded against my accuracy.

---

## Step 6: Large Text Mode — Does the App Scale Gracefully?

I go to Settings → Appearance → Font Size and crank it to maximum. Then I check the Dashboard.

**What I expect:** All text scales properly. Cards expand. Charts adapt. No text is clipped, truncated, or overflowing.

**What the code shows:**
1. `main.dart:350-358`: Combines `MediaQuery.textScalerOf(context).scale(1.0)` with `settings.fontSize` (clamped 10-30) to produce `totalScale` (clamped 1.0-2.0). Applied via `MediaQuery.boldText` wrapper at line 356.
2. The effective scale is `systemTextScale * (fontSize / 14)` — a dialog at `settings_screen.dart:492-496` allows setting `fontSize` from 10 to 30 (default 14).
3. **No maximum width constraints on cards**: The `DashboardScreen` uses `SliverGrid` for metric cards with `crossAxisCount: 2` on phones. `childAspectRatio` at `dashboard_screen.dart:133` is computed from screen width. At max font size, cards may overflow their grid cells because the `childAspectRatio` doesn't consider text scaling.
4. `practice_mode_grid.dart:71`: `childAspectRatio` is adjusted by `MediaQuery.textScalerOf(context).scale(1.0)` — this IS done for the practice grid. But similar adjustment may be missing in other grid layouts (Dashboard, Subject Detail).
5. **No overflow-safe layout in metric cards**: The `_DashboardMetricCard` widget — if the title or value text at max font size exceeds the card bounds, there's no `softWrap` or `OverflowBar`. Text may overflow with no `overflow: TextOverflow.ellipsis` or clip behavior.

**What I worry about:** Inconsistent grid aspect ratio adjustments. Some grids adjust for text scale, others don't. At max font size, card layouts break on small screens.

---

## Step 7: Color Blind Mode — Can I Distinguish Mastery Levels?

I have deuteranopia (red-green color blindness). I look at the Dashboard's mastery overview and topic breakdown.

**What I expect:** Mastery levels are distinguishable by more than color — icons, patterns, text labels. Progress bars and charts use accessible color palettes.

**What the code shows:**
1. `TopicBreakdownCard._getProgressColor()` at `topic_breakdown_card.dart:128-133`:
   ```dart
   Color _getProgressColor(BuildContext context, double value) {
     final cs = Theme.of(context).colorScheme;
     if (value >= 0.8) return cs.primary;   // Usually blue
     if (value >= 0.6) return cs.tertiary;  // Usually amber
     return cs.error;                        // Usually red
   }
   ```
   **Color-only differentiation** — the progress bar color, the percentage text color, and the mastery label color all use the same three-color scheme with NO icons, NO patterns, NO shape differentiation.
2. **Text labels are present** — the mastery label itself IS a text string (`l10n.masteryLevelProficient`, etc.). So a color-blind user CAN read the label to understand the level. **This partially mitigates the color-only issue.** ✓
3. **However**, the `LinearProgressIndicator` at lines 86-94 uses ONLY color for the filled portion — no pattern, no label embedded in the bar. The progress bar value is distinguishable only by its fill ratio (which is fine) and color (which is not color-blind safe).
4. The `Weak Areas` card in the dashboard uses `Icons.circle` colored with `Theme.of(context).colorScheme.error` (red) at `workload_card.dart:93` — the ONLY visual indicator is a red dot. No text alternative or icon distinguishes this from other dots on the screen.
5. **No color-blind specific theme** exists. The `highContrastTheme` in `app_theme.dart` increases contrast and border widths but doesn't change the color palette to a color-blind safe one (e.g., blue-orange instead of red-green).

**The workload_card.dart at line 93** shows weak topics with just a red dot icon — no "!" icon, no warning symbol, nothing but color differentiation. If the user is red-green color blind, the red dot is indistinguishable from other colored dots, and the weak area is only identifiable by its position in the card.

---

## Step 8: Keyboard Navigation — Focus Traversal for a User with Limited Mobility

I can still use one finger to tap, but precise taps are hard. I rely on focus-based navigation (Tab key via Bluetooth keyboard or sequential focus via TalkBack).

**What I expect:** Logical focus order. No focus traps. All interactive elements reachable via keyboard/sequential navigation.

**What the code shows:**
- `FocusTraversalGroup` + `FocusTraversalOrder` used in 14+ screens (practice_session, mentor, planner, profile, upload, settings, dashboard, etc.) ✓
- `NumericFocusOrder` assigns specific numbers to form fields and buttons ✓
- This is well-implemented across the app

**But there's a concern:** The `VoiceBar` is inside the `ConversationInput` leading Row, which is inside a `FocusTraversalGroup`. The `VoiceBar` contains an `IconButton` and a `CustomPaint` + `Text`. On keyboard navigation, the focus might not reach the `IconButton` because:
- The waveform `CustomPaint` is a non-focusable `SizedBox` (24x24) — it might intercept focus in the flex layout
- The `AnimatedBuilder` wrapping `CustomPaint` has no `focusNode`
- The `IconButton` should be focusable by default, but its position at the trailing end of the leading row might cause unexpected focus order

---

## Step 9: Reduce Motion — Does the VoiceBar Respect It?

I enabled Reduce Motion in Settings → Accessibility. I start a tutor lesson and use voice input.

**What I expect:** No extraneous animations. The VoiceBar doesn't show waveform animation. Screen transitions are instant.

**What the code shows:**
1. `VoiceBar` constructor accepts `reduceMotion` parameter (line 17), passed from `settingsProvider` at `tutor_screen.dart:677`
2. `_toggleListening()` checks `widget.reduceMotion` at line 66-68 — skips `_waveController.repeat()` if true ✓
3. However, **the `_WaveformPainter` `SizedBox` still renders** (lines 94-109) — it's just static (no animation value changing), but it still occupies 24x24 space and `CustomPaint` still draws the 5 bars at their initial positions.
4. **`Semantics` for the reduce-motion state**: There's no semantic indication that animation is disabled. The widget doesn't announce "waveform animation disabled."
5. Also worth checking: the `IconButton` still changes icon from `mic_none` to `mic` when listening — this is a visual change, not an animation, so it's appropriate.

**Additional animation concerns:**
- `ChatBubble` streaming text animation: `conversation_manager.dart:257-264` yields adaptive chunk sizes (3-10 chars per chunk). If reduce motion is enabled, this chunked streaming might still happen — a screen reader will read partial phrases. There's no `reduceMotion` check in `_buildAdaptiveChunks`.
- The `LessonProgressBar` and `PhaseIndicator` animations: not checked for reduceMotion compliance.

---

## Step 10: Bold Text Support — Does Bold System Setting Apply?

I enabled Bold Text in my system settings (Android: Developer Options → System font size → Bold text). I reopen StudyKing.

**What I expect:** All text appears in bold. No layout breaks.

**What the code shows:**
1. `main.dart:330`: `final boldText = MediaQuery.boldTextOf(context);`
2. `main.dart:331`: Combines `boldText` with `settings.highContrastEnabled` for theme selection
3. `main.dart:356-358`: The `MediaQuery.boldText` is NOT directly applied as a boldText override. Instead, it's used to select the high-constract theme (line 335: `useHighContrast = systemHighContrast || settings.highContrastEnabled`). 
4. The `boldText` value from `MediaQuery.boldTextOf(context)` is read at line 330 and used at line 335, but **not explicitly applied** as bold text. Flutter's `MediaQuery.boldText` with `DefaultTextStyle` does handle this at the framework level — text should render bold automatically when the system bold setting is enabled.
5. However, the `AccessibilityPreferences` model defines a `boldText` field (line 8) that is **never written to by any UI**. The settings screen has no "Bold Text" toggle — only High Contrast, Large Touch Targets, and Reduce Motion (lines 155-180). The `boldText` field in the model exists but is dead code.

---

## Step 11: Large Touch Targets — Do Buttons Get Bigger?

I enabled Large Touch Targets in Accessibility settings. I try to tap buttons.

**What I expect:** Buttons are bigger. Touch targets are at least 48x48dp. All interactive elements are easier to hit.

**What the code shows:**
1. `settings_screen.dart:164-170`: SwitchListTile for large touch targets, saved to `settings.largeTouchTargets`.
2. **Only consumed in one place:** `practice_session_question_card.dart:189` reads `settings.largeTouchTargets` to adjust button sizes.
3. **No other screen checks this setting.** The Dashboard, Subjects, Mentor, Settings, Planner — none read `largeTouchTargets`. The setting is stored and persisted but ignored by 95% of the app's interactive elements.
4. Even in the practice session question card (line 189), the adjustment is minimal — likely just a `SizedBox` height increase. The `IconButton` size (48dp default) should already be accessible, but smaller interactive elements (chips, small icons) aren't adjusted.

**The VoiceBar's IconButton** (voice_bar.dart:111-118) is a default `IconButton` with 48dp tap target. At default this is fine. But with `largeTouchTargets` enabled, the `VoiceBar` doesn't increase its button size.

---

## Step 12: Microphone Permission — Aggressive Request Timing

I open the Tutor screen for the first time.

**What I expect:** Microphone permission is requested when I first tap the mic button, not when I open the screen.

**What the code shows:**
1. `VoiceBar.initState()` at `voice_bar.dart:41-43`:
   ```dart
   WidgetsBinding.instance.addPostFrameCallback((_) {
     widget.controller.requestPermission();
   });
   ```
   **Permission is requested immediately when the Tutor screen mounts**, not when the user taps the mic button. This is aggressive — the user may not want to use voice at all, but they get a system permission dialog on screen load.
2. The Mentor screen's `_buildVoiceButton()` (line 507) checks `isAvailable` — which was initialized in `VoiceService._initialize()` at construction time. If the user never granted permission, `isAvailable` is false, and the mic button is hidden entirely. To use voice in the Mentor, the user must have already granted permission (perhaps from the Tutor screen). There's no "request permission on demand" path — the button either shows (permission already granted) or completely disappears.
3. The Practice screen's mic button (line 637) also checks `vs.isAvailable` and hides if false — similar issue. No permission request mechanism exists for practice session voice input.

**Permission denial scenario:** If the user denies microphone permission on the Tutor screen, `VoiceBar.requestPermission()` is never called again — the `VoiceBar` won't auto-retry. On the Tutor screen, `VoiceBar.initState()` runs once. If permission was denied, `isAvailable` stays false, and the Tutor VoiceBar shows but the speech recognition won't work (silent failure inside `startListening()` at voice_service.dart:87 — returns early with `if (!_isAvailable) return;`). The user sees the mic button, taps it, hears nothing, and gets no error message.

---

## Step 13: Session Resume After Interruption — Voice State Preservation

I'm in a tutor lesson with voice output enabled. The AI is speaking. I accidentally navigate away (system back gesture) and return.

**What I expect:** The TTS state is preserved. Voice output toggle is still enabled.

**What the code shows:**
1. The Tutor screen is wrapped in the tab's `TabNavigator` — it's preserved via `Offstage`. When I return, the `_voiceOutputEnabled` state variable (line 594) is still set.
2. **But TTS was mid-speech when I left.** The `VoiceService.speak()` completes if it was in the middle of speaking — Flutter's `flutter_tts` plugin continues even if the widget is offstage. When I return, TTS may have finished, may still be running, or may have been interrupted by the OS.
3. **No automatic TTS restart:** `ConversationManager._speakResponse()` is only called right AFTER an AI response finishes streaming. If the user leaves mid-TTS and returns, the TTS does not resume from where it left off.
4. **Voice service disposal on TutorScreen dispose:** If the tab is actually destroyed (not just offstage), the `voiceServiceProvider` is scoped to the widget tree. `VoiceService.dispose()` stops listening and speaking. On re-creation, a new `VoiceService()` starts fresh. The TTS utterance is lost.

---

## Step 14: The AccessibilitySettings Bold Text Field — Dead Code

The `AccessibilityPreferences` model at `accessibility_preferences.dart:8` defines `boldText` as a `@HiveField(0)` field.

**What the code shows:**
- `boldText` is declared, serialized (`toJson`), deserialized (`fromJson`), and has `copyWith` support
- **But there is no UI toggle to set it.** Settings screen (lines 155-180) has switches for High Contrast, Large Touch Targets, and Reduce Motion — but NOT Bold Text.
- **Bold text is never read from `AccessibilityPreferences`** — `main.dart:330` reads `MediaQuery.boldTextOf(context)` (system setting), not `settings.boldText` (app setting).
- The `boldText` field in the model is completely dead code — persisted to Hive but never written or read by any UI or logic path.

---

## Summary of Expectations vs Reality

| # | Expectation | Reality | Status |
|---|---|---|---|
| 1 | Screen reader can explore all elements: VoiceBar has a semantic label | VoiceBar `IconButton` has only `tooltip` (not semantic label). Waveform `CustomPaint` has zero semantics. | FAIL (MAJOR) |
| 2 | Mentor mic button is always visible (disabled state if unavailable) | Hidden entirely when `!isAvailable` — no fallback or disabled state | FAIL (MAJOR) |
| 3 | Mentor voice input doesn't leak stream subscriptions | Each `onPressed` creates a new `.listen()` with no cancellation — subscription leak | FAIL (MAJOR) |
| 4 | VoiceBar requests mic permission on user action (tap mic) | Requests permission on widget mount — before user action | FAIL (MAJOR) |
| 5 | VoiceBar allows reviewing transcription before sending | Auto-submits on stop — no review step | FAIL (MAJOR) |
| 6 | Practice session voice input handles partial results correctly | Calls `_onAnswerSelected` on every partial transcription — multiple rapid submissions | FAIL (BLOCKER) |
| 7 | Practice session voice input stops after submission | Listener keeps firing — can submit answers multiple times in quick succession | FAIL (MAJOR) |
| 8 | TTS and STT don't compete (ducking/interruption) | No mutual state checking — both can run simultaneously | FAIL (MAJOR) |
| 9 | TTS auto-reads AI responses in tutor lesson | Works via `_speakResponse()` | PASS |
| 10 | Per-message speak button exists in tutor chat | ChatBubble `onSpeak` callback works | PASS |
| 11 | Large text scales consistently across all grids | Some grids adjust aspect ratio, others don't — inconsistent | FAIL (MAJOR) |
| 12 | Color-blind users can distinguish mastery levels without color | Text labels help, but progress bars use color-only. Weak areas use red dot only. No color-blind palette. | FAIL (MAJOR) |
| 13 | Keyboard focus traversal includes all interactive elements | 14+ screens have `FocusTraversalGroup`. VoiceBar's IconButton may be in group but waveform SizedBox may interfere. | PARTIAL |
| 14 | Reduce Motion disables VoiceBar waveform animation | Waveform animation stopped, but widget still renders | PASS (partial) |
| 15 | Large Touch Targets applies to all interactive elements | Only applied in `practice_session_question_card.dart` — 95% of app ignores it | FAIL (BLOCKER) |
| 16 | Microphone permission denied shows clear error message | Silent failure — `startListening()` returns early with no user feedback | FAIL (MAJOR) |
| 17 | Permission re-request after initial denial | Not implemented — `VoiceBar` only requests once in initState | FAIL (MAJOR) |
| 18 | Voice state preserved after tab switch | Tab is `Offstage`-preserved, TTS may continue in background | PASS (partial) |
| 19 | Bold Text toggle exists in Settings | `boldText` Hive field exists but no UI toggle — dead code | FAIL (MAJOR) |
| 20 | Bold system setting applies throughout the app | `MediaQuery.boldText` read and applied via framework DefaultTextStyle | PASS |

---

## Validation Results (Dry-Run Audit — May 2026)

Audit performed by tracing each scenario claim against the actual source code. Many issues noted in the original scenario have been fixed. Below is the per-step verdict with code references.

### Step 1: Screen Reader — Bottom Navigation Labels
**Verdict: COMPLETED** ✓
- `NavigationBar` with `NavigationDestination` has built-in semantics via `label` field (`main.dart:310-336`).
- `VoiceBar` is wrapped in `Semantics(container: true, label: ...)` (`voice_bar.dart:146-149`).
- `IconButton` wrapped in `Semantics(button: true, label: ...)` (`voice_bar.dart:190-201`).
- Waveform `CustomPaint` has `Semantics(excludeSemantics: true)` (`voice_bar.dart:171-188`).
- Transcription uses `Semantics(liveRegion: true, label: ...)` (`voice_bar.dart:154-167`).

### Step 2: Mentor Mic Button
**Verdict: COMPLETED** ✓
- Button **disabled** (not hidden) when `!isAvailable` — `onPressed: null` (`mentor_screen.dart:617-641`).
- Subscription leak **fixed**: `_voiceSubscription?.cancel()` before new `.listen()` (`mentor_screen.dart:631`).
- Subscription cancelled on dispose (`mentor_screen.dart:646`).

### Step 3: VoiceBar Component
**Verdict: PARTIAL** ⚠️
- Permission requested **on first tap**, not on mount — `_toggleListening()` at `voice_bar.dart:77`. ✓
- **Review overlay exists**: 2-second overlay with cancel button before auto-submit (`voice_bar.dart:60-75, 202-211`). ✓
- **But**: When `reduceMotion=true`, the review overlay is **skipped** — text auto-submits immediately (`voice_bar.dart:70-74`).

### Step 4: TTS Auto-Reading
**Verdict: COMPLETED** ✓
- TTS toggle via AppBar volume button (`tutor_screen.dart:736-746`).
- `_speakResponse()` calls `vs.speak()` after AI response (`conversation_manager.dart:250-255`).
- Mutual state checking: `speak()` blocks if listening (`voice_service.dart:189-192`); `startListening()` stops TTS first (`voice_service.dart:110-113`).
- Per-message speak via `ChatBubble.onSpeak` (`tutor_screen.dart:1098-1099`).

### Step 5: Practice Voice Input
**Verdict: COMPLETED** ✓
- Partial results NOT auto-submitted — updates `_voiceTranscriptionPreview` only (`practice_session_screen.dart:594-599`).
- `_onAnswerSelected` called only on stop or timeout (`practice_session_screen.dart:582-584, 607-609`).
- Subscription leak fixed (`practice_session_screen.dart:593-594, 605`). ✓
- Mic button disabled (not hidden) when unavailable (`practice_session_screen.dart:733-748`).
- Timer-based auto-stop (`practice_session_screen.dart:601-614`).

### Step 6: Large Text Mode
**Verdict: PARTIAL** ⚠️
- Text scaling works: `main.dart:441-449` combines system + user scale, clamped 1.0–2.0.
- Dashboard uses `SingleChildScrollView` + `CollapsibleCard`, not `SliverGrid` — scenario's grid concern outdated.
- `practice_mode_grid.dart:100` adjusts `childAspectRatio` for `MediaQuery.textScalerOf`.
- **Remaining:** No systematic overflow (`TextOverflow.ellipsis`) check across all card widgets at max font size.

### Step 7: Color Blind Mode
**Verdict: PARTIAL** ⚠️
- Text labels in `_masteryLabel()` differentiate levels verbally (`topic_breakdown_card.dart:188-205`). ✓
- `WeakAreasCard` uses `Icons.warning_amber`, not red dot (`weak_areas_card.dart:52`). ✓
- `workload_card.dart:96` uses `Icons.error_outline` — icon + color. ✓
- **Remaining:** `LinearProgressIndicator` color-only fill (`topic_breakdown_card.dart:155-165`). `_getProgressColor()` color-only (`topic_breakdown_card.dart:207-212`). No color-blind safe palette in `app_theme.dart`.

### Step 8: Keyboard Navigation
**Verdict: COMPLETED** ✓
- `FocusTraversalGroup` + `NumericFocusOrder` used in 14+ screens (mentor, tutor, practice, settings, dashboard).
- `VoiceBar` `IconButton` is `Semantics(button: true, ...)` and keyboard-focusable.
- Waveform `CustomPaint` has `excludeSemantics: true` — cannot intercept focus.

### Step 9: Reduce Motion
**Verdict: COMPLETED** ✓
- `VoiceBar.reduceMotion` from `settingsProvider` (`tutor_screen.dart:852`).
- Waveform animation skipped: `if (!widget.reduceMotion) { ... }` (`voice_bar.dart:102`).
- Waveform `SizedBox` not rendered: `if (isListening && !widget.reduceMotion)` (`voice_bar.dart:170`).
- `_buildAdaptiveChunks()` at `conversation_manager.dart:301` streams full text when reduceMotion=true.
- `_AnimatedMessageItem` skips fade animation (`mentor_screen.dart:1378-1401`).

### Step 10: Bold Text Support
**Verdict: COMPLETED** ✓
- **UI toggle EXISTS** at `settings_screen.dart:167-173` — SwitchListTile for `settings.boldText`.
- `main.dart:421`: `systemBoldText = MediaQuery.boldTextOf(context) || settings.boldText`.
- `main.dart:447`: `boldText: systemBoldText` via `MediaQuery.copyWith`.
- `SettingsBox.boldText` at field 26, fully serialized (`settings_box.dart:94, 123, 167, 216-218`).

### Step 11: Large Touch Targets
**Verdict: PARTIAL** ⚠️
- SwitchListTile at `settings_screen.dart:182-189`.
- Button themes respect `largeTouchTargets` (`app_theme.dart:62-90`).
- Drawing widgets pass it (`practice_session_question_card.dart:191, 197`).
- **Remaining:** `VoiceBar` `IconButton` not largeTouchTarget-aware (`voice_bar.dart:111-118`). Majority of interactive elements (chips, tabs, sliders, list tiles) don't check it.

### Step 12: Microphone Permission
**Verdict: COMPLETED** ✓
- Permission requested on first tap (`voice_bar.dart:77`) — no postFrameCallback in initState.
- Denial dialog at `voice_bar.dart:108-130`.
- Retry via snack bar at `voice_bar.dart:85-97`.
- Mentor button disabled with `micPermissionDenied` tooltip (`mentor_screen.dart:624, 640`).
- Practice button has `voiceInputNotAvailable` semantic label (`practice_session_screen.dart:735-748`).

### Step 13: Session Resume After Interruption
**Verdict: PARTIAL** ⚠️
- `AutomaticKeepAliveClientMixin` preserves state across tab switches (`tutor_screen.dart:53, 76`). ✓
- `_voiceOutputEnabled` state retained on return.
- **Remaining:** Mid-speech TTS not restorable — `_speakResponse()` only fires after AI response completes (`conversation_manager.dart:243-255`). No TTS progress tracking.

### Step 14: AccessibilityPreferences Dead Code
**Verdict: COMPLETED** ✓
- `AccessibilityPreferences.boldText` at `accessibility_preferences.dart:8` — fully implemented with Hive, `toJson`, `fromJson`, `copyWith`.
- **Confirmed dead:** No UI or logic path reads from this model. Settings UI uses `SettingsBox.boldText` (field 26).

---

### Summary of Updated Status

| # | Expectation | Status | Code Reference |
|---|---|---|---|
| 1 | Screen reader can explore all elements | **COMPLETED** | `voice_bar.dart:146-213` |
| 2 | Mentor mic button shows disabled (not hidden) when unavailable | **COMPLETED** | `mentor_screen.dart:617-641` |
| 3 | Mentor voice input doesn't leak stream subscriptions | **COMPLETED** | `mentor_screen.dart:631, 646` |
| 4 | VoiceBar requests mic permission on user action | **COMPLETED** | `voice_bar.dart:77` |
| 5 | VoiceBar allows reviewing transcription before sending | **PARTIAL** — review skipped when reduceMotion=true | `voice_bar.dart:70-74` |
| 6 | Practice voice input handles partial results correctly | **COMPLETED** | `practice_session_screen.dart:594-608` |
| 7 | Practice voice input stops after submission | **COMPLETED** | `practice_session_screen.dart:576-614` |
| 8 | TTS and STT don't compete | **COMPLETED** | `voice_service.dart:110-113, 189-192` |
| 9 | TTS auto-reads AI responses | **COMPLETED** | `conversation_manager.dart:250-255` |
| 10 | Per-message speak button in tutor chat | **COMPLETED** | `tutor_screen.dart:1098-1099` |
| 11 | Large text scales consistently | **PARTIAL** — scaling works, card overflow not systematically checked | `main.dart:441-449` |
| 12 | Color-blind accessible mastery levels | **PARTIAL** — text labels + icons help, but progress bars color-only, no CB palette | `topic_breakdown_card.dart:155-165, 207-212` |
| 13 | Keyboard focus includes all interactive elements | **COMPLETED** | 14+ screens with `FocusTraversalGroup` |
| 14 | Reduce Motion disables VoiceBar waveform | **COMPLETED** | `voice_bar.dart:60, 102, 170` |
| 15 | Large Touch Targets applies to all interactive elements | **PARTIAL** — button themes respect it, VoiceBar and most widgets do not | `app_theme.dart:62-90`, `voice_bar.dart:111-118` |
| 16 | Permission denied shows clear error | **COMPLETED** | `voice_bar.dart:108-130` |
| 17 | Permission re-request after initial denial | **COMPLETED** | `voice_bar.dart:85-97, 120-125` |
| 18 | Voice state preserved after tab switch | **PARTIAL** — KeepAlive preserves state, mid-speech TTS not restorable | `tutor_screen.dart:53, 76` |
| 19 | Bold Text toggle exists in Settings | **COMPLETED** | `settings_screen.dart:167-173` |
| 20 | Bold system setting applies throughout app | **COMPLETED** | `main.dart:421, 447` |
| 21 | `AccessibilityPreferences.boldText` dead code | **COMPLETED** (confirmed dead) | `accessibility_preferences.dart:1-64` vs `settings_box.dart:94` |
