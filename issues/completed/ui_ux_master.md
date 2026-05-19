# UI/UX Master Issue Report

Generated: 2026-05-19
Scope: All 36 screen files, 52 presentation widget files, core widgets/services/providers

---

## BLOCKER (app crashes or user cannot proceed)

### B1. FocusTimerScreen route argument check always fails — route never resolves correctly

**Context**: `app_router.dart:272-280` — The `FocusMode` route checks `if (args is FocusTimerScreen)` which compares the entire widget class (a `StatefulWidget` type) to route arguments. This will **never be true** because route arguments are data objects, not widgets. The intended check should compare against the arg's type or presence/null.

**Rationale**: This means any navigation to `/focus-mode` with arguments (e.g., from the Dashboard "Resume Focus Session" card) always falls through to the else branch or fails. The user may tap "Resume" and get the default screen instead of the intended session context.

**Acceptance Criteria**:
- [ ] `FocusMode` route correctly inspects `args` type (e.g., `args is FocusTimerScreenArgs` or checks `args != null`).
- [ ] Navigation from Dashboard's active session card correctly resumes the focus session with the right subject/topic context.

### B2. InlinePracticeWidget close button is a no-op — user gets stuck

**Context**: `inline_practice_widget.dart:239-241` — The "Close" button inside the completion card uses `FilledButton(onPressed: () {}, ...)` — empty callback that does nothing.

**Rationale**: After completing inline practice during a focus session, the user sees a completion summary with exactly one action: "Close." Tapping it does nothing. The user is trapped on this screen with no way to dismiss it and return to the timer.

**Acceptance Criteria**:
- [ ] The Close button dismisses the completion card and returns the user to the active timer view.
- [ ] Or the completion card has a working dismiss/continue action.

### B3. `dashboard_data_providers.dart` forced unwraps (`result.data!`) — crash risk

**Context**: `dashboard_data_providers.dart:38,46,68` — Multiple `FutureProvider` builders use `result.data!` with a forced null-assert on `AsyncValue.data`. If the repository call returns null, this crashes the app with a null-check error at runtime.

**Rationale**: Any one of these providers failing (e.g., during DB migration, first launch, or data corruption) crashes the entire Dashboard screen instantly. The user sees a white screen or a crash rather than a graceful error state.

**Acceptance Criteria**:
- [ ] All forced unwraps in dashboard data providers replaced with safe access (`result.data ?? fallback`) or proper error propagation.
- [ ] Crash is replaced with a user-facing error/retry widget in the relevant card.

---

## MAJOR (feature is broken or misleading)

### M1. 31+ Hardcoded English strings across 12+ files — i18n broken

**Context**: User-facing strings hardcoded in English, never passed through `AppLocalizations.of(context)`. Affected locations:

| File | Examples |
|---|---|
| `export_section.dart` | "For a full data backup … go to Settings → Backup & Restore.", "CSV: overall stats…", "PDF: formatted report…", "JSON: structured data…", "Stats CSV: summary…", "Progress Analytics: plan…" |
| `next_up_card.dart` | "Next Up", "Scheduled lesson", "X upcoming lesson(s)", "X review(s) due", "Due for spaced repetition review", "X weak topic(s)", "Practice weak areas" |
| `dashboard_header.dart` | Semantics/tooltip `'Export Reports'`, `'Backup & Restore'` |
| `workload_card.dart` | "Remaining Workload", " lessons", "X topics need attention" |
| `session_history_screen.dart` | "Full Progress CSV", "Full Progress PDF", "Full Progress JSON", "What will be cleared:", bullet-point descriptions |
| `settings_screen.dart` | "Share", "Back Up Now", "Share last backup", API key plaintext warnings, "Student ID mismatch…", "Data restored successfully…" |
| `mentor_screen.dart` | "--- While you were away ---", "--- End of pending messages ---" |
| `notification_service.dart` | "Mentor Messages" (channel name, appears in OS settings), "Ready to continue learning?" |
| `engagement_scheduler.dart` | "Mentor Check-In" |
| `planner_providers.dart` | "'Failed_to_load_plan: $e'" (underscore-prefixed internal format exposed to user) |
| `focus_timer_screen.dart` / `tutor_screen.dart` | `(Focus)` hardcoded, `...` hardcoded |
| `question_card_widget.dart` | "Upload file", "Record audio", "File attached", "Recording complete", "Start recording" |
| `graph_drawing_canvas_widget.dart` | "Graph canvas", "Draw your graph here", "X strokes, Y points", "Freehand", "Line", "Rectangle", "Circle", "Text", "Plot Point" |
| `chat_bubble.dart` | "Read aloud" tooltip |
| `lesson_block_card.dart` | `'X / Y'` number separator |
| `dashboard_data_providers.dart` | "'All Subjects'" virtual subject label |
| `session_history_screen.dart` | Clear-data dialog text |

