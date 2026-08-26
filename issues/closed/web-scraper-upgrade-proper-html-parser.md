# Web Scraper: Replace Custom HTML Stripping with Proper HTML Parser

**Severity:** major
**Affected area:** Content Ingestion — Web Scraping
**Reported by:** codebase audit

## Description

The current web scraper (`lib/features/ingestion/services/web_scraper.dart`) uses a custom HTML-to-text conversion implemented in `DocumentExtractor.stripHtmlToText()`. This custom implementation removes HTML tags with basic regex/string operations, which has critical limitations:

1. **No proper DOM parsing** — Tags are stripped with naive string operations, not a real HTML parser. This breaks on malformed HTML, nested tags, and edge cases.
2. **No content extraction refinement** — Extracts ALL text including navigation, sidebars, headers, footers, ads, and other non-content elements. There's no main-content extraction algorithm (like readability/boilerpipe).
3. **No encoding handling** — Character encoding issues with non-UTF8 pages
4. **No JavaScript rendering** — Cannot handle SPAs or JavaScript-rendered content
5. **No meta-data extraction** — Doesn't extract page title, description, author, publication date, or other metadata
6. **No rate limiting/politeness** — No delay between requests, no robots.txt respect, no caching

## Steps to reproduce

1. Open Upload screen
2. Enter a URL (e.g., a Wikipedia article, a blog post, a documentation page)
3. Click "Fetch & Scrape"
4. Observe: extracted content includes navigation menus, sidebar links, footer text mixed with actual content

## Expected behavior

The web scraper should:
- Extract only the main content (article body, ignoring navigation, ads, sidebars)
- Return clean, structured text with preserved headings and hierarchy
- Handle different page layouts reliably
- Extract page metadata (title, description)
- Cache results to avoid redundant fetches
- Be polite (user-agent, rate limiting, robots.txt)

## Actual behavior

Custom HTML stripping extracts all visible text including non-content elements. Navigation menus, ads, and page chrome contaminate the extracted content.

## Code analysis

- `lib/features/ingestion/services/web_scraper.dart:1-53` — `WebScraper` class: HTTP fetch + delegates to `DocumentExtractor.stripHtmlToText()`
- `lib/features/ingestion/services/document_extractor.dart` — `stripHtmlToText()` method uses regex/string operations:
  - Removes `<script>` and `<style>` blocks
  - Strips remaining HTML tags
  - Decodes common entities
  - No DOM parsing, no content extraction algorithm
- `lib/features/ingestion/presentation/upload_screen.dart:164-180` — `_fetchUrlContent()` calls pipeline scraper

## Suggested approach

1. **Add a proper HTML parsing library**:
   - `html` (from the `html` Dart package, formerly `html_parser`) — Provides full DOM parsing with querySelector support
   - `readability` or implement Mozilla's Readability algorithm — Extracts main content, removes navigation/ads/sidebars

2. **Implement a two-pass extraction**:
   - **Pass 1**: Parse HTML into DOM tree, extract <title>, <meta> tags, canonical URL
   - **Pass 2**: Run Readability-like algorithm to identify and extract main content (article body, ignoring nav, aside, footer, script, style, .sidebar, .ad, etc.)

3. **Add metadata extraction**:
   ```dart
   class PageMetadata {
     final String title;
     final String? description;
     final String? author;
     final DateTime? publicationDate;
     final String? siteName;
     final String? canonicalUrl;
   }
   ```

4. **Add cache layer** — Cache fetched pages in Hive (with TTL) to avoid unnecessary repeat fetches

5. **Add polite fetching** — Respect `robots.txt` (via `robots_txt` package or manual), add configurable delay between requests, set proper `User-Agent` header
