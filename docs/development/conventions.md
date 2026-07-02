# Coding Conventions

## Architecture

- **Feature-first structure:** Each feature is self-contained in `lib/features/<feature>/` with its own data, services, providers, and presentation layers.
- **Shared code** belongs in `lib/core/`.
- **No barrel files** unless imported by production code.

## Error Handling

- Public repository and service methods must return `Result<T>` (sealed class).
- `throw` is only allowed in private helper methods or config validation at startup.
- Use `SpacedRepetitionErrorCode` enum (from `lib/core/errors/spaced_repetition_error_codes.dart`) for spaced repetition errors instead of string literals.
- Empty `catch (_) {}` blocks are forbidden — every catch must log the error.

## Logger

- All Logger instances must be `static final` at class level.
- `const Logger('Name').e(...)` inline is forbidden.
- `.e()` — unexpected exceptions requiring investigation.
- `.w()` — caught exceptions in expected error paths.

## String Normalization

Use the `.normalized` extension (from `lib/core/utils/string_extensions.dart`) instead of `.trim().toLowerCase()` or `.toLowerCase().trim()`:

```dart
// Good
if (input.normalized == query.normalized) { ... }

// Bad
if (input.trim().toLowerCase() == query.trim().toLowerCase()) { ... }
```

## i18n & Number Formatting

### Number Formatting

**Never use `toStringAsFixed()` for user-facing numeric displays.** It always uses a period decimal separator, which is incorrect for comma-decimal locales.

Use locale-aware helpers from `lib/core/utils/number_format_utils.dart`:

```dart
formatDecimal(value, localeName, ...)    // Plain decimals
formatPercent(value, localeName, ...)    // Percentages (0–100 range)
formatCompactNumber(value, localeName)   // Compact (1.5K, 2.3M)
formatHours(totalSeconds, localeName)    // Hours from seconds
formatCurrency(value, localeName, ...)   // Dollar amounts
```

All helpers accept `localeName` from `AppLocalizations.of(context)!.localeName`.

- **CSV exports:** Use invariant `en` format (CSV is data).
- **PDF exports:** Use the user's locale.
- **LLM-facing strings:** Can stay in `en` invariant format.

### l10n Null-Coalesce Fallback

Widgets that run before `AppLocalizations` is available should use:

```dart
l10n?.key ?? 'English fallback'
```

This pattern is used in:
- `lib/core/widgets/dialog_utils.dart`
- `lib/core/utils/error_boundary.dart`
- `lib/core/widgets/shimmer_widget.dart`
- `lib/core/utils/time_utils.dart`

### Locale Switching Gotcha

When the user changes their language in the Profile screen (`ref.read(localeProvider.notifier).state = Locale(value)`), any screen that caches `l10n = AppLocalizations.of(context)!` in a local variable (not inside `build`) will display stale strings until the screen is re-entered. To avoid stale text:

- Always read `l10n` inside the `build` method or use `Consumer`/`ConsumerWidget` that re-reads on every build.
- If stale text is observed after a locale switch, refactor to ensure `context` is fresh (e.g., via `Navigator.pushAndRemoveUntil` or by using `ref.watch(localeProvider)` at the widget root).

## Provider Patterns

- Use Riverpod for all state management.
- Providers should be composed through dependency injection.
- Use `.autoDispose` for providers that don't need to persist across screens.
- Use `.family` for parameterized providers.
- Provider files are named `<name>_providers.dart` (plural).

## Riverpod Provider Test Overrides

When testing, override providers with fakes:

```dart
ProviderScope(
  overrides: [
    myServiceProvider.overrideWithValue(fakeService),
  ],
  child: ...
)
```

## Style

- Follow the [Flutter style guide](https://flutter.dev/docs/development/tools/formatting).
- Use `flutter analyze` to enforce lint rules.
- Avoid `dynamic` types where possible — prefer proper typing.