**Rationale**: All these strings display in English regardless of the user's selected locale (Spanish, future locales). This breaks the app's core i18n promise and creates a confusing bilingual experience.

**Acceptance Criteria**:
- [ ] Every user-facing string above is extracted into `.arb` files and accessed via `AppLocalizations.of(context)!.key`.
- [ ] String concatenation patterns like `'$count lessons'` replaced with ICU plural messages (`{count, plural, one {# lesson} other {# lessons}}`).
- [ ] `' / '` hardcoded separators replaced with localized templates or locale-aware list formatting.
- [ ] Semantics `label` / `tooltip` strings use `l10n` keys (not hardcoded English) for accessibility in non-English locales.

### M2. Raw `e.toString()` leaked to users at 15+ call sites

**Context**: Exception messages (`e.toString()`) are passed directly to SnackBars and dialogs across many screens:

- `subject_selection_screen.dart:136`
- `subject_topics_tab.dart:94,125,157,258`
- `source_detail_screen.dart:192`
- `question_bank_screen.dart:114`
- `profile_screen.dart:93,154`
- `api_config_screen.dart:197`
- `export_section.dart` (multiple)
- `settings_screen.dart:998,1200`
- `planner_providers.dart:346,380,546` (via `l10n.errorWithMessage(e.toString())`)

**Rationale**: Raw exception messages contain technical Dart internals (e.g., `Null check operator used on a null value`, `SocketException: OS Error: Connection refused`). Users see cryptic technical jargon they cannot act on. This is both a UX and a security concern (internal paths in stack traces).

**Acceptance Criteria**:
- [ ] Every `e.toString()` user-facing display replaced with a localized, human-readable message (e.g., `l10n.somethingWentWrong` or a context-appropriate message).
- [ ] `AppErrorHandler.handleError()` used consistently to map exceptions to localized user messages.
- [ ] Raw exception details logged via `Logger` for debugging but never displayed to the user.

### M3. `toStringAsFixed()` used for user-facing file size display (i18n violation)

**Context**: `settings_screen.dart:971,973` — File size formatting uses `toStringAsFixed(1)` and `toStringAsFixed(0)`, which always produces a period decimal separator (e.g., `"5.5 MB"`). This is incorrect for Spanish (`es`) and other comma-decimal locales.

**Rationale**: The `AGENTS.md` explicitly prohibits `toStringAsFixed()` for user-facing numeric displays. While `formatDecimal` exists in `number_format_utils.dart`, these call sites bypass it. Spanish users will see "5.5 MB" instead of "5,5 MB".

**Acceptance Criteria**:
- [ ] File size display uses locale-aware formatting (either `formatDecimal` or a dedicated `formatFileSize` helper that respects locale).
- [ ] Renders correctly as "5.5 MB" in `en` and "5,5 MB" in `es`.

### M4. Missing empty/error/loading states on key screens

