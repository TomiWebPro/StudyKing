# Repository Test Fragmentation in core/data/repositories

## Context

`test/core/data/repositories/` contains **23 test files** for 19 production repositories. Several repositories have their tests fragmented across multiple files with overlapping concerns, making maintenance harder and review slower.

The worst offenders:

| Repository | Test Files | Total Tests | Total Lines |
|---|---|---|---|
| `subject_repository.dart` | 5 files | 163 | 1,969 |
| `settings_repository.dart` | 2 files | 121 | ~2,200 |
| All others | 1 file each | varies | varies |

Additionally, `repository_test.dart` is a 44-line file with trivial tests (filtering `[1,2,3,2,5,4,1]` by difficulty, checking `subjectNames.length == 4`) that do not test any repository — they test in-memory list operations.

## Affected Files

### Subject Repository — 5-way fragmentation

| File | Tests | Focus |
|---|---|---|
| `test/core/data/repositories/subject_repository_test.dart` | 54 | Core CRUD, `MockSubjectBox` based |
| `test/core/data/repositories/subject_repository_comprehensive_test.dart` | 36 | Additional edge cases |
| `test/core/data/repositories/subject_repository_extra_edge_cases_test.dart` | 33 | Yet more edge cases |
| `test/core/data/repositories/subject_repository_error_test.dart` | 31 | Error paths |
| `test/core/data/repositories/subject_repository_init_test.dart` | 9 | Hive `init()` |

These 5 files share the same test infrastructure, the same `Hive.init(testPath)` setup, and overlapping test scenarios (e.g., CRUD tests appear in 3 different files). There is no clear boundary between what goes in `_test.dart` vs `_comprehensive_test.dart` vs `_extra_edge_cases_test.dart`.

### Settings Repository — Near-total duplication

| File | Tests | Approach |
|---|---|---|
| `test/features/settings/data/repositories/settings_repository_test.dart` | 59 | In-memory `FakeSettingsBox` |
| `test/features/settings/data/repositories/settings_repository_hive_test.dart` | 62 | Real Hive box + adapter |

These two files share near-identical test structures and assertions. The only difference is the backing box implementation. Every change to the repository interface must be applied twice — to both files.

### Trivial / Spurious — `repository_test.dart`

```dart
group('Subject Repository Operations', () {
  test('Subject filtering logic', () {
    final subjectNames = ['Math', 'Science', 'English', 'History'];
    expect(subjectNames.length, equals(4));
    expect(subjectNames.contains('Math'), isTrue);
  });
});
```

This tests `List.length` and `List.contains` — not the repository. Adds noise to the test suite.

## Rationale

| Problem | Impact |
|---|---|
| **5 files for one repo** | A developer searching for subject repo tests must open 5 files to see full coverage. CI output lists 5 separate files for one unit under test. |
| **No organization convention** | The boundary between `_comprehensive_test`, `_extra_edge_cases_test`, and `_test` is undefined. Future contributors cannot determine where to add new tests. |
| **Settings duplication** | The `_hive_test.dart` variant adds ~900 lines of near-identical assertions. A single parametrized test file (or a shared `group()` extracted to a helper) would eliminate the duplication while keeping both test configurations. |
| **Trivial test file** | `repository_test.dart` has zero value. It tests standard library operations and should be removed. |
| **Impacts relocation** | The open `code_refactor_master.md` plans to move these tests to `test/features/*/data/repositories/`. If moved as-is, the fragmentation is carried into the new structure, making the problem permanent. |

## Acceptance Criteria

1. `test/core/data/repositories/subject_repository_comprehensive_test.dart`, `_extra_edge_cases_test.dart`, and `_error_test.dart` are merged into `subject_repository_test.dart` using `group()` blocks to organize by concern (e.g., `group('CRUD')`, `group('Error handling')`, `group('Edge cases')`).

2. `test/core/data/repositories/subject_repository_init_test.dart` is merged into `subject_repository_test.dart` as a `group('init')` block (this file uses real Hive; it can remain separate if Hive init proves too slow to run alongside 150+ mock-based tests, but this decision must be documented).

3. After consolidation, there is exactly **1 test file** for `subject_repository.dart` in the test directory.

4. `test/features/settings/data/repositories/settings_repository_test.dart` and `_hive_test.dart` are refactored to eliminate duplication using one of:
   - A shared `group()` function in a helper file that both test files import.
   - A single parametrized test file.

5. `test/core/data/repositories/repository_test.dart` is deleted (its contents are not tests).

6. All tests still pass after consolidation.

7. (Future-proofing) Any other repository test file in `test/core/data/repositories/` that demonstrates fragmentation should follow the same consolidation pattern if/when the `code_refactor_master` relocation occurs.
