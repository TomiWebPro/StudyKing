# UI/UX Master Audit — StudyKing

**Date:** 2026-05-17
**Scope:** All screens, navigation flows, theme, i18n, accessibility, widget tree
**Method:** Static code review of all `lib/features/*/presentation/` + `lib/core/` + test files

---

## MAJOR

### M1. Non-localized hardcoded strings in localized app

Three user-facing/accessibility strings are **not** passed through `AppLocalizations`, so they always render in English regardless of the user's locale setting.

| File | Line | String | Context |
|---|---|---|---|
| `lib/features/planner/presentation/planner_screen.dart` | 587 | `'Are you sure you want to cancel this lesson?'` | `AlertDialog.content` in `_confirmCancelLesson` |
| `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart` | 160 | `'Decrease duration'` | `Semantics(label:)` on duration `IconButton` |
| `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart` | 174 | `'Increase duration'` | `Semantics(label:)` on duration `IconButton` |

**Rationale:** The app has full English/Spanish localization (360+ keys in ARB). These gaps mean Spanish users see mixed-language dialogs and screen readers read English-only labels.

**Acceptance criteria:**
- [ ] `l10n.areYouSureCancelLesson` is added to both ARB files and replaces the inline string.
- [ ] `l10n.decreaseDuration` and `l10n.increaseDuration` are added to both ARB files and replace the Semantics labels.
- [ ] Unit-test: the dialog content widget renders the localized value, not a literal.

---

### M2. Missing `FilledButtonTheme` / `OutlinedButtonTheme` — visual button inconsistency

`lib/core/theme/app_theme.dart` only overrides `ElevatedButtonTheme` (lines 48-56). Several screens use `FilledButton` and `OutlinedButton` which fall back to M3 defaults with different padding, border radius, and typography, creating visible inconsistency.

**Affected usages:**

| Screen | Button type |
|---|---|
| `onboarding_dialog.dart:123` | `FilledButton` ("Get Started") |
| `mentor_screen.dart` (init-error card) | `OutlinedButton.icon` ("Go to Settings"), `FilledButton.icon` ("Retry") |
| `focus_timer_screen.dart` | `FilledButton` (Start timer) |
| `planner_screen.dart` | `FilledButton` (Generate plan, Schedule) |

**Rationale:** A user sees different button heights, corner radii, and padding across screens. This erodes the perceived polish of the app.

**Acceptance criteria:**
- [ ] `FilledButtonTheme` and `OutlinedButtonTheme` are added in `_baseTheme()` with `elevation: 0`, `borderRadius: 8`, vertical padding 12, horizontal padding 24 (matching `ElevatedButton` overrides).
- [ ] Visual regression: Open onboarding, mentor error card, focus timer, planner — all buttons of the same hierarchy level look identical.

---

### M3. Navigation destinations lack explicit Semantics labels

`main.dart:377-403` (`NavigationRailDestination`) and `main.dart:434-458` (`NavigationDestination`) display text and icons but have **no wrapping `Semantics` widget**. Contrast with the Dashboard FAB (`main.dart:415-418`) which correctly uses `Semantics(button: true, label: l10n.dashboard)`.

**Rationale:** Screen readers may not reliably announce these as interactive tab destinations, especially on TalkBack where merged semantics between the icon and label text can be inconsistent across platforms.

**Acceptance criteria:**
- [ ] Each nav destination builder wraps the `NavigationRailDestination`/`NavigationDestination` in `Semantics(button: true, label: l10n.subjects/practice/mentor/focusMode/settings)`.
- [ ] Widget test verifies `find.bySemanticsLabel(l10n.mentor)` finds the nav destination.

---

### M4. Onboarding dialog completely invisible to screen readers

`lib/features/onboarding/presentation/onboarding_dialog.dart`

The `_buildFeature()` method (line 136) returns a plain `Row` of icon + `Text` widgets with zero Semantics. The five feature items, the "don't show again" `CheckboxListTile`, and the three action buttons are presented to sighted users as a list of interactive options, but a screen reader user only hears a blob of unrelated text.

**Rationale:** The onboarding dialog is the very first thing a new user sees. If it's inaccessible, the user may never understand what the app does or how to proceed.

**Acceptance criteria:**
- [ ] Each `_buildFeature()` call is wrapped in `MergeSemantics(child: ...)` with the title and description in the label.
- [ ] The `CheckboxListTile` gets explicit `Semantics(checkbox: true, checked: _dontShowAgain, label: l10n.dontShowAgain)`.
- [ ] Three action buttons are included in `FocusTraversalGroup` with proper order.
- [ ] Widget test: `tester.getSemantics(find.text(l10n.onboardingSubjectsDesc))` resolves to non-null.

