# Code Refactor Master & Quality — New Findings (Post-Completed Report Audit)

**Generated:** 2026-05-19
**Scope:** Full re-exploration of `lib/` (349 non-generated Dart files) to identify issues not covered by the previous completed report at `issues/completed/code_refactor_master.md`.

> **Note:** The previous completed report (2026-05-18) covered 3 BLOCKER, 13 MAJOR, and 10 MINOR items. Since then, 1 dead file (`inline_practice_panel.dart`) was deleted, and 2 previously-failing files (`question_variant_generator.dart`, `graph_drawing_canvas_widget.dart`) now compile cleanly. This report documents findings that are **new** (not present in the prior report) or have **regressed**.

---

## BLOCKER — App Cannot Analyze Cleanly

### B1. `settings_screen.dart` — 4 Compile Errors Blocking `dart analyze`

`lib/features/settings/presentation/settings_screen.dart` is the **only file** in `lib/` producing analyzer errors. All 7 issues are concentrated here:

| # | Line | Type | Message | Root Cause |
|---|---|---|---|---|
| 1 | 122 | **error** | `The getter 'share' isn't defined for the type 'AppLocalizations'` | ARB key `"share"` does not exist in any `.arb` file |
| 2 | 1046 | **error** | `The method 'StudentIdService' isn't defined` | Missing `import 'package:studyking/core/services/student_id_service.dart'` |
| 3 | 1512 | **error** | `The name 'PackageInfo' isn't a type` | `package_info_plus` not resolved in `.dart_tool/package_config.json` (run `dart pub get`) |
| 4 | 52 | **error** | `Target of URI doesn't exist: 'package:package_info_plus/package_info_plus.dart'` | Same root cause as #3 |
| 5 | 79 | **warning** | `'_checkAutoBackup' isn't referenced` | Dead code — defined but never called |
| 6 | 892 | **warning** | `The value of 'boxCount' isn't used` | Variable assigned but never read |
| 7 | 66 | **info** | `Unnecessary override` | Empty `initState()` override |

**Acceptance Criteria:**
- `dart analyze lib/` reports **0 errors, 0 warnings**.
- `"share"` key added to `app_en.arb` and `app_es.arb`.
- `student_id_service.dart` import added at line 1046.
- `dart pub get` resolves `package_info_plus`.
- `_checkAutoBackup` wired to a call site or removed.
- `boxCount` variable used or removed.
- Empty `initState()` override removed.

---

## MAJOR — Deprecated Code Still Actively Used in Production

### M1. `Markscheme` + `MarkSchemeStep` — `@Deprecated` Annotation Misleading (25+ Files)

`lib/core/data/models/markscheme_model.dart`:
- Line 3: `@Deprecated('Use QuestionEvaluation instead (typeId 14)')`
- Line 87: `@Deprecated('Use EvaluationStep instead (typeId 15)')`

Despite these annotations, **25+ files** in `lib/` still import and use these types:
- `question_model.dart` — the `Question` model holds a `Markscheme?` field
- `question_repository.dart`, `source_repository.dart`, `content_pipeline.dart`
- `answer_validation_service.dart`
- `question_bank_screen.dart`, `question_variant_generator.dart`
- `markscheme_adapter.dart` (typeId 12, still registered in Hive)

The replacement types (`QuestionEvaluation` typeId 14, `EvaluationStep` typeId 15) exist but the migration was **never completed**. Anyone reading `@Deprecated` assumes safe removal, which would crash the app.

**Fix:** Either (a) complete the migration — replace all `Markscheme`/`MarkSchemeStep` usages with `QuestionEvaluation`/`EvaluationStep`, remove deprecated files, or (b) remove the `@Deprecated` annotations since migration is not happening.

### M2. `VoiceController` — `@Deprecated` But Still Exported From Teaching Barrel

`lib/features/teaching/services/voice_controller.dart:4`:
```dart
@Deprecated('Use VoiceService directly. Will be removed in a future version.')
```

Still exported from the `teaching.dart` barrel. Only test files reference it. Keeps a dead class in the public API surface.

