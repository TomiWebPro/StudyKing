# [Scanner] Empty catch blocks in QuestionImportUtils violate AGENTS.md

**Source:** automatic scanner
**Severity:** major

## Finding

Five empty `catch (_) {}` blocks in `QuestionImportUtils` that silently swallow errors without logging. This directly violates the AGENTS.md rule: *"Empty `catch (_) {}` blocks are forbidden. Every catch must log the error with a descriptive message."*

The catches parse DateTime fields from CSV rows; if parsing fails they fall back to `DateTime.now()`. While the fallback logic is acceptable, the caught exception should be logged (at `.w()` level) so that malformed CSV data doesn't go unnoticed.

## Location

- `lib/core/utils/question_import_utils.dart:114` — `catch (_) { createdAt = DateTime.now(); }`
- `lib/core/utils/question_import_utils.dart:120` — `catch (_) { updatedAt = DateTime.now(); }`
- `lib/core/utils/question_import_utils.dart:128` — `catch (_) {}` (completely empty, no fallback logging)
- `lib/core/utils/question_import_utils.dart:165` — `catch (_) { createdAt = DateTime.now(); }`
- `lib/core/utils/question_import_utils.dart:171` — `catch (_) { updatedAt = DateTime.now(); }`

## Recommendation

Replace each `catch (_)` with `catch (e)` and call `_logger.w('Failed to parse date from CSV: $e')` or similar. The class already has a `static final Logger _logger` declared at line 14.
