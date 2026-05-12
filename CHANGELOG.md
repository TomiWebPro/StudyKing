# Changelog

- 2026-05-13: Migrated theme system from Material 2 to Material 3 — set `useMaterial3: true`, migrated `CardTheme`, `ElevatedButtonTheme`, and `AppBarTheme` to M3 tokens, and added `NavigationBarThemeData` for consistent M3 `NavigationBar` styling
- 2026-05-13: Added `ThemeMode.system` option to the theme picker bottom sheet, allowing users to follow device-level dark/light preference
- 2026-05-13: Removed `FittedBox` with `BoxFit.scaleDown` from Quick Guide chat bubbles — long messages now wrap naturally and respect the user's accessibility font size
- 2026-05-13: Unified `centerTitle` — set globally to `false` in `AppTheme.appBarTheme` and removed per-screen overrides in `practice_session_screen.dart` and `session_history_screen.dart`
- 2026-05-13: Replaced hardcoded `TextStyle`, `Color`, and other visual constants with `textTheme` and `colorScheme` lookups across `api_config_screen.dart`, `profile_screen.dart`, `settings_screen.dart`, `practice_session_screen.dart`, `session_history_screen.dart`, and `subject_detail_view.dart`
