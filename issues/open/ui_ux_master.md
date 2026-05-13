# UI/UX Issue: Broken Subject Detail Screen & Systemic Design Language Violations

## Context

The `SubjectDetailScreen` (`lib/features/subjects/presentation/subject_detail_view.dart`) is a critical navigation hub with 4 tabs (Lessons, Practice, History, Stats), but **two of its tab builder methods are missing** — the screen will crash at runtime when those tabs are selected. Beyond this crash, the file exemplifies systemic problems across the codebase: hardcoded colors bypassing the Material 3 theme, `as dynamic` casts that subvert type safety, nested `Card` widgets creating visual artifacts, and a fixed `SliverAppBar` height that does not respond to screen size.

These patterns recur in 20+ files (practice, sessions, questions, lessons, settings) and erode the design system, accessibility, and responsiveness that the `AppTheme` and `ResponsiveUtils` infrastructure was built to provide.

---

## Affected Files

| File | Lines | Issue |
|------|-------|-------|
| `lib/features/subjects/presentation/subject_detail_view.dart` | 189, 192 | `_buildPracticeTab()` and `_buildHistoryTab()` referenced but **never defined** — runtime crash |
| Same file | 266–270 | **Nested `Card`** (Card inside Card) produces double elevation shadow and visual artifact |
| Same file | 262–319 | **`as dynamic` casts** on Lesson objects (`(lesson as dynamic).title`, `(lesson as dynamic).questionIds`) defeat type safety |
| Same file | 69 | Fixed `SliverAppBar(expandedHeight: 200)` does not adapt to screen height |
| Same file | 272–285 | Hardcoded `Colors.green`, `Colors.orange`, `Colors.red` for score indicators bypass theme |
| `lib/features/questions/ui/widgets/question_card_widget.dart` | 104, 116, 129, 285 | **`FittedBox(fit: BoxFit.scaleDown)`** on chip labels defeats system text scaling accessibility |
| `lib/features/practice/presentation/practice_screen.dart` | 231–260 | Hardcoded `Colors.blue`, `Colors.orange`, `Colors.purple`, `Colors.red` for mode cards |
| `lib/features/practice/presentation/practice_session_screen.dart` | 352, 372, 554–575 | Hardcoded `Colors.blue`, `Colors.green`, `Colors.grey.shade600` |
| `lib/features/lessons/presentation/lesson_detail_screen.dart` | 28–30, 48–50 | `Timer? _timer` declared but **never initialized** — dead code, incomplete feature |
| `lib/core/widgets/animated_bar_chart.dart` | 30 | Hardcoded `EdgeInsets.all(16)` instead of `ResponsiveUtils.cardPadding(context)` |
| 7 feature files: `settings_screen.dart`, `api_config_screen.dart`, `profile_screen.dart`, `subject_management_screen.dart`, `topic_list_screen.dart`, `lesson_list_screen.dart`, `lesson_detail_screen.dart` | various | **`import 'package:studyking/main.dart'`** creates tight coupling and circular-dependency risk |

---

## Rationale

### 1. Crashing Tabs (Critical Severity)
`TabBarView` at line 182 lists 4 children: `_buildLessonsTab()`, `_buildPracticeTab()`, `_buildHistoryTab()`, `_buildStatsTab()`. Grepping the entire codebase confirms `_buildPracticeTab` and `_buildHistoryTab` are **referenced only at lines 189 and 192** and **defined nowhere**. Any user tapping the Practice or History tab triggers a runtime error. This is a `NoSuchMethod` crash waiting to happen.

### 2. Nested Card Produces Visual Artifact
```dart
Card(                                  // outer Card
  child: Card(                         // inner Card — creates double shadow + border radius
    child: ListTile(...),
  ),
);
```
Two `Card` widgets stacked produce overlapping elevation shadows, doubled border radii, and redundant internal padding. The inner card's `margin` has no effect because it sits inside the outer card's child slot.

