# Test Master: Comprehensive Test Coverage Audit

**Generated:** 2026-05-20
**Scope:** All `lib/features/*/` and `lib/core/*/` vs `test/` — cross-referenced against AGENTS.md conventions.

---

## BLOCKER — Missing Test Files (untested production code)

### B1: Mentor services — 3 source files have zero test coverage

| Source file | Missing test |
|---|---|
| `lib/features/mentor/services/mentor_schedule_handler.dart` | `test/features/mentor/services/mentor_schedule_handler_test.dart` |
| `lib/features/mentor/services/mentor_wellbeing_service.dart` | `test/features/mentor/services/mentor_wellbeing_service_test.dart` |
| `lib/features/mentor/services/mentor_context_builder.dart` | `test/features/mentor/services/mentor_context_builder_test.dart` |

**Rationale:** The `mentor/` feature has one of the most detailed dependency-injection docs in AGENTS.md (the `MentorService Dependencies` table), yet three core service files are completely uncovered. `MentorScheduleHandler` orchestrates lesson scheduling, `MentorWellbeingService` handles proactive engagement nudges, and `MentorContextBuilder` constructs the LLM prompt context. Any refactor to these will go undetected.

**Acceptance criteria:**
- [ ] `mentor_schedule_handler_test.dart` created with fake `PlannerService`, fakes for `SessionRepository`/`EngagementNudgeRepository`. Tests cover: `scheduleLesson` success, scheduling conflict detection, adherence check, and error propagation.
- [ ] `mentor_wellbeing_service_test.dart` created with fakes for `EngagementNudgeRepository`/`SessionRepository`. Tests cover: `checkWellbeingAndGenerateNudges` with low/high activity, nudge creation, today-count limits, and service-thrown errors.
- [ ] `mentor_context_builder_test.dart` created. Tests cover: context assembly from `MasteryGraphService`/`PlannerService`/`SessionRepository` outputs, empty state handling, and provider-thrown errors.

---

### B2: Planner — syllabus_progress_card missing test

| Source file | Missing test |
|---|---|
| `lib/features/planner/presentation/widgets/syllabus_progress_card.dart` | `test/features/planner/presentation/widgets/syllabus_progress_card_test.dart` |

**Rationale:** This widget renders a visual syllabus completion bar on the planner screen. No test exists to verify rendering with 0%, partial, or 100% progress, or with an empty syllabus.

**Acceptance criteria:**
- [ ] Test file created with `ProviderScope` + overrides for syllabus providers.
- [ ] Tests verify: empty progress, partial progress (e.g. 3/10 topics mastered), full progress, and loading/error states.

---

### B3: Subjects — subject_repository_provider missing test

| Source file | Missing test |
|---|---|
| `lib/features/subjects/providers/subject_repository_provider.dart` | `test/features/subjects/providers/subject_repository_provider_test.dart` |

**Rationale:** This provider wires the `SubjectRepository` into the Riverpod graph. No test verifies that it provides a singleton, that it can be overridden, or that an init failure propagates.

**Acceptance criteria:**
- [ ] Provider test file created. Tests: singleton behavior (same instance across reads), override injection via `ProviderScope`, error handling (if repo init throws).

---

## MAJOR — Insufficient Test Quality

### M1: Core utilities and constants with no test coverage

| Source file | Missing test |
|---|---|
| `lib/core/utils/answer_comparator.dart` | `test/core/utils/answer_comparator_test.dart` |
| `lib/core/utils/date_utils.dart` | `test/core/utils/date_utils_test.dart` |
| `lib/core/constants/mentor_keywords.dart` | `test/core/constants/mentor_keywords_test.dart` |
| `lib/core/constants/spaced_repetition_config.dart` | `test/core/constants/spaced_repetition_config_test.dart` |

**Rationale:** `answer_comparator` is used during practice evaluation — incorrect comparison logic would silently mark answers right/wrong. `date_utils` is used across scheduling and planning. Both constants files drive LLM keyword detection and SR algorithm tuning. Zero coverage means regressions go undetected.

