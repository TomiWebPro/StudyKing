# Refactor: Subjects Feature Architecture Violations, Dead Code, and Incomplete Implementation

## Context

The subjects feature (`lib/features/subjects/`) contains several maintainability issues that range from architecture violations (core depending on features) to dead code (`SubjectColors` thin wrapper), misleading API design (`getStudentSubjects` ignores its parameter), and incomplete UI implementations (no-op handlers, hardcoded strings, missing `mounted` guards, `SubjectDetailArgs`→constructor field duplication).

---

## Issues Found

### 1. Core→Feature Dependency Violation (Layered Architecture Breach)

**Affected files:**
- `lib/core/data/database_service.dart` (line 3): `import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';`
- `lib/features/subjects/data/repositories/subject_repository.dart`

**Evidence:** `DatabaseService` in `core/data/` imports and depends on `SubjectRepository` from `features/subjects/`. This creates a bidirectional dependency pattern where the "core" layer has knowledge of a specific feature. All other repositories (TopicRepository, QuestionRepository, LessonRepository, etc.) live in `core/data/repositories/`, but `SubjectRepository` was placed inside the feature. The `DatabaseService` then has to reach into the feature to reference it.

**Rationale:** In a layered architecture, `core/` should be feature-agnostic. Placing `SubjectRepository` in `core/data/repositories/` alongside the other repositories (or extracting the repository interface into core and keeping the implementation in the feature) would eliminate this violation. This creates a fragile import chain and makes the subjects feature a "special case" that requires core to know about it.

**Acceptance Criteria:**
- [ ] Move `SubjectRepository` out of features and into `core/data/repositories/`, OR extract an abstract `SubjectRepository` interface into core with the Hive implementation remaining in the feature
- [ ] Update all imports across the codebase to point to the new location
- [ ] Verify that no `core/` file imports from `features/` after the change
- [ ] Update barrel files (`core/data/data.dart`, `features/subjects/subject_feature.dart`)

---

### 2. `SubjectColors` Is a Dead Thin Wrapper Around `ColorUtils`

**Affected file:** `lib/features/subjects/presentation/subject_form_widgets.dart` (lines 5–14)

**Evidence:** `SubjectColors` is a static pass-through class:

```dart
class SubjectColors {
  static const List<String> all = ColorUtils.availableColors;
  static String get defaultColor => ColorUtils.defaultColorHex;
  static Color stringToColor(String hexColor) => ColorUtils.stringToColor(hexColor);
  static String getColorLabel(String hexColor, {AppLocalizations? l10n}) =>
      ColorUtils.getColorLabel(hexColor, l10n: l10n);
}
```

Every single member delegates directly to `ColorUtils` in `core/utils/color_utils.dart`. The class adds no behavior, no state, no abstraction — it is purely a forwarding layer. Six call sites in the subjects feature use `SubjectColors.*`, and 12 call sites (in tests) test `SubjectColors` instead of `ColorUtils` directly. If `ColorUtils` changes, `SubjectColors` must be updated in lockstep or it silently diverges.

**Tests strongly coupled to this dead layer:** `test/features/subjects/presentation/subject_form_widgets_test.dart` devotes an entire `group('SubjectColors', ...)` to testing `SubjectColors`, which is just testing `ColorUtils` through a one-line redirect. This test will need to be rewritten if the class is removed, indicating the tests are testing the wrong layer.

**Rationale:** An indirection layer that adds zero value doubles the maintenance surface. All callers should use `ColorUtils` directly. Removing `SubjectColors` reduces code and eliminates confusion about which API to use.

**Acceptance Criteria:**
- [ ] Remove `SubjectColors` class from `subject_form_widgets.dart`
- [ ] Replace all `SubjectColors.*` call sites with `ColorUtils.*`:
  - `lib/features/subjects/presentation/subject_selection_screen.dart`: `SubjectColors.defaultColor` → `ColorUtils.defaultColorHex`
  - `lib/features/subjects/presentation/subject_list_view.dart`: `SubjectColors.stringToColor(...)` → `ColorUtils.stringToColor(...)`
  - `lib/features/subjects/presentation/subject_form_widgets.dart`: `SubjectColors.all` / `SubjectColors.stringToColor` / `SubjectColors.getColorLabel`
