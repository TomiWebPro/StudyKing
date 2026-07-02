# [Scanner] Inline Logger instances violating static-final convention

**Source:** automatic scanner
**Severity:** major

## Finding

Eight occurrences of inline `Logger('Name').w(...)` calls where the Logger should instead be a `static final` class-level member. This violates the AGENTS.md rule: *"Inline `const Logger('Name').e(...)` is forbidden."* (and the same applies to `.w()` calls).

## Location

- `lib/features/sessions/services/session_export_service.dart:207` — `Logger('SessionExportService').w('Failed to write CSV file', e);` (inside `writeCSVFile`)
- `lib/features/sessions/services/session_export_service.dart:228` — `Logger('SessionExportService').w('Failed to write JSON file', e);` (inside `writeJSONFile`)
- `lib/features/sessions/services/session_export_service.dart:250` — `Logger('SessionExportService').w('Failed to write PDF file', e);` (inside `writePDFFile`)
- `lib/features/subjects/presentation/widgets/subject_stats_tab.dart:73` — `Logger('SubjectStatsTab').w('Failed to load syllabus progress', e);`
- `lib/features/planner/providers/syllabus_providers.dart:63` — `Logger('SyllabusProgressProvider').w('Failed to load syllabus progress', e);`
- `lib/features/planner/providers/syllabus_providers.dart:88` — `Logger('RoadmapListProvider').w('Failed to load roadmaps', e);`
- `lib/features/planner/providers/adherence_providers.dart:109` — `Logger('AdherenceSummaryProvider').w('Failed to compute adherence summary', e);`
- `lib/features/planner/providers/adherence_providers.dart:172` — `Logger('TodayAdherenceProvider').w('Failed to load today adherence', e);`

## Recommendation

Add a `static final Logger _logger = const Logger('ClassName');` to each class and replace the inline calls with `_logger.w(...)`.
