# UI/UX Master — Round 3 Issue Report

**Date:** 2026-05-21
**Scope:** Web platform (PWA/manifest/meta), loading/error/empty state audit, route transitions, inline vs reusable widgets, locale switching, accessibility
**Method:** Screen-by-screen audit, web asset inspection, transition/animation analysis, accessibility semantics review, locale-switch behavior testing
**Note:** This report supplements the Round 1 and Round 2 reports in `issues/completed/`. Findings below are **new** — not present in earlier rounds.

---

## BLOCKER — App crashes or user cannot proceed

### B-1: Web PWA manifest and viewport missing — app unresponsive on mobile web

**Context:**
- `web/index.html:1-46`
- `web/manifest.json:1-35`

**Issue (a): Missing `<meta name="viewport">` tag.** The `web/index.html` does NOT include:
```html
<meta name="viewport" content="width=device-width, initial-scale=1.0">
```
Without this tag, mobile browsers render the app at a desktop-width viewport (typically 980px). The user must manually pinch-zoom to see any content. All `ResponsiveUtils` breakpoints (xs=600px, sm=840px) become meaningless because the effective CSS pixel width is always —980px on every phone.

**Issue (b): PWA manifest colors use default Flutter blue instead of app brand purple.**
```json
{
  "background_color": "#0175C2",
  "theme_color": "#0175C2"
}
```
The app's seed color is `#673AB7` (deep purple). The manifest's blue (`#0175C2`) creates a jarring color mismatch on the PWA splash screen, task switcher, and browser chrome. Users installing the PWA see a blue splash screen that transitions to a purple app.

**Issue (c): `<title>studyking</title>` uses lowercase.** The app brand is "StudyKing" (capital S, capital K). The HTML title and `apple-mobile-web-app-title` use lowercase "studyking".

**Rationale:** On mobile web (the most accessible entry point for new users without app store installation), the missing viewport tag makes the app functionally unusable — all UI renders at ~41% scale on a typical 400px-wide phone. The brand color mismatch erodes trust: the PWA looks like a generic template.

**Affected files:**
- `web/index.html` — add viewport meta tag, fix casing
- `web/manifest.json` — update colors to seed color `#673AB7`

**Acceptance criteria (fixed):**
- Add `<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">` to `web/index.html` `<head>` before the `<base>` tag.
- Change `manifest.json` `background_color` and `theme_color` to `#673AB7` (matching `ColorScheme.fromSeed` seed color in `app_theme.dart:169`).
- Update `<title>` and `apple-mobile-web-app-title` to "StudyKing".
- Verify on a 375px-wide emulated mobile device: content fills the viewport, no horizontal scroll, no pinch-zoom required.

---

### B-2: `onGenerateRoute` always uses fade transition — violates `reduceMotion` setting

**Context:** `lib/core/routes/app_router.dart:323-335`

```dart
PageRouteBuilder<dynamic> _materialPageRoute(Widget page, RouteSettings settings) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: Timeouts.routeTransition,
  );
}
```

**Issue:** The route transition animation ignores the user's `reduceMotion` setting entirely. Every navigation — including trivial route pushes like opening a dialog-equivalent screen — uses a 200ms `FadeTransition`. For users with `reduceMotion: true` in Settings or with the system `Accessibility > Reduce Motion` enabled, the animation still plays.

Per AGENTS.md: `"Use `pumpAndSettle` for widget tests that involve async operations"` — but the production code doesn't check the setting.

**Rationale:** For users with vestibular disorders or who prefer reduced motion, unnecessary animations can cause discomfort. The `MainScreen` already reads `settingsProvider.reduceMotion` but applies it only to tab switching (line 664 of `main.dart`), not to route transitions.

**Affected files:**
- `lib/core/routes/app_router.dart:323-335`

**Acceptance criteria (fixed):**
- Pass `reduceMotion` flag to `_materialPageRoute` (via a global or provider).
- When `reduceMotion == true`, use `TransitionBuilder.none` (instant transition) or `OpacityTransition` with `0ms` duration.
- Verify: with `reduceMotion: true`, navigation is instant (no fade); with `reduceMotion: false`, existing 200ms fade is preserved.
- Test: widget test asserting route transition duration == 0 when reduceMotion is enabled.