**Context**: Several screens have weak or missing state handling:

| Screen | Issue |
|---|---|
| `topic_list_screen.dart` | Empty state is a bare `Text(l10n.noTopicsYetAddSome)` — no icon, no action button, inconsistent with `EmptyStateWidget` used everywhere else. |
| `question_bank_screen.dart` + `content_library_screen.dart` | Error states use `Text`+`ElevatedButton` directly instead of the standard `ErrorRetryWidget`. |
| `export_section.dart` | Export operations show **no loading indicator** — user taps export and nothing visible happens until the file is ready or an error snackbar appears. |
| `lesson_booking_sheet.dart` | `_loadAvailability()` failure is silently caught and logged — user sees no error. |
| `voice_bar.dart` | Mic permission denied gives **zero visual feedback** — icon silently does nothing. |
| `planner_providers.dart` | `loadMissedLessons()`, `loadPendingActions()`, `loadScheduledLessons()`, `checkAdherence()` all silently catch errors without surfacing to user UI state. |
| `dashboard_data_providers.dart` | Multiple providers return `null` / `[]` on error, collapsing "error" into "empty" — UI cannot distinguish between "no data" and "data failed to load." |

**Rationale**: Users in error states see blank or misleading content. The lack of loading indicators during exports creates uncertainty ("did my tap register?"). The lack of error feedback on permission denial is especially confusing.

**Acceptance Criteria**:
- [ ] All screens listed use `ErrorRetryWidget` (not bare `Text`+`ElevatedButton`) for error states.
- [ ] Export operations show a progress indicator (e.g., `LinearProgressIndicator` or spinner overlay).
- [ ] `voice_bar.dart` shows a snackbar or tooltip when mic permission is denied.
- [ ] `lesson_booking_sheet.dart` surfaces availability load errors to the user.
- [ ] Provider-level silent failures log to `Logger` and set a user-facing error state on the relevant `PlannerState` / dashboard model.
- [ ] `topic_list_screen.dart` empty state uses `EmptyStateWidget` with an icon and CTA button.

### M5. ShimmerWidget has no ExcludeSemantics — screen reader noise

**Context**: `shimmer_widget.dart` — The shimmer loading skeleton has no `Semantics(excludeSemantics: true)` wrapping. Screen readers will attempt to read the animated opacity/container changes as content, creating confusing noise.

**Rationale**: The shimmer is purely decorative/visual. Screen reader users hear garbage descriptions of loading placeholders instead of a concise "Loading…" message.

**Acceptance Criteria**:
- [ ] `ShimmerWidget` wraps its visual content in `ExcludeSemantics`.
- [ ] A separate `Semantics(liveRegion: true, label: l10n.loading)` widget handles the accessibility announcement.

### M6. Duplicate helper functions across 6 files — maintenance hazard

**Context**: These private helper functions are duplicated verbatim across multiple screen files:

- `_questionTypeLabel`: `question_bank_screen.dart`, `source_detail_screen.dart`
- `_sourceTypeLabel`: `content_library_screen.dart`, `source_detail_screen.dart`, `subject_detail_screen.dart`
- `_statusLabel` / `_processingStatusLabel`: `content_library_screen.dart`, `source_detail_screen.dart`, `subject_detail_screen.dart`

**Rationale**: Any change to the label logic (e.g., adding a new question type or source type) requires updating 3 files. This has already caused drift — some files format the label slightly differently. Inconsistent labels confuse users across different screens.

