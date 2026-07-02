# [Scanner] Hardcoded non-localized error strings in WebScraper

**Source:** automatic scanner
**Severity:** minor

## Finding

`WebScraper.fetchPageContent()` returns hardcoded error strings via `Result.failure(...)` that could be shown to users without localization. The strings `'Invalid_URL_scheme'`, `'Fetch_failed_status: ${response.statusCode}'`, and `'No_readable_content'` are neither localized nor even proper user-facing messages (they use PascalCase/snake_case format suitable for internal error codes).

## Location

- `lib/features/ingestion/services/web_scraper.dart:18` — `return Result.failure('Invalid_URL_scheme');`
- `lib/features/ingestion/services/web_scraper.dart:29-31` — `return Result.failure('Fetch_failed_status: ${response.statusCode}');`
- `lib/features/ingestion/services/web_scraper.dart:37` — `return Result.failure('No_readable_content');`

## Recommendation

Either:
1. Replace the hardcoded strings with localized messages from `l10n` (if the errors are user-facing), or
2. Define proper error code constants/enums and let the caller handle localization.

At minimum the strings should be proper English sentences if they are shown to the user.
