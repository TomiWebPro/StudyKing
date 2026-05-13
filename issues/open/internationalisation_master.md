# Internationalisation Overhaul: Spanish Quality & Localisation Architecture

## Context

The app currently supports English (`app_en.arb`) and Spanish (`app_es.arb`) with ~200+ ARB keys each. However, a significant gap exists between what's in the ARB files and what's actually rendered in the UI. Many user-facing strings are hardcoded in English in widget/build methods, bypassing the `AppLocalizations` system entirely. The Spanish translation also contains inconsistencies and quality issues that would compound if this serves as the template for adding more languages.

## Issues Found

### 1. ~70+ Strings Hardcoded in English (Bypass Localisation Entirely)

**Files affected (most impactful):**

| File | Count | Examples |
|------|-------|---------|
| `lib/core/errors/handlers.dart:114-140` | 17 | All error messages: `'Unable to connect to the server...'`, `'API key is required...'`, `'Too many requests...'`, `'A database error occurred...'` |
| `lib/features/practice/presentation/analytics_dashboard.dart` | 30+ | Section headings: `'Accuracy'`, `'Weekly Activity'`, `'Mastery Overview'`, `'Topic Performance'`, empty states: `'No topic data yet...'` |
| `lib/features/quickguide/presentation/quick_guide_screen.dart:308-331` | 6 | Mode cards: `'AI Tutor'`, `'Mentor'`, `'Interactive conversational lessons'`, `'Personal study assistant & planner'` |
| `lib/features/teaching/presentation/widgets/chat_bubble.dart:54` | 3 | Sender labels: `'You'`, `'Tutor'`, `'System'` |
| `lib/features/teaching/presentation/widgets/lesson_progress_bar.dart:55-92` | 3 | `'$remaining min remaining'`, `'$exerciseCount questions'`, `'$correctCount correct'` |
| `lib/features/mentor/presentation/mentor_screen.dart:74-83` | 1 | Welcome message body (only greeting is localised) |
| `lib/features/teaching/presentation/tutor_screen.dart:101` | 1 | Initial AI greeting prompt |
| `lib/features/practice/presentation/practice_screen.dart:648` | 1 | Snackbar error |

**Rationale:** None of these strings exist in `app_en.arb` or `app_es.arb`. A Spanish user sees every error message, analytics label, and mode picker card in English. This is the most impactful issue because it's a complete blind spot — the ARB files show coverage that doesn't reflect reality.

### 2. Spanish Translation Inconsistencies

| Key | English | Spanish (current) | Problem |
|-----|---------|-------------------|---------|
| `accuracy` (line 344) | Accuracy | `Exactitud` | Inconsistent with `accuracyLabel` |
| `accuracyLabel` (line 1827) | Accuracy: {percent} | `Precisión: {percent}` | Same English word "Accuracy" → two different Spanish words |
| `weakLabel` (line 1856) | Weak | `Débil` | Unnatural as a noun; `Por mejorar` or `Con dificultad` is more natural |
| `atRiskTopics` (line 1819) | At Risk Topics | `Temas en Riesgo` | Awkward; `Temas con dificultades` or `Temas en riesgo de quedarse atrás` reads better |
| `weakAreas` (line 219) | Weak Areas | `Áreas Débiles` | Consider `Áreas por mejorar` (positive framing, common in education) |
| `masteredLabel` (line 1852) | Mastered | `Dominado` | Better: `Dominado` is OK but `Adquirido` or `Superado` is more common in educational contexts |

**Rationale:** A Spanish-speaking user will see "Exactitud" in one place and "Precisión" in another for the same English concept. If Spanish — the only non-English locale — has these issues, they will propagate when more languages are added without a style guide.

### 3. Missing ICU Plural Forms in English ARB

| Key | Current | Issue |
|-----|---------|-------|
| `randomQuestions` | `{count} random questions` | No ICU plural: `1 random questions` is grammatically wrong. Should use ICU: `{count, plural, =1{1 random question} other{{count} random questions}}` |
| `sessionsCount` | `{count} sessions` | No ICU plural: `1 sessions`. Should use ICU: `{count, plural, =1{1 session} other{{count} sessions}}` |
| `questionsCountLabel` | `{count} questions` | Same issue: `1 questions` |

**Rationale:** The English base locale itself has grammatically incorrect plurals. Since ARB tooling uses ICU MessageFormat, these should use `plural` syntax. Note that Spanish versions are OK because "1 preguntas" vs "0 preguntas" vs "2 preguntas" are all grammatically the same, but the tooling still won't handle them correctly for English.

### 4. No Extensible Language Architecture

**Issues:**
- Only 2 locales (`en`, `es`) are in `supportedLocales`. Adding a third (e.g. `fr`, `de`) requires manual ARB creation without any guide or checklist.
- No `l10n.yaml` or `AGENTS.md` documenting how to add a new locale, run code generation, or test it.
- No CI check that all `app_en.arb` keys exist in other locale ARB files.
- The coverage test (`test/l10n/app_localizations_coverage_test.dart`) only tests keys that already exist — it cannot detect missing keys from hardcoded strings.

## Affected Files

- `lib/l10n/app_en.arb` — English source of truth
- `lib/l10n/app_es.arb` — Spanish translation (inconsistencies to fix)
- `lib/core/errors/handlers.dart` — 17 hardcoded error messages
- `lib/features/practice/presentation/analytics_dashboard.dart` — Entirely unlocalised dashboard
- `lib/features/quickguide/presentation/quick_guide_screen.dart` — Mode picker cards
- `lib/features/teaching/presentation/widgets/chat_bubble.dart` — Sender role labels
- `lib/features/teaching/presentation/widgets/lesson_progress_bar.dart` — Progress stat labels
- `lib/features/mentor/presentation/mentor_screen.dart` — Welcome message body
- `lib/features/teaching/presentation/tutor_screen.dart` — Initial greeting
- `lib/features/practice/presentation/practice_screen.dart` — Error snackbar
- `test/l10n/app_localizations_coverage_test.dart` — Coverage test that needs extension

## Acceptance Criteria

1. **All error messages in `handlers.dart`** are extracted to ARB keys in both `app_en.arb` and `app_es.arb` with proper ICU placeholders. Hardcoded strings replaced with `AppLocalizations.of(context)!` calls.
2. **`analytics_dashboard.dart`** — Every label, section heading, empty state, and stat string is localised via ARB keys.
3. **Mode picker cards** in `quick_guide_screen.dart` use localised strings instead of `'AI Tutor'` / `'Mentor'`.
4. **Sender labels** in `chat_bubble.dart` (`'You'`, `'Tutor'`, `'System'`) are localised.
5. **Lesson progress bar** labels in `lesson_progress_bar.dart` and `tutor_screen.dart` use localised strings.
6. **Spanish consistency** — `accuracy` and `accuracyLabel` use the same translation; `weakLabel` and `atRiskTopics` reviewed for naturalness; one style chosen per concept.
7. **English ICU plurals** — `randomQuestions`, `sessionsCount`, `questionsCountLabel` updated to proper ICU `plural` syntax in `app_en.arb`.
8. **Coverage test** updated to detect missing keys between English and Spanish ARB files (fails if any `app_en.arb` key lacks a `app_es.arb` counterpart, and vice versa).
9. **`AGENTS.md` or `CONTRIBUTING.md`** contains a "Adding a new locale" checklist documenting: creating the ARB, running `flutter gen-l10n`, adding the locale to `supportedLocales`, adding it to the coverage test.
