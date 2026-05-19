# Dry-Run Usability Validation: Voice-First Interaction & Accessibility

## Scenario Summary

A student recovering from RSI (repetitive strain injury) tries to use StudyKing entirely through voice interaction and accessibility features — speech-to-text for input, text-to-speech for output, screen reader navigation, large text, high contrast, and large touch targets. The scenario traces through Mentor chat, Tutor lessons, practice sessions, and Settings, finding critical gaps in voice pipeline robustness, accessibility coverage, and settings effectiveness.

---

## BLOCKER Findings

### B1. Practice Session Voice Input Submits Partial Transcriptions as Final Answers

**Files:** `lib/features/practice/presentation/screens/practice_session_screen.dart:516-524`

**Affected lines:**
```dart
void _useVoiceInput() {
  final voiceService = ref.read(voiceServiceProvider);
  if (!voiceService.isAvailable) return;
  final l10n = AppLocalizations.of(context)!;
  voiceService.startListening(localeName: l10n.localeName);
  voiceService.transcribedText.listen((text) {
    _onAnswerSelected(text);
  });
}
```

**Rationale:** `_onAnswerSelected(text)` is invoked on **every partial transcription update** from the speech-to-text engine. When a user says "two point five moles", the STT engine produces incremental results: "two" → "two point" → "two point five" → "two point five moles". Each partial update triggers a full answer submission, recording 4 separate attempts against the mastery graph. The first 3 are incorrect, artificially deflating the user's accuracy score. The user sees "Wrong!" flash 3 times before the final "Correct!" — a confusing and destructive experience.

**Acceptance criteria:**
- Voice input in practice sessions must wait for the user to indicate completion (stop button, silence timeout, or manual submit) before calling `_onAnswerSelected`.
- Partial results should be displayed in the answer field for user review, not auto-submitted.
- If a submission is already in progress, subsequent transcriptions should be ignored until the current question is resolved.

### B2. Large Touch Targets Setting Ignored by 95% of the App

**Files:**
- `lib/features/settings/presentation/settings_screen.dart:164-170` (setting toggle saved)
- `lib/features/practice/presentation/widgets/practice_session_question_card.dart:189` (only consumer)
- All other screens: NO read of `largeTouchTargets`

**Rationale:** The `largeTouchTargets` setting is persisted in the Settings model but only consumed in one widget across the entire app. Users who need larger touch targets to accommodate motor impairments will find the setting in Settings, enable it, and see zero difference in 95% of screens (Dashboard, Subjects, Mentor, Tutor, Planner, Settings, Focus Mode, Question Bank, etc.). Buttons, chips, list tiles, and icon buttons all remain at default sizes regardless of the setting.

**Acceptance criteria:**
- Every interactive widget across all screens must read and apply `settings.largeTouchTargets`.
- A minimum touch target of 48x48dp must be enforced when the setting is enabled.
- Icon-only buttons should show visible labels or get larger bounding boxes.
- Chips and small tap targets should expand to meet accessibility minimums.

---

## MAJOR Findings

### M1. VoiceBar Has No Screen Reader Support

**Files:** `lib/features/teaching/presentation/widgets/voice_bar.dart:72-121`

**Rationale:** The `VoiceBar` widget (the primary voice control UI in the Tutor screen) has zero semantic labels for screen readers:
- The `IconButton` at line 111-118 uses `tooltip` (for long-press hint) but NOT a `Semantics` wrapper — Flutter's `IconButton` may not expose tooltip text through all screen reader APIs.
- The waveform `_WaveformPainter` at lines 94-108 is a `CustomPaint` in a 24x24 `SizedBox` — a screen reader sees only an empty box with no semantic role.
- The transcription `Text` at lines 80-93 has no `Semantics` label — partial speech results are invisible to screen readers.

A blind user relying on TalkBack/VoiceOver cannot discover, understand, or operate the voice input control.

**Acceptance criteria:**
- `VoiceBar` must have `Semantics` container with a clear label like "Voice input. Double-tap to start speaking."
- When listening, semantics must announce "Listening. Speak now."
- The `IconButton` must use `Semantics(button: true, label: ...)` instead of or in addition to `tooltip`.
- The waveform animation must be `ExcludeSemantics` or have a meaningful label.
- Transcription text must be wrapped in `Semantics(liveRegion: true)` so screen readers announce partial results.

### M2. VoiceBar Requests Microphone Permission on Widget Mount (Before User Action)

