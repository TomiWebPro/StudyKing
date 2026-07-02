# Remove irrelevant fields from Profile screen (studentId, preferredStudyTime)

**Severity:** minor
**Affected area:** Settings > User Management > Current User (Profile screen)
**Reported by:** user (codebase analysis)

## Description

The Profile screen (Settings > User Management > Current User) currently displays two text fields — "Student ID" and "Preferred Study Time" — that serve no functional purpose. Neither field is read or depended on by any feature, service, or provider in the app. They are purely ornamental metadata that the user can fill in, but nothing ever acts on that data.

- `UserProfile.studentId` (`HiveField(2)`) — A free-text numeric field. The app's actual student identification uses `StudentIdService.getStudentId()` instead. No code reads `profile.studentId` except to display/edit it on the Profile screen.
- `UserProfile.preferredStudyTime` (`HiveField(5)`) — A free-text string like "Evening (6-9 PM)". The actual scheduler/planner system uses the structured `StudentAvailabilityModel` (with `preferredStartHour`, `preferredEndHour`, etc.) and never reads this field.

Both fields are dead weight that clutter the UI and add unnecessary complexity to the model.

## Steps to reproduce

1. Open Settings.
2. Tap "User Management" > "Current User".
3. Observe the "Student ID" and "Preferred Study Time" text fields.

## Expected behavior

The Profile screen should show only meaningful, functional fields: Name, Avatar, Learning Goal, Notifications toggle, Language selection, and Account deletion.

## Actual behavior

Two irrelevant text fields ("Student ID" and "Preferred Study Time") are displayed that have no downstream effect on the app's behavior.

## Code analysis

### `UserProfile` model (`lib/features/settings/data/models/user_profile_model.dart`)
- **Line 15**: `final String? studentId;` — HiveField 2, nullable, never read functionally
- **Line 24**: `final String? preferredStudyTime;` — HiveField 5, nullable, never read functionally
- Both flow through `toJson()` (lines 50, 53), `fromJson()` (lines 62, 65), `copyWith()` (lines 79, 82, 90, 93), and the Hive adapter (`user_profile_model.g.dart` lines 25, 47)

### Profile screen (`lib/features/settings/presentation/profile_screen.dart`)
- **Line 29**: `_studentIdController = TextEditingController();`
- **Line 31**: `_studyTimeController = TextEditingController();`
- **Line 75**: `_studentIdController.text = profile.studentId ?? '';`
- **Line 77**: `_studyTimeController.text = profile.preferredStudyTime ?? '';`
- **Lines 102, 109-114**: Numeric validation of student ID before save
- **Line 123**: `studentId: trimmedStudentId.isEmpty ? null : trimmedStudentId`
- **Line 126**: `preferredStudyTime: _studyTimeController.text.trim().isEmpty ? null : _studyTimeController.text.trim()`
- **Lines 258, 260**: `dispose()` calls
- **Lines 403-419**: Student ID text field widget (uses l10n keys `studentIdOptional`, `yourStudentIdNumber`)
- **Lines 437-448**: Preferred Study Time text field widget (uses l10n keys `preferredStudyTime`, `preferredStudyTimeHint`)

### Localization files (`lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`)
Each contains 6 keys total (3 per field): `studentIdMustBeNumeric`, `studentIdOptional`, `yourStudentIdNumber`, `preferredStudyTime`, `preferredStudyTimeHint` — all become dead strings if the fields are removed.

### No downstream consumers
An exhaustive search confirmed that **zero** files outside of the model and the profile screen read or depend on either field:
- No service, provider, or repository reads `UserProfile.studentId` for data filtering or identification
- No scheduler, planner, or mentor code reads `UserProfile.preferredStudyTime`
- The scheduler uses `StudentAvailabilityModel` (separate structured model in `lib/features/planner/data/models/student_availability_model.dart`)

## Suggested approach

### Option A (recommended for safety): Remove from UI only
Keep the model fields in `UserProfile` for backward compatibility with existing Hive data. Remove only the UI surface and l10n strings:

1. **`profile_screen.dart`**: Remove `_studentIdController`, `_studyTimeController`, their load/save/validation/dispose logic, and the two `_buildTextField` widgets.
2. **`app_en.arb` / `app_es.arb`**: Remove the 6 dead l10n keys.
3. **Regenerate l10n**: Run code generation to update `app_localizations*.dart` files.
4. **Tests**: Remove related assertions in `profile_screen_test.dart`, `app_localizations_test.dart`.

### Option B (cleaner, requires migration): Remove from model too
All of Option A, plus:
1. **`user_profile_model.dart`**: Remove `studentId` (HiveField 2) and `preferredStudyTime` (HiveField 5). ⚠️ Removing HiveField(2) shifts all subsequent field indices, which would corrupt existing serialized Hive data. Requires either bumping the Hive `typeId` with a migration, or leaving the fields in place as `@deprecated` unused fields.
2. **Regenerate Hive adapter**: Run `build_runner` to update `user_profile_model.g.dart`.
3. **`user_profile_model_test.dart`**: Remove related test data and assertions.
4. **`settings_repository_test_helper.dart`**, **`settings_repository_hive_test.dart`**: Remove related assertions.

**Recommendation**: Start with Option A (UI-only removal). It's safe, has zero migration risk, and immediately cleans up the Profile screen. Option B can be done in a follow-up when a Hive migration strategy is in place.
