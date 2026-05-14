# UI/UX Inconsistency: Fragmented Chat Component Language & Theme Gaps Across Features

## Context

Three features offer conversational AI interfaces — **QuickGuide** (`lib/features/quickguide/presentation/quick_guide_screen.dart`), **Mentor** (`lib/features/mentor/presentation/mentor_screen.dart`), and **Tutor** (`lib/features/teaching/presentation/tutor_screen.dart`). Despite serving similar chat-based interactions, QuickGuide duplicates chat UI components inline instead of reusing shared widgets already used by Mentor and Tutor. This creates visual inconsistencies, a larger maintenance surface, and degrades the user experience when switching between modes. Additionally, theme and responsive utilities exist but are inconsistently applied.

---

## Issues Found

### 1. QuickGuide Uses Inline Chat Bubble Rendering Instead of Shared `ChatBubble` Widget

**Affected files:**
- `lib/features/quickguide/presentation/quick_guide_screen.dart` (lines 420–485) — inline chat bubble
- `lib/features/teaching/presentation/widgets/chat_bubble.dart` (lines 1–207) — shared `ChatBubble` widget
- `lib/features/mentor/presentation/mentor_screen.dart` (line 14) — correctly imports `ChatBubble`

**Evidence:** Mentor screen imports `ChatBubble` from teaching (`import '../../teaching/presentation/widgets/chat_bubble.dart';`). QuickGuide has its own standalone rendering with materially different visuals:

| Aspect | QuickGuide (inline) | ChatBubble (shared) |
|--------|-------------------|-------------------|
| User bubble color | `colorScheme.primary` | `colorScheme.primaryContainer` |
| Border radius | `BorderRadius.circular(16)` symmetric | `BorderRadius.only` asymmetric (4/16) |
| Font size | Hardcoded `fontSize: 15` | `textTheme.bodyMedium` (respects scaling) |
| Avatar | None | `CircleAvatar` with robot/person icon |
| Sender label | None | Shows "You" / "Tutor" / "System" |
| Text color (user) | `onPrimary` (white on deep purple) | `onPrimaryContainer` |
| Streaming visual | `CircularProgressIndicator` (spinner) | Animated bouncing dots (`_TypingIndicator`) |

**Rationale:** A user who starts in QuickGuide then moves to Mentor or Tutor sees different bubble colors, radii, and absence/presence of avatars. This undermines the sense of a cohesive product. The `ChatBubble` widget exists specifically to solve this — QuickGuide should use it.

**Acceptance Criteria:**
- [ ] Replace inline `Container` in `_buildMessageList` (lines 434–479) with the shared `ChatBubble` widget
- [ ] Verify QuickGuide student messages render with `primaryContainer` (not `primary`) and asymmetric border radii, matching Mentor/Tutor
- [ ] Confirm `textTheme.bodyMedium` is used instead of hardcoded `fontSize: 15`
- [ ] Confirm streaming indicator transitions from `CircularProgressIndicator` to animated dots
- [ ] Ensure no visual regression: color contrast, spacing, and accessibility labels remain intact

---

### 2. QuickGuide Duplicates Message Composer Instead of Reusing `ConversationInput`

**Affected files:**
- `lib/features/quickguide/presentation/quick_guide_screen.dart` (lines 565–658) — inline `_buildMessageComposer`
- `lib/core/widgets/conversation_input.dart` (lines 1–130) — shared `ConversationInput` widget
- `lib/features/mentor/presentation/mentor_screen.dart` (line 8) — correctly imports `ConversationInput`

**Evidence:** QuickGuide's `_buildMessageComposer` (93 lines) is a near-exact copy of `ConversationInput`. It redefines the same `TextField` decoration (border radius 24, fill color, content padding), the same `IconButton.filled` send button (48x48, `CircularProgressIndicator` when loading), and the same bottom padding logic. The Mentor screen correctly uses `ConversationInput` in 1 line. QuickGuide's version adds `CallbackShortcuts` for Ctrl+Enter and `FocusTraversalGroup` — features that should be added to the shared widget instead of duplicated.

| Aspect | QuickGuide inline | ConversationInput |
|--------|-----------------|-------------------|
| Lines of code | 93 | 130 (with more features) |
| Keyboard shortcuts | Ctrl+Enter (inline) | None |
| `trailing` customization | Hardcoded send button | Configurable via `trailing` param |
| `leading` customization | None | Configurable via `leading` param |
| `Semantics` on input | Yes (`label` + `hint`) | No |

**Rationale:** Any future enhancement to the message composer (e.g., voice input button, attachment picker, quick-reply chips) must be implemented in two places. This is a maintenance risk and a missed opportunity for a single-source-of-truth chat input.