**Files:** `lib/features/teaching/presentation/widgets/voice_bar.dart:41-43`

**Rationale:** `requestPermission()` is called in `initState` via `addPostFrameCallback`. This means the microphone permission dialog appears immediately when the Tutor screen loads, before the user has indicated any intention to use voice input. The user might be confused by a system permission dialog appearing on screen load with no context.

Compare with the Mentor screen approach (line 507) which simply hides the mic button if `isAvailable` is false — and the Practice screen approach (line 637) which does the same. Inconsistent permission strategies across the same app.

**Acceptance criteria:**
- Permission must be requested on user action (tapping the mic button), not on widget init.
- If permission is denied, a clear explanation must be shown with a "Retry" button or Settings link.
- All three screens (Tutor, Mentor, Practice) must use a consistent permission strategy.

### M3. Mentor Voice Input Leaks Stream Subscriptions

**Files:** `lib/features/mentor/presentation/mentor_screen.dart:505-531`

**Rationale:**
```dart
voiceService.transcribedText.listen((text) {
  _textController.text = text;
  _textController.selection = TextSelection.fromPosition(
    TextPosition(offset: text.length),
  );
});
```
Each press of the mic button calls `.listen()` which returns a `StreamSubscription` that is **never stored or cancelled**. The subscription is stored in a local scope only. If the user taps the mic button 5 times, 5 simultaneous listeners write transcribed text into the text field. The `dispose()` method (line 534) does not cancel any subscription because there's no reference to it.

**Acceptance criteria:**
- Store the `StreamSubscription` from `transcribedText.listen()` as an instance variable.
- Cancel the previous subscription before creating a new one on each press.
- Cancel the subscription in `dispose()`.
- Consider using `_textController.addListener` or a single persistent subscription with a flag to reduce complexity.

### M4. Mentor Voice Button Hidden When Unavailable (No Fallback)

**Files:** `lib/features/mentor/presentation/mentor_screen.dart:507` and `lib/features/practice/presentation/screens/practice_session_screen.dart:637`

**Rationale:**
```dart
if (!voiceService.isAvailable) return null; // Mentor, line 507
if (!vs.isAvailable) return const SizedBox.shrink(); // Practice, line 637
```
When the speech-to-text service is unavailable (no permission, no microphone, platform not supported), the mic button is completely removed from the UI. There is no disabled state, no tooltip explaining why it's missing, no fallback message like "Voice input not available on this device." A user looking for voice input sees nothing and has no way to know the feature exists but is unavailable.

**Acceptance criteria:**
- The mic button must always be rendered. When unavailable, show a disabled state with a tooltip/explanation: "Voice input not available on this device" or "Microphone permission required."
- The button should never disappear from the UI — only toggle between enabled and disabled states.

### M5. VoiceBar Auto-Submits Transcription Without User Review

**Files:** `lib/features/teaching/presentation/widgets/voice_bar.dart:56-60`

**Rationale:** When the user stops listening (by tapping the mic button again), if `_currentTranscription.isNotEmpty`, the transcription is immediately submitted via `onTranscriptionSubmitted`. There is no review step — the user cannot correct speech-to-text errors before sending. If the STT engine transcribes "Avogadro's number" as "avocado's number", the wrong text is sent directly to the AI tutor.

Compare with the Mentor screen approach (line 522-527) which writes transcription to the text field for manual review and editing. Inconsistent patterns.

**Acceptance criteria:**
- VoiceBar must provide an optional review mode (configurable) where transcription is written to the text field instead of auto-submitted.
- At minimum, VoiceBar should show the final transcription for 1-2 seconds with an undo/cancel button before auto-submitting.
- Or align with the Mentor approach: always write to text field, let the user manually submit.

### M6. Practice Session Voice Input Has No Listen Duration Limit

**Files:** `lib/features/practice/presentation/screens/practice_session_screen.dart:516-524`

**Rationale:** `_useVoiceInput()` starts listening with the default `voiceListen` timeout (60 seconds from `Timeouts.voiceListen`). During this time, every partial transcription triggers `_onAnswerSelected`. For a `typedAnswer` question expecting a short number, the STT engine might produce noise for 60 seconds, submitting dozens of incorrect predictions. There is no mechanism to stop listening after a submission is made.

**Acceptance criteria:**
- After one submission via voice, the mic must auto-stop listening.
- A shorter listen duration (10-15 seconds) should be used for practice answers vs. conversational chat.
- The user must be able to manually stop listening at any time.
- Multiple rapid submissions must be coalesced or the latest transcription must take priority.