- [ ] Migrate the `SubjectColors` test group in `test/features/subjects/presentation/subject_form_widgets_test.dart` to test `ColorUtils` directly, or remove the redundant test cases

---

### 3. `SubjectRepository.getStudentSubjects(String studentId)` Ignores Its Parameter

**Affected file:** `lib/features/subjects/data/repositories/subject_repository.dart` (lines 71–73)

```dart
Future<List<Subject>> getStudentSubjects(String studentId) async {
  return getAll();
}
```

**Evidence:** The `studentId` parameter is accepted but never used — the method unconditionally returns all subjects in the database. This is confirmed by the existing test at `test/features/subjects/data/repositories/subject_repository_test.dart:686`: `test('getStudentSubjects ignores studentId parameter and returns all', ...)`.

**Rationale:** A method signature that accepts a parameter and silently ignores it is a maintenance trap. A future developer will call `getStudentSubjects('some-id')` expecting filtered results and get unfiltered data with no warning. Either implement proper student-scoped filtering, remove the parameter, or rename the method to `getAll()` and remove this method entirely.

**Acceptance Criteria:**
- [ ] Option A: Remove `getStudentSubjects` entirely, replacing call sites with `getAll()`
- [ ] Option B: Implement actual student-based filtering (requires student-subject association data)
- [ ] Option C: Rename to `getAllSubjects()` and drop the `studentId` parameter
- [ ] Update all tests that reference `getStudentSubjects` accordingly

---

### 4. `SubjectDetailArgs` → `SubjectDetailScreen` Parameter Duplication

**Affected files:**
- `lib/core/routes/app_router.dart` (lines 44–66): `SubjectDetailArgs` with 9 fields
- `lib/features/subjects/presentation/subject_detail_view.dart` (lines 15–37): `SubjectDetailScreen` constructor with the same 9 fields
- `lib/core/routes/app_router.dart` (lines 164–181): Manual destructuring of `SubjectDetailArgs` into individual constructor parameters

**Evidence:** The field list of `SubjectDetailArgs` is a line-for-line copy of `SubjectDetailScreen`'s constructor parameters. The router then manually destructures the args and passes each field individually. Adding a new field (e.g., `subjectCredits`) requires changes in 4 places: `SubjectDetailArgs`, `SubjectDetailScreen` constructor, the route handler destructuring, and the call site that constructs `SubjectDetailArgs`.

The same duplication pattern applies to `PracticeSessionArgs`/`PracticeSessionScreen` (lines 68–80), `LessonDetailArgs`/`LessonDetailScreen` (lines 82–94), and `LessonListArgs`/`LessonListScreen` (lines 96–106).

**Rationale:** This is a well-known DRY violation in Flutter navigation. The standard solution is to pass the args object directly and have the screen accept it, or use a code-gen approach. Currently the boilerplate is error-prone and discourages adding new fields.

**Acceptance Criteria:**
- [ ] Refactor `SubjectDetailScreen` to accept `SubjectDetailArgs` directly rather than destructured fields (or use a static `fromArgs` factory)
- [ ] Remove manual destructuring in `app_router.dart:164–181` — pass the args object directly
- [ ] Apply the same pattern to `PracticeSessionScreen` / `PracticeSessionArgs`, `LessonDetailScreen` / `LessonDetailArgs`, and `LessonListScreen` / `LessonListArgs`
- [ ] Verify no navigation breakage (all routes still pass the correct data)

---

### 5. No-Op Handlers and Hardcoded Strings in `SubjectDetailScreen`

**Affected file:** `lib/features/subjects/presentation/subject_detail_view.dart`

| Lines | Issue |
|-------|-------|
| 141 | Edit `IconButton` has `onPressed: () {}` — a no-op that renders a button with no function |
| 225–226 | Bottom sheet "Edit Subject" pops the sheet but does nothing |
| 234–235 | Bottom sheet "Settings" pops the sheet but does nothing |
| 240 | `Semantics(label: 'Upload Content')` — hardcoded, not localised |
| 243 | `title: const Text('Upload Content')` — hardcoded, not localised |
| 257 | `Semantics(label: 'Dashboard')` — hardcoded, not localised |
| 258 | `title: const Text('Dashboard')` — hardcoded, not localised |

