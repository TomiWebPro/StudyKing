# Mentor Progress Report & Cross-Cutting UI/UX Issues

## Context

A thorough inspection of the mentor, dashboard, practice, and other features reveals several UX deficiencies that range from accessibility violations to locale-unsafe rendering and confusing UI patterns. The most critical cluster centers on the mentor feature's progress report — a core feature delivered as a plain-text AlertDialog with no visual hierarchy, locale-aware formatting, or persistence.

---

## Issues

### 1. Mentor Progress Report Displayed as Featureless Plain-Text AlertDialog

`MentorScreen._showProgressReport()` (`lib/features/mentor/presentation/mentor_screen.dart:277-354`) assembles all report data (accuracy, study time, weak topics, badges, recommendations) into a `StringBuffer`, then wraps the entire string in a single `Text` widget inside `SingleChildScrollView` within an `AlertDialog`.

| Aspect | Current (bad) | Expected |
|---|---|---|
| Visual hierarchy | Flat wall of text, `\n` as the only separator | Section headers, icons, cards, progress bars |
| Accessibility | Single monolithic `Text` node, no heading levels | `Semantics` headings per section, ARIA landmarks |
| Weak topics | Plain text strings | Tappable `ListTile`s linking to practice (reuse `WeakAreasCard` pattern) |
| Badges | Raw `'name: description'` string | `Chip` widgets with trophy icon |
| Scannability | User must read every line to find relevant info | Collapsible sections, visual grouping |
| Dismiss-ability | Dialog closes, data gone forever | Could persist last report or show in a bottom sheet |
| Actions | None | "Practice weak topic" navigation, "View roadmap" from recommendations |

**Affected files:**
- `lib/features/mentor/presentation/mentor_screen.dart` — method `_showProgressReport`, lines 277-354

**Rationale:**
- The progress report is a primary value proposition of the mentor feature. Presenting it as raw text undermines the feature's credibility and utility.
- Accessibility violation: screen readers encounter a single unstructured text block. WCAG 1.3.1 (Info and Relationships) requires that information and relationships conveyed visually are also conveyed programmatically.
- Missed cross-feature integration: weak topics shown here cannot be acted upon (no "practice now" action), whereas the identical data in `WeakAreasCard` on the dashboard is tappable.

**Acceptance criteria:**
- Replace the `AlertDialog` body with sectioned widgets: heading row (icon + title), stats row with `LinearProgressIndicator` for accuracy, weak topics as tappable `ListTile`s, badges as `Chip`s.
- Each section must be wrapped in `Semantics(headingLevel: 3)` or equivalent.
- Weak topic items must be tappable and navigate to `AppRoutes.practiceSession` with the topic ID.
- The dialog must use a `Column` (inside `SingleChildScrollView`) not a single `Text` node.
- Verify screen reader traverses each section independently.

---

### 2. Locale-Unsafe Number Formatting in Mentor Progress Report

Within `_showProgressReport()`, the AGENTS.md convention (never use `toStringAsFixed()`; use `formatPercent`/`formatDecimal` from `number_format_utils.dart`) is violated:

```dart
// Line 282: double.toString() → always period decimal, e.g. "85.5"
buffer.writeln(l10n.mentorOverallAccuracy(
  '${report.accuracy}',     // BUG: will be "85.5" even for es locale where it should be "85,5"
  '${report.correctAttempts}',
  '${report.totalAttempts}',
));
```

Meanwhile, line 293 in the same function correctly uses integer rounding:
```dart
(topic.accuracy * 100).round()  // OK: integer is locale-invariant
```

This inconsistency means Spanish, French, German, and other comma-decimal locale users see period decimals in the progress report but correct formatting elsewhere in the app.

**Affected files:**
- `lib/features/mentor/presentation/mentor_screen.dart` — lines 282-283, 289, 291, 292