### M7. TTS and STT Have No Mutual Interruption Logic

**Files:**
- `lib/core/services/voice_service.dart:86-111` (startListening)  
- `lib/core/services/voice_service.dart:159-179` (speak/TTS)

**Rationale:** `startListening()` does not check `_isSpeaking` before starting, and `speak()` does not check `_isListening`. If TTS is reading an AI response and the user triggers voice input, both audio streams will play simultaneously. The user hears the AI voice while their microphone is open — producing feedback loops, overlapping audio, and confusing behavior.

**Acceptance criteria:**
- Starting voice input must stop any active TTS.
- Starting TTS must not interrupt active voice input (or should provide a warning).
- `VoiceService` should expose a `stopAll()` method that stops both listening and speaking.
- The Tutor screen should pause TTS when voice input is triggered and resume when transcription completes.

### M8. Inconsistent Grid Text Scaling

**Files:**
- `lib/main.dart:350-358` (text scaling logic)
- `lib/features/dashboard/presentation/dashboard_screen.dart:133` (grid aspect ratio)
- `lib/features/practice/presentation/widgets/practice_mode_grid.dart:71` (adjusts for text scale)
- `lib/features/subjects/presentation/subject_selection_screen.dart` (subject list grid)

**Rationale:** The `practice_mode_grid.dart` adjusts `childAspectRatio` based on `MediaQuery.textScalerOf(context).scale(1.0)`, but the Dashboard's metric card grid does not. At maximum font size (2.0x scale), Dashboard cards may overflow their grid cells. Other grids (subject selection, question bank) may have similar issues.

**Acceptance criteria:**
- All `SliverGrid` and `GridView` widgets must adjust `childAspectRatio` for text scaling, following the pattern in `practice_mode_grid.dart:71`.
- Cards should use `softWrap: true` and handle overflow gracefully at all text sizes.
- Test at maximum text scale (2.0x) on the smallest supported screen size.

### M9. Color-Blind Accessibility Gaps

**Files:**
- `lib/features/dashboard/presentation/widgets/topic_breakdown_card.dart:128-133` (color-only progress bars)
- `lib/features/dashboard/presentation/widgets/workload_card.dart:93` (red dot for weak areas)
- `lib/core/theme/app_theme.dart:177-184` (high contrast theme has no color-blind palette adjustment)

**Rationale:** Mastery level differentiation on progress bars uses color only (`primary`/`tertiary`/`error`). The weak areas card uses a red `Icons.circle` with no icon alternative. No color-blind safe palette (e.g., blue-orange instead of red-green) exists. While text labels on mastery chips partially mitigate this, the progress bar fill color and the weak-area red dot are pure color signals with no shape/icon/pattern alternative.

**Acceptance criteria:**
- Progress bar colors must be supplemented with patterns or shapes (e.g., diagonal stripes for the filled portion).
- The weak areas dot must use `Icons.warning_amber` or `Icons.error_outline` instead of `Icons.circle` — shape-based differentiation.
- A color-blind safe theme palette should be added as an option.
- All color-only indicators (error/success/warning states, progress values, mastery levels) must have a non-color alternative.

### M10. Permission Denied Results in Silent Failure

**Files:** `lib/core/services/voice_service.dart:86-88`