**Fix:** Remove export from teaching barrel, delete the file.

### M3. `SubjectDetailArgs` DTO Duplicates `Subject` Model (Maintenance Burden)

`lib/core/routes/app_router.dart:57-79` defines `SubjectDetailArgs` with **9 fields** duplicating the `Subject` model:

| `Subject` field | `SubjectDetailArgs` field | Problem |
|---|---|---|
| `id` | `subjectId` | Renamed |
| `name` | `subjectName` | Renamed |
| `description` | `subjectDescription` | Renamed + nullable |
| `syllabus` | `subjectSyllabus` | Renamed |
| `code` | `subjectCode` | Renamed |
| `teacher` | `subjectTeacher` | Renamed |
| `color` | `subjectColor` | Renamed |
| `examDate` | `subjectExamDate` | Renamed + nullable |
| `topicIds` | `topicIds` | Same |
| `createdAt`, `iconName` | ✗ **Missing** | Added to Subject but not to Args |

Every `Subject` model change requires manually updating `SubjectDetailArgs` + `SubjectDetailScreen` + `SubjectListScreen`. This already bit the codebase — `iconName` exists on `Subject` but is silently dropped when navigating. The DTO adds no value since `Subject` is serializable and can be passed directly.

**Fix:** Replace `SubjectDetailArgs` with direct `Subject` passing, or generate args from the model.

---

## MAJOR — Inconsistent Patterns

### M4. `PlannerService` — 9 Manual try/catch Blocks Instead of `Result.capture()`

`lib/features/planner/services/planner_service.dart` has 9 try/catch blocks following this pattern:
```dart
try { ... return value; }
catch (e) { Logger(...).e('...', e); return false/[]; }
```

Affected methods: `scheduleLesson`, `cancelLesson`, `rescheduleLesson`, `getScheduledLessons`, `getMissedLessons`, `dismissAllMissed`, `acceptPendingAction`, `dismissPendingAction`.

Problems:
- Returns plain types (`bool`, `List`, `void`) instead of `Result<T>`
- `.e()` log level for recoverable errors (should be `.w()`)
- No error propagation to callers

**Fix:** Migrate to `Result.capture()` and return `Result<T>`.

### M5. `PlannerNotifier` — 18 `.e()` Log Calls That Should Be `.w()`

`lib/features/planner/providers/planner_providers.dart` uses `.e()` for **all 18** error handlers (lines 246, 262, 276, 286, 313, 404, 428, 440, 470, 487, 498, 526, 577, 593, 618, 633, 645, 667). All catch recoverable exceptions and set error state.

**Fix:** Change `.e()` → `.w()` on all 18 lines.

### M6. `core/data/data.dart` Barrel — Inconsistent Exports

`lib/core/data/data.dart` exports 9 files from `core/data/` but omits several that live in the same directories:
- **Exports:** `enums`, `hive_initializer`, `database_service`, `topic_model`, `question_model`, `session_model`, `subject_model`, `repository`, `hive_box_names`
- **Omits:** `markscheme_model`, `source_model`, `source_adapter`, `session_adapter`, `database_migration`, `student_availability_adapter`, `engagement_nudge_adapter`, `hive_type_ids`

`source_model.dart` sits in the same `models/` folder as the exported models but callers must import it by direct path. This is inconsistent.

**Fix:** Either export all public files or remove the barrel (most callers bypass it anyway).

### M7. `core/data/` Feature-Specific Hive Adapters — Wrong Placement (Extended)

The previous report (M11) flagged 2 adapters in the wrong place but missed 2 more:

| File | Line Count | Belongs In |
|---|---|---|
| `lib/core/data/source_adapter.dart` | 79 | `features/ingestion/data/adapters/` |
| `lib/core/data/session_adapter.dart` | 117 | `features/sessions/data/adapters/` |
| `lib/core/data/student_availability_adapter.dart` | (previously flagged) | `features/planner/data/adapters/` |
| `lib/core/data/engagement_nudge_adapter.dart` | (previously flagged) | `features/planner/data/adapters/` |