**Acceptance criteria:**
- [ ] `answer_comparator_test.dart`: tests for exact match, whitespace-tolerant match, empty/null input, numeric comparison edge cases.
- [ ] `date_utils_test.dart`: tests for all exported functions — date range generation, week start/end, formatting edge cases (leap year, DST).
- [ ] `mentor_keywords_test.dart`: tests that keyword lists contain expected entries, are non-empty.
- [ ] `spaced_repetition_config_test.dart`: tests default config values, config boundaries.

---

### M2: Mixed unit + widget tests in one file

**Affected file:** `test/features/dashboard/presentation/screens/topic_detail_screen_test.dart`

**Finding:** Contains 23 `testWidgets` blocks and 1 `test(...)` block (`"constructs with topicId and studentId"` at line 637). This violates the AGENTS.md rule: *"Keep unit tests and widget tests in separate files — never mix them in the same file."*

**Acceptance criteria:**
- [ ] The unit test (`constructs with topicId and studentId`) is extracted into a separate file `test/features/dashboard/presentation/screens/topic_detail_screen_unit_test.dart` (or appended to an existing unit file).
- [ ] The original file contains only `testWidgets` calls.

---

### M3: Core model tests located in feature test directory

**Affected files:**

| Source (lib/core/data/models/) | Test location (should be test/core/data/models/) | Actual test location |
|---|---|---|
| `mastery_state_model.dart` | `test/core/data/models/mastery_state_model_test.dart` | `test/features/practice/data/models/mastery_state_model_test.dart` |
| `mastery_improvement_metric_model.dart` | `test/core/data/models/...` | `test/features/practice/data/models/...` |
| `question_mastery_state_model.dart` | `test/core/data/models/...` | `test/features/practice/data/models/...` |
| `attempt_repository.dart` | `test/core/data/repositories/...` | `test/features/practice/data/repositories/attempt_repository_test.dart` |

**Rationale:** Models defined in `lib/core/data/models/` are shared across features. Having their tests buried in `test/features/practice/` means they are not discoverable via the convention mapping. Also means CI scoped to `test/core/` would miss these tests.

**Acceptance criteria:**
- [ ] Test files are symlinked OR moved to `test/core/data/models/` and `test/core/data/repositories/` respectively.
- [ ] Import paths are updated.

---

### M4: Widget tests missing NavigatorObserver for navigation verification

**Finding:** The following widget tests exercise screens/widgets that trigger navigation but do not use `NavigatorObserver` to verify the route:

| Test file | Widget under test | Navigates? |
|---|---|---|
| `test/features/planner/presentation/widgets/plan_summary_card_test.dart` | PlanSummaryCard | Yes (lesson detail) |
| `test/features/planner/presentation/widgets/calendar_view_widget_test.dart` | CalendarViewWidget | Yes (day tap) |
| `test/features/dashboard/presentation/widgets/plan_adherence_card_test.dart` | PlanAdherenceCard | Yes (details) |
| `test/features/dashboard/presentation/widgets/due_reviews_card_test.dart` | DueReviewsCard | Yes (review) |
| `test/features/dashboard/presentation/widgets/mastery_progress_card_test.dart` | MasteryProgressCard | Yes (detail) |
| `test/features/dashboard/presentation/widgets/workload_card_test.dart` | WorkloadCard | Yes (detail) |
| `test/features/dashboard/presentation/widgets/weak_areas_card_test.dart` | WeakAreasCard | Yes (detail) |
| `test/features/dashboard/presentation/widgets/topic_breakdown_card_test.dart` | TopicBreakdownCard | Yes (detail) |
| `test/features/dashboard/presentation/widgets/badges_card_test.dart` | BadgesCard | Yes (badge list) |
| `test/features/sessions/presentation/session_tracker_screen_test.dart` | SessionTrackerScreen | Yes (history) |