**Rationale:**
- Direct violation of the project's conventions (`AGENTS.md` > i18n / Number Formatting Conventions).
- The fix is trivial (use `formatPercent` and `formatDecimal`) and the screen already has access to `l10n.localeName`.
- The inconsistency is within the same method, suggesting it was an oversight rather than an intentional choice.

**Acceptance criteria:**
- Replace `'${report.accuracy}'` with `formatPercent(report.accuracy, l10n.localeName, maxFractionDigits: 1)`.
- Replace `'${report.weeklyActivity}'` with `formatDecimal(report.weeklyActivity.toDouble(), l10n.localeName)`.
- Replace `'${report.completedLessons}'` and `'${report.topicsStudied}'` similarly.
- Verify en locale produces `"85.5%"` and es locale produces `"85,5%"`.

---

### 3. Mentor Chat History Lost on Widget Rebuild / Navigation

The conversation is stored in an ephemeral in-memory list:
```dart
// mentor_screen.dart:37
final List<_ChatMessage> _messages = [];
```

The `MentorService` already persists messages via `ConversationMemory` → `ConversationRepository`, but the UI never reloads from it. Consequences:

| Scenario | Current Behavior |
|---|---|
| Navigate to dashboard tab and back | Widget rebuilds → all history lost → duplicate welcome message |
| Hot-reload during development | All state lost |
| App sent to background and killed | All state lost |

**Affected files:**
- `lib/features/mentor/presentation/mentor_screen.dart` — lines 37, 88-100 (`_initializeMentor`), 104-114 (`_sendWelcomeMessage`)
- `lib/features/mentor/services/mentor_service.dart` — `_memory` field and `initialize()` method (persistence infrastructure already exists)

**Rationale:**
- Losing conversation context in a chat application is a fundamental UX failure. Users expect history to persist across navigation.
- The persistence infrastructure is already implemented and working (`ConversationMemory` with `maxTurns: 50` and `ConversationRepository`). The UI simply fails to consume it.
- This is a low-effort, high-impact fix: load messages from `_mentorService.memory` on init before sending the welcome message.

**Acceptance criteria:**
- On `_initializeMentor()`, call `_mentorService.memory.getMessages()` (or equivalent) and populate `_messages` from persisted data.
- Only send the welcome message if no persisted messages exist (avoid duplicate greetings).
- New messages sent during the session must be persisted via `_mentorService.memory.addUserMessage()` / `addAssistantMessage()` (already done in `_sendMessage()` flow via `_mentorService.chat()`).
- Verify navigating to another tab and back preserves the full conversation including streaming state.
- Verify duplicate welcome messages do not appear after navigation.

---

### 4. Confidence Selector Lacks Semantic Grouping for Screen Readers

In the practice session (`lib/features/practice/presentation/screens/practice_session_screen.dart`), the confidence rating control renders 5 circles, each wrapped in:

```dart
Semantics(
  button: true,
  label: '${l10n.howConfident} $rating',   // e.g. "How confident 3"
  child: InkWell(...),
)
```

| WCAG Criterion | Current Violation |
|---|---|
| 4.1.2 (Name, Role, Value) | Exposed as 5 independent buttons, not a single "confidence rating" group with a selected value |
| 1.3.1 (Info and Relationships) | No relationship between the 5 circles — screen reader cannot tell they form a 1-to-5 scale |
| ARIA Authoring Practices | Should be a `radiogroup` pattern, not independent buttons |

**Affected files:**
- `lib/features/practice/presentation/screens/practice_session_screen.dart` — method `_buildConfidenceSelector`, lines 578-629

**Rationale:**
- The `button: true` annotation is semantically incorrect. These are radio-style selection controls within a group, not navigation buttons.
- A screen reader user must tab through 5 separate controls to understand the scale, with no indication of which is currently selected.
- The label `"How confident 3"` is incomplete — it should include the range context (e.g., "Confidence rating: 3 of 5, moderately confident").

