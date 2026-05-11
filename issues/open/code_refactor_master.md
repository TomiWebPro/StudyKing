# Code Refactor Issue: Duplicated Hex-to-Color Conversion Utilities

## Context
The `SubjectColors` class in `subject_form_widgets.dart` provides a proper utility for hex-to-Color conversion (`stringToColor`), but **identical logic is duplicated** in two other files:

- `SubjectManagementScreen._colorToMaterialColor()` (lines 248-252)
- `SubjectDetailScreen._stringToColor()` (lines 707-713)

All three methods perform the exact same conversion:
```dart
// From SubjectColors (correct, reusable):
static Color stringToColor(String hexColor) {
  final hex = hexColor.replaceAll('#', '');
  return Color(int.parse(hex, radix: 16) + 0xFF000000);
}

// Duplicated locally (not reusable):
Color _colorToMaterialColor(String hexColor) {
  final hex = hexColor.replaceAll('#', '');
  return Color(int.parse(hex, radix: 16) + 0xFF000000);
}

// Duplicated locally (different parsing approach, same result):
Color _stringToColor(String hexColor) {
  try {
    return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
  } catch (_) {
    return Colors.blue;
  }
}
```

## Affected Files
| File | Line(s) | Issue |
|------|---------|-------|
| `lib/features/subjects/presentation/subject_management_screen.dart` | 248-252 | Duplicated `_colorToMaterialColor()` |
| `lib/features/subjects/presentation/subject_detail_view.dart` | 707-713 | Duplicated `_stringToColor()` |
| `lib/features/subjects/presentation/subject_form_widgets.dart` | 18-21 | The canonical implementation (`SubjectColors.stringToColor`) |

## Rationale
- **DRY violation**: Three separate implementations exist for one utility
- **Maintainability burden**: Changing the hex format requires updating three locations
- **Missed abstraction**: `SubjectColors` already exists as a color utility class but is only used by `SubjectListView`
- **Inconsistent error handling**: `_stringToColor` catches errors and returns `Colors.blue`, while `_colorToMaterialColor` and `stringToColor` do not

## Acceptance Criteria
1. Consolidate all hex-to-Color conversion into `SubjectColors` (which already has the canonical implementation)
2. Remove `_colorToMaterialColor` from `SubjectManagementScreen`; use `SubjectColors.stringToColor`
3. Remove `_stringToColor` from `SubjectDetailScreen`; use `SubjectColors.stringToColor`
4. Consider moving `SubjectColors` to `lib/core/utils/color_utils.dart` for broader reusability across the app
5. Add consistent error handling (fallback to default color when parsing fails)