**Rationale:**
```dart
Future<void> startListening({String? localeName}) async {
  if (_speech == null || !_isAvailable) return;
  if (_isListening) return;
  // ...
}
```
When `_isAvailable` is false (permission denied), `startListening()` returns early with no user feedback. No snackbar, no dialog, no explanation. The user pressed the mic button expecting to be heard, but got silence. The only clue is that the microphone icon might toggle briefly (the button state doesn't change because `!_isAvailable` returns early before `_isListening` is set).

**Acceptance criteria:**
- When `startListening()` is called but the service is unavailable, the calling code must show a user-visible message: "Microphone permission is required. Go to Settings to enable it." or similar.
- `VoiceService` should expose a `lastError` string or stream for the UI to render.
- A "Permission denied" callback chain must be established from `_checkAvailability` through to the UI.

### M11. No Permission Re-Request Path

**Files:** `lib/features/teaching/presentation/widgets/voice_bar.dart:41-43`

**Rationale:** `VoiceBar.requestPermission()` is called exactly once — in `initState`. If the user denies permission on first request, `isAvailable` stays false forever. The `VoiceBar` never retries. The user cannot grant permission later without restarting the app or the Tutor screen. The Mentor and Practice screens don't call `requestPermission()` at all — they just hide the mic button.

**Acceptance criteria:**
- A "retry permission" mechanism must exist on all three screens (Tutor, Mentor, Practice).
- If permission was denied, tapping the disabled mic button should show a dialog: "Microphone access is needed for voice input. Open Settings to grant permission, or try again."
- Alternatively, call `requestPermission()` each time the user taps the mic button (not just at init).

### M12. Bold Text Field Is Dead Code

**Files:** `lib/features/settings/data/models/accessibility_preferences.dart:8`

**Rationale:** The `boldText` Hive field (typeId: 34, field 0) is defined in the model with full `toJson`, `fromJson`, and `copyWith` support — but has zero UI consumers:
- No Settings toggle writes to it (Settings accessibility section has High Contrast, Large Touch Targets, Reduce Motion — not Bold Text)
- `main.dart:330` reads `MediaQuery.boldTextOf(context)` (system setting), not `settings.boldText`
- The field is persisted to Hive but never read by any code path

The field is needlessly stored in every backup (wasting space) and gives a false impression that Bold Text is configurable.

**Acceptance criteria:**
- Either add a Bold Text toggle in Settings → Accessibility that writes to this field and applies the setting, OR
- Remove the `boldText` field from `AccessibilityPreferences` entirely.

---

## MINOR Findings

### m1. VoiceBar Waveform SizedBox Still Renders with Reduce Motion

**Files:** `lib/features/teaching/presentation/widgets/voice_bar.dart:94-109`

The `_WaveformPainter` `SizedBox` continues to render (as a static 24x24 space with 5 bars drawn at their initial height) even when `reduceMotion` is true. The animation is disabled but the widget occupies the same space and draws the same elements. Should be hidden entirely when `reduceMotion` is true to reduce visual noise.

### m2. Keyboard Focus May Not Reach VoiceBar IconButton Consistently

**Files:** `lib/features/teaching/presentation/widgets/voice_bar.dart:72-121`

The VoiceBar's `IconButton` is inside a `Row` with a `CustomPaint` `SizedBox`. The `SizedBox` has no `focusNode` but may intercept keyboard focus traversal in the `FocusTraversalGroup`. The exact behavior depends on the Flutter framework's focus traversal algorithm with mixed focusable/non-focusable children.

### m3. TTS Does Not Resume After Interruption

**Files:** `lib/features/teaching/services/conversation_manager.dart:219-224`

If the user navigates away while TTS is speaking, and the tab is eventually destroyed, the utterance is lost. On return, there is no "resume last TTS utterance" mechanism. For a voice-reliant user, interrupted audio that never resumes is disorienting.

### m4. ChatBubble Streaming Uses Same Chunk Size Regardless of Reduce Motion

**Files:** `lib/features/teaching/services/conversation_manager.dart:257-264`

The `_buildAdaptiveChunks` method yields adaptive chunk sizes (3-10 characters per chunk) to animate text streaming. This chunked rendering continues regardless of the `reduceMotion` setting. A screen reader reading partial chunks may confuse the user. Should yield the entire response at once when reduce motion is enabled.

### m5. Reduce Motion Not Checked in LessonProgressBar and PhaseIndicator

The `LessonProgressBar` and `PhaseIndicator` widgets may have animated transitions (progress bar fill, phase change animation). These should be disabled or made instant when reduce motion is enabled.

---

## Finding Severity Summary

| Severity | Count | Key Issues |
|----------|-------|------------|
| BLOCKER | 2 | Practice voice corrupts mastery data via partial submissions; Large Touch Targets ignored by 95% of app |
| MAJOR | 12 | Screen reader invisible VoiceBar; aggressive permission; subscription leaks; hidden voice buttons; auto-submit without review; no TTS/STT mutual interruption; inconsistent grid scaling; color-blind gaps; silent permission failure; no retry path; dead bold text field |
| MINOR | 5 | Reduce motion widget still renders; keyboard focus concerns; TTS loses state on tab destroy; streaming not disabled with reduce motion; animation widgets not reduce-motion-aware |

---

## Associated Scenario

`dry-run-test/scenario_voice_first_accessibility.md` — 20-step user journey covering voice-first interaction, screen reader navigation, text scaling, color-blind accessibility, and accessibility settings effectiveness.