**Acceptance Criteria:**
- [ ] Add `CallbackShortcuts` (Ctrl+Enter binding) and `FocusTraversalGroup` support to the shared `ConversationInput` widget
- [ ] Replace QuickGuide's `_buildMessageComposer` with `ConversationInput`, passing `_onSend`, `_textController`, `_inputFocusNode`, `_isStreaming` as parameters
- [ ] Verify `Semantics` labels transfer correctly to the shared widget
- [ ] Remove the inline `_buildMessageComposer` method and all dead code

---

### 3. `ConversationMemory` maxTurns Mismatch Between QuickGuide and LlmService Default

**Affected files:**
- `lib/features/quickguide/presentation/quick_guide_screen.dart` (line 38): `ConversationMemory(maxTurns: 30)`
- `lib/core/services/llm/llm_chat_service.dart` (line 19): `ConversationMemory({this.maxTurns = 20})`

**Evidence:** The shared `ConversationMemory` has a default of 20 turns. QuickGuide explicitly overrides this to 30, meaning it retains 50% more conversation history than any other consumer. There is no documented reason for this discrepancy. If the LLM service's `maxTurns` and QuickGuide's are both used (QuickGuide maintains both `_messages` and `_memory`), the effective limit is unclear and may lead to inconsistent truncation behavior.

**Rationale:** Users may experience message loss differently depending on which list truncates first. A single canonical limit should apply across all chat features.

**Acceptance Criteria:**
- [ ] Align QuickGuide's `ConversationMemory` to the shared default of 20 turns, or document why 30 is necessary
- [ ] Ensure consistent truncation logic between `_messages` list and `_memory` history
- [ ] Verify no conversation history is silently dropped

---

### 4. Google Fonts Dependency Declared But Never Applied

**Affected files:**
- `pubspec.yaml`: includes `google_fonts: ^6.1.0`
- `lib/core/theme/app_theme.dart` (lines 1–190): no `fontFamily` is ever set

**Evidence:** The `TextTheme` in `AppTheme.createTextTheme()` returns vanilla `TextStyle` objects without a `fontFamily`. The `_baseTheme()` returns a `ThemeData` with no `fontFamily` override. This means Google Fonts are downloaded (adding ~2–8 MB to the bundle) but never used. All text renders in the platform default (Roboto on Android, San Francisco on iOS).

**Rationale:** Including an unused dependency wastes bundle size and initial load time. Either remove `google_fonts` from `pubspec.yaml` or apply a chosen font family (e.g., Inter, Lora, or Atkinson Hyperlegible for accessibility) consistently across the theme.

**Acceptance Criteria:**
- [ ] Option A: Remove `google_fonts` dependency from `pubspec.yaml`, prune related imports
- [ ] Option B: Select a single font family, apply it in `createTextTheme()`, verify CJK/Latin/Spanish glyph coverage, and confirm no measurable performance regression
- [ ] Ensure the chosen option is applied consistently (AppBar, cards, buttons, input fields)

---

### 5. QuickGuide Mode Nav Cards Use Hardcoded Route String Instead of Named Constant

**Affected files:**
- `lib/features/quickguide/presentation/quick_guide_screen.dart` (line 331): `Navigator.pushNamed(context, '/mentor')`

**Evidence:** The AI Tutor card correctly uses `AppRoutes.tutor` (line 312), but the Mentor card uses a bare string literal `'/mentor'` (line 331). If the Mentor route path ever changes, this reference silently breaks while `AppRoutes.tutor` would be caught by the compiler.

**Rationale:** Inconsistent routing patterns create fragility. All navigation should use `AppRoutes` constants.

**Acceptance Criteria:**
- [ ] Replace `'/mentor'` with `AppRoutes.mentor`
- [ ] Search for any other hardcoded route strings across the codebase (e.g., `grep -rn "pushNamed.*'/" lib/`)

---

### 6. Weak Accessibility Semantics on Mode Navigation Cards

**Affected files:**
- `lib/features/quickguide/presentation/quick_guide_screen.dart` (lines 351–390)

**Evidence:** The `_buildModeCard` wraps the card in `Semantics(button: true, label: "$title: $subtitle")`, but the `Card` has `child: InkWell` wrapping icon + title + subtitle `Text` widgets. These child text widgets are still exposed to the accessibility tree as individual nodes, meaning a screen reader may read both the semantic label AND the child text redundantly. The `Card` itself has no `explicitChildNodes: true`.

The `ChatBubble` widget similarly uses `explicitChildNodes: true` which can interfere with fluid screen reader navigation (see teaching widget).

