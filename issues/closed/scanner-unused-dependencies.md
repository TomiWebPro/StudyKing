# [Scanner] Unused pubspec dependencies

**Source:** automatic scanner
**Severity:** minor

## Finding

Two packages declared as direct main dependencies in `pubspec.yaml` are **never imported** by any Dart file in the project (lib/ or test/). These can be safely removed to reduce dependency bloat and `flutter pub get` resolution time.

## Locations

1. **`dio: ^5.4.0`** (pubspec.yaml line 25) — Zero `import 'package:dio/...'` statements found anywhere in the project. This HTTP client package appears to be unused; all network/API calls in the project use a different mechanism.

2. **`table_calendar: ^3.0.9`** (pubspec.yaml line 51) — Zero `import 'package:table_calendar/...'` statements found anywhere in the project. The calendar/date-picking UI in the planner uses a custom widget rather than this package.

## Recommendation

Remove both dependencies from `pubspec.yaml` and run `flutter pub get` to clean up the lock file. If either is intended for future use, add a comment explaining the planned integration to avoid re-adding later.

Additionally, `leak_tracker_flutter_testing: ^3.0.10` (dev dependency, line 76) may be removable — verify if it is pulled in as a transitive dependency via `dart pub deps`.
