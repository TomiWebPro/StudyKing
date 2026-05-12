# i18n: Localise hardcoded English strings & improve Spanish translation quality

## Context

The app uses Flutter's `gen-l10n` with ARB files (`app_en.arb`, `app_es.arb`) and supports `en` + `es` locales. Many user-facing strings remain hardcoded in English across the codebase — they never pass through `AppLocalizations.of(context)`, so they are invisible to Spanish (and future) users. Additionally, the Spanish translation has several quality gaps (identical duration abbreviations, inconsistent formality register, string concatenation patterns that break for RTL).

## Affected Files

### Sessions feature (primary)
| File | Issue |
|------|-------|
| `lib/features/sessions/widgets/session_analytics.dart` | **8 hardcoded strings**: `'Sessions by Day of Week'`, `'Performance Metrics'`, `'Avg Session'`, `'Total Sessions'`, `'Current Streak'`, `'$currentStreak days'`, `'Total Time'`, `'0s'`. Entire file lacks `AppLocalizations` import. |
| `lib/features/sessions/presentation/session_tracker_screen.dart:177` | `_formatElapsed` returns `'${hours}h ${mins}m ${secs}s'` — English h/m/s abbreviations hardcoded. Should reuse `time_utils.dart` `formatDuration` which already uses locale-aware keys. |

### Across all other features
| File | Hardcoded strings |
|------|-------------------|
| `lib/features/lessons/presentation/topic_list_screen.dart:50` | `'No topics yet - add some!'` |
| `lib/features/lessons/presentation/lesson_list_screen.dart:41` | `'No lessons - use Planner to generate!'` |
| `lib/features/lessons/presentation/lesson_list_screen.dart:55` | `'${l.blocks.length} blocks'` |
| `lib/features/lessons/presentation/lesson_detail_screen.dart:113-123` | `'Explanation'`, `'Example'`, `'Exercise'`, `'Slide'`, `'Quiz'`, `'Summary'` block type labels |
| `lib/features/practice/presentation/practice_session_screen.dart:302-303` | `' - '` hardcoded separator in app bar title |
| `lib/features/practice/presentation/practice_session_screen.dart:434` | `['Option A', 'Option B', 'Option C', 'Option D']` fallback options |
| `lib/features/practice/presentation/practice_session_screen.dart:455` | `'Drawing submitted'` |
| `lib/features/practice/presentation/practice_session_screen.dart:501` | `'Unsupported question type: ${question.type.name}'` |
| `lib/features/practice/presentation/learning_plan_dashboard.dart` | **12 hardcoded strings**: `'No study plan for today'`, `'At Risk Topics'`, `'Ready to Advance'`, `'Mastery Overview'`, `'Total Topics'`, `'Mastered'`, `'Weak'`, `'Accuracy: ...'`, `'Avg Accuracy: ...'`, `'Avg Readiness: ...'`, empty states, etc. |
| `lib/features/planner/presentation/planner_screen.dart:47` | `'$course - Topic ${...}'` |
| `lib/features/quickguide/presentation/quick_guide_screen.dart:327-333` | Full help dialog is hardcoded English text block |
| `lib/features/quickguide/presentation/quick_guide_screen.dart:221,262` | Semantics labels hardcoded |
| `lib/features/settings/presentation/settings_screen.dart:416-418` | AboutDialog: `'StudyKing'`, `'v0.1.0'`, `'© 2026 StudyKing.'` |
| `lib/features/settings/presentation/settings_screen.dart:289,293` | `'unknown-model'`, `'Unknown'` fallbacks |
| `lib/features/subjects/presentation/subject_detail_view.dart:200` | `'${l10n.examDateOptional}: '` — colon+space appended with `+` |
| `lib/features/subjects/presentation/subject_detail_view.dart:263,272` | `'Lesson'` fallback |
| `lib/features/subjects/presentation/subject_list_view.dart:39,55` | `'Error: $error'` formatting |
| `lib/features/questions/ui/widgets/question_card_widget.dart:227,244` | `['Option 1', 'Option 2', 'Option 3', 'Option 4']` fallback |
| `lib/features/questions/ui/widgets/question_card_widget.dart:371` | `'Question'` default type label |

### ARB / translation files
| File | Issue |
|------|-------|
| `lib/l10n/app_es.arb:durationDays/Hours/Minutes/Seconds` | Identical to English: `1d`, `1h`, `1m`, `1s`. Spanish convention uses `min` for minutes. |
| `lib/l10n/app_es.arb:practiceQuestionsFrom` | Uses formal `Practique` (usted) — informal `Practica` (tú) is more natural for the student/teen target audience. |
| `lib/l10n/app_en.arb` | Missing ~30+ translation keys for the hardcoded strings listed above |