**Acceptance Criteria**:
- [ ] Shared label helpers extracted to a single utility file (e.g., `lib/core/utils/label_helpers.dart` or within the relevant feature's `data/` barrel).
- [ ] All 6+ files import from the shared source.
- [ ] Available types are covered comprehensively so no new type silently falls back to an ugly `.name` or index display.

---

## MINOR (code quality / UX friction)

### m1. PracticeSheetTemplate double-padding bug

**Context**: `practice_sheet_template.dart` — The widget applies `padding` parameter as outer `Padding` AND also calls `ResponsiveUtils.screenPadding(context)` inside the `Container`. This creates **double padding** on both sides (or triple if caller passes non-zero padding).

**Acceptance Criteria**:
- [ ] Padding is applied exactly once in `PracticeSheetTemplate`.
- [ ] No visual change in expected layout, but rendered padding is correct.

### m2. WeakAreasSheet is ~70% duplicate of SubjectSelectionSheet

**Context**: `weak_areas_sheet.dart` vs `subject_selection_sheet.dart` — Nearly identical widget structure. Only difference: `weak_areas_sheet.dart` has no `subtitleBuilder` parameter.

**Acceptance Criteria**:
- [ ] Both sheets refactored to share a common base or a single parameterized widget.
- [ ] No behavioral change; both screens work identically after refactor.

### m3. TopicSelectionSheet static `show` duplicates `build` logic

**Context**: `topic_selection_sheet.dart` — The static `show()` method re-instantiates the entire widget tree instead of delegating to the widget's `build()`. The two code paths are near-identical and can drift.

**Acceptance Criteria**:
- [ ] `show()` delegates to the widget's `build()` via a single shared widget instance or builder pattern.

### m4. Massive screen files (>800 lines) that should be split

**Context**: These files contain screens, private widgets, dialogs, and business logic mixed together:

| File | Lines |
|---|---|
| `settings_screen.dart` | 1825 |
| `planner_screen.dart` | 1463 |
| `mentor_screen.dart` | 1118 |
| `focus_timer_screen.dart` | 1090 |
| `tutor_screen.dart` | 928 |
| `practice_screen.dart` | 863 |
| `question_bank_screen.dart` | 842 |
| `practice_session_screen.dart` | 825 |

**Rationale**: Single files this large are hard to navigate, review, test, and maintain. Private dialogs/widgets inlined in these files should be extracted to separate files.

**Acceptance Criteria**:
- [ ] Each screen file reduced to <600 lines.
- [ ] Private dialogs/bottom-sheets extracted to `presentation/dialogs/` or `presentation/sheets/` subdirectories.
- [ ] Business logic extracted to service/provider calls (not inline in widget state).

### m5. Inconsistent state management — local mutable state vs Riverpod

**Context**: Several screens use local `StatefulWidget` mutable state (`_isLoading`, `_subjects`, `_error`) instead of Riverpod providers, creating inconsistency:

- `practice_screen.dart`: `_subjects`, `_dueCounts`, `_isLoading`, `_loadError`
- `lesson_list_screen.dart`: `_statusCache` as a plain `Map`
- `planner_screen.dart`: `_useMultiSyllabus`, `_paceHours`, `_syllabusEntries` as local state

**Rationale**: Mixed approaches make the codebase harder to reason about. New contributors must understand both patterns. Local state is lost on tab switch or rebuild, while Riverpod state persists.

**Acceptance Criteria**:
- [ ] All async data loading in screens uses Riverpod `AsyncValue` patterns (loading/error/data).
- [ ] Mutable state minimized; `StateProvider` or `StateNotifierProvider` used where local state is needed.

### m6. Direct repository instantiation instead of provider injection (7+ files)

**Context**: Several screens create repository instances directly with `new` instead of using Riverpod providers:

- `planner_screen.dart` — `SubjectRepository()`
- `practice_screen.dart` — `SourceRepository()`
- `upload_screen.dart` — `SubjectRepository()`
- `session_history_screen.dart` — Repository instances
- `subject_list_screen.dart` — `SessionRepository()` inside build
- `lesson_booking_sheet.dart` — `StudentAvailabilityRepository()`
- `inline_practice_widget.dart` — `StudentIdService()`

**Rationale**: Direct instantiation bypasses Hive initialization, adapter registration, and dependency injection. These repos may not have their boxes and adapters ready, causing runtime failures. They're also untestable (no way to inject fakes in widget tests).

**Acceptance Criteria**:
- [ ] All repository creation uses Riverpod providers (`ref.read(repositoryProvider)`).
- [ ] Widget tests can inject fakes via `ProviderScope(overrides: ...)`.

### m7. GraphDrawingCanvasWidget touch targets below 48px minimum

**Context**: `graph_drawing_canvas_widget.dart:279` — Toolbar icon buttons use fixed `EdgeInsets.all(8)` padding. With default icon size, this yields ~34px touch targets, below the WCAG-recommended 48px minimum. Similarly, `canvas_drawing_widget.dart:157-178` has smaller touch targets when `largeTouchTargets` is false.

**Acceptance Criteria**:
- [ ] All interactive toolbar buttons have minimum 48x48px touch targets per WCAG 2.1 Success Criterion 2.5.8.
- [ ] `MathInputToolbar` symbol buttons similarly meet 48px target.

### m8. TopicListScreen empty state is just a Text — no affordance

**Context**: `topic_list_screen.dart:58-60` — The empty state is a simple centered `Text(l10n.noTopicsYetAddSome)` — no icon, no illustration, no action button. All other empty states in the app use `EmptyStateWidget` which includes an icon and optional CTA.

**Acceptance Criteria**:
- [ ] Topic list empty state uses `EmptyStateWidget` with an appropriate icon and a "Add Topic" CTA button.

### m9. VoiceBar shows same tooltip for both mic states

**Context**: `voice_bar.dart:117` — The `IconButton` tooltip always shows `l10n.voiceInput` regardless of whether the mic is recording or idle. A user focused on the button cannot tell from the tooltip alone whether tapping will start or stop recording.

**Acceptance Criteria**:
- [ ] Tooltip changes to `l10n.stopRecording` (or similar) when the mic is active.
- [ ] A brief snackbar or tooltip shown when permission is denied, explaining how to enable it.

### m10. LessonBlockCard uses wrong localized key for incorrect quiz answer

**Context**: `lesson_block_card.dart:266` — When the user submits an incorrect quiz answer, the widget shows `Text(l10n.submitAnswer)` ("Submit Answer") instead of a localized "Incorrect" / "Wrong answer" message.

**Acceptance Criteria**:
- [ ] A localized `l10n.incorrectAnswer` or similar key is used for incorrect quiz feedback.
- [ ] The existing `l10n.submitAnswer` key is only used for the submit button label.

### m11. DashboardHeader actions overflow on narrow screens

**Context**: `dashboard_header.dart` — The `Row` containing 1 `Text` + 3 `IconButton`s has no overflow handling. On 320dp-wide screens, this will overflow.

**Acceptance Criteria**:
- [ ] The header row uses `Flexible` / `Wrap` or enters a collapsed "more actions" popup menu on narrow screens.

### m12. CollapsibleCard header double-activation zone

**Context**: `collapsible_card.dart:81-93` — The `InkWell` wraps the entire title row including the `IconButton`. Both the `InkWell` and the `IconButton` call `toggleCollapsed()`. Tapping the icon fires both handlers simultaneously.

**Acceptance Criteria**:
- [ ] The `IconButton` is excluded from the parent `InkWell`'s tap zone (e.g., by using `GestureDetector` with `HitTestBehavior.translucent` on only the title text area).

### m13. Dashboard onboarding checklist passes empty-string subjectId

**Context**: `empty_dashboard_checklist.dart:33` — The checklist item for starting practice passes `subjectId: ''` (empty string) to `PracticeSessionArgs`. Downstream screens that check `if (args.subjectId.isEmpty)` may silently misbehave.

**Acceptance Criteria**:
- [ ] Empty-string subjectId replaced with `null`, or the practice session uses a subject-selection screen when no specific subject is provided.
- [ ] Downstream screens handle null subjectId gracefully.

### m14. Accessibility: page indicator dots and filter chips lack semantics

**Context**: `onboarding_dialog.dart` — Page indicator dots have no `Semantics` (screen reader doesn't know current page). Across the app, filter chips in `question_bank_screen.dart`, `content_library_screen.dart`, and `session_history_screen.dart` have no `Semantics(button: true, label: ...)` or `Semantics(selected: ...)`.

**Acceptance Criteria**:
- [ ] Page indicator dots expose current page / total pages via Semantics.
- [ ] All filter chips have Semantics with `button: true` and `selected: bool` status.
- [ ] Filter chip labels come from l10n (not enum `.name` or index).

### m15. `formatInstrumentation` is `@visibleForTesting` but has no tests

**Context**: `export_section.dart` — The `formatInstrumentation` function is annotated `@visibleForTesting` but has no unit test file in the test suite.

**Acceptance Criteria**:
- [ ] Unit tests exist for `formatInstrumentation` covering all export formats (CSV, PDF, JSON, Progress CSV, Progress Analytics).
- [ ] Or the `@visibleForTesting` annotation is removed if the function is not intended for external testing.

### m16. WeakAreasCard catch block uses wrong error message

**Context**: `weak_areas_card.dart:146-148` — The catch block shows `l10n.noWeakAreasFound` even when the actual error is something else (network timeout, DB error, etc.). A network failure being reported as "no weak areas found" is misleading.

**Acceptance Criteria**:
- [ ] Error types are distinguished: network errors show a retry message, empty results show "no weak areas found."

### m17. ChatBubble evaluation content fallback shows raw JSON to users

**Context**: `chat_bubble.dart:225` — When `_buildEvaluationContent` fails to parse a JSON evaluation message, it falls back to `Text(content)`, showing the raw JSON string to the user.

**Acceptance Criteria**:
- [ ] JSON parse failure shows a localized fallback message (e.g., "Unable to display evaluation result") and logs the raw content for debugging.

### m18. Inconsistent Semantics headingLevel usage across dashboard cards

**Context**: Among the 13 dashboard card widgets, `mastery_progress_card.dart`, `topic_breakdown_card.dart`, `plan_adherence_card.dart`, and `due_reviews_card.dart` use `Semantics(headingLevel: 3)` on their titles. But `weak_areas_card.dart` and `workload_card.dart` do NOT — their titles have no heading semantics.

**Acceptance Criteria**:
- [ ] All dashboard card titles consistently use `Semantics(headingLevel: 3)` (or the appropriate heading level).
- [ ] Screen reader users can navigate between dashboard cards by heading in a consistent hierarchy.

### m19. Strings concatenated with `·` and non-localizable patterns

**Context**: `planner_screen.dart:865,1078,1091,1127-1145` — Multiple instances of patterns like `'${goal.targetDays} ${l10n.days} ${l10n.planSummary} · $topicCount ${l10n.topics}'`. The `·` (middle dot) separator and string order do not adapt to RTL or different word-order languages.

**Acceptance Criteria**:
- [ ] All concatenated strings with custom separators replaced with localized template strings from ARB files.
- [ ] ICU MessageFormat or simple `l10n.planSummaryDays(count, topicCount)` patterns used.

### m20. ProfileScreen locale switch may leave stale text on itself

**Context**: `profile_screen.dart` — Changing locale via `ref.read(localeProvider.notifier).state = Locale(value)` does not force the current screen to rebuild. Per AGENTS.md: "any screen that caches `l10n = AppLocalizations.of(context)!` in a local variable will display stale strings."

**Acceptance Criteria**:
- [ ] Profile screen re-reads `AppLocalizations.of(context)` in `build` or uses `ref.watch(localeProvider)` to trigger rebuild on locale change.
- [ ] Alternatively, a `Navigator.pushAndRemoveUntil` is used after locale change to refresh the whole stack.