**Rationale:** Users relying on TalkBack/VoiceOver get a noisy experience — the label is read, then each child text is read again.

**Acceptance Criteria:**
- [ ] Add `explicitChildNodes: true` to the outer `Semantics` in `_buildModeCard`
- [ ] Wrap child Icon and Text widgets in `ExcludeSemantics` or use `Semantics(explicitChildNodes: true ...)` recursively
- [ ] Audit `ChatBubble` (chat_bubble.dart:19) for similar redundant semantics

---

### 7. Responsive Layout Gaps: Hardcoded Padding Instead of `ResponsiveUtils`

**Affected files (non-exhaustive):**
- `lib/features/quickguide/presentation/quick_guide_screen.dart` (line 364): `const EdgeInsets.all(12)` — `_buildModeCard` padding
- `lib/features/quickguide/presentation/quick_guide_screen.dart` (line 440, 461): `EdgeInsets.symmetric(horizontal: ..., vertical: 12)` and `fontSize: 15` — chat bubble content sizing
- Many other feature screens (dashboard, planner, sessions) use hardcoded `EdgeInsets.all(16)` or similar instead of `ResponsiveUtils.screenPadding(context)`

**Evidence:** `ResponsiveUtils` provides `screenPadding`, `listPadding`, `cardPadding`, `horizontalSpacing`, and `verticalSpacing` — all breakpoint-aware. QuickGuide and several other screens use fixed values that do not adapt to tablet or desktop widths.

**Rationale:** On tablets (md breakpoint, 840–1200px), hardcoded 12px padding creates an uncomfortably wide content column. The responsive utilities exist to solve this but are underused.

**Acceptance Criteria:**
- [ ] Replace hardcoded `EdgeInsets.all(12)` in `_buildModeCard` with `ResponsiveUtils.cardPadding(context)`
- [ ] Replace hardcoded `fontSize: 15` in chat bubble with `Theme.of(context).textTheme.bodyMedium?.fontSize`
- [ ] Audit all feature screens for hardcoded padding values and replace with `ResponsiveUtils` variants where appropriate

---

### 8. Animation and Motion Consistency: Duplicate Typing Indicator Implementations

**Affected files:**
- `lib/features/quickguide/presentation/quick_guide_screen.dart` (lines 531–562): standalone `_buildTypingIndicator` with `AnimatedOpacity` + `CircularProgressIndicator`
- `lib/features/teaching/presentation/widgets/chat_bubble.dart` (lines 116–206): `_TypingIndicator` with animated bouncing dots + `AnimationController`

**Evidence:** When the AI is generating a response, QuickGuide shows a spinner inside a text container ("Quick Guide is thinking...") while Tutor and Mentor show animated bouncing dots inside a `ChatBubble`. These are two different visual languages for the same mechanical state.

Crucially, the `ChatBubble`'s `_TypingIndicator` respects `reduceMotion` setting (displaying static dots when disabled), while QuickGuide's `_buildTypingIndicator` does not check for reduced motion — it always animates.

**Rationale:** Users who enable "Reduce Motion" in Settings or OS-level accessibility still see fading animations in QuickGuide. This violates WCAG 2.1 Success Criterion 2.3.3 (Animation from Interactions).

**Acceptance Criteria:**
- [ ] Remove standalone `_buildTypingIndicator` from QuickGuide
- [ ] Ensure `ChatBubble`'s `_TypingIndicator` is used consistently across all three chat features
- [ ] Verify `reduceMotion` is passed from each screen's state to the `ChatBubble` or typing indicator widget
- [ ] Confirm no animation plays when `reduceMotion` is true (verify with `MediaQuery.boldTextOf(context)` or the settings provider)

---

### 9. Dashboard FAB Is Hidden to Keyboard Users

**Affected files:**
- `lib/main.dart` (lines 238–241): `FloatingActionButton.small` with `onPressed: _openDashboard`

**Evidence:** The Dashboard is the app's analytics hub but is only accessible via a FAB on the main screen. FABs are not keyboard-focusable by default on all platforms. There is no menu entry, navigation rail button, or keyboard shortcut to open the Dashboard.

**Rationale:** A keyboard-only user (or user navigating with a switch device) cannot reach the Dashboard without first tabbing through all bottom navigation destinations. This is an accessibility barrier.

**Acceptance Criteria:**
- [ ] Add "Dashboard" as a keyboard-accessible action (e.g., a fifth `NavigationDestination` or a menu item in the AppBar of the first tab)
- [ ] Or wrap the FAB in `Focus` + `Actions` to ensure it appears in the tab order
- [ ] Verify screen reader can discover and activate the Dashboard action
