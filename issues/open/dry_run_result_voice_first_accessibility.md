# Dry-Run Result: Voice-First Interaction & Accessibility Features

**Source scenario:** `dry-run-test/scenario_voice_first_accessibility.md`
**Validation date:** May 2026

## Summary

9 of 14 steps are **COMPLETED** (64%). 5 steps remain **PARTIAL**. 0 steps are **NOT_COMPLETED**.

The scenario was written against older code. Many issues it identified have been fixed since:
- Bold Text toggle now exists in Settings ✓
- Mentor mic button shows disabled (not hidden) when unavailable ✓
- VoiceBar requests permission on first tap, not on mount ✓
- Subscription leaks in Mentor and Practice screens fixed ✓
- TTS/STT mutual state checking implemented ✓
- Permission denial shows dialogs and retry mechanisms ✓

## Remaining Issues

### Issue 1: VoiceBar review overlay skipped when Reduce Motion is enabled (Step 3)

**Location:** `lib/features/teaching/presentation/widgets/voice_bar.dart:70-74`

**Problem:** When `widget.reduceMotion` is `true`, the `_toggleListening()` function skips the 2-second review overlay and submits transcription immediately:
```dart
} else {
  if (_currentTranscription.isNotEmpty) {
    widget.onTranscriptionSubmitted(_currentTranscription);
    _currentTranscription = '';
  }
}
```
This means users who need reduced motion also lose the chance to review/fix speech-to-text errors before submission.

**Fix:** Show the review overlay regardless of `reduceMotion` state, or add a separate `Semantics` live-region confirmation step.

---

### Issue 2: Inconsistent text overflow protection at max font size (Step 6)

**Location:** `lib/features/dashboard/presentation/dashboard_screen.dart` (various card widgets)

**Problem:** Text scaling works (`main.dart:441-449`) but there is no systematic audit of text overflow behavior across card widgets at maximum font size (scale 2.0). Cards like `WeakAreasCard`, `WorkloadCard`, `TopicBreakdownCard`, and dynamic text widgets in the dashboard may allow text to overflow their containers.

**Fix:** Audit all card widgets for `TextOverflow.ellipsis`, `softWrap`, or clipping behavior at max font size. Ensure `Flexible`/`Expanded` wrappers around dynamic text.

---

### Issue 3: Color-blind accessibility gaps (Step 7)

**Locations:**
- `lib/features/dashboard/presentation/widgets/topic_breakdown_card.dart:155-165, 207-212`
- `lib/core/theme/app_theme.dart:245-264`

**Problems:**
1. `LinearProgressIndicator` in `TopicBreakdownCard` uses **color-only** fill — no pattern overlay, no embedded label.
2. `_getProgressColor()` (`topic_breakdown_card.dart:207-212`) and `AppTheme.progressColor()` (`app_theme.dart:245-250`) and `AppTheme.masteryColor()` (`app_theme.dart:259-264`) all use color-only thresholds (primary/tertiary/error).
3. No color-blind safe palette exists — the `highContrastTheme` increases contrast but does not switch to a blue-orange or otherwise accessible palette.

**Fix (options):**
- Add pattern overlay (stripes, dots) to `LinearProgressIndicator` using `CustomPainter`.
- Add color-blind safe theme palette (e.g., blue-orange instead of red-green) via `ColorScheme.fromSeed` with accessible seed colors.
- Add icon/shape differentiation alongside color in progress indicators.

---

### Issue 4: Large Touch Targets not universally applied (Step 11)

**Locations:**
- `lib/features/teaching/presentation/widgets/voice_bar.dart:111-118`
- `lib/features/teaching/presentation/tutor_screen.dart:736-746` (TTS toggle, popup menu buttons)
- `lib/features/dashboard/presentation/dashboard_screen.dart` (various IconButtons, chips)
- `lib/features/practice/presentation/widgets/practice_session_question_card.dart:191, 197` (partially done for drawing tools only)

**Problem:** The `largeTouchTargets` setting is respected by the theme-level button minimum sizes (`app_theme.dart:62-90`) and by practice session drawing widgets. However, the majority of interactive elements throughout the app — `VoiceBar` `IconButton`, AppBar action buttons, PopupMenuButtons, chips, sliders, tabs — do not check this setting.

**Fix:** Either propagate `largeTouchTargets` via a theme extension or query `settingsProvider` in each widget that has user-facing interactive elements. At minimum, add it to:
- `VoiceBar` `IconButton` in `voice_bar.dart`
- Tutor screen volume/menu buttons in `tutor_screen.dart`
- Dashboard collapsible card headers and action buttons

---

### Issue 5: Mid-speech TTS not restorable after interruption (Step 13)

**Location:** `lib/features/teaching/services/conversation_manager.dart:243-255`
`lib/core/services/voice_service.dart:185-211`

**Problem:** `ConversationManager._speakResponse()` only fires `vs.speak()` after an AI response finishes streaming. If the user navigates away while TTS is speaking, and the widget is destroyed/recreated, the TTS utterance is lost. `flutter_tts` has no API to query current position or resume from a specific point.

**Fix:** This is partially a platform limitation (`flutter_tts` doesn't support position tracking). Acceptable mitigations:
- Re-read the last complete AI response on widget re-creation if `_voiceOutputEnabled` is still true.
- Add a "Replay last response" TTS button visible when returning to an in-progress lesson.
- Document as known limitation in the code.