### 3. `as dynamic` Casts Defeat Type Safety
`(lesson as dynamic).title` at line 265 and `(lesson as dynamic).questionIds?.length` at line 263 mean the compiler cannot catch type errors. If the repository returns a model without these fields (e.g., a different `Lesson` variant), the app crashes with `NoSuchMethodError` at runtime. A properly typed `Lesson` model already exists at `lib/core/data/models/lesson_model.dart`.

### 4. FittedBox Breaks Font Size Accessibility
`FittedBox(fit: BoxFit.scaleDown)` in `question_card_widget.dart` forces text to shrink when constrained. This directly overrides the user's system font size setting — a WCAG 2.1 SC 1.4.4 (Resize Text) violation. Users who rely on larger text for readability will find chip labels illegibly small.

### 5. 168+ Hardcoded Colors Ignore Theme
`Colors.grey.shade600`, `Colors.blue`, `Colors.green`, etc. are used throughout practice screens, session screens, question cards, and subject detail screens. These do not respond to:
- Dark/light theme switching
- High-contrast mode (`contrastLevel: 1.0` in `AppTheme`)
- User-customized seed color

The `AppTheme` already provides `colorScheme.onSurfaceVariant`, `colorScheme.primaryContainer`, `colorScheme.tertiary`, etc. that should be used instead.

### 6. Tight Coupling to `main.dart`
Seven feature files import `package:studyking/main.dart` directly to access `database` and `settingsRepository`. This means:
- Unit-testing any of these widgets requires bootstrapping the entire app
- `main.dart` cannot be refactored without touching every feature
- Riverpod providers exist but are bypassed in favor of global singletons

---

## Acceptance Criteria

- [ ] **CRITICAL**: Implement `_buildPracticeTab()` and `_buildHistoryTab()` in `subject_detail_view.dart`, or replace the `TabBarView` with only the two working tabs, so the screen no longer crashes on tab switch.
- [ ] Fix the nested `Card` in `subject_detail_view.dart:266–270` — keep only one `Card` widget.
- [ ] Replace all `as dynamic` casts in `subject_detail_view.dart:262–319` with proper typed access from the existing `Lesson` model.
- [ ] Make `SliverAppBar.expandedHeight` in `subject_detail_view.dart:69` proportional to screen height via `MediaQuery`.
- [ ] Remove `FittedBox(fit: BoxFit.scaleDown)` from all 4 chip labels in `question_card_widget.dart` and use `Flexible` + `TextOverflow.ellipsis` instead.
- [ ] Replace hardcoded `Colors.green`/`Colors.orange`/`Colors.red` in `subject_detail_view.dart:272–285` with theme-derived colors (e.g., `colorScheme.primary`, `colorScheme.error`, `colorScheme.tertiary`).
- [ ] Replace hardcoded `Colors.blue`/`Colors.orange`/`Colors.purple`/`Colors.red` in `practice_screen.dart:231–260` with a palette derived from `colorScheme`.
- [ ] Replace `EdgeInsets.all(16)` in `animated_bar_chart.dart:30` with `ResponsiveUtils.cardPadding(context)`.
- [ ] Replace all `import 'package:studyking/main.dart' show ...` across 7 feature files with proper Riverpod provider access or a dedicated dependency injection module.
- [ ] Either implement the `_timer` in `lesson_detail_screen.dart` or remove the dead `Timer? _timer` field and its cancellation in `dispose()`.

---

## Impact

- **Users**: Tab crash blocks access to Practice and History on the Subject Detail screen. Hardcoded colors cause contrast issues in dark/high-contrast mode. Text scaling is broken on question chip labels.
- **Developers**: Each new screen copies the hardcoded-color anti-pattern. Tight `main.dart` coupling makes testing and refactoring expensive. `as dynamic` casts hide type errors until production.

## Priority

**Critical** — includes a runtime crash (missing methods), accessibility violations (text scaling, contrast), and maintainability debt across 20+ files.