### Other
| File | Issue |
|------|-------|
| `lib/core/utils/time_utils.dart:21-47` | `formatDuration` joins locale-aware segments with hardcoded spaces (`'... ${_getDurationHours(...)} ${_getDurationMinutes(...)} ...'`). Space-separated concatenation may not suit all locales. |

## Rationale

1. **Hardcoded strings are invisible to localisation**: Any user-facing string not wrapped in `AppLocalizations.of(context)` will always display in English, regardless of locale setting. ~40+ strings across 13+ files have this problem.

2. **Duration formatting is English-centric**: The `_formatElapsed` method and `formatDuration` use `h`, `m`, `s` abbreviations. In Spanish, minutes should use `min`, and the space-separated concatenation pattern does not allow locale-specific formatting (e.g., some languages may use no spaces or different ordering).

3. **String concatenation with punctuation breaks locale adaptability**: Patterns like `'${l10n.examDateOptional}: '` or `'${label} - ${value}'` embed English punctuation directly. This is fine for English and Spanish, but would silently break for RTL languages (Arabic, Hebrew) where colon/dash placement differs.

4. **Stale ARB keys**: `app_en.arb` has `noTopicsAvailable` ("No topics available") and `noLessonsYet` ("No lessons yet"), but the UI uses different strings (`'No topics yet - add some!'`, `'No lessons - use Planner to generate!'`). These keys are unused and the UI strings are not translated.

5. **Spanish translation quality**: The `m` (minutes) abbreviation is ambiguous in Spanish (`m` = metros), and `1d`/`1h`/`1s` being identical to English suggests the duration strings were copied without adaptation. The imperative mood choice (`Practique` vs `Practica`) should match the app's overall register.

6. **Scalability**: Every hardcoded string today means rework when adding a third locale (e.g., French, Arabic). A systematic sweep now prevents compounding tech debt.

## Acceptance Criteria

1. **Add translation keys to ARB files**: Create new keys in `app_en.arb` and `app_es.arb` for every hardcoded user-facing string identified above. Each key must have a `@description` and correct `placeholders` where applicable.

2. **Wire `session_analytics.dart` to AppLocalizations**: Import and use `AppLocalizations.of(context)` to replace all 8 hardcoded strings. The `_buildSectionHeader`, `_buildMetricCard`, and `_formatDuration` calls must receive localized text.

3. **Replace `_formatElapsed` with `formatDuration`**: In `session_tracker_screen.dart`, delete the `_formatElapsed` method and use the locale-aware `formatDuration` from `time_utils.dart` (or `formatDurationFromContext`).

4. **Localise duration abbreviations in Spanish ARB**: Update `durationMinutes` in `app_es.arb` to use `min` instead of `m`:
   ```
   "{count, plural, =1{1min} other{{count}min}}"
   ```

5. **Fix all hardcoded strings across remaining features**: Replace every hardcoded string in the table above with `l10n.xxx` calls using the newly created ARB keys.

6. **Remove stale ARB keys**: Replace or remove `noTopicsAvailable` and `noLessonsYet` from both ARB files if they are unused. If the UI strings differ intentionally, add new keys and remove the unused ones.

7. **Add locale-aware punctuation/separators**: Convert `+` concatenation with punctuation into parameterised strings. Examples:
   - `'${l10n.examDateOptional}: '` → Use a key like `examDateOptionalLabel` that includes the colon in the translated string (e.g., `"Fecha de examen opcional:"`).
   - `'${spacedRepetitionMode} - ${question.type.name}'` → Use a key with `{mode}` and `{type}` placeholders.

8. **Review Spanish formality register**: Decide on a consistent register (tú vs usted) and apply it to all imperative/action-oriented translations. Change `"Practique preguntas de {subjectName}"` to `"Practica preguntas de {subjectName}"` if informal is preferred.

9. **Regenerate & verify**: Run `flutter gen-l10n` and verify no compilation errors. Run `flutter test` — especially `test/l10n.app_localizations.test.dart` — to ensure all keys resolve correctly for both `en` and `es`.

10. **Test in Spanish**: Set device locale to `es` and manually verify:
    - All text in `session_analytics.dart` renders in Spanish
    - Duration displays use `h`/`min`/`s` abbreviations in Spanish vs `h`/`m`/`s` in English
    - Block type labels, empty states, section headers, and error messages all render in Spanish