**Fix:** Move all 4 adapters. Update imports in `hive_initializer.dart`.

---

## MINOR — Code Quality / UX Friction

### m1. `"share"` ARB Key Missing

`settings_screen.dart:122` uses `l10n.share` but no ARB file has a `"share"` key. Must be added to both `app_en.arb` and `app_es.arb`.

### m2. Missing `student_id_service.dart` Import at `settings_screen.dart:1046`

Line 1046 calls `StudentIdService().getStudentId()` without importing the service. Add:
```dart
import 'package:studyking/core/services/student_id_service.dart';
```

### m3. `settings_screen.dart` — Heavy Cross-Feature Imports (25+ Feature Imports)

`settings_screen.dart` imports from **7 different features**: lessons, planner, dashboard, focus_mode, practice, questions, settings, ingestion, subjects, teaching. This makes it one of the most coupled files in the codebase — its import list (lines 1-53) is longer than many entire feature files.

**Fix:** Extract settings sub-sections into separate widget files (one per feature domain) and compose them in SettingsScreen. This would also reduce the 207-line `_buildSettingsBody()` method.

### m4. `DashboardScreen.build()` — 368-Line God Method

`lib/features/dashboard/presentation/dashboard_screen.dart:45-413` has a 368-line `build()` method that:
- Watches 10+ async providers
- Renders loading skeletons, empty state, error state
- Builds 15+ collapsible cards inline
- Mixes data watching, business logic (`hasAnyData` calculation), large UI tree

**Fix:** Extract each card section into a separate widget file (many already exist as `*_card.dart` files but the orchestration logic stays in `build()`). Decompose into focused sub-builders (< 40 lines each).

### m5. Two Dead Files Remain as Dead Code

`lib/features/questions/services/question_variant_generator.dart` and `lib/features/questions/presentation/widgets/graph_drawing_canvas_widget.dart` compile cleanly but are **not imported by any production file** (not in any barrel export, not referenced by any import). They are dead code.

**Fix:** Verify they are truly dead (no imports), then either remove or add to barrel + wire up.

### m6. `conversation_manager.dart` Uses 5 Feature Models — High Coupling

`lib/features/teaching/services/conversation_manager.dart` has high coupling: 10+ imports from 4 different packages/features. The `_handleInput()` method mixes streaming LLM calls, phase transitions, error handling, and UI state updates.

**Fix:** Extract LLM streaming into a dedicated service. Separate phase transition logic from message handling.

---

## Summary Table

| Priority | Count | Key Items |
|---|---|---|
| **BLOCKER** | 1 (4 errors) | `settings_screen.dart` compile errors (ARB missing key, missing import, missing package) |
| **MAJOR** | 7 | Deprecated-but-used Markscheme (25+ files), deprecated VoiceController, SubjectDetailArgs duplication, 9 manual try/catch in PlannerService, 18 .e()→.w() in PlannerNotifier, inconsistent barrel exports, misplaced Hive adapters |
| **MINOR** | 6 | Missing ARB key, missing import, SettingsScreen coupling (25 imports), DashboardScreen god build() (368 lines), 2 dead files, ConversationManager coupling |

## How to Verify Complete Fix

```bash
dart analyze lib/                                          # 0 errors, 0 warnings
# Verify deprecated markscheme_model.dart coverage:
grep -rn "Markscheme\|MarkSchemeStep" lib/ --include="*.dart" | grep -v test/ | wc -l  # target: 0
# Verify VoiceController coverage:
grep -rn "VoiceController" lib/ --include="*.dart" | wc -l  # target: 0
# Verify SubjectDetailArgs removal:
grep -rn "SubjectDetailArgs" lib/ --include="*.dart" | wc -l  # target: 0
# Verify planner .e()→.w() migration:
grep -n "\.e(" lib/features/planner/services/planner_service.dart | wc -l  # target: 0
grep -n "\.e(" lib/features/planner/providers/planner_providers.dart | wc -l  # target: 0
```
