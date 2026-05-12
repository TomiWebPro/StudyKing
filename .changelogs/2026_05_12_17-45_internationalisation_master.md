## Internationalisation Master - Hardcoded UI Strings Localized

### Summary
Replaced 150+ hardcoded English UI strings across 15+ files with `AppLocalizations` calls, added corresponding translation keys to both English and Spanish ARB files, and regenerated the generated localization Dart files.

### Changes Made

**ARB Files (Translation Keys Added):**
- `lib/l10n/app_en.arb` — Added ~350 new translation keys covering all affected screens
- `lib/l10n/app_es.arb` — Added corresponding Spanish translations for all new keys

**Generated Localization Files:**
- `lib/l10n/generated/app_localizations.dart` — Added abstract getters/methods for all new keys
- `lib/l10n/generated/app_localizations_en.dart` — Added English implementations
- `lib/l10n/generated/app_localizations_es.dart` — Added Spanish implementations

**Affected Source Files (15+ files localized):**
- `lib/features/settings/presentation/profile_screen.dart` — 20+ strings (profile fields, validation, dialogs)
- `lib/features/settings/presentation/settings_screen.dart` — 18+ strings (section titles, tiles, dialogs)
- `lib/features/settings/presentation/api_config_screen.dart` — 12+ strings (field labels, descriptions, buttons)
- `lib/features/subjects/presentation/subject_detail_view.dart` — 15+ strings (tabs, stats, menus, dialogs)
- `lib/features/subjects/presentation/subject_management_screen.dart` — 14+ strings (form fields, validation)
- `lib/features/subjects/presentation/subject_list_view.dart` — 4+ strings (empty state, card labels)
- `lib/features/subjects/presentation/subject_selection_screen.dart` — 3 strings (title, button, error)
- `lib/features/subjects/presentation/subject_form_widgets.dart` — 10+ strings (form labels, hints, validation)
- `lib/features/sessions/presentation/session_tracker_screen.dart` — 12+ strings (tracker UI, dialog, labels)
- `lib/features/sessions/presentation/session_history_screen.dart` — 20+ strings (filters, stats, empty states, dialogs)
- `lib/features/quickguide/presentation/quick_guide_screen.dart` — 10+ strings (titles, hints, tooltips, dialog)
- `lib/features/questions/ui/widgets/question_card_widget.dart` — 8+ strings (type labels, difficulty, buttons)
- `lib/features/questions/ui/widgets/single_answer_widget.dart` — 5 strings (semantics, feedback)
- `lib/features/questions/ui/widgets/canvas_drawing_widget.dart` — 12 strings (semantics, status, buttons)
- `lib/pages/graph_rendering_page.dart` — 30+ strings (sections, buttons, dialogs, validation)
- `lib/pages/lesson_scheduling_page.dart` — 15+ strings (sections, dialogs, question types)