**Acceptance criteria:**
- Wrap the entire row in a single `Semantics` with `label: l10n.howConfident` and appropriate container role.
- Each circle should use `Semantics(selected: isSelected)` rather than `button: true`.
- Announce the current value: e.g., `"Confidence rating: 3 of 5, moderately confident"`.
- Verify with a screen reader that the group is traversed as a single control with a selected value, not as 5 independent buttons.

---

### 5. Dashboard WeakAreasCard Returns SizedBox.shrink() — Empty Invisible Card with Visible Header

`WeakAreasCard` (`lib/features/dashboard/presentation/widgets/weak_areas_card.dart:27`):

```dart
final weakStates = allMastery.where((s) => s.accuracy < 0.6).toList();
if (weakStates.isEmpty) return const SizedBox.shrink();
```

Returns an invisible widget, but the surrounding `CollapsibleCard` still renders:
- A card header with the title "Weak Areas", a warning icon, and an expand/collapse toggle
- The card border and background

The user sees a card that appears to have content (header is visible) but when expanded, shows nothing. Meanwhile, other dashboard cards handle empty states correctly:
- `BadgesCard`: Shows `"No badges yet"` centered text
- `TopicBreakdownCard`: Shows `"No topic data yet"` centered text

**Affected files:**
- `lib/features/dashboard/presentation/widgets/weak_areas_card.dart` — lines 27-28

**Rationale:**
- Inconsistency in empty state handling across dashboard cards creates a confusing UX artifact.
- The `CollapsibleCard`'s collapse toggle implies expandable content, but there is none — this is misleading.
- When all topics are above 60%, the card should celebrate this achievement rather than silently hide its content.

**Acceptance criteria:**
- Replace `SizedBox.shrink()` with a positive message: e.g., `"All topics are above 60% accuracy — great progress!"` using a localized string.
- The message should be centered and styled with `onSurfaceVariant` color, matching the pattern used by `BadgesCard` and `TopicBreakdownCard`.
- Verify the card shows the positive message when expanded with zero weak areas.

---

### 6. Practice Session SlideTransition Direction Incorrect on Back-Navigation

The `AnimatedSwitcher` in `PracticeSessionScreen` (`lib/features/practice/presentation/screens/practice_session_screen.dart:267`) uses `_currentIndex > _previousIndex` to determine animation direction:

```dart
final isForward = _currentIndex > _previousIndex;
final offset = isForward ? const Offset(0.3, 0.0) : const Offset(-0.3, 0.0);
```

The bug: `_previousIndex` is only updated in `_nextQuestion()`:
```dart
void _nextQuestion() {
  setState(() {
    _previousIndex = _currentIndex;  // ← updated here
    _currentIndex++;
  });
}
```

But `_previousQuestion()` does NOT update `_previousIndex`:
```dart
void _previousQuestion() {
  if (_currentIndex > 0) {
    setState(() {
      _previousIndex = _currentIndex;  // ← MISSING: should be here
      _currentIndex--;
    });
  }
}
```

When navigating backward, `_previousIndex` still holds the value from the last forward navigation, causing the slide direction to feel reversed (content slides right-to-left when it should slide left-to-right).

**Affected files:**
- `lib/features/practice/presentation/screens/practice_session_screen.dart` — lines 183-191 (`_previousQuestion`), lines 267-270 (animation direction logic)

**Rationale:**
- `_previousQuestion` is a 6-line method with a clear parallel to `_nextQuestion`. The missing assignment is an obvious copy-paste oversight.
- Incorrect animation direction is disorienting — it violates the user's spatial mental model of "forward" and "backward."

**Acceptance criteria:**
- Add `_previousIndex = _currentIndex;` to `_previousQuestion()` before `_currentIndex--`.
- Verify forward navigation: content slides in from the right.
- Verify backward navigation: content slides in from the left.
- Verify `reduceMotion` mode (no animation) is unaffected.
