# [Scanner] Unit and widget tests mixed in same file (convention violation)

**Source:** automatic scanner
**Severity:** minor

## Finding

Per AGENTS.md: *"Keep unit tests and widget tests in separate files — never mix them in the same file."*

Two test files violate this convention by containing both `test()` (unit) and `testWidgets()` (widget) calls in the same file.

## Location 1: `test/features/practice/presentation/widgets/source_practice_sheet_status_test.dart`

**Widget tests** (lines 17–77):
- `testWidgets('shows pending status label', ...)`
- `testWidgets('shows extracting status label', ...)`
- `testWidgets('shows generating questions status label', ...)`
- `testWidgets('shows summarizing status label', ...)`
- `testWidgets('shows validating status label', ...)`

**Unit tests** (lines 79–101):
- `test('creates instance with default status', ...)`
- `test('creates instance with specified status', ...)`
- `test('creates instance with all parameters', ...)`

These 3 unit tests test `SourceItemData` model construction and should live in `test/features/practice/data/models/source_practice_item_test.dart` or similar.

## Location 2: `test/features/practice/presentation/widgets/confidence_selector_test.dart`

**Unit tests** (lines 17–42):
- `test('returns error for rating 1', ...)`
- `test('returns tertiary for rating 2', ...)`
- `test('returns tertiary for rating 3', ...)`
- `test('returns primary for rating 4', ...)`
- `test('returns primary for rating 5', ...)`
- `test('returns onSurfaceVariant for default', ...)`

**Widget tests** (lines 55–161):
- Multiple `testWidgets` for `ConfidenceSelector` rendering

These 6 unit tests test the private `_ratingColor` helper method and should live in a separate unit test file.

## Impact

- Reduces clarity about what is being tested
- Makes it harder to categorize and find tests
- Violates the explicit AGENTS.md convention

## Recommendation

- Extract the 3 unit tests from `source_practice_sheet_status_test.dart` into a new file: `test/features/practice/data/models/source_practice_item_test.dart`
- Extract the 6 unit tests from `confidence_selector_test.dart` into a new file: `test/features/practice/presentation/widgets/confidence_selector_unit_test.dart`
- Keep only `testWidgets` calls in the original files to maintain the widget-test-only contract