---

### M5. ChatBubble text messages invisible to screen readers

`lib/features/teaching/presentation/widgets/chat_bubble.dart`

Only streaming messages (line 124: `Semantics(liveRegion: true)`) and evaluation messages (line 164: `Semantics(label: ...)`) get Semantics wrappers. **Regular student/tutor text messages have none** — the `Text` widget at line 114 renders the content visually but TalkBack/VoiceOver will skip over it or announce "Text" with no content.

**Rationale:** Chat is the core interaction in Mentor and Tutor screens. Screen reader users cannot read any chat history unless every message is evaluated as a score. This is a critical accessibility failure.

**Acceptance criteria:**
- [ ] The non-streaming, non-evaluation text message gets `Semantics(label: message.content, child: textWidget)`.
- [ ] Sender labels ("You", "Tutor", "System") are merged into the same Semantics node via `MergeSemantics`.
- [ ] Widget test: verify Semantics label matches message content for both student and tutor roles.

---

### M6. Focus timer screen lacks any Semantics

`lib/features/focus_mode/presentation/focus_timer_screen.dart` + `lib/features/focus_mode/presentation/widgets/focus_timer_widget.dart`

The timer display, pause/resume/end buttons, break timer, and duration presets have **no `Semantics` wrappers**. The only exception is the introductory `CircularProgressIndicator` which is standard Flutter.

**Rationale:** Timer countdowns are inherently time-sensitive. A blind user needs live-region announcements for remaining time and explicit button semantics for pause/resume/end.

**Acceptance criteria:**
- [ ] Timer display: `Semantics(liveRegion: true, label: 'Remaining time $formattedTime')`.
- [ ] Each control button: `Semantics(button: true, label: l10n.pause/l10n.resume/l10n.endSession)`.
- [ ] Duration preset chips: `Semantics(button: true, selected: isSelected, label: '${minutes} minutes')`.
- [ ] Break countdown: `Semantics(liveRegion: true, label: 'Break remaining $breakTime')`.

---

### M7. UploadScreen error/success result containers have no Semantics

`lib/features/ingestion/presentation/upload_screen.dart`

When upload succeeds or fails, colored containers with icon + message appear (lines ~90-130). These have **no Semantics wrapper** — a screen reader user never hears the result.

**Rationale:** The user needs to know whether their content was uploaded. The only feedback is visual.

**Acceptance criteria:**
- [ ] Error container: `Semantics(liveRegion: true, label: 'Error: $errorMessage')`.
- [ ] Success container: `Semantics(liveRegion: true, label: 'Success: $successMessage')`.
- [ ] Widget test: verify Semantics label contains the error/success string.

---

### M8. Dashboard accessed via nested push with no breadcrumb

`lib/main.dart:327-331`

The Dashboard FAB calls `_navigatorKeys[_selectedIndex].currentState?.pushNamed(AppRoutes.dashboard)`. This means Dashboard is a named-route push **inside** the currently selected tab's Navigator.

**Problem:** If the user is deep in Practice → Session → Results and taps the Dashboard FAB, the Dashboard pushes on the Practice tab's stack. The bottom nav still shows the Practice tab as selected. If the user then switches to Subjects tab and back to Practice, the Dashboard is gone (Navigator was reset). There's no visual indicator of "you are now in Dashboard within Practice".

**Rationale:** Users can lose their place. The Dashboard is a cross-cutting view, but the navigation pattern makes it behave like a regular tab page.

**Acceptance criteria:**
- [ ] Option A: Dashboard is promoted to its own tab key (not just a push). When navigating from FAB, the tab index switches to the Dashboard.
- [ ] Option B: A bottom-sheet or full-screen dialog (barrierDismissible) is used instead of push, so it's visually distinct from tab navigation.
- [ ] The FAB tooltip and Semantics label remain `l10n.dashboard` (already correct).

---

### M9. Missing first-launch guidance beyond onboarding dialog

After the onboarding dialog + local-data notice, new users land on the Subjects tab which shows **empty state** (icon + "No subjects yet"). There is no sequential tutorial, no coach marks, and no "next step" call-to-action after the initial dialog.

The empty-state checklist on the Dashboard (`empty_dashboard_checklist.dart`) is helpful but hidden behind the FAB, which new users may not discover.

**Rationale:** First-run retention drops when users don't know what to do next. The app has a Quick Guide (`/quick-guide`) reached from a `TextButton` in the onboarding, but new users who click "Get Started" skip this entirely.

