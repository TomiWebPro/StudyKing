# Improvements Report: `lib/features/settings`

## Scope
- Reviewed all files under `lib/features/settings`:
  - `presentation/settings_screen.dart`
  - `presentation/profile_screen.dart`
  - `presentation/api_config_screen.dart`
  - `data/repositories/settings_repository.dart`
  - `data/models/settings_box.dart`
  - `data/models/settings_box.g.dart` (generated)
  - `data/models/user_profile_model.dart`

## Findings

| # | File | Line | Severity | Issue | Suggested fix |
|---|---|---:|---|---|---|
| 1 | `lib/features/settings/presentation/api_config_screen.dart` | 194-214 | **High** | API key field behavior is broken: `obscureText: true` is always on, and suffix icon mutates controller text to bullets/empty string instead of toggling visibility. This can overwrite a real key and accidentally save invalid data. | Add a dedicated `bool _obscureApiKey` state and toggle that; never mutate input text for visibility. |
| 2 | `lib/features/settings/presentation/api_config_screen.dart` | 55 | **High** | Base URL changes are written to `apiBaseUrlProvider` only, but not persisted through repository/API-specific save path; they may be lost on restart depending on provider wiring. | Persist both API key and base URL in storage (e.g., `updateSettings(apiKey: ..., apiBaseUrl: ...)` or dedicated repository methods). |
| 3 | `lib/features/settings/data/repositories/settings_repository.dart` | 127-129, 153-154 | **High** | `updateSettings`/`updateStats` clear the entire settings box and then write one object at key `0`, while other methods read/write named keys (`apiKey`, `apiBaseUrl`, etc.). This creates a storage schema mismatch and can silently drop settings. | Use one consistent schema: either structured object at one key everywhere, or per-key storage everywhere. Remove `clear()` for partial updates. |
| 4 | `lib/features/settings/data/repositories/settings_repository.dart` | 27-37 | **Medium** | In `saveApiKey`, a `SettingsBox(...)` instance is constructed but discarded. Dead code suggests incomplete refactor and hides intended behavior. | Remove unused object or persist it intentionally. |
| 5 | `lib/features/settings/data/repositories/settings_repository.dart` | 24, 47, 61, 67, 84, 110, 137 | **Medium** | Methods silently return when boxes are `null`, masking initialization errors and causing data-loss-like behavior without logs. | Throw explicit state error (e.g., `StateError('SettingsRepository not initialized')`) or auto-init before access. |
| 6 | `lib/features/settings/data/repositories/settings_repository.dart` | 69-80 | **Medium** | `getProfileData` returns `box.keys.first`; Hive key order is not a reliable "latest profile" strategy. | Store and read a stable key (e.g., `current_profile`) or sort by a stored updated timestamp. |
| 7 | `lib/features/settings/presentation/profile_screen.dart` | 381-386 | **High** | Account deletion performs three `Navigator.pop` calls blindly, which can pop unrelated routes or fail if stack depth differs. | Replace with controlled navigation (e.g., `popUntil` to known route, or pop dialog then `maybePop` once). |
| 8 | `lib/features/settings/presentation/settings_screen.dart` | 377 | **Medium** | In API-key-required dialog, pressing OK pops twice (`Navigator.pop` twice), which can unexpectedly exit settings screen. | Pop only the dialog; navigate explicitly to API config if desired. |
| 9 | `lib/features/settings/presentation/settings_screen.dart` | 389-390 | **Medium** | Loading dialog is `barrierDismissible: false`; if `Navigator.pop` fails during async edge cases, user can get stuck. | Use safer loading pattern (`if (Navigator.canPop) pop`) and/or state-driven progress overlay in widget tree. |
| 10 | `lib/features/settings/presentation/settings_screen.dart` | 435-437 | **High** | Model parsing assumes `providers` shape and accesses `.values.first['id']`; if API response format differs or map is empty, runtime exception occurs. | Parse defensively with null/type checks and fallback values. |
| 11 | `lib/features/settings/presentation/settings_screen.dart` | 394-400 | **Medium** | HTTP request lacks timeout/cancellation and retry policy; slow network can hang UX. | Add `.timeout(...)`, catch `TimeoutException`, and provide retry UI. |
| 12 | `lib/features/settings/presentation/settings_screen.dart` | 398 | **Low** | Hardcoded referer string (`https://studyking.app`) may be wrong in dev/testing and duplicates config. | Move header values to constants/config and vary by environment. |
| 13 | `lib/features/settings/presentation/settings_screen.dart` | 22-197 | **Medium** | Very large `build` method (hundreds of lines) with many inline tiles; difficult to maintain/test. | Split into smaller widgets per section and use reusable tile builders. |
| 14 | `lib/features/settings/presentation/settings_screen.dart` | 524 | **Low** | `_showAnalytics` accepts `dynamic settings`; sacrifices type safety and IDE checks. | Use concrete type (`SettingsBox`) in signature. |
| 15 | `lib/features/settings/presentation/settings_screen.dart` | 571, 611 | **Low** | `_ThemeOption` and `_FontSizeOption` store a `BuildContext` field while also receiving `build` context; unnecessary and confusing. | Remove stored `context` fields; use `build` method context only. |
| 16 | `lib/features/settings/presentation/settings_screen.dart` | 341-344 | **Low** | `Slider` `clamp` returns `num`; implicit conversion to `double` may rely on analyzer permissiveness and reduce clarity. | Cast explicitly (`final validSize = value.clamp(10.0, 30.0) as double`). |
| 17 | `lib/features/settings/presentation/settings_screen.dart` | 367-464 | **Medium** | Networking logic is embedded directly in UI widget, coupling HTTP, parsing, and presentation. | Move model-fetching into repository/service + provider; keep UI focused on state rendering. |
| 18 | `lib/features/settings/presentation/settings_screen.dart` | 103-108 | **Medium** | Study reminder switch is hardcoded `value: true` with no persistence; user action has no effect. | Bind switch to persisted settings state and save changes. |
| 19 | `lib/features/settings/presentation/settings_screen.dart` | 467-499 | **Medium** | Timeout dialog slider is hardcoded to 120 and `onChanged` is empty; Save does nothing. | Store selected timeout in state and persist via settings repository/provider. |
| 20 | `lib/features/settings/presentation/settings_screen.dart` | 501-521 | **Medium** | Session duration picker shows options but does not persist or reflect current value. | Add `sessionDuration` setting in model/repo and wire UI to read/update it. |
| 21 | `lib/features/settings/presentation/settings_screen.dart` | 676-733 | **Low** | Export/Clear cache flows are placeholder-only (always success snackbars), no real implementation/feedback/errors. | Implement real operations or disable/mark as coming soon until functionality exists. |
| 22 | `lib/features/settings/presentation/settings_screen.dart` | 750-766 | **Low** | Sign-out dialog has no sign-out logic, giving false affordance. | Hook into auth service and clear session/state, then redirect appropriately. |
| 23 | `lib/features/settings/presentation/profile_screen.dart` | 14-17, 13 | **Medium** | `TextEditingController`s are never disposed in `State`, causing memory leaks. | Override `dispose()` and dispose all controllers. |
| 24 | `lib/features/settings/presentation/profile_screen.dart` | 46, 54 | **Low** | Profile IDs are created with timestamp strings; collision risk is low but non-zero and not semantically stable. | Use UUIDs (`uuid` package) or a single stable key for one-profile mode. |
| 25 | `lib/features/settings/presentation/profile_screen.dart` | 81-83, 327 | **Low** | `notificationsEnabled` and `language` are hardcoded on save and language tile is non-functional. | Load from existing profile/settings and provide editable controls. |
| 26 | `lib/features/settings/presentation/profile_screen.dart` | 337, 414, 347 | **Low** | Uses `TextStyle(color: Colors.redAccent)` without `const` opportunities and duplicated styles; minor style inconsistency. | Extract shared styles/constants; apply `const` where possible. |
| 27 | `lib/features/settings/presentation/profile_screen.dart` | 178-194, 246-267 | **Low** | Avatar selectors use `GestureDetector` without semantic labels; accessibility support is limited. | Use `InkWell`/`IconButton` with `tooltip`/`Semantics` labels. |
| 28 | `lib/features/settings/presentation/api_config_screen.dart` | 27-28 | **Low** | Null-coalescing on provider reads implies nullable providers; if providers are non-nullable strings, this is redundant and can hide typing issues. | Align provider types and remove unnecessary `?? ''`/`?? default` if non-nullable. |
| 29 | `lib/features/settings/presentation/api_config_screen.dart` | 32 | **Low** | Method signature `void _saveKeys() async` uses `void` async, making errors harder to await/test. | Change to `Future<void> _saveKeys() async`. |
| 30 | `lib/features/settings/presentation/api_config_screen.dart` | 194-214 | **Medium** | Both API key and base URL use identical field builder with `obscureText: true`, so base URL is masked as if sensitive data. | Add parameter to `_buildApiSection` for obscuring; only obscure secret fields. |
| 31 | `lib/features/settings/data/models/settings_box.dart` | 80 | **High** | `toString()` uses `apiKey.substring(0, 8)` whenever key is non-empty; keys shorter than 8 chars crash with range error. | Use safe truncation (`apiKey.substring(0, min(8, apiKey.length))`). |
| 32 | `lib/features/settings/data/models/settings_box.dart` | 80 | **Medium** | `toString()` reveals partial API key; still sensitive leakage in logs/crash reports. | Never include key material in logs; replace with static marker only. |
| 33 | `lib/features/settings/data/models/settings_box.dart` | 67-74, 136-143; `user_profile_model.dart` 57-58 | **Medium** | JSON factories rely on dynamic values without type guards; malformed JSON can throw at runtime. | Add explicit parsing/conversion and default fallbacks with type checks. |
| 34 | `lib/features/settings/data/models/settings_box.dart` | 84-151 and `data/models/user_profile_model.dart` | **Low** | Two overlapping profile models (`ProfileData` and `UserProfile`) indicate duplicated domain concepts and potential drift. | Consolidate to one profile entity and one persistence adapter path. |
| 35 | `lib/features/settings/data/models/user_profile_model.dart` | 3-91 | **Medium** | Hive model lacks generated adapter linkage (`part` + generated file) in this directory, suggesting it cannot be persisted unless adapter is elsewhere. | If used, add `part 'user_profile_model.g.dart';` and generate/register adapter; otherwise remove dead model. |
| 36 | `lib/features/settings/presentation/settings_screen.dart` | 56 | **Low** | Formatting/style issue: irregular spacing (`onTap: () =>      _showThemeDialog...`). | Run formatter and keep style lint-clean. |
| 37 | `lib/features/settings/presentation/settings_screen.dart` | 215-224 | **Low** | `_getAiModelLabel` assumes non-empty `name` before indexing `name[0]`; malformed IDs can throw. | Guard for empty derived names before capitalization. |
| 38 | `lib/features/settings/presentation/settings_screen.dart` | 407-452 | **Medium** | Full model list is rendered without paging/search/filter; can degrade UX/perf with large model catalogs. | Add search field, lazy filtering, and optional pagination/limits. |
| 39 | `lib/features/settings/presentation/settings_screen.dart` | 454-463 and similar | **Low** | Raw exception text shown directly to users (`Error: $e`), leaking technical details and reducing UX quality. | Map errors to user-friendly messages; log technical details separately. |
| 40 | `lib/features/settings/presentation/profile_screen.dart` | 419-428 | **Low** | Input fields have no validators/formatters (e.g., student ID numeric constraints), increasing bad data risk. | Add `TextInputFormatter`s and per-field validation before save. |

## Additional enhancement suggestions (non-blocking)

1. Introduce a typed `SettingsState` + notifier for all settings (theme, font size, timeout, reminders, session duration) to avoid split state across ad hoc providers and repository calls.
2. Add unit tests for repository read/write schema consistency and migration tests for existing users.
3. Add widget tests for settings flows (API key save, model selection, profile save/delete, dialogs) and navigator behavior.
4. Add secure storage for API keys (e.g., `flutter_secure_storage`) rather than plain local box storage.
5. Add i18n support for all user-facing strings currently hardcoded in UI.

## Notes on generated code
- `lib/features/settings/data/models/settings_box.g.dart` is generated; direct manual edits are not recommended.