---

## MAJOR — Feature is broken or misleading

### M-1: Locale-switch stale text on `AutomaticKeepAliveClientMixin` screens (TutorScreen, MentorScreen, FocusTimerScreen, etc.)

**Context (per AGENTS.md i18n Locale Switching Gotcha):**
- `lib/features/teaching/presentation/tutor_screen.dart:54` — `AutomaticKeepAliveClientMixin`
- `lib/features/mentor/presentation/mentor_screen.dart:33` — no mixin, but caches `l10n` via `AppLocalizations.of(context)!`
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:44` — `AutomaticKeepAliveClientMixin`
- `lib/features/settings/presentation/settings_screen.dart:76` — `AutomaticKeepAliveClientMixin`
- `lib/features/dashboard/presentation/dashboard_screen.dart:46` — `AutomaticKeepAliveClientMixin`
- `lib/features/sessions/presentation/session_tracker_screen.dart:37` — `AutomaticKeepAliveClientMixin`
- `lib/features/practice/presentation/screens/practice_screen.dart:55` — `AutomaticKeepAliveClientMixin`
- `lib/features/subjects/presentation/subject_detail_screen.dart` — likely also affected

**Issue:** Any screen with `AutomaticKeepAliveClientMixin` that also calls `AppLocalizations.of(context)!` at the top of `build` is vulnerable to stale locale text. When the user changes language in Profile screen:
```dart
ref.read(localeProvider.notifier).state = Locale(value);
```

The `MaterialApp` rebuilds with the new locale. However, screens with `wantKeepAlive = true` are in a preserved subtree. Their `build` method IS called (because `ref.watch(localeProvider)` is triggered), BUT if the screen uses `AutomaticKeepAliveClientMixin`, the `KeepAlive` parent may short-circuit the full build. The l10n captured via `AppLocalizations.of(context)!` references a `Localizations` widget that may have already been replaced, returning stale strings.

At minimum, `TutorScreen` (line 643+ in its build) caches `l10n` locally:
```dart
final l10n = AppLocalizations.of(context)!;
```
And then uses it for ALL strings. After locale switch, these strings remain unchanged until the user re-enters the screen.

**Rationale:** The AGENTS.md explicitly warns: "any screen that caches l10n in a local variable will display stale strings until the screen is re-entered." This affects the most-used screens (Dashboard, Practice, FocusTimer, Settings) and the most AI-intensive screens (Tutor, Mentor). A user who switches from English to Spanish will see a mix of English and Spanish text.

**Affected files:**
- ALL screens with `AutomaticKeepAliveClientMixin` that read `l10n` at build time

**Acceptance criteria (fixed):**
- For screens using `AutomaticKeepAliveClientMixin`, ensure they also `ref.watch(localeProvider)` in `build` to force rebuild on locale change, AND call `AppLocalizations.of(context)!` inside `build` (not cached).
- Add a `ref.watch(localeProvider)` call before any `l10n` usage in all affected screens.
- Verify: switch locale → navigate to Dashboard → all text is in the new locale.
- Write a test: mock locale provider → change locale → assert screen re-renders with new strings.

---

### M-2: SettingsScreen has no loading indicator — blank screen until provider resolves

**Context:** `lib/features/settings/presentation/settings_screen.dart:69-82`

```dart
class _SettingsScreenState extends ConsumerState<SettingsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: _buildSettingsBody(settings, l10n, theme),
    );
  }