**Acceptance criteria:**
- [ ] After onboarding dismissal, the Subjects tab shows a highlighted "Add your first subject" CTA (not just a passive empty-state icon).
- [ ] Alternatively, an inline banner suggests: "Start by adding a subject → Upload your first material → Practice what you learned".
- [ ] Coach-mark overlay on Dashboard FAB after first subject is added.

---

## MINOR

### m1. Hardcoded `'*'` for required field indicator

`lib/features/settings/presentation/profile_screen.dart:536` — `Text('*')` has no Semantics label.

**Fix:** Wrap in `Semantics(label: l10n.requiredField)` or use `Text.rich` with a Semantics span.

---

### m2. Raw numeric display in font-size slider

`lib/features/settings/presentation/settings_screen.dart:265` — `Text('${localSize.round()}')` is not locale-aware.

**Fix:** Use `formatDecimal(localSize.round(), l10n.localeName, minFractionDigits: 0)`.

---

### m3. MathExpressionWidget has no Semantics

`lib/features/questions/presentation/widgets/math_expression_widget.dart` — Complex LaTeX-like math expressions are rendered as colored text spans but never described.

**Fix:** Compute a plain-text fallback for screen readers from the expression tokens and wrap the widget in `Semantics(label: plainText)`.

---

### m4. LlmTaskManagerScreen has no Semantics

`lib/features/llm_tasks/presentation/llm_task_manager_screen.dart` — Status icons, progress bars, cancel buttons all lack Semantics.

**Fix:** Each task card gets `Semantics(label: '${task.status}: ${task.description}')`; cancel button gets `Semantics(button: true, label: 'Cancel ${task.id}')`.

---

### m5. Uniform fade transitions on all routes

`lib/core/routes/app_router.dart` — Every named route uses `PageRouteBuilder` with `FadeTransition(200ms)`.

**Rationale:** Fade is context-neutral. Drill-down navigations (e.g., Subject → SubjectDetail → Session) feel more natural with `SlideTransition` (right-to-left). Modal/dialog-like screens (Settings dialogs) could stay fade.

**Fix:** Use `CupertinoPageRoute` or custom slide transitions for push; keep fade for tab-switch and modals.

---

### m6. No RTL layout testing

All widget tests assume LTR. Expanding to Arabic/Hebrew would reveal hardcoded `EdgeInsets.only(left: ...)`, `crossAxisAlignment.start`, and unidirectional `Padding` values.

**Fix:** Run widget tests with `Directionality` override; audit all padding/margins for RTL safety.

---

### m7. Dashboard rebuilds from 8+ independent providers

`lib/features/dashboard/presentation/dashboard_screen.dart:33-49` watches 8 separate async providers. Each emits separately, potentially causing 8 cascading rebuilds.

**Fix:** Consider a single aggregate provider that bundles all dashboard data into one stream (as seen in `dashboard_data_providers.dart` `DashboardAllData`).

---

### m8. AnimatedBarChart has no keyboard accessibility

Bars display tooltips on tap but are not reachable via keyboard tab navigation.

**Fix:** Wrap each bar in `Semantics(button: true, label: '$label: $value sessions')` and add `Focus` to allow keyboard selection.

---

### m9. No splash / loading screen on cold start

`lib/main.dart` runs all Hive init, repository init, engagement scheduler, and settings load before `runApp()`. Users see a blank white screen for 500-2000ms on slow devices.

**Fix:** Show a native splash screen (via `flutter_native_splash` or Android manifest) or render a minimal loading widget immediately in `runApp()`.

---

### m10. No offline indicator

The app has network-dependent features (LLM calls, Ollama connection) but no `Connectivity` listener or offline banner.

**Fix:** Add a `ConnectivityBanner` widget (similar to `ApiKeyBanner`) that watches network state and shows a `MaterialBanner` when offline.

---

### m11. `assets/fonts/` directory is empty but declared

The `assets/fonts/` directory exists but contains no font files and is not referenced in `pubspec.yaml`. This adds confusion for new contributors and a no-op entry in the build.

**Fix:** Remove the empty directory, or add a `.gitkeep` with a README comment if fonts are planned.

---

### m12. Empty `roadmapList` in Planner forces user to guess next step

`lib/features/planner/presentation/planner_screen.dart` — When the Roadmaps tab shows "No roadmaps yet", the only action is the "Create Roadmap" button in the AppBar. New users may not notice this button since it's in the `AppBar` actions slot.

**Fix:** Add a prominent CTA card in the empty-state body (not just in the AppBar) that reads "Create your first roadmap →" and scrolls/brings focus to the creation fields.