**Rationale:** Two hardcoded English strings (`'Upload Content'`, `'Dashboard'`) bypass the `l10n` system that every other string in the same file uses. The Edit button at line 141 and the two bottom-sheet items that just pop without action present interactive elements that do nothing — this is a usability defect and unfinished implementation.

**Acceptance Criteria:**
- [ ] Replace hardcoded 'Upload Content' with `l10n.uploadContent` (create the l10n key if missing)
- [ ] Replace hardcoded 'Dashboard' with `l10n.dashboard` (create the l10n key if missing)
- [ ] Wire up the Edit button (line 141) to navigate to an edit screen, or remove it
- [ ] Wire up bottom-sheet "Edit Subject" and "Settings" to their respective screens, or remove them
- [ ] Verify no remaining hardcoded English strings in `subject_detail_view.dart`

---

### 6. Missing `mounted` Guards on Async Navigation Calls

**Affected file:** `lib/features/subjects/presentation/subject_detail_view.dart`

**Evidence:** The file has inconsistent async safety:

| Method | Uses `mounted` check? |
|--------|----------------------|
| `_startPractice()` (line 200) | ❌ — calls `Navigator.pushNamed` without `mounted` check |
| `_confirmDelete()` line 301 | ❌ — calls `Navigator.pop(context)` without `mounted` check |
| `_saveSubject()` in `subject_selection_screen.dart:73,77,83` | ✅ — wraps in `if (mounted)` |

The delete confirmation callback (line 301) and the practice session navigation are called from `FutureBuilder` / dialog callbacks where the widget could be disposed. `Navigator` methods on a disposed element will throw a `FlutterError`.

**Rationale:** Inconsistent patterns create latent crash paths. The guard exists in `_saveSubject()` but is absent from identical patterns in the same file group. Missing `mounted` checks are a common source of `Looking up a deactivated widget's ancestor is unsafe` crashes.

**Acceptance Criteria:**
- [ ] Add `if (!mounted) return;` before `Navigator.pushNamed(...)` in `_startPractice()`
- [ ] Add `if (!mounted) return;` before `Navigator.pop(context)` at line 301 (inside `_confirmDelete`'s `ElevatedButton.onPressed`)
- [ ] Audit the rest of the file for any other navigation calls missing `mounted` checks

---

### 7. Class and File Naming Convention Inconsistency

**Affected files:**
- `lib/features/subjects/presentation/subject_list_view.dart` — class `SubjectListView` (no "Screen" suffix)
- `lib/features/subjects/presentation/subject_detail_view.dart` — class `SubjectDetailScreen` (has "Screen" suffix)
- `lib/features/subjects/presentation/subject_selection_screen.dart` — class `SubjectSelectionScreen` (has "Screen" suffix)

**Evidence:** Three files in the same directory use two different naming conventions:
- `SubjectListView` — file name says `View`, class name says `View`
- `SubjectDetailScreen` — file name says `View`, class name says `Screen`
- `SubjectSelectionScreen` — file name says `Screen`, class name says `Screen`

The barrel file `subject_feature.dart` (line 4) exports `subject_list_view.dart` while the dashboard barrel file exports screens by class name. This inconsistency makes it harder for new contributors to guess correct names.

**Rationale:** A consistent naming convention (choose "Screen" or "View" project-wide) reduces cognitive load and aligns with Flutter conventions where full-page widgets are typically called `*Screen` and reusable sub-regions are called `*View` or `*Widget`.

**Acceptance Criteria:**
- [ ] Rename `SubjectListView` to `SubjectListScreen` (and update filename to `subject_list_screen.dart` to match)
- [ ] OR rename `SubjectDetailScreen` to `SubjectDetailView` (and update its filename)
- [ ] Update all imports and barrel exports
- [ ] Ensure the chosen convention is documented or consistent with the rest of the project (check: `DashboardScreen`, `SettingsScreen`, `MentorScreen` — project convention appears to be `*Screen`)