```

**Issue:** `settingsProvider` is an async provider. On first load (or after invalidation), the provider is in `AsyncLoading` state. However, the screen doesn't check `settings.isLoading` — it just reads `ref.watch(settingsProvider)` and passes whatever value comes through. If the provider returns a default/empty `Settings` object during loading, the screen renders empty sections. If it returns `AsyncValue.loading()`, the `.value` access may throw or return null.

There is no `AsyncValue.when()` pattern here, unlike most other screens. Compare with `SubjectListScreen` which correctly uses:
```dart
subjectsAsync.when(
  data: ...,
  loading: () => const Center(child: LoadingIndicator()),
  error: (error, stack) => ErrorRetryWidget(...),
);
```

**Rationale:** A blank Settings screen on first load (especially on slow devices where Hive takes time) appears broken. Users who navigate to Settings to fix an API key error see nothing — a frustrating dead end.

**Affected files:**
- `lib/features/settings/presentation/settings_screen.dart`

**Acceptance criteria (fixed):**
- Use `ref.watch(settingsProvider)` with `.when()` pattern (loading / error / data).
- Show `LoadingScreen()` during loading state.
- Show `ErrorRetryWidget` with `ref.invalidate(settingsProvider)` on error.
- Use `settings.valueOrNull` for the data case, or add a proper `.when()` builder.
- Verify: invalidate `settingsProvider` → see loading indicator → data appears.

---

### M-3: LessonDetailScreen builds inline error/empty UIs instead of using reusable widgets

**Context:** `lib/features/lessons/presentation/lesson_detail_screen.dart:103-181`

**Issue:** The screen has three manual state branches:
1. **Error state (lines 103-144):** Builds its own `Scaffold` with inline `Icon(Icons.error_outline)`, `Text(l10n.failedToLoadLesson)`, `OutlinedButton.icon` for back, and `FilledButton.icon` for retry. This is a custom layout that duplicates the functionality of `ErrorRetryWidget` and `NotFoundScreen`.
2. **Loading state (lines 146-151):** Shows `LoadingIndicator()` — correct use of reusable widget.
3. **Empty blocks state (lines 154-182):** Builds its own `Icon(Icons.hourglass_top)`, `Text(l10n.generating)`, `Text(l10n.inProgress)`, and `OutlinedButton.icon` for refresh. This duplicates `EmptyStateWidget`.

The error state (lines 103-144) is particularly wasteful — it duplicates the `Scaffold` wrapper and AppBar that's already present in the loading and success states. If the AppBar title, back button behavior, or error icon changes, it must be updated in three places.

**Rationale:** The project has well-designed reusable widgets (`ErrorRetryWidget`, `EmptyStateWidget`, `LoadingIndicator`) in `lib/core/widgets/`. Not using them creates code duplication, inconsistent error layouts across screens (LessonDetail's error has back+retry buttons side by side, while other screens use the centered `ErrorRetryWidget` with retry only), and maintenance burden.

**Affected files:**
- `lib/features/lessons/presentation/lesson_detail_screen.dart:103-181`

**Acceptance criteria (fixed):**
- Replace the error state block (lines 103-144) with `ErrorRetryWidget(message: l10n.failedToLoadLesson, onRetry: _retryLoadLesson)`.
- Add a "go back" action by wrapping in a `Scaffold` with AppBar that has a back button (or make `ErrorRetryWidget` support an optional back callback).
- Replace the empty blocks state (lines 154-182) with `EmptyStateWidget(icon: Icons.hourglass_top, title: l10n.generating, subtitle: l10n.inProgress, actionLabel: l10n.retry, onAction: _loadLesson)`.
- Verify: error/empty states render with consistent styling compared to other screens.

---

### M-4: PlannerScreen shows raw `Exception` strings to users via SnackBar

**Context:** `lib/features/planner/presentation/planner_screen.dart:221-228`

```dart
ref.listen<PlannerState>(plannerProvider, (prev, next) {
  if (next.error != null && prev?.error != next.error) {
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(next.error!.contains('{') || next.error!.contains('Exception')
          ? l.somethingWentWrong
          : next.error!)),
    );
```

**Issue:** The error display logic attempts to filter raw errors by checking for `{` or `Exception` substrings. This heuristic is fragile:
- `next.error!.contains('{')` — catches JSON-like errors but misses exceptions with messages like `"HiveBoxNotOpen"` or `"SocketException: Connection refused"`.
- `next.error!.contains('Exception')` — case-sensitive, misses lowercase "exception" in some platforms and Dart's `Error` types.
- If neither pattern matches, the **raw error string is shown to the user**. For example, a database error like `"Failed to load roadmap: Null check operator used on a null value"` would pass through.

This violates the AGENTS.md Error Handling Convention: `"Public repository and service method return types must be Result<T>"` and `"throw is only allowed in private helper methods"`. If PlannerState.errors contain uncaught exceptions from the service layer, this indicates a deeper architecture issue.

**Rationale:** Users seeing "Null check operator used on a null value" or "type 'String' is not a subtype of type 'int'" in a SnackBar will be confused and may lose trust in the app. The planner is a critical feature for goal-oriented students.

**Affected files:**
- `lib/features/planner/presentation/planner_screen.dart:221-228`
- `lib/features/planner/providers/planner_providers.dart` (PlannerState model — errors should use ErrorCode or sealed class)

**Acceptance criteria (fixed):**
- Replace `PlannerState.error` (String) with a sealed `PlannerError` class (or use `SpacedRepetitionErrorCode` pattern) so the UI can switch on error type.
- Ensure all planner service methods return `Result<T>` — no `throw`.
- Remove the fragile heuristic filtering. Every SnackBar message must be a localized string from `l10n`.
- Log the raw error to Logger with descriptive message.
- Test: inject a planner service that returns `Result.failure(PlannerError.databaseError)` → UI shows localized "Something went wrong", not the raw error.

---

### M-5: SubjectListScreen uses dual async pattern (Riverpod.when + FutureBuilder)

**Context:** `lib/features/subjects/presentation/subject_list_screen.dart:39-103`

```dart
subjectsAsync.when(
  data: (repository) => _buildSubjectList(context, ref, repository),
  loading: () => const Center(child: LoadingIndicator()),
  error: (error, stack) => ErrorRetryWidget(...),
),

// Then inside _buildSubjectList:
FutureBuilder<List<Subject>>(
  future: repository.getAll().then((r) => r.data ?? []),
  builder: (context, snapshot) { ... },
)
```

**Issue:** The Riverpod provider already fetches the subject list. The `when()` data callback receives a `SubjectRepository` instance. But instead of using the already-loaded data, `_buildSubjectList` calls `repository.getAll()` again via `FutureBuilder`, creating a second async fetch. This means:
1. Two async requests to Hive for the same data.
2. The `FutureBuilder` shows its own loading state (briefly) after Riverpod's loading state cleared.
3. The `FutureBuilder` error state duplicates Riverpod's error handling.
4. If the repository uses Riverpod's `ref.watch`, the `FutureBuilder` may not react to data changes.

**Rationale:** The dual pattern adds unnecessary complexity and an extra Hive read on every build. The `FutureBuilder` shows a flash of `LoadingIndicator()` between Riverpod's data resolution and the `FutureBuilder`'s completion.

**Affected files:**
- `lib/features/subjects/presentation/subject_list_screen.dart:64-104`

**Acceptance criteria (fixed):**
- Remove the `FutureBuilder` entirely. Pass the subjects list directly from the Riverpod provider.
- Create a dedicated `subjectListProvider` (or extend `subjectsRepositoryProvider`) that returns `List<Subject>` (not `SubjectRepository`).
- Use the data from Riverpod's `.when()` directly in `ListView.builder`.
- Verify: subject list loads exactly once on navigation, no flash between loading states.

---

### M-6: LLM Task Manager has no loading state — flashes "No LLM tasks yet" before data arrives

**Context:** `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart:91-143`

```dart
Widget build(BuildContext context) {
  final tasks = taskService.getAllTasks();
  // ...
  return Scaffold(
    body: tasks.isEmpty
        ? Center(child: Column(children: [
            Icon(Icons.check_circle_outline),
            Text(l10n.noLlmTasksYet),
          ]))
        : Column(children: [ ... ]),
  );
}
```

**Issue:** The screen uses a listener pattern (`addListener → _onTasksChanged → setState`). On first build, `_onTasksChanged` may not have fired yet (or the task service may not have completed its initial async load). The `tasks` list is empty, so the screen renders "No LLM tasks yet" — then immediately replaces it with the task list when the listener fires.

This flash is especially noticeable because:
- The `llmTaskServiceProvider` may need to read from Hive or memory
- The empty state icon (`check_circle_outline`) is misleading — it suggests "all clear" rather than "loading"

**Rationale:** A flash of "no data" before showing data is a common UX anti-pattern that creates visual noise and can confuse users about whether their data has been lost.

**Affected files:**
- `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart:113-125`

**Acceptance criteria (fixed):**
- Add an `_isInitialized` flag that transitions from false to true after the first `_onTasksChanged` callback.
- While `!_isInitialized`, show `LoadingIndicator()` instead of the empty state.
- Use `EmptyStateWidget` for the empty state after initialization (instead of inline layout).
- Verify: screen shows loading → transitions to data or empty (no flash).

---

### M-7: OnboardingDialog has hardcoded 360px content height — not responsive

**Context:** `lib/features/onboarding/presentation/onboarding_dialog.dart:74-76`

```dart
SizedBox(
  height: 360,
  child: PageView(
    controller: _pageController,
    ...
```

**Issue:** The onboarding dialog constrains its content area to exactly 360px. On small phones (e.g., iPhone SE at 667px screen height with status bar and dialog padding), this leaves little room for the page indicators, buttons, and checkbox below — potentially overflowing the dialog. On tablets, the 360px is dwarfed by the available space, wasting the opportunity for larger illustrations.

**Rationale:** The onboarding dialog is the first thing new users see. A cramped or overflowing dialog creates a poor first impression. The content height should adapt to screen size.

**Affected files:**
- `lib/features/onboarding/presentation/onboarding_dialog.dart:74-76`

**Acceptance criteria (fixed):**
- Replace the fixed 360px height with a responsive value: `MediaQuery.sizeOf(context).height * 0.4` or `ResponsiveUtils`-based min/max.
- Set a minimum height of 320px (for very small screens) and maximum of 480px (for large screens).
- Verify on: iPhone SE (667px height), Pixel 7 (900px), iPad (1080px) — no overflow, no wasted space.

---

### M-8: PracticeScreen FloatingActionButton overflows on very narrow widths

**Context:** `lib/features/practice/presentation/screens/practice_screen.dart:858-887`

```dart
floatingActionButton: LayoutBuilder(
  builder: (context, constraints) {
    final isXs = constraints.maxWidth < 360;
    if (isXs) {
      return FloatingActionButton.small(...);
    }
    return SizedBox(
      width: constraints.maxWidth - 64,
      child: FloatingActionButton.extended(
        // ... width is (constraints.maxWidth - 64)
      ),
    );
  },
),
```

**Issue:** When `constraints.maxWidth` is between 360 and ~380, the FAB width `constraints.maxWidth - 64` is still very narrow (296-316px). The FAB's internal padding (horizontal 24dp on each side) plus the icon (24dp) and text can exceed this width on longer localized strings. For example, Spanish "Practicar" or German "Üben" may overflow.

More critically, `constraints.maxWidth - 64` could be 0 or negative if `constraints.maxWidth < 64`, causing a `SizedBox` with negative/zero dimension.

**Rationale:** A truncated or overlapped FAB makes the primary CTA (starting practice) inaccessible.

**Affected files:**
- `lib/features/practice/presentation/screens/practice_screen.dart:858-887`

**Acceptance criteria (fixed):**
- Add a minimum width clamp: `max(constraints.maxWidth - 64, 200)` or use `FloatingActionButton.extended` with `Constraints.tightFor(width: ...)`.
- Use `Flexible` child: if the text doesn't fit, the FAB should still render with ellipsis.
- Verify on a 320px-wide emulated device: FAB renders without overflow, text is readable.

---

## MINOR — Code quality / UX friction

### m-1: Chat bubble has nested/conflicting Semantics wrappers

**Context:** `lib/features/teaching/presentation/widgets/chat_bubble.dart:32-100`

**Issue:** The chat bubble builds several layers of semantics:
1. **Outer `Row`** (line 32-100): No explicit Semantics wrapper (OK).
2. **Inner text content** (lines 130-149):
   ```dart
   final textWidget = Text(content, ...);
   if (message.isStreaming) {
     return Semantics(liveRegion: ..., child: textWidget);
   }
   return Semantics(label: message.content, child: textWidget);
   ```
3. **Evaluation content** (lines 158-218): Has its own `Semantics(label: _evaluationSemanticLabel(...))`.

When both the outer `InkWell` (via `Semantics(button: true, label: ...)` in the conversation list) and the inner `Semantics(label: content)` read the same message, a screen reader may announce the content twice — once as the button label and once as the static text. The `Semantics(label: message.content)` on line 148 overrides the Text widget's auto-generated semantics but doesn't merge with the parent button semantics.

**Rationale:** Duplicate or conflicting screen reader announcements degrade the experience for blind and low-vision users — one of the app's stated audiences given the voice-input features.

**Affected files:**
- `lib/features/teaching/presentation/widgets/chat_bubble.dart:32-149`

**Acceptance criteria (fixed):**
- Remove the inner `Semantics(label: message.content)` wrapper on line 146-148. The `Text` widget already exposes its content to accessibility APIs.
- Keep the `Semantics(liveRegion: ...)` for streaming messages (line 141).
- For evaluation content, ensure the Row containing the score icon and percentage is labeled once via `Semantics(label: _evaluationSemanticLabel(...), child: Row(...))`.
- Verify with TalkBack/VoiceOver: message content is announced once, not duplicated.

---

### m-2: PlannerScreen uses `ScaffoldMessenger.maybeOf()` — inconsistent error handling pattern

**Context:** `lib/features/planner/presentation/planner_screen.dart:224`

```dart
ScaffoldMessenger.maybeOf(context)?.showSnackBar(...)
```

**Issue:** The planner is the only screen in the app that uses `ScaffoldMessenger.maybeOf()`. All other screens use `ScaffoldMessenger.of(context)` (which throws if no `ScaffoldMessenger` is found). The `maybeOf` pattern silently swallows errors if the context is not inside a MaterialApp (which should never happen in this app's architecture). This inconsistency suggests the planner screen was built with defensive coding that masks potential bugs.

**Rationale:** Silent error swallowing in critical user feedback (error SnackBars) means failures in the planner go completely unnoticed. Other screens trust the architecture and use `of()` consistently.

**Affected files:**
- `lib/features/planner/presentation/planner_screen.dart:224, 233`

**Acceptance criteria (fixed):**
- Replace `ScaffoldMessenger.maybeOf(context)?.showSnackBar` with `ScaffoldMessenger.of(context).showSnackBar`.
- Add a comment if the `maybeOf` was intentional (explaining the edge case), or remove it for consistency.
- Verify: planner error SnackBars display correctly in all navigation contexts.

---

### m-3: `ShimmerWidget` has `didChangeDependencies` that calls `_controller.repeat()` without checking mounted

**Context:** `lib/core/widgets/shimmer_widget.dart:40-51`

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final enabled = TickerMode.valuesOf(context).enabled;
  if (enabled) {
    if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  } else {
    if (_controller.isAnimating) {
      _controller.stop();
    }
  }
}
```

**Issue:** `didChangeDependencies` can be called multiple times during the widget's lifecycle. If the widget is deactivated and reactivated (e.g., moving between tabs), `TickerMode` may flip. However, there's no `mounted` check before calling `_controller.repeat()`. If the widget is in the process of being unmounted but `didChangeDependencies` fires (due to a parent rebuilding), `_controller.repeat()` could throw because the `Ticker` is already disposed.

**Rationale:** The shimmer is used in the dashboard (the most-loaded screen). A crash in `ShimmerWidget.didChangeDependencies` could crash the entire dashboard, which is the first screen users see.

**Affected files:**
- `lib/core/widgets/shimmer_widget.dart:40-51`

**Acceptance criteria (fixed):**
- Add `if (!mounted) return;` at the top of `didChangeDependencies`.

---

### m-4: `ConversationInput` uses `CallbackShortcuts` with an empty binding for Shift+Enter

**Context:** `lib/core/widgets/conversation_input.dart:54-58`

```dart
CallbackShortcuts(
  bindings: {
    const SingleActivator(LogicalKeyboardKey.enter, shift: true): () {},
  },
  child: FocusTraversalGroup(...),
)
```

**Issue:** The `CallbackShortcuts` widget maps `Shift+Enter` to an empty no-op function. This swallows the `Shift+Enter` event entirely — it cannot bubble up or be handled by a parent. If a user expects `Shift+Enter` to insert a newline in the text field, it does nothing. The underlying `TextField` with `maxLines: 4` supports multi-line input, but there's no way to insert a newline because:
- `Enter` alone triggers `onSubmitted → _debouncedSend`
- `Shift+Enter` is consumed by the empty callback

This is a critical usability issue for users typing longer messages that need line breaks.

**Rationale:** The mentor chat and tutor chat both use `ConversationInput` with `maxLines: 4`. Users writing multi-paragraph questions or code snippets cannot format their input. For an AI tutoring app, this is a significant limitation.

**Affected files:**
- `lib/core/widgets/conversation_input.dart:54-58`

**Acceptance criteria (fixed):**
- Remove the `CallbackShortcuts` wrapper entirely (it's not needed — `TextField.onSubmitted` only fires on `Enter` without shift by default).
- Or change the binding to insert a newline: `const SingleActivator(LogicalKeyboardKey.enter, shift: true): () => controller.text += '\n'`.
- Verify: `Enter` sends the message, `Shift+Enter` inserts a newline, the text field handles multi-line content correctly.

---

### m-5: `PlannerScreen` popup menu items use ListTile with fixed `dense: true, contentPadding: EdgeInsets.zero` — non-standard PopupMenu layout

**Context:** `lib/features/planner/presentation/planner_screen.dart:262-289`

```dart
PopupMenuItem(
  value: 'extend',
  child: ListTile(
    leading: const Icon(Icons.date_range, size: 20),
    title: Text(l10n.catchUp),
    dense: true,
    contentPadding: EdgeInsets.zero,
  ),
),
```

**Issue:** The popup menu items use `ListTile` inside `PopupMenuItem`. This is non-standard — `PopupMenuItem` already provides the correct Material 3 touch target size and padding. Nesting `ListTile` inside `PopupMenuItem`:
1. Double-pads the content (ListTile's internal padding + PopupMenuItem's padding).
2. Uses `contentPadding: EdgeInsets.zero` to compensate, which is fragile.
3. The `dense: true` reduces the touch target below the recommended 48dp.

The correct pattern is to use `PopupMenuItem(child: Text(...))` or `PopupMenuItem(child: ListTile(...))` but not both layered.

**Rationale:** Inconsistency with Material 3. The non-standard padding may cause clipped text on some platforms or with larger font sizes.

**Affected files:**
- `lib/features/planner/presentation/planner_screen.dart:262-289`

**Acceptance criteria (fixed):**
- Replace `PopupMenuItem(child: ListTile(...))` with either `PopupMenuItem(child: Row(children: [Icon(...), SizedBox(width: 8), Text(...)]))` or use the `PopupMenuButton`'s `itemBuilder` with properly padded items.
- Ensure touch targets are ≥ 48dp.
- Verify: popup menu renders with standard Material 3 spacing.

---

### m-6: No Home/End or page-based keyboard navigation in scrollable screens

**Context:** Multiple screens with `ListView` or `ScrollView`:
- `lib/features/dashboard/presentation/dashboard_screen.dart` — long scrollable content
- `lib/features/settings/presentation/settings_screen.dart` — very long scrollable content
- `lib/features/sessions/presentation/session_history_screen.dart` — filterable list
- `lib/features/questions/presentation/question_bank_screen.dart` — searchable list

**Issue:** None of the scrollable screens handle keyboard navigation beyond default Flutter scroll behavior. On desktop/web platforms (which the app supports via `kIsWeb` and Linux builds), users expect:
- `Home` / `End` keys to jump to top/bottom
- `Page Up` / `Page Down` for rapid navigation
- Focusable section headers for skip-navigation

The app's scroll behavior (`_AppScrollBehavior` in `main.dart:450-477`) correctly enables scrollbars for desktop platforms but doesn't enable keyboard scroll shortcuts.

**Rationale:** Desktop users (especially on Linux where the app can be installed) expect standard keyboard navigation. The Settings screen is 2025+ lines scrolled — keyboard navigation is essential for power users.

**Affected files:**
- `lib/core/widgets/widgets.dart` — add a `ScrollConfiguration` or `KeyboardScrollConfiguration`
- All long scrollable screens

**Acceptance criteria (fixed):**
- Create a `KeyboardScrollConfiguration` (or extend `_AppScrollBehavior`) that binds `Home`, `End`, `PageUp`, `PageDown` to `Scrollable.ensureVisible` or `ScrollController.jumpTo`.
- Apply it to the `MaterialApp` scrollBehavior or wrap individual scrollable screens.
- Verify: on desktop web/Linux, pressing `Home` scrolls to top, `End` scrolls to bottom.

---

### m-7: `LlmTaskManagerScreen` empty state uses inline layout instead of `EmptyStateWidget`

**Context:** `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart:113-125`

```dart
body: tasks.isEmpty
    ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(l10n.noLlmTasksYet,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      )
    : ...
```

**Issue:** The inline empty state duplicates `EmptyStateWidget` but with missing features:
- No responsive icon size (hardcoded 64px)
- No subtitle (while the existing EmptyStateWidget supports it)
- No action button (cannot navigate to generate a task)
- Uses `check_circle_outline` icon, which looks like "success" rather than "empty"

**Affected files:**
- `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart:113-125`

**Acceptance criteria (fixed):**
- Replace inline empty state with `EmptyStateWidget(icon: Icons.auto_awesome_outlined, title: l10n.noLlmTasksYet, subtitle: l10n.llmTasksEmptyHint, actionLabel: l10n.learnMore, onAction: () => Navigator.pushNamed(context, AppRoutes.quickGuide))`.

---

### m-8: PWA `display: standalone` but no offline fallback page

**Context:** `web/manifest.json:5`

```json
"display": "standalone"
```

**Issue:** The app is configured as a PWA with `display: standalone` (full-screen app-like experience), but there's no service worker registration or offline fallback page. When the user installs the PWA and has no network:
- The app shows Flutter's default white-screen error
- No "You are offline" message
- No cached assets from a service worker

This is a partial issue: Flutter web already bundles assets in the initial download, so the app may work offline for previously loaded routes. But without a service worker, new data fetches silently fail.

**Affected files:**
- Any new file `web/service_worker.dart` or equivalent
- `web/manifest.json`

**Acceptance criteria (fixed):**
- Register a basic Flutter service worker via `flutter_bootstrap.js` or a custom service worker script.
- Add a network connectivity listener that shows a banner when offline (similar to `ApiKeyBanner` pattern).
- Not a full offline mode — just graceful degradation.

---

## Summary

| Severity | Count | Key themes |
|---|---|---|
| BLOCKER | 2 | Web viewport/PWA missing (mobile web unusable), reduceMotion ignored in all route transitions |
| MAJOR | 8 | Stale locale text on kept-alive screens, no loading in Settings, inline error UIs in LessonDetail, raw error leaks in Planner, dual async in SubjectList, LLM screen flashes empty, non-responsive onboarding dialog, FAB overflow |
| MINOR | 8 | Nested chat semantics, inconsistent SnackBar pattern, shimmer mounted check, no Shift+Enter newline, non-standard popup menu layout, no desktop keyboard nav, LLM screen doesn't use EmptyStateWidget, no offline PWA fallback |