**Rationale:** Without `NavigatorObserver`, these tests cannot verify that the correct route is pushed. A future regression that breaks navigation links would not be caught. AGENTS.md says *"Use `NavigatorObserver` for verifying navigation behavior."*

**Acceptance criteria:**
- [ ] Each file above injects a `TestNavigatorObserver` via `navigatorObservers`.
- [ ] At least one test per file verifies the pushed route name/arguments after the navigation-triggering interaction.

---

## MINOR — Code Quality / Test Hygiene

### m1: Widespread Hive I/O dependency in tests (~40+ test files)

**Finding:** Many repository, adapter, and service tests perform real Hive operations (`Hive.init`, `Hive.openBox`, `Hive.registerAdapter`, `Hive.deleteBoxFromDisk`) instead of using fake repositories/in-memory boxes.

**Affected area examples:** All `test/features/planner/data/repositories/*`, `test/features/practice/data/repositories/*`, `test/features/ingestion/data/repositories/*`, `test/features/lessons/data/repositories/*`, `test/features/questions/data/repositories/*`, `test/features/sessions/data/repositories/*`, plus several adapter tests.

**Rationale:** Real Hive I/O makes tests slower, leaves temp directories on disk, and fragments cross-test state if cleanup is partial. The AGENTS.md docs recommend `fixedStudentId` as an alternative and favours hand-written fakes. True, many repository tests unavoidably test Hive storage (get/put/delete against a real box), and using `Hive.init` with a temp dir is the standard pattern for Hive unit tests. However, the setup/teardown ceremony is error-prone — missing `deleteBoxFromDisk` can cause test pollution.

**Acceptance criteria:**
- [ ] All repository tests use `setUp`/`tearDown` that initializes and cleans up a temp Hive directory.
- [ ] No test file misses `Hive.deleteBoxFromDisk` after tests complete.
- [ ] Consider extracting a shared `HiveTestHelper` utility (e.g. `initHive`, `cleanHive`, `registerAllAdapters`) to reduce boilerplate.

---

### m2: Construction-only assertions in model tests

**Finding:** Some model tests rely on `isA<Type>()` or `isNotNull` without behavioral round-trip verification (e.g., `pending_action_model_test.dart` line 24 has `isA<DateTime>()`).

**Affected files with weak assertions:**
- `test/features/planner/data/models/pending_action_model_test.dart` — one `isA<DateTime>()` assertion

**Rationale:** While not critical, the AGENTS.md convention expects behavioral assertions. Model tests should include `toJson`/`fromJson` round trips, copyWith, equality, etc.

**Acceptance criteria:**
- [ ] Each model test includes at least one round-trip test: `final decoded = T.fromJson(encoded.toJson()); expect(decoded, equals(original))`.

---

### m3: Duplicate / orphaned test file

**Finding:** `test/features/dashboard/presentation/widgets/export_section_widget_test.dart` tests the same source (`export_section.dart`) as `export_section_test.dart`. The two files are kept separate (unit vs widget, which is correct per convention), but the naming is inconsistent with the rest of the project (all other split files use `_test` and `_widget_test` suffixes respectively).

**Acceptance criteria:**
- [ ] Both files remain (splitting is correct), but `export_section_widget_test.dart` should be verified to not duplicate test logic from `export_section_test.dart`. Update naming for consistency if needed, or merge widget-specific assertions into a single widget-only file.

---

## Summary Table

| Severity | Count | Key items |
|---|---|---|
| **BLOCKER** | 3 | Missing tests: mentor (3 services), syllabus_progress_card, subject_repository_provider |
| **MAJOR** | 4 | Core untested (4 files), mixed test type, model location mismatch, missing NavigatorObserver (~10 files) |
| **MINOR** | 3 | Hive I/O boilerplate (~40 files), weak assertions (1 file), duplicate test naming (1 file) |

---

*This issue was generated by Test Master automation. Each finding has concrete acceptance criteria so the issue is actionable upon assignment.*
